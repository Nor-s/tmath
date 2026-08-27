-- Question: where does one implementation lead or regress, and do the exact values support the bars?
-- Replace benchmark_specs only. Values are illustrative; both chart and table derive from the same records.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local LAYER = {guide = 0, mark = 10, text = 20}
local root = scene:group {id = "benchmark-report:root"}
local chartFrame = root:group {id = "benchmark-report:chart-frame"}
local marks = root:group {id = "benchmark-report:marks"}
local table = root:group {id = "benchmark-report:table"}

local benchmark_specs = {
    {id = "rect", label = "Rect", a = 42, b = 18},
    {id = "stroke", label = "Stroke", a = 51, b = 20},
    {id = "path", label = "Path", a = 36, b = 15},
    {id = "image", label = "Image", a = 12, b = 28},
    {id = "gradient", label = "Gradient", a = 24, b = 21},
}

local PLOT_LEFT, PLOT_RIGHT = -430, 55
local PLOT_BOTTOM, PLOT_TOP = -145, 165
local MAX_VALUE = 60
local function value_y(value)
    return PLOT_BOTTOM + (PLOT_TOP - PLOT_BOTTOM) * value / MAX_VALUE
end

chartFrame:text {
    text = "Illustrative render benchmark", point = {PLOT_LEFT, 224}, align = {0, 0.5},
    role = "h3", fill = "foreground", layer = LAYER.text, id = "benchmark-report:title",
}
chartFrame:text {
    text = "higher is better · frames/s", point = {PLOT_LEFT, 194}, align = {0, 0.5},
    role = "code", fill = "muted", layer = LAYER.text, id = "benchmark-report:subtitle",
}
chartFrame:rectangle {
    center = {-111, 194}, size = {12, 12}, corner = 1, fill = "accent", stroke = "accent",
    layer = LAYER.mark, id = "benchmark-report:legend:a:mark",
}
chartFrame:text {
    text = "Engine A", point = {-98, 194}, align = {0, 0.5}, role = "code", fill = "foreground",
    layer = LAYER.text, id = "benchmark-report:legend:a:label",
}
chartFrame:rectangle {
    center = {-1, 194}, size = {12, 12}, corner = 1, fill = "secondary", stroke = "secondary",
    layer = LAYER.mark, id = "benchmark-report:legend:b:mark",
}
chartFrame:text {
    text = "Engine B", point = {12, 194}, align = {0, 0.5}, role = "code", fill = "foreground",
    layer = LAYER.text, id = "benchmark-report:legend:b:label",
}

for value = 0, MAX_VALUE, 10 do
    local y = value_y(value)
    chartFrame:line {
        from = {PLOT_LEFT, y}, to = {PLOT_RIGHT, y}, color = "border", width = value == 0 and 1.5 or 1,
        opacity = value == 0 and 0.8 or 0.28, layer = LAYER.guide,
        id = "benchmark-report:grid:" .. value,
    }
    chartFrame:text {
        text = tostring(value), point = {PLOT_LEFT - 12, y}, align = {1, 0.5}, role = "code",
        fill = "muted", layer = LAYER.text, id = "benchmark-report:tick:" .. value,
    }
end

local group_width = (PLOT_RIGHT - PLOT_LEFT) / #benchmark_specs
local bar_entries = {}
for index, item in ipairs(benchmark_specs) do
    local x = PLOT_LEFT + group_width * (index - 0.5)
    local bar_w = 28
    local a_top, b_top = value_y(item.a), value_y(item.b)
    local a = marks:rectangle {
        center = {x - 17, (PLOT_BOTTOM + a_top) * 0.5}, size = {bar_w, a_top - PLOT_BOTTOM}, corner = 2,
        fill = "accent", stroke = "accent", layer = LAYER.mark,
        id = "benchmark-report:bar:" .. item.id .. ":a",
    }
    local b = marks:rectangle {
        center = {x + 17, (PLOT_BOTTOM + b_top) * 0.5}, size = {bar_w, b_top - PLOT_BOTTOM}, corner = 2,
        fill = "secondary", stroke = "secondary", layer = LAYER.mark,
        id = "benchmark-report:bar:" .. item.id .. ":b",
    }
    chartFrame:text {
        text = item.label, point = {x, PLOT_BOTTOM - 22}, role = "code", fill = "foreground",
        layer = LAYER.text, id = "benchmark-report:category:" .. item.id,
    }
    bar_entries[#bar_entries + 1] = {a = a, b = b}
end

local TABLE_LEFT, TABLE_RIGHT = 105, 430
local TABLE_TOP, ROW_H = 168, 58
local columns = {TABLE_LEFT, 272, 330, 388, TABLE_RIGHT}
table:rectangle {
    center = {(TABLE_LEFT + TABLE_RIGHT) * 0.5, -6}, size = {TABLE_RIGHT - TABLE_LEFT, 348}, corner = 2,
    fill = "surface", stroke = "border", width = 1.5, layer = LAYER.guide, id = "benchmark-report:table:body",
}
table:rectangle {
    center = {(TABLE_LEFT + TABLE_RIGHT) * 0.5, TABLE_TOP - ROW_H * 0.5},
    size = {TABLE_RIGHT - TABLE_LEFT, ROW_H}, corner = 2, fill = "border", stroke = "border",
    opacity = 0.72, layer = LAYER.guide, id = "benchmark-report:table:header",
}
local headers = {{"Test", 119, 0}, {"A", 301, 0.5}, {"B", 359, 0.5}, {"A/B", 409, 0.5}}
for index, h in ipairs(headers) do
    table:text {
        text = h[1], point = {h[2], TABLE_TOP - ROW_H * 0.5}, align = {h[3], 0.5}, role = "code",
        fill = "foreground", layer = LAYER.text, id = "benchmark-report:table:header:" .. index,
    }
end
for index = 2, #columns - 1 do
    table:line {
        from = {columns[index], TABLE_TOP}, to = {columns[index], TABLE_TOP - ROW_H * 6},
        color = "border", width = 1, layer = LAYER.guide, id = "benchmark-report:table:column:" .. index,
    }
end
for index, item in ipairs(benchmark_specs) do
    local y = TABLE_TOP - ROW_H * (index + 0.5)
    table:line {
        from = {TABLE_LEFT, TABLE_TOP - ROW_H * index}, to = {TABLE_RIGHT, TABLE_TOP - ROW_H * index},
        color = "border", width = 1, layer = LAYER.guide, id = "benchmark-report:table:row:" .. index,
    }
    local ratio = item.a / item.b
    local values = {{item.label, 119, 0}, {tostring(item.a), 301, 0.5}, {tostring(item.b), 359, 0.5}, {string.format("%.1fx", ratio), 409, 0.5}}
    for column, value in ipairs(values) do
        table:text {
            text = value[1], point = {value[2], y}, align = {value[3], 0.5}, role = "code",
            fill = column == 4 and (ratio >= 1 and "result" or "danger") or "foreground",
            layer = LAYER.text, id = "benchmark-report:table:" .. item.id .. ":" .. column,
        }
    end
end

scene:fade_in(chartFrame, {duration = 0.5, curve = "gentle"})
for _, pair in ipairs(bar_entries) do
    scene:grow_from_edge(pair.a, "bottom", 0.32, "ease_out")
    scene:grow_from_edge(pair.b, "bottom", 0.32, "ease_out")
end
scene:fade_in(table, {shift = {-8, 0}, duration = 0.65, curve = "gentle"})
scene:wait(2.6)
return scene
