local palette = {
    background = "#0b111a",
    grid = "#263447",
    axis = "#66758a",
    text = "#f4f7fb",
    muted = "#94a3b8",
    control = "#66758a",
    curve = "#4cc9f0",
    level1 = "#7bd88f",
    level2 = "#ffd166",
    derivative = "#ff6b6b",
}

local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    background = palette.background,
    camera = { mode = "interactive", view = "2d", target = { 0, 0.1 }, height = 7.6 },
}
local space = scene:space {
    x = { -6, 6, 1 },
    y = { -3, 4, 1 },
    numbers = false,
    color = palette.grid,
    axis_x = palette.axis,
    axis_y = palette.axis,
}

local p0 = { -4.7, -1.7 }
local p1 = { -2.4, 2.15 }
local p2 = { 2.1, 2.0 }
local p3 = { 4.65, -1.35 }
local function mix(a, b, t)
    return { a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t }
end
local t = 0.62
local a = mix(p0, p1, t)
local b = mix(p1, p2, t)
local c = mix(p2, p3, t)
local d = mix(a, b, t)
local e = mix(b, c, t)
local q = mix(d, e, t)

local control_lines = {
    space:line { from = p0, to = p1, color = palette.control, width = 2 },
    space:line { from = p1, to = p2, color = palette.control, width = 2 },
    space:line { from = p2, to = p3, color = palette.control, width = 2 },
}
local control_points = {
    space:point { point = p0, fill = palette.text, radius = 6 },
    space:point { point = p1, fill = palette.text, radius = 6 },
    space:point { point = p2, fill = palette.text, radius = 6 },
    space:point { point = p3, fill = palette.text, radius = 6 },
}
local control_labels = {
    space:text {
        text = "P₀",
        point = { -5.03, -1.95 },
        font = "Pretendard",
        size = 15,
        fill = palette.text,
    },
    space:text {
        text = "P₁",
        point = { -2.62, 2.46 },
        font = "Pretendard",
        size = 15,
        fill = palette.text,
    },
    space:text {
        text = "P₂",
        point = { 2.08, 2.33 },
        font = "Pretendard",
        size = 15,
        fill = palette.text,
    },
    space:text {
        text = "P₃",
        point = { 4.72, -1.62 },
        font = "Pretendard",
        size = 15,
        fill = palette.text,
    },
}

local level1_lines = {
    space:line { from = a, to = b, color = palette.level1, width = 3 },
    space:line { from = b, to = c, color = palette.level1, width = 3 },
}
local level1_points = {
    space:point { point = a, fill = palette.level1, radius = 5 },
    space:point { point = b, fill = palette.level1, radius = 5 },
    space:point { point = c, fill = palette.level1, radius = 5 },
}
local level2_line = space:line { from = d, to = e, color = palette.level2, width = 4 }
local level2_points = {
    space:point { point = d, fill = palette.level2, radius = 6 },
    space:point { point = e, fill = palette.level2, radius = 6 },
}

local curve_points = {}
for i = 0, 100 do
    local u = i / 100
    local v = 1 - u
    curve_points[#curve_points + 1] = {
        v * v * v * p0[1] + 3 * v * v * u * p1[1] + 3 * v * u * u * p2[1] + u * u * u * p3[1],
        v * v * v * p0[2] + 3 * v * v * u * p1[2] + 3 * v * u * u * p2[2] + u * u * u * p3[2],
    }
end
local curve = space:plot {
    points = curve_points,
    color = palette.curve,
    width = 5,
    id = "cubic-bezier",
}
local evaluated_point = space:point {
    point = q,
    fill = palette.derivative,
    radius = 8,
    layer = 5,
    id = "interpolated-point",
}
local v = 1 - t
local derivative = {
    3 * v * v * (p1[1] - p0[1]) + 6 * v * t * (p2[1] - p1[1]) + 3 * t * t * (p3[1] - p2[1]),
    3 * v * v * (p1[2] - p0[2]) + 6 * v * t * (p2[2] - p1[2]) + 3 * t * t * (p3[2] - p2[2]),
}
local tangent = space:vector {
    origin = q,
    value = { derivative[1] * 0.32, derivative[2] * 0.32 },
    color = palette.derivative,
    width = 4,
    tip = 13,
    id = "bezier-derivative",
}

local heading = space:text {
    text = "DE CASTELJAU  ·  t = 0.62",
    point = { -5.72, 3.34 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 15,
    fill = palette.muted,
}
local level1_label = space:text {
    text = "A, B, C : first lerp",
    point = { 0.45, 3.34 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 16,
    fill = palette.level1,
}
local level2_label = space:text {
    text = "D, E : second lerp",
    point = { 0.45, 2.96 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 16,
    fill = palette.level2,
}
local curve_label = space:text {
    text = "B(t)",
    point = { 4.75, -0.92 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 18,
    fill = palette.curve,
}
local point_label = space:text {
    text = "Q = B(0.62)",
    point = { q[1] - 1.08, q[2] + 0.36 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 16,
    fill = palette.derivative,
}
local derivative_label = space:text {
    text = "B′(0.62) = tangent direction",
    point = { 0.78, -2.56 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 19,
    fill = palette.derivative,
}
local conclusion = space:text {
    text = "interpolation -> Q",
    point = { -5.72, -2.56 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 15,
    fill = palette.muted,
}

scene:create(space, 0.40, "ease_out")
scene:create(control_lines, 0.58, "linear", 0.07)
scene:create(control_points, 0.30, "ease_out", 0.04)
scene:create(
    { heading, control_labels[1], control_labels[2], control_labels[3], control_labels[4] },
    0.30,
    "ease_out",
    0.04
)
scene:create(
    { level1_lines[1], level1_lines[2], level1_points[1], level1_points[2], level1_points[3] },
    0.55,
    "ease_out",
    0.05
)
scene:create(level1_label, 0.28, "ease_out")
scene:create({ level2_line, level2_points[1], level2_points[2] }, 0.48, "ease_out", 0.05)
scene:create(level2_label, 0.28, "ease_out")
scene:create(evaluated_point, 0.28, "ease_out")
scene:create({ point_label, curve }, 1.05, "ease_in_out", 0.08)
scene:create({ tangent, curve_label }, 0.62, "ease_out", 0.08)
scene:create({ conclusion, derivative_label }, 0.42, "ease_out", 0.08)
scene:wait(0.72)
return scene
