#ifndef _TMATH_MOTION_H_
#define _TMATH_MOTION_H_

#include "tmath.h"

namespace tmath::motion
{

struct State
{
    Vec3 origin;
    Vec3 shift;
    Vec3 rotation;
    Vec3 scale = {1.0f, 1.0f, 1.0f};
    float opacity = 1.0f;
    float progress = 1.0f;
    bool originEnabled = false;
};

struct Target
{
    Object* object = nullptr;
    const char* state = nullptr;
};

struct Event;

struct Controller final : Group
{
    static constexpr uint32_t ObjectLimit = 512u;
    static constexpr uint32_t StateLimit = 2048u;
    static constexpr uint32_t EventLimit = 4096u;
    static constexpr uint32_t StateNameLimit = 96u;

    static Controller* gen(Scene* scene) noexcept;
    Scene* scene() const noexcept;
    Result define(Object* object, const char* name, const State& state) noexcept;
    Result transition(Object* object, const char* state, float duration = 0.2f,
                      Easing easing = Easing::Smooth) noexcept;
    Result transition(Object* object, const char* state, float duration,
                      const AnimCurve& curve) noexcept;
    Result transition(const Target* targets, uint32_t count, float duration = 0.2f,
                      Easing easing = Easing::Smooth) noexcept;
    Result transition(const Target* targets, uint32_t count, float duration,
                      const AnimCurve& curve) noexcept;
    Result advance(float elapsed) noexcept;
    Result sample(const Object* object, State& state) const noexcept;
    double time() const noexcept;
    bool active() const noexcept;
    uint32_t definitionCount() const noexcept;
    uint32_t eventCount() const noexcept;
    bool eventAt(uint32_t index, Event& event) const noexcept;
    void clearEvents() noexcept;

private:
    struct Impl;

    explicit Controller(Scene* scene) noexcept;
    ~Controller() override;
    static Result modifyObject(const Object* object, float time, Mat4& model,
                               float& opacity, float& progress, void* data) noexcept;

    Impl* pImpl = nullptr;
};

struct Event
{
    double time = 0.0;
    AnimCurve curve;
    float duration = 0.0f;
    uint32_t object = 0u;
    uint64_t transaction = 0u;
    char state[Controller::StateNameLimit + 1u] = {};
};

struct Lua
{
    static Result load(const char* source, uint32_t size, const char* name,
                       Scene** scene, Controller** controller, char* error,
                       uint32_t errorSize,
                       tmath::Lua::AssetResolver resolver = nullptr,
                       void* resolverData = nullptr,
                       const Theme* adaptiveTheme = nullptr,
                       bool* adaptiveThemeUsed = nullptr) noexcept;
};

}  // namespace tmath::motion

#endif
