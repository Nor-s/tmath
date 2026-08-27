#ifndef _TMATH_SCENE_H_
#define _TMATH_SCENE_H_

#include "tmath.h"

namespace tmath
{

struct DisplayList;

bool valid(const Config& config) noexcept;
bool valid(const Object* object) noexcept;
const Color* sampleColors(const Cell* cell, uint32_t frame) noexcept;
uint32_t sampleFrames(const Cell* cell) noexcept;
float sampleDuration(const Object* object) noexcept;
uint64_t fingerprint(const Object* object) noexcept;
bool localBounds(const Object* object, Bounds& bounds) noexcept;

struct VisualState
{
    Mat4 model;
    Color stroke;
    Color fill;
    Color gradientEnd;
    float width;
    float radius;
    float dashOffset;
    float markerTail = 0.0f;
    float markerTip = 0.0f;
    float opacity;
    float progress;
    float fillProgress = 1.0f;
    float pixelScale = 1.0f;
    bool gradient = false;
    bool traceFill = false;
    DrawDirection direction = DrawDirection::Forward;
    const Object* morph = nullptr;
    float morphProgress = 0.0f;
};

struct ObjectEntry
{
    Object* object = nullptr;
    VisualState base;
    uint64_t fingerprint = 0;
    float born = 0.0f;
    float dead = -1.0f;
    bool revealScheduled = false;
    bool fillRevealScheduled = false;
};

struct Clip
{
    Object* object = nullptr;
    VisualState from;
    VisualState to;
    float begin = 0.0f;
    float end = 0.0f;
    AnimCurve curve = AnimCurve::preset(AnimCurvePreset::Smooth);
    AnimationKind kind = AnimationKind::Create;
    Object* related = nullptr;
};

struct CameraClip
{
    Camera from;
    Camera to;
    CameraView fromView = CameraView::TwoD;
    CameraView toView = CameraView::TwoD;
    float begin = 0.0f;
    float end = 0.0f;
    AnimCurve curve = AnimCurve::preset(AnimCurvePreset::Smooth);
};

struct ViewportEntry
{
    Scene* scene = nullptr;
    Viewport viewport;
};

struct SceneStage
{
    Scene* scene = nullptr;
    float begin = 0.0f;
    float end = 0.0f;
};

struct SceneTransition
{
    uint32_t* matches = nullptr;
    float begin = 0.0f;
    float end = 0.0f;
    AnimCurve curve = AnimCurve::preset(AnimCurvePreset::Smooth);
};

struct SceneSequence
{
    ~SceneSequence();
    SceneStage* stages = nullptr;
    SceneTransition* transitions = nullptr;
    uint32_t count = 0;
    Viewport viewport;
    float begin = 0.0f;
    bool owned = false;
};

struct StyleMember
{
    Object* object = nullptr;
    StyleChannel channel = StyleChannel::Both;
};

struct StyleGroup::Impl
{
    Scene* scene = nullptr;
    StyleMember* members = nullptr;
    uint32_t count = 0;
    uint32_t capacity = 0;
    Color color;

    ~Impl();
    bool grow(uint32_t amount = 1u) noexcept;
};

struct Scene::Impl
{
    Config cfg;
    Theme sceneTheme;
    ObjectEntry* objects = nullptr;
    Clip* clips = nullptr;
    CameraClip* cameras = nullptr;
    ViewportEntry* viewports = nullptr;
    SceneSequence* sequence = nullptr;
    StyleGroup** styleGroups = nullptr;
    Scene* owner = nullptr;
    uint32_t objectCnt = 0;
    uint32_t objectCap = 0;
    uint32_t clipCnt = 0;
    uint32_t clipCap = 0;
    uint32_t cameraCnt = 0;
    uint32_t cameraCap = 0;
    uint32_t viewportCnt = 0;
    uint32_t viewportCap = 0;
    uint32_t styleGroupCnt = 0;
    uint32_t styleGroupCap = 0;
    uint32_t nextId = 1;
    uint32_t colorCursor = 0;
    float cursor = 0.0f;
    bool definitionsSealed = false;
    Camera initialCamera;
    CameraView initialView = CameraView::TwoD;
    RuntimeModifier runtimeModifiers[Scene::RuntimeLimit];
    uint32_t runtimeModifierCnt = 0;
    char* themeFonts[5] = {};

    ~Impl();
    bool assign(const Theme& theme) noexcept;
    bool growObjects(uint32_t count = 1) noexcept;
    bool growClips(uint32_t count) noexcept;
    bool growCameras() noexcept;
    bool growViewports() noexcept;
    bool growStyleGroups() noexcept;
    ObjectEntry* entry(const Object* object) const noexcept;
    bool sample(const ObjectEntry& entry, float time, VisualState& state) const noexcept;
    Result sample(float time, Camera& camera, CameraView& view) const noexcept;
    Result world(const Object* object, float time, VisualState& state, bool& visible) const noexcept;
    Result bounds(const Object* object, float time, Bounds& bounds, bool& defined) const noexcept;
    Result build(float time, DisplayList& list, bool sort = true) const noexcept;
};

}  // namespace tmath

#endif
