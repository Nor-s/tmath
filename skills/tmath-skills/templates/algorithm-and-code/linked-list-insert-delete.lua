-- Question: in which source order do pointer writes make insertion and deletion safe?
-- Variant: singly linked list; insert n9 after n3, then delete n3 through predecessor n7.
-- The canonical next-map below generates and verifies every live reachability state.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local LAYER = {route = 10, preview = 14, body = 20, text = 40}
local NODE_SPECS = {
    {id = "n7", value = 7, x = -300},
    {id = "n3", value = 3, x = -100},
    {id = "n9", value = 9, x = 100},
    {id = "n13", value = 13, x = 300},
}
local Y = 25

local function cloneMap(source)
    local copy = {}
    for _, spec in ipairs(NODE_SPECS) do copy[spec.id] = source[spec.id] end
    return copy
end

local function reachable(nextMap)
    local result, seen, node = {}, {}, "n7"
    while node do
        assert(not seen[node], "unexpected cycle in illustrative list")
        seen[node] = true
        result[#result + 1] = node
        node = nextMap[node]
    end
    return result
end

local function buildTrace()
    local state = {n7 = "n3", n3 = "n13", n9 = nil, n13 = nil}
    local trace = {}
    local function record(kind, field, oldValue, newValue)
        if field then
            assert(state[field] == oldValue)
            state[field] = newValue
        end
        trace[#trace + 1] = {
            kind = kind, field = field, old = oldValue, new = newValue,
            stateAfter = cloneMap(state), reachableAfter = reachable(state),
        }
    end
    record("allocate", nil, nil, "n9")
    record("link", "n9", nil, "n13")
    record("link", "n3", "n13", "n9")
    record("link", "n7", "n3", "n9")
    record("detach", nil, "n3", nil)
    assert(table.concat(trace[3].reachableAfter, ",") == "n7,n3,n9,n13")
    assert(table.concat(trace[5].reachableAfter, ",") == "n7,n9,n13")
    return trace
end

local TRACE = buildTrace()
local VALUE_BY_ID = {}
for _, spec in ipairs(NODE_SPECS) do VALUE_BY_ID[spec.id] = spec.value end
local function reachableValues(ids)
    local values = {}
    for _, id in ipairs(ids) do values[#values + 1] = VALUE_BY_ID[id] end
    return values
end

local function translate(x, y)
    return {1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, 0, 0, 0, 0, 1}
end

local title = scene:text {
    text = "Linked-list mutation · preview → commit → invariant",
    point = {0, 228}, role = "h2", fill = "foreground",
    layer = LAYER.text, id = "scene-title",
}
local subtitle = scene:text {
    text = "insert n9 after n3, then bypass n3 without losing the tail",
    point = {0, 190}, role = "text", fill = "muted",
    layer = LAYER.text, id = "scene-subtitle",
}

local nodeLayer = scene:group {id = "list:nodes"}
local nodes, bodies = {}, {}
for _, spec in ipairs(NODE_SPECS) do
    local node = nodeLayer:group {
        matrix = translate(spec.x, Y), id = "list-node:" .. spec.id,
    }
    bodies[spec.id] = node:rectangle {
        center = {0, 0}, size = {130, 72}, corner = 7,
        fill = "surface", stroke = "border", width = 2,
        layer = LAYER.body, id = "list-node:" .. spec.id .. ":body",
    }
    node:line {
        from = {11, -36}, to = {11, 36}, stroke = "border", width = 2,
        layer = LAYER.body + 1, id = "list-node:" .. spec.id .. ":divider",
    }
    node:text {
        text = tostring(spec.value), point = {-22, 0}, role = "h3",
        fill = "foreground", layer = LAYER.text,
        id = "list-node:" .. spec.id .. ":value",
    }
    node:text {
        text = "next", point = {38, 0}, role = "code", fill = "muted",
        layer = LAYER.text, id = "list-node:" .. spec.id .. ":next-label",
    }
    nodes[spec.id] = node
end

local routeLayer = scene:group {id = "list:routes"}
local head = routeLayer:arrow {
    from = {-410, 120}, to = {-365, 55}, tip = 11,
    stroke = "accent", width = 3, layer = LAYER.route, id = "pointer:head",
}
local link7to3 = routeLayer:arrow {
    from = {-235, Y}, to = {-165, Y}, tip = 11,
    stroke = "foreground", width = 3, layer = LAYER.route, id = "pointer:n7.next:to-n3",
}
local link3to13 = routeLayer:route {
    points = {{-35, Y}, {0, Y}, {0, 110}, {210, 110}, {210, Y}, {235, Y}},
    tip = 11, stroke = "foreground", width = 3,
    layer = LAYER.route, id = "pointer:n3.next:to-n13",
}
local nullLink = routeLayer:arrow {
    from = {365, Y}, to = {415, Y}, tip = 11,
    stroke = "muted", width = 3, layer = LAYER.route, id = "pointer:n13.next:null",
}

local preview9to13 = routeLayer:arrow {
    from = {165, Y}, to = {235, Y}, tip = 11, dash = {8, 6},
    stroke = "focus", width = 3, opacity = 0,
    layer = LAYER.preview, id = "preview:n9.next:to-n13",
}
local link9to13 = routeLayer:arrow {
    from = {165, Y}, to = {235, Y}, tip = 11,
    stroke = "foreground", width = 3, opacity = 0,
    layer = LAYER.route, id = "pointer:n9.next:to-n13",
}
local preview3to9 = routeLayer:arrow {
    from = {-35, Y}, to = {35, Y}, tip = 11, dash = {8, 6},
    stroke = "focus", width = 3, opacity = 0,
    layer = LAYER.preview, id = "preview:n3.next:to-n9",
}
local link3to9 = routeLayer:arrow {
    from = {-35, Y}, to = {35, Y}, tip = 11,
    stroke = "foreground", width = 3, opacity = 0,
    layer = LAYER.route, id = "pointer:n3.next:to-n9",
}
local preview7to9 = routeLayer:route {
    points = {{-235, Y}, {-210, Y}, {-210, 115}, {5, 115}, {5, Y}, {35, Y}},
    tip = 11, dash = {8, 6}, stroke = "focus", width = 3, opacity = 0,
    layer = LAYER.preview, id = "preview:n7.next:to-n9",
}
local link7to9 = routeLayer:route {
    points = {{-235, Y}, {-210, Y}, {-210, 115}, {5, 115}, {5, Y}, {35, Y}},
    tip = 11, stroke = "foreground", width = 3, opacity = 0,
    layer = LAYER.route, id = "pointer:n7.next:to-n9",
}

local headLabel = scene:text {
    text = "head", point = {-420, 145}, role = "code", fill = "accent",
    layer = LAYER.text, id = "pointer:head:label",
}
local nullLabel = scene:text {
    text = "NULL", point = {447, Y}, role = "code", fill = "muted",
    layer = LAYER.text, id = "pointer:null:label",
}
local invariant = scene:rectangle {
    center = {0, Y}, size = {760, 104}, corner = 10,
    fill = "#00000000", stroke = "muted", width = 2, dash = {10, 7},
    layer = LAYER.route - 2, id = "invariant:reachable-chain",
}
local invariantLabel = scene:text {
    text = "reachable from head", point = {0, -50}, role = "code", fill = "muted",
    layer = LAYER.text, id = "invariant:reachable-chain:label",
}

local status, statusIndex = nil, 0
local function setStatus(message, color)
    statusIndex = statusIndex + 1
    local nextStatus = scene:text {
        text = message, point = {0, -155}, role = "code", fill = color or "focus",
        layer = LAYER.text, id = "status:" .. statusIndex,
    }
    if status then scene:fade_transform(status, nextStatus, 0.18, "gentle")
    else scene:fade_in(nextStatus, {duration = 0.25, curve = "gentle"}) end
    status = nextStatus
end

scene:fade_in(title, {shift = {0, -6}, duration = 0.42, curve = "gentle"})
scene:fade_in(subtitle, {shift = {0, -5}, duration = 0.34, curve = "gentle"})
scene:fade_in(invariant, {duration = 0.28, curve = "gentle"})
scene:fade_in(invariantLabel, {duration = 0.24, curve = "gentle"})
scene:fade_in(nodes.n7, {duration = 0.32, curve = "gentle"})
scene:fade_in(nodes.n3, {duration = 0.32, curve = "gentle"})
scene:fade_in(nodes.n13, {duration = 0.32, curve = "gentle"})
scene:create(head, 0.25, "ease_out")
scene:create(link7to3, 0.30, "ease_out")
scene:create(link3to13, 0.42, "ease_out")
scene:create(nullLink, 0.25, "ease_out")
scene:fade_in(headLabel, {duration = 0.18, curve = "gentle"})
scene:fade_in(nullLabel, {duration = 0.18, curve = "gentle"})
scene:wait(0.45)

setStatus("allocate " .. TRACE[1].new .. " · no live pointer reaches it yet")
scene:fade_in(nodes.n9, {shift = {0, -10}, duration = 0.45, curve = "ease_out"})
scene:play({{target = bodies.n9, fill = "focus", stroke = "focus"}}, 0.32, "ease_in_out", 0)
scene:wait(0.35)

setStatus("preview " .. TRACE[2].field .. ".next = " .. TRACE[2].new .. " · state unchanged")
scene:play({{target = preview9to13, opacity = 1}}, 0.32, "ease_out", 0)
scene:wait(0.32)
setStatus("commit " .. TRACE[2].field .. ".next = " .. TRACE[2].new)
scene:play({
    {target = preview9to13, opacity = 0},
    {target = link9to13, opacity = 1},
    {target = bodies.n9, fill = "surface", stroke = "border"},
}, 0.48, "ease_in_out", 0)

setStatus("preview " .. TRACE[3].field .. ".next: " .. TRACE[3].old .. " → " .. TRACE[3].new)
scene:play({{target = preview3to9, opacity = 1}}, 0.32, "ease_out", 0)
scene:wait(0.30)
setStatus("commit insertion · head reaches " .. table.concat(reachableValues(TRACE[3].reachableAfter), " → "))
scene:play({
    {target = preview3to9, opacity = 0},
    {target = link3to13, opacity = 0.18},
    {target = link3to9, opacity = 1},
}, 0.52, "ease_in_out", 0)
scene:fade_out(link3to13, {duration = 0.22, curve = "gentle"})
scene:wait(0.45)

setStatus("preview delete · bypass " .. TRACE[4].old .. " with " .. TRACE[4].field .. ".next = " .. TRACE[4].new)
scene:play({{target = preview7to9, opacity = 1}}, 0.34, "ease_out", 0)
scene:wait(0.32)
setStatus("commit bypass before detaching " .. TRACE[5].old)
scene:play({
    {target = preview7to9, opacity = 0},
    {target = link7to3, opacity = 0.18},
    {target = link7to9, opacity = 1},
}, 0.52, "ease_in_out", 0)
scene:play({
    {target = nodes.n3, opacity = 0.24},
    {target = link7to3, opacity = 0},
    {target = link3to9, opacity = 0.18},
}, 0.42, "ease_in_out", 0)

local finalIds = TRACE[#TRACE].reachableAfter
local finalValues = reachableValues(finalIds)
local result = scene:text {
    text = "invariant: head reaches " .. table.concat(finalValues, " → ") .. " → NULL",
    point = {0, -210}, role = "text", fill = "result",
    layer = LAYER.text, id = "result:reachable-chain",
}
scene:fade_transform(status, result, 0.24, "gentle")
scene:play({
    {target = invariant, stroke = "result"},
    {target = link7to9, stroke = "result"},
    {target = link9to13, stroke = "result"},
}, 0.48, "ease_in_out", 0)
scene:wait(2.2)
return scene
