-- local question: How does a PNG byte stream become typed chunks?
-- visible input: the PNG signature followed by IHDR, IDAT, and IEND
-- subject object or field: one real IHDR byte layout
-- one dominant action: expand IHDR into length, type, data, and CRC fields
-- observable output: the parser boundaries remain visible in the final pose
-- coordinate frame and units: figure-local world units; bytes are discrete cells
-- section bounds supplied by the parent: standalone 960 x 540 wrapper
-- final readable pose: stream order above, expanded IHDR below

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "3_blue_1_eyes",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local LAYER = {object = 0, arrow = 30, text = 40}
local figure = scene:group {id = "png-chunk-stream-figure"}

local function text(parent, id, value, point, role, fill, align)
    return parent:text {
        id = id, text = value, point = point, role = role or "code",
        fill = fill or "foreground", align = align or {0.5, 0.5}, layer = LAYER.text,
    }
end

local function append(destination, values)
    for _, value in ipairs(values) do destination[#destination + 1] = value end
end

local function u32Bytes(value)
    return {
        (value >> 24) & 0xff, (value >> 16) & 0xff,
        (value >> 8) & 0xff, value & 0xff,
    }
end

local function asciiBytes(value)
    local bytes = {}
    for index = 1, #value do bytes[#bytes + 1] = string.byte(value, index) end
    return bytes
end

local function byteString(bytes)
    local parts = {}
    for index, value in ipairs(bytes) do parts[index] = string.format("%02X", value) end
    return table.concat(parts, " ")
end

local function crc32(bytes)
    local crc, polynomial = 0xffffffff, 0xedb88320
    for _, byte in ipairs(bytes) do
        crc = (crc ~ byte) & 0xffffffff
        for _ = 1, 8 do
            if (crc & 1) == 1 then
                crc = ((crc >> 1) ~ polynomial) & 0xffffffff
            else
                crc = (crc >> 1) & 0xffffffff
            end
        end
    end
    return (~crc) & 0xffffffff
end

local width, height, bitDepth, colorType = 2, 2, 8, 6
local signature = {0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a}
local ihdrType = asciiBytes("IHDR")
local ihdrData = {}
append(ihdrData, u32Bytes(width))
append(ihdrData, u32Bytes(height))
append(ihdrData, {bitDepth, colorType, 0, 0, 0})
local crcInput = {}
append(crcInput, ihdrType)
append(crcInput, ihdrData)
local ihdrCrc = u32Bytes(crc32(crcInput))
local idatPayloadLength = 11

local claim = text(
    figure, "png-chunk-stream-claim",
    "A PNG stream is a signature followed by self-delimiting chunks",
    {0, 2.55}, "h3"
)

local function labeledBox(id, center, size, stroke, title, detail)
    local group = figure:group {id = id}
    group:rectangle {
        id = id .. "-body", center = center, size = size,
        fill = "surface", stroke = stroke, width = 2, layer = LAYER.object,
    }
    text(group, id .. "-title", title, {center[1], center[2] + 0.19}, "code", stroke)
    text(group, id .. "-detail", detail, {center[1], center[2] - 0.19}, "code", "muted")
    return group
end

local stream = {
    labeledBox(
        "png-signature", {-3.72, 1.25}, {3.05, 0.95}, "info",
        "PNG signature", byteString(signature)
    ),
    labeledBox(
        "png-ihdr-chunk", {-1.18, 1.25}, {1.65, 0.95}, "focus",
        "IHDR", string.format("%d data bytes", #ihdrData)
    ),
    labeledBox(
        "png-idat-chunk", {0.75, 1.25}, {1.85, 0.95}, "result",
        "IDAT", string.format("%d data bytes", idatPayloadLength)
    ),
    labeledBox(
        "png-iend-chunk", {2.60, 1.25}, {1.45, 0.95}, "warning",
        "IEND", string.format("%d data bytes", 0)
    ),
}

local expandArrow = figure:arrow {
    id = "png-ihdr-expand-arrow", from = {-1.18, 0.70}, to = {-1.18, 0.12},
    stroke = "focus", width = 2, tip = 10, layer = LAYER.arrow,
}

local anatomy = {
    labeledBox(
        "png-ihdr-length", {-3.80, -0.80}, {1.65, 1.10}, "muted",
        "Length", byteString(u32Bytes(#ihdrData))
    ),
    labeledBox(
        "png-ihdr-type", {-2.00, -0.80}, {1.65, 1.10}, "focus",
        "Type", byteString(ihdrType)
    ),
    labeledBox(
        "png-ihdr-data", {0.45, -0.80}, {2.95, 1.10}, "result",
        "13 data bytes",
        string.format("%d x %d  |  RGBA%d  |  methods 0", width, height, bitDepth)
    ),
    labeledBox(
        "png-ihdr-crc", {2.98, -0.80}, {1.80, 1.10}, "warning",
        "CRC-32", byteString(ihdrCrc)
    ),
}

local crcScope = text(
    figure, "png-ihdr-crc-scope", "CRC covers Type + Data, not Length",
    {0, -1.80}, "code", "muted"
)

scene:fade_in(claim, {shift = {0, 0.08}, duration = 0.45, curve = "gentle"})
for _, part in ipairs(stream) do
    scene:fade_in(part, {shift = {0, 0.10}, duration = 0.32, curve = "ease_out"})
end
scene:wait(0.45)
scene:create(expandArrow, 0.35, "ease_out")
for _, field in ipairs(anatomy) do
    scene:fade_in(field, {shift = {0, 0.10}, duration = 0.30, curve = "gentle"})
end
scene:fade_in(crcScope, {shift = {0, 0.08}, duration = 0.30, curve = "gentle"})
scene:wait(1.8)
return scene
