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
    outer = "#25314a",
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
    text = "THORVG · SOFTWARE RASTERIZER / 04",
    point = { -5.85, 3.28 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = palette.muted,
}
local title = space:text {
    text = "Radial gradient sampling",
    point = { -5.85, 2.82 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 30,
    fill = palette.text,
}
local subtitle = space:text {
    text = "Normalize distance from the center before interpolating the stops",
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
        center = { -3.10, -0.30 },
        size = { 5.65, 4.20 },
        corner = 0.15,
        fill = palette.panel,
        stroke = palette.line,
        width = 2,
    },
    space:rectangle {
        center = { 3.10, -0.30 },
        size = { 5.65, 4.20 },
        corner = 0.15,
        fill = palette.panel,
        stroke = palette.line,
        width = 2,
    },
}
local panel_titles = {
    space:text {
        text = "MECHANISM · NORMALIZED DISTANCE",
        point = { -5.62, 1.48 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 13,
        fill = palette.muted,
    },
    space:text {
        text = "RESULT · COLOR FIELD",
        point = { 0.58, 1.48 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 13,
        fill = palette.muted,
    },
}

local center = { -3.15, -0.38 }
local function ellipse(rx, ry, color, width)
    local points = {}
    for i = 0, 64 do
        local angle = i * math.pi * 2 / 64
        points[#points + 1] = {
            center[1] + rx * math.cos(angle),
            center[2] + ry * math.sin(angle),
        }
    end
    return space:plot {
        points = points,
        color = color,
        width = width,
        layer = 2,
    }
end
local rings = {
    ellipse(2.25, 1.35, palette.line, 2),
    ellipse(1.50, 0.90, palette.cyan, 2),
    ellipse(0.75, 0.45, palette.gold, 2),
}
local center_point = space:point {
    point = center,
    fill = palette.gold,
    radius = 7,
    layer = 6,
}
local sample_point = { -1.42, 0.34 }
local radius = space:arrow {
    from = center,
    to = sample_point,
    tip = 11,
    color = palette.coral,
    width = 3,
    id = "radial-distance",
}
local sample = space:point {
    point = sample_point,
    fill = palette.coral,
    radius = 6,
    layer = 6,
}
local guide_labels = {
    space:text {
        text = "c",
        point = { -3.42, -0.67 },
        font = "Pretendard",
        size = 15,
        fill = palette.gold,
    },
    space:text {
        text = "p",
        point = { -1.20, 0.52 },
        font = "Pretendard",
        size = 15,
        fill = palette.coral,
    },
    space:text {
        text = "t = length((p - c) / radius)",
        point = { -3.10, -2.08 },
        font = "Pretendard",
        size = 17,
        fill = palette.text,
    },
}

local pixel_space = space:space {
    x = { 0, 24, 1 },
    y = { 0, 16, 1 },
    opacity = 0,
    matrix = { 0.18, 0, 0, 0.94, 0, 0.18, 0, -1.75, 0, 0, 1, 0, 0, 0, 0, 1 },
}
local patches = {}
for y = 0, 15 do
    for x = 0, 23 do
        local dx = (x - 11.5) / 11.5
        local dy = (y - 7.5) / 7.5
        local t = math.min(1, math.sqrt(dx * dx + dy * dy))
        local r = math.floor(255 + (37 - 255) * t + 0.5)
        local g = math.floor(209 + (49 - 209) * t + 0.5)
        local b = math.floor(102 + (74 - 102) * t + 0.5)
        patches[#patches + 1] = {
            region = { x, y, 1, 1 },
            color = string.format("#%02x%02x%02x", r, g, b),
        }
    end
end
local gradient = pixel_space:cell {
    origin = { 0, 0 },
    size = { 24, 16 },
    mode = "full",
    color = palette.outer,
    patches = patches,
    id = "radial-gradient",
}
local color_formula = space:text {
    text = "color(p) = mix(center, outer, clamp(t, 0, 1))",
    point = { 3.10, -2.08 },
    font = "Pretendard",
    size = 14,
    fill = palette.text,
}
local conclusion = space:text {
    text = "RESULT  ·  equal normalized distance produces equal color",
    point = { 0, -2.92 },
    font = "Pretendard",
    size = 17,
    fill = palette.green,
}
local note = space:text {
    text = "ellipse radii scale x and y independently",
    point = { 0, -3.27 },
    font = "Pretendard",
    size = 13,
    fill = palette.muted,
}

scene:create({ eyebrow, title, subtitle, divider }, 0.52, "ease_out", 0.06)
scene:create(panels, 0.42, "ease_out", 0.08)
scene:create(panel_titles, 0.30, "ease_out", 0.08)
scene:create(rings, 0.68, "ease_out", 0.08)
scene:create(center_point, 0.24, "ease_out")
scene:create({ radius, sample }, 0.48, "ease_out", 0.07)
scene:create(guide_labels, 0.36, "ease_out", 0.06)
scene:create(gradient, 1.10, "linear")
scene:create(color_formula, 0.34, "ease_out")
scene:create({ conclusion, note }, 0.42, "ease_out", 0.07)
scene:wait(0.70)
return scene
