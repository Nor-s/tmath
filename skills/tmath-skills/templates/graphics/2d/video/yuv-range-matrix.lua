-- local question: Why must YUV video carry both matrix coefficients and numeric range?
-- visible input: one nonlinear RGB triplet encoded as BT.709 limited-range Y'CbCr
-- subject object or field: literal Y', Cb, and Cr code-position gradients plus RGB swatches
-- one dominant action: encode once, then compare correct limited-range and wrong full-range decoding
-- observable output: correct RGB reconstruction and a visibly/numerically different wrong result
-- coordinate frame and units: normalized R'G'B' math and 8-bit code values
-- section bounds supplied by the parent: standalone 960 x 540 wrapper
-- final readable pose: coefficients, nominal ranges, selected codes, and both interpretations

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "3_blue_1_eyes",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local LAYER = {cell = 0, marker = 20, text = 40}
local figure = scene:group {id = "yuv-range-matrix-figure"}

local function text(parent, id, value, point, role, fill, align)
    return parent:text {
        id = id, text = value, point = point, role = role or "code",
        fill = fill or "foreground", align = align or {0.5, 0.5}, layer = LAYER.text,
    }
end

local function clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

local function round(value)
    return math.floor(value + 0.5)
end

local function rgbHex(rgb)
    return string.format(
        "#%02x%02x%02xff",
        round(clamp(rgb[1], 0, 1) * 255),
        round(clamp(rgb[2], 0, 1) * 255),
        round(clamp(rgb[3], 0, 1) * 255)
    )
end

local kr, kb = 0.2126, 0.0722
local kg = 1 - kr - kb
local inputBytes = {209, 64, 31}
local input = {inputBytes[1] / 255, inputBytes[2] / 255, inputBytes[3] / 255}

local function encode709Limited(rgb)
    local y = kr * rgb[1] + kg * rgb[2] + kb * rgb[3]
    local cb = (rgb[3] - y) / (2 * (1 - kb))
    local cr = (rgb[1] - y) / (2 * (1 - kr))
    return {
        round(16 + 219 * y),
        round(128 + 224 * cb),
        round(128 + 224 * cr),
    }
end

local function componentsToRgb(y, cb, cr)
    local r = y + 2 * (1 - kr) * cr
    local b = y + 2 * (1 - kb) * cb
    local g = (y - kr * r - kb * b) / kg
    return {clamp(r, 0, 1), clamp(g, 0, 1), clamp(b, 0, 1)}
end

local function decode709Limited(codes)
    return componentsToRgb(
        (codes[1] - 16) / 219,
        (codes[2] - 128) / 224,
        (codes[3] - 128) / 224
    )
end

local function decodeAsFullRange(codes)
    return componentsToRgb(
        codes[1] / 255,
        (codes[2] - 128) / 255,
        (codes[3] - 128) / 255
    )
end

local function rgbBytes(rgb)
    return {
        round(clamp(rgb[1], 0, 1) * 255),
        round(clamp(rgb[2], 0, 1) * 255),
        round(clamp(rgb[3], 0, 1) * 255),
    }
end

local codes = encode709Limited(input)
local correctRgb = decode709Limited(codes)
local wrongRgb = decodeAsFullRange(codes)
local correctBytes = rgbBytes(correctRgb)
local wrongBytes = rgbBytes(wrongRgb)

local claim = text(
    figure, "yuv-range-claim",
    "Y'CbCr decoding needs both matrix coefficients and range",
    {0, 2.62}, "h3"
)
local coefficients = text(
    figure, "yuv-range-coefficients",
    string.format("BT.709: Kr %.4f · Kg %.4f · Kb %.4f · 8-bit limited range", kr, kg, kb),
    {0, 2.18}, "code", "muted"
)

local function mix(first, second, amount)
    return {
        first[1] + (second[1] - first[1]) * amount,
        first[2] + (second[2] - first[2]) * amount,
        first[3] + (second[3] - first[3]) * amount,
    }
end

local neutral = {0.52, 0.52, 0.52}
local function gradientColor(kind, amount)
    if kind == "y" then return {amount, amount, amount} end
    local low = kind == "cb" and {0.88, 0.74, 0.18} or {0.12, 0.76, 0.78}
    local high = kind == "cb" and {0.12, 0.38, 0.92} or {0.94, 0.16, 0.12}
    if amount <= 0.5 then return mix(low, neutral, amount * 2) end
    return mix(neutral, high, (amount - 0.5) * 2)
end

local function makeGauge(id, label, kind, code, nominalMin, nominalMax, y)
    local columns, scale = 32, 0.18
    local space = figure:space {
        id = id .. "-space", x = {0, columns - 1, 1}, y = {0, 0, 1}, opacity = 0,
        matrix = {
            scale, 0, 0, -0.15 - (columns - 1) * scale / 2,
            0, 0.42, 0, y,
            0, 0, 1, 0,
            0, 0, 0, 1,
        },
    }
    local patches = {}
    for column = 0, columns - 1 do
        patches[#patches + 1] = {
            region = {column, 0, 1, 1}, color = rgbHex(gradientColor(kind, column / (columns - 1))),
        }
    end
    local cell = space:cell {
        id = id .. "-gradient", origin = {-0.5, -0.5}, size = {columns, 1},
        mode = "padd", padding = 0.018, color = "surface", patches = patches, layer = LAYER.cell,
    }
    local normalized = (code - nominalMin) / (nominalMax - nominalMin)
    local selectedColumn = clamp(round(normalized * (columns - 1)), 0, columns - 1)
    local marker = space:rectangle {
        id = id .. "-marker", center = {selectedColumn, 0}, size = {1, 1},
        fill = "#00000000", stroke = "focus", width = 3, layer = LAYER.marker,
    }
    local name = text(figure, id .. "-label", label, {-4.72, y}, "code", "foreground", {0, 0.5})
    local range = text(
        figure, id .. "-range",
        string.format("%d .. %d", nominalMin, nominalMax), {-3.25, y}, "code", "muted", {1, 0.5}
    )
    local value = text(
        figure, id .. "-value", string.format("code %d", code), {3.72, y}, "code", "focus", {0, 0.5}
    )
    return {cell = cell, marker = marker, labels = {name, range, value}}
end

local gauges = {
    makeGauge("yuv-range-y", "Y'", "y", codes[1], 16, 235, 1.34),
    makeGauge("yuv-range-cb", "Cb", "cb", codes[2], 16, 240, 0.70),
    makeGauge("yuv-range-cr", "Cr", "cr", codes[3], 16, 240, 0.06),
}

local swatches = {
    {
        id = "input", x = -3.38, label = "source R'G'B'", color = rgbHex(input), values = inputBytes,
    },
    {
        id = "correct", x = 0, label = "decode: 709 limited", color = rgbHex(correctRgb), values = correctBytes,
    },
    {
        id = "wrong", x = 3.38, label = "wrong: read as full", color = rgbHex(wrongRgb), values = wrongBytes,
    },
}
local swatchGroup = figure:group {id = "yuv-range-swatches"}
for index, item in ipairs(swatches) do
    text(
        swatchGroup, string.format("yuv-range-swatch-%02d-label", index), item.label,
        {item.x, -0.62}, "code", index == 3 and "warning" or "foreground"
    )
    swatchGroup:rectangle {
        id = string.format("yuv-range-swatch-%02d-body", index),
        center = {item.x, -1.10}, size = {1.82, 0.62},
        fill = item.color, stroke = index == 2 and "result" or (index == 3 and "warning" or "border"),
        width = 2.0, layer = LAYER.cell,
    }
    text(
        swatchGroup, string.format("yuv-range-swatch-%02d-value", index),
        string.format("%d  %d  %d", item.values[1], item.values[2], item.values[3]),
        {item.x, -1.10}, "code", "#ffffffff"
    )
end

local equation = text(
    figure, "yuv-range-equation",
    string.format("encoded codes = Y' %d, Cb %d, Cr %d · chroma center = 128", codes[1], codes[2], codes[3]),
    {0, -1.73}, "code", "result"
)
local summary = text(
    figure, "yuv-range-summary",
    "The same three bytes produce different RGB when range metadata is interpreted incorrectly",
    {0, -2.28}, "code", "muted"
)

scene:fade_in(claim, {shift = {0, 0.08}, duration = 0.42, curve = "gentle"})
scene:fade_in(coefficients, {shift = {0, 0.05}, duration = 0.32, curve = "gentle"})
for _, gauge in ipairs(gauges) do
    scene:create(gauge.cell, 0.44, "linear")
    scene:create(gauge.marker, 0.24, "ease_out")
    scene:create(gauge.labels, 0.24, "ease_out", 0.03)
end
scene:fade_in(swatchGroup, {shift = {0, 0.05}, duration = 0.62, curve = "ease_out"})
scene:fade_in(equation, {shift = {0, -0.04}, duration = 0.30, curve = "gentle"})
scene:fade_in(summary, {shift = {0, -0.04}, duration = 0.32, curve = "gentle"})
scene:wait(2.0)
return scene
