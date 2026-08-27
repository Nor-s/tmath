local p = {
    paper = "#f7f8fb",
    ink = "#182033",
    muted = "#687086",
    blue = "#2563eb",
    orange = "#f97316",
    rule = "#d8deea",
}

local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 60,
    background = p.paper,
    camera = { mode = "fixed", view = "2d", height = 7.2 },
}

scene:text {
    text = "BRACE ANNOTATION",
    point = { -5.75, 2.75 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 27,
    fill = p.ink,
    id = "title",
}
scene:text {
    text = "one segment, two measured directions",
    point = { -5.72, 2.25 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = p.muted,
}
scene:line { from = { -5.75, 1.92 }, to = { 5.75, 1.92 }, stroke = p.rule, width = 1 }

local a, b = { -3.2, -0.7 }, { 2.9, 1.05 }
local segment = scene:line { from = a, to = b, stroke = p.ink, width = 4, id = "segment" }
local endpoints = {
    scene:point { point = a, fill = p.orange, stroke = p.paper, width = 2, radius = 7 },
    scene:point { point = b, fill = p.orange, stroke = p.paper, width = 2, radius = 7 },
}

local horizontal = scene:path {
    commands = {
        { type = "move", to = { -3.2, -1.25 } },
        {
            type = "cubic",
            control1 = { -2.9, -1.25 },
            control2 = { -2.9, -1.55 },
            to = {
                -2.6,
                -1.55,
            },
        },
        { type = "line", to = { -0.45, -1.55 } },
        {
            type = "cubic",
            control1 = { -0.10, -1.55 },
            control2 = { -0.18, -1.85 },
            to = { -0.02, -1.85 },
        },
        {
            type = "cubic",
            control1 = { 0.14, -1.85 },
            control2 = { 0.06, -1.55 },
            to = {
                0.41,
                -1.55,
            },
        },
        { type = "line", to = { 2.55, -1.55 } },
        {
            type = "cubic",
            control1 = { 2.85, -1.55 },
            control2 = { 2.85, -1.25 },
            to = {
                3.15,
                -1.25,
            },
        },
    },
    samples = 10,
    fill = "#00000000",
    stroke = p.blue,
    width = 4,
    id = "horizontal-brace",
}
local vertical = scene:path {
    commands = {
        { type = "move", to = { 3.65, -0.7 } },
        {
            type = "cubic",
            control1 = { 3.65, -0.5 },
            control2 = { 3.95, -0.5 },
            to = { 3.95, -0.28 },
        },
        { type = "line", to = { 3.95, -0.05 } },
        {
            type = "cubic",
            control1 = { 3.95, 0.18 },
            control2 = { 4.22, 0.05 },
            to = { 4.22, 0.18 },
        },
        {
            type = "cubic",
            control1 = { 4.22, 0.31 },
            control2 = { 3.95, 0.18 },
            to = { 3.95, 0.41 },
        },
        { type = "line", to = { 3.95, 0.66 } },
        {
            type = "cubic",
            control1 = { 3.95, 0.88 },
            control2 = { 3.65, 0.88 },
            to = { 3.65, 1.08 },
        },
    },
    samples = 10,
    fill = "#00000000",
    stroke = p.orange,
    width = 4,
    id = "vertical-brace",
}
local labels = {
    scene:text {
        text = "horizontal distance",
        point = { 0, -2.22 },
        font = "Pretendard",
        size = 16,
        fill = p.blue,
    },
    scene:text {
        text = "y₂ − y₁",
        point = { 4.85, 0.18 },
        font = "Pretendard",
        size = 16,
        fill = p.orange,
    },
}

scene:create(segment, 0.55, "ease_out")
for _, endpoint in ipairs(endpoints) do
    scene:grow_from_center(endpoint, 0.11, "snappy")
end
scene:create({ horizontal, vertical }, 0.75, "ease_out", 0)
scene:fade_in(labels[1], { shift = { 0, 0.16 }, duration = 0.32, curve = "ease_out" })
scene:fade_in(labels[2], { shift = { -0.16, 0 }, duration = 0.32, curve = "ease_out" })
scene:wait(0.8)
return scene
