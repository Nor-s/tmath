#include <cerrno>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <new>

#include "tmath.h"
#ifdef TMATH_AUDIT
#include "tmathAudit.h"
#endif
#include "tmathLuaHost.h"

using namespace tmath;

static void _usage()
{
    std::fprintf(stderr,
                 "Usage:\n"
                 "  tmath render <scene.lua> [-o output.png|mp4|gif] [--time SEC]\n"
                 "               [--width PX] [--height PX] [--fps N] [--font FILE]\n"
                 "  tmath benchmark <scene.lua> [--frames N] [--warmup N] [--font FILE]\n"
                 "  tmath layout <scene.lua> [--time SEC] [--padding PX] [--font FILE]\n"
#ifdef TMATH_AUDIT
                 "  tmath audit <scene.lua> --font FILE [--format json|text] [audit options]\n"
#endif
                 "  tmath inspect <scene.lua>\n"
                 "  tmath capabilities\n"
    );
}

static int _capabilities()
{
#ifdef TMATH_ENGINE_CPU
    constexpr auto preview = "true";
#else
    constexpr auto preview = "false";
#endif
#if defined(TMATH_AUDIT) && defined(TMATH_ENGINE_CPU)
    constexpr auto audit = "true";
#else
    constexpr auto audit = "false";
#endif
    std::printf("{\"format\":\"tmath.cli-capabilities\",\"version\":1,"
                "\"nativeInspection\":{\"preview\":%s,\"audit\":%s}}\n",
                preview, audit);
    return 0;
}

static bool _ends(const char* value, const char* suffix)
{
    auto valueSize = std::strlen(value);
    auto suffixSize = std::strlen(suffix);
    if (valueSize < suffixSize) return false;
    return std::strcmp(value + valueSize - suffixSize, suffix) == 0;
}

static bool _uint(const char* value, uint32_t& output, bool allowZero = false)
{
    if (!value || !value[0]) return false;
    for (auto cursor = value; *cursor; cursor++) {
        if (*cursor < '0' || *cursor > '9') return false;
    }
    errno = 0;
    char* end = nullptr;
    auto number = std::strtoull(value, &end, 10);
    if (errno == ERANGE || !end || *end || (!allowZero && !number) || number > UINT32_MAX) return false;
    output = static_cast<uint32_t>(number);
    return true;
}

static bool _float(const char* value, float& output)
{
    char* end = nullptr;
    auto number = std::strtof(value, &end);
    if (!value[0] || !end || *end || !std::isfinite(number) || number < 0.0f) return false;
    output = number;
    return true;
}

static uint32_t _utf8(const unsigned char* value, size_t remaining)
{
    auto continuation = [](unsigned char byte) {
        return byte >= 0x80 && byte <= 0xbf;
    };
    if (remaining >= 2 && value[0] >= 0xc2 && value[0] <= 0xdf && continuation(value[1])) return 2;
    if (remaining >= 3 && value[0] == 0xe0 && value[1] >= 0xa0 && value[1] <= 0xbf && continuation(value[2])) return 3;
    if (remaining < 3) return 0;
    if (((value[0] >= 0xe1 && value[0] <= 0xec) || (value[0] >= 0xee && value[0] <= 0xef)) && continuation(value[1]) && continuation(value[2])) {
        return 3;
    }
    if (value[0] == 0xed && value[1] >= 0x80 && value[1] <= 0x9f && continuation(value[2])) return 3;
    if (remaining < 4) return 0;
    if (value[0] == 0xf0 && value[1] >= 0x90 && value[1] <= 0xbf && continuation(value[2]) && continuation(value[3])) {
        return 4;
    }
    if (value[0] >= 0xf1 && value[0] <= 0xf3 && continuation(value[1]) && continuation(value[2]) && continuation(value[3])) {
        return 4;
    }
    if (value[0] == 0xf4 && value[1] >= 0x80 && value[1] <= 0x8f && continuation(value[2]) && continuation(value[3])) {
        return 4;
    }
    return 0;
}

static void _json(const char* value)
{
    std::putchar('"');
    if (value) {
        auto cursor = reinterpret_cast<const unsigned char*>(value);
        auto end = cursor + std::strlen(value);
        while (cursor < end) {
            auto byte = *cursor;
            switch (byte) {
                case '"':
                    std::fputs("\\\"", stdout);
                    cursor++;
                    break;
                case '\\':
                    std::fputs("\\\\", stdout);
                    cursor++;
                    break;
                case '\n':
                    std::fputs("\\n", stdout);
                    cursor++;
                    break;
                case '\r':
                    std::fputs("\\r", stdout);
                    cursor++;
                    break;
                case '\t':
                    std::fputs("\\t", stdout);
                    cursor++;
                    break;
                default:
                    if (byte < 0x20) {
                        std::printf("\\u%04x", byte);
                        cursor++;
                    } else if (byte < 0x80) {
                        std::putchar(byte);
                        cursor++;
                    } else if (auto size = _utf8(cursor, static_cast<size_t>(end - cursor))) {
                        std::fwrite(cursor, 1, size, stdout);
                        cursor += size;
                    } else {
                        std::printf("\\u%04x", byte);
                        cursor++;
                    }
                    break;
            }
        }
    }
    std::putchar('"');
}

static Scene* _load(const char* path)
{
    char error[2048] = {};
    Scene* scene = nullptr;
    detail::LuaHostContext context;
    auto status = detail::luaHostLoadFile(path, &scene, error, sizeof(error), context);
    if (status == Result::Success) return scene;
    std::fprintf(stderr, "tmath: %s: %s\n", result(status), error[0] ? error : "failed to load scene");
    return nullptr;
}

static void _inspectScene(const Scene* scene, const char* source)
{
    auto& config = scene->config();
    std::putchar('{');
    if (source) {
        std::fputs("\"source\":", stdout);
        _json(source);
        std::putchar(',');
    }
    std::printf("\"width\":%u,\"height\":%u,\"fps\":%u,\"duration\":%.6g,\"loop\":%s,\"camera\":{\"mode\":\"%s\",\"view\":\"%s\",\"projection\":\"%s\"},\"objects\":[",
                config.width, config.height, config.fps, scene->duration(), config.loop ? "true" : "false",
                config.cameraMode == CameraMode::Interactive ? "interactive" : "fixed",
                config.cameraView == CameraView::ThreeD ? "3d" : "2d",
                config.camera.projection == Projection::Perspective ? "perspective" : "orthographic");
    for (auto i = 0u; i < scene->count(); i++) {
        auto object = scene->objectAt(i);
        if (i) std::putchar(',');
        std::printf("{\"handle\":%u,\"id\":", object->id());
        if (object->tag()) _json(object->tag());
        else std::fputs("null", stdout);
        std::printf(",\"type\":");
        _json(type(object->type()));
        std::printf(",\"parent\":");
        if (object->parent()) std::printf("%u", object->parent()->id());
        else std::fputs("null", stdout);
        std::printf(",\"space\":");
        if (object->space()) std::printf("%u", object->space()->id());
        else std::fputs("null", stdout);
        std::putchar('}');
    }
    std::fputs("],\"viewports\":[", stdout);
    for (auto i = 0u; i < scene->viewportCount(); i++) {
        if (i) std::putchar(',');
        Viewport viewport;
        scene->viewportAt(i, viewport);
        std::printf("{\"x\":%.6g,\"y\":%.6g,\"width\":%.6g,\"height\":%.6g,\"scene\":",
                    viewport.x, viewport.y, viewport.width, viewport.height);
        _inspectScene(scene->sceneAt(i), nullptr);
        std::putchar('}');
    }
    std::fputs("]}", stdout);
}

static int _inspect(const char* path)
{
    auto scene = _load(path);
    if (!scene) return 2;
    _inspectScene(scene, path);
    std::putchar('\n');
    delete scene;
    return 0;
}

static bool _ancestor(const Object* ancestor, const Object* object)
{
    while (object) {
        if (object == ancestor) return true;
        object = object->parent();
    }
    return false;
}

static bool _layoutScene(const Scene* scene, Renderer* renderer, float time, float padding)
{
    auto count = scene->count();
    auto boxes = new (std::nothrow) BBox[count];
    auto defined = new (std::nothrow) bool[count]();
    if ((!boxes || !defined) && count) {
        delete[] boxes;
        delete[] defined;
        return false;
    }
    auto& config = scene->config();
    std::printf("{\"width\":%u,\"height\":%u,\"objects\":[", config.width, config.height);
    for (auto i = 0u; i < count; i++) {
        auto object = scene->objectAt(i);
        if (i) std::putchar(',');
        std::printf("{\"handle\":%u,\"id\":", object->id());
        if (object->tag()) _json(object->tag());
        else std::fputs("null", stdout);
        std::fputs(",\"type\":", stdout);
        _json(type(object->type()));
        if (object->type() == Type::Text) {
            std::fputs(",\"text\":", stdout);
            _json(static_cast<Text*>(object)->text());
        }
        auto result = renderer->bounds(scene, object, time, boxes[i]);
        defined[i] = result == Result::Success;
        if (defined[i]) {
            std::printf(",\"bounds\":{\"x\":%.6g,\"y\":%.6g,\"width\":%.6g,\"height\":%.6g}}",
                        boxes[i].x, boxes[i].y, boxes[i].width, boxes[i].height);
        } else {
            std::fputs(",\"bounds\":null}", stdout);
        }
    }
    std::fputs("],\"intersections\":[", stdout);
    auto written = false;
    for (auto i = 0u; i < count; i++) {
        if (!defined[i]) continue;
        auto first = scene->objectAt(i);
        for (auto j = i + 1u; j < count; j++) {
            if (!defined[j]) continue;
            auto second = scene->objectAt(j);
            if (_ancestor(first, second) || _ancestor(second, first)
                || !boxes[i].intersects(boxes[j], padding)) {
                continue;
            }
            if (written) std::putchar(',');
            std::printf("{\"first\":%u,\"second\":%u}", first->id(), second->id());
            written = true;
        }
    }
    std::fputs("],\"viewports\":[", stdout);
    for (auto i = 0u; i < scene->viewportCount(); i++) {
        if (i) std::putchar(',');
        Viewport viewport;
        scene->viewportAt(i, viewport);
        std::printf("{\"x\":%.6g,\"y\":%.6g,\"width\":%.6g,\"height\":%.6g,\"scene\":",
                    viewport.x, viewport.y, viewport.width, viewport.height);
        if (!_layoutScene(scene->sceneAt(i), renderer, time, padding)) {
            delete[] boxes;
            delete[] defined;
            return false;
        }
        std::putchar('}');
    }
    std::fputs("],\"transitions\":[", stdout);
    for (auto i = 0u; i < scene->transitionCount(); i++) {
        if (i) std::putchar(',');
        if (!_layoutScene(scene->transitionAt(i), renderer,
                          scene->transitionAt(i)->duration(), padding)) {
            delete[] boxes;
            delete[] defined;
            return false;
        }
    }
    std::fputs("]}", stdout);
    delete[] boxes;
    delete[] defined;
    return true;
}

static void _bbox(const BBox& bounds)
{
    std::printf("{\"x\":%.6g,\"y\":%.6g,\"width\":%.6g,\"height\":%.6g}",
                bounds.x, bounds.y, bounds.width, bounds.height);
}

static const char* _layoutKind(LayoutSceneKind kind)
{
    switch (kind) {
        case LayoutSceneKind::Root: return "root";
        case LayoutSceneKind::Viewport: return "viewport";
        case LayoutSceneKind::Transition: return "transition";
    }
    return "unknown";
}

static const char* _layoutVisualKind(LayoutVisualKind kind)
{
    switch (kind) {
        case LayoutVisualKind::Stable: return "stable";
        case LayoutVisualKind::Morph: return "morph";
        case LayoutVisualKind::FadeOut: return "fade-out";
        case LayoutVisualKind::FadeIn: return "fade-in";
    }
    return "unknown";
}

static void _layoutReport(const LayoutReport& report, const Scene* root)
{
    std::printf("{\"width\":%u,\"height\":%u,\"scenes\":[",
                root->config().width, root->config().height);
    for (auto i = 0u; i < report.sceneCount(); i++) {
        auto scene = report.sceneAt(i);
        if (i) std::putchar(',');
        std::printf("{\"index\":%u,\"path\":", i);
        _json(scene->path);
        std::fputs(",\"kind\":", stdout);
        _json(_layoutKind(scene->kind));
        std::fputs(",\"parent\":", stdout);
        if (scene->parent == UINT32_MAX) std::fputs("null", stdout);
        else std::printf("%u", scene->parent);
        std::printf(",\"depth\":%u,\"bounds\":", scene->depth);
        _bbox(scene->bounds);
        std::fputs(",\"clipBounds\":", stdout);
        _bbox(scene->clipBounds);
        std::printf(",\"scale\":{\"x\":%.6g,\"y\":%.6g},\"clipped\":%s,\"stretched\":%s}",
                    scene->scaleX, scene->scaleY, scene->clipped ? "true" : "false",
                    scene->stretched ? "true" : "false");
    }
    std::fputs("],\"objects\":[", stdout);
    for (auto i = 0u; i < report.objectCount(); i++) {
        auto item = report.objectAt(i);
        auto object = item->object;
        auto scene = report.sceneAt(item->scene);
        if (i) std::putchar(',');
        std::printf("{\"index\":%u,\"scene\":%u,\"scenePath\":", i, item->scene);
        _json(scene->path);
        std::printf(",\"handle\":%u,\"id\":", object->id());
        if (object->tag()) _json(object->tag());
        else std::fputs("null", stdout);
        std::fputs(",\"parent\":", stdout);
        if (item->parent == UINT32_MAX) std::fputs("null", stdout);
        else std::printf("%u", item->parent);
        std::fputs(",\"type\":", stdout);
        _json(type(object->type()));
        std::printf(",\"layer\":%d,\"paintBounds\":", item->layer);
        if (item->paintBounds.width > 0.0f && item->paintBounds.height > 0.0f) {
            _bbox(item->paintBounds);
        } else {
            std::fputs("null", stdout);
        }
        std::fputs(",\"familyBounds\":", stdout);
        if (item->familyBounds.width > 0.0f && item->familyBounds.height > 0.0f) {
            _bbox(item->familyBounds);
        } else {
            std::fputs("null", stdout);
        }
        std::fputs(",\"visibleBounds\":", stdout);
        if (item->visible) _bbox(item->visibleBounds);
        else std::fputs("null", stdout);
        std::fputs(",\"visibleFamilyBounds\":", stdout);
        if (item->familyVisible) _bbox(item->visibleFamilyBounds);
        else std::fputs("null", stdout);
        std::fputs(",\"clipBounds\":", stdout);
        _bbox(item->clipBounds);
        auto painted = item->paintBounds.width > 0.0f && item->paintBounds.height > 0.0f;
        auto familyPainted = item->familyBounds.width > 0.0f && item->familyBounds.height > 0.0f;
        std::printf(",\"visible\":%s,\"familyVisible\":%s,\"clipped\":%s,\"familyClipped\":%s,\"outside\":%s,\"familyOutside\":%s}",
                    item->visible ? "true" : "false", item->familyVisible ? "true" : "false",
                    item->clipped ? "true" : "false", item->familyClipped ? "true" : "false",
                    painted && !item->visible ? "true" : "false",
                    familyPainted && !item->familyVisible ? "true" : "false");
    }
    std::fputs("],\"visuals\":[", stdout);
    for (auto i = 0u; i < report.visualCount(); i++) {
        auto visual = report.visualAt(i);
        if (i) std::putchar(',');
        std::printf("{\"index\":%u,\"object\":%u,\"counterpart\":", i, visual->object);
        if (visual->counterpart == UINT32_MAX) std::fputs("null", stdout);
        else std::printf("%u", visual->counterpart);
        std::fputs(",\"occluder\":", stdout);
        if (visual->occluder == UINT32_MAX) std::fputs("null", stdout);
        else std::printf("%u", visual->occluder);
        std::fputs(",\"kind\":", stdout);
        _json(_layoutVisualKind(visual->kind));
        std::printf(",\"layer\":%d,\"paintBounds\":", visual->layer);
        auto painted = visual->paintBounds.width > 0.0f && visual->paintBounds.height > 0.0f;
        if (painted) _bbox(visual->paintBounds);
        else std::fputs("null", stdout);
        std::fputs(",\"visibleBounds\":", stdout);
        if (visual->visible) _bbox(visual->visibleBounds);
        else std::fputs("null", stdout);
        std::fputs(",\"clipBounds\":", stdout);
        _bbox(visual->clipBounds);
        std::printf(",\"opacity\":%.6g,\"visible\":%s,\"clipped\":%s,\"occluded\":%s}",
                    visual->opacity, visual->visible ? "true" : "false",
                    visual->clipped ? "true" : "false",
                    visual->occluded ? "true" : "false");
    }
    std::fputs("],\"paths\":[", stdout);
    for (auto i = 0u; i < report.pathCount(); i++) {
        auto path = report.pathAt(i);
        if (i) std::putchar(',');
        std::printf("{\"index\":%u,\"visual\":%u,\"paintBounds\":", i, path->visual);
        _bbox(path->paintBounds);
        std::printf(",\"strokeWidth\":%.6g,\"closed\":%s,\"filled\":%s,"
                    "\"stroked\":%s,\"points\":[",
                    path->strokeWidth, path->closed ? "true" : "false",
                    path->filled ? "true" : "false", path->stroked ? "true" : "false");
        for (auto j = 0u; j < path->count; j++) {
            if (j) std::putchar(',');
            std::printf("{\"x\":%.6g,\"y\":%.6g}", path->points[j].x,
                        path->points[j].y);
        }
        std::putchar(']');
        std::putchar('}');
    }
    std::fputs("],\"collisions\":[", stdout);
    for (auto i = 0u; i < report.collisionCount(); i++) {
        auto collision = report.collisionAt(i);
        if (i) std::putchar(',');
        std::printf("{\"first\":%u,\"second\":%u,\"kind\":\"%s\",\"overlap\":",
                    collision->first, collision->second,
                    collision->overlapping ? "overlap" : "insufficient-gap");
        if (collision->overlapping) _bbox(collision->overlap);
        else std::fputs("null", stdout);
        std::printf(",\"clearance\":{\"x\":%.6g,\"y\":%.6g},\"separation\":{\"x\":%.6g,\"y\":%.6g}}",
                    collision->clearance.x, collision->clearance.y,
                    collision->separation.x, collision->separation.y);
    }
    std::fputs("],\"containments\":[", stdout);
    for (auto i = 0u; i < report.containmentCount(); i++) {
        auto containment = report.containmentAt(i);
        if (i) std::putchar(',');
        std::printf("{\"container\":%u,\"content\":%u,\"depth\":%u,\"inset\":%.6g,\"contained\":%s,\"overflow\":{\"left\":%.6g,\"top\":%.6g,\"right\":%.6g,\"bottom\":%.6g}}",
                    containment->container, containment->content, containment->depth,
                    containment->inset, containment->contained ? "true" : "false",
                    containment->overflowLeft, containment->overflowTop,
                    containment->overflowRight, containment->overflowBottom);
    }
    std::fputs("]}", stdout);
}

static int _layout(int argc, char** argv)
{
    if (argc < 3) {
        _usage();
        return 2;
    }
    auto source = argv[2];
    const char* font = nullptr;
    auto time = -1.0f;
    auto padding = 0.0f;
    for (auto i = 3; i < argc; i++) {
        if (std::strcmp(argv[i], "--font") == 0 && i + 1 < argc) {
            font = argv[++i];
        } else if (std::strcmp(argv[i], "--time") == 0 && i + 1 < argc && _float(argv[i + 1], time)) {
            i++;
        } else if (std::strcmp(argv[i], "--padding") == 0 && i + 1 < argc && _float(argv[i + 1], padding)) {
            i++;
        } else {
            std::fprintf(stderr, "tmath: invalid option: %s\n", argv[i]);
            return 2;
        }
    }
    auto scene = _load(source);
    if (!scene) return 2;
    auto renderer = Renderer::gen(RenderEngine::Cpu);
    if (!renderer) {
        std::fprintf(stderr, "tmath: SW renderer is unavailable\n");
        delete scene;
        return 3;
    }
    if (font && renderer->font(font) != Result::Success) {
        std::fprintf(stderr, "tmath: cannot load font: %s\n", font);
        delete renderer;
        delete scene;
        return 3;
    }
    if (time < 0.0f) time = scene->duration();
    LayoutReport report;
    auto reportResult = renderer->layout(scene, time, report, padding);
    if (reportResult != Result::Success) {
        std::fprintf(stderr, "tmath: layout report failed: %s\n", result(reportResult));
        delete renderer;
        delete scene;
        return 4;
    }
    std::fputs("{\"source\":", stdout);
    _json(source);
    std::printf(",\"time\":%.6g,\"padding\":%.6g,\"scene\":", time, padding);
    auto success = _layoutScene(scene, renderer, time, padding);
    if (success) {
        std::fputs(",\"report\":", stdout);
        _layoutReport(report, scene);
        std::fputs("}\n", stdout);
    }
    else std::fprintf(stderr, "tmath: layout inspection failed: OutOfMemory\n");
    delete renderer;
    delete scene;
    return success ? 0 : 4;
}

static int _render(int argc, char** argv)
{
    if (argc < 3) {
        _usage();
        return 2;
    }
    auto source = argv[2];
    auto output = "render.png";
    const char* font = nullptr;
    uint32_t width = 0;
    uint32_t height = 0;
    uint32_t fps = 0;
    float time = -1.0f;
    for (auto i = 3; i < argc; i++) {
        if ((std::strcmp(argv[i], "-o") == 0 || std::strcmp(argv[i], "--output") == 0) && i + 1 < argc) {
            output = argv[++i];
        } else if (std::strcmp(argv[i], "--font") == 0 && i + 1 < argc) {
            font = argv[++i];
        } else if (std::strcmp(argv[i], "--width") == 0 && i + 1 < argc && _uint(argv[i + 1], width)) {
            i++;
        } else if (std::strcmp(argv[i], "--height") == 0 && i + 1 < argc && _uint(argv[i + 1], height)) {
            i++;
        } else if (std::strcmp(argv[i], "--fps") == 0 && i + 1 < argc && _uint(argv[i + 1], fps)) {
            i++;
        } else if (std::strcmp(argv[i], "--time") == 0 && i + 1 < argc && _float(argv[i + 1], time)) {
            i++;
        } else {
            std::fprintf(stderr, "tmath: invalid option: %s\n", argv[i]);
            return 2;
        }
    }

    auto scene = _load(source);
    if (!scene) return 2;
    auto& config = scene->config();
    if (width) config.width = width;
    if (height) config.height = height;
    if (fps) config.fps = fps;
    auto renderer = Renderer::gen(RenderEngine::Cpu);
    if (!renderer) {
        std::fprintf(stderr, "tmath: SW renderer is unavailable\n");
        delete scene;
        return 3;
    }
    if (font) {
        auto status = renderer->font(font);
        if (status != Result::Success) {
            std::fprintf(stderr, "tmath: cannot load font: %s\n", font);
            delete renderer;
            delete scene;
            return 3;
        }
    }

    Result status;
    if (_ends(output, ".mp4") || _ends(output, ".gif")) {
        status = Saver::save(scene, *renderer, output, fps);
    } else if (_ends(output, ".png")) {
        Surface surface;
        if (time < 0.0f) time = scene->duration();
        status = renderer->render(scene, time, surface);
        if (status == Result::Success) status = Saver::png(surface, output);
    } else {
        status = Result::NonSupport;
    }
    if (status == Result::Success) {
        std::printf("%s\n", output);
    } else {
        std::fprintf(stderr, "tmath: render failed: %s\n", result(status));
    }
    delete renderer;
    delete scene;
    return status == Result::Success ? 0 : 4;
}

static uint64_t _objectCount(const Scene* scene)
{
    if (!scene) return 0;
    auto count = static_cast<uint64_t>(scene->count());
    for (auto i = 0u; i < scene->viewportCount(); i++)
        count += _objectCount(scene->sceneAt(i));
    for (auto i = 0u; i < scene->transitionCount(); i++)
        count += _objectCount(scene->transitionAt(i));
    return count;
}

static int _benchmark(int argc, char** argv)
{
    if (argc < 3) {
        _usage();
        return 2;
    }
    auto source = argv[2];
    const char* font = nullptr;
    auto frames = 120u;
    auto warmup = 5u;
    for (auto i = 3; i < argc; i++) {
        if (std::strcmp(argv[i], "--frames") == 0 && i + 1 < argc && _uint(argv[i + 1], frames)) {
            i++;
        } else if (std::strcmp(argv[i], "--warmup") == 0 && i + 1 < argc && _uint(argv[i + 1], warmup, true)) {
            i++;
        } else if (std::strcmp(argv[i], "--font") == 0 && i + 1 < argc) {
            font = argv[++i];
        } else {
            std::fprintf(stderr, "tmath: invalid option: %s\n", argv[i]);
            return 2;
        }
    }

    auto scene = _load(source);
    if (!scene) return 2;
    auto renderer = Renderer::gen(RenderEngine::Cpu);
    if (!renderer) {
        std::fprintf(stderr, "tmath: SW renderer is unavailable\n");
        delete scene;
        return 3;
    }
    if (font) {
        auto status = renderer->font(font);
        if (status != Result::Success) {
            std::fprintf(stderr, "tmath: cannot load font: %s\n", font);
            delete renderer;
            delete scene;
            return 3;
        }
    }

    Surface surface;
    auto duration = scene->duration();
    auto render = [&](uint32_t frame, uint32_t count) {
        auto time = count > 1u
                  ? static_cast<float>(static_cast<double>(duration) * frame / (count - 1u))
                  : duration;
        return renderer->render(scene, time, surface);
    };
    for (auto i = 0u; i < warmup; i++) {
        auto status = render(i % frames, frames);
        if (status != Result::Success) {
            std::fprintf(stderr, "tmath: benchmark warmup failed: %s\n", result(status));
            delete renderer;
            delete scene;
            return 4;
        }
    }

    auto begin = std::chrono::steady_clock::now();
    for (auto i = 0u; i < frames; i++) {
        auto status = render(i, frames);
        if (status != Result::Success) {
            std::fprintf(stderr, "tmath: benchmark render failed: %s\n", result(status));
            delete renderer;
            delete scene;
            return 4;
        }
    }
    auto end = std::chrono::steady_clock::now();
    auto elapsed = std::chrono::duration<double, std::milli>(end - begin).count();
    auto frameTime = elapsed / frames;
    std::printf("{\"source\":");
    _json(source);
    std::printf(",\"objects\":%llu,\"frames\":%u,\"warmup\":%u,\"elapsed_ms\":%.6f,\"ms_per_frame\":%.6f,\"fps\":%.6f}\n",
                static_cast<unsigned long long>(_objectCount(scene)), frames, warmup, elapsed,
                frameTime, 1000.0 / frameTime);
    delete renderer;
    delete scene;
    return 0;
}

int main(int argc, char** argv)
{
    if (argc < 2) {
        _usage();
        return 2;
    }
    if (std::strcmp(argv[1], "render") == 0) return _render(argc, argv);
    if (std::strcmp(argv[1], "benchmark") == 0) return _benchmark(argc, argv);
    if (std::strcmp(argv[1], "layout") == 0) return _layout(argc, argv);
#ifdef TMATH_AUDIT
    if (std::strcmp(argv[1], "audit") == 0) return tmathAudit(argc, argv);
#endif
    if (std::strcmp(argv[1], "inspect") == 0 && argc == 3) return _inspect(argv[2]);
    if (std::strcmp(argv[1], "capabilities") == 0 && argc == 2) return _capabilities();
    _usage();
    return 2;
}
