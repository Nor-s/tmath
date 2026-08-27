local p = {
    paper = "#f7f8fb",
    panel = "#ffffff",
    ink = "#182033",
    muted = "#687086",
    purple = "#7c3aed",
    red = "#ef4444",
}
local columns, rows, buffer = 48, 30, {}
local function channel(value)
    return math.max(0, math.min(255, math.floor(value + 0.5)))
end
for row = 0, rows - 1 do
    local v = row / (rows - 1)
    for column = 0, columns - 1 do
        local u = column / (columns - 1)
        local glow = math.exp(-10 * ((u - 0.68) ^ 2 + (v - 0.34) ^ 2))
        local r = channel(28 + 205 * u + 42 * glow)
        local g = channel(48 + 150 * (1 - v) + 50 * glow)
        local b = channel(118 + 105 * v - 62 * u + 30 * math.sin(6.28 * (u + v)))
        buffer[#buffer + 1] = string.format("#%02x%02x%02x", r, g, b)
    end
end

local image_width, zoom_scale = 8.4, 3.0
local first, second, third = { -2.6, 1.15 }, { 2.35, -1.1 }, { -0.3, 0 }
local source = tmath.scene {
    width = 570,
    height = 360,
    fps = 60,
    background = p.panel,
    camera = { mode = "fixed", view = "2d", height = 6.2 },
}
local source_image = source:image {
    pixels = buffer,
    size = { columns, rows },
    center = { 0, 0 },
    width = image_width,
    filter = "bilinear",
    layer = 0,
    id = "gradient-buffer-source",
}
local frame = source:rectangle {
    center = first,
    size = { 1.894, 2.067 },
    corner = 0.04,
    fill = "#00000010",
    stroke = p.purple,
    width = 5,
    layer = 30,
    id = "zoom-frame",
}
source:fade_in(source_image, { scale = 0.96, duration = 0.45, curve = "ease_out" })
source:create(frame, 0.25, "ease_out")
source:wait(0.2)
source:shift(frame, { second[1] - first[1], second[2] - first[2] }, 1.0, "ease_in_out")
source:shift(frame, { third[1] - second[1], third[2] - second[2] }, 0.85, "ease_in_out")
source:wait(0.45)

local zoom = tmath.scene {
    width = 330,
    height = 360,
    fps = 60,
    background = p.panel,
    camera = { mode = "fixed", view = "2d", height = 6.2 },
}
local zoom_image = zoom:image {
    pixels = buffer,
    size = { columns, rows },
    center = { -zoom_scale * first[1], -zoom_scale * first[2] },
    width = image_width * zoom_scale,
    filter = "nearest",
    id = "gradient-buffer-zoom",
}
zoom:fade_in(zoom_image, { scale = 0.96, duration = 0.45, curve = "ease_out" })
zoom:wait(0.45)
zoom:shift(
    zoom_image,
    { -zoom_scale * (second[1] - first[1]), -zoom_scale * (second[2] - first[2]) },
    1.0,
    "ease_in_out"
)
zoom:shift(
    zoom_image,
    { -zoom_scale * (third[1] - second[1]), -zoom_scale * (third[2] - second[2]) },
    0.85,
    "ease_in_out"
)
zoom:wait(0.45)

local page = tmath.scene {
    width = 960,
    height = 540,
    fps = 60,
    background = p.paper,
    camera = { mode = "fixed", view = "2d", height = 7 },
}
page:text {
    text = "IMAGE BUFFER  /  MOVING ZOOM",
    point = { -5.7, 2.72 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 27,
    fill = p.ink,
}
page:text {
    text = "one generated pixel buffer, sampled through two image filters",
    point = { -5.68, 2.20 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = p.muted,
}
page:text {
    text = "BILINEAR SOURCE",
    point = { -5.28, 1.72 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 11,
    fill = p.purple,
}
page:text {
    text = "NEAREST  ·  3×",
    point = { 2.02, 1.72 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 11,
    fill = p.red,
}
page:viewport(source, { x = 0.03, y = 0.29, width = 0.58, height = 0.66 })
page:viewport(zoom, { x = 0.63, y = 0.29, width = 0.34, height = 0.66 })
return page
