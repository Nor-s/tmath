-- local question: In what order does an interlaced GIF deliver image rows?
-- visible input: one 12 x 16 literal RGB raster with all rows initially empty
-- subject object or field: the four GIF interlace pass schedules
-- one dominant action: reveal the raster rows pass by pass in stored order
-- observable output: coarse coverage arrives first and odd rows complete the image
-- coordinate frame and units: image rows are numbered from the top, starting at zero
-- section bounds supplied by the parent: standalone 960 x 540 wrapper
-- final readable pose: complete raster, four pass rules, and exact row order

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "3_blue_1_eyes",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local LAYER = {base = -10, cell = 0, text = 40}
local figure = scene:group {id = "gif-interlace-passes-figure"}

local function text(parent, id, value, point, role, fill, align)
    return parent:text {
        id = id, text = value, point = point, role = role or "code",
        fill = fill or "foreground", align = align or {0.5, 0.5}, layer = LAYER.text,
    }
end

local function join(values, separator)
    local parts = {}
    for index, value in ipairs(values) do parts[index] = tostring(value) end
    return table.concat(parts, separator or ", ")
end

local function pixelColor(column, row, columns, rows)
    local red = 36 + math.floor(204 * column / (columns - 1) + 0.5)
    local green = 42 + math.floor(176 * row / (rows - 1) + 0.5)
    local blue = 232 - math.floor(156 * column / (columns - 1) + 0.5)
    return string.format("#%02x%02x%02xff", red, green, blue)
end

local columns, rows = 12, 16
local passStarts = {0, 4, 2, 1}
local passSteps = {8, 8, 4, 2}
local passRoles = {"info", "warning", "focus", "result"}
local passRows = {}
for pass = 1, 4 do
    passRows[pass] = {}
    local row = passStarts[pass]
    while row < rows do
        passRows[pass][#passRows[pass] + 1] = row
        row = row + passSteps[pass]
    end
end

local storedOrder = {}
for pass = 1, 4 do
    for _, row in ipairs(passRows[pass]) do storedOrder[#storedOrder + 1] = row end
end

local claim = text(
    figure, "gif-interlace-claim",
    "Interlaced GIF sends image rows in four widening passes",
    {0, 2.55}, "h3"
)
local rasterLabel = text(
    figure, "gif-interlace-raster-label",
    string.format("%d x %d RGB raster · row 0 is top", columns, rows),
    {-2.86, 2.02}, "code", "muted"
)

local rasterSpace = figure:space {
    id = "gif-interlace-raster-space", x = {0, columns - 1, 1}, y = {0, rows - 1, 1}, opacity = 0,
    matrix = {0.27, 0, 0, -4.35, 0, -0.20, 0, 1.58, 0, 0, 1, 0, 0, 0, 0, 1},
}
local rasterBase = rasterSpace:cell {
    id = "gif-interlace-raster-base", origin = {-0.5, -0.5}, size = {columns, rows},
    mode = "padd", padding = 0.045, color = "surface", layer = LAYER.base,
}
local passCells = {}
for pass = 1, 4 do
    local patches = {}
    for _, row in ipairs(passRows[pass]) do
        for column = 0, columns - 1 do
            patches[#patches + 1] = {
                region = {column, row, 1, 1},
                color = pixelColor(column, row, columns, rows),
            }
        end
    end
    passCells[pass] = rasterSpace:cell {
        id = string.format("gif-interlace-pass-%d-cells", pass),
        origin = {-0.5, -0.5}, size = {columns, rows}, mode = "padd",
        padding = 0.045, color = "#00000000", patches = patches, layer = LAYER.cell,
    }
end
text(figure, "gif-interlace-row-zero", "row 0", {-4.62, 1.58}, "code", "foreground", {1, 0.5})
text(figure, "gif-interlace-row-last", string.format("row %d", rows - 1), {-4.62, -1.42}, "code", "foreground", {1, 0.5})

local passGroups = {}
local passYs = {1.42, 0.52, -0.38, -1.28}
for pass = 1, 4 do
    local y = passYs[pass]
    local group = figure:group {id = string.format("gif-interlace-pass-%d-rule", pass)}
    group:rectangle {
        id = string.format("gif-interlace-pass-%d-marker", pass),
        center = {-0.28, y}, size = {0.22, 0.58},
        fill = passRoles[pass], stroke = passRoles[pass], width = 1.4, layer = LAYER.cell,
    }
    text(
        group, string.format("gif-interlace-pass-%d-title", pass),
        string.format("pass %d · rows %s", pass, join(passRows[pass])),
        {0.10, y + 0.16}, "code", passRoles[pass], {0, 0.5}
    )
    text(
        group, string.format("gif-interlace-pass-%d-step", pass),
        string.format("start %d · step %d", passStarts[pass], passSteps[pass]),
        {0.10, y - 0.18}, "code", "muted", {0, 0.5}
    )
    passGroups[pass] = group
end

local orderLabel = text(
    figure, "gif-interlace-order-label", "stored row order",
    {-3.95, -2.12}, "code", "muted", {0, 0.5}
)
local orderSummary = text(
    figure, "gif-interlace-order-summary", join(storedOrder, "  "),
    {-2.14, -2.12}, "code", "result", {0, 0.5}
)

scene:fade_in(claim, {shift = {0, 0.08}, duration = 0.44, curve = "gentle"})
scene:fade_in(rasterLabel, {shift = {0, 0.05}, duration = 0.26, curve = "gentle"})
scene:fade_in(rasterBase, {shift = {0, 0.06}, duration = 0.42, curve = "ease_out"})
for pass = 1, 4 do
    scene:fade_in(passGroups[pass], {shift = {0.08, 0}, duration = 0.30, curve = "ease_out"})
    scene:create(passCells[pass], 0.62, "linear")
    scene:wait(0.34)
end
scene:fade_in(orderLabel, {shift = {0, -0.05}, duration = 0.28, curve = "gentle"})
scene:fade_in(orderSummary, {shift = {0, -0.05}, duration = 0.36, curve = "gentle"})
scene:wait(2.0)
return scene
