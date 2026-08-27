-- Measure a circle's diameter with world-unit ticks and explicit boundary markers.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}
local center, radius = {0, 0.35}, 2
local diameter = 2 * radius
local from, to = {center[1] - radius, center[2]}, {center[1] + radius, center[2]}
local function marker(id, point, fill)
    return scene:point {id = id, point = point, radius = 6, fill = fill, layer = 30}
end

-- The ruler endpoints coincide with opposite points on the circle boundary.
local circle = scene:circle {id = "measure-circle", center = center, radius = radius, fill = "surface", stroke = "foreground", width = 3, layer = 0}
local ruler = scene:ruler {id = "measure-ruler", from = from, to = to, step = 0.5, tick = 10, stroke = "result", width = 3, layer = 20}
local points = {
    marker("measure-from", from, "result"),
    marker("measure-center", center, "focus"),
    marker("measure-to", to, "result"),
}
local value = scene:text {id = "measure-value", text = string.format("diameter = %.0f units", diameter), point = {0, -2.15}, role = "code", fill = "result", align = {0.5, 0.5}, layer = 40}

-- Draw the shape first, then let the ruler visibly traverse the measured span.
scene:draw_border_then_fill(circle, 0.75, "ease_out")
scene:grow_from_center(points[2], 0.24, "ease_out")
scene:create(ruler, 1.05, "linear")
scene:grow_from_center(points[1], 0.18, "ease_out")
scene:grow_from_center(points[3], 0.18, "ease_out")
scene:fade_in(value, {shift = {0, 0.12}, duration = 0.4, curve = "gentle"})
scene:wait(1.2)
return scene
