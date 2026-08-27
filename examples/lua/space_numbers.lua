local palette = {
    background = "#0b111a",
    panel_a = "#101925",
    panel_b = "#0f1722",
    grid = "#263447",
    axis = "#66758a",
    text = "#f4f7fb",
    muted = "#94a3b8",
    fixed = "#ffd166",
    relative = "#4cc9f0",
    off = "#7bd88f",
    point = "#ff6b6b",
}

local function make_panel(index, title, mode, color, note, background)
    local panel = tmath.scene {
        width = 320,
        height = 540,
        fps = 30,
        background = background,
        camera = { mode = "fixed", view = "2d", target = { 0, 0 }, height = 0.72 },
    }
    local options = {
        x = { 0, 3, 1 },
        y = { 0, 2, 1 },
        z = { 0, 0, 1 },
        numbers = mode ~= "off",
        number_size = 15,
        number_color = color,
        color = palette.grid,
        axis_x = palette.axis,
        axis_y = palette.axis,
        matrix = {
            0.1,
            0,
            0,
            -0.15,
            0,
            0.1,
            0,
            -0.08,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            1,
        },
        id = mode .. "-numbers",
    }
    if mode ~= "off" then
        options.number_mode = mode
    end
    local grid = panel:space(options)
    local sample = grid:point {
        point = { 3, 1 },
        fill = palette.point,
        radius = 6,
        layer = 5,
    }
    local step = panel:text {
        text = index,
        point = { -0.185, 0.292 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 13,
        fill = palette.muted,
    }
    local heading = panel:text {
        text = title,
        point = { -0.132, 0.292 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 19,
        fill = palette.text,
    }
    local transform_note = panel:text {
        text = "M = scale(0.1)",
        point = { -0.185, 0.242 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 14,
        fill = palette.muted,
    }
    local result = panel:text {
        text = note,
        point = { -0.185, -0.265 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 16,
        fill = color,
    }
    local caption = panel:text {
        text = mode == "fixed" and "grid units"
            or (mode == "relative" and "world units" or "labels disabled"),
        point = { -0.185, -0.305 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 13,
        fill = palette.muted,
    }

    panel:create({ step, heading, transform_note }, 0.38, "ease_out", 0.05)
    panel:create(grid, 0.72, "ease_out")
    panel:create(sample, 0.28, "ease_out")
    panel:create({ result, caption }, 0.34, "ease_out", 0.05)
    panel:wait(0.65)
    return panel
end

local fixed = make_panel("01", "FIXED", "fixed", palette.fixed, "1   2   3", palette.panel_a)
local relative =
    make_panel("02", "RELATIVE", "relative", palette.relative, "0.1   0.2   0.3", palette.panel_b)
local off = make_panel("03", "OFF", "off", palette.off, "numbers = false", palette.panel_a)

local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    background = palette.background,
    camera = { mode = "fixed", view = "2d", height = 6 },
}
scene:viewport(fixed, { x = 0, y = 0, width = 1 / 3, height = 1 })
scene:viewport(relative, { x = 1 / 3, y = 0, width = 1 / 3, height = 1 })
scene:viewport(off, { x = 2 / 3, y = 0, width = 1 / 3, height = 1 })
return scene
