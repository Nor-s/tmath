-- local question: How does PNG filter type 1 reconstruct a scanline exactly?
-- visible input: one smooth grayscale byte row and its Sub residuals
-- subject object or field: byte-wise left-neighbor prediction
-- one dominant action: reconstruct bytes from left to right
-- observable output: the reconstructed row equals the original row
-- coordinate frame and units: figure-local world units; each cell is one byte
-- section bounds supplied by the parent: standalone 960 x 540 wrapper
-- final readable pose: original, filtered, and reconstructed rows remain aligned

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "3_blue_1_eyes",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local LAYER = {object = 0, focus = 20, arrow = 30, text = 40}
local figure = scene:group {id = "png-filter-reconstruction-figure"}

local function text(parent, id, value, point, role, fill, align)
    return parent:text {
        id = id, text = value, point = point, role = role or "code",
        fill = fill or "foreground", align = align or {0.5, 0.5}, layer = LAYER.text,
    }
end

local function gray(value)
    return string.format("#%02x%02x%02x", value, value, value)
end

local original = {50, 52, 55, 58, 60}
local filtered = {}
for index, value in ipairs(original) do
    local left = index == 1 and 0 or original[index - 1]
    filtered[index] = (value - left) % 256
end
local reconstructed = {}
for index, value in ipairs(filtered) do
    local left = index == 1 and 0 or reconstructed[index - 1]
    reconstructed[index] = (value + left) % 256
end

local claim = text(
    figure, "png-filter-claim",
    "Sub stores byte differences; reconstruction adds the left byte back",
    {0, 2.55}, "h3"
)

local centers, startX, step = {}, -2.55, 1.28
for index = 1, #original do centers[index] = startX + (index - 1) * step end

local function makeRow(id, values, y, fillForValue)
    local group, cells = figure:group {id = id}, {}
    for index, value in ipairs(values) do
        local cell = group:group {id = string.format("%s-cell-%d", id, index)}
        local fill = fillForValue and fillForValue(value, index) or "surface"
        cell:rectangle {
            id = string.format("%s-body-%d", id, index), center = {centers[index], y}, size = {0.94, 0.70},
            fill = fill, stroke = "border", width = 1.5, layer = LAYER.object,
        }
        text(
            cell, string.format("%s-value-%d", id, index), tostring(value),
            {centers[index], y}, "code",
            fillForValue and (value < 96 and "#ffffffff" or "#111827ff") or "foreground"
        )
        cells[index] = cell
    end
    return group, cells
end

local originalRow = makeRow("png-filter-original", original, 1.20, function(value) return gray(value) end)
local filteredRow = makeRow("png-filter-residuals", filtered, 0.02)
local reconstructedRow, reconstructedCells = makeRow(
    "png-filter-reconstructed", reconstructed, -1.20, function(value) return gray(value) end
)

local labels = {
    text(figure, "png-filter-original-label", "Original", {-4.65, 1.20}, "code", "foreground", {0, 0.5}),
    text(figure, "png-filter-residual-label", "Sub", {-4.65, 0.02}, "code", "focus", {0, 0.5}),
    text(figure, "png-filter-recon-label", "Recon", {-4.65, -1.20}, "code", "result", {0, 0.5}),
}

local filterArrow = figure:arrow {
    id = "png-filter-down-arrow", from = {4.20, 0.92}, to = {4.20, 0.30},
    stroke = "focus", width = 2, tip = 10, layer = LAYER.arrow,
}
local filterArrowLabel = text(
    figure, "png-filter-down-label", "subtract left", {4.02, 0.62}, "code", "focus", {1, 0.5}
)
local reconArrow = figure:arrow {
    id = "png-filter-recon-arrow", from = {4.20, -0.28}, to = {4.20, -0.90},
    stroke = "result", width = 2, tip = 10, layer = LAYER.arrow,
}
local reconArrowLabel = text(
    figure, "png-filter-recon-arrow-label", "add left", {4.02, -0.60}, "code", "result", {1, 0.5}
)

local cursor = figure:rectangle {
    id = "png-filter-current-byte", center = {centers[1], 0.02}, size = {1.06, 0.82},
    fill = "#00000000", stroke = "focus", width = 3, layer = LAYER.focus,
}
local formula = text(
    figure, "png-filter-formula",
    "Recon(x) = Filt(x) + Recon(a)  mod 256",
    {0, -2.10}, "code", "foreground"
)
local example = text(
    figure, "png-filter-example",
    string.format("%d + %d = %d", filtered[2], reconstructed[1], reconstructed[2]),
    {0, -2.52}, "code", "result"
)

scene:fade_in(claim, {shift = {0, 0.08}, duration = 0.42, curve = "gentle"})
scene:fade_in(originalRow, {shift = {0, 0.08}, duration = 0.45, curve = "ease_out"})
scene:fade_in(labels[1], {shift = {0.08, 0}, duration = 0.24, curve = "gentle"})
scene:create(filterArrow, 0.30, "ease_out")
scene:fade_in(filterArrowLabel, {shift = {-0.06, 0}, duration = 0.22, curve = "gentle"})
scene:fade_in(filteredRow, {shift = {0, 0.08}, duration = 0.50, curve = "ease_out"})
scene:fade_in(labels[2], {shift = {0.08, 0}, duration = 0.24, curve = "gentle"})
scene:create(reconArrow, 0.30, "ease_out")
scene:fade_in(reconArrowLabel, {shift = {-0.06, 0}, duration = 0.22, curve = "gentle"})
scene:fade_in(formula, {shift = {0, -0.06}, duration = 0.28, curve = "gentle"})
scene:create(cursor, 0.24, "ease_out")
scene:fade_in(reconstructedCells[1], {shift = {0, 0.08}, duration = 0.34, curve = "ease_out"})
scene:fade_in(labels[3], {shift = {0.08, 0}, duration = 0.22, curve = "gentle"})
scene:shift(cursor, {step, 0}, 0.30, "ease_in_out")
scene:fade_in(reconstructedCells[2], {shift = {0, 0.08}, duration = 0.32, curve = "ease_out"})
scene:fade_in(example, {shift = {0, -0.05}, duration = 0.24, curve = "gentle"})
for index = 3, #reconstructedCells do
    scene:shift(cursor, {step, 0}, 0.20, "ease_in_out")
    scene:fade_in(reconstructedCells[index], {shift = {0, 0.06}, duration = 0.22, curve = "ease_out"})
end
scene:wait(1.8)
return scene
