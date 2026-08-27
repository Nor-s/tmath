local p = {
    paper = "#f7f8fb",
    ink = "#182033",
    muted = "#687086",
    blue = "#2563eb",
    yellow = "#eab308",
    orange = "#f97316",
    grid = "#d8deea",
}
local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 60,
    background = p.paper,
    camera = { mode = "fixed", view = "2d", height = 7 },
}
scene:text {
    text = "SINE CURVE  /  UNIT CIRCLE",
    point = { -5.7, 2.72 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 27,
    fill = p.ink,
}
scene:text {
    text = "one rotating coordinate writes the wave",
    point = { -5.68, 2.20 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = p.muted,
}
local origin = { -3.7, -0.25 }
local circle = scene:circle {
    center = origin,
    radius = 1.25,
    fill = "#00000000",
    stroke = p.blue,
    width = 4,
    id = "unit-circle",
}
local axes = {
    scene:line { from = { -2.15, -0.25 }, to = { 5.55, -0.25 }, stroke = p.ink, width = 2 },
    scene:line { from = { -2.15, -1.75 }, to = { -2.15, 1.45 }, stroke = p.ink, width = 2 },
}
local samples = 32
local function state(step)
    local angle = 2 * math.pi * step / samples
    local circle_point = { origin[1] + 1.25 * math.cos(angle), origin[2] + 1.25 * math.sin(angle) }
    local wave_x = -1.75 + 6.75 * step / samples
    local wave_point = { wave_x, circle_point[2] }
    local diamond = {
        { circle_point[1] - 0.08, circle_point[2] },
        { circle_point[1], circle_point[2] + 0.08 },
        { circle_point[1] + 0.08, circle_point[2] },
        { circle_point[1], circle_point[2] - 0.08 },
    }
    local trace = {}
    for index = 0, samples do
        local visible = math.min(index, step)
        local a = 2 * math.pi * visible / samples
        trace[#trace + 1] = { -1.75 + 6.75 * visible / samples, origin[2] + 1.25 * math.sin(a) }
    end
    return diamond, { origin, circle_point }, { circle_point, wave_point }, trace
end
local diamond, radius_points, bridge_points, trace_points = state(0)
local dot = scene:polygon {
    points = diamond,
    fill = p.orange,
    stroke = p.orange,
    width = 2,
    id = "circle-dot-0",
}
local radius = scene:plot { points = radius_points, stroke = p.blue, width = 3, id = "radius-0" }
local bridge = scene:plot { points = bridge_points, stroke = p.yellow, width = 2, id = "bridge-0" }
local trace = scene:plot { points = trace_points, stroke = p.orange, width = 4, id = "trace-0" }
scene:create({ circle, axes[1], axes[2] }, 0.5, "ease_out", 0)
scene:grow_from_center(dot, 0.18, "snappy")
for step = 1, samples do
    local next_diamond, next_radius, next_bridge, next_trace = state(step)
    local next_dot = scene:polygon {
        points = next_diamond,
        fill = p.orange,
        stroke = p.orange,
        width = 2,
        id = "circle-dot-" .. step,
    }
    local next_radius_object =
        scene:plot { points = next_radius, stroke = p.blue, width = 3, id = "radius-" .. step }
    local next_bridge_object =
        scene:plot { points = next_bridge, stroke = p.yellow, width = 2, id = "bridge-" .. step }
    local next_trace_object =
        scene:plot { points = next_trace, stroke = p.orange, width = 4, id = "trace-" .. step }
    scene:morph(
        { dot, radius, bridge, trace },
        { next_dot, next_radius_object, next_bridge_object, next_trace_object },
        0.055,
        "linear",
        0
    )
    dot, radius, bridge, trace = next_dot, next_radius_object, next_bridge_object, next_trace_object
end
scene:wait(0.8)
return scene
