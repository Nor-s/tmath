local p = {
    paper = "#f7f8fb",
    ink = "#182033",
    muted = "#687086",
    blue = "#2563eb",
    x = "#ef4444",
    y = "#16a34a",
    z = "#2563eb",
}
local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 60,
    background = p.paper,
    camera = {
        mode = "fixed",
        view = "3d",
        eye = { 5.8, 4.6, 6.2 },
        target = { 0, 0, 0 },
        up = { 0, 1, 0 },
        projection = "perspective",
        fov = 0.68,
        near = 0.1,
        far = 100,
    },
}
scene:text {
    text = "3D CAMERA ILLUSION",
    point = { -3.8, 3.05, 0 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 25,
    fill = p.ink,
}
scene:text {
    text = "the object is still; only the view orbits",
    point = { -3.77, 2.58, 0 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 12,
    fill = p.muted,
}
local axes = {
    scene:arrow { from = { -2.6, 0, 0 }, to = { 2.6, 0, 0 }, stroke = p.x, width = 3, tip = 10 },
    scene:arrow { from = { 0, -2.6, 0 }, to = { 0, 2.6, 0 }, stroke = p.y, width = 3, tip = 10 },
    scene:arrow { from = { 0, 0, -2.6 }, to = { 0, 0, 2.6 }, stroke = p.z, width = 3, tip = 10 },
}
local circle_points = {}
for sample = 0, 96 do
    local a = 2 * math.pi * sample / 96
    circle_points[#circle_points + 1] = { 2 * math.cos(a), 0, 2 * math.sin(a) }
end
local circle =
    scene:plot { points = circle_points, stroke = p.blue, width = 6, id = "fixed-circle" }
local normal = scene:vector {
    origin = { 0, 0, 0 },
    value = { 0, 1.8, 0 },
    stroke = "#f59e0b",
    width = 4,
    tip = 13,
    id = "normal",
}
scene:create(axes, 0.4, "ease_out", 0)
scene:create(circle, 0.8, "ease_out")
scene:create(normal, 0.35, "ease_out")
for _, eye in ipairs {
    { -5.8, 4.6, 6.2 },
    { -5.8, 4.6, -6.2 },
    { 5.8, 4.6, -6.2 },
    { 5.8, 4.6, 6.2 },
} do
    scene:look({
        view = "3d",
        eye = eye,
        target = { 0, 0, 0 },
        up = { 0, 1, 0 },
        projection = "perspective",
        fov = 0.68,
        near = 0.1,
        far = 100,
    }, 0.65, "linear")
end
scene:wait(0.7)
return scene
