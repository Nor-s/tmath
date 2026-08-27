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
    related = "#7bd88f",
}

local function make_panel(background, index, title)
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
        point = { -4.32, 2.72 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 19,
        fill = palette.text,
    }
    return panel, space, { step, heading }
end

local function formula(space, text, x, color)
    return space:text {
        text = text,
        point = { x, -2.62 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 15,
        fill = color,
    }
end

local function play_panel(panel, space, heading, operands, operand_labels, relation, conclusion)
    panel:create(space, 0.38, "ease_out")
    panel:create(heading, 0.24, "ease_out", 0.04)
    panel:create(operands, 0.62, "ease_out", 0.08)
    panel:create(operand_labels, 0.30, "ease_out", 0.05)
    panel:create(relation, 0.62, "ease_out", 0.06)
    panel:create(conclusion, 0.34, "ease_out")
    panel:wait(0.55)
end

local add, add_space, add_heading = make_panel(palette.panel_a, "01", "Addition")
local add_a = add_space:vector {
    value = { 2.4, 0.7 },
    color = palette.a,
    width = 4,
    tip = 13,
}
local add_b = add_space:vector {
    origin = { 2.4, 0.7 },
    value = { -0.7, 1.25 },
    color = palette.b,
    width = 4,
    tip = 13,
}
local add_sum = add_space:vector {
    value = { 1.7, 1.95 },
    color = palette.result,
    width = 5,
    tip = 15,
}
local add_a_name = add_space:text {
    text = "a",
    point = { 1.28, 0.08 },
    font = "Pretendard",
    size = 18,
    fill = palette.a,
}
local add_b_name = add_space:text {
    text = "b",
    point = { 2.58, 1.48 },
    font = "Pretendard",
    size = 18,
    fill = palette.b,
}
local add_sum_name = add_space:text {
    text = "a + b",
    point = { 0.48, 1.62 },
    font = "Pretendard",
    size = 17,
    fill = palette.result,
}
play_panel(add, add_space, add_heading, { add_a, add_b }, {
    add_a_name,
    add_b_name,
    formula(add_space, "a = (2.4, 0.7)", -5.02, palette.a),
    formula(add_space, "b = (-0.7, 1.25)", -2.15, palette.b),
}, { add_sum, add_sum_name }, formula(add_space, "a + b = (1.7, 1.95)", 1.20, palette.result))

local subtract, subtract_space, subtract_heading = make_panel(palette.panel_b, "02", "Subtraction")
local subtract_a = subtract_space:vector {
    value = { 2.6, 1.35 },
    color = palette.a,
    width = 4,
    tip = 13,
}
local subtract_neg_b = subtract_space:vector {
    origin = { 2.6, 1.35 },
    value = { -1.0, -2.0 },
    color = palette.b,
    width = 4,
    tip = 13,
}
local subtract_result = subtract_space:vector {
    value = { 1.6, -0.65 },
    color = palette.result,
    width = 5,
    tip = 15,
}
local subtract_a_name = subtract_space:text {
    text = "a",
    point = { 1.35, 0.38 },
    font = "Pretendard",
    size = 18,
    fill = palette.a,
}
local subtract_b_name = subtract_space:text {
    text = "-b",
    point = { 2.42, 0.24 },
    font = "Pretendard",
    size = 18,
    fill = palette.b,
}
local subtract_result_name = subtract_space:text {
    text = "a - b",
    point = { 0.72, -0.82 },
    font = "Pretendard",
    size = 17,
    fill = palette.result,
}
play_panel(
    subtract,
    subtract_space,
    subtract_heading,
    { subtract_a, subtract_neg_b },
    {
        subtract_a_name,
        subtract_b_name,
        formula(subtract_space, "a = (2.6, 1.35)", -5.02, palette.a),
        formula(subtract_space, "-b = (-1, -2)", -1.85, palette.b),
    },
    { subtract_result, subtract_result_name },
    formula(subtract_space, "a - b = (1.6, -0.65)", 1.02, palette.result)
)

local scalar, scalar_space, scalar_heading =
    make_panel(palette.panel_b, "03", "Scalar multiplication")
local scalar_v = scalar_space:vector {
    origin = { -3.8, -0.75 },
    value = { 1.6, 1.0 },
    color = palette.a,
    width = 4,
    tip = 13,
}
local scalar_v_name = scalar_space:text {
    text = "v",
    point = { -2.9, -0.05 },
    font = "Pretendard",
    size = 18,
    fill = palette.a,
}
local scalar_half = scalar_space:vector {
    origin = { -3.8, 0.95 },
    value = { 0.8, 0.5 },
    color = palette.related,
    width = 3,
    tip = 11,
}
local scalar_twice = scalar_space:vector {
    origin = { -0.65, -0.75 },
    value = { 3.2, 2.0 },
    color = palette.result,
    width = 5,
    tip = 15,
}
local scalar_half_name = scalar_space:text {
    text = "0.5v",
    point = { -3.02, 1.55 },
    font = "Pretendard",
    size = 17,
    fill = palette.related,
}
local scalar_twice_name = scalar_space:text {
    text = "2v",
    point = { 1.15, 0.45 },
    font = "Pretendard",
    size = 18,
    fill = palette.result,
}
play_panel(
    scalar,
    scalar_space,
    scalar_heading,
    { scalar_v },
    { scalar_v_name, formula(scalar_space, "v = (1.6, 1.0)", -5.02, palette.a) },
    { scalar_half, scalar_twice, scalar_half_name, scalar_twice_name },
    {
        formula(scalar_space, "0.5v", -2.22, palette.related),
        formula(scalar_space, "2v", -0.92, palette.result),
        formula(scalar_space, "|kv| = |k||v|", 0.22, palette.text),
    }
)

local negate, negate_space, negate_heading =
    make_panel(palette.panel_a, "04", "Negation and cancellation")
local negate_v = negate_space:vector {
    value = { 2.2, 1.25 },
    color = palette.a,
    width = 4,
    tip = 13,
}
local negate_minus_v = negate_space:vector {
    value = { -2.2, -1.25 },
    color = palette.b,
    width = 4,
    tip = 13,
}
local negate_cancel = negate_space:vector {
    origin = { 2.2, 1.25 },
    value = { -2.2, -1.25 },
    color = palette.result,
    width = 3,
    tip = 11,
}
local negate_v_name = negate_space:text {
    text = "v",
    point = { 1.25, 0.35 },
    font = "Pretendard",
    size = 18,
    fill = palette.a,
}
local negate_minus_name = negate_space:text {
    text = "-v",
    point = { -1.35, -0.45 },
    font = "Pretendard",
    size = 18,
    fill = palette.b,
}
local negate_zero = negate_space:point {
    point = { 0, 0 },
    fill = palette.result,
    radius = 6,
    layer = 5,
}
play_panel(negate, negate_space, negate_heading, { negate_v, negate_minus_v }, {
    negate_v_name,
    negate_minus_name,
    formula(negate_space, "v = (2.2, 1.25)", -5.02, palette.a),
    formula(negate_space, "-v = (-2.2, -1.25)", -1.82, palette.b),
}, { negate_cancel, negate_zero }, formula(negate_space, "v + (-v) = 0", 1.48, palette.result))

local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    background = palette.background,
    camera = { mode = "fixed", view = "2d", height = 6 },
}
scene:viewport(add, { x = 0, y = 0, width = 0.5, height = 0.5 })
scene:viewport(subtract, { x = 0.5, y = 0, width = 0.5, height = 0.5 })
scene:viewport(scalar, { x = 0, y = 0.5, width = 0.5, height = 0.5 })
scene:viewport(negate, { x = 0.5, y = 0.5, width = 0.5, height = 0.5 })
return scene
