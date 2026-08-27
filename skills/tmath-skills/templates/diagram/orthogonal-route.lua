-- A marker-ended SVG polyline becomes one marker-aware tmath Route.
-- Replace these authored coordinates only after node bounds and route corridors are final.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = { mode = "fixed", view = "2d", target = { 0, 0 }, height = 540 },
}

local nodes = scene:group { id = "nodes" }
local function node(id, title, center)
    local group = nodes:group { id = id }
    group:rectangle {
        center = center, size = { 130, 62 }, corner = 10, fill = "surface", stroke = "border",
        width = 1.25, layer = 20, id = id .. "-body",
    }
    group:text {
        text = title, point = center, role = "text", layer = 30, id = id .. "-label",
    }
end
node("source", "Source", { -350, 100 })
node("target", "Target", { 350, -100 })

local route = scene:route {
    points = {
        { -285, 100 },
        { 0, 100 },
        { 0, -100 },
        { 285, -100 },
    },
    dash = { 12, 8 },
    tip = 18,
    stroke = "accent",
    width = 5,
    layer = 10,
    id = "route-source-target",
}

scene:fade_in(nodes, { duration = 0.6, curve = "ease_out" })
scene:create(route, 1.2, "ease_out", 0, "forward")
scene:play({ target = route, dash_offset = -20 }, 1.2, "linear")
scene:wait(2.2)
return scene
