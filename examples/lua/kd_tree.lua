local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    background = "#081018",
    camera = { mode = "fixed", view = "2d", height = 8 },
}

local function translate(x, y)
    return {
        1,
        0,
        0,
        x,
        0,
        1,
        0,
        y,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        1,
    }
end

local title = scene:text {
    text = "KD-TREE  |  partition, index, search",
    point = { 0, 3.55 },
    font = "Pretendard",
    size = 29,
    fill = "#f4f7fb",
    id = "title",
}
local subtitle = scene:text {
    text = "The same color names the split in space and the decision in the tree.",
    point = { 0, 3.04 },
    font = "Pretendard",
    size = 15,
    fill = "#91a4b7",
    id = "subtitle",
}

local spatialFrame = scene:rectangle {
    center = { -4.05, -0.05 },
    size = { 5.35, 4.65 },
    corner = 0.17,
    fill = "#0d1b2a",
    stroke = "#26394c",
    width = 2,
    layer = -10,
    id = "spatial-frame",
}
local treeFrame = scene:rectangle {
    center = { 3.35, -0.05 },
    size = { 5.7, 4.65 },
    corner = 0.17,
    fill = "#0d1b2a",
    stroke = "#26394c",
    width = 2,
    layer = -10,
    id = "tree-frame",
}
local spatialTitle = scene:text {
    text = "2D POINT SET",
    point = { -4.05, 1.94 },
    font = "Pretendard",
    size = 16,
    fill = "#dbe7f3",
    id = "spatial-title",
}
local treeTitle = scene:text {
    text = "ALTERNATING x / y DECISIONS",
    point = { 3.35, 1.94 },
    font = "Pretendard",
    size = 16,
    fill = "#dbe7f3",
    id = "tree-title",
}

local xLegend = scene:text {
    text = "x split",
    point = { -5.15, 2.47 },
    font = "Pretendard",
    size = 14,
    fill = "#ff6b6b",
    id = "x-legend",
}
local yLegend = scene:text {
    text = "y split",
    point = { -3.85, 2.47 },
    font = "Pretendard",
    size = 14,
    fill = "#4cc9f0",
    id = "y-legend",
}
local queryLegend = scene:text {
    text = "query",
    point = { -2.65, 2.47 },
    font = "Pretendard",
    size = 14,
    fill = "#ffd166",
    id = "query-legend",
}
local nearestLegend = scene:text {
    text = "nearest",
    point = { -1.72, 2.47 },
    font = "Pretendard",
    size = 14,
    fill = "#7bd88f",
    id = "nearest-legend",
}

local function spatialPoint(name, coordinate, x, y, color)
    local item = scene:group { matrix = translate(x, y), id = "point-" .. name }
    local body = item:circle {
        radius = 0.16,
        fill = "#101b29",
        stroke = color,
        width = 3,
        layer = 2,
        id = "point-" .. name .. "-body",
    }
    item:text {
        text = name,
        point = { 0.29, 0.22 },
        font = "Pretendard",
        size = 13,
        fill = color,
        layer = 3,
        id = "point-" .. name .. "-label",
    }
    item:text {
        text = coordinate,
        point = { 0.34, -0.16 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 11,
        fill = "#7f93a8",
        layer = 3,
        id = "point-" .. name .. "-coordinate",
    }
    return item, body
end

local pointA, pointABody = spatialPoint("A", "(5,4)", -4.05, -0.64, "#ff6b6b")
local pointD, pointDBody = spatialPoint("D", "(1,5)", -5.96, -0.24, "#4cc9f0")
local pointF, pointFBody = spatialPoint("F", "(8,6)", -2.62, 0.16, "#4cc9f0")
local pointB, pointBBody = spatialPoint("B", "(2,3)", -5.48, -1.04, "#91a4b7")
local pointC, pointCBody = spatialPoint("C", "(4,7)", -4.53, 0.56, "#91a4b7")
local pointE, pointEBody = spatialPoint("E", "(7,2)", -3.10, -1.44, "#91a4b7")
local pointG, pointGBody = spatialPoint("G", "(6,8)", -3.57, 0.96, "#91a4b7")
local allPoints = { pointA, pointD, pointF, pointB, pointC, pointE, pointG }

local rootSplit = scene:line {
    from = { -4.05, -2.15 },
    to = { -4.05, 1.65 },
    stroke = "#ff6b6b",
    width = 4,
    layer = 1,
    id = "split-x-5",
}
local leftSplit = scene:line {
    from = { -6.42, -0.24 },
    to = { -4.05, -0.24 },
    stroke = "#4cc9f0",
    width = 4,
    layer = 1,
    id = "split-y-5-left",
}
local rightSplit = scene:line {
    from = { -4.05, 0.16 },
    to = { -1.68, 0.16 },
    stroke = "#4cc9f0",
    width = 4,
    layer = 1,
    id = "split-y-6-right",
}

local function treeNode(name, coordinate, x, y, color)
    local item = scene:group { matrix = translate(x, y), id = "node-" .. name }
    local body = item:circle {
        radius = 0.41,
        fill = "#132235",
        stroke = color,
        width = 3,
        layer = 2,
        id = "node-" .. name .. "-body",
    }
    item:text {
        text = name,
        point = { 0, 0 },
        font = "Pretendard",
        size = 19,
        fill = "#f4f7fb",
        layer = 3,
        id = "node-" .. name .. "-label",
    }
    local caption = scene:text {
        text = coordinate,
        point = { x, y - 0.58 },
        font = "Pretendard",
        size = 11,
        fill = "#7f93a8",
        layer = 3,
        id = "node-" .. name .. "-coordinate",
    }
    return item, body, caption
end

local nodeA, nodeABody, nodeACaption = treeNode("A", "x = 5", 3.35, 1.23, "#ff6b6b")
local nodeD, nodeDBody, nodeDCaption = treeNode("D", "y = 5", 1.85, 0.02, "#4cc9f0")
local nodeF, nodeFBody, nodeFCaption = treeNode("F", "y = 6", 4.85, 0.02, "#4cc9f0")
local nodeB, nodeBBody, nodeBCaption = treeNode("B", "(2,3)", 1.12, -1.45, "#91a4b7")
local nodeC, nodeCBody, nodeCCaption = treeNode("C", "(4,7)", 2.58, -1.45, "#91a4b7")
local nodeE, nodeEBody, nodeECaption = treeNode("E", "(7,2)", 4.12, -1.45, "#91a4b7")
local nodeG, nodeGBody, nodeGCaption = treeNode("G", "(6,8)", 5.58, -1.45, "#91a4b7")

local edgeAD = scene:connector {
    from = nodeA,
    to = nodeD,
    padding = 0.06,
    stroke = "#ff6b6b",
    width = 3,
    layer = 1,
    id = "edge-a-d",
}
local edgeAF = scene:connector {
    from = nodeA,
    to = nodeF,
    padding = 0.06,
    stroke = "#ff6b6b",
    width = 3,
    layer = 1,
    id = "edge-a-f",
}
local edgeDB = scene:connector {
    from = nodeD,
    to = nodeB,
    padding = 0.06,
    stroke = "#4cc9f0",
    width = 3,
    layer = 1,
    id = "edge-d-b",
}
local edgeDC = scene:connector {
    from = nodeD,
    to = nodeC,
    padding = 0.06,
    stroke = "#4cc9f0",
    width = 3,
    layer = 1,
    id = "edge-d-c",
}
local edgeFE = scene:connector {
    from = nodeF,
    to = nodeE,
    padding = 0.06,
    stroke = "#4cc9f0",
    width = 3,
    layer = 1,
    id = "edge-f-e",
}
local edgeFG = scene:connector {
    from = nodeF,
    to = nodeG,
    padding = 0.06,
    stroke = "#4cc9f0",
    width = 3,
    layer = 1,
    id = "edge-f-g",
}

local query = scene:group {
    matrix = translate(-5.00, 0.96),
    opacity = 0,
    id = "query-q",
}
query:circle {
    radius = 0.21,
    fill = "#ffd16633",
    stroke = "#ffd166",
    width = 4,
    layer = 2,
    id = "query-q-body",
}
query:text {
    text = "Q(3,8)",
    point = { -0.08, 0.34 },
    font = "Pretendard",
    size = 13,
    fill = "#ffd166",
    layer = 3,
    id = "query-q-label",
}

local status1 = scene:text {
    text = "Q.x < 5  ->  visit the left subtree",
    point = { 0, -2.80 },
    font = "Pretendard",
    size = 17,
    fill = "#ffd166",
    opacity = 0,
    id = "search-step-x",
}
local status2 = scene:text {
    text = "Q.y > 5  ->  visit D's upper branch",
    point = { 0, -2.80 },
    font = "Pretendard",
    size = 17,
    fill = "#ffd166",
    opacity = 0,
    id = "search-step-y",
}
local status3 = scene:text {
    text = "C(4,7), d = sqrt(2)   |   both split planes prune",
    point = { 0, -2.80 },
    font = "Pretendard",
    size = 17,
    fill = "#7bd88f",
    opacity = 0,
    id = "search-result",
}

for _, item in ipairs {
    title,
    subtitle,
    spatialFrame,
    treeFrame,
    spatialTitle,
    treeTitle,
    xLegend,
    yLegend,
    queryLegend,
    nearestLegend,
} do
    scene:fade_in(item, { shift = { 0, 0.10 }, duration = 0.07, curve = "snappy" })
end
for _, point in ipairs(allPoints) do
    scene:grow_from_center(point, 0.08, { preset = "back", strength = 0.40 })
end

scene:create(rootSplit, 0.28, "linear")
scene:grow_from_center(nodeA, 0.22, { preset = "back", strength = 0.55 })
scene:fade_in(nodeACaption, { shift = { 0, 0.10 }, duration = 0.12, curve = "snappy" })

scene:create({ leftSplit, rightSplit, edgeAD, edgeAF }, 0.36, "linear", 0.05)
for _, node in ipairs { nodeD, nodeF } do
    scene:grow_from_center(node, 0.16, { preset = "back", strength = 0.50 })
end
for _, caption in ipairs { nodeDCaption, nodeFCaption } do
    scene:fade_in(caption, { shift = { 0, 0.08 }, duration = 0.09, curve = "snappy" })
end

scene:create({ edgeDB, edgeDC, edgeFE, edgeFG }, 0.34, "linear", 0.045)
for _, node in ipairs { nodeB, nodeC, nodeE, nodeG } do
    scene:grow_from_center(node, 0.11, { preset = "back", strength = 0.42 })
end
for _, caption in ipairs { nodeBCaption, nodeCCaption, nodeECaption, nodeGCaption } do
    scene:fade_in(caption, { shift = { 0, 0.07 }, duration = 0.07, curve = "snappy" })
end

scene:play({
    { target = query, opacity = 1 },
    { target = status1, opacity = 1 },
    { target = pointABody, fill = "#6c4b1f", stroke = "#ffd166" },
    { target = nodeABody, fill = "#6c4b1f", stroke = "#ffd166" },
    { target = rootSplit, stroke = "#ffd166" },
}, 0.62, "ease_in_out", 0)
scene:wait(0.22)
scene:play({ { target = status1, opacity = 0 } }, 0.16, "ease_out", 0)

scene:play({
    { target = status2, opacity = 1 },
    { target = pointABody, fill = "#101b29", stroke = "#ff6b6b" },
    { target = nodeABody, fill = "#132235", stroke = "#ff6b6b" },
    { target = rootSplit, stroke = "#ff6b6b" },
    { target = pointDBody, fill = "#6c4b1f", stroke = "#ffd166" },
    { target = nodeDBody, fill = "#6c4b1f", stroke = "#ffd166" },
    { target = leftSplit, stroke = "#ffd166" },
    { target = edgeAD, stroke = "#ffd166" },
}, 0.62, "ease_in_out", 0)
scene:wait(0.22)
scene:play({ { target = status2, opacity = 0 } }, 0.16, "ease_out", 0)

scene:play({
    { target = status3, opacity = 1 },
    { target = pointDBody, fill = "#101b29", stroke = "#4cc9f0" },
    { target = nodeDBody, fill = "#132235", stroke = "#4cc9f0" },
    { target = leftSplit, stroke = "#4cc9f0" },
    { target = pointCBody, fill = "#214d3d", stroke = "#7bd88f" },
    { target = nodeCBody, fill = "#214d3d", stroke = "#7bd88f" },
    { target = edgeDC, stroke = "#7bd88f" },
}, 0.68, "ease_in_out", 0)
scene:wait(0.65)

return scene
