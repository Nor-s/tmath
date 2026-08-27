-- Interactive camera template. No Panel is required.
-- In the VS Code Preview: drag to orbit, Shift-drag to pan, use +/- to zoom,
-- press 2 or 3 to switch view, and R to reset the authored camera.
if not tmath.input then
    error("camera-orbit-view.lua requires a tmath build configured with -Dinput=true")
end
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = true,
    theme = "adaptive_vscode",
    camera = {
        mode = "interactive", view = "3d",
        eye = {6.4, 4.8, 7.2}, target = {0, 0.2, 0}, up = {0, 1, 0},
        projection = "perspective", fov = 0.66, near = 0.1, far = 100,
    },
}

local input = tmath.input.controller(scene)

local LAYER = {surface = 10, grid = 20, axis = 30, mark = 40, text = 50}
local world = scene:space {
    x = {-3, 3, 1}, y = {-2.5, 2.5, 1}, z = {-3, 3, 1},
    color = "border", axis_x = "danger", axis_y = "success", axis_z = "info",
    numbers = false, width = 1, layer = LAYER.grid,
    id = "camera-demo:space",
}

-- A reference plane makes orbit, projection, and depth changes visible.
world:polygon {
    points = {{-2.2, 0, -2.2}, {2.2, 0, -2.2}, {2.2, 0, 2.2}, {-2.2, 0, 2.2}},
    fill = "surface", stroke = "border", width = 1.5,
    layer = LAYER.surface, id = "camera-demo:reference-plane",
}

local radius = 1.45
for latitude = -2, 2 do
    local phi = latitude * math.pi / 6
    local points = {}
    for i = 0, 64 do
        local theta = i * 2 * math.pi / 64
        points[#points + 1] = {
            radius * math.cos(phi) * math.cos(theta),
            0.3 + radius * math.sin(phi),
            radius * math.cos(phi) * math.sin(theta),
        }
    end
    world:plot {
        points = points, stroke = "accent", width = 2,
        layer = LAYER.axis,
        id = "camera-demo:sphere:latitude:" .. tostring(latitude + 3),
    }
end
for longitude = 0, 7 do
    local theta = longitude * math.pi / 8
    local points = {}
    for i = 0, 64 do
        local phi = -math.pi / 2 + i * math.pi / 64
        points[#points + 1] = {
            radius * math.cos(phi) * math.cos(theta),
            0.3 + radius * math.sin(phi),
            radius * math.cos(phi) * math.sin(theta),
        }
    end
    world:plot {
        points = points, stroke = "accent", width = 2,
        layer = LAYER.axis,
        id = "camera-demo:sphere:longitude:" .. tostring(longitude + 1),
    }
end

local sample = {1.05, 1.35, 0.8}
world:vector {
    origin = {0, 0.3, 0}, value = {sample[1], sample[2] - 0.3, sample[3]},
    color = "result", width = 4, tip = 12,
    layer = LAYER.mark, id = "camera-demo:radius-vector",
}
world:point {
    point = sample, radius = 7, fill = "focus", stroke = "background", width = 2,
    layer = LAYER.mark + 1, id = "camera-demo:sample-point",
}
world:text {
    text = "P(x, y, z)", point = {1.22, 1.58, 0.9}, align = {0, 0.5},
    orientation = "billboard", role = "text", fill = "focus",
    layer = LAYER.text, id = "camera-demo:sample-label",
}
world:text {
    text = "Drag: orbit   Shift-drag: pan   +/−: zoom   2/3: view   R: reset",
    point = {-2.7, 2.45, 0}, align = {0, 0.5}, orientation = "billboard",
    role = "code", fill = "foreground", layer = LAYER.text,
    id = "camera-demo:instructions",
}

scene:wait(12)
return scene
