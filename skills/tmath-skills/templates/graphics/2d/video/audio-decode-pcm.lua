-- local question: What does an audio decoder hand to the playback pipeline?
-- visible input: one encoded packet and eight decoded stereo sample frames
-- subject object or field: two PCM waveforms plus their interleaved signed-16 memory order
-- one dominant action: synthesize codec data into channel samples at fixed sampling instants
-- observable output: an S16 interleaved PCM frame with derived duration and sample values
-- coordinate frame and units: 48 kHz sampling instants and signed 16-bit amplitudes
-- section bounds supplied by the parent: standalone 960 x 540 wrapper
-- final readable pose: decoder spine, channel plots, and complete L/R memory sequence

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "3_blue_1_eyes",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local LAYER = {route = -10, object = 0, point = 10, text = 40}
local figure = scene:group {id = "audio-decode-pcm-figure"}

local function text(parent, id, value, point, role, fill, align)
    return parent:text {
        id = id, text = value, point = point, role = role or "code",
        fill = fill or "foreground", align = align or {0.5, 0.5}, layer = LAYER.text,
    }
end

local function roundS16(value)
    local rounded = value >= 0 and math.floor(value + 0.5) or math.ceil(value - 0.5)
    return math.max(-32768, math.min(32767, rounded))
end

local sampleRate = 48000
local channelCount = 2
local frameCount = 8
local frequency = 6000
local amplitudeLeft = 0.75
local amplitudeRight = 0.55
local phaseRight = math.pi / 3
local durationMs = frameCount * 1000 / sampleRate
local left, right = {}, {}
for index = 0, frameCount - 1 do
    local phase = 2 * math.pi * frequency * index / sampleRate
    left[index + 1] = roundS16(32767 * amplitudeLeft * math.sin(phase))
    right[index + 1] = roundS16(32767 * amplitudeRight * math.sin(phase + phaseRight))
end

local claim = text(
    figure, "audio-decode-pcm-claim",
    "Audio decoders turn coded packets into clocked PCM samples",
    {0, 2.62}, "h3"
)
local contract = text(
    figure, "audio-decode-pcm-contract",
    string.format("%d Hz · %d channels · S16 interleaved · %d sample frames", sampleRate, channelCount, frameCount),
    {0, 2.18}, "code", "muted"
)

local stageNames = {"encoded packet", "codec synthesis", "PCM frame", "audio device"}
local stageDetails = {"compressed bytes", "codec-specific", "samples", "clocked playback"}
local stageXs = {-3.78, -1.26, 1.26, 3.78}
local stages, arrows = {}, {}
for index, name in ipairs(stageNames) do
    local group = figure:group {id = string.format("audio-decode-stage-%02d", index)}
    group:rectangle {
        id = string.format("audio-decode-stage-%02d-body", index),
        center = {stageXs[index], 1.44}, size = {1.94, 0.66},
        fill = "surface", stroke = index == 3 and "result" or "border",
        width = 1.6, layer = LAYER.object,
    }
    text(
        group, string.format("audio-decode-stage-%02d-name", index), name,
        {stageXs[index], 1.59}, "code", index == 3 and "result" or "foreground"
    )
    text(
        group, string.format("audio-decode-stage-%02d-detail", index), stageDetails[index],
        {stageXs[index], 1.25}, "code", "muted"
    )
    stages[index] = group
    if index < #stageNames then
        arrows[index] = figure:arrow {
            id = string.format("audio-decode-stage-arrow-%02d", index),
            from = {stageXs[index] + 1.00, 1.44}, to = {stageXs[index + 1] - 1.00, 1.44},
            stroke = "muted", width = 1.7, tip = 9, layer = LAYER.route,
        }
    end
end

local waveSpace = figure:space {
    id = "audio-decode-wave-space", x = {0, frameCount - 1, 1}, y = {-1.2, 1.2, 0.5}, opacity = 0,
    matrix = {
        0.72, 0, 0, -0.72 * (frameCount - 1) / 2,
        0, 0.72, 0, 0.05,
        0, 0, 1, 0,
        0, 0, 0, 1,
    },
}
local leftPoints, rightPoints = {}, {}
for index = 0, frameCount - 1 do
    leftPoints[#leftPoints + 1] = {index, 0.48 + 0.42 * left[index + 1] / 32768}
    rightPoints[#rightPoints + 1] = {index, -0.48 + 0.42 * right[index + 1] / 32768}
end
local leftPlot = waveSpace:plot {
    id = "audio-decode-left-wave", points = leftPoints,
    stroke = "info", width = 2.5, layer = LAYER.object,
}
local rightPlot = waveSpace:plot {
    id = "audio-decode-right-wave", points = rightPoints,
    stroke = "warning", width = 2.5, layer = LAYER.object,
}
local wavePoints = waveSpace:group {id = "audio-decode-wave-points"}
for index = 0, frameCount - 1 do
    wavePoints:point {
        id = string.format("audio-decode-left-point-%02d", index),
        point = leftPoints[index + 1], radius = 4, fill = "info", layer = LAYER.point,
    }
    wavePoints:point {
        id = string.format("audio-decode-right-point-%02d", index),
        point = rightPoints[index + 1], radius = 4, fill = "warning", layer = LAYER.point,
    }
end
local leftChannelLabel = text(figure, "audio-decode-left-label", "L", {-3.12, 0.40}, "code", "info")
local rightChannelLabel = text(figure, "audio-decode-right-label", "R", {-3.12, -0.33}, "code", "warning")
local waveformLabel = text(
    figure, "audio-decode-waveform-label", "sample amplitude, n = 0 ... 7",
    {4.55, 0.05}, "code", "muted", {1, 0.5}
)

local memoryY = -1.18
local memoryStart, memoryStep = -4.27, 0.57
local memory = figure:group {id = "audio-decode-interleaved-memory"}
local selectedFrame = 3
for frame = 0, frameCount - 1 do
    local channels = {
        {name = "L", color = "info"},
        {name = "R", color = "warning"},
    }
    for channelIndex, channel in ipairs(channels) do
        local slot = frame * channelCount + channelIndex
        local x = memoryStart + (slot - 1) * memoryStep
        memory:rectangle {
            id = string.format("audio-decode-memory-slot-%02d", slot),
            center = {x, memoryY}, size = {0.52, 0.48},
            fill = channel.color,
            stroke = frame == selectedFrame and "focus" or "foreground",
            width = frame == selectedFrame and 2.4 or 1.0,
            layer = LAYER.object,
        }
        text(
            memory, string.format("audio-decode-memory-label-%02d", slot),
            channel.name .. tostring(frame), {x, memoryY}, "code", "#ffffffff"
        )
    end
end
local memoryLabel = text(
    figure, "audio-decode-memory-title",
    "S16 interleaved memory: one L/R pair per sampling instant",
    {0, -0.83}, "code", "foreground"
)
local selectedValue = text(
    figure, "audio-decode-selected-value",
    string.format("frame %d -> L %d, R %d", selectedFrame, left[selectedFrame + 1], right[selectedFrame + 1]),
    {0, -1.67}, "code", "focus"
)
local summary = text(
    figure, "audio-decode-pcm-summary",
    string.format("duration = %d / %d s = %.3f ms; planar PCM would store one array per channel", frameCount, sampleRate, durationMs),
    {0, -2.24}, "code", "result"
)

scene:fade_in(claim, {shift = {0, 0.08}, duration = 0.42, curve = "gentle"})
scene:fade_in(contract, {shift = {0, 0.05}, duration = 0.32, curve = "gentle"})
for index, stage in ipairs(stages) do
    scene:fade_in(stage, {shift = {0, 0.05}, duration = 0.28, curve = "ease_out"})
    if arrows[index] then scene:create(arrows[index], 0.20, "ease_out") end
end
scene:create({leftChannelLabel, rightChannelLabel}, 0.22, "ease_out", 0.04)
scene:create({leftPlot, rightPlot}, 0.58, "linear", 0)
scene:fade_in(wavePoints, {duration = 0.30, curve = "gentle"})
scene:fade_in(waveformLabel, {shift = {0.04, 0}, duration = 0.26, curve = "gentle"})
scene:fade_in(memoryLabel, {shift = {0, -0.04}, duration = 0.28, curve = "gentle"})
scene:fade_in(memory, {shift = {0, 0.06}, duration = 0.62, curve = "ease_out"})
scene:fade_in(selectedValue, {shift = {0, -0.04}, duration = 0.28, curve = "gentle"})
scene:fade_in(summary, {shift = {0, -0.04}, duration = 0.34, curve = "gentle"})
scene:wait(2.0)
return scene
