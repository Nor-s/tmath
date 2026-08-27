-- local question: What does the VP8L subtract-green transform store?
-- visible input: one concrete ARGB pixel
-- subject object or field: the pixel's four channel bytes before and after the transform
-- one dominant action: subtract green from red and blue modulo 256, then invert it
-- observable output: decoding restores the exact original ARGB values
-- coordinate frame and units: figure-local world units; channels are unsigned 8-bit bytes
-- section bounds supplied by the parent: standalone 960 x 540 wrapper
-- final readable pose: original, transformed, and reconstructed byte rows remain aligned

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "3_blue_1_eyes",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local LAYER = {object = 0, arrow = 30, text = 40}
local figure = scene:group {id = "webp-vp8l-subtract-green-figure"}

local function text(parent, id, value, point, role, fill, align)
    return parent:text {
        id = id, text = value, point = point, role = role or "code",
        fill = fill or "foreground", align = align or {0.5, 0.5}, layer = LAYER.text,
    }
end

local original = {A = 255, R = 180, G = 120, B = 70}
local transformed = {
    A = original.A,
    R = (original.R - original.G) % 256,
    G = original.G,
    B = (original.B - original.G) % 256,
}
local decoded = {
    A = transformed.A,
    R = (transformed.R + transformed.G) % 256,
    G = transformed.G,
    B = (transformed.B + transformed.G) % 256,
}
local channels = {"A", "R", "G", "B"}
local channelColors = {A = "muted", R = "danger", G = "success", B = "info"}

local claim = text(
    figure, "webp-vp8l-claim",
    "VP8L subtract-green is exactly reversible modulo 256",
    {0, 2.55}, "h3"
)

local xCenters = {-1.20, -0.05, 1.10, 2.25}
local function makeByteRow(id, values, y, label, labelColor)
    local group = figure:group {id = id}
    text(group, id .. "-label", label, {-4.82, y}, "code", labelColor, {0, 0.5})
    for index, channel in ipairs(channels) do
        local x = xCenters[index]
        group:rectangle {
            id = id .. "-" .. channel .. "-cell", center = {x, y}, size = {0.92, 0.70},
            fill = "surface", stroke = channelColors[channel], width = 2, layer = LAYER.object,
        }
        text(
            group, id .. "-" .. channel .. "-value",
            string.format("%s %d", channel, values[channel]), {x, y}, "code", channelColors[channel]
        )
    end
    return group
end

local originalRow = makeByteRow("webp-vp8l-original", original, 1.08, "Original ARGB", "foreground")
local transformedRow = makeByteRow(
    "webp-vp8l-transformed", transformed, 0.00, "Stored transform", "focus"
)
local decodedRow = makeByteRow("webp-vp8l-decoded", decoded, -1.08, "Inverse transform", "result")

local originalColor = string.format("#%02x%02x%02xff", original.R, original.G, original.B)
local originalSwatch = figure:rectangle {
    id = "webp-vp8l-original-swatch", center = {4.55, 1.08}, size = {0.72, 0.72},
    fill = originalColor, stroke = "border", width = 2, layer = LAYER.object,
}
local decodedSwatch = figure:rectangle {
    id = "webp-vp8l-decoded-swatch", center = {4.55, -1.08}, size = {0.72, 0.72},
    fill = string.format("#%02x%02x%02xff", decoded.R, decoded.G, decoded.B),
    stroke = "result", width = 2, layer = LAYER.object,
}

local subtractArrow = figure:arrow {
    id = "webp-vp8l-subtract-arrow", from = {3.25, 0.80}, to = {3.25, 0.28},
    stroke = "focus", width = 2, tip = 10, layer = LAYER.arrow,
}
local inverseArrow = figure:arrow {
    id = "webp-vp8l-inverse-arrow", from = {3.25, -0.28}, to = {3.25, -0.80},
    stroke = "result", width = 2, tip = 10, layer = LAYER.arrow,
}
local subtractLabel = text(
    figure, "webp-vp8l-subtract-label", "subtract G", {3.58, 0.54}, "code", "focus", {0, 0.5}
)
local inverseLabel = text(
    figure, "webp-vp8l-inverse-label", "add G", {3.58, -0.54}, "code", "result", {0, 0.5}
)

local transformFormula = text(
    figure, "webp-vp8l-transform-formula",
    string.format(
        "R'=(%d-%d) mod 256=%d    B'=(%d-%d) mod 256=%d",
        original.R, original.G, transformed.R, original.B, original.G, transformed.B
    ),
    {0, -1.92}, "code", "focus"
)
local restoredFormula = text(
    figure, "webp-vp8l-restored-formula",
    string.format("inverse adds G: ARGB(%d,%d,%d,%d) restored exactly", decoded.A, decoded.R, decoded.G, decoded.B),
    {0, -2.42}, "code", "result"
)

scene:fade_in(claim, {shift = {0, 0.08}, duration = 0.44, curve = "gentle"})
scene:fade_in(originalRow, {shift = {0, 0.08}, duration = 0.55, curve = "ease_out"})
scene:grow_from_center(originalSwatch, 0.28, "ease_out")
scene:create(subtractArrow, 0.32, "ease_out")
scene:fade_in(subtractLabel, {shift = {-0.05, 0}, duration = 0.22, curve = "gentle"})
scene:fade_in(transformedRow, {shift = {0, 0.08}, duration = 0.55, curve = "ease_out"})
scene:fade_in(transformFormula, {shift = {0, -0.05}, duration = 0.32, curve = "gentle"})
scene:create(inverseArrow, 0.32, "ease_out")
scene:fade_in(inverseLabel, {shift = {-0.05, 0}, duration = 0.22, curve = "gentle"})
scene:fade_in(decodedRow, {shift = {0, 0.08}, duration = 0.55, curve = "ease_out"})
scene:grow_from_center(decodedSwatch, 0.28, "ease_out")
scene:fade_in(restoredFormula, {shift = {0, -0.05}, duration = 0.32, curve = "gentle"})
scene:wait(1.9)
return scene
