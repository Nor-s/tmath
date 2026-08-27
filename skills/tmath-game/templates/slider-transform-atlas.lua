-- Multi-target Slider transform atlas.
-- Requires a tmath build configured with -Dui=true.
-- Each Slider drives an independent thumb and one exact runtime transform.
if not tmath.ui then
    error("slider-transform-atlas.lua requires a tmath build configured with -Dui=true")
end

local WIDTH, HEIGHT = 960, 540
local scene = tmath.scene {
    width = WIDTH, height = HEIGHT, fps = 30, loop = true,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = HEIGHT},
}

local LAYER = {rule = 10, evidence = 20, mark = 30, text = 40, control = 50}
local TRACK_X, TRACK_WIDTH = 46, 322

local function translate(x, y)
    return {1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, 0, 0, 0, 0, 1}
end

local function pixel_region(cx, cy, width, height)
    return {
        x = cx - width / 2 + WIDTH / 2,
        y = HEIGHT / 2 - (cy + height / 2),
        width = width,
        height = height,
    }
end
local function text(spec) scene:text(spec) end

for _, spec in ipairs {
    {text = "One slider, multiple synchronized targets", point = {-424, 226}, align = {0, 0.5}, role = "h2", layer = LAYER.text, id = "slider-atlas:title"},
    {text = "Every row maps one normalized value to a thumb and one declared object property.", point = {-424, 187}, align = {0, 0.5}, role = "text", fill = "muted", layer = LAYER.text, id = "slider-atlas:subtitle"},
    {text = "property / range", point = {-424, 146}, align = {0, 0.5}, role = "code", fill = "muted", layer = LAYER.text, id = "slider-atlas:header:property"},
    {text = "visual evidence", point = {-250, 146}, align = {0, 0.5}, role = "code", fill = "muted", layer = LAYER.text, id = "slider-atlas:header:evidence"},
    {text = "normalized value   0 → 1", point = {46, 146}, align = {0, 0.5}, role = "code", fill = "muted", layer = LAYER.text, id = "slider-atlas:header:control"},
} do text(spec) end
scene:line {
    from = {-424, 130}, to = {424, 130}, color = "border", width = 1,
    layer = LAYER.rule, id = "slider-atlas:header-rule",
}
scene:line {
    from = {-82, 130}, to = {-82, -212}, color = "border", width = 1,
    layer = LAYER.rule, id = "slider-atlas:column-rule",
}

local controls = {}

local function label_row(id, y, property, range)
    text {text = property, point = {-424, y + 10}, align = {0, 0.5}, role = "h3", layer = LAYER.text, id = "slider-atlas:" .. id .. ":property"}
    text {text = range, point = {-424, y - 20}, align = {0, 0.5}, role = "code", fill = "muted", layer = LAYER.text, id = "slider-atlas:" .. id .. ":range"}
end

local function add_control(id, y, value, evidence, from, to)
    local parent = scene:group {
        matrix = translate(TRACK_X, y), id = "slider-atlas:" .. id .. ":control-parent",
    }
    local track = parent:group {id = "slider-atlas:" .. id .. ":track"}
    track:line {
        from = {0, 0}, to = {TRACK_WIDTH, 0}, color = "border", width = 4,
        layer = LAYER.control, id = "slider-atlas:" .. id .. ":track:shaft",
    }
    for index, x in ipairs({0, TRACK_WIDTH / 2, TRACK_WIDTH}) do
        track:line {
            from = {x, -7}, to = {x, 7}, color = "border", width = 1.5,
            layer = LAYER.control, id = "slider-atlas:" .. id .. ":track:tick:" .. tostring(index),
        }
    end
    local handle = parent:circle {
        center = {0, 0}, radius = 9, fill = "focus", stroke = "background", width = 3,
        layer = LAYER.control + 1, id = "slider-atlas:" .. id .. ":handle",
    }
    controls[#controls + 1] = {visual = track, handle = handle, evidence = evidence,
        region = pixel_region(TRACK_X + TRACK_WIDTH / 2, y, TRACK_WIDTH, 42), value = value, from = from, to = to}
end

local shift_y = 96
label_row("shift", shift_y, "shift", "x: −48 → 48 px")
local shift_parent = scene:group {
    matrix = translate(-214, shift_y), id = "slider-atlas:shift:evidence-parent",
}
shift_parent:line {
    from = {-58, 0}, to = {58, 0}, color = "border", width = 2,
    layer = LAYER.evidence, id = "slider-atlas:shift:axis",
}
local shift_mark = shift_parent:group {id = "slider-atlas:shift:evidence"}
shift_mark:circle {
    center = {0, 0}, radius = 9, fill = "accent", stroke = "background", width = 2,
    layer = LAYER.mark, id = "slider-atlas:shift:mark",
}
add_control("shift", shift_y, 0.28, shift_mark,
            {shift = {-48, 0, 0}}, {shift = {48, 0, 0}})

local rotation_y = 28
label_row("rotation", rotation_y, "rotation", "θ: −45° → 45°")
local rotation_parent = scene:group {
    matrix = translate(-214, rotation_y), id = "slider-atlas:rotation:evidence-parent",
}
local rotation_mark = rotation_parent:group {id = "slider-atlas:rotation:evidence"}
rotation_mark:line {
    from = {-35, 0}, to = {35, 0}, color = "accent", width = 4,
    layer = LAYER.evidence, id = "slider-atlas:rotation:shaft",
}
rotation_mark:circle {
    center = {0, 0}, radius = 6, fill = "focus", stroke = "background", width = 2,
    layer = LAYER.mark, id = "slider-atlas:rotation:pivot",
}
add_control("rotation", rotation_y, 0.62, rotation_mark,
            {rotation = {0, 0, -math.pi / 4}},
            {rotation = {0, 0, math.pi / 4}})

local scale_y = -40
label_row("scale", scale_y, "scale", "s: 0.6 → 1.4")
local scale_parent = scene:group {
    matrix = translate(-214, scale_y), id = "slider-atlas:scale:evidence-parent",
}
local scale_mark = scale_parent:group {id = "slider-atlas:scale:evidence"}
scale_mark:rectangle {
    center = {0, 0}, size = {64, 32}, corner = 3,
    fill = "#4CC9F026", stroke = "accent", width = 2.5,
    layer = LAYER.evidence, id = "slider-atlas:scale:body",
}
add_control("scale", scale_y, 0.5, scale_mark,
            {scale = {0.6, 0.6, 1}}, {scale = {1.4, 1.4, 1}})

local opacity_y = -108
label_row("opacity", opacity_y, "opacity", "α: 0.15 → 1")
local opacity_parent = scene:group {
    matrix = translate(-214, opacity_y), id = "slider-atlas:opacity:evidence-parent",
}
opacity_parent:circle {
    center = {0, 0}, radius = 23, fill = "#FFFFFF12", stroke = "border", width = 1,
    layer = LAYER.evidence, id = "slider-atlas:opacity:reference",
}
local opacity_mark = opacity_parent:circle {
    center = {0, 0}, radius = 18, fill = "accent", stroke = "accent", width = 1,
    layer = LAYER.mark, id = "slider-atlas:opacity:evidence",
}
add_control("opacity", opacity_y, 0.72, opacity_mark,
            {opacity = 0.15}, {opacity = 1})

local progress_y = -176
label_row("progress", progress_y, "progress", "p: 0 → 1")
local progress_parent = scene:group {
    matrix = translate(-252, progress_y), id = "slider-atlas:progress:evidence-parent",
}
progress_parent:line {
    from = {0, 0}, to = {76, 0}, color = "border", width = 5,
    layer = LAYER.evidence, id = "slider-atlas:progress:reference",
}
local progress_mark = progress_parent:line {
    from = {0, 0}, to = {76, 0}, color = "accent", width = 5,
    layer = LAYER.mark, id = "slider-atlas:progress:evidence",
}
add_control("progress", progress_y, 0.64, progress_mark,
            {progress = 0}, {progress = 1})

local panel = tmath.ui.panel(scene)
for _, control in ipairs(controls) do
    panel:slider {
        visual = control.visual,
        region = control.region,
        axis = "horizontal",
        value = control.value,
        bindings = {
            {
                target = control.handle,
                from = {},
                to = {shift = {TRACK_WIDTH, 0, 0}},
            },
            {
                target = control.evidence,
                from = control.from,
                to = control.to,
            },
        },
    }
end

scene:wait(12)
return scene
