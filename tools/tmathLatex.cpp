#include <cerrno>
#include <cstdio>
#include <cstring>
#include <spawn.h>
#include <sys/wait.h>
#include <unistd.h>

#include "tmathLatex.h"

extern char** environ;

static bool _path(char* output, size_t capacity, const char* directory,
                  const char* name)
{
    auto written = std::snprintf(output, capacity, "%s/%s", directory, name);
    return written > 0 && static_cast<size_t>(written) < capacity;
}

static int _run(const char* name, char* const arguments[])
{
    pid_t process = 0;
    auto status = posix_spawnp(&process, name, nullptr, nullptr, arguments, environ);
    if (status != 0) {
        if (status == ENOENT) {
            std::fprintf(stderr, "tmath: experimental LaTeX requires '%s' on PATH\n", name);
        } else {
            std::fprintf(stderr, "tmath: could not start %s: %s\n", name,
                         std::strerror(status));
        }
        return -1;
    }
    while (waitpid(process, &status, 0) < 0) {
        if (errno != EINTR) {
            std::fprintf(stderr, "tmath: could not wait for %s: %s\n", name,
                         std::strerror(errno));
            return -1;
        }
    }
    if (WIFEXITED(status)) return WEXITSTATUS(status);
    return -1;
}

static bool _write(const char* path, const char* expression)
{
    auto file = std::fopen(path, "wb");
    if (!file) return false;
    auto success = std::fputs(
        "\\documentclass{article}\n"
        "\\usepackage{amsmath,amssymb}\n"
        "\\pagestyle{empty}\n"
        "\\begin{document}\n"
        "\\(\\displaystyle ", file) >= 0;
    success = success && std::fputs(expression, file) >= 0;
    success = success && std::fputs("\\)\n\\end{document}\n", file) >= 0;
    if (std::fclose(file) != 0) success = false;
    return success;
}

static bool _copy(const char* source, const char* destination)
{
    auto input = std::fopen(source, "rb");
    if (!input) return false;
    auto output = std::fopen(destination, "wb");
    if (!output) {
        std::fclose(input);
        return false;
    }
    char buffer[16384];
    auto success = true;
    while (auto read = std::fread(buffer, 1, sizeof(buffer), input)) {
        if (std::fwrite(buffer, 1, read, output) != read) {
            success = false;
            break;
        }
    }
    success = success && !std::ferror(input);
    if (std::fclose(input) != 0) success = false;
    if (std::fclose(output) != 0) success = false;
    return success;
}

static void _cleanup(const char* directory)
{
    static constexpr const char* Files[] = {
        "formula.aux", "formula.dvi", "formula.log", "formula.svg", "formula.tex"};
    char path[4096];
    for (auto file : Files) {
        if (_path(path, sizeof(path), directory, file)) unlink(path);
    }
    rmdir(directory);
}

int tmathLatex(int argc, char** argv) noexcept
{
    if (argc != 5 || std::strcmp(argv[3], "-o") != 0 || !argv[2][0]
        || !argv[4][0]) {
        std::fprintf(stderr, "Usage: tmath latex <expression> -o <output.svg>\n");
        return 2;
    }

    char directory[] = "/tmp/tmath-latex-XXXXXX";
    if (!mkdtemp(directory)) {
        std::fprintf(stderr, "tmath: could not create LaTeX workspace: %s\n",
                     std::strerror(errno));
        return 5;
    }
    char tex[4096];
    char dvi[4096];
    char svg[4096];
    char outputDirectory[4120];
    auto outputDirectorySize = std::snprintf(outputDirectory, sizeof(outputDirectory),
                                             "-output-directory=%s", directory);
    if (!_path(tex, sizeof(tex), directory, "formula.tex")
        || !_path(dvi, sizeof(dvi), directory, "formula.dvi")
        || !_path(svg, sizeof(svg), directory, "formula.svg")
        || outputDirectorySize <= 0
        || static_cast<size_t>(outputDirectorySize) >= sizeof(outputDirectory)) {
        _cleanup(directory);
        std::fprintf(stderr, "tmath: LaTeX workspace path is too long\n");
        return 5;
    }
    if (!_write(tex, argv[2])) {
        _cleanup(directory);
        std::fprintf(stderr, "tmath: could not write temporary LaTeX source\n");
        return 5;
    }

    char* latex[] = {
        const_cast<char*>("latex"), const_cast<char*>("-interaction=batchmode"),
        const_cast<char*>("-halt-on-error"), const_cast<char*>("-no-shell-escape"),
        outputDirectory, tex, nullptr};
    auto status = _run("latex", latex);
    if (status != 0) {
        _cleanup(directory);
        if (status > 0) std::fprintf(stderr, "tmath: LaTeX compilation failed (%d)\n", status);
        return status < 0 ? 3 : 4;
    }

    char* dvisvgm[] = {
        const_cast<char*>("dvisvgm"), const_cast<char*>("--no-fonts"),
        const_cast<char*>("--bbox=min"), const_cast<char*>("--output"), svg, dvi,
        nullptr};
    status = _run("dvisvgm", dvisvgm);
    if (status != 0) {
        _cleanup(directory);
        if (status > 0) std::fprintf(stderr, "tmath: dvisvgm conversion failed (%d)\n", status);
        return status < 0 ? 3 : 4;
    }

    auto copied = _copy(svg, argv[4]);
    _cleanup(directory);
    if (!copied) {
        std::fprintf(stderr, "tmath: could not write SVG output: %s\n", argv[4]);
        return 5;
    }
    std::printf("%s\n", argv[4]);
    return 0;
}
