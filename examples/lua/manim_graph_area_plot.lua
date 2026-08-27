local p = {
    paper = "#f7f8fb",
    ink = "#182033",
    muted = "#687086",
    grid = "#dce2ed",
    blue = "#2563eb",
    green = "#16a34a",
    gold = "#eab308",
}
local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 60,
    background = p.paper,
    camera = { mode = "fixed", view = "2d", height = 8 },
}
scene:text {
    text = "GRAPH AREA PLOT",
    point = { -5.8, 3.15 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 27,
    fill = p.ink,
}
scene:text {
    text = "Riemann rectangles and bounded area",
    point = { -5.77, 2.65 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = p.muted,
}
local axes = scene:space {
    x = { 0, 5, 1 },
    y = { 0, 6, 1 },
    matrix = { 1.15, 0, 0, -2.75, 0, 0.82, 0, -2.55, 0, 0, 1, 0, 0, 0, 0, 1 },
    color = p.grid,
    axis_x = p.ink,
    axis_y = p.ink,
    numbers = true,
    number_size = 10,
    id = "axes",
}
local curve_a_points, curve_b_points = {}, {}
for sample = 0, 100 do
    local x = 4 * sample / 100
    curve_a_points[#curve_a_points + 1] = { x, 4 * x - x * x }
    curve_b_points[#curve_b_points + 1] = { x, 0.8 * x * x - 3 * x + 4 }
end
local curve_a = axes:plot { points = curve_a_points, stroke = p.blue, width = 4, id = "curve-a" }
local curve_b = axes:plot { points = curve_b_points, stroke = p.green, width = 4, id = "curve-b" }
local rectangles = {}
for index = 0, 7 do
    local x0 = 0.3 + index * 0.0375
    local x1 = x0 + 0.034
    local y = 4 * (x0 + x1) * 0.5 - ((x0 + x1) * 0.5) ^ 2
    rectangles[#rectangles + 1] = axes:polygon {
        points = { { x0, 0 }, { x1, 0 }, { x1, y }, { x0, y } },
        fill = p.blue .. "66",
        stroke = p.blue .. "aa",
        width = 1,
    }
end
local band = {}
for index = 0, 17 do
    local x0 = 2 + index / 18
    local x1 = 2 + (index + 1) / 18
    local a0, a1 = 4 * x0 - x0 * x0, 4 * x1 - x1 * x1
    local b0, b1 = 0.8 * x0 * x0 - 3 * x0 + 4, 0.8 * x1 * x1 - 3 * x1 + 4
    band[#band + 1] = axes:polygon {
        points = { { x0, b0 }, { x1, b1 }, { x1, a1 }, { x0, a0 } },
        fill = p.gold .. "68",
        stroke = "#00000000",
        width = 0,
    }
end
local bounds = {
    axes:line { from = { 2, 0 }, to = { 2, 4 }, stroke = p.gold, width = 2 },
    axes:line { from = { 3, 0 }, to = { 3, 3 }, stroke = p.gold, width = 2 },
}
scene:create(axes, 0.4, "ease_out")
scene:create({ curve_a, curve_b }, 0.85, "ease_out", 0)
scene:create(rectangles, 0.42, "ease_out", 0.025)
scene:create(band, 0.62, "ease_out", 0.012)
scene:create(bounds, 0.35, "ease_out", 0)
scene:wait(0.8)
return scene
