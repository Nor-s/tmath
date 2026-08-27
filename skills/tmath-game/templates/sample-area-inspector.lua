-- Click-only pixel and object-family inspection template.
-- Requires a tmath build configured with -Dui=true and a CPU sampling host.
if not tmath.ui then
    error("sample-area-inspector.lua requires a tmath build configured with -Dui=true")
end

local WIDTH, HEIGHT = 960, 540
local scene = tmath.scene {
    width = WIDTH, height = HEIGHT, fps = 30, loop = true,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = HEIGHT},
}

local LAYER = {surface = 10, candidate = 20, mark = 34, text = 40}
local FIELD = {left = -408, right = 118, bottom = -132, top = 156}

local function pixel_region(left, top, right, bottom)
    return {
        x = left + WIDTH / 2,
        y = HEIGHT / 2 - top,
        width = right - left,
        height = top - bottom,
    }
end

scene:text {
    text = "Inspect the rendered result",
    point = {-424, 226}, align = {0, 0.5}, role = "h2",
    layer = LAYER.text, id = "sample-inspector:title",
}
scene:text {
    text = "Click a painted candidate. Release commits the marker and sampled-color swatch.",
    point = {-424, 187}, align = {0, 0.5}, role = "text", fill = "muted",
    layer = LAYER.text, id = "sample-inspector:subtitle",
}

-- The backing surface defines the exact logical-pixel sampling region.
scene:rectangle {
    center = {(FIELD.left + FIELD.right) / 2, (FIELD.top + FIELD.bottom) / 2},
    size = {FIELD.right - FIELD.left, FIELD.top - FIELD.bottom}, corner = 4,
    fill = "surface", stroke = "border", width = 1.5,
    layer = LAYER.surface, id = "sample-inspector:field",
}

local gradient = scene:rectangle {
    center = {-286, 42}, size = {184, 166}, corner = 3,
    fill = "#25A7E0", gradient = "#8A6FE8", stroke = "#FFFFFF33", width = 1,
    layer = LAYER.candidate, id = "sample-inspector:candidate:gradient",
}
local disk = scene:circle {
    center = {-102, 25}, radius = 82,
    fill = "#F0B84BDB", stroke = "#FFE3A4", width = 2,
    layer = LAYER.candidate + 1, id = "sample-inspector:candidate:disk",
}
local wedge = scene:polygon {
    points = {{-12, -104}, {87, -72}, {78, 88}, {20, 118}},
    fill = "#53C592D6", stroke = "#9BE7C0", width = 2,
    layer = LAYER.candidate + 2, id = "sample-inspector:candidate:wedge",
}

scene:text {
    text = "gradient", point = {-334, -106}, role = "code", fill = "muted",
    layer = LAYER.text, id = "sample-inspector:legend:gradient",
}
scene:text {
    text = "disk", point = {-123, -106}, role = "code", fill = "muted",
    layer = LAYER.text, id = "sample-inspector:legend:disk",
}
scene:text {
    text = "wedge", point = {55, -106}, role = "code", fill = "muted",
    layer = LAYER.text, id = "sample-inspector:legend:wedge",
}

-- The complete marker family stays hidden until the first successful sample.
local marker = scene:group {id = "sample-inspector:selection-marker"}
marker:circle {
    center = {0, 0}, radius = 11, fill = "#00000000", stroke = "foreground", width = 2,
    layer = LAYER.mark, id = "sample-inspector:selection-marker:ring",
}
marker:line {
    from = {-16, 0}, to = {16, 0}, color = "foreground", width = 1.5,
    layer = LAYER.mark + 1, id = "sample-inspector:selection-marker:x",
}
marker:line {
    from = {0, -16}, to = {0, 16}, color = "foreground", width = 1.5,
    layer = LAYER.mark + 1, id = "sample-inspector:selection-marker:y",
}

scene:line {
    from = {166, -132}, to = {166, 156}, color = "border", width = 1,
    layer = LAYER.surface, id = "sample-inspector:result-divider",
}
scene:text {
    text = "Committed sample", point = {214, 128}, align = {0, 0.5}, role = "h3",
    layer = LAYER.text, id = "sample-inspector:result-title",
}
scene:text {
    text = "candidate family\nnormalized (u, v)\nstraight RGBA",
    point = {214, 70}, align = {0, 0.5}, role = "text", fill = "muted",
    layer = LAYER.text, id = "sample-inspector:result-fields",
}

local swatch = scene:rectangle {
    center = {292, -34}, size = {164, 94}, corner = 4,
    fill = "surface", stroke = "border", width = 2,
    layer = LAYER.candidate, id = "sample-inspector:result-swatch",
}
scene:text {
    text = "sampled color", point = {292, -97}, role = "code", fill = "muted",
    layer = LAYER.text, id = "sample-inspector:result-swatch-label",
}
scene:text {
    text = "Miss → keep last result",
    point = {214, -153}, align = {0, 0.5}, role = "text", fill = "muted",
    layer = LAYER.text, id = "sample-inspector:miss-contract",
}

local panel = tmath.ui.panel(scene)
panel:sample_area {
    region = pixel_region(FIELD.left, FIELD.top, FIELD.right, FIELD.bottom),
    targets = {gradient, disk, wedge},
    marker = marker,
    marker_origin = {FIELD.left, FIELD.top, 0},
    marker_x = {FIELD.right - FIELD.left, 0, 0},
    marker_y = {0, FIELD.bottom - FIELD.top, 0},
    swatch = swatch,
}

scene:wait(12)
return scene
