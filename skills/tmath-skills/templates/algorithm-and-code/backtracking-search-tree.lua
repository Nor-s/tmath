-- Question: why does backtracking remove a choice before trying its sibling?
-- Variant: first solution to 4-queens, columns tried left-to-right.
-- The complete decision trace is generated before any timeline operation.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local N = 4
local LAYER = {edge = 8, cell = 12, body = 20, text = 40, focus = 50}

local function buildTrace()
    local columns, events, nodes, solution = {}, {}, {}, nil
    local function safe(row, col)
        for prior = 1, row - 1 do
            local other = columns[prior]
            if other == col or math.abs(other - col) == math.abs(prior - row) then return false end
        end
        return true
    end
    local function keyThrough(row, extra)
        local values = {}
        for r = 1, row do values[#values + 1] = tostring(r == row and extra or columns[r]) end
        return table.concat(values, "-")
    end
    local function search(row, parentKey)
        if row > N then
            solution = {columns[1], columns[2], columns[3], columns[4]}
            events[#events + 1] = {kind = "solution", columns = solution}
            return true
        end
        for col = 1, N do
            events[#events + 1] = {kind = "try", row = row, col = col}
            if safe(row, col) then
                columns[row] = col
                local key = keyThrough(row, col)
                local node = {key = key, parent = parentKey, row = row, col = col}
                nodes[#nodes + 1] = node
                events[#events + 1] = {kind = "place", node = node}
                if search(row + 1, key) then return true end
                events[#events + 1] = {kind = "backtrack", node = node}
                columns[row] = nil
            else
                events[#events + 1] = {kind = "reject", row = row, col = col}
            end
        end
        return false
    end
    assert(search(1, "root"))
    return events, nodes, solution
end

local TRACE, NODES, SOLUTION = buildTrace()
assert(table.concat(SOLUTION, ",") == "2,4,1,3")
local PLACED = {}
for _, node in ipairs(NODES) do PLACED[node.row .. ":" .. node.col] = true end
local TREE_POS = {
    root = {305, 120}, ["1"] = {210, 63}, ["1-3"] = {145, 6},
    ["1-4"] = {250, 6}, ["1-4-2"] = {250, -51}, ["2"] = {400, 63},
    ["2-4"] = {400, 6}, ["2-4-1"] = {400, -51}, ["2-4-1-3"] = {400, -108},
}
for _, node in ipairs(NODES) do assert(TREE_POS[node.key], "missing illustrative tree position") end

local title = scene:text {
    text = "Backtracking · choose, reject, undo, try the sibling",
    point = {0, 230}, role = "h2", fill = "foreground",
    layer = LAYER.text, id = "scene-title",
}
local subtitle = scene:text {
    text = "4-queens · depth-first search · columns tried left-to-right",
    point = {0, 194}, role = "code", fill = "muted",
    layer = LAYER.text, id = "scene-subtitle",
}
local boardLabel = scene:text {
    text = "BOARD STATE", point = {-245, 145}, role = "code", fill = "accent",
    layer = LAYER.text, id = "board-label",
}
local treeLabel = scene:text {
    text = "EXPLORED CHOICES", point = {305, 145}, role = "code", fill = "accent",
    layer = LAYER.text, id = "tree-label",
}

local CELL = 72
local BOARD_X, BOARD_Y = -355, 110
local cells, queens = {}, {}
for row = 1, N do
    cells[row], queens[row] = {}, {}
    for col = 1, N do
        local x = BOARD_X + (col - 0.5) * CELL
        local y = BOARD_Y - (row - 0.5) * CELL
        cells[row][col] = scene:rectangle {
            center = {x, y}, size = {CELL - 3, CELL - 3},
            fill = (row + col) % 2 == 0 and "surface" or "border",
            stroke = "muted", width = 1, layer = LAYER.cell,
            id = string.format("board:%d:%d:body", row, col),
        }
        if PLACED[row .. ":" .. col] then
            queens[row][col] = scene:text {
                text = "Q", point = {x, y}, role = "h3", fill = "result", opacity = 0,
                layer = LAYER.text, id = string.format("queen:%d:%d", row, col),
            }
        end
    end
end

local rootBody = scene:circle {
    center = TREE_POS.root, radius = 17, fill = "surface", stroke = "border", width = 2,
    layer = LAYER.body, id = "choice:root:body",
}
local rootText = scene:text {
    text = "∅", point = TREE_POS.root, role = "code", fill = "foreground",
    layer = LAYER.text, id = "choice:root:label",
}
local nodeBodies, nodeLabels, nodeEdges = {}, {}, {}
for _, node in ipairs(NODES) do
    local pos, parent = TREE_POS[node.key], TREE_POS[node.parent]
    nodeEdges[node.key] = scene:line {
        from = {parent[1], parent[2] - 17}, to = {pos[1], pos[2] + 17},
        stroke = "muted", width = 2, opacity = 0,
        layer = LAYER.edge, id = "choice:" .. node.key .. ":edge",
    }
    nodeBodies[node.key] = scene:circle {
        center = pos, radius = 17, fill = "surface", stroke = "border", width = 2, opacity = 0,
        layer = LAYER.body, id = "choice:" .. node.key .. ":body",
    }
    nodeLabels[node.key] = scene:text {
        text = tostring(node.col), point = pos, role = "code", fill = "foreground", opacity = 0,
        layer = LAYER.text, id = "choice:" .. node.key .. ":label",
    }
end

local status, statusVersion = nil, 0
local function setStatus(text, color)
    statusVersion = statusVersion + 1
    local nextStatus = scene:text {
        text = text, point = {0, -188}, role = "code", fill = color or "focus",
        layer = LAYER.text, id = "status:" .. statusVersion,
    }
    if status then scene:fade_transform(status, nextStatus, 0.14, "gentle")
    else scene:fade_in(nextStatus, {duration = 0.22, curve = "gentle"}) end
    status = nextStatus
end

scene:fade_in(title, {shift = {0, -6}, duration = 0.42, curve = "gentle"})
scene:fade_in(subtitle, {shift = {0, -5}, duration = 0.34, curve = "gentle"})
scene:fade_in(boardLabel, {duration = 0.24, curve = "gentle"})
scene:fade_in(treeLabel, {duration = 0.24, curve = "gentle"})
scene:fade_in(rootBody, {duration = 0.24, curve = "gentle"})
scene:fade_in(rootText, {duration = 0.20, curve = "gentle"})

local activeByRow = {}
for _, event in ipairs(TRACE) do
    if event.kind == "try" then
        setStatus(string.format("try row %d, column %d", event.row, event.col))
        scene:play({{target = cells[event.row][event.col], stroke = "focus"}},
            0.15, "ease_in_out", 0)
    elseif event.kind == "reject" then
        setStatus(string.format("reject (%d,%d): same column or diagonal", event.row, event.col), "danger")
        scene:play({{target = cells[event.row][event.col], fill = "danger", stroke = "danger"}},
            0.16, "ease_in_out", 0)
        scene:play({{target = cells[event.row][event.col], fill = (event.row + event.col) % 2 == 0 and "surface" or "border", stroke = "muted"}},
            0.16, "ease_in_out", 0)
    elseif event.kind == "place" then
        local node = event.node
        setStatus(string.format("choose column %d for row %d", node.col, node.row), "success")
        scene:play({
            {target = queens[node.row][node.col], opacity = 1},
            {target = cells[node.row][node.col], stroke = "success"},
            {target = nodeEdges[node.key], opacity = 1},
            {target = nodeBodies[node.key], opacity = 1, stroke = "success"},
            {target = nodeLabels[node.key], opacity = 1},
        }, 0.28, "ease_out", 0)
        activeByRow[node.row] = node
    elseif event.kind == "backtrack" then
        local node = event.node
        setStatus(string.format("dead end → undo row %d, column %d", node.row, node.col), "warning")
        scene:play({
            {target = queens[node.row][node.col], opacity = 0},
            {target = cells[node.row][node.col], stroke = "muted"},
            {target = nodeBodies[node.key], opacity = 0.28, stroke = "muted"},
            {target = nodeLabels[node.key], opacity = 0.28},
            {target = nodeEdges[node.key], opacity = 0.28},
        }, 0.30, "ease_in_out", 0)
        activeByRow[node.row] = nil
    elseif event.kind == "solution" then
        setStatus("all four rows satisfy the constraints", "result")
    end
end

local solutionTargets = {}
local prefix = {}
for row, col in ipairs(SOLUTION) do
    prefix[#prefix + 1] = tostring(col)
    local key = table.concat(prefix, "-")
    solutionTargets[#solutionTargets + 1] = {target = nodeBodies[key], fill = "result", stroke = "result"}
    solutionTargets[#solutionTargets + 1] = {target = cells[row][col], stroke = "result"}
end
scene:play(solutionTargets, 0.48, "ease_in_out", 0)
local result = scene:text {
    text = "solution [2, 4, 1, 3] · failed branches stay visible as search history",
    point = {0, -225}, role = "text", fill = "result",
    layer = LAYER.text, id = "result:first-solution",
}
scene:fade_transform(status, result, 0.22, "gentle")
scene:wait(2.4)
return scene
