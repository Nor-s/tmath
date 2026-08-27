-- local question: How is a JFIF/JPEG byte stream divided into markers and segments?
-- visible input: a baseline stream from SOI through one entropy-coded scan to EOI
-- subject object or field: one real JFIF APP0 marker segment
-- one dominant action: expand APP0 into marker, length, identifier, and payload fields
-- observable output: standalone markers and length-delimited segments remain distinct
-- coordinate frame and units: figure-local world units; displayed values are bytes
-- section bounds supplied by the parent: standalone 960 x 540 wrapper
-- final readable pose: stream order above and exact APP0 anatomy below

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "3_blue_1_eyes",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local LAYER = {object = 0, arrow = 30, text = 40}
local figure = scene:group {id = "jpg-marker-stream-figure"}

local function text(parent, id, value, point, role, fill, align)
    return parent:text {
        id = id, text = value, point = point, role = role or "code",
        fill = fill or "foreground", align = align or {0.5, 0.5}, layer = LAYER.text,
    }
end

local function append(destination, values)
    for _, value in ipairs(values) do destination[#destination + 1] = value end
end

local function u16be(value)
    return {(value >> 8) & 0xff, value & 0xff}
end

local function asciiBytes(value)
    local bytes = {}
    for index = 1, #value do bytes[#bytes + 1] = string.byte(value, index) end
    return bytes
end

local function hexBytes(bytes)
    local parts = {}
    for index, value in ipairs(bytes) do parts[index] = string.format("%02X", value) end
    return table.concat(parts, " ")
end

local identifier = asciiBytes("JFIF")
identifier[#identifier + 1] = 0
local app0Payload = {}
append(app0Payload, identifier)
append(app0Payload, {1, 2, 0, 0, 72, 0, 72, 0, 0})
local app0Length = #app0Payload + 2

local claim = text(
    figure, "jpg-marker-stream-claim",
    "JPEG streams combine markers and length-delimited segments",
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

local streamGroup = figure:group {id = "jpg-marker-stream"}
local streamSpecs = {
    {"soi", -4.55, 0.80, "info", "SOI", "FF D8"},
    {"app0", -3.45, 1.12, "focus", "APP0", "FF E0"},
    {"dqt", -2.30, 0.90, "warning", "DQT", "FF DB"},
    {"sof0", -1.15, 1.04, "result", "SOF0", "FF C0"},
    {"dht", 0.00, 0.90, "info", "DHT", "FF C4"},
    {"sos", 1.03, 0.86, "focus", "SOS", "FF DA"},
    {"scan", 2.40, 1.62, "result", "scan data", "entropy bytes"},
    {"eoi", 4.02, 0.80, "warning", "EOI", "FF D9"},
}
local app0Box
for _, spec in ipairs(streamSpecs) do
    local box = labeledBox(
        streamGroup, "jpg-marker-" .. spec[1], {spec[2], 1.22}, {spec[3], 0.76},
        spec[4], spec[5], spec[6]
    )
    if spec[1] == "app0" then app0Box = box end
end

local expandArrow = figure:arrow {
    id = "jpg-app0-expand-arrow", from = {-3.45, 0.79}, to = {-3.45, 0.24},
    stroke = "focus", width = 2, tip = 10, layer = LAYER.arrow,
}

local anatomy = figure:group {id = "jpg-app0-anatomy"}
labeledBox(anatomy, "jpg-app0-marker", {-4.45, -0.62}, {1.20, 1.02}, "focus", "marker", "FF E0")
labeledBox(
    anatomy, "jpg-app0-length", {-3.02, -0.62}, {1.38, 1.02}, "info", "length",
    hexBytes(u16be(app0Length))
)
labeledBox(
    anatomy, "jpg-app0-identifier", {-1.25, -0.62}, {1.78, 1.02}, "result", "identifier",
    hexBytes(identifier)
)
labeledBox(anatomy, "jpg-app0-version", {0.62, -0.62}, {1.62, 1.02}, "warning", "version / units", "01 02  ·  00")
labeledBox(anatomy, "jpg-app0-density", {2.52, -0.62}, {1.88, 1.02}, "info", "X / Y density", "00 48  ·  00 48")
labeledBox(anatomy, "jpg-app0-thumb", {4.24, -0.62}, {1.28, 1.02}, "muted", "thumbnail", "00 00")

local app0Summary = text(
    figure, "jpg-app0-summary",
    string.format("APP0 payload = %d bytes; segment length = payload + 2 = %d", #app0Payload, app0Length),
    {0, -1.55}, "code", "result"
)
local markerRule = text(
    figure, "jpg-marker-length-rule",
    "Length includes its two bytes, but excludes the FF E0 marker",
    {0, -2.08}, "code", "muted"
)

scene:fade_in(claim, {shift = {0, 0.08}, duration = 0.44, curve = "gentle"})
scene:fade_in(streamGroup, {shift = {0, 0.08}, duration = 0.72, curve = "ease_out"})
scene:wait(0.42)
scene:indicate(app0Box, {scale = 1.035, duration = 0.36, curve = "gentle"})
scene:create(expandArrow, 0.34, "ease_out")
scene:fade_in(anatomy, {shift = {0, 0.08}, duration = 0.72, curve = "ease_out"})
scene:fade_in(app0Summary, {shift = {0, -0.05}, duration = 0.32, curve = "gentle"})
scene:fade_in(markerRule, {shift = {0, -0.05}, duration = 0.30, curve = "gentle"})
scene:wait(1.9)
return scene
