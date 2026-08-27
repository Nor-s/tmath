local palette = {
    background = "#0b111a",
    panel = "#101925",
    line = "#2a3a4d",
    text = "#f4f7fb",
    muted = "#94a3b8",
    cyan = "#4cc9f0",
    gold = "#ffd166",
    coral = "#ff6b6b",
    green = "#7bd88f",
}

local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    antialiasing = true,
    background = palette.background,
    camera = { mode = "fixed", view = "2d", height = 7.4 },
}
local space = scene:space {
    x = { -6.5, 6.5, 1 },
    y = { -3.5, 3.5, 1 },
    opacity = 0,
}

local eyebrow = space:text {
    text = "THORVG · SOFTWARE RASTERIZER / 03",
    point = { -5.85, 3.28 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = palette.muted,
}
local title = space:text {
    text = "Linear gradient sampling",
    point = { -5.85, 2.82 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 30,
    fill = palette.text,
}
local subtitle = space:text {
    text = "Project each pixel onto the gradient vector, then interpolate the stops",
    point = { -5.83, 2.34 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 15,
    fill = palette.muted,
}
local divider = space:line {
    from = { -5.85, 2.08 },
    to = { 5.85, 2.08 },
    color = palette.line,
    width = 2,
}

local mechanism_label = space:text {
    text = "MECHANISM · PROJECT p ONTO d",
    point = { -5.75, 1.72 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = palette.muted,
}
local projection = space:text {
    text = "t = clamp( dot(p − p₀, d) / dot(d, d), 0, 1 )",
    point = { 5.75, 1.72 },
    align = { 1, 0.5 },
    font = "Pretendard",
    size = 15,
    fill = palette.text,
}
local direction = space:arrow {
    from = { -5.45, 1.16 },
    to = { 5.45, 1.16 },
    tail = 8,
    tip = 13,
    color = palette.text,
    width = 3,
    id = "gradient-direction",
}
local stops = {
    space:point { point = { -5.45, 1.16 }, fill = palette.cyan, radius = 7, layer = 5 },
    space:point { point = { 5.45, 1.16 }, fill = palette.coral, radius = 7, layer = 5 },
}
local stop_labels = {
    space:text {
        text = "p₀  ·  t = 0",
        point = { -5.45, 0.82 },
        font = "Pretendard",
        size = 14,
        fill = palette.cyan,
    },
    space:text {
        text = "p₁  ·  t = 1",
        point = { 5.45, 0.82 },
        font = "Pretendard",
        size = 14,
        fill = palette.coral,
    },
}
local sample_x = -1.63
local sample = space:point {
    point = { sample_x, 1.16 },
    fill = palette.gold,
    radius = 7,
    layer = 6,
}
local sample_guide = space:line {
    from = { sample_x, 0.98 },
    to = { sample_x, 0.18 },
    color = palette.gold,
    width = 2,
}
local sample_label = space:text {
    text = "sample p  ·  t = 0.35",
    point = { sample_x + 0.18, 0.63 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 14,
    fill = palette.gold,
}

local result_panel = space:rectangle {
    center = { 0, -0.73 },
    size = { 12.0, 2.40 },
    corner = 0.15,
    fill = palette.panel,
    stroke = palette.line,
    width = 2,
}
local result_label = space:text {
    text = "RESULT · 32 PIXEL SAMPLES",
    point = { -5.65, 0.22 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = palette.muted,
}
local pixel_space = space:space {
    x = { 0, 32, 1 },
    y = { 0, 5, 1 },
    opacity = 0,
    matrix = { 0.35, 0, 0, -5.60, 0, 0.27, 0, -1.42, 0, 0, 1, 0, 0, 0, 0, 1 },
}
local patches = {}
for x = 0, 31 do
    local t = x / 31
    local r = math.floor(76 + (255 - 76) * t + 0.5)
    local g = math.floor(201 + (107 - 201) * t + 0.5)
    local b = math.floor(240 + (107 - 240) * t + 0.5)
    patches[#patches + 1] = {
        region = { x, 0, 1, 5 },
        color = string.format("#%02x%02x%02x", r, g, b),
    }
end
local gradient = pixel_space:cell {
    origin = { 0, 0 },
    size = { 32, 5 },
    mode = "full",
    color = palette.panel,
    patches = patches,
    id = "linear-gradient",
}
local mix_formula = space:text {
    text = "color(p) = mix(stop₀, stop₁, t)",
    point = { 0, -1.70 },
    font = "Pretendard",
    size = 16,
    fill = palette.text,
}
local conclusion = space:text {
    text = "one projected scalar t drives every color channel",
    point = { 0, -2.52 },
    font = "Pretendard",
    size = 17,
    fill = palette.green,
}

scene:create({ eyebrow, title, subtitle, divider }, 0.52, "ease_out", 0.06)
scene:create({ mechanism_label, projection }, 0.36, "ease_out", 0.06)
scene:create(direction, 0.62, "ease_out")
scene:create({ stops[1], stops[2], stop_labels[1], stop_labels[2] }, 0.36, "ease_out", 0.06)
scene:create({ sample, sample_guide, sample_label }, 0.42, "ease_out", 0.06)
scene:create({ result_panel, result_label }, 0.38, "ease_out", 0.05)
scene:create(gradient, 1.00, "linear")
scene:create(mix_formula, 0.32, "ease_out")
scene:create(conclusion, 0.38, "ease_out")
scene:wait(0.70)
return scene
