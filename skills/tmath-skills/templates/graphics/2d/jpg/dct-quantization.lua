-- local question: How does baseline JPEG turn one luma block into sparse coefficients?
-- visible input: one computed 8 x 8 luma block
-- subject object or field: level-shifted DCT coefficients and their quantized values
-- one dominant action: divide each DCT coefficient by its quantization-table entry and round
-- observable output: the quantized block contains fewer non-zero coefficients
-- coordinate frame and units: rows and columns index spatial samples or DCT frequencies
-- section bounds supplied by the parent: standalone 960 x 540 wrapper
-- final readable pose: source, DCT, quantized fields, and one checked coefficient

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "3_blue_1_eyes",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local LAYER = {cell = 0, arrow = 30, text = 40}
local figure = scene:group {id = "jpg-dct-quantization-figure"}

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

local function hex(r, g, b)
    return string.format("#%02x%02x%02xff", clampByte(r), clampByte(g), clampByte(b))
end

local blockSize = 8
local spatial = {}
for row = 0, blockSize - 1 do
    for column = 0, blockSize - 1 do
        local edge = column >= 4 and row >= 2 and row <= 5 and 24 or 0
        spatial[#spatial + 1] = clampByte(72 + 10 * row + 5 * column + edge)
    end
end

local function alpha(index)
    return index == 0 and 1 / math.sqrt(2) or 1
end

local coefficients = {}
for v = 0, blockSize - 1 do
    for u = 0, blockSize - 1 do
        local sum = 0
        for y = 0, blockSize - 1 do
            for x = 0, blockSize - 1 do
                local sample = spatial[y * blockSize + x + 1] - 128
                sum = sum
                    + sample
                        * math.cos((2 * x + 1) * u * math.pi / 16)
                        * math.cos((2 * y + 1) * v * math.pi / 16)
            end
        end
        coefficients[#coefficients + 1] = 0.25 * alpha(u) * alpha(v) * sum
    end
end

-- Annex K's typical 8-bit luminance quantization table.
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
local quantized, nonzeroCount = {}, 0
for index, coefficient in ipairs(coefficients) do
    quantized[index] = round(coefficient / luminanceQ[index])
    if quantized[index] ~= 0 then nonzeroCount = nonzeroCount + 1 end
end

local function maximumMagnitude(values)
    local maximum = 0
    for _, value in ipairs(values) do maximum = math.max(maximum, math.abs(value)) end
    return maximum
end

local coefficientMaximum = maximumMagnitude(coefficients)
local quantizedMaximum = maximumMagnitude(quantized)
local function signedColor(value, maximum)
    if math.abs(value) < 0.0001 then return "#111820ff" end
    local amount = math.sqrt(math.min(1, math.abs(value) / math.max(maximum, 1)))
    if value > 0 then return hex(70 + 185 * amount, 55 + 90 * amount, 42) end
    return hex(40, 75 + 80 * amount, 90 + 165 * amount)
end

local function gray(value)
    return hex(value, value, value)
end

local function makeField(id, values, centerX, colorForValue)
    local scale = 0.32
    local space = figure:space {
        id = id .. "-space", x = {0, 7, 1}, y = {0, 7, 1}, opacity = 0,
        matrix = {
            scale, 0, 0, centerX - 3.5 * scale,
            0, scale, 0, 0.18 - 3.5 * scale,
            0, 0, 1, 0,
            0, 0, 0, 1,
        },
    }
    local patches = {}
    for row = 0, 7 do
        for column = 0, 7 do
            local index = row * 8 + column + 1
            patches[#patches + 1] = {
                region = {column, row, 1, 1}, color = colorForValue(values[index]),
            }
        end
    end
    return space:cell {
        id = id, origin = {-0.5, -0.5}, size = {8, 8}, mode = "padd",
        padding = 0.045, color = "surface", patches = patches, layer = LAYER.cell,
    }
end

local claim = text(
    figure, "jpg-dct-quantization-claim",
    "JPEG quantization sparsifies one 8 x 8 DCT block",
    {0, 2.55}, "h3"
)
local centers = {-3.62, 0, 3.62}
local sourceField = makeField("jpg-dct-source", spatial, centers[1], gray)
local coefficientField = makeField(
    "jpg-dct-coefficients", coefficients, centers[2],
    function(value) return signedColor(value, coefficientMaximum) end
)
local quantizedField = makeField(
    "jpg-dct-quantized", quantized, centers[3],
    function(value) return signedColor(value, quantizedMaximum) end
)

local labels = {
    text(figure, "jpg-dct-source-label", "8 x 8 luma samples", {centers[1], 1.73}, "code", "info"),
    text(figure, "jpg-dct-coefficients-label", "DCT after Y - 128", {centers[2], 1.73}, "code", "focus"),
    text(figure, "jpg-dct-quantized-label", "quantized integers", {centers[3], 1.73}, "code", "result"),
}
local dctArrow = figure:arrow {
    id = "jpg-dct-transform-arrow", from = {-2.12, 0.18}, to = {-1.48, 0.18},
    stroke = "focus", width = 2, tip = 10, layer = LAYER.arrow,
}
local quantizeArrow = figure:arrow {
    id = "jpg-quantize-arrow", from = {1.48, 0.18}, to = {2.12, 0.18},
    stroke = "result", width = 2, tip = 10, layer = LAYER.arrow,
}
local dctLabel = text(figure, "jpg-dct-arrow-label", "2D DCT", {-1.80, 0.58}, "code", "focus")
local quantizeLabel = text(figure, "jpg-quantize-arrow-label", "÷ Q, round", {1.80, 0.58}, "code", "result")

local dcIndex = 1
local checkedCoefficient = text(
    figure, "jpg-dct-checked-coefficient",
    string.format(
        "DC: round(F(0,0) / Q(0,0)) = round(%.2f / %d) = %d",
        coefficients[dcIndex], luminanceQ[dcIndex], quantized[dcIndex]
    ),
    {0, -1.48}, "code", "foreground"
)
local sparsity = text(
    figure, "jpg-dct-sparsity",
    string.format("non-zero quantized coefficients: %d / %d", nonzeroCount, blockSize * blockSize),
    {0, -1.93}, "code", "result"
)
local signLegend = text(
    figure, "jpg-dct-sign-legend",
    "blue = negative   orange = positive   dark = zero",
    {0, -2.32}, "code", "muted"
)

scene:fade_in(claim, {shift = {0, 0.08}, duration = 0.44, curve = "gentle"})
scene:fade_in(labels[1], {shift = {0, 0.05}, duration = 0.24, curve = "gentle"})
scene:create(sourceField, 0.72, "linear")
scene:create(dctArrow, 0.34, "ease_out")
scene:fade_in(dctLabel, {shift = {0, 0.04}, duration = 0.22, curve = "gentle"})
scene:fade_in(labels[2], {shift = {0, 0.05}, duration = 0.24, curve = "gentle"})
scene:create(coefficientField, 0.78, "linear")
scene:create(quantizeArrow, 0.34, "ease_out")
scene:fade_in(quantizeLabel, {shift = {0, 0.04}, duration = 0.22, curve = "gentle"})
scene:fade_in(labels[3], {shift = {0, 0.05}, duration = 0.24, curve = "gentle"})
scene:create(quantizedField, 0.78, "linear")
scene:fade_in(checkedCoefficient, {shift = {0, -0.05}, duration = 0.34, curve = "gentle"})
scene:fade_in(sparsity, {shift = {0, -0.05}, duration = 0.30, curve = "gentle"})
scene:fade_in(signLegend, {shift = {0, -0.04}, duration = 0.26, curve = "gentle"})
scene:wait(2.0)
return scene
