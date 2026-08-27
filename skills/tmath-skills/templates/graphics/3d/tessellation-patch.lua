-- Reference study: an integer level-4 triangular patch is generated in
-- barycentric space, then each generated vertex is evaluated onto a displaced
-- surface. This is a didactic equal subdivision; replace it with the target
-- API's exact spacing, winding, and inner/outer tessellation rules.
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
local function normalize(v)
    local length = math.sqrt(dot(v, v))
    assert(length > 1e-9, "patch must be non-degenerate")
    return scale(v, 1 / length)
end
local function barycentric(a, b, c, wa, wb, wc)
    return add(add(scale(a, wa), scale(b, wb)), scale(c, wc))
end

local control = {
    {-2.20, -0.58, -1.48},
    {2.18, -0.58, -1.12},
    {-0.18, -0.58, 2.02},
}
local patchNormal = normalize(cross(subtract(control[2], control[1]), subtract(control[3], control[1])))
if patchNormal[2] < 0 then patchNormal = scale(patchNormal, -1) end
local level = 4
local generated, lookup = {}, {}
local function key(i, j) return i .. ":" .. j end
for i = 0, level do
    for j = 0, level - i do
        local wb, wc = i / level, j / level
        local wa = 1 - wb - wc
        local flat = barycentric(control[1], control[2], control[3], wa, wb, wc)
        local displacement = 18.0 * wa * wb * wc
        local evaluated = add(flat, scale(patchNormal, displacement))
        local vertex = {
            id = string.format("g:%d:%d", i, j), i = i, j = j,
            weights = {wa, wb, wc}, flat = flat, evaluated = evaluated,
        }
        generated[#generated + 1] = vertex
        lookup[key(i, j)] = #generated
    end
end
local topology = {}
for i = 0, level - 1 do
    for j = 0, level - i - 1 do
        topology[#topology + 1] = {
            lookup[key(i, j)], lookup[key(i + 1, j)], lookup[key(i, j + 1)],
        }
        if i + j <= level - 2 then
            topology[#topology + 1] = {
                lookup[key(i + 1, j)], lookup[key(i + 1, j + 1)], lookup[key(i, j + 1)],
            }
        end
    end
end
assert(#generated == 15 and #topology == 16, "level-4 triangular tessellation counts changed")

local spatial = tmath.scene {
    width = 640, height = 410, fps = 30, loop = false, theme = "adaptive_vscode",
    camera = {
        mode = "fixed", view = "3d", eye = {4.8, 5.55, 6.25}, target = {0, -0.05, 0.15},
        up = {0, 1, 0}, projection = "perspective", fov = 0.68, near = 0.1, far = 30,
    },
}
local space = spatial:space {
    x = {-2.8, 2.8, 1}, y = {-1.2, 2.0, 0.5}, z = {-2.1, 2.5, 1},
    opacity = 0.13, id = "tess:space",
}
local patch = space:group {id = "tess:patch"}
local controlFace = patch:polygon {
    points = control, fill = "#ffd86616", stroke = "warning", width = 3,
    id = "tess:control-patch",
}
local controlPoints, controlLabels = {}, {}
for index, point in ipairs(control) do
    controlPoints[index] = patch:point {
        point = point, radius = 8, fill = "warning", stroke = "background", width = 1.4,
        layer = 10, id = "tess:control:" .. (index - 1),
    }
    controlLabels[index] = patch:text {
        text = "cp" .. (index - 1), point = add(point, {0, 0.22, 0}), role = "code",
        fill = "warning", layer = 20, id = "tess:control-label:" .. (index - 1),
    }
end
local flatFaces = {}
for faceIndex, indices in ipairs(topology) do
    flatFaces[faceIndex] = patch:polygon {
        points = {
            generated[indices[1]].flat, generated[indices[2]].flat, generated[indices[3]].flat,
        },
        fill = faceIndex % 2 == 0 and "#4fc1ff2c" or "#8b5cf62c",
        stroke = "accent", width = 1.4, id = "tess:flat-face:" .. faceIndex,
    }
end
local flatPointGroup = patch:group {id = "tess:generated-flat-points"}
local flatPoints = {}
for index, vertex in ipairs(generated) do
    flatPoints[index] = flatPointGroup:point {
        point = vertex.flat, radius = 4.5, fill = "focus", stroke = "background", width = 0.8,
        layer = 10, id = "tess:flat:" .. vertex.id,
    }
end

spatial:create(space, 0.30, "ease_out")
spatial:draw_border_then_fill(controlFace, 0.55, "ease_out")
spatial:create(controlPoints, 0.30, "ease_out", 0.08)
for _, label in ipairs(controlLabels) do spatial:fade_in(label, {duration = 0.12, curve = "gentle"}) end
local controlReady = spatial:duration()
spatial:wait(0.45)
local generationStart = spatial:duration()
spatial:draw_border_then_fill(flatFaces, 0.62, "ease_out", 0.035)
spatial:create(flatPoints, 0.34, "ease_out", 0.025)
local topologyReady = spatial:duration()
spatial:wait(0.72)
spatial:fade_out(flatPointGroup, {duration = 0.24, curve = "gentle"})
local evaluationStart = spatial:duration()

-- Attach compatible targets at the current cursor, then preserve triangle IDs
-- through the evaluation deformation.
local curvedFaces = {}
for faceIndex, indices in ipairs(topology) do
    curvedFaces[faceIndex] = patch:polygon {
        points = {
            generated[indices[1]].evaluated, generated[indices[2]].evaluated, generated[indices[3]].evaluated,
        },
        fill = faceIndex % 2 == 0 and "#4fc1ff4c" or "#8b5cf64c",
        stroke = "result", width = 1.5, id = "tess:evaluated-face:" .. faceIndex,
    }
end
spatial:morph(flatFaces, curvedFaces, 1.25, "ease_in_out", 0)
local curvedPoints = {}
for index, vertex in ipairs(generated) do
    curvedPoints[index] = patch:point {
        point = vertex.evaluated, radius = 4.5, fill = "result", stroke = "background", width = 0.8,
        layer = 10, id = "tess:evaluated:" .. vertex.id,
    }
end
spatial:create(curvedPoints, 0.34, "ease_out", 0.025)
local evaluationReady = spatial:duration()
spatial:wait(0.72)
spatial:look({
    view = "3d", eye = {6.25, 2.75, 5.45}, target = {0, -0.02, 0.18}, up = {0, 1, 0},
    projection = "perspective", fov = 0.68, near = 0.1, far = 30,
}, 1.40, "ease_in_out")
spatial:wait(2.05)
local spatialEnd = spatial:duration()

local ledger = tmath.scene {
    width = 316, height = 405, fps = 30, loop = false, theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 7.4},
}
local stages = {
    {"1  control patch", "3 control points", "warning"},
    {"2  tessellator", "level = 4 · equal integer subdivision", "focus"},
    {"3  generated topology", "15 vertices · 16 triangles", "accent"},
    {"4  evaluation", "P′ = bary(cp) + N · h(w)", "result"},
}
local groups = {}
for index, stage in ipairs(stages) do
    local y = 2.55 - (index - 1) * 1.25
    local group = ledger:group {id = "tess:stage:" .. index}
    group:text {
        text = stage[1], point = {-2.62, y + 0.22}, align = {0, 0.5}, role = "code",
        fill = stage[3], id = "tess:stage:" .. index .. ":title",
    }
    group:text {
        text = stage[2], point = {-2.62, y - 0.24}, align = {0, 0.5}, role = "code", size = 11.3,
        fill = "foreground", id = "tess:stage:" .. index .. ":value",
    }
    groups[index] = group
end
local invariant = ledger:text {
    text = "control points ≠ generated vertices\ntopology first · displacement second",
    point = {0, -2.95}, role = "code", size = 11.5, fill = "muted", id = "tess:invariant",
}
local function waitUntil(scene, time)
    local remaining = time - scene:duration()
    if remaining > 0 then scene:wait(remaining) end
end
local stageTimes = {controlReady, generationStart, topologyReady, evaluationStart}
for index, group in ipairs(groups) do
    waitUntil(ledger, stageTimes[index] - 0.42)
    ledger:fade_in(group, {shift = {0.10, 0}, duration = 0.42, curve = "ease_out"})
end
waitUntil(ledger, evaluationReady)
ledger:fade_in(invariant, {duration = 0.36, curve = "gentle"})
waitUntil(ledger, spatialEnd)

local title = page:text {
    text = "Tessellation: patch → topology → evaluation", point = {0, 2.65}, role = "h2",
    fill = "foreground", id = "tess:title",
}
local subtitle = page:text {
    text = "generated barycentric vertices keep their identity as the domain evaluation bends the mesh",
    point = {0, 2.25}, role = "text", fill = "muted", id = "tess:subtitle",
}
page:fade_in(title, {shift = {0, -0.08}, duration = 0.38, curve = "gentle"})
page:fade_in(subtitle, {duration = 0.28, curve = "gentle"})
page:viewport(spatial, {x = 0.015, y = 0.23, width = 0.632, height = 0.72})
page:viewport(ledger, {x = 0.657, y = 0.23, width = 0.316, height = 0.72})
return page
