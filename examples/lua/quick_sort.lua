local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    background = "#0b1020",
    camera = { mode = "fixed", view = "2d", height = 6 },
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

local colors = {
    text = "#f4f7fb",
    muted = "#8b9bb4",
    surface = "#17233d",
    outline = "#42526b",
    active = "#c77dff",
    activeFill = "#53356f",
    pivot = "#ffd166",
    pivotFill = "#62501f",
    less = "#4cc9f0",
    lessFill = "#17445a",
    greater = "#f07178",
    greaterFill = "#4a2635",
    sorted = "#7bd88f",
    sortedFill = "#1f5343",
}

local title = scene:text {
    text = "QUICK SORT",
    point = { 0, 2.55 },
    font = "Pretendard",
    size = 32,
    fill = colors.text,
    id = "title",
}
local subtitle = scene:text {
    text = "partition around pivot = 4",
    point = { 0, 2.08 },
    font = "Pretendard",
    size = 20,
    fill = colors.pivot,
    id = "pivot-equation",
}
local greaterLabel = scene:text {
    text = "> pivot",
    point = { -4.25, 1.35 },
    font = "Pretendard",
    size = 18,
    fill = colors.greater,
    id = "greater-label",
}
local lessLabel = scene:text {
    text = "<= pivot",
    point = { -4.25, -0.45 },
    font = "Pretendard",
    size = 18,
    fill = colors.less,
    id = "less-label",
}
local hint = scene:text {
    text = "compare  |  classify  |  place pivot  |  recurse",
    point = { 0, -2.25 },
    font = "Pretendard",
    size = 18,
    fill = colors.muted,
    id = "algorithm-hint",
}
local partition = scene:text {
    text = "partition:  [2, 3]   4   [6, 8, 7]",
    point = { 0, -1.42 },
    font = "Pretendard",
    size = 21,
    fill = colors.pivot,
    id = "partition-result",
}
local recurse = scene:text {
    text = "recurse on the left and right partitions",
    point = { 0, -1.82 },
    font = "Pretendard",
    size = 18,
    fill = colors.muted,
    id = "recurse-label",
}
local result = scene:text {
    text = "sorted:  2   3   4   6   7   8",
    point = { 0, -1.42 },
    font = "Pretendard",
    size = 21,
    fill = colors.sorted,
    id = "sorted-result",
}

local values = { 6, 2, 8, 3, 7, 4 }
local cells = {}
local bodies = {}
local reveal = { title, subtitle, greaterLabel, lessLabel, hint }
local startX = -2.875
local step = 1.15

for i, value in ipairs(values) do
    local cell = scene:group {
        matrix = translate(startX + (i - 1) * step, 0.45),
        id = "value-" .. value,
    }
    local body = cell:rectangle {
        size = { 0.98, 0.78 },
        corner = 0.12,
        fill = colors.surface,
        stroke = colors.outline,
        width = 3,
        id = "value-" .. value .. "-body",
    }
    cell:text {
        text = tostring(value),
        point = { 0, 0 },
        font = "Pretendard",
        size = 25,
        fill = colors.text,
        id = "value-" .. value .. "-text",
    }
    cells[i] = cell
    bodies[i] = body
    reveal[#reveal + 1] = cell
end

for _, item in ipairs(reveal) do
    scene:fade_in(item, {
        shift = { 0, 0.16 },
        scale = 0.96,
        duration = 0.10,
        curve = { preset = "snappy", strength = 0.80 },
    })
end
scene:play({
    { target = bodies[6], fill = colors.pivotFill, stroke = colors.pivot },
    { target = cells[6], shift = { 0, 0.12 } },
}, 0.4, "ease_out", 0)

local function classify(index, isLess)
    scene:play({
        { target = bodies[index], fill = colors.activeFill, stroke = colors.active },
        { target = bodies[6], fill = colors.pivotFill, stroke = colors.pivot },
    }, 0.22, "ease_in_out", 0)

    scene:play({
        {
            target = bodies[index],
            fill = isLess and colors.lessFill or colors.greaterFill,
            stroke = isLess and colors.less or colors.greater,
        },
        { target = cells[index], shift = { 0, isLess and -0.9 or 0.9 } },
    }, 0.32, "ease_out", 0)
end

classify(1, false)
classify(2, true)
classify(3, false)
classify(4, true)
classify(5, false)

scene:fade_in(partition, { shift = { 0, -0.16 }, duration = 0.24, curve = "snappy" })

scene:play({
    { target = cells[1], shift = { 3.45, 0 } },
    { target = cells[2], shift = { -1.15, 0 } },
    { target = cells[3], shift = { 2.3, 0 } },
    { target = cells[4], shift = { -2.3, 0 } },
    { target = cells[5], shift = { 1.15, 0 } },
    { target = cells[6], shift = { -3.45, 0 } },
}, 0.8, "ease_in_out", 0)
scene:play({
    { target = cells[1], shift = { 0, -0.9 } },
    { target = cells[2], shift = { 0, 0.9 } },
    { target = cells[3], shift = { 0, -0.9 } },
    { target = cells[4], shift = { 0, 0.9 } },
    { target = cells[5], shift = { 0, -0.9 } },
    { target = cells[6], shift = { 0, -0.12 } },
}, 0.48, "ease_in_out", 0)

scene:fade_in(recurse, { shift = { 0, -0.14 }, duration = 0.22, curve = "gentle" })
scene:play({
    { target = cells[3], shift = { 1.15, 0 } },
    { target = cells[5], shift = { -1.15, 0 } },
    { target = bodies[1], fill = colors.sortedFill, stroke = colors.sorted },
    { target = bodies[2], fill = colors.sortedFill, stroke = colors.sorted },
    { target = bodies[3], fill = colors.sortedFill, stroke = colors.sorted },
    { target = bodies[4], fill = colors.sortedFill, stroke = colors.sorted },
    { target = bodies[5], fill = colors.sortedFill, stroke = colors.sorted },
    { target = bodies[6], fill = colors.sortedFill, stroke = colors.sorted },
}, 0.72, "ease_in_out", 0)

scene:fade(partition, 0, 0.2, "ease_out")
scene:fade_in(result, { shift = { 0, -0.18 }, duration = 0.28, curve = "snappy" })
scene:wait(0.55)

return scene
