-- Animatrix-inspired study: a seamless sampled surface, 3D plane text,
-- and a Write animation whose fill follows the traced contour.

local p = {
    paper = "#f7f8fc",
    panel = "#ffffff",
    ink = "#172033",
    muted = "#667085",
    rule = "#dde3ee",
    blue = "#5271e8",
    cyan = "#20b8cd",
    coral = "#ef6461",
    gold = "#f4b942",
}

local page = tmath.scene {
    width = 960,
    height = 540,
    fps = 60,
    loop = false,
    antialiasing = true,
    background = p.paper,
    camera = { mode = "fixed", view = "2d", height = 9 },
}

page:text {
    text = "GEOMETRY THAT EXPLAINS ITSELF",
    point = { -7.15, 3.78 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 25,
    fill = p.ink,
    id = "title",
}
page:text {
    text = "sampled surface  /  spatial type  /  traced fill",
    point = { -7.12, 3.22 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 12,
    fill = p.muted,
    id = "subtitle",
}
page:line {
    from = { -7.15, 2.87 },
    to = { 7.15, 2.87 },
    stroke = p.rule,
    width = 1,
    id = "title-rule",
}

local graph = tmath.scene {
    width = 620,
    height = 390,
    fps = 60,
    background = p.panel,
    camera = {
        mode = "fixed",
        view = "3d",
        eye = { 6.6, 4.8, 7.2 },
        target = { 0, 0, 0 },
        up = { 0, 1, 0 },
        projection = "perspective",
        fov = 0.62,
        near = 0.1,
        far = 100,
    },
}

local axes = {
    graph:arrow {
        from = { -3.55, -1.10, 0 },
        to = { 3.55, -1.10, 0 },
        stroke = p.coral,
        width = 2.5,
        tip = 10,
        id = "axis-x",
    },
    graph:arrow {
        from = { 0, -1.10, -3.35 },
        to = { 0, -1.10, 3.35 },
        stroke = p.cyan,
        width = 2.5,
        tip = 10,
        id = "axis-z",
    },
    graph:arrow {
        from = { 0, -1.10, 0 },
        to = { 0, 1.75, 0 },
        stroke = p.gold,
        width = 2.5,
        tip = 10,
        id = "axis-y",
    },
}

local columns, rows = 29, 23
local points = {}
for row = 0, rows - 1 do
    local z = -3 + 6 * row / (rows - 1)
    for column = 0, columns - 1 do
        local x = -3 + 6 * column / (columns - 1)
        local radial = math.exp(-0.055 * (x * x + z * z))
        local y = 0.82 * math.sin(x) * math.cos(z) * radial
        points[#points + 1] = { x, y, z }
    end
end

local surface = graph:surface {
    points = points,
    size = { columns, rows },
    mode = "solid",
    fill = "#5271e8dc",
    id = "wave-surface",
}

-- Plane text uses world-space font size and follows this XZ-plane transform.
local ground_type = graph:group {
    matrix = {
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        -1.12,
        0,
        -1,
        0,
        -2.75,
        0,
        0,
        0,
        1,
    },
    id = "ground-type-plane",
}
local plane_label = ground_type:text {
    text = "f(x,z) = sin(x) cos(z)",
    point = { 0, 0, 0 },
    align = { 0.5, 0.5 },
    orientation = "plane",
    size = 0.52,
    font = "Pretendard",
    fill = p.ink,
    id = "plane-label",
}
local billboard_label = graph:text {
    text = "surface value",
    point = { 0.55, 1.33, 0.15 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = p.muted,
    id = "billboard-label",
}
local normal = graph:vector {
    origin = { 0.42, 0.29, 0.18 },
    value = { -0.55, 1.15, 0.40 },
    stroke = p.gold,
    width = 4,
    tip = 13,
    layer = 8,
    id = "surface-normal",
}

graph:create(axes, 0.45, "ease_out", 0.06)
graph:create(surface, 1.20, { preset = "gentle", strength = 0.85 })
graph:fade_in(plane_label, {
    shift = { 0, 0.12, 0 },
    duration = 0.42,
    curve = "ease_out",
})
graph:create({ normal, billboard_label }, 0.42, "snappy", 0.08)
graph:look({
    view = "3d",
    eye = { -5.8, 5.2, 6.4 },
    target = { 0, -0.15, 0 },
    up = { 0, 1, 0 },
    projection = "perspective",
    fov = 0.62,
    near = 0.1,
    far = 100,
}, 1.40, "ease_in_out")
graph:wait(0.35)

local writing = tmath.scene {
    width = 300,
    height = 390,
    fps = 60,
    background = p.panel,
    camera = { mode = "fixed", view = "2d", height = 7.8 },
}

writing:text {
    text = "WRITE",
    point = { -2.45, 3.15 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 12,
    fill = p.coral,
    id = "write-eyebrow",
}
writing:text {
    text = "one contour,\none continuous reveal",
    point = { -2.45, 2.57 },
    align = { 0, 0 },
    font = "Pretendard",
    size = 18,
    fill = p.ink,
    id = "write-title",
}

local contour = writing:path {
    commands = {
        { type = "move", to = { -1.70, -0.15 } },
        {
            type = "cubic",
            control1 = { -1.78, 1.18 },
            control2 = { -0.30, 1.62 },
            to = { 0.18, 0.52 },
        },
        {
            type = "cubic",
            control1 = { 0.82, -0.68 },
            control2 = { 1.74, 0.42 },
            to = { 1.58, -0.72 },
        },
        {
            type = "quadratic",
            control = { 0.08, -1.66 },
            to = { -1.70, -0.15 },
        },
        { type = "close" },
    },
    samples = 42,
    fill = "#ef6461b8",
    stroke = p.coral,
    width = 4,
    id = "write-contour",
}
local note = writing:text {
    text = "fill is clipped to the\nalready traced region",
    point = { 0, -2.35 },
    align = { 0.5, 0 },
    font = "Pretendard",
    size = 12,
    fill = p.muted,
    id = "write-note",
}

writing:wait(0.28)
writing:write(contour, 1.85, { preset = "gentle", strength = 0.80 })
writing:fade_in(note, {
    shift = { 0, -0.16 },
    duration = 0.40,
    curve = "ease_out",
})
writing:wait(1.31)

page:viewport(graph, { x = 0.025, y = 0.24, width = 0.64, height = 0.72 })
page:viewport(writing, { x = 0.69, y = 0.24, width = 0.285, height = 0.72 })

return page
