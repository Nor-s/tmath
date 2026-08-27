local palette = {
    background = "#0b111a",
    panel = "#101925",
    line = "#2a3a4d",
    text = "#f4f7fb",
    muted = "#94a3b8",
    cyan = "#4cc9f0",
    cyan_mid = "#388faa",
    cyan_low = "#244f62",
    coral = "#ff6b6b",
    gold = "#ffd166",
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
    text = "THORVG · SOFTWARE RASTERIZER / 02",
    point = { -5.85, 3.28 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = palette.muted,
}
local title = space:text {
    text = "Edge coverage and anti-aliasing",
    point = { -5.85, 2.82 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 30,
    fill = palette.text,
}
local subtitle = space:text {
    text = "Conceptual map · binary test -> fractional pixel coverage",
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

local panels = {
    space:rectangle {
        center = { -3.1, -0.24 },
        size = { 5.65, 4.20 },
        corner = 0.15,
        fill = palette.panel,
        stroke = palette.line,
        width = 2,
    },
    space:rectangle {
        center = { 3.1, -0.24 },
        size = { 5.65, 4.20 },
        corner = 0.15,
        fill = palette.panel,
        stroke = palette.line,
        width = 2,
    },
}
local panel_titles = {
    space:text {
        text = "A  ·  BINARY COVERAGE",
        point = { -5.63, 1.48 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 13,
        fill = palette.muted,
    },
    space:text {
        text = "B  ·  FRACTIONAL COVERAGE",
        point = { 0.58, 1.48 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 13,
        fill = palette.muted,
    },
}

local hard_patches = {}
local aa_patches = {}
for y = 0, 7 do
    for x = 0, 7 do
        hard_patches[#hard_patches + 1] = {
            region = { x, y, 1, 1 },
            color = x >= y and palette.cyan or "#1b2734",
        }
        local distance = x - y
        local color = "#1b2734"
        if distance >= 1 then
            color = palette.cyan
        elseif distance == 0 then
            color = palette.cyan_mid
        elseif distance == -1 then
            color = palette.cyan_low
        end
        aa_patches[#aa_patches + 1] = { region = { x, y, 1, 1 }, color = color }
    end
end

local hard_space = space:space {
    x = { 0, 8, 1 },
    y = { 0, 8, 1 },
    opacity = 0,
    matrix = { 0.37, 0, 0, -4.58, 0, 0.37, 0, -1.72, 0, 0, 1, 0, 0, 0, 0, 1 },
}
local aa_space = space:space {
    x = { 0, 8, 1 },
    y = { 0, 8, 1 },
    opacity = 0,
    matrix = { 0.37, 0, 0, 1.62, 0, 0.37, 0, -1.72, 0, 0, 1, 0, 0, 0, 0, 1 },
}
local hard = hard_space:cell {
    origin = { 0, 0 },
    size = { 8, 8 },
    mode = "padd",
    padding = 0.04,
    color = "#1b2734",
    patches = hard_patches,
    id = "binary-coverage",
}
local aa = aa_space:cell {
    origin = { 0, 0 },
    size = { 8, 8 },
    mode = "padd",
    padding = 0.04,
    color = "#1b2734",
    patches = aa_patches,
    id = "fractional-coverage",
}
local edges = {
    hard_space:line { from = { 0, 0 }, to = { 8, 8 }, color = palette.coral, width = 2 },
    aa_space:line { from = { 0, 0 }, to = { 8, 8 }, color = palette.coral, width = 2 },
}
local mechanism_labels = {
    space:text {
        text = "alpha = 0 or 1",
        point = { -3.1, -2.05 },
        font = "Pretendard",
        size = 16,
        fill = palette.text,
    },
    space:text {
        text = "alpha = covered area / pixel area",
        point = { 3.1, -2.05 },
        font = "Pretendard",
        size = 16,
        fill = palette.text,
    },
}
local result = space:text {
    text = "RESULT  ·  out = α · source + (1 − α) · destination",
    point = { 0, -2.78 },
    font = "Pretendard",
    size = 18,
    fill = palette.gold,
}
local conclusion = space:text {
    text = "fractional coverage softens the staircase without moving the edge",
    point = { 0, -3.14 },
    font = "Pretendard",
    size = 13,
    fill = palette.green,
}

scene:create({ eyebrow, title, subtitle, divider }, 0.52, "ease_out", 0.06)
scene:create(panels, 0.42, "ease_out", 0.08)
scene:create(panel_titles, 0.30, "ease_out", 0.08)
scene:create(hard, 0.72, "linear")
scene:create({ edges[1], mechanism_labels[1] }, 0.38, "ease_out", 0.06)
scene:create(aa, 0.78, "linear")
scene:create({ edges[2], mechanism_labels[2] }, 0.42, "ease_out", 0.06)
scene:create(result, 0.38, "ease_out")
scene:create(conclusion, 0.30, "ease_out")
scene:wait(0.70)
return scene
