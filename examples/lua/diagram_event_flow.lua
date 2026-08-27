local LAYER = {
    structure = 0,
    route = 10,
    node = 20,
    text = 30,
    marker = 40,
}

local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    loop = false,
    theme = "pro_white",
    camera = { mode = "fixed", view = "2d", target = { 0, 0 }, height = 540 },
}

local header = scene:group { id = "event-flow-header" }
header:text {
    text = "Events branch only at declared decisions",
    point = { -432, 232 },
    align = { 0, 0.5 },
    role = "h2",
    id = "event-flow-title",
}
header:text {
    text = "The main rail remains stable while failure and materialized state use named exits.",
    point = { -432, 194 },
    align = { 0, 0.5 },
    role = "text",
    fill = "muted",
    id = "event-flow-subtitle",
}
header:line {
    from = { -432, 162 },
    to = { 432, 162 },
    color = "border",
    width = 1,
    layer = LAYER.structure,
    id = "event-flow-divider",
}

local nodes = scene:group { id = "event-flow-nodes" }
local function node(id, title, detail, center, size, color)
    local group = nodes:group { id = id }
    group:rectangle {
        center = center,
        size = size,
        corner = 10,
        fill = "surface",
        stroke = color or "border",
        width = color and 2.25 or 1.25,
        layer = LAYER.node,
        id = id .. "-body",
    }
    group:text {
        text = title,
        point = { center[1], center[2] + 10 },
        role = "text",
        fill = color or "foreground",
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

node("node-producer", "Producer", "order.created", { -360, 46 }, { 128, 64 })
node("node-validate", "Validate", "schema · policy", { -130, 46 }, { 128, 64 }, "focus")
node("node-enrich", "Enrich", "customer context", { 100, 46 }, { 128, 64 })
node("node-consumer", "Consumer", "fulfillment", { 340, 46 }, { 128, 64 })
node("node-dlq", "Dead letter", "rejected event", { -130, -140 }, { 128, 58 }, "danger")
node("node-projection", "Projection", "orders_by_id", { 340, -140 }, { 128, 58 }, "result")

local routes = scene:group { id = "event-flow-routes" }
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
    route("route-producer-validate", { -296, 46 }, { -194, 46 }, "accent"),
    route("route-validate-enrich", { -66, 46 }, { 36, 46 }, "accent"),
    route("route-enrich-consumer", { 164, 46 }, { 276, 46 }, "accent"),
}
local branches = {
    route("route-validate-dlq", { -130, 14 }, { -130, -111 }, "danger", true),
    route("route-consumer-projection", { 340, 14 }, { 340, -111 }, "result"),
}

local labels = scene:group { id = "event-flow-labels" }
local function label(id, text, point, color)
    labels:text {
        text = text,
        point = point,
        role = "code",
        fill = color or "muted",
        layer = LAYER.text,
        id = id,
    }
end

label("label-publish", "publish", { -245, 92 })
label("label-normalize", "normalize", { -15, 92 })
label("label-deliver", "deliver", { 220, 92 })
label("label-reject", "reject", { -166, -46 }, "danger")
label("label-project", "project state", { 286, -46 }, "result")

local marker = scene:point {
    point = { -360, 46 },
    radius = 7,
    color = "focus",
    layer = LAYER.marker,
    id = "event-marker",
}

scene:fade_in(header, { shift = { 0, 8 }, duration = 0.45, curve = "gentle" })
scene:fade_in(nodes, { duration = 0.65, curve = "ease_out" })
scene:create(primary, 1.0, "ease_out", 0.1, "forward")
scene:create(branches, 0.7, "ease_out", 0.1, "forward")
scene:fade_in(labels, { duration = 0.4, curve = "gentle" })
scene:fade_in(marker, { duration = 0.3, curve = "gentle" })
scene:shift(marker, { 230, 0 }, 0.8, "linear")
scene:wait(0.2)
scene:shift(marker, { 230, 0 }, 0.8, "linear")
scene:wait(0.2)
scene:shift(marker, { 240, 0 }, 0.85, "linear")
scene:fade_out(marker, { duration = 0.3, curve = "gentle" })
scene:wait(2.2)
return scene
