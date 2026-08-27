-- local question: How are WebP extended features and canvas size encoded in VP8X?
-- visible input: one ten-byte VP8X payload for a 640 x 360 image
-- subject object or field: feature bits plus two little-endian uint24 dimensions
-- one dominant action: unpack the flag byte and decode both one-based dimensions
-- observable output: 0x30 resolves to ICCP plus alpha and 639/359 resolve to 640/360
-- coordinate frame and units: figure-local world units; fields are bytes and pixels
-- section bounds supplied by the parent: standalone 960 x 540 wrapper
-- final readable pose: all ten bytes, flag meanings, and decoded canvas remain visible

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "3_blue_1_eyes",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local LAYER = {object = 0, focus = 20, arrow = 30, text = 40}
local figure = scene:group {id = "webp-vp8x-layout-figure"}

local function text(parent, id, value, point, role, fill, align)
    return parent:text {
        id = id, text = value, point = point, role = role or "code",
        fill = fill or "foreground", align = align or {0.5, 0.5}, layer = LAYER.text,
    }
end

local function u24le(value)
    return {value & 0xff, (value >> 8) & 0xff, (value >> 16) & 0xff}
end

local canvasWidth, canvasHeight = 640, 360
local features = {iccp = true, alpha = true, exif = false, xmp = false, animation = false}
local flagByte =
    (features.iccp and 0x20 or 0) |
    (features.alpha and 0x10 or 0) |
    (features.exif and 0x08 or 0) |
    (features.xmp and 0x04 or 0) |
    (features.animation and 0x02 or 0)
local widthStored, heightStored = canvasWidth - 1, canvasHeight - 1
local payload = {flagByte, 0, 0, 0}
for _, value in ipairs(u24le(widthStored)) do payload[#payload + 1] = value end
for _, value in ipairs(u24le(heightStored)) do payload[#payload + 1] = value end

local claim = text(
    figure, "webp-vp8x-claim",
    "VP8X packs feature flags and canvas dimensions into ten bytes",
    {0, 2.55}, "h3"
)

local byteCenters, byteStart, byteStep = {}, -4.05, 0.90
for index = 1, #payload do byteCenters[index] = byteStart + (index - 1) * byteStep end

local fieldLabels = {
    text(figure, "webp-vp8x-flags-label", "flags", {byteCenters[1], 1.48}, "code", "focus"),
    text(figure, "webp-vp8x-reserved-label", "reserved", {(byteCenters[2] + byteCenters[4]) / 2, 1.48}, "code", "muted"),
    text(figure, "webp-vp8x-width-label", "width - 1 (uint24 LE)", {(byteCenters[5] + byteCenters[7]) / 2, 1.48}, "code", "info"),
    text(figure, "webp-vp8x-height-label", "height - 1 (uint24 LE)", {(byteCenters[8] + byteCenters[10]) / 2, 1.48}, "code", "result"),
}

local byteRow = figure:group {id = "webp-vp8x-byte-row"}
for index, value in ipairs(payload) do
    local stroke = index == 1 and "focus" or (index <= 4 and "border" or (index <= 7 and "info" or "result"))
    byteRow:rectangle {
        id = string.format("webp-vp8x-byte-%02d", index - 1),
        center = {byteCenters[index], 0.88}, size = {0.72, 0.68},
        fill = "surface", stroke = stroke, width = 2, layer = LAYER.object,
    }
    text(
        byteRow, string.format("webp-vp8x-byte-value-%02d", index - 1),
        string.format("%02X", value), {byteCenters[index], 0.88}, "code", stroke
    )
end

local bitNames = {"R", "R", "I", "L", "E", "X", "A", "R"}
local bitValues = {}
for index = 1, 8 do bitValues[index] = (flagByte >> (8 - index)) & 1 end
local bitRow = figure:group {id = "webp-vp8x-flag-bits"}
local bitStart, bitStep = -4.48, 0.55
for index, value in ipairs(bitValues) do
    local x = bitStart + (index - 1) * bitStep
    local active = value == 1
    bitRow:rectangle {
        id = string.format("webp-vp8x-flag-bit-%d", index - 1),
        center = {x, -0.18}, size = {0.46, 0.60},
        fill = active and "focus" or "surface", stroke = active and "focus" or "border",
        width = 1.5, layer = LAYER.object,
    }
    text(
        bitRow, string.format("webp-vp8x-flag-name-%d", index - 1),
        bitNames[index], {x, 0.27}, "code", active and "focus" or "muted"
    )
    text(
        bitRow, string.format("webp-vp8x-flag-value-%d", index - 1),
        tostring(value), {x, -0.18}, "code", active and "#ffffffff" or "foreground"
    )
end

local flagSummary = text(
    figure, "webp-vp8x-flag-summary",
    string.format("0x%02X = ICCP + alpha", flagByte), {-2.55, -1.02}, "code", "focus"
)
local widthSummary = text(
    figure, "webp-vp8x-width-summary",
    string.format("%d + 1 = %d px", widthStored, canvasWidth), {1.16, -0.40}, "code", "info"
)
local heightSummary = text(
    figure, "webp-vp8x-height-summary",
    string.format("%d + 1 = %d px", heightStored, canvasHeight), {3.48, -0.40}, "code", "result"
)
local canvasSummary = text(
    figure, "webp-vp8x-canvas-summary",
    string.format("decoded canvas = %d x %d pixels", canvasWidth, canvasHeight),
    {1.95, -1.42}, "code", "result"
)
local reservedRule = text(
    figure, "webp-vp8x-reserved-rule",
    string.format("reserved bytes = %02X %02X %02X", payload[2], payload[3], payload[4]),
    {0, -2.18}, "code", "muted"
)

scene:fade_in(claim, {shift = {0, 0.08}, duration = 0.44, curve = "gentle"})
for _, label in ipairs(fieldLabels) do
    scene:fade_in(label, {shift = {0, 0.05}, duration = 0.22, curve = "gentle"})
end
scene:fade_in(byteRow, {shift = {-0.10, 0}, duration = 0.62, curve = "ease_out"})
scene:wait(0.38)
scene:fade_in(bitRow, {shift = {0, 0.08}, duration = 0.52, curve = "ease_out"})
scene:fade_in(flagSummary, {shift = {0, -0.05}, duration = 0.28, curve = "gentle"})
scene:fade_in(widthSummary, {shift = {0, -0.05}, duration = 0.28, curve = "gentle"})
scene:fade_in(heightSummary, {shift = {0, -0.05}, duration = 0.28, curve = "gentle"})
scene:fade_in(canvasSummary, {shift = {0, -0.06}, duration = 0.32, curve = "gentle"})
scene:fade_in(reservedRule, {shift = {0, -0.06}, duration = 0.28, curve = "gentle"})
scene:wait(1.8)
return scene
