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
return scene
