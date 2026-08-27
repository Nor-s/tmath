-- Reference study: a primary ray collides with a finite triangle surface, then
-- a finite shadow ray is blocked by a second triangle. Intersections use the
-- same Moller-Trumbore results shown in the ledger.
local page = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6},
}

local function add(a, b) return {a[1] + b[1], a[2] + b[2], a[3] + b[3]} end
local function subtract(a, b) return {a[1] - b[1], a[2] - b[2], a[3] - b[3]} end
local function scale(v, amount) return {v[1] * amount, v[2] * amount, v[3] * amount} end
local function dot(a, b) return a[1] * b[1] + a[2] * b[2] + a[3] * b[3] end
local function cross(a, b)
    return {
        a[2] * b[3] - a[3] * b[2],
        a[3] * b[1] - a[1] * b[3],
        a[1] * b[2] - a[2] * b[1],
    }
end
local function length(v) return math.sqrt(dot(v, v)) end
local function normalize(v)
    local magnitude = length(v)
    assert(magnitude > 1e-9, "cannot normalize a zero vector")
    return scale(v, 1 / magnitude)
end
local function weighted(a, wa, b, wb, c, wc)
    return add(add(scale(a, wa), scale(b, wb)), scale(c, wc))
end
local function rayTriangle(origin, direction, a, b, c, epsilon)
    local edge1, edge2 = subtract(b, a), subtract(c, a)
    local p = cross(direction, edge2)
    local determinant = dot(edge1, p)
    if math.abs(determinant) <= epsilon then return nil end
    local inverse = 1 / determinant
    local offset = subtract(origin, a)
    local u = dot(offset, p) * inverse
    if u < 0 or u > 1 then return nil end
    local q = cross(offset, edge1)
    local v = dot(direction, q) * inverse
    if v < 0 or u + v > 1 then return nil end
    local t = dot(edge2, q) * inverse
    if t <= epsilon then return nil end
    return {t = t, u = u, v = v, w = 1 - u - v}
end

local receiverVertices = {
    {-2.25, -0.78, -1.55},
    {2.18, -0.46, -1.08},
    {1.72, 0.34, 1.82},
    {-2.02, -0.02, 1.54},
}
local receiverIndices = {{1, 2, 3}, {1, 3, 4}}
local target = weighted(receiverVertices[1], 0.22, receiverVertices[2], 0.33, receiverVertices[3], 0.45)
local rayOrigin = {-3.62, 2.70, 4.48}
local rayDirection = normalize(subtract(target, rayOrigin))
local epsilon = 1e-5

local candidates = {}
for faceIndex, face in ipairs(receiverIndices) do
    local hit = rayTriangle(
        rayOrigin, rayDirection,
        receiverVertices[face[1]], receiverVertices[face[2]], receiverVertices[face[3]], epsilon
    )
    candidates[faceIndex] = hit
end
local chosenFace, chosen = nil, nil
for faceIndex, candidate in ipairs(candidates) do
    if candidate and (not chosen or candidate.t < chosen.t) then
        chosenFace, chosen = faceIndex, candidate
    end
end
assert(chosenFace == 1 and chosen, "reference ray must hit receiver triangle T0")
local hitPoint = add(rayOrigin, scale(rayDirection, chosen.t))
local chosenIndices = receiverIndices[chosenFace]
local a, b, c = receiverVertices[chosenIndices[1]], receiverVertices[chosenIndices[2]], receiverVertices[chosenIndices[3]]
local hitNormal = normalize(cross(subtract(b, a), subtract(c, a)))
if dot(hitNormal, {0, 1, 0}) < 0 then hitNormal = scale(hitNormal, -1) end
assert(length(subtract(hitPoint, target)) < 1e-8, "hit position must come from the primary ray")

local shadowBias = 0.025
local shadowOrigin = add(hitPoint, scale(hitNormal, shadowBias))
local lightPosition = {3.30, 3.35, 2.75}
local lightVector = subtract(lightPosition, shadowOrigin)
local lightDistance = length(lightVector)
local shadowDirection = normalize(lightVector)
local blockerCenter = add(shadowOrigin, scale(shadowDirection, lightDistance * 0.56))
local helper = math.abs(dot(shadowDirection, {0, 1, 0})) > 0.90 and {1, 0, 0} or {0, 1, 0}
local blockerU = normalize(cross(shadowDirection, helper))
local blockerV = normalize(cross(shadowDirection, blockerU))
local blockerVertices = {
    add(add(blockerCenter, scale(blockerU, 0.72)), scale(blockerV, -0.44)),
    add(add(blockerCenter, scale(blockerU, -0.72)), scale(blockerV, -0.44)),
    add(blockerCenter, scale(blockerV, 0.78)),
}
local blockerHit = rayTriangle(
    shadowOrigin, shadowDirection,
    blockerVertices[1], blockerVertices[2], blockerVertices[3], epsilon
)
assert(blockerHit and blockerHit.t < lightDistance - shadowBias, "blocker must lie on the finite light segment")
local blockerPoint = add(shadowOrigin, scale(shadowDirection, blockerHit.t))

local spatial = tmath.scene {
    width = 640, height = 410, fps = 30, loop = false, theme = "adaptive_vscode",
    camera = {
        mode = "fixed", view = "3d", eye = {6.2, 4.65, 8.8}, target = {0, 0.45, 0.65},
        up = {0, 1, 0}, projection = "perspective", fov = 0.70, near = 0.1, far = 40,
    },
}
local space = spatial:space {
    x = {-4.2, 4.2, 1}, y = {-1.4, 4.0, 1}, z = {-2.2, 5.2, 1},
    opacity = 0.12, id = "ray:space",
}
local receiver = space:group {id = "ray:receiver-mesh"}
local receiverFaces = {}
for faceIndex, face in ipairs(receiverIndices) do
    receiverFaces[faceIndex] = receiver:polygon {
        points = {
            receiverVertices[face[1]], receiverVertices[face[2]], receiverVertices[face[3]],
        },
        fill = faceIndex == chosenFace and "#4fc1ff55" or "#4fc1ff24",
        stroke = faceIndex == chosenFace and "focus" or "border",
        width = faceIndex == chosenFace and 2.8 or 1.5,
        id = "ray:receiver-face:" .. (faceIndex - 1),
    }
end
local receiverEdges = {
    receiver:line {from = receiverVertices[1], to = receiverVertices[2], color = "border", width = 2, id = "ray:receiver-edge:01"},
    receiver:line {from = receiverVertices[2], to = receiverVertices[3], color = "border", width = 2, id = "ray:receiver-edge:12"},
    receiver:line {from = receiverVertices[3], to = receiverVertices[4], color = "border", width = 2, id = "ray:receiver-edge:23"},
    receiver:line {from = receiverVertices[4], to = receiverVertices[1], color = "border", width = 2, id = "ray:receiver-edge:30"},
    receiver:line {from = receiverVertices[1], to = receiverVertices[3], color = "focus", width = 2.5, id = "ray:receiver-edge:02"},
}
local rayEnd = add(hitPoint, scale(rayDirection, 1.25))
local fullRay = space:line {
    from = rayOrigin, to = rayEnd, color = "muted", width = 2, dash = {7, 6}, id = "ray:primary-lineage",
}
local primary = space:line {
    from = rayOrigin, to = hitPoint, color = "focus", width = 4, layer = 5, id = "ray:primary-hit-segment",
}
local rayOriginPoint = space:point {
    point = rayOrigin, radius = 8, fill = "secondary", stroke = "background", width = 1.5,
    layer = 10, id = "ray:origin",
}
local hit = space:point {
    point = hitPoint, radius = 8, fill = "result", stroke = "background", width = 1.5,
    layer = 10, id = "ray:hit",
}
local normal = space:vector {
    origin = hitPoint, value = scale(hitNormal, 1.05), color = "result", width = 4, tip = 13,
    layer = 12, id = "ray:normal",
}
local hitLabel = space:text {
    text = "hit T0", point = add(hitPoint, scale(hitNormal, 1.28)), role = "code",
    fill = "result", layer = 20, id = "ray:hit-label",
}
local blocker = space:polygon {
    points = blockerVertices, fill = "#ffd86645", stroke = "warning", width = 2.5,
    id = "ray:blocker-surface",
}
local lightPoint = space:point {
    point = lightPosition, radius = 9, fill = "warning", stroke = "background", width = 1.5,
    layer = 10, id = "ray:light",
}
local lightLabel = space:text {
    text = "light", point = add(lightPosition, {0, 0.26, 0}), role = "code",
    fill = "warning", layer = 20, id = "ray:light-label",
}
local lightSegment = space:line {
    from = shadowOrigin, to = lightPosition, color = "muted", width = 2, dash = {7, 6}, id = "ray:light-segment",
}
local blockedSegment = space:line {
    from = shadowOrigin, to = blockerPoint, color = "warning", width = 4, layer = 5,
    id = "ray:shadow-to-blocker",
}
local blockerPointObject = space:point {
    point = blockerPoint, radius = 7, fill = "warning", stroke = "background", width = 1.2,
    layer = 10, id = "ray:blocker-hit",
}

spatial:create(space, 0.30, "ease_out")
spatial:draw_border_then_fill(receiverFaces, 0.48, "ease_out", 0.05)
spatial:create(receiverEdges, 0.42, "ease_out", 0.035)
spatial:create({rayOriginPoint, fullRay}, 0.34, "ease_out", 0.06)
spatial:wait(0.36)
spatial:create(primary, 0.90, "linear")
local candidatesReady = spatial:duration()
spatial:create({hit, normal}, 0.40, "ease_out", 0.08)
spatial:fade_in(hitLabel, {duration = 0.22, curve = "gentle"})
local hitReady = spatial:duration()
spatial:wait(0.72)
spatial:create({lightPoint, blocker}, 0.42, "ease_out", 0.08)
spatial:fade_in(lightLabel, {duration = 0.18, curve = "gentle"})
local blockerReady = spatial:duration()
spatial:create(lightSegment, 0.70, "linear")
spatial:create(blockedSegment, 0.52, "linear")
spatial:create(blockerPointObject, 0.22, "ease_out")
local visibilityReady = spatial:duration()
spatial:wait(2.05)
local spatialEnd = spatial:duration()

local ledger = tmath.scene {
    width = 316, height = 405, fps = 30, loop = false, theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 7.4},
}
local equation = ledger:text {
    text = "r(t) = o + t d\ntriangle test → (t, u, v)",
    point = {-2.62, 2.72}, align = {0, 0.5}, role = "code", size = 12,
    fill = "foreground", id = "ray:equation",
}
local candidatesText = ledger:text {
    text = string.format(
        "T0  t = %.3f\n    bary = (%.3f, %.3f, %.3f)\nT1  miss",
        chosen.t, chosen.w, chosen.u, chosen.v
    ),
    point = {-2.62, 1.25}, align = {0, 0.5}, role = "code", size = 11.7,
    fill = "focus", id = "ray:candidates",
}
local chosenText = ledger:text {
    text = string.format(
        "nearest positive: T%d\nhit = (%.2f, %.2f, %.2f)",
        chosenFace - 1, hitPoint[1], hitPoint[2], hitPoint[3]
    ),
    point = {-2.62, -0.34}, align = {0, 0.5}, role = "code", size = 11.7,
    fill = "result", id = "ray:chosen",
}
local shadowText = ledger:text {
    text = string.format(
        "shadow interval (%.3f, %.3f)\nblocker t = %.3f < light distance",
        shadowBias, lightDistance - shadowBias, blockerHit.t
    ),
    point = {-2.62, -1.75}, align = {0, 0.5}, role = "code", size = 11.3,
    fill = "foreground", id = "ray:shadow-test",
}
local resultText = ledger:text {
    text = "visibility = 0 · blocked by triangle", point = {0, -3.00}, role = "code",
    fill = "warning", id = "ray:visibility",
}
ledger:fade_in(equation, {duration = 0.34, curve = "gentle"})
local function waitUntil(scene, time)
    local remaining = time - scene:duration()
    if remaining > 0 then scene:wait(remaining) end
end
waitUntil(ledger, candidatesReady - 0.44)
ledger:fade_in(candidatesText, {shift = {0, 0.08}, duration = 0.44, curve = "ease_out"})
waitUntil(ledger, hitReady - 0.38)
ledger:fade_in(chosenText, {duration = 0.38, curve = "gentle"})
waitUntil(ledger, blockerReady - 0.40)
ledger:fade_in(shadowText, {duration = 0.40, curve = "gentle"})
waitUntil(ledger, visibilityReady - 0.36)
ledger:fade_in(resultText, {duration = 0.36, curve = "gentle"})
waitUntil(ledger, spatialEnd)

local title = page:text {
    text = "Ray → finite surface → shadow visibility", point = {0, 2.65}, role = "h2",
    fill = "foreground", id = "ray:title",
}
local subtitle = page:text {
    text = "triangle barycentrics choose the hit; a second surface blocks the light segment",
    point = {0, 2.25}, role = "text", fill = "muted", id = "ray:subtitle",
}
page:fade_in(title, {shift = {0, -0.08}, duration = 0.38, curve = "gentle"})
page:fade_in(subtitle, {duration = 0.28, curve = "gentle"})
page:viewport(spatial, {x = 0.015, y = 0.23, width = 0.632, height = 0.72})
page:viewport(ledger, {x = 0.657, y = 0.23, width = 0.316, height = 0.72})
return page
