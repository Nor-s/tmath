-- Animate one retained Cell field through its pure (x, y, time) sampler.
local duration = 2.8
local startTime = 0
local function smooth(t) return t * t * (3 - 2 * t) end
local colors = {"#0891b2", "#2879c5", "#5557ce", "#7c3aed"}

-- One state function drives position, deformation, guides, and sampled occupancy.
local function state(time)
    local progress = smooth(math.max(0, math.min(1, time / duration)))
    return {
        center = {-1.35 + 2.55 * progress, 0.28 * math.sin(math.pi * progress)},
        a = 1.15 + 0.75 * progress,
        b = 1.15 - 0.30 * progress,
        progress = progress,
    }
end
local function ellipsePoints(value)
    local points = {}
    for i = 0, 63 do
        local angle = 2 * math.pi * i / 64
        points[#points + 1] = {
            value.center[1] + value.a * math.cos(angle),
            value.center[2] + value.b * math.sin(angle),
        }
    end
    return points
end
local function sampleColor(x, y, time)
    local value = state(time)
    local dx, dy = (x - value.center[1]) / value.a, (y - value.center[2]) / value.b
    if dx * dx + dy * dy > 1 then return "#00000000" end
    return colors[math.min(#colors, math.floor(value.progress * #colors) + 1)]
end

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.4},
}
local grid = scene:space {id = "cell-time-grid", x = {-4, 4, 1}, y = {-2, 2, 1}, numbers = false, stroke = "border", width = 1, opacity = 0.45}
local field = scene:space {id = "cell-time-space", x = {-3.5, 3.5, 0.18}, y = {-2, 2, 0.18}, opacity = 0}
local initial, final = state(startTime), state(duration)

-- Endpoint outlines make the full motion envelope readable in the final still.
field:polygon {id = "cell-time-start", points = ellipsePoints(initial), fill = "#00000000", stroke = "muted", width = 2, dash = {7, 5}, opacity = 0.55, layer = 10}
field:polygon {id = "cell-time-end", points = ellipsePoints(final), fill = "#00000000", stroke = "result", width = 3, opacity = 0.7, layer = 10}
scene:text {id = "cell-time-sampler", text = "cell(x, y, time)", point = {0, 2.65}, role = "code", fill = "foreground", layer = 40}
scene:text {id = "cell-time-zero", text = string.format("t = %.0f", startTime), point = {initial.center[1], -1.75}, role = "code", fill = "muted", layer = 40}
scene:text {id = "cell-time-end-label", text = string.format("t = %.1f s", duration), point = {final.center[1], -1.75}, role = "code", fill = "result", layer = 40}

-- Positive duration and FPS retain endpoint-inclusive field samples and advance the cursor.
field:cell(sampleColor, {
    mode = "padd", padding = 0.045, duration = duration, fps = 18,
})
scene:wait(1.0)
return scene
