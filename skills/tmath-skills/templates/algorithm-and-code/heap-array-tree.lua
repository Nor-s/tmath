-- Question: how does one sift-down swap update the array and tree views of one heap state?
-- Variant: zero-based max-heap indices; sift down from the root until heap order holds.
-- Edit VALUES; the trace and both synchronized projections are regenerated below.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local VALUES = {
    {id = "a", value = 4}, {id = "b", value = 10}, {id = "c", value = 7},
    {id = "d", value = 5}, {id = "e", value = 1}, {id = "f", value = 3},
}
local LAYER = {divider = 2, edge = 8, slot = 12, token = 20, text = 40}

local function cloneItems(items)
    local copy = {}
    for index, item in ipairs(items) do copy[index] = item end
    return copy
end

local function buildSiftDownTrace(values)
    local state, trace, current = cloneItems(values), {}, 1
    while true do
        local left, right = current * 2, current * 2 + 1
        if left > #state then break end
        local chosen = left
        if right <= #state and state[right].value > state[left].value then chosen = right end
        local event = {
            parent = current, left = left, right = right <= #state and right or nil,
            chosen = chosen, parentItem = state[current], chosenItem = state[chosen],
        }
        if state[current].value >= state[chosen].value then
            event.kind, event.stateAfter = "stop", cloneItems(state)
            trace[#trace + 1] = event
            break
        end
        event.kind = "swap"
        state[current], state[chosen] = state[chosen], state[current]
        event.stateAfter = cloneItems(state)
        trace[#trace + 1] = event
        current = chosen
    end
    for index = 1, #state do
        local left, right = index * 2, index * 2 + 1
        if left <= #state then assert(state[index].value >= state[left].value) end
        if right <= #state then assert(state[index].value >= state[right].value) end
    end
    return trace, state
end

local TRACE, HEAP = buildSiftDownTrace(VALUES)
assert(#TRACE == 2 and TRACE[1].parent == 1 and TRACE[1].chosen == 2)

local ARRAY_X, ARRAY_Y, ARRAY_STEP = -395, 38, 62
local TREE_POSITIONS = {
    {240, 100}, {145, 10}, {335, 10},
    {95, -91}, {195, -91}, {285, -91},
}

local function translate(x, y)
    return {1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, 0, 0, 0, 0, 1}
end

local title = scene:text {
    text = "Heap · one state, two synchronized projections",
    point = {0, 230}, role = "h2", fill = "foreground",
    layer = LAYER.text, id = "scene-title",
}
local subtitle = scene:text {
    text = "zero-based children: left = 2i + 1 · right = 2i + 2",
    point = {0, 194}, role = "code", fill = "muted",
    layer = LAYER.text, id = "scene-subtitle",
}
scene:line {
    from = {0, 165}, to = {0, -145}, stroke = "border", width = 2,
    layer = LAYER.divider, id = "view-divider",
}
local arrayHeading = scene:text {
    text = "ARRAY STORAGE", point = {-240, 164}, role = "code",
    fill = "accent", layer = LAYER.text, id = "array:heading",
}
local treeHeading = scene:text {
    text = "COMPLETE TREE", point = {240, 164}, role = "code",
    fill = "secondary", layer = LAYER.text, id = "tree:heading",
}

local arraySlots = scene:group {id = "heap:array-slots"}
local treeSlots = scene:group {id = "heap:tree-slots"}
local treeSlotHandles, arrayIndexLabels, treeIndexLabels = {}, {}, {}
for index = 1, #VALUES do
    local logical = index - 1
    local x = ARRAY_X + logical * ARRAY_STEP
    arraySlots:rectangle {
        center = {x, ARRAY_Y}, size = {56, 56}, corner = 5,
        fill = "surface", stroke = "border", width = 2,
        layer = LAYER.slot, id = "array-slot:" .. logical,
    }
    arrayIndexLabels[index] = arraySlots:text {
        text = tostring(logical), point = {x, ARRAY_Y - 43}, role = "code",
        fill = "muted", layer = LAYER.text, id = "array-index:" .. logical,
    }

    local p = TREE_POSITIONS[index]
    local slot = treeSlots:group {
        matrix = translate(p[1], p[2]), id = "tree-slot:" .. logical,
    }
    slot:circle {
        center = {0, 0}, radius = 29, fill = "surface", stroke = "border",
        width = 2, layer = LAYER.slot, id = "tree-slot:" .. logical .. ":body",
    }
    treeIndexLabels[index] = slot:text {
        text = "i=" .. logical, point = {0, -39}, role = "code",
        fill = "muted", layer = LAYER.text, id = "tree-slot:" .. logical .. ":index",
    }
    treeSlotHandles[index] = slot
end

local treeEdges = scene:group {id = "heap:tree-edges"}
for child = 2, #VALUES do
    local parent = math.floor(child / 2)
    treeEdges:connector {
        from = treeSlotHandles[parent], to = treeSlotHandles[child], padding = 4,
        stroke = "border", width = 2.2, layer = LAYER.edge,
        id = "tree-edge:" .. (parent - 1) .. ":" .. (child - 1),
    }
end

local arrayValues = scene:group {id = "heap:array-values"}
local treeValues = scene:group {id = "heap:tree-values"}
local arrayTokens, arrayBodies, treeTokens, treeBodies = {}, {}, {}, {}
for index, spec in ipairs(VALUES) do
    local x = ARRAY_X + (index - 1) * ARRAY_STEP
    local arrayToken = arrayValues:group {
        matrix = translate(x, ARRAY_Y), id = "array-view:value:" .. spec.id,
    }
    arrayBodies[index] = arrayToken:rectangle {
        center = {0, 0}, size = {44, 44}, corner = 4,
        fill = "surface", stroke = "foreground", width = 2,
        layer = LAYER.token, id = "array-view:value:" .. spec.id .. ":body",
    }
    arrayToken:text {
        text = tostring(spec.value), point = {0, 0}, role = "h3",
        fill = "foreground", layer = LAYER.text,
        id = "array-view:value:" .. spec.id .. ":label",
    }
    local p = TREE_POSITIONS[index]
    local treeToken = treeValues:group {
        matrix = translate(p[1], p[2]), id = "tree-view:value:" .. spec.id,
    }
    treeBodies[index] = treeToken:circle {
        center = {0, 0}, radius = 21, fill = "surface", stroke = "foreground",
        width = 2, layer = LAYER.token, id = "tree-view:value:" .. spec.id .. ":body",
    }
    treeToken:text {
        text = tostring(spec.value), point = {0, 0}, role = "h3",
        fill = "foreground", layer = LAYER.text,
        id = "tree-view:value:" .. spec.id .. ":label",
    }
    arrayTokens[index], treeTokens[index] = arrayToken, treeToken
end

local status, statusIndex = nil, 0
local function setStatus(message, color)
    statusIndex = statusIndex + 1
    local nextStatus = scene:text {
        text = message, point = {0, -170}, role = "code", fill = color or "focus",
        layer = LAYER.text, id = "status:" .. statusIndex,
    }
    if status then scene:fade_transform(status, nextStatus, 0.18, "gentle")
    else scene:fade_in(nextStatus, {duration = 0.25, curve = "gentle"}) end
    status = nextStatus
end

local function swapBothViews(first, second)
    local arrayDistance = (second - first) * ARRAY_STEP
    local firstTree, secondTree = TREE_POSITIONS[first], TREE_POSITIONS[second]
    local treeDelta = {secondTree[1] - firstTree[1], secondTree[2] - firstTree[2]}
    local length = math.sqrt(treeDelta[1] * treeDelta[1] + treeDelta[2] * treeDelta[2])
    local perpendicular = {-treeDelta[2] / length * 28, treeDelta[1] / length * 28}
    scene:play({
        {target = arrayIndexLabels[first], opacity = 0},
        {target = arrayIndexLabels[second], opacity = 0},
        {target = treeIndexLabels[first], opacity = 0},
        {target = treeIndexLabels[second], opacity = 0},
    }, 0.18, "gentle", 0)
    scene:play({
        {target = arrayTokens[first], shift = {0, 30}},
        {target = arrayTokens[second], shift = {0, 80}},
        {target = treeTokens[first], shift = perpendicular},
        {target = treeTokens[second], shift = {-perpendicular[1], -perpendicular[2]}},
    }, 0.24, "ease_out", 0)
    scene:play({
        {target = arrayTokens[first], shift = {arrayDistance, 0}},
        {target = arrayTokens[second], shift = {-arrayDistance, 0}},
        {target = treeTokens[first], shift = treeDelta},
        {target = treeTokens[second], shift = {-treeDelta[1], -treeDelta[2]}},
    }, 0.54, "ease_in_out", 0)
    scene:play({
        {target = arrayTokens[first], shift = {0, -30}},
        {target = arrayTokens[second], shift = {0, -80}},
        {target = treeTokens[first], shift = {-perpendicular[1], -perpendicular[2]}},
        {target = treeTokens[second], shift = perpendicular},
    }, 0.24, "ease_in", 0)
    scene:play({
        {target = arrayIndexLabels[first], opacity = 1},
        {target = arrayIndexLabels[second], opacity = 1},
        {target = treeIndexLabels[first], opacity = 1},
        {target = treeIndexLabels[second], opacity = 1},
    }, 0.18, "gentle", 0)
    arrayTokens[first], arrayTokens[second] = arrayTokens[second], arrayTokens[first]
    arrayBodies[first], arrayBodies[second] = arrayBodies[second], arrayBodies[first]
    treeTokens[first], treeTokens[second] = treeTokens[second], treeTokens[first]
    treeBodies[first], treeBodies[second] = treeBodies[second], treeBodies[first]
end

scene:fade_in(title, {shift = {0, -6}, duration = 0.42, curve = "gentle"})
scene:fade_in(subtitle, {shift = {0, -5}, duration = 0.34, curve = "gentle"})
scene:fade_in(arrayHeading, {duration = 0.25, curve = "gentle"})
scene:fade_in(treeHeading, {duration = 0.25, curve = "gentle"})
scene:fade_in(arraySlots, {duration = 0.38, curve = "gentle"})
scene:create(treeEdges, 0.45, "ease_out")
scene:fade_in(treeSlots, {duration = 0.42, curve = "gentle"})
scene:fade_in(arrayValues, {shift = {0, 6}, duration = 0.46, curve = "ease_out"})
scene:fade_in(treeValues, {shift = {0, 6}, duration = 0.46, curve = "ease_out"})

for _, event in ipairs(TRACE) do
    local rightText = event.right and (" and i=" .. (event.right - 1)) or ""
    setStatus(string.format(
        "compare i=%d (%s) with children i=%d%s · choose %s",
        event.parent - 1, tostring(event.parentItem.value), event.left - 1, rightText,
        tostring(event.chosenItem.value)
    ))
    scene:play({
        {target = arrayBodies[event.parent], fill = "focus", stroke = "focus"},
        {target = arrayBodies[event.chosen], fill = "focus", stroke = "focus"},
        {target = treeBodies[event.parent], fill = "focus", stroke = "focus"},
        {target = treeBodies[event.chosen], fill = "focus", stroke = "focus"},
    }, 0.34, "ease_in_out", 0)
    scene:wait(0.28)

    if event.kind == "swap" then
        setStatus(string.format(
            "commit swap i=%d ↔ i=%d in both views",
            event.parent - 1, event.chosen - 1
        ))
        swapBothViews(event.parent, event.chosen)
        scene:play({
            {target = arrayBodies[event.parent], fill = "surface", stroke = "foreground"},
            {target = arrayBodies[event.chosen], fill = "surface", stroke = "foreground"},
            {target = treeBodies[event.parent], fill = "surface", stroke = "foreground"},
            {target = treeBodies[event.chosen], fill = "surface", stroke = "foreground"},
        }, 0.28, "ease_in_out", 0)
    else
        setStatus("stop · parent is already at least as large as both children", "result")
    end
end

local resultValues = {}
for _, item in ipairs(HEAP) do resultValues[#resultValues + 1] = item.value end
local result = scene:text {
    text = "max-heap: [" .. table.concat(resultValues, ", ") .. "] · every parent ≥ its children",
    point = {0, -225}, role = "text", fill = "result",
    layer = LAYER.text, id = "result:max-heap",
}
scene:fade_in(result, {shift = {0, 4}, duration = 0.38, curve = "gentle"})
scene:wait(2.3)
return scene
