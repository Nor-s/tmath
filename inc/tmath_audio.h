#ifndef _TMATH_AUDIO_H_
#define _TMATH_AUDIO_H_

#include "tmath.h"

namespace tmath::audio
{

enum struct Bus : uint8_t
{
    Music = 0,
    Effect,
    Ui
};

struct Cue
{
    static constexpr uint32_t Invalid = 0xffffffffu;
    uint32_t index = Invalid;

    explicit operator bool() const noexcept { return index != Invalid; }
};

struct Voice
{
    static constexpr uint32_t Invalid = 0xffffffffu;
    uint32_t index = Invalid;
    uint32_t generation = 0u;

    explicit operator bool() const noexcept { return index != Invalid; }
};

struct CueConfig
{
    const char* asset = nullptr;
    Bus bus = Bus::Effect;
    float begin = 0.0f;
    float end = 0.0f;
    float gain = 1.0f;
    bool loop = false;
};

struct Playback
{
    const char* asset = nullptr;
    Bus bus = Bus::Effect;
    float gain = 1.0f;
    float rate = 1.0f;
    bool loop = false;
};

struct Transport
{
    float time = 0.0f;
    float rate = 1.0f;
    bool playing = false;
    bool seek = false;
};

struct PlayerConfig
{
    uint32_t voiceLimit = 32u;
    bool device = true;
};

struct Soundscape final : Group
{
    static constexpr uint32_t CueLimit = 256u;
    static constexpr uint32_t GainLimit = 1024u;
    static constexpr uint32_t AssetNameLimit = 255u;

    ~Soundscape() override;
    static Soundscape* gen(Scene* scene) noexcept;

    Scene* scene() const noexcept;
    Result cue(const CueConfig& config, Cue& output) noexcept;
    Result gain(Cue cue, float value, float begin, float duration = 1.0f,
                Easing easing = Easing::Smooth) noexcept;
    Result gain(Cue cue, float value, float begin, float duration,
                const AnimCurve& curve) noexcept;
    uint32_t count() const noexcept;
    bool cueAt(uint32_t index, CueConfig& output) const noexcept;
    Result sample(Cue cue, float time, float& output) const noexcept;
    float duration() const noexcept;

private:
    struct Impl;
    Impl* pImpl = nullptr;

    explicit Soundscape(Scene* scene) noexcept;
    friend struct Player;
};

struct Player
{
    static constexpr uint32_t AssetLimit = 64u;
    static constexpr uint32_t AssetByteLimit = 32u * 1024u * 1024u;
    static constexpr uint32_t AssetTotalByteLimit = 64u * 1024u * 1024u;
    static constexpr uint32_t VoiceLimit = 256u;

    ~Player();
    Player(const Player&) = delete;
    Player& operator=(const Player&) = delete;

    static Player* gen(const PlayerConfig& config = {}) noexcept;
    Result load(const char* name, const uint8_t* data, uint32_t size) noexcept;
    Result start() noexcept;
    Result play(const Playback& playback, Voice* output = nullptr) noexcept;
    Result stop(Voice voice) noexcept;
    bool active(Voice voice) const noexcept;
    Result gain(float value) noexcept;
    Result gain(Bus bus, float value) noexcept;
    Result bind(const Soundscape* soundscape) noexcept;
    Result sync(const Transport& transport) noexcept;

private:
    struct Impl;
    Impl* pImpl = nullptr;

    explicit Player(const PlayerConfig& config) noexcept;
};

struct Lua
{
    static Result load(const char* source, uint32_t size, const char* name,
                       Scene** scene, Soundscape** soundscape,
                       char* error, uint32_t errorSize,
                       tmath::Lua::AssetResolver resolver = nullptr,
                       void* resolverData = nullptr,
                       const Theme* adaptiveTheme = nullptr,
                       bool* adaptiveThemeUsed = nullptr) noexcept;
};

}  // namespace tmath::audio

#endif
