local scene = tmath.scene {
    width = 1280,
    height = 720,
    camera = {
        mode = "interactive",
        view = "3d",
        eye = { 6, 5, 7 },
        target = { 0, 0, 0 },
        up = { 0, 1, 0 },
        projection = "perspective",
        fov = 0.8,
        near = 0.1,
        far = 100,
    },
}

local space = scene:space {
    x = { -3, 3, 1 },
    y = { -3, 3, 1 },
    z = { -3, 3, 1 },
    id = "space",
}
local objects = {
    space,
    space:vector { value = { 2.5, 0, 0 }, color = "#ef5350", width = 4 },
    space:vector { value = { 0, 2.5, 0 }, color = "#66bb6a", width = 4 },
    space:vector { value = { 0, 0, 2.5 }, color = "#42a5f5", width = 4 },
}

local points = {
    { -1, -1, -1 },
    { 1, -1, -1 },
    { 1, 1, -1 },
    { -1, 1, -1 },
    { -1, -1, 1 },
    { 1, -1, 1 },
    { 1, 1, 1 },
    { -1, 1, 1 },
}
local edges = {
    { 1, 2 },
    { 2, 3 },
    { 3, 4 },
    { 4, 1 },
    { 5, 6 },
    { 6, 7 },
    { 7, 8 },
    { 8, 5 },
    { 1, 5 },
    { 2, 6 },
    { 3, 7 },
    { 4, 8 },
}
for _, edge in ipairs(edges) do
    objects[#objects + 1] = space:line {
        from = points[edge[1]],
        to = points[edge[2]],
        color = "#ffd166",
        width = 3,
    }
end

local diagonal = space:vector {
    value = { 1, 1, 1 },
    color = "#f72585",
    width = 5,
    id = "cube-diagonal",
}
objects[#objects + 1] = diagonal

scene:create(objects, 1.5, "smooth", 0.025)
scene:wait(0.4)
scene:transform(diagonal, {
    0.7071,
    0,
    0.7071,
    0,
    0,
    1,
    0,
    0,
    -0.7071,
    0,
    0.7071,
    0,
    0,
    0,
    0,
    1,
}, 2, "ease_in_out")
scene:wait(0.5)

return scene
