-- Use one scalar function as both a 2D field and a lifted 3D surface.
local domain = {min = -2.5, max = 2.5, step = 0.25}
local columns = math.floor((domain.max - domain.min) / domain.step + 0.5) + 1
local rows = columns
local function height(x, z) return 1.9 * math.exp(-(x*x + z*z) / 1.65) - 0.72 end
local function fieldColor(x, y)
    local value = height(x, y)
    if value > 0.85 then return "#f59e0b" end
    if value > 0.3 then return "#8b5cf6" end
    if value > -0.2 then return "#2563eb" end
    return "#0f766e"
end
local function surfacePoints()
    local result = {}
    for row = 0, rows - 1 do
        local z = domain.min + (domain.max - domain.min) * row / (rows - 1)
        for column = 0, columns - 1 do
            local x = domain.min + (domain.max - domain.min) * column / (columns - 1)
            result[#result + 1] = {x, height(x, z), z}
        end
    end
    return result
end

-- Left: quantize height into color bands while retaining the sampled center.
local left = tmath.scene {
    width = 480, height = 540, fps = 30, loop = false,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.4},
}
local space = left:space {x = {domain.min, domain.max, domain.step}, y = {domain.min, domain.max, domain.step}, opacity = 0}
local field = space:cell(fieldColor, {mode = "padd", padding = 0.055})
local sample2d = space:point {point = {0, 0}, radius = 7, fill = "result", layer = 20}
left:create(field, 0.8, "ease_out")
left:grow_from_center(sample2d, 0.3, "gentle")
left:wait(1.2)

-- Right: lift each (x, z) sample to (x, height(x, z), z), then orbit the camera.
local right = tmath.scene {
    width = 480, height = 540, fps = 30, loop = false,
    camera = {mode = "fixed", view = "3d", eye = {8, 6.2, 8.8}, target = {0, 0, 0}, up = {0, 1, 0}, projection = "perspective", fov = 0.68, near = 0.1, far = 100},
}
local points = surfacePoints()
local mesh = right:surface {points = points, size = {columns, rows}, mode = "solid_mesh", shading = false, fill = "#2563eb55", stroke = "#2563ebbb", width = 0.85}
local sample3d = right:point {point = {0, height(0, 0), 0}, radius = 7, fill = "result", layer = 20}
right:create(mesh, 0.9, "gentle")
right:grow_from_center(sample3d, 0.3, "gentle")
right:look({view = "3d", eye = {-7.8, 6.3, 8.7}, target = {0, 0, 0}, up = {0, 1, 0}, projection = "perspective", fov = 0.68, near = 0.1, far = 100}, 1.2, "ease_in_out")
right:wait(0.7)

-- Pair both encodings at equal visual weight.
local page = tmath.scene {width = 960, height = 540, fps = 30, loop = false}
page:viewport(left, {x = 0, y = 0, width = 0.5, height = 1})
page:viewport(right, {x = 0.5, y = 0, width = 0.5, height = 1})
return page
