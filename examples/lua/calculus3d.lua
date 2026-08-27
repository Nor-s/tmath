local palette = {
    background = "#0b111a",
    grid = "#263447",
    axis = "#66758a",
    text = "#f4f7fb",
    muted = "#94a3b8",
    curve = "#4cc9f0",
    tangent = "#ffd166",
    accumulated = "#7bd88f",
    point = "#ff6b6b",
}

local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    background = palette.background,
    camera = {
        mode = "interactive",
        view = "3d",
        eye = { 6, 4.8, 7 },
        target = { 0, 1.25, 0 },
        up = { 0, 1, 0 },
        projection = "perspective",
        fov = 0.72,
        near = 0.1,
        far = 100,
    },
}

local space = scene:space {
    x = { -3, 3, 1 },
    y = { -1, 4, 1 },
    z = { -3, 3, 1 },
    numbers = false,
    color = palette.grid,
    axis_x = palette.axis,
    axis_y = palette.axis,
    axis_z = palette.axis,
    id = "curve-space",
}
local points = {}
for i = 0, 120 do
    local t = i * 6.28318530718 / 120
    points[#points + 1] = { 2 * math.cos(t), 0.45 * t, 2 * math.sin(t) }
end
local curve = space:plot {
    points = points,
    color = palette.curve,
    width = 4,
    id = "helix",
}
local curve_formula = space:text {
    text = "r(t) = (2 cos t, 0.45t, 2 sin t)",
    point = { -2.85, 3.65, 0.15 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 20,
    fill = palette.curve,
    id = "curve-formula",
}

local t0 = 2.2
local sample_position = {
    2 * math.cos(t0),
    0.45 * t0,
    2 * math.sin(t0),
}
local sample = space:point {
    point = sample_position,
    fill = palette.point,
    radius = 8,
    layer = 5,
}
local tangent = space:vector {
    origin = sample_position,
    value = { -1.2 * math.sin(t0), 0.27, 1.2 * math.cos(t0) },
    color = palette.tangent,
    width = 5,
    tip = 14,
    id = "tangent-vector",
}
local sample_formula = space:text {
    text = "P = r(t₀)",
    point = {
        sample_position[1] + 0.18,
        sample_position[2] + 0.42,
        sample_position[3] + 0.06,
    },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 17,
    fill = palette.point,
}
local tangent_formula = space:text {
    text = "r′(t₀)  ->  tangent direction",
    point = { -2.85, 3.18, 0.15 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 19,
    fill = palette.tangent,
    id = "tangent-formula",
}

local accumulated_points = {}
for i = 0, 44 do
    local t = t0 * i / 44
    accumulated_points[#accumulated_points + 1] = {
        2 * math.cos(t),
        0.45 * t,
        2 * math.sin(t),
    }
end
local accumulated_arc = space:plot {
    points = accumulated_points,
    color = palette.accumulated,
    width = 7,
    id = "accumulated-arc",
}
local start_point = space:point {
    point = { 2, 0, 0 },
    fill = palette.accumulated,
    radius = 5,
    layer = 5,
}
local arc_formula = space:text {
    text = "s(t₀) = integral[0, t₀] |r′(u)| du",
    point = { -2.85, 2.72, 0.15 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 20,
    fill = palette.accumulated,
    id = "arc-length",
}
local arc_note = space:text {
    text = "accumulated length along the curve",
    point = { -2.82, 2.30, 0.15 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 14,
    fill = palette.muted,
}

scene:create(space, 0.42, "ease_out")
scene:create(curve, 1.35, "linear")
scene:create(curve_formula, 0.34, "ease_out")
scene:create(sample, 0.28, "ease_out")
scene:create(tangent, 0.68, "ease_out")
scene:create({ sample_formula, tangent_formula }, 0.36, "ease_out", 0.08)
scene:create({ accumulated_arc, start_point }, 0.92, "ease_in_out", 0.08)
scene:create({ arc_formula, arc_note }, 0.40, "ease_out", 0.07)
scene:wait(0.72)
return scene
