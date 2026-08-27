-- local question: How do IHDR color type and bit depth determine one scanline?
-- visible input: a 2 x 2 RGBA8 image and one selected row
-- subject object or field: literal pixels and their ordered sample bytes
-- one dominant action: unpack the selected row into filter + RGBA bytes
-- observable output: the displayed byte count equals the visible row layout
-- coordinate frame and units: pixel centers are integer-local; byte cells are discrete
-- section bounds supplied by the parent: standalone 960 x 540 wrapper
-- final readable pose: image, IHDR fields, bytes, and byte-count equation

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "3_blue_1_eyes",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local LAYER = {base = -5, object = 0, focus = 20, arrow = 30, text = 40}
local figure = scene:group {id = "png-ihdr-layout-figure"}

local function text(parent, id, value, point, role, fill, align)
    return parent:text {
        id = id, text = value, point = point, role = role or "code",
        fill = fill or "foreground", align = align or {0.5, 0.5}, layer = LAYER.text,
    }
end

local function rgbaHex(rgba)
    return string.format("#%02x%02x%02x%02x", rgba[1], rgba[2], rgba[3], rgba[4])
end

local width, height, bitDepth, colorType = 2, 2, 8, 6
local channels = {"R", "G", "B", "A"}
local pixels = {
    {{57, 125, 219, 255}, {245, 183, 56, 64}},
    {{236, 72, 86, 255}, {51, 167, 105, 128}},
}
local selectedRow = pixels[height]
local scanlineBytes = {0}
for _, pixel in ipairs(selectedRow) do
    for _, sample in ipairs(pixel) do scanlineBytes[#scanlineBytes + 1] = sample end
end

local claim = text(
    figure, "png-ihdr-layout-claim",
    "IHDR defines how pixel samples are packed into every scanline",
    {0, 2.55}, "h3"
)
local headerLine = text(
    figure, "png-ihdr-layout-fields",
    string.format(
        "width=%d   height=%d   bit depth=%d   color type=%d (RGBA)",
        width, height, bitDepth, colorType
    ),
    {0, 1.70}, "code", "foreground"
)
local methodLine = text(
    figure, "png-ihdr-layout-methods",
    "compression=0   filter=0   interlace=0",
    {0, 1.32}, "code", "muted"
)

local pixelSpace = figure:space {
    id = "png-ihdr-pixel-space", x = {0, width - 1, 1}, y = {0, height - 1, 1}, opacity = 0,
    matrix = {0.90, 0, 0, -4.05, 0, 0.90, 0, -0.65, 0, 0, 1, 0, 0, 0, 0, 1},
}
local patches = {}
for row = 0, height - 1 do
    for column = 0, width - 1 do
        patches[#patches + 1] = {
            region = {column, row, 1, 1}, color = rgbaHex(pixels[row + 1][column + 1]),
        }
    end
end
local image = pixelSpace:cell {
    id = "png-ihdr-pixels", origin = {-0.5, -0.5}, size = {width, height},
    mode = "padd", padding = 0.05, color = "surface", patches = patches, layer = LAYER.object,
}
local rowSelection = pixelSpace:rectangle {
    id = "png-ihdr-selected-row", center = {(width - 1) / 2, height - 1}, size = {width, 1},
    fill = "#00000000", stroke = "focus", width = 4, layer = LAYER.focus,
}
local pixelLabel = text(
    figure, "png-ihdr-pixel-label", string.format("%d x %d literal pixels", width, height),
    {-3.60, -1.55}, "code", "muted"
)

local unpackArrow = figure:arrow {
    id = "png-ihdr-unpack-arrow", from = {-2.72, 0.22}, to = {-1.52, -0.12},
    stroke = "focus", width = 2, tip = 11, layer = LAYER.arrow,
}

local byteRow = figure:group {id = "png-ihdr-byte-row"}
local byteStart, byteStep = -1.12, 0.61
local byteFills = {"muted", "#7f1d1d", "#166534", "#1e3a8a", "#52525b"}
for index, value in ipairs(scanlineBytes) do
    local x = byteStart + (index - 1) * byteStep
    local channelIndex = index == 1 and 1 or ((index - 2) % #channels) + 2
    local channel = index == 1 and "F" or channels[((index - 2) % #channels) + 1]
    byteRow:rectangle {
        id = string.format("png-ihdr-byte-%02d", index - 1), center = {x, -0.32}, size = {0.52, 0.74},
        fill = byteFills[channelIndex], stroke = "border", width = 1.5, layer = LAYER.object,
    }
    text(
        byteRow, string.format("png-ihdr-byte-channel-%02d", index - 1), channel,
        {x, 0.23}, "code", "muted"
    )
    text(
        byteRow, string.format("png-ihdr-byte-value-%02d", index - 1), tostring(value),
        {x, -0.32}, "code", "#ffffffff"
    )
end
local byteLabel = text(
    figure, "png-ihdr-byte-label", "filter byte + two RGBA pixels",
    {1.35, 0.70}, "code", "muted"
)
local byteCount = 1 + width * #channels
local byteEquation = text(
    figure, "png-ihdr-byte-equation",
    string.format("1 + %d x %d = %d bytes per scanline", width, #channels, byteCount),
    {0.85, -1.72}, "code", "result"
)

scene:fade_in(claim, {shift = {0, 0.08}, duration = 0.42, curve = "gentle"})
scene:fade_in(headerLine, {shift = {0, 0.06}, duration = 0.34, curve = "gentle"})
scene:fade_in(methodLine, {shift = {0, 0.06}, duration = 0.28, curve = "gentle"})
scene:create(image, 0.55, "ease_out")
scene:fade_in(pixelLabel, {shift = {0, 0.06}, duration = 0.25, curve = "gentle"})
scene:create(rowSelection, 0.32, "ease_out")
scene:create(unpackArrow, 0.40, "ease_out")
scene:fade_in(byteLabel, {shift = {0, 0.06}, duration = 0.26, curve = "gentle"})
scene:fade_in(byteRow, {shift = {-0.12, 0}, duration = 0.65, curve = "ease_out"})
scene:fade_in(byteEquation, {shift = {0, -0.08}, duration = 0.34, curve = "gentle"})
scene:wait(1.8)
return scene
