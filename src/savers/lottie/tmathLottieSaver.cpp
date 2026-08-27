#include <charconv>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <limits>
#include <new>

#if !defined(__EMSCRIPTEN__) && !defined(_WIN32)
#include <unistd.h>
#endif

#include "tmathDisplayList.h"
#include "tmathSaver.h"
#include "tmathScene.h"

namespace tmath
{

struct LottieOutput
{
    FILE* file = nullptr;
    char* temporary = nullptr;

    ~LottieOutput()
    {
        if (file) std::fclose(file);
        if (temporary) {
            std::remove(temporary);
            delete[] temporary;
        }
    }

    Result open(const char* path) noexcept
    {
        auto size = std::strlen(path);
#if !defined(__EMSCRIPTEN__) && !defined(_WIN32)
        static constexpr char SUFFIX[] = ".tmath-XXXXXX";
        if (size > std::numeric_limits<size_t>::max() - sizeof(SUFFIX)) {
            return Result::OutOfMemory;
        }
        temporary = new (std::nothrow) char[size + sizeof(SUFFIX)];
        if (!temporary) return Result::OutOfMemory;
        std::memcpy(temporary, path, size);
        std::memcpy(temporary + size, SUFFIX, sizeof(SUFFIX));
        auto descriptor = mkstemp(temporary);
        if (descriptor < 0) return Result::IoError;
        file = fdopen(descriptor, "wb");
        if (!file) close(descriptor);
#else
        static constexpr char SUFFIX[] = ".tmath.tmp";
        if (size > std::numeric_limits<size_t>::max() - sizeof(SUFFIX)) {
            return Result::OutOfMemory;
        }
        temporary = new (std::nothrow) char[size + sizeof(SUFFIX)];
        if (!temporary) return Result::OutOfMemory;
        std::memcpy(temporary, path, size);
        std::memcpy(temporary + size, SUFFIX, sizeof(SUFFIX));
        file = std::fopen(temporary, "wb");
#endif
        return file ? Result::Success : Result::IoError;
    }

    Result finish(const char* path, Result result) noexcept
    {
        if (file && std::fclose(file) != 0 && result == Result::Success) result = Result::IoError;
        file = nullptr;
        if (result == Result::Success && std::rename(temporary, path) != 0) result = Result::IoError;
        if (result != Result::Success) std::remove(temporary);
        delete[] temporary;
        temporary = nullptr;
        return result;
    }
};

struct LottieMemoryOutput
{
    uint8_t* data = nullptr;
    uint32_t size = 0;
    uint32_t capacity = 0;

    ~LottieMemoryOutput()
    {
        delete[] data;
    }

    bool write(const void* value, size_t count) noexcept
    {
        if (count > UINT32_MAX - size) return false;
        auto required = size + static_cast<uint32_t>(count);
        if (required > capacity) {
            auto next = capacity ? capacity : 4096u;
            while (next < required) {
                if (next > UINT32_MAX / 2u) {
                    next = required;
                    break;
                }
                next *= 2u;
            }
            auto resized = new (std::nothrow) uint8_t[next];
            if (!resized) return false;
            if (size) std::memcpy(resized, data, size);
            delete[] data;
            data = resized;
            capacity = next;
        }
        if (count) std::memcpy(data + size, value, count);
        size = required;
        return true;
    }

    uint8_t* release(uint32_t& outputSize) noexcept
    {
        auto output = data;
        outputSize = size;
        data = nullptr;
        size = 0;
        capacity = 0;
        return output;
    }
};

struct JsonWriter
{
    FILE* file = nullptr;
    LottieMemoryOutput* memory = nullptr;
    bool valid = true;
    Result failure = Result::Success;

    explicit JsonWriter(FILE* file) : file(file)
    {
    }

    explicit JsonWriter(LottieMemoryOutput& memory) : memory(&memory)
    {
    }

    void bytes(const void* value, size_t size) noexcept
    {
        if (!valid) return;
        if (file) {
            valid = std::fwrite(value, 1, size, file) == size;
            if (!valid) failure = Result::IoError;
        } else {
            valid = memory && memory->write(value, size);
            if (!valid) failure = Result::OutOfMemory;
        }
    }

    void raw(const char* value) noexcept
    {
        bytes(value, std::strlen(value));
    }

    void character(char value) noexcept
    {
        bytes(&value, 1u);
    }

    void string(const char* value) noexcept
    {
        character('"');
        if (value) {
            for (auto cursor = reinterpret_cast<const uint8_t*>(value); *cursor && valid; cursor++) {
                switch (*cursor) {
                    case '"': raw("\\\""); break;
                    case '\\': raw("\\\\"); break;
                    case '\b': raw("\\b"); break;
                    case '\f': raw("\\f"); break;
                    case '\n': raw("\\n"); break;
                    case '\r': raw("\\r"); break;
                    case '\t': raw("\\t"); break;
                    default: {
                        if (*cursor < 0x20u) {
                            static constexpr char HEX[] = "0123456789abcdef";
                            char escaped[7] = {'\\', 'u', '0', '0', HEX[*cursor >> 4], HEX[*cursor & 0x0f], '\0'};
                            raw(escaped);
                        } else {
                            character(static_cast<char>(*cursor));
                        }
                        break;
                    }
                }
            }
        }
        character('"');
    }

    template<typename T>
    void number(T value) noexcept
    {
        if (!valid) return;
        char buffer[64];
        auto converted = std::to_chars(buffer, buffer + sizeof(buffer), value);
        if (converted.ec != std::errc{}) {
            valid = false;
            failure = Result::Unknown;
            return;
        }
        bytes(buffer, static_cast<size_t>(converted.ptr - buffer));
    }
};

struct LottiePlacement
{
    float sx = 1.0f;
    float sy = 1.0f;
    float tx = 0.0f;
    float ty = 0.0f;
    BBox clip;
    bool clipped = false;
};

static float _opacity(uint8_t alpha, float opacity)
{
    auto value = static_cast<float>(alpha) * opacity * (100.0f / 255.0f);
    if (value < 0.0f) return 0.0f;
    if (value > 100.0f) return 100.0f;
    return value;
}

static Color _mix(Color from, Color to, float progress)
{
    auto channel = [progress](uint8_t a, uint8_t b) {
        auto value = static_cast<float>(a) + (static_cast<float>(b) - a) * progress;
        return static_cast<uint8_t>(value + 0.5f);
    };
    return {channel(from.r, to.r), channel(from.g, to.g),
            channel(from.b, to.b), channel(from.a, to.a)};
}

static Vec2 _point(const LottiePlacement& placement, const Vec2& point)
{
    return {placement.tx + point.x * placement.sx, placement.ty + point.y * placement.sy};
}

static float _scale(const LottiePlacement& placement)
{
    return (std::fabs(placement.sx) + std::fabs(placement.sy)) * 0.5f;
}

static BBox _intersect(const BBox& first, const BBox& second)
{
    auto x = std::fmax(first.x, second.x);
    auto y = std::fmax(first.y, second.y);
    auto right = std::fmin(first.x + first.width, second.x + second.width);
    auto bottom = std::fmin(first.y + first.height, second.y + second.height);
    return {x, y, std::fmax(0.0f, right - x), std::fmax(0.0f, bottom - y)};
}

static LottiePlacement _mount(const LottiePlacement& parent, const Config& parentConfig,
                              const Config& childConfig, const Viewport& viewport)
{
    LottiePlacement output;
    auto x = viewport.x * static_cast<float>(parentConfig.width);
    auto y = viewport.y * static_cast<float>(parentConfig.height);
    auto width = viewport.width * static_cast<float>(parentConfig.width);
    auto height = viewport.height * static_cast<float>(parentConfig.height);
    output.sx = parent.sx * width / static_cast<float>(childConfig.width);
    output.sy = parent.sy * height / static_cast<float>(childConfig.height);
    output.tx = parent.tx + parent.sx * x;
    output.ty = parent.ty + parent.sy * y;
    auto a = _point(parent, {x, y});
    auto b = _point(parent, {x + width, y + height});
    output.clip = {std::fmin(a.x, b.x), std::fmin(a.y, b.y),
                   std::fabs(b.x - a.x), std::fabs(b.y - a.y)};
    if (parent.clipped) output.clip = _intersect(parent.clip, output.clip);
    output.clipped = true;
    return output;
}

static void _property(JsonWriter& json, float value)
{
    json.raw("{\"a\":0,\"k\":");
    json.number(value);
    json.character('}');
}

static void _vectorProperty(JsonWriter& json, const Vec2& value)
{
    json.raw("{\"a\":0,\"k\":[");
    json.number(value.x);
    json.character(',');
    json.number(value.y);
    json.raw("]}");
}

static void _transform(JsonWriter& json, const Vec2& position, float opacity)
{
    json.raw("{\"o\":");
    _property(json, opacity);
    json.raw(",\"r\":");
    _property(json, 0.0f);
    json.raw(",\"p\":");
    _vectorProperty(json, position);
    json.raw(",\"a\":");
    _vectorProperty(json, {});
    json.raw(",\"s\":");
    _vectorProperty(json, {100.0f, 100.0f});
    json.character('}');
}

static void _color(JsonWriter& json, const Color& color)
{
    json.character('[');
    json.number(static_cast<float>(color.r) / 255.0f);
    json.character(',');
    json.number(static_cast<float>(color.g) / 255.0f);
    json.character(',');
    json.number(static_cast<float>(color.b) / 255.0f);
    json.raw(",1]");
}

static void _pathData(JsonWriter& json, const Vec2* points, uint32_t count, bool closed,
                      const LottiePlacement& placement)
{
    json.raw("{\"i\":[");
    for (auto i = 0u; i < count; i++) {
        if (i) json.character(',');
        json.raw("[0,0]");
    }
    json.raw("],\"o\":[");
    for (auto i = 0u; i < count; i++) {
        if (i) json.character(',');
        json.raw("[0,0]");
    }
    json.raw("],\"v\":[");
    for (auto i = 0u; i < count; i++) {
        if (i) json.character(',');
        auto value = _point(placement, points[i]);
        json.character('[');
        json.number(value.x);
        json.character(',');
        json.number(value.y);
        json.character(']');
    }
    json.raw("],\"c\":");
    json.raw(closed ? "true}" : "false}");
}

static void _mask(JsonWriter& json, const LottiePlacement& placement, const Vec2& position)
{
    if (!placement.clipped) return;
    Vec2 points[4] = {
        {placement.clip.x - position.x, placement.clip.y - position.y},
        {placement.clip.x + placement.clip.width - position.x,
         placement.clip.y - position.y},
        {placement.clip.x + placement.clip.width - position.x,
         placement.clip.y + placement.clip.height - position.y},
        {placement.clip.x - position.x,
         placement.clip.y + placement.clip.height - position.y}};
    LottiePlacement identity;
    json.raw(",\"hasMask\":true,\"masksProperties\":[{\"inv\":false,\"mode\":\"a\",\"pt\":{\"a\":0,\"k\":");
    _pathData(json, points, 4u, true, identity);
    json.raw("},\"o\":{\"a\":0,\"k\":100},\"x\":{\"a\":0,\"k\":0}}]");
}

static void _fill(JsonWriter& json, const Color& color, float opacity)
{
    json.raw("{\"ty\":\"fl\",\"c\":{\"a\":0,\"k\":");
    _color(json, color);
    json.raw("},\"o\":");
    _property(json, _opacity(color.a, opacity));
    json.raw(",\"r\":1,\"nm\":\"Fill\"}");
}

static void _gradientBounds(const DrawCommand& command, const LottiePlacement& placement,
                            Vec2& from, Vec2& to)
{
    if (command.type == CommandType::Circle) {
        from = {command.center.x - command.radius, command.center.y - command.radius};
        to = {command.center.x + command.radius, command.center.y + command.radius};
    } else if (command.count) {
        if (!command.closed && command.count > 1u) {
            from = command.points[0];
            to = command.points[command.count - 1u];
        }
        if (command.closed || (std::fabs(to.x - from.x) < 1e-6f
                               && std::fabs(to.y - from.y) < 1e-6f)) {
            from = command.points[0];
            to = command.points[0];
            for (auto i = 1u; i < command.count; i++) {
                from.x = std::fmin(from.x, command.points[i].x);
                from.y = std::fmin(from.y, command.points[i].y);
                to.x = std::fmax(to.x, command.points[i].x);
                to.y = std::fmax(to.y, command.points[i].y);
            }
        }
    }
    if (std::fabs(to.x - from.x) < 1e-6f && std::fabs(to.y - from.y) < 1e-6f) {
        to.x = from.x + 1.0f;
    }
    from = _point(placement, from);
    to = _point(placement, to);
}

static void _gradientColors(JsonWriter& json, const Color& start, const Color& end)
{
    json.raw("{\"p\":2,\"k\":{\"a\":0,\"k\":[0,");
    json.number(static_cast<float>(start.r) / 255.0f);
    json.character(',');
    json.number(static_cast<float>(start.g) / 255.0f);
    json.character(',');
    json.number(static_cast<float>(start.b) / 255.0f);
    json.raw(",1,");
    json.number(static_cast<float>(end.r) / 255.0f);
    json.character(',');
    json.number(static_cast<float>(end.g) / 255.0f);
    json.character(',');
    json.number(static_cast<float>(end.b) / 255.0f);
    json.raw("]}}");
}

static void _gradientFill(JsonWriter& json, const DrawCommand& command, float opacity,
                          const LottiePlacement& placement)
{
    Vec2 from;
    Vec2 to;
    _gradientBounds(command, placement, from, to);
    json.raw("{\"ty\":\"gf\",\"o\":");
    _property(json, _opacity(command.style.fill.a, opacity));
    json.raw(",\"r\":1,\"g\":");
    _gradientColors(json, command.style.fill, command.style.gradientEnd);
    json.raw(",\"s\":");
    _vectorProperty(json, from);
    json.raw(",\"e\":");
    _vectorProperty(json, to);
    json.raw(",\"t\":1,\"nm\":\"Gradient Fill\"}");
}

static void _stroke(JsonWriter& json, const DrawCommand& command, float opacity,
                    const LottiePlacement& placement)
{
    auto& style = command.style;
    json.raw("{\"ty\":\"st\",\"c\":{\"a\":0,\"k\":");
    _color(json, style.stroke);
    json.raw("},\"o\":");
    _property(json, _opacity(style.stroke.a, opacity));
    json.raw(",\"w\":");
    _property(json, style.width * _scale(placement));
    json.raw(command.cap == PathCap::Butt ? ",\"lc\":1" : ",\"lc\":2");
    json.raw(",\"lj\":2,\"ml\":4");
    if (style.dashCount) {
        json.raw(",\"d\":[");
        for (auto i = 0u; i < style.dashCount; i++) {
            if (i) json.character(',');
            json.raw("{\"n\":");
            json.string((i & 1u) ? "g" : "d");
            json.raw(",\"v\":");
            _property(json, style.dash[i] * _scale(placement));
            json.character('}');
        }
        json.raw(",{\"n\":\"o\",\"v\":");
        _property(json, style.dashOffset * _scale(placement));
        json.raw("}]");
    }
    json.raw(",\"nm\":\"Stroke\"}");
}

static void _gradientStroke(JsonWriter& json, const DrawCommand& command, float opacity,
                            const LottiePlacement& placement)
{
    Vec2 from;
    Vec2 to;
    _gradientBounds(command, placement, from, to);
    auto& style = command.style;
    json.raw("{\"ty\":\"gs\",\"o\":");
    _property(json, _opacity(style.stroke.a, opacity));
    json.raw(",\"g\":");
    _gradientColors(json, style.stroke, style.gradientEnd);
    json.raw(",\"s\":");
    _vectorProperty(json, from);
    json.raw(",\"e\":");
    _vectorProperty(json, to);
    json.raw(",\"t\":1,\"w\":");
    _property(json, style.width * _scale(placement));
    json.raw(command.cap == PathCap::Butt ? ",\"lc\":1" : ",\"lc\":2");
    json.raw(",\"lj\":2,\"ml\":4");
    if (style.dashCount) {
        json.raw(",\"d\":[");
        for (auto i = 0u; i < style.dashCount; i++) {
            if (i) json.character(',');
            json.raw("{\"n\":");
            json.string((i & 1u) ? "g" : "d");
            json.raw(",\"v\":");
            _property(json, style.dash[i] * _scale(placement));
            json.character('}');
        }
        json.raw(",{\"n\":\"o\",\"v\":");
        _property(json, style.dashOffset * _scale(placement));
        json.raw("}]");
    }
    json.raw(",\"nm\":\"Gradient Stroke\"}");
}

static void _groupTransform(JsonWriter& json)
{
    json.raw("{\"ty\":\"tr\",\"p\":");
    _vectorProperty(json, {});
    json.raw(",\"a\":");
    _vectorProperty(json, {});
    json.raw(",\"s\":");
    _vectorProperty(json, {100.0f, 100.0f});
    json.raw(",\"r\":");
    _property(json, 0.0f);
    json.raw(",\"o\":");
    _property(json, 100.0f);
    json.raw(",\"nm\":\"Transform\"}");
}

static bool _visible(const DrawCommand& command, float opacity)
{
    if (opacity <= 0.0f) return false;
    switch (command.type) {
        case CommandType::Path:
        case CommandType::Circle:
            return command.style.fill.a
                || (command.style.stroke.a && command.style.width > 0.0f);
        case CommandType::Text:
        case CommandType::Number: return command.style.fill.a;
        case CommandType::Svg:
        case CommandType::Image: return command.opacity;
    }
    return false;
}

struct LottieSerializer
{
    JsonWriter& json;
    uint32_t frame = 0;
    uint32_t index = 1;
    uint32_t commandCount = 0;
    bool first = true;

    explicit LottieSerializer(JsonWriter& json) : json(json)
    {
    }

    Result emit(const Scene* scene, float time, const LottiePlacement& placement,
                float opacity) noexcept;

    Result layer(uint8_t type, const char* name, const LottiePlacement& placement,
                 float opacity = 100.0f, const Vec2& position = {}) noexcept
    {
        if (index == UINT32_MAX) return Result::InsufficientCondition;
        if (!first) json.character(',');
        first = false;
        json.raw("{\"ddd\":0,\"ind\":");
        json.number(index++);
        json.raw(",\"ty\":");
        json.number(type);
        json.raw(",\"nm\":");
        json.string(name);
        json.raw(",\"sr\":1,\"ks\":");
        _transform(json, position, opacity);
        _mask(json, placement, position);
        return json.valid ? Result::Success : Result::IoError;
    }

    void timing() noexcept
    {
        json.raw(",\"ao\":0,\"ip\":");
        json.number(frame);
        json.raw(",\"op\":");
        json.number(frame + 1u);
        json.raw(",\"st\":");
        json.number(frame);
        json.raw(",\"bm\":0}");
    }

    Result shape(const DrawCommand& command, const LottiePlacement& placement,
                 float opacity) noexcept
    {
        auto name = command.object && command.object->tag() && command.object->tag()[0]
                  ? command.object->tag()
                  : command.type == CommandType::Circle ? "Circle" : "Path";
        auto result = layer(4u, name, placement);
        if (result != Result::Success) return result;
        json.raw(",\"shapes\":[{\"ty\":\"gr\",\"it\":[");
        if (command.type == CommandType::Path) {
            json.raw("{\"ty\":\"sh\",\"ks\":{\"a\":0,\"k\":");
            _pathData(json, command.points, command.count, command.closed, placement);
            json.raw("},\"nm\":\"Path\"}");
        } else {
            auto center = _point(placement, command.center);
            json.raw("{\"ty\":\"el\",\"d\":1,\"p\":");
            _vectorProperty(json, center);
            json.raw(",\"s\":");
            _vectorProperty(json, {command.radius * 2.0f * std::fabs(placement.sx),
                                   command.radius * 2.0f * std::fabs(placement.sy)});
            json.raw(",\"nm\":\"Ellipse\"}");
        }
        if (command.style.fill.a) {
            json.character(',');
            if (command.style.gradient) _gradientFill(json, command, opacity, placement);
            else _fill(json, command.style.fill, opacity);
        }
        if (command.style.stroke.a && command.style.width > 0.0f) {
            json.character(',');
            if (command.style.gradient) _gradientStroke(json, command, opacity, placement);
            else _stroke(json, command, opacity, placement);
        }
        json.character(',');
        _groupTransform(json);
        json.raw("],\"nm\":");
        json.string(name);
        json.raw("}]");
        timing();
        return json.valid ? Result::Success : Result::IoError;
    }

    Result text(const DrawCommand& command, const char* value,
                const LottiePlacement& placement, float opacity) noexcept
    {
        if (command.transformed) return Result::NonSupport;
        auto name = command.object && command.object->tag() && command.object->tag()[0]
                  ? command.object->tag() : "Text";
        auto alpha = _opacity(command.style.fill.a, opacity);
        auto position = _point(placement, command.center);
        auto size = command.size * _scale(placement);
        auto lines = 1u;
        for (auto cursor = value; *cursor; cursor++) {
            if (*cursor == '\n') lines++;
        }
        auto height = size * (1.0f + static_cast<float>(lines - 1u) * 1.2f);
        position.y -= height * command.align.y;
        auto result = layer(5u, name, placement, alpha, position);
        if (result != Result::Success) return result;
        auto justification = command.align.x >= 0.75f ? 1u : command.align.x > 0.25f ? 2u : 0u;
        json.raw(",\"t\":{\"d\":{\"k\":[{\"s\":{\"s\":");
        json.number(size * (4.0f / 3.0f));
        json.raw(",\"f\":");
        json.string(command.font && command.font[0] ? command.font : "sans-serif");
        json.raw(",\"t\":");
        json.string(value);
        json.raw(",\"j\":");
        json.number(justification);
        json.raw(",\"tr\":0,\"lh\":");
        json.number(size * 1.2f);
        json.raw(",\"ls\":0,\"fc\":");
        _color(json, command.style.fill);
        json.raw("},\"t\":0}]},\"a\":[],\"m\":{\"g\":1,\"a\":{\"a\":0,\"k\":[0,0]}},\"p\":{}}");
        timing();
        return json.valid ? Result::Success : Result::IoError;
    }

    Result command(const DrawCommand& command, const LottiePlacement& placement,
                   float opacity) noexcept
    {
        if (!_visible(command, opacity)) return Result::Success;
        switch (command.type) {
            case CommandType::Path:
            case CommandType::Circle: return shape(command, placement, opacity);
            case CommandType::Text: return text(command, command.text, placement, opacity);
            case CommandType::Number: {
                char value[64];
                auto converted = std::to_chars(value, value + sizeof(value) - 1u,
                                               command.number, std::chars_format::general);
                if (converted.ec != std::errc{}) return Result::Unknown;
                *converted.ptr = '\0';
                return text(command, value, placement, opacity);
            }
            case CommandType::Svg:
            case CommandType::Image: return Result::NonSupport;
        }
        return Result::NonSupport;
    }

    Result commands(const DisplayList& list, const LottiePlacement& placement,
                    float opacity) noexcept
    {
        for (auto i = list.count; i > 0u; i--) {
            auto result = command(list.commands[i - 1u], placement, opacity);
            if (result != Result::Success) return result;
        }
        return Result::Success;
    }

    Result background(const Config& config, const LottiePlacement& placement,
                      float opacity) noexcept
    {
        if (!config.background.a || opacity <= 0.0f) return Result::Success;
        auto result = layer(4u, "Background", placement);
        if (result != Result::Success) return result;
        auto center = _point(placement, {static_cast<float>(config.width) * 0.5f,
                                        static_cast<float>(config.height) * 0.5f});
        json.raw(",\"shapes\":[{\"ty\":\"gr\",\"it\":[{\"ty\":\"rc\",\"p\":");
        _vectorProperty(json, center);
        json.raw(",\"s\":");
        _vectorProperty(json, {static_cast<float>(config.width) * std::fabs(placement.sx),
                               static_cast<float>(config.height) * std::fabs(placement.sy)});
        json.raw(",\"r\":{\"a\":0,\"k\":0},\"nm\":\"Canvas\"},");
        _fill(json, config.background, opacity);
        json.character(',');
        _groupTransform(json);
        json.raw("],\"nm\":\"Background\"}]");
        timing();
        return json.valid ? Result::Success : Result::IoError;
    }

    Result viewports(const Scene* scene, float time, const Config& parentConfig,
                     const LottiePlacement& placement, float opacity) noexcept
    {
        for (auto i = scene->pImpl->viewportCnt; i > 0u; i--) {
            auto& viewport = scene->pImpl->viewports[i - 1u];
            auto childPlacement = _mount(placement, parentConfig,
                                         viewport.scene->pImpl->cfg, viewport.viewport);
            auto result = emit(viewport.scene, time, childPlacement, opacity);
            if (result != Result::Success) return result;
        }
        return Result::Success;
    }

    Result sequence(const Scene* scene, float time, const Config& parentConfig,
                    const LottiePlacement& placement, float opacity) noexcept
    {
        auto sequence = scene->pImpl->sequence;
        if (!sequence || time < sequence->begin) return Result::Success;
        for (auto i = 0u; i < sequence->count; i++) {
            auto& stage = sequence->stages[i];
            if (time < stage.end || i + 1u >= sequence->count) {
                auto childPlacement = _mount(placement, parentConfig,
                                             stage.scene->pImpl->cfg, sequence->viewport);
                return emit(stage.scene, stage.scene->duration(), childPlacement, opacity);
            }
            auto& clip = sequence->transitions[i];
            if (time >= clip.end) continue;
            auto progress = (time - clip.begin) / (clip.end - clip.begin);
            if (progress <= 0.0f) {
                auto childPlacement = _mount(placement, parentConfig,
                                             stage.scene->pImpl->cfg, sequence->viewport);
                return emit(stage.scene, stage.scene->duration(), childPlacement, opacity);
            }
            return transition(stage.scene, sequence->stages[i + 1u].scene, clip,
                              ease(clip.curve, progress), parentConfig, sequence->viewport,
                              placement, opacity);
        }
        return Result::Unknown;
    }

    Result transition(const Scene* from, const Scene* to, const SceneTransition& transition,
                      float progress, const Config& parentConfig, const Viewport& viewport,
                      const LottiePlacement& placement, float opacity) noexcept
    {
        DisplayList first;
        DisplayList second;
        DisplayList blended;
        auto fromTime = from->duration();
        auto toTime = to->duration();
        auto result = from->pImpl->build(fromTime, first, false);
        if (result != Result::Success) return result;
        result = to->pImpl->build(toTime, second, false);
        if (result != Result::Success) return result;
        auto& fromConfig = from->pImpl->cfg;
        auto& toConfig = to->pImpl->cfg;
        result = blended.blend(first, second, transition.matches,
                               from->pImpl->objectCnt, to->pImpl->objectCnt,
                               {static_cast<float>(fromConfig.width), static_cast<float>(fromConfig.height)},
                               {static_cast<float>(toConfig.width), static_cast<float>(toConfig.height)},
                               progress);
        if (result != Result::Success) return result;
        if (blended.count > DISPLAY_COMMAND_LIMIT - commandCount) {
            return Result::InsufficientCondition;
        }
        commandCount += blended.count;

        auto composite = _mount(placement, parentConfig, fromConfig, viewport);
        auto bounded = std::fmax(0.0f, std::fmin(1.0f, progress));
        auto fromOpacity = opacity * (1.0f - bounded);
        auto toOpacity = opacity * bounded;
        result = sequence(to, toTime, fromConfig, composite, toOpacity);
        if (result != Result::Success) return result;
        result = sequence(from, fromTime, fromConfig, composite, fromOpacity);
        if (result != Result::Success) return result;
        result = viewports(to, toTime, fromConfig, composite, toOpacity);
        if (result != Result::Success) return result;
        result = viewports(from, fromTime, fromConfig, composite, fromOpacity);
        if (result != Result::Success) return result;
        result = commands(blended, composite, opacity);
        if (result != Result::Success) return result;
        auto config = fromConfig;
        config.background = _mix(fromConfig.background, toConfig.background, bounded);
        return background(config, composite, opacity);
    }
};

Result LottieSerializer::emit(const Scene* scene, float time,
                              const LottiePlacement& placement, float opacity) noexcept
{
    if (placement.clipped && (placement.clip.width <= 0.0f || placement.clip.height <= 0.0f)) {
        return Result::Success;
    }
    auto& config = scene->pImpl->cfg;
    auto result = sequence(scene, time, config, placement, opacity);
    if (result != Result::Success) return result;
    result = viewports(scene, time, config, placement, opacity);
    if (result != Result::Success) return result;
    DisplayList list;
    result = scene->pImpl->build(time, list);
    if (result != Result::Success) return result;
    if (list.count > DISPLAY_COMMAND_LIMIT - commandCount) {
        return Result::InsufficientCondition;
    }
    commandCount += list.count;
    result = commands(list, placement, opacity);
    if (result != Result::Success) return result;
    return background(config, placement, opacity);
}

static Result _serializeLottie(const Scene* scene, uint32_t fps, uint32_t frames,
                               JsonWriter& json) noexcept
{
    auto& config = scene->config();
    json.raw("{\"v\":\"5.7.4\",\"fr\":");
    json.number(fps);
    json.raw(",\"ip\":0,\"op\":");
    json.number(frames);
    json.raw(",\"w\":");
    json.number(config.width);
    json.raw(",\"h\":");
    json.number(config.height);
    json.raw(",\"nm\":\"TMATH Scene\",\"ddd\":0,\"assets\":[],\"layers\":[");

    LottieSerializer serializer(json);
    LottiePlacement placement;
    placement.clip = {0.0f, 0.0f, static_cast<float>(config.width),
                      static_cast<float>(config.height)};
    auto result = Result::Success;
    for (auto frame = 0u; frame < frames; frame++) {
        serializer.frame = frame;
        serializer.commandCount = 0u;
        auto time = static_cast<float>(frame) / static_cast<float>(fps);
        result = serializer.emit(scene, time, placement, 1.0f);
        if (result != Result::Success) break;
    }
    if (result == Result::Success) {
        json.raw("],\"markers\":[],\"meta\":{\"g\":\"tmath 0.1.0\"}}");
        if (!json.valid) result = json.failure;
    }
    return result;
}

Result Saver::lottie(const Scene* scene, const char* path, uint32_t fps) noexcept
{
    if (!scene || !path || !path[0] || !saver::ends(path, ".json")) {
        return Result::InvalidArguments;
    }
    uint32_t frames;
    auto result = saver::timeline(scene, fps, frames);
    if (result != Result::Success) return result;

    LottieOutput output;
    result = output.open(path);
    if (result != Result::Success) return result;
    JsonWriter json(output.file);
    result = _serializeLottie(scene, fps, frames, json);
    return output.finish(path, result);
}

Result saver::lottie(const Scene* scene, uint32_t fps, uint8_t*& data, uint32_t& size) noexcept
{
    data = nullptr;
    size = 0;
    uint32_t frames;
    auto result = timeline(scene, fps, frames);
    if (result != Result::Success) return result;

    LottieMemoryOutput output;
    JsonWriter json(output);
    result = _serializeLottie(scene, fps, frames, json);
    if (result == Result::Success) data = output.release(size);
    return result;
}

}  // namespace tmath
