local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 60,
    background = "#f7f8fb",
    camera = { mode = "fixed", view = "2d", height = 7 },
}

scene:text {
    text = "MOVING AROUND",
    point = { -5.7, 2.62 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 27,
    fill = "#182033",
}
scene:text {
    text = "shift  ·  fill  ·  scale  ·  rotate",
    point = { -5.68, 2.10 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = "#687086",
}

local square = scene:rectangle {
    center = { 0, 0 },
    size = { 2.2, 2.2 },
    corner = 0.08,
    fill = "#2563eb",
    stroke = "#1d4ed8",
    width = 4,
    id = "square",
}

scene:fade_in(square, { scale = 0.8, duration = 0.30, curve = "snappy" })
scene:shift(square, { -2.2, 0 }, 0.65, "ease_in_out")
scene:fill(square, "#f97316", 0.52, "ease_in_out")
scene:transform(square, {
    0.42,
    0,
    0,
    -2.2,
    0,
    0.42,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    1,
}, 0.55, "snappy")
scene:transform(square, {
    0.36,
    -0.22,
    0,
    -2.2,
    0.22,
    0.36,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    1,
}, 0.65, { preset = "back", strength = 0.55 })
scene:wait(0.8)
return scene
