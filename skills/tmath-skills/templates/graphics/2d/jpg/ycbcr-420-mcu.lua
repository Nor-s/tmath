-- local question: What does one 4:2:0 JPEG minimum coded unit contain?
-- visible input: a synthetic 16 x 16 RGB footprint converted to Y, Cb, and Cr
-- subject object or field: four 8 x 8 luma blocks plus two 8 x 8 chroma blocks
-- one dominant action: average each 2 x 2 chroma footprint into one stored sample
-- observable output: one MCU contains 4 Y blocks, 1 Cb block, and 1 Cr block
-- coordinate frame and units: Cell coordinates are stored component samples
-- section bounds supplied by the parent: standalone 960 x 540 wrapper
-- final readable pose: exact plane dimensions, sampling factors, and block count

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "3_blue_1_eyes",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local LAYER = {cell = 0, block = 10, focus = 20, text = 40}
local figure = scene:group {id = "jpg-ycbcr-420-figure"}

local function text(parent, id, value, point, role, fill, align)
    return parent:text {
        id = id, text = value, point = point, role = role or "code",
        fill = fill or "foreground", align = align or {0.5, 0.5}, layer = LAYER.text,
    }
end

local function clampByte(value)
    return math.max(0, math.min(255, math.floor(value + 0.5)))
end

local function hex(r, g, b)
    return string.format("#%02x%02x%02xff", clampByte(r), clampByte(g), clampByte(b))
end

local function toYCbCr(rgb)
    local r, g, b = rgb[1], rgb[2], rgb[3]
    return {
        0.299 * r + 0.587 * g + 0.114 * b,
        128 - 0.168736 * r - 0.331264 * g + 0.5 * b,
        128 + 0.5 * r - 0.418688 * g - 0.081312 * b,
    }
end

local width, height = 16, 16
local ySamples, fullCb, fullCr = {}, {}, {}
for row = 0, height - 1 do
    for column = 0, width - 1 do
        local rgb = {
            clampByte(36 + 12 * column),
            clampByte(48 + 10 * row),
            clampByte(210 - 7 * column + 3 * row),
        }
        local ycbcr = toYCbCr(rgb)
        local index = row * width + column + 1
        ySamples[index], fullCb[index], fullCr[index] = ycbcr[1], ycbcr[2], ycbcr[3]
    end
end

local cbSamples, crSamples = {}, {}
for row = 0, 7 do
    for column = 0, 7 do
        local cbSum, crSum = 0, 0
        for dy = 0, 1 do
            for dx = 0, 1 do
                local index = (row * 2 + dy) * width + column * 2 + dx + 1
                cbSum, crSum = cbSum + fullCb[index], crSum + fullCr[index]
            end
        end
        cbSamples[#cbSamples + 1] = cbSum / 4
        crSamples[#crSamples + 1] = crSum / 4
    end
end

local function yColor(value)
    local byte = clampByte(value)
    return hex(byte, byte, byte)
end

local function cbColor(value)
    local delta, luminance = value - 128, 156
    return hex(luminance, luminance - 0.344136 * delta, luminance + 1.772 * delta)
end

local function crColor(value)
    local delta, luminance = value - 128, 156
    return hex(luminance + 1.402 * delta, luminance - 0.714136 * delta, luminance)
end

local function makeCell(id, values, columns, rows, center, scale, colorForValue)
    local space = figure:space {
        id = id .. "-space", x = {0, columns - 1, 1}, y = {0, rows - 1, 1}, opacity = 0,
        matrix = {
            scale, 0, 0, center[1] - (columns - 1) * scale / 2,
            0, scale, 0, center[2] - (rows - 1) * scale / 2,
            0, 0, 1, 0,
            0, 0, 0, 1,
        },
    }
    local patches = {}
    for row = 0, rows - 1 do
        for column = 0, columns - 1 do
            local index = row * columns + column + 1
            patches[#patches + 1] = {
                region = {column, row, 1, 1}, color = colorForValue(values[index]),
            }
        end
    end
    local cell = space:cell {
        id = id, origin = {-0.5, -0.5}, size = {columns, rows},
        mode = "padd", padding = 0.035, color = "surface", patches = patches, layer = LAYER.cell,
    }
    return space, cell
end

local claim = text(
    figure, "jpg-ycbcr-420-claim",
    "A 4:2:0 MCU stores four luma blocks for every pair of chroma blocks",
    {0, 2.55}, "h3"
)
local sampling = text(
    figure, "jpg-ycbcr-420-sampling",
    "SOF sampling factors: Y = 2 x 2,  Cb = 1 x 1,  Cr = 1 x 1",
    {0, 2.10}, "code", "foreground"
)

local ySpace, yPlane = makeCell("jpg-ycbcr-y", ySamples, 16, 16, {-3.28, 0.12}, 0.17, yColor)
local cbSpace, cbPlane = makeCell("jpg-ycbcr-cb", cbSamples, 8, 8, {0.18, 0.38}, 0.19, cbColor)
local crSpace, crPlane = makeCell("jpg-ycbcr-cr", crSamples, 8, 8, {2.72, 0.38}, 0.19, crColor)

local blockColors = {"info", "focus", "result", "warning"}
local blockNames = {"Y0", "Y1", "Y2", "Y3"}
local blockCenters = {{3.5, 3.5}, {11.5, 3.5}, {3.5, 11.5}, {11.5, 11.5}}
local yBlocks = {}
for index, center in ipairs(blockCenters) do
    yBlocks[index] = ySpace:rectangle {
        id = "jpg-ycbcr-" .. string.lower(blockNames[index]) .. "-block",
        center = center, size = {8, 8}, fill = "#00000000",
        stroke = blockColors[index], width = 2.2, layer = LAYER.block,
    }
    text(
        ySpace, "jpg-ycbcr-" .. string.lower(blockNames[index]) .. "-label",
        blockNames[index], center, "code", blockColors[index]
    )
end

local yLabel = text(figure, "jpg-ycbcr-y-label", "Y  16 x 16  /  four 8 x 8 blocks", {-3.28, 1.68}, "code", "info")
local cbLabel = text(figure, "jpg-ycbcr-cb-label", "Cb  8 x 8", {0.18, 1.36}, "code", "focus")
local crLabel = text(figure, "jpg-ycbcr-cr-label", "Cr  8 x 8", {2.72, 1.36}, "code", "result")

local footprint = ySpace:rectangle {
    id = "jpg-ycbcr-2x2-footprint", center = {12.5, 4.5}, size = {2, 2},
    fill = "#00000022", stroke = "foreground", width = 3, layer = LAYER.focus,
}
local cbSample = cbSpace:rectangle {
    id = "jpg-ycbcr-cb-sample", center = {6, 2}, size = {1, 1},
    fill = "#00000000", stroke = "foreground", width = 3, layer = LAYER.focus,
}
local crSample = crSpace:rectangle {
    id = "jpg-ycbcr-cr-sample", center = {6, 2}, size = {1, 1},
    fill = "#00000000", stroke = "foreground", width = 3, layer = LAYER.focus,
}
local footprintRule = text(
    figure, "jpg-ycbcr-footprint-rule",
    "each stored Cb/Cr sample represents one 2 x 2 source footprint",
    {0.45, -1.45}, "code", "muted"
)
local sampleCount = 4 * 8 * 8 + 8 * 8 + 8 * 8
local summary = text(
    figure, "jpg-ycbcr-420-summary",
    string.format("one MCU = 4Y + 1Cb + 1Cr = 6 blocks = %d component samples", sampleCount),
    {0, -1.95}, "code", "result"
)
local colorNote = text(
    figure, "jpg-ycbcr-color-note",
    "Cb and Cr planes use component-isolating display colors",
    {0, -2.37}, "code", "muted"
)

scene:fade_in(claim, {shift = {0, 0.08}, duration = 0.44, curve = "gentle"})
scene:fade_in(sampling, {shift = {0, 0.05}, duration = 0.32, curve = "gentle"})
scene:fade_in(yLabel, {shift = {0, 0.05}, duration = 0.24, curve = "gentle"})
scene:create(yPlane, 0.78, "linear")
scene:create(yBlocks, 0.52, "ease_out", 0.04)
scene:create({cbLabel, crLabel}, 0.26, "ease_out", 0.04)
scene:create({cbPlane, crPlane}, 0.66, "linear", 0.08)
scene:create(footprint, 0.28, "ease_out")
scene:create({cbSample, crSample}, 0.28, "ease_out", 0.06)
scene:fade_in(footprintRule, {shift = {0, -0.05}, duration = 0.30, curve = "gentle"})
scene:fade_in(summary, {shift = {0, -0.05}, duration = 0.34, curve = "gentle"})
scene:fade_in(colorNote, {shift = {0, -0.04}, duration = 0.26, curve = "gentle"})
scene:wait(2.0)
return scene
