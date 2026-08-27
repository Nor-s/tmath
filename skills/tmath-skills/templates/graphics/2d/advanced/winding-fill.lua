-- Advanced reference: trace one ray through contours and compare two fill rules.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.4},
}

local center, outerRadius, innerRadius = {-2.45, 0.2}, 2.0, 0.88
local sample = {center[1] - 0.12, center[2] + 0.3}
local function rightIntersection(radius)
    local dy = sample[2] - center[2]
    return {center[1] + math.sqrt(radius * radius - dy * dy), sample[2]}
end
local crossings = {rightIntersection(innerRadius), rightIntersection(outerRadius)}
local winding = #crossings
local rayEnd = {center[1] + outerRadius + 0.58, sample[2]}

-- The main contours share orientation; the ray meets both right-hand boundaries.
local contours = {
    scene:circle {id = "winding-outer-contour", center = center, radius = outerRadius, fill = "#00000000", stroke = "foreground", width = 4, layer = 10},
    scene:circle {id = "winding-inner-contour", center = center, radius = innerRadius, fill = "#00000000", stroke = "foreground", width = 4, layer = 10},
}
local directionMarks = {
    scene:arrow {id = "winding-outer-direction", from = {center[1] + 0.52, center[2] + outerRadius - 0.08}, to = {center[1] - 0.52, center[2] + outerRadius - 0.08}, stroke = "secondary", width = 3, tip = 10, layer = 30},
    scene:arrow {id = "winding-inner-direction", from = {center[1] + 0.34, center[2] + innerRadius - 0.06}, to = {center[1] - 0.34, center[2] + innerRadius - 0.06}, stroke = "secondary", width = 3, tip = 10, layer = 30},
}
local ray = scene:arrow {id = "winding-ray", from = sample, to = rayEnd, stroke = "focus", width = 3, tip = 12, layer = 30}
local samplePoint = scene:point {id = "winding-sample", point = sample, fill = "focus", radius = 8, layer = 40}
local crossingPoints = {}
for index, point in ipairs(crossings) do
    crossingPoints[index] = scene:point {id = "winding-crossing-" .. index, point = point, fill = "result", radius = 7, layer = 40}
end
local traceLabels = {
    scene:text {id = "winding-crossing-count", text = string.format("crossings = %d", #crossings), point = {-3.25, -2.4}, role = "code", fill = "focus", align = {0.5, 0.5}, layer = 40},
    scene:text {id = "winding-number", text = string.format("winding = +%d", winding), point = {-1.65, -2.4}, role = "code", fill = "result", align = {0.5, 0.5}, layer = 40},
}

-- The same nested geometry yields a hole for parity and a filled center for non-zero.
local resultColor = "#ffd166bb"
local evenCenter, nonZeroCenter, resultRadius, holeRadius = {2.55, 1.28}, {2.55, -1.25}, 0.9, 0.4
local evenOdd = {
    scene:circle {id = "winding-even-outer", center = evenCenter, radius = resultRadius, fill = resultColor, stroke = "result", width = 3, layer = 10},
    scene:circle {id = "winding-even-hole", center = evenCenter, radius = holeRadius, fill = "surface", stroke = "foreground", width = 2, layer = 20},
}
local nonZero = {
    scene:circle {id = "winding-nonzero-outer", center = nonZeroCenter, radius = resultRadius, fill = resultColor, stroke = "result", width = 3, layer = 10},
    scene:circle {id = "winding-nonzero-inner", center = nonZeroCenter, radius = holeRadius, fill = "#00000000", stroke = "foreground", width = 2, layer = 20},
}
local resultSamples = {
    scene:point {id = "winding-even-sample", point = evenCenter, fill = "focus", radius = 6, layer = 40},
    scene:point {id = "winding-nonzero-sample", point = nonZeroCenter, fill = "focus", radius = 6, layer = 40},
}
local resultLabels = {
    scene:text {id = "winding-even-label", text = "even-odd → outside", point = {evenCenter[1], 2.45}, role = "code", fill = "foreground", align = {0.5, 0.5}, layer = 40},
    scene:text {id = "winding-nonzero-label", text = "non-zero → inside", point = {nonZeroCenter[1], -0.08}, role = "code", fill = "result", align = {0.5, 0.5}, layer = 40},
}

-- Count the real intersections before revealing the rule-dependent fill states.
scene:create(contours, 0.7, "ease_out", 0.08, "counterclockwise")
scene:create(directionMarks, 0.32, "ease_out", 0.06)
scene:grow_from_center(samplePoint, 0.22, "ease_out")
scene:create(ray, 0.65, "linear")
scene:grow_from_center(crossingPoints[1], 0.24, "ease_out")
scene:grow_from_center(crossingPoints[2], 0.24, "ease_out")
scene:fade_in(traceLabels[1], {shift = {0, 0.06}, duration = 0.28, curve = "gentle"})
scene:fade_in(traceLabels[2], {shift = {0, 0.06}, duration = 0.28, curve = "gentle"})
scene:draw_border_then_fill(evenOdd, 0.6, "ease_out", 0.05)
scene:grow_from_center(resultSamples[1], 0.2, "ease_out")
scene:fade_in(resultLabels[1], {shift = {0, 0.06}, duration = 0.28, curve = "gentle"})
scene:draw_border_then_fill(nonZero, 0.6, "ease_out", 0.05)
scene:grow_from_center(resultSamples[2], 0.2, "ease_out")
scene:fade_in(resultLabels[2], {shift = {0, 0.06}, duration = 0.28, curve = "gentle"})
scene:wait(1.35)
return scene
