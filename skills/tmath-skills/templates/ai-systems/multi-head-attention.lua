-- Source: Vaswani et al. (2017), Figure 2 (right) and Section 3.2.2.
-- Question: where do independent head projections fan out, and where do they first merge?
-- This shows logical graph parallelism; physical GPU concurrency is implementation-specific.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "pro_white",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local LAYER = {guide = 0, route = 10, node = 20, text = 30, focus = 40}
local root = scene:group {id = "multi-head:root"}
local header = root:group {id = "multi-head:header"}
local context = root:group {id = "multi-head:context"}
local fan = root:group {id = "multi-head:fan"}
local heads = root:group {id = "multi-head:heads"}
local merge_routes_group = root:group {id = "multi-head:merge-routes"}
local merge = root:group {id = "multi-head:merge"}
local tail = root:group {id = "multi-head:tail"}
local evidence = root:group {id = "multi-head:evidence"}

header:text {
    text = "Multi-head attention", point = {0, 232}, role = "h2",
    fill = "foreground", layer = LAYER.text, id = "multi-head:title",
}
header:text {
    text = "Vaswani et al. · Figure 2 · base model h = 8 · logical head parallelism",
    point = {0, 199}, role = "code", fill = "muted", layer = LAYER.text,
    id = "multi-head:subtitle",
}

local function box(parent, id, label, detail, center, size, semantic)
    local group = parent:group {id = "multi-head:node:" .. id}
    local body = group:rectangle {
        center = center, size = size, corner = 7, fill = "surface",
        stroke = semantic or "border", width = semantic and 2.1 or 1.3,
        layer = LAYER.node, id = "multi-head:node:" .. id .. ":body",
    }
    group:text {
        text = label, point = {center[1], center[2] + 12}, role = "text",
        fill = semantic or "foreground", layer = LAYER.text,
        id = "multi-head:node:" .. id .. ":label",
    }
    group:text {
        text = detail, point = {center[1], center[2] - 17}, role = "code",
        fill = "muted", layer = LAYER.text, id = "multi-head:node:" .. id .. ":detail",
    }
    return body
end

box(context, "inputs", "Q, K, V", "d_model = 512", {-395, 31}, {136, 104})
box(context, "projections", "Q/K/V maps", "WᵢQ · WᵢK · WᵢV", {-242, 31}, {140, 104}, "accent")
context:arrow {
    from = {-327, 31}, to = {-312, 31}, tip = 9, color = "foreground", width = 2,
    layer = LAYER.route, id = "multi-head:route:inputs-projections",
}

local head_specs = {
    {id = "0", label = "head 0", center = {-54, 105}},
    {id = "middle", label = "heads 1…6", center = {-54, 31}},
    {id = "7", label = "head 7", center = {-54, -43}},
}
heads:text {
    text = "scaled dot-product attention", point = {-54, 158},
    role = "code", fill = "muted", layer = LAYER.text,
    id = "multi-head:heads-heading",
}
for _, spec in ipairs(head_specs) do
    box(
        heads, "head:" .. spec.id, spec.label, "d_k = d_v = 64",
        spec.center, {164, 64}, spec.id == "middle" and "focus" or "accent"
    )
end
heads:text {
    text = "×8 independent projected paths", point = {-54, -96},
    role = "code", fill = "focus", layer = LAYER.text, id = "multi-head:heads-note",
}

local fan_routes = {
    fan:route {
        points = {{-172, 55}, {-154, 55}, {-154, 105}, {-136, 105}},
        tip = 8, color = "accent", width = 1.8, layer = LAYER.route,
        id = "multi-head:route:projection-head:0",
    },
    fan:arrow {
        from = {-172, 31}, to = {-136, 31}, tip = 8, color = "accent", width = 1.8,
        layer = LAYER.route, id = "multi-head:route:projection-head:middle",
    },
    fan:route {
        points = {{-172, 7}, {-154, 7}, {-154, -43}, {-136, -43}},
        tip = 8, color = "accent", width = 1.8, layer = LAYER.route,
        id = "multi-head:route:projection-head:7",
    },
}

box(merge, "concat", "Concat", "8 × 64 → 512", {110, 31}, {124, 94}, "focus")
local merge_routes = {
    merge_routes_group:route {
        points = {{28, 105}, {38, 105}, {38, 31}, {48, 31}},
        tip = 8, color = "focus", width = 1.8, layer = LAYER.route,
        id = "multi-head:route:head-concat:0",
    },
    merge_routes_group:arrow {
        from = {28, 31}, to = {48, 31}, tip = 8, color = "focus", width = 1.8,
        layer = LAYER.route, id = "multi-head:route:head-concat:middle",
    },
    merge_routes_group:route {
        points = {{28, -43}, {38, -43}, {38, 31}, {48, 31}},
        tip = 8, color = "focus", width = 1.8, layer = LAYER.route,
        id = "multi-head:route:head-concat:7",
    },
}

box(tail, "projection-o", "Output linear", "Wᴼ [512,512]", {258, 31}, {138, 94}, "accent")
box(tail, "output", "Output", "[T_q,512]", {410, 31}, {92, 84}, "result")
tail:arrow {
    from = {172, 31}, to = {189, 31}, tip = 9, color = "foreground", width = 2,
    layer = LAYER.route, id = "multi-head:route:concat-projection-o",
}
tail:arrow {
    from = {327, 31}, to = {364, 31}, tip = 9, color = "result", width = 2.1,
    layer = LAYER.route, id = "multi-head:route:projection-o-output",
}

evidence:rectangle {
    center = {0, -151}, size = {860, 76}, corner = 7, fill = "background",
    stroke = "border", width = 1.1, layer = LAYER.guide, id = "multi-head:evidence:boundary",
}
evidence:text {
    text = "PER HEAD", point = {-408, -136}, align = {0, 0.5},
    role = "code", fill = "muted", layer = LAYER.text, id = "multi-head:evidence:head-label",
}
evidence:text {
    text = "headᵢ = Attention(QWᵢQ, KWᵢK, VWᵢV)", point = {-300, -136}, align = {0, 0.5},
    role = "code", fill = "foreground", layer = LAYER.text, id = "multi-head:evidence:head-equation",
}
evidence:text {
    text = "MERGE", point = {-408, -166}, align = {0, 0.5},
    role = "code", fill = "muted", layer = LAYER.text, id = "multi-head:evidence:merge-label",
}
evidence:text {
    text = "MultiHead(Q,K,V) = Concat(head₁,…,head₈) Wᴼ", point = {-300, -166}, align = {0, 0.5},
    role = "code", fill = "foreground", layer = LAYER.text, id = "multi-head:evidence:merge-equation",
}
local conclusion = root:text {
    text = "Heads are parallel dependencies in the graph; only Concat merges them.",
    point = {0, -229}, role = "code", fill = "result", layer = LAYER.text,
    id = "multi-head:conclusion",
}

scene:fade_in(header, {shift = {0, -6}, duration = 0.5, curve = "gentle"})
scene:fade_in(context, {shift = {0, -6}, duration = 0.65, curve = "ease_out"})
scene:create(fan_routes, 0.55, "ease_out", 0, "forward")
scene:fade_in(heads, {shift = {0, -5}, duration = 0.6, curve = "gentle"})
scene:create(merge_routes, 0.55, "ease_out", 0, "forward")
scene:fade_in(merge, {duration = 0.45, curve = "gentle"})
scene:fade_in(tail, {shift = {0, -5}, duration = 0.55, curve = "gentle"})
scene:fade_in(evidence, {shift = {0, -5}, duration = 0.45, curve = "gentle"})
scene:fade_in(conclusion, {duration = 0.35, curve = "gentle"})
scene:wait(2.4)
return scene
