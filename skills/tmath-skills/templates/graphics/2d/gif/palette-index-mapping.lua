-- local question: How does a GIF color index become an RGB pixel?
-- visible input: one 4 x 3 index raster and two four-entry RGB color tables
-- subject object or field: the active Global or Local Color Table
-- one dominant action: switch the active table while preserving the same indices
-- observable output: a Local Color Table overrides the Global Color Table for one image
-- coordinate frame and units: raster coordinates are top-left row-major pixel indices
-- section bounds supplied by the parent: standalone 960 x 540 wrapper
-- final readable pose: indices, both literal RGB tables, and both decoded rasters

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "3_blue_1_eyes",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local LAYER = {cell = 0, focus = 20, arrow = 30, text = 40}
local figure = scene:group {id = "gif-palette-index-figure"}

local function text(parent, id, value, point, role, fill, align)
    return parent:text {
        id = id, text = value, point = point, role = role or "code",
        fill = fill or "foreground", align = align or {0.5, 0.5}, layer = LAYER.text,
    }
end

local function rgbHex(rgb)
    return string.format("#%02x%02x%02xff", rgb[1], rgb[2], rgb[3])
end

local function rgbLabel(rgb)
    return string.format("#%02X%02X%02X", rgb[1], rgb[2], rgb[3])
end

local columns, rows = 4, 3
local indices = {
    {0, 1, 2, 3},
    {1, 2, 3, 0},
    {2, 3, 0, 1},
}
local globalPalette = {
    {11, 16, 32}, {56, 189, 248}, {249, 115, 22}, {250, 204, 21},
}
local localPalette = {
    {11, 16, 32}, {167, 139, 250}, {34, 197, 94}, {251, 113, 133},
}
local selectedIndex = 2

local claim = text(
    figure, "gif-palette-index-claim",
    "GIF pixels store indices into one active RGB color table",
    {0, 2.55}, "h3"
)

local sourceSpace = figure:space {
    id = "gif-palette-index-space", x = {0, columns - 1, 1}, y = {0, rows - 1, 1}, opacity = 0,
    matrix = {0.48, 0, 0, -4.46, 0, -0.48, 0, 0.72, 0, 0, 1, 0, 0, 0, 0, 1},
}
local source = sourceSpace:cell {
    id = "gif-palette-index-cells", origin = {-0.5, -0.5}, size = {columns, rows},
    mode = "padd", padding = 0.06, color = "surface", layer = LAYER.cell,
}
for row = 0, rows - 1 do
    for column = 0, columns - 1 do
        text(
            sourceSpace, string.format("gif-palette-index-%d-%d", column, row),
            tostring(indices[row + 1][column + 1]), {column, row}, "code", "foreground"
        )
    end
end
local sourceFocus = sourceSpace:rectangle {
    id = "gif-palette-index-focus", center = {2, 0}, size = {0.94, 0.94},
    fill = "#00000000", stroke = "focus", width = 4, layer = LAYER.focus,
}
local sourceLabel = text(
    figure, "gif-palette-index-label", "stored index raster", {-3.74, 1.58}, "code", "muted"
)

local function paletteRow(id, y, label, palette, role)
    local group = figure:group {id = id}
    text(group, id .. "-label", label, {-0.20, y + 0.48}, "code", role)
    local startX, step = -1.30, 0.74
    for index, rgb in ipairs(palette) do
        local paletteIndex = index - 1
        local x = startX + paletteIndex * step
        group:rectangle {
            id = string.format("%s-swatch-%d", id, paletteIndex),
            center = {x, y}, size = {0.58, 0.58}, fill = rgbHex(rgb),
            stroke = paletteIndex == selectedIndex and "focus" or "border",
            width = paletteIndex == selectedIndex and 3 or 1.4, layer = LAYER.cell,
        }
        text(
            group, string.format("%s-index-%d", id, paletteIndex), tostring(paletteIndex),
            {x, y}, "code", paletteIndex == 3 and "#111827ff" or "#ffffffff"
        )
    end
    return group
end

local globalTable = paletteRow(
    "gif-global-color-table", 0.92,
    string.format("GCT · %d entries · RGB8", #globalPalette), globalPalette, "info"
)
local localTable = paletteRow(
    "gif-local-color-table", -0.64,
    string.format("LCT · %d entries · RGB8", #localPalette), localPalette, "result"
)

local function decodedRaster(id, palette, translateY)
    local space = figure:space {
        id = id .. "-space", x = {0, columns - 1, 1}, y = {0, rows - 1, 1}, opacity = 0,
        matrix = {0.38, 0, 0, 2.90, 0, -0.38, 0, translateY, 0, 0, 1, 0, 0, 0, 0, 1},
    }
    local patches = {}
    for row = 0, rows - 1 do
        for column = 0, columns - 1 do
            local index = indices[row + 1][column + 1]
            patches[#patches + 1] = {
                region = {column, row, 1, 1}, color = rgbHex(palette[index + 1]),
            }
        end
    end
    return space:cell {
        id = id .. "-cells", origin = {-0.5, -0.5}, size = {columns, rows},
        mode = "padd", padding = 0.06, color = "surface", patches = patches, layer = LAYER.cell,
    }
end

local globalOutput = decodedRaster("gif-global-decoded", globalPalette, 1.10)
local localOutput = decodedRaster("gif-local-decoded", localPalette, -0.54)
local globalOutputLabel = text(
    figure, "gif-global-decoded-label", "image without LCT", {3.47, 1.82}, "code", "info"
)
local localOutputLabel = text(
    figure, "gif-local-decoded-label", "image with LCT", {3.47, 0.18}, "code", "result"
)

local globalArrow = figure:arrow {
    id = "gif-global-palette-arrow", from = {1.02, 0.92}, to = {2.05, 1.10},
    stroke = "info", width = 2, tip = 10, layer = LAYER.arrow,
}
local localArrow = figure:arrow {
    id = "gif-local-palette-arrow", from = {1.02, -0.64}, to = {2.05, -0.54},
    stroke = "result", width = 2, tip = 10, layer = LAYER.arrow,
}
local selectedSummary = text(
    figure, "gif-palette-selected-summary",
    string.format("index %d -> GCT %s   |   LCT %s", selectedIndex,
        rgbLabel(globalPalette[selectedIndex + 1]), rgbLabel(localPalette[selectedIndex + 1])),
    {0.92, -1.62}, "code", "focus"
)
local scopeSummary = text(
    figure, "gif-palette-scope-summary",
    "LCT overrides GCT only for the image that immediately follows it",
    {0, -2.18}, "code", "muted"
)

scene:fade_in(claim, {shift = {0, 0.08}, duration = 0.44, curve = "gentle"})
scene:fade_in(sourceLabel, {shift = {0, 0.05}, duration = 0.24, curve = "gentle"})
scene:create(source, 0.58, "linear")
scene:create(sourceFocus, 0.28, "ease_out")
scene:fade_in(globalTable, {shift = {0, 0.08}, duration = 0.52, curve = "ease_out"})
scene:create(globalArrow, 0.34, "ease_out")
scene:fade_in(globalOutput, {shift = {-0.10, 0}, duration = 0.50, curve = "ease_out"})
scene:fade_in(globalOutputLabel, {shift = {0, 0.05}, duration = 0.24, curve = "gentle"})
scene:wait(0.44)
scene:fade_in(localTable, {shift = {0, 0.08}, duration = 0.52, curve = "ease_out"})
scene:create(localArrow, 0.34, "ease_out")
scene:fade_in(localOutput, {shift = {-0.10, 0}, duration = 0.50, curve = "ease_out"})
scene:fade_in(localOutputLabel, {shift = {0, 0.05}, duration = 0.24, curve = "gentle"})
scene:fade_in(selectedSummary, {shift = {0, -0.05}, duration = 0.32, curve = "gentle"})
scene:fade_in(scopeSummary, {shift = {0, -0.05}, duration = 0.32, curve = "gentle"})
scene:wait(1.9)
return scene
