local scene = tmath.scene {
    width = 1280,
    height = 720,
    camera = { mode = "fixed", view = "2d", height = 6 },
}

local space = scene:space {
    x = { -6, 6, 1 },
    y = { -3, 3, 1 },
    axis_x = "#ef5350",
    axis_y = "#66bb6a",
    id = "plane",
}
local forward = space:arrow {
    from = { -3, 1.4 },
    to = { 3, 1.4 },
    tail = 0,
    tip = 18,
    color = "#ef5350",
    width = 5,
    id = "forward",
}
local both = space:arrow {
    from = { -3, 0 },
    to = { 3, 0 },
    tail = 14,
    tip = 20,
    color = "#ffd166",
    width = 5,
    id = "both",
}
local reverse = space:arrow {
    from = { -3, -1.4 },
    to = { 3, -1.4 },
    tail = 18,
    tip = 0,
    color = "#4cc9f0",
    width = 5,
    id = "reverse",
}

scene:create({ space, forward, both, reverse }, 1, "smooth", 0.08)
scene:wait(0.25)
return scene
