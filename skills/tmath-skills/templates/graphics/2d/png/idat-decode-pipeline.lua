-- local question: Why can several IDAT chunks contain one image stream?
-- visible input: one valid zlib stream split across three IDAT payloads
-- subject object or field: compressed bytes, filtered scanline, and decoded pixels
-- one dominant action: concatenate payloads, then inflate once
-- observable output: filter byte 0 and grayscale samples 17 and 200
-- coordinate frame and units: figure-local world units; byte cells are discrete
-- section bounds supplied by the parent: standalone 960 x 540 wrapper
-- final readable pose: chunk boundaries, continuous stream, and decoded pixels

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "3_blue_1_eyes",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local LAYER = {object = 0, arrow = 30, text = 40}
local figure = scene:group {id = "png-idat-pipeline-figure"}

local function text(parent, id, value, point, role, fill, align)
    return parent:text {
        id = id, text = value, point = point, role = role or "code",
        fill = fill or "foreground", align = align or {0.5, 0.5}, layer = LAYER.text,
    }
end

local function gray(value)
    return string.format("#%02x%02x%02x", value, value, value)
end

-- zlib level-9 encoding of the filtered scanline bytes 00 11 C8.
local compressed = {0x78, 0xda, 0x63, 0x10, 0x3c, 0x01, 0x00, 0x00, 0xed, 0x00, 0xda}
local splitLengths = {3, 4, 4}
local segmentColors = {"info", "focus", "result"}
local segments, cursor = {}, 1
for segmentIndex, length in ipairs(splitLengths) do
    local segment = {}
    for offset = 0, length - 1 do segment[#segment + 1] = compressed[cursor + offset] end
    segments[segmentIndex] = segment
    cursor = cursor + length
end
local filtered = {0x00, 0x11, 0xc8}
local samples = {filtered[2], filtered[3]}

local claim = text(
    figure, "png-idat-pipeline-claim",
    "Several IDAT payloads form one continuous zlib stream",
    {0, 2.55}, "h3"
)

local function byteStrip(parent, id, values, startX, y, step, fillForIndex)
    local group = parent:group {id = id}
    for index, value in ipairs(values) do
        local x = startX + (index - 1) * step
        local fill = type(fillForIndex) == "function" and fillForIndex(index) or fillForIndex
        group:rectangle {
            id = string.format("%s-cell-%02d", id, index), center = {x, y}, size = {step - 0.08, 0.58},
            fill = fill or "surface", stroke = "border", width = 1.4, layer = LAYER.object,
        }
        text(
            group, string.format("%s-value-%02d", id, index), string.format("%02X", value),
            {x, y}, "code", "#ffffffff"
        )
    end
    return group
end

local payloadGroups = {}
local payloadStarts = {-3.45, -0.95, 1.95}
for segmentIndex, values in ipairs(segments) do
    local group = figure:group {id = string.format("png-idat-payload-%d", segmentIndex)}
    local startX = payloadStarts[segmentIndex]
    byteStrip(
        group, string.format("png-idat-payload-%d-bytes", segmentIndex), values,
        startX, 1.30, 0.62, segmentColors[segmentIndex]
    )
    local centerX = startX + (#values - 1) * 0.62 / 2
    text(
        group, string.format("png-idat-payload-%d-label", segmentIndex),
        string.format("IDAT #%d payload", segmentIndex), {centerX, 1.82}, "code", segmentColors[segmentIndex]
    )
    payloadGroups[segmentIndex] = group
end

local concatenateArrow = figure:arrow {
    id = "png-idat-concatenate-arrow", from = {0, 0.88}, to = {0, 0.48},
    stroke = "foreground", width = 2, tip = 10, layer = LAYER.arrow,
}
local concatenateLabel = text(
    figure, "png-idat-concatenate-label", "concatenate payload bytes",
    {1.48, 0.68}, "code", "muted", {0, 0.5}
)

local cumulative = {}
local segmentAt = {}
for segmentIndex, values in ipairs(segments) do
    for _, value in ipairs(values) do
        cumulative[#cumulative + 1] = value
        segmentAt[#segmentAt + 1] = segmentIndex
    end
end
local streamStart, streamStep = -3.05, 0.61
local stream = byteStrip(
    figure, "png-idat-zlib-stream", cumulative, streamStart, 0.08, streamStep,
    function(index) return segmentColors[segmentAt[index]] end
)
local streamLabel = text(
    figure, "png-idat-zlib-label", string.format("one zlib stream (%d bytes)", #cumulative),
    {0, -0.45}, "code", "foreground"
)

local inflateArrow = figure:arrow {
    id = "png-idat-inflate-arrow", from = {0, -0.72}, to = {0, -1.10},
    stroke = "result", width = 2, tip = 10, layer = LAYER.arrow,
}
local inflateLabel = text(
    figure, "png-idat-inflate-label", "inflate once",
    {0.75, -0.91}, "code", "result", {0, 0.5}
)

local filteredRow = byteStrip(
    figure, "png-idat-filtered-row", filtered, -2.65, -1.55, 0.72,
    function(index) return index == 1 and "muted" or "surface" end
)
local filteredLabel = text(
    figure, "png-idat-filtered-label", "filter=0   samples=17, 200",
    {-1.93, -2.12}, "code", "muted"
)

local decoded = figure:group {id = "png-idat-decoded-pixels"}
for index, value in ipairs(samples) do
    local x = 1.45 + (index - 1) * 1.05
    decoded:rectangle {
        id = string.format("png-idat-pixel-%d", index - 1), center = {x, -1.55}, size = {0.88, 0.88},
        fill = gray(value), stroke = "border", width = 2, layer = LAYER.object,
    }
    text(
        decoded, string.format("png-idat-pixel-value-%d", index - 1), tostring(value),
        {x, -1.55}, "code", value < 96 and "#ffffffff" or "#111827ff"
    )
end
local unpackArrow = figure:arrow {
    id = "png-idat-unpack-arrow", from = {-0.12, -1.55}, to = {0.82, -1.55},
    stroke = "result", width = 2, tip = 10, layer = LAYER.arrow,
}
local decodedLabel = text(
    figure, "png-idat-decoded-label", "two grayscale pixels",
    {1.98, -2.12}, "code", "result"
)

scene:fade_in(claim, {shift = {0, 0.08}, duration = 0.44, curve = "gentle"})
for _, group in ipairs(payloadGroups) do
    scene:fade_in(group, {shift = {0, 0.08}, duration = 0.34, curve = "ease_out"})
end
scene:create(concatenateArrow, 0.30, "ease_out")
scene:fade_in(concatenateLabel, {shift = {0.08, 0}, duration = 0.26, curve = "gentle"})
scene:fade_in(stream, {shift = {0, 0.10}, duration = 0.62, curve = "ease_out"})
scene:fade_in(streamLabel, {shift = {0, 0.05}, duration = 0.26, curve = "gentle"})
scene:create(inflateArrow, 0.32, "ease_out")
scene:fade_in(inflateLabel, {shift = {0.08, 0}, duration = 0.24, curve = "gentle"})
scene:fade_in(filteredRow, {shift = {0, 0.08}, duration = 0.42, curve = "ease_out"})
scene:fade_in(filteredLabel, {shift = {0, 0.05}, duration = 0.24, curve = "gentle"})
scene:create(unpackArrow, 0.30, "ease_out")
scene:fade_in(decoded, {shift = {-0.10, 0}, duration = 0.42, curve = "ease_out"})
scene:fade_in(decodedLabel, {shift = {0, 0.05}, duration = 0.24, curve = "gentle"})
scene:wait(1.8)
return scene
