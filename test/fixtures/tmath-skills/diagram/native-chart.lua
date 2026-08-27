-- Requires a Lua host built with -Dchart=enabled.
-- Question: how does observed latency move against the requested budget?
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = {mode = "fixed", view = "2d", target = {0, -30}, height = 540},
}

local sampleCount = 5
local chartFrame = {center = {0, -30}, size = {860, 360}}
local chartPadding = 50
local chart = tmath.chart(scene, {
    id = "latency",
    frame = chartFrame,
    -- Category centers occupy half-offset slots so edge bars stay inside the plot.
    x = {0, sampleCount, 1},
    y = {0, 120, 20},
    x_ticks = 0,
    y_ticks = 5,
    legend = false,
    padding = chartPadding,
    line_width = 2,
    bar_gap = 66,
})

local observed = chart:series {
    id = "observed", label = "Observed", mark = "bar",
    data = {{0.5, 104}, {1.5, 91}, {2.5, 76}, {3.5, 71}, {4.5, 69}},
}
local budget = chart:series {
    id = "budget", label = "Budget", mark = "line",
    data = {{0.5, 80}, {1.5, 80}, {2.5, 80}, {3.5, 80}, {4.5, 80}},
}

local built = chart:build()  -- axes, grid, labels, and marks are ordinary Objects
local plotLeft = chartFrame.center[1] - chartFrame.size[1] * 0.5 + chartPadding
local plotBottom = chartFrame.center[2] - chartFrame.size[2] * 0.5 + chartPadding
local plotWidth = chartFrame.size[1] - chartPadding * 2
local plotHeight = chartFrame.size[2] - chartPadding * 2
local sampleLabels = scene:group {id = "sample-labels"}
for index = 1, sampleCount do
    sampleLabels:text {
        text = "S" .. index,
        point = {plotLeft + plotWidth * (index - 0.5) / sampleCount, plotBottom - 27},
        align = {0.5, 0.5}, role = "code", fill = "muted", layer = 40,
        id = "sample-label-" .. index,
    }
end
local budgetLabel = scene:text {
    text = "80 ms budget",
    point = {plotLeft + plotWidth - 4, plotBottom + plotHeight * (80 / 120) + 18},
    align = {1, 0.5}, role = "code", layer = 40,
    id = "budget-label",
}
scene:style_group {
    members = {
        {target = built:series(budget), channel = "stroke"},
        {target = budgetLabel, channel = "fill"},
    },
}

scene:fade_in(built:grid(), {duration = 0.35, curve = "gentle"})
scene:create(built:axes(), 0.45, "ease_out")
scene:fade_in(built:labels(), {duration = 0.35, curve = "gentle"})
scene:fade_in(sampleLabels, {duration = 0.3, curve = "gentle"})
scene:create(built:series(budget), 0.6, "ease_out")
scene:fade_in(budgetLabel, {shift = {0, -6}, duration = 0.25, curve = "ease_out"})
for index = 1, built:mark_count(observed) do
    scene:grow_from_edge(built:mark(observed, index), "bottom", 0.34, "ease_out")
end
scene:wait(2.0)
return scene
