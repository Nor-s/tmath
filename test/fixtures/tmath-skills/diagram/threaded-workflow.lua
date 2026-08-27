-- Question: when does foreground work hand off to the scheduler, and how is queued work assigned to threads?
-- Replace task_specs and thread_specs; keep the sequence time axis separate from the scheduler topology.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local LAYER = {boundary = 0, route = 10, node = 20, text = 30}
local root = scene:group {id = "threaded-workflow:root"}
local sequence = root:group {id = "threaded-workflow:sequence"}
local scheduler = root:group {id = "threaded-workflow:scheduler"}
local routes = root:group {id = "threaded-workflow:routes"}
local messagesGroup = root:group {id = "threaded-workflow:messages"}
local messageLabels = root:group {id = "threaded-workflow:message-labels"}

sequence:text {
    text = "FOREGROUND / BACKGROUND HANDOFF", point = {-430, 230}, align = {0, 0.5},
    role = "code", fill = "muted", layer = LAYER.text, id = "threaded-workflow:sequence:title",
}
local actors = {{id = "app", label = "App", x = -385}, {id = "runtime", label = "Runtime", x = -235}}
for _, actor in ipairs(actors) do
    sequence:rectangle {
        center = {actor.x, 180}, size = {110, 46}, corner = 2, fill = "surface", stroke = "border",
        width = 1.5, layer = LAYER.node, id = "threaded-workflow:actor:" .. actor.id .. ":body",
    }
    sequence:text {
        text = actor.label, point = {actor.x, 180}, role = "code", fill = "foreground",
        layer = LAYER.text, id = "threaded-workflow:actor:" .. actor.id .. ":label",
    }
    sequence:line {
        from = {actor.x, 157}, to = {actor.x, -205}, color = "border", width = 1.5,
        dash = {7, 6}, layer = LAYER.boundary, id = "threaded-workflow:lifeline:" .. actor.id,
    }
end
local message_specs = {
    {id = "update", from = -385, to = -235, y = 105, label = "update()", color = "accent"},
    {id = "render", from = -385, to = -235, y = 20, label = "render()", color = "foreground"},
    {id = "sync", from = -235, to = -385, y = -80, label = "frame ready", color = "result", dashed = true},
}
local messages = {}
for _, msg in ipairs(message_specs) do
    messages[#messages + 1] = messagesGroup:arrow {
        from = {msg.from, msg.y}, to = {msg.to, msg.y}, tip = 10, color = msg.color,
        width = 2, dash = msg.dashed and {8, 6} or nil, layer = LAYER.route,
        id = "threaded-workflow:message:" .. msg.id,
    }
    messageLabels:text {
        text = msg.label, point = {(msg.from + msg.to) * 0.5, msg.y + 18}, role = "code",
        fill = msg.color, layer = LAYER.text, id = "threaded-workflow:message:" .. msg.id .. ":label",
    }
end
sequence:rectangle {
    center = {-235, 26}, size = {10, 230}, corner = 1, fill = "accent", stroke = "accent",
    layer = LAYER.node, id = "threaded-workflow:activation",
}
sequence:text {
    text = "background", point = {-205, 26}, align = {0, 0.5}, role = "code",
    fill = "muted", layer = LAYER.text, id = "threaded-workflow:activation:label",
}

scheduler:rectangle {
    center = {165, 0}, size = {500, 430}, corner = 3, fill = "surface", stroke = "border",
    width = 1.5, dash = {8, 6}, opacity = 0.65, layer = LAYER.boundary,
    id = "threaded-workflow:scheduler:boundary",
}
scheduler:text {
    text = "TASK SCHEDULER", point = {-70, 188}, align = {0, 0.5}, role = "code",
    fill = "muted", layer = LAYER.text, id = "threaded-workflow:scheduler:title",
}

local task_specs = {
    {id = "layout", label = "Layout", x = -35},
    {id = "paint", label = "Paint", x = 65},
    {id = "encode", label = "Encode", x = 165},
}
for _, task in ipairs(task_specs) do
    scheduler:rectangle {
        center = {task.x, 125}, size = {84, 44}, corner = 2, fill = "surface", stroke = "border",
        width = 1.5, layer = LAYER.node, id = "threaded-workflow:task:" .. task.id,
    }
    scheduler:text {
        text = task.label, point = {task.x, 125}, role = "code", fill = "foreground",
        layer = LAYER.text, id = "threaded-workflow:task:" .. task.id .. ":label",
    }
end
scheduler:rectangle {
    center = {65, 62}, size = {220, 42}, corner = 2, fill = "surface", stroke = "accent",
    width = 2, layer = LAYER.node, id = "threaded-workflow:queue",
}
scheduler:text {
    text = "ready queue  [ 3 · 2 · 1 ]", point = {65, 62}, role = "code", fill = "accent",
    layer = LAYER.text, id = "threaded-workflow:queue:label",
}
scheduler:rectangle {
    center = {65, -24}, size = {170, 64}, corner = 3, fill = "surface", stroke = "accent",
    width = 2.25, layer = LAYER.node, id = "threaded-workflow:dispatcher",
}
scheduler:text {
    text = "Dispatcher", point = {65, -24}, role = "text", fill = "accent",
    layer = LAYER.text, id = "threaded-workflow:dispatcher:label",
}

local thread_specs = {
    {id = "one", label = "Thread 1", detail = "buffer A", y = 95},
    {id = "two", label = "Thread 2", detail = "buffer B", y = 0},
    {id = "three", label = "Thread 3", detail = "buffer C", y = -95},
}
for _, thread in ipairs(thread_specs) do
    scheduler:rectangle {
        center = {330, thread.y}, size = {118, 56}, corner = 2, fill = "surface", stroke = "border",
        width = 1.5, layer = LAYER.node, id = "threaded-workflow:thread:" .. thread.id,
    }
    scheduler:text {
        text = thread.label, point = {330, thread.y + 10}, role = "code", fill = "foreground",
        layer = LAYER.text, id = "threaded-workflow:thread:" .. thread.id .. ":label",
    }
    scheduler:text {
        text = thread.detail, point = {330, thread.y - 14}, role = "code", fill = "muted",
        layer = LAYER.text, id = "threaded-workflow:thread:" .. thread.id .. ":detail",
    }
end

local topology = {}
for _, task in ipairs(task_specs) do
    topology[#topology + 1] = routes:route {
        points = {{task.x, 103}, {task.x, 88}, {65, 88}, {65, 83}}, tip = 8,
        color = "foreground", width = 1.6, layer = LAYER.route,
        id = "threaded-workflow:enqueue:" .. task.id,
    }
end
topology[#topology + 1] = routes:arrow {
    from = {65, 41}, to = {65, 8}, tip = 9, color = "accent", width = 2,
    layer = LAYER.route, id = "threaded-workflow:queue-dispatch",
}
for _, thread in ipairs(thread_specs) do
    topology[#topology + 1] = routes:route {
        points = {{150, -24}, {220, -24}, {220, thread.y}, {270, thread.y}}, tip = 9,
        color = "foreground", width = 1.8, layer = LAYER.route,
        id = "threaded-workflow:dispatch:" .. thread.id,
    }
end
local complete = routes:route {
    points = {{270, -95}, {235, -95}, {235, -165}, {-235, -165}, {-235, -103}}, tip = 10,
    color = "result", width = 2, dash = {8, 6}, layer = LAYER.route,
    id = "threaded-workflow:completion",
}
local completeLabel = root:text {
    text = "notify completion", point = {0, -147}, role = "code", fill = "result",
    layer = LAYER.text, id = "threaded-workflow:completion:label",
}

scene:fade_in(sequence, {duration = 0.55, curve = "gentle"})
for _, message in ipairs(messages) do scene:create(message, 0.42, "ease_out") end
scene:fade_in(messageLabels, {shift = {0, -4}, duration = 0.3, curve = "gentle"})
scene:fade_in(scheduler, {shift = {-7, 0}, duration = 0.65, curve = "gentle"})
for _, route in ipairs(topology) do scene:create(route, 0.25, "ease_out") end
scene:create(complete, 0.75, "ease_out")
scene:fade_in(completeLabel, {shift = {0, -4}, duration = 0.25, curve = "gentle"})
scene:wait(2.6)
return scene
