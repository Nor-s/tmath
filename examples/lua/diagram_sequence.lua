local LAYER = {
    structure = 0,
    activation = 5,
    route = 10,
    node = 20,
    text = 30,
}

local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    loop = false,
    theme = "pro_white",
    camera = { mode = "fixed", view = "2d", target = { 0, 0 }, height = 540 },
}

local header = scene:group { id = "sequence-header" }
header:text {
    text = "Checkout returns before receipt work finishes",
    point = { -432, 232 },
    align = { 0, 0.5 },
    role = "h2",
    id = "sequence-title",
}
header:text {
    text = "Time moves downward; dashed messages return or continue without blocking the caller.",
    point = { -432, 194 },
    align = { 0, 0.5 },
    role = "text",
    fill = "muted",
    id = "sequence-subtitle",
}
header:line {
    from = { -432, 162 },
    to = { 432, 162 },
    color = "border",
    width = 1,
    layer = LAYER.structure,
    id = "sequence-divider",
}

local actors = scene:group { id = "sequence-actors" }
local actor_x = { -330, -110, 110, 330 }
local actor_names = { "Web", "API", "Worker", "Database" }
for index, x in ipairs(actor_x) do
    local actor = actors:group { id = "actor-" .. index }
    actor:rectangle {
        center = { x, 112 },
        size = { 132, 54 },
        corner = 9,
        fill = "surface",
        stroke = index == 2 and "focus" or "border",
        width = index == 2 and 2.5 or 1.25,
        layer = LAYER.node,
        id = "actor-" .. index .. "-body",
    }
    actor:text {
        text = actor_names[index],
        point = { x, 112 },
        role = "text",
        fill = index == 2 and "focus" or "foreground",
        layer = LAYER.text,
        id = "actor-" .. index .. "-label",
    }
end

local lifelines = scene:group { id = "sequence-lifelines" }
for index, x in ipairs(actor_x) do
    lifelines:line {
        from = { x, 84 },
        to = { x, -192 },
        color = "border",
        width = 1.5,
        dash = { 7, 7 },
        layer = LAYER.structure,
        id = "lifeline-" .. index,
    }
end

local activations = scene:group { id = "sequence-activations" }
activations:rectangle {
    center = { -110, -64 },
    size = { 10, 212 },
    corner = 3,
    fill = "surface",
    stroke = "focus",
    width = 1.5,
    layer = LAYER.activation,
    id = "activation-api",
}
activations:rectangle {
    center = { 330, -14 },
    size = { 10, 80 },
    corner = 3,
    fill = "surface",
    stroke = "border",
    width = 1.25,
    layer = LAYER.activation,
    id = "activation-database",
}
activations:rectangle {
    center = { 110, -147 },
    size = { 10, 58 },
    corner = 3,
    fill = "surface",
    stroke = "border",
    width = 1.25,
    layer = LAYER.activation,
    id = "activation-worker",
}

local messages = scene:group { id = "sequence-messages" }
local labels = scene:group { id = "sequence-labels" }
local message_handles = {}
local message_specs = {
    { "checkout", -330, -110, 40, "POST /checkout", false, "accent" },
    { "reserve", -110, 330, -14, "reserve(order)", false, "accent" },
    { "reserved", 330, -110, -68, "reservation", true, "muted" },
    { "publish", -110, 110, -122, "publish(receipt)", true, "secondary" },
    { "accepted", 110, -110, -176, "accepted", true, "muted" },
}

for _, spec in ipairs(message_specs) do
    local id, from_x, to_x, y, label, dashed, color = table.unpack(spec)
    message_handles[#message_handles + 1] = messages:arrow {
        from = { from_x, y },
        to = { to_x, y },
        tip = 12,
        color = color,
        width = 2.5,
        dash = dashed and { 8, 6 } or nil,
        layer = LAYER.route,
        id = "message-" .. id,
    }
    labels:text {
        text = label,
        point = { (from_x + to_x) * 0.5, y + 16 },
        role = "code",
        fill = color,
        layer = LAYER.text,
        id = "message-" .. id .. "-label",
    }
end

scene:fade_in(header, { shift = { 0, 8 }, duration = 0.45, curve = "gentle" })
scene:fade_in(actors, { duration = 0.55, curve = "ease_out" })
scene:fade_in(lifelines, { duration = 0.4, curve = "gentle" })
scene:fade_in(activations, { duration = 0.4, curve = "gentle" })
for _, message in ipairs(message_handles) do
    scene:create(message, 0.55, "ease_out", 0, "forward")
    scene:wait(0.16)
end
scene:fade_in(labels, { duration = 0.4, curve = "gentle" })
scene:wait(2.2)
return scene
