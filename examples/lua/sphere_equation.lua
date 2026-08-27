local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    camera = {
        mode = "interactive",
        view = "3d",
        eye = { 6.5, 4.9, 7.6 },
        target = { 0, -0.1, 0 },
        up = { 0, 1, 0 },
        projection = "perspective",
        fov = 0.7,
        near = 0.1,
        far = 100,
    },
}

local space = scene:space {
    x = { -2.6, 2.6, 1 },
    y = { -2.6, 2.6, 1 },
    z = { -2.6, 2.6, 1 },
    color = "#28333d",
    id = "sphere-space",
}
local curves = {}
local radius = 2.2
for latitude = -3, 3 do
    local phi = latitude * 3.14159265359 / 8
    local points = {}
    for i = 0, 64 do
        local theta = i * 6.28318530718 / 64
        points[#points + 1] = {
            radius * math.cos(phi) * math.cos(theta),
            radius * math.sin(phi),
            radius * math.cos(phi) * math.sin(theta),
        }
    end
    curves[#curves + 1] = space:plot { points = points, color = "#4cc9f0aa", width = 2 }
end
for longitude = 0, 7 do
    local theta = longitude * 3.14159265359 / 8
    local points = {}
    for i = 0, 128 do
        local phi = -3.14159265359 / 2 + i * 6.28318530718 / 128
        points[#points + 1] = {
            radius * math.cos(phi) * math.cos(theta),
            radius * math.sin(phi),
            radius * math.cos(phi) * math.sin(theta),
        }
    end
    curves[#curves + 1] = space:plot { points = points, color = "#4cc9f088", width = 2 }
end
local sample = { 1.27017, 1.27017, 1.27017 }
local radial = space:vector { value = sample, color = "#ffd166", width = 4, tip = 13 }
local point = space:point { point = sample, fill = "#ef5350", radius = 7 }
local equation = space:text {
    text = "x² + y² + z² = r²",
    point = { -2.7, 2.45, 0 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 24,
    fill = "#4cc9f0",
    id = "equation",
}
local radius_formula = space:text {
    text = "r = 2.2",
    point = { 0.9, 2.45, 0 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 24,
    fill = "#ffd166",
}
local point_formula = space:text {
    text = "P(x, y, z)",
    point = { sample[1] + 0.2, sample[2] + 0.3, sample[3] },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 17,
    fill = "#ef5350",
}

scene:create(curves, 1.2, "ease_out", 0.025)
scene:create({ radial, point }, 0.7, "ease_out", 0.12)
scene:create({ equation, radius_formula, point_formula }, 0.45, "ease_out", 0.08)
scene:wait(0.7)
return scene
