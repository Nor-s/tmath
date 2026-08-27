-- Question: how do recursive calls create activation records and return values to callers?
-- Variant: fact(n) returns 1 for n <= 1, otherwise n * fact(n - 1).
-- Edit INPUT_N; unique call IDs and the exact call/return trace are regenerated below.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local INPUT_N = 4
local LAYER = {guide = 8, body = 20, text = 40}

local function buildFactorialTrace(input)
    local events, calls, nextId, maxDepth = {}, {}, 0, 0
    local function evaluate(n, parentId, depth)
        nextId = nextId + 1
        local id = "call-" .. nextId
        local call = {id = id, parentId = parentId, n = n, depth = depth}
        calls[#calls + 1] = call
        if depth > maxDepth then maxDepth = depth end
        events[#events + 1] = {kind = "call", call = call, liveDepth = depth}

        local value, childId, childValue
        if n <= 1 then
            value = 1
        else
            local childCall
            childValue, childCall = evaluate(n - 1, id, depth + 1)
            childId = childCall.id
            value = n * childValue
        end
        call.value, call.childId, call.childValue = value, childId, childValue
        events[#events + 1] = {
            kind = "return", call = call, value = value,
            childValue = childValue, liveDepthAfter = depth - 1,
        }
        return value, call
    end
    local result = evaluate(input, nil, 1)
    return events, calls, result, maxDepth
end

local TRACE, CALLS, RESULT, MAX_DEPTH = buildFactorialTrace(INPUT_N)
local EXPECTED = 1
for value = 2, INPUT_N do EXPECTED = EXPECTED * value end
assert(INPUT_N >= 1 and INPUT_N == math.floor(INPUT_N))
assert(#CALLS == INPUT_N and RESULT == EXPECTED and MAX_DEPTH == INPUT_N)

local FRAME_X, FRAME_Y0, FRAME_STEP = 35, -78, 62
local function translate(x, y)
    return {1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, 0, 0, 0, 0, 1}
end

local title = scene:text {
    text = "Recursion · calls descend, values return",
    point = {0, 230}, role = "h2", fill = "foreground",
    layer = LAYER.text, id = "scene-title",
}
local subtitle = scene:text {
    text = "fact(n) = n × fact(n - 1) · base case n ≤ 1 returns 1",
    point = {0, 194}, role = "code", fill = "muted",
    layer = LAYER.text, id = "scene-subtitle",
}
local stackLabel = scene:text {
    text = "ACTIVATION STACK", point = {-330, 145}, role = "code",
    fill = "accent", layer = LAYER.text, id = "stack:label",
}
local stackDirection = scene:arrow {
    from = {-330, -105}, to = {-330, 115}, tip = 11,
    stroke = "accent", width = 2.5, layer = LAYER.guide,
    id = "stack:growth-direction",
}
local directionLabel = scene:text {
    text = "deeper calls", point = {-405, 8}, role = "code",
    fill = "muted", layer = LAYER.text, id = "stack:growth-label",
}

local frameLayer = scene:group {id = "stack:frames"}
local frames, bodies, details = {}, {}, {}
for _, call in ipairs(CALLS) do
    local y = FRAME_Y0 + (call.depth - 1) * FRAME_STEP
    local frame = frameLayer:group {
        matrix = translate(FRAME_X, y), id = "activation:" .. call.id,
    }
    bodies[call.id] = frame:rectangle {
        center = {0, 0}, size = {570, 52}, corner = 6,
        fill = "surface", stroke = "border", width = 2,
        layer = LAYER.body, id = "activation:" .. call.id .. ":body",
    }
    frame:text {
        text = call.id .. " · fact(" .. call.n .. ")",
        point = {-255, 0}, align = {-1, 0.5}, role = "code",
        fill = "foreground", layer = LAYER.text,
        id = "activation:" .. call.id .. ":label",
    }
    local waiting = call.n <= 1 and "base case: n ≤ 1" or ("waiting for fact(" .. (call.n - 1) .. ")")
    details[call.id] = frame:text {
        text = waiting, point = {-25, 0}, align = {-1, 0.5}, role = "code",
        fill = call.n <= 1 and "warning" or "muted", layer = LAYER.text,
        id = "activation:" .. call.id .. ":detail:waiting",
    }
    frames[call.id] = frame
end

local status, statusIndex = nil, 0
local function setStatus(message, color)
    statusIndex = statusIndex + 1
    local nextStatus = scene:text {
        text = message, point = {0, -165}, role = "code", fill = color or "focus",
        layer = LAYER.text, id = "status:" .. statusIndex,
    }
    if status then scene:fade_transform(status, nextStatus, 0.18, "gentle")
    else scene:fade_in(nextStatus, {duration = 0.25, curve = "gentle"}) end
    status = nextStatus
end

scene:fade_in(title, {shift = {0, -6}, duration = 0.42, curve = "gentle"})
scene:fade_in(subtitle, {shift = {0, -5}, duration = 0.34, curve = "gentle"})
scene:fade_in(stackLabel, {duration = 0.25, curve = "gentle"})
scene:create(stackDirection, 0.38, "ease_out")
scene:fade_in(directionLabel, {duration = 0.22, curve = "gentle"})

local activeCall = nil
for _, event in ipairs(TRACE) do
    local call = event.call
    if event.kind == "call" then
        if activeCall then
            scene:play({{target = bodies[activeCall], fill = "surface", stroke = "border"}},
                0.24, "ease_in_out", 0)
        end
        setStatus(string.format(
            "call %s: fact(%d) · live depth %d / max %d",
            call.id, call.n, event.liveDepth, MAX_DEPTH
        ))
        scene:fade_in(frames[call.id], {shift = {0, -8}, duration = 0.42, curve = "ease_out"})
        scene:play({{target = bodies[call.id], fill = "focus", stroke = "focus"}},
            0.30, "ease_in_out", 0)
        activeCall = call.id
        scene:wait(0.24)
    else
        local returnText
        if call.n <= 1 then
            returnText = "return 1 · base case"
        else
            returnText = string.format("return %d × %d = %d", call.n, event.childValue, event.value)
        end
        setStatus(call.id .. " returns " .. event.value .. " to " .. (call.parentId or "the program"),
            call.parentId and "focus" or "result")
        local returned = frames[call.id]:text {
            text = returnText, point = {-25, 0}, align = {-1, 0.5}, role = "code",
            fill = call.parentId and "success" or "result", layer = LAYER.text,
            id = "activation:" .. call.id .. ":detail:return",
        }
        scene:fade_transform(details[call.id], returned, 0.22, "gentle")
        details[call.id] = returned
        scene:play({{target = bodies[call.id], fill = "surface", stroke = "success"}},
            0.30, "ease_in_out", 0)
        scene:wait(0.28)

        if call.parentId then
            scene:play({
                {target = frames[call.id], opacity = 0.28},
                {target = bodies[call.parentId], fill = "focus", stroke = "focus"},
            }, 0.38, "ease_in_out", 0)
            activeCall = call.parentId
        else
            scene:play({{target = bodies[call.id], fill = "surface", stroke = "result"}},
                0.38, "ease_in_out", 0)
            activeCall = call.id
        end
    end
end

local result = scene:text {
    text = string.format("fact(%d) = %d · maximum live depth = %d", INPUT_N, RESULT, MAX_DEPTH),
    point = {0, -220}, role = "text", fill = "result",
    layer = LAYER.text, id = "result:factorial",
}
scene:fade_in(result, {shift = {0, 4}, duration = 0.38, curve = "gentle"})
scene:wait(2.3)
return scene
