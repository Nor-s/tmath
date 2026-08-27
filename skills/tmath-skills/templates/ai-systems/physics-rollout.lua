-- Physics-AI one-step operator and autoregressive rollout template.
-- Mesh geometry and field values are illustrative; preserve source coordinates and units.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "pro_white",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local LAYER = {mesh = 0, route = 10, node = 20, text = 30, focus = 40}
local root = scene:group {id = "physics-rollout:root"}
local header = root:group {id = "physics-rollout:header"}
local input = root:group {id = "physics-rollout:input"}
local operator = root:group {id = "physics-rollout:operator"}
local output = root:group {id = "physics-rollout:output"}
local routes = root:group {id = "physics-rollout:routes"}
local timeline = root:group {id = "physics-rollout:timeline"}

header:text {
    text = "Physics-AI rollout", point = {0, 232}, role = "h2",
    fill = "foreground", layer = LAYER.text, id = "physics-rollout:title",
}
header:text {
    text = "one-step learned operator · illustrative mesh and scalar field",
    point = {0, 199}, role = "code", fill = "muted", layer = LAYER.text,
    id = "physics-rollout:subtitle",
}

local function mesh(parent, prefix, center, displaced)
    local points = {}
    for row = 0, 2 do
        for column = 0, 3 do
            local index = row * 4 + column + 1
            local dx = displaced and (row - 1) * 5 + column * 2 or 0
            local dy = displaced and math.sin((column + row) * 1.2) * 7 or 0
            points[index] = {center[1] - 78 + column * 52 + dx, center[2] + 49 - row * 49 + dy}
        end
    end
    for row = 0, 2 do
        for column = 0, 2 do
            local a = row * 4 + column + 1
            parent:line {
                from = points[a], to = points[a + 1], color = "border", width = 1.4,
                layer = LAYER.mesh, id = prefix .. ":edge:h:" .. row .. ":" .. column,
            }
        end
    end
    for row = 0, 1 do
        for column = 0, 3 do
            local a = row * 4 + column + 1
            parent:line {
                from = points[a], to = points[a + 4], color = "border", width = 1.4,
                layer = LAYER.mesh, id = prefix .. ":edge:v:" .. row .. ":" .. column,
            }
        end
    end
    for index, point in ipairs(points) do
        local hot = displaced and index >= 7 or (not displaced and index >= 9)
        parent:circle {
            center = point, radius = 8, fill = hot and "#fb7185" or "#60a5fa",
            stroke = "background", width = 1.4, layer = LAYER.node,
            id = prefix .. ":point:" .. index,
        }
    end
end

input:text {
    text = "state u(t)", point = {-356, 130}, role = "text", fill = "accent",
    layer = LAYER.text, id = "physics-rollout:input:title",
}
mesh(input, "physics-rollout:input-mesh", {-356, 36}, false)
input:text {
    text = "state + boundary", point = {-356, -47}, role = "code",
    fill = "muted", layer = LAYER.text, id = "physics-rollout:input:detail",
}

local operator_specs = {
    {id = "encode", label = "Encode", detail = "state", center = {-130, 36}, size = {100, 76}},
    {id = "message", label = "Message", detail = "×K local passes", center = {12, 36}, size = {146, 76}, focal = true},
    {id = "decode", label = "Decode", detail = "Δu or u′", center = {156, 36}, size = {100, 76}},
}
local operator_bodies = {}
for _, spec in ipairs(operator_specs) do
    local group = operator:group {id = "physics-rollout:operator:" .. spec.id}
    operator_bodies[spec.id] = group:rectangle {
        center = spec.center, size = spec.size, corner = 7, fill = "surface",
        stroke = spec.focal and "focus" or "border", width = spec.focal and 2.1 or 1.2,
        layer = LAYER.node, id = "physics-rollout:operator:" .. spec.id .. ":body",
    }
    group:text {
        text = spec.label, point = {spec.center[1], spec.center[2] + 12}, role = "text",
        fill = spec.focal and "focus" or "foreground", layer = LAYER.text,
        id = "physics-rollout:operator:" .. spec.id .. ":label",
    }
    group:text {
        text = spec.detail, point = {spec.center[1], spec.center[2] - 17}, role = "code",
        fill = "muted", layer = LAYER.text, id = "physics-rollout:operator:" .. spec.id .. ":detail",
    }
end
operator:text {
    text = "learned one-step operator Fθ", point = {13, 118}, role = "code",
    fill = "muted", layer = LAYER.text, id = "physics-rollout:operator:title",
}

output:text {
    text = "prediction û(t+Δt)", point = {357, 130}, role = "text", fill = "result",
    layer = LAYER.text, id = "physics-rollout:output:title",
}
mesh(output, "physics-rollout:output-mesh", {357, 36}, true)
output:text {
    text = "same IDs + next field", point = {357, -47}, role = "code",
    fill = "muted", layer = LAYER.text, id = "physics-rollout:output:detail",
}

local input_route = routes:arrow {
    from = {-270, 36}, to = {-180, 36}, tip = 9, color = "accent", width = 2,
    layer = LAYER.route, id = "physics-rollout:route:input-operator",
}
local inner_routes = {
    routes:arrow {from = {-80, 36}, to = {-61, 36}, tip = 8, color = "foreground", width = 1.8, layer = LAYER.route, id = "physics-rollout:route:encode-message"},
    routes:arrow {from = {85, 36}, to = {106, 36}, tip = 8, color = "foreground", width = 1.8, layer = LAYER.route, id = "physics-rollout:route:message-decode"},
}
local output_route = routes:arrow {
    from = {206, 36}, to = {269, 36}, tip = 9, color = "result", width = 2.2,
    layer = LAYER.route, id = "physics-rollout:route:operator-output",
}

timeline:line {
    from = {-338, -130}, to = {338, -130}, color = "border", width = 2,
    layer = LAYER.route, id = "physics-rollout:timeline:axis",
}
for step = 0, 3 do
    local x = -300 + step * 200
    timeline:circle {
        center = {x, -130}, radius = 9, fill = step == 0 and "accent" or "surface",
        stroke = step == 0 and "accent" or "result", width = 2, layer = LAYER.node,
        id = "physics-rollout:timeline:step:" .. step,
    }
    timeline:text {
        text = "t" .. step, point = {x, -155}, role = "code",
        fill = step == 0 and "accent" or "result", layer = LAYER.text,
        id = "physics-rollout:timeline:label:" .. step,
    }
end
timeline:text {
    text = "reuse Fθ autoregressively", point = {0, -184}, role = "code",
    fill = "focus", layer = LAYER.text, id = "physics-rollout:timeline:note",
}
local conclusion = root:text {
    text = "Separate one-step accuracy from rollout stability; show truth/error when the paper claims either.",
    point = {0, -229}, role = "code", fill = "result", layer = LAYER.text,
    id = "physics-rollout:conclusion",
}

scene:fade_in(header, {shift = {0, -6}, duration = 0.5, curve = "gentle"})
scene:fade_in(input, {shift = {0, -6}, duration = 0.65, curve = "ease_out"})
scene:create(input_route, 0.4, "ease_out")
scene:fade_in(operator, {shift = {0, -6}, duration = 0.65, curve = "gentle"})
scene:create(inner_routes, 0.45, "ease_out", 0.08, "forward")
scene:indicate(operator_bodies.message, {color = "focus", scale = 1.025, duration = 0.42, curve = "ease_in_out"})
scene:create(output_route, 0.4, "ease_out")
scene:fade_in(output, {shift = {0, -6}, duration = 0.6, curve = "gentle"})
scene:fade_in(timeline, {duration = 0.55, curve = "gentle"})
scene:fade_in(conclusion, {duration = 0.35, curve = "gentle"})
scene:wait(2.3)
return scene
