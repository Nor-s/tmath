-- Visual-computing comparison template: nonlinear reference, local linearization, samples.
-- Geometry is illustrative. Replace transforms, camera convention, and error evidence together.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "pro_white",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local LAYER = {guide = 0, route = 10, shape = 20, text = 30, focus = 40}
local root = scene:group {id = "projection:root"}
local header = root:group {id = "projection:header"}
local source = root:group {id = "projection:source"}
local outputs = root:group {id = "projection:outputs"}
local routes = root:group {id = "projection:routes"}
local evidence = root:group {id = "projection:evidence"}

header:text {
    text = "Geometric projection comparison", point = {0, 232}, role = "h2",
    fill = "foreground", layer = LAYER.text, id = "projection:title",
}
header:text {
    text = "same source object · aligned outputs · illustrative nonlinear transform g",
    point = {0, 199}, role = "code", fill = "muted", layer = LAYER.text,
    id = "projection:subtitle",
}

local function ellipse_points(center, rx, ry, tilt, count)
    local points, c, s = {}, math.cos(tilt), math.sin(tilt)
    for index = 0, count - 1 do
        local angle = 2 * math.pi * index / count
        local x, y = rx * math.cos(angle), ry * math.sin(angle)
        points[#points + 1] = {center[1] + x * c - y * s, center[2] + x * s + y * c}
    end
    return points
end

source:text {
    text = "SOURCE", point = {-385, 137}, role = "code", fill = "muted",
    layer = LAYER.text, id = "projection:source:title",
}
source:polygon {
    points = ellipse_points({-385, 35}, 74, 45, 0.48, 36), fill = "#dbeafe",
    stroke = "accent", width = 2.2, layer = LAYER.shape, id = "projection:source:ellipse",
}
source:line {
    from = {-428, 10}, to = {-342, 60}, color = "accent", width = 1.5,
    layer = LAYER.focus, id = "projection:source:principal-axis",
}
source:circle {
    center = {-385, 35}, radius = 6, fill = "accent", stroke = "accent",
    layer = LAYER.focus, id = "projection:source:center",
}
source:text {
    text = "same source object", point = {-385, -41}, role = "code",
    fill = "muted", layer = LAYER.text, id = "projection:source:detail",
}

local output_specs = {
    {id = "reference", label = "nonlinear reference", center = {-115, 35}, rx = 66, ry = 37, tilt = 0.12, color = "result"},
    {id = "linear", label = "local linearization", center = {155, 35}, rx = 69, ry = 32, tilt = -0.08, color = "accent"},
    {id = "samples", label = "sample points", center = {397, 35}, rx = 66, ry = 37, tilt = 0.12, color = "focus", samples = true},
}
local output_shapes = {}
for _, spec in ipairs(output_specs) do
    local group = outputs:group {id = "projection:output:" .. spec.id}
    group:text {
        text = spec.label, point = {spec.center[1], 137}, role = "code",
        fill = spec.color, layer = LAYER.text, id = "projection:output:" .. spec.id .. ":title",
    }
    group:rectangle {
        center = {spec.center[1], 35}, size = {212, 164}, corner = 8, fill = "surface",
        stroke = "border", width = 1.2, layer = LAYER.guide,
        id = "projection:output:" .. spec.id .. ":boundary",
    }
    output_shapes[spec.id] = group:polygon {
        points = ellipse_points(spec.center, spec.rx, spec.ry, spec.tilt, 36),
        fill = spec.samples and "#fef3c7" or (spec.id == "reference" and "#dcfce7" or "#dbeafe"),
        stroke = spec.color, width = 2.2, layer = LAYER.shape,
        id = "projection:output:" .. spec.id .. ":shape",
    }
    group:line {
        from = {spec.center[1] - spec.rx, spec.center[2]},
        to = {spec.center[1] + spec.rx, spec.center[2]}, color = "border", width = 0.8,
        layer = LAYER.guide, id = "projection:output:" .. spec.id .. ":axis",
    }
    if spec.samples then
        for sample = 0, 7 do
            local angle = 2 * math.pi * sample / 8
            group:circle {
                center = {spec.center[1] + spec.rx * math.cos(angle), spec.center[2] + spec.ry * math.sin(angle)},
                radius = 5, fill = "focus", stroke = "background", width = 1,
                layer = LAYER.focus, id = "projection:output:samples:point:" .. sample,
            }
        end
    end
    group:text {
        text = spec.id == "reference" and "target geometry" or (spec.id == "linear" and "first-order proxy" or "finite probes"),
        point = {spec.center[1], -68}, role = "code", fill = "muted", layer = LAYER.text,
        id = "projection:output:" .. spec.id .. ":detail",
    }
end

local branch_routes = {}
for index, spec in ipairs(output_specs) do
    local branch_y = -86 - index * 13
    local entry_x = spec.center[1] - 82
    branch_routes[index] = routes:route {
        points = {{-311, 35}, {-277, 35}, {-277, branch_y}, {entry_x, branch_y}, {entry_x, -47}},
        tip = 8, color = spec.color, width = 1.7, layer = LAYER.route,
        id = "projection:route:" .. spec.id,
    }
end
evidence:text {
    text = "g(x)", point = {-276, 57}, role = "code", fill = "foreground",
    layer = LAYER.text, id = "projection:operator-label",
}
evidence:text {
    text = "compare corresponding object, view, crop, and scale", point = {133, -150},
    role = "code", fill = "focus", layer = LAYER.text, id = "projection:alignment-note",
}
local conclusion = root:text {
    text = "A projection figure is evidence only when conventions and comparison frames are held constant.",
    point = {0, -224}, role = "code", fill = "result", layer = LAYER.text,
    id = "projection:conclusion",
}

scene:fade_in(header, {shift = {0, -6}, duration = 0.5, curve = "gentle"})
scene:fade_in(source, {shift = {0, -6}, duration = 0.6, curve = "ease_out"})
scene:create(branch_routes, 0.8, "ease_out", 0.08, "forward")
scene:fade_in(outputs, {shift = {0, -6}, duration = 0.8, curve = "gentle"})
scene:indicate(output_shapes.reference, {color = "result", scale = 1.025, duration = 0.4, curve = "ease_in_out"})
scene:fade_in(evidence, {duration = 0.35, curve = "gentle"})
scene:fade_in(conclusion, {duration = 0.35, curve = "gentle"})
scene:wait(2.3)
return scene
