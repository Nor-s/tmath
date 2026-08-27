#include <cmath>
#include <cstdio>
#include <limits>

#include "tmath_chart.h"

using namespace tmath;
using namespace tmath::chart;
namespace tc = tmath::chart;

static int failures = 0;

#define CHECK(condition)                                                                       \
    do {                                                                                       \
        if (!(condition)) {                                                                    \
            std::fprintf(stderr, "%s:%d: check failed: %s\n", __FILE__, __LINE__, #condition); \
            failures++;                                                                        \
        }                                                                                      \
    } while (false)

static bool near(float lhs, float rhs, float epsilon = 1.0e-4f)
{
    return std::fabs(lhs - rhs) <= epsilon;
}

static bool equal(Color lhs, Color rhs)
{
    return lhs.r == rhs.r && lhs.g == rhs.g && lhs.b == rhs.b && lhs.a == rhs.a;
}

static tc::Config config()
{
    tc::Config output;
    output.id = "metrics";
    output.frame = {{10.0f, 5.0f}, {8.0f, 4.0f}};
    output.x = {0.0f, 10.0f, 1.0f};
    output.y = {-10.0f, 10.0f, 1.0f};
    output.xTicks = 3u;
    output.yTicks = 3u;
    output.padding = 1.0f;
    output.lineWidth = 0.1f;
    output.barGap = 0.1f;
    return output;
}

static void invalidInputs()
{
    auto invalid = config();
    invalid.id = nullptr;
    CHECK(Chart::gen(invalid) == nullptr);
    invalid = config();
    invalid.frame.size.x = invalid.padding * 2.0f;
    CHECK(Chart::gen(invalid) == nullptr);
    invalid = config();
    invalid.x.max = invalid.x.min;
    CHECK(Chart::gen(invalid) == nullptr);
    invalid = config();
    invalid.x.min = -std::numeric_limits<float>::max();
    invalid.x.max = std::numeric_limits<float>::max();
    CHECK(Chart::gen(invalid) == nullptr);
    invalid = config();
    invalid.xTicks = 1u;
    CHECK(Chart::gen(invalid) == nullptr);

    auto chart = Chart::gen(config());
    CHECK(chart);
    if (!chart) return;
    Built* empty = nullptr;
    CHECK(chart->build(Theme::preset(ThemePreset::ThreeBlueOneEyes), empty)
              == Result::InsufficientCondition
          && !empty);

    tc::Point one[] = {{0.0f, 1.0f}};
    Series line;
    CHECK(chart->add({"line", nullptr, Mark::Line, one, 1u}, line)
              == Result::InvalidArguments
          && !line);
    tc::Point bad[] = {{0.0f, std::numeric_limits<float>::quiet_NaN()}};
    CHECK(chart->add({"bad", nullptr, Mark::Bar, bad, 1u}, line)
              == Result::InvalidArguments
          && !line);

    tc::Point valid[] = {{0.0f, 1.0f}, {1.0f, 2.0f}};
    CHECK(chart->add({"line", nullptr, Mark::Line, valid, 2u}, line)
          == Result::Success);
    Series duplicate;
    CHECK(chart->add({"line", nullptr, Mark::Line, valid, 2u}, duplicate)
              == Result::InvalidArguments
          && !duplicate);
    CHECK(chart->add({"another", nullptr, Mark::Line, valid, 2u}, line)
          == Result::InvalidArguments);
    delete chart;

    auto colorChart = Chart::gen(config());
    Series explicitColor;
    CHECK(colorChart
          && colorChart->add({"explicit", nullptr, Mark::Line, valid, 2u, 1}, explicitColor)
                 == Result::Success);
    Theme narrow = Theme::preset(ThemePreset::ThreeBlueOneEyes);
    narrow.objectCount = 1u;
    Built* failed = nullptr;
    CHECK(colorChart->build(narrow, failed) == Result::InvalidArguments && !failed);
    narrow.objectCount = 2u;
    CHECK(colorChart->build(narrow, failed) == Result::Success && failed);
    delete failed;
    delete colorChart;
}

static void mappingAndColors()
{
    auto chart = Chart::gen(config());
    CHECK(chart);
    if (!chart) return;
    tc::Point lineData[] = {{0.0f, -10.0f}, {10.0f, 10.0f}, {5.0f, 0.0f}};
    tc::Point barData[] = {{2.0f, -5.0f}, {8.0f, 5.0f}};
    Series line;
    Series bars;
    CHECK(chart->add({"latency", "Latency", Mark::Line, lineData, 3u}, line)
          == Result::Success);
    CHECK(chart->add({"delta", "Delta", Mark::Bar, barData, 2u}, bars)
          == Result::Success);
    lineData[0] = {9.0f, 9.0f};
    barData[0] = {9.0f, 9.0f};

    Theme theme = Theme::preset(ThemePreset::ThreeBlueOneEyes);
    theme.objects[0] = {210, 20, 30, 255};
    theme.objects[1] = {20, 180, 70, 255};
    theme.objectCount = 2u;
    theme.axis.grid = {1, 2, 3, 90};
    theme.axis.label = {4, 5, 6, 255};
    Built* built = nullptr;
    CHECK(chart->build(theme, built) == Result::Success && built);
    if (!built) {
        delete chart;
        return;
    }

    CHECK(built->root() && built->axes() && built->grid() && built->labels());
    CHECK(built->root()->childCount() == 4u);
    CHECK(built->series(line) && built->series(line)->type() == Type::Plot);
    CHECK(built->markCount(line) == 1u && built->mark(line, 0u) == built->series(line));
    CHECK(!built->mark(line, 1u));
    auto plot = static_cast<Plot*>(built->series(line));
    CHECK(plot->count() == 3u);
    CHECK(near(plot->points()[0].x, 7.0f) && near(plot->points()[0].y, 4.0f));
    CHECK(near(plot->points()[1].x, 13.0f) && near(plot->points()[1].y, 6.0f));
    CHECK(near(plot->points()[2].x, 10.0f) && near(plot->points()[2].y, 5.0f));
    CHECK(equal(plot->style.stroke, theme.objects[0]));

    CHECK(built->series(bars) && built->series(bars)->type() == Type::Group);
    CHECK(built->markCount(bars) == 2u);
    auto negative = static_cast<Rectangle*>(built->mark(bars, 0u));
    auto positive = static_cast<Rectangle*>(built->mark(bars, 1u));
    CHECK(negative && positive);
    if (negative && positive) {
        CHECK(near(negative->center.y, 4.75f) && near(negative->size.y, 0.5f));
        CHECK(near(positive->center.y, 5.25f) && near(positive->size.y, 0.5f));
        CHECK(equal(negative->style.fill, theme.objects[1]));
        CHECK(equal(positive->style.fill, theme.objects[1]));
    }
    CHECK(built->legend(line) && built->legend(bars));
    CHECK(built->legend(line)->role == TextRole::Code
          && equal(built->legend(line)->style.fill, theme.objects[0]));
    CHECK(built->xTickCount() == 3u && built->yTickCount() == 3u);
    CHECK(built->xTick(0u) && built->xTick(0u)->role == TextRole::Code
          && equal(built->xTick(0u)->style.fill, theme.axis.label));
    CHECK(built->grid()->childCount() == 6u);
    CHECK(equal(built->grid()->childAt(0u)->style.stroke, theme.axis.grid));

    auto root = built->release();
    CHECK(root && !built->root() && !built->release());
    CHECK(built->series(line) == plot && built->mark(bars, 0u) == negative);
    auto scene = Scene::gen();
    CHECK(scene && scene->theme(theme) == Result::Success);
    CHECK(scene && scene->add(root) == Result::Success);
    CHECK(scene && scene->object("metrics/series/latency") == plot);
    CHECK(scene && scene->object("metrics/series/delta/0") == negative);
    delete built;
    delete chart;
    delete scene;
}

static void clampedZeroBaseline()
{
    auto positiveConfig = config();
    positiveConfig.y = {10.0f, 20.0f, 1.0f};
    auto chart = Chart::gen(positiveConfig);
    tc::Point data[] = {{5.0f, 15.0f}};
    Series bars;
    CHECK(chart && chart->add({"positive", nullptr, Mark::Bar, data, 1u}, bars)
                       == Result::Success);
    Built* built = nullptr;
    CHECK(chart
          && chart->build(Theme::preset(ThemePreset::ThreeBlueOneEyes), built) == Result::Success
          && built);
    if (built) {
        auto bar = static_cast<Rectangle*>(built->mark(bars, 0u));
        CHECK(bar && near(bar->center.y, 4.5f) && near(bar->size.y, 1.0f));
    }
    delete built;
    delete chart;
}

static void explicitColorDoesNotAdvanceCycle()
{
    auto chart = Chart::gen(config());
    tc::Point data[] = {{0.0f, 0.0f}, {1.0f, 1.0f}};
    Series explicitSeries;
    Series automaticSeries;
    CHECK(chart
          && chart->add({"fixed", nullptr, Mark::Line, data, 2u, 2}, explicitSeries)
                 == Result::Success);
    CHECK(chart
          && chart->add({"auto", nullptr, Mark::Line, data, 2u}, automaticSeries)
                 == Result::Success);
    Theme theme = Theme::preset(ThemePreset::ThreeBlueOneEyes);
    theme.objectCount = 3u;
    Built* built = nullptr;
    CHECK(chart && chart->build(theme, built) == Result::Success && built);
    if (built) {
        CHECK(equal(built->series(explicitSeries)->style.stroke, theme.objects[2]));
        CHECK(equal(built->series(automaticSeries)->style.stroke, theme.objects[0]));
    }
    delete built;
    delete chart;
}

int main()
{
    invalidInputs();
    mappingAndColors();
    clampedZeroBaseline();
    explicitColorDoesNotAdvanceCycle();
    if (failures) std::fprintf(stderr, "%d chart checks failed\n", failures);
    return failures ? 1 : 0;
}
