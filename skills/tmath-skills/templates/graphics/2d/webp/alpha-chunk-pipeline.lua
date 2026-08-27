-- local question: How does an ALPH chunk add transparency to lossy VP8 color data?
-- visible input: one 2 x 2 VP8 color plane and one raw 2 x 2 alpha plane
-- subject object or field: the ALPH header byte plus its scan-ordered samples
-- one dominant action: merge corresponding color and alpha samples into RGBA
-- observable output: the checker-backed output shows all four transparency values
-- coordinate frame and units: pixel centers are integer-local; alpha is an 8-bit byte
-- section bounds supplied by the parent: standalone 960 x 540 wrapper
-- final readable pose: color plane, ALPH bytes, alpha plane, and RGBA output remain visible

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "3_blue_1_eyes",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local LAYER = {checker = -10, object = 0, arrow = 30, text = 40}
local figure = scene:group {id = "webp-alpha-pipeline-figure"}

local function text(parent, id, value, point, role, fill, align)
    return parent:text {
        id = id, text = value, point = point, role = role or "code",
        fill = fill or "foreground", align = align or {0.5, 0.5}, layer = LAYER.text,
    }
end

local function rgbHex(rgb)
    return string.format("#%02x%02x%02xff", rgb[1], rgb[2], rgb[3])
end

local function rgbaHex(rgb, alpha)
    return string.format("#%02x%02x%02x%02x", rgb[1], rgb[2], rgb[3], alpha)
end

local function gray(value)
    return string.format("#%02x%02x%02xff", value, value, value)
end

local function hexBytes(bytes)
    local parts = {}
    for index, value in ipairs(bytes) do parts[index] = string.format("%02X", value) end
    return table.concat(parts, " ")
end

local columns, rows = 2, 2
local colors = {
    {{230, 68, 68}, {34, 197, 94}},
    {{59, 130, 246}, {250, 204, 21}},
}
local alpha = {
    {255, 192},
    {96, 0},
}
local alphaSettings = {reserved = 0, preprocessing = 0, filter = 0, compression = 0}
local alphaHeader =
    (alphaSettings.reserved << 6) |
    (alphaSettings.preprocessing << 4) |
    (alphaSettings.filter << 2) |
    alphaSettings.compression
local alphaPayload = {alphaHeader}
for row = 1, rows do
    for column = 1, columns do alphaPayload[#alphaPayload + 1] = alpha[row][column] end
end

local claim = text(
    figure, "webp-alpha-claim",
    "ALPH supplies a separate transparency plane for a lossy VP8 image",
    {0, 2.55}, "h3"
)

local scale, centerY = 0.78, 0.42
local centers = {-3.75, 0, 3.75}
local function pixelSpace(id, centerX)
    return figure:space {
        id = id, x = {0, columns - 1, 1}, y = {0, rows - 1, 1}, opacity = 0,
        matrix = {
            scale, 0, 0, centerX - 0.5 * scale,
            0, scale, 0, centerY - 0.5 * scale,
            0, 0, 1, 0,
            0, 0, 0, 1,
        },
    }
end

local colorSpace = pixelSpace("webp-alpha-color-space", centers[1])
local colorPatches = {}
for row = 1, rows do
    for column = 1, columns do
        colorPatches[#colorPatches + 1] = {
            region = {column - 1, rows - row, 1, 1}, color = rgbHex(colors[row][column]),
        }
    end
end
local colorPlane = colorSpace:cell {
    id = "webp-alpha-color-plane", origin = {-0.5, -0.5}, size = {columns, rows},
    mode = "padd", padding = 0.06, color = "surface", patches = colorPatches, layer = LAYER.object,
}

local alphaSpace = pixelSpace("webp-alpha-sample-space", centers[2])
local alphaPatches = {}
for row = 1, rows do
    for column = 1, columns do
        alphaPatches[#alphaPatches + 1] = {
            region = {column - 1, rows - row, 1, 1}, color = gray(alpha[row][column]),
        }
    end
end
local alphaPlane = alphaSpace:cell {
    id = "webp-alpha-sample-plane", origin = {-0.5, -0.5}, size = {columns, rows},
    mode = "padd", padding = 0.06, color = "surface", patches = alphaPatches, layer = LAYER.object,
}
local alphaValueGroup = alphaSpace:group {id = "webp-alpha-sample-values"}
for row = 1, rows do
    for column = 1, columns do
        local value = alpha[row][column]
        text(
            alphaValueGroup, string.format("webp-alpha-value-%d-%d", column - 1, row - 1),
            tostring(value), {column - 1, rows - row}, "code",
            value < 128 and "#ffffffff" or "#111827ff"
        )
    end
end

local outputSpace = pixelSpace("webp-alpha-output-space", centers[3])
local checkerPatches, outputPatches = {}, {}
for row = 1, rows do
    for column = 1, columns do
        local x, y = column - 1, rows - row
        checkerPatches[#checkerPatches + 1] = {
            region = {x, y, 1, 1}, color = (x + y) % 2 == 0 and "#d1d5dbff" or "#6b7280ff",
        }
        outputPatches[#outputPatches + 1] = {
            region = {x, y, 1, 1}, color = rgbaHex(colors[row][column], alpha[row][column]),
        }
    end
end
local checker = outputSpace:cell {
    id = "webp-alpha-output-checker", origin = {-0.5, -0.5}, size = {columns, rows},
    mode = "padd", padding = 0.06, color = "surface", patches = checkerPatches, layer = LAYER.checker,
}
local outputPlane = outputSpace:cell {
    id = "webp-alpha-output-plane", origin = {-0.5, -0.5}, size = {columns, rows},
    mode = "padd", padding = 0.06, color = "#00000000", patches = outputPatches, layer = LAYER.object,
}

local labels = {
    text(figure, "webp-alpha-color-label", "VP8 color plane", {centers[1], 1.55}, "code", "info"),
    text(figure, "webp-alpha-plane-label", "ALPH samples", {centers[2], 1.55}, "code", "focus"),
    text(figure, "webp-alpha-output-label", "decoded RGBA", {centers[3], 1.55}, "code", "result"),
}
local colorArrow = figure:arrow {
    id = "webp-alpha-color-arrow", from = {-2.60, centerY}, to = {-1.16, centerY},
    stroke = "focus", width = 2, tip = 10, layer = LAYER.arrow,
}
local mergeArrow = figure:arrow {
    id = "webp-alpha-merge-arrow", from = {1.16, centerY}, to = {2.60, centerY},
    stroke = "result", width = 2, tip = 10, layer = LAYER.arrow,
}
local plus = text(figure, "webp-alpha-plus", "+", {-1.88, centerY + 0.36}, "code", "focus")
local equals = text(figure, "webp-alpha-equals", "=", {1.88, centerY + 0.36}, "code", "result")

local headerGroup = figure:group {id = "webp-alpha-header-fields"}
local headerFields = {
    {name = "Rsv", value = alphaSettings.reserved},
    {name = "P", value = alphaSettings.preprocessing},
    {name = "F", value = alphaSettings.filter},
    {name = "C", value = alphaSettings.compression},
}
local headerStart, headerStep = -1.08, 0.72
for index, field in ipairs(headerFields) do
    local x = headerStart + (index - 1) * headerStep
    headerGroup:rectangle {
        id = "webp-alpha-header-" .. field.name, center = {x, -0.98}, size = {0.60, 0.60},
        fill = "surface", stroke = "focus", width = 1.5, layer = LAYER.object,
    }
    text(
        headerGroup, "webp-alpha-header-" .. field.name .. "-value",
        string.format("%s%d", field.name, field.value), {x, -0.98}, "code", "focus"
    )
end
local headerLabel = text(
    figure, "webp-alpha-header-label",
    string.format("header byte = 0x%02X  (raw, unfiltered alpha)", alphaHeader),
    {0, -1.46}, "code", "focus"
)
local payloadLabel = text(
    figure, "webp-alpha-payload-label",
    string.format("ALPH payload = %s", hexBytes(alphaPayload)),
    {0, -1.94}, "code", "foreground"
)
local resultLabel = text(
    figure, "webp-alpha-result-label",
    "ALPH accompanies VP8 color; VP8L already carries alpha internally",
    {0, -2.44}, "code", "result"
)

scene:fade_in(claim, {shift = {0, 0.08}, duration = 0.44, curve = "gentle"})
scene:fade_in(labels[1], {shift = {0, 0.05}, duration = 0.24, curve = "gentle"})
scene:create(colorPlane, 0.55, "ease_out")
scene:create(colorArrow, 0.34, "ease_out")
scene:fade_in(plus, {duration = 0.20, curve = "gentle"})
scene:fade_in(labels[2], {shift = {0, 0.05}, duration = 0.24, curve = "gentle"})
scene:fade_in(alphaPlane, {shift = {0, 0.08}, duration = 0.52, curve = "ease_out"})
scene:fade_in(alphaValueGroup, {duration = 0.24, curve = "gentle"})
scene:fade_in(headerGroup, {shift = {0, 0.06}, duration = 0.46, curve = "ease_out"})
scene:fade_in(headerLabel, {shift = {0, -0.04}, duration = 0.26, curve = "gentle"})
scene:fade_in(payloadLabel, {shift = {0, -0.04}, duration = 0.28, curve = "gentle"})
scene:create(mergeArrow, 0.34, "ease_out")
scene:fade_in(equals, {duration = 0.20, curve = "gentle"})
scene:fade_in(labels[3], {shift = {0, 0.05}, duration = 0.24, curve = "gentle"})
scene:fade_in(checker, {duration = 0.26, curve = "gentle"})
scene:fade_in(outputPlane, {shift = {-0.10, 0}, duration = 0.55, curve = "ease_out"})
scene:fade_in(resultLabel, {shift = {0, -0.05}, duration = 0.30, curve = "gentle"})
scene:wait(1.9)
return scene
