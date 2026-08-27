-- Question: which event changes state, which guard chooses a branch, and where can flow end?
-- Replace state and transition labels below; preserve distinct ports and transition corridors.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local LAYER = {route = 10, state = 20, text = 30}
local root = scene:group {id = "job-state:root"}
local symbols = root:group {id = "job-state:symbols"}

local function state(id, label, center, options)
    options = options or {}
    local prefix = "job-state:state:" .. id
    symbols:rectangle {
        center = center, size = options.size or {120, 54}, corner = 4, fill = "surface",
        stroke = options.stroke or "border", width = options.focal and 2 or 1.5,
        layer = LAYER.state, id = prefix .. ":body",
    }
    symbols:text {
        text = label, point = center, role = "text", fill = options.fill or "foreground",
        layer = LAYER.text, id = prefix .. ":label",
    }
end

-- UML start, state, choice, and final symbols are intentionally different primitives.
symbols:circle {
    center = {-435, 120}, radius = 8, fill = "foreground", stroke = "foreground",
    layer = LAYER.state, id = "job-state:start",
}
state("idle", "Idle", {-315, 120})
symbols:polygon {
    points = {{-105, 142}, {-83, 120}, {-105, 98}, {-127, 120}},
    fill = "surface", stroke = "result", width = 2,
    layer = LAYER.state, id = "job-state:choice:validation",
}
symbols:text {
    text = "VALID?", point = {-105, 190}, role = "code", fill = "muted",
    layer = LAYER.text, id = "job-state:choice:validation:label",
}
state("active", "Active", {105, 120}, {stroke = "accent", fill = "accent", focal = true})
state("closed", "Closed", {305, 120})
state("rejected", "Rejected", {-295, -105}, {stroke = "danger", fill = "danger", focal = true, size = {130, 54}})
state("retry", "Retry", {105, -105})

local function final_symbol(id, center, stroke)
    symbols:circle {
        center = center, radius = 13, fill = "surface", stroke = stroke or "foreground",
        width = 2, layer = LAYER.state, id = "job-state:final:" .. id .. ":ring",
    }
    symbols:circle {
        center = center, radius = 6, fill = stroke or "foreground", stroke = stroke or "foreground",
        layer = LAYER.state, id = "job-state:final:" .. id .. ":dot",
    }
end
final_symbol("complete", {435, 120})
final_symbol("rejected", {-295, -205}, "danger")

local transitions = {}
local function transition(spec)
    local prefix = "job-state:transition:" .. spec.id
    local geometry
    if #spec.points == 2 then
        geometry = root:arrow {
            from = spec.points[1], to = spec.points[2], tip = 10,
            color = spec.color or "foreground", width = 2,
            layer = LAYER.route, id = prefix .. ":route",
        }
    else
        geometry = root:route {
            points = spec.points, tip = 10, color = spec.color or "foreground", width = 2,
            dash = spec.dash, layer = LAYER.route, id = prefix .. ":route",
        }
    end
    local label = nil
    if spec.label then
        label = root:text {
            text = spec.label, point = spec.label_point, align = spec.align,
            role = "code", fill = spec.color or "muted", layer = LAYER.text,
            id = prefix .. ":label",
        }
    end
    transitions[#transitions + 1] = {geometry = geometry, label = label}
end

-- Happy path first, then bounded failure/retry paths. No transition shares a shaft.
transition {id = "start-idle", points = {{-427, 120}, {-375, 120}}}
transition {
    id = "idle-validate", label = "submit", points = {{-255, 120}, {-127, 120}},
    label_point = {-191, 166},
}
transition {
    id = "validate-active", label = "[valid] / activate", points = {{-83, 120}, {45, 120}},
    label_point = {-19, 166},
}
transition {
    id = "active-closed", label = "complete", points = {{165, 120}, {245, 120}},
    label_point = {205, 166},
}
transition {id = "closed-final", points = {{365, 120}, {422, 120}}}
transition {
    id = "validate-rejected", label = "[invalid] / reject",
    points = {{-122, 105}, {-122, 20}, {-295, 20}, {-295, -78}},
    label_point = {-209, 34}, color = "danger",
}
transition {
    id = "rejected-final", label = "stop", points = {{-295, -132}, {-295, -192}},
    label_point = {-280, -162}, align = {0, 0.5}, color = "danger",
}
transition {
    id = "active-retry", label = "timeout / backoff", points = {{105, 93}, {105, -78}},
    label_point = {120, 7}, align = {0, 0.5},
}
transition {
    id = "retry-validate", label = "retry [count < 3]",
    points = {{45, -105}, {-105, -105}, {-105, 98}},
    label_point = {-30, -125}, dash = {7, 5},
}

scene:fade_in(symbols, {shift = {0, -6}, duration = 0.65, curve = "gentle"})
for _, item in ipairs(transitions) do
    scene:create(item.geometry, 0.38, "ease_out")
    if item.label then
        scene:fade_in(item.label, {shift = {0, -4}, duration = 0.16, curve = "gentle"})
    end
end
scene:wait(2.4)
return scene
