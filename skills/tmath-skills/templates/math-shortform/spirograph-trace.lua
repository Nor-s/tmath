-- One rolling-circle parameter keeps the construction arm and trace synchronized.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 7.2},
}

local fixedRadius, rollingRadius, penOffset = 3.0, 1.0, 0.72
local steps, circleSamples = 96, 48
local function hypotrochoid(theta)
    local orbit = fixedRadius - rollingRadius
    local spin = orbit * theta / rollingRadius
    local center = {orbit * math.cos(theta), orbit * math.sin(theta)}
    return center, {
        center[1] + penOffset * math.cos(spin),
        center[2] - penOffset * math.sin(spin),
    }
end
local function circlePoints(center, radius)
    local points = {}
    for i = 0, circleSamples do
        local angle = 2 * math.pi * i / circleSamples
        points[#points + 1] = {
            center[1] + radius * math.cos(angle),
            center[2] + radius * math.sin(angle),
        }
    end
    return points
end
local function diamond(point, radius)
    return {{point[1] - radius, point[2]}, {point[1], point[2] + radius},
            {point[1] + radius, point[2]}, {point[1], point[2] - radius}}
end
local function state(step)
    local theta = 2 * math.pi * step / steps
    local center, pen = hypotrochoid(theta)
    local trace = {}
    for i = 0, steps do
        local visible = math.min(i, step)
        local _, point = hypotrochoid(2 * math.pi * visible / steps)
        trace[#trace + 1] = point
    end
    return {center = center, pen = pen, rolling = circlePoints(center, rollingRadius), trace = trace}
end
local function movingMembers(step)
    local s = state(step)
    return {
        scene:plot {id = "spiro-rolling-circle-" .. step, points = s.rolling,
            stroke = "secondary", width = 3, layer = 5},
        scene:plot {id = "spiro-center-link-" .. step, points = {{0, 0}, s.center},
            stroke = "border", width = 1.5, layer = 0},
        scene:polygon {id = "spiro-rolling-center-" .. step, points = diamond(s.center, 0.07),
            fill = "secondary", stroke = "secondary", layer = 20},
        scene:plot {id = "spiro-pen-arm-" .. step, points = {s.center, s.pen},
            stroke = "accent", width = 4, layer = 10},
        scene:polygon {id = "spiro-pen-" .. step, points = diamond(s.pen, 0.10),
            fill = "accent", stroke = "accent", layer = 30},
        scene:plot {id = "spiro-trace-" .. step, points = s.trace,
            stroke = "result", width = 4, layer = 15},
    }
end

-- Establish the two-circle constraint before the pen starts to travel.
local fixedCircle = scene:circle {
    id = "spiro-fixed-circle", center = {0, 0}, radius = fixedRadius,
    fill = "#00000000", stroke = "foreground", width = 3, layer = 0,
}
local fixedCenter = scene:point {
    id = "spiro-fixed-center", point = {0, 0}, fill = "foreground", radius = 5, layer = 20,
}
local live = movingMembers(1)
scene:create({fixedCircle, fixedCenter}, 0.55, "ease_out", 0.05)
scene:create(live, 0.48, "ease_out", 0.025)
scene:wait(0.35)

-- Equal-sampled targets let every construction member advance on one parameter clock.
for step = 2, steps do
    local target = movingMembers(step)
    scene:morph(live, target, 0.052, "linear", 0)
    live = target
end

local conclusion = scene:text {
    id = "spiro-conclusion", text = "rolling constraint  →  closed trace",
    point = {0, -3.18}, role = "code", fill = "result", align = {0.5, 0.5}, layer = 40,
}
scene:fade_in(conclusion, {shift = {0, 0.08}, duration = 0.34, curve = "gentle"})
scene:wait(1.8)
return scene
