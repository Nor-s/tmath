-- local question: How does a WebP file use RIFF chunks and padding?
-- visible input: one RIFF/WEBP header followed by VP8X, ICCP, ALPH, and VP8 chunks
-- subject object or field: one odd-sized ALPH chunk with its RIFF pad byte
-- one dominant action: expand ALPH into FourCC, size, payload, and padding
-- observable output: chunk size excludes the zero pad while RIFF size includes it
-- coordinate frame and units: figure-local world units; byte counts are integers
-- section bounds supplied by the parent: standalone 960 x 540 wrapper
-- final readable pose: file order above, expanded ALPH chunk below

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "3_blue_1_eyes",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local LAYER = {object = 0, arrow = 30, text = 40}
local figure = scene:group {id = "webp-riff-stream-figure"}

local function text(parent, id, value, point, role, fill, align)
    return parent:text {
        id = id, text = value, point = point, role = role or "code",
        fill = fill or "foreground", align = align or {0.5, 0.5}, layer = LAYER.text,
    }
end

local function u32le(value)
    return {
        value & 0xff, (value >> 8) & 0xff,
        (value >> 16) & 0xff, (value >> 24) & 0xff,
    }
end

local function hexBytes(bytes)
    local parts = {}
    for index, value in ipairs(bytes) do parts[index] = string.format("%02X", value) end
    return table.concat(parts, " ")
end

local alphaValues = {255, 192, 96, 0}
local alphaHeader = 0
local alphaPayload = {alphaHeader}
for _, value in ipairs(alphaValues) do alphaPayload[#alphaPayload + 1] = value end

local chunks = {
    {id = "vp8x", fourcc = "VP8X", size = 10, color = "info"},
    {id = "iccp", fourcc = "ICCP", size = 128, color = "focus"},
    {id = "alph", fourcc = "ALPH", size = #alphaPayload, color = "result"},
    {id = "vp8", fourcc = "VP8 ", size = 12, color = "warning"},
}
local chunkBytes = 0
for _, chunk in ipairs(chunks) do
    chunk.pad = chunk.size % 2
    chunkBytes = chunkBytes + 8 + chunk.size + chunk.pad
end
local riffSize = 4 + chunkBytes
local totalFileSize = 8 + riffSize

local claim = text(
    figure, "webp-riff-claim",
    "RIFF pads odd WebP chunk payloads with one zero byte",
    {0, 2.55}, "h3"
)

local function labeledBox(id, center, size, stroke, title, detail)
    local group = figure:group {id = id}
    group:rectangle {
        id = id .. "-body", center = center, size = size,
        fill = "surface", stroke = stroke, width = 2, layer = LAYER.object,
    }
    text(group, id .. "-title", title, {center[1], center[2] + 0.18}, "code", stroke)
    text(group, id .. "-detail", detail, {center[1], center[2] - 0.20}, "code", "muted")
    return group
end

local header = {
    labeledBox("webp-riff-fourcc", {-4.47, 1.25}, {1.25, 0.92}, "info", "RIFF", "file tag"),
    labeledBox(
        "webp-riff-size", {-3.03, 1.25}, {1.42, 0.92}, "focus", "File Size",
        hexBytes(u32le(riffSize))
    ),
    labeledBox("webp-riff-webp", {-1.60, 1.25}, {1.20, 0.92}, "info", "WEBP", "form type"),
}

local stream = {}
local chunkCenters = {0.02, 1.37, 2.72, 4.07}
for index, chunk in ipairs(chunks) do
    stream[index] = labeledBox(
        "webp-riff-chunk-" .. chunk.id,
        {chunkCenters[index], 1.25}, {1.18, 0.92}, chunk.color,
        chunk.fourcc, string.format("%d B%s", chunk.size, chunk.pad == 1 and " + pad" or "")
    )
end

local expandArrow = figure:arrow {
    id = "webp-riff-alpha-expand-arrow", from = {2.72, 0.72}, to = {2.72, 0.18},
    stroke = "result", width = 2, tip = 10, layer = LAYER.arrow,
}

local anatomy = {
    labeledBox(
        "webp-riff-alpha-fourcc", {-3.75, -0.62}, {1.55, 1.08}, "result",
        "FourCC", "41 4C 50 48"
    ),
    labeledBox(
        "webp-riff-alpha-size", {-1.88, -0.62}, {1.72, 1.08}, "focus",
        "Chunk Size", hexBytes(u32le(#alphaPayload))
    ),
    labeledBox(
        "webp-riff-alpha-payload", {0.75, -0.62}, {3.18, 1.08}, "info",
        string.format("Payload: %d bytes", #alphaPayload), hexBytes(alphaPayload)
    ),
    labeledBox(
        "webp-riff-alpha-padding", {3.23, -0.62}, {1.18, 1.08}, "warning",
        "Padding", "00"
    ),
}

local sizeRule = text(
    figure, "webp-riff-size-rule",
    string.format("ALPH Chunk Size = %d; its pad byte is not counted", #alphaPayload),
    {0, -1.55}, "code", "result"
)
local fileRule = text(
    figure, "webp-riff-file-rule",
    string.format("Illustrative lengths: RIFF Size = %d; whole stream = %d bytes", riffSize, totalFileSize),
    {0, -2.18}, "code", "muted"
)

scene:fade_in(claim, {shift = {0, 0.08}, duration = 0.44, curve = "gentle"})
for _, part in ipairs(header) do
    scene:fade_in(part, {shift = {0, 0.08}, duration = 0.28, curve = "ease_out"})
end
for _, part in ipairs(stream) do
    scene:fade_in(part, {shift = {0, 0.08}, duration = 0.26, curve = "ease_out"})
end
scene:wait(0.42)
scene:create(expandArrow, 0.32, "ease_out")
for _, field in ipairs(anatomy) do
    scene:fade_in(field, {shift = {0, 0.08}, duration = 0.28, curve = "gentle"})
end
scene:fade_in(sizeRule, {shift = {0, -0.06}, duration = 0.30, curve = "gentle"})
scene:fade_in(fileRule, {shift = {0, -0.06}, duration = 0.30, curve = "gentle"})
scene:wait(1.8)
return scene
