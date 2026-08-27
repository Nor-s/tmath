-- Question: why may nearest-neighbor search prune both far branches after finding C?
-- Preserve the same point/split identity in the spatial view and decision tree.
-- Edit POINTS, QUERY, topology, and the verified search trace together.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local LAYER = {frame = 0, region = 2, edge = 10, mark = 20, text = 40}
local POINTS = {
    A = {5, 4}, D = {2, 5}, F = {8, 6},
    B = {1, 2}, C = {4, 7}, E = {7, 2}, G = {9, 8},
}
local QUERY = {3.4, 7.4}
local ROOT_SPLIT_X = POINTS.A[1]
local LEFT_SPLIT_Y = POINTS.D[2]
local RIGHT_SPLIT_Y = POINTS.F[2]
local bestDx, bestDy = QUERY[1] - POINTS.C[1], QUERY[2] - POINTS.C[2]
local BEST_DISTANCE = math.sqrt(bestDx * bestDx + bestDy * bestDy)
local ROOT_PLANE_DISTANCE = math.abs(QUERY[1] - ROOT_SPLIT_X)
local LEFT_PLANE_DISTANCE = math.abs(QUERY[2] - LEFT_SPLIT_Y)
local SCALE, OX, OY = 28, -390, -125

assert(LEFT_PLANE_DISTANCE > BEST_DISTANCE)
assert(ROOT_PLANE_DISTANCE > BEST_DISTANCE)

local function translate(x, y)
    return {1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, 0, 0, 0, 0, 1}
end

local function mapPoint(point)
    return {OX + point[1] * SCALE, OY + point[2] * SCALE}
end

local title = scene:text {
    text = "KD-tree · nearest-neighbor pruning", point = {0, 234}, role = "h2",
    fill = "foreground", layer = LAYER.text, id = "scene-title",
}
local subtitle = scene:text {
    text = "the spatial split and tree decision share one identity",
    point = {0, 198}, role = "text", fill = "muted",
    layer = LAYER.text, id = "scene-subtitle",
}
local spatialFrame = scene:rectangle {
    center = {-250, 15}, size = {330, 330}, corner = 8,
    fill = "#00000000", stroke = "border", width = 2,
    layer = LAYER.frame, id = "spatial:frame",
}
local treeFrame = scene:rectangle {
    center = {240, 15}, size = {390, 330}, corner = 8,
    fill = "#00000000", stroke = "border", width = 2,
    layer = LAYER.frame, id = "tree:frame",
}
local spatialTitle = scene:text {
    text = "SPACE", point = {-250, 158}, role = "code", fill = "foreground",
    layer = LAYER.text, id = "spatial:title",
}
local treeTitle = scene:text {
    text = "DECISION TREE", point = {240, 158}, role = "code", fill = "foreground",
    layer = LAYER.text, id = "tree:title",
}
local legend = scene:text {
    text = "x split  |  y split  |  query Q", point = {0, 162}, role = "code",
    fill = "muted", layer = LAYER.text, id = "legend",
}

local splitLayer = scene:group {id = "spatial:splits"}
local rootSplit = splitLayer:line {
    from = mapPoint({ROOT_SPLIT_X, 0}), to = mapPoint({ROOT_SPLIT_X, 10}),
    stroke = "danger", width = 4, layer = LAYER.edge,
    id = "split:A:x-" .. ROOT_SPLIT_X,
}
local leftSplit = splitLayer:line {
    from = mapPoint({0, LEFT_SPLIT_Y}), to = mapPoint({ROOT_SPLIT_X, LEFT_SPLIT_Y}),
    stroke = "info", width = 4, layer = LAYER.edge,
    id = "split:D:y-" .. LEFT_SPLIT_Y,
}
local rightSplit = splitLayer:line {
    from = mapPoint({ROOT_SPLIT_X, RIGHT_SPLIT_Y}), to = mapPoint({10, RIGHT_SPLIT_Y}),
    stroke = "info", width = 4, layer = LAYER.edge,
    id = "split:F:y-" .. RIGHT_SPLIT_Y,
}

local pointLayer = scene:group {id = "spatial:points"}
local pointHandles, pointBodies = {}, {}
local function makeSpatialPoint(name, color)
    local p = mapPoint(POINTS[name])
    local point = pointLayer:group {matrix = translate(p[1], p[2]), id = "point:" .. name}
    local body = point:circle {
        center = {0, 0}, radius = 8, fill = "surface", stroke = color,
        width = 3, layer = LAYER.mark, id = "point:" .. name .. ":body",
    }
    point:text {
        text = name, point = {15, 15}, role = "code", fill = color,
        layer = LAYER.text, id = "point:" .. name .. ":label",
    }
    pointHandles[name], pointBodies[name] = point, body
end
makeSpatialPoint("A", "danger")
makeSpatialPoint("D", "info")
makeSpatialPoint("F", "info")
for _, name in ipairs {"B", "C", "E", "G"} do makeSpatialPoint(name, "foreground") end

local queryPosition = mapPoint(QUERY)
local query = scene:group {
    matrix = translate(queryPosition[1], queryPosition[2]), id = "query:Q",
}
query:circle {
    center = {0, 0}, radius = 9, fill = "surface", stroke = "warning",
    width = 3, layer = LAYER.mark, id = "query:Q:body",
}
query:text {
    text = "Q", point = {-16, 16}, role = "code", fill = "warning",
    layer = LAYER.text, id = "query:Q:label",
}

local treeNodes = scene:group {id = "tree:nodes"}
local treeHandles, treeBodies = {}, {}
local TREE_POSITIONS = {
    A = {240, 112}, D = {145, 28}, F = {335, 28},
    B = {95, -90}, C = {195, -90}, E = {285, -90}, G = {385, -90},
}
local TREE_AXIS = {
    A = "x=" .. ROOT_SPLIT_X,
    D = "y=" .. LEFT_SPLIT_Y,
    F = "y=" .. RIGHT_SPLIT_Y,
}
local function makeTreeNode(name, color)
    local p = TREE_POSITIONS[name]
    local node = treeNodes:group {matrix = translate(p[1], p[2]), id = "tree-node:" .. name}
    local body = node:circle {
        center = {0, 0}, radius = 23, fill = "surface", stroke = color,
        width = 3, layer = LAYER.mark, id = "tree-node:" .. name .. ":body",
    }
    node:text {
        text = name, point = {0, 0}, role = "h3", fill = "foreground",
        layer = LAYER.text, id = "tree-node:" .. name .. ":label",
    }
    if TREE_AXIS[name] then
        node:text {
            text = TREE_AXIS[name], point = {0, -34}, role = "code", fill = color,
            layer = LAYER.text, id = "tree-node:" .. name .. ":axis",
        }
    end
    treeHandles[name], treeBodies[name] = node, body
end
makeTreeNode("A", "danger")
makeTreeNode("D", "info")
makeTreeNode("F", "info")
for _, name in ipairs {"B", "C", "E", "G"} do makeTreeNode(name, "border") end

local treeEdges = scene:group {id = "tree:edges"}
local edgeHandles = {}
local function edge(parent, child, branch)
    local id = "tree-edge:" .. parent .. ":" .. branch
    edgeHandles[id] = treeEdges:connector {
        from = treeHandles[parent], to = treeHandles[child], padding = 4,
        stroke = "border", width = 2.5, layer = LAYER.edge, id = id,
    }
end
edge("A", "D", "left")
edge("A", "F", "right")
edge("D", "B", "lower")
edge("D", "C", "upper")
edge("F", "E", "lower")
edge("F", "G", "upper")

local status, statusCounter = nil, 0
local function setStatus(message, color)
    statusCounter = statusCounter + 1
    local nextStatus = scene:text {
        text = message, point = {0, -192}, role = "code", fill = color or "focus",
        layer = LAYER.text, id = "status:" .. statusCounter,
    }
    if status then scene:fade_transform(status, nextStatus, 0.18, "gentle")
    else scene:fade_in(nextStatus, {duration = 0.25, curve = "gentle"}) end
    status = nextStatus
end

scene:fade_in(title, {shift = {0, -6}, duration = 0.42, curve = "gentle"})
scene:fade_in(subtitle, {shift = {0, -5}, duration = 0.34, curve = "gentle"})
scene:fade_in(spatialFrame, {duration = 0.30, curve = "gentle"})
scene:fade_in(treeFrame, {duration = 0.30, curve = "gentle"})
scene:fade_in(spatialTitle, {duration = 0.24, curve = "gentle"})
scene:fade_in(treeTitle, {duration = 0.24, curve = "gentle"})
scene:fade_in(pointLayer, {duration = 0.42, curve = "gentle"})
scene:create(splitLayer, 0.62, "ease_out")
scene:fade_in(treeNodes, {duration = 0.46, curve = "gentle"})
scene:create(treeEdges, 0.62, "ease_out")
scene:fade_in(query, {duration = 0.30, curve = "gentle"})

setStatus(string.format("Q.x = %.1f < %g  →  visit A's left branch", QUERY[1], ROOT_SPLIT_X))
scene:play({
    {target = pointBodies.A, fill = "focus", stroke = "focus"},
    {target = treeBodies.A, fill = "focus", stroke = "focus"},
    {target = rootSplit, stroke = "focus"},
    {target = edgeHandles["tree-edge:A:left"], stroke = "focus"},
}, 0.52, "ease_in_out", 0)
scene:wait(0.32)

setStatus(string.format("Q.y = %.1f > %g  →  visit D's upper branch", QUERY[2], LEFT_SPLIT_Y))
scene:play({
    {target = pointBodies.A, fill = "surface", stroke = "danger"},
    {target = treeBodies.A, fill = "surface", stroke = "danger"},
    {target = rootSplit, stroke = "danger"},
    {target = pointBodies.D, fill = "focus", stroke = "focus"},
    {target = treeBodies.D, fill = "focus", stroke = "focus"},
    {target = leftSplit, stroke = "focus"},
    {target = edgeHandles["tree-edge:D:upper"], stroke = "focus"},
}, 0.52, "ease_in_out", 0)
scene:wait(0.32)

setStatus(string.format("C becomes current best  ·  distance = %.2f", BEST_DISTANCE), "result")
scene:play({
    {target = pointBodies.D, fill = "surface", stroke = "info"},
    {target = treeBodies.D, fill = "surface", stroke = "info"},
    {target = leftSplit, stroke = "info"},
    {target = pointBodies.C, fill = "result", stroke = "result"},
    {target = treeBodies.C, fill = "result", stroke = "result"},
}, 0.50, "ease_in_out", 0)
local bestRadius = scene:circle {
    center = queryPosition, radius = BEST_DISTANCE * SCALE,
    fill = "#00000000", stroke = "result", width = 2.5,
    layer = LAYER.mark - 1, id = "query:best-radius",
}
scene:create(bestRadius, 0.40, "ease_out", 0, "counterclockwise")
scene:wait(0.35)

setStatus(string.format(
    "%.2f and %.2f are both > %.2f  →  prune lower-left and right",
    LEFT_PLANE_DISTANCE,
    ROOT_PLANE_DISTANCE,
    BEST_DISTANCE
), "result")
local lowerLeftPrune = scene:rectangle {
    center = {-320, -55}, size = {140, 140}, fill = "muted", opacity = 0.12,
    stroke = "#00000000", layer = LAYER.region, id = "pruned:lower-left-region",
}
local rightPrune = scene:rectangle {
    center = {-180, 15}, size = {140, 280}, fill = "muted", opacity = 0.12,
    stroke = "#00000000", layer = LAYER.region, id = "pruned:right-region",
}
scene:fade_in(lowerLeftPrune, {duration = 0.30, curve = "gentle"})
scene:fade_in(rightPrune, {duration = 0.30, curve = "gentle"})
scene:play({
    {target = pointHandles.B, opacity = 0.25},
    {target = pointHandles.F, opacity = 0.25},
    {target = pointHandles.E, opacity = 0.25},
    {target = pointHandles.G, opacity = 0.25},
    {target = treeHandles.B, opacity = 0.25},
    {target = treeHandles.F, opacity = 0.25},
    {target = treeHandles.E, opacity = 0.25},
    {target = treeHandles.G, opacity = 0.25},
    {target = edgeHandles["tree-edge:D:lower"], opacity = 0.25},
    {target = edgeHandles["tree-edge:A:right"], opacity = 0.25},
    {target = edgeHandles["tree-edge:F:lower"], opacity = 0.25},
    {target = edgeHandles["tree-edge:F:upper"], opacity = 0.25},
    {target = rightSplit, opacity = 0.25},
}, 0.55, "ease_in_out", 0)

local result = scene:text {
    text = string.format(
        "nearest = C(%g, %g)  ·  spatial distance justifies tree pruning",
        POINTS.C[1],
        POINTS.C[2]
    ),
    point = {0, -232}, role = "text", fill = "result",
    layer = LAYER.text, id = "result:nearest",
}
scene:fade_in(result, {shift = {0, 4}, duration = 0.34, curve = "gentle"})
scene:wait(2.2)
return scene
