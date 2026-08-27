-- local question: What does a demuxer do with interleaved media packets?
-- visible input: four container packets in stored read order
-- subject object or field: packet stream_index, DTS, and two output queues
-- one dominant action: route each named packet to the queue selected by stream_index
-- observable output: coded video and audio packets remain timestamped but are not decoded
-- coordinate frame and units: packet DTS values remain in each stream's own time base
-- section bounds supplied by the parent: standalone 960 x 540 wrapper
-- final readable pose: stored input order beside populated video/audio packet queues

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "3_blue_1_eyes",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local LAYER = {zone = -20, route = -10, object = 0, packet = 20, text = 40}
local figure = scene:group {id = "video-demux-packet-routing-figure"}

local function text(parent, id, value, point, role, fill, align)
    return parent:text {
        id = id, text = value, point = point, role = role or "code",
        fill = fill or "foreground", align = align or {0.5, 0.5}, layer = LAYER.text,
    }
end

local packets = {
    {name = "V0", stream = 0, dts = 0, color = "info", startY = 1.28, queue = "video", slot = 1},
    {name = "A0", stream = 1, dts = 0, color = "warning", startY = 0.62, queue = "audio", slot = 1},
    {name = "A1", stream = 1, dts = 1024, color = "warning", startY = -0.04, queue = "audio", slot = 2},
    {name = "V1", stream = 0, dts = 1, color = "info", startY = -0.70, queue = "video", slot = 2},
}

local inputX = -4.20
local demuxCenter = {-1.50, 0.30}
local videoY, audioY = 1.02, -0.82
local queueStart, queueStep = 1.30, 1.34

local claim = text(
    figure, "video-demux-claim",
    "A demuxer separates interleaved packets by stream_index",
    {0, 2.62}, "h3"
)
local inputLabel = text(
    figure, "video-demux-input-label",
    "container read order",
    {inputX, 1.82}, "code", "muted"
)

local inputSlots = figure:group {id = "video-demux-input-slots"}
for index, packet in ipairs(packets) do
    inputSlots:rectangle {
        id = string.format("video-demux-input-slot-%02d", index),
        center = {inputX, packet.startY}, size = {0.92, 0.56},
        fill = "#00000000", stroke = "border", width = 1.3, dash = {4, 3},
        layer = LAYER.object,
    }
end

local inputRoute = figure:arrow {
    id = "video-demux-input-route",
    from = {-3.55, demuxCenter[2]}, to = {-2.38, demuxCenter[2]},
    stroke = "foreground", width = 2, tip = 11, layer = LAYER.route,
}
local videoRoute = figure:route {
    id = "video-demux-video-route",
    points = {
        {-0.62, 0.52}, {0.05, 0.52}, {0.05, videoY}, {0.72, videoY},
    },
    stroke = "info", width = 2.2, tip = 11, layer = LAYER.route,
}
local audioRoute = figure:route {
    id = "video-demux-audio-route",
    points = {
        {-0.62, 0.08}, {0.05, 0.08}, {0.05, audioY}, {0.72, audioY},
    },
    stroke = "warning", width = 2.2, tip = 11, layer = LAYER.route,
}

local demux = figure:group {id = "video-demux-node"}
demux:rectangle {
    id = "video-demux-node-body", center = demuxCenter, size = {1.62, 1.18},
    fill = "surface", stroke = "focus", width = 2.2, layer = LAYER.object,
}
text(demux, "video-demux-node-label", "DEMUX", {demuxCenter[1], 0.47}, "h3", "focus")
text(demux, "video-demux-node-detail", "stream map", {demuxCenter[1], 0.12}, "code", "muted")

local function makeQueue(id, label, detail, y, color)
    local queue = figure:group {id = id}
    queue:rectangle {
        id = id .. "-body", center = {2.85, y}, size = {4.28, 0.88},
        fill = "surface", stroke = color, width = 1.7, layer = LAYER.zone,
    }
    text(queue, id .. "-label", label, {0.88, y + 0.62}, "code", color, {0, 0.5})
    text(queue, id .. "-detail", detail, {4.84, y + 0.62}, "code", "muted", {1, 0.5})
    for slot = 1, 3 do
        queue:rectangle {
            id = string.format("%s-slot-%02d", id, slot),
            center = {queueStart + (slot - 1) * queueStep, y - 0.10}, size = {0.92, 0.56},
            fill = "#00000000", stroke = "border", width = 1.1, layer = LAYER.object,
        }
    end
    return queue
end

local videoQueue = makeQueue(
    "video-demux-video-queue", "video queue", "s0 · tb 1/30", videoY, "info"
)
local audioQueue = makeQueue(
    "video-demux-audio-queue", "audio queue", "s1 · tb 1/48000", audioY, "warning"
)

local packetLayer = figure:group {id = "video-demux-packets"}
local packetGroups = {}
for index, packet in ipairs(packets) do
    local group = packetLayer:group {id = string.format("video-demux-packet-%02d", index)}
    group:rectangle {
        id = string.format("video-demux-packet-%02d-body", index),
        center = {inputX, packet.startY}, size = {1.04, 0.48},
        fill = packet.color, stroke = "foreground", width = 1.1, layer = LAYER.packet,
    }
    text(
        group, string.format("video-demux-packet-%02d-label", index),
        string.format("%s · d%d", packet.name, packet.dts), {inputX, packet.startY}, "code", "#ffffffff"
    )
    packetGroups[index] = group
end

local outputLayer = figure:group {id = "video-demux-output-packets"}
local outputPackets = {}
for index, packet in ipairs(packets) do
    local destinationY = packet.queue == "video" and videoY or audioY
    local destinationX = queueStart + (packet.slot - 1) * queueStep
    local group = outputLayer:group {id = string.format("video-demux-output-%02d", index)}
    group:rectangle {
        id = string.format("video-demux-output-%02d-body", index),
        center = {destinationX, destinationY - 0.10}, size = {1.14, 0.48},
        fill = packet.color, stroke = "foreground", width = 1.1, layer = LAYER.packet,
    }
    text(
        group, string.format("video-demux-output-%02d-label", index),
        string.format("%s · d%d", packet.name, packet.dts),
        {destinationX, destinationY - 0.10}, "code", "#ffffffff"
    )
    outputPackets[index] = group
end

local legend = text(
    figure, "video-demux-legend",
    "V = coded video packet   ·   A = coded audio packet",
    {0, -1.72}, "code", "muted"
)
local summary = text(
    figure, "video-demux-summary",
    "Demux preserves packet payload + PTS/DTS; decoding happens after the queues",
    {0, -2.28}, "code", "result"
)

scene:fade_in(claim, {shift = {0, 0.08}, duration = 0.42, curve = "gentle"})
scene:fade_in(inputLabel, {shift = {0, 0.04}, duration = 0.26, curve = "gentle"})
scene:fade_in(inputSlots, {duration = 0.32, curve = "gentle"})
scene:create(inputRoute, 0.34, "ease_out")
scene:fade_in(demux, {shift = {0, 0.06}, duration = 0.42, curve = "ease_out"})
scene:create({videoRoute, audioRoute}, 0.48, "ease_out", 0.08)
scene:fade_in(videoQueue, {shift = {0, 0.05}, duration = 0.40, curve = "gentle"})
scene:fade_in(audioQueue, {shift = {0, -0.05}, duration = 0.40, curve = "gentle"})
scene:fade_in(packetLayer, {duration = 0.38, curve = "gentle"})

for index, packet in ipairs(packets) do
    scene:indicate(packetGroups[index], {
        color = packet.color, scale = 1.03, duration = 0.28, curve = "ease_in_out",
    })
    scene:fade_in(outputPackets[index], {shift = {-0.08, 0}, duration = 0.28, curve = "ease_out"})
end

scene:fade_in(legend, {shift = {0, -0.04}, duration = 0.28, curve = "gentle"})
scene:fade_in(summary, {shift = {0, -0.05}, duration = 0.34, curve = "gentle"})
scene:wait(2.0)
return scene
