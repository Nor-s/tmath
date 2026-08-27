-- local question: How does JPEG turn one sparse quantized block into entropy bits?
-- visible input: one exact 8 x 8 quantized coefficient block
-- subject object or field: zigzag order, AC run/size symbols, and amplitude bits
-- one dominant action: serialize sparse coefficients into Huffman-coded tokens
-- observable output: ZRL and EOB replace long and trailing zero runs
-- coordinate frame and units: matrix cells are natural-order coefficient positions
-- section bounds supplied by the parent: standalone 960 x 540 wrapper
-- final readable pose: zigzag path, derived tokens, and concatenated bitstream

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "3_blue_1_eyes",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local LAYER = {cell = 0, path = 10, arrow = 30, text = 40}
local figure = scene:group {id = "jpg-zigzag-entropy-figure"}

local function text(parent, id, value, point, role, fill, align)
    return parent:text {
        id = id, text = value, point = point, role = role or "code",
        fill = fill or "foreground", align = align or {0.5, 0.5}, layer = LAYER.text,
    }
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

local function magnitudeCategory(value)
    local magnitude, size = math.abs(value), 0
    while magnitude > 0 do
        magnitude, size = magnitude // 2, size + 1
    end
    return size
end

local function amplitudeBits(value, size)
    if size == 0 then return "" end
    local encoded = value >= 0 and value or (1 << size) - 1 + value
    local bits = {}
    for shift = size - 1, 0, -1 do
        bits[#bits + 1] = ((encoded >> shift) & 1) == 1 and "1" or "0"
    end
    return table.concat(bits)
end

local zigzag = zigzagCoordinates(8)
local scan = {}
for index = 1, 64 do scan[index] = 0 end
scan[1], scan[2], scan[3], scan[6], scan[23] = 15, -2, -1, 1, -1

local natural = {}
for index = 1, 64 do natural[index] = 0 end
for index, coordinate in ipairs(zigzag) do
    natural[coordinate[2] * 8 + coordinate[1] + 1] = scan[index]
end

-- Selected codewords from Annex K's typical luminance AC Huffman table.
local huffman = {
    ["02"] = "01",
    ["01"] = "00",
    ["21"] = "11100",
    ["F0"] = "11111111001",
    ["00"] = "1010",
}

local tokens, zeroRun = {}, 0
for index = 2, 64 do
    local value = scan[index]
    if value == 0 then
        zeroRun = zeroRun + 1
    else
        while zeroRun >= 16 do
            tokens[#tokens + 1] = {
                name = "ZRL (F,0)", symbol = "F0", value = nil,
                code = huffman["F0"], amplitude = "",
            }
            zeroRun = zeroRun - 16
        end
        local size = magnitudeCategory(value)
        local symbol = string.format("%X%d", zeroRun, size)
        tokens[#tokens + 1] = {
            name = string.format("(%X,%d)  %+d", zeroRun, size, value),
            symbol = symbol, value = value, code = huffman[symbol],
            amplitude = amplitudeBits(value, size),
        }
        zeroRun = 0
    end
end
if zeroRun > 0 then
    tokens[#tokens + 1] = {
        name = "EOB (0,0)", symbol = "00", value = nil,
        code = huffman["00"], amplitude = "",
    }
end

local bitParts = {}
for _, token in ipairs(tokens) do bitParts[#bitParts + 1] = token.code .. token.amplitude end
local entropyBits = table.concat(bitParts)
local previousDc, currentDc = 12, scan[1]
local dcDifference = currentDc - previousDc

local claim = text(
    figure, "jpg-zigzag-entropy-claim",
    "JPEG zigzag order exposes zero runs for entropy coding",
    {0, 2.55}, "h3"
)

local matrixSpace = figure:space {
    id = "jpg-zigzag-matrix-space", x = {0, 7, 1}, y = {0, 7, 1}, opacity = 0,
    matrix = {0.34, 0, 0, -4.60, 0, 0.34, 0, -0.80, 0, 0, 1, 0, 0, 0, 0, 1},
}
local patches = {}
for row = 0, 7 do
    for column = 0, 7 do
        local value = natural[row * 8 + column + 1]
        local color = "#121922ff"
        if value > 0 then color = "#b45309ff" end
        if value < 0 then color = "#1d4ed8ff" end
        patches[#patches + 1] = {region = {column, row, 1, 1}, color = color}
    end
end
local matrix = matrixSpace:cell {
    id = "jpg-zigzag-coefficients", origin = {-0.5, -0.5}, size = {8, 8},
    mode = "padd", padding = 0.045, color = "surface", patches = patches, layer = LAYER.cell,
}
local valueLabels = {}
for index, coordinate in ipairs(zigzag) do
    if scan[index] ~= 0 then
        valueLabels[#valueLabels + 1] = text(
            matrixSpace, string.format("jpg-zigzag-value-%02d", index - 1), tostring(scan[index]),
            coordinate, "code", "#ffffffff"
        )
    end
end
local path = matrixSpace:plot {
    id = "jpg-zigzag-path", points = zigzag,
    stroke = "focus", width = 2.2, layer = LAYER.path,
}
local matrixLabel = text(
    figure, "jpg-zigzag-matrix-label", "quantized 8 x 8 block", {-3.41, 1.80}, "code", "info"
)

local serializeArrow = figure:arrow {
    id = "jpg-zigzag-serialize-arrow", from = {-1.95, 0.18}, to = {-1.18, 0.18},
    stroke = "focus", width = 2, tip = 10, layer = LAYER.arrow,
}
local serializeLabel = text(
    figure, "jpg-zigzag-serialize-label", "zigzag + RLE", {-1.57, 0.57}, "code", "focus"
)

local tokenGroup = figure:group {id = "jpg-zigzag-token-group"}
local tokenXs, tokenYs = {-0.15, 1.78, 3.71}, {1.05, -0.06}
for index, token in ipairs(tokens) do
    local column, row = (index - 1) % 3 + 1, (index - 1) // 3 + 1
    local center = {tokenXs[column], tokenYs[row]}
    local group = tokenGroup:group {id = string.format("jpg-entropy-token-%02d", index)}
    group:rectangle {
        id = string.format("jpg-entropy-token-%02d-body", index),
        center = center, size = {1.68, 0.86}, fill = "surface",
        stroke = token.symbol == "00" and "result" or "border", width = 1.6, layer = LAYER.cell,
    }
    text(
        group, string.format("jpg-entropy-token-%02d-name", index), token.name,
        {center[1], center[2] + 0.18}, "code", token.symbol == "00" and "result" or "foreground"
    )
    local detail = token.amplitude == "" and token.code or token.code .. " | " .. token.amplitude
    text(
        group, string.format("jpg-entropy-token-%02d-bits", index), detail,
        {center[1], center[2] - 0.20}, "code", "muted"
    )
end
local tokenLabel = text(
    figure, "jpg-entropy-token-label", "Huffman code  |  amplitude bits", {1.78, 1.80}, "code", "muted"
)

local scanPreview = text(
    figure, "jpg-zigzag-scan-preview",
    string.format("scan: %d  %d  %d  %d  %d  %+d  ...", scan[1], scan[2], scan[3], scan[4], scan[5], scan[6]),
    {-3.48, -1.48}, "code", "muted"
)
local bitstreamLabel = text(
    figure, "jpg-entropy-bitstream-label",
    string.format("AC entropy payload · %d bits", #entropyBits),
    {1.55, -1.34}, "code", "result"
)
local bitstream = text(
    figure, "jpg-entropy-bitstream", entropyBits,
    {1.55, -1.72}, "code", "foreground"
)
local summary = text(
    figure, "jpg-zigzag-summary",
    string.format("DC difference = %d - %d = %+d;  16 zeros -> ZRL;  trailing zeros -> EOB", currentDc, previousDc, dcDifference),
    {0, -2.24}, "code", "foreground"
)

scene:fade_in(claim, {shift = {0, 0.08}, duration = 0.44, curve = "gentle"})
scene:fade_in(matrixLabel, {shift = {0, 0.05}, duration = 0.24, curve = "gentle"})
scene:create(matrix, 0.68, "linear")
scene:create(valueLabels, 0.24, "ease_out", 0.04)
scene:create(path, 1.00, "linear")
scene:fade_in(scanPreview, {shift = {0, -0.04}, duration = 0.28, curve = "gentle"})
scene:create(serializeArrow, 0.34, "ease_out")
scene:fade_in(serializeLabel, {shift = {0, 0.04}, duration = 0.22, curve = "gentle"})
scene:fade_in(tokenLabel, {shift = {0, 0.04}, duration = 0.24, curve = "gentle"})
scene:fade_in(tokenGroup, {shift = {0, 0.07}, duration = 0.74, curve = "ease_out"})
scene:fade_in(bitstreamLabel, {shift = {0, -0.04}, duration = 0.28, curve = "gentle"})
scene:fade_in(bitstream, {shift = {0, -0.04}, duration = 0.30, curve = "gentle"})
scene:fade_in(summary, {shift = {0, -0.05}, duration = 0.34, curve = "gentle"})
scene:wait(2.0)
return scene
