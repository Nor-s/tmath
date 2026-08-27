const PRETENDARD = [{ name: "Pretendard", url: "./Pretendard.ttf", mime: "ttf" }];

const ARCHITECTURE_LUA = `local LAYER = {
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
return scene`;
const SEQUENCE_LUA = `local LAYER = {
    structure = 0,
    activation = 5,
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

local header = scene:group { id = "sequence-header" }
header:text {
    text = "Checkout returns before receipt work finishes",
    point = { -432, 232 },
    align = { 0, 0.5 },
    role = "h2",
    id = "sequence-title",
}
header:text {
    text = "Time moves downward; dashed messages return or continue without blocking the caller.",
    point = { -432, 194 },
    align = { 0, 0.5 },
    role = "text",
    fill = "muted",
    id = "sequence-subtitle",
}
header:line {
    from = { -432, 162 },
    to = { 432, 162 },
    color = "border",
    width = 1,
    layer = LAYER.structure,
    id = "sequence-divider",
}

local actors = scene:group { id = "sequence-actors" }
local actor_x = { -330, -110, 110, 330 }
local actor_names = { "Web", "API", "Worker", "Database" }
for index, x in ipairs(actor_x) do
    local actor = actors:group { id = "actor-" .. index }
    actor:rectangle {
        center = { x, 112 },
        size = { 132, 54 },
        corner = 9,
        fill = "surface",
        stroke = index == 2 and "focus" or "border",
        width = index == 2 and 2.5 or 1.25,
        layer = LAYER.node,
        id = "actor-" .. index .. "-body",
    }
    actor:text {
        text = actor_names[index],
        point = { x, 112 },
        role = "text",
        fill = index == 2 and "focus" or "foreground",
        layer = LAYER.text,
        id = "actor-" .. index .. "-label",
    }
end

local lifelines = scene:group { id = "sequence-lifelines" }
for index, x in ipairs(actor_x) do
    lifelines:line {
        from = { x, 84 },
        to = { x, -192 },
        color = "border",
        width = 1.5,
        dash = { 7, 7 },
        layer = LAYER.structure,
        id = "lifeline-" .. index,
    }
end

local activations = scene:group { id = "sequence-activations" }
activations:rectangle {
    center = { -110, -64 },
    size = { 10, 212 },
    corner = 3,
    fill = "surface",
    stroke = "focus",
    width = 1.5,
    layer = LAYER.activation,
    id = "activation-api",
}
activations:rectangle {
    center = { 330, -14 },
    size = { 10, 80 },
    corner = 3,
    fill = "surface",
    stroke = "border",
    width = 1.25,
    layer = LAYER.activation,
    id = "activation-database",
}
activations:rectangle {
    center = { 110, -147 },
    size = { 10, 58 },
    corner = 3,
    fill = "surface",
    stroke = "border",
    width = 1.25,
    layer = LAYER.activation,
    id = "activation-worker",
}

local messages = scene:group { id = "sequence-messages" }
local labels = scene:group { id = "sequence-labels" }
local message_handles = {}
local message_specs = {
    { "checkout", -330, -110, 40, "POST /checkout", false, "accent" },
    { "reserve", -110, 330, -14, "reserve(order)", false, "accent" },
    { "reserved", 330, -110, -68, "reservation", true, "muted" },
    { "publish", -110, 110, -122, "publish(receipt)", true, "secondary" },
    { "accepted", 110, -110, -176, "accepted", true, "muted" },
}

for _, spec in ipairs(message_specs) do
    local id, from_x, to_x, y, label, dashed, color = table.unpack(spec)
    message_handles[#message_handles + 1] = messages:arrow {
        from = { from_x, y },
        to = { to_x, y },
        tip = 12,
        color = color,
        width = 2.5,
        dash = dashed and { 8, 6 } or nil,
        layer = LAYER.route,
        id = "message-" .. id,
    }
    labels:text {
        text = label,
        point = { (from_x + to_x) * 0.5, y + 16 },
        role = "code",
        fill = color,
        layer = LAYER.text,
        id = "message-" .. id .. "-label",
    }
end

scene:fade_in(header, { shift = { 0, 8 }, duration = 0.45, curve = "gentle" })
scene:fade_in(actors, { duration = 0.55, curve = "ease_out" })
scene:fade_in(lifelines, { duration = 0.4, curve = "gentle" })
scene:fade_in(activations, { duration = 0.4, curve = "gentle" })
for _, message in ipairs(message_handles) do
    scene:create(message, 0.55, "ease_out", 0, "forward")
    scene:wait(0.16)
end
scene:fade_in(labels, { duration = 0.4, curve = "gentle" })
scene:wait(2.2)
return scene`;
const EVENT_FLOW_LUA = `local LAYER = {
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
return scene`;
const CAUSAL_LOOP_LUA = `local LAYER = {
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
    loop = true,
    theme = "pro_white",
    camera = { mode = "fixed", view = "2d", target = { 0, 0 }, height = 540 },
}

local header = scene:group { id = "causal-loop-header" }
header:text {
    text = "Persistent state closes the feedback loop",
    point = { -432, 232 },
    align = { 0, 0.5 },
    role = "h2",
    id = "causal-loop-title",
}
header:text {
    text = "The topology stays fixed; one operational token advances through the recurring cycle.",
    point = { -432, 194 },
    align = { 0, 0.5 },
    role = "text",
    fill = "muted",
    id = "causal-loop-subtitle",
}
header:line {
    from = { -432, 162 },
    to = { 432, 162 },
    color = "border",
    width = 1,
    layer = LAYER.structure,
    id = "causal-loop-divider",
}

local nodes = scene:group { id = "causal-loop-nodes" }
local function node(id, title, detail, center)
    local group = nodes:group { id = id }
    group:rectangle {
        center = center,
        size = { 150, 58 },
        corner = 10,
        fill = "surface",
        stroke = "border",
        width = 1.25,
        layer = LAYER.node,
        id = id .. "-body",
    }
    group:text {
        text = title,
        point = { center[1], center[2] + 10 },
        role = "text",
        layer = LAYER.text,
        id = id .. "-title",
    }
    group:text {
        text = detail,
        point = { center[1], center[2] - 17 },
        role = "code",
        fill = "muted",
        layer = LAYER.text,
        id = id .. "-detail",
    }
end

node("node-observe", "Observe", "signal", { 0, 104 })
node("node-interpret", "Interpret", "context", { 285, -10 })
node("node-decide", "Decide", "policy", { 0, -124 })
node("node-act", "Act", "effect", { -285, -10 })

local hub = nodes:group { id = "node-memory" }
hub:circle {
    center = { 0, -10 },
    radius = 43,
    fill = "surface",
    stroke = "result",
    width = 2.25,
    layer = LAYER.node,
    id = "node-memory-body",
}
hub:text {
    text = "Memory",
    point = { 0, 0 },
    role = "text",
    fill = "result",
    layer = LAYER.text,
    id = "node-memory-title",
}
hub:text {
    text = "state",
    point = { 0, -26 },
    role = "code",
    fill = "muted",
    layer = LAYER.text,
    id = "node-memory-detail",
}

local routes = scene:group { id = "causal-loop-routes" }
local function route(id, from, to, color)
    return routes:arrow {
        from = from,
        to = to,
        tip = 12,
        color = color,
        width = 3,
        layer = LAYER.route,
        id = id,
    }
end

route("route-observe-interpret", { 75, 88 }, { 210, 10 }, "accent")
route("route-interpret-decide", { 210, -30 }, { 75, -108 }, "accent")
route("route-decide-act", { -75, -108 }, { -210, -30 }, "accent")
route("route-act-observe", { -210, 10 }, { -75, 88 }, "accent")
route("route-decide-memory", { 16, -95 }, { 16, -53 }, "result")
route("route-memory-observe", { -16, 33 }, { -16, 75 }, "result")

local labels = scene:group { id = "causal-loop-labels" }
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

label("label-frame", "frame", { 154, 82 })
label("label-choose", "choose", { 154, -92 })
label("label-execute", "execute", { -154, -92 })
label("label-feedback", "feedback", { -154, 82 })
label("label-write", "write", { 52, -74 }, "result")
label("label-read", "read", { -50, 54 }, "result")

local token = scene:point {
    point = { 75, 88 },
    radius = 8,
    color = "focus",
    layer = LAYER.marker,
    id = "loop-token",
}

scene:wait(0.35)
scene:shift(token, { 135, -78 }, 0.55, "linear")
scene:shift(token, { 0, -40 }, 0.25, "linear")
scene:shift(token, { -135, -78 }, 0.55, "linear")
scene:shift(token, { -150, 0 }, 0.25, "linear")
scene:shift(token, { -135, 78 }, 0.55, "linear")
scene:shift(token, { 0, 40 }, 0.25, "linear")
scene:shift(token, { 135, 78 }, 0.55, "linear")
scene:shift(token, { 150, 0 }, 0.25, "linear")
scene:wait(0.35)
return scene`;
const SANKEY_LUA = `local p = {
    paper = "#f7f5f0", panel = "#fffefa", ink = "#111827", muted = "#64748b",
    soft = "#94a3b8", rule = "#d9dee7", accent = "#2563eb", cyan = "#0891b2",
    signal = "#db2777",
}

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, background = p.paper,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local header = scene:group {id = "sankey-header"}
header:text {
    text = "SANKEY / MATERIAL BALANCE", point = {-432, 238}, align = {0, 0.5},
    font = "Pretendard", size = 13, fill = p.accent, id = "sankey-eyebrow",
}
header:text {
    text = "100 units in · 72 units retained", point = {-432, 207}, align = {0, 0.5},
    font = "Pretendard", size = 30, fill = p.ink, id = "sankey-title",
}
header:text {
    text = "Ribbon thickness is the quantity — every split conserves its incoming total",
    point = {-432, 168}, align = {0, 0.5}, font = "Pretendard", size = 15,
    fill = p.muted, id = "sankey-subtitle",
}
header:line {from = {-432, 148}, to = {432, 148}, stroke = p.rule, width = 1}

local function ribbon(x1, top1, bottom1, x2, top2, bottom2, color, id)
    local bend = (x2 - x1) * 0.48
    return scene:path {
        commands = {
            {type = "move", to = {x1, top1}},
            {type = "cubic", control1 = {x1 + bend, top1}, control2 = {x2 - bend, top2}, to = {x2, top2}},
            {type = "line", to = {x2, bottom2}},
            {type = "cubic", control1 = {x2 - bend, bottom2}, control2 = {x1 + bend, bottom1}, to = {x1, bottom1}},
            {type = "close"},
        },
        samples = 28, fill = color, stroke = "#00000000", width = 1,
        layer = 1, id = id,
    }
end

local ribbons = {
    ribbon(-350, 130, -57.2, -10, 130, -57.2, "#2563eb55", "flow-input-converted"),
    ribbon(-350, -57.2, -130, -10, -73, -145.8, "#db277744", "flow-input-loss"),
    ribbon(10, 130, -10.4, 350, 130, -10.4, "#2563eb88", "flow-converted-product"),
    ribbon(10, -10.4, -57.2, 350, -26, -72.8, "#0891b266", "flow-converted-recovery"),
    ribbon(10, -73, -145.8, 350, -89, -161.8, "#db277766", "flow-loss-waste"),
}

local columns = scene:group {id = "sankey-columns"}
local function bar(id, x, top, bottom, color)
    return columns:rectangle {
        center = {x, (top + bottom) * 0.5}, size = {20, top - bottom}, corner = 4,
        fill = color, stroke = color, width = 1, layer = 4, id = id,
    }
end
bar("bar-input", -360, 130, -130, p.ink)
bar("bar-converted", 0, 130, -57.2, p.accent)
bar("bar-loss", 0, -73, -145.8, p.signal)
bar("bar-product", 360, 130, -10.4, p.accent)
bar("bar-recovery", 360, -26, -72.8, p.cyan)
bar("bar-waste", 360, -89, -161.8, p.signal)

local labels = scene:group {id = "sankey-labels"}
local function label(title, value, x, y, align, color, maskWidth, id)
    local group = labels:group {id = id}
    local center = align[1] == 1 and x - maskWidth * 0.5 or x + maskWidth * 0.5
    group:rectangle {
        center = {center, y}, size = {maskWidth, 50}, corner = 6, fill = p.paper,
        stroke = "#00000000", layer = 3, id = id .. "-mask",
    }
    group:text {
        text = title, point = {x, y + 12}, align = align, font = "Pretendard", size = 13,
        fill = p.muted, layer = 5, id = id .. "-title",
    }
    group:text {
        text = value, point = {x, y - 13}, align = align, font = "Pretendard", size = 20,
        fill = color, layer = 5, id = id .. "-value",
    }
end
label("INPUT", "100", -382, 0, {1, 0.5}, p.ink, 64, "label-input")
label("CONVERTED", "72", -22, 36.4, {1, 0.5}, p.accent, 112, "label-converted")
label("LOSS", "28", -22, -109.4, {1, 0.5}, p.signal, 58, "label-loss")
label("PRODUCT", "54", 382, 59.8, {0, 0.5}, p.accent, 88, "label-product")
label("RECOVERY", "18", 382, -49.4, {0, 0.5}, p.cyan, 96, "label-recovery")
label("WASTE", "28", 382, -125.4, {0, 0.5}, p.signal, 68, "label-waste")

local footer = scene:group {id = "sankey-footer"}
footer:rectangle {
    center = {0, -215}, size = {864, 34}, corner = 8, fill = p.panel,
    stroke = p.rule, width = 1, layer = 2, id = "balance-card",
}
footer:text {
    text = "INPUT 100  =  PRODUCT 54  +  RECOVERY 18  +  WASTE 28",
    point = {0, -215}, font = "Pretendard", size = 14, fill = p.ink,
    layer = 3, id = "balance-equation",
}

scene:fade_in(header, {shift = {0, 8}, duration = 0.28, curve = "snappy"})
scene:fade_in(columns, {duration = 0.28, curve = "gentle"})
scene:fill_reveal(ribbons, 0.9, "ease_out", 0)
scene:fade_in(labels, {shift = {0, -5}, duration = 0.24, curve = "snappy"})
scene:fade_in(footer, {shift = {0, -6}, duration = 0.22, curve = "snappy"})
scene:wait(0.8)

return scene`;

const ARCHITECTURE_JS = `const LAYER={zone:0,route:10,node:20,text:30};
const scene=tmath.scene({width:960,height:540,fps:30,loop:false,theme:"pro_white",
    camera:{mode:"fixed",view:"2d",target:[0,0],height:540}});
const header=scene.group({id:"architecture-header"});
header.text({text:"A request crosses three explicit ownership boundaries",point:[-432,232],
    align:[0,.5],role:"h2",id:"architecture-title"});
header.text({text:"The primary path stays straight; asynchronous work uses its own corridor.",
    point:[-432,194],align:[0,.5],role:"text",fill:"muted",id:"architecture-subtitle"});
header.line({from:[-432,162],to:[432,162],color:"border",width:1,layer:LAYER.zone,
    id:"architecture-divider"});
const zones=scene.group({id:"architecture-zones"});
const zone=(id,label,center,size)=>{
    const group=zones.group({id});
    group.rectangle({center,size,corner:12,fill:"surface",stroke:"border",width:1.25,
        layer:LAYER.zone,id:id+"-body"});
    group.text({text:label,point:[center[0]-size[0]*.5+16,center[1]+size[1]*.5-22],
        align:[0,.5],role:"h3",fill:"muted",layer:LAYER.text,id:id+"-label"});
};
zone("zone-public","Public",[-342,-30],[178,340]);
zone("zone-platform","Platform",[-36,-30],[396,340]);
zone("zone-data","Data",[350,-30],[164,340]);
const nodes=scene.group({id:"architecture-nodes"});
const node=(id,title,detail,center,size,emphasis)=>{
    const group=nodes.group({id});
    group.rectangle({center,size,corner:10,fill:"surface",stroke:emphasis||"border",
        width:emphasis?2.5:1.25,layer:LAYER.node,id:id+"-body"});
    group.text({text:title,point:[center[0],center[1]+11],role:"text",
        fill:emphasis||"foreground",layer:LAYER.text,id:id+"-title"});
    group.text({text:detail,point:[center[0],center[1]-18],role:"code",fill:"muted",
        layer:LAYER.text,id:id+"-detail"});
};
node("node-client","Client","web / mobile",[-342,50],[126,64]);
node("node-edge","Edge","TLS · routing",[-142,50],[126,64]);
node("node-api","API","auth · policy",[75,50],[138,64],"focus");
node("node-cache","Cache","read-through",[350,50],[118,64]);
node("node-worker","Worker","async jobs",[75,-110],[138,64]);
node("node-store","Store","durable state",[350,-110],[118,64]);
const routes=scene.group({id:"architecture-routes"});
const route=(id,from,to,color,dashed=false)=>routes.arrow({from,to,tip:12,color,width:3,
    ...(dashed?{dash:[8,6]}:{}),layer:LAYER.route,id});
const primary=[
    route("route-client-edge",[-279,50],[-205,50],"accent"),
    route("route-edge-api",[-79,50],[6,50],"accent"),
    route("route-api-cache",[144,50],[291,50],"accent")];
const asynchronous=[
    route("route-api-worker",[75,18],[75,-78],"secondary",true),
    route("route-worker-store",[144,-110],[291,-110],"secondary",true)];
const routeLabels=scene.group({id:"architecture-route-labels"});
const routeLabel=(id,text,point,color="muted")=>routeLabels.text({text,point,role:"code",
    fill:color,layer:LAYER.text,id});
routeLabel("label-https","HTTPS",[-242,94]);
routeLabel("label-cache","lookup",[218,94]);
routeLabel("label-enqueue","enqueue",[38,-30],"secondary");
routeLabel("label-state-write","state write",[218,-72],"secondary");
scene.fadeIn(header,{shift:[0,8],duration:.45,curve:"gentle"});
scene.fadeIn(zones,{duration:.45,curve:"gentle"});
scene.fadeIn(nodes,{shift:[0,-6],duration:.65,curve:"ease_out"});
scene.create(primary,1,"ease_out",.08,"forward");
scene.create(asynchronous,.75,"ease_out",.1,"forward");
scene.fadeIn(routeLabels,{duration:.4,curve:"gentle"});
scene.wait(2.2);
return scene;`;

const SEQUENCE_JS = `const LAYER={structure:0,activation:5,route:10,node:20,text:30};
const scene=tmath.scene({width:960,height:540,fps:30,loop:false,theme:"pro_white",
    camera:{mode:"fixed",view:"2d",target:[0,0],height:540}});
const header=scene.group({id:"sequence-header"});
header.text({text:"Checkout returns before receipt work finishes",point:[-432,232],
    align:[0,.5],role:"h2",id:"sequence-title"});
header.text({text:"Time moves downward; dashed messages return or continue without blocking the caller.",
    point:[-432,194],align:[0,.5],role:"text",fill:"muted",id:"sequence-subtitle"});
header.line({from:[-432,162],to:[432,162],color:"border",width:1,layer:LAYER.structure,
    id:"sequence-divider"});
const actors=scene.group({id:"sequence-actors"});
const actorX=[-330,-110,110,330],actorNames=["Web","API","Worker","Database"];
actorX.forEach((x,index)=>{
    const number=index+1,actor=actors.group({id:"actor-"+number});
    actor.rectangle({center:[x,112],size:[132,54],corner:9,fill:"surface",
        stroke:number===2?"focus":"border",width:number===2?2.5:1.25,
        layer:LAYER.node,id:"actor-"+number+"-body"});
    actor.text({text:actorNames[index],point:[x,112],role:"text",
        fill:number===2?"focus":"foreground",layer:LAYER.text,id:"actor-"+number+"-label"});
});
const lifelines=scene.group({id:"sequence-lifelines"});
actorX.forEach((x,index)=>lifelines.line({from:[x,84],to:[x,-192],color:"border",width:1.5,
    dash:[7,7],layer:LAYER.structure,id:"lifeline-"+(index+1)}));
const activations=scene.group({id:"sequence-activations"});
activations.rectangle({center:[-110,-64],size:[10,212],corner:3,fill:"surface",
    stroke:"focus",width:1.5,layer:LAYER.activation,id:"activation-api"});
activations.rectangle({center:[330,-14],size:[10,80],corner:3,fill:"surface",
    stroke:"border",width:1.25,layer:LAYER.activation,id:"activation-database"});
activations.rectangle({center:[110,-147],size:[10,58],corner:3,fill:"surface",
    stroke:"border",width:1.25,layer:LAYER.activation,id:"activation-worker"});
const messages=scene.group({id:"sequence-messages"});
const labels=scene.group({id:"sequence-labels"});
const specs=[
    ["checkout",-330,-110,40,"POST /checkout",false,"accent"],
    ["reserve",-110,330,-14,"reserve(order)",false,"accent"],
    ["reserved",330,-110,-68,"reservation",true,"muted"],
    ["publish",-110,110,-122,"publish(receipt)",true,"secondary"],
    ["accepted",110,-110,-176,"accepted",true,"muted"]];
const handles=[];
for(const [id,fromX,toX,y,label,dashed,color] of specs){
    handles.push(messages.arrow({from:[fromX,y],to:[toX,y],tip:12,color,width:2.5,
        ...(dashed?{dash:[8,6]}:{}),layer:LAYER.route,id:"message-"+id}));
    labels.text({text:label,point:[(fromX+toX)*.5,y+16],role:"code",fill:color,
        layer:LAYER.text,id:"message-"+id+"-label"});
}
scene.fadeIn(header,{shift:[0,8],duration:.45,curve:"gentle"});
scene.fadeIn(actors,{duration:.55,curve:"ease_out"});
scene.fadeIn(lifelines,{duration:.4,curve:"gentle"});
scene.fadeIn(activations,{duration:.4,curve:"gentle"});
for(const message of handles){scene.create(message,.55,"ease_out",0,"forward");scene.wait(.16);}
scene.fadeIn(labels,{duration:.4,curve:"gentle"});
scene.wait(2.2);
return scene;`;

const EVENT_FLOW_JS = `const LAYER={structure:0,route:10,node:20,text:30,marker:40};
const scene=tmath.scene({width:960,height:540,fps:30,loop:false,theme:"pro_white",
    camera:{mode:"fixed",view:"2d",target:[0,0],height:540}});
const header=scene.group({id:"event-flow-header"});
header.text({text:"Events branch only at declared decisions",point:[-432,232],
    align:[0,.5],role:"h2",id:"event-flow-title"});
header.text({text:"The main rail remains stable while failure and materialized state use named exits.",
    point:[-432,194],align:[0,.5],role:"text",fill:"muted",id:"event-flow-subtitle"});
header.line({from:[-432,162],to:[432,162],color:"border",width:1,layer:LAYER.structure,
    id:"event-flow-divider"});
const nodes=scene.group({id:"event-flow-nodes"});
const node=(id,title,detail,center,size,color)=>{
    const group=nodes.group({id});
    group.rectangle({center,size,corner:10,fill:"surface",stroke:color||"border",
        width:color?2.25:1.25,layer:LAYER.node,id:id+"-body"});
    group.text({text:title,point:[center[0],center[1]+10],role:"text",
        fill:color||"foreground",layer:LAYER.text,id:id+"-title"});
    group.text({text:detail,point:[center[0],center[1]-18],role:"code",fill:"muted",
        layer:LAYER.text,id:id+"-detail"});
};
node("node-producer","Producer","order.created",[-360,46],[128,64]);
node("node-validate","Validate","schema · policy",[-130,46],[128,64],"focus");
node("node-enrich","Enrich","customer context",[100,46],[128,64]);
node("node-consumer","Consumer","fulfillment",[340,46],[128,64]);
node("node-dlq","Dead letter","rejected event",[-130,-140],[128,58],"danger");
node("node-projection","Projection","orders_by_id",[340,-140],[128,58],"result");
const routes=scene.group({id:"event-flow-routes"});
const route=(id,from,to,color,dashed=false)=>routes.arrow({from,to,tip:12,color,width:3,
    ...(dashed?{dash:[8,6]}:{}),layer:LAYER.route,id});
const primary=[
    route("route-producer-validate",[-296,46],[-194,46],"accent"),
    route("route-validate-enrich",[-66,46],[36,46],"accent"),
    route("route-enrich-consumer",[164,46],[276,46],"accent")];
const branches=[
    route("route-validate-dlq",[-130,14],[-130,-111],"danger",true),
    route("route-consumer-projection",[340,14],[340,-111],"result")];
const labels=scene.group({id:"event-flow-labels"});
const label=(id,text,point,color="muted")=>labels.text({text,point,role:"code",
    fill:color,layer:LAYER.text,id});
label("label-publish","publish",[-245,92]);
label("label-normalize","normalize",[-15,92]);
label("label-deliver","deliver",[220,92]);
label("label-reject","reject",[-166,-46],"danger");
label("label-project","project state",[286,-46],"result");
const marker=scene.point({point:[-360,46],radius:7,color:"focus",layer:LAYER.marker,
    id:"event-marker"});
scene.fadeIn(header,{shift:[0,8],duration:.45,curve:"gentle"});
scene.fadeIn(nodes,{duration:.65,curve:"ease_out"});
scene.create(primary,1,"ease_out",.1,"forward");
scene.create(branches,.7,"ease_out",.1,"forward");
scene.fadeIn(labels,{duration:.4,curve:"gentle"});
scene.fadeIn(marker,{duration:.3,curve:"gentle"});
scene.shift(marker,[230,0],.8,"linear");scene.wait(.2);
scene.shift(marker,[230,0],.8,"linear");scene.wait(.2);
scene.shift(marker,[240,0],.85,"linear");
scene.fadeOut(marker,{duration:.3,curve:"gentle"});
scene.wait(2.2);
return scene;`;

const CAUSAL_LOOP_JS = `const LAYER={structure:0,route:10,node:20,text:30,marker:40};
const scene=tmath.scene({width:960,height:540,fps:30,loop:true,theme:"pro_white",
    camera:{mode:"fixed",view:"2d",target:[0,0],height:540}});
const header=scene.group({id:"causal-loop-header"});
header.text({text:"Persistent state closes the feedback loop",point:[-432,232],
    align:[0,.5],role:"h2",id:"causal-loop-title"});
header.text({text:"The topology stays fixed; one operational token advances through the recurring cycle.",
    point:[-432,194],align:[0,.5],role:"text",fill:"muted",id:"causal-loop-subtitle"});
header.line({from:[-432,162],to:[432,162],color:"border",width:1,layer:LAYER.structure,
    id:"causal-loop-divider"});
const nodes=scene.group({id:"causal-loop-nodes"});
const node=(id,title,detail,center)=>{
    const group=nodes.group({id});
    group.rectangle({center,size:[150,58],corner:10,fill:"surface",stroke:"border",
        width:1.25,layer:LAYER.node,id:id+"-body"});
    group.text({text:title,point:[center[0],center[1]+10],role:"text",
        layer:LAYER.text,id:id+"-title"});
    group.text({text:detail,point:[center[0],center[1]-17],role:"code",fill:"muted",
        layer:LAYER.text,id:id+"-detail"});
};
node("node-observe","Observe","signal",[0,104]);
node("node-interpret","Interpret","context",[285,-10]);
node("node-decide","Decide","policy",[0,-124]);
node("node-act","Act","effect",[-285,-10]);
const hub=nodes.group({id:"node-memory"});
hub.circle({center:[0,-10],radius:43,fill:"surface",stroke:"result",width:2.25,
    layer:LAYER.node,id:"node-memory-body"});
hub.text({text:"Memory",point:[0,0],role:"text",fill:"result",
    layer:LAYER.text,id:"node-memory-title"});
hub.text({text:"state",point:[0,-26],role:"code",fill:"muted",
    layer:LAYER.text,id:"node-memory-detail"});
const routes=scene.group({id:"causal-loop-routes"});
const route=(id,from,to,color)=>routes.arrow({from,to,tip:12,color,width:3,
    layer:LAYER.route,id});
route("route-observe-interpret",[75,88],[210,10],"accent");
route("route-interpret-decide",[210,-30],[75,-108],"accent");
route("route-decide-act",[-75,-108],[-210,-30],"accent");
route("route-act-observe",[-210,10],[-75,88],"accent");
route("route-decide-memory",[16,-95],[16,-53],"result");
route("route-memory-observe",[-16,33],[-16,75],"result");
const labels=scene.group({id:"causal-loop-labels"});
const label=(id,text,point,color="muted")=>labels.text({text,point,role:"code",
    fill:color,layer:LAYER.text,id});
label("label-frame","frame",[154,82]);
label("label-choose","choose",[154,-92]);
label("label-execute","execute",[-154,-92]);
label("label-feedback","feedback",[-154,82]);
label("label-write","write",[52,-74],"result");
label("label-read","read",[-50,54],"result");
const token=scene.point({point:[75,88],radius:8,color:"focus",layer:LAYER.marker,
    id:"loop-token"});
scene.wait(.35);
scene.shift(token,[135,-78],.55,"linear");
scene.shift(token,[0,-40],.25,"linear");
scene.shift(token,[-135,-78],.55,"linear");
scene.shift(token,[-150,0],.25,"linear");
scene.shift(token,[-135,78],.55,"linear");
scene.shift(token,[0,40],.25,"linear");
scene.shift(token,[135,78],.55,"linear");
scene.shift(token,[150,0],.25,"linear");
scene.wait(.35);
return scene;`;

const SANKEY_JS = `const p={paper:"#f7f5f0",panel:"#fffefa",ink:"#111827",muted:"#64748b",
    soft:"#94a3b8",rule:"#d9dee7",accent:"#2563eb",cyan:"#0891b2",signal:"#db2777"};
const scene=tmath.scene({width:960,height:540,fps:30,loop:false,background:p.paper,
    camera:{mode:"fixed",view:"2d",target:[0,0],height:540}});
const header=scene.group({id:"sankey-header"});
header.text({text:"SANKEY / MATERIAL BALANCE",point:[-432,238],align:[0,.5],font:"Pretendard",
    size:13,fill:p.accent,id:"sankey-eyebrow"});
header.text({text:"100 units in · 72 units retained",point:[-432,207],align:[0,.5],
    font:"Pretendard",size:30,fill:p.ink,id:"sankey-title"});
header.text({text:"Ribbon thickness is the quantity — every split conserves its incoming total",
    point:[-432,168],align:[0,.5],font:"Pretendard",size:15,fill:p.muted,id:"sankey-subtitle"});
header.line({from:[-432,148],to:[432,148],stroke:p.rule,width:1});
const ribbon=(x1,top1,bottom1,x2,top2,bottom2,color,id)=>{const bend=(x2-x1)*.48;
    return scene.path({commands:[{type:"move",to:[x1,top1]},
        {type:"cubic",control1:[x1+bend,top1],control2:[x2-bend,top2],to:[x2,top2]},
        {type:"line",to:[x2,bottom2]},
        {type:"cubic",control1:[x2-bend,bottom2],control2:[x1+bend,bottom1],to:[x1,bottom1]},
        {type:"close"}],samples:28,fill:color,stroke:"#00000000",width:1,layer:1,id});};
const ribbons=[
    ribbon(-350,130,-57.2,-10,130,-57.2,"#2563eb55","flow-input-converted"),
    ribbon(-350,-57.2,-130,-10,-73,-145.8,"#db277744","flow-input-loss"),
    ribbon(10,130,-10.4,350,130,-10.4,"#2563eb88","flow-converted-product"),
    ribbon(10,-10.4,-57.2,350,-26,-72.8,"#0891b266","flow-converted-recovery"),
    ribbon(10,-73,-145.8,350,-89,-161.8,"#db277766","flow-loss-waste")];
const columns=scene.group({id:"sankey-columns"});
const bar=(id,x,top,bottom,color)=>columns.rectangle({center:[x,(top+bottom)*.5],
    size:[20,top-bottom],corner:4,fill:color,stroke:color,width:1,layer:4,id});
bar("bar-input",-360,130,-130,p.ink);bar("bar-converted",0,130,-57.2,p.accent);
bar("bar-loss",0,-73,-145.8,p.signal);bar("bar-product",360,130,-10.4,p.accent);
bar("bar-recovery",360,-26,-72.8,p.cyan);bar("bar-waste",360,-89,-161.8,p.signal);
const labels=scene.group({id:"sankey-labels"});
const label=(title,value,x,y,align,color,maskWidth,id)=>{const group=labels.group({id}),
    center=align[0]===1?x-maskWidth*.5:x+maskWidth*.5;
    group.rectangle({center:[center,y],size:[maskWidth,50],corner:6,fill:p.paper,
        stroke:"#00000000",layer:3,id:id+"-mask"});
    group.text({text:title,point:[x,y+12],align,font:"Pretendard",size:13,fill:p.muted,
        layer:5,id:id+"-title"});
    group.text({text:value,point:[x,y-13],align,font:"Pretendard",size:20,fill:color,
        layer:5,id:id+"-value"});};
label("INPUT","100",-382,0,[1,.5],p.ink,64,"label-input");
label("CONVERTED","72",-22,36.4,[1,.5],p.accent,112,"label-converted");
label("LOSS","28",-22,-109.4,[1,.5],p.signal,58,"label-loss");
label("PRODUCT","54",382,59.8,[0,.5],p.accent,88,"label-product");
label("RECOVERY","18",382,-49.4,[0,.5],p.cyan,96,"label-recovery");
label("WASTE","28",382,-125.4,[0,.5],p.signal,68,"label-waste");
const footer=scene.group({id:"sankey-footer"});
footer.rectangle({center:[0,-215],size:[864,34],corner:8,fill:p.panel,stroke:p.rule,
    width:1,layer:2,id:"balance-card"});
footer.text({text:"INPUT 100  =  PRODUCT 54  +  RECOVERY 18  +  WASTE 28",point:[0,-215],
    font:"Pretendard",size:14,fill:p.ink,layer:3,id:"balance-equation"});
scene.fadeIn(header,{shift:[0,8],duration:.28,curve:"snappy"})
    .fadeIn(columns,{duration:.28,curve:"gentle"}).fillReveal(ribbons,.9,"ease_out",0)
    .fadeIn(labels,{shift:[0,-5],duration:.24,curve:"snappy"})
    .fadeIn(footer,{shift:[0,-6],duration:.22,curve:"snappy"}).wait(.8);
return scene;
`;

export const DIAGRAM_EXAMPLES = [
    {
        id: "diagram-architecture",
        title: "Architecture · service delivery",
        description:
            "Show a six-service request path across explicit trust zones with masked route labels.",
        category: "Diagram",
        dimension: "2D",
        fonts: PRETENDARD,
        lua: ARCHITECTURE_LUA,
        js: ARCHITECTURE_JS,
    },
    {
        id: "diagram-sequence",
        title: "Sequence · checkout",
        description: "Read blocking, return, and asynchronous messages from top to bottom.",
        category: "Diagram",
        dimension: "2D",
        fonts: PRETENDARD,
        lua: SEQUENCE_LUA,
        js: SEQUENCE_JS,
    },
    {
        id: "diagram-event-flow",
        title: "Event flow · declared branches",
        description: "Follow one stable event rail into explicit failure and state-projection exits.",
        category: "Diagram",
        dimension: "2D",
        fonts: PRETENDARD,
        lua: EVENT_FLOW_LUA,
        js: EVENT_FLOW_JS,
    },
    {
        id: "diagram-causal-loop",
        title: "Causal loop · persistent state",
        description: "Inspect a stable feedback topology while one operational token completes the cycle.",
        category: "Diagram",
        dimension: "2D",
        fonts: PRETENDARD,
        lua: CAUSAL_LOOP_LUA,
        js: CAUSAL_LOOP_JS,
    },
    {
        id: "diagram-sankey",
        title: "Sankey · material balance",
        description: "Conserve one hundred input units through proportional cubic flow ribbons.",
        category: "Diagram",
        dimension: "2D",
        fonts: PRETENDARD,
        lua: SANKEY_LUA,
        js: SANKEY_JS,
    },
];
