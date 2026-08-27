local p = {
    background = "#080d14",
    panel_a = "#0d1622",
    panel_b = "#101a27",
    rule = "#253448",
    text = "#f4f7fb",
    muted = "#8fa1b7",
    cyan = "#4cc9f0",
    violet = "#9b8cff",
    magenta = "#f72585",
    gold = "#ffd166",
    green = "#7bd88f",
    orange = "#ff9f5a",
}

local function preset_value(name, t)
    if name == "gentle" then
        return t * t * t * (t * (t * 6 - 15) + 10)
    end
    if name == "snappy" then
        return 1 - (1 - t) ^ 4
    end
    if name == "back" then
        local c1 = 1.70158
        local c3 = c1 + 1
        return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
    end
    if name == "bounce" then
        local n1, d1 = 7.5625, 2.75
        if t < 1 / d1 then
            return n1 * t * t
        end
        if t < 2 / d1 then
            t = t - 1.5 / d1
            return n1 * t * t + 0.75
        end
        if t < 2.5 / d1 then
            t = t - 2.25 / d1
            return n1 * t * t + 0.9375
        end
        t = t - 2.625 / d1
        return n1 * t * t + 0.984375
    end
    if name == "elastic" then
        if t == 0 or t == 1 then
            return t
        end
        return 2 ^ (-10 * t) * math.sin((t * 10 - 0.75) * 2.09439510239) + 1
    end
    return t
end

local function cubic(value, a, b)
    local inverse = 1 - value
    return 3 * inverse * inverse * value * a + 3 * inverse * value * value * b + value ^ 3
end

local function custom_value(t, bezier)
    local low, high = 0, 1
    for _ = 1, 18 do
        local middle = (low + high) * 0.5
        if cubic(middle, bezier[1], bezier[3]) < t then
            low = middle
        else
            high = middle
        end
    end
    return cubic((low + high) * 0.5, bezier[2], bezier[4])
end

local function curve_points(name, strength, bezier)
    local points = {}
    for i = 0, 60 do
        local t = i / 60
        local value = bezier and custom_value(t, bezier) or preset_value(name, t)
        value = t + (value - t) * strength
        points[#points + 1] = { -2.25 + 4.5 * t, -2.04 + 0.92 * value }
    end
    return points
end

local function panel(index, title, detail, color, curve, graph_name, strength, bezier)
    local scene = tmath.scene {
        width = 320,
        height = 270,
        fps = 60,
        background = index % 2 == 0 and p.panel_b or p.panel_a,
        loop = false,
        camera = { mode = "fixed", view = "2d", target = { 0, 0 }, height = 6.4 },
    }
    scene:text {
        text = string.format("%02d", index),
        point = { -3.42, 2.70 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 10,
        fill = p.muted,
        id = "curve-index-" .. index,
    }
    scene:text {
        text = title,
        point = { -2.78, 2.70 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 17,
        fill = p.text,
        id = "curve-title-" .. index,
    }
    scene:text {
        text = detail,
        point = { 3.35, 2.70 },
        align = { 1, 0.5 },
        font = "Pretendard",
        size = 10,
        fill = color,
        id = "curve-detail-" .. index,
    }
    scene:line {
        from = { -3.42, 2.26 },
        to = { 3.42, 2.26 },
        stroke = p.rule,
        width = 1.4,
        id = "curve-rule-" .. index,
    }

    scene:line {
        from = { -2.25, 0.20 },
        to = { 2.25, 0.20 },
        stroke = p.rule,
        width = 3,
        id = "motion-track-" .. index,
    }
    scene:line {
        from = { 2.25, -0.13 },
        to = { 2.25, 0.53 },
        stroke = color,
        width = 2,
        id = "motion-stop-" .. index,
    }
    scene:text {
        text = "0",
        point = { -2.25, -0.58 },
        font = "Pretendard",
        size = 10,
        fill = p.muted,
        id = "motion-zero-" .. index,
    }
    scene:text {
        text = "1",
        point = { 2.25, -0.58 },
        font = "Pretendard",
        size = 10,
        fill = color,
        id = "motion-one-" .. index,
    }

    local subject = scene:group { id = "curve-subject-" .. index }
    subject:circle {
        center = { -2.25, 0.20 },
        radius = 0.52,
        fill = color .. "33",
        stroke = color,
        width = 4,
        id = "curve-body-" .. index,
    }
    subject:text {
        text = "t",
        point = { -2.25, 0.20 },
        font = "Pretendard",
        size = 18,
        fill = p.text,
        id = "curve-symbol-" .. index,
    }

    scene:line {
        from = { -2.25, -2.04 },
        to = { 2.25, -2.04 },
        stroke = p.rule,
        width = 1,
        id = "graph-x-" .. index,
    }
    scene:line {
        from = { -2.25, -2.04 },
        to = { -2.25, -1.00 },
        stroke = p.rule,
        width = 1,
        id = "graph-y-" .. index,
    }
    local graph = scene:plot {
        points = curve_points(graph_name, strength, bezier),
        stroke = color,
        width = 3,
        id = "curve-graph-" .. index,
    }

    scene:wait(0.30)
    scene:create(graph, 0.65, "ease_out")
    scene:wait(0.20)
    scene:shift(subject, { 4.5, 0 }, 1.80, curve)
    scene:wait(0.45)
    return scene
end

local panels = {
    panel(
        1,
        "GENTLE",
        "strength 0.65",
        p.cyan,
        { preset = "gentle", strength = 0.65 },
        "gentle",
        0.65
    ),
    panel(
        2,
        "SNAPPY",
        "strength 1.00",
        p.violet,
        { preset = "snappy", strength = 1.00 },
        "snappy",
        1.00
    ),
    panel(
        3,
        "BACK",
        "strength 1.45",
        p.magenta,
        { preset = "back", strength = 1.45 },
        "back",
        1.45
    ),
    panel(
        4,
        "BOUNCE",
        "strength 1.00",
        p.gold,
        { preset = "bounce", strength = 1.00 },
        "bounce",
        1.00
    ),
    panel(
        5,
        "ELASTIC",
        "strength 0.80",
        p.green,
        { preset = "elastic", strength = 0.80 },
        "elastic",
        0.80
    ),
    panel(
        6,
        "CUSTOM CUBIC",
        "(.18,.90,.28,1)",
        p.orange,
        { bezier = { 0.18, 0.90, 0.28, 1.00 }, strength = 1.00 },
        "custom",
        1.00,
        { 0.18, 0.90, 0.28, 1.00 }
    ),
}

local gallery = tmath.scene {
    width = 960,
    height = 540,
    fps = 60,
    background = p.background,
    loop = false,
    camera = { mode = "fixed", view = "2d", target = { 0, 0 }, height = 6.4 },
}
for index, scene in ipairs(panels) do
    local column = (index - 1) % 3
    local row = math.floor((index - 1) / 3)
    gallery:viewport(scene, { x = column / 3, y = row / 2, width = 1 / 3, height = 1 / 2 })
end
return gallery
