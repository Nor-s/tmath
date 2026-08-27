local p = {
    paper = "#f7f8fb",
    ink = "#182033",
    muted = "#687086",
    grid = "#dce2ed",
    blue = "#2563eb",
    orange = "#f97316",
}
local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 60,
    background = p.paper,
    camera = { mode = "fixed", view = "2d", height = 7 },
}
scene:rectangle {
    center = { 0, 2.58 },
    size = { 12.5, 1.85 },
    fill = p.paper,
    stroke = "#00000000",
    layer = 18,
    id = "fixed-header",
}
scene:text {
    text = "FOLLOWING GRAPH CAMERA",
    point = { -5.7, 2.62 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 27,
    fill = p.ink,
    layer = 20,
}
scene:text {
    text = "the camera frame stays locked to a moving sample",
    point = { -5.68, 2.10 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = p.muted,
    layer = 20,
}
local world = scene:group { id = "moving-camera-world" }
local grid = world:space {
    x = { -1, 10, 1 },
    y = { -2, 2, 0.5 },
    color = p.grid,
    axis_x = p.ink,
    axis_y = p.ink,
    numbers = false,
    id = "axes",
}
local sample_count = 120
local points = {}
for sample = 0, sample_count do
    local x = 3 * math.pi * sample / sample_count
    points[#points + 1] = { x, math.sin(x) }
end
local graph = grid:plot { points = points, stroke = p.blue, width = 4, id = "sine-path" }
grid:point { point = { 0, 0 }, fill = p.ink, radius = 4, id = "start" }
grid:point { point = { 3 * math.pi, 0 }, fill = p.ink, radius = 4, id = "end" }
local focus = scene:point {
    point = { 0, -0.15 },
    fill = p.orange,
    stroke = p.paper,
    width = 3,
    radius = 9,
    layer = 10,
    id = "camera-focus",
}
local frame = scene:rectangle {
    center = { 0, -0.15 },
    size = { 4.0, 2.35 },
    corner = 0.08,
    fill = "#00000000",
    stroke = p.orange .. "88",
    width = 2,
    layer = 9,
    id = "camera-frame",
}
local function camera_matrix(point)
    local scale = 1.65
    return {
        scale,
        0,
        0,
        -scale * point[1],
        0,
        scale,
        0,
        -0.15 - scale * point[2],
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        1,
    }
end
scene:create(grid, 0.42, "ease_out")
scene:create(graph, 0.75, "ease_out")
scene:grow_from_center(focus, 0.2, "snappy")
scene:create(frame, 0.3, "ease_out")
scene:transform(world, camera_matrix(points[1]), 0.6, "ease_in_out")
for step = 1, sample_count do
    scene:transform(world, camera_matrix(points[step + 1]), 0.025, "linear")
end
scene:transform(
    world,
    { 1, 0, 0, -4.5, 0, 1, 0, -0.15, 0, 0, 1, 0, 0, 0, 0, 1 },
    0.65,
    "ease_in_out"
)
scene:wait(0.8)
return scene
