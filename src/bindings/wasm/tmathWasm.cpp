#include <cstdarg>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <limits>
#include <new>

#ifdef __EMSCRIPTEN__
#include <emscripten/emscripten.h>
#define TMATH_KEEPALIVE EMSCRIPTEN_KEEPALIVE
#else
#define TMATH_KEEPALIVE
#endif

#include "tmath.h"
#include "tmath_capi.h"
#include "tmathLuaHost.h"
#include "tmathSaver.h"
#if defined(TMATH_AUDIO)
#include "tmath_audio.h"

static_assert(static_cast<uint32_t>(tmath::audio::Bus::Music) == 0u);
static_assert(static_cast<uint32_t>(tmath::audio::Bus::Effect) == 1u);
static_assert(static_cast<uint32_t>(tmath::audio::Bus::Ui) == 2u);
#endif
#if defined(TMATH_UI)
#include "tmath_ui.h"

static_assert(static_cast<uint32_t>(tmath::ui::InputKind::PointerDown) == 0u);
static_assert(static_cast<uint32_t>(tmath::ui::InputKind::PointerMove) == 1u);
static_assert(static_cast<uint32_t>(tmath::ui::InputKind::PointerUp) == 2u);
static_assert(static_cast<uint32_t>(tmath::ui::InputKind::PointerCancel) == 3u);
static_assert(static_cast<uint32_t>(tmath::ui::InputKind::Wheel) == 4u);
static_assert(static_cast<uint32_t>(tmath::ui::InputKind::KeyDown) == 5u);
#endif
#if defined(TMATH_INPUT)
#include "tmath_input.h"

static_assert(static_cast<uint32_t>(tmath::input::InputKind::PointerDown) == 0u);
static_assert(static_cast<uint32_t>(tmath::input::InputKind::KeyDown) == 5u);
static_assert(static_cast<uint32_t>(tmath::input::InputKind::KeyUp) == 6u);
static_assert(static_cast<uint32_t>(tmath::input::Key::ArrowLeft) == 1u);
static_assert(static_cast<uint32_t>(tmath::input::Key::Space) == 5u);
static_assert(static_cast<uint32_t>(tmath::input::Key::A) == 8u);
static_assert(static_cast<uint32_t>(tmath::input::Key::Z) == 33u);
static_assert(static_cast<uint32_t>(tmath::input::Key::Number0) == 34u);
static_assert(static_cast<uint32_t>(tmath::input::Key::Number9) == 43u);
static_assert(static_cast<uint32_t>(tmath::input::Key::Plus) == 44u);
static_assert(static_cast<uint32_t>(tmath::input::Key::Minus) == 45u);
static_assert(static_cast<uint32_t>(tmath::input::Key::Shift) == 46u);
static_assert(static_cast<uint32_t>(tmath::input::Key::Tab) == 47u);
#endif
#if defined(TMATH_LUA_RUNTIME)
#include "tmath_lua_runtime.h"

static_assert(static_cast<uint32_t>(tmath::lua_runtime::SoundBus::Music) == 0u);
static_assert(static_cast<uint32_t>(tmath::lua_runtime::SoundBus::Effect) == 1u);
static_assert(static_cast<uint32_t>(tmath::lua_runtime::SoundBus::Ui) == 2u);
#endif

struct Engine
{
    struct AssetSlot
    {
        char name[257] = {};
        tmath::Asset* asset = nullptr;
    };

    tmath::Scene* scene = nullptr;
    tmath::Renderer* renderer = nullptr;
    tmath::Surface surface;
    char error[1024] = {};
    float renderTime = 0.0f;
    bool rendered = false;
    uint8_t* layoutReport = nullptr;
    uint32_t layoutReportSize = 0;
    AssetSlot assets[64];
    uint32_t assetCount = 0;
    size_t assetBytes = 0;
    tmath::Theme hostTheme;
    bool hasHostTheme = false;
    bool adaptiveTheme = false;
#if defined(TMATH_AUDIO)
    struct AudioVoiceSlot
    {
        tmath::audio::Voice voice;
        uint32_t serial = 0u;
        bool mapped = false;
    };

    tmath::audio::Player* audioPlayer = nullptr;
    tmath::audio::Soundscape* soundscape = nullptr;
    AudioVoiceSlot audioVoices[64];
#endif
#if defined(TMATH_UI)
    tmath::ui::Panel* panel = nullptr;
    tmath::PixelSample uiSample;
    tmath::Vec2 uiSampleValue;
    uint32_t renderPixelRatio = 1u;
    bool uiSampled = false;
#endif
#if defined(TMATH_INPUT)
    tmath::input::Controller* input = nullptr;
    tmath::input::DigitalState inputKey;
    tmath::input::PointerState inputPointer;
#endif
#if defined(TMATH_LUA_RUNTIME)
    tmath::lua_runtime::Runtime* luaRuntime = nullptr;
#endif
};

static constexpr uint32_t TMATH_PIXEL_LIMIT = 67108864;
static constexpr uint32_t TMATH_FONT_LIMIT = 32u * 1024u * 1024u;
static constexpr size_t TMATH_ASSET_MEMORY_LIMIT = 64u * 1024u * 1024u;
static constexpr uint32_t TMATH_ASSET_SOURCE_LIMIT = 32u * 1024u * 1024u;
#if defined(TMATH_AUDIO)
static constexpr uint32_t TMATH_AUDIO_VOICE_LIMIT = 64u;
static constexpr uint32_t TMATH_AUDIO_VOICE_SLOT_BITS = 6u;
static constexpr uint32_t TMATH_AUDIO_VOICE_SLOT_MASK = TMATH_AUDIO_VOICE_LIMIT - 1u;
static constexpr uint32_t TMATH_AUDIO_VOICE_SERIAL_MASK =
    UINT32_MAX >> TMATH_AUDIO_VOICE_SLOT_BITS;
static_assert(TMATH_AUDIO_VOICE_LIMIT == (1u << TMATH_AUDIO_VOICE_SLOT_BITS));
#endif

static Engine* _engine(TMathEngine engine)
{
    return static_cast<Engine*>(engine);
}

#if defined(TMATH_AUDIO)
static tmath::Result _audioPlayer(Engine* engine, tmath::audio::Player*& output)
{
    if (engine->audioPlayer) {
        output = engine->audioPlayer;
        return tmath::Result::Success;
    }
    auto config = tmath::audio::PlayerConfig{};
    config.voiceLimit = TMATH_AUDIO_VOICE_LIMIT;
    auto player = tmath::audio::Player::gen(config);
    if (!player) return tmath::Result::OutOfMemory;
    auto result = player->bind(engine->soundscape);
    if (result != tmath::Result::Success) {
        delete player;
        return result;
    }
    engine->audioPlayer = player;
    output = player;
    return tmath::Result::Success;
}

static uint32_t _audioVoice(Engine::AudioVoiceSlot& slot, uint32_t index)
{
    slot.serial++;
    slot.mapped = true;
    return (slot.serial << TMATH_AUDIO_VOICE_SLOT_BITS) | index;
}

static tmath::Result _audioVoice(Engine* engine, uint32_t handle,
                                Engine::AudioVoiceSlot*& output)
{
    auto serial = handle >> TMATH_AUDIO_VOICE_SLOT_BITS;
    if (!serial) return tmath::Result::InvalidArguments;
    auto index = handle & TMATH_AUDIO_VOICE_SLOT_MASK;
    auto& slot = engine->audioVoices[index];
    if (!slot.mapped || slot.serial != serial) {
        return tmath::Result::InsufficientCondition;
    }
    output = &slot;
    return tmath::Result::Success;
}

static Engine::AudioVoiceSlot* _audioVoiceSlot(Engine* engine,
                                               tmath::audio::Player* player,
                                               uint32_t& output)
{
    for (auto i = 0u; i < TMATH_AUDIO_VOICE_LIMIT; i++) {
        auto& slot = engine->audioVoices[i];
        if (slot.mapped && player->active(slot.voice)) continue;
        slot.mapped = false;
        if (slot.serial == TMATH_AUDIO_VOICE_SERIAL_MASK) continue;
        output = i;
        return &slot;
    }
    return nullptr;
}

static bool _audioBus(uint32_t value, tmath::audio::Bus& output)
{
    if (value > static_cast<uint32_t>(tmath::audio::Bus::Ui)) return false;
    output = static_cast<tmath::audio::Bus>(value);
    return true;
}
#endif

static bool _renderEngine(TMathRenderEngine value, tmath::RenderEngine& output)
{
    switch (value) {
        case TMATH_RENDER_ENGINE_CPU: output = tmath::RenderEngine::Cpu; return true;
        case TMATH_RENDER_ENGINE_GL: output = tmath::RenderEngine::Gl; return true;
    }
    return false;
}

#if defined(TMATH_UI)
static tmath::Result _sample(const tmath::Scene* scene, float time,
                             const tmath::Vec2& position,
                             const tmath::Object* const* candidates, uint32_t count,
                             tmath::PixelSample& output, void* data) noexcept
{
    auto engine = static_cast<Engine*>(data);
    if (!engine || !engine->renderer || engine->scene != scene) {
        return tmath::Result::InvalidArguments;
    }
    return engine->renderer->sample(scene, time, position, candidates, count, output,
                                    engine->renderPixelRatio);
}
#endif

static void _clearLayoutReport(Engine* engine)
{
    delete[] engine->layoutReport;
    engine->layoutReport = nullptr;
    engine->layoutReportSize = 0;
}

struct JsonBuffer
{
    ~JsonBuffer()
    {
        delete[] data;
    }

    bool reserve(uint32_t additional)
    {
        if (additional > UINT32_MAX - size - 1u) return false;
        auto required = size + additional + 1u;
        if (required <= capacity) return true;
        auto next = capacity ? capacity * 2u : 4096u;
        if (next < capacity || next < required) next = required;
        auto grown = new (std::nothrow) uint8_t[next];
        if (!grown) return false;
        if (size) std::memcpy(grown, data, size);
        delete[] data;
        data = grown;
        capacity = next;
        return true;
    }

    bool append(const char* value)
    {
        auto length = std::strlen(value);
        if (length > UINT32_MAX || !reserve(static_cast<uint32_t>(length))) return false;
        std::memcpy(data + size, value, length);
        size += static_cast<uint32_t>(length);
        data[size] = 0;
        return true;
    }

    bool format(const char* format, ...)
    {
        va_list arguments;
        va_start(arguments, format);
        va_list countArguments;
        va_copy(countArguments, arguments);
        auto length = std::vsnprintf(nullptr, 0, format, countArguments);
        va_end(countArguments);
        if (length < 0 || !reserve(static_cast<uint32_t>(length))) {
            va_end(arguments);
            return false;
        }
        std::vsnprintf(reinterpret_cast<char*>(data + size), static_cast<size_t>(length) + 1u,
                       format, arguments);
        va_end(arguments);
        size += static_cast<uint32_t>(length);
        return true;
    }

    bool string(const char* value)
    {
        if (!append("\"")) return false;
        if (value) {
            for (auto cursor = reinterpret_cast<const uint8_t*>(value); *cursor; cursor++) {
                char escaped[7];
                switch (*cursor) {
                    case '\"': if (!append("\\\"")) return false; break;
                    case '\\': if (!append("\\\\")) return false; break;
                    case '\n': if (!append("\\n")) return false; break;
                    case '\r': if (!append("\\r")) return false; break;
                    case '\t': if (!append("\\t")) return false; break;
                    default:
                        if (*cursor < 0x20u) {
                            std::snprintf(escaped, sizeof(escaped), "\\u%04x", *cursor);
                            if (!append(escaped)) return false;
                        } else {
                            if (!reserve(1u)) return false;
                            data[size++] = *cursor;
                            data[size] = 0;
                        }
                        break;
                }
            }
        }
        return append("\"");
    }

    uint8_t* release()
    {
        auto output = data;
        data = nullptr;
        size = 0;
        capacity = 0;
        return output;
    }

    uint8_t* data = nullptr;
    uint32_t size = 0;
    uint32_t capacity = 0;
};

static bool _json(JsonBuffer& json, const tmath::BBox& bounds)
{
    return json.format("{\"x\":%.9g,\"y\":%.9g,\"width\":%.9g,\"height\":%.9g}",
                       bounds.x, bounds.y, bounds.width, bounds.height);
}

static const char* _layoutKind(tmath::LayoutSceneKind kind)
{
    switch (kind) {
        case tmath::LayoutSceneKind::Root: return "root";
        case tmath::LayoutSceneKind::Viewport: return "viewport";
        case tmath::LayoutSceneKind::Transition: return "transition";
    }
    return "unknown";
}

static const char* _layoutVisualKind(tmath::LayoutVisualKind kind)
{
    switch (kind) {
        case tmath::LayoutVisualKind::Stable: return "stable";
        case tmath::LayoutVisualKind::Morph: return "morph";
        case tmath::LayoutVisualKind::FadeOut: return "fade-out";
        case tmath::LayoutVisualKind::FadeIn: return "fade-in";
    }
    return "unknown";
}

static bool _serialize(const tmath::LayoutReport& report, const tmath::Scene* root,
                       JsonBuffer& json)
{
    if (!json.format("{\"time\":%.9g,\"padding\":%.9g,\"width\":%u,\"height\":%u,\"scenes\":[",
                     report.time(), report.padding(), root->config().width, root->config().height)) {
        return false;
    }
    for (auto i = 0u; i < report.sceneCount(); i++) {
        auto scene = report.sceneAt(i);
        if ((i && !json.append(",")) || !json.format("{\"index\":%u,\"path\":", i)
            || !json.string(scene->path) || !json.append(",\"kind\":")
            || !json.string(_layoutKind(scene->kind))) {
            return false;
        }
        if (scene->parent == UINT32_MAX) {
            if (!json.append(",\"parent\":null")) return false;
        } else if (!json.format(",\"parent\":%u", scene->parent)) {
            return false;
        }
        if (!json.format(",\"depth\":%u,\"bounds\":", scene->depth)
            || !_json(json, scene->bounds) || !json.append(",\"clipBounds\":")
            || !_json(json, scene->clipBounds)
            || !json.format(",\"scale\":{\"x\":%.9g,\"y\":%.9g},\"clipped\":%s,\"stretched\":%s}",
                            scene->scaleX, scene->scaleY, scene->clipped ? "true" : "false",
                            scene->stretched ? "true" : "false")) {
            return false;
        }
    }
    if (!json.append("],\"objects\":[")) return false;
    for (auto i = 0u; i < report.objectCount(); i++) {
        auto item = report.objectAt(i);
        auto object = item->object;
        auto scene = report.sceneAt(item->scene);
        if ((i && !json.append(","))
            || !json.format("{\"index\":%u,\"scene\":%u,\"scenePath\":", i, item->scene)
            || !json.string(scene->path)
            || !json.format(",\"handle\":%u,\"id\":", object->id())) {
            return false;
        }
        if (object->tag()) {
            if (!json.string(object->tag())) return false;
        } else if (!json.append("null")) {
            return false;
        }
        if (item->parent == UINT32_MAX) {
            if (!json.append(",\"parent\":null")) return false;
        } else if (!json.format(",\"parent\":%u", item->parent)) {
            return false;
        }
        if (!json.append(",\"type\":") || !json.string(tmath::type(object->type()))
            || !json.format(",\"layer\":%d,\"paintBounds\":", item->layer)) {
            return false;
        }
        auto painted = item->paintBounds.width > 0.0f && item->paintBounds.height > 0.0f;
        if (painted) {
            if (!_json(json, item->paintBounds)) return false;
        } else if (!json.append("null")) {
            return false;
        }
        if (!json.append(",\"familyBounds\":")) return false;
        auto familyPainted = item->familyBounds.width > 0.0f
                          && item->familyBounds.height > 0.0f;
        if (familyPainted) {
            if (!_json(json, item->familyBounds)) return false;
        } else if (!json.append("null")) {
            return false;
        }
        if (!json.append(",\"visibleBounds\":")) return false;
        if (item->visible) {
            if (!_json(json, item->visibleBounds)) return false;
        } else if (!json.append("null")) {
            return false;
        }
        if (!json.append(",\"visibleFamilyBounds\":")) return false;
        if (item->familyVisible) {
            if (!_json(json, item->visibleFamilyBounds)) return false;
        } else if (!json.append("null")) {
            return false;
        }
        if (!json.append(",\"clipBounds\":") || !_json(json, item->clipBounds)
            || !json.format(",\"visible\":%s,\"familyVisible\":%s,\"clipped\":%s,\"familyClipped\":%s,\"outside\":%s,\"familyOutside\":%s}",
                            item->visible ? "true" : "false",
                            item->familyVisible ? "true" : "false",
                            item->clipped ? "true" : "false",
                            item->familyClipped ? "true" : "false",
                            painted && !item->visible ? "true" : "false",
                            familyPainted && !item->familyVisible ? "true" : "false")) {
            return false;
        }
    }
    if (!json.append("],\"visuals\":[")) return false;
    for (auto i = 0u; i < report.visualCount(); i++) {
        auto visual = report.visualAt(i);
        if ((i && !json.append(","))
            || !json.format("{\"index\":%u,\"object\":%u,\"counterpart\":", i,
                            visual->object)) {
            return false;
        }
        if (visual->counterpart == UINT32_MAX) {
            if (!json.append("null")) return false;
        } else if (!json.format("%u", visual->counterpart)) {
            return false;
        }
        if (!json.append(",\"occluder\":")) return false;
        if (visual->occluder == UINT32_MAX) {
            if (!json.append("null")) return false;
        } else if (!json.format("%u", visual->occluder)) {
            return false;
        }
        if (!json.append(",\"kind\":") || !json.string(_layoutVisualKind(visual->kind))
            || !json.format(",\"layer\":%d,\"paintBounds\":", visual->layer)) {
            return false;
        }
        auto painted = visual->paintBounds.width > 0.0f && visual->paintBounds.height > 0.0f;
        if (painted) {
            if (!_json(json, visual->paintBounds)) return false;
        } else if (!json.append("null")) {
            return false;
        }
        if (!json.append(",\"visibleBounds\":")) return false;
        if (visual->visible) {
            if (!_json(json, visual->visibleBounds)) return false;
        } else if (!json.append("null")) {
            return false;
        }
        if (!json.append(",\"clipBounds\":") || !_json(json, visual->clipBounds)
            || !json.format(",\"opacity\":%.9g,\"visible\":%s,\"clipped\":%s,\"occluded\":%s}",
                            visual->opacity, visual->visible ? "true" : "false",
                            visual->clipped ? "true" : "false",
                            visual->occluded ? "true" : "false")) {
            return false;
        }
    }
    if (!json.append("],\"paths\":[")) return false;
    for (auto i = 0u; i < report.pathCount(); i++) {
        auto path = report.pathAt(i);
        if ((i && !json.append(","))
            || !json.format("{\"index\":%u,\"visual\":%u,\"paintBounds\":", i,
                            path->visual)
            || !_json(json, path->paintBounds)
            || !json.format(",\"strokeWidth\":%.9g,\"closed\":%s,\"filled\":%s,"
                            "\"stroked\":%s,\"points\":[",
                            path->strokeWidth, path->closed ? "true" : "false",
                            path->filled ? "true" : "false",
                            path->stroked ? "true" : "false")) {
            return false;
        }
        for (auto j = 0u; j < path->count; j++) {
            if ((j && !json.append(","))
                || !json.format("{\"x\":%.9g,\"y\":%.9g}", path->points[j].x,
                                path->points[j].y)) {
                return false;
            }
        }
        if (!json.append("]}")) return false;
    }
    if (!json.append("],\"collisions\":[")) return false;
    for (auto i = 0u; i < report.collisionCount(); i++) {
        auto collision = report.collisionAt(i);
        if ((i && !json.append(","))
            || !json.format("{\"first\":%u,\"second\":%u,\"kind\":\"%s\",\"overlap\":",
                            collision->first, collision->second,
                            collision->overlapping ? "overlap" : "insufficient-gap")) {
            return false;
        }
        if (collision->overlapping) {
            if (!_json(json, collision->overlap)) return false;
        } else if (!json.append("null")) {
            return false;
        }
        if (!json.format(",\"clearance\":{\"x\":%.9g,\"y\":%.9g},\"separation\":{\"x\":%.9g,\"y\":%.9g}}",
                         collision->clearance.x, collision->clearance.y,
                         collision->separation.x, collision->separation.y)) {
            return false;
        }
    }
    if (!json.append("],\"containments\":[")) return false;
    for (auto i = 0u; i < report.containmentCount(); i++) {
        auto containment = report.containmentAt(i);
        if ((i && !json.append(","))
            || !json.format("{\"container\":%u,\"content\":%u,\"depth\":%u,\"inset\":%.9g,\"contained\":%s,\"overflow\":{\"left\":%.9g,\"top\":%.9g,\"right\":%.9g,\"bottom\":%.9g}}",
                            containment->container, containment->content, containment->depth,
                            containment->inset, containment->contained ? "true" : "false",
                            containment->overflowLeft, containment->overflowTop,
                            containment->overflowRight, containment->overflowBottom)) {
            return false;
        }
    }
    return json.append("]}");
}

static TMathResult _error(Engine* engine, tmath::Result result)
{
    if (engine) std::snprintf(engine->error, sizeof(engine->error), "%s", tmath::result(result));
    return static_cast<TMathResult>(result);
}

#if defined(TMATH_AUDIO)
static TMathResult _audioResult(Engine* engine, tmath::Result result)
{
    if (result != tmath::Result::Success) return _error(engine, result);
    engine->error[0] = '\0';
    return TMATH_RESULT_SUCCESS;
}
#endif

// Retained bytes: the encoded source for decoded-on-render assets, RGBA pixels for raw-pixel assets.
// The lazy RGBA cache that Cell textures request is not counted, which keeps the accounting stable.
static size_t _assetBytes(const tmath::Asset* asset)
{
    if (!asset->encoded()) return _assetBytes(asset);
    return asset->encodedSize();
}

static const tmath::Asset* _asset(const char* name, void* data)
{
    auto engine = static_cast<Engine*>(data);
    for (auto i = 0u; i < engine->assetCount; i++) {
        if (std::strcmp(engine->assets[i].name, name) == 0) return engine->assets[i].asset;
    }
    return nullptr;
}

static tmath::Color _rgba(uint32_t value)
{
    return {
        static_cast<uint8_t>(value >> 24u),
        static_cast<uint8_t>(value >> 16u),
        static_cast<uint8_t>(value >> 8u),
        static_cast<uint8_t>(value),
    };
}

static_assert(static_cast<TMathResult>(tmath::Result::Success) == TMATH_RESULT_SUCCESS);
static_assert(static_cast<TMathResult>(tmath::Result::InvalidArguments) == TMATH_RESULT_INVALID_ARGUMENTS);
static_assert(static_cast<TMathResult>(tmath::Result::InsufficientCondition) == TMATH_RESULT_INSUFFICIENT_CONDITION);
static_assert(static_cast<TMathResult>(tmath::Result::NonSupport) == TMATH_RESULT_NON_SUPPORT);
static_assert(static_cast<TMathResult>(tmath::Result::OutOfMemory) == TMATH_RESULT_OUT_OF_MEMORY);
static_assert(static_cast<TMathResult>(tmath::Result::IoError) == TMATH_RESULT_IO_ERROR);
static_assert(static_cast<TMathResult>(tmath::Result::ScriptError) == TMATH_RESULT_SCRIPT_ERROR);
static_assert(static_cast<TMathResult>(tmath::Result::Unknown) == TMATH_RESULT_UNKNOWN);
static_assert(static_cast<uint8_t>(tmath::RenderEngine::Cpu) == TMATH_RENDER_ENGINE_CPU);
static_assert(static_cast<uint8_t>(tmath::RenderEngine::Gl) == TMATH_RENDER_ENGINE_GL);
static_assert(static_cast<uint8_t>(tmath::CameraMode::Fixed) == TMATH_CAMERA_FIXED);
static_assert(static_cast<uint8_t>(tmath::CameraMode::Interactive) == TMATH_CAMERA_INTERACTIVE);
static_assert(static_cast<uint8_t>(tmath::CameraView::TwoD) == TMATH_CAMERA_VIEW_2D);
static_assert(static_cast<uint8_t>(tmath::CameraView::ThreeD) == TMATH_CAMERA_VIEW_3D);
static_assert(static_cast<uint8_t>(tmath::CameraAction::Pan) == TMATH_CAMERA_PAN);
static_assert(static_cast<uint8_t>(tmath::CameraAction::View3D) == TMATH_CAMERA_SET_3D);

static TMathEngine _create(tmath::Renderer* renderer)
{
    if (!renderer) return nullptr;
    auto engine = new (std::nothrow) Engine;
    if (engine) {
        engine->renderer = renderer;
        return engine;
    }
    delete renderer;
    return nullptr;
}

extern "C" TMATH_KEEPALIVE TMathEngine tmath_create(void)
{
    return _create(tmath::Renderer::gen());
}

extern "C" TMATH_KEEPALIVE TMathEngine tmath_create_with_engine(TMathRenderEngine value)
{
    tmath::RenderEngine engine;
    if (!_renderEngine(value, engine)) return nullptr;
    return _create(tmath::Renderer::gen(engine));
}

extern "C" TMATH_KEEPALIVE TMathResult tmath_default_render_engine_set(TMathRenderEngine value)
{
    tmath::RenderEngine engine;
    if (!_renderEngine(value, engine)) return TMATH_RESULT_INVALID_ARGUMENTS;
    return static_cast<TMathResult>(tmath::Renderer::defaultEngine(engine));
}

extern "C" TMATH_KEEPALIVE TMathRenderEngine tmath_default_render_engine(void)
{
    return static_cast<TMathRenderEngine>(tmath::Renderer::defaultEngine());
}

extern "C" TMATH_KEEPALIVE uint8_t tmath_render_engine_enabled(TMathRenderEngine value)
{
    tmath::RenderEngine engine;
    return _renderEngine(value, engine) && tmath::Renderer::enabled(engine) ? 1u : 0u;
}

extern "C" TMATH_KEEPALIVE TMathRenderEngine tmath_render_engine(TMathEngine handle)
{
    auto engine = _engine(handle);
    if (!engine || !engine->renderer) return TMATH_RENDER_ENGINE_CPU;
    return static_cast<TMathRenderEngine>(engine->renderer->engine());
}

extern "C" TMATH_KEEPALIVE void tmath_destroy(TMathEngine handle)
{
    auto engine = _engine(handle);
    if (!engine) return;
#if defined(TMATH_AUDIO)
    delete engine->audioPlayer;
    for (auto& slot : engine->audioVoices) slot = {};
    engine->soundscape = nullptr;
#endif
    delete engine->scene;
    delete engine->renderer;
    _clearLayoutReport(engine);
    for (auto i = 0u; i < engine->assetCount; i++)
        delete engine->assets[i].asset;
    delete engine;
}

extern "C" TMATH_KEEPALIVE TMathResult tmath_host_theme(TMathEngine handle, uint8_t dark,
                                                          uint32_t background, uint32_t foreground,
                                                          uint32_t muted, uint32_t accent,
                                                          uint32_t secondary, uint32_t success,
                                                          uint32_t warning, uint32_t danger,
                                                          uint32_t info, uint32_t surface,
                                                          uint32_t line, uint32_t result,
                                                          uint32_t focus, const uint32_t* objects,
                                                          uint32_t objectCount)
{
    auto engine = _engine(handle);
    if (!engine || !objects || !objectCount || objectCount > tmath::Theme::ColorLimit) {
        return TMATH_RESULT_INVALID_ARGUMENTS;
    }
    auto theme = tmath::Theme::preset(dark ? tmath::ThemePreset::ProBlack
                                           : tmath::ThemePreset::ProWhite);
    theme.h1.font = "Source Serif 4";
    theme.h2.font = "Source Serif 4";
    theme.h3.font = "Source Serif 4";
    theme.text.font = "Source Serif 4";
    theme.code.font = "Source Serif 4";
    theme.background = _rgba(background);
    theme.h1.color = _rgba(foreground);
    theme.h2.color = _rgba(foreground);
    theme.h3.color = _rgba(foreground);
    theme.text.color = _rgba(muted);
    theme.code.color = _rgba(accent);
    for (auto i = 0u; i < objectCount; i++) theme.objects[i] = _rgba(objects[i]);
    theme.objectCount = objectCount;
    theme.endGradientStop = _rgba(accent);
    theme.axis = {_rgba(line), _rgba(line), _rgba(line), _rgba(line), _rgba(muted)};
    theme.colors = {
        _rgba(foreground),
        _rgba(muted),
        _rgba(accent),
        _rgba(secondary),
        _rgba(success),
        _rgba(warning),
        _rgba(danger),
        _rgba(info),
        _rgba(surface),
        _rgba(line),
        _rgba(result),
        _rgba(focus),
    };
    engine->hostTheme = theme;
    engine->hasHostTheme = true;
    engine->error[0] = '\0';
    return TMATH_RESULT_SUCCESS;
}

extern "C" TMATH_KEEPALIVE uint8_t tmath_adaptive_theme(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine && engine->adaptiveTheme;
}

extern "C" TMATH_KEEPALIVE TMathResult tmath_load_lua(TMathEngine handle, const char* source, uint32_t size,
                                                      const char* name)
{
    auto engine = _engine(handle);
    if (!engine) return TMATH_RESULT_INVALID_ARGUMENTS;
    if (!source || !size) return _error(engine, tmath::Result::InvalidArguments);
    tmath::Scene* scene = nullptr;
    engine->error[0] = '\0';
    bool adaptiveTheme = false;
    tmath::detail::LuaHostContext modules;
    auto result = tmath::detail::luaHostLoad(
        source, size, name ? name : "scene.lua", &scene, engine->error,
        sizeof(engine->error), _asset, engine,
        engine->hasHostTheme ? &engine->hostTheme : nullptr, &adaptiveTheme, modules);
#if defined(TMATH_AUDIO)
    auto soundscape = modules.audio.soundscape;
#endif
#if defined(TMATH_UI)
    auto panel = modules.ui.panel;
    if (result == tmath::Result::Success && !panel) panel = tmath::ui::Panel::gen(scene);
    if (result == tmath::Result::Success && !panel) {
        delete scene;
        return _error(engine, tmath::Result::OutOfMemory);
    }
    if (result == tmath::Result::Success
        && panel->sampler(_sample, engine) != tmath::Result::Success) {
        delete scene;
        return _error(engine, tmath::Result::Unknown);
    }
#endif
#if defined(TMATH_INPUT)
    auto input = modules.input.controller;
    if (result == tmath::Result::Success && !input) {
        input = tmath::input::Controller::gen(scene);
    }
    if (result == tmath::Result::Success && !input) {
        delete scene;
        return _error(engine, tmath::Result::OutOfMemory);
    }
#endif
#if defined(TMATH_LUA_RUNTIME)
    auto luaRuntime = modules.runtime.runtime;
#if defined(TMATH_INPUT)
    if (result == tmath::Result::Success && luaRuntime
        && luaRuntime->input(input->state()) != tmath::Result::Success) {
        delete scene;
        return _error(engine, tmath::Result::Unknown);
    }
#endif
#endif
    if (result != tmath::Result::Success) return static_cast<TMathResult>(result);
    auto& config = scene->config();
    if (config.height > TMATH_PIXEL_LIMIT / config.width) {
        delete scene;
        return _error(engine, tmath::Result::InvalidArguments);
    }
#if defined(TMATH_AUDIO)
    if (engine->audioPlayer) {
        result = engine->audioPlayer->bind(soundscape);
        if (result != tmath::Result::Success) {
            delete scene;
            return _error(engine, result);
        }
    }
#endif
    delete engine->scene;
    engine->scene = scene;
#if defined(TMATH_AUDIO)
    engine->soundscape = soundscape;
#endif
#if defined(TMATH_UI)
    engine->panel = panel;
    engine->uiSample = {};
    engine->uiSampleValue = {};
    engine->renderPixelRatio = 1u;
    engine->uiSampled = false;
#endif
#if defined(TMATH_INPUT)
    engine->input = input;
    engine->inputKey = {};
    engine->inputPointer = {};
#endif
#if defined(TMATH_LUA_RUNTIME)
    engine->luaRuntime = luaRuntime;
#endif
    engine->adaptiveTheme = adaptiveTheme;
    engine->rendered = false;
    _clearLayoutReport(engine);
    return TMATH_RESULT_SUCCESS;
}

extern "C" TMATH_KEEPALIVE TMathResult tmath_load_font(TMathEngine handle, const char* name, const uint8_t* data,
                                                       uint32_t size, const char* mime)
{
    auto engine = _engine(handle);
    if (!engine) return TMATH_RESULT_INVALID_ARGUMENTS;
    if (!engine->renderer || !name || !name[0] || !data || !size || size > TMATH_FONT_LIMIT || !mime || !mime[0]) {
        return _error(engine, tmath::Result::InvalidArguments);
    }
    auto result = engine->renderer->font(name, data, size, mime);
    if (result != tmath::Result::Success) return _error(engine, result);
    _clearLayoutReport(engine);
    engine->error[0] = '\0';
    return static_cast<TMathResult>(result);
}

extern "C" TMATH_KEEPALIVE TMathResult tmath_load_asset(TMathEngine handle, const char* name,
                                                        const uint8_t* data, uint32_t size,
                                                        const char* mime)
{
    auto engine = _engine(handle);
    if (!engine) return TMATH_RESULT_INVALID_ARGUMENTS;
    auto nameSize = name ? std::strlen(name) : 0u;
    if (!nameSize || nameSize > 256u || !data || !size || size > TMATH_ASSET_SOURCE_LIMIT || !mime || !mime[0]) {
        return _error(engine, tmath::Result::InvalidArguments);
    }
    tmath::Asset* asset = nullptr;
    auto result = tmath::AssetLoader::load(data, size, mime, asset);
    if (result != tmath::Result::Success) return _error(engine, result);
    auto bytes = _assetBytes(asset);
    auto index = engine->assetCount;
    for (auto i = 0u; i < engine->assetCount; i++) {
        if (std::strcmp(engine->assets[i].name, name) == 0) {
            index = i;
            break;
        }
    }
    auto retained = engine->assetBytes;
    if (index < engine->assetCount) {
        retained -= _assetBytes(engine->assets[index].asset);
    }
    if (bytes > TMATH_ASSET_MEMORY_LIMIT - retained || (index == engine->assetCount && engine->assetCount >= 64u)) {
        delete asset;
        return _error(engine, tmath::Result::OutOfMemory);
    }
    if (index == engine->assetCount) engine->assetCount++;
    else {
        engine->assetBytes -= _assetBytes(engine->assets[index].asset);
        delete engine->assets[index].asset;
    }
    std::memcpy(engine->assets[index].name, name, nameSize + 1u);
    engine->assets[index].asset = asset;
    engine->assetBytes += _assetBytes(asset);
    engine->error[0] = '\0';
    return TMATH_RESULT_SUCCESS;
}

static TMathResult _render(Engine* engine, float time, uint32_t pixelRatio)
{
    if (!engine->scene || !engine->renderer) return _error(engine, tmath::Result::InsufficientCondition);
    auto& config = engine->scene->config();
    if (!pixelRatio || config.width > UINT32_MAX / pixelRatio
        || config.height > UINT32_MAX / pixelRatio) {
        return _error(engine, tmath::Result::InvalidArguments);
    }
    auto width = config.width * pixelRatio;
    auto height = config.height * pixelRatio;
    if (height > TMATH_PIXEL_LIMIT / width) {
        return _error(engine, tmath::Result::InvalidArguments);
    }
    engine->rendered = false;
    auto result = engine->renderer->render(engine->scene, time, engine->surface, pixelRatio);
    if (result != tmath::Result::Success) return _error(engine, result);
    engine->rendered = true;
    engine->renderTime = time;
#if defined(TMATH_UI)
    engine->renderPixelRatio = pixelRatio;
#endif
    engine->error[0] = '\0';
    return static_cast<TMathResult>(result);
}

extern "C" TMATH_KEEPALIVE TMathResult tmath_render(TMathEngine handle, float time)
{
    auto engine = _engine(handle);
    return engine ? _render(engine, time, 1u) : TMATH_RESULT_INVALID_ARGUMENTS;
}

extern "C" TMATH_KEEPALIVE TMathResult tmath_render_scaled(TMathEngine handle, float time,
                                                            uint32_t pixelRatio)
{
    auto engine = _engine(handle);
    return engine ? _render(engine, time, pixelRatio) : TMATH_RESULT_INVALID_ARGUMENTS;
}

extern "C" TMATH_KEEPALIVE TMathResult tmath_render_gl(TMathEngine handle, float time,
                                                         const TMathGlTarget* target)
{
    auto engine = _engine(handle);
    if (!engine) return TMATH_RESULT_INVALID_ARGUMENTS;
    if (!target) return _error(engine, tmath::Result::InvalidArguments);
    if (!engine->scene || !engine->renderer) {
        return _error(engine, tmath::Result::InsufficientCondition);
    }
    tmath::GlTarget output = {
        target->display,
        target->surface,
        target->context,
        target->id,
        target->width,
        target->height,
    };
    engine->rendered = false;
    auto result = engine->renderer->render(engine->scene, time, output);
    if (result != tmath::Result::Success) return _error(engine, result);
    engine->rendered = true;
    engine->renderTime = time;
    engine->error[0] = '\0';
    return TMATH_RESULT_SUCCESS;
}

extern "C" TMATH_KEEPALIVE TMathResult tmath_bounds(TMathEngine handle, const char* object, float time,
                                                     TMathBBox* output)
{
    auto engine = _engine(handle);
    if (!engine) return TMATH_RESULT_INVALID_ARGUMENTS;
    if (!engine->scene || !engine->renderer || !object || !object[0] || !output) {
        return _error(engine, tmath::Result::InvalidArguments);
    }
    auto target = engine->scene->object(object);
    if (!target) return _error(engine, tmath::Result::InvalidArguments);
    tmath::BBox bounds;
    auto result = engine->renderer->bounds(engine->scene, target, time, bounds);
    if (result != tmath::Result::Success) return _error(engine, result);
    *output = {bounds.x, bounds.y, bounds.width, bounds.height};
    engine->error[0] = '\0';
    return TMATH_RESULT_SUCCESS;
}

extern "C" TMATH_KEEPALIVE TMathResult tmath_intersects(TMathEngine handle, const char* first,
                                                         const char* second, float time, float padding,
                                                         uint8_t* output)
{
    auto engine = _engine(handle);
    if (!engine) return TMATH_RESULT_INVALID_ARGUMENTS;
    if (!engine->scene || !engine->renderer || !first || !first[0] || !second || !second[0] || !output) {
        return _error(engine, tmath::Result::InvalidArguments);
    }
    auto firstObject = engine->scene->object(first);
    auto secondObject = engine->scene->object(second);
    if (!firstObject || !secondObject) return _error(engine, tmath::Result::InvalidArguments);
    auto intersects = false;
    auto result = engine->renderer->intersects(engine->scene, firstObject, secondObject, time,
                                                intersects, padding);
    if (result != tmath::Result::Success) return _error(engine, result);
    *output = intersects ? 1u : 0u;
    engine->error[0] = '\0';
    return TMATH_RESULT_SUCCESS;
}

extern "C" TMATH_KEEPALIVE TMathResult tmath_layout_report(TMathEngine handle, float time,
                                                             float padding)
{
    auto engine = _engine(handle);
    if (!engine) return TMATH_RESULT_INVALID_ARGUMENTS;
    if (!engine->scene || !engine->renderer) {
        return _error(engine, tmath::Result::InsufficientCondition);
    }
    tmath::LayoutReport report;
    auto result = engine->renderer->layout(engine->scene, time, report, padding);
    if (result != tmath::Result::Success) return _error(engine, result);
    JsonBuffer json;
    if (!_serialize(report, engine->scene, json)) {
        return _error(engine, tmath::Result::OutOfMemory);
    }
    auto size = json.size;
    auto data = json.release();
    _clearLayoutReport(engine);
    engine->layoutReport = data;
    engine->layoutReportSize = size;
    engine->error[0] = '\0';
    return TMATH_RESULT_SUCCESS;
}

extern "C" TMATH_KEEPALIVE const uint8_t* tmath_layout_report_data(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine ? engine->layoutReport : nullptr;
}

extern "C" TMATH_KEEPALIVE uint32_t tmath_layout_report_size(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine ? engine->layoutReportSize : 0u;
}

extern "C" TMATH_KEEPALIVE TMathResult tmath_resize(TMathEngine handle, uint32_t width, uint32_t height)
{
    auto engine = _engine(handle);
    if (!engine) return TMATH_RESULT_INVALID_ARGUMENTS;
    if (!engine->scene || !width || !height || height > TMATH_PIXEL_LIMIT / width) {
        return _error(engine, tmath::Result::InvalidArguments);
    }
    engine->scene->config().width = width;
    engine->scene->config().height = height;
    engine->rendered = false;
    _clearLayoutReport(engine);
    engine->error[0] = '\0';
    return TMATH_RESULT_SUCCESS;
}

#if !defined(__EMSCRIPTEN__) || defined(TMATH_UI) || defined(TMATH_INPUT)
extern "C" TMATH_KEEPALIVE TMathResult tmath_camera(TMathEngine handle, TMathCameraAction action, float x, float y)
{
    auto engine = _engine(handle);
    if (!engine) return TMATH_RESULT_INVALID_ARGUMENTS;
    if (!engine->scene || action < TMATH_CAMERA_PAN || action > TMATH_CAMERA_SET_3D) {
        return _error(engine, tmath::Result::InvalidArguments);
    }
#if defined(TMATH_INPUT)
    if (!engine->input || engine->scene->config().cameraMode != tmath::CameraMode::Interactive) {
        return _error(engine, tmath::Result::InsufficientCondition);
    }
    tmath::Result result;
    switch (action) {
        case TMATH_CAMERA_PAN: result = engine->input->cameraMove({x, y}); break;
        case TMATH_CAMERA_ORBIT: result = engine->input->cameraOrbit({x, y}); break;
        case TMATH_CAMERA_ZOOM: result = engine->input->cameraZoom(y); break;
        case TMATH_CAMERA_RESET: result = engine->input->cameraReset(); break;
        case TMATH_CAMERA_SET_2D: result = engine->input->cameraView(tmath::CameraView::TwoD); break;
        case TMATH_CAMERA_SET_3D: result = engine->input->cameraView(tmath::CameraView::ThreeD); break;
    }
#elif defined(TMATH_UI)
    if (!engine->panel || engine->scene->config().cameraMode != tmath::CameraMode::Interactive) {
        return _error(engine, tmath::Result::InsufficientCondition);
    }
    tmath::Result result;
    switch (action) {
        case TMATH_CAMERA_PAN: result = engine->panel->cameraMove({x, y}); break;
        case TMATH_CAMERA_ORBIT: result = engine->panel->cameraOrbit({x, y}); break;
        case TMATH_CAMERA_ZOOM: result = engine->panel->cameraZoom(y); break;
        case TMATH_CAMERA_RESET: result = engine->panel->cameraReset(); break;
        case TMATH_CAMERA_SET_2D: result = engine->panel->cameraView(tmath::CameraView::TwoD); break;
        case TMATH_CAMERA_SET_3D: result = engine->panel->cameraView(tmath::CameraView::ThreeD); break;
    }
#else
    auto result = engine->scene->camera({static_cast<tmath::CameraAction>(action), {x, y}});
#endif
    if (result != tmath::Result::Success) return _error(engine, result);
    engine->rendered = false;
    _clearLayoutReport(engine);
    engine->error[0] = '\0';
    return TMATH_RESULT_SUCCESS;
}
#endif

#if defined(TMATH_UI) || defined(TMATH_INPUT)
extern "C" TMATH_KEEPALIVE uint32_t tmath_input(TMathEngine handle, uint32_t type,
                                                  float x, float y, float dx, float dy,
                                                  float wheelX, float wheelY, int32_t button,
                                                  uint32_t buttons, uint32_t modifiers,
                                                  uint32_t pointer, uint32_t key,
                                                  uint8_t repeat, float time)
{
    auto engine = _engine(handle);
#if defined(TMATH_UI)
    if (engine) engine->uiSampled = false;
#endif
    if (!engine || !engine->scene || type > 6u
        || !std::isfinite(x) || !std::isfinite(y) || !std::isfinite(dx)
        || !std::isfinite(dy) || !std::isfinite(wheelX) || !std::isfinite(wheelY)
        || !std::isfinite(time) || time < 0.0f) {
        return 0u;
    }
    constexpr uint32_t Handled = 1u;
    constexpr uint32_t Redraw = 2u;
    constexpr uint32_t Capture = 4u;
    constexpr uint32_t Release = 8u;
#if defined(TMATH_UI)
    constexpr uint32_t Sampled = 16u;
#endif
    constexpr uint32_t Failed = 32u;
    uint32_t flags = 0u;
#if !defined(TMATH_INPUT)
    (void) key;
    (void) repeat;
#endif
#if defined(TMATH_UI)
    if (engine->panel && type <= 5u
#if defined(TMATH_INPUT)
        && type != static_cast<uint32_t>(tmath::ui::InputKind::KeyDown)
#endif
    ) {
        tmath::ui::InputEvent event;
        event.kind = static_cast<tmath::ui::InputKind>(type);
        event.pointer = pointer;
        event.position = {x, y};
        event.delta = {dx, dy};
        event.wheel = {wheelX, wheelY};
        event.button = button;
        event.buttons = buttons;
        event.modifiers = modifiers;
        event.time = time;
        auto input = engine->panel->input(event);
        if (input.handled) flags |= Handled;
        if (input.redraw) flags |= Redraw;
        if (input.capture) flags |= Capture;
        if (input.release) flags |= Release;
        if (input.status != tmath::Result::Success) {
            _error(engine, input.status);
            flags |= Failed;
        }
        if (input.sample && input.sample->selected()) {
            engine->uiSample = input.sample->selection();
            engine->uiSampleValue = input.sample->value();
            engine->uiSampled = true;
            flags |= Sampled;
        }
    }
#endif
#if defined(TMATH_INPUT)
    if ((!(flags & Handled)
         || type == static_cast<uint32_t>(tmath::input::InputKind::PointerCancel))
        && engine->input) {
        tmath::input::InputEvent event;
        event.kind = static_cast<tmath::input::InputKind>(type);
        event.key = static_cast<tmath::input::Key>(key);
        event.pointer = pointer;
        event.position = {x, y};
        event.delta = {dx, dy};
        event.wheel = {wheelX, wheelY};
        event.button = button;
        event.buttons = buttons;
        event.modifiers = modifiers;
        event.time = time;
        event.repeat = repeat != 0u;
        auto input = engine->input->input(event);
        if (input.handled) flags |= Handled;
        if (input.redraw) flags |= Redraw;
        if (input.status != tmath::Result::Success) {
            _error(engine, input.status);
            flags |= Failed;
        }
    }
#if defined(TMATH_LUA_RUNTIME)
    if (engine->luaRuntime) {
        auto claimed = engine->luaRuntime->claimsPointer(pointer);
        if ((type == static_cast<uint32_t>(tmath::input::InputKind::KeyDown)
             || type == static_cast<uint32_t>(tmath::input::InputKind::KeyUp))
            && engine->luaRuntime->claimsKey(key)) {
            flags |= Handled;
        } else if (type == static_cast<uint32_t>(tmath::input::InputKind::PointerDown)
                   && button >= 0 && button < 32
                   && (claimed & (1u << button))) {
            flags |= Handled | Capture;
        } else if (type == static_cast<uint32_t>(tmath::input::InputKind::PointerMove)
                   && (claimed & buttons)) {
            flags |= Handled;
        } else if (type == static_cast<uint32_t>(tmath::input::InputKind::PointerUp)
                   && button >= 0 && button < 32
                   && (claimed & (1u << button))) {
            flags |= Handled | Release;
        } else if (type == static_cast<uint32_t>(tmath::input::InputKind::PointerCancel)
                   && claimed) {
            flags |= Handled | Release;
        }
    }
#endif
#endif
    if (flags & Redraw) {
        engine->rendered = false;
        _clearLayoutReport(engine);
    }
    return flags;
}
#endif

#if defined(TMATH_INPUT)
extern "C" TMATH_KEEPALIVE TMathResult tmath_input_begin(TMathEngine handle, float time)
{
    auto engine = _engine(handle);
    if (!engine || !engine->scene || !engine->input || !std::isfinite(time)
        || time < 0.0f) {
        return TMATH_RESULT_INVALID_ARGUMENTS;
    }
    auto result = engine->input->state()->begin(time);
    if (result != tmath::Result::Success) return _error(engine, result);
    engine->inputKey = {};
    engine->inputPointer = {};
    engine->error[0] = '\0';
    return TMATH_RESULT_SUCCESS;
}

extern "C" TMATH_KEEPALIVE uint32_t tmath_input_release(TMathEngine handle, float time)
{
    auto engine = _engine(handle);
    if (!engine || !engine->scene || !engine->input || !std::isfinite(time)
        || time < 0.0f) {
        return 32u;
    }
    auto result = engine->input->release(time);
    auto flags = (result.handled ? 1u : 0u) | (result.redraw ? 2u : 0u);
    if (result.status != tmath::Result::Success) {
        _error(engine, result.status);
        return flags | 32u;
    }
    if (result.redraw) {
        engine->rendered = false;
        _clearLayoutReport(engine);
    }
    engine->inputKey = {};
    engine->inputPointer = {};
    engine->error[0] = '\0';
    return flags;
}

extern "C" TMATH_KEEPALIVE uint32_t tmath_input_key_state(TMathEngine handle,
                                                            uint32_t key)
{
    auto engine = _engine(handle);
    if (!engine || !engine->scene || !engine->input || key == 0u
        || key > static_cast<uint32_t>(tmath::input::Key::Tab)) {
        return UINT32_MAX;
    }
    auto result = engine->input->state()->key(static_cast<tmath::input::Key>(key),
                                               engine->inputKey);
    if (result != tmath::Result::Success) {
        _error(engine, result);
        return UINT32_MAX;
    }
    engine->error[0] = '\0';
    return (engine->inputKey.previous ? 1u : 0u)
         | (engine->inputKey.down ? 2u : 0u)
         | (engine->inputKey.pressed ? 4u : 0u)
         | (engine->inputKey.released ? 8u : 0u);
}

extern "C" TMATH_KEEPALIVE float tmath_input_key_begin(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine ? engine->inputKey.begin : 0.0f;
}

extern "C" TMATH_KEEPALIVE float tmath_input_key_end(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine ? engine->inputKey.end : 0.0f;
}

extern "C" TMATH_KEEPALIVE uint32_t tmath_input_pointer_state(TMathEngine handle,
                                                                uint32_t pointer)
{
    auto engine = _engine(handle);
    if (!engine || !engine->scene || !engine->input) return UINT32_MAX;
    auto result = engine->input->state()->pointer(pointer, engine->inputPointer);
    if (result == tmath::Result::InsufficientCondition) {
        engine->inputPointer = {};
        engine->error[0] = '\0';
        return 0u;
    }
    if (result != tmath::Result::Success) {
        _error(engine, result);
        return UINT32_MAX;
    }
    engine->error[0] = '\0';
    return 1u | (engine->inputPointer.active ? 2u : 0u);
}

extern "C" TMATH_KEEPALIVE float tmath_input_pointer_x(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine ? engine->inputPointer.position.x : 0.0f;
}

extern "C" TMATH_KEEPALIVE float tmath_input_pointer_y(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine ? engine->inputPointer.position.y : 0.0f;
}

extern "C" TMATH_KEEPALIVE float tmath_input_pointer_dx(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine ? engine->inputPointer.delta.x : 0.0f;
}

extern "C" TMATH_KEEPALIVE float tmath_input_pointer_dy(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine ? engine->inputPointer.delta.y : 0.0f;
}

extern "C" TMATH_KEEPALIVE float tmath_input_pointer_wheel_x(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine ? engine->inputPointer.wheel.x : 0.0f;
}

extern "C" TMATH_KEEPALIVE float tmath_input_pointer_wheel_y(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine ? engine->inputPointer.wheel.y : 0.0f;
}

extern "C" TMATH_KEEPALIVE uint32_t tmath_input_pointer_previous_buttons(
    TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine ? engine->inputPointer.previousButtons : 0u;
}

extern "C" TMATH_KEEPALIVE uint32_t tmath_input_pointer_buttons(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine ? engine->inputPointer.buttons : 0u;
}

extern "C" TMATH_KEEPALIVE uint32_t tmath_input_pointer_pressed(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine ? engine->inputPointer.pressed : 0u;
}

extern "C" TMATH_KEEPALIVE uint32_t tmath_input_pointer_released(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine ? engine->inputPointer.released : 0u;
}
#endif

#if defined(TMATH_LUA_RUNTIME)
extern "C" TMATH_KEEPALIVE uint8_t tmath_runtime_active(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine && engine->luaRuntime ? 1u : 0u;
}

extern "C" TMATH_KEEPALIVE TMathResult tmath_runtime_advance(TMathEngine handle,
                                                              float elapsed)
{
    auto engine = _engine(handle);
    if (!engine || !engine->scene || !engine->luaRuntime) {
        return TMATH_RESULT_INSUFFICIENT_CONDITION;
    }
    auto result = engine->luaRuntime->advance(elapsed);
    if (engine->luaRuntime->steps()) {
        engine->rendered = false;
        _clearLayoutReport(engine);
    }
    if (result != tmath::Result::Success) {
        auto message = engine->luaRuntime->error();
        if (message && message[0]) {
            std::snprintf(engine->error, sizeof(engine->error), "%s", message);
        } else {
            _error(engine, result);
        }
        return static_cast<TMathResult>(result);
    }
    engine->error[0] = '\0';
    return TMATH_RESULT_SUCCESS;
}

extern "C" TMATH_KEEPALIVE double tmath_runtime_time(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine && engine->luaRuntime ? engine->luaRuntime->time() : 0.0;
}

extern "C" TMATH_KEEPALIVE double tmath_runtime_dropped(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine && engine->luaRuntime ? engine->luaRuntime->dropped() : 0.0;
}

extern "C" TMATH_KEEPALIVE double tmath_runtime_tick(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine && engine->luaRuntime
               ? static_cast<double>(engine->luaRuntime->tick()) : 0.0;
}

extern "C" TMATH_KEEPALIVE uint32_t tmath_runtime_steps(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine && engine->luaRuntime ? engine->luaRuntime->steps() : 0u;
}

extern "C" TMATH_KEEPALIVE float tmath_runtime_interpolation(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine && engine->luaRuntime
               ? engine->luaRuntime->interpolation() : 0.0f;
}

extern "C" TMATH_KEEPALIVE uint32_t tmath_runtime_sound_count(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine && engine->luaRuntime ? engine->luaRuntime->soundCount() : 0u;
}

extern "C" TMATH_KEEPALIVE TMathResult tmath_runtime_sound(
    TMathEngine handle, uint32_t index, char* asset, uint32_t assetSize,
    uint32_t* bus, float* gain, float* rate, uint8_t* loop)
{
    auto engine = _engine(handle);
    if (!engine || !engine->luaRuntime || !asset || !assetSize || !bus
        || !gain || !rate || !loop) {
        return TMATH_RESULT_INVALID_ARGUMENTS;
    }
    tmath::lua_runtime::SoundEvent event;
    if (!engine->luaRuntime->soundAt(index, event)) {
        return TMATH_RESULT_INSUFFICIENT_CONDITION;
    }
    auto length = std::strlen(event.asset);
    if (length >= assetSize) return TMATH_RESULT_INVALID_ARGUMENTS;
    std::memcpy(asset, event.asset, length + 1u);
    *bus = static_cast<uint32_t>(event.bus);
    *gain = event.gain;
    *rate = event.rate;
    *loop = event.loop ? 1u : 0u;
    return TMATH_RESULT_SUCCESS;
}
#endif

#if defined(TMATH_AUDIO)
extern "C" TMATH_KEEPALIVE uint8_t tmath_audio_supported(TMathEngine handle)
{
    return _engine(handle) ? 1u : 0u;
}

extern "C" TMATH_KEEPALIVE TMathResult tmath_audio_load(TMathEngine handle,
                                                          const char* name,
                                                          const uint8_t* data,
                                                          uint32_t size)
{
    auto engine = _engine(handle);
    if (!engine) return TMATH_RESULT_INVALID_ARGUMENTS;
    tmath::audio::Player* player = nullptr;
    auto result = _audioPlayer(engine, player);
    if (result == tmath::Result::Success) result = player->load(name, data, size);
    return _audioResult(engine, result);
}

extern "C" TMATH_KEEPALIVE TMathResult tmath_audio_start(TMathEngine handle)
{
    auto engine = _engine(handle);
    if (!engine) return TMATH_RESULT_INVALID_ARGUMENTS;
    tmath::audio::Player* player = nullptr;
    auto result = _audioPlayer(engine, player);
    if (result == tmath::Result::Success) result = player->start();
    return _audioResult(engine, result);
}

extern "C" TMATH_KEEPALIVE TMathResult tmath_audio_play(TMathEngine handle,
                                                          const char* asset,
                                                          uint32_t bus,
                                                          float gain,
                                                          float rate,
                                                          uint8_t loop,
                                                          uint32_t* output)
{
    auto engine = _engine(handle);
    if (output) *output = 0u;
    tmath::audio::Bus targetBus;
    if (!engine || !output || loop > 1u || !_audioBus(bus, targetBus)) {
        return engine ? _error(engine, tmath::Result::InvalidArguments)
                      : TMATH_RESULT_INVALID_ARGUMENTS;
    }
    tmath::audio::Player* player = nullptr;
    auto result = _audioPlayer(engine, player);
    if (result != tmath::Result::Success) return _error(engine, result);
    auto index = 0u;
    auto slot = _audioVoiceSlot(engine, player, index);
    if (!slot) return _error(engine, tmath::Result::InsufficientCondition);
    auto playback = tmath::audio::Playback{};
    playback.asset = asset;
    playback.bus = targetBus;
    playback.gain = gain;
    playback.rate = rate;
    playback.loop = loop != 0u;
    result = player->play(playback, &slot->voice);
    if (result != tmath::Result::Success) return _error(engine, result);
    *output = _audioVoice(*slot, index);
    return _audioResult(engine, result);
}

extern "C" TMATH_KEEPALIVE TMathResult tmath_audio_stop(TMathEngine handle,
                                                          uint32_t voice)
{
    auto engine = _engine(handle);
    if (!engine) return TMATH_RESULT_INVALID_ARGUMENTS;
    if (!engine->audioPlayer) {
        return _error(engine, tmath::Result::InsufficientCondition);
    }
    Engine::AudioVoiceSlot* slot = nullptr;
    auto result = _audioVoice(engine, voice, slot);
    if (result != tmath::Result::Success) return _error(engine, result);
    result = engine->audioPlayer->stop(slot->voice);
    slot->mapped = false;
    return _audioResult(engine, result);
}

extern "C" TMATH_KEEPALIVE uint8_t tmath_audio_active(TMathEngine handle,
                                                        uint32_t voice)
{
    auto engine = _engine(handle);
    if (!engine || !engine->audioPlayer) return 0u;
    Engine::AudioVoiceSlot* slot = nullptr;
    if (_audioVoice(engine, voice, slot) != tmath::Result::Success) return 0u;
    if (engine->audioPlayer->active(slot->voice)) return 1u;
    slot->mapped = false;
    return 0u;
}

extern "C" TMATH_KEEPALIVE TMathResult tmath_audio_master_gain(TMathEngine handle,
                                                                 float gain)
{
    auto engine = _engine(handle);
    if (!engine) return TMATH_RESULT_INVALID_ARGUMENTS;
    tmath::audio::Player* player = nullptr;
    auto result = _audioPlayer(engine, player);
    if (result == tmath::Result::Success) result = player->gain(gain);
    return _audioResult(engine, result);
}

extern "C" TMATH_KEEPALIVE TMathResult tmath_audio_bus_gain(TMathEngine handle,
                                                              uint32_t bus,
                                                              float gain)
{
    auto engine = _engine(handle);
    tmath::audio::Bus targetBus;
    if (!engine || !_audioBus(bus, targetBus)) {
        return engine ? _error(engine, tmath::Result::InvalidArguments)
                      : TMATH_RESULT_INVALID_ARGUMENTS;
    }
    tmath::audio::Player* player = nullptr;
    auto result = _audioPlayer(engine, player);
    if (result == tmath::Result::Success) result = player->gain(targetBus, gain);
    return _audioResult(engine, result);
}

extern "C" TMATH_KEEPALIVE TMathResult tmath_audio_transport(TMathEngine handle,
                                                               float time,
                                                               float rate,
                                                               uint8_t playing,
                                                               uint8_t seek)
{
    auto engine = _engine(handle);
    if (!engine || playing > 1u || seek > 1u) {
        return engine ? _error(engine, tmath::Result::InvalidArguments)
                      : TMATH_RESULT_INVALID_ARGUMENTS;
    }
    tmath::audio::Player* player = nullptr;
    auto result = _audioPlayer(engine, player);
    if (result != tmath::Result::Success) return _error(engine, result);
    auto transport = tmath::audio::Transport{};
    transport.time = time;
    transport.rate = rate;
    transport.playing = playing != 0u;
    transport.seek = seek != 0u;
    result = player->sync(transport);
    return _audioResult(engine, result);
}
#endif

#if defined(TMATH_UI)
extern "C" TMATH_KEEPALIVE uint32_t tmath_ui_input(TMathEngine handle, uint32_t type,
                                                     float x, float y, float dx, float dy,
                                                     float wheelX, float wheelY, int32_t button,
                                                     uint32_t buttons, uint32_t modifiers,
                                                     uint32_t pointer, float time)
{
    auto engine = _engine(handle);
    if (engine) engine->uiSampled = false;
    if (!engine || !engine->scene || !engine->panel || type > 5u
        || !std::isfinite(x) || !std::isfinite(y) || !std::isfinite(dx)
        || !std::isfinite(dy) || !std::isfinite(wheelX) || !std::isfinite(wheelY)
        || !std::isfinite(time) || time < 0.0f) {
        return 0u;
    }
    constexpr uint32_t Handled = 1u;
    constexpr uint32_t Redraw = 2u;
    constexpr uint32_t Capture = 4u;
    constexpr uint32_t Release = 8u;
    constexpr uint32_t Sampled = 16u;
    constexpr uint32_t Failed = 32u;
    uint32_t flags = 0u;
    tmath::ui::InputEvent event;
    event.kind = static_cast<tmath::ui::InputKind>(type);
    event.pointer = pointer;
    event.position = {x, y};
    event.delta = {dx, dy};
    event.wheel = {wheelX, wheelY};
    event.button = button;
    event.buttons = buttons;
    event.modifiers = modifiers;
    event.time = time;
    auto input = engine->panel->input(event);
    if (input.handled) flags |= Handled;
    if (input.redraw) flags |= Redraw;
    if (input.capture) flags |= Capture;
    if (input.release) flags |= Release;
    if (input.status != tmath::Result::Success) {
        _error(engine, input.status);
        flags |= Failed;
    }
    if (input.sample && input.sample->selected()) {
        engine->uiSample = input.sample->selection();
        engine->uiSampleValue = input.sample->value();
        engine->uiSampled = true;
        flags |= Sampled;
    }
    if (!(flags & Handled) && type == 5u && !(modifiers & (2u | 4u | 8u))
        && engine->scene->config().cameraMode == tmath::CameraMode::Interactive) {
        tmath::Result result = tmath::Result::InvalidArguments;
        switch (button) {
            case 0: result = engine->panel->cameraMove({0.04f, 0.0f}); break;
            case 1: result = engine->panel->cameraMove({-0.04f, 0.0f}); break;
            case 2: result = engine->panel->cameraMove({0.0f, -0.04f}); break;
            case 3: result = engine->panel->cameraMove({0.0f, 0.04f}); break;
            case 4: result = engine->panel->cameraZoom(-0.12f); break;
            case 5: result = engine->panel->cameraZoom(0.12f); break;
            case 6: result = engine->panel->cameraReset(); break;
            case 7: result = engine->panel->cameraView(tmath::CameraView::TwoD); break;
            case 8: result = engine->panel->cameraView(tmath::CameraView::ThreeD); break;
        }
        if (result == tmath::Result::Success) flags = Handled | Redraw;
    }
    if (flags & Redraw) {
        engine->rendered = false;
        _clearLayoutReport(engine);
    }
    return flags;
}

extern "C" TMATH_KEEPALIVE uint32_t tmath_ui_sample_handle(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine && engine->uiSampled && engine->uiSample.object
               ? engine->uiSample.object->id() : 0u;
}

extern "C" TMATH_KEEPALIVE const char* tmath_ui_sample_tag(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine && engine->uiSampled && engine->uiSample.object
               ? engine->uiSample.object->tag() : nullptr;
}

extern "C" TMATH_KEEPALIVE const char* tmath_ui_sample_type(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine && engine->uiSampled && engine->uiSample.object
               ? tmath::type(engine->uiSample.object->type()) : nullptr;
}

extern "C" TMATH_KEEPALIVE float tmath_ui_sample_x(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine && engine->uiSampled ? engine->uiSample.position.x : 0.0f;
}

extern "C" TMATH_KEEPALIVE float tmath_ui_sample_y(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine && engine->uiSampled ? engine->uiSample.position.y : 0.0f;
}

extern "C" TMATH_KEEPALIVE float tmath_ui_sample_u(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine && engine->uiSampled ? engine->uiSampleValue.x : 0.0f;
}

extern "C" TMATH_KEEPALIVE float tmath_ui_sample_v(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine && engine->uiSampled ? engine->uiSampleValue.y : 0.0f;
}

extern "C" TMATH_KEEPALIVE uint32_t tmath_ui_sample_rgba(TMathEngine handle)
{
    auto engine = _engine(handle);
    if (!engine || !engine->uiSampled) return 0u;
    auto& color = engine->uiSample.color;
    return static_cast<uint32_t>(color.r) << 24u
         | static_cast<uint32_t>(color.g) << 16u
         | static_cast<uint32_t>(color.b) << 8u
         | color.a;
}
#endif

extern "C" TMATH_KEEPALIVE TMathCameraMode tmath_camera_mode(TMathEngine handle)
{
    auto engine = _engine(handle);
    if (!engine || !engine->scene) return TMATH_CAMERA_FIXED;
    return static_cast<TMathCameraMode>(engine->scene->config().cameraMode);
}

extern "C" TMATH_KEEPALIVE TMathCameraView tmath_camera_view(TMathEngine handle)
{
    auto engine = _engine(handle);
    if (!engine || !engine->scene) return TMATH_CAMERA_VIEW_2D;
    auto time = engine->rendered ? engine->renderTime : 0.0f;
    return static_cast<TMathCameraView>(engine->scene->view(time));
}

extern "C" TMATH_KEEPALIVE const uint8_t* tmath_pixels(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine && engine->rendered ? reinterpret_cast<const uint8_t*>(engine->surface.data()) : nullptr;
}

extern "C" TMATH_KEEPALIVE uint32_t tmath_pixels_size(TMathEngine handle)
{
    auto engine = _engine(handle);
    if (!engine || !engine->rendered || !engine->surface.data() || !engine->surface.width()) return 0;
    auto limit = std::numeric_limits<uint32_t>::max() / 4u;
    if (engine->surface.height() > limit / engine->surface.width()) return 0;
    return engine->surface.width() * engine->surface.height() * 4u;
}

extern "C" TMATH_KEEPALIVE uint32_t tmath_width(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine && engine->scene ? engine->scene->config().width : 0;
}

extern "C" TMATH_KEEPALIVE uint32_t tmath_height(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine && engine->scene ? engine->scene->config().height : 0;
}

extern "C" TMATH_KEEPALIVE float tmath_duration(TMathEngine handle)
{
    auto engine = _engine(handle);
    if (!engine || !engine->scene) return 0.0f;
    auto duration = engine->scene->duration();
#if defined(TMATH_AUDIO)
    auto audioDuration = engine->soundscape ? engine->soundscape->duration() : 0.0f;
    if (audioDuration > duration) duration = audioDuration;
#endif
    return duration;
}

extern "C" TMATH_KEEPALIVE uint8_t tmath_loop(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine && engine->scene && engine->scene->config().loop ? 1u : 0u;
}

extern "C" TMATH_KEEPALIVE const char* tmath_last_error(TMathEngine handle)
{
    auto engine = _engine(handle);
    return engine ? engine->error : "invalid engine";
}
