-- Advanced reference: compare straight and premultiplied storage over one background.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local source, background, alpha = {240, 80, 40}, {32, 45, 64}, 0.35
local function byte(value) return math.max(0, math.min(255, math.floor(value + 0.5))) end
local function rgbColor(rgb) return string.format("#%02x%02x%02x", byte(rgb[1]), byte(rgb[2]), byte(rgb[3])) end
local function scale(rgb, factor) return {rgb[1] * factor, rgb[2] * factor, rgb[3] * factor} end
local function add(a, b) return {a[1] + b[1], a[2] + b[2], a[3] + b[3]} end
local premultiplied = scale(source, alpha)
local composited = add(premultiplied, scale(background, 1 - alpha))
local straightBytes = {source[1], source[2], source[3], 255 * alpha}
local premultBytes = {premultiplied[1], premultiplied[2], premultiplied[3], 255 * alpha}
local function channelColor(index, value)
    if index == 1 then return rgbColor({value, 0, 0}) end
    if index == 2 then return rgbColor({0, value, 0}) end
    if index == 3 then return rgbColor({0, 0, value}) end
    return rgbColor({value, value, value})
end
local function pixelRow(id, center, values, labelText)
    local scale = 0.52
    local space = scene:space {
        id = id .. "-space", x = {0, 3, 1}, y = {0, 0, 1}, opacity = 0,
        matrix = {scale, 0, 0, center[1] - 1.5 * scale, 0, scale, 0, center[2], 0, 0, 1, 0, 0, 0, 0, 1},
    }
    local patches, texts = {}, {}
    for index = 1, 4 do
        patches[index] = {region = {index - 1, 0, 1, 1}, color = channelColor(index, values[index])}
        texts[index] = space:text {
            id = id .. "-value-" .. index, text = tostring(byte(values[index])), point = {index - 1, 0},
            role = "code", fill = "#ffffffff", align = {0.5, 0.5}, layer = 40,
        }
    end
    local cells = space:cell {id = id .. "-cells", origin = {-0.5, -0.5}, size = {4, 1}, mode = "padd", padding = 0.055, patches = patches}
    local label = scene:text {id = id .. "-label", text = labelText, point = {center[1], center[2] + 0.72}, role = "code", fill = "muted", align = {0.5, 0.5}, layer = 40}
    return {cells = cells, texts = texts, label = label, center = center}
end

-- The stored RGB bytes differ; alpha and the final over operation remain identical.
local straight = pixelRow("alpha-straight", {-1.3, 1.25}, straightBytes, "straight RGBA")
local premult = pixelRow("alpha-premult", {-1.3, -1.25}, premultBytes, "premultiplied RGBA")
local sourceColor, backgroundColor, outputColor = rgbColor(source), rgbColor(background), rgbColor(composited)
local sourceSwatch = scene:rectangle {id = "alpha-source-swatch", center = {-4.2, 0}, size = {1.35, 1.35}, fill = sourceColor, stroke = "border", width = 3, layer = 10}
local backgroundSwatch = scene:rectangle {id = "alpha-background-swatch", center = {0.5, 0}, size = {0.62, 0.62}, fill = backgroundColor, stroke = "border", width = 2, layer = 10}
local outputs = {
    scene:rectangle {id = "alpha-straight-output", center = {3.45, 1.25}, size = {1.35, 1.35}, fill = outputColor, stroke = "result", width = 3, layer = 10},
    scene:rectangle {id = "alpha-premult-output", center = {3.45, -1.25}, size = {1.35, 1.35}, fill = outputColor, stroke = "result", width = 3, layer = 10},
}
local sourcePaths = {
    scene:line {id = "alpha-source-to-straight", from = {-3.45, 0.2}, to = {-2.45, 1.25}, stroke = sourceColor, width = 2.5, layer = 20},
    scene:line {id = "alpha-source-to-premult", from = {-3.45, -0.2}, to = {-2.45, -1.25}, stroke = sourceColor, width = 2.5, layer = 20},
}
local outputPaths = {
    scene:arrow {id = "alpha-straight-over", from = {-0.12, 1.25}, to = {2.65, 1.25}, stroke = "foreground", width = 2.5, tip = 11, layer = 30},
    scene:arrow {id = "alpha-premult-over", from = {-0.12, -1.25}, to = {2.65, -1.25}, stroke = "foreground", width = 2.5, tip = 11, layer = 30},
}
local labels = {
    scene:text {id = "alpha-source-label", text = string.format("C, α = %.2f", alpha), point = {-4.2, -1.02}, role = "code", fill = sourceColor, align = {0.5, 0.5}, layer = 40},
    scene:text {id = "alpha-straight-equation", text = "αC + (1 - α)B", point = {1.25, 1.62}, role = "code", fill = "foreground", align = {0.5, 0.5}, layer = 40},
    scene:text {id = "alpha-premult-equation", text = "C′ + (1 - α)B", point = {1.25, -0.88}, role = "code", fill = "foreground", align = {0.5, 0.5}, layer = 40},
    scene:text {id = "alpha-same-output", text = string.format("same output %s", outputColor:upper()), point = {3.45, 0}, role = "code", fill = "result", align = {0.5, 0.5}, layer = 40},
    scene:text {id = "alpha-background-symbol", text = "B", point = {0.5, 0}, role = "code", fill = "#ffffffff", align = {0.5, 0.5}, layer = 40},
    scene:text {id = "alpha-background-label", text = string.format("background B = %s", backgroundColor:upper()), point = {0.5, 0.58}, role = "code", fill = "muted", align = {0.5, 0.5}, layer = 40},
}

-- Branch one literal source pixel into two storage conventions, then composite both.
scene:draw_border_then_fill(sourceSwatch, 0.5, "ease_out")
scene:fade_in(labels[1], {shift = {0, 0.08}, duration = 0.28, curve = "gentle"})
scene:create(sourcePaths, 0.45, "ease_out", 0.06)
scene:create(straight.cells, 0.38, "ease_out")
scene:create(straight.texts, 0.24, "ease_out", 0.04)
scene:fade_in(straight.label, {shift = {0, 0.06}, duration = 0.24, curve = "gentle"})
scene:create(premult.cells, 0.38, "ease_out")
scene:create(premult.texts, 0.24, "ease_out", 0.04)
scene:fade_in(premult.label, {shift = {0, 0.06}, duration = 0.24, curve = "gentle"})
scene:draw_border_then_fill(backgroundSwatch, 0.35, "ease_out")
scene:fade_in(labels[5], {duration = 0.2, curve = "gentle"})
scene:fade_in(labels[6], {shift = {0, 0.06}, duration = 0.26, curve = "gentle"})
scene:create(outputPaths, 0.55, "ease_out", 0.06)
scene:fade_in(labels[2], {shift = {0, 0.06}, duration = 0.26, curve = "gentle"})
scene:fade_in(labels[3], {shift = {0, 0.06}, duration = 0.26, curve = "gentle"})
scene:draw_border_then_fill(outputs, 0.55, "ease_out", 0.06)
scene:fade_in(labels[4], {shift = {0, 0.08}, duration = 0.32, curve = "gentle"})
scene:wait(1.35)
return scene
