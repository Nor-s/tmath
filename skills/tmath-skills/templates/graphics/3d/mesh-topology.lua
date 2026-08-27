-- Reference study: build one closed indexed mesh as vertices -> unique edges -> faces.
-- The final object is an explicit octahedral mesh, not a SurfaceMesh lattice.
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
    assert(length > 1e-9, "degenerate face")
    return scale(v, 1 / length)
end
local function multiply4(a, b)
    local result = {}
    for row = 0, 3 do
        for column = 0, 3 do
            local value = 0
            for k = 0, 3 do value = value + a[row * 4 + k + 1] * b[k * 4 + column + 1] end
            result[row * 4 + column + 1] = value
        end
    end
    return result
end
local function rotateX(angle)
    local c, s = math.cos(angle), math.sin(angle)
    return {1, 0, 0, 0, 0, c, -s, 0, 0, s, c, 0, 0, 0, 0, 1}
end
local function rotateY(angle)
    local c, s = math.cos(angle), math.sin(angle)
    return {c, 0, s, 0, 0, 1, 0, 0, -s, 0, c, 0, 0, 0, 0, 1}
end

local vertices = {
    {id = "v0", p = {0, 1.46, 0}},
    {id = "v1", p = {1.24, 0.06, 0}},
    {id = "v2", p = {0.04, 0, 1.08}},
    {id = "v3", p = {-1.16, -0.04, 0.02}},
    {id = "v4", p = {-0.02, 0, -0.98}},
    {id = "v5", p = {0, -1.28, 0}},
}
local indexBuffer = {
    {1, 2, 3}, {1, 3, 4}, {1, 4, 5}, {1, 5, 2},
    {6, 3, 2}, {6, 4, 3}, {6, 5, 4}, {6, 2, 5},
}

local faces = {}
for faceIndex, source in ipairs(indexBuffer) do
    local indices = {source[1], source[2], source[3]}
    local a, b, c = vertices[indices[1]].p, vertices[indices[2]].p, vertices[indices[3]].p
    local centroid = scale(add(add(a, b), c), 1 / 3)
    local normal = normalize(cross(subtract(b, a), subtract(c, a)))
    if dot(normal, centroid) < 0 then
        indices[2], indices[3] = indices[3], indices[2]
        b, c = c, b
        normal = normalize(cross(subtract(b, a), subtract(c, a)))
    end
    faces[faceIndex] = {indices = indices, points = {a, b, c}, centroid = centroid, normal = normal}
end

local edges, edgeSeen = {}, {}
for _, face in ipairs(faces) do
    for corner = 1, 3 do
        local first = face.indices[corner]
        local second = face.indices[corner % 3 + 1]
        local low, high = math.min(first, second), math.max(first, second)
        local key = low .. ":" .. high
        if not edgeSeen[key] then
            edgeSeen[key] = true
            edges[#edges + 1] = {low, high, key}
        end
    end
end
assert(#vertices == 6 and #edges == 12 and #faces == 8, "closed octahedron topology changed")
assert(#vertices - #edges + #faces == 2, "Euler characteristic must be two")

local selectedIndex = 2
local selected = faces[selectedIndex]
local finalTurn = multiply4(rotateY(math.rad(32)), rotateX(math.rad(-9)))

local spatial = tmath.scene {
    width = 620, height = 410, fps = 30, loop = false, theme = "adaptive_vscode",
    camera = {
        mode = "fixed", view = "3d", eye = {4.6, 3.35, 6.6}, target = {0, 0.08, 0},
        up = {0, 1, 0}, projection = "perspective", fov = 0.69, near = 0.1, far = 30,
    },
}
local space = spatial:space {
    x = {-2.2, 2.2, 1}, y = {-1.8, 1.9, 1}, z = {-1.8, 1.8, 1},
    opacity = 0.16, id = "mesh:space",
}
local mesh = space:group {id = "mesh:closed-object"}

local pointObjects, pointLabels = {}, {}
for index, vertex in ipairs(vertices) do
    pointObjects[index] = mesh:point {
        point = vertex.p, radius = 7, fill = index == 1 and "result" or "accent",
        stroke = "background", width = 1.5, layer = 10, id = "mesh:" .. vertex.id,
    }
    pointLabels[index] = mesh:text {
        text = vertex.id, point = add(vertex.p, {0, 0.20, 0}), role = "code",
        fill = index == 1 and "result" or "foreground", layer = 20,
        id = "mesh:" .. vertex.id .. ":label",
    }
end

local edgeObjects = {}
for index, edge in ipairs(edges) do
    edgeObjects[index] = mesh:line {
        from = vertices[edge[1]].p, to = vertices[edge[2]].p,
        color = "border", width = 2.2, id = "mesh:edge:" .. edge[3],
    }
end

local faceObjects = {}
for index, face in ipairs(faces) do
    faceObjects[index] = mesh:polygon {
        points = face.points,
        fill = index == selectedIndex and "#4fc1ff66" or (index % 2 == 0 and "#4fc1ff38" or "#8b5cf638"),
        stroke = index == selectedIndex and "focus" or "border",
        width = index == selectedIndex and 2.8 or 1.2,
        id = "mesh:face:" .. (index - 1),
    }
end

local a, b, c = selected.points[1], selected.points[2], selected.points[3]
local winding = {
    mesh:line {from = a, to = b, color = "focus", width = 4, layer = 8, id = "mesh:winding:0"},
    mesh:line {from = b, to = c, color = "focus", width = 4, layer = 8, id = "mesh:winding:1"},
    mesh:line {from = c, to = a, color = "focus", width = 4, layer = 8, id = "mesh:winding:2"},
}
local normal = mesh:vector {
    origin = selected.centroid, value = scale(selected.normal, 1.05), color = "result",
    width = 4, tip = 13, layer = 12, id = "mesh:selected-normal",
}
local normalLabel = mesh:text {
    text = "N(T1)", point = add(selected.centroid, scale(selected.normal, 1.28)),
    role = "code", fill = "result", layer = 20, id = "mesh:selected-normal-label",
}

spatial:create(space, 0.30, "ease_out")
spatial:create(pointObjects, 0.42, "ease_out", 0.07)
for _, label in ipairs(pointLabels) do spatial:fade_in(label, {duration = 0.10, curve = "gentle"}) end
local verticesReady = spatial:duration()
spatial:wait(0.32)
local indicesReady = spatial:duration()
spatial:create(edgeObjects, 0.58, "ease_out", 0.035)
local edgesReady = spatial:duration()
spatial:wait(0.36)
spatial:draw_border_then_fill(faceObjects, 0.62, "ease_out", 0.055)
local facesReady = spatial:duration()
spatial:wait(0.42)
spatial:create(winding, 0.58, "linear", 0.08)
spatial:create(normal, 0.42, "ease_out")
spatial:fade_in(normalLabel, {duration = 0.20, curve = "gentle"})
local normalReady = spatial:duration()
spatial:wait(0.72)
spatial:transform(mesh, finalTurn, 1.05, "ease_in_out")
spatial:wait(2.0)
local spatialEnd = spatial:duration()

local ledger = tmath.scene {
    width = 336, height = 405, fps = 30, loop = false, theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 7.4},
}
local stages = {
    {"1  vertex buffer", "6 stable vertex records", "accent"},
    {"2  index buffer", "8 × triangle indices", "focus"},
    {"3  unique edges", "12 derived edge pairs", "warning"},
    {"4  closed mesh", "V − E + F = 6 − 12 + 8 = 2", "result"},
}
local stageGroups = {}
for index, stage in ipairs(stages) do
    local y = 2.65 - (index - 1) * 1.12
    local group = ledger:group {id = "mesh:ledger-stage:" .. index}
    group:text {
        text = stage[1], point = {-2.75, y + 0.20}, align = {0, 0.5}, role = "code",
        fill = stage[3], id = "mesh:ledger-stage:" .. index .. ":title",
    }
    group:text {
        text = stage[2], point = {-2.75, y - 0.24}, align = {0, 0.5}, role = "code", size = 11.5,
        fill = "foreground", id = "mesh:ledger-stage:" .. index .. ":value",
    }
    stageGroups[index] = group
end
local selectedText = ledger:text {
    text = string.format(
        "T1 = [%d, %d, %d]\nN = normalize((v%d−v%d) × (v%d−v%d))\n  = (%.2f, %.2f, %.2f)",
        selected.indices[1] - 1, selected.indices[2] - 1, selected.indices[3] - 1,
        selected.indices[2] - 1, selected.indices[1] - 1,
        selected.indices[3] - 1, selected.indices[1] - 1,
        selected.normal[1], selected.normal[2], selected.normal[3]
    ),
    point = {-2.75, -2.27}, align = {0, 0.5}, role = "code", size = 11.5,
    fill = "result", id = "mesh:selected-face-ledger",
}
local function waitUntil(scene, time)
    local remaining = time - scene:duration()
    if remaining > 0 then scene:wait(remaining) end
end
local stageTimes = {verticesReady, indicesReady, edgesReady, facesReady}
for index, group in ipairs(stageGroups) do
    waitUntil(ledger, stageTimes[index] - 0.40)
    ledger:fade_in(group, {shift = {0.10, 0}, duration = 0.40, curve = "ease_out"})
end
waitUntil(ledger, normalReady - 0.42)
ledger:fade_in(selectedText, {duration = 0.42, curve = "gentle"})
waitUntil(ledger, spatialEnd)

local title = page:text {
    text = "Mesh topology becomes a closed object", point = {0, 2.65}, role = "h2",
    fill = "foreground", id = "mesh:title",
}
local subtitle = page:text {
    text = "vertices → shared edges → ordered faces → inspectable 3D mesh",
    point = {0, 2.25}, role = "text", fill = "muted", id = "mesh:subtitle",
}
page:fade_in(title, {shift = {0, -0.08}, duration = 0.38, curve = "gentle"})
page:fade_in(subtitle, {duration = 0.28, curve = "gentle"})
page:viewport(spatial, {x = 0.015, y = 0.23, width = 0.613, height = 0.72})
page:viewport(ledger, {x = 0.638, y = 0.23, width = 0.336, height = 0.72})
return page
