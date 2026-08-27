-- One spherical state drives the point, projection, radius, and both angle arcs.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = {
        mode = "fixed", view = "3d", eye = {6.2, 4.5, 7.4}, target = {0, 0, 0},
        up = {0, 1, 0}, projection = "perspective", fov = 0.7, near = 0.1, far = 100,
    },
}

local LAYER = {geometry = 0, text = 40}
local radius, arcRadius, samples = 1.75, 0.58, 28
local eye, up = {6.2, 4.5, 7.4}, {0, 1, 0}

local function add(a, b)
    return {a[1] + b[1], a[2] + b[2], a[3] + b[3]}
end

local function scale(v, amount)
    return {v[1] * amount, v[2] * amount, v[3] * amount}
end

local function cross(a, b)
    return {
        a[2] * b[3] - a[3] * b[2],
        a[3] * b[1] - a[1] * b[3],
        a[1] * b[2] - a[2] * b[1],
    }
end

local function normalize(v)
    local length = math.sqrt(v[1] * v[1] + v[2] * v[2] + v[3] * v[3])
    return {v[1] / length, v[2] / length, v[3] / length}
end

-- Keep point glyphs camera-facing while their centers remain exact 3D coordinates.
local forward = normalize(scale(eye, -1))
local screenRight = normalize(cross(forward, up))
local screenUp = normalize(cross(screenRight, forward))
local function marker(center, size)
    return {
        add(center, scale(screenRight, -size)),
        add(center, scale(screenUp, size)),
        add(center, scale(screenRight, size)),
        add(center, scale(screenUp, -size)),
    }
end

local function spherical(theta, phi)
    local cosPhi = math.cos(phi)
    local point = {
        radius * cosPhi * math.cos(theta),
        radius * math.sin(phi),
        radius * cosPhi * math.sin(theta),
    }
    local projected = {point[1], 0, point[3]}
    local azimuth, latitude = {}, {}
    for index = 0, samples do
        local az = theta * index / samples
        local lat = phi * index / samples
        azimuth[#azimuth + 1] = {arcRadius * math.cos(az), 0, arcRadius * math.sin(az)}
        latitude[#latitude + 1] = {
            arcRadius * math.cos(lat) * math.cos(theta),
            arcRadius * math.sin(lat),
            arcRadius * math.cos(lat) * math.sin(theta),
        }
    end
    return {
        point = point,
        projected = projected,
        radial = {{0, 0, 0}, point},
        planar = {{0, 0, 0}, projected},
        lift = {projected, point},
        azimuth = azimuth,
        latitude = latitude,
    }
end

local space = scene:space {
    id = "spherical-space", x = {-2.3, 2.3, 1}, y = {-2.3, 2.3, 1}, z = {-2.3, 2.3, 1},
    numbers = false, stroke = "border", axis_x = "border", axis_y = "border", axis_z = "border",
    width = 1, opacity = 0.34,
}

-- A quiet wire sphere makes the coordinate state spatially legible.
local sphereWire = {}
for latitude = -2, 2 do
    local phi = latitude * math.pi / 8
    local points = {}
    for index = 0, 72 do
        local theta = 2 * math.pi * index / 72
        points[#points + 1] = {
            radius * math.cos(phi) * math.cos(theta),
            radius * math.sin(phi),
            radius * math.cos(phi) * math.sin(theta),
        }
    end
    sphereWire[#sphereWire + 1] = space:plot {
        id = "spherical-latitude-wire-" .. (latitude + 3), points = points,
        stroke = "border", width = 1.2, opacity = 0.32, layer = LAYER.geometry,
    }
end
for longitude = 0, 5 do
    local theta = longitude * math.pi / 6
    local points = {}
    for index = 0, 72 do
        local phi = -math.pi / 2 + math.pi * index / 72
        points[#points + 1] = {
            radius * math.cos(phi) * math.cos(theta),
            radius * math.sin(phi),
            radius * math.cos(phi) * math.sin(theta),
        }
    end
    sphereWire[#sphereWire + 1] = space:plot {
        id = "spherical-longitude-wire-" .. (longitude + 1), points = points,
        stroke = "border", width = 1.2, opacity = 0.24, layer = LAYER.geometry,
    }
end

local function geometry(state, suffix)
    return {
        space:plot {id = "spherical-radial-" .. suffix, points = state.radial, stroke = "result", width = 4.5, layer = LAYER.geometry},
        space:plot {id = "spherical-planar-" .. suffix, points = state.planar, stroke = "accent", width = 3.5, layer = LAYER.geometry},
        space:plot {id = "spherical-lift-" .. suffix, points = state.lift, stroke = "secondary", width = 2.5, dash = {8, 6}, layer = LAYER.geometry},
        space:plot {id = "spherical-azimuth-" .. suffix, points = state.azimuth, stroke = "accent", width = 5, layer = LAYER.geometry},
        space:plot {id = "spherical-latitude-" .. suffix, points = state.latitude, stroke = "secondary", width = 5, layer = LAYER.geometry},
        space:polygon {id = "spherical-point-" .. suffix, points = marker(state.point, 0.085), fill = "result", stroke = "result", layer = LAYER.geometry},
        space:polygon {id = "spherical-projection-" .. suffix, points = marker(state.projected, 0.06), fill = "accent", stroke = "accent", layer = LAYER.geometry},
    }
end

local convention = {
    scene:text {
        id = "spherical-theta-convention", text = "θ  azimuth in the xz plane",
        point = {-3.8, 2.55, 0}, role = "code", fill = "accent", align = {0, 0.5}, layer = LAYER.text,
    },
    scene:text {
        id = "spherical-phi-convention", text = "φ  elevation above the xz plane",
        point = {-3.8, 2.1, 0}, role = "code", fill = "secondary", align = {0, 0.5}, layer = LAYER.text,
    },
}

local targets = {
    {theta = 0.28, phi = 0.24},
    {theta = 0.92, phi = 0.66},
    {theta = 1.72, phi = 0.38},
    {theta = 2.34, phi = 0.76},
    {theta = 1.18, phi = 0.56},
}

local live = geometry(spherical(targets[1].theta, targets[1].phi), "state-1")
scene:create(space, 0.48, "ease_out")
scene:create(sphereWire, 0.72, "ease_out", 0.025)
scene:create(live, 0.62, "ease_out", 0.035)
scene:fade_in(convention[1], {shift = {0, -0.08, 0}, duration = 0.3, curve = "gentle"})
scene:fade_in(convention[2], {shift = {0, -0.08, 0}, duration = 0.3, curve = "gentle"})
scene:wait(0.45)

-- Every target is rebuilt from one state and all compatible marks morph together.
for index = 2, #targets do
    local target = targets[index]
    local nextGeometry = geometry(spherical(target.theta, target.phi), "state-" .. index)
    scene:morph(live, nextGeometry, 0.92, "ease_in_out", 0)
    live = nextGeometry
    scene:wait(0.16)
end

local conclusion = scene:text {
    id = "spherical-coordinate-conclusion",
    text = "P = (r cos φ cos θ,  r sin φ,  r cos φ sin θ)",
    point = {0, -2.62, 0}, role = "code", fill = "result", align = {0.5, 0.5}, layer = LAYER.text,
}
scene:fade_in(conclusion, {shift = {0, 0.08, 0}, duration = 0.38, curve = "gentle"})
scene:wait(1.8)
return scene
