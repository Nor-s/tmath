-- local question: How do GIF transparency, delay, disposal, and looping affect frames?
-- visible input: one logical screen and a 3 x 2 indexed frame rectangle
-- subject object or field: one exact Graphic Control Extension and loop extension
-- one dominant action: composite the frame, wait, then restore its rectangle to background
-- observable output: transparent pixels preserve the canvas and disposal 2 clears only the frame area
-- coordinate frame and units: raster coordinates are top-left pixels; delay uses centiseconds
-- section bounds supplied by the parent: standalone 960 x 540 wrapper
-- final readable pose: before, displayed, disposed canvases and exact control bytes

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "3_blue_1_eyes",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local LAYER = {cell = 0, focus = 20, arrow = 30, text = 40}
local figure = scene:group {id = "gif-frame-compositing-figure"}

local function text(parent, id, value, point, role, fill, align)
    return parent:text {
        id = id, text = value, point = point, role = role or "code",
        fill = fill or "foreground", align = align or {0.5, 0.5}, layer = LAYER.text,
    }
end

local function copyRaster(source)
    local result = {}
    for row, values in ipairs(source) do
        result[row] = {}
        for column, value in ipairs(values) do result[row][column] = value end
    end
    return result
end

local function u16le(value)
    return {value & 0xff, (value >> 8) & 0xff}
end

local function hexBytes(values)
    local parts = {}
    for index, value in ipairs(values) do parts[index] = string.format("%02X", value) end
    return table.concat(parts, " ")
end

local columns, rows = 5, 4
local palette = {"#111827ff", "#38bdf8ff", "#f97316ff"}
local backgroundIndex, existingIndex, frameColorIndex = 0, 1, 2
local transparentIndex = 0
local frameLeft, frameTop, frameWidth, frameHeight = 1, 1, 3, 2
local framePixels = {
    {frameColorIndex, transparentIndex, frameColorIndex},
    {transparentIndex, frameColorIndex, frameColorIndex},
}

local before = {}
for row = 1, rows do
    before[row] = {}
    for column = 1, columns do before[row][column] = backgroundIndex end
end
before[1][1], before[4][5] = existingIndex, existingIndex
before[2][2], before[2][3] = existingIndex, existingIndex
before[3][2], before[3][3] = existingIndex, existingIndex

local displayed = copyRaster(before)
for localRow = 0, frameHeight - 1 do
    for localColumn = 0, frameWidth - 1 do
        local index = framePixels[localRow + 1][localColumn + 1]
        if index ~= transparentIndex then
            displayed[frameTop + localRow + 1][frameLeft + localColumn + 1] = index
        end
    end
end

local disposed = copyRaster(displayed)
for localRow = 0, frameHeight - 1 do
    for localColumn = 0, frameWidth - 1 do
        disposed[frameTop + localRow + 1][frameLeft + localColumn + 1] = backgroundIndex
    end
end

local disposalMethod = 2
local transparencyFlag = 1
local packed = (disposalMethod << 2) | transparencyFlag
local delayCentiseconds = 20
local delayBytes = u16le(delayCentiseconds)
local gceBytes = {0x21, 0xf9, 0x04, packed, delayBytes[1], delayBytes[2], transparentIndex, 0x00}
local loopCount = 0
local loopBytes = {0x03, 0x01, loopCount & 0xff, (loopCount >> 8) & 0xff, 0x00}

local claim = text(
    figure, "gif-frame-compositing-claim",
    "GIF frames modify one logical screen, then apply a disposal rule",
    {0, 2.55}, "h3"
)

local function canvas(id, raster, translateX, label, role)
    local group = figure:group {id = id}
    local space = group:space {
        id = id .. "-space", x = {0, columns - 1, 1}, y = {0, rows - 1, 1}, opacity = 0,
        matrix = {0.43, 0, 0, translateX, 0, -0.43, 0, 1.02, 0, 0, 1, 0, 0, 0, 0, 1},
    }
    local patches = {}
    for row = 0, rows - 1 do
        for column = 0, columns - 1 do
            patches[#patches + 1] = {
                region = {column, row, 1, 1},
                color = palette[raster[row + 1][column + 1] + 1],
            }
        end
    end
    space:cell {
        id = id .. "-cells", origin = {-0.5, -0.5}, size = {columns, rows},
        mode = "padd", padding = 0.055, color = palette[backgroundIndex + 1],
        patches = patches, layer = LAYER.cell,
    }
    space:rectangle {
        id = id .. "-frame-rect",
        center = {frameLeft + (frameWidth - 1) / 2, frameTop + (frameHeight - 1) / 2},
        size = {frameWidth, frameHeight}, fill = "#00000000", stroke = role,
        width = 3, layer = LAYER.focus,
    }
    text(group, id .. "-label", label, {translateX + 0.86, 1.72}, "code", role)
    return group
end

local beforeGroup = canvas("gif-frame-before", before, -4.68, "before frame", "info")
local displayedGroup = canvas("gif-frame-displayed", displayed, -0.86, "displayed", "focus")
local disposedGroup = canvas(
    "gif-frame-disposed", disposed, 2.96,
    string.format("after disposal %d", disposalMethod), "result"
)

local compositeArrow = figure:arrow {
    id = "gif-frame-composite-arrow", from = {-2.30, 0.38}, to = {-1.38, 0.38},
    stroke = "focus", width = 2, tip = 10, layer = LAYER.arrow,
}
local compositeLabel = text(
    figure, "gif-frame-composite-label",
    string.format("index %d -> skip write", transparentIndex),
    {-1.84, 1.40}, "code", "focus"
)
local disposalArrow = figure:arrow {
    id = "gif-frame-disposal-arrow", from = {1.52, 0.38}, to = {2.44, 0.38},
    stroke = "result", width = 2, tip = 10, layer = LAYER.arrow,
}
local disposalLabel = text(
    figure, "gif-frame-disposal-label",
    string.format("%d cs (%.2f s) -> restore BG rect",
        delayCentiseconds, delayCentiseconds / 100),
    {1.98, 1.40}, "code", "result"
)

local gceSummary = text(
    figure, "gif-frame-gce-summary",
    string.format("GCE bytes: %s", hexBytes(gceBytes)),
    {0, -1.35}, "code", "warning"
)
local packedSummary = text(
    figure, "gif-frame-packed-summary",
    string.format("packed %02X = disposal %d + transparency flag %d", packed, disposalMethod, transparencyFlag),
    {0, -1.78}, "code", "foreground"
)
local loopSummary = text(
    figure, "gif-frame-loop-summary",
    string.format("NETSCAPE2.0 application data: %s -> loop count %d = forever",
        hexBytes(loopBytes), loopCount),
    {0, -2.20}, "code", "muted"
)

scene:fade_in(claim, {shift = {0, 0.08}, duration = 0.44, curve = "gentle"})
scene:fade_in(beforeGroup, {shift = {0, 0.08}, duration = 0.52, curve = "ease_out"})
scene:create(compositeArrow, 0.34, "ease_out")
scene:fade_in(compositeLabel, {shift = {0, 0.05}, duration = 0.30, curve = "gentle"})
scene:fade_in(displayedGroup, {shift = {-0.10, 0}, duration = 0.58, curve = "ease_out"})
scene:fade_in(gceSummary, {shift = {0, -0.05}, duration = 0.30, curve = "gentle"})
scene:wait(0.44)
scene:create(disposalArrow, 0.34, "ease_out")
scene:fade_in(disposalLabel, {shift = {0, 0.05}, duration = 0.30, curve = "gentle"})
scene:fade_in(disposedGroup, {shift = {-0.10, 0}, duration = 0.58, curve = "ease_out"})
scene:fade_in(packedSummary, {shift = {0, -0.05}, duration = 0.30, curve = "gentle"})
scene:fade_in(loopSummary, {shift = {0, -0.05}, duration = 0.34, curve = "gentle"})
scene:wait(2.0)
return scene
