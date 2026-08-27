-- A changing tangent triangle turns one angle into the secant identity.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.4},
}

local LAYER = {guide = 0, triangle = 5, annotation = 8, dot = 10, text = 40}
local center = {-2.45, -0.05}
local arcRadius, arcSamples = 0.34, 24

local function add(point, offset)
    return {point[1] + offset[1], point[2] + offset[2]}
end

local function diamond(point, radius)
    return {
        {point[1] - radius, point[2]}, {point[1], point[2] + radius},
        {point[1] + radius, point[2]}, {point[1], point[2] - radius},
    }
end

local function state(theta)
    local tangent = math.tan(theta)
    local circlePoint = add(center, {math.cos(theta), math.sin(theta)})
    local foot = add(center, {1, 0})
    local tangentPoint = add(center, {1, tangent})
    local arc = {}
    for index = 0, arcSamples do
        local angle = theta * index / arcSamples
        arc[#arc + 1] = add(center, {arcRadius * math.cos(angle), arcRadius * math.sin(angle)})
    end
    return {
        theta = theta, tangent = tangent, circlePoint = circlePoint, foot = foot, tangentPoint = tangentPoint,
        horizontal = {center, foot}, vertical = {foot, tangentPoint}, hypotenuse = {center, tangentPoint},
        radius = {center, circlePoint}, arc = arc,
    }
end

local circle = scene:circle {
    id = "secant-unit-circle", center = center, radius = 1,
    fill = "#00000000", stroke = "border", width = 3, layer = LAYER.guide,
}
local axes = {
    scene:line {id = "secant-x-axis", from = add(center, {-1.35, 0}), to = add(center, {1.42, 0}), stroke = "border", width = 1.5},
    scene:line {id = "secant-y-axis", from = add(center, {0, -1.25}), to = add(center, {0, 1.85}), stroke = "border", width = 1.5},
    scene:line {id = "secant-tangent-line", from = add(center, {1, -0.18}), to = add(center, {1, 1.9}), stroke = "border", width = 2, dash = {7, 6}},
    scene:plot {
        id = "secant-right-angle", points = {
            add(center, {0.84, 0}), add(center, {0.84, 0.16}), add(center, {1, 0.16}),
        },
        stroke = "foreground", width = 2, layer = LAYER.annotation,
    },
}

local function geometry(current, suffix)
    return {
        scene:plot {id = "secant-horizontal-" .. suffix, points = current.horizontal, stroke = "accent", width = 5, layer = LAYER.triangle},
        scene:plot {id = "secant-vertical-" .. suffix, points = current.vertical, stroke = "secondary", width = 5, layer = LAYER.triangle},
        scene:plot {id = "secant-hypotenuse-" .. suffix, points = current.hypotenuse, stroke = "result", width = 5, layer = LAYER.triangle},
        scene:plot {id = "secant-radius-" .. suffix, points = current.radius, stroke = "foreground", width = 2.5, opacity = 0.58, layer = LAYER.guide},
        scene:plot {id = "secant-angle-" .. suffix, points = current.arc, stroke = "foreground", width = 3, layer = LAYER.annotation},
        scene:polygon {id = "secant-circle-point-" .. suffix, points = diamond(current.circlePoint, 0.065), fill = "foreground", stroke = "foreground", layer = LAYER.dot},
        scene:polygon {id = "secant-tangent-point-" .. suffix, points = diamond(current.tangentPoint, 0.075), fill = "result", stroke = "result", layer = LAYER.dot},
    }
end

local targets = {0.36, 0.94, 0.54, 0.78}
local final = state(targets[#targets])
local hypotenuseNormal = {-math.sin(final.theta), math.cos(final.theta)}
local hypotenuseMidpoint = {
    (center[1] + final.tangentPoint[1]) / 2 + 0.28 * hypotenuseNormal[1],
    (center[2] + final.tangentPoint[2]) / 2 + 0.28 * hypotenuseNormal[2],
}

-- Final labels are positioned from the same settled state as the triangle.
local labels = {
    scene:text {
        id = "secant-unit-label", text = "unit circle", point = add(center, {-0.55, -0.72}),
        role = "text", fill = "muted", align = {0.5, 0.5}, layer = LAYER.text,
    },
    scene:text {
        id = "secant-horizontal-label", text = "1", point = add(center, {0.5, -0.27}),
        role = "code", fill = "accent", align = {0.5, 0.5}, layer = LAYER.text,
    },
    scene:text {
        id = "secant-vertical-label", text = "tan θ",
        point = {final.foot[1] + 0.32, (final.foot[2] + final.tangentPoint[2]) / 2},
        role = "code", fill = "secondary", align = {0.5, 0.5}, layer = LAYER.text,
    },
    scene:text {
        id = "secant-hypotenuse-label", text = "sec θ", point = hypotenuseMidpoint,
        role = "code", fill = "result", align = {0.5, 0.5}, layer = LAYER.text,
    },
}
local identity = scene:text {
    id = "secant-identity-conclusion", text = "1 + tan² θ = sec² θ",
    point = {2.35, 0.15}, role = "h3", fill = "result", align = {0.5, 0.5}, layer = LAYER.text,
}

local live = geometry(state(targets[1]), "state-1")
scene:create({circle, axes[1], axes[2], axes[3], axes[4]}, 0.62, "ease_out", 0.035)
scene:fade_in(labels[1], {shift = {0, -0.06}, duration = 0.28, curve = "gentle"})
scene:create(live, 0.58, "ease_out", 0.025)
scene:wait(0.42)

-- Moderate angles avoid the tangent singularity while making the relation breathe.
for index = 2, #targets do
    local nextGeometry = geometry(state(targets[index]), "state-" .. index)
    scene:morph(live, nextGeometry, 0.95, "ease_in_out", 0)
    live = nextGeometry
    scene:wait(0.18)
end

scene:fade_in(labels[2], {shift = {0, 0.06}, duration = 0.28, curve = "gentle"})
scene:fade_in(labels[3], {shift = {-0.06, 0}, duration = 0.28, curve = "gentle"})
scene:fade_in(labels[4], {shift = {0.04, -0.04}, duration = 0.28, curve = "gentle"})
scene:wait(0.5)
scene:fade_in(identity, {shift = {0, -0.08}, duration = 0.42, curve = "gentle"})
scene:indicate(identity, {scale = 1.035, duration = 0.38, curve = "gentle"})
scene:wait(1.9)
return scene
