-- Add vectors geometrically, then copy each colored object into matching equation text.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.6},
}
local plane = scene:space {id = "add-space", x = {-5, 5, 1}, y = {-3, 3, 1}, numbers = false, stroke = "border", width = 1}
local origin, av, bv = {-3, -0.55}, {2.7, 0.9}, {1.4, 1.5}
local function add(first, second) return {first[1] + second[1], first[2] + second[2]} end
local function pointAlong(originPoint, value, amount, offset)
    return {originPoint[1] + value[1] * amount + offset[1], originPoint[2] + value[2] * amount + offset[2]}
end
local sumValue, aEnd = add(av, bv), add(origin, av)
local sumEnd = add(origin, sumValue)
-- Convert an arrow into a closed polygon so it can morph into a glyph-sized seed.
local function arrowPoints(from, to)
    local dx, dy = to[1] - from[1], to[2] - from[2]
    local length = math.sqrt(dx * dx + dy * dy)
    local ux, uy, nx, ny = dx / length, dy / length, -dy / length, dx / length
    local neck = {to[1] - 0.32 * ux, to[2] - 0.32 * uy}
    return {{from[1] + 0.045 * nx, from[2] + 0.045 * ny}, {neck[1] + 0.045 * nx, neck[2] + 0.045 * ny},
            {neck[1] + 0.15 * nx, neck[2] + 0.15 * ny}, to,
            {neck[1] - 0.15 * nx, neck[2] - 0.15 * ny}, {neck[1] - 0.045 * nx, neck[2] - 0.045 * ny},
            {from[1] - 0.045 * nx, from[2] - 0.045 * ny}}
end
local function seedPoints(center)
    local points = {}
    for i = 0, 6 do
        local angle = 2 * math.pi * i / 7
        points[#points + 1] = {center[1] + 0.09 * math.cos(angle), center[2] + 0.14 * math.sin(angle)}
    end
    return points
end
local function handoff(points, target, text, color, id)
    -- Morph a temporary copy; the source vector remains visible in the figure.
    local copy = plane:polygon {id = id .. "-copy", points = points, fill = color, stroke = color, width = 1, layer = 30}
    local seed = plane:polygon {id = id .. "-seed", points = seedPoints(target), fill = color, stroke = color, width = 1, layer = 30}
    scene:replacement_transform(copy, seed, 0.62, "ease_in_out")
    local term = plane:text {id = id, text = text, point = target, role = "code", fill = color, align = {0.5, 0.5}, layer = 40}
    scene:fade_transform(seed, term, 0.22, "gentle")
    return term
end

-- Head-to-tail placement encodes a + b; the direct vector is the resultant.
local a = plane:vector {id = "add-a", origin = origin, value = av, stroke = "accent", width = 4, tip = 13, layer = 20}
local b = plane:vector {id = "add-b", origin = aEnd, value = bv, stroke = "secondary", width = 4, tip = 13, layer = 20}
local sum = plane:vector {id = "add-result", origin = origin, value = sumValue, stroke = "result", width = 5, tip = 14, layer = 20}
local labels = {
    plane:text {id = "add-a-label", text = "a", point = pointAlong(origin, av, 0.5, {0.03, -0.22}), role = "code", fill = "accent", layer = 40},
    plane:text {id = "add-b-label", text = "b", point = pointAlong(aEnd, bv, 0.5, {0.18, 0.1}), role = "code", fill = "secondary", layer = 40},
    plane:text {id = "add-result-label", text = "a + b", point = pointAlong(origin, sumValue, 0.5, {0.53, 0.63}), role = "code", fill = "result", layer = 40},
}
local equation = {
    lhs = {point = {-1.25, -2.35}, text = "b", color = "secondary", id = "add-lhs", points = arrowPoints(aEnd, sumEnd)},
    plus = {-0.68, -2.35},
    rhs = {point = {-0.12, -2.35}, text = "a", color = "accent", id = "add-rhs", points = arrowPoints(origin, aEnd)},
    equals = {0.42, -2.35},
    result = {point = {1.25, -2.35}, text = "a + b", color = "result", id = "add-sum-term", points = arrowPoints(origin, sumEnd)},
}
local plus = plane:text {id = "add-plus", text = "+", point = equation.plus, role = "code", fill = "muted", layer = 40}
local equals = plane:text {id = "add-equals", text = "=", point = equation.equals, role = "code", fill = "muted", layer = 40}
local function handoffTerm(term)
    return handoff(term.points, term.point, term.text, term.color, term.id)
end

-- Establish geometry first, then hand each colored object into the final identity.
scene:create(plane, 0.42, "ease_out")
scene:create({a, b}, 0.72, "ease_out", 0.08)
scene:create({labels[1], labels[2]}, 0.3, "ease_out", 0.05)
scene:wait(0.5)
scene:create(sum, 0.72, "ease_out")
scene:fade_in(labels[3], {duration = 0.3, curve = "gentle"})
scene:wait(0.65)
scene:create({plus, equals}, 0.28, "ease_out")
handoffTerm(equation.rhs)
handoffTerm(equation.lhs)
handoffTerm(equation.result)
scene:wait(1.5)
return scene
