-- Input-only pointer follower.
-- Requires a tmath build configured with -Dinput=true; no UI Panel is used.
if not tmath.input then
    error("pointer-follow-angle.lua requires a tmath build configured with -Dinput=true")
end

local WIDTH, HEIGHT = 960, 540
local scene = tmath.scene {
    width = WIDTH, height = HEIGHT, fps = 60, loop = true,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = HEIGHT},
}

local LAYER = {grid = 10, guide = 20, mark = 30, text = 40}

scene:text {
    text = "Pointer-follow motion with a measured heading",
    point = {-424, 226}, align = {0, 0.5}, role = "h2",
    layer = LAYER.text, id = "pointer-follow:title",
}
scene:text {
    text = "Move the pointer. Each sample starts one exact 180 ms response interval.",
    point = {-424, 187}, align = {0, 0.5}, role = "text", fill = "muted",
    layer = LAYER.text, id = "pointer-follow:subtitle",
}

local frame = {left = -424, right = 424, top = 137, bottom = -204, active_bottom = -150}
scene:rectangle {
    center = {0, (frame.top + frame.bottom) / 2},
    size = {frame.right - frame.left, frame.top - frame.bottom}, corner = 4,
    fill = "surface", stroke = "border", width = 1.5,
    layer = LAYER.grid, id = "pointer-follow:field",
}
for x = -360, 360, 72 do
    scene:line {
        from = {x, frame.active_bottom}, to = {x, frame.top},
        color = "border", width = 1, layer = LAYER.grid,
        id = "pointer-follow:grid:x:" .. tostring(x),
    }
end
for y = -96, 120, 72 do
    scene:line {
        from = {frame.left, y}, to = {frame.right, y},
        color = "border", width = 1, layer = LAYER.grid,
        id = "pointer-follow:grid:y:" .. tostring(y),
    }
end
scene:line {
    from = {frame.left, frame.active_bottom}, to = {frame.right, frame.active_bottom},
    color = "border", width = 1.5, layer = LAYER.guide,
    id = "pointer-follow:equation:separator",
}

scene:text {
    text = "θ = atan2(yₚ − y(t), xₚ − x(t))",
    point = {-402, -177}, align = {0, 0.5}, role = "code", fill = "muted",
    layer = LAYER.text, id = "pointer-follow:equation",
}

local follower = scene:group {id = "pointer-follow:follower"}
follower:circle {
    center = {0, 0}, radius = 22,
    fill = "background", stroke = "accent", width = 3,
    layer = LAYER.mark, id = "pointer-follow:follower:body",
}
follower:arrow {
    from = {-5, 0}, to = {43, 0}, tail = 0, tip = 12,
    color = "focus", width = 4,
    layer = LAYER.mark + 1, id = "pointer-follow:follower:heading",
}
follower:point {
    point = {0, 0}, radius = 5,
    fill = "result", stroke = "background", width = 2,
    layer = LAYER.mark + 2, id = "pointer-follow:follower:anchor",
}

local input = tmath.input.controller(scene)
input:pointer_follow {
    target = follower,
    region = {
        x = frame.left + WIDTH / 2,
        y = HEIGHT / 2 - frame.top,
        width = frame.right - frame.left,
        height = frame.top - frame.active_bottom,
    },
    target_origin = {0, 0, 0},
    map_origin = {frame.left, frame.top, 0},
    map_x = {frame.right - frame.left, 0, 0},
    map_y = {0, frame.active_bottom - frame.top, 0},
    period = 0.18,
    rotate = true,
    angle_offset = 0,
    reset_on_leave = true,
}

scene:wait(12)
return scene
