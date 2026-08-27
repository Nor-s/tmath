local p = {
    background = "#09111b",
    panel_a = "#101b29",
    panel_b = "#0d1825",
    rule = "#26384e",
    text = "#f4f7fb",
    muted = "#91a1b5",
    cyan = "#4cc9f0",
    magenta = "#f72585",
    gold = "#ffd166",
}

local function contour(scene, color, id)
    return scene:path {
        commands = {
            { type = "move", to = { -1.10, -0.30 } },
            {
                type = "cubic",
                control1 = { -1.05, 0.95 },
                control2 = { -0.25, 1.25 },
                to = { 0.15, 0.55 },
            },
            {
                type = "quadratic",
                control = { 0.85, -0.35 },
                to = { 1.10, 0.35 },
            },
            { type = "line", to = { 0.78, -0.88 } },
            {
                type = "quadratic",
                control = { -0.10, -1.18 },
                to = { -1.10, -0.30 },
            },
            { type = "close" },
        },
        samples = 36,
        fill = color .. "42",
        stroke = color,
        width = 5,
        id = id,
    }
end

local function timeline(scene, split, color, left, right, caption)
    local start_x = -1.30
    local end_x = 1.30
    local division = start_x + (end_x - start_x) * split
    scene:line { from = { start_x, -1.52 }, to = { end_x, -1.52 }, stroke = p.rule, width = 6 }
    scene:line {
        from = { start_x, -1.52 },
        to = { division - 0.03, -1.52 },
        stroke = color,
        width = 6,
    }
    scene:line {
        from = { division + 0.03, -1.52 },
        to = { end_x, -1.52 },
        stroke = color .. "88",
        width = 6,
    }
    scene:text {
        text = left,
        point = { (start_x + division) * 0.5, -1.78 },
        font = "Pretendard",
        size = 9,
        fill = color,
    }
    scene:text {
        text = right,
        point = { (division + end_x) * 0.5, -1.78 },
        font = "Pretendard",
        size = 9,
        fill = color,
    }
    scene:text {
        text = caption,
        point = { 0, -2.20 },
        font = "Pretendard",
        size = 10,
        fill = p.muted,
    }
end

local function panel(index, title, color, background, id)
    local scene = tmath.scene {
        width = 320,
        height = 410,
        fps = 60,
        background = background,
        camera = { mode = "fixed", view = "2d", target = { 0, 0 }, height = 5.2 },
    }
    scene:rectangle {
        center = { 0, 0 },
        size = { 3.72, 4.78 },
        corner = 0.16,
        fill = "#00000000",
        stroke = p.rule,
        width = 2,
        layer = -2,
        id = id .. "-frame",
    }
    scene:text {
        text = index,
        point = { -1.48, 2.14 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 11,
        fill = color,
        id = id .. "-index",
    }
    scene:text {
        text = title,
        point = { 0, 2.14 },
        font = "Pretendard",
        size = 12,
        fill = p.text,
        id = id .. "-title",
    }
    scene:line {
        from = { -1.48, 1.78 },
        to = { 1.48, 1.78 },
        stroke = p.rule,
        width = 1.5,
        id = id .. "-rule",
    }
    return scene
end

local explicit = panel("01", "MANUAL SEQUENCE", p.cyan, p.panel_a, "explicit")
local explicit_path = contour(explicit, p.cyan, "explicit-path")
timeline(explicit, 0.52, p.cyan, "DRAW", "FILL", "create  >  pause  >  fill_reveal")
explicit:wait(0.35)
explicit:create(explicit_path, 0.58, "linear")
explicit:wait(0.16)
explicit:fill_reveal(explicit_path, 0.66, "ease_out")
explicit:wait(0.65)

local combined = panel("02", "COMBINED PHASES", p.magenta, p.panel_b, "combined")
local combined_path = contour(combined, p.magenta, "combined-path")
timeline(combined, 2 / 3, p.magenta, "2/3 BORDER", "1/3 FILL", "draw_border_then_fill · one clip")
combined:wait(0.35)
combined:draw_border_then_fill(combined_path, 1.40, "ease_in_out")
combined:wait(0.65)

local curved = panel("03", "DIRECTION + CURVE", p.gold, p.panel_a, "curved")
local curved_path = contour(curved, p.gold, "curved-path")
timeline(curved, 2 / 3, p.gold, "CLOCKWISE", "FILL", "snappy curve · strength 0.90")
curved:point {
    point = { -1.10, -0.30 },
    fill = p.gold,
    radius = 5,
    layer = 5,
    id = "direction-start",
}
curved:text {
    text = "CW",
    point = { -1.46, -0.06 },
    font = "Pretendard",
    size = 10,
    fill = p.gold,
    id = "direction-label",
}
curved:wait(0.35)
curved:draw_border_then_fill(
    curved_path,
    1.40,
    { preset = "snappy", strength = 0.90 },
    0,
    "clockwise"
)
curved:wait(0.65)

local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 60,
    background = p.background,
    loop = false,
    camera = { mode = "fixed", view = "2d", target = { 0, 0 }, height = 7 },
}
scene:text {
    text = "PATH TO FILL · SIDE BY SIDE",
    point = { -5.70, 2.95 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 27,
    fill = p.text,
    id = "title",
}
scene:text {
    text = "same contour · same start time · three timing models",
    point = { -5.68, 2.47 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = p.muted,
    id = "subtitle",
}
scene:line { from = { -5.70, 2.13 }, to = { 5.70, 2.13 }, stroke = p.rule, width = 2, id = "divider" }
scene:viewport(explicit, { x = 0, y = 0.245, width = 1 / 3, height = 0.755 })
scene:viewport(combined, { x = 1 / 3, y = 0.245, width = 1 / 3, height = 0.755 })
scene:viewport(curved, { x = 2 / 3, y = 0.245, width = 1 / 3, height = 0.755 })
return scene
