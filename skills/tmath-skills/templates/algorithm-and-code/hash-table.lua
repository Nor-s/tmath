-- Question: how do a hash, collisions, and linear probes choose the occupied bucket?
-- Variant: open addressing, h(k) = k mod capacity, linear probing, no tombstones.
-- Addresses are explicitly illustrative; edit KEYS, CAPACITY, BASE_ADDRESS, and STRIDE together.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local CAPACITY, BASE_ADDRESS, STRIDE = 7, 0x1000, 8
local KEYS = {
    {id = "k10", key = 10}, {id = "k17", key = 17}, {id = "k24", key = 24},
}
local LOOKUP_KEY = 24
local LAYER = {slot = 10, token = 20, text = 40}

local function cloneTable(source)
    local copy = {}
    for index = 1, CAPACITY do copy[index] = source[index] end
    return copy
end

local function buildTrace(keys)
    local state, trace = {}, {}
    for _, item in ipairs(keys) do
        local home, probes, destination = item.key % CAPACITY, {}, nil
        for offset = 0, CAPACITY - 1 do
            local logical = (home + offset) % CAPACITY
            local occupant = state[logical + 1]
            probes[#probes + 1] = {index = logical, occupant = occupant, attempt = offset + 1}
            if not occupant then destination = logical break end
        end
        assert(destination, "illustrative table is full")
        state[destination + 1] = item
        trace[#trace + 1] = {
            kind = "insert", item = item, home = home, probes = probes,
            destination = destination, stateAfter = cloneTable(state),
        }
    end
    return trace, state
end

local function buildLookup(state, key)
    local home, probes = key % CAPACITY, {}
    for offset = 0, CAPACITY - 1 do
        local logical = (home + offset) % CAPACITY
        local occupant = state[logical + 1]
        probes[#probes + 1] = {index = logical, occupant = occupant, attempt = offset + 1}
        if not occupant then return {home = home, probes = probes, found = nil} end
        if occupant.key == key then
            return {home = home, probes = probes, found = logical, item = occupant}
        end
    end
    return {home = home, probes = probes, found = nil}
end

local INSERT_TRACE, TABLE_STATE = buildTrace(KEYS)
local LOOKUP = buildLookup(TABLE_STATE, LOOKUP_KEY)
assert(INSERT_TRACE[1].destination == 3 and INSERT_TRACE[2].destination == 4)
assert(INSERT_TRACE[3].destination == 5 and LOOKUP.found == 5 and #LOOKUP.probes == 3)

local START_X, STEP, TABLE_Y = -315, 105, 15
local SOURCE_X = {-120, 0, 120}
local SOURCE_Y = 120
local function translate(x, y)
    return {1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, 0, 0, 0, 0, 1}
end

local title = scene:text {
    text = "Hash table · home bucket, collision, probe, commit",
    point = {0, 230}, role = "h2", fill = "foreground",
    layer = LAYER.text, id = "scene-title",
}
local subtitle = scene:text {
    text = string.format(
        "h(k) = k mod %d · illustrative addresses: base 0x%04X, stride %d bytes",
        CAPACITY, BASE_ADDRESS, STRIDE
    ),
    point = {0, 194}, role = "code", fill = "muted",
    layer = LAYER.text, id = "scene-subtitle",
}
local sourceLabel = scene:text {
    text = "KEYS TO INSERT", point = {0, 158}, role = "code",
    fill = "accent", layer = LAYER.text, id = "incoming:label",
}

local slots = scene:group {id = "hash:buckets"}
local slotBodies = {}
for logical = 0, CAPACITY - 1 do
    local x = START_X + logical * STEP
    slotBodies[logical + 1] = slots:rectangle {
        center = {x, TABLE_Y}, size = {88, 74}, corner = 6,
        fill = "surface", stroke = "border", width = 2,
        layer = LAYER.slot, id = "bucket:" .. logical .. ":body",
    }
    slots:text {
        text = "bucket " .. logical, point = {x, TABLE_Y - 53}, role = "code",
        fill = "foreground", layer = LAYER.text, id = "bucket:" .. logical .. ":index",
    }
    slots:text {
        text = string.format("0x%04X", BASE_ADDRESS + logical * STRIDE),
        point = {x, TABLE_Y - 78}, role = "code", fill = "muted",
        layer = LAYER.text, id = "bucket:" .. logical .. ":address",
    }
end

local keyLayer = scene:group {id = "hash:keys"}
local tokens, tokenBodies, tokenPositions = {}, {}, {}
for index, item in ipairs(KEYS) do
    local token = keyLayer:group {
        matrix = translate(SOURCE_X[index], SOURCE_Y), id = "key:" .. item.id,
    }
    tokenBodies[item.id] = token:rectangle {
        center = {0, 0}, size = {72, 44}, corner = 5,
        fill = "surface", stroke = "foreground", width = 2,
        layer = LAYER.token, id = "key:" .. item.id .. ":body",
    }
    token:text {
        text = tostring(item.key), point = {0, 0}, role = "h3",
        fill = "foreground", layer = LAYER.text, id = "key:" .. item.id .. ":label",
    }
    tokens[item.id] = token
    tokenPositions[item.id] = {SOURCE_X[index], SOURCE_Y}
end

local status, statusIndex = nil, 0
local function setStatus(message, color)
    statusIndex = statusIndex + 1
    local nextStatus = scene:text {
        text = message, point = {0, -145}, role = "code", fill = color or "focus",
        layer = LAYER.text, id = "status:" .. statusIndex,
    }
    if status then scene:fade_transform(status, nextStatus, 0.18, "gentle")
    else scene:fade_in(nextStatus, {duration = 0.25, curve = "gentle"}) end
    status = nextStatus
end

scene:fade_in(title, {shift = {0, -6}, duration = 0.42, curve = "gentle"})
scene:fade_in(subtitle, {shift = {0, -5}, duration = 0.34, curve = "gentle"})
scene:fade_in(sourceLabel, {duration = 0.24, curve = "gentle"})
scene:fade_in(slots, {duration = 0.44, curve = "gentle"})
scene:fade_in(keyLayer, {shift = {0, 6}, duration = 0.46, curve = "ease_out"})

for _, event in ipairs(INSERT_TRACE) do
    local item = event.item
    setStatus(string.format("key %d · home = %d mod %d = bucket %d",
        item.key, item.key, CAPACITY, event.home))
    scene:play({
        {target = tokenBodies[item.id], fill = "focus", stroke = "focus"},
        {target = slotBodies[event.home + 1], fill = "focus", stroke = "focus"},
    }, 0.36, "ease_in_out", 0)
    scene:wait(0.24)

    for _, probe in ipairs(event.probes) do
        if probe.occupant then
            setStatus(string.format(
                "probe %d · bucket %d contains %d → collision",
                probe.attempt, probe.index, probe.occupant.key
            ), "warning")
            scene:play({
                {target = slotBodies[probe.index + 1], fill = "warning", stroke = "warning"},
            }, 0.30, "ease_in_out", 0)
            scene:wait(0.22)
            scene:play({
                {target = slotBodies[probe.index + 1], fill = "surface", stroke = "border"},
            }, 0.24, "ease_in_out", 0)
        end
    end

    local destinationX = START_X + event.destination * STEP
    local current = tokenPositions[item.id]
    setStatus(string.format(
        "commit key %d → bucket %d after %d probe%s",
        item.key, event.destination, #event.probes, #event.probes == 1 and "" or "s"
    ), "success")
    scene:play({
        {target = tokens[item.id], shift = {destinationX - current[1], TABLE_Y - current[2]}},
        {target = tokenBodies[item.id], fill = "surface", stroke = "success"},
        {target = slotBodies[event.destination + 1], fill = "surface", stroke = "success"},
    }, 0.58, "ease_out", 0)
    tokenPositions[item.id] = {destinationX, TABLE_Y}
    scene:wait(0.24)
end

local lookupLabel = scene:text {
    text = "LOOKUP " .. LOOKUP_KEY .. " · PROBE FROM HOME", point = {0, 158}, role = "code",
    fill = "accent", layer = LAYER.text, id = "lookup:label",
}
scene:fade_transform(sourceLabel, lookupLabel, 0.22, "gentle")
setStatus(string.format("lookup %d · start at home bucket %d", LOOKUP_KEY, LOOKUP.home))
for _, probe in ipairs(LOOKUP.probes) do
    local occupant = probe.occupant
    local message = occupant and string.format(
        "lookup probe %d · bucket %d has %d%s",
        probe.attempt, probe.index, occupant.key,
        occupant.key == LOOKUP_KEY and " → match" or " → continue"
    ) or string.format("lookup probe %d · bucket %d is empty → miss", probe.attempt, probe.index)
    setStatus(message, occupant and occupant.key == LOOKUP_KEY and "result" or "focus")
    scene:play({{target = slotBodies[probe.index + 1], fill = "focus", stroke = "focus"}},
        0.30, "ease_in_out", 0)
    scene:wait(0.24)
    scene:play({{
        target = slotBodies[probe.index + 1], fill = "surface",
        stroke = occupant and occupant.key == LOOKUP_KEY and "result" or "border",
    }}, 0.24, "ease_in_out", 0)
end

local resultText = LOOKUP.found and string.format(
    "found %d at bucket %d · exact lookup cost = %d probes",
    LOOKUP_KEY, LOOKUP.found, #LOOKUP.probes
) or string.format("%d not found · exact lookup cost = %d probes", LOOKUP_KEY, #LOOKUP.probes)
local result = scene:text {
    text = resultText, point = {0, -215}, role = "text", fill = "result",
    layer = LAYER.text, id = "result:lookup",
}
scene:fade_transform(status, result, 0.24, "gentle")
scene:wait(2.3)
return scene
