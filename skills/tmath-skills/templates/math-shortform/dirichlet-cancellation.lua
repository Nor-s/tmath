-- Symmetric signed sinc lobes reveal cancellation toward the Dirichlet integral.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.6},
}

local pi, lobeSamples = math.pi, 28
local function sinc(x) return math.abs(x) < 1e-9 and 1 or math.sin(x) / x end
local plane = scene:space {
    id = "dirichlet-plane", x = {-4 * pi, 4 * pi, pi}, y = {-0.3, 1.08, 0.25}, numbers = false,
    stroke = "border", axis_x = "border", axis_y = "border", width = 1.1,
    matrix = {0.41, 0, 0, 0, 0, 2.35, 0, -0.38, 0, 0, 1, 0, 0, 0, 0, 1},
}
local curvePoints = {}
for i = 0, 320 do
    local x = -4 * pi + 8 * pi * i / 320
    curvePoints[#curvePoints + 1] = {x, sinc(x)}
end
local curve = plane:plot {id = "dirichlet-sinc", points = curvePoints, stroke = "foreground", width = 3.5, layer = 20}

-- Each zero-to-zero interval owns one non-self-intersecting signed region.
local lobes = {}
for k = -4, 3 do
    local x0, x1, points = k * pi, (k + 1) * pi, {{k * pi, 0}}
    for i = 0, lobeSamples do
        local x = x0 + (x1 - x0) * i / lobeSamples
        points[#points + 1] = {x, sinc(x)}
    end
    points[#points + 1] = {x1, 0}
    local positive = sinc((x0 + x1) * 0.5) >= 0
    lobes[k] = plane:polygon {
        id = "dirichlet-lobe-" .. (k + 4), points = points,
        fill = positive and "result" or "secondary", stroke = positive and "result" or "secondary",
        opacity = 0.42, width = 1.5, layer = 5,
    }
end

scene:create(plane, 0.45, "ease_out")
scene:create(curve, 1.0, "linear")
scene:wait(0.35)
local pairs = {{-1, 0}, {-2, 1}, {-3, 2}, {-4, 3}}
for index, pair in ipairs(pairs) do
    scene:draw_border_then_fill({lobes[pair[1]], lobes[pair[2]]}, index == 1 and 0.5 or 0.34, "ease_out", 0.04)
    scene:wait(index == 1 and 0.42 or 0.22)
end

local conclusion = scene:text {
    id = "dirichlet-conclusion", text = "∫(-∞,∞)  sin(x) / x  dx  =  π",
    point = {0, 2.72}, role = "code", fill = "result", align = {0.5, 0.5}, layer = 40,
}
scene:fade_in(conclusion, {shift = {0, -0.08}, duration = 0.45, curve = "gentle"})
scene:wait(2.0)
return scene
