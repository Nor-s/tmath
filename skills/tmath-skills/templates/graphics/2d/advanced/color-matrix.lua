-- Advanced reference: multiply one normalized RGB vector by a real 3 × 3 matrix.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local input = {0.18, 0.52, 0.88}
local matrix = {
    0.393, 0.769, 0.189,
    0.349, 0.686, 0.168,
    0.272, 0.534, 0.131,
}
local function clamp(value) return math.max(0, math.min(1, value)) end
local function multiply(m, v)
    return {
        m[1] * v[1] + m[2] * v[2] + m[3] * v[3],
        m[4] * v[1] + m[5] * v[2] + m[6] * v[3],
        m[7] * v[1] + m[8] * v[2] + m[9] * v[3],
    }
end
local output = multiply(matrix, input)
local function byte(value) return math.floor(255 * clamp(value) + 0.5) end
local function color(rgb) return string.format("#%02x%02x%02x", byte(rgb[1]), byte(rgb[2]), byte(rgb[3])) end
local function channelColor(index, value)
    local channels = {0, 0, 0}
    channels[index] = clamp(value)
    return color(channels)
end
local function vectorField(id, centerX, values, labelText)
    local space = scene:space {
        id = id .. "-space", x = {0, 0, 1}, y = {0, 2, 1}, opacity = 0,
        matrix = {0.62, 0, 0, centerX, 0, 0.62, 0, -0.62, 0, 0, 1, 0, 0, 0, 0, 1},
    }
    local patches, texts = {}, {}
    for row = 0, 2 do
        local channel = 3 - row
        patches[#patches + 1] = {region = {0, row, 1, 1}, color = channelColor(channel, values[channel])}
        texts[#texts + 1] = space:text {
            id = string.format("%s-value-%d", id, channel), text = string.format("%.2f", values[channel]), point = {0, row},
            role = "code", fill = "#ffffffff", align = {0.5, 0.5}, layer = 40,
        }
    end
    local cells = space:cell {id = id .. "-cells", origin = {-0.5, -0.5}, size = {1, 3}, mode = "padd", padding = 0.06, patches = patches}
    local label = scene:text {id = id .. "-label", text = labelText, point = {centerX, 1.5}, role = "code", fill = "muted", align = {0.5, 0.5}, layer = 40}
    return {cells = cells, texts = texts, label = label}
end

-- The matrix grid and every displayed number share the same row-major coefficients.
local inputVector = vectorField("color-input", -2.75, input, "RGB")
local outputVector = vectorField("color-output", 2.75, output, "RGB′")
local matrixSpace = scene:space {
    id = "color-matrix-space", x = {0, 2, 1}, y = {0, 2, 1}, opacity = 0,
    matrix = {0.66, 0, 0, -0.66, 0, 0.62, 0, -0.62, 0, 0, 1, 0, 0, 0, 0, 1},
}
local matrixCells = matrixSpace:cell {id = "color-matrix-cells", origin = {-0.5, -0.5}, size = {3, 3}, mode = "padd", padding = 0.055, color = "surface"}
local matrixTexts = {}
for row = 0, 2 do
    for column = 0, 2 do
        local value = matrix[row * 3 + column + 1]
        matrixTexts[#matrixTexts + 1] = matrixSpace:text {
            id = string.format("color-matrix-%d-%d", row, column), text = string.format("%.3f", value), point = {column, 2 - row},
            role = "code", fill = "foreground", align = {0.5, 0.5}, layer = 40,
        }
    end
end
local inputColor, outputColor = color(input), color(output)
local swatches = {
    scene:rectangle {id = "color-input-swatch", center = {-4.45, 0}, size = {1.2, 1.2}, fill = inputColor, stroke = "border", width = 3, layer = 10},
    scene:rectangle {id = "color-output-swatch", center = {4.45, 0}, size = {1.2, 1.2}, fill = outputColor, stroke = "border", width = 3, layer = 10},
}
local operators = {
    scene:text {id = "color-multiply", text = "×", point = {-1.62, 0}, role = "code", fill = "muted", align = {0.5, 0.5}, layer = 40},
    scene:text {id = "color-equals", text = "=", point = {1.62, 0}, role = "code", fill = "muted", align = {0.5, 0.5}, layer = 40},
    scene:text {id = "color-matrix-label", text = "M", point = {0, 1.5}, role = "code", fill = "muted", align = {0.5, 0.5}, layer = 40},
    scene:text {id = "color-input-hex", text = inputColor:upper(), point = {-4.45, -1.0}, role = "code", fill = inputColor, align = {0.5, 0.5}, layer = 40},
    scene:text {id = "color-output-hex", text = outputColor:upper(), point = {4.45, -1.0}, role = "code", fill = outputColor, align = {0.5, 0.5}, layer = 40},
    scene:text {id = "color-normalized-label", text = "normalized RGB", point = {0, -2.28}, role = "code", fill = "muted", align = {0.5, 0.5}, layer = 40},
}

-- Read from the literal input swatch through the coefficient field into the output color.
scene:draw_border_then_fill(swatches[1], 0.5, "ease_out")
scene:create(inputVector.cells, 0.4, "ease_out")
scene:create(inputVector.texts, 0.24, "ease_out", 0.04)
scene:fade_in(inputVector.label, {shift = {0, 0.06}, duration = 0.24, curve = "gentle"})
scene:create(operators[1], 0.2, "ease_out")
scene:create(matrixCells, 0.45, "ease_out")
scene:create(matrixTexts, 0.3, "ease_out", 0.025)
scene:fade_in(operators[3], {shift = {0, 0.06}, duration = 0.24, curve = "gentle"})
scene:create(operators[2], 0.2, "ease_out")
scene:create(outputVector.cells, 0.4, "ease_out")
scene:create(outputVector.texts, 0.24, "ease_out", 0.04)
scene:fade_in(outputVector.label, {shift = {0, 0.06}, duration = 0.24, curve = "gentle"})
scene:draw_border_then_fill(swatches[2], 0.5, "ease_out")
scene:fade_in(operators[4], {shift = {0, 0.06}, duration = 0.24, curve = "gentle"})
scene:fade_in(operators[5], {shift = {0, 0.06}, duration = 0.24, curve = "gentle"})
scene:fade_in(operators[6], {shift = {0, 0.06}, duration = 0.24, curve = "gentle"})
scene:wait(1.25)
return scene
