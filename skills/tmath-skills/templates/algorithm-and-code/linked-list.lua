-- Question: what makes list order a pointer relation rather than physical adjacency?
-- Edit NODE_SPECS and the route geometry together. Preserve field boundaries, head, and NULL.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local LAYER = {route = 10, body = 20, text = 40}
local NODE_SPECS = {
    {id = "n7", value = 7, x = -245, y = 5},
    {id = "n3", value = 3, x = -5, y = 45},
    {id = "n13", value = 13, x = 235, y = -15},
}

local function translate(x, y)
    return {1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, 0, 0, 0, 0, 1}
end

local title = scene:text {
    text = "Singly linked list", point = {0, 220}, role = "h2",
    fill = "foreground", layer = LAYER.text, id = "scene-title",
}
local subtitle = scene:text {
    text = "node placement is editorial; next pointers define logical order",
    point = {0, 182}, role = "text", fill = "muted",
    layer = LAYER.text, id = "scene-subtitle",
}

local nodes = scene:group {id = "list:nodes"}
local nodeHandles, nodeBodies = {}, {}
for _, spec in ipairs(NODE_SPECS) do
    local node = nodes:group {matrix = translate(spec.x, spec.y), id = "list-node:" .. spec.id}
    local body = node:rectangle {
        center = {0, 0}, size = {150, 82}, corner = 7,
        fill = "surface", stroke = "border", width = 2,
        layer = LAYER.body, id = "list-node:" .. spec.id .. ":body",
    }
    node:line {
        from = {28, -41}, to = {28, 41}, stroke = "border", width = 2,
        layer = LAYER.body + 1, id = "list-node:" .. spec.id .. ":divider",
    }
    node:text {
        text = tostring(spec.value), point = {-24, 0}, role = "h3",
        fill = "foreground", layer = LAYER.text,
        id = "list-node:" .. spec.id .. ":value",
    }
    node:text {
        text = "next", point = {53, 0}, role = "code",
        fill = "muted", layer = LAYER.text,
        id = "list-node:" .. spec.id .. ":next-label",
    }
    nodeHandles[spec.id], nodeBodies[spec.id] = node, body
end

local routes = scene:group {id = "list:links"}
local head = routes:arrow {
    from = {-355, 125}, to = {-285, 52}, tip = 12,
    stroke = "accent", width = 3, layer = LAYER.route,
    id = "pointer:head",
}
local link1 = routes:route {
    points = {{-170, 5}, {-120, 5}, {-120, 45}, {-80, 45}}, tip = 12,
    stroke = "foreground", width = 3, layer = LAYER.route,
    id = "pointer:n7.next",
}
local link2 = routes:route {
    points = {{70, 45}, {120, 45}, {120, -15}, {160, -15}}, tip = 12,
    stroke = "foreground", width = 3, layer = LAYER.route,
    id = "pointer:n3.next",
}
local nullLink = routes:arrow {
    from = {310, -15}, to = {380, -15}, tip = 12,
    stroke = "muted", width = 3, layer = LAYER.route,
    id = "pointer:n13.next",
}
scene:text {
    text = "head", point = {-370, 145}, role = "code", fill = "accent",
    layer = LAYER.text, id = "pointer:head:label",
}
scene:text {
    text = "NULL", point = {420, -15}, role = "code", fill = "muted",
    layer = LAYER.text, id = "pointer:null:label",
}

local status = scene:text {
    text = "traverse: head → 7", point = {0, -150}, role = "code",
    fill = "focus", layer = LAYER.text, id = "status:node-7",
}

scene:fade_in(title, {shift = {0, -6}, duration = 0.45, curve = "gentle"})
scene:fade_in(subtitle, {shift = {0, -5}, duration = 0.35, curve = "gentle"})
scene:fade_in(nodes, {shift = {0, 7}, duration = 0.55, curve = "ease_out"})
scene:create(head, 0.35, "ease_out")
scene:create(link1, 0.45, "ease_out")
scene:create(link2, 0.45, "ease_out")
scene:create(nullLink, 0.35, "ease_out")
scene:fade_in(status, {duration = 0.28, curve = "gentle"})
scene:indicate(nodeHandles.n7, {scale = 1.04, duration = 0.38, curve = "ease_in_out"})

local status2 = scene:text {
    text = "follow n7.next → 3", point = {0, -150}, role = "code",
    fill = "focus", layer = LAYER.text, id = "status:node-3",
}
scene:fade_transform(status, status2, 0.20, "gentle")
scene:stroke(link1, "focus", 0.30, "ease_in_out")
scene:indicate(nodeHandles.n3, {scale = 1.04, duration = 0.38, curve = "ease_in_out"})

local status3 = scene:text {
    text = "follow n3.next → 13 → NULL", point = {0, -150}, role = "code",
    fill = "result", layer = LAYER.text, id = "result:traversal",
}
scene:fade_transform(status2, status3, 0.20, "gentle")
scene:stroke(link2, "focus", 0.30, "ease_in_out")
scene:indicate(nodeHandles.n13, {scale = 1.04, duration = 0.38, curve = "ease_in_out"})
scene:wait(2.0)
return scene
