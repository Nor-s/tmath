-- Source-grounded preset for Vaswani et al. (2017), Figure 1 and Section 3.
-- Question: how do the original post-norm encoder, decoder, cross-attention, and output head connect?
-- Do not relabel this preset as a modern decoder-only or pre-norm Transformer.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "pro_white",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local LAYER = {guide = 0, route = 10, node = 20, text = 30, focus = 40}
local root = scene:group {id = "transformer-2017:root"}
local header = root:group {id = "transformer-2017:header"}
local guides = root:group {id = "transformer-2017:guides"}
local nodes = root:group {id = "transformer-2017:nodes"}
local routes = root:group {id = "transformer-2017:routes"}
local evidence = root:group {id = "transformer-2017:evidence"}

header:text {
    text = "The 2017 Transformer encoder–decoder", point = {0, 232}, role = "h2",
    fill = "foreground", layer = LAYER.text, id = "transformer-2017:title",
}
header:text {
    text = "Vaswani et al. · Figure 1 · post-norm · source-grounded base architecture",
    point = {0, 199}, role = "code", fill = "muted", layer = LAYER.text,
    id = "transformer-2017:subtitle",
}

guides:text {
    text = "ENCODER PATH", point = {-458, 153}, align = {0, 0.5}, role = "code",
    fill = "muted", layer = LAYER.text, id = "transformer-2017:encoder-lane-label",
}
guides:text {
    text = "DECODER PATH", point = {-458, -157}, align = {0, 0.5}, role = "code",
    fill = "muted", layer = LAYER.text, id = "transformer-2017:decoder-lane-label",
}
guides:line {
    from = {-458, 15}, to = {458, 15}, color = "border", width = 1,
    dash = {5, 6}, layer = LAYER.guide, id = "transformer-2017:lane-divider",
}

local function node(spec)
    local group = nodes:group {id = "transformer-2017:node:" .. spec.id}
    local body = group:rectangle {
        center = spec.center, size = spec.size, corner = 7, fill = "surface",
        stroke = spec.semantic or "border", width = spec.semantic and 2.2 or 1.5,
        layer = LAYER.node, id = "transformer-2017:node:" .. spec.id .. ":body",
    }
    group:text {
        text = spec.label, point = {spec.center[1], spec.center[2] + spec.title_dy},
        role = spec.label_role or "text", fill = spec.semantic or "foreground", layer = LAYER.text,
        id = "transformer-2017:node:" .. spec.id .. ":label",
    }
    for index, line in ipairs(spec.lines) do
        group:text {
            text = line, point = {spec.center[1], spec.center[2] + spec.line_y[index]},
            role = "code", fill = "muted", layer = LAYER.text,
            id = "transformer-2017:node:" .. spec.id .. ":detail:" .. index,
        }
    end
    return {body = body, spec = spec}
end

-- Exact paper facts are folded into readable macro nodes; repetition remains explicit.
local specs = {
    {id = "inputs", label = "inputs", center = {-405, 86}, size = {82, 62}, title_dy = 0, lines = {}, line_y = {}},
    {id = "input-embed", label = "Embedding + PE", center = {-272, 86}, size = {150, 72}, title_dy = 12, label_role = "code",
        lines = {"sinusoidal"}, line_y = {-18}},
    {id = "encoder", label = "Encoder layer ×6", center = {-64, 86}, size = {234, 112}, title_dy = 34,
        lines = {"self-attn → Add & Norm", "FFN(ReLU) → Add & Norm"}, line_y = {1, -28}, semantic = "accent"},
    {id = "memory", label = "Encoder memory", center = {149, 86}, size = {160, 72}, title_dy = 12, label_role = "code",
        lines = {"K,V source"}, line_y = {-18}, semantic = "focus"},
    {id = "shifted", label = "outputs", center = {-402, -82}, size = {116, 68}, title_dy = 13,
        lines = {"shifted right"}, line_y = {-18}},
    {id = "output-embed", label = "Embedding + PE", center = {-251, -82}, size = {150, 72}, title_dy = 12, label_role = "code",
        lines = {"causal input"}, line_y = {-18}},
    {id = "decoder", label = "Decoder layer ×6", center = {-16, -82}, size = {286, 132}, title_dy = 45,
        lines = {"masked self-attn → Add & Norm", "cross-attn → Add & Norm", "FFN(ReLU) → Add & Norm"},
        line_y = {13, -17, -47}, semantic = "accent"},
    {id = "head", label = "Linear + Softmax", center = {226, -82}, size = {164, 76}, title_dy = 13, label_role = "code",
        lines = {"tied output map"}, line_y = {-20}},
    {id = "probabilities", label = "Output", center = {385, -82}, size = {120, 68}, title_dy = 13,
        lines = {"probabilities"}, line_y = {-18}, semantic = "result"},
}

local handles = {}
for _, spec in ipairs(specs) do handles[spec.id] = node(spec) end

local encoder_routes = {
    routes:arrow {from = {-364, 86}, to = {-347, 86}, tip = 9, color = "foreground", width = 2, layer = LAYER.route, id = "transformer-2017:route:inputs-embed"},
    routes:arrow {from = {-197, 86}, to = {-181, 86}, tip = 9, color = "foreground", width = 2, layer = LAYER.route, id = "transformer-2017:route:embed-encoder"},
    routes:arrow {from = {53, 86}, to = {69, 86}, tip = 9, color = "foreground", width = 2, layer = LAYER.route, id = "transformer-2017:route:encoder-memory"},
}
local decoder_routes = {
    routes:arrow {from = {-344, -82}, to = {-326, -82}, tip = 9, color = "foreground", width = 2, layer = LAYER.route, id = "transformer-2017:route:shifted-embed"},
    routes:arrow {from = {-176, -82}, to = {-159, -82}, tip = 9, color = "foreground", width = 2, layer = LAYER.route, id = "transformer-2017:route:embed-decoder"},
    routes:arrow {from = {127, -82}, to = {144, -82}, tip = 9, color = "foreground", width = 2, layer = LAYER.route, id = "transformer-2017:route:decoder-head"},
    routes:arrow {from = {308, -82}, to = {325, -82}, tip = 9, color = "result", width = 2, layer = LAYER.route, id = "transformer-2017:route:head-output"},
}
local cross_route = routes:route {
    points = {{149, 50}, {149, 17}, {17, 17}, {17, -16}}, tip = 10,
    color = "focus", width = 2.3, layer = LAYER.route,
    id = "transformer-2017:route:encoder-decoder-attention",
}
local cross_label = root:text {
    text = "encoder K,V → decoder cross-attention", point = {281, 0},
    role = "code", fill = "focus", layer = LAYER.text,
    id = "transformer-2017:cross-attention-label",
}

evidence:text {
    text = "d_model = 512  ·  h = 8  ·  d_k = d_v = 64  ·  d_ff = 2048",
    point = {0, -184}, role = "code", fill = "foreground", layer = LAYER.text,
    id = "transformer-2017:base-facts",
}
local conclusion = evidence:text {
    text = "Parallel attention lives inside each step; shifted outputs and masking preserve autoregressive dependence.",
    point = {0, -226}, role = "code", fill = "result", layer = LAYER.text,
    id = "transformer-2017:conclusion",
}

scene:fade_in(header, {shift = {0, -6}, duration = 0.55, curve = "gentle"})
scene:fade_in(guides, {duration = 0.35, curve = "gentle"})
scene:fade_in(nodes, {shift = {0, -6}, duration = 0.75, curve = "ease_out"})
scene:create(encoder_routes, 0.55, "ease_out", 0.08, "forward")
scene:create(decoder_routes, 0.7, "ease_out", 0.07, "forward")
scene:create(cross_route, 0.55, "ease_out")
scene:fade_in(cross_label, {duration = 0.3, curve = "gentle"})
scene:fade_in(evidence, {shift = {0, -5}, duration = 0.5, curve = "gentle"})
scene:indicate(handles.decoder.body, {color = "focus", scale = 1.018, duration = 0.42, curve = "ease_in_out"})
scene:wait(2.5)
return scene
