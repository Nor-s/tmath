-- Build with -Dchart=enabled. Series and marks remain ordinary Scene Objects.
local scene = tmath.scene {
    width = 800, height = 450, fps = 30, loop = false, theme = "pro_white",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 450},
}

local chart = tmath.chart(scene, {
    id = "throughput", frame = {center = {0, 0}, size = {680, 330}},
    x = {0, 4, 1}, y = {0, 100, 20}, x_ticks = 5, y_ticks = 5,
    padding = 44, line_width = 3, bar_gap = 18,
})
local target = chart:series {
    id = "target", label = "Target", mark = "bar",
    data = {{0, 60}, {1, 60}, {2, 60}, {3, 60}, {4, 60}},
}
local measured = chart:series {
    id = "measured", label = "Measured", mark = "line",
    data = {{0, 42}, {1, 55}, {2, 68}, {3, 77}, {4, 86}},
}
local built = chart:build()

scene:fade_in(built:grid(), {duration = 0.25, curve = "gentle"})
scene:create(built:axes(), 0.4, "ease_out")
scene:fade_in(built:series(target), {shift = {0, -8}, duration = 0.45})
scene:create(built:series(measured), 0.7, "ease_out")
scene:fade_in(built:labels(), {duration = 0.25})
scene:indicate(built:mark(measured, built:mark_count(measured)), {
    color = "result", duration = 0.35,
})
scene:wait(0.8)
return scene
