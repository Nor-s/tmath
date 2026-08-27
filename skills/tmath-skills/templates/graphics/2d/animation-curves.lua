-- Compare equal-distance motion under preset and custom animation curves.
local function presetValue(name, t)
    if name == "gentle" then return t^3 * (t * (t * 6 - 15) + 10) end
    if name == "snappy" then return 1 - (1 - t)^4 end
    if name == "back" then
        local c1, c3 = 1.70158, 2.70158
        return 1 + c3 * (t - 1)^3 + c1 * (t - 1)^2
    end
    if name == "bounce" then
        local n, d = 7.5625, 2.75
        if t < 1 / d then return n * t^2 end
        if t < 2 / d then t = t - 1.5 / d; return n * t^2 + 0.75 end
        if t < 2.5 / d then t = t - 2.25 / d; return n * t^2 + 0.9375 end
        t = t - 2.625 / d; return n * t^2 + 0.984375
    end
    if name == "elastic" and t ~= 0 and t ~= 1 then
        return 2^(-10 * t) * math.sin((10 * t - 0.75) * 2.09439510239) + 1
    end
    return t
end

-- Invert cubic Bézier x numerically, then evaluate y at the same parameter.
local function cubic(t, a, b)
    local u = 1 - t
    return 3 * u^2 * t * a + 3 * u * t^2 * b + t^3
end
local function bezierValue(t, curve)
    local low, high = 0, 1
    for _ = 1, 18 do
        local middle = (low + high) * 0.5
        if cubic(middle, curve[1], curve[3]) < t then low = middle else high = middle end
    end
    return cubic((low + high) * 0.5, curve[2], curve[4])
end
local startX, endX = -1.9, 1.9
local function curveValue(config, t)
    local value = config.bezier and bezierValue(t, config.bezier) or presetValue(config.name, t)
    return t + (value - t) * config.strength
end
local function curveSpec(config)
    return config.bezier
        and {bezier = config.bezier, strength = config.strength}
        or {preset = config.name, strength = config.strength}
end
local function curvePoints(config)
    local points = {}
    for i = 0, 48 do
        local t = i / 48
        local value = curveValue(config, t)
        points[#points + 1] = {startX + (endX - startX) * t, -2.1 + 0.95 * value}
    end
    return points
end
local function compactNumber(value)
    if value == math.floor(value) then return string.format("%d", value) end
    if math.abs(value) < 1 then
        return (value < 0 and "-." or ".") .. string.format("%02d", math.floor(math.abs(value) * 100 + 0.5))
    end
    return string.format("%.2f", value)
end
local function detailText(config)
    if not config.bezier then return string.format("strength %.2f", config.strength) end
    local c = config.bezier
    return "(" .. compactNumber(c[1]) .. "," .. compactNumber(c[2]) .. "," .. compactNumber(c[3]) .. "," .. compactNumber(c[4]) .. ")"
end

local configs = {
    {name = "gentle", strength = 0.65, color = "accent"},
    {name = "snappy", strength = 1.00, color = "secondary"},
    {name = "back", strength = 1.45, color = "danger"},
    {name = "bounce", strength = 1.00, color = "warning"},
    {name = "elastic", strength = 0.80, color = "success"},
    {name = "custom", strength = 1.00, bezier = {0.18, 0.90, 0.28, 1.00}, color = "info"},
}

-- Each child owns one curve so all six shifts share the root clock but not easing.
local function panel(config, index)
    local scene = tmath.scene {
        width = 320, height = 270, fps = 60, loop = false,
        camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 7.2},
    }
    local detail = detailText(config)
    scene:text {id = "curve-name-" .. index, text = config.name, point = {-3.25, 2.5}, role = "code", fill = config.color, align = {0, 0.5}, layer = 40}
    scene:text {id = "curve-detail-" .. index, text = detail, point = {3.25, 2.5}, role = "code", fill = "muted", align = {1, 0.5}, layer = 40}
    scene:line {id = "curve-track-" .. index, from = {startX, 0.35}, to = {endX, 0.35}, stroke = "border", width = 3, layer = 0}
    scene:line {id = "curve-stop-" .. index, from = {endX, 0.04}, to = {endX, 0.66}, stroke = config.color, width = 2, layer = 10}

    local subject = scene:group {id = "curve-subject-" .. index}
    subject:circle {id = "curve-body-" .. index, center = {startX, 0.35}, radius = 0.42, fill = config.color, stroke = config.color, opacity = 0.28, width = 4, layer = 20}
    subject:text {id = "curve-t-" .. index, text = "t", point = {startX, 0.35}, role = "code", fill = "foreground", layer = 40}

    -- The graph and moving subject are driven by the same preset, strength, or Bézier.
    scene:line {from = {startX, -2.1}, to = {endX, -2.1}, stroke = "border", width = 1, layer = 0}
    scene:line {from = {startX, -2.1}, to = {startX, -1.05}, stroke = "border", width = 1, layer = 0}
    local graph = scene:plot {id = "curve-graph-" .. index, points = curvePoints(config), stroke = config.color, width = 3, layer = 10}
    local curve = curveSpec(config)

    scene:create(graph, 0.6, "ease_out")
    scene:wait(0.2)
    scene:shift(subject, {endX - startX, 0}, 1.8, curve)
    scene:wait(0.8)
    return scene
end

-- A 3x2 gallery keeps each comparison large enough for a section-level figure.
local page = tmath.scene {width = 960, height = 540, fps = 60, loop = false}
for index, config in ipairs(configs) do
    local column, row = (index - 1) % 3, math.floor((index - 1) / 3)
    page:viewport(panel(config, index), {x = column / 3, y = row / 2, width = 1 / 3, height = 1 / 2})
end
return page
