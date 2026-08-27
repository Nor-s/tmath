-- A monotone curve partitions the moving u × v rectangle into complementary integrals.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.8},
}

local samples = 32
local function f(u) return 0.35 + 0.5 * u end
local plane = scene:space {
    id = "parts-plane", x = {0, 3.4, 0.5}, y = {0, 2.15, 0.5}, numbers = false,
    stroke = "border", axis_x = "border", axis_y = "border", width = 1.1,
    matrix = {2.15, 0, 0, -3.72, 0, 2.15, 0, -1.72, 0, 0, 1, 0, 0, 0, 0, 1},
}
local curvePoints = {}
for i = 0, 80 do
    local u = 3.35 * i / 80
    curvePoints[#curvePoints + 1] = {u, f(u)}
end
local curve = plane:plot {id = "parts-curve", points = curvePoints, stroke = "foreground", width = 3.5, layer = 20}

local function geometry(index, u)
    local v = f(u)
    local lower, upper = {{0, 0}, {u, 0}}, {{0, v}, {u, v}}
    for i = samples, 0, -1 do
        local x = u * i / samples
        lower[#lower + 1] = {x, f(x)}
        upper[#upper + 1] = {x, f(x)}
    end
    return {
        lower = plane:polygon {id = "parts-lower-" .. index, points = lower, fill = "accent", stroke = "accent", opacity = 0.34, width = 1.5, layer = 5},
        upper = plane:polygon {id = "parts-upper-" .. index, points = upper, fill = "secondary", stroke = "secondary", opacity = 0.34, width = 1.5, layer = 5},
        box = plane:polygon {id = "parts-box-" .. index, points = {{0, 0}, {u, 0}, {u, v}, {0, v}}, fill = "#00000000", stroke = "result", width = 3, layer = 15},
        point = plane:polygon {id = "parts-point-" .. index, points = {{u - 0.04, v}, {u, v + 0.04}, {u + 0.04, v}, {u, v - 0.04}}, fill = "result", stroke = "result", layer = 30},
    }
end
local function members(g) return {g.lower, g.upper, g.box, g.point} end

scene:create(plane, 0.45, "ease_out")
scene:create(curve, 0.8, "ease_out")
local live = geometry(1, 1.05)
scene:draw_border_then_fill({live.lower, live.upper}, 0.55, "ease_out", 0.05)
scene:create({live.box, live.point}, 0.38, "ease_out", 0.04)
scene:wait(0.45)

for index, u in ipairs({2.05, 3.12}) do
    local target = geometry(index + 1, u)
    scene:morph(members(live), members(target), 1.05, "ease_in_out", 0)
    live = target
    scene:wait(0.48)
end

-- Formula terms inherit the same identities as the two visible area partitions.
local formula = {
    scene:text {id = "parts-term-vdu", text = "∫ v du", point = {-3.15, 2.72}, role = "code", fill = "accent", align = {0.5, 0.5}, layer = 40},
    scene:text {id = "parts-plus", text = "+", point = {-1.72, 2.72}, role = "code", fill = "foreground", align = {0.5, 0.5}, layer = 40},
    scene:text {id = "parts-term-udv", text = "∫ u dv", point = {-0.35, 2.72}, role = "code", fill = "secondary", align = {0.5, 0.5}, layer = 40},
    scene:text {id = "parts-equals", text = "=", point = {1.13, 2.72}, role = "code", fill = "foreground", align = {0.5, 0.5}, layer = 40},
    scene:text {id = "parts-product", text = "uv", point = {2.25, 2.72}, role = "code", fill = "result", align = {0.5, 0.5}, layer = 40},
}
scene:create(formula, 0.32, "ease_out", 0.08)
scene:wait(2.0)
return scene
