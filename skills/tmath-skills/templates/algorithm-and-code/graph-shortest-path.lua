-- Question: how do selection and relaxation make Dijkstra's shortest path inspectable?
-- Variant: directed non-negative graph, array-backed priority set, NODE_ORDER breaks ties.
-- Edit NODE_ORDER and EDGES; the exact settle/relax trace and predecessor path regenerate below.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local SOURCE, TARGET = "S", "T"
local NODE_ORDER = {"S", "A", "B", "C", "D", "T"}
local POSITIONS = {
    S = {-335, 48}, A = {-155, 115}, B = {-155, -35},
    C = {55, 115}, D = {55, -35}, T = {300, 48},
}
local EDGES = {
    {from = "S", to = "A", weight = 4, label = {-250, 105}},
    {from = "S", to = "B", weight = 2, label = {-250, -8}},
    {from = "B", to = "A", weight = 1, label = {-118, 40}},
    {from = "A", to = "C", weight = 3, label = {-50, 132}},
    {from = "B", to = "D", weight = 4, label = {-50, -65}},
    {from = "B", to = "C", weight = 5, label = {-30, 34}},
    {from = "C", to = "T", weight = 2, label = {188, 110}},
    {from = "D", to = "T", weight = 3, label = {188, -12}},
}
local LAYER = {edge = 10, node = 20, mark = 30, text = 40}
local INF = math.huge

local function copyMap(source)
    local copy = {}
    for _, id in ipairs(NODE_ORDER) do copy[id] = source[id] end
    return copy
end

local function adjacency()
    local result = {}
    for _, id in ipairs(NODE_ORDER) do result[id] = {} end
    for _, edge in ipairs(EDGES) do
        assert(edge.weight >= 0, "Dijkstra requires non-negative weights")
        result[edge.from][#result[edge.from] + 1] = edge
    end
    return result
end

local ADJ = adjacency()
local function frontierSnapshot(distance, settled)
    local result = {}
    for order, id in ipairs(NODE_ORDER) do
        if not settled[id] and distance[id] < INF then
            result[#result + 1] = {id = id, distance = distance[id], order = order}
        end
    end
    table.sort(result, function(a, b)
        if a.distance == b.distance then return a.order < b.order end
        return a.distance < b.distance
    end)
    return result
end

local function buildDijkstraTrace()
    local distance, predecessor, settled, trace = {}, {}, {}, {}
    for _, id in ipairs(NODE_ORDER) do distance[id] = INF end
    distance[SOURCE] = 0

    while true do
        local frontier = frontierSnapshot(distance, settled)
        if #frontier == 0 then break end
        local current = frontier[1].id
        settled[current] = true
        trace[#trace + 1] = {
            kind = "settle", node = current, distance = distance[current],
            frontierAfter = frontierSnapshot(distance, settled),
        }
        if current == TARGET then break end

        for _, edge in ipairs(ADJ[current]) do
            if not settled[edge.to] then
                local old = distance[edge.to]
                local candidate = distance[current] + edge.weight
                local improved = candidate < old
                local oldPredecessor = predecessor[edge.to]
                if improved then
                    distance[edge.to], predecessor[edge.to] = candidate, current
                end
                trace[#trace + 1] = {
                    kind = "relax", from = current, to = edge.to, weight = edge.weight,
                    fromDistance = distance[current],
                    oldDistance = old, candidate = candidate, improved = improved,
                    newDistance = distance[edge.to], oldPredecessor = oldPredecessor,
                    predecessorAfter = predecessor[edge.to],
                    frontierAfter = frontierSnapshot(distance, settled),
                    distanceAfter = copyMap(distance), predecessorMapAfter = copyMap(predecessor),
                }
            end
        end
    end

    local reversed, node = {}, TARGET
    while node do
        reversed[#reversed + 1] = node
        if node == SOURCE then break end
        node = predecessor[node]
    end
    assert(reversed[#reversed] == SOURCE, "target must be reachable in this template")
    local path = {}
    for index = #reversed, 1, -1 do path[#path + 1] = reversed[index] end
    return trace, distance, path
end

local TRACE, FINAL_DISTANCE, SHORTEST_PATH = buildDijkstraTrace()
assert(FINAL_DISTANCE[TARGET] == 8)
assert(table.concat(SHORTEST_PATH, "") == "SBACT")

local function translate(x, y)
    return {1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, 0, 0, 0, 0, 1}
end
local function distanceText(value)
    return value == INF and "∞" or tostring(value)
end
local function frontierText(frontier)
    if #frontier == 0 then return "frontier: ∅" end
    local parts = {}
    for _, entry in ipairs(frontier) do
        parts[#parts + 1] = entry.id .. ":" .. entry.distance
    end
    return "frontier min → [" .. table.concat(parts, ", ") .. "]"
end

local header = {}
for _, spec in ipairs({
    {id = "scene-title", text = "Dijkstra · select minimum, relax, settle", y = 230, role = "h2", fill = "foreground"},
    {id = "scene-subtitle", text = "directed non-negative graph · ties follow S, A, B, C, D, T", y = 194, role = "code", fill = "muted"},
    {id = "state-legend", text = "focus = current comparison · small dot = settled · green edge = predecessor", y = 163, role = "code", fill = "muted"},
}) do
    header[spec.id] = scene:text {
        text = spec.text, point = {0, spec.y}, role = spec.role, fill = spec.fill,
        layer = LAYER.text, id = spec.id,
    }
end
local title, subtitle, legend = header["scene-title"], header["scene-subtitle"], header["state-legend"]

local nodeLayer = scene:group {id = "graph:nodes"}
local nodes, bodies, settledMarks, distanceLabels = {}, {}, {}, {}
local function addNode(id)
    local p = POSITIONS[id]
    local prefix = "graph-node:" .. id
    local node = nodeLayer:group {matrix = translate(p[1], p[2]), id = prefix}
    bodies[id] = node:circle {
        center = {0, 0}, radius = 27, fill = "surface", stroke = "border",
        width = 2.5, layer = LAYER.node, id = prefix .. ":body",
    }
    node:text {text = id, point = {0, 0}, role = "h3", fill = "foreground", layer = LAYER.text, id = prefix .. ":label"}
    settledMarks[id] = node:circle {
        center = {21, 21}, radius = 5, fill = "success", stroke = "success",
        width = 1, opacity = 0, layer = LAYER.mark, id = prefix .. ":settled-mark",
    }
    distanceLabels[id] = node:text {
        text = "d=" .. distanceText(id == SOURCE and 0 or INF), point = {0, -42}, role = "code",
        fill = id == SOURCE and "accent" or "muted", layer = LAYER.text, id = prefix .. ":distance:0",
    }
    nodes[id] = node
end
for _, id in ipairs(NODE_ORDER) do
    addNode(id)
end

local edgeLayer = scene:group {id = "graph:edges"}
local edgeHandles = {}
local function addEdge(edge)
    local key = edge.from .. ":" .. edge.to
    local id = "graph-edge:" .. key
    edgeHandles[key] = edgeLayer:connector {
        from = nodes[edge.from], to = nodes[edge.to], padding = 6, tip = 10,
        stroke = "border", width = 2.3, layer = LAYER.edge, id = id,
    }
    edgeLayer:text {text = tostring(edge.weight), point = edge.label, role = "code", fill = "foreground", layer = LAYER.text, id = id .. ":weight"}
end
for _, edge in ipairs(EDGES) do
    addEdge(edge)
end

local status, statusIndex = nil, 0
local function replaceText(previous, parent, spec, firstDuration)
    local nextText = parent:text(spec)
    if previous then scene:fade_transform(previous, nextText, 0.16, "gentle")
    elseif firstDuration then scene:fade_in(nextText, {duration = firstDuration, curve = "gentle"}) end
    return nextText
end
local function setStatus(message, color)
    statusIndex = statusIndex + 1
    status = replaceText(status, scene, {
        text = message, point = {0, -150}, role = "code", fill = color or "focus",
        layer = LAYER.text, id = "status:" .. statusIndex,
    }, 0.24)
end

local frontier = scene:text {
    text = frontierText({{id = SOURCE, distance = 0}}), point = {0, -184}, role = "code",
    fill = "accent", layer = LAYER.text, id = "frontier:0",
}
local frontierIndex = 0
local function setFrontier(snapshot)
    frontierIndex = frontierIndex + 1
    frontier = replaceText(frontier, scene, {
        text = frontierText(snapshot), point = {0, -184}, role = "code",
        fill = #snapshot == 0 and "muted" or "accent", layer = LAYER.text,
        id = "frontier:" .. frontierIndex,
    })
end

scene:fade_in(title, {shift = {0, -6}, duration = 0.42, curve = "gentle"})
scene:fade_in(subtitle, {shift = {0, -5}, duration = 0.34, curve = "gentle"})
scene:fade_in(legend, {duration = 0.24, curve = "gentle"})
scene:create(edgeLayer, 0.62, "ease_out")
scene:fade_in(nodeLayer, {shift = {0, 6}, duration = 0.48, curve = "gentle"})
scene:fade_in(frontier, {duration = 0.24, curve = "gentle"})

local distanceVersion = {}
for _, id in ipairs(NODE_ORDER) do distanceVersion[id] = 0 end
for _, event in ipairs(TRACE) do
    if event.kind == "settle" then
        setStatus(string.format("select minimum %s with d=%d → settle", event.node, event.distance))
        scene:play({{target = bodies[event.node], fill = "focus", stroke = "focus"}},
            0.34, "ease_in_out", 0)
        scene:wait(0.22)
        scene:play({
            {target = bodies[event.node], fill = "surface", stroke = "success"},
            {target = settledMarks[event.node], opacity = 1},
        }, 0.30, "ease_in_out", 0)
        setFrontier(event.frontierAfter)
    else
        local oldText = distanceText(event.oldDistance)
        setStatus(string.format(
            "relax %s→%s: %d + %d = %d %s %s",
            event.from, event.to, event.fromDistance, event.weight, event.candidate,
            event.improved and "<" or "≥", oldText
        ), event.improved and "focus" or "warning")
        local edge = edgeHandles[event.from .. ":" .. event.to]
        scene:play({
            {target = edge, stroke = "focus"},
            {target = bodies[event.to], fill = "focus", stroke = "focus"},
        }, 0.32, "ease_in_out", 0)
        scene:wait(0.20)

        if event.improved then
            distanceVersion[event.to] = distanceVersion[event.to] + 1
            local nextDistance = nodes[event.to]:text {
                text = "d=" .. event.newDistance, point = {0, -42}, role = "code",
                fill = "accent", layer = LAYER.text,
                id = "graph-node:" .. event.to .. ":distance:" .. distanceVersion[event.to],
            }
            scene:fade_transform(distanceLabels[event.to], nextDistance, 0.18, "gentle")
            distanceLabels[event.to] = nextDistance
            local commit = {
                {target = edge, stroke = "success"},
                {target = bodies[event.to], fill = "surface", stroke = "border"},
            }
            if event.oldPredecessor then
                commit[#commit + 1] = {
                    target = edgeHandles[event.oldPredecessor .. ":" .. event.to], stroke = "border",
                }
            end
            scene:play(commit, 0.34, "ease_in_out", 0)
            setFrontier(event.frontierAfter)
        else
            scene:play({
                {target = edge, stroke = "border"},
                {target = bodies[event.to], fill = "surface", stroke = "border"},
            }, 0.30, "ease_in_out", 0)
        end
    end
end

local pathTargets = {}
for _, id in ipairs(SHORTEST_PATH) do
    pathTargets[#pathTargets + 1] = {target = bodies[id], fill = "surface", stroke = "result"}
end
for index = 1, #SHORTEST_PATH - 1 do
    local key = SHORTEST_PATH[index] .. ":" .. SHORTEST_PATH[index + 1]
    pathTargets[#pathTargets + 1] = {target = edgeHandles[key], stroke = "result"}
end
scene:play(pathTargets, 0.48, "ease_in_out", 0)
local result = scene:text {
    text = string.format(
        "shortest %s → %s: %s · total cost = %d",
        SOURCE, TARGET, table.concat(SHORTEST_PATH, " → "), FINAL_DISTANCE[TARGET]
    ),
    point = {0, -228}, role = "text", fill = "result",
    layer = LAYER.text, id = "result:shortest-path",
}
scene:fade_in(result, {shift = {0, 4}, duration = 0.38, curve = "gentle"})
scene:wait(2.4)
return scene
