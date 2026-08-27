-- Advanced reference: composite one coordinate from source, mask, and destination buffers.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local columns, rows = 4, 3
local selected = {x = 2, y = 1}
local source = {
    {{239, 92, 82}, {244, 145, 68}, {246, 188, 72}, {224, 90, 132}},
    {{65, 163, 223}, {67, 190, 164}, {123, 97, 221}, {229, 111, 63}},
    {{52, 103, 181}, {43, 139, 136}, {194, 73, 120}, {105, 78, 177}},
}
local destination = {
    {{24, 32, 50}, {32, 44, 66}, {38, 53, 75}, {48, 62, 82}},
    {{35, 46, 63}, {42, 54, 72}, {49, 63, 81}, {56, 70, 88}},
    {{45, 57, 74}, {52, 65, 82}, {60, 73, 90}, {68, 81, 98}},
}
local mask = {
    {0.00, 0.20, 0.55, 0.90},
    {0.10, 0.42, 0.72, 1.00},
    {0.00, 0.30, 0.66, 0.86},
}

local function clampByte(value) return math.max(0, math.min(255, math.floor(value + 0.5))) end
local function color(rgb)
    return string.format("#%02x%02x%02x", clampByte(rgb[1]), clampByte(rgb[2]), clampByte(rgb[3]))
end
local function gray(value)
    local byte = clampByte(255 * value)
    return string.format("#%02x%02x%02x", byte, byte, byte)
end
local function over(src, coverage, dst)
    local result = {}
    for channel = 1, 3 do result[channel] = src[channel] * coverage + dst[channel] * (1 - coverage) end
    return result
end
local function outputAt(x, y) return over(source[y + 1][x + 1], mask[y + 1][x + 1], destination[y + 1][x + 1]) end
local function matrixAt(center)
    local scale = 0.5
    return {scale, 0, 0, center[1] - 1.5 * scale, 0, scale, 0, center[2] - scale, 0, 0, 1, 0, 0, 0, 0, 1}
end
local function mapPoint(matrix, point)
    return {matrix[1] * point[1] + matrix[2] * point[2] + matrix[4],
            matrix[5] * point[1] + matrix[6] * point[2] + matrix[8]}
end
local function patches(sampler)
    local result = {}
    for y = 0, rows - 1 do
        for x = 0, columns - 1 do
            result[#result + 1] = {region = {x, y, 1, 1}, color = sampler(x, y)}
        end
    end
    return result
end
local function buffer(id, center, sampler, labelText)
    local matrix = matrixAt(center)
    local space = scene:space {id = id .. "-space", x = {0, columns - 1, 1}, y = {0, rows - 1, 1}, opacity = 0, matrix = matrix}
    local cells = space:cell {
        id = id .. "-cells", origin = {-0.5, -0.5}, size = {columns, rows}, mode = "padd", padding = 0.055,
        color = "surface", patches = patches(sampler),
    }
    local focus = space:rectangle {
        id = id .. "-selected", center = {selected.x, selected.y}, size = {0.92, 0.92},
        fill = "#00000000", stroke = "focus", width = 3, layer = 20,
    }
    local label = scene:text {
        id = id .. "-label", text = labelText, point = {center[1], center[2] + 1.12},
        role = "code", fill = "muted", align = {0.5, 0.5}, layer = 40,
    }
    return {space = space, cells = cells, focus = focus, label = label, point = mapPoint(matrix, {selected.x, selected.y})}
end

-- Literal colors remain visible in four buffers; only their placement is abstracted.
local src = buffer("composite-source", {-3.7, 1.25}, function(x, y) return color(source[y + 1][x + 1]) end, "source")
local msk = buffer("composite-mask", {0, 1.25}, function(x, y) return gray(mask[y + 1][x + 1]) end, "mask")
local dst = buffer("composite-destination", {3.7, 1.25}, function(x, y) return color(destination[y + 1][x + 1]) end, "destination")
local out = buffer("composite-output", {0, -1.55}, function(x, y) return color(outputAt(x, y)) end, "output")
local selectedMask = mask[selected.y + 1][selected.x + 1]
local equation = scene:text {
    id = "composite-equation", text = string.format("out = src × %.2f + dst × %.2f", selectedMask, 1 - selectedMask),
    point = {0, -2.72}, role = "code", fill = color(outputAt(selected.x, selected.y)), align = {0.5, 0.5}, layer = 40,
}
local handoffs = {
    scene:line {id = "composite-source-path", from = src.point, to = out.point, stroke = color(source[selected.y + 1][selected.x + 1]), width = 2.5, layer = 10},
    scene:line {id = "composite-mask-path", from = msk.point, to = out.point, stroke = "focus", width = 2.5, layer = 10},
    scene:line {id = "composite-destination-path", from = dst.point, to = out.point, stroke = color(destination[selected.y + 1][selected.x + 1]), width = 2.5, layer = 10},
}

-- Establish inputs, trace the selected coordinate, then materialize the computed buffer.
scene:create({src.cells, msk.cells, dst.cells}, 0.6, "ease_out", 0.08)
scene:fade_in(src.label, {shift = {0, 0.08}, duration = 0.28, curve = "gentle"})
scene:fade_in(msk.label, {shift = {0, 0.08}, duration = 0.28, curve = "gentle"})
scene:fade_in(dst.label, {shift = {0, 0.08}, duration = 0.28, curve = "gentle"})
scene:create({src.focus, msk.focus, dst.focus}, 0.3, "ease_out", 0.08)
scene:wait(0.3)
scene:create(handoffs, 0.55, "ease_in_out", 0.08)
scene:create(out.cells, 0.7, "ease_out")
scene:create(out.focus, 0.25, "ease_out")
scene:fade_in(out.label, {shift = {0, 0.08}, duration = 0.35, curve = "gentle"})
scene:fade_in(equation, {shift = {0, 0.08}, duration = 0.35, curve = "gentle"})
scene:wait(1.2)
return scene
