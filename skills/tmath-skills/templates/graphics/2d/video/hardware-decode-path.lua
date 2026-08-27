-- Requires a Lua host built with -Ddiagram=enabled.
-- local question: Where do decoded frames live in a hardware-accelerated playback path?
-- visible input: a CPU packet queue submitted to a device video decoder
-- subject object or field: CPU/device ownership zones, GPU-native surfaces, and an optional readback branch
-- one dominant action: keep decoded NV12/P010 surfaces device-local through composition
-- observable output: a zero-copy presentation spine and a clearly separate CPU-transfer fallback
-- coordinate frame and units: left-to-right resource ownership and ordered handoffs
-- section bounds supplied by the parent: standalone 960 x 540 wrapper
-- final readable pose: complete device path, fences/ownership detail, and optional copy branch

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = {
        preset = "3_blue_1_eyes",
        text = {text = {size = 15}, code = {size = 13}},
    },
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local LAYER = {zone = -30, zone_label = 10, text = 40}
local function text(id, value, point, role, fill, align)
    return scene:text {
        id = id, text = value, point = point, role = role or "code",
        fill = fill or "foreground", align = align or {0.5, 0.5}, layer = LAYER.text,
    }
end

local claim = text(
    "hardware-decode-claim",
    "Hardware decode keeps presentation surfaces device-local",
    {0, 2.62}, "h3"
)
local scope = text(
    "hardware-decode-scope",
    "generic API model · exact queues, handles, and pixel formats are platform-specific",
    {0, 2.18}, "code", "muted"
)

local boundaries = scene:group {id = "hardware-decode-boundaries"}
local zones = {
    {id = "cpu", label = "CPU submission", center = {-3.815, 0.28}, size = {3.33, 1.56}},
    {id = "device", label = "Device-local video", center = {0.64, 0.28}, size = {5.38, 1.56}},
}
for _, zone in ipairs(zones) do
    local left = zone.center[1] - zone.size[1] * 0.5
    local top = zone.center[2] + zone.size[2] * 0.5
    boundaries:rectangle {
        id = "hardware-decode-zone-" .. zone.id,
        center = zone.center, size = zone.size, corner = 0.16,
        fill = "#131a2444", stroke = "#3c485c", width = 0.025, layer = LAYER.zone,
    }
    boundaries:text {
        id = "hardware-decode-zone-" .. zone.id .. "-label",
        text = zone.label, point = {left + 0.18, top - 0.19}, role = "code",
        fill = "muted", align = {0, 0.5}, layer = LAYER.zone_label,
    }
end

local diagram = tmath.diagram(scene, {
    id = "hardware-decode-path",
    direction = "lr",
    origin = {-4.35, 0.15},
    node_size = {1.40, 0.96},
    rank_gap = 0.38,
    node_gap = 0.50,
    zone_padding = 0.25,
    route_width = 0.065,
    arrow_length = 0.25,
    arrow_width = 0.22,
    corner = 0.12,
    layers = {zones = -30, routes = -20, nodes = 0, annotations = 10},
})

local packetQueue = diagram:node {
    id = "packet-queue", label = "Packet queue", detail = "coded AUs", rank = 0,
    position = {-4.55, 0.10}, size = {1.62, 0.96},
}
local submit = diagram:node {
    id = "submit", label = "API submit", detail = "submit", rank = 1,
    position = {-2.85, 0.10}, size = {1.35, 0.96},
}
local decoder = diagram:node {
    id = "decoder", label = "HW decoder", detail = "decode engine", rank = 2,
    position = {-1.15, 0.10}, size = {1.55, 0.96},
}
local surfaces = diagram:node {
    id = "surfaces", label = "Surface pool", detail = "NV12 / P010", rank = 3,
    position = {0.65, 0.10}, size = {1.55, 0.96},
}
local compositor = diagram:node {
    id = "compositor", label = "Compositor", detail = "wait + sample", rank = 4,
    position = {2.45, 0.10}, size = {1.50, 0.96},
}
local display = diagram:node {
    id = "display", label = "Display", detail = "present", rank = 5,
    position = {4.18, 0.10}, size = {1.15, 0.96},
}
local readback = diagram:node {
    id = "readback", label = "CPU frame", detail = "map / copy", rank = 4,
    position = {0.65, -1.16}, size = {1.35, 0.96},
}

local mainEdges = {
    diagram:connect {
        id = "packet-submit", from = packetQueue, to = submit,
        route = "straight", flow = true,
    },
    diagram:connect {
        id = "submit-decode", from = submit, to = decoder,
        route = "straight", flow = true,
    },
    diagram:connect {
        id = "decode-surface", from = decoder, to = surfaces,
        route = "straight", flow = true,
    },
    diagram:connect {
        id = "surface-compose", from = surfaces, to = compositor,
        route = "straight", flow = true,
    },
    diagram:connect {
        id = "compose-present", from = compositor, to = display,
        route = "straight", flow = true,
    },
}
local readbackEdge = diagram:connect {
    id = "surface-readback", from = surfaces, to = readback,
    from_port = "bottom", to_port = "top", route = "straight", flow = false,
}

local built = diagram:build()
local flows = {}
for index, edge in ipairs(mainEdges) do flows[index] = built:edge(edge) end
local readbackRoute = built:edge(readbackEdge)

local readbackLabel = text(
    "hardware-decode-readback-label", "optional readback",
    {1.27, -0.57}, "code", "warning", {0, 0.5}
)

local ownership = text(
    "hardware-decode-ownership",
    "surface pool owns reusable decode targets; fences prevent reuse while GPU work is pending",
    {0, -2.00}, "code", "foreground"
)
local summary = text(
    "hardware-decode-summary",
    "zero-copy path: decode -> surface -> composite -> present · CPU access adds transfer cost",
    {0, -2.43}, "code", "result"
)

scene:fade_in(claim, {shift = {0, 0.08}, duration = 0.42, curve = "gentle"})
scene:fade_in(scope, {shift = {0, 0.05}, duration = 0.32, curve = "gentle"})
scene:fade_in(boundaries, {duration = 0.36, curve = "gentle"})
scene:fade_in(built:nodes(), {shift = {0, 0.06}, duration = 0.60, curve = "ease_out"})
scene:fade_in(built:routes(), {duration = 0.56, curve = "ease_out"})
scene:fade_in(built:annotations(), {duration = 0.34, curve = "gentle"})
scene:play({
    {target = flows[1], dash_offset = -9},
    {target = flows[2], dash_offset = -9},
    {target = flows[3], dash_offset = -9},
    {target = flows[4], dash_offset = -9},
    {target = flows[5], dash_offset = -9},
}, 1.20, "linear")
scene:indicate(built:node_body(surfaces), {color = "result", scale = 1.04, duration = 0.42})
scene:indicate(readbackRoute, {color = "warning", scale = 1.02, duration = 0.38})
scene:fade_in(readbackLabel, {shift = {0.03, 0}, duration = 0.26, curve = "gentle"})
scene:fade_in(ownership, {shift = {0, -0.04}, duration = 0.32, curve = "gentle"})
scene:fade_in(summary, {shift = {0, -0.04}, duration = 0.34, curve = "gentle"})
scene:wait(2.0)
return scene
