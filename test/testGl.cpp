#include <cstdio>
#include <dlfcn.h>
#include <new>

#define GL_SILENCE_DEPRECATION 1
#include <OpenGL/OpenGL.h>
#include <OpenGL/gl3.h>

#include "tmath.h"
#include "tmath_capi.h"

using namespace tmath;

static auto failures = 0;

#define CHECK(condition)                                                                       \
    do {                                                                                       \
        if (!(condition)) {                                                                    \
            std::fprintf(stderr, "%s:%d: check failed: %s\n", __FILE__, __LINE__, #condition); \
            failures++;                                                                        \
        }                                                                                      \
    } while (false)

struct Context
{
    CGLContextObj context = nullptr;
    void* library = nullptr;
    GLuint fbo = 0;
    GLuint color = 0;
    GLuint depth = 0;
    uint32_t width = 160;
    uint32_t height = 90;
    PFNGLGENFRAMEBUFFERSPROC genFramebuffers = nullptr;
    PFNGLBINDFRAMEBUFFERPROC bindFramebuffer = nullptr;
    PFNGLGENRENDERBUFFERSPROC genRenderbuffers = nullptr;
    PFNGLBINDRENDERBUFFERPROC bindRenderbuffer = nullptr;
    PFNGLRENDERBUFFERSTORAGEPROC renderbufferStorage = nullptr;
    PFNGLFRAMEBUFFERRENDERBUFFERPROC framebufferRenderbuffer = nullptr;
    PFNGLCHECKFRAMEBUFFERSTATUSPROC checkFramebufferStatus = nullptr;
    PFNGLDELETEFRAMEBUFFERSPROC deleteFramebuffers = nullptr;
    PFNGLDELETERENDERBUFFERSPROC deleteRenderbuffers = nullptr;
    PFNGLREADPIXELSPROC readPixels = nullptr;

    template<typename T>
    bool resolve(T& function, const char* name)
    {
        function = reinterpret_cast<T>(dlsym(library, name));
        return function;
    }

    bool init()
    {
        // ThorVG owns same-named loader symbols, so keep test entry points under local aliases.
        library = dlopen("/System/Library/Frameworks/OpenGL.framework/OpenGL", RTLD_LAZY | RTLD_LOCAL);
        if (!library) library = dlopen("/Library/Frameworks/OpenGL.framework/OpenGL", RTLD_LAZY | RTLD_LOCAL);
        if (!library || !resolve(genFramebuffers, "glGenFramebuffers")
            || !resolve(bindFramebuffer, "glBindFramebuffer")
            || !resolve(genRenderbuffers, "glGenRenderbuffers")
            || !resolve(bindRenderbuffer, "glBindRenderbuffer")
            || !resolve(renderbufferStorage, "glRenderbufferStorage")
            || !resolve(framebufferRenderbuffer, "glFramebufferRenderbuffer")
            || !resolve(checkFramebufferStatus, "glCheckFramebufferStatus")
            || !resolve(deleteFramebuffers, "glDeleteFramebuffers")
            || !resolve(deleteRenderbuffers, "glDeleteRenderbuffers")
            || !resolve(readPixels, "glReadPixels")) {
            return false;
        }
        CGLPixelFormatAttribute attributes[] = {
            kCGLPFAOpenGLProfile, static_cast<CGLPixelFormatAttribute>(kCGLOGLPVersion_GL3_Core),
            kCGLPFAColorSize, static_cast<CGLPixelFormatAttribute>(32),
            kCGLPFADepthSize, static_cast<CGLPixelFormatAttribute>(24),
            kCGLPFAStencilSize, static_cast<CGLPixelFormatAttribute>(8),
            static_cast<CGLPixelFormatAttribute>(0)};
        CGLPixelFormatObj format = nullptr;
        GLint count = 0;
        if (CGLChoosePixelFormat(attributes, &format, &count) != kCGLNoError || !format || !count) return false;
        auto result = CGLCreateContext(format, nullptr, &context);
        CGLDestroyPixelFormat(format);
        if (result != kCGLNoError || !context || CGLSetCurrentContext(context) != kCGLNoError) return false;

        genFramebuffers(1, &fbo);
        bindFramebuffer(GL_FRAMEBUFFER, fbo);
        genRenderbuffers(1, &color);
        bindRenderbuffer(GL_RENDERBUFFER, color);
        renderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, width, height);
        framebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, color);
        genRenderbuffers(1, &depth);
        bindRenderbuffer(GL_RENDERBUFFER, depth);
        renderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, width, height);
        framebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_RENDERBUFFER, depth);
        auto complete = checkFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE;
        bindFramebuffer(GL_FRAMEBUFFER, 0);
        return complete;
    }

    ~Context()
    {
        if (context) {
            CGLSetCurrentContext(context);
            if (deleteFramebuffers && fbo) deleteFramebuffers(1, &fbo);
            if (deleteRenderbuffers && color) deleteRenderbuffers(1, &color);
            if (deleteRenderbuffers && depth) deleteRenderbuffers(1, &depth);
            CGLSetCurrentContext(nullptr);
            CGLDestroyContext(context);
        }
        if (library) dlclose(library);
    }
};

int main()
{
    Context context;
    auto ready = context.init();
    CHECK(ready);
    if (!ready) return 1;

    Config config;
    config.width = context.width;
    config.height = context.height;
    config.camera.orthoHeight = 6.0f;
    auto scene = Scene::gen(config);
    auto space = Space::gen({-1.0f, 1.0f, 1.0f}, {-1.0f, 1.0f, 1.0f}, {-1.0f, 1.0f, 1.0f});
    auto circle = Circle::gen({}, 1.25f);
    CHECK(scene && space && circle);
    if (!scene || !space || !circle) {
        delete circle;
        delete space;
        delete scene;
        return 1;
    }
    space->style.stroke.a = 0;
    space->axisX.a = 0;
    space->axisY.a = 0;
    space->axisZ.a = 0;
    circle->stroke(Color::hex("#ffd166"), 4.0f).fill(Color::hex("#4cc9f080"));
    CHECK(space->add(circle) == Result::Success);
    auto added = scene->add(space);
    CHECK(added == Result::Success);
    if (added != Result::Success) {
        delete space;
        delete scene;
        return 1;
    }

    auto child = Scene::gen(config);
    auto childSpace = Space::gen({-1.0f, 1.0f, 1.0f}, {-1.0f, 1.0f, 1.0f}, {-1.0f, 1.0f, 1.0f});
    auto childCircle = Circle::gen({}, 10.0f);
    CHECK(child && childSpace && childCircle);
    if (!child || !childSpace || !childCircle) {
        delete childCircle;
        delete childSpace;
        delete child;
        delete scene;
        return 1;
    }
    child->config().background.a = 0;
    childSpace->progress = 0.0f;
    childCircle->style.stroke.a = 0;
    childCircle->fill(Color::hex("#40d8a0"));
    CHECK(childSpace->add(childCircle) == Result::Success);
    CHECK(child->add(childSpace) == Result::Success);
    auto mounted = scene->viewport(child, {0.25f, 0.25f, 0.5f, 0.5f});
    CHECK(mounted == Result::Success);
    if (mounted != Result::Success) {
        delete child;
        delete scene;
        return 1;
    }

    CGLSetCurrentContext(context.context);
    auto renderer = Renderer::gen(RenderEngine::Gl);
    CHECK(renderer != nullptr);
    if (renderer) {
        CHECK(renderer->engine() == RenderEngine::Gl);
        GlTarget target;
        target.context = context.context;
        target.id = static_cast<int32_t>(context.fbo);
        target.width = context.width;
        target.height = context.height;
        CHECK(renderer->render(scene, 0.0f, target) == Result::Success);

        auto bytes = new (std::nothrow) uint8_t[static_cast<size_t>(context.width) * context.height * 4];
        CHECK(bytes != nullptr);
        if (bytes) {
            context.bindFramebuffer(GL_FRAMEBUFFER, context.fbo);
            context.readPixels(0, 0, context.width, context.height, GL_RGBA, GL_UNSIGNED_BYTE, bytes);
            auto changed = 0u;
            for (auto i = 0u; i < context.width * context.height; i++) {
                auto pixel = bytes + static_cast<size_t>(i) * 4;
                if (pixel[0] != config.background.r || pixel[1] != config.background.g || pixel[2] != config.background.b || pixel[3] != config.background.a) changed++;
            }
            CHECK(changed > 1000);
            auto outside = bytes + (45u * context.width + 20u) * 4u;
            CHECK(outside[0] == config.background.r && outside[1] == config.background.g
                  && outside[2] == config.background.b && outside[3] == config.background.a);
            auto center = bytes + (45u * context.width + 80u) * 4u;
            auto green = Color::hex("#40d8a0");
            CHECK(center[0] == green.r && center[1] == green.g
                  && center[2] == green.b && center[3] == green.a);
            delete[] bytes;
        }
    }
    delete renderer;

#if defined(TMATH_EXPECT_LUA)
    static constexpr char source[] = R"lua(
local scene = tmath.scene {width = 160, height = 90}
scene:rectangle {center = {0, 0}, size = {2, 2}, fill = "#40d8a0"}
return scene
    )lua";
    auto capi = tmath_create_with_engine(TMATH_RENDER_ENGINE_GL);
    CHECK(capi != nullptr);
    if (capi) {
        CHECK(tmath_load_lua(capi, source, sizeof(source) - 1u, "gl-capi.lua")
              == TMATH_RESULT_SUCCESS);
        TMathGlTarget target = {
            nullptr,
            nullptr,
            context.context,
            static_cast<int32_t>(context.fbo),
            context.width,
            context.height,
        };
        CHECK(tmath_render_gl(capi, 0.0f, &target) == TMATH_RESULT_SUCCESS);
        CHECK(tmath_render_engine(capi) == TMATH_RENDER_ENGINE_GL);
        CHECK(tmath_pixels(capi) == nullptr && tmath_pixels_size(capi) == 0u);
        tmath_destroy(capi);
    }
#endif

    delete scene;
    return failures ? 1 : 0;
}
