-- Question: which boundary owns each component, and how does the request reach its result?
-- Replace the semantic inventory first; then remeasure node bodies and route endpoints.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    camera = { mode = "fixed", view = "2d", target = { 0, 0 }, height = 540 },
}
local layer = { zone = 0, route = 10, node = 20, text = 30 }

local zones = scene:group { id = "zones" }
local zone_specs = {
    { id = "zone-external", label = "External", center = { -330, 0 }, size = { 190, 150 } },
    { id = "zone-runtime", label = "Runtime", center = { 0, 0 }, size = { 420, 150 } },
    { id = "zone-state", label = "State", center = { 350, 0 }, size = { 180, 150 } },
}
for _, spec in ipairs(zone_specs) do
    local zone = zones:group { id = spec.id }
    zone:rectangle {
        center = spec.center, size = spec.size, corner = 12, fill = "surface", stroke = "border",
        width = 1.25, layer = layer.zone, id = spec.id .. "-body",
    }
    zone:text {
        text = spec.label,
        point = { spec.center[1] - spec.size[1] * 0.5 + 16, spec.center[2] + spec.size[2] * 0.5 - 22 },
        align = { 0, 0.5 }, role = "h3", fill = "muted", layer = layer.text,
        id = spec.id .. "-label",
    }
end

local nodes = scene:group { id = "nodes" }
local function node(id, title, detail, x, y, emphasis)
    local group = nodes:group { id = id }
    group:rectangle {
        center = { x, y }, size = { 132, 62 }, corner = 10, fill = "surface",
        stroke = emphasis or "border", width = emphasis and 2.25 or 1.25,
        layer = layer.node, id = id .. "-body",
    }
    group:text {
        text = title, point = { x, y + 10 }, role = "text", fill = emphasis or "foreground",
        layer = layer.text, id = id .. "-title",
    }
    group:text {
        text = detail, point = { x, y - 17 }, role = "code", fill = "muted",
        layer = layer.text, id = id .. "-detail",
    }
end
node("client", "Client", "request", -330, -14)
node("gateway", "Gateway", "policy", -110, -14)
node("service", "Service", "operation", 110, -14, "focus")
node("store", "Store", "result", 350, -14, "result")

local routes = scene:group { id = "routes" }
local route_specs = {
    { id = "client-gateway", from = { -264, -14 }, to = { -176, -14 } },
    { id = "gateway-service", from = { -44, -14 }, to = { 44, -14 } },
    { id = "service-store", from = { 176, -14 }, to = { 284, -14 } },
}
local handles = {}
for _, spec in ipairs(route_specs) do
    handles[#handles + 1] = routes:arrow {
        from = spec.from, to = spec.to, tip = 12, color = "accent", width = 3,
        layer = layer.route, id = "route-" .. spec.id,
    }
end

scene:fade_in(zones, { duration = 0.45, curve = "gentle" })
scene:fade_in(nodes, { duration = 0.65, curve = "ease_out" })
scene:create(handles, 1.0, "ease_out", 0.1, "forward")
scene:wait(2.2)
return scene
