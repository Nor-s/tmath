-- Question: which public surfaces depend on the core, which backends execute it, and which modules extend it?
-- Replace layer_specs and module_specs; preserve the central vertical dependency spine and separate module rail.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local LAYER = {boundary = 0, route = 10, node = 20, text = 30}
local root = scene:group {id = "system-structure:root"}
local boundaries = root:group {id = "system-structure:boundaries"}
local nodes = root:group {id = "system-structure:nodes"}
local routes = root:group {id = "system-structure:routes"}
local modules = root:group {id = "system-structure:modules"}

local function boundary(id, center, size, label)
    boundaries:rectangle {
        center = center, size = size, corner = 3, fill = "surface", stroke = "border",
        width = 1.5, dash = {8, 6}, opacity = 0.72, layer = LAYER.boundary,
        id = "system-structure:boundary:" .. id,
    }
    local label_point = id == "module"
        and {center[1], center[2] + size[2] * 0.5 + 18}
        or {center[1] - size[1] * 0.5 - 18, center[2]}
    boundaries:text {
        text = label, point = label_point,
        align = id == "module" and {0.5, 0.5} or {1, 0.5},
        role = "code", fill = "muted", layer = LAYER.text,
        id = "system-structure:boundary:" .. id .. ":label",
    }
end

local function box(parent, spec)
    local prefix = "system-structure:node:" .. spec.id
    parent:rectangle {
        center = spec.center, size = spec.size, corner = spec.corner or 2,
        fill = "surface", stroke = spec.focal and "accent" or "border",
        width = spec.focal and 2.25 or 1.5, layer = LAYER.node, id = prefix .. ":body",
    }
    parent:text {
        text = spec.label, point = {spec.center[1], spec.center[2] + (spec.detail and 11 or 0)},
        role = spec.detail and "text" or "h3", fill = spec.focal and "accent" or "foreground",
        layer = LAYER.text, id = prefix .. ":label",
    }
    if spec.detail then
        parent:text {
            text = spec.detail, point = {spec.center[1], spec.center[2] - 17},
            role = "code", fill = "muted", layer = LAYER.text, id = prefix .. ":detail",
        }
    end
end

-- Data surface: layer membership, exact centers, and concise technical labels.
local layer_specs = {
    {id = "native", label = "Native API", detail = "C / C++", center = {-170, 186}, size = {250, 66}},
    {id = "web", label = "Web API", detail = "JavaScript / TypeScript", center = {120, 186}, size = {250, 66}},
    {id = "engine", label = "Vector Engine", detail = "scene graph · animation · effects · text", center = {-25, 48}, size = {540, 130}, focal = true},
    {id = "cpu", label = "CPU", center = {-205, -104}, size = {150, 62}},
    {id = "gpu", label = "GPU", detail = "OpenGL / WebGPU", center = {-25, -104}, size = {170, 62}},
    {id = "portable", label = "Portable", detail = "software fallback", center = {165, -104}, size = {170, 62}},
}

boundary("api", {-25, 186}, {570, 86}, "PUBLIC API")
boundary("core", {-25, 48}, {570, 150}, "RENDER CORE")
boundary("backend", {-25, -104}, {570, 82}, "BACKENDS")
boundary("module", {363, 43}, {160, 376}, "MODULES")
for _, spec in ipairs(layer_specs) do box(nodes, spec) end

routes:route {
    points = {{-170, 153}, {-170, 136}, {-25, 136}, {-25, 113}}, tip = 10,
    color = "foreground", width = 2, layer = LAYER.route, id = "system-structure:route:native-core",
}
routes:route {
    points = {{120, 153}, {120, 136}, {-5, 136}, {-5, 113}}, tip = 10,
    color = "foreground", width = 2, layer = LAYER.route, id = "system-structure:route:web-core",
}
routes:route {
    points = {{-25, -17}, {-25, -49}, {-205, -49}, {-205, -73}}, tip = 10,
    color = "foreground", width = 2, layer = LAYER.route, id = "system-structure:route:core-cpu",
}
routes:arrow {
    from = {-25, -17}, to = {-25, -73}, tip = 10, color = "foreground", width = 2,
    layer = LAYER.route, id = "system-structure:route:core-gpu",
}
routes:route {
    points = {{-25, -17}, {-25, -49}, {165, -49}, {165, -73}}, tip = 10,
    color = "foreground", width = 2, layer = LAYER.route, id = "system-structure:route:core-portable",
}

local module_specs = {
    {id = "svg", label = "SVG", y = 174},
    {id = "lottie", label = "Lottie", y = 108},
    {id = "image", label = "Image", y = 42},
    {id = "font", label = "Font", y = -24},
    {id = "codec", label = "Codec", y = -90},
}
for _, spec in ipairs(module_specs) do
    box(modules, {id = "module-" .. spec.id, label = spec.label, center = {363, spec.y}, size = {126, 48}})
end
routes:line {
    from = {299, 174}, to = {280, 174}, color = "muted", width = 2, layer = LAYER.route,
    id = "system-structure:module-rail:top",
}
routes:line {
    from = {280, 174}, to = {280, -90}, color = "muted", width = 2, layer = LAYER.route,
    id = "system-structure:module-rail",
}
for _, spec in ipairs(module_specs) do
    routes:line {
        from = {280, spec.y}, to = {300, spec.y}, color = "muted", width = 2,
        layer = LAYER.route, id = "system-structure:module-link:" .. spec.id,
    }
end
routes:arrow {
    from = {280, 42}, to = {245, 42}, tip = 10, color = "muted", width = 2,
    layer = LAYER.route, id = "system-structure:route:modules-core",
}

scene:fade_in(boundaries, {duration = 0.45, curve = "gentle"})
scene:fade_in(nodes, {shift = {0, -7}, duration = 0.65, curve = "gentle"})
scene:create(routes, 1.0, "ease_out")
scene:fade_in(modules, {shift = {-7, 0}, duration = 0.5, curve = "gentle"})
scene:indicate(root, {scale = 1.008, duration = 0.45, curve = "ease_in_out"})
scene:wait(2.4)
return scene
