-- local question: How are visible pixels stored when plane stride exceeds image width?
-- visible input: one 6 x 4, 8-bit I420-like frame with aligned row strides
-- subject object or field: literal Y, U, and V plane storage including row padding
-- one dominant action: expand visible plane dimensions into byte ranges using linesize
-- observable output: exact plane offsets and a 48-byte backing-buffer layout
-- coordinate frame and units: cells are bytes; offsets and linesizes are byte counts
-- section bounds supplied by the parent: standalone 960 x 540 wrapper
-- final readable pose: colored planes, visible rectangles, padding, stride, and offsets

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "3_blue_1_eyes",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local LAYER = {cell = 0, outline = 20, text = 40}
local figure = scene:group {id = "video-frame-buffer-figure"}

local function text(parent, id, value, point, role, fill, align)
    return parent:text {
        id = id, text = value, point = point, role = role or "code",
        fill = fill or "foreground", align = align or {0.5, 0.5}, layer = LAYER.text,
    }
end

local function clampByte(value)
    return math.max(0, math.min(255, math.floor(value + 0.5)))
end

local function gray(value)
    local byte = clampByte(value)
    return string.format("#%02x%02x%02xff", byte, byte, byte)
end

local function blueChroma(value)
    local delta = value - 128
    return string.format(
        "#%02x%02x%02xff",
        clampByte(132 - 0.15 * delta), clampByte(142 - 0.35 * delta), clampByte(158 + 0.72 * delta)
    )
end

local function redChroma(value)
    local delta = value - 128
    return string.format(
        "#%02x%02x%02xff",
        clampByte(158 + 0.72 * delta), clampByte(142 - 0.35 * delta), clampByte(132 - 0.15 * delta)
    )
end

local width, height = 6, 4
local chromaWidth, chromaHeight = math.ceil(width / 2), math.ceil(height / 2)
local strideY, strideU, strideV = 8, 4, 4
local sizeY = strideY * height
local sizeU = strideU * chromaHeight
local sizeV = strideV * chromaHeight
local offsetY, offsetU, offsetV = 0, sizeY, sizeY + sizeU
local totalBytes = sizeY + sizeU + sizeV

local yValues, uValues, vValues = {}, {}, {}
for row = 0, height - 1 do
    for column = 0, width - 1 do
        yValues[row * width + column + 1] = 46 + 23 * column + 17 * row
    end
end
for row = 0, chromaHeight - 1 do
    for column = 0, chromaWidth - 1 do
        local index = row * chromaWidth + column + 1
        uValues[index] = 82 + 30 * column + 16 * row
        vValues[index] = 172 - 24 * column + 12 * row
    end
end

local claim = text(
    figure, "video-frame-buffer-claim",
    "A video plane is addressed by row stride, not visible width alone",
    {0, 2.62}, "h3"
)
local contract = text(
    figure, "video-frame-buffer-contract",
    string.format("8-bit planar 4:2:0 example · visible %d x %d · positive linesizes", width, height),
    {0, 2.18}, "code", "muted"
)

local function makePlane(id, values, visibleColumns, rows, stride, center, scale, colorForValue)
    local space = figure:space {
        id = id .. "-space", x = {0, stride - 1, 1}, y = {0, rows - 1, 1}, opacity = 0,
        matrix = {
            scale, 0, 0, center[1] - (stride - 1) * scale / 2,
            0, scale, 0, center[2] - (rows - 1) * scale / 2,
            0, 0, 1, 0,
            0, 0, 0, 1,
        },
    }
    local patches = {}
    for row = 0, rows - 1 do
        for column = 0, stride - 1 do
            local color = "surface"
            if column < visibleColumns then
                color = colorForValue(values[row * visibleColumns + column + 1])
            end
            patches[#patches + 1] = {region = {column, row, 1, 1}, color = color}
        end
    end
    local cell = space:cell {
        id = id .. "-cell", origin = {-0.5, -0.5}, size = {stride, rows},
        mode = "padd", padding = 0.045, color = "surface", patches = patches,
        layer = LAYER.cell,
    }
    local visible = space:rectangle {
        id = id .. "-visible", center = {(visibleColumns - 1) / 2, (rows - 1) / 2},
        size = {visibleColumns, rows}, fill = "#00000000", stroke = "focus",
        width = 2.4, layer = LAYER.outline,
    }
    local padding = nil
    if stride > visibleColumns then
        padding = space:rectangle {
            id = id .. "-padding", center = {(visibleColumns + stride - 1) / 2, (rows - 1) / 2},
            size = {stride - visibleColumns, rows}, fill = "#00000000", stroke = "warning",
            width = 2.0, dash = {5, 3}, layer = LAYER.outline,
        }
    end
    return {space = space, cell = cell, visible = visible, padding = padding}
end

local yPlane = makePlane("video-frame-y", yValues, width, height, strideY, {-2.55, 0.35}, 0.48, gray)
local uPlane = makePlane("video-frame-u", uValues, chromaWidth, chromaHeight, strideU, {2.55, 0.83}, 0.55, blueChroma)
local vPlane = makePlane("video-frame-v", vValues, chromaWidth, chromaHeight, strideV, {2.55, -0.52}, 0.55, redChroma)

local yLabel = text(
    figure, "video-frame-y-label",
    string.format("Y plane · visible %d x %d · linesize[0] = %d", width, height, strideY),
    {-2.55, 1.55}, "code", "info"
)
local uLabel = text(
    figure, "video-frame-u-label",
    string.format("U · visible %d x %d · stride %d", chromaWidth, chromaHeight, strideU),
    {2.55, 1.55}, "code", "info"
)
local vLabel = text(
    figure, "video-frame-v-label",
    string.format("V · visible %d x %d · stride %d", chromaWidth, chromaHeight, strideV),
    {2.55, 0.16}, "code", "warning"
)
local paddingLabel = text(
    figure, "video-frame-padding-label",
    "pad",
    {-1.11, 0.35}, "code", "warning"
)

local yLeft = -2.55 - strideY * 0.48 / 2
local yRight = -2.55 + strideY * 0.48 / 2
local strideRuler = figure:ruler {
    id = "video-frame-stride-ruler", from = {yLeft, -0.89}, to = {yRight, -0.89},
    step = 0.48, tick = 7, stroke = "result", width = 2.1, layer = LAYER.outline,
}
local strideLabel = text(
    figure, "video-frame-stride-label",
    string.format("one stored Y row = %d bytes", strideY),
    {-2.55, -1.18}, "code", "result"
)

local memoryY = -1.68
local memorySpecs = {
    {name = "Y", offset = offsetY, size = sizeY, x = -2.80, color = "info"},
    {name = "U", offset = offsetU, size = sizeU, x = 0, color = "focus"},
    {name = "V", offset = offsetV, size = sizeV, x = 2.80, color = "warning"},
}
local memory = figure:group {id = "video-frame-backing-memory"}
for index, item in ipairs(memorySpecs) do
    memory:rectangle {
        id = string.format("video-frame-memory-%02d-body", index),
        center = {item.x, memoryY}, size = {2.42, 0.58},
        fill = "surface", stroke = item.color, width = 1.8, layer = LAYER.outline,
    }
    text(
        memory, string.format("video-frame-memory-%02d-label", index),
        string.format("%s @ %d · %d B", item.name, item.offset, item.size),
        {item.x, memoryY}, "code", item.color
    )
end
local summary = text(
    figure, "video-frame-buffer-summary",
    string.format("plane offsets: %d -> %d -> %d · total backing storage = %d bytes", offsetY, offsetU, offsetV, totalBytes),
    {0, -2.28}, "code", "result"
)

scene:fade_in(claim, {shift = {0, 0.08}, duration = 0.42, curve = "gentle"})
scene:fade_in(contract, {shift = {0, 0.05}, duration = 0.32, curve = "gentle"})
scene:fade_in(yLabel, {duration = 0.24, curve = "gentle"})
scene:create(yPlane.cell, 0.66, "linear")
scene:create(yPlane.visible, 0.28, "ease_out")
scene:create(yPlane.padding, 0.28, "ease_out")
scene:fade_in(paddingLabel, {duration = 0.24, curve = "gentle"})
scene:create(strideRuler, 0.50, "linear")
scene:fade_in(strideLabel, {duration = 0.26, curve = "gentle"})
scene:create({uLabel, vLabel}, 0.28, "ease_out", 0.04)
scene:create({uPlane.cell, vPlane.cell}, 0.58, "linear", 0.08)
scene:create({uPlane.visible, vPlane.visible}, 0.30, "ease_out", 0.05)
scene:create({uPlane.padding, vPlane.padding}, 0.30, "ease_out", 0.05)
scene:fade_in(memory, {shift = {0, 0.05}, duration = 0.52, curve = "ease_out"})
scene:fade_in(summary, {shift = {0, -0.04}, duration = 0.34, curve = "gentle"})
scene:wait(2.0)
return scene
