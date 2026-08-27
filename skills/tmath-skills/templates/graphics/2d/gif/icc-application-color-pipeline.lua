-- local question: How can a GIF carry and apply an ICC profile?
-- visible input: one palette RGB8 triplet and a 700-byte Display P3 ICC profile
-- subject object or field: ICCRGBG1/012 application data mapped into CIE xy
-- one dominant action: join profile sub-blocks, then reinterpret the unchanged palette entry
-- observable output: the embedded-P3 and assumed-sRGB chromaticity points differ
-- coordinate frame and units: application data lengths are bytes; chart uses CIE 1931 x,y
-- section bounds supplied by the parent: standalone 960 x 540 wrapper
-- final readable pose: palette sample, ICC sub-blocks, RGB-filled gamut guide, and both xy values

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "3_blue_1_eyes",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local LAYER = {gamut = -20, object = 0, line = 10, point = 20, arrow = 30, text = 40}
local figure = scene:group {id = "gif-icc-application-color-figure"}

local function text(parent, id, value, point, role, fill, align)
    return parent:text {
        id = id, text = value, point = point, role = role or "code",
        fill = fill or "foreground", align = align or {0.5, 0.5}, layer = LAYER.text,
    }
end

local function clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

local function linearSample(value)
    local encoded = value / 255
    if encoded <= 0.04045 then return encoded / 12.92 end
    return ((encoded + 0.055) / 1.055) ^ 2.4
end

local function multiply3(matrix, vector)
    return {
        matrix[1] * vector[1] + matrix[2] * vector[2] + matrix[3] * vector[3],
        matrix[4] * vector[1] + matrix[5] * vector[2] + matrix[6] * vector[3],
        matrix[7] * vector[1] + matrix[8] * vector[2] + matrix[9] * vector[3],
    }
end

local function encodeSrgb(value)
    value = clamp(value, 0, 1)
    if value <= 0.0031308 then return 12.92 * value end
    return 1.055 * value ^ (1 / 2.4) - 0.055
end

local function rgbHex(rgb)
    local red = math.floor(encodeSrgb(rgb[1]) * 255 + 0.5)
    local green = math.floor(encodeSrgb(rgb[2]) * 255 + 0.5)
    local blue = math.floor(encodeSrgb(rgb[3]) * 255 + 0.5)
    return string.format("#%02x%02x%02xff", red, green, blue)
end

local function xyYToRgb(x, y, luminance, matrix)
    if y <= 0 or x + y > 1 then return nil end
    return multiply3(matrix, {x * luminance / y, luminance, (1 - x - y) * luminance / y})
end

local function insidePolygon(x, y, polygon)
    local inside, previous = false, #polygon
    for index = 1, #polygon do
        local currentPoint, previousPoint = polygon[index], polygon[previous]
        if ((currentPoint[2] > y) ~= (previousPoint[2] > y))
            and x < (previousPoint[1] - currentPoint[1]) * (y - currentPoint[2])
                / (previousPoint[2] - currentPoint[2]) + currentPoint[1]
        then
            inside = not inside
        end
        previous = index
    end
    return inside
end

local function xyFromRgb(rgb, matrix)
    local linear = {linearSample(rgb[1]), linearSample(rgb[2]), linearSample(rgb[3])}
    local xyz = multiply3(matrix, linear)
    local total = xyz[1] + xyz[2] + xyz[3]
    return {xyz[1] / total, xyz[2] / total}
end

local sampleRgb = {209, 64, 31}
local sampleColor = string.format("#%02x%02x%02xff", sampleRgb[1], sampleRgb[2], sampleRgb[3])
local profileByteCount = 700
local maximumSubBlockBytes = 255
local subBlockSizes, remaining = {}, profileByteCount
while remaining > 0 do
    subBlockSizes[#subBlockSizes + 1] = math.min(maximumSubBlockBytes, remaining)
    remaining = remaining - subBlockSizes[#subBlockSizes]
end

local srgbToXyz = {
    0.4123907993, 0.3575843394, 0.1804807884,
    0.2126390059, 0.7151686788, 0.0721923154,
    0.0193308187, 0.1191947798, 0.9505321522,
}
local p3ToXyz = {
    0.4865709486, 0.2656676932, 0.1982172852,
    0.2289745641, 0.6917385218, 0.0792869141,
    0.0000000000, 0.0451133819, 1.0439443689,
}
local xyzToSrgb = {
    3.2409699419, -1.5373831776, -0.4986107603,
    -0.9692436363, 1.8759675015, 0.0415550574,
    0.0556300797, -0.2039769589, 1.0569715142,
}
local srgbXy = xyFromRgb(sampleRgb, srgbToXyz)
local p3Xy = xyFromRgb(sampleRgb, p3ToXyz)
local srgbPrimaries = {{0.64, 0.33}, {0.30, 0.60}, {0.15, 0.06}}
local p3Primaries = {{0.68, 0.32}, {0.265, 0.69}, {0.15, 0.06}}
-- CIE 1931 2-degree spectrum locus, sampled every 10 nm from 380 to 700 nm.
local spectralXy = {
    {0.17411, 0.00496}, {0.17380, 0.00492}, {0.17334, 0.00480},
    {0.17258, 0.00480}, {0.17141, 0.00510}, {0.16888, 0.00690},
    {0.16441, 0.01086}, {0.15664, 0.01771}, {0.14396, 0.02970},
    {0.12412, 0.05780}, {0.09129, 0.13270}, {0.04539, 0.29498},
    {0.00817, 0.53842}, {0.01387, 0.75019}, {0.07430, 0.83380},
    {0.15472, 0.80586}, {0.22962, 0.75433}, {0.30160, 0.69231},
    {0.37310, 0.62445}, {0.44406, 0.55472}, {0.51249, 0.48659},
    {0.57515, 0.42423}, {0.62704, 0.37249}, {0.66576, 0.33401},
    {0.69151, 0.30834}, {0.70792, 0.29203}, {0.71903, 0.28094},
    {0.72599, 0.27401}, {0.72997, 0.27003}, {0.73199, 0.26801},
    {0.73342, 0.26658}, {0.73439, 0.26561}, {0.73469, 0.26531},
}

local claim = text(
    figure, "gif-icc-application-claim",
    "GIF embeds ICC profiles in ICCRGBG1 / 012 application data",
    {0, 2.55}, "h3"
)

local sampleGroup = figure:group {id = "gif-icc-application-sample"}
sampleGroup:rectangle {
    id = "gif-icc-application-swatch", center = {-3.82, 0.78}, size = {1.14, 1.14},
    fill = sampleColor, stroke = "border", width = 2, layer = LAYER.object,
}
text(sampleGroup, "gif-icc-application-sample-label", "same palette RGB8", {-3.82, 1.50}, "code", "muted")
text(
    sampleGroup, "gif-icc-application-rgb-value",
    string.format("RGB8 = (%d, %d, %d)", sampleRgb[1], sampleRgb[2], sampleRgb[3]),
    {-3.82, 0.02}, "code", "foreground"
)

local applicationGroup = figure:group {id = "gif-icc-application-data"}
local applicationHeader = text(
    applicationGroup, "gif-icc-application-header",
    "21 FF 0B · ICCRGBG1 · 012",
    {-2.58, -0.52}, "code", "focus"
)
local subBlockXs = {-4.15, -2.60, -1.05}
for index, byteCount in ipairs(subBlockSizes) do
    local x = subBlockXs[index]
    local role = index == #subBlockSizes and "result" or "focus"
    applicationGroup:rectangle {
        id = string.format("gif-icc-sub-block-%d-body", index), center = {x, -1.17},
        size = {1.38, 0.84}, fill = "surface", stroke = role,
        width = 1.7, layer = LAYER.object,
    }
    text(
        applicationGroup, string.format("gif-icc-sub-block-%d-title", index),
        string.format("sub-block %d", index), {x, -1.01}, "code", role
    )
    text(
        applicationGroup, string.format("gif-icc-sub-block-%d-size", index),
        string.format("%02X · %d B", byteCount, byteCount), {x, -1.34}, "code", "muted"
    )
end

local chart = figure:space {
    id = "gif-icc-xy-space", x = {0, 0.75, 0.25}, y = {0, 0.85, 0.25}, numbers = false,
    color = "border", axis_x = "muted", axis_y = "muted", width = 1,
    matrix = {4.0, 0, 0, 0.94, 0, 4.0, 0, -1.48, 0, 0, 1, 0, 0, 0, 0, 1},
}
local chartLabel = text(
    figure, "gif-icc-chart-label", "CIE 1931 xy · display RGB proxy",
    {2.46, 2.00}, "code", "muted"
)
text(chart, "gif-icc-axis-x", "x", {0.77, -0.025}, "code", "muted", {0, 0.5})
text(chart, "gif-icc-axis-y", "y", {-0.055, 0.86}, "code", "muted", {0.5, 0})

local gamutColumns, gamutRows = 48, 54
local gamutRaster = chart:space {
    id = "gif-icc-gamut-raster", x = {0, gamutColumns, 1}, y = {0, gamutRows, 1}, opacity = 0,
    matrix = {
        0.75 / gamutColumns, 0, 0, 0,
        0, 0.85 / gamutRows, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    },
}
local gamutPatches = {}
for row = 0, gamutRows - 1 do
    for column = 0, gamutColumns - 1 do
        local x = (column + 0.5) * 0.75 / gamutColumns
        local y = (row + 0.5) * 0.85 / gamutRows
        if insidePolygon(x, y, spectralXy) then
            local rgb = xyYToRgb(x, y, 0.5, xyzToSrgb)
            if rgb then
                local maximum = math.max(rgb[1], rgb[2], rgb[3])
                if maximum > 1 then rgb = {rgb[1] / maximum, rgb[2] / maximum, rgb[3] / maximum} end
                gamutPatches[#gamutPatches + 1] = {
                    region = {column, row, 1, 1}, color = rgbHex(rgb),
                }
            end
        end
    end
end
local gamutField = gamutRaster:cell {
    id = "gif-icc-gamut-field", origin = {0, 0}, size = {gamutColumns, gamutRows},
    mode = "full", color = "#00000000", patches = gamutPatches, layer = LAYER.gamut,
}
local chromaticityBoundary = chart:polygon {
    id = "gif-icc-chromaticity-boundary", points = spectralXy,
    fill = "#00000000", stroke = "foreground", width = 1.3, layer = LAYER.line,
}
local srgbGamut = chart:polygon {
    id = "gif-icc-srgb-gamut", points = srgbPrimaries,
    fill = "#00000000", stroke = "info", width = 2, layer = LAYER.line,
}
local p3Gamut = chart:polygon {
    id = "gif-icc-p3-gamut", points = p3Primaries,
    fill = "#00000000", stroke = "result", width = 3, layer = LAYER.line,
}
local srgbPoint = chart:point {
    id = "gif-icc-srgb-point", point = srgbXy, fill = "info", radius = 7, layer = LAYER.point,
}
local p3Point = chart:point {
    id = "gif-icc-p3-point", point = p3Xy, fill = "result", radius = 8, layer = LAYER.point,
}
local delta = chart:line {
    id = "gif-icc-chromaticity-delta", from = srgbXy, to = p3Xy,
    stroke = "focus", width = 3, layer = LAYER.line,
}
local srgbLabel = text(
    chart, "gif-icc-srgb-label", "assumed / sRGB",
    {srgbXy[1] - 0.10, srgbXy[2] + 0.08}, "code", "info", {1, 0.5}
)
local p3Label = text(
    chart, "gif-icc-p3-label", "ICC / P3",
    {p3Xy[1] + 0.02, p3Xy[2] - 0.10}, "code", "result", {0, 0.5}
)
local srgbGamutLabel = text(
    chart, "gif-icc-srgb-gamut-label", "sRGB gamut", {0.30, 0.56}, "code", "info"
)
local p3GamutLabel = text(
    chart, "gif-icc-p3-gamut-label", "Display P3", {0.47, 0.72}, "code", "result"
)

local interpretArrow = figure:arrow {
    id = "gif-icc-interpret-arrow", from = {-1.62, 0.52}, to = {0.56, 0.52},
    stroke = "focus", width = 2, tip = 11, layer = LAYER.arrow,
}
local interpretLabel = text(
    figure, "gif-icc-interpret-label", "join sub-blocks -> PCS", {-0.54, 0.82}, "code", "focus"
)
local subBlockSummary = text(
    figure, "gif-icc-sub-block-summary",
    string.format("%d B profile -> %d + %d + %d · terminator 00",
        profileByteCount, subBlockSizes[1], subBlockSizes[2], subBlockSizes[3]),
    {-2.72, -2.16}, "code", "focus"
)
local coordinateSummary = text(
    figure, "gif-icc-coordinate-summary",
    string.format("sRGB (%.3f, %.3f) · P3 (%.3f, %.3f)",
        srgbXy[1], srgbXy[2], p3Xy[1], p3Xy[2]),
    {2.74, -2.16}, "code", "result"
)

scene:fade_in(claim, {shift = {0, 0.08}, duration = 0.44, curve = "gentle"})
scene:fade_in(sampleGroup, {shift = {0, 0.08}, duration = 0.48, curve = "ease_out"})
scene:fade_in(chartLabel, {shift = {0, 0.05}, duration = 0.24, curve = "gentle"})
scene:create(gamutField, 0.72, "linear")
scene:create(chromaticityBoundary, 0.34, "ease_out")
scene:create(srgbGamut, 0.58, "ease_out")
scene:fade_in(srgbGamutLabel, {shift = {0, 0.05}, duration = 0.24, curve = "gentle"})
scene:grow_from_center(srgbPoint, 0.24, "ease_out")
scene:fade_in(srgbLabel, {shift = {0, 0.04}, duration = 0.22, curve = "gentle"})
scene:wait(0.42)
scene:fade_in(applicationGroup, {shift = {0, 0.08}, duration = 0.62, curve = "ease_out"})
scene:create(interpretArrow, 0.42, "ease_out")
scene:fade_in(interpretLabel, {shift = {0, 0.05}, duration = 0.24, curve = "gentle"})
scene:create(p3Gamut, 0.58, "ease_out")
scene:fade_in(p3GamutLabel, {shift = {0, 0.05}, duration = 0.24, curve = "gentle"})
scene:create(delta, 0.32, "linear")
scene:grow_from_center(p3Point, 0.24, "ease_out")
scene:fade_in(p3Label, {shift = {0, -0.04}, duration = 0.22, curve = "gentle"})
scene:fade_in(subBlockSummary, {shift = {0, -0.05}, duration = 0.32, curve = "gentle"})
scene:fade_in(coordinateSummary, {shift = {0, -0.05}, duration = 0.32, curve = "gentle"})
scene:wait(2.0)
return scene
