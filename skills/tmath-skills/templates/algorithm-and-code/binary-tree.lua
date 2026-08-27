-- Question: why does a BST search for 10 follow exactly 8 -> 12 -> 10?
-- Edit NODE_SPECS, EDGES, QUERY, and the precomputed search trace together.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local LAYER = {edge = 10, node = 20, text = 40}
local NODE_SPECS = {
    {id = "n8", value = 8, x = 0, y = 120},
    {id = "n3", value = 3, x = -205, y = 20},
    {id = "n12", value = 12, x = 205, y = 20},
    {id = "n1", value = 1, x = -285, y = -105},
    {id = "n6", value = 6, x = -125, y = -105},
    {id = "n10", value = 10, x = 125, y = -105},
    {id = "n14", value = 14, x = 285, y = -105},
}
local QUERY = 10
local SEARCH_PATH = {"n8", "n12", "n10"}
local EDGES = {
    {"n8", "n3", "left"}, {"n8", "n12", "right"},
    {"n3", "n1", "left"}, {"n3", "n6", "right"},
    {"n12", "n10", "left"}, {"n12", "n14", "right"},
}
local VALUE_BY_ID = {}
for _, spec in ipairs(NODE_SPECS) do VALUE_BY_ID[spec.id] = spec.value end
assert(QUERY > VALUE_BY_ID[SEARCH_PATH[1]])
assert(QUERY < VALUE_BY_ID[SEARCH_PATH[2]])
assert(QUERY == VALUE_BY_ID[SEARCH_PATH[3]])

local function translate(x, y)
    return {1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, 0, 0, 0, 0, 1}
end

local title = scene:text {
    text = "Binary-search tree", point = {0, 225}, role = "h2",
    fill = "foreground", layer = LAYER.text, id = "scene-title",
}
local query = scene:text {
    text = "query = " .. QUERY, point = {335, 188}, role = "code",
    fill = "accent", layer = LAYER.text, id = "query:label",
}

local nodes = scene:group {id = "bst:nodes"}
local handles, bodies = {}, {}
for _, spec in ipairs(NODE_SPECS) do
    local node = nodes:group {matrix = translate(spec.x, spec.y), id = "bst-node:" .. spec.id}
    local body = node:circle {
        center = {0, 0}, radius = 30, fill = "surface", stroke = "border",
        width = 2.5, layer = LAYER.node, id = "bst-node:" .. spec.id .. ":body",
    }
    node:text {
        text = tostring(spec.value), point = {0, 0}, role = "h3",
        fill = "foreground", layer = LAYER.text,
        id = "bst-node:" .. spec.id .. ":label",
    }
    handles[spec.id], bodies[spec.id] = node, body
end

local edges = scene:group {id = "bst:edges"}
local edgeHandles = {}
for _, spec in ipairs(EDGES) do
    local id = "bst-edge:" .. spec[1] .. ":" .. spec[3]
    edgeHandles[id] = edges:connector {
        from = handles[spec[1]], to = handles[spec[2]], padding = 5,
        stroke = "border", width = 2.5, layer = LAYER.edge, id = id,
    }
end

local branchLeft = scene:text {
    text = "L", point = {-72, 84}, role = "code", fill = "muted",
    layer = LAYER.text, id = "branch:left:label",
}
local branchRight = scene:text {
    text = "R", point = {72, 84}, role = "code", fill = "muted",
    layer = LAYER.text, id = "branch:right:label",
}

local status = scene:text {
    text = string.format("%d > %d  →  choose right", QUERY, VALUE_BY_ID[SEARCH_PATH[1]]),
    point = {0, -190}, role = "code",
    fill = "focus", layer = LAYER.text, id = "status:at-8",
}

scene:fade_in(title, {shift = {0, -6}, duration = 0.42, curve = "gentle"})
scene:fade_in(query, {shift = {-5, 0}, duration = 0.34, curve = "gentle"})
scene:create(edges, 0.65, "ease_out")
scene:fade_in(nodes, {shift = {0, 7}, duration = 0.55, curve = "gentle"})
scene:fade_in(branchLeft, {duration = 0.20, curve = "gentle"})
scene:fade_in(branchRight, {duration = 0.20, curve = "gentle"})
scene:fade_in(status, {duration = 0.28, curve = "gentle"})
scene:play({
    {target = bodies.n8, fill = "focus"},
    {target = edgeHandles["bst-edge:n8:right"], stroke = "focus"},
}, 0.48, "ease_in_out", 0)
scene:wait(0.35)

local status2 = scene:text {
    text = string.format("%d < %d  →  choose left", QUERY, VALUE_BY_ID[SEARCH_PATH[2]]),
    point = {0, -190}, role = "code",
    fill = "focus", layer = LAYER.text, id = "status:at-12",
}
scene:fade_transform(status, status2, 0.20, "gentle")
scene:play({
    {target = bodies.n8, fill = "surface"},
    {target = bodies.n12, fill = "focus"},
    {target = edgeHandles["bst-edge:n12:left"], stroke = "focus"},
}, 0.48, "ease_in_out", 0)
scene:wait(0.35)

local result = scene:text {
    text = string.format(
        "found %d  ·  path: %d → %d → %d",
        QUERY,
        VALUE_BY_ID[SEARCH_PATH[1]],
        VALUE_BY_ID[SEARCH_PATH[2]],
        VALUE_BY_ID[SEARCH_PATH[3]]
    ),
    point = {0, -190},
    role = "text", fill = "result", layer = LAYER.text, id = "result:found",
}
scene:fade_transform(status2, result, 0.22, "gentle")
scene:play({
    {target = bodies.n12, fill = "surface"},
    {target = bodies.n10, fill = "result", stroke = "result"},
    {target = handles.n3, opacity = 0.30},
    {target = handles.n1, opacity = 0.30},
    {target = handles.n6, opacity = 0.30},
    {target = handles.n14, opacity = 0.30},
    {target = edgeHandles["bst-edge:n8:left"], opacity = 0.30},
    {target = edgeHandles["bst-edge:n3:left"], opacity = 0.30},
    {target = edgeHandles["bst-edge:n3:right"], opacity = 0.30},
    {target = edgeHandles["bst-edge:n12:right"], opacity = 0.30},
}, 0.55, "ease_in_out", 0)
scene:wait(2.0)
return scene
