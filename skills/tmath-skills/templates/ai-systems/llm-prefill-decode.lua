-- Question: what runs in parallel during prompt prefill, and why are ordinary generated tokens sequential?
-- The timeline is symbolic, not benchmark data. Replace tokenizer, cache layout, decoding rule, and stop condition from the source.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "pro_white",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local LAYER = {guide = 0, route = 10, node = 20, bar = 25, text = 30, focus = 40}
local root = scene:group {id = "llm-decode:root"}
local header = root:group {id = "llm-decode:header"}
local topology = root:group {id = "llm-decode:topology"}
local routes = root:group {id = "llm-decode:routes"}
local guides = root:group {id = "llm-decode:guides"}
local bars = root:group {id = "llm-decode:bars"}
local cache_entries = root:group {id = "llm-decode:cache-entries"}

header:text {
    text = "LLM prefill and autoregressive decode", point = {0, 232}, role = "h2",
    fill = "foreground", layer = LAYER.text, id = "llm-decode:title",
}
header:text {
    text = "symbolic schedule · generated token tₙ becomes a dependency of step n+1",
    point = {0, 199}, role = "code", fill = "muted", layer = LAYER.text,
    id = "llm-decode:subtitle",
}

local function node(id, label, detail, center, size, semantic)
    local group = topology:group {id = "llm-decode:node:" .. id}
    local body = group:rectangle {
        center = center, size = size, corner = 7, fill = "surface",
        stroke = semantic or "border", width = semantic and 2.25 or 1.5,
        layer = LAYER.node, id = "llm-decode:node:" .. id .. ":body",
    }
    group:text {
        text = label, point = {center[1], center[2] + 12}, role = "text",
        fill = semantic or "foreground", layer = LAYER.text,
        id = "llm-decode:node:" .. id .. ":label",
    }
    group:text {
        text = detail, point = {center[1], center[2] - 17}, role = "code",
        fill = "muted", layer = LAYER.text, id = "llm-decode:node:" .. id .. ":detail",
    }
    return body
end

local tokenizer = node("tokenizer", "Tokenizer", "text → IDs", {-405, 103}, {108, 72})
local model = node("model", "Decoder model", "prefill / step", {-210, 103}, {160, 82}, "accent")
local logits = node("logits", "Logits", "[B,V]", {20, 103}, {110, 72})
local select_token = node("selection", "Select token", "sampling / rule", {210, 103}, {140, 72})
local token = node("token", "tₙ", "next ID", {405, 103}, {82, 72}, "result")
local cache = node("cache", "KV cache", "per layer · positions", {-210, -2}, {180, 72}, "focus")

local main_routes = {
    routes:arrow {from = {-351, 103}, to = {-290, 103}, tip = 10, color = "foreground", width = 2, layer = LAYER.route, id = "llm-decode:route:tokenizer-model"},
    routes:arrow {from = {-130, 103}, to = {-35, 103}, tip = 10, color = "foreground", width = 2, layer = LAYER.route, id = "llm-decode:route:model-logits"},
    routes:arrow {from = {75, 103}, to = {140, 103}, tip = 10, color = "foreground", width = 2, layer = LAYER.route, id = "llm-decode:route:logits-selection"},
    routes:arrow {from = {280, 103}, to = {364, 103}, tip = 10, color = "result", width = 2, layer = LAYER.route, id = "llm-decode:route:selection-token"},
}
local cache_routes = {
    routes:arrow {from = {-232, 62}, to = {-232, 34}, tip = 9, color = "focus", width = 2, layer = LAYER.route, id = "llm-decode:route:cache-write"},
    routes:arrow {from = {-188, 34}, to = {-188, 62}, tip = 9, color = "focus", width = 2, layer = LAYER.route, id = "llm-decode:route:cache-read"},
}
local feedback = routes:route {
    points = {{405, 139}, {405, 174}, {-210, 174}, {-210, 145}},
    tip = 10, color = "result", width = 2, layer = LAYER.route,
    id = "llm-decode:route:next-token-feedback",
}
local feedback_label = root:text {
    text = "selected token becomes the next model input", point = {96, 158},
    role = "code", fill = "result", layer = LAYER.text,
    id = "llm-decode:feedback-label",
}

guides:arrow {
    from = {-420, -73}, to = {420, -73}, tip = 10, color = "border", width = 1.5,
    layer = LAYER.guide, id = "llm-decode:time-axis",
}
guides:text {
    text = "symbolic time →", point = {-420, -48}, align = {0, 0.5},
    role = "code", fill = "muted", layer = LAYER.text, id = "llm-decode:time-label",
}

local bar_specs = {
    {id = "prefill", label = "prefill: prompt positions", left = -410, width = 250, color = "accent"},
    {id = "decode1", label = "decode 1", left = -140, width = 120, color = "focus"},
    {id = "decode2", label = "decode 2", left = 0, width = 120, color = "focus"},
    {id = "decode3", label = "decode 3", left = 140, width = 120, color = "focus"},
}
local bar_bodies, bar_labels = {}, {}
for index, spec in ipairs(bar_specs) do
    bar_bodies[index] = bars:rectangle {
        center = {spec.left + spec.width * 0.5, -105}, size = {spec.width, 34}, corner = 5,
        fill = "surface", stroke = spec.color, width = 2, layer = LAYER.bar,
        id = "llm-decode:bar:" .. spec.id,
    }
    bar_labels[index] = bars:text {
        text = spec.label, point = {spec.left + spec.width * 0.5, -105}, role = "code",
        fill = spec.color, layer = LAYER.text, id = "llm-decode:bar:" .. spec.id .. ":label",
    }
end

local cache_row_label = cache_entries:text {
    text = "KV slots", point = {-468, -174}, align = {0, 0.5}, role = "code",
    fill = "muted", layer = LAYER.text, id = "llm-decode:cache-row-label",
}
local entry_specs = {
    {id = "prompt", label = "prompt K,V", center = {-286, -174}, size = {170, 42}, color = "accent"},
    {id = "t1", label = "t₁", center = {-142, -174}, size = {62, 42}, color = "focus"},
    {id = "t2", label = "t₂", center = {-65, -174}, size = {62, 42}, color = "focus"},
    {id = "t3", label = "t₃", center = {12, -174}, size = {62, 42}, color = "focus"},
}
local entry_groups = {}
for index, spec in ipairs(entry_specs) do
    local group = cache_entries:group {id = "llm-decode:cache-entry:" .. spec.id}
    entry_groups[index] = group
    group:rectangle {
        center = spec.center, size = spec.size, corner = 5, fill = "surface",
        stroke = spec.color, width = 1.75, layer = LAYER.node,
        id = "llm-decode:cache-entry:" .. spec.id .. ":body",
    }
    group:text {
        text = spec.label, point = spec.center, role = "code", fill = spec.color,
        layer = LAYER.text, id = "llm-decode:cache-entry:" .. spec.id .. ":label",
    }
end
local cache_ellipsis = cache_entries:text {
    text = "…", point = {68, -174}, role = "text", fill = "muted",
    layer = LAYER.text, id = "llm-decode:cache-ellipsis",
}

local conclusion = root:text {
    text = "Prefill handles the known prompt; each decode step appends cache state and waits for the selected token.",
    point = {0, -235}, role = "code", fill = "result", layer = LAYER.text,
    id = "llm-decode:conclusion",
}

scene:fade_in(header, {shift = {0, -6}, duration = 0.55, curve = "gentle"})
scene:fade_in(topology, {shift = {0, -6}, duration = 0.65, curve = "ease_out"})
scene:create(main_routes, 0.75, "ease_out", 0.06, "forward")
scene:create(cache_routes, 0.45, "ease_out", 0.08, "forward")
scene:create(feedback, 0.55, "ease_out")
scene:fade_in(feedback_label, {duration = 0.3, curve = "gentle"})
scene:fade_in(guides, {duration = 0.35, curve = "gentle"})
scene:fade_in(cache_row_label, {duration = 0.25, curve = "gentle"})
for index, body in ipairs(bar_bodies) do
    scene:grow_from_edge(body, "left", index == 1 and 0.7 or 0.48, "ease_out")
    scene:fade_in(bar_labels[index], {duration = 0.24, curve = "gentle"})
    scene:fade_in(entry_groups[index], {shift = {0, -4}, duration = 0.3, curve = "gentle"})
end
scene:fade_in(cache_ellipsis, {duration = 0.24, curve = "gentle"})
scene:indicate(cache, {color = "focus", scale = 1.025, duration = 0.42, curve = "ease_in_out"})
scene:indicate(token, {color = "result", scale = 1.03, duration = 0.42, curve = "ease_in_out"})
scene:fade_in(conclusion, {shift = {0, -5}, duration = 0.4, curve = "gentle"})
scene:wait(2.4)
return scene
