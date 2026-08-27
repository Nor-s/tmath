local palette = {
    background = "#0b111a",
    panel_a = "#101925",
    panel_b = "#0f1722",
    grid = "#263447",
    axis = "#66758a",
    text = "#f4f7fb",
    muted = "#94a3b8",
    a = "#4cc9f0",
    b = "#f72585",
    result = "#ffd166",
    relation = "#7bd88f",
    residual = "#ff6b6b",
}

local function make_2d_panel(background, index, title)
    local panel = tmath.scene {
        width = 480,
        height = 270,
        fps = 30,
        background = background,
        camera = { mode = "fixed", view = "2d", target = { 0, 0 }, height = 6.4 },
    }
    local space = panel:space {
        x = { -5.3, 5.3, 1 },
        y = { -2.05, 2.05, 1 },
        color = palette.grid,
        axis_x = palette.axis,
        axis_y = palette.axis,
    }
    local step = space:text {
        text = index,
        point = { -5.02, 2.72 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 14,
        fill = palette.muted,
    }
    local heading = space:text {
        text = title,
        point = { -4.30, 2.72 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 19,
        fill = palette.text,
    }
    return panel, space, { step, heading }
end

local function make_3d_panel(background, index, title)
    local panel = tmath.scene {
        width = 480,
        height = 270,
        fps = 30,
        background = background,
        camera = {
            mode = "fixed",
            view = "3d",
            eye = { 6, 5, 7 },
            target = { 0, 0.2, 0 },
            up = { 0, 1, 0 },
            projection = "orthographic",
            height = 6.4,
            near = 0.1,
            far = 100,
        },
    }
    local space = panel:space {
        x = { -2.25, 2.25, 1 },
        y = { -2.25, 2.25, 1 },
        z = { -2.25, 2.25, 1 },
        color = palette.grid,
        axis_x = palette.axis,
        axis_y = palette.axis,
        axis_z = palette.axis,
    }
    local step = space:text {
        text = index,
        point = { -4.55, 2.45, 1.7 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 13,
        fill = palette.muted,
    }
    local heading = space:text {
        text = title,
        point = { -3.72, 2.45, 1.7 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 18,
        fill = palette.text,
    }
    return panel, space, { step, heading }
end

local function label_2d(space, text, x, color)
    return space:text {
        text = text,
        point = { x, -2.62 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 15,
        fill = color,
    }
end

local function begin_panel(panel, space, heading)
    panel:create(space, 0.38, "ease_out")
    panel:create(heading, 0.24, "ease_out", 0.04)
end

local dot2d, dot2d_space, dot2d_heading =
    make_2d_panel(palette.panel_a, "01", "2D dot · projection")
local dot2d_a = dot2d_space:vector {
    value = { 2, 3 },
    color = palette.a,
    width = 5,
    tip = 14,
}
local dot2d_b = dot2d_space:vector {
    value = { 2, 1 },
    color = palette.b,
    width = 4,
    tip = 13,
}
local dot2d_projection = dot2d_space:vector {
    value = { 2.8, 1.4 },
    color = palette.relation,
    width = 4,
    tip = 13,
}
local dot2d_residual = dot2d_space:line {
    from = { 2.8, 1.4 },
    to = { 2, 3 },
    color = palette.residual,
    width = 3,
}
local dot2d_projection_name = dot2d_space:text {
    text = "projection",
    point = { 2.72, 1.05 },
    font = "Pretendard",
    size = 16,
    fill = palette.relation,
}
local dot2d_residual_name = dot2d_space:text {
    text = "perpendicular residual",
    point = { 3.18, 1.82 },
    font = "Pretendard",
    size = 14,
    fill = palette.residual,
}
begin_panel(dot2d, dot2d_space, dot2d_heading)
dot2d:create({ dot2d_a, dot2d_b }, 0.62, "ease_out", 0.08)
dot2d:create({
    label_2d(dot2d_space, "a = (2, 3)", -5.02, palette.a),
    label_2d(dot2d_space, "b = (2, 1)", -3.12, palette.b),
}, 0.30, "ease_out", 0.04)
dot2d:create({ dot2d_projection, dot2d_residual }, 0.58, "ease_out", 0.08)
dot2d:create({ dot2d_projection_name, dot2d_residual_name }, 0.28, "ease_out", 0.04)
dot2d:create(label_2d(dot2d_space, "a · b = 7", 1.20, palette.result), 0.34, "ease_out")
dot2d:wait(0.55)

local cross2d, cross2d_space, cross2d_heading =
    make_2d_panel(palette.panel_b, "02", "2D cross · signed area")
local cross2d_a = cross2d_space:vector {
    value = { 3, 1 },
    color = palette.a,
    width = 5,
    tip = 14,
}
local cross2d_b = cross2d_space:vector {
    value = { 1, 2 },
    color = palette.b,
    width = 4,
    tip = 13,
}
local cross2d_area = cross2d_space:polygon {
    points = { { 0, 0 }, { 3, 1 }, { 4, 3 }, { 1, 2 } },
    fill = "#7bd88f3f",
    stroke = palette.relation,
    width = 2,
}
local cross2d_area_name = cross2d_space:text {
    text = "oriented parallelogram",
    point = { 2.38, 1.88 },
    font = "Pretendard",
    size = 14,
    fill = palette.relation,
}
begin_panel(cross2d, cross2d_space, cross2d_heading)
cross2d:create({ cross2d_a, cross2d_b }, 0.62, "ease_out", 0.08)
cross2d:create({
    label_2d(cross2d_space, "a = (3, 1)", -5.02, palette.a),
    label_2d(cross2d_space, "b = (1, 2)", -3.12, palette.b),
}, 0.30, "ease_out", 0.04)
cross2d:create(cross2d_area, 0.58, "ease_out")
cross2d:create(cross2d_area_name, 0.28, "ease_out")
cross2d:create(label_2d(cross2d_space, "det(a, b) = +5", 0.72, palette.relation), 0.34, "ease_out")
cross2d:wait(0.55)

local dot3d, dot3d_space, dot3d_heading =
    make_3d_panel(palette.panel_b, "03", "3D dot · projection")
local dot3d_a = dot3d_space:vector {
    value = { 2, 2, 2 },
    color = palette.a,
    width = 5,
    tip = 14,
}
local dot3d_b = dot3d_space:vector {
    value = { 2, 0, 1 },
    color = palette.b,
    width = 4,
    tip = 13,
}
local dot3d_projection = dot3d_space:vector {
    value = { 2.4, 0, 1.2 },
    color = palette.relation,
    width = 4,
    tip = 13,
}
local dot3d_residual = dot3d_space:line {
    from = { 2.4, 0, 1.2 },
    to = { 2, 2, 2 },
    color = palette.residual,
    width = 3,
}
local dot3d_a_name = dot3d_space:text {
    text = "a",
    point = { 2.12, 2.2, 2.05 },
    font = "Pretendard",
    size = 16,
    fill = palette.a,
}
local dot3d_b_name = dot3d_space:text {
    text = "b",
    point = { 2.18, 0.15, 1.0 },
    font = "Pretendard",
    size = 16,
    fill = palette.b,
}
local dot3d_result = dot3d_space:text {
    text = "a · b = 6",
    point = { -4.05, -2.25, 1.7 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 17,
    fill = palette.result,
}
begin_panel(dot3d, dot3d_space, dot3d_heading)
dot3d:create({ dot3d_a, dot3d_b }, 0.62, "ease_out", 0.08)
dot3d:create({ dot3d_a_name, dot3d_b_name }, 0.30, "ease_out", 0.04)
dot3d:create({ dot3d_projection, dot3d_residual }, 0.58, "ease_out", 0.08)
dot3d:wait(0.28)
dot3d:create(dot3d_result, 0.34, "ease_out")
dot3d:wait(0.55)

local cross3d, cross3d_space, cross3d_heading =
    make_3d_panel(palette.panel_a, "04", "3D cross · perpendicular")
local cross3d_a = cross3d_space:vector {
    value = { 1.4, 0.7, 0 },
    color = palette.a,
    width = 5,
    tip = 14,
}
local cross3d_b = cross3d_space:vector {
    value = { 0, 0.7, 1.4 },
    color = palette.b,
    width = 4,
    tip = 13,
}
local cross3d_plane = cross3d_space:polygon {
    points = { { 0, 0, 0 }, { 1.4, 0.7, 0 }, { 1.4, 1.4, 1.4 }, { 0, 0.7, 1.4 } },
    fill = "#7bd88f35",
    stroke = palette.relation,
    width = 2,
}
local cross3d_result = cross3d_space:vector {
    value = { 0.98, -1.96, 0.98 },
    color = palette.result,
    width = 5,
    tip = 15,
}
local cross3d_a_name = cross3d_space:text {
    text = "a",
    point = { 1.55, 0.85, 0 },
    font = "Pretendard",
    size = 16,
    fill = palette.a,
}
local cross3d_b_name = cross3d_space:text {
    text = "b",
    point = { 0, 0.9, 1.55 },
    font = "Pretendard",
    size = 16,
    fill = palette.b,
}
local cross3d_plane_name = cross3d_space:text {
    text = "span(a, b)",
    point = { 0.55, 1.35, 0.72 },
    font = "Pretendard",
    size = 14,
    fill = palette.relation,
}
local cross3d_formula = cross3d_space:text {
    text = "a × b = (0.98, -1.96, 0.98)",
    point = { -4.05, -2.25, 1.7 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 16,
    fill = palette.result,
}
begin_panel(cross3d, cross3d_space, cross3d_heading)
cross3d:create({ cross3d_a, cross3d_b }, 0.62, "ease_out", 0.08)
cross3d:create({ cross3d_a_name, cross3d_b_name }, 0.30, "ease_out", 0.04)
cross3d:create(cross3d_plane, 0.58, "ease_out")
cross3d:create(cross3d_plane_name, 0.28, "ease_out")
cross3d:create({ cross3d_result, cross3d_formula }, 0.34, "ease_out", 0.04)
cross3d:wait(0.55)

local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    background = palette.background,
    camera = { mode = "fixed", view = "2d", height = 6 },
}
scene:viewport(dot2d, { x = 0, y = 0, width = 0.5, height = 0.5 })
scene:viewport(cross2d, { x = 0.5, y = 0, width = 0.5, height = 0.5 })
scene:viewport(dot3d, { x = 0, y = 0.5, width = 0.5, height = 0.5 })
scene:viewport(cross3d, { x = 0.5, y = 0.5, width = 0.5, height = 0.5 })
return scene
