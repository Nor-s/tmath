-- Follow one selected surface pixel into its RGBA bytes and red-channel bits.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 5.8},
}
local function label(parent, text, point, color)
    return parent:text {text = text, point = point, role = "code", fill = color or "muted", align = {0.5, 0.5}, layer = 40}
end
local palette = {"#1d4ed8", "#0f766e", "#7c3aed", "#d97706"}
local selectedPixel = {x = 2, y = 1, rgba = {204, 96, 48, 144}}
local channelNames = {"R", "G", "B", "A"}
local function rgbaHex(rgba, prefix, format)
    return string.format((prefix or "#") .. (format or "%02x%02x%02x%02x"), rgba[1], rgba[2], rgba[3], rgba[4])
end
local selectedColor = rgbaHex(selectedPixel.rgba)
local function channelColors(rgba)
    return {
        string.format("#%02x0000", rgba[1]),
        string.format("#00%02x00", rgba[2]),
        string.format("#%02x%02x%02x", rgba[3], rgba[3], rgba[1]),
        string.format("#%02x%02x%02x", rgba[4], rgba[4], rgba[4]),
    }
end
local function byteBits(value)
    local result = {}
    for shift = 7, 0, -1 do result[#result + 1] = math.floor(value / 2^shift) % 2 end
    return result
end
local function pixelColor(x, y)
    x, y = math.floor(x + 0.5), math.floor(y + 0.5)
    return x == selectedPixel.x and y == selectedPixel.y and selectedColor or palette[(x + 2*y) % #palette + 1]
end
local function rectanglePoints(center, size)
    local x, y, w, h = center[1], center[2], size[1] / 2, size[2] / 2
    return {{x - w, y - h}, {x + w, y - h}, {x + w, y + h}, {x - w, y + h}}
end
local function pixelProxy(id, center, size, fill, stroke)
    return scene:polygon {id = id, points = rectanglePoints(center, size), fill = fill, stroke = stroke, width = 2, layer = 30}
end

-- The source Space owns the pixel grid and its local-to-scene placement.
local sourceMatrix = {0.48, 0, 0, -4.45, 0, 0.48, 0, -0.55, 0, 0, 1, 0, 0, 0, 0, 1}
local function mapPoint(matrix, point)
    return {matrix[1] * point[1] + matrix[2] * point[2] + matrix[4],
            matrix[5] * point[1] + matrix[6] * point[2] + matrix[8]}
end
local source = scene:space {
    x = {0, 3, 1}, y = {0, 3, 1}, opacity = 0,
    matrix = sourceMatrix,
}
source:cell(pixelColor, {mode = "padd", padding = 0.06})
label(scene, "selected pixel", {-3.73, 1.55}, "focus")
local selected = source:rectangle {center = {selectedPixel.x, selectedPixel.y}, size = {0.96, 0.96}, fill = "#00000000", stroke = "focus", width = 4, layer = 30}

-- The wedge frames the magnification path; a copied pixel supplies the motion.
local zoomLabel = label(scene, rgbaHex(selectedPixel.rgba, "0x", "%02X%02X%02X%02X"), {-1.8, -0.9}, "result")
local wedge = {
    scene:line {from = {-3.25, 0.17}, to = {-2.43, 0.58}, stroke = "focus", width = 2, layer = 20},
    scene:line {from = {-3.25, -0.31}, to = {-2.43, -0.68}, stroke = "focus", width = 2, layer = 20},
}
local transfer = scene:arrow {from = {-1.05, -0.05}, to = {-0.15, -0.05}, stroke = "muted", width = 2, tip = 10, layer = 30}

-- Express the pixel as an ordered byte array with channel-matched colors.
local array = scene:group {}
label(array, "RGBA[4]", {1.8, 1.45})
label(array, "[", {0.12, 0.25}, "result")
label(array, "]", {3.48, 0.25}, "result")
local byteMatrix = {0.78, 0, 0, 0.62, 0, 0.78, 0, 0.25, 0, 0, 1, 0, 0, 0, 0, 1}
local bytes = array:space {
    x = {0, 3, 1}, y = {0, 0, 1}, opacity = 0,
    matrix = byteMatrix,
}
local swatches = channelColors(selectedPixel.rgba)
bytes:cell {
    origin = {-0.5, -0.5}, size = {4, 1}, mode = "padd", padding = 0.07,
    patches = {
        {region = {0, 0, 1, 1}, color = swatches[1]}, {region = {1, 0, 1, 1}, color = swatches[2]},
        {region = {2, 0, 1, 1}, color = swatches[3]}, {region = {3, 0, 1, 1}, color = swatches[4]},
    },
}
for i = 0, 3 do
    bytes:text {text = channelNames[i + 1], point = {i, 0.75}, role = "code", align = {0.5, 0.5}, layer = 40}
    bytes:text {text = tostring(selectedPixel.rgba[i + 1]), point = {i, 0}, role = "code", fill = "#ffffffff", align = {0.5, 0.5}, layer = 40}
end

-- Fan eight opaque R copies into the final MSB-first bit row.
local bits = scene:group {}
local bitValues = byteBits(selectedPixel.rgba[1])
local bitStrings = {}
for i, value in ipairs(bitValues) do bitStrings[i] = tostring(value) end
local bitTitle = label(bits, string.format("R = %d", selectedPixel.rgba[1]), {1.8, -1.02}, swatches[1])
local bitDigits = label(bits, table.concat(bitStrings, " "), {1.8, -2.18}, swatches[1])
local function morphRedByteToBits()
    local copies, targets = {}, {}
    local redCenter = mapPoint(byteMatrix, {0, 0})
    for i, value in ipairs(bitValues) do
        copies[i] = pixelProxy("r-bit-copy-" .. i, redCenter, {0.67, 0.67}, swatches[1], swatches[1])
        targets[i] = pixelProxy("r-bit-" .. i, {0.4 * i, -1.72}, {0.32, 0.32}, value == 1 and swatches[1] or "surface", "border")
    end
    scene:morph(copies, targets, 0.9, "ease_in_out", 0.035)
end

-- Choreography follows the same semantic handoff: select, magnify, unpack, inspect.
scene:create(selected, 0.3, "ease_out")
scene:create(wedge, 0.45, "ease_out", 0.06)
scene:wait(0.18)
local pixelCopy = pixelProxy("selected-pixel-copy", mapPoint(sourceMatrix, {selectedPixel.x, selectedPixel.y}), {0.46, 0.46}, selectedColor, "focus")
local zoomPixel = pixelProxy("zoomed-pixel", {-1.8, -0.05}, {1.25, 1.25}, selectedColor, "border")
scene:morph(pixelCopy, zoomPixel, 0.78, "ease_in_out")
scene:fade_in(zoomLabel, {shift = {0, 0.1}, duration = 0.3, curve = "gentle"})
scene:wait(0.4)
scene:create(transfer, 0.3, "ease_out")
scene:fade_in(array, {shift = {-0.12, 0}, duration = 0.5, curve = "gentle"})
scene:wait(0.6)
scene:fade_in(bitTitle, {shift = {0, 0.1}, duration = 0.3, curve = "gentle"})
morphRedByteToBits()
scene:fade_in(bitDigits, {shift = {0, 0.08}, duration = 0.32, curve = "gentle"})
scene:wait(1.2)
return scene
