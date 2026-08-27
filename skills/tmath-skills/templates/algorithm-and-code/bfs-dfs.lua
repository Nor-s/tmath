-- Question: why do BFS and iterative DFS visit the same graph in different orders?
-- Variant: directed graph, discovery on insertion, adjacency order as listed below.
-- DFS pushes neighbors in reverse adjacency order so the first neighbor is popped first.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local LAYER = {divider = 2, edge = 10, node = 20, mark = 30, text = 40}
local START = "A"
local NODE_ORDER = {"A", "B", "C", "D", "E", "F"}
local ADJACENCY = {
    A = {"B", "C"}, B = {"D", "E"}, C = {"F"},
    D = {}, E = {}, F = {},
}
local POSITIONS = {
    A = {0, 112}, B = {-92, 25}, C = {92, 25},
    D = {-145, -82}, E = {-38, -82}, F = {118, -82},
}

local function copyArray(source)
    local copy = {}
    for index, value in ipairs(source) do copy[index] = value end
    return copy
end

local function join(values)
    return #values == 0 and "∅" or table.concat(values, ", ")
end

local function buildTraversal(mode)
    local frontier, discovered, parent, visited, trace = {START}, {[START] = true}, {}, {}, {}
    while #frontier > 0 do
        local current
        if mode == "bfs" then
            current = frontier[1]
            table.remove(frontier, 1)
        else
            current = frontier[#frontier]
            table.remove(frontier, #frontier)
        end

        local newly = {}
        if mode == "bfs" then
            for _, neighbor in ipairs(ADJACENCY[current]) do
                if not discovered[neighbor] then
                    discovered[neighbor], parent[neighbor] = true, current
                    frontier[#frontier + 1] = neighbor
                    newly[#newly + 1] = neighbor
                end
            end
        else
            for index = #ADJACENCY[current], 1, -1 do
                local neighbor = ADJACENCY[current][index]
                if not discovered[neighbor] then
                    discovered[neighbor], parent[neighbor] = true, current
                    frontier[#frontier + 1] = neighbor
                    newly[#newly + 1] = neighbor
                end
            end
        end

        visited[#visited + 1] = current
        trace[#trace + 1] = {
            current = current, parent = parent[current], newly = newly,
            frontierAfter = copyArray(frontier), visitedAfter = copyArray(visited),
        }
    end
    return trace, visited
end

local BFS_TRACE, BFS_ORDER = buildTraversal("bfs")
local DFS_TRACE, DFS_ORDER = buildTraversal("dfs")
assert(table.concat(BFS_ORDER, "") == "ABCDEF")
assert(table.concat(DFS_ORDER, "") == "ABDECF")

local function translate(x, y)
    return {1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, 0, 0, 0, 0, 1}
end

local title = scene:text {
    text = "BFS vs DFS · frontier order chooses the next node",
    point = {0, 230}, role = "h2", fill = "foreground",
    layer = LAYER.text, id = "scene-title",
}
local subtitle = scene:text {
    text = "same topology, start node, and adjacency order · queue versus stack",
    point = {0, 194}, role = "text", fill = "muted",
    layer = LAYER.text, id = "scene-subtitle",
}
scene:line {
    from = {0, 168}, to = {0, -204}, stroke = "border", width = 2,
    layer = LAYER.divider, id = "comparison-divider",
}
local bfsHeading = scene:text {
    text = "BFS · FIFO queue", point = {-240, 158}, role = "h3",
    fill = "accent", layer = LAYER.text, id = "bfs:heading",
}
local dfsHeading = scene:text {
    text = "DFS · LIFO stack", point = {240, 158}, role = "h3",
    fill = "secondary", layer = LAYER.text, id = "dfs:heading",
}
local legend = scene:text {
    text = "small dot = visited", point = {0, -198}, role = "code",
    fill = "muted", layer = LAYER.text, id = "state-legend",
}

local function makeGraph(prefix, offsetX, identityColor)
    local root = scene:group {id = prefix .. ":graph"}
    local nodes = root:group {id = prefix .. ":nodes"}
    local handles, bodies, visitedMarks = {}, {}, {}
    for _, id in ipairs(NODE_ORDER) do
        local p = POSITIONS[id]
        local node = nodes:group {
            matrix = translate(offsetX + p[1], p[2]), id = prefix .. ":node:" .. id,
        }
        bodies[id] = node:circle {
            center = {0, 0}, radius = 25, fill = "surface", stroke = "border",
            width = 2.5, layer = LAYER.node, id = prefix .. ":node:" .. id .. ":body",
        }
        node:text {
            text = id, point = {0, 0}, role = "h3", fill = "foreground",
            layer = LAYER.text, id = prefix .. ":node:" .. id .. ":label",
        }
        visitedMarks[id] = node:circle {
            center = {19, 19}, radius = 5, fill = identityColor, stroke = identityColor,
            width = 1, opacity = 0, layer = LAYER.mark,
            id = prefix .. ":node:" .. id .. ":visited-mark",
        }
        handles[id] = node
    end

    local edges = root:group {id = prefix .. ":edges"}
    local edgeHandles = {}
    for _, from in ipairs(NODE_ORDER) do
        for _, to in ipairs(ADJACENCY[from]) do
            local id = prefix .. ":edge:" .. from .. ":" .. to
            edgeHandles[from .. ":" .. to] = edges:connector {
                from = handles[from], to = handles[to], padding = 5, tip = 10,
                stroke = "border", width = 2.2, layer = LAYER.edge, id = id,
            }
        end
    end
    return {root = root, edges = edges, bodies = bodies, marks = visitedMarks, edgeHandles = edgeHandles}
end

local bfs = makeGraph("bfs", -240, "accent")
local dfs = makeGraph("dfs", 240, "secondary")

local function frontierLabel(mode, frontier)
    if mode == "bfs" then return "queue head → [" .. join(frontier) .. "]"
    else
        local top = #frontier > 0 and frontier[#frontier] or "∅"
        return "stack [" .. join(frontier) .. "] · top=" .. top
    end
end

local function runTraversal(prefix, mode, graph, trace, order, x, identityColor)
    local status = scene:text {
        text = frontierLabel(mode, {START}), point = {x, -135}, role = "code",
        fill = "focus", layer = LAYER.text, id = prefix .. ":status:0",
    }
    scene:fade_in(status, {duration = 0.24, curve = "gentle"})
    local statusIndex = 0
    for _, event in ipairs(trace) do
        statusIndex = statusIndex + 1
        local operation = mode == "bfs" and "dequeue " or "pop "
        local nextStatus = scene:text {
            text = operation .. event.current .. " · " .. frontierLabel(mode, event.frontierAfter),
            point = {x, -135}, role = "code", fill = "focus",
            layer = LAYER.text, id = prefix .. ":status:" .. statusIndex,
        }
        scene:fade_transform(status, nextStatus, 0.17, "gentle")
        status = nextStatus

        local focusTargets = {{target = graph.bodies[event.current], fill = "focus", stroke = "focus"}}
        local incoming = event.parent and graph.edgeHandles[event.parent .. ":" .. event.current]
        if incoming then focusTargets[#focusTargets + 1] = {target = incoming, stroke = "focus"} end
        scene:play(focusTargets, 0.34, "ease_in_out", 0)
        scene:wait(0.16)

        local settleTargets = {
            {target = graph.bodies[event.current], fill = "surface", stroke = identityColor},
            {target = graph.marks[event.current], opacity = 1},
        }
        if incoming then settleTargets[#settleTargets + 1] = {target = incoming, stroke = "border"} end
        scene:play(settleTargets, 0.30, "ease_in_out", 0)
    end

    local result = scene:text {
        text = "visit order: " .. table.concat(order, " → "),
        point = {x, -171}, role = "code", fill = identityColor,
        layer = LAYER.text, id = prefix .. ":result:order",
    }
    scene:fade_in(result, {shift = {0, 4}, duration = 0.32, curve = "gentle"})
    return status, result
end

scene:fade_in(title, {shift = {0, -6}, duration = 0.42, curve = "gentle"})
scene:fade_in(subtitle, {shift = {0, -5}, duration = 0.34, curve = "gentle"})
scene:fade_in(bfsHeading, {duration = 0.26, curve = "gentle"})
scene:fade_in(dfsHeading, {duration = 0.26, curve = "gentle"})
scene:create(bfs.edges, 0.48, "ease_out")
scene:fade_in(bfs.root, {duration = 0.42, curve = "gentle"})
scene:create(dfs.edges, 0.48, "ease_out")
scene:fade_in(dfs.root, {duration = 0.42, curve = "gentle"})
scene:fade_in(legend, {duration = 0.22, curve = "gentle"})
scene:play({{target = dfs.root, opacity = 0.28}, {target = dfsHeading, opacity = 0.45}}, 0.30, "gentle", 0)

local bfsStatus = runTraversal("bfs", "bfs", bfs, BFS_TRACE, BFS_ORDER, -240, "accent")
scene:wait(0.45)
scene:play({
    {target = bfs.root, opacity = 0.32}, {target = bfsHeading, opacity = 0.48},
    {target = bfsStatus, opacity = 0.35}, {target = dfs.root, opacity = 1},
    {target = dfsHeading, opacity = 1},
}, 0.42, "ease_in_out", 0)

runTraversal("dfs", "dfs", dfs, DFS_TRACE, DFS_ORDER, 240, "secondary")
local result = scene:text {
    text = "same graph · FIFO expands by depth; LIFO follows one branch first",
    point = {0, -230}, role = "text", fill = "result",
    layer = LAYER.text, id = "result:comparison",
}
scene:play({{target = bfs.root, opacity = 1}, {target = bfsHeading, opacity = 1}}, 0.38, "gentle", 0)
scene:fade_in(result, {shift = {0, 4}, duration = 0.36, curve = "gentle"})
scene:wait(2.3)
return scene
