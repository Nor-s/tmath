-- Reference study: character-style FK with elongated bipyramid bones.
-- Local joint rotations accumulate root-to-leaf in a right-handed 3D Space.
local page = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6},
}

local function identity3() return {1, 0, 0, 0, 1, 0, 0, 0, 1} end
local function multiply3(a, b)
    local result = {}
    for row = 0, 2 do
        for column = 0, 2 do
            local value = 0
            for k = 0, 2 do value = value + a[row * 3 + k + 1] * b[k * 3 + column + 1] end
            result[row * 3 + column + 1] = value
        end
    end
    return result
end
local function apply3(matrix, vector)
    return {
        matrix[1] * vector[1] + matrix[2] * vector[2] + matrix[3] * vector[3],
        matrix[4] * vector[1] + matrix[5] * vector[2] + matrix[6] * vector[3],
        matrix[7] * vector[1] + matrix[8] * vector[2] + matrix[9] * vector[3],
    }
end
local function rotateZ(angle)
    local c, s = math.cos(angle), math.sin(angle)
    return {c, -s, 0, s, c, 0, 0, 0, 1}
end
local function rotateY(angle)
    local c, s = math.cos(angle), math.sin(angle)
    return {c, 0, s, 0, 1, 0, -s, 0, c}
end
local function add(a, b) return {a[1] + b[1], a[2] + b[2], a[3] + b[3]} end
local function subtract(a, b) return {a[1] - b[1], a[2] - b[2], a[3] - b[3]} end
local function scale(v, amount) return {v[1] * amount, v[2] * amount, v[3] * amount} end
local function magnitude(v) return math.sqrt(v[1] ^ 2 + v[2] ^ 2 + v[3] ^ 2) end
local function normalize(v)
    local length = magnitude(v)
    assert(length > 1e-9, "cannot normalize a zero vector")
    return scale(v, 1 / length)
end
local function round(value)
    return value >= 0 and math.floor(value + 0.5) or math.ceil(value - 0.5)
end
local function cross(a, b)
    return {
        a[2] * b[3] - a[3] * b[2],
        a[3] * b[1] - a[1] * b[3],
        a[1] * b[2] - a[2] * b[1],
    }
end
local function frameFromX(origin, direction)
    local x = normalize(direction)
    local helper = math.abs(x[2]) > 0.92 and {0, 0, 1} or {0, 1, 0}
    local z = normalize(cross(x, helper))
    local y = cross(z, x)
    return {
        x[1], y[1], z[1], origin[1],
        x[2], y[2], z[2], origin[2],
        x[3], y[3], z[3], origin[3],
        0, 0, 0, 1,
    }
end
local function linkTransform(orientation, origin)
    return {
        orientation[1], orientation[2], orientation[3], origin[1],
        orientation[4], orientation[5], orientation[6], origin[2],
        orientation[7], orientation[8], orientation[9], origin[3],
        0, 0, 0, 1,
    }
end

local arm = {
    {length = 1.08, angle = math.rad(34), rotation = rotateZ, axis = "Z"},
    {length = 0.88, angle = math.rad(-38), rotation = rotateY, axis = "Y"},
    {length = 0.50, angle = math.rad(-46), rotation = rotateZ, axis = "Z"},
}
local base = {0.44, 1.10, 0}

local function solve(angles)
    local points = {{base[1], base[2], base[3]}}
    local transforms, orientations, parentOrientations = {}, {}, {}
    local orientation = identity3()
    for index = 1, #arm do
        parentOrientations[index] = orientation
        orientation = multiply3(orientation, arm[index].rotation(angles[index]))
        orientations[index] = orientation
        transforms[index] = linkTransform(orientation, points[index])
        points[index + 1] = add(points[index], apply3(orientation, {arm[index].length, 0, 0}))
    end
    return {
        points = points,
        linkTransforms = transforms,
        orientations = orientations,
        parentOrientations = parentOrientations,
    }
end

local states = {}
for pose = 0, #arm do
    local angles = {}
    for index, link in ipairs(arm) do angles[index] = index <= pose and link.angle or 0 end
    states[#states + 1] = solve(angles)
end
for link = 1, #arm do
    local measured = magnitude(subtract(states[4].points[link + 1], states[4].points[link]))
    assert(math.abs(measured - arm[link].length) < 1e-9, "FK must preserve bone length")
end

local chain = tmath.scene {
    width = 640, height = 410, fps = 30, loop = false, theme = "adaptive_vscode",
    camera = {
        mode = "fixed", view = "3d", eye = {4.25, 2.95, 6.65}, target = {0, 0.05, 0},
        up = {0, 1, 0}, projection = "perspective", fov = 0.60, near = 0.1, far = 30,
    },
}
local space = chain:space {
    x = {-2.8, 3.2, 1}, y = {-2.7, 2.7, 1}, z = {-2.4, 2.4, 1},
    opacity = 0.15, id = "fk:space",
}

local function bipyramid(parent, id, boneLength, matrix, fill, stroke, opacity)
    local owner = parent:group {matrix = matrix, opacity = opacity or 1, id = id .. ":owner"}
    local waist = boneLength * 0.42
    local radius = math.min(0.16, boneLength * 0.16)
    local startPoint, endPoint = {0, 0, 0}, {boneLength, 0, 0}
    local ring = {
        {waist, radius, 0}, {waist, 0, radius},
        {waist, -radius, 0}, {waist, 0, -radius},
    }
    local faces = {}
    for index = 1, 4 do
        local nextIndex = index % 4 + 1
        for _, face in ipairs({
            {startPoint, ring[index], ring[nextIndex], "proximal"},
            {endPoint, ring[nextIndex], ring[index], "distal"},
        }) do
            faces[#faces + 1] = owner:polygon {
                points = {face[1], face[2], face[3]}, fill = fill, stroke = stroke,
                width = 1.1, id = id .. ":" .. face[4] .. ":" .. index,
            }
        end
    end
    return owner, faces
end

-- Quiet whole-character context makes the active arm read as a skeletal rig.
local context = space:group {opacity = 0.56, id = "fk:character-context"}
local contextJoints = {
    pelvis = {0, -0.58, 0}, spine = {0, 0.18, 0}, chest = {0, 1.10, 0}, neck = {0, 1.52, 0}, head = {0, 2.02, 0},
    leftShoulder = {-0.44, 1.10, 0}, leftElbow = {-1.32, 0.82, 0.08}, leftWrist = {-2.02, 0.42, 0.18},
    leftHip = {-0.28, -0.58, 0}, leftKnee = {-0.44, -1.55, 0.10}, leftAnkle = {-0.34, -2.42, 0},
    rightHip = {0.28, -0.58, 0}, rightKnee = {0.42, -1.55, -0.08}, rightAnkle = {0.34, -2.42, 0},
}
local contextLinks = {
    {contextJoints.pelvis, contextJoints.spine, "pelvis-spine"},
    {contextJoints.spine, contextJoints.chest, "spine-chest"},
    {contextJoints.chest, contextJoints.neck, "chest-neck"},
    {contextJoints.neck, contextJoints.head, "neck-head"},
    {contextJoints.chest, contextJoints.leftShoulder, "left-clavicle"},
    {contextJoints.leftShoulder, contextJoints.leftElbow, "left-upper-arm"},
    {contextJoints.leftElbow, contextJoints.leftWrist, "left-forearm"},
    {contextJoints.pelvis, contextJoints.leftHip, "left-hip"},
    {contextJoints.leftHip, contextJoints.leftKnee, "left-thigh"},
    {contextJoints.leftKnee, contextJoints.leftAnkle, "left-shin"},
    {contextJoints.pelvis, contextJoints.rightHip, "right-hip"},
    {contextJoints.rightHip, contextJoints.rightKnee, "right-thigh"},
    {contextJoints.rightKnee, contextJoints.rightAnkle, "right-shin"},
    {contextJoints.chest, base, "right-clavicle"},
}
local contextFaces = {}
for _, link in ipairs(contextLinks) do
    local delta = subtract(link[2], link[1])
    local _, faces = bipyramid(context, "fk:context:" .. link[3], magnitude(delta), frameFromX(link[1], delta), "surface", "muted", 1)
    for _, face in ipairs(faces) do contextFaces[#contextFaces + 1] = face end
end
local contextJointOrder = {
    "pelvis", "spine", "chest", "neck", "head",
    "leftShoulder", "leftElbow", "leftWrist",
    "leftHip", "leftKnee", "leftAnkle", "rightHip", "rightKnee", "rightAnkle",
}
for _, name in ipairs(contextJointOrder) do
    local point = contextJoints[name]
    context:point {point = point, radius = name == "head" and 11 or 5, fill = "surface", stroke = "muted", width = 1.5, id = "fk:context-joint:" .. name}
end

local activeBones, activeFaces = {}, {}
for index, link in ipairs(arm) do
    local owner, faces = bipyramid(
        space, "fk:bone:" .. index, link.length, states[1].linkTransforms[index],
        "accent", "foreground", 1
    )
    activeBones[index] = owner
    for _, face in ipairs(faces) do activeFaces[#activeFaces + 1] = face end
end
local joints, labels = {}, {}
local labelOffsets = {{-0.28, -0.25, 0}, {-0.12, 0.30, 0}, {0.14, 0.16, 0}, {0.24, -0.18, 0}}
for index, point in ipairs(states[1].points) do
    joints[index] = space:point {
        point = point, radius = index == 1 and 9 or 7,
        fill = index == 1 and "warning" or "surface", stroke = index == 1 and "warning" or "accent",
        width = 2, layer = 10, id = "fk:j" .. (index - 1),
    }
    local offset = labelOffsets[index]
    labels[index] = space:text {
        text = "J" .. (index - 1), point = add(point, offset), role = "code", size = 10.5,
        fill = index == 1 and "warning" or "foreground", layer = 20,
        id = "fk:j" .. (index - 1) .. ":label",
    }
end

local function angleArc(index)
    local before = states[index]
    local origin = before.points[index]
    local parentOrientation = before.parentOrientations[index]
    local radius = 0.36 + 0.04 * index
    local points = {}
    for sampleIndex = 0, 28 do
        local angle = arm[index].angle * sampleIndex / 28
        local localPoint
        if arm[index].axis == "Z" then
            localPoint = {radius * math.cos(angle), radius * math.sin(angle), 0}
        else
            localPoint = {radius * math.cos(angle), 0, -radius * math.sin(angle)}
        end
        points[#points + 1] = add(origin, apply3(parentOrientation, localPoint))
    end
    local endpoint = points[#points]
    local labelOffsets = {{-0.10, -0.30, 0}, {-0.88, -0.42, 0}, {-0.04, 0.24, 0}}
    return space:plot {
        points = points, color = "focus", width = 3, layer = 12, id = "fk:angle-arc:" .. index,
    }, space:text {
        text = string.format("θ%d = %+d° · local %s", index, round(math.deg(arm[index].angle)), arm[index].axis),
        point = add(endpoint, labelOffsets[index]), align = {0, 0.5}, role = "code", size = 11.5,
        fill = "focus", layer = 20, id = "fk:angle-label:" .. index,
    }
end
local arcs, arcLabels = {}, {}
for index = 1, #arm do arcs[index], arcLabels[index] = angleArc(index) end

local current = {}
for index, point in ipairs(states[1].points) do current[index] = {point[1], point[2], point[3]} end
local jointBeatStart = {}
local function moveToPose(state, activeJoint)
    jointBeatStart[activeJoint] = chain:duration()
    local changes = {{target = joints[activeJoint], fill = "focus", stroke = "focus"}}
    if activeJoint > 1 then
        changes[#changes + 1] = {target = arcs[activeJoint - 1], opacity = 0.24}
        changes[#changes + 1] = {target = arcLabels[activeJoint - 1], opacity = 0}
    end
    for index = activeJoint + 1, #joints do
        local delta = subtract(state.points[index], current[index])
        changes[#changes + 1] = {target = joints[index], shift = delta}
        changes[#changes + 1] = {target = labels[index], shift = delta}
    end
    for index = activeJoint, #activeBones do
        changes[#changes + 1] = {target = activeBones[index], transform = state.linkTransforms[index]}
    end
    chain:play(changes, 0.95, "ease_in_out", 0)
    for index = activeJoint + 1, #joints do
        local point = state.points[index]
        current[index] = {point[1], point[2], point[3]}
    end
    chain:create(arcs[activeJoint], 0.30, "ease_out")
    chain:fade_in(arcLabels[activeJoint], {duration = 0.20, curve = "gentle"})
    chain:play({{target = joints[activeJoint], fill = "surface", stroke = "accent"}}, 0.20, "gentle", 0)
    chain:wait(0.28)
end

chain:create(space, 0.30, "ease_out")
chain:fade_in(context, {duration = 0.48, curve = "gentle"})
chain:draw_border_then_fill(activeFaces, 0.50, "ease_out", 0.02)
chain:create(joints, 0.36, "ease_out", 0.05)
for _, label in ipairs(labels) do chain:fade_in(label, {duration = 0.12, curve = "gentle"}) end
chain:wait(0.55)
for index = 1, #arm do moveToPose(states[index + 1], index) end
local poseReady = chain:duration()
chain:play({{target = joints[4], fill = "result", stroke = "result"}}, 0.34, "ease_out", 0)
chain:wait(2.05)
local chainEnd = chain:duration()

local ledger = tmath.scene {
    width = 316, height = 405, fps = 30, loop = false, theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 7.4},
}
local hierarchy = ledger:text {
    text = "pelvis → spine → shoulder\n                 └→ elbow → wrist → hand",
    point = {-2.65, 2.72}, align = {0, 0.5}, role = "code", size = 11.5,
    fill = "muted", id = "fk:hierarchy",
}
ledger:fade_in(hierarchy, {duration = 0.40, curve = "gentle"})
local rows = {}
for index, link in ipairs(arm) do
    local y = 1.55 - (index - 1) * 0.93
    local row = ledger:group {id = "fk:ledger-angle:" .. index}
    row:text {
        text = string.format("R%d_world = R%d_parent · R%s(%+d°)", index, index, link.axis, round(math.deg(link.angle))),
        point = {-2.62, y}, align = {0, 0.5}, role = "code", size = 11.5,
        fill = index == 3 and "result" or "foreground", id = "fk:ledger-angle:" .. index .. ":text",
    }
    rows[index] = row
end
local endpoint = states[4].points[4]
local result = ledger:text {
    text = string.format("hand = (%.2f, %.2f, %.2f)", endpoint[1], endpoint[2], endpoint[3]),
    point = {0, -1.62}, role = "code", fill = "result", id = "fk:end-effector",
}
local invariant = ledger:text {
    text = string.format("bone lengths = %.2f · %.2f · %.2f", arm[1].length, arm[2].length, arm[3].length),
    point = {0, -2.34}, role = "code", size = 11.5, fill = "muted", id = "fk:lengths",
}
local direction = ledger:text {
    text = "FK input: local angles\nFK output: world joint poses",
    point = {0, -3.03}, role = "code", size = 11.5, fill = "foreground", id = "fk:direction",
}
local function waitUntil(scene, time)
    local remaining = time - scene:duration()
    if remaining > 0 then scene:wait(remaining) end
end
for index, row in ipairs(rows) do
    waitUntil(ledger, jointBeatStart[index])
    ledger:fade_in(row, {shift = {0.10, 0}, duration = 0.36, curve = "ease_out"})
end
waitUntil(ledger, poseReady)
ledger:fade_in(result, {shift = {0, 0.10}, duration = 0.40, curve = "gentle"})
ledger:fade_in(invariant, {duration = 0.28, curve = "gentle"})
ledger:fade_in(direction, {duration = 0.30, curve = "gentle"})
waitUntil(ledger, chainEnd)

local title = page:text {
    text = "Forward kinematics · character arm rig", point = {0, 2.65}, role = "h2",
    fill = "foreground", id = "fk:title",
}
local subtitle = page:text {
    text = "bipyramid bones · local-angle arcs · root-to-leaf world transforms",
    point = {0, 2.25}, role = "text", fill = "muted", id = "fk:subtitle",
}
page:fade_in(title, {shift = {0, -0.08}, duration = 0.38, curve = "gentle"})
page:fade_in(subtitle, {duration = 0.28, curve = "gentle"})
page:viewport(chain, {x = 0.015, y = 0.23, width = 0.632, height = 0.72})
page:viewport(ledger, {x = 0.657, y = 0.23, width = 0.316, height = 0.72})
return page
