-- Advanced reference: four coverage samples share one pixel, shade per sample,
-- then resolve to one stored color by averaging those sample colors.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.4},
}

local columns, rows = 7, 5
local sampleOffsets = {{0.375, 0.125}, {0.875, 0.375}, {0.125, 0.625}, {0.625, 0.875}}
local foreground, background = {76, 201, 240}, {25, 31, 40}
local function inside(x, y) return y <= 0.68*x + 1.18 end
local function byte(v) return math.max(0, math.min(255, math.floor(v + 0.5))) end
local function hex(rgb) return string.format("#%02x%02x%02x", byte(rgb[1]), byte(rgb[2]), byte(rgb[3])) end
local function coverageAt(x, y)
    local covered = 0
    for _, offset in ipairs(sampleOffsets) do
        if inside(x - 0.5 + offset[1], y - 0.5 + offset[2]) then covered = covered + 1 end
    end
    return covered
end
local function resolvedColor(x, y)
    local coverage = coverageAt(x, y) / #sampleOffsets
    return {
        background[1] + coverage*(foreground[1] - background[1]),
        background[2] + coverage*(foreground[2] - background[2]),
        background[3] + coverage*(foreground[3] - background[3]),
    }
end
local selected, best = nil, math.huge
for y = 0, rows - 1 do for x = 0, columns - 1 do
    local count = coverageAt(x, y)
    if count > 0 and count < #sampleOffsets and math.abs(count - 2) < best then
        selected, best = {x = x, y = y, covered = count}, math.abs(count - 2)
    end
end end
assert(selected and selected.covered == 2)

local gridScale, gridCenter = 0.63, {-2.55, 0.05}
local gridMatrix = {gridScale, 0, 0, gridCenter[1] - 0.5*(columns - 1)*gridScale,
                    0, gridScale, 0, gridCenter[2] - 0.5*(rows - 1)*gridScale,
                    0, 0, 1, 0, 0, 0, 0, 1}
local grid = scene:space {x = {0, columns - 1, 1}, y = {0, rows - 1, 1}, opacity = 0,
    matrix = gridMatrix, id = "msaa:grid"}
local patches = {}
for y = 0, rows - 1 do for x = 0, columns - 1 do
    patches[#patches + 1] = {region = {x, y, 1, 1}, color = hex(resolvedColor(x, y))}
end end
local pixels = grid:cell {origin = {-0.5, -0.5}, size = {columns, rows}, mode = "padd", padding = 0.05,
    patches = patches, id = "msaa:resolved-field"}
local boundary = grid:line {from = {-0.5, 0.68*(-0.5) + 1.18}, to = {(4.5 - 1.18)/0.68, 4.5},
    stroke = "warning", width = 4, layer = 20, id = "msaa:triangle-edge"}
local selectedFrame = grid:rectangle {center = {selected.x, selected.y}, size = {0.94, 0.94},
    fill = "#00000000", stroke = "focus", width = 4, layer = 30, id = "msaa:selected-pixel"}

local detailCenter, detailSize = {2.45, 0.35}, 2.25
local detail = scene:rectangle {center = detailCenter, size = {detailSize, detailSize},
    fill = hex(resolvedColor(selected.x, selected.y)), stroke = "border", width = 3, layer = 0, id = "msaa:detail"}
local detailEdge = scene:line {
    from = {detailCenter[1] - detailSize/2, detailCenter[2] + detailSize*(0.68*(selected.x - 0.5) + 1.18 - (selected.y - 0.5))/detailSize},
    to = {detailCenter[1] + detailSize/2, detailCenter[2] + detailSize*(0.68*(selected.x + 0.5) + 1.18 - (selected.y - 0.5))/detailSize},
    stroke = "warning", width = 4, layer = 20, id = "msaa:detail-edge",
}
local samplePoints, sampleLabels = {}, {}
for i, offset in ipairs(sampleOffsets) do
    local sampleX = selected.x - 0.5 + offset[1]
    local sampleY = selected.y - 0.5 + offset[2]
    local hit = inside(sampleX, sampleY)
    local point = {detailCenter[1] + (offset[1] - 0.5)*detailSize,
                   detailCenter[2] + (offset[2] - 0.5)*detailSize}
    samplePoints[i] = scene:point {point = point, radius = 9, fill = hit and hex(foreground) or hex(background),
        stroke = "foreground", width = 2, layer = 30, id = "msaa:sample:" .. i}
    sampleLabels[i] = scene:text {text = tostring(i), point = {point[1] + 0.16, point[2] + 0.16}, role = "code",
        fill = "foreground", align = {0, 0.5}, layer = 40, id = "msaa:sample-label:" .. i}
end
local output = scene:rectangle {center = {2.45, -1.82}, size = {0.78, 0.78},
    fill = hex(resolvedColor(selected.x, selected.y)), stroke = "result", width = 3, id = "msaa:output"}
local title = scene:text {text = "4× MSAA: four samples resolve to one pixel", point = {0, 2.82},
    role = "h2", fill = "foreground", id = "msaa:title"}
local subtitle = scene:text {text = "coverage is evaluated at fixed subpixel positions along the same primitive edge", point = {0, 2.43},
    role = "text", fill = "muted", id = "msaa:subtitle"}
local labels = {
    scene:text {text = "resolved framebuffer", point = {-2.55, 1.92}, role = "code", fill = "foreground", id = "msaa:grid-label"},
    scene:text {text = string.format("pixel (%d,%d) · %d/4 covered", selected.x, selected.y, selected.covered),
        point = {detailCenter[1], 1.82}, role = "code", fill = "focus", id = "msaa:detail-label"},
    scene:text {text = "resolve = (C₀ + C₁ + C₂ + C₃) / 4", point = {detailCenter[1], -1.22},
        role = "code", fill = "result", id = "msaa:formula"},
    scene:text {text = string.format("stored %s", hex(resolvedColor(selected.x, selected.y)):upper()),
        point = {detailCenter[1], -2.48}, role = "code", fill = "result", id = "msaa:result"},
}

scene:fade_in(title, {shift = {0, -0.08}, duration = 0.40, curve = "gentle"})
scene:fade_in(subtitle, {duration = 0.28, curve = "gentle"})
scene:create(pixels, 0.64, "ease_out")
scene:create(boundary, 0.58, "ease_out")
scene:fade_in(labels[1], {duration = 0.24, curve = "gentle"})
scene:create(selectedFrame, 0.28, "ease_out")
scene:draw_border_then_fill(detail, 0.48, "ease_out")
scene:create(detailEdge, 0.32, "ease_out")
scene:fade_in(labels[2], {duration = 0.26, curve = "gentle"})
for i = 1, #samplePoints do
    scene:grow_from_center(samplePoints[i], 0.18, "ease_out")
    scene:fade_in(sampleLabels[i], {duration = 0.12, curve = "gentle"})
end
scene:fade_in(labels[3], {duration = 0.34, curve = "gentle"})
scene:draw_border_then_fill(output, 0.38, "ease_out")
scene:fade_in(labels[4], {duration = 0.28, curve = "gentle"})
scene:wait(1.6)
return scene
