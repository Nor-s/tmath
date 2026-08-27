-- local question: How does progressive JPEG improve a fixed-resolution preview?
-- visible input: one quantized 8 x 8 luminance coefficient block
-- subject object or field: three cumulative inverse-DCT reconstructions
-- one dominant action: add successive zigzag-frequency bands across scans
-- observable output: mean squared error falls while spatial dimensions stay 8 x 8
-- coordinate frame and units: cells are reconstructed 8-bit luminance samples
-- section bounds supplied by the parent: standalone 960 x 540 wrapper
-- final readable pose: DC, low-frequency, and complete quantized reconstructions

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "3_blue_1_eyes",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local LAYER = {cell = 0, arrow = 30, text = 40}
local figure = scene:group {id = "jpg-progressive-scans-figure"}

local function text(parent, id, value, point, role, fill, align)
    return parent:text {
        id = id, text = value, point = point, role = role or "code",
        fill = fill or "foreground", align = align or {0.5, 0.5}, layer = LAYER.text,
    }
end

local function clampByte(value)
    return math.max(0, math.min(255, math.floor(value + 0.5)))
end

local function round(value)
    if value >= 0 then return math.floor(value + 0.5) end
    return math.ceil(value - 0.5)
end

local function gray(value)
    local byte = clampByte(value)
    return string.format("#%02x%02x%02xff", byte, byte, byte)
end

local function alpha(index)
    return index == 0 and 1 / math.sqrt(2) or 1
end

local function zigzagCoordinates(size)
    local coordinates = {}
    for diagonal = 0, 2 * (size - 1) do
        if diagonal % 2 == 0 then
            local row = math.min(diagonal, size - 1)
            local column = diagonal - row
            while row >= 0 and column < size do
                coordinates[#coordinates + 1] = {column, row}
                row, column = row - 1, column + 1
            end
        else
            local column = math.min(diagonal, size - 1)
            local row = diagonal - column
            while column >= 0 and row < size do
                coordinates[#coordinates + 1] = {column, row}
                column, row = column - 1, row + 1
            end
        end
    end
    return coordinates
end

local spatial = {}
for row = 0, 7 do
    for column = 0, 7 do
        local edge = column >= 4 and row >= 2 and row <= 5 and 24 or 0
        spatial[#spatial + 1] = clampByte(72 + 10 * row + 5 * column + edge)
    end
end

local coefficients = {}
for v = 0, 7 do
    for u = 0, 7 do
        local sum = 0
        for y = 0, 7 do
            for x = 0, 7 do
                local sample = spatial[y * 8 + x + 1] - 128
                sum = sum
                    + sample
                        * math.cos((2 * x + 1) * u * math.pi / 16)
                        * math.cos((2 * y + 1) * v * math.pi / 16)
            end
        end
        coefficients[#coefficients + 1] = 0.25 * alpha(u) * alpha(v) * sum
    end
end

local luminanceQ = {
    16, 11, 10, 16, 24, 40, 51, 61,
    12, 12, 14, 19, 26, 58, 60, 55,
    14, 13, 16, 24, 40, 57, 69, 56,
    14, 17, 22, 29, 51, 87, 80, 62,
    18, 22, 37, 56, 68, 109, 103, 77,
    24, 35, 55, 64, 81, 104, 113, 92,
    49, 64, 78, 87, 103, 121, 120, 101,
    72, 92, 95, 98, 112, 100, 103, 99,
}
local quantized = {}
for index, value in ipairs(coefficients) do quantized[index] = round(value / luminanceQ[index]) end
local zigzag = zigzagCoordinates(8)

local function reconstruct(lastZigzagIndex)
    local active = {}
    for index = 1, 64 do active[index] = 0 end
    for scanIndex = 1, lastZigzagIndex + 1 do
        local coordinate = zigzag[scanIndex]
        local naturalIndex = coordinate[2] * 8 + coordinate[1] + 1
        active[naturalIndex] = quantized[naturalIndex] * luminanceQ[naturalIndex]
    end

    local samples = {}
    for y = 0, 7 do
        for x = 0, 7 do
            local sum = 0
            for v = 0, 7 do
                for u = 0, 7 do
                    local coefficient = active[v * 8 + u + 1]
                    sum = sum
                        + alpha(u) * alpha(v) * coefficient
                            * math.cos((2 * x + 1) * u * math.pi / 16)
                            * math.cos((2 * y + 1) * v * math.pi / 16)
                end
            end
            samples[#samples + 1] = clampByte(128 + 0.25 * sum)
        end
    end
    return samples
end

local function mse(reference, candidate)
    local sum = 0
    for index, value in ipairs(reference) do
        local delta = value - candidate[index]
        sum = sum + delta * delta
    end
    return sum / #reference
end

local scans = {
    {number = 1, ss = 0, se = 0, last = 0, title = "DC preview"},
    {number = 2, ss = 1, se = 5, last = 5, title = "low frequencies"},
    {number = 3, ss = 6, se = 63, last = 63, title = "all quantized bands"},
}
for _, scan in ipairs(scans) do
    scan.samples = reconstruct(scan.last)
    scan.error = mse(spatial, scan.samples)
end

local function makePreview(scan, centerX)
    local scale = 0.34
    local space = figure:space {
        id = string.format("jpg-progressive-scan-%d-space", scan.number),
        x = {0, 7, 1}, y = {0, 7, 1}, opacity = 0,
        matrix = {
            scale, 0, 0, centerX - 3.5 * scale,
            0, scale, 0, 0.15 - 3.5 * scale,
            0, 0, 1, 0,
            0, 0, 0, 1,
        },
    }
    local patches = {}
    for row = 0, 7 do
        for column = 0, 7 do
            local index = row * 8 + column + 1
            patches[#patches + 1] = {
                region = {column, row, 1, 1}, color = gray(scan.samples[index]),
            }
        end
    end
    local cell = space:cell {
        id = string.format("jpg-progressive-scan-%d-preview", scan.number),
        origin = {-0.5, -0.5}, size = {8, 8}, mode = "padd",
        padding = 0.045, color = "surface", patches = patches, layer = LAYER.cell,
    }
    return cell
end

local claim = text(
    figure, "jpg-progressive-scans-claim",
    "Progressive JPEG adds DCT bands to a fixed-size preview",
    {0, 2.55}, "h3"
)
local centers = {-3.62, 0, 3.62}
local previews, labels, parameters, errors = {}, {}, {}, {}
local labelColors = {"info", "focus", "result"}
for index, scan in ipairs(scans) do
    previews[index] = makePreview(scan, centers[index])
    labels[index] = text(
        figure, string.format("jpg-progressive-scan-%d-label", scan.number),
        string.format("scan %d · %s", scan.number, scan.title),
        {centers[index], 1.72}, "code", labelColors[index]
    )
    parameters[index] = text(
        figure, string.format("jpg-progressive-scan-%d-parameters", scan.number),
        string.format("Ss=%d  Se=%d", scan.ss, scan.se),
        {centers[index], -1.34}, "code", "muted"
    )
    errors[index] = text(
        figure, string.format("jpg-progressive-scan-%d-mse", scan.number),
        string.format("MSE = %.1f", scan.error),
        {centers[index], -1.72}, "code", labelColors[index]
    )
end

local arrows = {
    figure:arrow {
        id = "jpg-progressive-scan-1-to-2", from = {-2.10, 0.15}, to = {-1.52, 0.15},
        stroke = "focus", width = 2, tip = 10, layer = LAYER.arrow,
    },
    figure:arrow {
        id = "jpg-progressive-scan-2-to-3", from = {1.52, 0.15}, to = {2.10, 0.15},
        stroke = "result", width = 2, tip = 10, layer = LAYER.arrow,
    },
}
local summary = text(
    figure, "jpg-progressive-summary",
    "spatial resolution stays 8 x 8; later scans add frequency detail",
    {0, -2.16}, "code", "result"
)
local approximationNote = text(
    figure, "jpg-progressive-approximation-note",
    "spectral-selection example: Ah = 0, Al = 0 for all three scans",
    {0, -2.48}, "code", "muted"
)

scene:fade_in(claim, {shift = {0, 0.08}, duration = 0.44, curve = "gentle"})
scene:fade_in(labels[1], {shift = {0, 0.05}, duration = 0.24, curve = "gentle"})
scene:create(previews[1], 0.70, "linear")
scene:create({parameters[1], errors[1]}, 0.28, "ease_out", 0.04)
scene:create(arrows[1], 0.34, "ease_out")
scene:fade_in(labels[2], {shift = {0, 0.05}, duration = 0.24, curve = "gentle"})
scene:create(previews[2], 0.70, "linear")
scene:create({parameters[2], errors[2]}, 0.28, "ease_out", 0.04)
scene:create(arrows[2], 0.34, "ease_out")
scene:fade_in(labels[3], {shift = {0, 0.05}, duration = 0.24, curve = "gentle"})
scene:create(previews[3], 0.70, "linear")
scene:create({parameters[3], errors[3]}, 0.28, "ease_out", 0.04)
scene:fade_in(summary, {shift = {0, -0.05}, duration = 0.34, curve = "gentle"})
scene:fade_in(approximationNote, {shift = {0, -0.04}, duration = 0.28, curve = "gentle"})
scene:wait(2.0)
return scene
