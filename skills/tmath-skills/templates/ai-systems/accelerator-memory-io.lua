-- Generic accelerator memory/data-movement template for a tiled kernel.
-- Capacities, reuse factors, and memory names are illustrative until sourced.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "pro_white",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local LAYER = {boundary = 0, route = 10, node = 20, text = 30, focus = 40}
local root = scene:group {id = "memory-io:root"}
local header = root:group {id = "memory-io:header"}
local hierarchy = root:group {id = "memory-io:hierarchy"}
local compute = root:group {id = "memory-io:compute"}
local routes = root:group {id = "memory-io:routes"}
local notes = root:group {id = "memory-io:notes"}

header:text {
    text = "Accelerator memory + I/O", point = {0, 232}, role = "h2",
    fill = "foreground", layer = LAYER.text, id = "memory-io:title",
}
header:text {
    text = "illustrative tiled kernel · edit memory levels and transfers from the source",
    point = {0, 199}, role = "code", fill = "muted", layer = LAYER.text,
    id = "memory-io:subtitle",
}

local levels = {
    {id = "hbm", label = "Device memory / HBM", detail = "large · high transfer cost", center = {-228, -125}, size = {370, 72}},
    {id = "shared", label = "Shared memory / SRAM", detail = "staged operand tiles", center = {-228, -25}, size = {324, 72}, focal = true},
    {id = "register", label = "Registers", detail = "thread-local fragments", center = {-228, 75}, size = {270, 72}},
}
local level_bodies = {}
for _, spec in ipairs(levels) do
    local group = hierarchy:group {id = "memory-io:level:" .. spec.id}
    level_bodies[spec.id] = group:rectangle {
        center = spec.center, size = spec.size, corner = 7, fill = "surface",
        stroke = spec.focal and "accent" or "border", width = spec.focal and 2.1 or 1.3,
        layer = LAYER.node, id = "memory-io:level:" .. spec.id .. ":body",
    }
    group:text {
        text = spec.label, point = {spec.center[1], spec.center[2] + 12}, role = "text",
        fill = spec.focal and "accent" or "foreground", layer = LAYER.text,
        id = "memory-io:level:" .. spec.id .. ":label",
    }
    group:text {
        text = spec.detail, point = {spec.center[1], spec.center[2] - 16}, role = "code",
        fill = "muted", layer = LAYER.text, id = "memory-io:level:" .. spec.id .. ":detail",
    }
end

compute:rectangle {
    center = {250, 27}, size = {326, 248}, corner = 9, fill = "surface",
    stroke = "border", width = 1.4, layer = LAYER.boundary, id = "memory-io:compute:boundary",
}
compute:text {
    text = "COMPUTE TILE", point = {105, 131}, align = {0, 0.5}, role = "code",
    fill = "muted", layer = LAYER.text, id = "memory-io:compute:title",
}
compute:rectangle {
    center = {194, 50}, size = {106, 82}, corner = 6, fill = "#dbeafe",
    stroke = "accent", width = 2, layer = LAYER.node, id = "memory-io:compute:operand-a",
}
compute:text {
    text = "tile A", point = {194, 50}, role = "text", fill = "accent",
    layer = LAYER.text, id = "memory-io:compute:operand-a-label",
}
compute:rectangle {
    center = {317, 50}, size = {106, 82}, corner = 6, fill = "#dcfce7",
    stroke = "result", width = 2, layer = LAYER.node, id = "memory-io:compute:operand-b",
}
compute:text {
    text = "tile B", point = {317, 50}, role = "text", fill = "result",
    layer = LAYER.text, id = "memory-io:compute:operand-b-label",
}
local accumulator = compute:rectangle {
    center = {255, -50}, size = {204, 70}, corner = 7, fill = "background",
    stroke = "focus", width = 2, layer = LAYER.node, id = "memory-io:compute:accumulator",
}
compute:text {
    text = "accumulate C", point = {255, -38}, role = "text", fill = "focus",
    layer = LAYER.text, id = "memory-io:compute:accumulator-label",
}
compute:text {
    text = "reuse ×R (illustrative)", point = {255, -67}, role = "code", fill = "muted",
    layer = LAYER.text, id = "memory-io:compute:reuse-label",
}

local load_hbm_shared = routes:arrow {
    from = {-228, -89}, to = {-228, -61}, tip = 9, color = "foreground", width = 2,
    layer = LAYER.route, id = "memory-io:route:hbm-shared",
}
local load_shared_regs = routes:arrow {
    from = {-228, 11}, to = {-228, 39}, tip = 9, color = "accent", width = 2,
    layer = LAYER.route, id = "memory-io:route:shared-register",
}
local feed_compute = routes:route {
    points = {{-93, 75}, {43, 75}, {43, 50}, {141, 50}}, tip = 9,
    color = "accent", width = 2, layer = LAYER.route, id = "memory-io:route:register-compute",
}
local reuse_routes = {
routes:route {
    points = {{194, 9}, {194, 1}, {255, 1}, {255, -15}}, tip = 9,
    color = "focus", width = 2, layer = LAYER.focus, id = "memory-io:route:reuse-a",
},
routes:route {
    points = {{317, 9}, {317, 1}, {255, 1}}, color = "focus", width = 2,
    layer = LAYER.focus, id = "memory-io:route:reuse-b",
},
}
local store = routes:route {
    points = {{357, -50}, {435, -50}, {435, -175}, {-22, -175}, {-22, -125}, {-43, -125}},
    tip = 9, color = "result", width = 2.2, layer = LAYER.route, id = "memory-io:route:store",
}
notes:text {
    text = "LOAD", point = {-274, -75}, role = "code", fill = "foreground",
    layer = LAYER.text, id = "memory-io:load-label",
}
notes:text {
    text = "STORE RESULT", point = {207, -158}, role = "code", fill = "result",
    layer = LAYER.text, id = "memory-io:store-label",
}
local conclusion = root:text {
    text = "Performance evidence should expose bytes moved, reuse, and synchronization—not compute alone.",
    point = {0, -229}, role = "code", fill = "result", layer = LAYER.text,
    id = "memory-io:conclusion",
}

scene:fade_in(header, {shift = {0, -6}, duration = 0.5, curve = "gentle"})
scene:fade_in(hierarchy, {shift = {0, -6}, duration = 0.65, curve = "ease_out"})
scene:create({load_hbm_shared, load_shared_regs}, 0.6, "ease_out", 0.1, "forward")
scene:fade_in(compute, {shift = {0, -6}, duration = 0.65, curve = "gentle"})
scene:create(feed_compute, 0.4, "ease_out")
scene:create(reuse_routes, 0.45, "ease_out", 0.08, "forward")
scene:indicate(accumulator, {color = "focus", scale = 1.025, duration = 0.45, curve = "ease_in_out"})
scene:create(store, 0.65, "ease_out")
scene:fade_in(notes, {duration = 0.3, curve = "gentle"})
scene:fade_in(conclusion, {duration = 0.35, curve = "gentle"})
scene:wait(2.2)
return scene
