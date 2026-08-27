-- local question: How does a muxer interleave encoded audio and video packets?
-- visible input: video and audio packet queues expressed in different time bases
-- subject object or field: DTS rescaling and the resulting container write order
-- one dominant action: repeatedly select the earliest next packet in common seconds
-- observable output: one monotonically interleaved packet stream with timestamps preserved
-- coordinate frame and units: raw DTS ticks are converted to milliseconds for comparison
-- section bounds supplied by the parent: standalone 960 x 540 wrapper
-- final readable pose: both source queues and the complete muxed packet order

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = {
        preset = "3_blue_1_eyes",
        text = {text = {size = 15}, code = {size = 13}},
    },
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local LAYER = {route = -10, object = 0, packet = 20, text = 40}
local figure = scene:group {id = "video-mux-interleave-figure"}

local function text(parent, id, value, point, role, fill, align)
    return parent:text {
        id = id, text = value, point = point, role = role or "code",
        fill = fill or "foreground", align = align or {0.5, 0.5}, layer = LAYER.text,
    }
end

local function milliseconds(dts, numerator, denominator)
    return dts * numerator * 1000 / denominator
end

local videoTicks = {0, 1, 2}
local audioTicks = {512, 1536, 2560, 3584}
local packets = {}
for index, dts in ipairs(videoTicks) do
    packets[#packets + 1] = {
        id = "V" .. tostring(index - 1), kind = "video", dts = dts,
        numerator = 1, denominator = 30, color = "info", sourceIndex = index,
    }
end
for index, dts in ipairs(audioTicks) do
    packets[#packets + 1] = {
        id = "A" .. tostring(index - 1), kind = "audio", dts = dts,
        numerator = 1, denominator = 48000, color = "warning", sourceIndex = index,
    }
end
for _, packet in ipairs(packets) do
    packet.ms = milliseconds(packet.dts, packet.numerator, packet.denominator)
end

local interleaved = {}
for index, packet in ipairs(packets) do interleaved[index] = packet end
table.sort(interleaved, function(first, second)
    if first.ms == second.ms then return first.id < second.id end
    return first.ms < second.ms
end)

local claim = text(
    figure, "video-mux-claim",
    "Muxing compares timestamps only after rescaling their time bases",
    {0, 2.62}, "h3"
)
local rule = text(
    figure, "video-mux-rule",
    "time_ms = DTS x time_base x 1000   ·   write the earliest available DTS",
    {0, 2.17}, "code", "muted"
)

local laneSpecs = {
    video = {y = 1.22, startX = -2.85, step = 2.10, label = "video", timeBase = "tb 1/30", color = "info"},
    audio = {y = 0.32, startX = -2.85, step = 2.10, label = "audio", timeBase = "tb 1/48000", color = "warning"},
}
local inputGroups = {}
local laneGroups = {
    video = figure:group {id = "video-mux-video-inputs"},
    audio = figure:group {id = "video-mux-audio-inputs"},
}
local laneScaffold = figure:group {id = "video-mux-lane-scaffold"}

for _, kind in ipairs({"video", "audio"}) do
    local lane = laneSpecs[kind]
    text(
        laneScaffold, "video-mux-" .. kind .. "-lane-label", lane.label,
        {-4.90, lane.y + 0.11}, "text", lane.color, {0, 0.5}
    )
    text(
        laneScaffold, "video-mux-" .. kind .. "-time-base", lane.timeBase,
        {-4.90, lane.y - 0.14}, "code", "muted", {0, 0.5}
    )
    laneScaffold:line {
        id = "video-mux-" .. kind .. "-lane",
        from = {-3.72, lane.y - 0.40}, to = {4.40, lane.y - 0.40},
        stroke = "border", width = 1.4, layer = LAYER.route,
    }
end

for _, packet in ipairs(packets) do
    local lane = laneSpecs[packet.kind]
    local x = lane.startX + (packet.sourceIndex - 1) * lane.step
    local group = laneGroups[packet.kind]:group {id = "video-mux-input-" .. packet.id}
    group:rectangle {
        id = "video-mux-input-" .. packet.id .. "-body",
        center = {x, lane.y}, size = {1.72, 0.68},
        fill = "surface", stroke = packet.color, width = 1.8, layer = LAYER.object,
    }
    text(group, "video-mux-input-" .. packet.id .. "-name", packet.id, {x - 0.52, lane.y}, "code", packet.color)
    text(
        group, "video-mux-input-" .. packet.id .. "-dts",
        string.format("dts %d", packet.dts), {x + 0.11, lane.y + 0.11}, "code", "foreground"
    )
    text(
        group, "video-mux-input-" .. packet.id .. "-ms",
        string.format("%.1f ms", packet.ms), {x + 0.11, lane.y - 0.14}, "code", "muted"
    )
    inputGroups[packet.id] = group
end

local mergeArrow = figure:arrow {
    id = "video-mux-merge-arrow", from = {0, -0.10}, to = {0, -0.38},
    stroke = "focus", width = 2.2, tip = 11, layer = LAYER.route,
}
local muxNode = figure:group {id = "video-mux-node"}
muxNode:rectangle {
    id = "video-mux-node-body", center = {0, -0.67}, size = {2.58, 0.58},
    fill = "surface", stroke = "focus", width = 2, layer = LAYER.object,
}
text(muxNode, "video-mux-node-label", "MUX · rescale + interleave", {0, -0.67}, "code", "focus")

local outputArrow = figure:arrow {
    id = "video-mux-output-arrow", from = {0, -0.96}, to = {0, -1.25},
    stroke = "focus", width = 2.2, tip = 11, layer = LAYER.route,
}

local outputY = -1.58
local outputStart, outputStep = -3.62, 1.20
local outputGroups = {}
for index, packet in ipairs(interleaved) do
    local x = outputStart + (index - 1) * outputStep
    local group = figure:group {id = string.format("video-mux-output-%02d", index)}
    group:rectangle {
        id = string.format("video-mux-output-%02d-body", index),
        center = {x, outputY}, size = {0.92, 0.60},
        fill = packet.color, stroke = "foreground", width = 1.2, layer = LAYER.packet,
    }
    text(
        group, string.format("video-mux-output-%02d-name", index), packet.id,
        {x, outputY + 0.10}, "code", "#ffffffff"
    )
    text(
        group, string.format("video-mux-output-%02d-ms", index),
        string.format("%.1f", packet.ms), {x, outputY - 0.13}, "code", "#ffffffff"
    )
    outputGroups[index] = group
end

local outputLabel = text(
    figure, "video-mux-output-label",
    "container write order (ms)", {-4.75, -1.08}, "code", "result", {0, 0.5}
)
local summary = text(
    figure, "video-mux-summary",
    "DTS orders decode/interleave; PTS is retained for later presentation",
    {0, -2.34}, "code", "result"
)

scene:fade_in(claim, {shift = {0, 0.08}, duration = 0.42, curve = "gentle"})
scene:fade_in(rule, {shift = {0, 0.05}, duration = 0.32, curve = "gentle"})
scene:fade_in(laneScaffold, {duration = 0.30, curve = "gentle"})
scene:fade_in(laneGroups.video, {shift = {0, 0.05}, duration = 0.52, curve = "ease_out"})
scene:fade_in(laneGroups.audio, {shift = {0, -0.05}, duration = 0.58, curve = "ease_out"})
scene:create(mergeArrow, 0.26, "ease_out")
scene:fade_in(muxNode, {shift = {0, 0.04}, duration = 0.34, curve = "gentle"})
scene:create(outputArrow, 0.24, "ease_out")
scene:fade_in(outputLabel, {shift = {0.04, 0}, duration = 0.26, curve = "gentle"})

for index, packet in ipairs(interleaved) do
    scene:indicate(inputGroups[packet.id], {
        color = packet.color, scale = 1.025, duration = 0.24, curve = "ease_in_out",
    })
    scene:fade_in(outputGroups[index], {shift = {0, 0.08}, duration = 0.22, curve = "ease_out"})
end

scene:fade_in(summary, {shift = {0, -0.05}, duration = 0.34, curve = "gentle"})
scene:wait(2.0)
return scene
