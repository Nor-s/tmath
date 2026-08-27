-- One sampled graph moves through a reversible family of function rules.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = true,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.5},
}

local samples, sampleX = 96, 1.15
local function base(x) return 0.18 * x * x - 1.05 end
local states = {
    {label = "f(x)", fn = base},
    {label = "f(x - 1) + 0.65", fn = function(x) return base(x - 1) + 0.65 end},
    {label = "-0.72 f(x)", fn = function(x) return -0.72 * base(x) end},
    {label = "|f(x)|", fn = function(x) return math.abs(base(x)) end},
    {label = "f(x)", fn = base},
}
local plane = scene:space {
    id = "function-transform-plane", x = {-4.8, 4.8, 1}, y = {-2.7, 2.7, 0.5}, numbers = false,
    stroke = "border", axis_x = "border", axis_y = "border", width = 1.2,
}
local function diamond(point)
    local r = 0.095
    return {{point[1] - r, point[2]}, {point[1], point[2] + r},
            {point[1] + r, point[2]}, {point[1], point[2] - r}}
end
local function geometry(index)
    local points, fn = {}, states[index].fn
    for i = 0, samples do
        local x = -4.8 + 9.6 * i / samples
        points[#points + 1] = {x, fn(x)}
    end
    local p = {sampleX, fn(sampleX)}
    return {
        curve = plane:plot {id = "function-curve-" .. index, points = points, stroke = "accent", width = 4, layer = 10},
        sample = plane:polygon {id = "function-sample-" .. index, points = diamond(p), fill = "result", stroke = "result", layer = 30},
    }
end
local function label(index)
    return scene:text {
        id = "function-rule-" .. index, text = states[index].label,
        point = {0, 2.72}, role = "code", fill = "result", align = {0.5, 0.5}, layer = 40,
    }
end

-- Frame zero is already a useful pose so the exact final return can loop cleanly.
local live, liveLabel = geometry(1), label(1)
local observation = scene:text {
    id = "function-transform-observation", text = "same samples · changed rule",
    point = {0, -2.82}, role = "code", fill = "muted", align = {0.5, 0.5}, layer = 40,
}
scene:wait(0.65)

for index = 2, #states do
    local target = geometry(index)
    scene:morph({live.curve, live.sample}, {target.curve, target.sample}, 0.82, "ease_in_out", 0)
    live = target
    local targetLabel = label(index)
    scene:fade_transform(liveLabel, targetLabel, 0.22, "gentle")
    liveLabel = targetLabel
    scene:wait(index == #states and 0.65 or 0.42)
end
return scene
