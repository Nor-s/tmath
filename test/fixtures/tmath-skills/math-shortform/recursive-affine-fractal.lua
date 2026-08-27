-- Three affine contractions repeatedly copy one triangle into a finite gasket.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 7.2},
}

local depth, scale = 4, 0.5
local base = {{-3.15, -2.45}, {3.15, -2.45}, {0, 2.85}}
local branchColors = {"accent", "secondary", "result"}
local function contraction(points, anchor)
    local output = {}
    for _, point in ipairs(points) do
        output[#output + 1] = {
            anchor[1] + scale * (point[1] - anchor[1]),
            anchor[2] + scale * (point[2] - anchor[2]),
        }
    end
    return output
end
local function triangle(parent, id, points, color)
    return parent:polygon {
        id = id, points = points, fill = color, stroke = color, width = 2, layer = 10,
    }
end

-- Begin with the seed whose three vertices define the contraction anchors.
local currentGroup = scene:group {id = "fractal-generation-0"}
local seed = triangle(currentGroup, "fractal-seed", base, "foreground")
local current = {{points = base, id = "0"}}
scene:draw_border_then_fill(seed, 0.72, "ease_out")
scene:wait(0.5)

-- Opaque source copies split toward affine targets; the old generation then clears.
for generation = 1, depth do
    local nextGroup = scene:group {id = "fractal-generation-" .. generation}
    local proxies, targets, nextState = {}, {}, {}
    for _, parentState in ipairs(current) do
        for branch = 1, 3 do
            local address = parentState.id .. branch
            local targetPoints = contraction(parentState.points, parentState.points[branch])
            proxies[#proxies + 1] = triangle(
                nextGroup, "fractal-copy-" .. generation .. "-" .. address,
                parentState.points, branchColors[branch])
            targets[#targets + 1] = triangle(
                nextGroup, "fractal-leaf-" .. generation .. "-" .. address,
                targetPoints, branchColors[branch])
            nextState[#nextState + 1] = {points = targetPoints, id = address}
        end
    end
    local duration = 1.0 - 0.08 * (generation - 1)
    local lag = 0.016 / generation
    scene:morph(proxies, targets, duration, "ease_in_out", lag)
    scene:fade(currentGroup, 0, 0.24, "gentle")
    scene:wait(0.18)
    currentGroup, current = nextGroup, nextState
end

local conclusion = scene:text {
    id = "fractal-conclusion",
    text = string.format("3 affine maps  ·  %d recursive levels", depth),
    point = {0, -3.18}, role = "code", fill = "result", align = {0.5, 0.5}, layer = 40,
}
scene:fade_in(conclusion, {shift = {0, 0.08}, duration = 0.34, curve = "gentle"})
scene:wait(1.9)
return scene
