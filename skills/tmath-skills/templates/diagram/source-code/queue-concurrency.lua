-- Question: what unblocks a producer waiting on a full queue?
-- Source-derived example: Modern-CPP-Design-Patterns/35_ThreadPool/ThreadPool.h.
-- Edit surface: SPEC, queue capacity/snapshots, actor labels, and ordered messages.
-- Preserve: concrete queue cells, wait predicate, partial-order constraints, and scheduler uncertainty.
local SPEC = {
    question = "What unblocks a producer waiting on a full queue?",
    source = "ThreadPool.h · SafeQueue::push / SafeQueue::pop",
    evidence = "partial order derived from source · task identities A–D illustrative",
}

local scene = tmath.scene {
    width = 1280, height = 720, fps = 30, loop = false,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 720},
}

local LAYER = {guide = 0, route = 10, body = 20, text = 40, focus = 50}
local root = scene:group {id = "queue-concurrency:root"}
local timeline = root:group {id = "queue-concurrency:timeline"}
local stateArea = root:group {id = "queue-concurrency:state-area"}

local title = root:text {
    text = SPEC.question, point = {0, 318}, role = "h2", fill = "foreground",
    layer = LAYER.text, id = "queue-concurrency:title",
}
local subtitle = root:text {
    text = SPEC.source .. " · " .. SPEC.evidence, point = {0, 280}, role = "code",
    fill = "muted", layer = LAYER.text, id = "queue-concurrency:subtitle",
}
local divider = root:line {
    from = {-600, 252}, to = {600, 252}, stroke = "border", width = 1.5,
    layer = LAYER.guide, id = "queue-concurrency:header-divider",
}

local actorSpecs = {
    {id = "producer", label = "producer thread", x = -400, width = 190},
    {id = "queue", label = "SafeQueue<Task>", x = 0, width = 230},
    {id = "worker", label = "worker thread", x = 400, width = 190},
}
local actorHandles = {}
for _, actor in ipairs(actorSpecs) do
    local group = timeline:group {id = "queue-concurrency:actor:" .. actor.id}
    local body = group:rectangle {
        center = {actor.x, 188}, size = {actor.width, 52}, corner = 7, fill = "surface",
        stroke = actor.id == "queue" and "accent" or "border",
        width = actor.id == "queue" and 2 or 1.5,
        layer = LAYER.body, id = "queue-concurrency:actor:" .. actor.id .. ":body",
    }
    local label = group:text {
        text = actor.label, point = {actor.x, 188}, role = "code",
        fill = actor.id == "queue" and "accent" or "foreground",
        layer = LAYER.text, id = "queue-concurrency:actor:" .. actor.id .. ":label",
    }
    local lifeline = timeline:line {
        from = {actor.x, 161}, to = {actor.x, -172}, stroke = "border", width = 1.4,
        dash = {7, 7}, layer = LAYER.guide, id = "queue-concurrency:lifeline:" .. actor.id,
    }
    actorHandles[actor.id] = {group = group, body = body, label = label, lifeline = lifeline}
end

local timeAxis = timeline:arrow {
    from = {-584, 160}, to = {-584, -172}, tip = 10, stroke = "muted", width = 1.7,
    layer = LAYER.guide, id = "queue-concurrency:time-axis",
}
local timeLabel = timeline:text {
    text = "time", point = {-584, 188}, role = "code", fill = "muted",
    layer = LAYER.text, id = "queue-concurrency:time-label",
}

local function message(id, fromX, toX, y, label, color, dashed)
    local route = timeline:arrow {
        from = {fromX, y}, to = {toX, y}, tip = 11, stroke = color, width = 2.35,
        dash = dashed and {8, 6} or nil, layer = LAYER.route,
        id = "queue-concurrency:message:" .. id,
    }
    local labelHandle = timeline:text {
        text = label, point = {(fromX + toX) * 0.5, y + 17}, role = "code",
        fill = color, layer = LAYER.text, id = "queue-concurrency:message:" .. id .. ":label",
    }
    return {route = route, label = labelHandle}
end

local pushMessage = message("push-waits", -400, 0, 112, "push(D) · wait [size == max]", "warning", false)
local popMessage = message("pop-front", 400, 0, 22, "pop(A) · queue_.pop()", "accent", false)
local notifyMessage = message("notify-space", 0, -400, -66, "notify_one() · eligible, not scheduled", "warning", true)
local resumeMessage = message("push-resumes", -400, 0, -150, "lock reacquired · queue_.push(D)", "result", false)

local blockedSpan = timeline:rectangle {
    center = {-400, 23}, size = {12, 154}, corner = 2, fill = "warning", stroke = "warning",
    opacity = 0.72, layer = LAYER.body, id = "queue-concurrency:producer:blocked-span",
}
local blockedSpanLabel = timeline:text {
    text = "blocked while predicate is false", point = {-380, 23}, align = {0, 0.5},
    role = "code", fill = "warning", layer = LAYER.text,
    id = "queue-concurrency:producer:blocked-span:label",
}

local queueGroup = stateArea:group {id = "queue-concurrency:queue-state"}
local queueBody = queueGroup:rectangle {
    center = {0, -242}, size = {326, 106}, corner = 8, fill = "surface", stroke = "accent",
    width = 2, layer = LAYER.body, id = "queue-concurrency:queue-state:body",
}
local queueTitle = queueGroup:text {
    text = "queue_ · max = 3 · logical cells", point = {0, -210}, role = "code",
    fill = "muted", layer = LAYER.text, id = "queue-concurrency:queue-state:title",
}
local cellX = {-82, 0, 82}
local cellBodies = {}
for index, x in ipairs(cellX) do
    cellBodies[index] = queueGroup:rectangle {
        center = {x, -256}, size = {70, 44}, corner = 5, fill = "surface", stroke = "border",
        width = 1.5, layer = LAYER.body, id = "queue-concurrency:queue-cell:" .. index .. ":body",
    }
end

local function queue_snapshot(id, values, opacity, focalIndex)
    local group = queueGroup:group {id = "queue-concurrency:queue-snapshot:" .. id, opacity = opacity}
    for index, value in ipairs(values) do
        group:text {
            text = value, point = {cellX[index], -256}, role = "code",
            fill = index == focalIndex and "result" or (value == "empty" and "muted" or "foreground"),
            layer = LAYER.text, id = "queue-concurrency:queue-snapshot:" .. id .. ":cell:" .. index,
        }
    end
    return group
end

local queueFull = queue_snapshot("full", {"A", "B", "C"}, 1, nil)
local queueSpace = nil
local queueRefilled = nil

local producerState = stateArea:group {id = "queue-concurrency:producer-state"}
local producerStateBody = producerState:rectangle {
    center = {-412, -242}, size = {310, 82}, corner = 8, fill = "surface", stroke = "border",
    width = 1.5, layer = LAYER.body, id = "queue-concurrency:producer-state:body",
}
local function producer_snapshot(id, heading, detail, color, opacity)
    local group = producerState:group {id = "queue-concurrency:producer-state:" .. id, opacity = opacity}
    group:text {
        text = heading, point = {-412, -228}, role = "code", fill = color,
        layer = LAYER.text, id = "queue-concurrency:producer-state:" .. id .. ":heading",
    }
    group:text {
        text = detail, point = {-412, -257}, role = "code", fill = "muted",
        layer = LAYER.text, id = "queue-concurrency:producer-state:" .. id .. ":detail",
    }
    return group
end
local producerRunning = producer_snapshot("running", "RUNNING", "enters push(D)", "foreground", 1)
local producerWaiting = nil
local producerEligible = nil
local producerResumed = nil

local workerState = stateArea:group {id = "queue-concurrency:worker-state"}
local workerStateBody = workerState:rectangle {
    center = {412, -242}, size = {270, 82}, corner = 8, fill = "surface", stroke = "border",
    width = 1.5, layer = LAYER.body, id = "queue-concurrency:worker-state:body",
}
local workerStateLabel = workerState:text {
    text = "pop not reached yet", point = {412, -242}, role = "code", fill = "muted",
    layer = LAYER.text, id = "queue-concurrency:worker-state:initial",
}

local resultBody = root:rectangle {
    center = {0, -324}, size = {1080, 46}, corner = 7, fill = "surface", stroke = "result",
    width = 2, layer = LAYER.body, id = "queue-concurrency:result:body",
}
local resultLabel = root:text {
    text = "proof: pop removes one cell before notify_one; actual wake time remains scheduler-dependent",
    point = {0, -324}, role = "code", fill = "result", layer = LAYER.text,
    id = "queue-concurrency:result:label",
}

scene:fade_in(title, {shift = {0, -6}, duration = 0.42, curve = "gentle"})
scene:fade_in(subtitle, {shift = {0, -4}, duration = 0.32, curve = "gentle"})
scene:create(divider, 0.28, "ease_out")
scene:fade_in(timeline, {shift = {0, 5}, duration = 0.52, curve = "gentle"})
scene:fade_in(stateArea, {shift = {0, 5}, duration = 0.48, curve = "gentle"})
scene:wait(0.50)

scene:create(pushMessage.route, 0.52, "ease_out")
scene:fade_in(pushMessage.label, {shift = {0, -3}, duration = 0.24, curve = "gentle"})
producerWaiting = producer_snapshot("waiting", "WAITING", "queue_.size() == max", "warning", 0)
scene:transition(producerRunning, producerWaiting, 0.32, "ease_in_out")
scene:fade_in(blockedSpan, {duration = 0.24, curve = "gentle"})
scene:fade_in(blockedSpanLabel, {duration = 0.20, curve = "gentle"})
scene:wait(0.65)

scene:create(popMessage.route, 0.50, "ease_out")
scene:fade_in(popMessage.label, {shift = {0, -3}, duration = 0.22, curve = "gentle"})
queueSpace = queue_snapshot("space-after-pop", {"B", "C", "empty"}, 0, 3)
scene:transition(queueFull, queueSpace, 0.38, "ease_in_out")
local workerPopped = workerState:text {
    text = "popped A · space exists", point = {412, -242}, role = "code", fill = "accent",
    layer = LAYER.text, id = "queue-concurrency:worker-state:popped",
}
scene:fade_transform(workerStateLabel, workerPopped, 0.26, "gentle")
workerStateLabel = workerPopped
scene:play({{target = workerStateBody, stroke = "accent"}}, 0.24, "ease_in_out", 0)
scene:wait(0.48)

scene:create(notifyMessage.route, 0.54, "ease_out")
scene:fade_in(notifyMessage.label, {shift = {0, -3}, duration = 0.24, curve = "gentle"})
producerEligible = producer_snapshot("eligible", "ELIGIBLE", "scheduler time unresolved", "warning", 0)
scene:transition(producerWaiting, producerEligible, 0.32, "ease_in_out")
scene:indicate(producerStateBody, {color = "warning", scale = 1.025, duration = 0.34, curve = "ease_in_out"})
scene:wait(0.72)

scene:create(resumeMessage.route, 0.54, "ease_out")
scene:fade_in(resumeMessage.label, {shift = {0, -3}, duration = 0.24, curve = "gentle"})
producerResumed = producer_snapshot("resumed", "RUNNING", "lock reacquired · push commits", "result", 0)
scene:transition(producerEligible, producerResumed, 0.32, "ease_in_out")
queueRefilled = queue_snapshot("refilled", {"B", "C", "D"}, 0, 3)
scene:transition(queueSpace, queueRefilled, 0.38, "ease_in_out")
scene:play({
    {target = queueBody, stroke = "result"},
    {target = producerStateBody, stroke = "result"},
}, 0.30, "ease_in_out", 0)
scene:fade_in(resultBody, {scale = 0.985, duration = 0.32, curve = "gentle"})
scene:fade_in(resultLabel, {duration = 0.24, curve = "gentle"})
scene:wait(2.8)
return scene
