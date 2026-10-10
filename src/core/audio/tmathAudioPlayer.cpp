#include <cmath>
#include <cstring>
#include <new>

#include <miniaudio.h>

#include "tmath_audio.h"

namespace tmath::audio
{

namespace
{

static bool _bus(Bus bus) noexcept
{
    return static_cast<uint8_t>(bus) <= static_cast<uint8_t>(Bus::Ui);
}

static bool _gain(float value) noexcept
{
    return std::isfinite(value) && value >= 0.0f && value <= 4.0f;
}

static bool _rate(float value) noexcept
{
    return std::isfinite(value) && value >= 0.125f && value <= 8.0f;
}

static char* _copy(const char* value) noexcept
{
    if (!value) return nullptr;
    auto size = std::strlen(value) + 1u;
    auto copy = new (std::nothrow) char[size];
    if (copy) std::memcpy(copy, value, size);
    return copy;
}

static Result _result(ma_result value) noexcept
{
    switch (value) {
        case MA_SUCCESS: return Result::Success;
        case MA_INVALID_ARGS:
        case MA_OUT_OF_RANGE:
        case MA_TOO_BIG:
        case MA_NAME_TOO_LONG: return Result::InvalidArguments;
        case MA_INVALID_OPERATION:
        case MA_BUSY:
        case MA_UNAVAILABLE:
        case MA_ALREADY_IN_USE: return Result::InsufficientCondition;
        case MA_OUT_OF_MEMORY: return Result::OutOfMemory;
        case MA_DOES_NOT_EXIST:
        case MA_INVALID_FILE:
        case MA_BAD_SEEK:
        case MA_IO_ERROR: return Result::IoError;
        case MA_FORMAT_NOT_SUPPORTED:
        case MA_DEVICE_TYPE_NOT_SUPPORTED:
        case MA_NO_BACKEND:
        case MA_NO_DEVICE:
        case MA_API_NOT_FOUND:
        case MA_BACKEND_NOT_ENABLED:
        case MA_NOT_IMPLEMENTED: return Result::NonSupport;
        default: return Result::Unknown;
    }
}

}  // namespace

struct Player::Impl
{
    struct Asset
    {
        char* name = nullptr;
        uint8_t* data = nullptr;
        uint32_t size = 0u;
        bool registered = false;
    };

    struct VoiceSlot
    {
        ma_sound sound = {};
        uint32_t generation = 0u;
        bool initialized = false;
        bool loop = false;
    };

    struct TrackSlot
    {
        ma_sound sound = {};
        float length = 0.0f;
        bool initialized = false;
    };

    ~Impl()
    {
        for (auto i = 0u; i < assetCount; i++) {
            delete[] assets[i].name;
            delete[] assets[i].data;
        }
        delete[] voices;
        delete[] tracks;
    }

    Asset* asset(const char* name) noexcept
    {
        if (!name) return nullptr;
        for (auto i = 0u; i < assetCount; i++) {
            if (std::strcmp(assets[i].name, name) == 0) return assets + i;
        }
        return nullptr;
    }

    ma_sound_group* group(Bus bus) noexcept
    {
        return groups + static_cast<uint8_t>(bus);
    }

    void clearTracks() noexcept
    {
        for (auto i = 0u; i < trackCount; i++) {
            if (!tracks[i].initialized) continue;
            ma_sound_stop(&tracks[i].sound);
            ma_sound_uninit(&tracks[i].sound);
            tracks[i] = {};
        }
    }

    void clearVoices() noexcept
    {
        for (auto i = 0u; i < config.voiceLimit; i++) {
            if (!voices[i].initialized) continue;
            ma_sound_stop(&voices[i].sound);
            ma_sound_uninit(&voices[i].sound);
            voices[i].initialized = false;
        }
    }

    void collect() noexcept
    {
        for (auto i = 0u; i < config.voiceLimit; i++) {
            auto& slot = voices[i];
            if (!slot.initialized || slot.loop || !ma_sound_at_end(&slot.sound)) continue;
            ma_sound_uninit(&slot.sound);
            slot.initialized = false;
        }
    }

    void uninit() noexcept
    {
        if (!initialized) return;
        clearTracks();
        clearVoices();
        auto manager = ma_engine_get_resource_manager(&engine);
        for (auto i = 0u; i < assetCount; i++) {
            if (!assets[i].registered) continue;
            ma_resource_manager_unregister_data(manager, assets[i].name);
            assets[i].registered = false;
        }
        for (auto i = groupCount; i > 0u; i--) ma_sound_group_uninit(groups + i - 1u);
        ma_engine_uninit(&engine);
        groupCount = 0u;
        initialized = false;
        started = false;
        transportValid = false;
    }

    Result init() noexcept
    {
        if (initialized) return Result::Success;
        auto engineConfig = ma_engine_config_init();
        engineConfig.sampleRate = 48000u;
        engineConfig.noAutoStart = MA_TRUE;
        engineConfig.noDevice = config.device ? MA_FALSE : MA_TRUE;
        if (!config.device) engineConfig.channels = 2u;
        engineConfig.defaultVolumeSmoothTimeInPCMFrames = 128u;
        auto status = ma_engine_init(&engineConfig, &engine);
        if (status != MA_SUCCESS) return _result(status);

        for (auto i = 0u; i < 3u; i++) {
            status = ma_sound_group_init(&engine, MA_SOUND_FLAG_NO_SPATIALIZATION,
                                         nullptr, groups + i);
            if (status != MA_SUCCESS) {
                groupCount = i;
                initialized = true;
                uninit();
                return _result(status);
            }
            groupCount++;
            ma_sound_group_set_volume(groups + i, busGain[i]);
        }
        status = ma_engine_set_volume(&engine, masterGain);
        if (status != MA_SUCCESS) {
            initialized = true;
            uninit();
            return _result(status);
        }

        auto manager = ma_engine_get_resource_manager(&engine);
        for (auto i = 0u; i < assetCount; i++) {
            status = ma_resource_manager_register_encoded_data(
                manager, assets[i].name, assets[i].data, assets[i].size);
            if (status != MA_SUCCESS) {
                initialized = true;
                uninit();
                return _result(status);
            }
            assets[i].registered = true;
        }
        initialized = true;
        return Result::Success;
    }

    Result init(TrackSlot& slot, const CueConfig& cue) noexcept
    {
        if (slot.initialized) return Result::Success;
        if (!asset(cue.asset)) return Result::InsufficientCondition;
        auto flags = static_cast<ma_uint32>(MA_SOUND_FLAG_NO_SPATIALIZATION);
        if (cue.bus != Bus::Music) flags |= MA_SOUND_FLAG_DECODE;
        if (cue.loop) flags |= MA_SOUND_FLAG_LOOPING;
        auto status = ma_sound_init_from_file(&engine, cue.asset, flags,
                                              group(cue.bus), nullptr, &slot.sound);
        if (status != MA_SUCCESS) return _result(status);
        slot.initialized = true;
        ma_sound_set_volume(&slot.sound, cue.gain);
        ma_sound_set_looping(&slot.sound, cue.loop ? MA_TRUE : MA_FALSE);
        if (ma_sound_get_length_in_seconds(&slot.sound, &slot.length) != MA_SUCCESS) {
            slot.length = 0.0f;
        }
        return Result::Success;
    }

    PlayerConfig config;
    ma_engine engine = {};
    ma_sound_group groups[3] = {};
    Asset assets[AssetLimit];
    VoiceSlot* voices = nullptr;
    TrackSlot* tracks = nullptr;
    const Soundscape* soundscape = nullptr;
    uint32_t assetCount = 0u;
    uint32_t assetBytes = 0u;
    uint32_t trackCount = 0u;
    uint32_t groupCount = 0u;
    float masterGain = 1.0f;
    float busGain[3] = {1.0f, 1.0f, 1.0f};
    float transportTime = 0.0f;
    float transportRate = 1.0f;
    bool initialized = false;
    bool started = false;
    bool transportPlaying = false;
    bool transportValid = false;
};

Player::Player(const PlayerConfig& config) noexcept : pImpl(new (std::nothrow) Impl)
{
    if (!pImpl) return;
    pImpl->config = config;
    pImpl->voices = new (std::nothrow) Impl::VoiceSlot[config.voiceLimit];
}

Player::~Player()
{
    if (pImpl) pImpl->uninit();
    delete pImpl;
}

Player* Player::gen(const PlayerConfig& config) noexcept
{
    if (!config.voiceLimit || config.voiceLimit > VoiceLimit) return nullptr;
    auto player = new (std::nothrow) Player(config);
    if (!player || !player->pImpl || !player->pImpl->voices) {
        delete player;
        return nullptr;
    }
    return player;
}

Result Player::load(const char* name, const uint8_t* data, uint32_t size) noexcept
{
    if (!pImpl || !name || !data || !size || size > AssetByteLimit) {
        return Result::InvalidArguments;
    }
    auto nameSize = std::strlen(name);
    if (!nameSize || nameSize > Soundscape::AssetNameLimit
        || pImpl->assetCount >= AssetLimit
        || size > AssetTotalByteLimit - pImpl->assetBytes) {
        return Result::InvalidArguments;
    }
    if (pImpl->asset(name)) return Result::InsufficientCondition;

    auto copiedName = _copy(name);
    auto copiedData = new (std::nothrow) uint8_t[size];
    if (!copiedName || !copiedData) {
        delete[] copiedName;
        delete[] copiedData;
        return Result::OutOfMemory;
    }
    std::memcpy(copiedData, data, size);

    auto& asset = pImpl->assets[pImpl->assetCount];
    asset.name = copiedName;
    asset.data = copiedData;
    asset.size = size;
    if (pImpl->initialized) {
        auto status = ma_resource_manager_register_encoded_data(
            ma_engine_get_resource_manager(&pImpl->engine), asset.name, asset.data, asset.size);
        if (status != MA_SUCCESS) {
            delete[] asset.name;
            delete[] asset.data;
            asset = {};
            return _result(status);
        }
        asset.registered = true;
    }
    pImpl->assetCount++;
    pImpl->assetBytes += size;
    return Result::Success;
}

Result Player::start() noexcept
{
    if (!pImpl) return Result::InvalidArguments;
    auto result = pImpl->init();
    if (result != Result::Success || pImpl->started) return result;
    if (pImpl->config.device) {
        auto status = ma_engine_start(&pImpl->engine);
        if (status != MA_SUCCESS) return _result(status);
    }
    pImpl->started = true;
    return Result::Success;
}

Result Player::play(const Playback& playback, Voice* output) noexcept
{
    if (output) *output = {};
    if (!pImpl || !playback.asset || !_bus(playback.bus)
        || !_gain(playback.gain) || !_rate(playback.rate)) {
        return Result::InvalidArguments;
    }
    auto result = pImpl->init();
    if (result != Result::Success) return result;
    if (!pImpl->asset(playback.asset)) return Result::InvalidArguments;
    pImpl->collect();

    auto index = Voice::Invalid;
    for (auto i = 0u; i < pImpl->config.voiceLimit; i++) {
        if (!pImpl->voices[i].initialized) {
            index = i;
            break;
        }
    }
    if (index == Voice::Invalid) return Result::InsufficientCondition;

    auto& slot = pImpl->voices[index];
    auto flags = static_cast<ma_uint32>(MA_SOUND_FLAG_NO_SPATIALIZATION);
    if (playback.bus != Bus::Music) flags |= MA_SOUND_FLAG_DECODE;
    if (playback.loop) flags |= MA_SOUND_FLAG_LOOPING;
    auto status = ma_sound_init_from_file(&pImpl->engine, playback.asset, flags,
                                          pImpl->group(playback.bus), nullptr, &slot.sound);
    if (status != MA_SUCCESS) return _result(status);
    slot.initialized = true;
    slot.loop = playback.loop;
    slot.generation++;
    if (!slot.generation) slot.generation = 1u;
    ma_sound_set_volume(&slot.sound, playback.gain);
    ma_sound_set_pitch(&slot.sound, playback.rate);
    ma_sound_set_looping(&slot.sound, playback.loop ? MA_TRUE : MA_FALSE);
    status = ma_sound_start(&slot.sound);
    if (status != MA_SUCCESS) {
        ma_sound_uninit(&slot.sound);
        slot.initialized = false;
        return _result(status);
    }
    if (output) *output = {index, slot.generation};
    return Result::Success;
}

Result Player::stop(Voice voice) noexcept
{
    if (!pImpl || voice.index >= pImpl->config.voiceLimit) return Result::InvalidArguments;
    auto& slot = pImpl->voices[voice.index];
    if (!slot.initialized || slot.generation != voice.generation) {
        return Result::InsufficientCondition;
    }
    ma_sound_stop(&slot.sound);
    ma_sound_uninit(&slot.sound);
    slot.initialized = false;
    return Result::Success;
}

bool Player::active(Voice voice) const noexcept
{
    if (!pImpl || voice.index >= pImpl->config.voiceLimit) return false;
    auto& slot = pImpl->voices[voice.index];
    return slot.initialized && slot.generation == voice.generation
        && ma_sound_is_playing(&slot.sound);
}

Result Player::gain(float value) noexcept
{
    if (!pImpl || !_gain(value)) return Result::InvalidArguments;
    pImpl->masterGain = value;
    if (!pImpl->initialized) return Result::Success;
    return _result(ma_engine_set_volume(&pImpl->engine, value));
}

Result Player::gain(Bus bus, float value) noexcept
{
    if (!pImpl || !_bus(bus) || !_gain(value)) return Result::InvalidArguments;
    pImpl->busGain[static_cast<uint8_t>(bus)] = value;
    if (pImpl->initialized) ma_sound_group_set_volume(pImpl->group(bus), value);
    return Result::Success;
}

Result Player::bind(const Soundscape* soundscape) noexcept
{
    if (!pImpl || (soundscape && !soundscape->scene())) return Result::InvalidArguments;
    auto count = soundscape ? soundscape->count() : 0u;
    auto tracks = count ? new (std::nothrow) Impl::TrackSlot[count] : nullptr;
    if (count && !tracks) return Result::OutOfMemory;
    pImpl->clearTracks();
    delete[] pImpl->tracks;
    pImpl->tracks = tracks;
    pImpl->trackCount = count;
    pImpl->soundscape = soundscape;
    pImpl->transportValid = false;
    return Result::Success;
}

Result Player::sync(const Transport& transport) noexcept
{
    if (!pImpl || !std::isfinite(transport.time) || transport.time < 0.0f
        || !_rate(transport.rate)) {
        return Result::InvalidArguments;
    }
    if (!pImpl->soundscape) {
        pImpl->transportTime = transport.time;
        pImpl->transportRate = transport.rate;
        pImpl->transportPlaying = transport.playing;
        pImpl->transportValid = true;
        return Result::Success;
    }
    auto result = pImpl->init();
    if (result != Result::Success) return result;
    if (pImpl->trackCount != pImpl->soundscape->count()) {
        return Result::InsufficientCondition;
    }

    auto hard = transport.seek || !pImpl->transportValid
             || (pImpl->transportValid && transport.time < pImpl->transportTime)
             || (pImpl->transportValid && transport.rate != pImpl->transportRate)
             || (pImpl->transportValid && transport.playing != pImpl->transportPlaying);
    for (auto i = 0u; i < pImpl->trackCount; i++) {
        CueConfig cue;
        if (!pImpl->soundscape->cueAt(i, cue)) return Result::Unknown;
        auto& slot = pImpl->tracks[i];
        result = pImpl->init(slot, cue);
        if (result != Result::Success) return result;

        auto local = transport.time - cue.begin;
        auto active = local >= 0.0f && (cue.end == 0.0f || transport.time < cue.end);
        if (active && !cue.loop && slot.length > 0.0f && local >= slot.length) active = false;
        auto offset = std::fmax(0.0f, local);
        if (cue.loop && slot.length > 0.0f) offset = std::fmod(offset, slot.length);

        float value;
        result = pImpl->soundscape->sample({i}, transport.time, value);
        if (result != Result::Success) return result;
        ma_sound_set_volume(&slot.sound, value);
        ma_sound_set_pitch(&slot.sound, transport.rate);

        if (!active) {
            if (ma_sound_is_playing(&slot.sound)) ma_sound_stop(&slot.sound);
            if (hard && local < 0.0f) ma_sound_seek_to_second(&slot.sound, 0.0f);
            continue;
        }

        float cursor = 0.0f;
        auto cursorResult = ma_sound_get_cursor_in_seconds(&slot.sound, &cursor);
        auto seek = hard || cursorResult != MA_SUCCESS || std::fabs(cursor - offset) > 0.08f;
        if (seek) {
            auto status = ma_sound_seek_to_second(&slot.sound, offset);
            if (status != MA_SUCCESS) return _result(status);
        }
        if (!transport.playing) {
            if (ma_sound_is_playing(&slot.sound)) ma_sound_stop(&slot.sound);
            continue;
        }
        if (!ma_sound_is_playing(&slot.sound)) {
            auto status = ma_sound_start(&slot.sound);
            if (status != MA_SUCCESS) return _result(status);
        }
    }
    pImpl->transportTime = transport.time;
    pImpl->transportRate = transport.rate;
    pImpl->transportPlaying = transport.playing;
    pImpl->transportValid = true;
    return Result::Success;
}

}  // namespace tmath::audio
