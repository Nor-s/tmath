-- Compare two cubic Bézier shapes, then trace a parameter along the final curve.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.6},
}
local first = {{-4.2, -1.35}, {-2.4, 2.15}, {1.8, 1.55}, {4.2, -1.25}}
local second = {{-4.2, -1.35}, {-1.15, -0.1}, {2.35, 2.35}, {4.2, -1.25}}
local colors = {"foreground", "accent", "secondary", "foreground"}
local labelOffsets = {{-0.28, -0.23}, {-0.32, 0.60}, {0.92, 1.20}, {0.28, -0.23}}
local function offset(point, delta) return {point[1] + delta[1], point[2] + delta[2]} end

-- Evaluate the curve directly so the moving sample follows the same geometry.
local function cubic(points, t)
    local u = 1 - t
    return {u^3 * points[1][1] + 3*u^2*t * points[2][1] + 3*u*t^2 * points[3][1] + t^3 * points[4][1],
            u^3 * points[1][2] + 3*u^2*t * points[2][2] + 3*u*t^2 * points[3][2] + t^3 * points[4][2]}
end
-- Control points are polygons, allowing them to participate in morph operations.
local function disk(center, color, id)
    local points = {}
    for i = 0, 11 do
        local angle = 2 * math.pi * i / 12
        points[#points + 1] = {center[1] + 0.09 * math.cos(angle), center[2] + 0.09 * math.sin(angle)}
    end
    return scene:polygon {id = id, points = points, fill = color, stroke = color, layer = 20}
end
-- Return one complete curve rig with stable member order for pairwise morphing.
local function geometry(points, suffix)
    local result = {
        control = scene:plot {id = "bezier-control-" .. suffix, points = points, stroke = "muted", width = 2, dash = {7, 5}, layer = 0},
        curve = scene:curve {id = "bezier-curve-" .. suffix, from = points[1], control1 = points[2], control2 = points[3], to = points[4], samples = 64, stroke = "result", width = 5, layer = 10},
        points = {},
    }
    for i = 1, 4 do result.points[i] = disk(points[i], colors[i], "bezier-p" .. (i - 1) .. "-" .. suffix) end
    return result
end
local function members(value)
    return {value.control, value.curve, value.points[1], value.points[2], value.points[3], value.points[4]}
end
local function trace(points, stop, steps)
    local sample = scene:point {id = "bezier-sample-" .. steps, point = points[1], radius = 7, fill = "success", layer = 30}
    scene:grow_from_center(sample, 0.22, "ease_out")
    local previous = points[1]
    for i = 1, steps do
        local nextPoint = cubic(points, stop * i / steps)
        scene:shift(sample, {nextPoint[1] - previous[1], nextPoint[2] - previous[2]}, 0.08, "linear")
        previous = nextPoint
    end
    return sample, previous
end

-- Establish the first rig before transforming every corresponding member together.
local initial = geometry(first, "a")
local labels = {
    scene:text {id = "bezier-p0-label", text = "P0", point = offset(first[1], labelOffsets[1]), role = "code", fill = "foreground", layer = 40},
    scene:text {id = "bezier-p1-label", text = "P1 control", point = offset(first[2], labelOffsets[2]), role = "code", fill = "accent", layer = 40},
    scene:text {id = "bezier-p2-label", text = "P2 control", point = offset(first[3], labelOffsets[3]), role = "code", fill = "secondary", layer = 40},
    scene:text {id = "bezier-p3-label", text = "P3", point = offset(first[4], labelOffsets[4]), role = "code", fill = "foreground", layer = 40},
}
scene:create(initial.control, 0.52, "ease_out")
scene:create(initial.points, 0.35, "ease_out", 0.04)
scene:create(labels, 0.32, "ease_out", 0.04)
scene:create(initial.curve, 1.0, "ease_out")
local sample = trace(first, 1, 14)
scene:fade_out(sample, {scale = 0.7, duration = 0.22, curve = "ease_in"})
scene:wait(0.35)
local target = geometry(second, "b")
scene:morph(members(initial), members(target), 1.45, "ease_in_out")
scene:wait(0.38)
-- The last trace stops at a named parameter instead of clearing the completed scene.
local sampleT = 0.65
local finalSample, q = trace(second, sampleT, 10)
local value = scene:text {id = "bezier-value", text = string.format("B(%.2f)", sampleT), point = {q[1] + 0.22, q[2] + 0.36}, role = "code", fill = "success", align = {0, 0.5}, layer = 40}
scene:fade_in(value, {shift = {0.12, 0}, duration = 0.3, curve = "gentle"})
scene:wait(1.3)
return scene
