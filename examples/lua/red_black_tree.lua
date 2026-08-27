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
    text = "RED-BLACK TREE  |  insert 10, 5, 1",
    point = { 0, 3.55 },
    font = "Pretendard",
    size = 29,
    fill = "#f4f7fb",
    id = "title",
}
local subtitle = scene:text {
    text = "A left-left violation is repaired by one right rotation and recoloring.",
    point = { 0, 3.04 },
    font = "Pretendard",
    size = 15,
    fill = "#91a4b7",
    id = "subtitle",
}

local traceFrame = scene:rectangle {
    center = { -4.52, -0.08 },
    size = { 3.65, 4.7 },
    corner = 0.17,
    fill = "#0d1b2a",
    stroke = "#26394c",
    width = 2,
    layer = -10,
    id = "trace-frame",
}
local treeFrame = scene:rectangle {
    center = { 2.05, -0.08 },
    size = { 8.4, 4.7 },
    corner = 0.17,
    fill = "#0d1b2a",
    stroke = "#26394c",
    width = 2,
    layer = -10,
    id = "tree-frame",
}
local traceTitle = scene:text {
    text = "INSERTION ORDER",
    point = { -4.52, 1.95 },
    font = "Pretendard",
    size = 16,
    fill = "#dbe7f3",
    id = "trace-title",
}
local treeTitle = scene:text {
    text = "LOCAL REPAIR",
    point = { 2.05, 1.95 },
    font = "Pretendard",
    size = 16,
    fill = "#dbe7f3",
    id = "tree-title",
}

local cards = scene:group { matrix = translate(-4.52, 0.82), id = "insertion-cards" }
local cardBodies = {}
for i, value in ipairs { 10, 5, 1 } do
    local card = cards:group { id = "insert-card-" .. value }
    local color = i == 1 and "#91a4b7" or "#ff5d73"
    cardBodies[i] = card:rectangle {
        size = { 0.82, 0.72 },
        corner = 0.11,
        fill = "#132235",
        stroke = color,
        width = 3,
        layer = 2,
        id = "insert-card-" .. value .. "-body",
    }
    card:text {
        text = tostring(value),
        point = { 0, 0 },
        font = "Pretendard",
        size = 19,
        fill = "#f4f7fb",
        layer = 3,
        id = "insert-card-" .. value .. "-label",
    }
end
cards:arrange({ 1, 0, 0 }, 0.18)

local orderHint = scene:text {
    text = "10  ->  5  ->  1",
    point = { -4.52, -0.05 },
    font = "Pretendard",
    size = 17,
    fill = "#91a4b7",
    id = "order-hint",
}
local ruleBlack = scene:text {
    text = "BLACK",
    point = { -5.28, -0.82 },
    font = "Pretendard",
    size = 14,
    fill = "#b9c7d5",
    id = "black-legend",
}
local ruleRed = scene:text {
    text = "RED",
    point = { -3.76, -0.82 },
    font = "Pretendard",
    size = 14,
    fill = "#ff5d73",
    id = "red-legend",
}
local invariant = scene:text {
    text = "No RED  ->  RED edge",
    point = { -4.52, -1.55 },
    font = "Pretendard",
    size = 14,
    fill = "#7f93a8",
    id = "red-parent-invariant",
}

local function treeNode(value, x, y, color)
    local item = scene:group { matrix = translate(x, y), id = "node-" .. value }
    local body = item:circle {
        radius = 0.5,
        fill = color,
        stroke = "#f4f7fb",
        width = 3,
        layer = 2,
        id = "node-" .. value .. "-body",
    }
    item:text {
        text = tostring(value),
        point = { 0, 0 },
        font = "Pretendard",
        size = 21,
        fill = "#ffffff",
        layer = 3,
        id = "node-" .. value .. "-label",
    }
    return item, body
end

local node10, body10 = treeNode(10, 2.7, 1.15, "#263343")
local node5, body5 = treeNode(5, 1.25, -0.15, "#c9364e")
local node1, body1 = treeNode(1, -0.20, -1.45, "#c9364e")

local edge10to5 = scene:connector {
    from = node10,
    to = node5,
    padding = 0.08,
    stroke = "#718399",
    width = 4,
    layer = 1,
    id = "edge-10-5",
}
local edge5to1 = scene:connector {
    from = node5,
    to = node1,
    padding = 0.08,
    stroke = "#718399",
    width = 4,
    layer = 1,
    id = "edge-5-1",
}

local rootBadge = scene:text {
    text = "root",
    point = { 3.42, 1.38 },
    font = "Pretendard",
    size = 13,
    fill = "#91a4b7",
    id = "root-badge-before",
}
local rootBadgeAfter = scene:text {
    text = "new root",
    point = { 3.90, 1.40 },
    font = "Pretendard",
    size = 13,
    fill = "#7bd88f",
    opacity = 0,
    id = "root-badge-after",
}
local violation = scene:text {
    text = "RED parent + RED child",
    point = { 3.60, -1.48 },
    font = "Pretendard",
    size = 16,
    fill = "#ff5d73",
    opacity = 0,
    id = "red-red-violation",
}
local repair = scene:text {
    text = "rotateRight(10)  +  recolor",
    point = { 2.05, -2.12 },
    font = "Pretendard",
    size = 18,
    fill = "#ffd166",
    opacity = 0,
    id = "repair-operation",
}
local repaired = scene:text {
    text = "Valid: black root, no red-red edge, equal black height",
    point = { 2.05, -2.12 },
    font = "Pretendard",
    size = 16,
    fill = "#7bd88f",
    opacity = 0,
    id = "repair-result",
}

for _, item in ipairs {
    title,
    subtitle,
    traceFrame,
    treeFrame,
    traceTitle,
    treeTitle,
    cards,
    orderHint,
    ruleBlack,
    ruleRed,
    invariant,
} do
    scene:fade_in(item, { shift = { 0, 0.10 }, duration = 0.07, curve = "snappy" })
end

scene:grow_from_center(node10, 0.28, { preset = "back", strength = 0.55 })
scene:fade_in(rootBadge, { shift = { -0.12, 0 }, duration = 0.14, curve = "snappy" })
scene:play({
    { target = cardBodies[1], fill = "#283b50", stroke = "#ffd166" },
    { target = body10, stroke = "#ffd166" },
}, 0.38, "ease_out", 0)

scene:create(edge10to5, 0.25, "linear")
scene:grow_from_center(node5, 0.26, { preset = "back", strength = 0.55 })
scene:play({
    { target = cardBodies[1], fill = "#132235", stroke = "#91a4b7" },
    { target = cardBodies[2], fill = "#512535", stroke = "#ffd166" },
    { target = body10, stroke = "#f4f7fb" },
    { target = body5, stroke = "#ffd166" },
}, 0.38, "ease_out", 0)

scene:create(edge5to1, 0.25, "linear")
scene:grow_from_center(node1, 0.26, { preset = "back", strength = 0.55 })
scene:play({
    { target = cardBodies[2], fill = "#132235", stroke = "#ff5d73" },
    { target = cardBodies[3], fill = "#512535", stroke = "#ffd166" },
    { target = body5, stroke = "#ff5d73" },
    { target = body1, stroke = "#ffd166" },
    { target = edge5to1, stroke = "#ff5d73" },
    { target = violation, opacity = 1 },
    { target = repair, opacity = 1 },
}, 0.50, "ease_in_out", 0)

scene:play({
    { target = rootBadge, opacity = 0 },
    { target = violation, opacity = 0 },
    { target = repair, opacity = 0 },
}, 0.24, "ease_out", 0)

scene:play({
    { target = node5, shift = { 1.45, 1.30 } },
    { target = node1, shift = { 1.45, 1.30 } },
    { target = node10, shift = { 1.45, -1.30 } },
    { target = body5, fill = "#263343", stroke = "#f4f7fb" },
    { target = body10, fill = "#c9364e", stroke = "#f4f7fb" },
    { target = body1, stroke = "#f4f7fb" },
    { target = edge5to1, stroke = "#718399" },
    { target = cardBodies[1], fill = "#512535", stroke = "#ff5d73" },
    { target = cardBodies[2], fill = "#283b50", stroke = "#91a4b7" },
    { target = cardBodies[3], fill = "#512535", stroke = "#ff5d73" },
}, 0.96, "ease_in_out", 0)

scene:play({
    { target = rootBadgeAfter, opacity = 1 },
    { target = repaired, opacity = 1 },
}, 0.32, "ease_out", 0)
scene:wait(0.75)

return scene
