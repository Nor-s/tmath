-- Question: how do all input-channel filter slices contribute to one CNN output value?
-- Edit channel_specs, bias, tensor layouts, stride/padding/dilation, and the selected output coordinate together.
-- This template shows one interior 3 x 3, three-channel contraction; boundary behavior is intentionally omitted.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "pro_white",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local LAYER = {route = 10, cell = 20, text = 30, focus = 40}
local root = scene:group {id = "cnn-convolution:root"}
local header = root:group {id = "cnn-convolution:header"}
local headings = root:group {id = "cnn-convolution:headings"}
local channels = root:group {id = "cnn-convolution:channels"}
local routes = root:group {id = "cnn-convolution:routes"}
local result_group = root:group {id = "cnn-convolution:result-group"}

header:text {
    text = "One multi-channel CNN convolution result", point = {0, 232}, role = "h2",
    fill = "foreground", layer = LAYER.text, id = "cnn-convolution:title",
}
header:text {
    text = "interior 3 × 3 example · learned filter slices are not CUDA launch kernels",
    point = {0, 199}, role = "code", fill = "muted", layer = LAYER.text,
    id = "cnn-convolution:subtitle",
}

local function cell_fill(value, weights)
    if weights then
        if value > 0 then return "#dcfce7" end
        if value < 0 then return "#fee2e2" end
        return "#f8fafc"
    end
    if value >= 2 then return "#bfdbfe" end
    if value == 1 then return "#dbeafe" end
    return "#f8fafc"
end

local function grid(parent, id, center, values, weights)
    local group = parent:group {id = id}
    local pitch = 25
    for row = 1, 3 do
        for column = 1, 3 do
            local index = (row - 1) * 3 + column
            local point = {
                center[1] + (column - 2) * pitch,
                center[2] + (2 - row) * pitch,
            }
            group:rectangle {
                center = point, size = {23, 23}, corner = 2,
                fill = cell_fill(values[index], weights), stroke = "border", width = 1,
                layer = LAYER.cell, id = id .. ":cell:" .. index,
            }
            group:text {
                text = tostring(values[index]), point = point, role = "code", fill = "foreground",
                layer = LAYER.text, id = id .. ":value:" .. index,
            }
        end
    end
    return group
end

local function dot(lhs, rhs)
    local sum = 0
    for index = 1, #lhs do sum = sum + lhs[index] * rhs[index] end
    return sum
end

-- Copy/paste edit surface. The shown W slices all belong to output channel c_o = 0.
local channel_specs = {
    {
        id = "c0", y = 106,
        input = {1, 1, 1, 1, 1, 1, 1, 1, 1},
        weight = {1, 1, 1, 1, 1, 1, 1, 1, 1},
    },
    {
        id = "c1", y = 0,
        input = {1, 1, 1, 1, 1, 1, 1, 1, 1},
        weight = {-1, -1, -1, -1, -1, -1, -1, -1, -1},
    },
    {
        id = "c2", y = -106,
        input = {0, 0, 0, 0, 2, 0, 0, 0, 0},
        weight = {0, 0, 0, 0, 1, 0, 0, 0, 0},
    },
}
local bias = 0.5

headings:text {
    text = "X patch [c,:,:]", point = {-410, 163}, role = "code", fill = "muted",
    layer = LAYER.text, id = "cnn-convolution:input-heading",
}
headings:text {
    text = "W[0,c,:,:]", point = {-285, 163}, role = "code", fill = "muted",
    layer = LAYER.text, id = "cnn-convolution:weight-heading",
}
headings:text {
    text = "channel dot", point = {-130, 163}, role = "code", fill = "muted",
    layer = LAYER.text, id = "cnn-convolution:dot-heading",
}

local contributions = {}
local channel_groups = {}
for index, spec in ipairs(channel_specs) do
    local group = channels:group {id = "cnn-convolution:channel:" .. spec.id}
    channel_groups[index] = group
    grid(group, "cnn-convolution:input:" .. spec.id, {-410, spec.y}, spec.input, false)
    group:text {
        text = "×", point = {-347, spec.y}, role = "text", fill = "muted",
        layer = LAYER.text, id = "cnn-convolution:multiply:" .. spec.id,
    }
    grid(group, "cnn-convolution:weight:" .. spec.id, {-285, spec.y}, spec.weight, true)
    local value = dot(spec.input, spec.weight)
    contributions[index] = value
    group:rectangle {
        center = {-130, spec.y}, size = {100, 52}, corner = 6,
        fill = "surface", stroke = "border", width = 1.25, layer = LAYER.cell,
        id = "cnn-convolution:dot:" .. spec.id .. ":body",
    }
    group:text {
        text = string.format("dot = %.1f", value), point = {-130, spec.y}, role = "code",
        fill = "foreground", layer = LAYER.text, id = "cnn-convolution:dot:" .. spec.id,
    }
end

local total = bias
for _, value in ipairs(contributions) do total = total + value end

local sum_body = result_group:rectangle {
    center = {70, 0}, size = {122, 78}, corner = 8, fill = "surface", stroke = "accent",
    width = 2.5, layer = LAYER.cell, id = "cnn-convolution:sum:body",
}
result_group:text {
    text = "Σ over c", point = {70, 14}, role = "text", fill = "accent",
    layer = LAYER.text, id = "cnn-convolution:sum:label",
}
result_group:text {
    text = "+ bias 0.5", point = {70, -17}, role = "code", fill = "muted",
    layer = LAYER.text, id = "cnn-convolution:sum:detail",
}
local output_body = result_group:rectangle {
    center = {302, 0}, size = {146, 82}, corner = 8, fill = "surface", stroke = "result",
    width = 2.5, layer = LAYER.cell, id = "cnn-convolution:output:body",
}
result_group:text {
    text = "Y[0,0,h,w]", point = {302, 16}, role = "text", fill = "result",
    layer = LAYER.text, id = "cnn-convolution:output:label",
}
result_group:text {
    text = string.format("= %.1f", total), point = {302, -18}, role = "code", fill = "result",
    layer = LAYER.text, id = "cnn-convolution:output:value",
}

local reduction_routes = {}
local input_ports = {22, 0, -22}
for index, spec in ipairs(channel_specs) do
    local points
    if index == 2 then
        points = {{-80, spec.y}, {9, 0}}
    else
        local corridor_x = -37 + (index == 1 and 0 or 10)
        points = {{-80, spec.y}, {corridor_x, spec.y}, {corridor_x, input_ports[index]}, {9, input_ports[index]}}
    end
    reduction_routes[#reduction_routes + 1] = routes:route {
        points = points, tip = 9, color = "foreground", width = 1.8,
        layer = LAYER.route, id = "cnn-convolution:route:" .. spec.id .. "-sum",
    }
end
local output_route = routes:arrow {
    from = {131, 0}, to = {229, 0}, tip = 11, color = "result", width = 2.3,
    layer = LAYER.route, id = "cnn-convolution:route:sum-output",
}

local formula = root:text {
    text = "Y[b,cₒ,h,w] = bias[cₒ] + Σ_c Σ_i Σ_j X[b,c,h+i,w+j] · W[cₒ,c,i,j]",
    point = {0, -205}, role = "code", fill = "foreground", layer = LAYER.text,
    id = "cnn-convolution:formula",
}
local conclusion = root:text {
    text = "The output value contracts every input-channel filter slice before writing one output channel.",
    point = {0, -238}, role = "code", fill = "result", layer = LAYER.text,
    id = "cnn-convolution:conclusion",
}

scene:fade_in(header, {shift = {0, -6}, duration = 0.55, curve = "gentle"})
scene:fade_in(headings, {duration = 0.35, curve = "gentle"})
for _, group in ipairs(channel_groups) do
    scene:fade_in(group, {shift = {0, -5}, duration = 0.38, curve = "ease_out"})
end
scene:fade_in(result_group, {shift = {0, -5}, duration = 0.5, curve = "gentle"})
scene:create(reduction_routes, 0.75, "ease_out", 0.08, "forward")
scene:create(output_route, 0.35, "ease_out")
scene:indicate(sum_body, {color = "focus", scale = 1.025, duration = 0.4, curve = "ease_in_out"})
scene:indicate(output_body, {color = "result", scale = 1.025, duration = 0.4, curve = "ease_in_out"})
scene:fade_in(formula, {shift = {0, -5}, duration = 0.45, curve = "gentle"})
scene:fade_in(conclusion, {shift = {0, -5}, duration = 0.38, curve = "gentle"})
scene:wait(2.3)
return scene
