local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    camera = { mode = "interactive", view = "2d", height = 7 },
}

local space = scene:space {
    x = { -5, 5, 1 },
    y = { -3, 3, 1 },
    numbers = true,
    number_color = "#9aa7b5",
    number_size = 14,
}
local circle = space:circle {
    center = { 0, 0 },
    radius = 2.25,
    fill = "#4cc9f022",
    stroke = "#4cc9f0",
    width = 4,
    id = "circle",
}
local angle = 0.68
local point = { 2.25 * math.cos(angle), 2.25 * math.sin(angle) }
local radius = space:vector {
    value = point,
    color = "#ffd166",
    width = 4,
    tip = 13,
    id = "radius",
}
local sample = space:point { point = point, fill = "#ef5350", radius = 7 }
local equation = space:text {
    text = "x² + y² = r²",
    point = { -2.7, 2.7 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 25,
    fill = "#4cc9f0",
    id = "equation",
}
local radius_formula = space:text {
    text = "r = 2.25",
    point = { 1.15, 2.7 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 25,
    fill = "#ffd166",
}
local point_formula = space:text {
    text = "P(x, y)",
    point = { point[1] + 0.15, point[2] + 0.35 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 18,
    fill = "#ef5350",
}

scene:create(circle, 1.1, "ease_in_out")
scene:create({ radius, sample }, 0.75, "ease_out", 0.12)
scene:create({ equation, radius_formula, point_formula }, 0.45, "ease_out", 0.08)
scene:wait(0.6)
return scene
