-- Advanced reference: convert one coverage scanline into contiguous non-zero spans.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 5.8},
}

local coverage = {0, 0, 0.25, 0.70, 1.00, 0.62, 0, 0, 0.35, 0.85, 0.85, 0.30, 0, 0, 0, 0.55, 1.00, 0.75, 0.20, 0}
local columns, cellScale = #coverage, 0.47
local rowMatrix = {cellScale, 0, 0, -0.5 * (columns - 1) * cellScale, 0, cellScale, 0, 1.05, 0, 0, 1, 0, 0, 0, 0, 1}
local function mapPoint(matrix, point)
    return {matrix[1] * point[1] + matrix[2] * point[2] + matrix[4],
            matrix[5] * point[1] + matrix[6] * point[2] + matrix[8]}
end
local function coverageColor(value)
    local alpha = math.floor(48 + 207 * value + 0.5)
    return string.format("#4fc1ff%02x", alpha)
end
local function findSpans(values)
    local result, first = {}, nil
    for index = 1, #values + 1 do
        local active = index <= #values and values[index] > 0
        if active and not first then first = index - 1 end
        if first and not active then
            local finish = index - 1
            local total = 0
            for sample = first + 1, finish do total = total + values[sample] end
            result[#result + 1] = {first = first, finish = finish, mean = total / (finish - first)}
            first = nil
        end
    end
    return result
end
local function rowPatches()
    local result = {}
    for x, value in ipairs(coverage) do
        result[#result + 1] = {region = {x - 1, 0, 1, 1}, color = value > 0 and coverageColor(value) or "#1f293744"}
    end
    return result
end

-- One Cell owns the dense input; the cursor is the only per-pixel timeline object.
local row = scene:space {id = "span-input-space", x = {0, columns - 1, 1}, y = {0, 0, 1}, opacity = 0, matrix = rowMatrix}
local cells = row:cell {
    id = "span-input", origin = {-0.5, -0.5}, size = {columns, 1}, mode = "padd", padding = 0.055,
    color = "surface", patches = rowPatches(),
}
local cursor = row:rectangle {
    id = "span-cursor", center = {0, 0}, size = {0.92, 0.92},
    fill = "#00000000", stroke = "focus", width = 4, layer = 30,
}
local inputLabel = scene:text {id = "span-input-label", text = "coverage scanline", point = {0, 1.82}, role = "code", fill = "muted", align = {0.5, 0.5}, layer = 40}
local outputLabel = scene:text {id = "span-output-label", text = "non-zero spans", point = {0, -0.62}, role = "code", fill = "muted", align = {0.5, 0.5}, layer = 40}

-- Span geometry and labels are derived from the same half-open intervals.
local spans, bars, labels = findSpans(coverage), {}, {}
for index, span in ipairs(spans) do
    local width = (span.finish - span.first) * cellScale
    local center = mapPoint(rowMatrix, {(span.first + span.finish - 1) * 0.5, 0})
    bars[index] = scene:rectangle {
        id = "span-run-" .. index, center = {center[1], -1.32}, size = {width - 0.06, 0.42},
        fill = coverageColor(span.mean), stroke = "focus", width = 2, layer = 20,
    }
    labels[index] = scene:text {
        id = "span-run-label-" .. index, text = string.format("[%d, %d)", span.first, span.finish),
        point = {center[1], -1.88}, role = "code", fill = "foreground", align = {0.5, 0.5}, layer = 40,
    }
end

-- Slow down only when a new semantic run closes; repeated pixels advance quickly.
scene:create(cells, 0.65, "ease_out")
scene:fade_in(inputLabel, {shift = {0, 0.08}, duration = 0.25, curve = "gentle"})
scene:create(cursor, 0.25, "ease_out")
scene:fade_in(outputLabel, {shift = {0, 0.08}, duration = 0.25, curve = "gentle"})
local nextSpan = 1
for x = 0, columns - 1 do
    if x > 0 then scene:shift(cursor, {1, 0}, coverage[x + 1] > 0 and 0.10 or 0.055, "linear") end
    local span = spans[nextSpan]
    if span and x == span.finish - 1 then
        scene:wait(0.14)
        scene:draw_border_then_fill(bars[nextSpan], 0.28, "ease_out")
        scene:fade_in(labels[nextSpan], {shift = {0, 0.06}, duration = 0.2, curve = "gentle"})
        nextSpan = nextSpan + 1
    end
end
scene:wait(1.1)
return scene
