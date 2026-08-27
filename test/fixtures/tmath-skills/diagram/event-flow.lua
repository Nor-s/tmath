-- Question: where does an event travel, branch, fail, and materialize state?
-- Branches begin at declared decision nodes; anonymous junctions are not added for layout convenience.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = { mode = "fixed", view = "2d", target = { 0, -45 }, height = 540 },
}
local layer = { route = 10, node = 20, text = 30 }

local nodes = scene:group { id = "nodes" }
local function node(id, title, detail, x, y, color)
    local group = nodes:group { id = id }
    group:rectangle {
        center = { x, y }, size = { 140, 62 }, corner = 10, fill = "surface",
        stroke = color or "border", width = color and 2.25 or 1.25,
        layer = layer.node, id = id .. "-body",
    }
    group:text {
        text = title, point = { x, y + 10 }, role = "text", fill = color or "foreground",
        layer = layer.text, id = id .. "-title",
    }
    group:text {
        text = detail, point = { x, y - 17 }, role = "code", fill = "muted",
        layer = layer.text, id = id .. "-detail",
    }
end
node("producer", "Producer", "event", -320, 40)
node("decision", "Validate", "guard", -80, 40, "focus")
node("consumer", "Consumer", "effect", 200, 40)
node("failure", "Failure", "rejected", -80, -130, "danger")
node("state", "Projection", "materialized", 280, -130, "result")

local routes = scene:group { id = "routes" }
local function route(id, from, to, color, dashed)
    return routes:arrow {
        from = from, to = to, tip = 12, color = color, width = 3,
        dash = dashed and { 8, 6 } or nil, layer = layer.route, id = id,
    }
end
local primary = {
    route("route-producer-decision", { -250, 40 }, { -150, 40 }, "accent"),
    route("route-decision-consumer", { -10, 40 }, { 130, 40 }, "accent"),
}
local branches = {
    route("route-decision-failure", { -80, 9 }, { -80, -99 }, "danger", true),
    route("route-consumer-state", { 200, 9 }, { 280, -99 }, "result"),
}
scene:fade_in(nodes, { duration = 0.65, curve = "ease_out" })
scene:create(primary, 0.9, "ease_out", 0.1, "forward")
scene:create(branches, 0.7, "ease_out", 0.1, "forward")
scene:wait(2.2)
return scene
