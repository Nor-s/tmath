-- Question: which parent owns each child, and how do coherent levels form the tree?
-- Edit NODES and EDGES. Preserve top-down ranks and non-directional ownership edges.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local LAYER = {edge = 10, node = 20, text = 40}
local NODES = {
    {id = "root", label = "A", x = 0, y = 125, level = 1},
    {id = "b", label = "B", x = -220, y = 15, level = 2},
    {id = "c", label = "C", x = 0, y = 15, level = 2},
    {id = "d", label = "D", x = 220, y = 15, level = 2},
    {id = "e", label = "E", x = -55, y = -115, level = 3},
    {id = "f", label = "F", x = 55, y = -115, level = 3},
}
local EDGES = {{"root", "b"}, {"root", "c"}, {"root", "d"}, {"c", "e"}, {"c", "f"}}

local function translate(x, y)
    return {1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, 0, 0, 0, 0, 1}
end

local title = scene:text {
    text = "General tree", point = {0, 225}, role = "h2",
    fill = "foreground", layer = LAYER.text, id = "scene-title",
}
local subtitle = scene:text {
    text = "levels express hierarchy; node identities do not depend on position",
    point = {0, 190}, role = "text", fill = "muted",
    layer = LAYER.text, id = "scene-subtitle",
}

local levelGroups = {
    scene:group {id = "tree:level-1"},
    scene:group {id = "tree:level-2"},
    scene:group {id = "tree:level-3"},
}
local handles = {}
for _, spec in ipairs(NODES) do
    local node = levelGroups[spec.level]:group {
        matrix = translate(spec.x, spec.y), id = "tree-node:" .. spec.id,
    }
    node:circle {
        center = {0, 0}, radius = 31, fill = "surface", stroke = "border",
        width = 2.5, layer = LAYER.node, id = "tree-node:" .. spec.id .. ":body",
    }
    node:text {
        text = spec.label, point = {0, 0}, role = "h3", fill = "foreground",
        layer = LAYER.text, id = "tree-node:" .. spec.id .. ":label",
    }
    handles[spec.id] = node
end

local edgeGroups = {
    scene:group {id = "tree:edges-to-level-2"},
    scene:group {id = "tree:edges-to-level-3"},
}
for index, edge in ipairs(EDGES) do
    local parent, child = edge[1], edge[2]
    local group = index <= 3 and edgeGroups[1] or edgeGroups[2]
    group:connector {
        from = handles[parent], to = handles[child], padding = 5,
        stroke = "border", width = 2.5, layer = LAYER.edge,
        id = "tree-edge:" .. parent .. ":" .. child,
    }
end

local result = scene:text {
    text = "parent-child ownership is fully inspectable", point = {0, -205},
    role = "text", fill = "result", layer = LAYER.text, id = "result:tree",
}

scene:fade_in(title, {shift = {0, -6}, duration = 0.42, curve = "gentle"})
scene:fade_in(subtitle, {shift = {0, -5}, duration = 0.34, curve = "gentle"})
scene:grow_from_center(levelGroups[1], 0.38, "ease_out")
scene:create(edgeGroups[1], 0.55, "ease_out")
scene:fade_in(levelGroups[2], {shift = {0, 8}, duration = 0.48, curve = "gentle"})
scene:create(edgeGroups[2], 0.48, "ease_out")
scene:fade_in(levelGroups[3], {shift = {0, 8}, duration = 0.46, curve = "gentle"})
scene:fade_in(result, {shift = {0, 5}, duration = 0.32, curve = "gentle"})
scene:wait(2.0)
return scene
