-- Reference study: block a camera move as three motivated shots.
-- The left viewport is the captured image. The right viewport is a top-down
-- director map of the same key poses: establish -> two-waypoint arc reveal ->
-- dolly/reframe. The subject never moves during a camera clip.
local page = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6},
}

local function add(a, b)
    return {a[1] + b[1], a[2] + b[2], (a[3] or 0) + (b[3] or 0)}
end
local function orbitEye(target, degrees, radius, height)
    local angle = math.rad(degrees)
    return {
        target[1] + radius * math.cos(angle),
        target[2] + height,
        target[3] + radius * math.sin(angle),
    }
end
local function shot(target, eye, fov)
    return {
        view = "3d", eye = eye, target = target, up = {0, 1, 0},
        projection = "perspective", fov = fov, near = 0.1, far = 40,
    }
end

local subjectTarget = {0, 0.38, 0}
local featureTarget = {-0.38, 0.48, -0.28}
local shotA = shot(subjectTarget, orbitEye(subjectTarget, 38, 6.65, 3.05), 0.66)
local shotMid = shot(subjectTarget, orbitEye(subjectTarget, 79, 6.65, 3.05), 0.66)
local shotB = shot(subjectTarget, orbitEye(subjectTarget, 121, 6.65, 3.05), 0.66)
local shotC = shot(featureTarget, orbitEye(featureTarget, 121, 5.25, 2.45), 0.68)

local capture = tmath.scene {
    width = 645, height = 405, fps = 30, loop = false, theme = "adaptive_vscode",
    camera = {
        mode = "fixed", view = shotA.view, eye = shotA.eye, target = shotA.target, up = shotA.up,
        projection = shotA.projection, fov = shotA.fov, near = shotA.near, far = shotA.far,
    },
}
local space = capture:space {
    x = {-3.2, 3.2, 1}, y = {-1.2, 2.8, 1}, z = {-3.2, 3.2, 1},
    opacity = 0.12, id = "camera:capture-space",
}
local context = space:group {opacity = 0.60, id = "camera:depth-context"}
local ground = context:polygon {
    points = {{-3.0, -0.72, -3.0}, {3.0, -0.72, -3.0}, {3.0, -0.72, 3.0}, {-3.0, -0.72, 3.0}},
    fill = "#4fc1ff0e", stroke = "border", width = 1.2, id = "camera:ground",
}
local depthPosts = {
    context:line {from = {-2.25, -0.72, 1.85}, to = {-2.25, 1.05, 1.85}, color = "muted", width = 4, id = "camera:post:near"},
    context:line {from = {2.20, -0.72, -1.75}, to = {2.20, 1.35, -1.75}, color = "muted", width = 4, id = "camera:post:far"},
    context:point {point = {-2.25, 1.05, 1.85}, radius = 6, fill = "muted", id = "camera:post-cap:near"},
    context:point {point = {2.20, 1.35, -1.75}, radius = 6, fill = "muted", id = "camera:post-cap:far"},
}

-- A faceted beacon supplies an asymmetric silhouette and an occluding body.
local beacon = space:group {id = "camera:beacon"}
local lower = {
    {-0.92, -0.62, -0.78}, {0.92, -0.62, -0.78},
    {0.92, -0.62, 0.78}, {-0.92, -0.62, 0.78},
}
local upper = {
    {-0.62, 0.78, -0.52}, {0.62, 0.78, -0.52},
    {0.62, 0.78, 0.52}, {-0.62, 0.78, 0.52},
}
local tip = {0.12, 2.05, -0.08}
local beaconFaces = {
    beacon:polygon {points = {lower[1], lower[2], upper[2], upper[1]}, fill = "#4fc1ff48", stroke = "border", width = 1.2, id = "camera:beacon:front"},
    beacon:polygon {points = {lower[2], lower[3], upper[3], upper[2]}, fill = "#8b5cf648", stroke = "border", width = 1.2, id = "camera:beacon:right"},
    beacon:polygon {points = {lower[3], lower[4], upper[4], upper[3]}, fill = "#4fc1ff38", stroke = "border", width = 1.2, id = "camera:beacon:back"},
    beacon:polygon {points = {lower[4], lower[1], upper[1], upper[4]}, fill = "#8b5cf638", stroke = "border", width = 1.2, id = "camera:beacon:left"},
    beacon:polygon {points = {upper[1], upper[2], tip}, fill = "#ffd8664f", stroke = "warning", width = 1.3, id = "camera:beacon:spire-front"},
    beacon:polygon {points = {upper[2], upper[3], tip}, fill = "#ffd8663f", stroke = "warning", width = 1.3, id = "camera:beacon:spire-right"},
    beacon:polygon {points = {upper[3], upper[4], tip}, fill = "#ffd86632", stroke = "warning", width = 1.3, id = "camera:beacon:spire-back"},
    beacon:polygon {points = {upper[4], upper[1], tip}, fill = "#ffd86642", stroke = "warning", width = 1.3, id = "camera:beacon:spire-left"},
}
local hiddenFeature = space:group {id = "camera:hidden-feature"}
local featureStem = hiddenFeature:line {
    from = {-1.02, -0.62, -0.82}, to = {-1.02, 0.43, -0.82},
    color = "result", width = 3, id = "camera:feature-stem",
}
local featurePoint = hiddenFeature:point {
    point = {-1.02, 0.43, -0.82}, radius = 9, fill = "result", stroke = "background", width = 1.4,
    layer = 10, id = "camera:feature",
}
local featureLabel = hiddenFeature:text {
    text = "reveal", point = {-1.02, 0.70, -0.82}, role = "code", fill = "result",
    layer = 20, id = "camera:feature-label",
}

capture:create(space, 0.30, "ease_out")
capture:fade_in(context, {duration = 0.42, curve = "gentle"})
capture:draw_border_then_fill(beaconFaces, 0.62, "ease_out", 0.04)
capture:create(hiddenFeature, 0.32, "ease_out")
capture:wait(0.62)
local moveStart = capture:duration()
capture:look(shotMid, 1.15, "ease_in_out")
capture:look(shotB, 1.15, "ease_in_out")
capture:wait(0.45)
capture:indicate(featurePoint, {scale = 1.07, duration = 0.38, curve = "ease_in_out"})
capture:wait(0.30)
capture:look(shotC, 1.35, "ease_in_out")
capture:wait(2.05)

local plan = tmath.scene {
    width = 310, height = 405, fps = 30, loop = false, theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 15.8},
}
local map = plan:space {
    x = {-7.6, 7.6, 2}, y = {-7.6, 7.6, 2}, opacity = 0.18,
    id = "camera:director-map",
}
local subjectMark = map:circle {
    center = {0, 0}, radius = 0.82, fill = "#4fc1ff24", stroke = "accent", width = 2.5,
    id = "camera:map-subject",
}
local targetMark = map:point {
    point = {subjectTarget[1], subjectTarget[3]}, radius = 6, fill = "result",
    layer = 10, id = "camera:map-target",
}
local orbitGuidePoints = {}
for sample = 0, 96 do
    local angle = math.rad(38 + (121 - 38) * sample / 96)
    orbitGuidePoints[#orbitGuidePoints + 1] = {6.65 * math.cos(angle), 6.65 * math.sin(angle)}
end
local orbitGuide = map:plot {
    points = orbitGuidePoints, color = "muted", width = 1.5, dash = {7, 6},
    id = "camera:map-orbit-guide",
}
local function mapEye(value) return {value[1], value[3]} end
local eyeA, eyeMid, eyeB, eyeC = mapEye(shotA.eye), mapEye(shotMid.eye), mapEye(shotB.eye), mapEye(shotC.eye)
local poseA = map:point {point = eyeA, radius = 7, fill = "warning", stroke = "background", width = 1.2, layer = 10, id = "camera:map-pose:A"}
local poseMid = map:point {point = eyeMid, radius = 5, fill = "muted", layer = 10, id = "camera:map-pose:mid"}
local poseB = map:point {point = eyeB, radius = 7, fill = "focus", stroke = "background", width = 1.2, layer = 10, id = "camera:map-pose:B"}
local poseC = map:point {point = eyeC, radius = 7, fill = "result", stroke = "background", width = 1.2, layer = 10, id = "camera:map-pose:C"}
local labels = {
    map:text {text = "A establish", point = add(eyeA, {-0.35, 0.35}), align = {1, 0.5}, role = "code", size = 11, fill = "warning", id = "camera:map-label:A"},
    map:text {text = "waypoint", point = add(eyeMid, {0.35, 0.35}), align = {0, 0.5}, role = "code", size = 10.5, fill = "muted", id = "camera:map-label:mid"},
    map:text {text = "B reveal", point = add(eyeB, {0.35, 0.35}), align = {0, 0.5}, role = "code", size = 11, fill = "focus", id = "camera:map-label:B"},
    map:text {text = "C dolly", point = add(eyeC, {0.35, -0.38}), align = {0, 0.5}, role = "code", size = 11, fill = "result", id = "camera:map-label:C"},
}
local arcFirst, arcSecond = {}, {}
for sample = 0, 48 do
    local firstAngle = math.rad(38 + (79 - 38) * sample / 48)
    arcFirst[#arcFirst + 1] = {6.65 * math.cos(firstAngle), 6.65 * math.sin(firstAngle)}
    local secondAngle = math.rad(79 + (121 - 79) * sample / 48)
    arcSecond[#arcSecond + 1] = {6.65 * math.cos(secondAngle), 6.65 * math.sin(secondAngle)}
end
local arcPathA = map:plot {points = arcFirst, color = "focus", width = 3, id = "camera:map-arc:A-mid"}
local arcPathB = map:plot {points = arcSecond, color = "focus", width = 3, id = "camera:map-arc:mid-B"}
local dollyPath = map:arrow {
    from = eyeB, to = eyeC, color = "result", width = 3, tip = 11,
    id = "camera:map-dolly:B-C",
}
local viewLines = {
    map:line {from = eyeA, to = {0, 0}, color = "warning", width = 1.5, dash = {6, 5}, id = "camera:map-view:A"},
    map:line {from = eyeB, to = {0, 0}, color = "focus", width = 1.5, dash = {6, 5}, id = "camera:map-view:B"},
    map:line {from = eyeC, to = {featureTarget[1], featureTarget[3]}, color = "result", width = 1.5, dash = {6, 5}, id = "camera:map-view:C"},
}

plan:create(map, 0.30, "ease_out")
plan:create({subjectMark, targetMark, orbitGuide}, 0.42, "ease_out", 0.06)
plan:create({poseA, poseMid, poseB, poseC}, 0.28, "ease_out", 0.04)
for _, label in ipairs(labels) do plan:fade_in(label, {duration = 0.10, curve = "gentle"}) end
plan:create(viewLines[1], 0.26, "ease_out")
local initialPlanDuration = plan:duration()
if initialPlanDuration < moveStart then plan:wait(moveStart - initialPlanDuration) end
plan:create(arcPathA, 1.15, "linear")
plan:create(arcPathB, 1.15, "linear")
plan:fade_in(viewLines[2], {duration = 0.30, curve = "gentle"})
plan:wait(0.15)
plan:indicate(subjectMark, {scale = 1.04, duration = 0.38, curve = "ease_in_out"})
plan:wait(0.30)
plan:create(dollyPath, 1.35, "linear")
plan:fade_in(viewLines[3], {duration = 0.30, curve = "gentle"})
plan:wait(1.75)

local title = page:text {
    text = "Cinematic 3D camera blocking", point = {0, 2.65}, role = "h2",
    fill = "foreground", id = "camera:title",
}
local subtitle = page:text {
    text = "establish → waypointed arc reveal → settle → motivated dolly/reframe",
    point = {0, 2.25}, role = "text", fill = "muted", id = "camera:subtitle",
}
page:fade_in(title, {shift = {0, -0.08}, duration = 0.38, curve = "gentle"})
page:fade_in(subtitle, {duration = 0.28, curve = "gentle"})
page:viewport(capture, {x = 0.015, y = 0.23, width = 0.645, height = 0.72})
page:viewport(plan, {x = 0.675, y = 0.23, width = 0.310, height = 0.72})
return page
