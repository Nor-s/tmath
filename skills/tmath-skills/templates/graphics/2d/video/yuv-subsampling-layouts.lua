-- local question: What spatial information changes between YUV 4:4:4, 4:2:2, and 4:2:0?
-- visible input: one literal 4 x 4 nonlinear RGB sample field
-- subject object or field: reconstructed RGB fields and one highlighted chroma footprint per format
-- one dominant action: average Cb/Cr over 1 x 1, 2 x 1, or 2 x 2 luma footprints
-- observable output: exact Y/U/V plane dimensions and component-sample counts
-- coordinate frame and units: each Cell location is one luma sample position
-- section bounds supplied by the parent: standalone 960 x 540 wrapper
-- final readable pose: three aligned color fields with footprints and storage ratios

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "3_blue_1_eyes",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local LAYER = {cell = 0, footprint = 20, text = 40}
local figure = scene:group {id = "yuv-subsampling-layouts-figure"}

local function text(parent, id, value, point, role, fill, align)
    return parent:text {
        id = id, text = value, point = point, role = role or "code",
        fill = fill or "foreground", align = align or {0.5, 0.5}, layer = LAYER.text,
    }
end

local function clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

local function byte(value)
    return math.floor(clamp(value, 0, 1) * 255 + 0.5)
end

local function rgbHex(rgb)
    return string.format("#%02x%02x%02xff", byte(rgb[1]), byte(rgb[2]), byte(rgb[3]))
end

local kr, kb = 0.2126, 0.0722
local kg = 1 - kr - kb
local function rgbToYCbCr(rgb)
    local y = kr * rgb[1] + kg * rgb[2] + kb * rgb[3]
    return {
        y,
        (rgb[3] - y) / (2 * (1 - kb)),
        (rgb[1] - y) / (2 * (1 - kr)),
    }
end

local function yCbCrToRgb(y, cb, cr)
    local r = y + 2 * (1 - kr) * cr
    local b = y + 2 * (1 - kb) * cb
    local g = (y - kr * r - kb * b) / kg
    return {clamp(r, 0, 1), clamp(g, 0, 1), clamp(b, 0, 1)}
end

local columns, rows = 4, 4
local sourceRgb = {
    {0.92, 0.12, 0.10}, {0.08, 0.78, 0.20}, {0.10, 0.24, 0.94}, {0.96, 0.82, 0.08},
    {0.90, 0.12, 0.72}, {0.04, 0.78, 0.82}, {0.98, 0.42, 0.06}, {0.08, 0.58, 0.46},
    {0.48, 0.06, 0.06}, {0.40, 0.92, 0.28}, {0.48, 0.16, 0.72}, {0.92, 0.64, 0.06},
    {0.96, 0.96, 0.96}, {0.50, 0.50, 0.50}, {0.04, 0.04, 0.04}, {0.96, 0.30, 0.22},
}
local sourceYCbCr = {}
for index, rgb in ipairs(sourceRgb) do sourceYCbCr[index] = rgbToYCbCr(rgb) end

local function reconstruct(horizontalFactor, verticalFactor)
    local chromaColumns = math.ceil(columns / horizontalFactor)
    local chromaRows = math.ceil(rows / verticalFactor)
    local cbPlane, crPlane = {}, {}
    for chromaRow = 0, chromaRows - 1 do
        for chromaColumn = 0, chromaColumns - 1 do
            local cbSum, crSum, count = 0, 0, 0
            for dy = 0, verticalFactor - 1 do
                for dx = 0, horizontalFactor - 1 do
                    local row = chromaRow * verticalFactor + dy
                    local column = chromaColumn * horizontalFactor + dx
                    if row < rows and column < columns then
                        local sample = sourceYCbCr[row * columns + column + 1]
                        cbSum, crSum, count = cbSum + sample[2], crSum + sample[3], count + 1
                    end
                end
            end
            local planeIndex = chromaRow * chromaColumns + chromaColumn + 1
            cbPlane[planeIndex], crPlane[planeIndex] = cbSum / count, crSum / count
        end
    end

    local result = {}
    for row = 0, rows - 1 do
        for column = 0, columns - 1 do
            local sourceIndex = row * columns + column + 1
            local chromaColumn = math.floor(column / horizontalFactor)
            local chromaRow = math.floor(row / verticalFactor)
            local planeIndex = chromaRow * chromaColumns + chromaColumn + 1
            result[sourceIndex] = yCbCrToRgb(
                sourceYCbCr[sourceIndex][1], cbPlane[planeIndex], crPlane[planeIndex]
            )
        end
    end
    return result, chromaColumns, chromaRows
end

local claim = text(
    figure, "yuv-subsampling-claim",
    "Chroma subsampling shares Cb/Cr across luma positions",
    {0, 2.62}, "h3"
)
local scope = text(
    figure, "yuv-subsampling-scope",
    "same 4 x 4 source · BT.709 full-range math for this illustrative reconstruction",
    {0, 2.18}, "code", "muted"
)

local cases = {
    {name = "4:4:4", h = 1, v = 1, x = -3.38, color = "info"},
    {name = "4:2:2", h = 2, v = 1, x = 0, color = "focus"},
    {name = "4:2:0", h = 2, v = 2, x = 3.38, color = "result"},
}
local caseGroups = {}
for index, item in ipairs(cases) do
    local reconstructed, chromaColumns, chromaRows = reconstruct(item.h, item.v)
    local scale, centerY = 0.52, 0.28
    local space = figure:space {
        id = string.format("yuv-subsampling-case-%02d-space", index),
        x = {0, columns - 1, 1}, y = {0, rows - 1, 1}, opacity = 0,
        matrix = {
            scale, 0, 0, item.x - (columns - 1) * scale / 2,
            0, scale, 0, centerY - (rows - 1) * scale / 2,
            0, 0, 1, 0,
            0, 0, 0, 1,
        },
    }
    local patches = {}
    for row = 0, rows - 1 do
        for column = 0, columns - 1 do
            local sampleIndex = row * columns + column + 1
            patches[#patches + 1] = {
                region = {column, row, 1, 1}, color = rgbHex(reconstructed[sampleIndex]),
            }
        end
    end
    local cell = space:cell {
        id = string.format("yuv-subsampling-case-%02d-cell", index),
        origin = {-0.5, -0.5}, size = {columns, rows}, mode = "padd", padding = 0.035,
        color = "surface", patches = patches, layer = LAYER.cell,
    }
    local footprint = space:rectangle {
        id = string.format("yuv-subsampling-case-%02d-footprint", index),
        center = {(item.h - 1) / 2, (item.v - 1) / 2}, size = {item.h, item.v},
        fill = "#00000000", stroke = item.color, width = 3, layer = LAYER.footprint,
    }
    local title = text(
        figure, string.format("yuv-subsampling-case-%02d-title", index), item.name,
        {item.x, 1.65}, "h3", item.color
    )
    local planeCount = columns * rows + 2 * chromaColumns * chromaRows
    local planes = text(
        figure, string.format("yuv-subsampling-case-%02d-planes", index),
        string.format("Y %dx%d · U %dx%d · V %dx%d", columns, rows, chromaColumns, chromaRows, chromaColumns, chromaRows),
        {item.x, -1.08}, "code", "foreground"
    )
    local footprintLabel = text(
        figure, string.format("yuv-subsampling-case-%02d-footprint-label", index),
        string.format("1 chroma sample / %dx%d Y", item.h, item.v),
        {item.x, -1.45}, "code", item.color
    )
    local count = text(
        figure, string.format("yuv-subsampling-case-%02d-count", index),
        string.format("%d component samples", planeCount),
        {item.x, -1.78}, "code", "muted"
    )
    caseGroups[index] = {
        cell = cell, footprint = footprint,
        labels = {title, planes, footprintLabel, count},
    }
end

local note = text(
    figure, "yuv-subsampling-note",
    "footprint size is shown; exact chroma siting is format/metadata-specific",
    {0, -2.30}, "code", "result"
)

scene:fade_in(claim, {shift = {0, 0.08}, duration = 0.42, curve = "gentle"})
scene:fade_in(scope, {shift = {0, 0.05}, duration = 0.32, curve = "gentle"})
for _, item in ipairs(caseGroups) do
    scene:fade_in(item.labels[1], {duration = 0.22, curve = "gentle"})
    scene:create(item.cell, 0.48, "linear")
    scene:create(item.footprint, 0.28, "ease_out")
    scene:create({item.labels[2], item.labels[3], item.labels[4]}, 0.32, "ease_out", 0.04)
end
scene:fade_in(note, {shift = {0, -0.04}, duration = 0.32, curve = "gentle"})
scene:wait(2.0)
return scene
