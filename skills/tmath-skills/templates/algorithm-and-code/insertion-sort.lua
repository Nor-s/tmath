-- Question: why is insertion into a sorted prefix a sequence of shifts, not swaps?
-- This scene shows one iteration: insert key 4 from index 3 into [2, 5, 7].
-- Edit VALUES and KEY_INDEX; the strict-greater-than shift trace is regenerated below.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local VALUES = {
    {id = "a", value = 2}, {id = "b", value = 5}, {id = "c", value = 7},
    {id = "key", value = 4}, {id = "e", value = 9},
}
local KEY_INDEX = 4 -- Lua position; the displayed zero-based index is 3.

local function buildInsertionTrace(values, keyIndex)
    assert(keyIndex >= 2 and keyIndex <= #values)
    for index = 2, keyIndex - 1 do
        assert(values[index - 1].value <= values[index].value)
    end

    local state, trace = {}, {}
    for index, item in ipairs(values) do state[index] = item end
    local key = state[keyIndex]
    local scan = keyIndex - 1
    while scan >= 1 and state[scan].value > key.value do
        trace[#trace + 1] = {
            kind = "shift", item = state[scan], source = scan, destination = scan + 1,
        }
        state[scan + 1] = state[scan]
        scan = scan - 1
    end
    trace[#trace + 1] = {
        kind = "write", compared = scan >= 1 and state[scan] or nil,
        destination = scan + 1, key = key,
    }
    state[scan + 1] = key
    for index = 2, keyIndex do assert(state[index - 1].value <= state[index].value) end
    return trace, state, scan + 1, key
end

local TRACE, RESULT_STATE, DESTINATION, KEY = buildInsertionTrace(VALUES, KEY_INDEX)
local PREFIX_LABELS = {}
for index = 1, KEY_INDEX - 1 do PREFIX_LABELS[index] = tostring(VALUES[index].value) end
local RESULT_LABELS = {}
for index, item in ipairs(RESULT_STATE) do RESULT_LABELS[index] = tostring(item.value) end
local STEP, START_X, Y = 96, -192, 10
local LIFT = 92
local LAYER = {range = 8, slot = 10, token = 20, text = 40}

local function translate(x, y)
    return {1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, 0, 0, 0, 0, 1}
end

local title = scene:text {
    text = "Insertion Sort · one insertion", point = {0, 220}, role = "h2",
    fill = "foreground", layer = LAYER.text, id = "scene-title",
}
local contract = scene:text {
    text = string.format(
        "sorted prefix [%s]  ·  key = %s",
        table.concat(PREFIX_LABELS, ", "),
        tostring(KEY.value)
    ),
    point = {0, 182}, role = "code", fill = "muted",
    layer = LAYER.text, id = "insertion-contract",
}

local slots = scene:group {id = "insertion:slots"}
local tokenLayer = scene:group {id = "insertion:values"}
local tokensById, bodiesById, labelsById = {}, {}, {}
for index, spec in ipairs(VALUES) do
    local x = START_X + (index - 1) * STEP
    slots:rectangle {
        center = {x, Y}, size = {82, 78}, corner = 5,
        fill = "surface", stroke = "border", width = 2,
        layer = LAYER.slot, id = "array-slot:" .. (index - 1),
    }
    slots:text {
        text = tostring(index - 1), point = {x, Y - 57}, role = "code",
        fill = "muted", layer = LAYER.text, id = "array-index:" .. (index - 1),
    }
    local token = tokenLayer:group {matrix = translate(x, Y), id = "value:" .. spec.id}
    local body = token:rectangle {
        center = {0, 0}, size = {68, 64}, corner = 5,
        fill = "surface", stroke = spec.id == KEY.id and "warning" or "foreground",
        width = spec.id == KEY.id and 3 or 2, layer = LAYER.token,
        id = "value:" .. spec.id .. ":body",
    }
    labelsById[spec.id] = token:text {
        text = tostring(spec.value), point = {0, 0}, role = "h3",
        fill = spec.id == KEY.id and "warning" or "foreground",
        layer = LAYER.text, id = "value:" .. spec.id .. ":label",
    }
    tokensById[spec.id], bodiesById[spec.id] = token, body
end

local function prefixBox(lastIndex, id)
    local left = START_X - 45
    local right = START_X + (lastIndex - 1) * STEP + 45
    return scene:rectangle {
        center = {(left + right) / 2, Y}, size = {right - left + 10, 94}, corner = 7,
        fill = "#00000000", stroke = "success", width = 3,
        layer = LAYER.range, id = id,
    }
end

local prefix = prefixBox(KEY_INDEX - 1, "prefix:before")
local prefixLabel = scene:text {
    text = "sorted prefix", point = {-96, 92}, role = "code",
    fill = "success", layer = LAYER.text, id = "prefix:label",
}
local status, statusCounter = nil, 0
local function setStatus(message, color)
    statusCounter = statusCounter + 1
    local nextStatus = scene:text {
        text = message, point = {0, -130}, role = "code", fill = color or "focus",
        layer = LAYER.text, id = "status:" .. statusCounter,
    }
    if status then scene:fade_transform(status, nextStatus, 0.18, "gentle")
    else scene:fade_in(nextStatus, {duration = 0.24, curve = "gentle"}) end
    status = nextStatus
end

scene:fade_in(title, {shift = {0, -6}, duration = 0.42, curve = "gentle"})
scene:fade_in(contract, {shift = {0, -5}, duration = 0.34, curve = "gentle"})
scene:fade_in(slots, {duration = 0.40, curve = "gentle"})
scene:fade_in(tokenLayer, {shift = {0, 7}, duration = 0.50, curve = "ease_out"})
scene:create(prefix, 0.36, "ease_out")
scene:fade_in(prefixLabel, {duration = 0.26, curve = "gentle"})

setStatus(string.format(
    "lift key %s; slot %d becomes available", tostring(KEY.value), KEY_INDEX - 1
), "warning")
scene:play({
    {target = tokensById[KEY.id], shift = {0, LIFT}},
    {target = bodiesById[KEY.id], fill = "warning"},
}, 0.55, "ease_out", 0)
scene:wait(0.28)

for _, event in ipairs(TRACE) do
    if event.kind == "shift" then
        setStatus(string.format(
            "%s > %s  →  shift %s right into slot %d",
            tostring(event.item.value), tostring(KEY.value),
            tostring(event.item.value), event.destination - 1
        ))
        scene:play({{target = bodiesById[event.item.id], fill = "focus"}},
            0.26, "ease_in_out", 0)
        scene:play({
            {target = tokensById[event.item.id], shift = {STEP, 0}},
            {target = bodiesById[event.item.id], fill = "surface"},
        }, 0.55, "ease_out", 0)
    else
        local decision = event.compared and string.format(
            "%s <= %s", tostring(event.compared.value), tostring(KEY.value)
        ) or "prefix start reached"
        setStatus(string.format(
            "%s  →  write key into slot %d", decision, event.destination - 1
        ), "result")
        scene:play({
            {target = tokensById[KEY.id], shift = {
                (event.destination - KEY_INDEX) * STEP, -LIFT,
            }},
            {target = bodiesById[KEY.id], fill = "result", stroke = "result"},
            {target = labelsById[KEY.id], fill = "foreground"},
        }, 0.72, "ease_in_out", 0)
    end
end

assert(DESTINATION == TRACE[#TRACE].destination)
local expandedPrefix = prefixBox(KEY_INDEX, "prefix:after")
scene:fade_transform(prefix, expandedPrefix, 0.32, "ease_in_out")
prefix = expandedPrefix
local result = scene:text {
    text = "result: [" .. table.concat(RESULT_LABELS, ", ")
        .. "]  ·  sorted prefix grows to length " .. KEY_INDEX,
    point = {0, -190}, role = "text", fill = "result",
    layer = LAYER.text, id = "result:insertion",
}
scene:fade_in(result, {shift = {0, 5}, duration = 0.34, curve = "gentle"})
scene:wait(2.2)
return scene
