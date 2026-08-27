local palette = {
    background = "#0b111a",
    panel_a = "#101925",
    panel_b = "#0f1722",
    grid = "#263447",
    axis = "#66758a",
    text = "#f4f7fb",
    muted = "#94a3b8",
    cosine = "#4cc9f0",
    sine = "#f72585",
    tangent = "#ffd166",
    warning = "#ff6b6b",
}

local pi = 3.141592653589793
local two_pi = 2 * pi
local theta_final = 0.85
local steps = 36
local step_duration = 0.065

local function graph_transform(x, y)
    return {
        1,
        0,
        0,
        x,
        0,
        y,
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
end

local function x_component_at(origin_x, value)
    return {
        value,
        0,
        0,
        origin_x,
        0,
        1,
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
end

local function y_component_at(origin_x, value)
    return {
        1,
        0,
        0,
        origin_x,
        0,
        value,
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
end

local function rotation_at(x, y, angle)
    local c = math.cos(angle)
    local s = math.sin(angle)
    return {
        c,
        -s,
        0,
        x,
        s,
        c,
        0,
        y,
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

local circle_panel = tmath.scene {
    width = 480,
    height = 270,
    fps = 30,
    background = palette.panel_a,
    camera = { mode = "fixed", view = "2d", target = { 0, 0 }, height = 3.8 },
}
local circle_space = circle_panel:space {
    x = { -3, 3, 1 },
    y = { -1.6, 1.6, 0.5 },
    progress = 0,
}
local center_x = -1.45
local circle = circle_space:circle {
    center = { center_x, 0 },
    radius = 1,
    stroke = palette.text,
    width = 3,
}
local x_axis = circle_space:line {
    from = { -2.75, 0 },
    to = { -0.15, 0 },
    color = palette.axis,
    width = 2,
}
local y_axis = circle_space:line {
    from = { center_x, -1.35 },
    to = { center_x, 1.35 },
    color = palette.axis,
    width = 2,
}
local tangent_axis = circle_space:line {
    from = { center_x + 1, -1.35 },
    to = { center_x + 1, 1.35 },
    color = "#ffd16666",
    width = 2,
}
local circle_heading = circle_space:text {
    text = "UNIT CIRCLE",
    point = { -2.78, 1.58 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 14,
    fill = palette.muted,
}
local cos_legend = circle_space:text {
    text = "cos θ  ->  x",
    point = { 0.05, 0.72 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 17,
    fill = palette.cosine,
}
local sin_legend = circle_space:text {
    text = "sin θ  ->  y",
    point = { 0.05, 0.32 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 17,
    fill = palette.sine,
}
local tan_legend = circle_space:text {
    text = "tan θ  ->  tangent",
    point = { 0.05, -0.08 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 17,
    fill = palette.tangent,
}

local motion = circle_space:space {
    x = { -0.1, 0.1, 0.1 },
    y = { -0.1, 0.1, 0.1 },
    progress = 0,
    matrix = rotation_at(center_x, 0, 0),
}
local radius = motion:vector {
    value = { 1, 0 },
    color = palette.text,
    width = 4,
    tip = 12,
}
local circle_marker = motion:point {
    point = { 1, 0 },
    fill = palette.text,
    radius = 6,
    layer = 5,
}
local cos_track = circle_space:space {
    x = { -0.1, 0.1, 0.1 },
    y = { -0.1, 0.1, 0.1 },
    progress = 0,
    matrix = x_component_at(center_x, 1),
}
local cos_component = cos_track:vector {
    value = { 1, 0 },
    color = palette.cosine,
    width = 5,
    tip = 11,
}
local sin_track = circle_space:space {
    x = { -0.1, 0.1, 0.1 },
    y = { -0.1, 0.1, 0.1 },
    progress = 0,
    matrix = y_component_at(center_x + 1, 0),
}
local sin_component = sin_track:vector {
    value = { 0, 1 },
    color = palette.sine,
    width = 5,
    tip = 11,
}
local tangent_track = circle_space:space {
    x = { -0.1, 0.1, 0.1 },
    y = { -0.1, 0.1, 0.1 },
    progress = 0,
    matrix = y_component_at(center_x + 1, 0),
}
local tangent_value = tangent_track:vector {
    value = { 0, 1 },
    color = palette.tangent,
    width = 4,
    tip = 11,
}
local tangent_ray_track = circle_space:space {
    x = { -0.1, 0.1, 0.1 },
    y = { -0.1, 0.1, 0.1 },
    progress = 0,
    matrix = graph_transform(center_x, 0),
}
local tangent_ray = tangent_ray_track:line {
    from = { 0, 0 },
    to = { 1, 1 },
    color = "#ffd166aa",
    width = 2,
}

local arc_points = {}
for i = 0, 24 do
    local theta = theta_final * i / 24
    arc_points[#arc_points + 1] = {
        center_x + 0.28 * math.cos(theta),
        0.28 * math.sin(theta),
    }
end
local angle_arc = circle_space:plot {
    points = arc_points,
    color = palette.muted,
    width = 2,
}
local theta_label = circle_space:text {
    text = "θ = 0.85 rad",
    point = { 0.05, -0.62 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 16,
    fill = palette.text,
}
local value_label = circle_space:text {
    text = "P = (0.660, 0.751)",
    point = { 0.05, -1.02 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 15,
    fill = palette.text,
}

circle_panel:create(
    { circle, x_axis, y_axis, tangent_axis, circle_heading, cos_legend, sin_legend, tan_legend },
    0.50,
    "ease_out"
)
circle_panel:create(
    { radius, circle_marker, cos_component, sin_component, tangent_value, tangent_ray },
    0.28,
    "ease_out"
)
for i = 1, steps do
    local theta = theta_final * i / steps
    local c = math.cos(theta)
    local s = math.sin(theta)
    local t = math.tan(theta)
    circle_panel:play({
        { target = motion, transform = rotation_at(center_x, 0, theta) },
        { target = cos_track, transform = x_component_at(center_x, c) },
        { target = sin_track, transform = y_component_at(center_x + c, s) },
        { target = tangent_track, transform = y_component_at(center_x + 1, t) },
        { target = tangent_ray_track, transform = graph_transform(center_x, t) },
    }, step_duration, "linear", 0)
end
circle_panel:create({ angle_arc, theta_label, value_label }, 0.38, "ease_out", 0.05)
circle_panel:wait(0.45)

local function wave_panel(name, result_text, color, fn, background)
    local panel = tmath.scene {
        width = 480,
        height = 270,
        fps = 30,
        background = background,
        camera = { mode = "fixed", view = "2d", target = { pi, 0 }, height = 3.8 },
    }
    local space = panel:space {
        x = { 0, two_pi, pi / 2 },
        y = { -1.4, 1.4, 0.5 },
        color = palette.grid,
        axis_x = palette.axis,
        axis_y = palette.axis,
    }
    local curve = space:plot {
        fn = fn,
        x_range = { 0, two_pi, 0.035 },
        color = color,
        width = 4,
    }
    local heading = space:text {
        text = name,
        point = { 0.12, 1.62 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 19,
        fill = color,
    }
    local zero = space:text {
        text = "0",
        point = { 0, -1.62 },
        font = "Pretendard",
        size = 13,
        fill = palette.muted,
    }
    local half_pi = space:text {
        text = "π/2",
        point = { pi / 2, -1.62 },
        font = "Pretendard",
        size = 13,
        fill = palette.muted,
    }
    local pi_label = space:text {
        text = "π",
        point = { pi, -1.62 },
        font = "Pretendard",
        size = 13,
        fill = palette.muted,
    }
    local three_half_pi = space:text {
        text = "3π/2",
        point = { 3 * pi / 2, -1.62 },
        font = "Pretendard",
        size = 13,
        fill = palette.muted,
    }
    local two_pi_label = space:text {
        text = "2π",
        point = { two_pi, -1.62 },
        font = "Pretendard",
        size = 13,
        fill = palette.muted,
    }
    local cursor = space:space {
        x = { -0.1, 0.1, 0.1 },
        y = { -0.1, 0.1, 0.1 },
        progress = 0,
        matrix = graph_transform(0, fn(0)),
    }
    local guide = cursor:line {
        from = { 0, 0 },
        to = { 0, 1 },
        color = color,
        width = 3,
    }
    local marker = cursor:point {
        point = { 0, 1 },
        fill = color,
        radius = 6,
        layer = 5,
    }
    local value = space:text {
        text = result_text,
        point = { 4.08, 1.62 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 15,
        fill = color,
    }

    panel:create(
        { space, curve, heading, zero, half_pi, pi_label, three_half_pi, two_pi_label },
        0.50,
        "ease_out"
    )
    panel:create({ guide, marker }, 0.28, "ease_out")
    for i = 1, steps do
        local theta = theta_final * i / steps
        panel:transform(cursor, graph_transform(theta, fn(theta)), step_duration, "linear")
    end
    panel:create(value, 0.38, "ease_out")
    panel:wait(0.45)
    return panel
end

local sine_panel =
    wave_panel("y = sin θ", "sin(0.85) = 0.751", palette.sine, math.sin, palette.panel_b)
local cosine_panel =
    wave_panel("y = cos θ", "cos(0.85) = 0.660", palette.cosine, math.cos, palette.panel_b)

local tangent_panel = tmath.scene {
    width = 480,
    height = 270,
    fps = 30,
    background = palette.panel_a,
    camera = { mode = "fixed", view = "2d", target = { 1.55 * pi, 0 }, height = 6.4 },
}
local tangent_space = tangent_panel:space {
    x = { 0, two_pi, pi / 2 },
    y = { -2.8, 2.8, 1 },
    matrix = {
        1.55,
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
        0,
        0,
        0,
        0,
        1,
    },
    color = palette.grid,
    axis_x = palette.axis,
    axis_y = palette.axis,
}
local tan_limit = 1.2490457723982544
local function tan_segment(from, to)
    local points = {}
    for i = 0, 44 do
        local x = from + (to - from) * i / 44
        points[#points + 1] = { x, math.tan(x) }
    end
    return tangent_space:plot { points = points, color = palette.tangent, width = 4 }
end
local tan_a = tan_segment(0, tan_limit)
local tan_b = tan_segment(pi - tan_limit, pi + tan_limit)
local tan_c = tan_segment(two_pi - tan_limit, two_pi)
local asymptote_a = tangent_space:line {
    from = { pi / 2, -2.8 },
    to = { pi / 2, 2.8 },
    color = "#ff6b6b77",
    width = 2,
}
local asymptote_b = tangent_space:line {
    from = { 3 * pi / 2, -2.8 },
    to = { 3 * pi / 2, 2.8 },
    color = "#ff6b6b77",
    width = 2,
}
local tan_name = tangent_space:text {
    text = "tan θ",
    point = { 0.08, 2.95 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 18,
    fill = palette.tangent,
}
local equals = tangent_space:text {
    text = "=",
    point = { 1.10, 2.95 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 18,
    fill = palette.text,
}
local sin_name = tangent_space:text {
    text = "sin θ",
    point = { 1.52, 2.95 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 18,
    fill = palette.sine,
}
local divide = tangent_space:text {
    text = "/",
    point = { 2.58, 2.95 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 18,
    fill = palette.text,
}
local cos_name = tangent_space:text {
    text = "cos θ",
    point = { 2.90, 2.95 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 18,
    fill = palette.cosine,
}
local tangent_note = tangent_space:text {
    text = "undefined at π/2 + kπ",
    point = { 3.72, 2.48 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 11,
    fill = palette.warning,
}
local tangent_cursor = tangent_space:space {
    x = { -0.1, 0.1, 0.1 },
    y = { -0.1, 0.1, 0.1 },
    progress = 0,
    matrix = graph_transform(0, 0),
}
local tangent_guide = tangent_cursor:line {
    from = { 0, 0 },
    to = { 0, 1 },
    color = palette.tangent,
    width = 3,
}
local tangent_marker = tangent_cursor:point {
    point = { 0, 1 },
    fill = palette.tangent,
    radius = 6,
    layer = 5,
}
local tangent_value_text = tangent_space:text {
    text = "tan(0.85) = 1.138",
    point = { 0.08, -2.38 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 16,
    fill = palette.tangent,
}
tangent_panel:create({
    tangent_space,
    tan_a,
    tan_b,
    tan_c,
    asymptote_a,
    asymptote_b,
    tan_name,
    equals,
    sin_name,
    divide,
    cos_name,
    tangent_note,
}, 0.50, "ease_out")
tangent_panel:create({ tangent_guide, tangent_marker }, 0.28, "ease_out")
for i = 1, steps do
    local theta = theta_final * i / steps
    tangent_panel:transform(
        tangent_cursor,
        graph_transform(theta, math.tan(theta)),
        step_duration,
        "linear"
    )
end
tangent_panel:create(tangent_value_text, 0.38, "ease_out")
tangent_panel:wait(0.45)

local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    background = palette.background,
    camera = { mode = "fixed", view = "2d", height = 6 },
}
scene:viewport(circle_panel, { x = 0, y = 0, width = 0.5, height = 0.5 })
scene:viewport(sine_panel, { x = 0.5, y = 0, width = 0.5, height = 0.5 })
scene:viewport(cosine_panel, { x = 0, y = 0.5, width = 0.5, height = 0.5 })
scene:viewport(tangent_panel, { x = 0.5, y = 0.5, width = 0.5, height = 0.5 })
return scene
