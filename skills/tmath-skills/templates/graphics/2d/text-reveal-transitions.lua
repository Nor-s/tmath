-- Preserve visible source geometry while a same-color copy becomes explanatory Text.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local function ellipse_points(center, rx, ry, count)
    local points = {}
    for i = 0, count - 1 do
        local angle = 2 * math.pi * i / count
        points[#points + 1] = {center[1] + rx * math.cos(angle), center[2] + ry * math.sin(angle)}
    end
    return points
end
local function box_points(center, width, height)
    local x, y, w, h = center[1], center[2], width * 0.5, height * 0.5
    return {{x - w, y - h}, {x, y - h}, {x + w, y - h}, {x + w, y},
            {x + w, y + h}, {x, y + h}, {x - w, y + h}, {x - w, y}}
end
local function arrow_points(from, to)
    local dx, dy = to[1] - from[1], to[2] - from[2]
    local length, shaft, head = math.sqrt(dx * dx + dy * dy), 0.05, 0.16
    local ux, uy = dx / length, dy / length
    local nx, ny, joint = -uy, ux, {to[1] - 0.32 * ux, to[2] - 0.32 * uy}
    return {{from[1] + shaft * nx, from[2] + shaft * ny},
            {joint[1] + shaft * nx, joint[2] + shaft * ny},
            {joint[1] + head * nx, joint[2] + head * ny}, to,
            {joint[1] - head * nx, joint[2] - head * ny},
            {joint[1] - shaft * nx, joint[2] - shaft * ny},
            {from[1] - shaft * nx, from[2] - shaft * ny}}
end

local rows = {1.9, 0, -1.9}
-- Cursor advances are production-font measurements supplied as explicit template data.
local cursorSteps = {{"p", 0.18}, {"p =", 0.5}, {"p = (3,", 1.05}, {"p = (3, 2)", 1.48}}
local labels = {
    scene:text {id = "text-morph-fade-label", text = "morph-fade", point = {-5, rows[1]}, role = "code", fill = "muted", align = {0, 0.5}, layer = 40},
    scene:text {id = "text-bullet-label", text = "bullet", point = {-5, rows[2]}, role = "code", fill = "muted", align = {0, 0.5}, layer = 40},
    scene:text {id = "text-cursor-label", text = "cursor", point = {-5, rows[3]}, role = "code", fill = "muted", align = {0, 0.5}, layer = 40},
}
local point_a = scene:point {id = "text-morph-source", point = {-3.35, rows[1]}, fill = "accent", radius = 8, layer = 10}
local vector_from, vector_to = {-3.95, rows[2]}, {-2.85, rows[2]}
local vector = scene:vector {id = "text-bullet-source", origin = vector_from, value = {1.1, 0}, stroke = "secondary", width = 5, tip = 14, layer = 20}
local point_b = scene:point {id = "text-cursor-source", point = {-3.35, rows[3]}, fill = "result", radius = 8, layer = 10}

-- Default: morph an opaque copy into a seed, then cross-fade the seed into Text.
local function morph_fade_text()
    local copy = scene:polygon {id = "text-morph-copy", points = ellipse_points({-3.35, rows[1]}, 0.13, 0.13, 8), fill = "accent", stroke = "accent", layer = 30}
    local seed = scene:polygon {id = "text-morph-seed", points = ellipse_points({-1.25, rows[1]}, 0.1, 0.15, 8), fill = "accent", stroke = "accent", layer = 30}
    scene:replacement_transform(copy, seed, 0.62, "ease_in_out")
    local text = scene:text {id = "text-morph-result", text = "sample point", point = {-1.12, rows[1]}, role = "text", fill = "accent", align = {0, 0.5}, layer = 40}
    scene:fade_transform(seed, text, 0.22, "gentle")
end

-- Bullet: consume a vector copy but keep the compact marker beside its label.
local function bullet_text()
    local copy = scene:polygon {id = "text-bullet-copy", points = arrow_points(vector_from, vector_to), fill = "secondary", stroke = "secondary", layer = 30}
    local proxy = scene:polygon {id = "text-bullet-proxy", points = ellipse_points({-1.25, rows[2]}, 0.11, 0.11, 7), fill = "secondary", stroke = "secondary", layer = 30}
    scene:replacement_transform(copy, proxy, 0.62, {preset = "back", strength = 0.4})
    scene:circle {id = "text-bullet-result", center = {-1.25, rows[2]}, radius = 0.11, fill = "secondary", stroke = "secondary", layer = 30}
    scene:remove(proxy)
    local text = scene:text {id = "text-bullet-result-label", text = "direction vector", point = {-0.92, rows[2]}, role = "text", fill = "secondary", align = {0, 0.5}, layer = 40}
    scene:fade_in(text, {shift = {-0.08, 0}, duration = 0.28, curve = "gentle"})
end

-- Cursor: use a few measured prefixes only when typing itself carries meaning.
local function cursor_text()
    local copy = scene:polygon {id = "text-cursor-copy", points = ellipse_points({-3.35, rows[3]}, 0.13, 0.13, 8), fill = "result", stroke = "result", layer = 30}
    local cursor = scene:polygon {id = "text-cursor-proxy", points = box_points({-1.1, rows[3]}, 0.06, 0.42), fill = "result", stroke = "result", layer = 40}
    scene:replacement_transform(copy, cursor, 0.58, {preset = "snappy", strength = 0.8})
    -- Remeasure these advances when the host changes the code-role font.
    local prefixes = {}
    for i, item in ipairs(cursorSteps) do
        prefixes[i] = scene:text {id = "text-cursor-prefix-" .. i, text = item[1], point = {-0.98, rows[3]}, role = "code", fill = "result", opacity = 0, align = {0, 0.5}, layer = 40}
    end
    local advance = 0
    for i, item in ipairs(cursorSteps) do
        local clips = {{target = prefixes[i], opacity = 1}, {target = cursor, shift = {item[2] - advance, 0}}}
        if i > 1 then clips[#clips + 1] = {target = prefixes[i - 1], opacity = 0} end
        scene:play(clips, i == 1 and 0.1 or 0.14, "linear", 0)
        advance = item[2]
    end
    scene:fade(cursor, 0, 0.16, "ease_out")
end

-- Establish the source objects first; each later transition consumes only its copy.
scene:fade_in(labels[1], {duration = 0.22, curve = "gentle"})
scene:fade_in(labels[2], {duration = 0.22, curve = "gentle"})
scene:fade_in(labels[3], {duration = 0.22, curve = "gentle"})
scene:grow_from_center(point_a, 0.24, "ease_out")
scene:create(vector, 0.38, "ease_out")
scene:grow_from_center(point_b, 0.24, "ease_out")
scene:wait(0.5)
morph_fade_text()
scene:wait(0.35)
bullet_text()
scene:wait(0.35)
cursor_text()
scene:wait(1.4)
return scene
