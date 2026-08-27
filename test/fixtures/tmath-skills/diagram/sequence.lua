-- Question: who waits, which message returns, and which work continues asynchronously?
-- Preserve the top-to-bottom execution order in message_specs.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = { mode = "fixed", view = "2d", target = { 0, -39 }, height = 540 },
}
local layer = { structure = 0, route = 10, node = 20, text = 30 }

local actors = scene:group { id = "actors" }
local actor_x = { -300, 0, 300 }
local actor_names = { "Caller", "Service", "Worker" }
for index, x in ipairs(actor_x) do
    local actor = actors:group { id = "actor-" .. index }
    actor:rectangle {
        center = { x, 112 }, size = { 140, 54 }, corner = 9, fill = "surface",
        stroke = index == 2 and "focus" or "border", width = index == 2 and 2.25 or 1.25,
        layer = layer.node, id = "actor-" .. index .. "-body",
    }
    actor:text {
        text = actor_names[index], point = { x, 112 }, role = "text",
        fill = index == 2 and "focus" or "foreground", layer = layer.text,
        id = "actor-" .. index .. "-label",
    }
    actors:line {
        from = { x, 84 }, to = { x, -190 }, color = "border", width = 1.5, dash = { 7, 7 },
        layer = layer.structure, id = "lifeline-" .. index,
    }
end

local messages = scene:group { id = "messages" }
local labels = scene:group { id = "message-labels" }
local message_specs = {
    { id = "call", from = -300, to = 0, y = 35, text = "request()", color = "accent" },
    { id = "enqueue", from = 0, to = 300, y = -35, text = "enqueue(job)", color = "secondary" },
    { id = "return", from = 0, to = -300, y = -105, text = "accepted", color = "muted", dashed = true },
}
local handles = {}
for _, spec in ipairs(message_specs) do
    handles[#handles + 1] = messages:arrow {
        from = { spec.from, spec.y }, to = { spec.to, spec.y }, tip = 12,
        color = spec.color, width = 2.5, dash = spec.dashed and { 8, 6 } or nil,
        layer = layer.route, id = "message-" .. spec.id,
    }
    labels:text {
        text = spec.text, point = { (spec.from + spec.to) * 0.5, spec.y + 16 }, role = "code",
        fill = spec.color, layer = layer.text, id = "message-" .. spec.id .. "-label",
    }
end

scene:fade_in(actors, { duration = 0.65, curve = "ease_out" })
for _, handle in ipairs(handles) do
    scene:create(handle, 0.6, "ease_out", 0, "forward")
    scene:wait(0.2)
end
scene:fade_in(labels, { duration = 0.4, curve = "gentle" })
scene:wait(2.2)
return scene
