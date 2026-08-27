local p = {
    paper = "#f7f8fb",
    ink = "#182033",
    muted = "#687086",
    red = "#ef4444",
    gold = "#f59e0b",
    x = "#ef4444",
    y = "#16a34a",
    z = "#2563eb",
}
local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 60,
    background = p.paper,
    camera = {
        mode = "fixed",
        view = "3d",
        eye = { 5.7, 4.2, 6.4 },
        target = { 0, 0, 0 },
        up = { 0, 1, 0 },
        projection = "perspective",
        fov = 0.68,
        near = 0.1,
        far = 100,
    },
}
scene:text {
    text = "LIGHT SOURCE POSITION",
    point = { -3.7, 3.05, 0 },
    align = { 0, 0.5 },
    orientation = "billboard",
    font = "Pretendard",
    size = 25,
    fill = p.ink,
}
scene:text {
    text = "surface luminance follows n · l",
    point = { -3.68, 2.58, 0 },
    align = { 0, 0.5 },
    orientation = "billboard",
    font = "Pretendard",
    size = 12,
    fill = p.muted,
}
local axes = {
    scene:arrow { from = { -2.3, 0, 0 }, to = { 2.3, 0, 0 }, stroke = p.x, width = 2.5, tip = 10 },
    scene:arrow { from = { 0, -2.3, 0 }, to = { 0, 2.3, 0 }, stroke = p.y, width = 2.5, tip = 10 },
    scene:arrow { from = { 0, 0, -2.3 }, to = { 0, 0, 2.3 }, stroke = p.z, width = 2.5, tip = 10 },
}
local light_a, light_b = { 3.2, 2.4, 3.8 }, { -3.0, 1.4, 2.4 }
local function normalize(v)
    local length = math.sqrt(v[1] * v[1] + v[2] * v[2] + v[3] * v[3])
    return { v[1] / length, v[2] / length, v[3] / length }
end
local function shade(normal, light)
    local l = normalize(light)
    local amount = math.max(0, normal[1] * l[1] + normal[2] * l[2] + normal[3] * l[3])
    amount = 0.16 + 0.84 * amount
    return string.format(
        "#%02x%02x%02x",
        math.floor(72 + 178 * amount),
        math.floor(22 + 72 * amount),
        math.floor(30 + 62 * amount)
    )
end
local function sphere_point(latitude, longitude)
    local radius = 1.55
    return {
        radius * math.cos(latitude) * math.cos(longitude),
        radius * math.sin(latitude),
        radius * math.cos(latitude) * math.sin(longitude),
    }
end
local cells, normals = {}, {}
local rows, columns = 9, 18
for row = 0, rows - 1 do
    local u0 = -1.43 + 2.86 * row / rows
    local u1 = -1.43 + 2.86 * (row + 1) / rows
    for column = 0, columns - 1 do
        local v0 = 2 * math.pi * column / columns
        local v1 = 2 * math.pi * (column + 1) / columns
        local um, vm = (u0 + u1) * 0.5, (v0 + v1) * 0.5
        local normal = { math.cos(um) * math.cos(vm), math.sin(um), math.cos(um) * math.sin(vm) }
        normals[#normals + 1] = normal
        cells[#cells + 1] = scene:polygon {
            points = {
                sphere_point(u0, v0),
                sphere_point(u0, v1),
                sphere_point(u1, v1),
                sphere_point(u1, v0),
            },
            fill = shade(normal, light_a),
            stroke = "#ffffff22",
            width = 0.5,
        }
    end
end
local light = scene:point {
    point = light_a,
    fill = p.gold,
    stroke = p.paper,
    width = 3,
    radius = 10,
    layer = 20,
    id = "light",
}
scene:create(axes, 0.4, "ease_out", 0)
scene:create(cells, 0.65, "ease_out", 0.002)
scene:grow_from_center(light, 0.22, "snappy")
local forward = {
    {
        target = light,
        shift = { light_b[1] - light_a[1], light_b[2] - light_a[2], light_b[3] - light_a[3] },
    },
}
for index, cell in ipairs(cells) do
    forward[#forward + 1] = { target = cell, fill = shade(normals[index], light_b) }
end
scene:play(forward, 1.0, "ease_in_out", 0)
local backward = {
    {
        target = light,
        shift = { light_a[1] - light_b[1], light_a[2] - light_b[2], light_a[3] - light_b[3] },
    },
}
for index, cell in ipairs(cells) do
    backward[#backward + 1] = { target = cell, fill = shade(normals[index], light_a) }
end
scene:play(backward, 1.0, "ease_in_out", 0)
scene:wait(0.7)
return scene
