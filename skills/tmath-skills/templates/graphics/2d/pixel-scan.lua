-- Reveal a surface in row-major memory order: left-to-right, then top-to-bottom.
local columns, rows, duration = 8, 5, 4.8
local colors = {"#173f5f", "#20639b", "#3caea3", "#58b368", "#f6d55c", "#f49d37", "#ed553b", "#9c27b0"}
local function scanColor(x, y, time)
    local column, row = math.floor(x + 0.5), rows - 1 - math.floor(y + 0.5)
    local index, count = row * columns + column, columns * rows
    local active = math.min(count, math.floor(math.max(0, time / duration) * count))
    if index < active then return colors[(column + 2 * row) % #colors + 1] end
    if index == active then return "#f59e0b" end
    if row == math.floor(active / columns) then return "#f59e0b2f" end
    return "#00000000"
end

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6},
}
local space = scene:space {
    x = {0, columns - 1, 1}, y = {0, rows - 1, 1}, opacity = 0,
    matrix = {0.9, 0, 0, -3.15, 0, 0.9, 0, -1.8, 0, 0, 1, 0, 0, 0, 0, 1},
}
-- The static cells preserve memory extent while the temporal layer carries progress.
space:cell {
    origin = {-0.5, -0.5}, size = {columns, rows}, mode = "padd",
    padding = 0.075, color = "surface", layer = -5,
}
space:cell(scanColor, {mode = "padd", padding = 0.075, duration = duration, fps = 24})
scene:wait(1)
return scene
