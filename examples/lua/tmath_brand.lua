local accent, rule, ink = "#9b3600", "#d8dadd", "#202124"
local cycle, total, tau = 4, 8, 2 * math.pi

local function scene2d(height)
    return tmath.scene {
        width = 500,
        height = 300,
        fps = 30,
        theme = "pro_white",
        camera = { mode = "fixed", view = "2d", height = height or 5 },
    }
end

local function panel(title, content, note)
    local frame = tmath.scene {
        width = 480,
        height = 344,
        fps = 30,
        theme = "pro_white",
        camera = { mode = "fixed", view = "2d", height = 6 },
    }
    frame:rectangle {
        center = { 0, 0 },
        size = { 8.1, 5.82 },
        corner = 0.08,
        fill = "#ffffff00",
        stroke = rule,
        width = 1,
    }
    frame:text {
        text = title,
        point = { -3.78, 2.48 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 15,
        role = "h3",
    }
    if note then
        frame:text {
            text = note,
            point = { 3.78, 2.48 },
            align = { 1, 0.5 },
            font = "Pretendard",
            size = 12,
            role = "code",
            fill = accent,
        }
    end
    frame:line { from = { -3.78, 2.08 }, to = { 3.78, 2.08 }, stroke = rule, width = 1 }
    frame:viewport(content, { x = 0.03, y = 0.18, width = 0.94, height = 0.78 })
    return frame
end

local function pulse(time)
    if time <= 0 or time >= total then
        return 0
    end
    return 0.5 - 0.5 * math.cos(tau * (time % cycle) / cycle)
end

local function mix(a, b, amount)
    local function channel(color, offset)
        return tonumber(string.sub(color, offset, offset + 1), 16)
    end
    local function hex(value)
        return string.format("%02x", math.floor(value + 0.5))
    end
    return "#"
        .. hex(channel(a, 2) + (channel(b, 2) - channel(a, 2)) * amount)
        .. hex(channel(a, 4) + (channel(b, 4) - channel(a, 4)) * amount)
        .. hex(channel(a, 6) + (channel(b, 6) - channel(a, 6)) * amount)
end

local show = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    theme = "pro_white",
    camera = { mode = "fixed", view = "2d", height = 9 },
}
local show_root = show:group { id = "angular-parameterization" }
local show_scale = 7.35 / 8.58954
local function st(seconds)
    return seconds * show_scale
end
local p = {
    paper = "#ffffff",
    ink = "#202124",
    muted = "#555b64",
    accent = "#9b3600",
    blue = "#5e7a9b",
    mustard = "#b8915a",
    purple = "#6e6479",
    orange = "#f28e2b",
}
local function show_text(value, point, size, color, id, align)
    return show_root:text {
        text = value,
        point = point,
        size = size,
        font = "Pretendard",
        fill = color or p.ink,
        id = id,
        align = align or { 0.5, 0.5 },
    }
end
local center = { -3.65, -0.55 }
local palette = { p.purple, p.blue, p.mustard, p.orange, p.purple }
local sectors, n = {}, 32
for i = 0, n - 1 do
    local phase, a0 = i / n * 4, -tau * i / n
    local k = math.min(4, math.floor(phase) + 1)
    local a1 = -tau * (i + 1) / n - 0.004
    local color = mix(palette[k], palette[k + 1], phase - math.floor(phase))
    sectors[#sectors + 1] = show_root:polygon {
        points = {
            center,
            { center[1] + 2.35 * math.cos(a0), center[2] + 2.35 * math.sin(a0) },
            { center[1] + 2.35 * math.cos(a1), center[2] + 2.35 * math.sin(a1) },
        },
        fill = color,
        stroke = color,
        width = 1,
    }
end
local hole = show_root:circle {
    center = center,
    radius = 1.25,
    fill = p.paper,
    stroke = p.paper,
    width = 1,
    layer = 5,
    id = "ring-hole",
}
local cpoint =
    show_root:point { point = center, fill = p.ink, radius = 6, layer = 7, id = "center" }
show:create(sectors, st(0.82), "ease_out", 0.012)
show:grow_from_center(hole, st(0.30), "ease_out")
show:fade_in(cpoint, { scale = 0.6, duration = st(0.25), easing = "ease_out" })
show:create(show_text("center", { -4.15, -0.55 }, 12, p.ink), st(0.22), "ease_out")
local seam = show_root:arrow {
    from = center,
    to = { -1.0, -0.55 },
    tip = 14,
    color = p.accent,
    width = 3,
    id = "seam",
}
show:create(seam, st(0.62), "ease_out")
show:create(
    show_text("seam / t = 0", { -0.78, -0.55 }, 12, p.accent, nil, { 0, 0.5 }),
    st(0.28),
    "ease_out"
)
local vector = show_root:arrow {
    from = center,
    to = { -1.60, -0.55 },
    tip = 14,
    color = p.ink,
    width = 3,
    id = "angle-vector",
}
show:create(vector, st(0.35), "linear")
local angle = -0.82
local c, s = math.cos(angle), math.sin(angle)
local tx, ty = center[1] - c * center[1] + s * center[2], center[2] - s * center[1] - c * center[2]
show:transform(
    vector,
    { c, -s, 0, tx, s, c, 0, ty, 0, 0, 1, 0, 0, 0, 0, 1 },
    st(1.25),
    "ease_in_out"
)
local vend, arcpts = { center[1] + 2.05 * c, center[2] + 2.05 * s }, {}
for i = 0, 24 do
    local a = angle * i / 24
    arcpts[#arcpts + 1] = { center[1] + 0.72 * math.cos(a), center[2] + 0.72 * math.sin(a) }
end
local arc = show_root:plot { points = arcpts, color = p.ink, width = 2, id = "theta-arc" }
local angular_sample =
    show_root:point { point = vend, fill = p.ink, radius = 6, id = "angular-sample" }
show:create(arc, st(0.52), "linear")
show:fade_in(angular_sample, { scale = 0.6, duration = st(0.25), easing = "ease_out" })
show:create(show_text("atan2f(ry, rx)", { -2.55, -1.10 }, 12, p.ink), st(0.25), "ease_out")
local formulas = {
    show_text("offset = -angle / 360", { 3.65, 1.38 }, 13, p.muted),
    show_text("t = atan2f(ry, rx) x (0.5 / pi) + offset", { 3.65, 0.92 }, 13, p.ink),
    show_text("t = t - floorf(t)", { 3.65, 0.42 }, 15, p.accent),
}
show:create(formulas, st(0.62), "ease_out", 0.10)
local table_cells, celln, start = {}, 12, 0.95
for i = 0, celln - 1 do
    local phase = i / (celln - 1) * 4
    local k = math.min(4, math.floor(phase) + 1)
    local color = mix(palette[k], palette[k + 1], phase - math.floor(phase))
    table_cells[#table_cells + 1] = show_root:rectangle {
        center = { start + i * 0.50, -0.72 },
        size = { 0.48, 0.62 },
        fill = color,
        stroke = p.paper,
        width = 1,
        id = "ctable-" .. i,
    }
end
show:create(table_cells, st(0.62), "ease_out", 0.025)
show:create(show_text("ctable[0 ... N-1]", { 3.70, -0.20 }, 12, p.muted), st(0.25), "ease_out")
local chosen = 10
local target = { start + chosen * 0.50, -0.72 }
local selected_phase = chosen / (celln - 1) * 4
local selected_k = math.min(4, math.floor(selected_phase) + 1)
local selected_color =
    mix(palette[selected_k], palette[selected_k + 1], selected_phase - math.floor(selected_phase))
local sample_points, cell_points, copy_count = {}, {}, 24
for i = 0, copy_count - 1 do
    local a = tau * i / copy_count
    local dx, dy = math.cos(a), math.sin(a)
    sample_points[#sample_points + 1] = { vend[1] + 0.10 * dx, vend[2] + 0.10 * dy }
    local sx = math.abs(dx) > 0.0001 and 0.24 / math.abs(dx) or 1000
    local sy = math.abs(dy) > 0.0001 and 0.31 / math.abs(dy) or 1000
    local scale = math.min(sx, sy)
    cell_points[#cell_points + 1] = { target[1] + scale * dx, target[2] + scale * dy }
end
local sample_copy = show_root:polygon {
    points = sample_points,
    fill = p.ink,
    stroke = p.ink,
    width = 1,
    id = "lookup-copy-source",
}
local lookup_copy = show_root:polygon {
    points = cell_points,
    fill = selected_color,
    stroke = p.paper,
    width = 1,
    id = "lookup-copy-target",
}
show:replacement_transform(sample_copy, lookup_copy, st(0.75), "ease_in_out")
local selector = show_root:rectangle {
    center = target,
    size = { 0.54, 0.76 },
    fill = "#ffffff00",
    stroke = p.accent,
    width = 3,
    id = "table-selector",
}
show:create(selector, st(0.34), "ease_out")
show:create(
    show_text("index = round((N - 1) x t)", { 3.70, -1.42 }, 14, p.accent),
    st(0.30),
    "ease_out"
)
show:wait(0.25)
show:fade_out(show_root, { duration = 0.40, curve = "ease_in_out" })

local sphere = tmath.scene {
    width = 500,
    height = 300,
    fps = 30,
    theme = "pro_white",
    camera = {
        mode = "fixed",
        view = "3d",
        eye = { 7.2 * math.cos(0.85), 3.8, 7.2 * math.sin(0.85) },
        target = { 0, 0, 0 },
        up = { 0, 1, 0 },
        projection = "perspective",
        fov = 0.68,
        near = 0.1,
        far = 100,
    },
}
local sphere_space = sphere:space {
    x = { -2.3, 2.3, 6 },
    y = { -2.3, 2.3, 6 },
    z = { -2.3, 2.3, 6 },
    color = "#00000000",
    axis_x = rule,
    axis_y = rule,
    axis_z = rule,
    id = "sphere-space",
}
local globe = sphere_space:group { id = "sphere-wireframe" }
local r = 1.65
for latitude = -2, 2 do
    local phi, points = latitude * math.pi / 6, {}
    for i = 0, 48 do
        local theta = tau * i / 48
        points[#points + 1] = {
            r * math.cos(phi) * math.cos(theta),
            r * math.sin(phi),
            r * math.cos(phi) * math.sin(theta),
        }
    end
    globe:plot { points = points, stroke = ink .. "a0", width = 1.3 }
end
for longitude = 0, 7 do
    local theta, points = math.pi * longitude / 8, {}
    for i = 0, 48 do
        local phi = -math.pi / 2 + math.pi * i / 48
        points[#points + 1] = {
            r * math.cos(phi) * math.cos(theta),
            r * math.sin(phi),
            r * math.cos(phi) * math.sin(theta),
        }
    end
    globe:plot { points = points, stroke = ink .. "80", width = 1.2 }
end
local sample = { 0.95, 0.95, 0.95 }
sphere_space:vector { value = sample, stroke = accent, width = 2.5, tip = 10, id = "sphere-radius" }
sphere_space:point { point = sample, fill = accent, radius = 5, id = "sphere-sample" }
for step = 1, 16 do
    local a = tau * step / 8
    sphere:look({
        view = "3d",
        eye = { 7.2 * math.cos(a + 0.85), 3.8, 7.2 * math.sin(a + 0.85) },
        target = { 0, 0, 0 },
        up = { 0, 1, 0 },
        projection = "perspective",
        fov = 0.68,
        near = 0.1,
        far = 100,
    }, cycle / 8, "linear")
end

local cells = scene2d(4.6)
local cell_space = cells:space {
    x = { -3.4, 3.4, 0.22 },
    y = { -1.8, 1.8, 0.22 },
    axis_x = rule,
    axis_y = rule,
    color = rule,
    id = "cell-space",
}
cell_space:cell(function(x, y, time)
    local phase = pulse(time)
    local a, b = 1.15 + 0.85 * phase, 1.15 - 0.28 * phase
    return x * x / (a * a) + y * y / (b * b) <= 1 and ink .. "d8" or "#00000000"
end, { mode = "padd", padding = 0.08, duration = total, fps = 15 })

local voxels = tmath.scene {
    width = 500,
    height = 300,
    fps = 30,
    theme = "pro_white",
    camera = {
        mode = "fixed",
        view = "3d",
        eye = { 5.2, 3.7, 6.2 },
        target = { 0, 0, 0 },
        up = { 0, 1, 0 },
        projection = "perspective",
        fov = 0.7,
        near = 0.1,
        far = 100,
    },
}
local voxel_space = voxels:space {
    x = { -2.4, 2.4, 0.6 },
    y = { -2.4, 2.4, 0.6 },
    z = { -2.4, 2.4, 0.6 },
    opacity = 0,
    id = "voxel-space",
}
voxel_space:voxel(function(x, y, z, time)
    local phase = pulse(time)
    local a, b, c = 1.25 + 0.7 * phase, 1.25 - 0.22 * phase, 1.25 + 0.35 * phase
    local inside = x * x / (a * a) + y * y / (b * b) + z * z / (c * c) <= 1
    if not inside then
        return "#00000000"
    end
    return x > a - 0.45 and accent .. "e8" or ink .. "b8"
end, { mode = "padd", padding = 0.08, duration = total, fps = 8 })

local function circle_points(count, radius)
    local points = {}
    for i = 0, count - 1 do
        local a = tau * i / count
        points[#points + 1] = { radius * math.cos(a), radius * math.sin(a) }
    end
    return points
end
local function square_points(count, radius)
    local corners, points =
        { { -radius, -radius }, { radius, -radius }, { radius, radius }, { -radius, radius } }, {}
    for i = 0, count - 1 do
        local phase, side = 4 * i / count, math.floor(4 * i / count) + 1
        local t, a, b = phase - math.floor(phase), corners[side], corners[side % 4 + 1]
        points[#points + 1] = { a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t }
    end
    return points
end
local primitives = scene2d(4.7)
local primitive_space = primitives:space {
    x = { -2.8, 2.8, 8 },
    y = { -1.8, 1.8, 8 },
    color = "#00000000",
    axis_x = rule,
    axis_y = rule,
    id = "primitive-space",
}
local original = primitive_space:polygon {
    points = circle_points(40, 1.2),
    fill = "#ffffff00",
    stroke = ink,
    width = 1.8,
    id = "primitive-circle",
}
primitive_space:point { point = { 0, 0 }, fill = accent, radius = 4, id = "primitive-origin" }
local square = primitive_space:polygon {
    points = square_points(40, 1.05),
    fill = "#ffffff00",
    stroke = ink,
    width = 1.8,
    id = "primitive-square",
}
primitives:morph(original, square, 1.5, "ease_in_out")
primitives:wait(0.5)
local restored = primitive_space:polygon {
    points = circle_points(40, 1.2),
    fill = "#ffffff00",
    stroke = ink,
    width = 1.8,
    id = "primitive-restored",
}
primitives:morph(square, restored, 1.5, "ease_in_out")
primitives:wait(0.5)
local square_second = primitive_space:polygon {
    points = square_points(40, 1.05),
    fill = "#ffffff00",
    stroke = ink,
    width = 1.8,
    id = "primitive-square-second",
}
primitives:morph(restored, square_second, 1.5, "ease_in_out")
primitives:wait(0.5)
local restored_second = primitive_space:polygon {
    points = circle_points(40, 1.2),
    fill = "#ffffff00",
    stroke = ink,
    width = 1.8,
    id = "primitive-restored-second",
}
primitives:morph(square_second, restored_second, 1.5, "ease_in_out")
primitives:wait(0.5)

local function curve_value(preset, time, strength)
    if time <= 0 or time >= 1 then
        return time
    end
    local value = time
    if preset == "back" then
        local overshoot, inverse = 1.70158, time - 1
        value = 1 + (overshoot + 1) * inverse * inverse * inverse + overshoot * inverse * inverse
    elseif preset == "bounce" then
        local n, d, t = 7.5625, 2.75, time
        if t < 1 / d then
            value = n * t * t
        elseif t < 2 / d then
            t = t - 1.5 / d
            value = n * t * t + 0.75
        elseif t < 2.5 / d then
            t = t - 2.25 / d
            value = n * t * t + 0.9375
        else
            t = t - 2.625 / d
            value = n * t * t + 0.984375
        end
    elseif preset == "elastic" then
        value = 2 ^ (-10 * time) * math.sin((10 * time - 0.75) * tau / 3) + 1
    end
    return time + (value - time) * strength
end

local function curve_lane(label, preset, strength)
    local lane = tmath.scene {
        width = 500,
        height = 100,
        fps = 30,
        theme = "pro",
        camera = { mode = "fixed", view = "2d", height = 1.4 },
    }
    lane:text {
        text = label,
        point = { -3.18, 0 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 13,
        role = "code",
    }
    local track_from, track_to = -1.72, 0.18
    lane:line { from = { track_from, 0 }, to = { track_to, 0 }, stroke = rule, width = 2 }
    lane:line { from = { track_from, -0.12 }, to = { track_from, 0.12 }, stroke = ink, width = 2 }
    lane:line { from = { track_to, -0.12 }, to = { track_to, 0.12 }, stroke = accent, width = 2 }
    local graph_left, graph_right, graph_bottom, graph_top = 0.82, 2.72, -0.43, 0.43
    local y_min, y_max, graph_points = -0.15, 1.15, {}
    local zero_y = graph_bottom + (0 - y_min) / (y_max - y_min) * (graph_top - graph_bottom)
    lane:line {
        from = { graph_left, zero_y },
        to = { graph_right, zero_y },
        stroke = rule,
        width = 1,
    }
    lane:line {
        from = { graph_left, graph_bottom },
        to = { graph_left, graph_top },
        stroke = rule,
        width = 1,
    }
    lane:line {
        from = { graph_right, graph_bottom },
        to = { graph_right, graph_top },
        stroke = rule,
        width = 1,
    }
    for i = 0, 32 do
        local time = i / 32
        local value = curve_value(preset, time, strength)
        graph_points[#graph_points + 1] = {
            graph_left + (graph_right - graph_left) * time,
            graph_bottom + (value - y_min) / (y_max - y_min) * (graph_top - graph_bottom),
        }
    end
    lane:plot { points = graph_points, stroke = accent, width = 1.6, id = "curve-graph-" .. preset }
    local runner =
        lane:point { point = { track_from, 0 }, fill = accent, radius = 6, id = "curve-" .. preset }
    local distance = track_to - track_from
    lane:shift(runner, { distance, 0 }, cycle / 2, { preset = preset, strength = strength })
    lane:shift(
        runner,
        { -distance, 0 },
        cycle / 2,
        { preset = preset, strength = strength, reverse = true }
    )
    lane:shift(runner, { distance, 0 }, cycle / 2, { preset = preset, strength = strength })
    lane:shift(
        runner,
        { -distance, 0 },
        cycle / 2,
        { preset = preset, strength = strength, reverse = true }
    )
    return lane
end
local curves = tmath.scene {
    width = 500,
    height = 300,
    fps = 30,
    theme = "pro",
    camera = { mode = "fixed", view = "2d", height = 4.2 },
}
local curve_lanes = {
    curve_lane("BACK", "back", 0.65),
    curve_lane("ELASTIC", "elastic", 0.55),
    curve_lane("BOUNCE", "bounce", 0.8),
}
for index, lane in ipairs(curve_lanes) do
    curves:viewport(lane, { x = 0, y = (index - 1) / 3, width = 1, height = 1 / 3 })
end

local root = tmath.scene {
    width = 1280,
    height = 720,
    fps = 30,
    loop = true,
    theme = "pro_white",
    camera = { mode = "fixed", view = "2d", height = 7.2 },
}
root:text {
    text = "TMATH",
    point = { 0, 3.12 },
    font = "Pretendard",
    size = 38,
    role = "h1",
    id = "brand-title",
}
local panels = {
    panel("2D", primitives),
    panel("3D", sphere),
    panel("ANIM CURVE", curves),
    panel("CELL FIELD", cells),
    panel("VOXEL FIELD", voxels),
    panel("SHOW", show),
}
local bounds = {
    { x = 0.02, y = 0.16, width = 0.31, height = 0.395 },
    { x = 0.345, y = 0.16, width = 0.31, height = 0.395 },
    { x = 0.67, y = 0.16, width = 0.31, height = 0.395 },
    { x = 0.02, y = 0.58, width = 0.31, height = 0.395 },
    { x = 0.345, y = 0.58, width = 0.31, height = 0.395 },
    { x = 0.67, y = 0.58, width = 0.31, height = 0.395 },
}
for i, child in ipairs(panels) do
    root:viewport(child, bounds[i])
end
return root
