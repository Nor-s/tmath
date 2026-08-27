-- Drive a unit-circle construction and two graph cursors from one angle state.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local center, radius = {-2.7, 0}, 1.45
local theta_start, theta_end, steps = 0.15, 1.05, 24
local function rotation_at(theta)
    local c, s = math.cos(theta), math.sin(theta)
    return {c, -s, 0, center[1], s, c, 0, center[2], 0, 0, 1, 0, 0, 0, 0, 1}
end
local function x_component_at(value)
    return {value, 0, 0, center[1], 0, 1, 0, center[2], 0, 0, 1, 0, 0, 0, 0, 1}
end
local function y_component_at(x, value)
    return {1, 0, 0, x, 0, value, 0, center[2], 0, 0, 1, 0, 0, 0, 0, 1}
end
local function cursor_at(theta, value)
    return {1, 0, 0, theta, 0, value, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1}
end
local function state(theta)
    return {theta = theta, cosine = math.cos(theta), sine = math.sin(theta)}
end

local circle = scene:circle {id = "sync-circle", center = center, radius = radius, fill = "#00000000", stroke = "foreground", width = 3, layer = 0}
local axes = {
    scene:line {id = "sync-circle-x-axis", from = {center[1] - 1.8, 0}, to = {center[1] + 1.8, 0}, stroke = "border", width = 2},
    scene:line {id = "sync-circle-y-axis", from = {center[1], -1.8}, to = {center[1], 1.8}, stroke = "border", width = 2},
}
local circle_label = scene:text {id = "sync-circle-label", text = "P = (cos θ, sin θ)", point = {-4.45, 2.35}, role = "code", fill = "foreground", align = {0, 0.5}, layer = 40}

-- Separate owner Spaces let one composite play update every dependent geometry atomically.
local initial = state(theta_start)
local motion = scene:space {x = {-0.1, 0.1, 0.1}, y = {-0.1, 0.1, 0.1}, opacity = 0, matrix = rotation_at(initial.theta)}
local radial = motion:vector {id = "sync-radius", value = {radius, 0}, stroke = "foreground", width = 4, tip = 12, layer = 20}
local marker = motion:point {id = "sync-circle-marker", point = {radius, 0}, fill = "foreground", radius = 7, layer = 30}
local cos_track = scene:space {x = {-0.1, 0.1, 0.1}, y = {-0.1, 0.1, 0.1}, opacity = 0, matrix = x_component_at(initial.cosine)}
local cos_component = cos_track:vector {id = "sync-cos-component", value = {radius, 0}, stroke = "accent", width = 5, tip = 11, layer = 20}
local sin_track = scene:space {x = {-0.1, 0.1, 0.1}, y = {-0.1, 0.1, 0.1}, opacity = 0, matrix = y_component_at(center[1] + radius * initial.cosine, initial.sine)}
local sin_component = sin_track:vector {id = "sync-sin-component", value = {0, radius}, stroke = "secondary", width = 5, tip = 11, layer = 20}
sin_track:point {id = "sync-projection-foot", point = {0, 0}, fill = "secondary", radius = 4, layer = 10}

-- Each plot owns a curve and a scalable vertical cursor in its local coordinates.
local function graph(id, labelText, y, color, fn)
    local space = scene:space {
        id = id .. "-space", x = {0, 1.2, 0.2}, y = {0, 1.05, 0.25}, numbers = false,
        stroke = "border", axis_x = "border", axis_y = "border",
        matrix = {2.9, 0, 0, 0.45, 0, 1.05, 0, y, 0, 0, 1, 0, 0, 0, 0, 1},
    }
    local curve = space:plot {id = id .. "-curve", fn = fn, x_range = {0, 1.2, 0.025}, stroke = color, width = 3, layer = 0}
    local cursor = space:space {x = {-0.05, 0.05, 0.05}, y = {-0.05, 0.05, 0.05}, opacity = 0, matrix = cursor_at(initial.theta, fn(initial.theta))}
    local guide = cursor:line {id = id .. "-guide", from = {0, 0}, to = {0, 1}, stroke = color, width = 2, layer = 10}
    local point = cursor:point {id = id .. "-marker", point = {0, 1}, fill = color, radius = 6, layer = 30}
    local label = scene:text {id = id .. "-label", text = labelText, point = {0.45, y + 1.5}, role = "code", fill = color, align = {0, 0.5}, layer = 40}
    return {curve = curve, cursor = cursor, guide = guide, point = point, label = label}
end
local cosine = graph("sync-cos", "cos θ", 0.55, "accent", math.cos)
local sine = graph("sync-sin", "sin θ", -1.75, "secondary", math.sin)
local angle_label = scene:text {
    id = "sync-angle-label", text = string.format("θ = %.2f rad", theta_end),
    point = {-3.42, -2.35}, role = "code", fill = "foreground", align = {0.5, 0.5}, layer = 40,
}

-- Establish the construction, then advance every target from the same sampled theta.
scene:create({circle, axes[1], axes[2], cosine.curve, sine.curve}, 0.65, "ease_out", 0.04)
scene:fade_in(circle_label, {shift = {0, -0.08}, duration = 0.24, curve = "gentle"})
scene:fade_in(cosine.label, {shift = {0, -0.08}, duration = 0.24, curve = "gentle"})
scene:fade_in(sine.label, {shift = {0, -0.08}, duration = 0.24, curve = "gentle"})
scene:create({radial, marker, cos_component, sin_component, cosine.guide, cosine.point, sine.guide, sine.point}, 0.45, "ease_out", 0.03)
scene:wait(0.5)
for i = 1, steps do
    local current = state(theta_start + (theta_end - theta_start) * i / steps)
    scene:play({
        {target = motion, transform = rotation_at(current.theta)},
        {target = cos_track, transform = x_component_at(current.cosine)},
        {target = sin_track, transform = y_component_at(center[1] + radius * current.cosine, current.sine)},
        {target = cosine.cursor, transform = cursor_at(current.theta, current.cosine)},
        {target = sine.cursor, transform = cursor_at(current.theta, current.sine)},
    }, 0.075, "linear", 0)
end
scene:fade_in(angle_label, {shift = {0, -0.08}, duration = 0.28, curve = "gentle"})
scene:wait(1.4)
return scene
