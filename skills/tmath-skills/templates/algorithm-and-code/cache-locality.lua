-- Question: why does traversal order change cache misses for the same 4x4 array?
-- Model: row-major storage, four elements per cache line, cache capacity = one line.
local scene = tmath.scene {width = 960, height = 540, fps = 30, loop = false, theme = "adaptive_vscode", camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540}}
local N, LINE_SIZE, CACHE_LINES = 4, 4, 1
local LAYER = {body = 20, text = 40}
local function buildTrace(order)
    local trace, cacheLine, hits, misses = {}, nil, 0, 0
    local function access(row, col)
        local index = (row - 1) * N + (col - 1)
        local line = math.floor(index / LINE_SIZE)
        local hit = cacheLine == line
        if hit then hits = hits + 1 else misses = misses + 1; cacheLine = line end
        trace[#trace + 1] = {row = row, col = col, index = index, line = line, hit = hit, hits = hits, misses = misses}
    end
    if order == "row" then for row = 1, N do for col = 1, N do access(row, col) end end
    else for col = 1, N do for row = 1, N do access(row, col) end end end
    return trace, hits, misses
end
local ROW_TRACE, ROW_HITS, ROW_MISSES = buildTrace("row")
local COL_TRACE, COL_HITS, COL_MISSES = buildTrace("col")
assert(CACHE_LINES == 1 and ROW_HITS == 12 and ROW_MISSES == 4 and COL_HITS == 0 and COL_MISSES == 16)

local title = scene:text {text = "Cache locality · same cells, different access order", point = {0, 230}, role = "h2", fill = "foreground", layer = LAYER.text, id = "scene-title"}
local subtitle = scene:text {text = "row-major array · cache line = 4 elements · capacity = 1 line", point = {0, 194}, role = "code", fill = "muted", layer = LAYER.text, id = "scene-subtitle"}
local PANEL = {row = {x = -245, label = "ROW-MAJOR"}, col = {x = 245, label = "COLUMN-MAJOR"}}
local bodies = {row = {}, col = {}}
for _, mode in ipairs({"row", "col"}) do
    scene:text {text = PANEL[mode].label, point = {PANEL[mode].x, 145}, role = "code", fill = "accent", layer = LAYER.text, id = mode .. ":label"}
    for row = 1, N do
        bodies[mode][row] = {}
        for col = 1, N do
            local x = PANEL[mode].x - 84 + (col - 1) * 56
            local y = 95 - (row - 1) * 56
            bodies[mode][row][col] = scene:rectangle {center = {x, y}, size = {50, 50}, corner = 4, fill = "surface", stroke = "border", width = 2, layer = LAYER.body, id = mode .. ":cell:" .. row .. ":" .. col .. ":body"}
            local order = mode == "row" and ((row - 1) * N + col) or ((col - 1) * N + row)
            scene:text {text = tostring(order), point = {x, y}, role = "code", fill = "foreground", layer = LAYER.text, id = mode .. ":cell:" .. row .. ":" .. col .. ":order"}
        end
    end
end
local counter = {}
counter.row = scene:text {text = "hits 0 · misses 0", point = {PANEL.row.x, -145}, role = "code", fill = "muted", layer = LAYER.text, id = "row:counter:0"}
counter.col = scene:text {text = "hits 0 · misses 0", point = {PANEL.col.x, -145}, role = "code", fill = "muted", layer = LAYER.text, id = "col:counter:0"}
local counterVersion = {row = 0, col = 0}
local function setCounter(mode, hits, misses)
    counterVersion[mode] = counterVersion[mode] + 1
    local nextCounter = scene:text {text = string.format("hits %d · misses %d", hits, misses), point = {PANEL[mode].x, -145}, role = "code", fill = "focus", layer = LAYER.text, id = mode .. ":counter:" .. counterVersion[mode]}
    scene:fade_transform(counter[mode], nextCounter, 0.18, "gentle"); counter[mode] = nextCounter
end
scene:fade_in(title, {shift = {0, -6}, duration = 0.42, curve = "gentle"}); scene:fade_in(subtitle, {duration = 0.32, curve = "gentle"}); scene:wait(0.35)
for group = 1, N do
    local rowTargets, colTargets = {}, {}
    for col = 1, N do rowTargets[#rowTargets + 1] = {target = bodies.row[group][col], fill = "focus", stroke = "focus"} end
    for row = 1, N do colTargets[#colTargets + 1] = {target = bodies.col[row][group], fill = "danger", stroke = "danger"} end
    scene:play(rowTargets, 0.28, "ease_in_out", 0.04)
    local rowEvent = ROW_TRACE[group * N]
    setCounter("row", rowEvent.hits, rowEvent.misses)
    local rowSettled = {}
    for col = 1, N do rowSettled[#rowSettled + 1] = {target = bodies.row[group][col], fill = "surface", stroke = "success"} end
    scene:play(rowSettled, 0.20, "ease_in_out", 0)
    scene:play(colTargets, 0.28, "ease_in_out", 0.04)
    local colEvent = COL_TRACE[group * N]
    setCounter("col", colEvent.hits, colEvent.misses)
    local colSettled = {}
    for row = 1, N do colSettled[#colSettled + 1] = {target = bodies.col[row][group], fill = "surface", stroke = "danger"} end
    scene:play(colSettled, 0.20, "ease_in_out", 0)
end
local result = scene:text {text = "row-major: 4 misses · column-major: 16 misses · capacity-one model", point = {0, -215}, role = "text", fill = "result", layer = LAYER.text, id = "result:cache-locality"}
scene:fade_in(result, {duration = 0.34, curve = "gentle"}); scene:wait(2.5)
return scene
