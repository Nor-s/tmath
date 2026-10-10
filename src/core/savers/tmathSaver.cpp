#include <cmath>
#include <cstdio>
#include <cstring>
#include <limits>
#include <new>

#if !defined(__EMSCRIPTEN__) && !defined(_WIN32)
#include <signal.h>
#include <unistd.h>
#if defined(__APPLE__)
#include <fcntl.h>
#else
#include <cerrno>
#include <pthread.h>
#include <time.h>
#endif
#endif

#include "tmath.h"
#include "tmathSaver.h"

namespace tmath
{

static uint32_t _crc(uint32_t crc, const uint8_t* data, size_t size)
{
    crc = ~crc;
    for (auto i = 0u; i < size; i++) {
        crc ^= data[i];
        for (auto bit = 0; bit < 8; bit++)
            crc = (crc >> 1) ^ (0xedb88320u & (0u - (crc & 1u)));
    }
    return ~crc;
}

static uint32_t _adler(const uint8_t* data, size_t size)
{
    uint32_t a = 1;
    uint32_t b = 0;
    for (auto i = 0u; i < size; i++) {
        a = (a + data[i]) % 65521u;
        b = (b + a) % 65521u;
    }
    return (b << 16) | a;
}

static void _be32(uint8_t* data, uint32_t value)
{
    data[0] = static_cast<uint8_t>(value >> 24);
    data[1] = static_cast<uint8_t>(value >> 16);
    data[2] = static_cast<uint8_t>(value >> 8);
    data[3] = static_cast<uint8_t>(value);
}

static bool _write(FILE* file, const void* data, size_t size)
{
    return std::fwrite(data, 1, size, file) == size;
}

static bool _chunk(FILE* file, const char* type, const uint8_t* data, uint32_t size)
{
    uint8_t length[4];
    _be32(length, size);
    if (!_write(file, length, sizeof(length)) || !_write(file, type, 4)) return false;
    if (size && !_write(file, data, size)) return false;
    auto crc = _crc(0, reinterpret_cast<const uint8_t*>(type), 4);
    crc = _crc(crc, data, size);
    uint8_t checksum[4];
    _be32(checksum, crc);
    return _write(file, checksum, sizeof(checksum));
}

static uint8_t* _rgba(const Surface& surface, bool filters, size_t& size)
{
    auto limit = std::numeric_limits<size_t>::max();
    if (surface.width() > limit / 4u) return nullptr;
    auto row = static_cast<size_t>(surface.width()) * 4;
    auto stride = row + (filters ? 1u : 0u);
    if (stride < row || surface.height() > limit / stride) return nullptr;
    size = stride * surface.height();
    auto output = new (std::nothrow) uint8_t[size];
    if (!output) return nullptr;
    size_t offset = 0;
    for (auto y = 0u; y < surface.height(); y++) {
        if (filters) output[offset++] = 0;
        for (auto x = 0u; x < surface.width(); x++) {
            auto pixel = surface.data()[static_cast<size_t>(y) * surface.stride() + x];
            output[offset++] = static_cast<uint8_t>(pixel);
            output[offset++] = static_cast<uint8_t>(pixel >> 8);
            output[offset++] = static_cast<uint8_t>(pixel >> 16);
            output[offset++] = static_cast<uint8_t>(pixel >> 24);
        }
    }
    return output;
}

Result Saver::png(const Surface& surface, const char* path) noexcept
{
    if (!surface.data() || !surface.width() || !surface.height() || surface.stride() < surface.width() || !path) {
        return Result::InvalidArguments;
    }
    size_t rawSize;
    auto raw = _rgba(surface, true, rawSize);
    if (!raw) return Result::OutOfMemory;
    auto blocks = rawSize / 65535u + (rawSize % 65535u ? 1u : 0u);
    if (rawSize > UINT32_MAX - 6u || blocks * 5u > UINT32_MAX - 6u - rawSize) {
        delete[] raw;
        return Result::OutOfMemory;
    }
    auto zlibSize = 2u + rawSize + blocks * 5u + 4u;
    auto zlib = new (std::nothrow) uint8_t[zlibSize];
    if (!zlib) {
        delete[] raw;
        return Result::OutOfMemory;
    }

    size_t offset = 0;
    zlib[offset++] = 0x78;
    zlib[offset++] = 0x01;
    size_t input = 0;
    while (input < rawSize) {
        auto remaining = rawSize - input;
        auto length = static_cast<uint16_t>(remaining > 65535u ? 65535u : remaining);
        auto final = input + length == rawSize;
        zlib[offset++] = final ? 1 : 0;
        zlib[offset++] = static_cast<uint8_t>(length);
        zlib[offset++] = static_cast<uint8_t>(length >> 8);
        auto inverse = static_cast<uint16_t>(~length);
        zlib[offset++] = static_cast<uint8_t>(inverse);
        zlib[offset++] = static_cast<uint8_t>(inverse >> 8);
        std::memcpy(zlib + offset, raw + input, length);
        offset += length;
        input += length;
    }
    auto adler = _adler(raw, rawSize);
    _be32(zlib + offset, adler);
    offset += 4;
    delete[] raw;

    auto file = std::fopen(path, "wb");
    if (!file) {
        delete[] zlib;
        return Result::IoError;
    }
    static constexpr uint8_t signature[8] = {137, 80, 78, 71, 13, 10, 26, 10};
    uint8_t header[13] = {};
    _be32(header, surface.width());
    _be32(header + 4, surface.height());
    header[8] = 8;
    header[9] = 6;
    auto ok = _write(file, signature, sizeof(signature));
    if (ok) ok = _chunk(file, "IHDR", header, sizeof(header));
    if (ok) ok = _chunk(file, "IDAT", zlib, static_cast<uint32_t>(offset));
    if (ok) ok = _chunk(file, "IEND", nullptr, 0);
    if (std::fclose(file) != 0) ok = false;
    delete[] zlib;
    return ok ? Result::Success : Result::IoError;
}

#if !defined(__EMSCRIPTEN__) && !defined(_WIN32)
static char* _quote(const char* path)
{
    auto size = std::strlen(path);
    if (size > (std::numeric_limits<size_t>::max() - 3u) / 4u) return nullptr;
    auto output = new (std::nothrow) char[size * 4 + 3];
    if (!output) return nullptr;
    auto offset = 0u;
    output[offset++] = '\'';
    for (auto i = 0u; i < size; i++) {
        if (path[i] == '\'') {
            output[offset++] = '\'';
            output[offset++] = '\\';
            output[offset++] = '\'';
            output[offset++] = '\'';
        } else {
            output[offset++] = path[i];
        }
    }
    output[offset++] = '\'';
    output[offset] = '\0';
    return output;
}

static char* _temporary(const char* path)
{
    auto size = std::strlen(path);
    static constexpr char suffix[] = ".tmath-XXXXXX";
    if (size > std::numeric_limits<size_t>::max() - sizeof(suffix)) return nullptr;
    auto output = new (std::nothrow) char[size + sizeof(suffix)];
    if (!output) return nullptr;
    std::memcpy(output, path, size);
    std::memcpy(output + size, suffix, sizeof(suffix));
    auto descriptor = mkstemp(output);
    if (descriptor < 0) {
        delete[] output;
        return nullptr;
    }
    if (close(descriptor) == 0) return output;
    unlink(output);
    delete[] output;
    return nullptr;
}

#if !defined(__APPLE__)
struct SigpipeGuard
{
    sigset_t mask = {};
    sigset_t previous = {};
    bool active = false;
    bool pending = false;

    bool block()
    {
        sigemptyset(&mask);
        sigaddset(&mask, SIGPIPE);
        sigset_t current = {};
        if (sigpending(&current) != 0) return false;
        pending = sigismember(&current, SIGPIPE) == 1;
        if (pthread_sigmask(SIG_BLOCK, &mask, &previous) != 0) return false;
        active = true;
        return true;
    }

    void restore()
    {
        if (!active) return;
        if (!pending) {
            sigset_t current = {};
            if (sigpending(&current) == 0 && sigismember(&current, SIGPIPE) == 1) {
                timespec timeout = {};
                while (sigtimedwait(&mask, nullptr, &timeout) < 0 && errno == EINTR) {
                }
            }
        }
        pthread_sigmask(SIG_SETMASK, &previous, nullptr);
        active = false;
    }
};
#endif
#endif

bool saver::ends(const char* value, const char* suffix) noexcept
{
    if (!value || !suffix) return false;
    auto valueSize = std::strlen(value);
    auto suffixSize = std::strlen(suffix);
    return valueSize >= suffixSize && std::strcmp(value + valueSize - suffixSize, suffix) == 0;
}

Result saver::timeline(const Scene* scene, uint32_t& fps, uint32_t& frames) noexcept
{
    if (!scene) return Result::InvalidArguments;
    auto& config = scene->config();
    if (!fps) fps = config.fps;
    if (!fps || !config.width || !config.height) return Result::InvalidArguments;
    auto total = scene->duration();
    if (!std::isfinite(total) || total < 0.0f) return Result::InvalidArguments;
    auto samples = static_cast<double>(total) * fps;
    if (!std::isfinite(samples)) return Result::InvalidArguments;
    auto adjacent = std::nextafter(total, std::numeric_limits<float>::infinity());
    if (std::isfinite(adjacent)) {
        auto tolerance = (static_cast<double>(adjacent) - total) * fps;
        auto integer = std::round(samples);
        if (std::fabs(samples - integer) <= tolerance) samples = integer;
    }
    auto frameValue = std::ceil(samples);
    if (!std::isfinite(frameValue) || frameValue > UINT32_MAX) return Result::InvalidArguments;
    frames = frameValue < 1.0 ? 1u : static_cast<uint32_t>(frameValue);
    return Result::Success;
}

Result saver::frames(const Scene* scene, SwRenderer* renderer, const char* path, uint32_t fps,
                     const char* options, bool evenDimensions) noexcept
{
#if defined(__EMSCRIPTEN__) || defined(_WIN32)
    static_cast<void>(scene);
    static_cast<void>(renderer);
    static_cast<void>(path);
    static_cast<void>(fps);
    static_cast<void>(options);
    static_cast<void>(evenDimensions);
    return Result::NonSupport;
#else
    if (!scene || !renderer || !path || !path[0] || !options || !options[0]) return Result::InvalidArguments;
    auto& config = scene->config();
    uint32_t frameCount;
    auto result = timeline(scene, fps, frameCount);
    if (result != Result::Success) return result;
    if (evenDimensions && ((config.width & 1u) || (config.height & 1u))) return Result::InvalidArguments;
    auto temporary = _temporary(path);
    if (!temporary) return Result::IoError;
    auto quoted = _quote(temporary);
    if (!quoted) {
        unlink(temporary);
        delete[] temporary;
        return Result::OutOfMemory;
    }
    auto optionSize = std::strlen(options);
    if (std::strlen(quoted) > std::numeric_limits<size_t>::max() - optionSize - 384u) {
        delete[] quoted;
        unlink(temporary);
        delete[] temporary;
        return Result::OutOfMemory;
    }
    auto commandSize = std::strlen(quoted) + optionSize + 384u;
    auto command = new (std::nothrow) char[commandSize];
    if (!command) {
        delete[] quoted;
        unlink(temporary);
        delete[] temporary;
        return Result::OutOfMemory;
    }
    auto commandLength = std::snprintf(command, commandSize,
                                       "ffmpeg -loglevel error -y -f rawvideo -pixel_format rgba -video_size %ux%u -framerate %u -i pipe:0 %s %s",
                                       config.width, config.height, fps, options, quoted);
    delete[] quoted;
    if (commandLength < 0 || static_cast<size_t>(commandLength) >= commandSize) {
        delete[] command;
        unlink(temporary);
        delete[] temporary;
        return Result::OutOfMemory;
    }
    auto pipe = popen(command, "w");
    delete[] command;
    if (!pipe) {
        unlink(temporary);
        delete[] temporary;
        return Result::NonSupport;
    }

#if defined(__APPLE__)
    if (fcntl(fileno(pipe), F_SETNOSIGPIPE, 1) != 0) {
        pclose(pipe);
        unlink(temporary);
        delete[] temporary;
        return Result::IoError;
    }
#else
    SigpipeGuard sigpipe;
    if (!sigpipe.block()) {
        pclose(pipe);
        unlink(temporary);
        delete[] temporary;
        return Result::IoError;
    }
#endif

    Surface surface;
    uint8_t* bytes = nullptr;
    size_t byteSize = 0;
    result = Result::Success;
    for (auto frame = 0u; frame < frameCount; frame++) {
        auto time = static_cast<float>(frame) / static_cast<float>(fps);
        result = renderer->render(scene, time, surface);
        if (result != Result::Success) break;
        if (!bytes) {
            bytes = _rgba(surface, false, byteSize);
            if (!bytes) {
                result = Result::OutOfMemory;
                break;
            }
        } else {
            auto offset = 0u;
            for (auto y = 0u; y < surface.height(); y++) {
                for (auto x = 0u; x < surface.width(); x++) {
                    auto pixel = surface.data()[static_cast<size_t>(y) * surface.stride() + x];
                    bytes[offset++] = static_cast<uint8_t>(pixel);
                    bytes[offset++] = static_cast<uint8_t>(pixel >> 8);
                    bytes[offset++] = static_cast<uint8_t>(pixel >> 16);
                    bytes[offset++] = static_cast<uint8_t>(pixel >> 24);
                }
            }
        }
        if (std::fwrite(bytes, 1, byteSize, pipe) != byteSize) {
            result = Result::IoError;
            break;
        }
    }
    delete[] bytes;
    auto status = pclose(pipe);
#if !defined(__APPLE__)
    sigpipe.restore();
#endif
    if (status != 0 && result == Result::Success) result = Result::IoError;
    if (result == Result::Success && std::rename(temporary, path) != 0) result = Result::IoError;
    if (result != Result::Success) unlink(temporary);
    delete[] temporary;
    return result;
#endif
}

Result Saver::video(const Scene* scene, SwRenderer* renderer, const char* path, uint32_t fps) noexcept
{
    if (!scene || !renderer || !path || !path[0]) return Result::InvalidArguments;
    auto gif = saver::ends(path, ".gif");
    auto mp4 = saver::ends(path, ".mp4");
    if (!gif && !mp4) return Result::InvalidArguments;
#if defined(__EMSCRIPTEN__) || defined(_WIN32)
    static_cast<void>(fps);
    return Result::NonSupport;
#else
    if (gif) return saver::gif(scene, renderer, path, fps);
    return saver::video(scene, renderer, path, fps);
#endif
}

Result Saver::save(const Scene* scene, Renderer& renderer, const char* path, uint32_t fps) noexcept
{
    if (renderer.engine() != RenderEngine::Cpu) return Result::NonSupport;
    return video(scene, renderer.cpuBackend(), path, fps);
}

}  // namespace tmath
