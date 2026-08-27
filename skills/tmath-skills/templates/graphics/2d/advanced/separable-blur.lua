-- Advanced reference: separable [1 2 1] / 4 blur with clamp borders and a real intermediate.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.4},
}

local size = 5
local weights, weightSum = {1, 2, 1}, 4
local selected = {2, 2}
local function clamp(value, low, high) return math.max(low, math.min(high, value)) end
local function clampByte(value) return clamp(math.floor(value + 0.5), 0, 255) end
local function inputValue(x, y)
    local edge = x >= 3 and 58 or 0
    local impulse = (x == 3 and y == 1) and 72 or 0
    return clampByte(24 + 17*x + 11*y + edge + impulse)
end
local function sampleInput(x, y) return inputValue(clamp(x, 0, size-1), clamp(y, 0, size-1)) end
local function horizontal(x, y)
    return (weights[1]*sampleInput(x-1, y) + weights[2]*sampleInput(x, y) + weights[3]*sampleInput(x+1, y)) / weightSum
end
local function sampleHorizontal(x, y) return horizontal(clamp(x, 0, size-1), clamp(y, 0, size-1)) end
local function vertical(x, y)
    return (weights[1]*sampleHorizontal(x, y-1) + weights[2]*sampleHorizontal(x, y) + weights[3]*sampleHorizontal(x, y+1)) / weightSum
end
local function gray(value)
    local byte = clampByte(value)
    return string.format("#%02x%02x%02x", byte, byte, byte)
end
local function matrix(scale, center)
    return {scale, 0, 0, center[1] - 0.5*(size-1)*scale,
            0, scale, 0, center[2] - 0.5*(size-1)*scale,
            0, 0, 1, 0, 0, 0, 0, 1}
end
local function patches(sampler)
    local result = {}
    for y = 0, size-1 do
        for x = 0, size-1 do
            result[#result+1] = {region = {x, y, 1, 1}, color = gray(sampler(x, y))}
        end
    end
    return result
end
local function buffer(id, center, sampler)
    local space = scene:space {
        id = id .. ":space", x = {0, size-1, 1}, y = {0, size-1, 1}, opacity = 0,
        matrix = matrix(0.43, center),
    }
    local cells = space:cell {
        id = id, origin = {-0.5, -0.5}, size = {size, size}, mode = "padd", padding = 0.045,
        color = "surface", patches = patches(sampler),
    }
    return space, cells
end

local inputSpace, input = buffer("blur:input", {-3.35, 0.15}, inputValue)
local horizontalSpace, intermediate = buffer("blur:horizontal", {0, 0.15}, horizontal)
local outputSpace, output = buffer("blur:output", {3.35, 0.15}, vertical)
local horizontalWindow = inputSpace:rectangle {
    center = {1, 1}, size = {2.94, 0.94}, fill = "#4fc1ff18", stroke = "focus", width = 4,
    layer = 30, id = "blur:horizontal-footprint",
}
local horizontalResult = horizontalSpace:rectangle {
    center = selected, size = {0.92, 0.92}, fill = "#00000000", stroke = "focus", width = 4,
    layer = 30, id = "blur:horizontal-result",
}
local verticalWindow = horizontalSpace:rectangle {
    center = {selected[1], 1}, size = {0.94, 2.94}, fill = "#c586c018", stroke = "secondary", width = 4,
    layer = 31, id = "blur:vertical-footprint",
}
local outputResult = outputSpace:rectangle {
    center = selected, size = {0.92, 0.92}, fill = "#00000000", stroke = "result", width = 4,
    layer = 30, id = "blur:output-result",
}

local hLeft, hCenter, hRight = sampleInput(selected[1]-1, selected[2]), sampleInput(selected[1], selected[2]), sampleInput(selected[1]+1, selected[2])
local vTop, vCenter, vBottom = sampleHorizontal(selected[1], selected[2]-1), sampleHorizontal(selected[1], selected[2]), sampleHorizontal(selected[1], selected[2]+1)
local hValue, finalValue = horizontal(selected[1], selected[2]), vertical(selected[1], selected[2])
assert(math.abs(hValue - (hLeft + 2*hCenter + hRight)/4) < 1e-9)
assert(math.abs(finalValue - (vTop + 2*vCenter + vBottom)/4) < 1e-9)

local title = scene:text {text = "Separable blur = horizontal pass → vertical pass", point = {0, 2.82}, role = "h2", fill = "foreground", id = "blur:title"}
local contract = scene:text {text = "kernel [1 2 1] / 4 · same-size output · clamp border · scalar linear samples", point = {0, 2.43}, role = "code", fill = "muted", id = "blur:contract"}
local labels = {
    scene:text {text = "INPUT I", point = {-3.35, 1.72}, role = "code", fill = "foreground", id = "blur:input-label"},
    scene:text {text = "HORIZONTAL H", point = {0, 1.72}, role = "code", fill = "focus", id = "blur:horizontal-label"},
    scene:text {text = "OUTPUT O", point = {3.35, 1.72}, role = "code", fill = "result", id = "blur:output-label"},
}
local horizontalFormula = scene:text {
    text = string.format("H(2,2) = (%d + 2×%d + %d) / 4 = %.1f", hLeft, hCenter, hRight, hValue),
    point = {0, -1.78}, role = "code", fill = "focus", id = "blur:horizontal-formula",
}
local verticalFormula = scene:text {
    text = string.format("O(2,2) = (%.1f + 2×%.1f + %.1f) / 4 = %.1f", vTop, vCenter, vBottom, finalValue),
    point = {0, -2.23}, role = "code", fill = "result", id = "blur:vertical-formula",
}
local invariant = scene:text {
    text = "weights sum to 1 · the vertical pass samples H, not I",
    point = {0, -2.76}, role = "text", fill = "result", id = "blur:invariant",
}

scene:fade_in(title, {shift = {0, -0.08}, duration = 0.40, curve = "gentle"})
scene:fade_in(contract, {duration = 0.28, curve = "gentle"})
scene:create(input, 0.58, "ease_out")
scene:fade_in(labels[1], {duration = 0.24, curve = "gentle"})
scene:create(horizontalWindow, 0.30, "ease_out")
scene:shift(horizontalWindow, {selected[1]-1, selected[2]-1}, 0.80, "ease_in_out")
scene:wait(0.25)
scene:create(intermediate, 0.58, "ease_out")
scene:fade_in(labels[2], {duration = 0.24, curve = "gentle"})
scene:create(horizontalResult, 0.25, "ease_out")
scene:fade_in(horizontalFormula, {duration = 0.32, curve = "gentle"})
scene:wait(0.35)
scene:create(verticalWindow, 0.30, "ease_out")
scene:shift(verticalWindow, {0, selected[2]-1}, 0.80, "ease_in_out")
scene:wait(0.25)
scene:create(output, 0.58, "ease_out")
scene:fade_in(labels[3], {duration = 0.24, curve = "gentle"})
scene:create(outputResult, 0.25, "ease_out")
scene:fade_in(verticalFormula, {duration = 0.32, curve = "gentle"})
scene:fade_in(invariant, {duration = 0.34, curve = "gentle"})
scene:wait(1.6)
return scene
