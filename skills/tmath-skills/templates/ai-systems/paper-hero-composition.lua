-- Three-zone paper hero template: problem, method, evidence.
-- Edit all zones from the same claim ledger so the composition tells one defensible story.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "pro_white",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local LAYER = {boundary = 0, route = 10, node = 20, text = 30, focus = 40}
local root = scene:group {id = "paper-hero:root"}
local header = root:group {id = "paper-hero:header"}
local problem = root:group {id = "paper-hero:problem"}
local method = root:group {id = "paper-hero:method"}
local evidence = root:group {id = "paper-hero:evidence"}
local routes = root:group {id = "paper-hero:routes"}

header:text {
    text = "Paper hero composition", point = {0, 232}, role = "h2",
    fill = "foreground", layer = LAYER.text, id = "paper-hero:title",
}
header:text {
    text = "one claim · three semantic zones · illustrative method and result",
    point = {0, 199}, role = "code", fill = "muted", layer = LAYER.text,
    id = "paper-hero:subtitle",
}

local zones = {
    {id = "problem", label = "1 · PROBLEM", center = {-318, 30}, color = "danger"},
    {id = "method", label = "2 · METHOD", center = {0, 30}, color = "accent"},
    {id = "evidence", label = "3 · EVIDENCE", center = {318, 30}, color = "result"},
}
for _, zone in ipairs(zones) do
    local parent = zone.id == "problem" and problem or (zone.id == "method" and method or evidence)
    parent:rectangle {
        center = zone.center, size = {282, 304}, corner = 9, fill = "surface",
        stroke = zone.color, width = 1.8, layer = LAYER.boundary,
        id = "paper-hero:zone:" .. zone.id .. ":boundary",
    }
    parent:text {
        text = zone.label, point = {zone.center[1], 153}, role = "code",
        fill = zone.color, layer = LAYER.text, id = "paper-hero:zone:" .. zone.id .. ":title",
    }
end

problem:text {
    text = "Global interaction", point = {-318, 101}, role = "text", fill = "foreground",
    layer = LAYER.text, id = "paper-hero:problem:label",
}
local problem_nodes = {{-382, 44}, {-318, 44}, {-254, 44}, {-350, -20}, {-286, -20}}
for index, point in ipairs(problem_nodes) do
    problem:circle {
        center = point, radius = 13, fill = "#fee2e2", stroke = "danger", width = 1.4,
        layer = LAYER.node, id = "paper-hero:problem:node:" .. index,
    }
    for target = index + 1, #problem_nodes do
        problem:line {
            from = point, to = problem_nodes[target], color = "#fca5a5", width = 0.8,
            layer = LAYER.route, id = "paper-hero:problem:edge:" .. index .. ":" .. target,
        }
    end
end
problem:text {
    text = "cost grows with all pairs", point = {-318, -84}, role = "code",
    fill = "danger", layer = LAYER.text, id = "paper-hero:problem:cost",
}

method:text {
    text = "Partition → local op → merge", point = {0, 101}, role = "text",
    fill = "foreground", layer = LAYER.text, id = "paper-hero:method:label",
}
local method_specs = {
    {id = "split", label = "split", center = {-94, 22}, width = 62},
    {id = "local", label = "local ×K", center = {0, 22}, width = 82, focal = true},
    {id = "merge", label = "merge", center = {94, 22}, width = 62},
}
local method_bodies = {}
for _, spec in ipairs(method_specs) do
    method_bodies[spec.id] = method:rectangle {
        center = spec.center, size = {spec.width, 72}, corner = 6,
        fill = spec.focal and "#dbeafe" or "background",
        stroke = spec.focal and "accent" or "border", width = spec.focal and 2.1 or 1.1,
        layer = LAYER.node, id = "paper-hero:method:" .. spec.id .. ":body",
    }
    method:text {
        text = spec.label, point = spec.center, role = "code",
        fill = spec.focal and "accent" or "foreground", layer = LAYER.text,
        id = "paper-hero:method:" .. spec.id .. ":label",
    }
end
local method_routes = {
    routes:arrow {from = {-63, 22}, to = {-41, 22}, tip = 7, color = "foreground", width = 1.6, layer = LAYER.route, id = "paper-hero:method:route:split-local"},
    routes:arrow {from = {41, 22}, to = {63, 22}, tip = 7, color = "foreground", width = 1.6, layer = LAYER.route, id = "paper-hero:method:route:local-merge"},
}
method:text {
    text = "claimed mechanism", point = {0, -84}, role = "code",
    fill = "accent", layer = LAYER.text, id = "paper-hero:method:claim",
}

evidence:text {
    text = "Same task + conditions", point = {318, 101}, role = "text",
    fill = "foreground", layer = LAYER.text, id = "paper-hero:evidence:label",
}
local evidence_values = {{label = "base", value = 0.86, y = 47, color = "muted"}, {label = "ours", value = 0.57, y = -4, color = "result"}}
local evidence_bar = nil
for _, item in ipairs(evidence_values) do
    evidence:text {
        text = item.label, point = {230, item.y}, align = {0, 0.5}, role = "code",
        fill = item.color, layer = LAYER.text, id = "paper-hero:evidence:" .. item.label .. ":label",
    }
    local body = evidence:rectangle {
        center = {290 + item.value * 90, item.y}, size = {item.value * 180, 31}, corner = 4,
        fill = item.label == "ours" and "#dcfce7" or "#e5e7eb",
        stroke = item.color, width = item.label == "ours" and 2 or 1,
        layer = LAYER.node, id = "paper-hero:evidence:" .. item.label .. ":bar",
    }
    if item.label == "ours" then evidence_bar = body end
end
evidence:text {
    text = "−33.7% illustrative", point = {318, -56}, role = "code",
    fill = "result", layer = LAYER.text, id = "paper-hero:evidence:delta",
}
evidence:text {
    text = "source + metric + units", point = {318, -90}, role = "code",
    fill = "muted", layer = LAYER.text, id = "paper-hero:evidence:provenance",
}

local story_routes = {
    routes:arrow {from = {-177, 30}, to = {-145, 30}, tip = 9, color = "danger", width = 2, layer = LAYER.focus, id = "paper-hero:route:problem-method"},
    routes:arrow {from = {141, 30}, to = {177, 30}, tip = 9, color = "result", width = 2, layer = LAYER.focus, id = "paper-hero:route:method-evidence"},
}
local conclusion = root:text {
    text = "The hero figure succeeds when the evidence tests the mechanism introduced in the center.",
    point = {0, -219}, role = "code", fill = "result", layer = LAYER.text,
    id = "paper-hero:conclusion",
}

scene:fade_in(header, {shift = {0, -6}, duration = 0.5, curve = "gentle"})
scene:fade_in(problem, {shift = {0, -6}, duration = 0.65, curve = "ease_out"})
scene:create(story_routes[1], 0.35, "ease_out")
scene:fade_in(method, {shift = {0, -6}, duration = 0.65, curve = "gentle"})
scene:create(method_routes, 0.4, "ease_out", 0.08, "forward")
scene:indicate(method_bodies["local"], {color = "focus", scale = 1.025, duration = 0.4, curve = "ease_in_out"})
scene:create(story_routes[2], 0.35, "ease_out")
scene:fade_in(evidence, {shift = {0, -6}, duration = 0.65, curve = "gentle"})
scene:indicate(evidence_bar, {color = "result", scale = 1.025, duration = 0.4, curve = "ease_in_out"})
scene:fade_in(conclusion, {duration = 0.35, curve = "gentle"})
scene:wait(2.4)
return scene
