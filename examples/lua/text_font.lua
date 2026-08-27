local palette = {
    background = "#0b111a",
    panel = "#101925",
    line = "#263447",
    text = "#f4f7fb",
    muted = "#94a3b8",
    cyan = "#4cc9f0",
    magenta = "#f72585",
    gold = "#ffd166",
    green = "#7bd88f",
    point = "#ff6b6b",
}

local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    background = palette.background,
    camera = { mode = "fixed", view = "2d", target = { 0, 0 }, height = 6.8 },
}
local space = scene:space { x = { -6, 6, 1 }, y = { -3.4, 3.4, 1 }, progress = 0 }

local hero_card = space:rectangle {
    center = { 2.5, 2.12 },
    size = { 5.65, 1.25 },
    corner = 0.12,
    fill = palette.panel,
    stroke = palette.line,
    width = 2,
}
local divider_top = space:line {
    from = { -5.45, 1.28 },
    to = { 5.45, 1.28 },
    color = palette.line,
    width = 2,
}
local divider_bottom = space:line {
    from = { -5.45, -1.55 },
    to = { 5.45, -1.55 },
    color = palette.line,
    width = 2,
}
local kicker = space:text {
    text = "TEXT / FONT SPECIMEN",
    point = { -5.35, 2.86 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 14,
    fill = palette.muted,
}
local family = space:text {
    text = "Pretendard",
    point = { -5.35, 2.12 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 43,
    fill = palette.text,
    id = "font-family",
}
local family_note = space:text {
    text = "ThorVG text object · loaded TTF",
    point = { -5.32, 1.62 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 15,
    fill = palette.muted,
}
local hero = space:text {
    text = "Aa 0123",
    point = { -0.08, 2.10 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 50,
    fill = palette.cyan,
    id = "hero-sample",
}

local size_label = space:text {
    text = "SIZE",
    point = { -5.35, 0.92 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = palette.muted,
}
local size_18 = space:text {
    text = "18 px",
    point = { -3.85, 0.45 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 18,
    fill = palette.text,
}
local size_28 = space:text {
    text = "28 px",
    point = { -1.45, 0.45 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 28,
    fill = palette.cyan,
}
local size_40 = space:text {
    text = "40 px",
    point = { 1.65, 0.45 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 40,
    fill = palette.gold,
}

local align_label = space:text {
    text = "ALIGN",
    point = { -5.35, -0.15 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = palette.muted,
}
local guides = {
    space:line { from = { -2.7, -1.30 }, to = { -2.7, -0.22 }, color = palette.line, width = 2 },
    space:line { from = { 0, -1.30 }, to = { 0, -0.22 }, color = palette.line, width = 2 },
    space:line { from = { 2.7, -1.30 }, to = { 2.7, -0.22 }, color = palette.line, width = 2 },
    space:point { point = { -2.7, -0.73 }, fill = palette.point, radius = 4, layer = 5 },
    space:point { point = { 0, -0.73 }, fill = palette.point, radius = 4, layer = 5 },
    space:point { point = { 2.7, -0.73 }, fill = palette.point, radius = 4, layer = 5 },
}
local left_text = space:text {
    text = "left",
    point = { -2.7, -0.73 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 21,
    fill = palette.green,
}
local center_text = space:text {
    text = "center",
    point = { 0, -0.73 },
    align = { 0.5, 0.5 },
    font = "Pretendard",
    size = 21,
    fill = palette.green,
}
local right_text = space:text {
    text = "right",
    point = { 2.7, -0.73 },
    align = { 1, 0.5 },
    font = "Pretendard",
    size = 21,
    fill = palette.green,
}

local color_label = space:text {
    text = "SEMANTIC COLOR",
    point = { -5.35, -1.90 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = palette.muted,
}
local color_a = space:text {
    text = "a",
    point = { -5.35, -2.48 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 30,
    fill = palette.cyan,
}
local color_plus = space:text {
    text = "+",
    point = { -4.92, -2.48 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 30,
    fill = palette.muted,
}
local color_b = space:text {
    text = "b",
    point = { -4.40, -2.48 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 30,
    fill = palette.magenta,
}
local color_equals = space:text {
    text = "=",
    point = { -3.88, -2.48 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 30,
    fill = palette.muted,
}
local color_c = space:text {
    text = "c",
    point = { -3.30, -2.48 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 30,
    fill = palette.gold,
}
local utf_label = space:text {
    text = "UTF-8 / MATH",
    point = { 0.15, -1.90 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = palette.muted,
}
local utf_sample = space:text {
    text = "π  λ  α  β  θ   Σ  ∫",
    point = { 0.15, -2.48 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 28,
    fill = palette.text,
    id = "utf8-sample",
}

scene:create({ hero_card, divider_top, divider_bottom, kicker }, 0.42, "ease_out", 0.05)
scene:create({ family, family_note, hero }, 0.62, "ease_out", 0.08)
scene:create(size_label, 0.24, "ease_out")
scene:create({ size_18, size_28, size_40 }, 0.52, "ease_out", 0.08)
scene:create(
    { align_label, guides[1], guides[2], guides[3], guides[4], guides[5], guides[6] },
    0.38,
    "ease_out",
    0.04
)
scene:create({ left_text, center_text, right_text }, 0.42, "ease_out", 0.08)
scene:create({ color_label, utf_label }, 0.26, "ease_out", 0.06)
scene:create(
    { color_a, color_plus, color_b, color_equals, color_c, utf_sample },
    0.46,
    "ease_out",
    0.06
)
scene:wait(0.72)
return scene
