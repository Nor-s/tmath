local palette = {
    background = "#0b111a",
    grid = "#263447",
    axis = "#66758a",
    text = "#f4f7fb",
    muted = "#94a3b8",
    curve = "#4cc9f0",
    tangent = "#ffd166",
    area = "#7bd88f",
    point = "#ff6b6b",
}

local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    background = palette.background,
    camera = { mode = "interactive", view = "2d", target = { 0, 0.2 }, height = 7.6 },
}

local space = scene:space {
    x = { -5, 5, 1 },
    y = { -3, 4, 1 },
    numbers = true,
    color = palette.grid,
    axis_x = palette.axis,
    axis_y = palette.axis,
    number_color = palette.muted,
    number_size = 13,
    id = "cartesian-space",
}
local curve = space:plot {
    fn = function(x)
        return 0.25 * x * x - 0.5
    end,
    x_range = { -4, 4, 0.06 },
    color = palette.curve,
    width = 4,
    id = "f-x",
}
local curve_formula = space:text {
    text = "f(x) = x²/4 − 1/2",
    point = { -5.65, 3.45 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 21,
    fill = palette.curve,
    id = "curve-formula",
}

local sample = space:point {
    point = { 1, -0.25 },
    fill = palette.point,
    radius = 7,
    layer = 5,
}
local tangent = space:line {
    from = { -2.6, -2.05 },
    to = { 4.2, 1.35 },
    color = palette.tangent,
    width = 4,
    id = "derivative-tangent",
}
local sample_formula = space:text {
    text = "P = (1, −0.25)",
    point = { 1.22, -0.72 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 16,
    fill = palette.point,
}
local derivative_formula = space:text {
    text = "f′(1) = slope = 1/2",
    point = { 1.45, 3.45 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 20,
    fill = palette.tangent,
    id = "derivative-formula",
}

local dx = 0.375
local dx_marker = {
    space:line { from = { 0, 0.08 }, to = { dx, 0.08 }, color = palette.area, width = 5 },
    space:line { from = { 0, -0.08 }, to = { 0, 0.24 }, color = palette.area, width = 2 },
    space:line { from = { dx, -0.08 }, to = { dx, 0.24 }, color = palette.area, width = 2 },
}
local dx_label = space:text {
    text = "Δx = 0.375",
    point = { 0.02, 0.42 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 15,
    fill = palette.area,
}
local rectangles = {}
for i = 0, 7 do
    local left = i * dx
    local right = left + dx
    local height = 0.25 * right * right - 0.5
    rectangles[#rectangles + 1] = space:polygon {
        points = { { left, 0 }, { right, 0 }, { right, height }, { left, height } },
        fill = "#7bd88f55",
        stroke = palette.area,
        width = 1.5,
    }
end
local integral = space:text {
    text = "Σ f(x_i) Δx  ->  ∫₀³ f(x) dx",
    point = { 1.45, 2.88 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 19,
    fill = palette.area,
    id = "riemann-conclusion",
}
local integral_note = space:text {
    text = "accumulated signed area",
    point = { 1.48, 2.52 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 14,
    fill = palette.muted,
}

scene:create(space, 0.42, "ease_out")
scene:create(curve, 1.05, "ease_in_out")
scene:create(curve_formula, 0.32, "ease_out")
scene:create(sample, 0.28, "ease_out")
scene:create(tangent, 0.62, "ease_out")
scene:create({ sample_formula, derivative_formula }, 0.34, "ease_out", 0.08)
scene:create(dx_marker, 0.34, "ease_out", 0.04)
scene:create(dx_label, 0.24, "ease_out")
scene:create(rectangles, 0.78, "ease_out", 0.055)
scene:create({ integral, integral_note }, 0.38, "ease_out", 0.06)
scene:wait(0.65)
return scene
