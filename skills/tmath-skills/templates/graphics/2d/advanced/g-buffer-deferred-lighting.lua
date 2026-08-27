-- Advanced reference: write screen-aligned material attachments first, then
-- reconstruct one deferred-lighting result from the same pixel coordinate.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.4},
}

local size, selected = 4, {x = 2, y = 2}
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
local function byte(v) return math.floor(clamp(v, 0, 255) + 0.5) end
local function hex(rgb) return string.format("#%02x%02x%02x", byte(rgb[1]), byte(rgb[2]), byte(rgb[3])) end
local function normalize(v)
    local length = math.sqrt(v[1]^2 + v[2]^2 + v[3]^2)
    return {v[1]/length, v[2]/length, v[3]/length}
end
local light = normalize({0.45, 0.62, 0.76})
local function surface(x, y)
    local dx, dy = x - 1.5, y - 1.5
    if dx*dx + dy*dy > 4.1 then return nil end
    local nx, ny = 0.22*dx, 0.22*dy
    local normal = normalize({nx, ny, math.sqrt(math.max(0.12, 1 - nx*nx - ny*ny))})
    return {
        albedo = {48 + 46*x, 84 + 30*y, 188 - 18*x},
        normal = normal,
        depth = 0.28 + 0.09*y + 0.025*x,
        roughness = 0.18 + 0.14*x,
    }
end
local function encodeNormal(n) return {(n[1]*0.5 + 0.5)*255, (n[2]*0.5 + 0.5)*255, (n[3]*0.5 + 0.5)*255} end
local function shade(sample)
    if not sample then return {18, 22, 29} end
    local ndotl = math.max(0, sample.normal[1]*light[1] + sample.normal[2]*light[2] + sample.normal[3]*light[3])
    local intensity = 0.12 + (1 - 0.35*sample.roughness)*1.05*ndotl
    return {sample.albedo[1]*intensity, sample.albedo[2]*intensity, sample.albedo[3]*intensity}
end
local sample = surface(selected.x, selected.y)
local ndotl = sample.normal[1]*light[1] + sample.normal[2]*light[2] + sample.normal[3]*light[3]
assert(sample and ndotl > 0)

local samplers = {
    function(x, y) local s = surface(x, y); return s and hex(s.albedo) or "#12161d" end,
    function(x, y) local s = surface(x, y); return s and hex(encodeNormal(s.normal)) or "#12161d" end,
    function(x, y) local s = surface(x, y); local d = s and (1 - s.depth)*255 or 18; return hex({d, d, d}) end,
    function(x, y) local s = surface(x, y); local r = s and s.roughness*255 or 18; return hex({r, r, r}) end,
    function(x, y) return hex(shade(surface(x, y))) end,
}
local names = {"albedo · RGB8", "normal · RGB8", "depth · R32F", "roughness · R8", "lit output"}
local colors = {"accent", "secondary", "warning", "focus", "result"}
local centers = {-4.05, -2.02, 0, 2.02, 4.05}
local scale = 0.33
local buffers, frames, labels = {}, {}, {}
local function matrix(center)
    return {scale, 0, 0, center - 0.5*(size - 1)*scale,
            0, scale, 0, 0.48 - 0.5*(size - 1)*scale,
            0, 0, 1, 0, 0, 0, 0, 1}
end
for index, sampler in ipairs(samplers) do
    local patches = {}
    for y = 0, size - 1 do for x = 0, size - 1 do
        patches[#patches + 1] = {region = {x, y, 1, 1}, color = sampler(x, y)}
    end end
    local space = scene:space {x = {0, size - 1, 1}, y = {0, size - 1, 1}, opacity = 0,
        matrix = matrix(centers[index]), id = "gbuffer:space:" .. index}
    buffers[index] = space:cell {origin = {-0.5, -0.5}, size = {size, size}, mode = "padd", padding = 0.045,
        patches = patches, id = "gbuffer:attachment:" .. index}
    frames[index] = space:rectangle {center = {selected.x, selected.y}, size = {0.92, 0.92},
        fill = "#00000000", stroke = colors[index], width = 4, layer = 30, id = "gbuffer:sample:" .. index}
    labels[index] = scene:text {text = names[index], point = {centers[index], 1.50}, role = "code",
        fill = colors[index], id = "gbuffer:label:" .. index}
end
local title = scene:text {text = "A G-buffer defers lighting, not geometry identity", point = {0, 2.82},
    role = "h2", fill = "foreground", id = "gbuffer:title"}
local subtitle = scene:text {text = "one screen coordinate indexes every attachment before the lighting pass", point = {0, 2.43},
    role = "text", fill = "muted", id = "gbuffer:subtitle"}
local coordinate = scene:text {text = string.format("pixel (%d,%d)", selected.x, selected.y), point = {-4.05, -0.55},
    role = "code", fill = "focus", id = "gbuffer:coordinate"}
local values = scene:text {
    text = string.format("N=(%.2f, %.2f, %.2f)   depth=%.3f   roughness=%.2f", sample.normal[1], sample.normal[2], sample.normal[3], sample.depth, sample.roughness),
    point = {0, -1.32}, role = "code", fill = "foreground", id = "gbuffer:values",
}
local formula = scene:text {text = string.format("max(N·L, 0) = %.3f   →   shade(albedo, normal, material)", ndotl),
    point = {0, -1.90}, role = "code", fill = "result", id = "gbuffer:formula"}
local invariant = scene:text {text = "same dimensions · sample count · pixel coordinates", point = {0, -2.54},
    role = "h3", fill = "result", id = "gbuffer:invariant"}

scene:fade_in(title, {shift = {0, -0.08}, duration = 0.40, curve = "gentle"})
scene:fade_in(subtitle, {duration = 0.28, curve = "gentle"})
for i = 1, 4 do
    scene:create(buffers[i], 0.38, "ease_out")
    scene:fade_in(labels[i], {duration = 0.18, curve = "gentle"})
end
scene:fade_in(coordinate, {duration = 0.24, curve = "gentle"})
scene:create({frames[1], frames[2], frames[3], frames[4]}, 0.40, "ease_out", 0.06)
scene:fade_in(values, {duration = 0.36, curve = "gentle"})
scene:fade_in(formula, {duration = 0.36, curve = "gentle"})
scene:create(buffers[5], 0.48, "ease_out")
scene:create(frames[5], 0.24, "ease_out")
scene:fade_in(labels[5], {duration = 0.22, curve = "gentle"})
scene:fade_in(invariant, {duration = 0.38, curve = "gentle"})
scene:wait(1.7)
return scene
