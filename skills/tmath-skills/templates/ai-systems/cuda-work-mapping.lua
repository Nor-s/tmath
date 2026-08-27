-- Generic CUDA execution mapping, grounded in the CUDA programming model.
-- Replace labels and residency examples when a paper or device is the source.
-- The shown block-to-SM assignment is representative: block order is not guaranteed.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "pro_white",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local LAYER = {boundary = 0, route = 10, node = 20, text = 30, focus = 40}
local root = scene:group {id = "cuda-map:root"}
local header = root:group {id = "cuda-map:header"}
local grid = root:group {id = "cuda-map:grid"}
local device = root:group {id = "cuda-map:device"}
local routes = root:group {id = "cuda-map:routes"}
local notes = root:group {id = "cuda-map:notes"}

header:text {
    text = "CUDA work mapping", point = {0, 232}, role = "h2",
    fill = "foreground", layer = LAYER.text, id = "cuda-map:title",
}
header:text {
    text = "programming model · representative residency · not a chip floorplan",
    point = {0, 199}, role = "code", fill = "muted", layer = LAYER.text,
    id = "cuda-map:subtitle",
}

grid:rectangle {
    center = {-240, 95}, size = {438, 154}, corner = 8, fill = "surface",
    stroke = "border", width = 1.4, layer = LAYER.boundary, id = "cuda-map:grid:boundary",
}
grid:text {
    text = "KERNEL LAUNCH → GRID", point = {-442, 153}, align = {0, 0.5},
    role = "code", fill = "muted", layer = LAYER.text, id = "cuda-map:grid:label",
}

local block_centers = {}
for index = 0, 5 do
    local column, row = index % 3, math.floor(index / 3)
    local center = {-363 + column * 124, 115 - row * 61}
    block_centers[index + 1] = center
    grid:rectangle {
        center = center, size = {103, 43}, corner = 5,
        fill = index == 4 and "#dbeafe" or "background",
        stroke = index == 4 and "accent" or "border", width = index == 4 and 2.1 or 1.1,
        layer = LAYER.node, id = "cuda-map:block:" .. index .. ":body",
    }
    grid:text {
        text = "block " .. index, point = center, role = "code",
        fill = index == 4 and "accent" or "foreground", layer = LAYER.text,
        id = "cuda-map:block:" .. index .. ":label",
    }
end

device:rectangle {
    center = {0, -96}, size = {890, 200}, corner = 9, fill = "surface",
    stroke = "border", width = 1.4, layer = LAYER.boundary, id = "cuda-map:device:boundary",
}
device:text {
    text = "GPU DEVICE", point = {-426, -18},
    align = {0, 0.5}, role = "code", fill = "muted", layer = LAYER.text,
    id = "cuda-map:device:label",
}
device:text {
    text = "resident blocks execute on SMs", point = {426, -18},
    align = {1, 0.5}, role = "code", fill = "muted", layer = LAYER.text,
    id = "cuda-map:device:detail",
}

local sm_centers = {-287, 0, 287}
local resident = {{"block 1", "block 4"}, {"block 0"}, {"block 2", "block 5"}}
for sm = 1, 3 do
    local x = sm_centers[sm]
    local group = device:group {id = "cuda-map:sm:" .. (sm - 1)}
    group:rectangle {
        center = {x, -100}, size = {246, 136}, corner = 7, fill = "background",
        stroke = sm == 1 and "accent" or "border", width = sm == 1 and 2.1 or 1.2,
        layer = LAYER.node, id = "cuda-map:sm:" .. (sm - 1) .. ":body",
    }
    group:text {
        text = "SM " .. (sm - 1), point = {x, -54}, role = "text",
        fill = sm == 1 and "accent" or "foreground", layer = LAYER.text,
        id = "cuda-map:sm:" .. (sm - 1) .. ":label",
    }
    group:text {
        text = table.concat(resident[sm], "  ·  "), point = {x, -82}, role = "code",
        fill = "foreground", layer = LAYER.text, id = "cuda-map:sm:" .. (sm - 1) .. ":resident",
    }
    for lane = 0, 7 do
        group:rectangle {
            center = {x - 82 + lane * 23.5, -119}, size = {19, 22}, corner = 2,
            fill = lane < 5 and "#bfdbfe" or "surface", stroke = "border", width = 0.8,
            layer = LAYER.node, id = "cuda-map:sm:" .. (sm - 1) .. ":lane:" .. lane,
        }
    end
    group:text {
        text = "warp lanes 0…31 (sampled)", point = {x, -149}, role = "code",
        fill = "muted", layer = LAYER.text, id = "cuda-map:sm:" .. (sm - 1) .. ":lanes-label",
    }
end

local assignment = routes:route {
    points = {{block_centers[5][1], block_centers[5][2] - 22}, {block_centers[5][1], -18}, {-287, -18}, {-287, -32}},
    tip = 9, color = "accent", width = 2, dash = {7, 5},
    layer = LAYER.focus, id = "cuda-map:route:block4-sm0",
}
notes:text {
    text = "dynamic scheduling: assignment and execution order may vary", point = {0, -178},
    role = "code", fill = "focus", layer = LAYER.text, id = "cuda-map:scheduling-note",
}
local conclusion = root:text {
    text = "grid → blocks → threads; one block is resident on one SM at a time",
    point = {0, -230}, role = "code", fill = "result", layer = LAYER.text,
    id = "cuda-map:conclusion",
}

scene:fade_in(header, {shift = {0, -6}, duration = 0.5, curve = "gentle"})
scene:fade_in(grid, {shift = {0, -6}, duration = 0.65, curve = "ease_out"})
scene:fade_in(device, {shift = {0, -6}, duration = 0.7, curve = "gentle"})
scene:create(assignment, 0.55, "ease_out")
scene:fade_in(notes, {duration = 0.35, curve = "gentle"})
scene:fade_in(conclusion, {duration = 0.35, curve = "gentle"})
scene:wait(2.3)
return scene
