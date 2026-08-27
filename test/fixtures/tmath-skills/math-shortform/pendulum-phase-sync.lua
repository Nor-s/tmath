-- One small-angle oscillator state drives both the pendulum and its phase portrait.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 7.0},
}

local pivot, length, amplitude = {-3.0, 2.25}, 3.15, 0.32
local phaseCenter, phaseRadius, steps = {2.55, -0.05}, 1.75, 72
local function diamond(point, radius)
    return {{point[1] - radius, point[2]}, {point[1], point[2] + radius},
            {point[1] + radius, point[2]}, {point[1], point[2] - radius}}
end
local function disk(point, radius, samples)
    local points = {}
    for i = 0, samples - 1 do
        local angle = 2 * math.pi * i / samples
        points[#points + 1] = {
            point[1] + radius * math.cos(angle), point[2] + radius * math.sin(angle),
        }
    end
    return points
end
local function oscillator(phase)
    local theta = amplitude * math.cos(phase)
    local omega = -amplitude * math.sin(phase)
    local bob = {
        pivot[1] + length * math.sin(theta),
        pivot[2] - length * math.cos(theta),
    }
    local phasePoint = {
        phaseCenter[1] + phaseRadius * theta / amplitude,
        phaseCenter[2] + phaseRadius * omega / amplitude,
    }
    return {theta = theta, omega = omega, bob = bob, phasePoint = phasePoint}
end
local function state(step)
    local current = oscillator(2 * math.pi * step / steps)
    local trace = {}
    for i = 0, steps do
        local visible = math.min(i, step)
        trace[#trace + 1] = oscillator(2 * math.pi * visible / steps).phasePoint
    end
    current.trace = trace
    return current
end
local function movingMembers(step)
    local s = state(step)
    return {
        scene:plot {id = "pendulum-rod-" .. step, points = {pivot, s.bob},
            stroke = "accent", width = 4, layer = 10},
        scene:polygon {id = "pendulum-bob-" .. step, points = disk(s.bob, 0.22, 20),
            fill = "accent", stroke = "accent", layer = 20},
        scene:plot {id = "phase-state-vector-" .. step, points = {phaseCenter, s.phasePoint},
            stroke = "secondary", width = 2.5, layer = 10},
        scene:plot {id = "phase-trace-" .. step, points = s.trace,
            stroke = "secondary", width = 4, layer = 15},
        scene:polygon {id = "phase-marker-" .. step, points = diamond(s.phasePoint, 0.10),
            fill = "secondary", stroke = "secondary", layer = 30},
    }
end

-- Quiet references make displacement and phase rotation readable without a panel.
local references = {
    scene:line {id = "pendulum-equilibrium", from = pivot, to = {pivot[1], pivot[2] - length - 0.3},
        stroke = "border", width = 1.5, dash = {6, 6}, layer = 0},
    scene:point {id = "pendulum-pivot", point = pivot, fill = "foreground", radius = 6, layer = 30},
    scene:line {id = "phase-x-axis", from = {phaseCenter[1] - 2.15, phaseCenter[2]},
        to = {phaseCenter[1] + 2.15, phaseCenter[2]}, stroke = "border", width = 1.5, layer = 0},
    scene:line {id = "phase-y-axis", from = {phaseCenter[1], phaseCenter[2] - 2.15},
        to = {phaseCenter[1], phaseCenter[2] + 2.15}, stroke = "border", width = 1.5, layer = 0},
}
local phaseLabel = scene:text {
    id = "phase-label", text = "phase  (theta, omega)", point = {phaseCenter[1], 2.55},
    role = "code", fill = "secondary", align = {0.5, 0.5}, layer = 40,
}
local live = movingMembers(1)
scene:create(references, 0.55, "ease_out", 0.04)
scene:fade_in(phaseLabel, {shift = {0, -0.08}, duration = 0.3, curve = "gentle"})
scene:create(live, 0.45, "ease_out", 0.025)
scene:wait(0.35)

-- The bob, rod, phase vector, marker, and accumulated orbit share every sample.
for step = 2, steps do
    local target = movingMembers(step)
    scene:morph(live, target, 0.065, "linear", 0)
    live = target
end

local conclusion = scene:text {
    id = "pendulum-phase-conclusion", text = "one state  ·  two synchronized views",
    point = {0, -3.05}, role = "code", fill = "result", align = {0.5, 0.5}, layer = 40,
}
scene:fade_in(conclusion, {shift = {0, 0.08}, duration = 0.34, curve = "gentle"})
scene:wait(1.8)
return scene
