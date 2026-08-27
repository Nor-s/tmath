local p = {
    paper = "#f7f8fb",
    ink = "#182033",
    muted = "#687086",
    grid = "#dce2ed",
    blue = "#2563eb",
    gold = "#eab308",
    orange = "#f97316",
}
local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 60,
    background = p.paper,
    camera = { mode = "fixed", view = "2d", height = 8 },
}
scene:text {
    text = "POLYGON ON AXES",
    point = { -5.8, 3.15 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 27,
    fill = p.ink,
}
scene:text {
    text = "xy = 25  ·  constant-area rectangle",
    point = { -5.77, 2.65 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = p.muted,
}
local axes = scene:space {
    x = { 0, 10, 1 },
    y = { 0, 10, 1 },
    matrix = { 0.52, 0, 0, -2.6, 0, 0.52, 0, -2.85, 0, 0, 1, 0, 0, 0, 0, 1 },
    color = p.grid,
    axis_x = p.ink,
    axis_y = p.ink,
    numbers = true,
    number_size = 9,
    id = "axes",
}
local curve_points = {}
for sample = 0, 60 do
    local x = 2.5 + 0.125 * sample
    curve_points[#curve_points + 1] = { x, 25 / x }
end
local curve = axes:plot { points = curve_points, stroke = p.gold, width = 4, id = "hyperbola" }
local function rectangle_points(index)
    local x, y = curve_points[index][1], curve_points[index][2]
    return { { x, y }, { 0, y }, { 0, 0 }, { x, 0 } }
end
local function tracker_points(index)
    local x, y, r = curve_points[index][1], curve_points[index][2], 0.13
    return { { x - r, y }, { x, y + r }, { x + r, y }, { x, y - r } }
end
local function make_state(index, stage)
    local rectangle = axes:polygon {
        points = rectangle_points(index),
        fill = p.blue .. "3d",
        stroke = p.blue,
        width = 2.5,
        id = "area-" .. stage,
    }
    local tracker = axes:polygon {
        points = tracker_points(index),
        fill = p.orange,
        stroke = p.paper,
        width = 1.25,
        layer = 10,
        id = "tracker-" .. stage,
    }
    return rectangle, tracker
end
local current_index = 21
local stage = 0
local rectangle, tracker = make_state(current_index, stage)
scene:create(axes, 0.48, "gentle")
scene:create(curve, 1.0, "gentle")
scene:draw_border_then_fill(rectangle, 0.78, "gentle")
scene:grow_from_center(tracker, 0.26, "gentle")
local function animate_to(target_index, duration)
    local direction = target_index > current_index and 1 or -1
    local count = math.abs(target_index - current_index)
    local weights, total_weight = {}, 0
    for step = 1, count do
        local phase = (step - 0.5) / count
        local weight = 0.55 + 1.45 * math.cos(math.pi * phase) ^ 2
        weights[step], total_weight = weight, total_weight + weight
    end
    for step = 1, count do
        current_index = current_index + direction
        stage = stage + 1
        local next_rectangle, next_tracker = make_state(current_index, stage)
        scene:morph(
            { rectangle, tracker },
            { next_rectangle, next_tracker },
            duration * weights[step] / total_weight,
            "linear",
            0
        )
        rectangle, tracker = next_rectangle, next_tracker
    end
end
animate_to(49, 1.35)
scene:wait(0.18)
animate_to(7, 2.1)
scene:wait(0.22)
animate_to(21, 1.25)
scene:wait(0.8)
return scene
