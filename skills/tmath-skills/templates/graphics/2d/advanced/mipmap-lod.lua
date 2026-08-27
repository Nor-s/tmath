-- Advanced reference: derive a complete mip chain, then select and blend two
-- adjacent levels from one minification footprint.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.4},
}

local function clampByte(v) return math.max(0, math.min(255, math.floor(v + 0.5))) end
local function hex(rgb)
    return string.format("#%02x%02x%02x", clampByte(rgb[1]), clampByte(rgb[2]), clampByte(rgb[3]))
end
local function sourceTexel(x, y)
    local checker = (x + 2*y) % 4 < 2 and 58 or 0
    return {32 + 21*x + checker, 48 + 17*y, 156 + 7*x - 9*y}
end
local function baseLevel()
    local level = {}
    for y = 0, 7 do
        level[y + 1] = {}
        for x = 0, 7 do level[y + 1][x + 1] = sourceTexel(x, y) end
    end
    return level
end
local function downsample(level)
    local sourceSize, result = #level, {}
    local size = math.max(1, math.floor(sourceSize / 2))
    for y = 0, size - 1 do
        result[y + 1] = {}
        for x = 0, size - 1 do
            local sum = {0, 0, 0}
            for oy = 0, 1 do for ox = 0, 1 do
                local sample = level[math.min(sourceSize, 2*y + oy + 1)][math.min(sourceSize, 2*x + ox + 1)]
                for c = 1, 3 do sum[c] = sum[c] + sample[c] end
            end end
            result[y + 1][x + 1] = {sum[1]/4, sum[2]/4, sum[3]/4}
        end
    end
    return result
end

local levels = {baseLevel()}
for i = 2, 4 do levels[i] = downsample(levels[i - 1]) end
assert(#levels[1] == 8 and #levels[2] == 4 and #levels[3] == 2 and #levels[4] == 1)

local footprint = 3.10
local lambda = math.log(footprint) / math.log(2)
local low = math.floor(lambda)
local high = math.min(low + 1, #levels - 1)
local blend = lambda - low
assert(low == 1 and high == 2 and blend > 0 and blend < 1)

local function patches(level)
    local result = {}
    for y = 0, #level - 1 do for x = 0, #level - 1 do
        result[#result + 1] = {region = {x, y, 1, 1}, color = hex(level[y + 1][x + 1])}
    end end
    return result
end
local function matrix(scale, center, size)
    return {scale, 0, 0, center[1] - 0.5*(size - 1)*scale,
            0, scale, 0, center[2] - 0.5*(size - 1)*scale,
            0, 0, 1, 0, 0, 0, 0, 1}
end
local centers = {{-3.35, 0.25}, {-0.55, 0.72}, {1.55, 1.02}, {3.10, 1.16}}
local scale = 0.37
local cells, frames, labels = {}, {}, {}
for index, level in ipairs(levels) do
    local size = #level
    local space = scene:space {x = {0, size - 1, 1}, y = {0, size - 1, 1}, opacity = 0,
        matrix = matrix(scale, centers[index], size), id = "mip:space:" .. index - 1}
    cells[index] = space:cell {origin = {-0.5, -0.5}, size = {size, size}, mode = "padd", padding = 0.045,
        patches = patches(level), id = "mip:level:" .. index - 1}
    frames[index] = space:rectangle {center = {(size - 1)/2, (size - 1)/2}, size = {size, size},
        fill = "#00000000", stroke = (index == low + 1 or index == high + 1) and "focus" or "border",
        width = (index == low + 1 or index == high + 1) and 4 or 2, layer = 20, id = "mip:frame:" .. index - 1}
    labels[index] = scene:text {text = string.format("L%d · %d×%d", index - 1, size, size),
        point = {centers[index][1], centers[index][2] + 0.5*size*scale + 0.32}, role = "code",
        fill = (index == low + 1 or index == high + 1) and "focus" or "foreground", id = "mip:label:" .. index - 1}
end
local sourceFootprint = scene:rectangle {center = {-3.35, 0.25}, size = {footprint*scale, footprint*scale},
    fill = "#ffd86616", stroke = "warning", width = 3, layer = 30, id = "mip:source-footprint"}
local title = scene:text {text = "Mipmap LOD follows the projected texel footprint", point = {0, 2.82},
    role = "h2", fill = "foreground", id = "mip:title"}
local subtitle = scene:text {text = "each level is a 2×2 box-filtered image, not a smaller redraw", point = {0, 2.43},
    role = "text", fill = "muted", id = "mip:subtitle"}
local equation = scene:text {
    text = string.format("ρ = %.2f texels   λ = log₂ρ = %.2f   → blend L%d/L%d with t = %.2f", footprint, lambda, low, high, blend),
    point = {0, -1.92}, role = "code", fill = "warning", id = "mip:equation",
}
local invariant = scene:text {text = "minification chooses scale before within-level filtering", point = {0, -2.54},
    role = "h3", fill = "result", id = "mip:invariant"}

scene:fade_in(title, {shift = {0, -0.08}, duration = 0.40, curve = "gentle"})
scene:fade_in(subtitle, {duration = 0.28, curve = "gentle"})
scene:create(cells[1], 0.62, "ease_out")
scene:create(frames[1], 0.22, "ease_out")
scene:fade_in(labels[1], {duration = 0.22, curve = "gentle"})
for i = 2, #levels do
    scene:create(cells[i], 0.42, "ease_out")
    scene:create(frames[i], 0.18, "ease_out")
    scene:fade_in(labels[i], {duration = 0.18, curve = "gentle"})
end
scene:create(sourceFootprint, 0.35, "ease_out")
scene:fade_in(equation, {duration = 0.38, curve = "gentle"})
scene:indicate(frames[low + 1], {scale = 1.035, duration = 0.28, curve = "gentle"})
scene:indicate(frames[high + 1], {scale = 1.035, duration = 0.28, curve = "gentle"})
scene:fade_in(invariant, {duration = 0.38, curve = "gentle"})
scene:wait(1.6)
return scene
