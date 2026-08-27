-- Construct area below one graph and the bounded area between two graphs.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local function f(x) return 4 * x - x * x end
local function g(x) return 0.8 * x * x - 3 * x + 4 end
local plane = scene:space {
    id = "area-space", x = {0, 4, 1}, y = {0, 5, 1}, numbers = false,
    matrix = {1.9, 0, 0, -3.8, 0, 0.85, 0, -2.125, 0, 0, 1, 0, 0, 0, 0, 1},
    color = "muted", axis_x = "foreground", axis_y = "foreground",
}
local curveRange = {0, 4, 0.04}
local curve_f = plane:plot {id = "area-curve-f", fn = f, x_range = curveRange, stroke = "accent", width = 4, layer = 20}
local curve_g = plane:plot {id = "area-curve-g", fn = g, x_range = curveRange, stroke = "secondary", width = 4, layer = 20}

-- Right-endpoint Riemann rectangles share the exact function and interval data.
local rectangles, a, b, slices = {}, 0.3, 1.5, 8
local dx = (b - a) / slices
for i = 0, slices - 1 do
    local left, right = a + i * dx, a + (i + 1) * dx
    rectangles[#rectangles + 1] = plane:polygon {
        id = "area-rect-" .. i,
        points = {{left, 0}, {right, 0}, {right, f(right)}, {left, f(right)}},
        fill = "accent", stroke = "accent", opacity = 0.28, width = 1.5, layer = 0,
    }
end

-- Aligned samples form a gap-free band between f(x) and g(x).
local band, band_a, band_b, segments = {}, 2, 3, 18
for i = 0, segments - 1 do
    local x0 = band_a + (band_b - band_a) * i / segments
    local x1 = band_a + (band_b - band_a) * (i + 1) / segments
    band[#band + 1] = plane:polygon {
        id = "area-band-" .. i,
        points = {{x0, g(x0)}, {x1, g(x1)}, {x1, f(x1)}, {x0, f(x0)}},
        fill = "result", stroke = "#00000000", opacity = 0.34, width = 0, layer = 0,
    }
end
local bounds = {
    plane:line {id = "area-bound-a", from = {band_a, g(band_a)}, to = {band_a, f(band_a)}, stroke = "result", width = 3, layer = 10},
    plane:line {id = "area-bound-b", from = {band_b, g(band_b)}, to = {band_b, f(band_b)}, stroke = "result", width = 3, layer = 10},
}

-- Curves establish the evidence; sampled area geometry fills afterward.
scene:create(plane, 0.40, "ease_out")
scene:create({curve_f, curve_g}, 0.82, "ease_out", 0)
scene:draw_border_then_fill(rectangles, 0.34, "ease_out", 0.06, "forward")
scene:wait(0.30)
scene:fill_reveal(band, 0.42, "ease_out", 0.025)
scene:create(bounds, 0.30, "ease_out", 0)
scene:wait(1.2)
return scene
