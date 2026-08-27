-- Visualize a dot product through projection onto vector a.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6},
}
local plane = scene:space {
    x = {-4.8, 4.8, 1}, y = {-2.2, 2.8, 1}, numbers = false,
    stroke = "border", width = 1,
}

local av, bv = {4, 1}, {1.4, 2.8}
local function dot(a, b) return a[1] * b[1] + a[2] * b[2] end
local function scale(v, k) return {v[1] * k, v[2] * k} end
local function vectorWithLabel(value, color, text, labelOffset)
    local vector = plane:vector {origin = {0, 0}, value = value, stroke = color, width = 4, tip = 13, layer = 20}
    local label = plane:text {text = text, point = {value[1] + labelOffset[1], value[2] + labelOffset[2]}, role = "code", fill = color, align = {0, 0.5}, layer = 40}
    return vector, label
end

-- proj_a(b) = a * dot(a, b) / dot(a, a).
local dotValue = dot(av, bv)
local projection = scale(av, dotValue / dot(av, av))
local a, aLabel = vectorWithLabel(av, "accent", "a", {0.2, 0.12})
local b, bLabel = vectorWithLabel(bv, "secondary", "b", {0.22, -0.35})
local projected = plane:vector {origin = {0, 0}, value = projection, stroke = "result", width = 5, tip = 13, layer = 20}
local residual = plane:line {from = projection, to = bv, stroke = "result", width = 2, dash = {7, 5}, layer = 10}
local foot = plane:point {point = projection, radius = 7, fill = "result", layer = 10}
local result = scene:text {text = string.format("a · b = %.1f", dotValue), point = {0, -2.55}, role = "code", fill = "result", align = {0.5, 0.5}, layer = 40}

-- Projection, residual, and scalar arrive as one visual claim.
scene:create(plane, 0.45, "ease_out")
scene:create({a, b}, 0.7, "ease_out", 0.08)
scene:create({aLabel, bLabel}, 0.25, "ease_out", 0.04)
scene:wait(0.45)
scene:create({projected, residual, foot}, 0.8, "ease_out", 0.06)
scene:fade_in(result, {shift = {0, -0.1}, duration = 0.4, curve = "gentle"})
scene:wait(1.2)
return scene
