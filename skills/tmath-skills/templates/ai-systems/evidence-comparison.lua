-- Exact-value comparison template. All included values are illustrative.
-- Keep records, units, axis maxima, captions, and derived deltas synchronized.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "pro_white",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local LAYER = {grid = 0, bar = 20, text = 30, focus = 40}
local root = scene:group {id = "evidence:root"}
local header = root:group {id = "evidence:header"}
local panels = root:group {id = "evidence:panels"}
local bars = root:group {id = "evidence:bars"}
local table_group = root:group {id = "evidence:table"}

header:text {
    text = "Aligned quantitative evidence", point = {0, 232}, role = "h2",
    fill = "foreground", layer = LAYER.text, id = "evidence:title",
}
header:text {
    text = "illustrative values · same task, batch, precision, hardware, and measurement window",
    point = {0, 199}, role = "code", fill = "muted", layer = LAYER.text,
    id = "evidence:subtitle",
}

local methods = {
    {id = "baseline", label = "Baseline", color = "muted"},
    {id = "proposed", label = "Proposed", color = "result"},
}
local metrics = {
    {id = "latency", label = "Latency ↓", unit = "ms", values = {82.0, 57.0}, max = 100.0, center = {-232, 65}},
    {id = "memory", label = "Peak memory ↓", unit = "GB", values = {12.4, 8.1}, max = 16.0, center = {232, 65}},
}
local proposed_bars = {}
for metric_index, metric in ipairs(metrics) do
    panels:rectangle {
        center = metric.center, size = {416, 224}, corner = 8, fill = "surface",
        stroke = "border", width = 1.3, layer = LAYER.grid,
        id = "evidence:panel:" .. metric.id .. ":boundary",
    }
    panels:text {
        text = metric.label, point = {metric.center[1], 147}, role = "text",
        fill = "foreground", layer = LAYER.text, id = "evidence:panel:" .. metric.id .. ":title",
    }
    local base_x, max_width = metric.center[1] - 124, 242
    panels:line {
        from = {base_x, -1}, to = {base_x, 112}, color = "border", width = 1.2,
        layer = LAYER.grid, id = "evidence:panel:" .. metric.id .. ":axis",
    }
    for method_index, method in ipairs(methods) do
        local value = metric.values[method_index]
        local y = 87 - (method_index - 1) * 64
        local width = max_width * value / metric.max
        bars:text {
            text = method.label, point = {base_x - 11, y}, align = {1, 0.5}, role = "code",
            fill = method.color, layer = LAYER.text,
            id = "evidence:" .. metric.id .. ":" .. method.id .. ":label",
        }
        local body = bars:rectangle {
            center = {base_x + width * 0.5, y}, size = {width, 34}, corner = 4,
            fill = method_index == 1 and "#e5e7eb" or "#dcfce7",
            stroke = method.color, width = method_index == 1 and 1.2 or 2,
            layer = LAYER.bar, id = "evidence:" .. metric.id .. ":" .. method.id .. ":bar",
        }
        if method_index == 2 then proposed_bars[metric.id] = body end
        bars:text {
            text = string.format("%.1f %s", value, metric.unit),
            point = {base_x + width + 10, y}, align = {0, 0.5}, role = "code",
            fill = "foreground", layer = LAYER.text,
            id = "evidence:" .. metric.id .. ":" .. method.id .. ":value",
        }
    end
    local reduction = 100 * (1 - metric.values[2] / metric.values[1])
    panels:text {
        text = string.format("%.1f%% lower", reduction), point = {metric.center[1], -20},
        role = "code", fill = "result", layer = LAYER.text,
        id = "evidence:panel:" .. metric.id .. ":delta",
    }
end

table_group:rectangle {
    center = {0, -107}, size = {880, 86}, corner = 7, fill = "background",
    stroke = "border", width = 1.2, layer = LAYER.grid, id = "evidence:table:boundary",
}
table_group:text {
    text = "PROVENANCE", point = {-418, -85}, align = {0, 0.5}, role = "code",
    fill = "muted", layer = LAYER.text, id = "evidence:table:title",
}
table_group:text {
    text = "Replace: source · table/figure ID · split · hardware · software · repeats · error bars",
    point = {8, -111}, role = "code", fill = "foreground", layer = LAYER.text,
    id = "evidence:table:fields",
}
table_group:text {
    text = "Do not animate a result beyond the statistic actually reported.", point = {0, -165},
    role = "code", fill = "focus", layer = LAYER.text, id = "evidence:caution",
}
local conclusion = root:text {
    text = "Readable final state = exact values + direction + comparison conditions + provenance.",
    point = {0, -221}, role = "code", fill = "result", layer = LAYER.text,
    id = "evidence:conclusion",
}

scene:fade_in(header, {shift = {0, -6}, duration = 0.5, curve = "gentle"})
scene:fade_in(panels, {shift = {0, -6}, duration = 0.6, curve = "ease_out"})
scene:fade_in(bars, {shift = {-7, 0}, duration = 0.75, curve = "ease_out"})
scene:indicate(proposed_bars.latency, {color = "result", scale = 1.02, duration = 0.4, curve = "ease_in_out"})
scene:indicate(proposed_bars.memory, {color = "result", scale = 1.02, duration = 0.4, curve = "ease_in_out"})
scene:fade_in(table_group, {shift = {0, -5}, duration = 0.5, curve = "gentle"})
scene:fade_in(conclusion, {duration = 0.35, curve = "gentle"})
scene:wait(2.4)
return scene
