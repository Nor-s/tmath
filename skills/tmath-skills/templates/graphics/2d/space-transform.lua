-- Transform a local Space so its shape, basis, point, and labels move as one.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 7.4},
}
local world = scene:space {
    id = "transform-world-space", x = {-6.5, 6.5, 1}, y = {-3.5, 3.5, 0.7}, numbers = false,
    stroke = "border", width = 1, opacity = 0.5,
}
-- Descendants stay in local coordinates; the Space owns their matrix.
local localSpace = scene:space {
    id = "transform-local-space", x = {-4, 4, 0.5}, y = {-2.4, 2.4, 0.4}, numbers = false,
    stroke = "accent", axis_x = "accent", axis_y = "secondary", width = 1.4, opacity = 0.62,
}
-- This sample region is independent of the basis vectors, so it does not share their origin.
local regionPoints = {{-3.2, -1.8}, {-1.4, -1.8}, {-1.4, -0.65}, {-3.2, -0.65}}
local shape = localSpace:polygon {
    id = "transform-region", points = regionPoints,
    fill = "result", stroke = "result", opacity = 0.18, width = 2.2, layer = 5,
}
local function offset(point, delta) return {point[1] + delta[1], point[2] + delta[2]} end
local function basis(id, value, color, text, labelOffset, align)
    local vector = localSpace:vector {id = id, origin = {0, 0}, value = value, stroke = color, width = 4, tip = 12, layer = 20}
    local label = localSpace:text {id = id .. "-label", text = text, point = offset(value, labelOffset), role = "code", fill = color, align = align, layer = 40}
    return vector, label
end
local ex, lx = basis("transform-basis-e1", {1.3, 0}, "accent", "e₁", {0.18, -0.1}, {0, 0.5})
local ey, ly = basis("transform-basis-e2", {0, 1.3}, "secondary", "e₂", {-0.12, 0.18}, {1, 0.5})
local samplePoint = regionPoints[3]
local point = localSpace:point {id = "transform-point", point = samplePoint, radius = 7, fill = "result", layer = 10}
local lp = localSpace:text {id = "transform-point-label", text = "p", point = offset(samplePoint, {0.2, 0.17}), role = "code", fill = "result", align = {0, 0.5}, layer = 40}
-- Row-major affine matrix: linear transform first, translation last.
local matrix = {
    1, 0.55, 0, 0.35,
    0.25, 1, 0, -0.2,
    0, 0, 1, 0,
    0, 0, 0, 1,
}

-- Establish both spaces, then animate only the owning local Space.
scene:create({world, localSpace}, 0.6, "ease_out", 0.08)
scene:create({shape, ex, ey, point}, 0.6, "ease_out", 0.06)
scene:create({lx, ly, lp}, 0.25, "ease_out", 0.04)
scene:wait(0.55)
scene:transform(localSpace, matrix, 1.4, "ease_in_out")
scene:wait(1.2)
return scene
