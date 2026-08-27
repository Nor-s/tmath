local p =
    { paper = "#f7f8fb", ink = "#182033", muted = "#687086", grid = "#b9c5d8", blue = "#2563eb" }
local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 60,
    background = p.paper,
    camera = { mode = "fixed", view = "2d", height = 7 },
}
local title = scene:text {
    text = "TMATH",
    point = { 0, 0.55 },
    font = "Pretendard",
    size = 58,
    fill = p.ink,
    id = "opening-title",
}
local formula = scene:text {
    text = "Σ 1/n²  =  π²/6",
    point = { 0, -0.45 },
    font = "Pretendard",
    size = 24,
    fill = p.blue,
    id = "opening-formula",
}
scene:write(title, 0.65, "ease_out")
scene:fade_in(formula, { shift = { 0, -0.2 }, duration = 0.42, curve = "ease_out" })
scene:wait(0.35)
scene:fade_out(title, { shift = { -0.4, 0 }, duration = 0.3, curve = "ease_in" })
scene:fade_out(formula, { shift = { 0, -0.2 }, duration = 0.3, curve = "ease_in" })

local originals, warped_points = {}, {}
local function warp(x, y)
    return { x + 0.34 * math.sin(1.2 * y), y + 0.34 * math.sin(1.2 * x) }
end
for index = -7, 7 do
    local vertical, vertical_warped = {}, {}
    local horizontal, horizontal_warped = {}, {}
    local coordinate = index * 0.48
    for sample = 0, 32 do
        local value = -3.4 + 6.8 * sample / 32
        vertical[#vertical + 1] = { coordinate, value }
        vertical_warped[#vertical_warped + 1] = warp(coordinate, value)
        horizontal[#horizontal + 1] = { value, coordinate }
        horizontal_warped[#horizontal_warped + 1] = warp(value, coordinate)
    end
    local color = index == 0 and p.blue or p.grid
    local width = index == 0 and 2.4 or 1.2
    originals[#originals + 1] =
        scene:plot { points = vertical, stroke = color, width = width, id = "grid-v-" .. index }
    originals[#originals + 1] =
        scene:plot { points = horizontal, stroke = color, width = width, id = "grid-h-" .. index }
    warped_points[#warped_points + 1] =
        { points = vertical_warped, stroke = color, width = width, id = "warped-v-" .. index }
    warped_points[#warped_points + 1] =
        { points = horizontal_warped, stroke = color, width = width, id = "warped-h-" .. index }
end
local grid_title = scene:text {
    text = "a nonlinear function applied to a grid",
    point = { -5.55, 2.72 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 18,
    fill = p.ink,
    id = "grid-title",
}
scene:create(originals, 0.75, "ease_out", 0.008)
scene:fade_in(grid_title, { shift = { 0, 0.15 }, duration = 0.3, curve = "ease_out" })
local warped = {}
for index, options in ipairs(warped_points) do
    warped[index] = scene:plot(options)
end
scene:morph(originals, warped, 1.2, "ease_in_out", 0)
local restored = {}
for index = 1, #originals do
    local points = {}
    local line_index = math.floor((index - 1) / 2) - 7
    local vertical = index % 2 == 1
    local coordinate = line_index * 0.48
    for sample = 0, 32 do
        local value = -3.4 + 6.8 * sample / 32
        points[#points + 1] = vertical and { coordinate, value } or { value, coordinate }
    end
    local color = line_index == 0 and p.blue or p.grid
    local width = line_index == 0 and 2.4 or 1.2
    restored[#restored + 1] =
        scene:plot { points = points, stroke = color, width = width, id = "restored-" .. index }
end
scene:morph(warped, restored, 1.0, "ease_in_out", 0)
scene:wait(0.7)
return scene
