-- Question: what changes, and what stays invariant, during one BST right rotation?
-- Variant: rotateRight(z) with y = z.left and T3 = y.right; no AVL metadata is implied.
-- Edit TREE and positions together; before/after relations and in-order witnesses are verified below.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local TREE = {
    z = {key = 30, left = "y", right = "t4"},
    y = {key = 20, left = "x", right = "t3"},
    x = {key = 10}, t3 = {key = 25}, t4 = {key = 40},
}
local ROOT, ROTATE_AT = "z", "z"
local BEFORE_POS = {
    z = {0, 100}, y = {-135, 10}, t4 = {145, 10},
    x = {-225, -88}, t3 = {-50, -88},
}
local AFTER_POS = {
    y = {0, 100}, x = {-135, 10}, z = {145, 10},
    t3 = {55, -88}, t4 = {235, -88},
}
local NODE_ORDER = {"z", "y", "x", "t3", "t4"}
local LAYER = {boundary = 4, edge = 10, ghost = 14, node = 20, text = 40}

local function cloneTree(source)
    local copy = {}
    for _, id in ipairs(NODE_ORDER) do
        local node = source[id]
        copy[id] = {key = node.key, left = node.left, right = node.right}
    end
    return copy
end

local function rotateRight(source, root)
    local after = cloneTree(source)
    local y = after[root].left
    assert(y, "right rotation requires a left child")
    local t3 = after[y].right
    after[root].left = t3
    after[y].right = root
    return after, y, t3
end

local function inorder(tree, node, output)
    if not node then return end
    inorder(tree, tree[node].left, output)
    output[#output + 1] = tree[node].key
    inorder(tree, tree[node].right, output)
end

local AFTER_TREE, AFTER_ROOT, TRANSFERRED = rotateRight(TREE, ROTATE_AT)
local BEFORE_ORDER, AFTER_ORDER = {}, {}
inorder(TREE, ROOT, BEFORE_ORDER)
inorder(AFTER_TREE, AFTER_ROOT, AFTER_ORDER)
assert(table.concat(BEFORE_ORDER, ",") == table.concat(AFTER_ORDER, ","))
for index = 2, #AFTER_ORDER do assert(AFTER_ORDER[index - 1] < AFTER_ORDER[index]) end
assert(AFTER_ROOT == "y" and TRANSFERRED == "t3")

local function translate(x, y)
    return {1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, 0, 0, 0, 0, 1}
end

local title = scene:text {
    text = "BST right rotation · key order stays invariant",
    point = {0, 230}, role = "h2", fill = "foreground",
    layer = LAYER.text, id = "scene-title",
}
local subtitle = scene:text {
    text = string.format("rotateRight(%d): y = z.left · T3 moves from y.right to z.left", TREE.z.key),
    point = {0, 194}, role = "code", fill = "muted",
    layer = LAYER.text, id = "scene-subtitle",
}
local boundary = scene:rectangle {
    center = {0, 12}, size = {650, 276}, corner = 10,
    fill = "#00000000", stroke = "muted", width = 2, dash = {10, 7},
    layer = LAYER.boundary, id = "invariant:rotated-key-range",
}
local boundaryLabel = scene:text {
    text = string.format("rotated subtree · keys [%d, %d]", BEFORE_ORDER[1], BEFORE_ORDER[#BEFORE_ORDER]),
    point = {-175, 132}, role = "code", fill = "muted",
    layer = LAYER.text, id = "invariant:rotated-key-range:label",
}

local nodeLayer = scene:group {id = "rotation:nodes"}
local nodes, bodies = {}, {}
for _, id in ipairs(NODE_ORDER) do
    local p = BEFORE_POS[id]
    local node = nodeLayer:group {matrix = translate(p[1], p[2]), id = "tree-node:" .. id}
    bodies[id] = node:circle {
        center = {0, 0}, radius = 29, fill = "surface", stroke = "border",
        width = 2.5, layer = LAYER.node, id = "tree-node:" .. id .. ":body",
    }
    node:text {
        text = tostring(TREE[id].key), point = {0, 0}, role = "h3",
        fill = "foreground", layer = LAYER.text, id = "tree-node:" .. id .. ":label",
    }
    nodes[id] = node
end

local edgeLayer = scene:group {id = "rotation:edges"}
local edgeZY = edgeLayer:connector {
    from = nodes.z, to = nodes.y, padding = 5, stroke = "border", width = 2.5,
    layer = LAYER.edge, id = "before-edge:z:left:y",
}
local edgeZT4 = edgeLayer:connector {
    from = nodes.z, to = nodes.t4, padding = 5, stroke = "border", width = 2.5,
    layer = LAYER.edge, id = "stable-edge:z:right:t4",
}
local edgeYX = edgeLayer:connector {
    from = nodes.y, to = nodes.x, padding = 5, stroke = "border", width = 2.5,
    layer = LAYER.edge, id = "stable-edge:y:left:x",
}
local edgeYT3 = edgeLayer:connector {
    from = nodes.y, to = nodes.t3, padding = 5, stroke = "border", width = 2.5,
    layer = LAYER.edge, id = "before-edge:y:right:t3",
}
local edgeYZ = edgeLayer:connector {
    from = nodes.y, to = nodes.z, padding = 5, stroke = "border", width = 2.5,
    opacity = 0, layer = LAYER.edge, id = "after-edge:y:right:z",
}
local edgeZT3 = edgeLayer:connector {
    from = nodes.z, to = nodes.t3, padding = 5, stroke = "border", width = 2.5,
    opacity = 0, layer = LAYER.edge, id = "after-edge:z:left:t3",
}
local previewZT3 = edgeLayer:connector {
    from = nodes.z, to = nodes.t3, padding = 5, stroke = "focus", width = 2.5,
    dash = {8, 6}, opacity = 0, layer = LAYER.ghost,
    id = "preview-edge:z:left:t3",
}

local ghostLayer = scene:group {id = "rotation:before-position-ghosts"}
for _, id in ipairs(NODE_ORDER) do
    local p = BEFORE_POS[id]
    ghostLayer:circle {
        center = p, radius = 34, fill = "#00000000", stroke = "muted",
        width = 2, dash = {7, 6},
        layer = LAYER.ghost, id = "before-ghost:" .. id,
    }
end
local ghostLabel = scene:text {
    text = "dashed rings = before positions", point = {205, 132},
    role = "code", fill = "muted",
    layer = LAYER.text, id = "before-ghost:label",
}

local witness = scene:group {id = "inorder:witness"}
witness:text {
    text = "in-order", point = {-300, -155}, role = "code", fill = "muted",
    layer = LAYER.text, id = "inorder:label",
}
local WITNESS_X, WITNESS_STEP = -165, 82
for index, value in ipairs(BEFORE_ORDER) do
    local x = WITNESS_X + (index - 1) * WITNESS_STEP
    witness:rectangle {
        center = {x, -155}, size = {58, 40}, corner = 4,
        fill = "surface", stroke = "border", width = 2,
        layer = LAYER.node, id = "inorder:slot:" .. index,
    }
    witness:text {
        text = tostring(value), point = {x, -155}, role = "code", fill = "foreground",
        layer = LAYER.text, id = "inorder:value:" .. value,
    }
end

local status, statusIndex = nil, 0
local function setStatus(message, color)
    statusIndex = statusIndex + 1
    local nextStatus = scene:text {
        text = message, point = {0, -205}, role = "code", fill = color or "focus",
        layer = LAYER.text, id = "status:" .. statusIndex,
    }
    if status then scene:fade_transform(status, nextStatus, 0.18, "gentle")
    else scene:fade_in(nextStatus, {duration = 0.25, curve = "gentle"}) end
    status = nextStatus
end

scene:fade_in(title, {shift = {0, -6}, duration = 0.42, curve = "gentle"})
scene:fade_in(subtitle, {shift = {0, -5}, duration = 0.34, curve = "gentle"})
scene:fade_in(boundary, {duration = 0.30, curve = "gentle"})
scene:fade_in(boundaryLabel, {duration = 0.24, curve = "gentle"})
scene:create({edgeZY, edgeZT4, edgeYX, edgeYT3}, 0.62, "ease_out", 0.05)
scene:fade_in(nodeLayer, {shift = {0, 6}, duration = 0.48, curve = "gentle"})
scene:fade_in(witness, {duration = 0.34, curve = "gentle"})
setStatus("before: z.left = y · y.right = T3 · in-order witness is fixed")
scene:wait(0.75)

setStatus("preview: y becomes root; T3 will become z.left")
scene:fade_in(ghostLayer, {duration = 0.32, curve = "gentle"})
scene:fade_in(ghostLabel, {duration = 0.22, curve = "gentle"})
scene:play({{target = previewZT3, opacity = 1}}, 0.32, "ease_out", 0)
scene:wait(0.42)

setStatus("commit one right rotation · move stable nodes and replace two relations")
local rotationTargets = {
    {target = edgeZY, opacity = 0}, {target = edgeYT3, opacity = 0},
    {target = edgeYZ, opacity = 1}, {target = edgeZT3, opacity = 1},
    {target = previewZT3, opacity = 0},
}
for _, id in ipairs(NODE_ORDER) do
    local before, after = BEFORE_POS[id], AFTER_POS[id]
    rotationTargets[#rotationTargets + 1] = {
        target = nodes[id], shift = {after[1] - before[1], after[2] - before[2]},
    }
end
scene:play(rotationTargets, 0.90, "ease_in_out", 0)
scene:wait(0.48)

setStatus("invariant: in-order remains " .. table.concat(AFTER_ORDER, " < "), "result")
scene:play({
    {target = ghostLayer, opacity = 0}, {target = ghostLabel, opacity = 0},
    {target = boundary, stroke = "result"},
    {target = bodies[AFTER_ROOT], fill = "result", stroke = "result"},
    {target = edgeYZ, stroke = "result"}, {target = edgeZT3, stroke = "result"},
}, 0.52, "ease_in_out", 0)

local result = scene:text {
    text = string.format("new root = %d · transferred T3 = %d · BST order preserved",
        TREE[AFTER_ROOT].key, TREE[TRANSFERRED].key),
    point = {0, -238}, role = "text", fill = "result",
    layer = LAYER.text, id = "result:right-rotation",
}
scene:fade_in(result, {shift = {0, 4}, duration = 0.36, curve = "gentle"})
scene:wait(2.4)
return scene
