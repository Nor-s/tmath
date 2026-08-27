-- Inspired by the learned-attention visual grammar in Vaswani et al. (2017), appendix.
-- Question: which key tokens receive weight from one selected query in one head/example?
-- Tokens and weights are illustrative. Replace both, and record layer/head/example provenance together.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "pro_white",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local LAYER = {relation = 10, mark = 20, text = 30, focus = 40}
local root = scene:group {id = "attention-evidence:root"}
local header = root:group {id = "attention-evidence:header"}
local rows = root:group {id = "attention-evidence:token-rows"}
local relations = root:group {id = "attention-evidence:relations"}
local focus_marks = root:group {id = "attention-evidence:focus-marks"}
local legend = root:group {id = "attention-evidence:legend"}

header:text {
    text = "Learned attention as relation evidence", point = {0, 232}, role = "h2",
    fill = "foreground", layer = LAYER.text, id = "attention-evidence:title",
}
header:text {
    text = "illustrative self-attention · one query · layer/head/example must be sourced",
    point = {0, 199}, role = "code", fill = "muted", layer = LAYER.text,
    id = "attention-evidence:subtitle",
}

local tokens = {"The", "model", "links", "each", "query", "to", "relevant", "context"}
local weights = {0.04, 0.05, 0.10, 0.06, 0.08, 0.07, 0.24, 0.36}
local selected_query = 5
local start_x, pitch = -350, 100
local top_anchor_y, bottom_anchor_y = 80, -72

rows:text {
    text = "KEYS", point = {-455, 110}, align = {0, 0.5}, role = "code",
    fill = "muted", layer = LAYER.text, id = "attention-evidence:key-row-label",
}
rows:text {
    text = "QUERIES", point = {-455, -104}, align = {0, 0.5}, role = "code",
    fill = "muted", layer = LAYER.text, id = "attention-evidence:query-row-label",
}

local top_points, bottom_points = {}, {}
for index, token in ipairs(tokens) do
    local x = start_x + (index - 1) * pitch
    top_points[index] = rows:point {
        point = {x, top_anchor_y}, radius = 5, fill = "accent", stroke = "accent",
        layer = LAYER.mark, id = "attention-evidence:key-anchor:" .. index,
    }
    bottom_points[index] = rows:point {
        point = {x, bottom_anchor_y}, radius = index == selected_query and 7 or 4,
        fill = index == selected_query and "focus" or "border",
        stroke = index == selected_query and "focus" or "border",
        layer = LAYER.mark, id = "attention-evidence:query-anchor:" .. index,
    }
    rows:text {
        text = token, point = {x, top_anchor_y + 30}, role = "text",
        fill = "foreground", layer = LAYER.text,
        id = "attention-evidence:key-token:" .. index,
    }
    rows:text {
        text = token, point = {x, bottom_anchor_y - 32}, role = "text",
        fill = index == selected_query and "focus" or "foreground",
        layer = LAYER.text, id = "attention-evidence:query-token:" .. index,
    }
end

local edge_colors = {
    "#2563eb33", "#2563eb38", "#2563eb55", "#2563eb40",
    "#2563eb48", "#2563eb44", "#2563eb99", "#2563ebdd",
}
local relation_lines = {}
local query_x = start_x + (selected_query - 1) * pitch
for index, weight in ipairs(weights) do
    relation_lines[index] = relations:line {
        from = {query_x, bottom_anchor_y}, to = {start_x + (index - 1) * pitch, top_anchor_y},
        color = edge_colors[index], width = 1.2 + weight * 9,
        layer = LAYER.relation, id = "attention-evidence:weight:" .. index,
    }
end

rows:rectangle {
    center = {query_x, bottom_anchor_y - 32}, size = {88, 36}, corner = 6,
    fill = "#00000000", stroke = "focus", width = 2,
    layer = LAYER.focus, id = "attention-evidence:selected-query-outline",
}
local strongest = focus_marks:rectangle {
    center = {start_x + 7 * pitch, top_anchor_y + 30}, size = {92, 36}, corner = 6,
    fill = "#00000000", stroke = "result", width = 2,
    layer = LAYER.focus, id = "attention-evidence:strongest-key-outline",
}

legend:text {
    text = "weight encoding", point = {-330, -172}, role = "code",
    fill = "muted", layer = LAYER.text, id = "attention-evidence:legend-title",
}
local legend_specs = {
    {x = -190, width = 1.5, color = "#2563eb44", label = "weak"},
    {x = -45, width = 4.0, color = "#2563eb88", label = "medium"},
    {x = 120, width = 7.5, color = "#2563ebdd", label = "strong"},
}
for index, spec in ipairs(legend_specs) do
    legend:line {
        from = {spec.x - 42, -172}, to = {spec.x + 18, -172}, color = spec.color,
        width = spec.width, layer = LAYER.relation,
        id = "attention-evidence:legend-line:" .. index,
    }
    legend:text {
        text = spec.label, point = {spec.x + 58, -172}, role = "code",
        fill = "foreground", layer = LAYER.text,
        id = "attention-evidence:legend-label:" .. index,
    }
end
legend:text {
    text = "line width + opacity = post-softmax attention weight",
    point = {0, -207}, role = "code", fill = "muted", layer = LAYER.text,
    id = "attention-evidence:legend-note",
}
local conclusion = root:text {
    text = "This query favors “context” here; it does not define a permanent head role.",
    point = {0, -236}, role = "code", fill = "result", layer = LAYER.text,
    id = "attention-evidence:conclusion",
}

scene:fade_in(header, {shift = {0, -6}, duration = 0.55, curve = "gentle"})
scene:fade_in(rows, {shift = {0, -5}, duration = 0.65, curve = "ease_out"})
scene:fade_in(relations, {duration = 0.75, curve = "gentle"})
scene:fade_in(focus_marks, {duration = 0.25, curve = "gentle"})
scene:indicate(strongest, {color = "result", scale = 1.025, duration = 0.42, curve = "ease_in_out"})
scene:fade_in(legend, {shift = {0, -4}, duration = 0.45, curve = "gentle"})
scene:fade_in(conclusion, {duration = 0.35, curve = "gentle"})
scene:wait(2.6)
return scene
