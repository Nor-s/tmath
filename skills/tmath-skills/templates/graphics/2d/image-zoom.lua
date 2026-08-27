-- Generate a portable raster so the crop and zoom stay deterministic.
local columns, rows = 24, 16
local function byte(v) return math.max(0, math.min(255, math.floor(v + 0.5))) end
local function pixelColor(x, y)
    local u, v = x / (columns - 1), y / (rows - 1)
    local glow = math.exp(-12 * ((u - 0.68)^2 + (v - 0.34)^2))
    return string.format("#%02x%02x%02x", byte(28 + 205*u + 35*glow), byte(48 + 150*(1 - v) + 48*glow), byte(118 + 105*v - 62*u))
end
local function buildPixels()
    local result = {}
    for y = 0, rows - 1 do
        for x = 0, columns - 1 do result[#result + 1] = pixelColor(x, y) end
    end
    return result
end

-- Child scenes keep each view's camera independent inside the split figure.
local childHeight, cameraHeight = 540, 6.4
local sourceWidth, zoomWidth = 576, 384
local function child(width)
    return tmath.scene {
        width = width, height = childHeight, fps = 30, loop = false,
        camera = {mode = "fixed", view = "2d", target = {0, 0}, height = cameraHeight},
    }
end
local pixels = buildPixels()
local first, second, scale = {-1.45, 0.7}, {1.25, -0.8}, 4
local delta = {second[1] - first[1], second[2] - first[2]}
local selectionSize = {cameraHeight * zoomWidth / childHeight / scale, cameraHeight / scale}
local source, zoom = child(sourceWidth), child(zoomWidth)

-- The left view moves the selection in image coordinates.
local image = source:image {pixels = pixels, size = {columns, rows}, center = {0, 0}, width = 6.4, filter = "bilinear"}
local selection = source:rectangle {id = "zoom-source-selection", center = first, size = selectionSize, fill = "#00000000", stroke = "focus", width = 4, layer = 40}
source:fade_in(image, {scale = 0.97, duration = 0.4, curve = "ease_out"})
source:create(selection, 0.3, "ease_out")
source:wait(0.45)
source:shift(selection, delta, 1.2, "ease_in_out")
source:wait(0.8)

-- The right view applies the inverse scaled shift, like a camera tracking the crop.
local detail = zoom:image {
    pixels = pixels, size = {columns, rows}, center = {-scale * first[1], -scale * first[2]},
    width = 6.4 * scale, filter = "nearest",
}
zoom:fade_in(detail, {scale = 0.97, duration = 0.4, curve = "ease_out"})
zoom:wait(0.75)
zoom:shift(detail, {-scale * delta[1], -scale * delta[2]}, 1.2, "ease_in_out")
zoom:wait(0.8)

-- Compose the overview and nearest-neighbor detail without adding a title block.
local page = child(960)
page:viewport(source, {x = 0, y = 0, width = 0.6, height = 1})
page:viewport(zoom, {x = 0.6, y = 0, width = 0.4, height = 1})
return page
