-- Advanced reference: reconstruct one fractional sample from four neighboring texels.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local size = 4
local pixels = {
    {{39, 78, 145}, {48, 130, 180}, {67, 174, 167}, {109, 190, 132}},
    {{63, 68, 160}, {89, 112, 198}, {118, 162, 202}, {163, 191, 169}},
    {{112, 66, 151}, {151, 86, 169}, {194, 124, 151}, {226, 161, 113}},
    {{155, 71, 126}, {198, 91, 112}, {228, 127, 91}, {244, 174, 88}},
}
local sample = {x = 1.65, y = 1.35}
local x0, y0 = math.floor(sample.x), math.floor(sample.y)
local tx, ty = sample.x - x0, sample.y - y0
local neighbors = {
    {x = x0,     y = y0,     weight = (1 - tx) * (1 - ty), key = "00"},
    {x = x0 + 1, y = y0,     weight = tx * (1 - ty),       key = "10"},
    {x = x0,     y = y0 + 1, weight = (1 - tx) * ty,       key = "01"},
    {x = x0 + 1, y = y0 + 1, weight = tx * ty,             key = "11"},
}
local function clampByte(value) return math.max(0, math.min(255, math.floor(value + 0.5))) end
local function color(rgb)
    return string.format("#%02x%02x%02x", clampByte(rgb[1]), clampByte(rgb[2]), clampByte(rgb[3]))
end
local function interpolate()
    local result = {0, 0, 0}
    for _, neighbor in ipairs(neighbors) do
        local texel = pixels[neighbor.y + 1][neighbor.x + 1]
        for channel = 1, 3 do result[channel] = result[channel] + texel[channel] * neighbor.weight end
    end
    return result
end
local function patches()
    local result = {}
    for y = 0, size - 1 do
        for x = 0, size - 1 do
            result[#result + 1] = {region = {x, y, 1, 1}, color = color(pixels[y + 1][x + 1])}
        end
    end
    return result
end
local gridMatrix = {0.82, 0, 0, -4.05, 0, 0.82, 0, -1.23, 0, 0, 1, 0, 0, 0, 0, 1}
local function mapPoint(matrix, point)
    return {matrix[1] * point[1] + matrix[2] * point[2] + matrix[4],
            matrix[5] * point[1] + matrix[6] * point[2] + matrix[8]}
end

-- The image, neighbor centers, and fractional point share one local pixel space.
local grid = scene:space {id = "bilinear-grid-space", x = {0, size - 1, 1}, y = {0, size - 1, 1}, opacity = 0, matrix = gridMatrix}
local image = grid:cell {
    id = "bilinear-image", origin = {-0.5, -0.5}, size = {size, size}, mode = "padd", padding = 0.045,
    color = "surface", patches = patches(),
}
local footprint = grid:rectangle {
    id = "bilinear-footprint", center = {x0 + 0.5, y0 + 0.5}, size = {1.94, 1.94},
    fill = "#4fc1ff12", stroke = "focus", width = 3, layer = 20,
}
local sampleColor = color(interpolate())
local samplePoint = grid:point {id = "bilinear-sample-point", point = {sample.x, sample.y}, fill = sampleColor, radius = 9, layer = 40}
local links, weightLabels = {}, {}
for index, neighbor in ipairs(neighbors) do
    local texelColor = color(pixels[neighbor.y + 1][neighbor.x + 1])
    links[index] = grid:line {
        id = "bilinear-weight-line-" .. neighbor.key, from = {neighbor.x, neighbor.y}, to = {sample.x, sample.y},
        stroke = texelColor, width = 2 + 5 * neighbor.weight, layer = 30,
    }
    weightLabels[index] = scene:text {
        id = "bilinear-weight-label-" .. neighbor.key, text = string.format("w%s %.2f", neighbor.key, neighbor.weight),
        point = {-4.4 + (index - 1) * 1.05, -2.18}, role = "code", fill = texelColor,
        align = {0.5, 0.5}, layer = 50,
    }
end

-- The result swatch uses the exact channel-weighted color shown at the sample point.
local sampleRoot = mapPoint(gridMatrix, {sample.x, sample.y})
local resultCenter, resultSize = {2.7, 0}, {2.05, 2.05}
local transfer = scene:arrow {id = "bilinear-transfer", from = {sampleRoot[1] + 0.2, sampleRoot[2]}, to = {1.5, 0}, stroke = sampleColor, width = 3, tip = 12, layer = 20}
local result = scene:rectangle {id = "bilinear-result", center = resultCenter, size = resultSize, fill = sampleColor, stroke = "border", width = 3, layer = 10}
local labels = {
    scene:text {id = "bilinear-coordinate", text = string.format("sample(%.2f, %.2f)", sample.x, sample.y), point = {-2.82, 2.18}, role = "code", fill = "foreground", align = {0.5, 0.5}, layer = 50},
    scene:text {id = "bilinear-formula", text = "Σ wᵢⱼ Cᵢⱼ", point = {2.7, 1.52}, role = "code", fill = "muted", align = {0.5, 0.5}, layer = 50},
    scene:text {id = "bilinear-result-label", text = sampleColor:upper(), point = {2.7, -1.52}, role = "code", fill = sampleColor, align = {0.5, 0.5}, layer = 50},
}

-- Reveal the four contributing paths before committing the interpolated sample.
scene:create(image, 0.7, "ease_out")
scene:fade_in(labels[1], {shift = {0, 0.08}, duration = 0.25, curve = "gentle"})
scene:create(footprint, 0.3, "ease_out")
scene:create(links, 0.5, "ease_in_out", 0.06)
scene:create(weightLabels, 0.28, "ease_out", 0.04)
scene:grow_from_center(samplePoint, 0.25, "ease_out")
scene:create(transfer, 0.4, "ease_out")
scene:draw_border_then_fill(result, 0.55, "ease_out")
scene:fade_in(labels[2], {shift = {0, 0.08}, duration = 0.3, curve = "gentle"})
scene:fade_in(labels[3], {shift = {0, 0.08}, duration = 0.3, curve = "gentle"})
scene:wait(1.2)
return scene
