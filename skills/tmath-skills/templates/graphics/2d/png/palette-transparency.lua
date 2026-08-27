-- local question: How do PLTE and tRNS turn an index into RGBA?
-- visible input: a 4 x 2 indexed image and four palette records
-- subject object or field: index bytes, RGB palette entries, and alpha table entries
-- one dominant action: follow index 2 through both tables into the decoded image
-- observable output: the selected output pixel is RGBA(59, 130, 246, 96)
-- coordinate frame and units: pixel centers are integer-local; table rows are records
-- section bounds supplied by the parent: standalone 960 x 540 wrapper
-- final readable pose: index field, selected record, and RGBA field remain visible

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "3_blue_1_eyes",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local LAYER = {checker = -10, object = 0, focus = 20, arrow = 30, text = 40}
local figure = scene:group {id = "png-palette-transparency-figure"}

local function text(parent, id, value, point, role, fill, align)
    return parent:text {
        id = id, text = value, point = point, role = role or "code",
        fill = fill or "foreground", align = align or {0.5, 0.5}, layer = LAYER.text,
    }
end

local function rgbaHex(rgba)
    return string.format("#%02x%02x%02x%02x", rgba[1], rgba[2], rgba[3], rgba[4])
end

local columns, rows = 4, 2
local indices = {
    {3, 2, 1, 0},
    {0, 1, 2, 3},
}
local palette = {
    {239, 68, 68, 255},
    {34, 197, 94, 192},
    {59, 130, 246, 96},
    {250, 204, 21, 0},
}
local selected = {x = 2, y = 1}
local selectedIndex = indices[selected.y + 1][selected.x + 1]
local selectedRgba = palette[selectedIndex + 1]

local claim = text(
    figure, "png-palette-claim",
    "PLTE supplies RGB; tRNS supplies alpha for each index",
    {0, 2.55}, "h3"
)

local source = figure:group {id = "png-palette-index-source"}
local sourceSpace = source:space {
    id = "png-palette-index-space", x = {0, columns - 1, 1}, y = {0, rows - 1, 1}, opacity = 0,
    matrix = {0.58, 0, 0, -4.30, 0, 0.58, 0, -0.48, 0, 0, 1, 0, 0, 0, 0, 1},
}
sourceSpace:cell {
    id = "png-palette-index-cells", origin = {-0.5, -0.5}, size = {columns, rows},
    mode = "padd", padding = 0.06, color = "surface", layer = LAYER.object,
}
for y = 0, rows - 1 do
    for x = 0, columns - 1 do
        text(
            sourceSpace, string.format("png-palette-index-%d-%d", x, y),
            tostring(indices[y + 1][x + 1]), {x, y}, "code", "foreground"
        )
    end
end
local sourceSelection = sourceSpace:rectangle {
    id = "png-palette-source-selection", center = {selected.x, selected.y}, size = {0.96, 0.96},
    fill = "#00000000", stroke = "focus", width = 4, layer = LAYER.focus,
}
local sourceLabel = text(
    figure, "png-palette-source-label", "index bytes", {-3.43, 1.42}, "code", "muted"
)

local tableGroup = figure:group {id = "png-palette-table"}
local tableHeader = text(
    tableGroup, "png-palette-table-header", "index     PLTE RGB             tRNS A",
    {0.02, 1.42}, "code", "muted"
)
local rowGroups, rowY = {}, {}
for index, rgba in ipairs(palette) do
    local paletteIndex = index - 1
    local y = 0.82 - paletteIndex * 0.56
    rowY[index] = y
    local row = tableGroup:group {id = string.format("png-palette-record-%d", paletteIndex)}
    row:rectangle {
        id = string.format("png-palette-swatch-%d", paletteIndex), center = {-1.02, y}, size = {0.38, 0.38},
        fill = string.format("#%02x%02x%02xff", rgba[1], rgba[2], rgba[3]),
        stroke = "border", width = 1.5, layer = LAYER.object,
    }
    text(row, string.format("png-palette-record-index-%d", paletteIndex), tostring(paletteIndex), {-1.42, y}, "code")
    text(
        row, string.format("png-palette-record-rgb-%d", paletteIndex),
        string.format("(%d,%d,%d)", rgba[1], rgba[2], rgba[3]), {-0.05, y}, "code", "foreground"
    )
    text(
        row, string.format("png-palette-record-alpha-%d", paletteIndex),
        tostring(rgba[4]), {1.12, y}, "code", "foreground"
    )
    rowGroups[index] = row
end
local tableSelection = tableGroup:rectangle {
    id = "png-palette-table-selection", center = {0, rowY[selectedIndex + 1]}, size = {3.12, 0.50},
    fill = "#00000000", stroke = "focus", width = 3, layer = LAYER.focus,
}

local output = figure:group {id = "png-palette-output"}
local outputSpace = output:space {
    id = "png-palette-output-space", x = {0, columns - 1, 1}, y = {0, rows - 1, 1}, opacity = 0,
    matrix = {0.58, 0, 0, 2.55, 0, 0.58, 0, -0.48, 0, 0, 1, 0, 0, 0, 0, 1},
}
local checkerPatches, outputPatches = {}, {}
for y = 0, rows - 1 do
    for x = 0, columns - 1 do
        local index = indices[y + 1][x + 1]
        checkerPatches[#checkerPatches + 1] = {
            region = {x, y, 1, 1}, color = (x + y) % 2 == 0 and "#d1d5db" or "#6b7280",
        }
        outputPatches[#outputPatches + 1] = {
            region = {x, y, 1, 1}, color = rgbaHex(palette[index + 1]),
        }
    end
end
outputSpace:cell {
    id = "png-palette-checker", origin = {-0.5, -0.5}, size = {columns, rows},
    mode = "padd", padding = 0.06, color = "surface", patches = checkerPatches, layer = LAYER.checker,
}
outputSpace:cell {
    id = "png-palette-rgba-cells", origin = {-0.5, -0.5}, size = {columns, rows},
    mode = "padd", padding = 0.06, color = "#00000000", patches = outputPatches, layer = LAYER.object,
}
local outputSelection = outputSpace:rectangle {
    id = "png-palette-output-selection", center = {selected.x, selected.y}, size = {0.96, 0.96},
    fill = "#00000000", stroke = "result", width = 4, layer = LAYER.focus,
}
local outputLabel = text(
    figure, "png-palette-output-label", "decoded RGBA", {3.42, 1.42}, "code", "result"
)

local sourcePoint = {-4.30 + selected.x * 0.58, -0.48 + selected.y * 0.58}
local outputPoint = {2.55 + selected.x * 0.58, -0.48 + selected.y * 0.58}
local lookupArrow = figure:arrow {
    id = "png-palette-lookup-arrow", from = {sourcePoint[1] + 0.40, sourcePoint[2]},
    to = {-1.67, rowY[selectedIndex + 1]}, stroke = "focus", width = 2, tip = 10, layer = LAYER.arrow,
}
local outputArrow = figure:arrow {
    id = "png-palette-output-arrow", from = {1.63, rowY[selectedIndex + 1]},
    to = {outputPoint[1] - 0.40, outputPoint[2]}, stroke = "result", width = 2, tip = 10, layer = LAYER.arrow,
}
local resultText = text(
    figure, "png-palette-result",
    string.format(
        "index %d -> PLTE[%d] + tRNS[%d] -> RGBA(%d,%d,%d,%d)",
        selectedIndex, selectedIndex, selectedIndex,
        selectedRgba[1], selectedRgba[2], selectedRgba[3], selectedRgba[4]
    ),
    {0, -2.05}, "code", "result"
)

scene:fade_in(claim, {shift = {0, 0.08}, duration = 0.42, curve = "gentle"})
scene:fade_in(source, {shift = {0, 0.08}, duration = 0.48, curve = "ease_out"})
scene:fade_in(sourceLabel, {shift = {0, 0.05}, duration = 0.24, curve = "gentle"})
scene:fade_in(tableHeader, {shift = {0, 0.05}, duration = 0.26, curve = "gentle"})
for _, row in ipairs(rowGroups) do
    scene:fade_in(row, {shift = {0.06, 0}, duration = 0.24, curve = "ease_out"})
end
scene:create(sourceSelection, 0.28, "ease_out")
scene:create(lookupArrow, 0.38, "ease_out")
scene:create(tableSelection, 0.28, "ease_out")
scene:create(outputArrow, 0.38, "ease_out")
scene:fade_in(output, {shift = {-0.10, 0}, duration = 0.50, curve = "ease_out"})
scene:fade_in(outputLabel, {shift = {0, 0.05}, duration = 0.24, curve = "gentle"})
scene:create(outputSelection, 0.28, "ease_out")
scene:fade_in(resultText, {shift = {0, -0.07}, duration = 0.34, curve = "gentle"})
scene:wait(1.8)
return scene
