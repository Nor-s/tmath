-- Advanced reference: apply one 3 × 3 mean kernel and expose the sampled output.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.4},
}

local inputSize, kernelSize = 7, 3
local outputSize = inputSize - kernelSize + 1
local selectedCenter = {3, 3}
local function clampByte(value) return math.max(0, math.min(255, math.floor(value + 0.5))) end
local function inputValue(x, y)
    local edge = x >= 3 and 82 or 0
    local spot = ((x - 4)^2 + (y - 2)^2 <= 2) and 88 or 0
    return clampByte(28 + 12 * x + 7 * y + edge + spot)
end
local function convolve(centerX, centerY)
    local sum = 0
    for y = centerY - 1, centerY + 1 do
        for x = centerX - 1, centerX + 1 do sum = sum + inputValue(x, y) end
    end
    return sum / (kernelSize * kernelSize), sum
end
local function gray(value)
    local byte = clampByte(value)
    return string.format("#%02x%02x%02x", byte, byte, byte)
end
local function matrix(scale, center, extent)
    return {scale, 0, 0, center[1] - 0.5 * (extent - 1) * scale,
            0, scale, 0, center[2] - 0.5 * (extent - 1) * scale,
            0, 0, 1, 0, 0, 0, 0, 1}
end
local function imagePatches(size, sampler)
    local result = {}
    for y = 0, size - 1 do
        for x = 0, size - 1 do result[#result + 1] = {region = {x, y, 1, 1}, color = gray(sampler(x, y))} end
    end
    return result
end
local function imageSpace(id, size, transform, sampler)
    local space = scene:space {id = id .. "-space", x = {0, size - 1, 1}, y = {0, size - 1, 1}, opacity = 0, matrix = transform}
    local cells = space:cell {
        id = id, origin = {-0.5, -0.5}, size = {size, size}, mode = "padd", padding = 0.045,
        color = "surface", patches = imagePatches(size, sampler),
    }
    return space, cells
end

-- Both images come from the same sampler; output coordinates address valid kernel centers.
local inputSpace, input = imageSpace("kernel-input", inputSize, matrix(0.5, {-3.2, 0}, inputSize), inputValue)
local outputSpace, output = imageSpace("kernel-output", outputSize, matrix(0.62, {3.35, 0}, outputSize), function(x, y)
    return convolve(x + 1, y + 1)
end)
local window = inputSpace:rectangle {
    id = "kernel-window", center = {1, 1}, size = {2.94, 2.94},
    fill = "#4fc1ff18", stroke = "focus", width = 4, layer = 30,
}
local outputCoordinate = {selectedCenter[1] - 1, selectedCenter[2] - 1}
local outputFocus = outputSpace:rectangle {
    id = "kernel-output-sample", center = outputCoordinate, size = {0.92, 0.92},
    fill = "#00000000", stroke = "result", width = 4, layer = 30,
}

-- A compact weight field identifies the operation without replacing the image evidence.
local weights = scene:space {
    id = "kernel-weights-space", x = {0, 2, 1}, y = {0, 2, 1}, opacity = 0,
    matrix = {0.32, 0, 0, -0.32, 0, 0.32, 0, 0.78, 0, 0, 1, 0, 0, 0, 0, 1},
}
local weightCells = weights:cell {id = "kernel-weights", origin = {-0.5, -0.5}, size = {3, 3}, mode = "padd", padding = 0.055, color = "#4fc1ff28"}
local weightLabel = scene:text {
    id = "kernel-weight-label", text = "each weight = 1/9", point = {0, 0.18},
    role = "code", fill = "foreground", align = {0.5, 0.5}, layer = 40,
}
local selectedValue, selectedSum = convolve(selectedCenter[1], selectedCenter[2])
local labels = {
    scene:text {id = "kernel-input-label", text = "input", point = {-3.2, 2.28}, role = "code", fill = "muted", align = {0.5, 0.5}, layer = 40},
    scene:text {id = "kernel-operation-label", text = "3 × 3 mean", point = {0, 2.28}, role = "code", fill = "muted", align = {0.5, 0.5}, layer = 40},
    scene:text {id = "kernel-output-label", text = "output", point = {3.35, 2.28}, role = "code", fill = "muted", align = {0.5, 0.5}, layer = 40},
    scene:text {id = "kernel-result", text = string.format("%d / %d = %.1f", selectedSum, kernelSize * kernelSize, selectedValue), point = {0, -1.85}, role = "code", fill = gray(selectedValue), align = {0.5, 0.5}, layer = 40},
}

-- Move the real sampling window first, then reveal its computed output coordinate.
scene:create(input, 0.7, "ease_out")
scene:fade_in(labels[1], {shift = {0, 0.08}, duration = 0.25, curve = "gentle"})
scene:create(weightCells, 0.35, "ease_out")
scene:fade_in(weightLabel, {shift = {0, 0.06}, duration = 0.25, curve = "gentle"})
scene:fade_in(labels[2], {shift = {0, 0.08}, duration = 0.25, curve = "gentle"})
scene:create(window, 0.28, "ease_out")
scene:wait(0.3)
scene:shift(window, {selectedCenter[1] - 1, selectedCenter[2] - 1}, 1.15, "ease_in_out")
scene:wait(0.25)
scene:create(output, 0.75, "ease_out")
scene:create(outputFocus, 0.25, "ease_out")
scene:fade_in(labels[3], {shift = {0, 0.08}, duration = 0.3, curve = "gentle"})
scene:fade_in(labels[4], {shift = {0, 0.08}, duration = 0.3, curve = "gentle"})
scene:wait(1.2)
return scene
