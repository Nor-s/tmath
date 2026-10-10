#include <cmath>
#include <cstdio>
#include <cstring>
#include <limits>

#include "tmath.h"
#include "tmath_audio.h"
#if defined(TMATH_EXPECT_LUA_RUNTIME)
#include "tmath_lua_runtime.h"
#include "tmathLuaHost.h"
#endif

using namespace tmath;
using namespace tmath::audio;

static int failures = 0;

#define CHECK(condition)                                                                       \
    do {                                                                                       \
        if (!(condition)) {                                                                    \
            std::fprintf(stderr, "%s:%d: check failed: %s\n", __FILE__, __LINE__, #condition); \
            failures++;                                                                        \
        }                                                                                      \
    } while (false)

static constexpr uint32_t SampleRate = 8000u;
static constexpr uint32_t SampleCount = 800u;
static constexpr uint32_t WavSize = 44u + SampleCount;

static bool _near(float lhs, float rhs, float epsilon = 1.0e-4f)
{
    return std::fabs(lhs - rhs) <= epsilon;
}

static void _word(uint8_t* output, uint16_t value)
{
    output[0] = static_cast<uint8_t>(value);
    output[1] = static_cast<uint8_t>(value >> 8u);
}

static void _dword(uint8_t* output, uint32_t value)
{
    output[0] = static_cast<uint8_t>(value);
    output[1] = static_cast<uint8_t>(value >> 8u);
    output[2] = static_cast<uint8_t>(value >> 16u);
    output[3] = static_cast<uint8_t>(value >> 24u);
}

static void _wav(uint8_t (&output)[WavSize])
{
    std::memcpy(output, "RIFF", 4u);
    _dword(output + 4u, WavSize - 8u);
    std::memcpy(output + 8u, "WAVEfmt ", 8u);
    _dword(output + 16u, 16u);
    _word(output + 20u, 1u);
    _word(output + 22u, 1u);
    _dword(output + 24u, SampleRate);
    _dword(output + 28u, SampleRate);
    _word(output + 32u, 1u);
    _word(output + 34u, 8u);
    std::memcpy(output + 36u, "data", 4u);
    _dword(output + 40u, SampleCount);
    for (auto i = 0u; i < SampleCount; i++) output[44u + i] = (i / 20u) % 2u ? 192u : 64u;
}

static void soundscape()
{
    CHECK(Soundscape::gen(nullptr) == nullptr);
    auto scene = Scene::gen();
    auto soundscape = Soundscape::gen(scene);
    CHECK(scene && soundscape);
    if (!scene || !soundscape) {
        delete scene;
        return;
    }
    CHECK(soundscape->type() == Type::Group);
    CHECK(soundscape->scene() == scene);
    CHECK(scene->object(soundscape->id()) == soundscape);
    CHECK(soundscape->count() == 0u && _near(soundscape->duration(), 0.0f));

    Cue cue;
    CueConfig invalid;
    CHECK(soundscape->cue(invalid, cue) == Result::InvalidArguments && !cue);
    invalid.asset = "";
    CHECK(soundscape->cue(invalid, cue) == Result::InvalidArguments && !cue);
    invalid.asset = "tone.wav";
    invalid.bus = static_cast<Bus>(255u);
    CHECK(soundscape->cue(invalid, cue) == Result::InvalidArguments && !cue);
    invalid.bus = Bus::Effect;
    invalid.begin = -1.0f;
    CHECK(soundscape->cue(invalid, cue) == Result::InvalidArguments && !cue);
    invalid.begin = 2.0f;
    invalid.end = 1.0f;
    CHECK(soundscape->cue(invalid, cue) == Result::InvalidArguments && !cue);
    invalid.end = 0.0f;
    invalid.gain = 4.01f;
    CHECK(soundscape->cue(invalid, cue) == Result::InvalidArguments && !cue);

    char musicName[] = "music.wav";
    CueConfig music;
    music.asset = musicName;
    music.bus = Bus::Music;
    music.begin = 0.0f;
    music.end = 4.0f;
    music.gain = 0.8f;
    music.loop = true;
    Cue musicCue;
    CHECK(soundscape->cue(music, musicCue) == Result::Success && musicCue);
    musicName[0] = 'x';

    CueConfig stored;
    CHECK(soundscape->cueAt(0u, stored));
    CHECK(std::strcmp(stored.asset, "music.wav") == 0);
    CHECK(stored.bus == Bus::Music && stored.loop);
    CHECK(!soundscape->cueAt(1u, stored));

    CueConfig effect;
    effect.asset = "effect.wav";
    effect.begin = 1.5f;
    effect.gain = 0.5f;
    Cue effectCue;
    CHECK(soundscape->cue(effect, effectCue) == Result::Success && effectCue);
    CHECK(soundscape->count() == 2u && _near(soundscape->duration(), 4.0f));

    float value = 0.0f;
    CHECK(soundscape->sample(musicCue, 0.0f, value) == Result::Success);
    CHECK(_near(value, 0.8f));
    CHECK(soundscape->gain(musicCue, 0.4f, 1.0f, 2.0f, Easing::Linear)
          == Result::Success);
    CHECK(soundscape->sample(musicCue, 1.0f, value) == Result::Success);
    CHECK(_near(value, 0.8f));
    CHECK(soundscape->sample(musicCue, 2.0f, value) == Result::Success);
    CHECK(_near(value, 0.6f));
    CHECK(soundscape->sample(musicCue, 3.0f, value) == Result::Success);
    CHECK(_near(value, 0.4f));

    CHECK(soundscape->gain(musicCue, 0.7f, 2.0f, 1.0f, Easing::Linear)
          == Result::InvalidArguments);
    CHECK(soundscape->gain({}, 0.7f, 3.0f, 1.0f, Easing::Linear)
          == Result::InvalidArguments);
    CHECK(soundscape->gain(musicCue, 4.1f, 3.0f, 1.0f, Easing::Linear)
          == Result::InvalidArguments);
    CHECK(soundscape->gain(musicCue, 0.7f, 3.0f, 0.0f, Easing::Linear)
          == Result::InvalidArguments);
    CHECK(soundscape->gain(musicCue, 0.7f,
                           std::numeric_limits<float>::quiet_NaN(), 1.0f,
                           Easing::Linear)
          == Result::InvalidArguments);

    auto curve = AnimCurve::preset(AnimCurvePreset::Smooth);
    CHECK(soundscape->gain(musicCue, 1.0f, 5.0f, 1.0f, curve) == Result::Success);
    CHECK(_near(soundscape->duration(), 6.0f));
    CHECK(soundscape->sample(musicCue, 6.0f, value) == Result::Success);
    CHECK(_near(value, 1.0f));
    CHECK(scene->duration() == 0.0f);
    delete scene;
}

static void player()
{
    PlayerConfig invalid;
    invalid.voiceLimit = 0u;
    invalid.device = false;
    CHECK(Player::gen(invalid) == nullptr);
    invalid.voiceLimit = Player::VoiceLimit + 1u;
    CHECK(Player::gen(invalid) == nullptr);

    PlayerConfig config;
    config.voiceLimit = 4u;
    config.device = false;
    auto player = Player::gen(config);
    CHECK(player != nullptr);
    if (!player) return;

    uint8_t wav[WavSize] = {};
    _wav(wav);
    CHECK(player->load(nullptr, wav, WavSize) == Result::InvalidArguments);
    CHECK(player->load("", wav, WavSize) == Result::InvalidArguments);
    CHECK(player->load("tone.wav", nullptr, WavSize) == Result::InvalidArguments);
    CHECK(player->load("tone.wav", wav, 0u) == Result::InvalidArguments);
    CHECK(player->load("tone.wav", wav, WavSize) == Result::Success);
    CHECK(player->load("tone.wav", wav, WavSize) == Result::InsufficientCondition);
    std::memset(wav, 0, sizeof(wav));

    CHECK(player->gain(0.75f) == Result::Success);
    CHECK(player->gain(Bus::Music, 0.6f) == Result::Success);
    CHECK(player->gain(Bus::Effect, 0.8f) == Result::Success);
    CHECK(player->gain(Bus::Ui, 0.9f) == Result::Success);
    CHECK(player->gain(-0.1f) == Result::InvalidArguments);
    CHECK(player->gain(static_cast<Bus>(255u), 1.0f) == Result::InvalidArguments);
    CHECK(player->start() == Result::Success);
    CHECK(player->start() == Result::Success);

    Playback effect;
    effect.asset = "tone.wav";
    effect.bus = Bus::Effect;
    effect.gain = 0.8f;
    Voice first;
    Voice second;
    CHECK(player->play(effect, &first) == Result::Success && first);
    CHECK(player->play(effect, &second) == Result::Success && second);
    CHECK(first.index != second.index);
    CHECK(player->active(first) && player->active(second));

    Playback music;
    music.asset = "tone.wav";
    music.bus = Bus::Music;
    music.gain = 0.6f;
    music.loop = true;
    Voice background;
    CHECK(player->play(music, &background) == Result::Success && background);
    CHECK(player->active(background));

    Playback ui = effect;
    ui.bus = Bus::Ui;
    Voice click;
    CHECK(player->play(ui, &click) == Result::Success && click);
    CHECK(player->play(effect) == Result::InsufficientCondition);

    CHECK(player->stop(second) == Result::Success);
    CHECK(!player->active(second));
    CHECK(player->stop(second) == Result::InsufficientCondition);
    Voice replacement;
    CHECK(player->play(effect, &replacement) == Result::Success && replacement);
    CHECK(replacement.index == second.index);
    CHECK(replacement.generation != second.generation);
    CHECK(player->stop(second) == Result::InsufficientCondition);
    CHECK(player->active(replacement));

    Playback bad = effect;
    bad.asset = "missing.wav";
    CHECK(player->play(bad) == Result::InvalidArguments);
    bad = effect;
    bad.rate = 0.124f;
    CHECK(player->play(bad) == Result::InvalidArguments);
    bad.rate = 8.01f;
    CHECK(player->play(bad) == Result::InvalidArguments);
    bad = effect;
    bad.gain = 4.01f;
    CHECK(player->play(bad) == Result::InvalidArguments);

    CHECK(player->stop(first) == Result::Success);
    CHECK(player->stop(background) == Result::Success);
    CHECK(player->stop(click) == Result::Success);
    CHECK(player->stop(replacement) == Result::Success);

    auto scene = Scene::gen();
    auto soundscape = Soundscape::gen(scene);
    CHECK(scene && soundscape);
    if (!scene || !soundscape) {
        delete scene;
        delete player;
        return;
    }
    CueConfig backgroundCue;
    backgroundCue.asset = "tone.wav";
    backgroundCue.bus = Bus::Music;
    backgroundCue.end = 10.0f;
    backgroundCue.loop = true;
    Cue cue;
    CHECK(soundscape->cue(backgroundCue, cue) == Result::Success);
    CueConfig effectCue;
    effectCue.asset = "tone.wav";
    effectCue.begin = 2.0f;
    effectCue.end = 3.0f;
    CHECK(soundscape->cue(effectCue, cue) == Result::Success);
    CHECK(player->bind(soundscape) == Result::Success);

    Transport transport;
    transport.seek = true;
    CHECK(player->sync(transport) == Result::Success);
    transport.time = 2.5f;
    transport.rate = 0.5f;
    transport.playing = true;
    CHECK(player->sync(transport) == Result::Success);
    transport.time = 4.0f;
    transport.rate = 2.0f;
    CHECK(player->sync(transport) == Result::Success);
    transport.time = 1.25f;
    transport.playing = false;
    CHECK(player->sync(transport) == Result::Success);
    transport.playing = true;
    CHECK(player->sync(transport) == Result::Success);

    transport.time = -1.0f;
    CHECK(player->sync(transport) == Result::InvalidArguments);
    transport.time = 1.0f;
    transport.rate = 0.0f;
    CHECK(player->sync(transport) == Result::InvalidArguments);
    transport.rate = 8.01f;
    CHECK(player->sync(transport) == Result::InvalidArguments);

    CueConfig late = effectCue;
    late.begin = 5.0f;
    late.end = 6.0f;
    CHECK(soundscape->cue(late, cue) == Result::Success);
    transport.rate = 1.0f;
    CHECK(player->sync(transport) == Result::InsufficientCondition);
    CHECK(player->bind(soundscape) == Result::Success);
    CHECK(player->sync(transport) == Result::Success);
    CHECK(player->bind(nullptr) == Result::Success);
    delete scene;
    delete player;
}

static void lua()
{
    static constexpr const char* source = R"(
local scene = tmath.scene {width = 32, height = 32}
local music = tmath.audio.cue(scene, {
    asset = "music.wav", bus = "music", begin = 0, ["end"] = 4,
    gain = 0.8, loop = true,
})
music:gain(0.2, 1, 1, "linear")
return scene
)";
    Scene* scene = nullptr;
    Soundscape* soundscape = nullptr;
    char error[512] = {};
    auto result = audio::Lua::load(source, static_cast<uint32_t>(std::strlen(source)),
                                   "audio.lua", &scene, &soundscape,
                                   error, sizeof(error));
#if defined(TMATH_EXPECT_LUA)
    CHECK(result == Result::Success);
    CHECK(scene && soundscape && soundscape->scene() == scene);
    if (soundscape) {
        CHECK(soundscape->count() == 1u);
        CueConfig cue;
        CHECK(soundscape->cueAt(0u, cue));
        CHECK(cue.bus == Bus::Music && cue.loop && _near(cue.end, 4.0f));
        auto value = 0.0f;
        CHECK(soundscape->sample({0u}, 1.5f, value) == Result::Success);
        CHECK(_near(value, 0.5f));
    }
    delete scene;

    static constexpr const char* invalid = R"(
local scene = tmath.scene {}
tmath.audio.cue(scene, {asset = "bad.wav", bus = "voice"})
return scene
)";
    scene = nullptr;
    soundscape = nullptr;
    result = audio::Lua::load(invalid, static_cast<uint32_t>(std::strlen(invalid)),
                              "invalid-audio.lua", &scene, &soundscape,
                              error, sizeof(error));
    CHECK(result == Result::ScriptError && !scene && !soundscape);
    CHECK(std::strstr(error, "audio bus") != nullptr);
#else
    CHECK(result == Result::NonSupport && !scene && !soundscape);
#endif
}

#if defined(TMATH_EXPECT_LUA_RUNTIME)
static void retainedLua()
{
    static constexpr const char* source = R"(
local scene = tmath.scene {width = 32, height = 32}
local cue = tmath.audio.cue(scene, {asset = "tone.wav"})
tmath.runtime(scene, {
    fixed_step = 0.1,
    update = function(ctx, dt, time, tick)
        cue:gain(0.5, time, 0.1, "linear")
    end,
})
return scene
)";
    Scene* scene = nullptr;
    char error[512] = {};
    detail::LuaHostContext context;
    auto result = detail::luaHostLoad(
        source, static_cast<uint32_t>(std::strlen(source)), "audio-runtime.lua",
        &scene, error, sizeof(error), nullptr, nullptr, nullptr, nullptr, context);
    CHECK(result == Result::Success && scene);
    CHECK(context.audio.soundscape && context.runtime.runtime);
    if (context.runtime.runtime) {
        result = context.runtime.runtime->advance(0.11f);
        CHECK(result == Result::ScriptError);
        CHECK(context.runtime.runtime->failed());
        CHECK(std::strstr(context.runtime.runtime->error(),
                          "audio authoring is unavailable after loading") != nullptr);
    }
    delete scene;
}
#endif

int main()
{
    soundscape();
    player();
    lua();
#if defined(TMATH_EXPECT_LUA_RUNTIME)
    retainedLua();
#endif
    if (failures) std::fprintf(stderr, "%d audio test(s) failed\n", failures);
    return failures ? 1 : 0;
}
