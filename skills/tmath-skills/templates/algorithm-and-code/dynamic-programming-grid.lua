-- Question: how does a dynamic-programming value become valid only after its dependencies?
-- Variant: minimum path sum; moves are right or down; cells are evaluated by anti-diagonals.
-- Edit COSTS and regenerate the trace rather than hand-editing displayed dp values.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local COSTS = {
    {1, 3, 1, 4},
    {2, 1, 5, 1},
    {4, 2, 1, 1},
}
local ROWS, COLS = #COSTS, #COSTS[1]
local LAYER = {guide = 8, dependency = 14, body = 20, text = 40, focus = 50}

local function buildTrace(costs)
    local dp, parent, trace = {}, {}, {}
    for row = 1, #costs do dp[row], parent[row] = {}, {} end
    for diagonal = 2, ROWS + COLS do
        for row = 1, ROWS do
            local col = diagonal - row
            if col >= 1 and col <= COLS then
                local top = row > 1 and dp[row - 1][col] or nil
                local left = col > 1 and dp[row][col - 1] or nil
                local best, chosen
                if not top and not left then best = 0
                elseif not left or (top and top <= left) then best, chosen = top, "top"
                else best, chosen = left, "left" end
                dp[row][col] = costs[row][col] + best
                parent[row][col] = chosen
                trace[#trace + 1] = {
                    row = row, col = col, cost = costs[row][col], top = top, left = left,
                    chosen = chosen, value = dp[row][col], diagonal = diagonal,
                }
            end
        end
    end
    local path, row, col = {}, ROWS, COLS
    while row and col do
        table.insert(path, 1, {row = row, col = col})
        if parent[row][col] == "top" then row = row - 1
        elseif parent[row][col] == "left" then col = col - 1
        else row, col = nil, nil end
    end
    return trace, dp, path
end

local TRACE, DP, PATH = buildTrace(COSTS)
assert(DP[ROWS][COLS] == 8)
local pathCost = 0
for _, point in ipairs(PATH) do pathCost = pathCost + COSTS[point.row][point.col] end
assert(pathCost == DP[ROWS][COLS])

local CELL_W, CELL_H = 84, 72
local GRID_X, GRID_Y = -235, 45
local function center(row, col)
    return GRID_X + (col - 1) * CELL_W, GRID_Y - (row - 1) * CELL_H
end

local title = scene:text {
    text = "Dynamic programming · settle dependencies first",
    point = {0, 230}, role = "h2", fill = "foreground",
    layer = LAYER.text, id = "scene-title",
}
local subtitle = scene:text {
    text = "minimum path sum · move right or down · anti-diagonal evaluation",
    point = {0, 194}, role = "code", fill = "muted",
    layer = LAYER.text, id = "scene-subtitle",
}
local gridLabel = scene:text {
    text = "cost / dp", point = {-235, 145}, role = "code", fill = "accent",
    layer = LAYER.text, id = "grid-label",
}
local recurrence = scene:text {
    text = "dp[r,c] = cost[r,c] + min(top, left)",
    point = {260, 105}, role = "code", fill = "foreground",
    layer = LAYER.text, id = "recurrence",
}
local boundary = scene:text {
    text = "missing predecessor = ∞\nstart cell uses 0",
    point = {260, 55}, role = "code", fill = "muted",
    layer = LAYER.text, id = "boundary-rule",
}

local bodies, dpText = {}, {}
for row = 1, ROWS do
    bodies[row], dpText[row] = {}, {}
    for col = 1, COLS do
        local x, y = center(row, col)
        local id = string.format("cell:%d:%d", row, col)
        bodies[row][col] = scene:rectangle {
            center = {x, y}, size = {CELL_W - 8, CELL_H - 8}, corner = 5,
            fill = "surface", stroke = "border", width = 2,
            layer = LAYER.body, id = id .. ":body",
        }
        scene:text {
            text = "c=" .. COSTS[row][col], point = {x, y + 8},
            role = "code", fill = "muted",
            layer = LAYER.text, id = id .. ":cost",
        }
        dpText[row][col] = scene:text {
            text = "d=" .. DP[row][col], point = {x, y - 15},
            role = "code", fill = "result", opacity = 0,
            layer = LAYER.text, id = id .. ":dp",
        }
    end
end

local status, statusVersion = nil, 0
local function setStatus(text, color)
    statusVersion = statusVersion + 1
    local nextStatus = scene:text {
        text = text, point = {245, -45}, role = "code", fill = color or "focus",
        layer = LAYER.text, id = "status:" .. statusVersion,
    }
    if status then scene:fade_transform(status, nextStatus, 0.16, "gentle")
    else scene:fade_in(nextStatus, {duration = 0.24, curve = "gentle"}) end
    status = nextStatus
end

scene:fade_in(title, {shift = {0, -6}, duration = 0.42, curve = "gentle"})
scene:fade_in(subtitle, {shift = {0, -5}, duration = 0.34, curve = "gentle"})
scene:fade_in(gridLabel, {duration = 0.24, curve = "gentle"})
scene:fade_in(recurrence, {duration = 0.32, curve = "gentle"})
scene:fade_in(boundary, {duration = 0.28, curve = "gentle"})

for _, event in ipairs(TRACE) do
    local x, y = center(event.row, event.col)
    local dependencies = scene:group {id = string.format("dependencies:%d:%d", event.row, event.col)}
    if event.top then
        local tx, ty = center(event.row - 1, event.col)
        dependencies:arrow {
            from = {tx, ty - 26}, to = {x, y + 26}, tip = 9,
            stroke = "focus", width = 2.5, layer = LAYER.dependency,
            id = string.format("dependency:top:%d:%d", event.row, event.col),
        }
    end
    if event.left then
        local lx, ly = center(event.row, event.col - 1)
        dependencies:arrow {
            from = {lx + 31, ly}, to = {x - 31, y}, tip = 9,
            stroke = "focus", width = 2.5, layer = LAYER.dependency,
            id = string.format("dependency:left:%d:%d", event.row, event.col),
        }
    end
    local expression
    if not event.top and not event.left then expression = string.format("start: %d + 0 = %d", event.cost, event.value)
    elseif not event.top then expression = string.format("%d + left %d = %d", event.cost, event.left, event.value)
    elseif not event.left then expression = string.format("%d + top %d = %d", event.cost, event.top, event.value)
    else expression = string.format("%d + min(%d, %d) = %d", event.cost, event.top, event.left, event.value) end
    setStatus(expression)
    scene:play({{target = bodies[event.row][event.col], fill = "focus", stroke = "focus"}},
        0.22, "ease_in_out", 0)
    if event.top or event.left then scene:create(dependencies, 0.24, "ease_out") end
    scene:fade_in(dpText[event.row][event.col], {duration = 0.22, curve = "gentle"})
    scene:play({{target = bodies[event.row][event.col], fill = "surface", stroke = "success"}},
        0.22, "ease_in_out", 0)
    if event.top or event.left then scene:fade_out(dependencies, {duration = 0.16, curve = "gentle"}) end
end

local pathTargets = {}
for _, point in ipairs(PATH) do
    pathTargets[#pathTargets + 1] = {target = bodies[point.row][point.col], stroke = "result"}
end
scene:play(pathTargets, 0.55, "ease_in_out", 0.04)
local result = scene:text {
    text = "optimal path cost = " .. DP[ROWS][COLS] .. " · every highlighted cell follows a chosen predecessor",
    point = {0, -205}, role = "text", fill = "result",
    layer = LAYER.text, id = "result:optimal-path",
}
scene:fade_transform(status, result, 0.24, "gentle")
scene:wait(2.3)
return scene
