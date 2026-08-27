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
    slot = "#10182b",
    outline = "#42526b",
    left = "#4cc9f0",
    leftFill = "#17384a",
    right = "#f07178",
    rightFill = "#3d2535",
    active = "#c77dff",
    activeFill = "#53356f",
    output = "#7bd88f",
    outputFill = "#1f5343",
}

local title = scene:text {
    text = "MERGE SORT",
    point = { 0, 2.55 },
    font = "Pretendard",
    size = 32,
    fill = colors.text,
    id = "title",
}
local subtitle = scene:text {
    text = "compare both run heads, then emit the smaller value",
    point = { 0, 2.08 },
    font = "Pretendard",
    size = 19,
    fill = colors.muted,
    id = "merge-rule",
}
local leftLabel = scene:text {
    text = "LEFT RUN  [2, 6, 8]",
    point = { -2.55, 1.5 },
    font = "Pretendard",
    size = 19,
    fill = colors.left,
    id = "left-run-label",
}
local rightLabel = scene:text {
    text = "RIGHT RUN  [1, 3, 7]",
    point = { 2.55, 1.5 },
    font = "Pretendard",
    size = 19,
    fill = colors.right,
    id = "right-run-label",
}
local outputLabel = scene:text {
    text = "OUTPUT BUFFER",
    point = { 0, -0.55 },
    font = "Pretendard",
    size = 19,
    fill = colors.output,
    id = "output-label",
}
local hint = scene:text {
    text = "purple = comparing     green = emitted",
    point = { 0, -2.32 },
    font = "Pretendard",
    size = 17,
    fill = colors.muted,
    id = "merge-hint",
}
local result = scene:text {
    text = "merged:  [1, 2, 3, 6, 7, 8]",
    point = { 0, -1.85 },
    font = "Pretendard",
    size = 21,
    fill = colors.output,
    id = "merged-result",
}

local function makeCell(value, x, color, fill, run)
    local cell = scene:group {
        matrix = translate(x, 0.65),
        id = run .. "-value-" .. value,
    }
    local body = cell:rectangle {
        size = { 1.02, 0.76 },
        corner = 0.12,
        fill = fill,
        stroke = color,
        width = 3,
        id = run .. "-value-" .. value .. "-body",
    }
    cell:text {
        text = tostring(value),
        point = { 0, 0 },
        font = "Pretendard",
        size = 24,
        fill = colors.text,
        id = run .. "-value-" .. value .. "-text",
    }
    return cell, body
end

local leftCells, leftBodies = {}, {}
local rightCells, rightBodies = {}, {}
local leftValues = { 2, 6, 8 }
local rightValues = { 1, 3, 7 }
local inputX = { -3.7, -2.55, -1.4 }
local reveal = { title, subtitle, leftLabel, rightLabel, outputLabel, hint }
local outputX = { -3.0, -1.8, -0.6, 0.6, 1.8, 3.0 }
for i, x in ipairs(outputX) do
    reveal[#reveal + 1] = scene:rectangle {
        center = { x, -1.2 },
        size = { 1.02, 0.76 },
        corner = 0.12,
        fill = colors.slot,
        stroke = colors.outline,
        width = 2,
        id = "output-slot-" .. i,
    }
end

for i, value in ipairs(leftValues) do
    leftCells[i], leftBodies[i] = makeCell(value, inputX[i], colors.left, colors.leftFill, "left")
    reveal[#reveal + 1] = leftCells[i]
end
for i, value in ipairs(rightValues) do
    rightCells[i], rightBodies[i] =
        makeCell(value, -inputX[4 - i], colors.right, colors.rightFill, "right")
    reveal[#reveal + 1] = rightCells[i]
end

for _, item in ipairs(reveal) do
    scene:fade_in(item, {
        shift = { 0, 0.15 },
        scale = 0.96,
        duration = 0.09,
        curve = { preset = "snappy", strength = 0.78 },
    })
end

local function compare(leftBody, rightBody)
    scene:play({
        { target = leftBody, fill = colors.activeFill, stroke = colors.active },
        { target = rightBody, fill = colors.activeFill, stroke = colors.active },
    }, 0.22, "ease_in_out", 0)
end

local function emit(winner, winnerBody, loserBody, loserFill, loserStroke, shift)
    scene:play({
        { target = winner, shift = shift },
        { target = winnerBody, fill = colors.outputFill, stroke = colors.output },
        { target = loserBody, fill = loserFill, stroke = loserStroke },
    }, 0.38, "ease_out", 0)
end

compare(leftBodies[1], rightBodies[1])
emit(rightCells[1], rightBodies[1], leftBodies[1], colors.leftFill, colors.left, { -4.4, -1.85 })

compare(leftBodies[1], rightBodies[2])
emit(leftCells[1], leftBodies[1], rightBodies[2], colors.rightFill, colors.right, { 1.9, -1.85 })

compare(leftBodies[2], rightBodies[2])
emit(rightCells[2], rightBodies[2], leftBodies[2], colors.leftFill, colors.left, { -3.15, -1.85 })

compare(leftBodies[2], rightBodies[3])
emit(leftCells[2], leftBodies[2], rightBodies[3], colors.rightFill, colors.right, { 3.15, -1.85 })

compare(leftBodies[3], rightBodies[3])
emit(rightCells[3], rightBodies[3], leftBodies[3], colors.leftFill, colors.left, { -1.9, -1.85 })

scene:play({
    { target = leftBodies[3], fill = colors.activeFill, stroke = colors.active },
}, 0.22, "ease_in_out", 0)
scene:play({
    { target = leftCells[3], shift = { 4.4, -1.85 } },
    { target = leftBodies[3], fill = colors.outputFill, stroke = colors.output },
}, 0.38, "ease_out", 0)

scene:fade_in(result, { shift = { 0, -0.18 }, duration = 0.28, curve = "snappy" })
scene:wait(0.6)

return scene
