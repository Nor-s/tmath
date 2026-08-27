-- Question: how does a paper model transform its input, and what happens inside one repeated block?
-- Edit stage_specs, block_specs, tensor labels, multiplicity, and source anchors together.
-- The included encoder is illustrative; do not relabel it as a named paper without verifying the source.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "pro_white",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local LAYER = {boundary = 0, route = 10, node = 20, text = 30, focus = 40}
local root = scene:group {id = "paper-model:root"}
local header = root:group {id = "paper-model:header"}
local overview = root:group {id = "paper-model:overview"}
local detail = root:group {id = "paper-model:block-detail"}
local routes = root:group {id = "paper-model:routes"}

header:text {
    text = "Source-grounded model architecture", point = {0, 232}, role = "h2",
    fill = "foreground", layer = LAYER.text, id = "paper-model:title",
}
header:text {
    text = "illustrative encoder · replace stages, shapes, multiplicity, and source anchors",
    point = {0, 199}, role = "code", fill = "muted", layer = LAYER.text,
    id = "paper-model:subtitle",
}

local function stage(parent, spec)
    local group = parent:group {id = "paper-model:stage:" .. spec.id}
    local body = group:rectangle {
        center = spec.center, size = spec.size, corner = 8,
        fill = "surface", stroke = spec.focal and "accent" or "border",
        width = spec.focal and 2.5 or 1.5, layer = LAYER.node,
        id = "paper-model:stage:" .. spec.id .. ":body",
    }
    group:text {
        text = spec.label, point = {spec.center[1], spec.center[2] + 13}, role = "text",
        fill = spec.focal and "accent" or "foreground", layer = LAYER.text,
        id = "paper-model:stage:" .. spec.id .. ":label",
    }
    group:text {
        text = spec.tensor or spec.detail, point = {spec.center[1], spec.center[2] - 17}, role = "code",
        fill = "muted", layer = LAYER.text,
        id = "paper-model:stage:" .. spec.id .. ":tensor",
    }
    return {group = group, body = body, spec = spec}
end

-- Copy/paste edit surface. Preserve the exact source order and tensor contracts.
local stage_specs = {
    {id = "input", label = "Input IDs", tensor = "[B, T]", center = {-410, 74}, size = {104, 72}},
    {id = "embed", label = "Embedding", tensor = "[B, T, d]", center = {-277, 74}, size = {126, 72}},
    {id = "blocks", label = "Encoder block ×N", tensor = "[B, T, d]", center = {-103, 74}, size = {190, 84}, focal = true},
    {id = "head", label = "Task head", tensor = "[B, T, V]", center = {100, 74}, size = {140, 72}},
    {id = "output", label = "Output", tensor = "logits", center = {286, 74}, size = {112, 72}},
}

local stages = {}
for _, spec in ipairs(stage_specs) do stages[#stages + 1] = stage(overview, spec) end

local main_routes = {}
for index = 1, #stages - 1 do
    local left = stages[index].spec
    local right = stages[index + 1].spec
    main_routes[#main_routes + 1] = routes:arrow {
        from = {left.center[1] + left.size[1] * 0.5, left.center[2]},
        to = {right.center[1] - right.size[1] * 0.5, right.center[2]},
        tip = 11, color = "foreground", width = 2, layer = LAYER.route,
        id = "paper-model:route:" .. left.id .. "-" .. right.id,
    }
end

detail:rectangle {
    center = {-16, -104}, size = {666, 196}, corner = 8,
    fill = "surface", stroke = "border", width = 1.25, dash = {7, 5},
    layer = LAYER.boundary, id = "paper-model:block-detail:boundary",
}
detail:text {
    text = "ONE REPEATED BLOCK", point = {-329, -29}, align = {0, 0.5},
    role = "code", fill = "muted", layer = LAYER.text,
    id = "paper-model:block-detail:title",
}

local block_specs = {
    {id = "x", label = "x", detail = "[B,T,d]", center = {-286, -103}, size = {68, 66}},
    {id = "norm", label = "Norm", detail = "variant", center = {-176, -103}, size = {94, 66}},
    {id = "core", label = "Core op", detail = "paper-defined", center = {-35, -103}, size = {132, 66}, focal = true},
    {id = "add", label = "+ residual", detail = "same shape", center = {121, -103}, size = {110, 66}},
    {id = "out", label = "x′", detail = "[B,T,d]", center = {260, -103}, size = {72, 66}},
}
local block_handles = {}
for _, spec in ipairs(block_specs) do block_handles[#block_handles + 1] = stage(detail, spec) end

local block_routes = {}
for index = 1, #block_handles - 1 do
    local left = block_handles[index].spec
    local right = block_handles[index + 1].spec
    block_routes[#block_routes + 1] = routes:arrow {
        from = {left.center[1] + left.size[1] * 0.5, left.center[2]},
        to = {right.center[1] - right.size[1] * 0.5, right.center[2]},
        tip = 10, color = "foreground", width = 2, layer = LAYER.route,
        id = "paper-model:block-route:" .. left.id .. "-" .. right.id,
    }
end
block_routes[#block_routes + 1] = routes:route {
    points = {{-286, -137}, {-286, -171}, {121, -171}, {121, -138}},
    tip = 10, color = "accent", width = 2, layer = LAYER.route,
    id = "paper-model:block-route:residual",
}
detail:text {
    text = "identity path", point = {-79, -181}, role = "code", fill = "accent",
    layer = LAYER.text, id = "paper-model:block-detail:residual-label",
}

local bridge = routes:arrow {
    from = {-103, 32}, to = {-103, -5}, tip = 10, color = "accent", width = 2,
    layer = LAYER.focus, id = "paper-model:scale-bridge",
}
local conclusion = root:text {
    text = "Overview preserves stage order; detail preserves the selected block's exact tensor contract.",
    point = {0, -226}, role = "code", fill = "result", layer = LAYER.text,
    id = "paper-model:conclusion",
}

scene:fade_in(header, {shift = {0, -6}, duration = 0.55, curve = "gentle"})
scene:fade_in(overview, {shift = {0, -7}, duration = 0.7, curve = "ease_out"})
scene:create(main_routes, 0.9, "ease_out", 0.08, "forward")
scene:create(bridge, 0.35, "ease_out")
scene:fade_in(detail, {shift = {0, -7}, duration = 0.65, curve = "gentle"})
scene:create(block_routes, 0.9, "ease_out", 0.06, "forward")
scene:indicate(stages[3].body, {color = "focus", scale = 1.025, duration = 0.42, curve = "ease_in_out"})
scene:fade_in(conclusion, {shift = {0, -5}, duration = 0.4, curve = "gentle"})
scene:wait(2.2)
return scene
