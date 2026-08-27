local LAYER = {
    zone = 0,
    route = 10,
    node = 20,
    text = 30,
}

local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    loop = false,
    theme = "pro_white",
    camera = { mode = "fixed", view = "2d", target = { 0, 0 }, height = 540 },
}

local header = scene:group { id = "architecture-header" }
header:text {
    text = "A request crosses three explicit ownership boundaries",
    point = { -432, 232 },
    align = { 0, 0.5 },
    role = "h2",
    id = "architecture-title",
}
header:text {
    text = "The primary path stays straight; asynchronous work uses its own corridor.",
    point = { -432, 194 },
    align = { 0, 0.5 },
    role = "text",
    fill = "muted",
    id = "architecture-subtitle",
}
header:line {
    from = { -432, 162 },
    to = { 432, 162 },
    color = "border",
    width = 1,
    layer = LAYER.zone,
    id = "architecture-divider",
}

local zones = scene:group { id = "architecture-zones" }
local function zone(id, label, center, size)
    local group = zones:group { id = id }
    group:rectangle {
        center = center,
        size = size,
        corner = 12,
        fill = "surface",
        stroke = "border",
        width = 1.25,
        layer = LAYER.zone,
        id = id .. "-body",
    }
    group:text {
        text = label,
        point = { center[1] - size[1] * 0.5 + 16, center[2] + size[2] * 0.5 - 22 },
        align = { 0, 0.5 },
        role = "h3",
        fill = "muted",
        layer = LAYER.text,
        id = id .. "-label",
    }
end

zone("zone-public", "Public", { -342, -30 }, { 178, 340 })
zone("zone-platform", "Platform", { -36, -30 }, { 396, 340 })
zone("zone-data", "Data", { 350, -30 }, { 164, 340 })

local nodes = scene:group { id = "architecture-nodes" }
local function node(id, title, detail, center, size, emphasis)
    local group = nodes:group { id = id }
    group:rectangle {
        center = center,
        size = size,
        corner = 10,
        fill = "surface",
        stroke = emphasis or "border",
        width = emphasis and 2.5 or 1.25,
        layer = LAYER.node,
        id = id .. "-body",
    }
    group:text {
        text = title,
        point = { center[1], center[2] + 11 },
        role = "text",
        fill = emphasis or "foreground",
        layer = LAYER.text,
        id = id .. "-title",
    }
    group:text {
        text = detail,
        point = { center[1], center[2] - 18 },
        role = "code",
        fill = "muted",
        layer = LAYER.text,
        id = id .. "-detail",
    }
end

node("node-client", "Client", "web / mobile", { -342, 50 }, { 126, 64 })
node("node-edge", "Edge", "TLS · routing", { -142, 50 }, { 126, 64 })
node("node-api", "API", "auth · policy", { 75, 50 }, { 138, 64 }, "focus")
node("node-cache", "Cache", "read-through", { 350, 50 }, { 118, 64 })
node("node-worker", "Worker", "async jobs", { 75, -110 }, { 138, 64 })
node("node-store", "Store", "durable state", { 350, -110 }, { 118, 64 })

local routes = scene:group { id = "architecture-routes" }
local function route(id, from, to, color, dashed)
    return routes:arrow {
        from = from,
        to = to,
        tip = 12,
        color = color,
        width = 3,
        dash = dashed and { 8, 6 } or nil,
        layer = LAYER.route,
        id = id,
    }
end

local primary = {
    route("route-client-edge", { -279, 50 }, { -205, 50 }, "accent"),
    route("route-edge-api", { -79, 50 }, { 6, 50 }, "accent"),
    route("route-api-cache", { 144, 50 }, { 291, 50 }, "accent"),
}
local asynchronous = {
    route("route-api-worker", { 75, 18 }, { 75, -78 }, "secondary", true),
    route("route-worker-store", { 144, -110 }, { 291, -110 }, "secondary", true),
}

local route_labels = scene:group { id = "architecture-route-labels" }
local function route_label(id, text, point, color)
    route_labels:text {
        text = text,
        point = point,
        role = "code",
        fill = color or "muted",
        layer = LAYER.text,
        id = id,
    }
end

route_label("label-https", "HTTPS", { -242, 94 })
route_label("label-cache", "lookup", { 218, 94 })
route_label("label-enqueue", "enqueue", { 38, -30 }, "secondary")
route_label("label-state-write", "state write", { 218, -72 }, "secondary")

scene:fade_in(header, { shift = { 0, 8 }, duration = 0.45, curve = "gentle" })
scene:fade_in(zones, { duration = 0.45, curve = "gentle" })
scene:fade_in(nodes, { shift = { 0, -6 }, duration = 0.65, curve = "ease_out" })
scene:create(primary, 1.0, "ease_out", 0.08, "forward")
scene:create(asynchronous, 0.75, "ease_out", 0.1, "forward")
scene:fade_in(route_labels, { duration = 0.4, curve = "gentle" })
scene:wait(2.2)
return scene
