-- Question: how does one Lomuto partition establish <= pivot | pivot | > pivot?
-- Variant: pivot = a[hi], scan j from lo to hi-1, swap when a[j] <= pivot.
-- This is one partition, not the complete recursive sort.
-- Edit VALUES; the exact Lomuto trace and final partition are regenerated below.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local VALUES = {
    {id = "a", value = 6}, {id = "b", value = 2}, {id = "c", value = 8},
    {id = "d", value = 3}, {id = "e", value = 7}, {id = "pivot", value = 4},
}
local PIVOT_ID = VALUES[#VALUES].id

local function buildLomutoTrace(values)
    local state, trace = {}, {}
    for index, item in ipairs(values) do state[index] = item end
    local pivot = state[#state]
    local boundary = 1
    for scan = 1, #state - 1 do
        local item = state[scan]
        local accepted = item.value <= pivot.value
        trace[#trace + 1] = {
            kind = "compare", scan = scan, boundary = boundary,
            itemId = item.id, itemValue = item.value,
            pivotId = pivot.id, pivotValue = pivot.value, accepted = accepted,
        }
        if accepted then
            state[boundary], state[scan] = state[scan], state[boundary]
            boundary = boundary + 1
        end
    end
    trace[#trace + 1] = {
        kind = "pivot", first = boundary, second = #state,
        pivotId = pivot.id, pivotValue = pivot.value,
    }
    state[boundary], state[#state] = state[#state], state[boundary]

    for index = 1, boundary - 1 do assert(state[index].value <= pivot.value) end
    assert(state[boundary].id == pivot.id)
    for index = boundary + 1, #state do assert(state[index].value > pivot.value) end
    return trace, state, boundary
end

local TRACE, PARTITIONED, PIVOT_POSITION = buildLomutoTrace(VALUES)
local STEP, START_X, Y = 90, -225, -10
local SWAP_LANE_NEAR, SWAP_LANE_FAR = 72, 142
local LAYER = {slot = 10, token = 20, text = 40}

local function translate(x, y)
    return {1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, 0, 0, 0, 0, 1}
end

local title = scene:text {
    text = "Quick Sort · Lomuto partition", point = {0, 220}, role = "h2",
    fill = "foreground", layer = LAYER.text, id = "scene-title",
}
local contract = scene:text {
    text = string.format(
        "pivot = %s  ·  one real comparison and optional swap per scan step",
        tostring(VALUES[#VALUES].value)
    ),
    point = {0, 182}, role = "code", fill = "muted",
    layer = LAYER.text, id = "partition-contract",
}

local slots = scene:group {id = "partition:slots"}
local tokenLayer = scene:group {id = "partition:values"}
local tokens, bodies, labelsById = {}, {}, {}
for index, spec in ipairs(VALUES) do
    local x = START_X + (index - 1) * STEP
    slots:rectangle {
        center = {x, Y}, size = {78, 78}, corner = 5,
        fill = "surface", stroke = "border", width = 2,
        layer = LAYER.slot, id = "array-slot:" .. (index - 1),
    }
    slots:text {
        text = tostring(index - 1), point = {x, Y - 57}, role = "code",
        fill = "muted", layer = LAYER.text, id = "array-index:" .. (index - 1),
    }
    local token = tokenLayer:group {matrix = translate(x, Y), id = "value:" .. spec.id}
    local body = token:rectangle {
        center = {0, 0}, size = {64, 64}, corner = 5,
        fill = "surface", stroke = spec.id == PIVOT_ID and "warning" or "foreground",
        width = spec.id == PIVOT_ID and 3 or 2, layer = LAYER.token,
        id = "value:" .. spec.id .. ":body",
    }
    labelsById[spec.id] = token:text {
        text = tostring(spec.value), point = {0, 0}, role = "h3",
        fill = spec.id == PIVOT_ID and "warning" or "foreground",
        layer = LAYER.text, id = "value:" .. spec.id .. ":label",
    }
    tokens[index], bodies[index] = token, body
end

local zoneLeft = scene:text {
    text = "accepted: <= pivot", point = {-165, -110}, role = "code",
    fill = "success", layer = LAYER.text, id = "zone:accepted",
}
local zoneRight = scene:text {
    text = "unclassified", point = {125, -110}, role = "code",
    fill = "muted", layer = LAYER.text, id = "zone:unclassified",
}

local status = nil
local statusCounter = 0
local function setStatus(message, color)
    statusCounter = statusCounter + 1
    local nextStatus = scene:text {
        text = message, point = {0, -155}, role = "code", fill = color or "focus",
        layer = LAYER.text, id = "status:" .. statusCounter,
    }
    if status then scene:fade_transform(status, nextStatus, 0.18, "gentle")
    else scene:fade_in(nextStatus, {duration = 0.24, curve = "gentle"}) end
    status = nextStatus
end

local function swapPositions(first, second, accepted)
    if first == second then
        scene:play({{target = bodies[first], fill = accepted and "success" or "surface"}},
            0.32, "ease_in_out", 0)
        return
    end
    local distance = (second - first) * STEP
    scene:play({
        {target = tokens[first], shift = {0, SWAP_LANE_NEAR}},
        {target = tokens[second], shift = {0, SWAP_LANE_FAR}},
    }, 0.24, "ease_out", 0)
    scene:play({
        {target = tokens[first], shift = {distance, 0}},
        {target = tokens[second], shift = {-distance, 0}},
    }, 0.54, "ease_in_out", 0)
    scene:play({
        {target = tokens[first], shift = {0, -SWAP_LANE_NEAR}},
        {target = tokens[second], shift = {0, -SWAP_LANE_FAR}},
        {target = bodies[first], fill = "surface"},
        {target = bodies[second], fill = accepted and "success" or "surface"},
    }, 0.24, "ease_in", 0)
    tokens[first], tokens[second] = tokens[second], tokens[first]
    bodies[first], bodies[second] = bodies[second], bodies[first]
end

local function compareOnly(position, message)
    setStatus(message)
    scene:play({{target = bodies[position], fill = "focus"}}, 0.28, "ease_in_out", 0)
    scene:wait(0.18)
    scene:play({{target = bodies[position], fill = "surface"}}, 0.24, "ease_in_out", 0)
end

local function accept(position, boundary, message)
    setStatus(message)
    scene:play({{target = bodies[position], fill = "focus"}}, 0.28, "ease_in_out", 0)
    swapPositions(boundary, position, true)
end

scene:fade_in(title, {shift = {0, -6}, duration = 0.42, curve = "gentle"})
scene:fade_in(contract, {shift = {0, -5}, duration = 0.34, curve = "gentle"})
scene:fade_in(slots, {duration = 0.40, curve = "gentle"})
scene:fade_in(tokenLayer, {shift = {0, 7}, duration = 0.50, curve = "ease_out"})
scene:fade_in(zoneLeft, {duration = 0.24, curve = "gentle"})
scene:fade_in(zoneRight, {duration = 0.24, curve = "gentle"})

for _, event in ipairs(TRACE) do
    if event.kind == "compare" then
        local relation = event.accepted and "<=" or ">"
        local action = event.accepted and string.format(
            "swap a[%d], a[%d]", event.boundary - 1, event.scan - 1
        ) or "no swap"
        local message = string.format(
            "j=%d: %s %s %s  ·  %s",
            event.scan - 1,
            tostring(event.itemValue),
            relation,
            tostring(event.pivotValue),
            action
        )
        if event.accepted then accept(event.scan, event.boundary, message)
        else compareOnly(event.scan, message) end
    else
        setStatus(string.format(
            "final pivot swap: a[%d] <-> a[%d]", event.first - 1, event.second - 1
        ), "warning")
        swapPositions(event.first, event.second, false)
    end
end
scene:play({
    {target = bodies[PIVOT_POSITION], fill = "result", stroke = "result"},
    {target = labelsById[PIVOT_ID], fill = "foreground"},
},
    0.38, "ease_in_out", 0)

local left, right = {}, {}
for index = 1, PIVOT_POSITION - 1 do left[#left + 1] = PARTITIONED[index].value end
for index = PIVOT_POSITION + 1, #PARTITIONED do right[#right + 1] = PARTITIONED[index].value end
local result = scene:text {
    text = string.format(
        "partition: [%s] <= pivot  |  pivot = %s  |  [%s] > pivot",
        table.concat(left, ", "),
        tostring(PARTITIONED[PIVOT_POSITION].value),
        table.concat(right, ", ")
    ),
    point = {0, -210}, role = "text", fill = "result",
    layer = LAYER.text, id = "result:partition",
}
scene:fade_in(result, {shift = {0, 5}, duration = 0.36, curve = "gentle"})
scene:wait(2.2)
return scene
