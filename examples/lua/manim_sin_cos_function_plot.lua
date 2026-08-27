local p = {
    paper = "#f7f8fb",
    ink = "#182033",
    muted = "#687086",
    grid = "#dce2ed",
    blue = "#2563eb",
    red = "#ef4444",
    yellow = "#eab308",
}
local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 60,
    background = p.paper,
    camera = { mode = "fixed", view = "2d", height = 7.4 },
}
scene:text {
    text = "SINE AND COSINE",
    point = { -5.75, 2.92 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 27,
    fill = p.ink,
}
scene:text {
    text = "phase-aligned function plots",
    point = { -5.72, 2.42 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = p.muted,
}

local axes = scene:space {
    x = { -2 * math.pi, 2 * math.pi, math.pi / 2 },
    y = { -1.5, 1.5, 0.5 },
    matrix = { 0.72, 0, 0, 0, 0, 1.25, 0, -0.35, 0, 0, 1, 0, 0, 0, 0, 1 },
    color = p.grid,
    axis_x = p.ink,
    axis_y = p.ink,
    width = 1.2,
    numbers = false,
    id = "axes",
}
local sine_points, cosine_points = {}, {}
for sample = 0, 160 do
    local x = -2 * math.pi + 4 * math.pi * sample / 160
    sine_points[#sine_points + 1] = { x, math.sin(x) }
    cosine_points[#cosine_points + 1] = { x, math.cos(x) }
end
local sine = axes:plot { points = sine_points, stroke = p.blue, width = 4, id = "sine" }
local cosine = axes:plot { points = cosine_points, stroke = p.red, width = 4, id = "cosine" }
local tau = axes:line {
    from = { 2 * math.pi, -1.18 },
    to = { 2 * math.pi, 1.18 },
    stroke = p.yellow,
    width = 3,
    id = "tau-line",
}
local labels = {
    scene:text {
        text = "sin(x)",
        point = { -4.8, 1.48 },
        font = "Pretendard",
        size = 16,
        fill = p.blue,
    },
    scene:text {
        text = "cos(x)",
        point = { -4.8, 1.05 },
        font = "Pretendard",
        size = 16,
        fill = p.red,
    },
    scene:text {
        text = "x = 2π",
        point = { 4.58, 1.62 },
        font = "Pretendard",
        size = 13,
        fill = p.yellow,
    },
}
scene:create(axes, 0.45, "ease_out")
scene:create({ sine, cosine }, 1.15, "ease_out", 0)
scene:create(tau, 0.35, "ease_out")
scene:fade_in(labels[1], { shift = { 0.14, 0 }, duration = 0.25, curve = "ease_out" })
scene:fade_in(labels[2], { shift = { 0.14, 0 }, duration = 0.25, curve = "ease_out" })
scene:fade_in(labels[3], { shift = { 0, -0.12 }, duration = 0.25, curve = "ease_out" })
scene:wait(0.8)
return scene
