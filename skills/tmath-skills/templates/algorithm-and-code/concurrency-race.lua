-- Question: how can two x++ operations legally finish with x == 1?
-- Variant: x++ is decomposed into read, increment, write; schedule A-read, B-read, A-write, B-write.
-- This is an illustrative interleaving, not a claim about a particular language memory model.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local LAYER = {guide = 8, route = 12, body = 20, text = 40, focus = 50}
local SCHEDULE = {
    {thread = "A", kind = "read", text = "rA = read(x)", observed = 0},
    {thread = "B", kind = "read", text = "rB = read(x)", observed = 0},
    {thread = "A", kind = "increment", text = "rA = rA + 1", result = 1},
    {thread = "B", kind = "increment", text = "rB = rB + 1", result = 1},
    {thread = "A", kind = "write", text = "write(x, rA)", value = 1},
    {thread = "B", kind = "write", text = "write(x, rB)", value = 1},
}
local shared, localValue = 0, {A = nil, B = nil}
for _, event in ipairs(SCHEDULE) do
    if event.kind == "read" then assert(shared == event.observed); localValue[event.thread] = shared
    elseif event.kind == "increment" then localValue[event.thread] = localValue[event.thread] + 1; assert(localValue[event.thread] == event.result)
    else assert(localValue[event.thread] == event.value); shared = event.value end
end
assert(shared == 1)

local title = scene:text {
    text = "Concurrency race · two increments, one lost update",
    point = {0, 230}, role = "h2", fill = "foreground",
    layer = LAYER.text, id = "scene-title",
}
local subtitle = scene:text {
    text = "x++ decomposed into read → increment → write · one valid interleaving",
    point = {0, 194}, role = "code", fill = "muted",
    layer = LAYER.text, id = "scene-subtitle",
}

local laneX = {A = -265, B = 0}
for _, thread in ipairs({"A", "B"}) do
    scene:text {
        text = "THREAD " .. thread, point = {laneX[thread], 145}, role = "code", fill = "accent",
        layer = LAYER.text, id = "thread:" .. thread .. ":label",
    }
    scene:line {
        from = {laneX[thread], 120}, to = {laneX[thread], -132},
        stroke = "muted", width = 2, dash = {7, 6}, layer = LAYER.guide,
        id = "thread:" .. thread .. ":lifeline",
    }
end
local timeArrow = scene:arrow {
    from = {-440, 120}, to = {-440, -132}, tip = 10,
    stroke = "muted", width = 2, layer = LAYER.guide, id = "time-axis",
}
local timeLabel = scene:text {
    text = "time", point = {-440, 145}, role = "code", fill = "muted",
    layer = LAYER.text, id = "time-label",
}

local memoryBody = scene:rectangle {
    center = {310, 45}, size = {230, 112}, corner = 8,
    fill = "surface", stroke = "border", width = 2,
    layer = LAYER.body, id = "shared:x:body",
}
local memoryLabel = scene:text {
    text = "shared x", point = {310, 77}, role = "code", fill = "muted",
    layer = LAYER.text, id = "shared:x:label",
}
local memoryValue = scene:text {
    text = "0", point = {310, 25}, role = "h3", fill = "foreground",
    layer = LAYER.text, id = "shared:x:value:0",
}
local registers = {}
for index, thread in ipairs({"A", "B"}) do
    local x = 250 + (index - 1) * 120
    local body = scene:rectangle {
        center = {x, -78}, size = {105, 62}, corner = 6,
        fill = "surface", stroke = "border", width = 2,
        layer = LAYER.body, id = "register:" .. thread .. ":body",
    }
    local value = scene:text {
        text = "r" .. thread .. " = ?", point = {x, -78}, role = "code", fill = "muted",
        layer = LAYER.text, id = "register:" .. thread .. ":value:0",
    }
    registers[thread] = {body = body, value = value, x = x, version = 0}
end

local eventGroups = {}
for index, event in ipairs(SCHEDULE) do
    local y = 102 - (index - 1) * 42
    local x = laneX[event.thread]
    local group = scene:group {id = "event:" .. index}
    group:rectangle {
        center = {x, y}, size = {230, 40}, corner = 4,
        fill = "surface", stroke = "border", width = 2,
        layer = LAYER.body, id = "event:" .. index .. ":body",
    }
    group:text {
        text = event.text, point = {x, y}, role = "code", fill = "foreground",
        layer = LAYER.text, id = "event:" .. index .. ":label",
    }
    eventGroups[index] = group
end

local status, statusVersion = nil, 0
local function setStatus(text, color)
    statusVersion = statusVersion + 1
    local nextStatus = scene:text {text = text, point = {0, -185}, role = "code", fill = color or "focus", layer = LAYER.text, id = "status:" .. statusVersion}
    if status then scene:fade_transform(status, nextStatus, 0.16, "gentle") else scene:fade_in(nextStatus, {duration = 0.22, curve = "gentle"}) end
    status = nextStatus
end
local function setRegister(thread, value)
    local register = registers[thread]
    register.version = register.version + 1
    local nextValue = scene:text {
        text = "r" .. thread .. " = " .. value, point = {register.x, -78}, role = "code", fill = "focus",
        layer = LAYER.text, id = "register:" .. thread .. ":value:" .. register.version,
    }
    scene:fade_transform(register.value, nextValue, 0.18, "gentle")
    register.value = nextValue
end
local memoryVersion = 0
local function setMemory(value, color)
    memoryVersion = memoryVersion + 1
    local nextValue = scene:text {
        text = tostring(value), point = {310, 25}, role = "h3", fill = color or "foreground",
        layer = LAYER.text, id = "shared:x:value:" .. memoryVersion,
    }
    scene:fade_transform(memoryValue, nextValue, 0.20, "gentle")
    memoryValue = nextValue
end

scene:fade_in(title, {shift = {0, -6}, duration = 0.42, curve = "gentle"})
scene:fade_in(subtitle, {shift = {0, -5}, duration = 0.34, curve = "gentle"})
scene:create(timeArrow, 0.30, "ease_out")
scene:fade_in(timeLabel, {duration = 0.20, curve = "gentle"})
scene:wait(0.32)

for index, event in ipairs(SCHEDULE) do
    scene:fade_in(eventGroups[index], {shift = {0, 4}, duration = 0.24, curve = "ease_out"})
    if event.kind == "read" then
        setStatus("thread " .. event.thread .. " reads x = " .. event.observed .. " into a private register")
        scene:play({{target = memoryBody, fill = "focus", stroke = "focus"}, {target = registers[event.thread].body, stroke = "focus"}}, 0.24, "ease_in_out", 0)
        setRegister(event.thread, event.observed)
        scene:play({{target = memoryBody, fill = "surface", stroke = "border"}}, 0.18, "ease_in_out", 0)
    elseif event.kind == "increment" then
        setStatus("thread " .. event.thread .. " computes locally; shared x is still 0")
        setRegister(event.thread, event.result)
    else
        local isLost = index == #SCHEDULE
        setStatus(isLost and "B writes stale 1 after A · A's update is overwritten" or "A writes 1 · B still holds a stale local 1", isLost and "danger" or "focus")
        scene:play({{target = registers[event.thread].body, stroke = "focus"}, {target = memoryBody, stroke = isLost and "danger" or "focus"}}, 0.22, "ease_in_out", 0)
        setMemory(event.value, isLost and "danger" or "foreground")
    end
    scene:wait(0.16)
end

local expectedGhost = scene:text {
    text = "expected after 2 increments: x = 2", point = {310, -145}, role = "code", fill = "success",
    layer = LAYER.text, id = "expected-result",
}
scene:fade_in(expectedGhost, {duration = 0.28, curve = "gentle"})
local result = scene:text {
    text = "observed x = 1 · read-modify-write was not atomic",
    point = {0, -225}, role = "text", fill = "danger",
    layer = LAYER.text, id = "result:lost-update",
}
scene:fade_transform(status, result, 0.24, "gentle")
scene:play({{target = memoryBody, fill = "surface", stroke = "danger"}}, 0.32, "ease_in_out", 0)
scene:wait(2.5)
return scene
