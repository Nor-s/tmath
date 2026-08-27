-- Reference study: deterministic samples reconstruct a recognizable torus.
-- Camera motion happens only after the point set is complete, so parallax reveals
-- depth without competing with point generation.
local page = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6},
}

local majorRadius, minorRadius = 1.88, 0.64
local majorSamples, minorSamples = 22, 10
local points = {}
for majorIndex = 0, majorSamples - 1 do
    local u = 2 * math.pi * majorIndex / majorSamples
    for minorIndex = 0, minorSamples - 1 do
        local v = 2 * math.pi * minorIndex / minorSamples
        points[#points + 1] = {
            id = string.format("p:%02d:%02d", majorIndex, minorIndex),
            major = majorIndex,
            minor = minorIndex,
            p = {
                (majorRadius + minorRadius * math.cos(v)) * math.cos(u),
                minorRadius * math.sin(v),
                (majorRadius + minorRadius * math.cos(v)) * math.sin(u),
            },
        }
    end
end
assert(#points == majorSamples * minorSamples, "point-cloud sample count changed")

local cloud = tmath.scene {
    width = 752, height = 333, fps = 30, loop = false, theme = "adaptive_vscode",
    camera = {
        mode = "fixed", view = "3d", eye = {5.8, 3.35, 6.55}, target = {0, 0, 0},
        up = {0, 1, 0}, projection = "perspective", fov = 0.65, near = 0.1, far = 30,
    },
}
local space = cloud:space {
    x = {-3.2, 3.2, 1}, y = {-1.8, 1.8, 1}, z = {-3.2, 3.2, 1},
    opacity = 0.13, id = "point-cloud:space",
}
local guides = space:group {id = "point-cloud:parametric-guides"}
local centerline = {}
for sample = 0, 96 do
    local u = 2 * math.pi * sample / 96
    centerline[#centerline + 1] = {majorRadius * math.cos(u), 0, majorRadius * math.sin(u)}
end
local profile = {}
for sample = 0, 64 do
    local v = 2 * math.pi * sample / 64
    profile[#profile + 1] = {
        majorRadius + minorRadius * math.cos(v), minorRadius * math.sin(v), 0,
    }
end
local majorGuide = guides:plot {
    points = centerline, color = "muted", width = 2, dash = {7, 6},
    id = "point-cloud:major-guide",
}
local minorGuide = guides:plot {
    points = profile, color = "focus", width = 2.5,
    id = "point-cloud:minor-guide",
}
local pointObjects = {}
for index, sample in ipairs(points) do
    local isSeam = sample.major == 0
    local isSelected = sample.major == 4 and sample.minor == 2
    pointObjects[index] = space:point {
        point = sample.p, radius = isSelected and 7 or (isSeam and 5 or 4),
        fill = isSelected and "result" or (isSeam and "focus" or "accent"),
        stroke = isSelected and "background" or "#00000000", width = isSelected and 1.2 or 0,
        layer = isSelected and 10 or 0, id = "point-cloud:" .. sample.id,
    }
end
local selected = points[4 * minorSamples + 2 + 1]
local selectedLabel = space:text {
    text = "p(4,2)", point = {selected.p[1], selected.p[2] + 0.26, selected.p[3]},
    role = "code", fill = "result", layer = 20, id = "point-cloud:selected-label",
}

cloud:create(space, 0.30, "ease_out")
cloud:create({majorGuide, minorGuide}, 0.72, "ease_out", 0.10)
cloud:wait(0.42)
cloud:create(pointObjects, 0.22, "ease_out", 0.006)
cloud:fade_in(selectedLabel, {duration = 0.22, curve = "gentle"})
cloud:wait(0.70)
cloud:fade(guides, 0.28, 0.32, "gentle")
cloud:look({
    view = "3d", eye = {-5.25, 2.65, 6.25}, target = {0, 0, 0}, up = {0, 1, 0},
    projection = "perspective", fov = 0.65, near = 0.1, far = 30,
}, 1.85, "ease_in_out")
cloud:wait(2.15)

local title = page:text {
    text = "Point cloud → recognizable 3D form", point = {0, 2.65}, role = "h2",
    fill = "foreground", id = "point-cloud:title",
}
local subtitle = page:text {
    text = string.format("torus sampling · %d × %d = %d stable points · camera orbit after construction", majorSamples, minorSamples, #points),
    point = {0, 2.25}, role = "text", fill = "muted", id = "point-cloud:subtitle",
}
local formula = page:text {
    text = "p(u,v) = ((R + r cos v) cos u,  r sin v,  (R + r cos v) sin u)",
    point = {0, -2.73}, role = "code", size = 12, fill = "result", id = "point-cloud:formula",
}
page:fade_in(title, {shift = {0, -0.08}, duration = 0.38, curve = "gentle"})
page:fade_in(subtitle, {duration = 0.28, curve = "gentle"})
page:fade_in(formula, {duration = 0.34, curve = "gentle"})
page:viewport(cloud, {x = 0.03, y = 0.20, width = 0.94, height = 0.74})
return page
