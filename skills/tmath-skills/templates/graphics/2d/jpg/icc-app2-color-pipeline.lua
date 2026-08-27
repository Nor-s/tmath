-- local question: How does JPEG embed and apply an ICC profile larger than one APP2 segment?
-- visible input: one decoded RGB8 triplet and a 100000-byte Display P3 ICC profile
-- subject object or field: ordered APP2 ICC_PROFILE chunks mapped into CIE xy
-- one dominant action: reassemble the profile, then reinterpret unchanged samples
-- observable output: the APP2/P3 and assumed-sRGB chromaticity points differ
-- coordinate frame and units: APP2 lengths are bytes; chart uses CIE 1931 x,y
-- section bounds supplied by the parent: standalone 960 x 540 wrapper
-- final readable pose: sample, APP2 chunks, RGB-filled gamut guide, and both xy values

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "3_blue_1_eyes",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local LAYER = {gamut = -20, object = 0, line = 10, point = 20, arrow = 30, text = 40}
local figure = scene:group {id = "jpg-icc-app2-color-figure"}

local function text(parent, id, value, point, role, fill, align)
    return parent:text {
        id = id, text = value, point = point, role = role or "code",
        fill = fill or "foreground", align = align or {0.5, 0.5}, layer = LAYER.text,
    }
end

local function clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

local function u16be(value)
    return {(value >> 8) & 0xff, value & 0xff}
end

local function hexBytes(bytes)
    local parts = {}
    for index, value in ipairs(bytes) do parts[index] = string.format("%02X", value) end
    return table.concat(parts, " ")
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
    local r = math.floor(encodeSrgb(rgb[1]) * 255 + 0.5)
    local g = math.floor(encodeSrgb(rgb[2]) * 255 + 0.5)
    local b = math.floor(encodeSrgb(rgb[3]) * 255 + 0.5)
    return string.format("#%02x%02x%02xff", r, g, b)
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
local profileByteCount = 100000
local app2LengthMaximum = 65535
local iccIdentifierBytes = 12
local sequenceBytes = 2
local iccHeaderBytes = iccIdentifierBytes + sequenceBytes
local profileBytesPerChunk = app2LengthMaximum - 2 - iccHeaderBytes
local chunkCount = (profileByteCount + profileBytesPerChunk - 1) // profileBytesPerChunk
local chunkSizes, remaining = {}, profileByteCount
for index = 1, chunkCount do
    chunkSizes[index] = math.min(profileBytesPerChunk, remaining)
    remaining = remaining - chunkSizes[index]
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
    figure, "jpg-icc-app2-claim",
    "JPEG applies ICC profiles reassembled from ordered APP2 chunks",
    {0, 2.55}, "h3"
)

local sampleGroup = figure:group {id = "jpg-icc-app2-sample"}
sampleGroup:rectangle {
    id = "jpg-icc-app2-swatch", center = {-3.78, 0.76}, size = {1.18, 1.18},
    fill = sampleColor, stroke = "border", width = 2, layer = LAYER.object,
}
text(sampleGroup, "jpg-icc-app2-sample-label", "same decoded RGB8", {-3.78, 1.52}, "code", "muted")
text(
    sampleGroup, "jpg-icc-app2-rgb-value",
    string.format("RGB8 = (%d, %d, %d)", sampleRgb[1], sampleRgb[2], sampleRgb[3]),
    {-3.78, 0.00}, "code", "foreground"
)

local function chunkBox(id, center, sequence, profileBytes, stroke)
    local group = figure:group {id = id}
    local segmentLength = 2 + iccHeaderBytes + profileBytes
    group:rectangle {
        id = id .. "-body", center = center, size = {2.55, 0.88},
        fill = "surface", stroke = stroke, width = 1.8, layer = LAYER.object,
    }
    text(
        group, id .. "-title",
        string.format("APP2 %d/%d · %d B", sequence, chunkCount, profileBytes),
        {center[1], center[2] + 0.18}, "code", stroke
    )
    text(
        group, id .. "-detail",
        string.format("FF E2 · length %s", hexBytes(u16be(segmentLength))),
        {center[1], center[2] - 0.20}, "code", "muted"
    )
    return group
end

local chunkGroup = figure:group {id = "jpg-icc-app2-chunks"}
local chunkPrefix = text(
    chunkGroup, "jpg-icc-app2-prefix",
    "payload: ICC_PROFILE\\0 · sequence · count · profile bytes",
    {-2.42, -0.54}, "code", "focus"
)
for _, spec in ipairs {
    {"jpg-icc-app2-chunk-1", {-3.76, -1.28}, 1, "focus"},
    {"jpg-icc-app2-chunk-2", {-1.08, -1.28}, 2, "result"},
} do chunkBox(spec[1], spec[2], spec[3], chunkSizes[spec[3]], spec[4]) end

local chart = figure:space {
    id = "jpg-icc-app2-xy-space", x = {0, 0.75, 0.25}, y = {0, 0.85, 0.25}, numbers = false,
    color = "border", axis_x = "muted", axis_y = "muted", width = 1,
    matrix = {4.0, 0, 0, 0.94, 0, 4.0, 0, -1.48, 0, 0, 1, 0, 0, 0, 0, 1},
}
local chartLabel = text(
    figure, "jpg-icc-app2-chart-label", "CIE 1931 xy · display RGB proxy",
    {2.46, 2.00}, "code", "muted"
)
text(chart, "jpg-icc-app2-axis-x", "x", {0.77, -0.025}, "code", "muted", {0, 0.5})
text(chart, "jpg-icc-app2-axis-y", "y", {-0.055, 0.86}, "code", "muted", {0.5, 0})

local gamutColumns, gamutRows = 48, 54
local gamutRaster = chart:space {
    id = "jpg-icc-app2-gamut-raster", x = {0, gamutColumns, 1}, y = {0, gamutRows, 1},
    opacity = 0,
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
    id = "jpg-icc-app2-gamut-field", origin = {0, 0}, size = {gamutColumns, gamutRows},
    mode = "full", color = "#00000000", patches = gamutPatches, layer = LAYER.gamut,
}
local chromaticityBoundary = chart:polygon {
    id = "jpg-icc-app2-chromaticity-boundary", points = spectralXy,
    fill = "#00000000", stroke = "foreground", width = 1.3, layer = LAYER.line,
}
local gamuts = {}
for _, spec in ipairs {
    {"srgb", "jpg-icc-app2-srgb-gamut", srgbPrimaries, "info", 2},
    {"p3", "jpg-icc-app2-p3-gamut", p3Primaries, "result", 3},
} do gamuts[spec[1]] = chart:polygon {
        id = spec[2], points = spec[3],
        fill = "#00000000", stroke = spec[4], width = spec[5], layer = LAYER.line,
    }
end
local srgbGamut, p3Gamut = gamuts.srgb, gamuts.p3
local srgbPoint = chart:point {
    id = "jpg-icc-app2-srgb-point", point = srgbXy, fill = "info", radius = 7, layer = LAYER.point,
}
local p3Point = chart:point {
    id = "jpg-icc-app2-p3-point", point = p3Xy, fill = "result", radius = 8, layer = LAYER.point,
}
local delta = chart:line {
    id = "jpg-icc-app2-chromaticity-delta", from = srgbXy, to = p3Xy,
    stroke = "focus", width = 3, layer = LAYER.line,
}
local labels = {}
for _, spec in ipairs {
    {"srgb", "jpg-icc-app2-srgb-label", "assumed / sRGB", {srgbXy[1] - 0.10, srgbXy[2] + 0.08}, "info", {1, 0.5}},
    {"p3", "jpg-icc-app2-p3-label", "APP2 / P3", {p3Xy[1] + 0.02, p3Xy[2] - 0.10}, "result", {0, 0.5}},
    {"srgbGamut", "jpg-icc-app2-srgb-gamut-label", "sRGB gamut", {0.30, 0.56}, "info"},
    {"p3Gamut", "jpg-icc-app2-p3-gamut-label", "Display P3", {0.47, 0.72}, "result"},
} do labels[spec[1]] = text(chart, spec[2], spec[3], spec[4], "code", spec[5], spec[6]) end
local srgbLabel, p3Label = labels.srgb, labels.p3
local srgbGamutLabel, p3GamutLabel = labels.srgbGamut, labels.p3Gamut

local interpretArrow = figure:arrow {
    id = "jpg-icc-app2-interpret-arrow", from = {-1.60, 0.54}, to = {0.56, 0.54},
    stroke = "focus", width = 2, tip = 11, layer = LAYER.arrow,
}
local interpretLabel = text(
    figure, "jpg-icc-app2-interpret-label", "reassemble -> PCS", {-0.52, 0.83}, "code", "focus"
)
local chunkSummary = text(
    figure, "jpg-icc-app2-chunk-summary",
    string.format("%d ICC bytes -> %d APP2 chunks", profileByteCount, chunkCount),
    {-2.58, -2.18}, "code", "focus"
)
local coordinateSummary = text(
    figure, "jpg-icc-app2-coordinate-summary",
    string.format(
        "sRGB xy=(%.3f, %.3f)   P3 xy=(%.3f, %.3f)",
        srgbXy[1], srgbXy[2], p3Xy[1], p3Xy[2]
    ),
    {2.38, -2.18}, "code", "result"
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
scene:fade_in(chunkGroup, {shift = {0, 0.08}, duration = 0.62, curve = "ease_out"})
scene:create(interpretArrow, 0.42, "ease_out")
scene:fade_in(interpretLabel, {shift = {0, 0.05}, duration = 0.24, curve = "gentle"})
scene:create(p3Gamut, 0.58, "ease_out")
scene:fade_in(p3GamutLabel, {shift = {0, 0.05}, duration = 0.24, curve = "gentle"})
scene:create(delta, 0.32, "linear")
scene:grow_from_center(p3Point, 0.24, "ease_out")
scene:fade_in(p3Label, {shift = {0, -0.04}, duration = 0.22, curve = "gentle"})
scene:fade_in(chunkSummary, {shift = {0, -0.05}, duration = 0.32, curve = "gentle"})
scene:fade_in(coordinateSummary, {shift = {0, -0.05}, duration = 0.32, curve = "gentle"})
scene:wait(2.0)
return scene
