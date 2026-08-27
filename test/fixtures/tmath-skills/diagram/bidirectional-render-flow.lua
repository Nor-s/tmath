-- Question: what crosses the application/runtime boundary in each direction, and where is work dispatched?
-- Replace endpoint_specs and backend_specs; keep commands and completed frames on separate named rails.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local LAYER = {boundary = 0, route = 10, node = 20, text = 30}
local root = scene:group {id = "render-flow:root"}
local context = root:group {id = "render-flow:context"}
local nodes = root:group {id = "render-flow:nodes"}
local routes = root:group {id = "render-flow:routes"}
local labels = root:group {id = "render-flow:labels"}

local function frame(id, center, size, label)
    context:rectangle {
        center = center, size = size, corner = 3, fill = "surface", stroke = "border",
        width = 1.5, dash = {8, 6}, opacity = 0.7, layer = LAYER.boundary,
        id = "render-flow:frame:" .. id,
    }
    context:text {
        text = label, point = {center[1], center[2] - size[2] * 0.5 - 18}, role = "code",
        fill = "muted", layer = LAYER.text, id = "render-flow:frame:" .. id .. ":label",
    }
end

local function box(id, label, detail, center, size, focal, compact)
    local prefix = "render-flow:node:" .. id
    nodes:rectangle {
        center = center, size = size, corner = 3, fill = "surface",
        stroke = focal and "accent" or "border", width = focal and 2.25 or 1.5,
        layer = LAYER.node, id = prefix .. ":body",
    }
    nodes:text {
        text = label, point = {center[1], center[2] + (detail and 10 or 0)},
        role = compact and "code" or "text", fill = focal and "accent" or "foreground",
        layer = LAYER.text, id = prefix .. ":label",
    }
    if detail then
        nodes:text {
            text = detail, point = {center[1], center[2] - 17}, role = "code", fill = "muted",
            layer = LAYER.text, id = prefix .. ":detail",
        }
    end
end

frame("host", {-350, 0}, {190, 360}, "HOST")
frame("runtime", {150, 0}, {560, 360}, "RENDER RUNTIME")
box("application", "Application", "update state", {-350, 95}, {150, 92})
box("presentation", "Presentation", "consume frames", {-350, -95}, {180, 92})
box("renderer", "Renderer", "record · resolve", {45, 80}, {170, 126}, true)

local backend_specs = {
    {id = "cpu", label = "CPU raster", x = -50},
    {id = "gl", label = "OpenGL", x = 81},
    {id = "gpu", label = "WebGPU", x = 212},
}
for _, spec in ipairs(backend_specs) do
    box("backend-" .. spec.id, spec.label, nil, {spec.x, -85}, {116, 62}, false, true)
end
box("decoder", "Asset decoders", "image · vector · font", {310, 80}, {200, 126})

local command = routes:arrow {
    from = {-275, 95}, to = {-40, 95}, tip = 12, color = "accent", width = 3,
    dash = {14, 8}, layer = LAYER.route, id = "render-flow:rail:commands",
}
local frameReturn = routes:arrow {
    from = {-130, -95}, to = {-260, -95}, tip = 12,
    color = "result", width = 3,
    layer = LAYER.route, id = "render-flow:rail:frames",
}
local commandLabel = labels:text {
    text = "scene commands", point = {-157, 123}, role = "code", fill = "accent",
    layer = LAYER.text, id = "render-flow:rail:commands:label",
}
local frameLabel = labels:text {
    text = "frame ready", point = {-195, -72}, role = "code", fill = "result",
    layer = LAYER.text, id = "render-flow:rail:frames:label",
}

local dispatchTrunk = routes:line {
    from = {45, 17}, to = {45, -32}, color = "foreground", width = 1.8,
    layer = LAYER.route, id = "render-flow:dispatch:trunk",
}
local dispatchRails = {
    routes:line {
        from = {45, -32}, to = {-50, -32}, color = "foreground", width = 1.8,
        layer = LAYER.route, id = "render-flow:dispatch:rail-left",
    },
    routes:line {
        from = {45, -32}, to = {212, -32}, color = "foreground", width = 1.8,
        layer = LAYER.route, id = "render-flow:dispatch:rail-right",
    },
}
local dispatchDrops = {}
for _, spec in ipairs(backend_specs) do
    dispatchDrops[#dispatchDrops + 1] = routes:arrow {
        from = {spec.x, -32}, to = {spec.x, -54}, tip = 9,
        color = "foreground", width = 1.8, layer = LAYER.route,
        id = "render-flow:dispatch:" .. spec.id,
    }
end
local decodeRequest = routes:arrow {
    from = {130, 105}, to = {210, 105}, tip = 9, color = "muted", width = 1.8,
    dash = {7, 5}, layer = LAYER.route, id = "render-flow:decode:request",
}
local decodeResult = routes:arrow {
    from = {210, 55}, to = {130, 55}, tip = 9, color = "muted", width = 1.8,
    layer = LAYER.route, id = "render-flow:decode:result",
}
local decodeRequestLabel = labels:text {
    text = "request", point = {170, 126}, role = "code", fill = "muted",
    layer = LAYER.text, id = "render-flow:decode:request:label",
}
local decodeResultLabel = labels:text {
    text = "bytes", point = {170, 34}, role = "code", fill = "muted",
    layer = LAYER.text, id = "render-flow:decode:result:label",
}

scene:fade_in(context, {duration = 0.4, curve = "gentle"})
scene:fade_in(nodes, {shift = {0, -6}, duration = 0.65, curve = "gentle"})
scene:create(command, 0.7, "ease_out")
scene:fade_in(commandLabel, {shift = {0, -4}, duration = 0.25, curve = "gentle"})
scene:create(dispatchTrunk, 0.25, "ease_out")
scene:create(dispatchRails, 0.35, "ease_out")
scene:create(dispatchDrops, 0.35, "ease_out", 0.06)
scene:create(decodeRequest, 0.35, "ease_out")
scene:fade_in(decodeRequestLabel, {shift = {0, -4}, duration = 0.2, curve = "gentle"})
scene:create(decodeResult, 0.35, "ease_out")
scene:fade_in(decodeResultLabel, {shift = {0, -4}, duration = 0.2, curve = "gentle"})
scene:create(frameReturn, 0.7, "ease_out")
scene:fade_in(frameLabel, {shift = {0, -4}, duration = 0.25, curve = "gentle"})
scene:play({target = command, dash_offset = -22}, 0.8, "linear")
scene:indicate(frameReturn, {scale = 1.015, duration = 0.4, curve = "ease_in_out"})
scene:wait(2.4)
return scene
