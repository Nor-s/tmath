local p = {
    background = "#080d14",
    grid = "#52657a",
    dark = "#111d2a",
    text = "#f4f7fb",
    muted = "#8fa1b7",
    ray = "#7890aa",
    cyan = "#4cc9f0",
    gold = "#ffd166",
    magenta = "#f72585",
}

local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 60,
    background = p.background,
    loop = false,
    camera = {
        mode = "fixed",
        view = "3d",
        eye = { 9, 6, 11 },
        target = { -0.6, 0, 0 },
        up = { 0, 1, 0 },
        projection = "perspective",
        fov = 0.66,
        near = 0.1,
        far = 100,
    },
}

local function translate(x, y, z)
    return {
        1,
        0,
        0,
        x,
        0,
        1,
        0,
        y,
        0,
        0,
        1,
        z,
        0,
        0,
        0,
        1,
    }
end

scene:text {
    text = "PRIMARY RAYS  >  INTERSECTION  >  PIXEL SHADE",
    point = { -6.0, 3.15, 0 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 18,
    fill = p.text,
    id = "ray-tracing-title",
}
scene:text {
    text = "one sample per pixel · nearest visible object wins",
    point = { -6.0, 2.72, 0 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 12,
    fill = p.muted,
    id = "ray-tracing-subtitle",
}

-- Local screen (u,v,0) maps to the world-space plane (-3,v,-u).
local screen = scene:group {
    matrix = {
        0,
        0,
        1,
        -3,
        0,
        1,
        0,
        0,
        -1,
        0,
        0,
        0,
        0,
        0,
        0,
        1,
    },
    id = "image-plane",
}
local pixels = {}
for row = 1, 3 do
    pixels[row] = {}
    for column = 1, 5 do
        local u = (column - 3) * 0.48
        local v = (2 - row) * 0.48
        pixels[row][column] = screen:rectangle {
            center = { u, v },
            size = { 0.42, 0.42 },
            corner = 0.035,
            fill = p.dark,
            stroke = p.grid,
            width = 1.6,
            id = "screen-pixel-" .. row .. "-" .. column,
        }
    end
end
local frame = {
    screen:line { from = { -1.29, -0.80 }, to = { 1.29, -0.80 }, stroke = p.cyan, width = 2.5 },
    screen:line { from = { 1.29, -0.80 }, to = { 1.29, 0.80 }, stroke = p.cyan, width = 2.5 },
    screen:line { from = { 1.29, 0.80 }, to = { -1.29, 0.80 }, stroke = p.cyan, width = 2.5 },
    screen:line { from = { -1.29, 0.80 }, to = { -1.29, -0.80 }, stroke = p.cyan, width = 2.5 },
}
local screen_label = scene:text {
    text = "IMAGE PLANE  5 × 3",
    point = { -3.35, 1.20, 0 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 15,
    fill = p.cyan,
    id = "image-plane-label",
}

local origin = { -6, 0, 0 }
local pinhole = scene:point {
    point = origin,
    fill = p.text,
    radius = 7,
    layer = 9,
    id = "pinhole",
}
local pinhole_label = scene:text {
    text = "PINHOLE",
    point = { -6.2, 0.62, 0 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = p.text,
    id = "pinhole-label",
}

local sphere_center = { 2.2, 0.656, 1.968 }
local sphere = scene:group {
    matrix = translate(sphere_center[1], sphere_center[2], sphere_center[3]),
    id = "sphere",
}
for latitude = -2, 2 do
    local phi = latitude * 3.14159265359 / 7
    local points = {}
    for i = 0, 40 do
        local angle = i * 6.28318530718 / 40
        points[#points + 1] = {
            0.98 * math.cos(phi) * math.cos(angle),
            0.98 * math.sin(phi),
            0.98 * math.cos(phi) * math.sin(angle),
        }
    end
    sphere:plot { points = points, stroke = p.cyan, width = 2.2 }
end
for longitude = 0, 5 do
    local theta = longitude * 3.14159265359 / 6
    local points = {}
    for i = 0, 48 do
        local phi = -3.14159265359 / 2 + i * 6.28318530718 / 48
        points[#points + 1] = {
            0.98 * math.cos(phi) * math.cos(theta),
            0.98 * math.sin(phi),
            0.98 * math.cos(phi) * math.sin(theta),
        }
    end
    sphere:plot { points = points, stroke = p.cyan .. "aa", width = 1.8 }
end

local cube_center = { 2.2, -0.656, -1.968 }
local cube =
    scene:group { matrix = translate(cube_center[1], cube_center[2], cube_center[3]), id = "cube" }
local cube_points = {
    { -0.82, -0.82, -0.82 },
    { 0.82, -0.82, -0.82 },
    { 0.82, 0.82, -0.82 },
    { -0.82, 0.82, -0.82 },
    { -0.82, -0.82, 0.82 },
    { 0.82, -0.82, 0.82 },
    { 0.82, 0.82, 0.82 },
    { -0.82, 0.82, 0.82 },
}
local cube_edges = {
    { 1, 2 },
    { 2, 3 },
    { 3, 4 },
    { 4, 1 },
    { 5, 6 },
    { 6, 7 },
    { 7, 8 },
    { 8, 5 },
    { 1, 5 },
    {
        2,
        6,
    },
    {
        3,
        7,
    },
    {
        4,
        8,
    },
}
for _, edge in ipairs(cube_edges) do
    cube:line { from = cube_points[edge[1]], to = cube_points[edge[2]], stroke = p.gold, width = 2.5 }
end

local pyramid_center = { 2.2, -1.312, 0 }
local pyramid = scene:group {
    matrix = translate(pyramid_center[1], pyramid_center[2], pyramid_center[3]),
    id = "pyramid",
}
local base = {
    { -0.72, -0.55, -0.72 },
    { 0.72, -0.55, -0.72 },
    { 0.72, -0.55, 0.72 },
    {
        -0.72,
        -0.55,
        0.72,
    },
}
for index = 1, 4 do
    pyramid:line { from = base[index], to = base[index % 4 + 1], stroke = p.magenta, width = 2.5 }
    pyramid:line { from = base[index], to = { 0, 0.82, 0 }, stroke = p.magenta, width = 2.5 }
end

local labels = {
    scene:text {
        text = "SPHERE",
        point = { 2.2, 1.95, 1.968 },
        font = "Pretendard",
        size = 14,
        fill = p.cyan,
    },
    scene:text {
        text = "CUBE",
        point = { 2.2, 0.62, -1.968 },
        font = "Pretendard",
        size = 14,
        fill = p.gold,
    },
    scene:text {
        text = "PYRAMID",
        point = { 2.2, -2.72, 0 },
        font = "Pretendard",
        size = 14,
        fill = p.magenta,
    },
}

local hit_colors = {
    { p.cyan, p.cyan, false, false, false },
    { p.cyan, p.cyan, false, p.gold, p.gold },
    { false, false, p.magenta, p.gold, p.gold },
}

local function sample_point(column, row, x)
    local u = (column - 3) * 0.48
    local v = (2 - row) * 0.48
    local scale = (x - origin[1]) / 3
    return { x, v * scale, -u * scale }
end

scene:create({ screen, pinhole, sphere, cube, pyramid }, 0.90, "ease_out", 0.08)
scene:create(
    { screen_label, pinhole_label, labels[1], labels[2], labels[3] },
    0.40,
    "ease_out",
    0.06
)
scene:wait(0.30)

for row = 1, 3 do
    local rays = {}
    local ray_fades = {}
    local hit_points = {}
    local pixel_shades = {}
    for column = 1, 5 do
        local color = hit_colors[row][column]
        local endpoint = sample_point(column, row, color and 2.2 or 3.8)
        local ray = scene:arrow {
            from = origin,
            to = endpoint,
            stroke = color or p.ray,
            width = color and 2.8 or 1.7,
            tip = 8,
            id = "primary-ray-" .. row .. "-" .. column,
        }
        rays[#rays + 1] = ray
        ray_fades[#ray_fades + 1] = { target = ray, opacity = color and 0.28 or 0.10 }
        if color then
            hit_points[#hit_points + 1] = scene:point {
                point = endpoint,
                fill = color,
                radius = 4.5,
                layer = 10,
                id = "hit-" .. row .. "-" .. column,
            }
            pixel_shades[#pixel_shades + 1] = { target = pixels[row][column], fill = color }
        end
    end
    scene:create(rays, 0.52, "linear", 0.08)
    for _, point in ipairs(hit_points) do
        scene:grow_from_center(point, 0.10, "snappy")
    end
    if #pixel_shades > 0 then
        scene:play(pixel_shades, 0.30, { preset = "snappy", strength = 0.85 }, 0.05)
    end
    scene:play(ray_fades, 0.22, "ease_out", 0)
    scene:wait(0.16)
end

local result = scene:text {
    text = "RGB HIT BUFFER",
    point = { -6.0, -2.20, 0 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 14,
    fill = p.text,
    id = "result-label",
}
scene:fade_in(result, { shift = { 0, -0.18 }, duration = 0.38, curve = "snappy" })
scene:wait(0.65)
return scene
