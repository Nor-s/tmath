local scene = tmath.scene {
    width = 960,
    height = 540,
    background = "#0b1020",
    camera = { view = "2d", height = 8 },
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
    text = "Shape composition for algorithms",
    point = { 0, 3.35 },
    size = 30,
    fill = "#f4f7fb",
    id = "title",
}

local buffer = scene:group { matrix = translate(-2.5, -2.15), id = "buffer" }
local values = { 8, 3, 6, 1, 7 }
local cells = {}
local cellBodies = {}
for i, value in ipairs(values) do
    local cell = buffer:group { id = "cell-" .. i }
    local body = cell:rectangle {
        size = { 1.25, 0.9 },
        corner = 0.12,
        fill = "#17233d",
        stroke = "#4cc9f0",
        width = 3,
        id = "cell-body-" .. i,
    }
    cell:text {
        text = tostring(value),
        point = { 0, 0 },
        size = 25,
        fill = "#f4f7fb",
        id = "cell-value-" .. i,
    }
    cells[i] = cell
    cellBodies[i] = body
end
buffer:arrange({ 1, 0, 0 }, 0.18)

local tree = scene:group { matrix = translate(2.4, 0.65), id = "tree" }
local function node(name, value, x, y, color)
    local item = tree:group { matrix = translate(x, y), id = name }
    local body = item:circle {
        radius = 0.52,
        fill = color,
        stroke = "#f4f7fb",
        width = 3,
        id = name .. "-body",
    }
    item:text {
        text = tostring(value),
        point = { 0, 0 },
        size = 23,
        fill = "#ffffff",
        id = name .. "-value",
    }
    return item, body
end

local root, rootBody = node("root", 8, 0, 1.55, "#343a52")
local left, leftBody = node("left", 3, -1.45, 0, "#d1495b")
local right, rightBody = node("right", 12, 1.45, 0, "#343a52")
local leaf, leafBody = node("leaf", 1, -2.15, -1.45, "#d1495b")

tree:connector {
    from = root,
    to = left,
    padding = 0.08,
    stroke = "#8b9bb4",
    width = 3,
    id = "edge-root-left",
}
tree:connector {
    from = root,
    to = right,
    padding = 0.08,
    stroke = "#8b9bb4",
    width = 3,
    id = "edge-root-right",
}
tree:connector {
    from = left,
    to = leaf,
    padding = 0.08,
    stroke = "#8b9bb4",
    width = 3,
    id = "edge-left-leaf",
}

scene:fade_in(title, {
    shift = { 0, 0.18 },
    duration = 0.28,
    curve = "snappy",
})
scene:fade_in(buffer, {
    shift = { -0.30, 0 },
    scale = 0.96,
    duration = 0.42,
    curve = { preset = "snappy", strength = 0.85 },
})
scene:fade_in(tree, {
    shift = { 0.30, 0 },
    scale = 0.94,
    duration = 0.46,
    curve = { preset = "back", strength = 0.45 },
})
scene:play({
    { target = cellBodies[4], fill = "#f4a261", stroke = "#ffd166" },
    { target = rootBody, fill = "#d1495b" },
    { target = rightBody, fill = "#d1495b" },
}, 0.55, "ease_in_out", 0.08)

scene:play({
    { target = cells[2], shift = { 2.86, 0.35 }, opacity = 0.8 },
    { target = cells[4], shift = { -2.86, 0.35 }, opacity = 0.8 },
    { target = left, shift = { 0.55, 0.35 } },
    { target = right, shift = { -0.35, -0.2 } },
    { target = leaf, shift = { 0.8, 0.15 } },
    { target = leftBody, fill = "#343a52" },
    { target = leafBody, fill = "#d1495b" },
}, 1.0, "ease_in_out", 0)

scene:play({
    { target = cells[2], shift = { 0, -0.35 }, opacity = 1 },
    { target = cells[4], shift = { 0, -0.35 }, opacity = 1 },
    { target = cellBodies[2], fill = "#2a9d8f", stroke = "#7bd88f" },
    { target = cellBodies[4], fill = "#17233d", stroke = "#4cc9f0" },
}, 0.45, "smooth", 0.04)
scene:wait(0.5)

return scene
