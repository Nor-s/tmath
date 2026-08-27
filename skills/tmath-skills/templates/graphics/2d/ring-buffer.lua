-- Map ring-buffer indices onto a segmented angular gradient.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 7},
}
local state = {capacity = 32, head = 18, tail = 31, writes = 2}
local count, inner, outer = state.capacity, 1.25, 2.55
local palette = {"#6e6479", "#5e7a9b", "#b8915a", "#f28e2b", "#6e6479"}
-- Interpolate palette stops without a project-specific color helper.
local function mix(a, b, t)
    local function channel(color, offset) return tonumber(color:sub(offset, offset + 1), 16) end
    local function hex(value) return string.format("%02x", math.floor(value + 0.5)) end
    return "#" .. hex(channel(a, 2) + (channel(b, 2) - channel(a, 2)) * t)
               .. hex(channel(a, 4) + (channel(b, 4) - channel(a, 4)) * t)
               .. hex(channel(a, 6) + (channel(b, 6) - channel(a, 6)) * t)
end
-- Clockwise index placement makes wraparound visible at the top seam.
local function point(radius, index)
    local angle = -2 * math.pi * index / count
    return {radius * math.cos(angle), radius * math.sin(angle)}
end
local function sector(index)
    return {point(inner, index - 0.48), point(outer, index - 0.48),
            point(outer, index + 0.48), point(inner, index + 0.48)}
end
local function color(index)
    local phase = index / count * 4
    local stop = math.floor(phase) + 1
    return mix(palette[stop], palette[stop + 1], phase - math.floor(phase))
end
local function label(value, position, fill)
    return scene:text {text = value, point = position, role = "code", fill = fill or "muted", align = {0.5, 0.5}, layer = 40}
end
local function rotation(angle)
    local c, s = math.cos(angle), math.sin(angle)
    return {c, -s, 0, 0, s, c, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1}
end
local function sectorShape(index, fill, layer)
    return scene:polygon {points = sector(index), fill = fill, stroke = fill, width = 1, layer = layer}
end
local function wrap(index) return index % count end
local function occupied(index, head, tail)
    return head <= tail and index >= head and index < tail or head > tail and (index >= head or index < tail)
end

-- Build the entire capacity first, then overlay only occupied slots.
local base, data = {}, {}
local preparedTail = wrap(state.tail + state.writes)
for i = 0, count - 1 do
    base[#base + 1] = scene:polygon {points = sector(i), fill = "surface", stroke = "border", width = 1, layer = 0}
    if occupied(i, state.head, preparedTail) then
        data[i + 1] = sectorShape(i, color(i), 5)
    end
end
local function slot(index) return data[wrap(index) + 1] end
local hole = scene:circle {center = {0, 0}, radius = inner - 0.03, fill = "background", stroke = "background", layer = 10}
local active = {}
for i = 0, count - 1 do
    if occupied(i, state.head, state.tail) then active[#active + 1] = slot(i) end
end

label("head / read", {-1.25, 3.05}, "accent")
label("tail / write", {1.25, 3.05}, "secondary")
label(string.format("(index + 1) %% %d", count), {0, -0.55}, "muted")
for i = 0, 3 do
    local index = i * count / 4
    label(string.format("%d", index), point(2.82, index))
end
local head = scene:arrow {from = {0, 0}, to = point(2.72, state.head), stroke = "accent", width = 3, tip = 12, layer = 20}
local tail = scene:arrow {from = {0, 0}, to = point(2.72, state.tail), stroke = "secondary", width = 3, tip = 12, layer = 20}
local step = -2 * math.pi / count

-- Write across the wrap seam, then read once to show both cursor operations.
scene:create(base, 0.75, "ease_out", 0.012)
scene:grow_from_center(hole, 0.28, "ease_out")
scene:create(active, 0.72, "ease_out", 0.025)
scene:create({head, tail}, 0.52, "ease_out", 0.08)
scene:wait(0.45)
scene:indicate(tail, {scale = 1.06, duration = 0.28, curve = "gentle"})
scene:create(slot(state.tail), 0.34, "ease_out")
scene:transform(tail, rotation(step), 0.62, "ease_in_out")
scene:wait(0.28)
scene:create(slot(state.tail + 1), 0.34, "ease_out")
scene:transform(tail, rotation(2 * step), 0.62, "ease_in_out")
scene:wait(0.42)
scene:indicate(head, {scale = 1.06, duration = 0.28, curve = "gentle"})
scene:fade_out(slot(state.head), {scale = 0.92, duration = 0.34, curve = "ease_in"})
scene:transform(head, rotation(step), 0.62, "ease_in_out")
scene:wait(1.2)
return scene
