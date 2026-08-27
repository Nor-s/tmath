-- Question: which service consumed the latency budget, and which measured span proves it?
-- Replace service_specs and span_specs; all trace bars derive from the same 0-900 ms axis.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local LAYER = {guide = 0, route = 10, mark = 20, text = 30}
local root = scene:group {id = "reliability-stack:root"}
local pathFrame = root:group {id = "reliability-stack:path-frame"}
local services = root:group {id = "reliability-stack:services"}
local traceFrame = root:group {id = "reliability-stack:trace-frame"}
local bars = root:group {id = "reliability-stack:spans"}

pathFrame:text {
    text = "CRITICAL REQUEST", point = {-430, 228}, align = {0, 0.5},
    role = "code", fill = "muted", layer = LAYER.text,
    id = "reliability-stack:path-title",
}
pathFrame:text {
    text = "GET /orders/42", point = {430, 228}, align = {1, 0.5},
    role = "code", fill = "foreground", layer = LAYER.text,
    id = "reliability-stack:path-request",
}

local service_specs = {
    {id = "client", label = "Client", detail = "request origin", center = {-330, 155}},
    {id = "edge", label = "Edge", detail = "+42 ms", center = {-110, 155}},
    {id = "api", label = "API", detail = "+318 ms", center = {110, 155}, focal = true},
    {id = "store", label = "Store", detail = "+540 ms · timeout", center = {330, 155}, error = true},
}

local SERVICE_W = 180
local SERVICE_H = 72
for _, service in ipairs(service_specs) do
    local prefix = "reliability-stack:service:" .. service.id
    services:rectangle {
        center = service.center, size = {SERVICE_W, SERVICE_H}, corner = 4, fill = "surface",
        stroke = service.error and "danger" or (service.focal and "accent" or "border"),
        width = (service.error or service.focal) and 2 or 1.5,
        layer = LAYER.mark, id = prefix .. ":body",
    }
    services:line {
        from = {service.center[1] - SERVICE_W * 0.5, service.center[2] + 5},
        to = {service.center[1] + SERVICE_W * 0.5, service.center[2] + 5},
        color = "border", width = 1, opacity = 0.55,
        layer = LAYER.mark, id = prefix .. ":divider",
    }
    services:text {
        text = service.label, point = {service.center[1], service.center[2] + 20},
        role = "text", fill = service.error and "danger" or (service.focal and "accent" or "foreground"),
        layer = LAYER.text, id = prefix .. ":label",
    }
    services:text {
        text = service.detail, point = {service.center[1], service.center[2] - 14},
        role = "code", fill = service.error and "danger" or "muted",
        layer = LAYER.text, id = prefix .. ":detail",
    }
end

local route_specs = {
    {"client-edge", {-240, 155}, {-200, 155}, "foreground"},
    {"edge-api", {-20, 155}, {20, 155}, "foreground"},
    {"api-store", {200, 155}, {240, 155}, "danger"},
}
local request_routes = {}
for _, route in ipairs(route_specs) do
    request_routes[#request_routes + 1] = root:arrow {
        from = route[2], to = route[3], tip = 10, color = route[4], width = 2,
        layer = LAYER.route, id = "reliability-stack:request:" .. route[1],
    }
end
local timeoutLabel = root:text {
    text = "deadline exceeded", point = {220, 204}, role = "code", fill = "danger",
    layer = LAYER.text, id = "reliability-stack:request:timeout-label",
}

local AXIS_LEFT = -250
local AXIS_RIGHT = 430
local AXIS_TOP = 40
local AXIS_BOTTOM = -190
local LABEL_DIVIDER = -280
local TOTAL_MS = 900
local function time_x(value)
    return AXIS_LEFT + (AXIS_RIGHT - AXIS_LEFT) * value / TOTAL_MS
end

traceFrame:text {
    text = "TRACE EVIDENCE", point = {-430, 84}, align = {0, 0.5},
    role = "code", fill = "muted", layer = LAYER.text,
    id = "reliability-stack:trace-title",
}
traceFrame:text {
    text = "900 ms total", point = {430, 84}, align = {1, 0.5},
    role = "code", fill = "foreground", layer = LAYER.text,
    id = "reliability-stack:trace-total",
}
traceFrame:line {
    from = {AXIS_LEFT, AXIS_TOP}, to = {AXIS_RIGHT, AXIS_TOP},
    color = "border", width = 1.5, layer = LAYER.guide,
    id = "reliability-stack:trace-axis",
}
traceFrame:line {
    from = {LABEL_DIVIDER, AXIS_TOP + 18}, to = {LABEL_DIVIDER, AXIS_BOTTOM},
    color = "border", width = 1.5, layer = LAYER.guide,
    id = "reliability-stack:trace-label-divider",
}
for value = 0, TOTAL_MS, 150 do
    local x = time_x(value)
    traceFrame:line {
        from = {x, AXIS_TOP}, to = {x, AXIS_BOTTOM}, color = "border", width = 1,
        opacity = (value == 0 or value == TOTAL_MS) and 0.75 or 0.28,
        layer = LAYER.guide, id = "reliability-stack:trace-grid:" .. value,
    }
    traceFrame:text {
        text = tostring(value), point = {x, AXIS_TOP + 17}, role = "code", fill = "muted",
        layer = LAYER.text, id = "reliability-stack:trace-tick:" .. value,
    }
end

local span_specs = {
    {id = "edge", label = "Edge", start = 0, finish = 42, y = -15, duration = "42 ms"},
    {id = "api", label = "API", start = 42, finish = 360, y = -85, duration = "318 ms", focal = true},
    {id = "store", label = "Store", start = 360, finish = 900, y = -155, duration = "540 ms · timeout", error = true},
}

local span_entries = {}
for index, span in ipairs(span_specs) do
    local left = time_x(span.start)
    local right = time_x(span.finish)
    local prefix = "reliability-stack:span:" .. span.id
    traceFrame:line {
        from = {-430, span.y - 35}, to = {AXIS_RIGHT, span.y - 35},
        color = "border", width = 1, opacity = index == #span_specs and 0.7 or 0.28,
        layer = LAYER.guide, id = prefix .. ":row-divider",
    }
    local color = span.error and "danger" or (span.focal and "accent" or "foreground")
    traceFrame:text {
        text = span.label, point = {-430, span.y}, align = {0, 0.5}, role = "text",
        fill = color, layer = LAYER.text, id = prefix .. ":label",
    }
    local handle = bars:rectangle {
        center = {(left + right) * 0.5, span.y}, size = {right - left, 28}, corner = 3,
        fill = "surface", stroke = span.error and color or (span.focal and "accent" or "muted"),
        width = span.error and 2.5 or (span.focal and 2 or 1.5),
        layer = LAYER.mark, id = prefix .. ":bar",
    }
    local duration_label = bars:text {
        text = span.duration,
        point = span.error and {right - 10, span.y} or {right + 10, span.y},
        align = span.error and {1, 0.5} or {0, 0.5},
        role = "code", fill = span.error and "danger" or "muted",
        layer = LAYER.text, id = prefix .. ":duration",
    }
    span_entries[#span_entries + 1] = {bar = handle, label = duration_label}
end

scene:fade_in(pathFrame, {duration = 0.35, curve = "gentle"})
scene:fade_in(services, {shift = {0, -6}, duration = 0.6, curve = "gentle"})
for _, route in ipairs(request_routes) do
    scene:create(route, 0.42, "ease_out")
end
scene:fade_in(timeoutLabel, {shift = {0, -4}, duration = 0.22, curve = "gentle"})
scene:fade_in(traceFrame, {duration = 0.5, curve = "gentle"})
for _, span in ipairs(span_entries) do
    scene:grow_from_edge(span.bar, "left", 0.45, "ease_out")
    scene:fade_in(span.label, {shift = {0, -4}, duration = 0.18, curve = "gentle"})
end
scene:wait(2.4)
return scene
