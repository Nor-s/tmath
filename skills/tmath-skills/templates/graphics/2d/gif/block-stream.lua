-- local question: How is a GIF89a byte stream divided into blocks and extensions?
-- visible input: one image stream from Header through Trailer
-- subject object or field: one exact Logical Screen Descriptor
-- one dominant action: expand the descriptor into its seven stored bytes
-- observable output: dimensions, packed flags, palette size, and byte order agree
-- coordinate frame and units: figure-local world units; displayed values are bytes
-- section bounds supplied by the parent: standalone 960 x 540 wrapper
-- final readable pose: stream order above and exact descriptor anatomy below

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "3_blue_1_eyes",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local LAYER = {object = 0, arrow = 30, text = 40}
local figure = scene:group {id = "gif-block-stream-figure"}

local function text(parent, id, value, point, role, fill, align)
    return parent:text {
        id = id, text = value, point = point, role = role or "code",
        fill = fill or "foreground", align = align or {0.5, 0.5}, layer = LAYER.text,
    }
end

local function append(destination, values)
    for _, value in ipairs(values) do destination[#destination + 1] = value end
end

local function u16le(value)
    return {value & 0xff, (value >> 8) & 0xff}
end

local function asciiBytes(value)
    local bytes = {}
    for index = 1, #value do bytes[#bytes + 1] = string.byte(value, index) end
    return bytes
end

local function hexByte(value)
    return string.format("%02X", value)
end

local width, height = 320, 180
local colorResolutionBits = 8
local sortFlag = 0
local globalTableSizeCode = 2
local globalTableEntries = 1 << (globalTableSizeCode + 1)
local globalTableBytes = 3 * globalTableEntries
local packed = 0x80
    | ((colorResolutionBits - 1) << 4)
    | (sortFlag << 3)
    | globalTableSizeCode
local descriptorBytes = {}
append(descriptorBytes, u16le(width))
append(descriptorBytes, u16le(height))
append(descriptorBytes, {packed, 0, 0})

local claim = text(
    figure, "gif-block-stream-claim",
    "GIF streams are ordered blocks, extensions, and data sub-blocks",
    {0, 2.55}, "h3"
)

local function labeledBox(parent, id, center, size, stroke, title, detail)
    local group = parent:group {id = id}
    group:rectangle {
        id = id .. "-body", center = center, size = size,
        fill = "surface", stroke = stroke, width = 1.8, layer = LAYER.object,
    }
    text(group, id .. "-title", title, {center[1], center[2] + 0.17}, "code", stroke)
    text(group, id .. "-detail", detail, {center[1], center[2] - 0.18}, "code", "muted")
    return group
end

local stream = figure:group {id = "gif-block-stream"}
local streamSpecs = {
    {"header", -4.70, 1.20, "info", "Header", "GIF89a"},
    {"lsd", -3.28, 1.16, "focus", "LSD", "7 B"},
    {"gct", -1.88, 1.18, "result", "GCT", string.format("%d B", globalTableBytes)},
    {"gce", -0.54, 1.04, "warning", "GCE", "21 F9"},
    {"image", 0.91, 1.48, "info", "Image", "2C · 10 B"},
    {"data", 2.63, 1.52, "result", "Image Data", "sub-blocks"},
    {"trailer", 4.46, 1.12, "warning", "Trailer", "3B"},
}
local descriptorBox
for _, spec in ipairs(streamSpecs) do
    local box = labeledBox(
        stream, "gif-block-" .. spec[1], {spec[2], 1.28}, {spec[3], 0.78},
        spec[4], spec[5], spec[6]
    )
    if spec[1] == "lsd" then descriptorBox = box end
end

local expandArrow = figure:arrow {
    id = "gif-lsd-expand-arrow", from = {-3.28, 0.86}, to = {-3.28, 0.36},
    stroke = "focus", width = 2, tip = 10, layer = LAYER.arrow,
}
local descriptorLabel = text(
    figure, "gif-lsd-byte-label", "Logical Screen Descriptor · little-endian integers",
    {0, 0.35}, "code", "focus"
)

local byteNames = {"width lo", "width hi", "height lo", "height hi", "packed", "BG index", "aspect"}
local bytes = figure:group {id = "gif-lsd-bytes"}
local byteStart, byteStep = -3.30, 1.10
for index, value in ipairs(descriptorBytes) do
    local x = byteStart + (index - 1) * byteStep
    local stroke = index == 5 and "result" or "border"
    bytes:rectangle {
        id = string.format("gif-lsd-byte-%d-body", index - 1),
        center = {x, -0.25}, size = {0.96, 0.82},
        fill = "surface", stroke = stroke, width = 1.6, layer = LAYER.object,
    }
    text(
        bytes, string.format("gif-lsd-byte-%d-name", index - 1), byteNames[index],
        {x, -0.08}, "code", stroke
    )
    text(
        bytes, string.format("gif-lsd-byte-%d-value", index - 1), hexByte(value),
        {x, -0.42}, "code", "foreground"
    )
end

local dimensions = text(
    figure, "gif-lsd-dimensions",
    string.format("%d x %d px  ->  %s %s · %s %s", width, height,
        hexByte(descriptorBytes[1]), hexByte(descriptorBytes[2]),
        hexByte(descriptorBytes[3]), hexByte(descriptorBytes[4])),
    {0, -1.14}, "code", "foreground"
)
local packedSummary = text(
    figure, "gif-lsd-packed-summary",
    string.format("packed %s = GCT 1 | color resolution %d | sort %d | size code %d",
        hexByte(packed), colorResolutionBits - 1, sortFlag, globalTableSizeCode),
    {0, -1.65}, "code", "result"
)
local tableSummary = text(
    figure, "gif-lsd-table-summary",
    string.format("GCT entries = 2^(%d + 1) = %d; RGB bytes = 3 x %d = %d",
        globalTableSizeCode, globalTableEntries, globalTableEntries, globalTableBytes),
    {0, -2.16}, "code", "muted"
)

scene:fade_in(claim, {shift = {0, 0.08}, duration = 0.44, curve = "gentle"})
scene:fade_in(stream, {shift = {0, 0.08}, duration = 0.72, curve = "ease_out"})
scene:wait(0.40)
scene:indicate(descriptorBox, {scale = 1.035, duration = 0.36, curve = "gentle"})
scene:create(expandArrow, 0.32, "ease_out")
scene:fade_in(descriptorLabel, {shift = {0, 0.05}, duration = 0.26, curve = "gentle"})
scene:fade_in(bytes, {shift = {0, 0.08}, duration = 0.68, curve = "ease_out"})
scene:fade_in(dimensions, {shift = {0, -0.05}, duration = 0.30, curve = "gentle"})
scene:fade_in(packedSummary, {shift = {0, -0.05}, duration = 0.32, curve = "gentle"})
scene:fade_in(tableSummary, {shift = {0, -0.05}, duration = 0.32, curve = "gentle"})
scene:wait(1.9)
return scene
