-- Interactive parameter template.
-- Requires a tmath build configured with -Dui=true.
-- The Slider applies the exact translation h -> 85h to the full curve/vertex/handle family.
if not tmath.ui then
    error("slider-function-translation.lua requires a tmath build configured with -Dui=true")
end

local WIDTH, HEIGHT = 960, 540
local scene = tmath.scene {
    width = WIDTH, height = HEIGHT, fps = 30, loop = true,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = HEIGHT},
}

local LAYER = {grid = 10, curve = 20, mark = 30, text = 40, control = 50}
local X_SCALE, Y_SCALE = 85, 55
local AXIS_Y = -58

local function pixel_region(cx, cy, width, height)
    return {
        x = cx - width / 2 + WIDTH / 2,
        y = HEIGHT / 2 - (cy + height / 2),
        width = width,
        height = height,
    }
end

scene:text {
    text = "Translate a quadratic by its parameter",
    point = {-424, 226}, align = {0, 0.5}, role = "h2",
    layer = LAYER.text, id = "quadratic-slider:title",
}
scene:text {
    text = "g_h(x) = (x - h)²     h ∈ [−2, 2]",
    point = {-424, 183}, align = {0, 0.5}, role = "h3", fill = "accent",
    layer = LAYER.text, id = "quadratic-slider:formula",
}

-- Coordinate scaffold: one mathematical x-unit is exactly X_SCALE Scene units.
scene:line {
    from = {-4.35 * X_SCALE, AXIS_Y}, to = {4.35 * X_SCALE, AXIS_Y},
    color = "border", width = 1.5, layer = LAYER.grid,
    id = "quadratic-slider:axis:x",
}
scene:line {
    from = {0, AXIS_Y - 14}, to = {0, 145},
    color = "border", width = 1.5, layer = LAYER.grid,
    id = "quadratic-slider:axis:y",
}

for x = -4, 4 do
    local px = x * X_SCALE
    scene:line {
        from = {px, AXIS_Y - 5}, to = {px, AXIS_Y + 5},
        color = "border", width = 1.2, layer = LAYER.grid,
        id = "quadratic-slider:tick:x:" .. tostring(x),
    }
    if x % 2 == 0 then
        scene:text {
            text = tostring(x), point = {px, AXIS_Y - 23}, role = "code", fill = "muted",
            layer = LAYER.text, id = "quadratic-slider:tick-label:x:" .. tostring(x),
        }
    end
end

for y = 1, 3 do
    local py = AXIS_Y + y * Y_SCALE
    scene:line {
        from = {-5, py}, to = {5, py}, color = "border", width = 1.2,
        layer = LAYER.grid, id = "quadratic-slider:tick:y:" .. tostring(y),
    }
    scene:text {
        text = tostring(y), point = {-18, py}, role = "code", fill = "muted",
        layer = LAYER.text, id = "quadratic-slider:tick-label:y:" .. tostring(y),
    }
end

local parameter_family = scene:group {id = "quadratic-slider:parameter-family"}
local curve_points = {}
for i = 0, 80 do
    local x = -1.7 + 3.4 * i / 80
    curve_points[#curve_points + 1] = {x * X_SCALE, AXIS_Y + x * x * Y_SCALE}
end
parameter_family:plot {
    points = curve_points, stroke = "accent", width = 4,
    layer = LAYER.curve, id = "quadratic-slider:curve",
}
parameter_family:line {
    from = {0, AXIS_Y}, to = {0, 131}, dash = {6, 6},
    color = "muted", width = 1.5, layer = LAYER.grid,
    id = "quadratic-slider:vertex-guide",
}
parameter_family:point {
    point = {0, AXIS_Y}, radius = 7, fill = "focus", stroke = "background", width = 2,
    layer = LAYER.mark, id = "quadratic-slider:vertex",
}
parameter_family:text {
    text = "(h, 0)", point = {16, AXIS_Y + 20}, align = {0, 0.5},
    role = "code", fill = "focus", layer = LAYER.text,
    id = "quadratic-slider:vertex-label",
}

scene:text {
    text = "Drag h",
    point = {0, -168}, role = "text", fill = "muted",
    layer = LAYER.text, id = "quadratic-slider:control-label",
}

-- The track is the Slider visual. The handle belongs to the translated target family.
local slider_track = scene:group {id = "quadratic-slider:track"}
slider_track:line {
    from = {-2 * X_SCALE, -211}, to = {2 * X_SCALE, -211},
    color = "border", width = 5, layer = LAYER.control,
    id = "quadratic-slider:track:shaft",
}
for _, h in ipairs({-2, 0, 2}) do
    local px = h * X_SCALE
    slider_track:line {
        from = {px, -219}, to = {px, -203}, color = "border", width = 2,
        layer = LAYER.control, id = "quadratic-slider:track:tick:" .. tostring(h),
    }
    scene:text {
        text = tostring(h), point = {px, -240}, role = "code", fill = "muted",
        layer = LAYER.text, id = "quadratic-slider:track:label:" .. tostring(h),
    }
end
parameter_family:circle {
    center = {0, -211}, radius = 10, fill = "focus", stroke = "background", width = 3,
    layer = LAYER.control + 1, id = "quadratic-slider:handle",
}

local panel = tmath.ui.panel(scene)
panel:slider {
    visual = slider_track,
    target = parameter_family,
    region = pixel_region(0, -211, 4 * X_SCALE, 54),
    axis = "horizontal",
    value = 0.5,
    from = {shift = {-2 * X_SCALE, 0, 0}},
    to = {shift = {2 * X_SCALE, 0, 0}},
}

scene:wait(12)
return scene
