-- local question: How does a hybrid block video decoder reconstruct pixel samples?
-- visible input: one coded unit and one computed 4 x 4 prediction/residual example
-- subject object or field: syntax stages plus prediction + inverse-transformed residual
-- one dominant action: add and clip the two sample blocks into a reconstructed block
-- observable output: reconstructed samples continue through codec filters into reference/display state
-- coordinate frame and units: 8-bit luma samples and signed residual sample values
-- section bounds supplied by the parent: standalone 960 x 540 wrapper
-- final readable pose: complete decoder spine above the literal block reconstruction

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "3_blue_1_eyes",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local LAYER = {route = -10, cell = 0, object = 10, text = 40}
local figure = scene:group {id = "video-decode-pipeline-figure"}

local function text(parent, id, value, point, role, fill, align)
    return parent:text {
        id = id, text = value, point = point, role = role or "code",
        fill = fill or "foreground", align = align or {0.5, 0.5}, layer = LAYER.text,
    }
end

local function clampByte(value)
    return math.max(0, math.min(255, math.floor(value + 0.5)))
end

local function grayscale(value)
    local byte = clampByte(value)
    return string.format("#%02x%02x%02xff", byte, byte, byte)
end

local function residualColor(value)
    local magnitude = math.min(1, math.abs(value) / 12)
    if value < 0 then
        return string.format("#%02x%02x%02xff", clampByte(72 - 24 * magnitude), clampByte(128 + 66 * magnitude), clampByte(220 + 25 * magnitude))
    end
    return string.format("#%02x%02x%02xff", clampByte(228 + 24 * magnitude), clampByte(150 - 54 * magnitude), clampByte(82 - 36 * magnitude))
end

local prediction = {
    52, 55, 58, 61,
    55, 58, 61, 64,
    58, 61, 64, 67,
    61, 64, 67, 70,
}
local residual = {
    -4, 2, 7, -1,
    3, -2, 5, 1,
    8, 4, -6, 2,
    -3, 6, 1, -5,
}
local reconstructed = {}
for index, value in ipairs(prediction) do
    reconstructed[index] = clampByte(value + residual[index])
end

local claim = text(
    figure, "video-decode-claim",
    "Block decoding adds a decoded residual to a prediction",
    {0, 2.62}, "h3"
)
local scope = text(
    figure, "video-decode-scope",
    "hybrid block-codec spine · exact syntax, transforms, and filters vary by codec",
    {0, 2.18}, "code", "muted"
)

local stageNames = {
    "coded AU", "syntax", "inverse Q/T", "predict", "add + clip", "filter / DPB",
}
local stageXs = {-4.38, -2.63, -0.88, 0.88, 2.63, 4.38}
local stages, stageArrows = {}, {}
for index, name in ipairs(stageNames) do
    local group = figure:group {id = string.format("video-decode-stage-%02d", index)}
    group:rectangle {
        id = string.format("video-decode-stage-%02d-body", index),
        center = {stageXs[index], 1.45}, size = {1.45, 0.58},
        fill = "surface", stroke = index == #stageNames and "result" or "border",
        width = 1.5, layer = LAYER.object,
    }
    text(
        group, string.format("video-decode-stage-%02d-label", index), name,
        {stageXs[index], 1.45}, "code", index == #stageNames and "result" or "foreground"
    )
    stages[index] = group
    if index < #stageNames then
        stageArrows[index] = figure:arrow {
            id = string.format("video-decode-stage-arrow-%02d", index),
            from = {stageXs[index] + 0.76, 1.45}, to = {stageXs[index + 1] - 0.76, 1.45},
            stroke = "muted", width = 1.6, tip = 8, layer = LAYER.route,
        }
    end
end

local function makeBlock(id, label, values, center, colorForValue, labelColor)
    local scale = 0.43
    local space = figure:space {
        id = id .. "-space", x = {0, 3, 1}, y = {0, 3, 1}, opacity = 0,
        matrix = {
            scale, 0, 0, center[1] - 1.5 * scale,
            0, scale, 0, center[2] - 1.5 * scale,
            0, 0, 1, 0,
            0, 0, 0, 1,
        },
    }
    local patches = {}
    for row = 0, 3 do
        for column = 0, 3 do
            local index = row * 4 + column + 1
            patches[#patches + 1] = {
                region = {column, row, 1, 1}, color = colorForValue(values[index]),
            }
        end
    end
    local cell = space:cell {
        id = id .. "-cell", origin = {-0.5, -0.5}, size = {4, 4},
        mode = "padd", padding = 0.045, color = "surface", patches = patches,
        layer = LAYER.cell,
    }
    local labels = space:group {id = id .. "-values"}
    for row = 0, 3 do
        for column = 0, 3 do
            local index = row * 4 + column + 1
            text(
                labels, string.format("%s-value-%02d", id, index), tostring(values[index]),
                {column, row}, "code", "#ffffffff"
            )
        end
    end
    local title = text(figure, id .. "-label", label, {center[1], 0.45}, "code", labelColor)
    return {space = space, cell = cell, labels = labels, title = title}
end

local predictionBlock = makeBlock(
    "video-decode-prediction", "prediction", prediction, {-2.88, -0.55}, grayscale, "info"
)
local residualBlock = makeBlock(
    "video-decode-residual", "decoded residual", residual, {0, -0.55}, residualColor, "warning"
)
local reconstructionBlock = makeBlock(
    "video-decode-reconstruction", "reconstruction", reconstructed, {2.88, -0.55}, grayscale, "result"
)

local plus = text(figure, "video-decode-plus", "+", {-1.45, -0.55}, "h2", "foreground")
local equals = text(figure, "video-decode-equals", "= clip8", {1.43, -0.55}, "code", "focus")
local sampleCheckIndex = 7
local selectedColumn = (sampleCheckIndex - 1) % 4
local selectedRow = math.floor((sampleCheckIndex - 1) / 4)
local sampleOutlines = {
    predictionBlock.space:rectangle {
        id = "video-decode-prediction-selected", center = {selectedColumn, selectedRow}, size = {1, 1},
        fill = "#00000000", stroke = "focus", width = 2.6, layer = LAYER.object,
    },
    residualBlock.space:rectangle {
        id = "video-decode-residual-selected", center = {selectedColumn, selectedRow}, size = {1, 1},
        fill = "#00000000", stroke = "focus", width = 2.6, layer = LAYER.object,
    },
    reconstructionBlock.space:rectangle {
        id = "video-decode-reconstruction-selected", center = {selectedColumn, selectedRow}, size = {1, 1},
        fill = "#00000000", stroke = "focus", width = 2.6, layer = LAYER.object,
    },
}
local sampleCheck = text(
    figure, "video-decode-sample-check",
    string.format(
        "sample %d: %d + (%d) = %d",
        sampleCheckIndex - 1,
        prediction[sampleCheckIndex], residual[sampleCheckIndex], reconstructed[sampleCheckIndex]
    ),
    {0, -1.78}, "code", "result"
)
local summary = text(
    figure, "video-decode-summary",
    "filtered reconstruction becomes display output and, when referenced, future prediction state",
    {0, -2.27}, "code", "muted"
)

scene:fade_in(claim, {shift = {0, 0.08}, duration = 0.42, curve = "gentle"})
scene:fade_in(scope, {shift = {0, 0.05}, duration = 0.32, curve = "gentle"})
for index, stage in ipairs(stages) do
    scene:fade_in(stage, {shift = {0, 0.05}, duration = 0.25, curve = "ease_out"})
    if stageArrows[index] then scene:create(stageArrows[index], 0.18, "ease_out") end
end
scene:fade_in(predictionBlock.title, {duration = 0.22, curve = "gentle"})
scene:create(predictionBlock.cell, 0.46, "linear")
scene:fade_in(predictionBlock.labels, {duration = 0.30, curve = "gentle"})
scene:fade_in(plus, {duration = 0.20, curve = "gentle"})
scene:fade_in(residualBlock.title, {duration = 0.22, curve = "gentle"})
scene:create(residualBlock.cell, 0.46, "linear")
scene:fade_in(residualBlock.labels, {duration = 0.30, curve = "gentle"})
scene:fade_in(equals, {duration = 0.22, curve = "gentle"})
scene:fade_in(reconstructionBlock.title, {duration = 0.22, curve = "gentle"})
scene:create(reconstructionBlock.cell, 0.48, "linear")
scene:fade_in(reconstructionBlock.labels, {duration = 0.30, curve = "gentle"})
scene:create(sampleOutlines, 0.30, "ease_out", 0.05)
scene:fade_in(sampleCheck, {shift = {0, -0.04}, duration = 0.32, curve = "gentle"})
scene:fade_in(summary, {shift = {0, -0.04}, duration = 0.32, curve = "gentle"})
scene:wait(2.0)
return scene
