-- local question: How does lossy VP8 reconstruct one luma subblock?
-- visible input: a 4 x 4 prediction and an illustrative inverse-DCT residual
-- subject object or field: one 4 x 4 Y subblock reconstructed sample by sample
-- one dominant action: add the reverse-transformed residual to the prediction
-- observable output: the reconstructed Y values are the clamped sums
-- coordinate frame and units: figure-local world units; samples are 8-bit luma values
-- section bounds supplied by the parent: standalone 960 x 540 wrapper
-- final readable pose: prediction, residual, reconstruction, and one checked sum

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "3_blue_1_eyes",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local LAYER = {object = 0, arrow = 30, text = 40}
local figure = scene:group {id = "webp-vp8-lossy-figure"}

local function text(parent, id, value, point, role, fill, align)
    return parent:text {
        id = id, text = value, point = point, role = role or "code",
        fill = fill or "foreground", align = align or {0.5, 0.5}, layer = LAYER.text,
    }
end

local function clampByte(value)
    if value < 0 then return 0 end
    if value > 255 then return 255 end
    return value
end

local function gray(value)
    return string.format("#%02x%02x%02xff", value, value, value)
end

local prediction = {}
for index = 1, 16 do prediction[index] = 100 end
local inverseResidual = {
    -8, -4, 0, 4,
    -4, 0, 4, 8,
    0, 4, 8, 12,
    4, 8, 12, 16,
}
local reconstructed = {}
for index, value in ipairs(prediction) do
    reconstructed[index] = clampByte(value + inverseResidual[index])
end

local claim = text(
    figure, "webp-vp8-lossy-claim",
    "VP8 adds an inverse-DCT residual to its prediction",
    {0, 2.55}, "h3"
)

local gridCenters = {-3.62, 0, 3.62}
local cellStep, cellSize = 0.48, 0.42

local function makeGrid(id, values, centerX, fillForValue, textForValue)
    local group = figure:group {id = id}
    for index, value in ipairs(values) do
        local column = (index - 1) % 4
        local row = (index - 1) // 4
        local x = centerX + (column - 1.5) * cellStep
        local y = 1.02 - row * cellStep
        group:rectangle {
            id = string.format("%s-cell-%02d", id, index - 1),
            center = {x, y}, size = {cellSize, cellSize},
            fill = fillForValue(value), stroke = "border", width = 1.2, layer = LAYER.object,
        }
        text(
            group, string.format("%s-value-%02d", id, index - 1),
            textForValue(value), {x, y}, "code",
            id == "webp-vp8-residual" and (value == 0 and "foreground" or "#ffffffff") or "#ffffffff"
        )
    end
    return group
end

local predictionGrid = makeGrid(
    "webp-vp8-prediction", prediction, gridCenters[1], gray, function(value) return tostring(value) end
)
local residualGrid = makeGrid(
    "webp-vp8-residual", inverseResidual, gridCenters[2],
    function(value)
        if value < 0 then return "#1d4ed8ff" end
        if value > 0 then return "#c2410cff" end
        return "surface"
    end,
    function(value) return value > 0 and string.format("+%d", value) or tostring(value) end
)
local reconstructedGrid = makeGrid(
    "webp-vp8-reconstructed", reconstructed, gridCenters[3], gray, function(value) return tostring(value) end
)

local labels = {
    text(figure, "webp-vp8-prediction-label", "prediction Y", {gridCenters[1], 1.68}, "code", "info"),
    text(figure, "webp-vp8-residual-label", "inverse-DCT residual", {gridCenters[2], 1.68}, "code", "focus"),
    text(figure, "webp-vp8-reconstructed-label", "reconstructed Y", {gridCenters[3], 1.68}, "code", "result"),
}

local plusArrow = figure:arrow {
    id = "webp-vp8-plus-arrow", from = {-2.55, 0.30}, to = {-1.13, 0.30},
    stroke = "focus", width = 2, tip = 10, layer = LAYER.arrow,
}
local resultArrow = figure:arrow {
    id = "webp-vp8-result-arrow", from = {1.13, 0.30}, to = {2.55, 0.30},
    stroke = "result", width = 2, tip = 10, layer = LAYER.arrow,
}
local plusLabel = text(figure, "webp-vp8-plus-label", "+", {-1.84, 0.64}, "code", "focus")
local equalsLabel = text(figure, "webp-vp8-equals-label", "=", {1.84, 0.64}, "code", "result")

local reconstructionRule = text(
    figure, "webp-vp8-reconstruction-rule",
    "recon = clamp(prediction + inverse-DCT residual)",
    {0, -1.10}, "code", "foreground"
)
local checkedSample = text(
    figure, "webp-vp8-checked-sample",
    string.format(
        "top-left sample: %d + (%d) = %d",
        prediction[1], inverseResidual[1], reconstructed[1]
    ),
    {0, -1.66}, "code", "result"
)
local context = text(
    figure, "webp-vp8-context",
    "Illustrative 4 x 4 luma values after coefficient decode, dequantization, and inverse transform",
    {0, -2.28}, "code", "muted"
)

scene:fade_in(claim, {shift = {0, 0.08}, duration = 0.44, curve = "gentle"})
scene:fade_in(labels[1], {shift = {0, 0.05}, duration = 0.24, curve = "gentle"})
scene:fade_in(predictionGrid, {shift = {0, 0.08}, duration = 0.55, curve = "ease_out"})
scene:fade_in(labels[2], {shift = {0, 0.05}, duration = 0.24, curve = "gentle"})
scene:fade_in(residualGrid, {shift = {0, 0.08}, duration = 0.55, curve = "ease_out"})
scene:create(plusArrow, 0.34, "ease_out")
scene:fade_in(plusLabel, {duration = 0.20, curve = "gentle"})
scene:fade_in(reconstructionRule, {shift = {0, -0.05}, duration = 0.30, curve = "gentle"})
scene:create(resultArrow, 0.34, "ease_out")
scene:fade_in(equalsLabel, {duration = 0.20, curve = "gentle"})
scene:fade_in(labels[3], {shift = {0, 0.05}, duration = 0.24, curve = "gentle"})
scene:fade_in(reconstructedGrid, {shift = {-0.10, 0}, duration = 0.62, curve = "ease_out"})
scene:fade_in(checkedSample, {shift = {0, -0.05}, duration = 0.30, curve = "gentle"})
scene:fade_in(context, {shift = {0, -0.05}, duration = 0.30, curve = "gentle"})
scene:wait(1.9)
return scene
