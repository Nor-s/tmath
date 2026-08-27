-- local question: How does a player decide whether to drop, present, or wait for a video frame?
-- visible input: one audio-master clock and three queued video-frame PTS values
-- subject object or field: a shared millisecond timeline and signed PTS deltas
-- one dominant action: compare each frame PTS with the current master clock
-- observable output: one late frame drops, one aligned frame presents, and one early frame waits
-- coordinate frame and units: all timestamps are rescaled to milliseconds on one presentation timeline
-- section bounds supplied by the parent: standalone 960 x 540 wrapper
-- final readable pose: playhead, frames, deltas, policy thresholds, and decisions

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "3_blue_1_eyes",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local LAYER = {guide = -10, object = 0, playhead = 20, text = 40}
local figure = scene:group {id = "av-sync-clock-figure"}

local function text(parent, id, value, point, role, fill, align)
    return parent:text {
        id = id, text = value, point = point, role = role or "code",
        fill = fill or "foreground", align = align or {0.5, 0.5}, layer = LAYER.text,
    }
end

local timelineMin, timelineMax = 0, 140
local timelineLeft, timelineRight = -4.55, 4.55
local function xAt(milliseconds)
    return timelineLeft + (milliseconds - timelineMin) * (timelineRight - timelineLeft) / (timelineMax - timelineMin)
end

local audioClock = 72
local lateDropThreshold = 25
local earlyWaitThreshold = 12
local framePts = {33.3, 66.7, 100.0}

local decisions = {}
for index, pts in ipairs(framePts) do
    local delta = pts - audioClock
    local action, color
    if delta < -lateDropThreshold then
        action, color = "DROP", "danger"
    elseif delta <= earlyWaitThreshold then
        action, color = "PRESENT", "result"
    else
        action, color = "WAIT", "warning"
    end
    decisions[index] = {pts = pts, delta = delta, action = action, color = color}
end

local claim = text(
    figure, "av-sync-claim",
    "A/V sync schedules video PTS against one master clock",
    {0, 2.62}, "h3"
)
local scope = text(
    figure, "av-sync-scope",
    "audio-master example · video, audio, or an external clock may be selected by policy",
    {0, 2.18}, "code", "muted"
)

local axisY = 0.28
local timeline = figure:arrow {
    id = "av-sync-timeline", from = {timelineLeft, axisY}, to = {timelineRight, axisY},
    stroke = "foreground", width = 2.2, tip = 11, layer = LAYER.guide,
}
local tickValues = {0, 40, 80, 120, 140}
local ticks = figure:group {id = "av-sync-ticks"}
for index, value in ipairs(tickValues) do
    local x = xAt(value)
    ticks:line {
        id = string.format("av-sync-tick-%02d-line", index),
        from = {x, axisY - 0.10}, to = {x, axisY + 0.10},
        stroke = "muted", width = 1.5, layer = LAYER.guide,
    }
    text(
        ticks, string.format("av-sync-tick-%02d-label", index),
        string.format("%g", value), {x, axisY - 0.28}, "code", "muted"
    )
end
local axisLabel = text(
    figure, "av-sync-axis-label", "ms",
    {timelineRight - 0.08, axisY + 0.26}, "code", "muted", {1, 0.5}
)

local frames = figure:group {id = "av-sync-video-frames"}
local decisionLabels = {}
local actionLabels = {}
for index, decision in ipairs(decisions) do
    local x = xAt(decision.pts)
    frames:line {
        id = string.format("av-sync-frame-%02d-guide", index),
        from = {x, axisY}, to = {x, 1.00}, stroke = "border", width = 1.3,
        dash = {4, 3}, layer = LAYER.guide,
    }
    frames:rectangle {
        id = string.format("av-sync-frame-%02d-body", index),
        center = {x, 1.22}, size = {1.28, 0.62},
        fill = "surface", stroke = decision.color, width = 2.0, layer = LAYER.object,
    }
    text(
        frames, string.format("av-sync-frame-%02d-name", index),
        "F" .. tostring(index - 1), {x, 1.34}, "code", decision.color
    )
    text(
        frames, string.format("av-sync-frame-%02d-pts", index),
        string.format("PTS %.1f", decision.pts), {x, 1.08}, "code", "foreground"
    )
    decisionLabels[index] = text(
        figure, string.format("av-sync-frame-%02d-decision", index),
        string.format("%+.1f ms", decision.delta),
        {x, -0.30}, "code", decision.color
    )
    actionLabels[index] = text(
        figure, string.format("av-sync-frame-%02d-action", index),
        decision.action, {x, -0.62}, "code", decision.color
    )
end
local videoQueueLabel = text(
    figure, "av-sync-video-queue-label", "video PTS queue",
    {timelineRight, 1.72}, "code", "foreground", {1, 0.5}
)

local audioRail = figure:group {id = "av-sync-audio-rail"}
audioRail:rectangle {
    id = "av-sync-audio-rail-body",
    center = {(timelineLeft + timelineRight) / 2, -1.02},
    size = {timelineRight - timelineLeft, 0.42}, fill = "surface",
    stroke = "info", width = 1.8, layer = LAYER.object,
}
text(
    audioRail, "av-sync-audio-rail-label",
    "PCM playback advances the audio clock continuously",
    {timelineLeft + 0.18, -1.02}, "code", "info", {0, 0.5}
)

local playheadStart = xAt(timelineMin)
local playheadTarget = xAt(audioClock)
local playhead = figure:group {id = "av-sync-audio-playhead"}
playhead:line {
    id = "av-sync-audio-playhead-line",
    from = {playheadStart, -1.38}, to = {playheadStart, 1.72},
    stroke = "focus", width = 3, layer = LAYER.playhead,
}
text(
    playhead, "av-sync-audio-playhead-label",
    string.format("A %.1f ms", audioClock),
    {playheadStart + 0.16, 1.82}, "code", "focus", {0, 0.5}
)

local policy = text(
    figure, "av-sync-policy",
    string.format("example policy: delta < -%d ms drop · delta <= +%d ms present · otherwise wait", lateDropThreshold, earlyWaitThreshold),
    {0, -1.62}, "code", "foreground"
)
local summary = text(
    figure, "av-sync-summary",
    "Decoding fills queues; the scheduler—not the decoder—chooses presentation time",
    {0, -2.26}, "code", "result"
)

scene:fade_in(claim, {shift = {0, 0.08}, duration = 0.42, curve = "gentle"})
scene:fade_in(scope, {shift = {0, 0.05}, duration = 0.32, curve = "gentle"})
scene:fade_in(videoQueueLabel, {shift = {0.05, 0}, duration = 0.24, curve = "gentle"})
scene:create(timeline, 0.62, "linear")
scene:fade_in(ticks, {duration = 0.34, curve = "gentle"})
scene:fade_in(axisLabel, {duration = 0.22, curve = "gentle"})
scene:fade_in(frames, {shift = {0, 0.06}, duration = 0.58, curve = "ease_out"})
scene:fade_in(audioRail, {shift = {0, -0.05}, duration = 0.42, curve = "gentle"})
scene:fade_in(playhead, {duration = 0.24, curve = "gentle"})
scene:shift(playhead, {playheadTarget - playheadStart, 0}, 1.20, "linear")
scene:create(decisionLabels, 0.34, "ease_out", 0.06)
scene:create(actionLabels, 0.30, "ease_out", 0.06)
scene:fade_in(policy, {shift = {0, -0.04}, duration = 0.32, curve = "gentle"})
scene:fade_in(summary, {shift = {0, -0.04}, duration = 0.34, curve = "gentle"})
scene:wait(2.0)
return scene
