-- Follow one curve sample by moving the complete world beneath a fixed 2D camera overlay.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local samples, follow_until, points = 120, 80, {}
for i = 0, samples do
    local x = 3 * math.pi * i / samples
    points[#points + 1] = {x, math.sin(x)}
end

-- Every world descendant shares the same inverse camera transform.
local anchor, zoom = {0, -0.1}, 1.65
local function view_matrix(point, zoom)
    return {
        zoom, 0, 0, anchor[1] - zoom * point[1],
        0, zoom, 0, anchor[2] - zoom * point[2],
        0, 0, 1, 0,
        0, 0, 0, 1,
    }
end

local world = scene:group {id = "camera-world"}
local plane = world:space {
    id = "camera-space", x = {0, 3 * math.pi, math.pi}, y = {-1.5, 1.5, 0.5},
    color = "muted", axis_x = "foreground", axis_y = "foreground", numbers = false,
}
local graph = plane:plot {id = "camera-graph", points = points, stroke = "result", width = 4, layer = 10}

-- Screen-fixed overlay: it never inherits the world transform.
local frame = scene:rectangle {
    id = "camera-frame", center = anchor, size = {4.0, 2.35}, corner = 0.08,
    fill = "#00000000", stroke = "focus", width = 2, layer = 20,
}
local focus = scene:point {id = "camera-focus", point = anchor, fill = "focus", radius = 8, layer = 30}

scene:create(plane, 0.42, "ease_out")
scene:create(graph, 0.72, "ease_out")
scene:create(frame, 0.28, "ease_out")
scene:grow_from_center(focus, 0.18, "ease_out")

-- Pin the first sample, then advance at uniform parameter speed.
scene:transform(world, view_matrix(points[1], zoom), 0.60, "ease_in_out")
for i = 2, follow_until + 1 do
    scene:transform(world, view_matrix(points[i], zoom), 0.025, "linear")
end
scene:wait(1.0)
return scene
