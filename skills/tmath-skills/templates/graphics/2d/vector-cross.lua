-- Visualize the signed 2D cross product as oriented parallelogram area.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.8},
}
local plane = scene:space {
    x = {-4.8, 4.8, 1}, y = {-2.2, 3.2, 1}, numbers = false,
    stroke = "border", width = 1,
}

local av, bv = {3, 1}, {1, 2}
local function cross2d(a, b) return a[1] * b[2] - a[2] * b[1] end
local function add(a, b) return {a[1] + b[1], a[2] + b[2]} end
local function vectorWithLabel(value, color, text, labelOffset, align)
    local vector = plane:vector {origin = {0, 0}, value = value, stroke = color, width = 4, tip = 13, layer = 20}
    local label = plane:text {text = text, point = {value[1] + labelOffset[1], value[2] + labelOffset[2]}, role = "code", fill = color, align = align, layer = 40}
    return vector, label
end

-- Translated copies of a and b close the parallelogram at a + b.
local cross = cross2d(av, bv)
local corner = add(av, bv)
local area = plane:polygon {
    points = {{0, 0}, av, corner, bv}, fill = "result", stroke = "result",
    opacity = 0.24, width = 2, layer = 8,
}
local a, aLabel = vectorWithLabel(av, "accent", "a", {0.18, -0.02}, {0, 0.5})
local b, bLabel = vectorWithLabel(bv, "secondary", "b", {-0.14, 0.22}, {1, 0.5})
local result = scene:text {text = string.format("cross(a, b) = %+.0f", cross), point = {0, -2.55}, role = "code", fill = "result", align = {0.5, 0.5}, layer = 40}

-- Reveal operands before the yellow area and its matching scalar result.
scene:create(plane, 0.45, "ease_out")
scene:create({a, b}, 0.7, "ease_out", 0.08)
scene:create({aLabel, bLabel}, 0.25, "ease_out", 0.04)
scene:wait(0.45)
scene:draw_border_then_fill(area, 0.9, "gentle", 0, "forward")
scene:fade_in(result, {shift = {0, -0.1}, duration = 0.4, curve = "gentle"})
scene:wait(1.2)
return scene
