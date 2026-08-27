-- Advanced reference: isolate HDR highlights, downsample, blur, upsample, and
-- add the bloom contribution back to the original image as distinct resources.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.4},
}

local width, height, threshold = 7, 5, 1.0
local halfWidth, halfHeight = 4, 3
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
local function input(x, y)
    local dx, dy = x - 3, y - 2
    local glow = 4.6*math.exp(-(dx*dx + 1.4*dy*dy)/1.15)
    local secondary = (x == 5 and y == 1) and 1.9 or 0
    return 0.10 + 0.045*x + 0.025*y + glow + secondary
end
local function bright(x, y) return math.max(input(x, y) - threshold, 0) end
local function downsample(x, y)
    local sum = 0
    for oy = 0, 1 do for ox = 0, 1 do
        sum = sum + bright(math.min(width - 1, 2*x + ox), math.min(height - 1, 2*y + oy))
    end end
    return sum/4
end
local weights = {1, 2, 1}
local function horizontal(x, y)
    local sum = 0
    for i = -1, 1 do sum = sum + weights[i + 2]*downsample(clamp(x + i, 0, halfWidth - 1), y) end
    return sum/4
end
local function blurred(x, y)
    local sum = 0
    for i = -1, 1 do sum = sum + weights[i + 2]*horizontal(x, clamp(y + i, 0, halfHeight - 1)) end
    return sum/4
end
local function upsampled(x, y) return blurred(math.floor(x/2), math.floor(y/2)) end
local function composite(x, y) return input(x, y) + 0.72*upsampled(x, y) end
local function byte(v) return math.floor(clamp(v, 0, 255) + 0.5) end
local function display(value, warm)
    local mapped = value/(1 + value)
    if warm then return string.format("#%02x%02x%02x", byte(255*mapped), byte(205*mapped), byte(72*mapped)) end
    return string.format("#%02x%02x%02x", byte(90*mapped), byte(185*mapped), byte(255*mapped))
end

local stages = {
    {name = "HDR input", w = width, h = height, sample = input, warm = false},
    {name = "bright pass", w = width, h = height, sample = bright, warm = true},
    {name = "downsample", w = halfWidth, h = halfHeight, sample = downsample, warm = true},
    {name = "blur", w = halfWidth, h = halfHeight, sample = blurred, warm = true},
    {name = "upsample", w = width, h = height, sample = upsampled, warm = true},
    {name = "add + output", w = width, h = height, sample = composite, warm = false},
}
local centers = {-4.35, -2.62, -0.88, 0.88, 2.62, 4.35}
local scale = 0.205
local buffers, frames, labels = {}, {}, {}
local selected = {x = 3, y = 2}
local function matrix(center, stage)
    return {scale, 0, 0, center - 0.5*(stage.w - 1)*scale,
            0, scale, 0, 0.48 - 0.5*(stage.h - 1)*scale,
            0, 0, 1, 0, 0, 0, 0, 1}
end
for index, stage in ipairs(stages) do
    local patches = {}
    for y = 0, stage.h - 1 do for x = 0, stage.w - 1 do
        patches[#patches + 1] = {region = {x, y, 1, 1}, color = display(stage.sample(x, y), stage.warm)}
    end end
    local space = scene:space {x = {0, stage.w - 1, 1}, y = {0, stage.h - 1, 1}, opacity = 0,
        matrix = matrix(centers[index], stage), id = "bloom:space:" .. index}
    buffers[index] = space:cell {origin = {-0.5, -0.5}, size = {stage.w, stage.h}, mode = "padd", padding = 0.045,
        patches = patches, id = "bloom:stage:" .. index}
    local sx = stage.w == width and selected.x or math.floor(selected.x/2)
    local sy = stage.h == height and selected.y or math.floor(selected.y/2)
    frames[index] = space:rectangle {center = {sx, sy}, size = {0.90, 0.90}, fill = "#00000000",
        stroke = index == 1 and "focus" or (index == #stages and "result" or "warning"), width = 3,
        layer = 30, id = "bloom:sample:" .. index}
    labels[index] = scene:text {text = stage.name, point = {centers[index], 1.38}, role = "code",
        fill = index == #stages and "result" or (index == 1 and "focus" or "warning"), id = "bloom:label:" .. index}
end
local selectedInput = input(selected.x, selected.y)
local selectedBright = bright(selected.x, selected.y)
local selectedBloom = upsampled(selected.x, selected.y)
local selectedOutput = composite(selected.x, selected.y)
assert(selectedInput > threshold and selectedBright == selectedInput - threshold)
local title = scene:text {text = "Bloom moves HDR highlights through a pyramid", point = {0, 2.82},
    role = "h2", fill = "foreground", id = "bloom:title"}
local subtitle = scene:text {text = "threshold → downsample → separable blur → nearest upsample → additive composite", point = {0, 2.43},
    role = "text", fill = "muted", id = "bloom:subtitle"}
local values = scene:text {
    text = string.format("p(3,2): HDR %.2f   bright=max(HDR−%.1f,0)=%.2f   upsampled=%.2f", selectedInput, threshold, selectedBright, selectedBloom),
    point = {0, -1.16}, role = "code", fill = "warning", id = "bloom:values",
}
local formula = scene:text {text = string.format("output = HDR + 0.72×bloom = %.2f  (tone map only for display)", selectedOutput),
    point = {0, -1.78}, role = "code", fill = "result", id = "bloom:formula"}
local invariant = scene:text {text = "a full-frame blur is not bloom: the bright-pass resource is required", point = {0, -2.48},
    role = "h3", fill = "result", id = "bloom:invariant"}

scene:fade_in(title, {shift = {0, -0.08}, duration = 0.40, curve = "gentle"})
scene:fade_in(subtitle, {duration = 0.28, curve = "gentle"})
for i = 1, #stages do
    scene:create(buffers[i], 0.34, "ease_out")
    scene:create(frames[i], 0.16, "ease_out")
    scene:fade_in(labels[i], {duration = 0.16, curve = "gentle"})
end
scene:fade_in(values, {duration = 0.38, curve = "gentle"})
scene:fade_in(formula, {duration = 0.36, curve = "gentle"})
scene:fade_in(invariant, {duration = 0.38, curve = "gentle"})
scene:wait(1.7)
return scene
