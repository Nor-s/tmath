local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    camera = { mode = "fixed", view = "2d", target = { 0, 0 }, height = 8 },
}

local world = scene:space {
    x = { -4, 4, 1 },
    y = { -3, 3, 1 },
    z = { -3, 3, 1 },
    color = "#34404b",
    id = "world",
}
local square = world:polygon {
    points = { { 0, 0 }, { 2, 0 }, { 2, 2 }, { 0, 2 } },
    fill = "#4cc9f044",
    stroke = "#4cc9f0",
    width = 4,
    id = "square",
}
local x = world:vector {
    value = { 2.4, 0, 0 },
    color = "#ef5350",
    width = 5,
    id = "basis-x",
}
local y = world:vector {
    value = { 0, 2.4, 0 },
    color = "#7bd88f",
    width = 5,
    id = "basis-y",
}
local z = world:vector {
    value = { 0, 0, 2.4 },
    color = "#ffd166",
    width = 5,
    id = "basis-z",
}

scene:create({ world, square, x, y, z }, 0.7, "ease_out", 0.08)
scene:wait(0.35)

scene:look({
    view = "3d",
    eye = { 5.5, 4.2, 6.5 },
    target = { 0, 0, 0 },
    up = { 0, 1, 0 },
    projection = "perspective",
    fov = 0.76101275,
    near = 0.1,
    far = 100,
}, 1.2, "ease_in_out")
scene:wait(0.65)
scene:look({
    view = "2d",
    target = { 0, 0 },
    eye = { 0, 0, 10 },
    up = { 0, 1, 0 },
    projection = "orthographic",
    height = 8,
}, 1.2, "ease_in_out")
scene:wait(0.5)
return scene
