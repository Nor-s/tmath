local scene = tmath.scene {
    width = 1280,
    height = 720,
    camera = { mode = "interactive", view = "2d", target = { 0, 0 }, height = 8 },
}

local space = scene:space {
    x = { -7, 7, 1 },
    y = { -4, 4, 1 },
    axis_x = "#ef5350",
    axis_y = "#66bb6a",
    id = "plane",
}
local x = space:vector {
    value = { 1, 0 },
    color = "#ef5350",
    width = 4,
    id = "basis-x",
}
local y = space:vector {
    value = { 0, 1 },
    color = "#66bb6a",
    width = 4,
    id = "basis-y",
}
local vector = space:vector {
    value = { 3, 2 },
    color = "#ffd166",
    width = 5,
    id = "vector",
}

scene:create({ space, x, y, vector }, 1.2, "smooth", 0.08)
scene:wait(0.3)

local transform = {
    0.8,
    -0.6,
    0,
    0,
    0.6,
    0.8,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    1,
}
scene:transform(space, transform, 2, "ease_in_out")
scene:wait(0.5)

return scene
