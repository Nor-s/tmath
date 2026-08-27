-- Advanced reference: sample one buffer with nearest and bilinear reconstruction.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.8},
}

local columns, rows, gridScale = 5, 5, 0.62
local pixels = {
    {{23, 63, 95}, {32, 99, 155}, {60, 174, 163}, {246, 213, 92}, {237, 85, 59}},
    {{32, 99, 155}, {60, 174, 163}, {246, 213, 92}, {237, 85, 59}, {156, 39, 176}},
    {{60, 174, 163}, {246, 213, 92}, {249, 247, 243}, {237, 85, 59}, {156, 39, 176}},
    {{246, 213, 92}, {237, 85, 59}, {156, 39, 176}, {32, 99, 155}, {60, 174, 163}},
    {{237, 85, 59}, {156, 39, 176}, {32, 99, 155}, {60, 174, 163}, {246, 213, 92}},
}
local sample = {x = 1.72, y = 1.35}
local nearest = {x = math.floor(sample.x + 0.5), y = math.floor(sample.y + 0.5)}
local x0, y0 = math.floor(sample.x), math.floor(sample.y)
local tx, ty = sample.x - x0, sample.y - y0
local neighbors = {
    {x = x0,     y = y0,     weight = (1 - tx) * (1 - ty), key = "00"},
    {x = x0 + 1, y = y0,     weight = tx * (1 - ty),       key = "10"},
    {x = x0,     y = y0 + 1, weight = (1 - tx) * ty,       key = "01"},
    {x = x0 + 1, y = y0 + 1, weight = tx * ty,             key = "11"},
}
local function byte(value) return math.max(0, math.min(255, math.floor(value + 0.5))) end
local function color(rgb) return string.format("#%02x%02x%02x", byte(rgb[1]), byte(rgb[2]), byte(rgb[3])) end
local function pixelAt(x, y) return pixels[y + 1][x + 1] end
local function bilinearColor()
    local result = {0, 0, 0}
    for _, neighbor in ipairs(neighbors) do
        local texel = pixelAt(neighbor.x, neighbor.y)
        for channel = 1, 3 do result[channel] = result[channel] + texel[channel] * neighbor.weight end
    end
    return result
end
local function patches()
    local result = {}
    for y = 0, rows - 1 do
        for x = 0, columns - 1 do result[#result + 1] = {region = {x, y, 1, 1}, color = color(pixelAt(x, y))} end
    end
    return result
end
local function matrixAt(center)
    return {gridScale, 0, 0, center[1] - 0.5 * (columns - 1) * gridScale,
            0, gridScale, 0, center[2] - 0.5 * (rows - 1) * gridScale,
            0, 0, 1, 0, 0, 0, 0, 1}
end
local function buffer(id, center)
    local space = scene:space {id = id .. "-space", x = {0, columns - 1, 1}, y = {0, rows - 1, 1}, opacity = 0, matrix = matrixAt(center)}
    local cells = space:cell {
        id = id .. "-cells", origin = {-0.5, -0.5}, size = {columns, rows}, mode = "padd", padding = 0.045,
        color = "surface", patches = patches(),
    }
    return {space = space, cells = cells, center = center}
end

-- Both views own the same texel data and receive the same fractional coordinate.
local centers = {{-2.75, 0.35}, {2.75, 0.35}}
local nearestView, bilinearView = buffer("nearest", centers[1]), buffer("bilinear", centers[2])
local nearestColor, reconstructedColor = color(pixelAt(nearest.x, nearest.y)), color(bilinearColor())
local samplePoints = {
    nearestView.space:point {id = "nearest-sample-point", point = {sample.x, sample.y}, fill = "focus", radius = 7, layer = 40},
    bilinearView.space:point {id = "bilinear-sample-point", point = {sample.x, sample.y}, fill = "focus", radius = 7, layer = 40},
}

-- Nearest chooses exactly one integer texel center.
local nearestChoice = nearestView.space:rectangle {
    id = "nearest-selected-texel", center = {nearest.x, nearest.y}, size = {0.94, 0.94},
    fill = "#00000000", stroke = nearestColor, width = 4, layer = 30,
}
local nearestCenter = nearestView.space:point {id = "nearest-texel-center", point = {nearest.x, nearest.y}, fill = nearestColor, radius = 6, layer = 35}
local nearestPath = nearestView.space:line {
    id = "nearest-distance", from = {sample.x, sample.y}, to = {nearest.x, nearest.y},
    stroke = nearestColor, width = 3, layer = 30,
}

-- Bilinear uses the enclosing 2 × 2 footprint and four derived weights.
local footprint = bilinearView.space:rectangle {
    id = "bilinear-footprint", center = {x0 + 0.5, y0 + 0.5}, size = {1.94, 1.94},
    fill = "#4fc1ff10", stroke = "focus", width = 3, layer = 20,
}
local contributionLines, weightLabels = {}, {}
for index, neighbor in ipairs(neighbors) do
    local texelColor = color(pixelAt(neighbor.x, neighbor.y))
    contributionLines[index] = bilinearView.space:line {
        id = "bilinear-contribution-" .. neighbor.key, from = {neighbor.x, neighbor.y}, to = {sample.x, sample.y},
        stroke = texelColor, width = 2 + 5 * neighbor.weight, layer = 30,
    }
    weightLabels[index] = scene:text {
        id = "bilinear-weight-" .. neighbor.key, text = string.format("w%s %.2f", neighbor.key, neighbor.weight),
        point = {1.05 + (index - 1) * 1.18, -1.58}, role = "code", fill = texelColor,
        align = {0.5, 0.5}, layer = 40,
    }
end

-- Output swatches are computed by the two algorithms, not copied from display colors.
local outputs = {
    scene:rectangle {id = "nearest-output", center = {centers[1][1], -2.28}, size = {0.78, 0.78}, fill = nearestColor, stroke = "border", width = 3, layer = 10},
    scene:rectangle {id = "bilinear-output", center = {centers[2][1], -2.28}, size = {0.78, 0.78}, fill = reconstructedColor, stroke = "border", width = 3, layer = 10},
}
local labels = {
    scene:text {id = "nearest-label", text = "nearest", point = {centers[1][1], 2.52}, role = "code", fill = "foreground", align = {0.5, 0.5}, layer = 40},
    scene:text {id = "bilinear-label", text = "bilinear", point = {centers[2][1], 2.52}, role = "code", fill = "foreground", align = {0.5, 0.5}, layer = 40},
    scene:text {id = "sampling-coordinate", text = string.format("sample(%.2f, %.2f)", sample.x, sample.y), point = {0, 2.52}, role = "code", fill = "focus", align = {0.5, 0.5}, layer = 40},
    scene:text {id = "nearest-rule", text = string.format("round → texel(%d, %d)", nearest.x, nearest.y), point = {centers[1][1], -1.58}, role = "code", fill = nearestColor, align = {0.5, 0.5}, layer = 40},
    scene:text {id = "nearest-result", text = string.format("nearest %s", nearestColor:upper()), point = {centers[1][1], -2.92}, role = "code", fill = nearestColor, align = {0.5, 0.5}, layer = 40},
    scene:text {id = "bilinear-result", text = string.format("ΣwC %s", reconstructedColor:upper()), point = {centers[2][1], -2.92}, role = "code", fill = reconstructedColor, align = {0.5, 0.5}, layer = 40},
}

-- Teach selection first, then weighted reconstruction from the same settled sample.
scene:create({nearestView.cells, bilinearView.cells}, 0.7, "ease_out", 0.08)
scene:fade_in(labels[1], {shift = {0, 0.06}, duration = 0.24, curve = "gentle"})
scene:fade_in(labels[2], {shift = {0, 0.06}, duration = 0.24, curve = "gentle"})
scene:fade_in(labels[3], {shift = {0, 0.06}, duration = 0.28, curve = "gentle"})
scene:grow_from_center(samplePoints[1], 0.2, "ease_out")
scene:grow_from_center(samplePoints[2], 0.2, "ease_out")
scene:create(nearestPath, 0.35, "ease_out")
scene:grow_from_center(nearestCenter, 0.2, "ease_out")
scene:create(nearestChoice, 0.28, "ease_out")
scene:fade_in(labels[4], {shift = {0, 0.06}, duration = 0.28, curve = "gentle"})
scene:draw_border_then_fill(outputs[1], 0.42, "ease_out")
scene:fade_in(labels[5], {shift = {0, 0.06}, duration = 0.26, curve = "gentle"})
scene:create(footprint, 0.3, "ease_out")
scene:create(contributionLines, 0.5, "ease_in_out", 0.06)
scene:create(weightLabels, 0.28, "ease_out", 0.04)
scene:draw_border_then_fill(outputs[2], 0.42, "ease_out")
scene:fade_in(labels[6], {shift = {0, 0.06}, duration = 0.26, curve = "gentle"})
scene:wait(1.35)
return scene
