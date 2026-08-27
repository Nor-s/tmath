-- Advanced reference: apply one affine matrix to a point and direction in one Space.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 7.2},
}

local pointValue, directionValue = {1.25, 1.0}, {1.8, 0.45}
local linear = {1.05, -0.35, 0.32, 0.92}
local translation = {1.25, -0.55}
local affine = {
    linear[1], linear[2], 0, translation[1],
    linear[3], linear[4], 0, translation[2],
    0, 0, 1, 0,
    0, 0, 0, 1,
}
local function mulLinear(value)
    return {linear[1] * value[1] + linear[2] * value[2], linear[3] * value[1] + linear[4] * value[2]}
end
local function add(a, b) return {a[1] + b[1], a[2] + b[2]} end
local mappedPoint, mappedDirection = add(mulLinear(pointValue), translation), mulLinear(directionValue)

-- The reference Space remains fixed while the local Space carries every descendant.
local world = scene:space {
    id = "affine-reference-space", x = {-5, 5, 1}, y = {-3, 3, 1}, numbers = false,
    stroke = "border", width = 1, opacity = 0.38,
}
local localSpace = scene:space {
    id = "affine-local-space", x = {-3, 3, 0.5}, y = {-2, 2, 0.5}, numbers = false,
    stroke = "accent", axis_x = "accent", axis_y = "secondary", width = 1.4, opacity = 0.58,
}
local point = localSpace:point {id = "affine-point", point = pointValue, fill = "accent", radius = 8, layer = 10}
local direction = localSpace:vector {
    id = "affine-direction", origin = {0, 0}, value = directionValue,
    stroke = "secondary", width = 4, tip = 13, layer = 20,
}
local localLabels = {
    localSpace:text {id = "affine-point-label", text = "point p", point = {pointValue[1] + 0.18, pointValue[2] + 0.18}, role = "code", fill = "accent", align = {0, 0.5}, layer = 40},
    localSpace:text {id = "affine-direction-label", text = "direction d", point = {directionValue[1] + 0.16, directionValue[2] - 0.16}, role = "code", fill = "secondary", align = {0, 0.5}, layer = 40},
}

-- Translation is visible as the transformed local origin; displacement still uses A only.
local translationArrow = scene:arrow {
    id = "affine-translation", from = {0, 0}, to = translation,
    stroke = "focus", width = 3, tip = 11, layer = 30,
}
local labels = {
    scene:text {id = "affine-matrix-label", text = "M = [ A  t ; 0  1 ]", point = {-4.9, 3.05}, role = "code", fill = "foreground", align = {0, 0.5}, layer = 40},
    scene:text {id = "affine-translation-label", text = "translation t", point = {0.42, -0.52}, role = "code", fill = "focus", align = {0, 0.5}, layer = 40},
    scene:text {id = "affine-point-result", text = string.format("M[p, 1] = (%.2f, %.2f) = A p + t", mappedPoint[1], mappedPoint[2]), point = {-2.75, -3.05}, role = "code", fill = "accent", align = {0.5, 0.5}, layer = 40},
    scene:text {id = "affine-direction-result", text = string.format("M[d, 0] = (%.2f, %.2f) = A d", mappedDirection[1], mappedDirection[2]), point = {2.9, -3.05}, role = "code", fill = "secondary", align = {0.5, 0.5}, layer = 40},
}

-- Establish the shared source frame, transform it once, then expose the two outcomes.
scene:create({world, localSpace}, 0.65, "ease_out", 0.08)
scene:create({point, direction}, 0.5, "ease_out", 0.08)
scene:create(localLabels, 0.24, "ease_out", 0.04)
scene:fade_in(labels[1], {shift = {0, 0.08}, duration = 0.3, curve = "gentle"})
scene:wait(0.45)
scene:transform(localSpace, affine, 1.45, "ease_in_out")
scene:create(translationArrow, 0.45, "ease_out")
scene:fade_in(labels[2], {shift = {0, 0.06}, duration = 0.24, curve = "gentle"})
scene:fade_in(labels[3], {shift = {0, 0.08}, duration = 0.32, curve = "gentle"})
scene:fade_in(labels[4], {shift = {0, 0.08}, duration = 0.32, curve = "gentle"})
scene:wait(1.35)
return scene
