-- Logical-to-physical placement template for distributed AI/HPC figures.
-- This depicts ownership, not an execution schedule or a specific collective.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "pro_white",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local LAYER = {boundary = 0, route = 10, node = 20, text = 30, focus = 40}
local root = scene:group {id = "placement:root"}
local header = root:group {id = "placement:header"}
local logical = root:group {id = "placement:logical"}
local physical = root:group {id = "placement:physical"}
local routes = root:group {id = "placement:routes"}
local exchange = root:group {id = "placement:exchange"}

header:text {
    text = "Distributed placement", point = {0, 232}, role = "h2",
    fill = "foreground", layer = LAYER.text, id = "placement:title",
}
header:text {
    text = "logical partition → rank ownership → physical node boundary",
    point = {0, 199}, role = "code", fill = "muted", layer = LAYER.text,
    id = "placement:subtitle",
}

logical:text {
    text = "LOGICAL DOMAIN", point = {-311, 157}, role = "code", fill = "muted",
    layer = LAYER.text, id = "placement:logical:title",
}
logical:rectangle {
    center = {-311, 26}, size = {272, 214}, corner = 8, fill = "surface",
    stroke = "border", width = 1.4, layer = LAYER.boundary, id = "placement:logical:boundary",
}
local shard_centers = {{-376, 76}, {-246, 76}, {-376, -24}, {-246, -24}}
local shard_bodies = {}
for index, center in ipairs(shard_centers) do
    local rank = index - 1
    shard_bodies[index] = logical:rectangle {
        center = center, size = {116, 86}, corner = 5,
        fill = rank == 0 and "#dbeafe" or "background",
        stroke = rank == 0 and "accent" or "border", width = rank == 0 and 2.1 or 1.1,
        layer = LAYER.node, id = "placement:shard:" .. rank .. ":body",
    }
    logical:text {
        text = "Ω" .. rank, point = {center[1], center[2] + 13}, role = "text",
        fill = rank == 0 and "accent" or "foreground", layer = LAYER.text,
        id = "placement:shard:" .. rank .. ":label",
    }
    logical:text {
        text = "owner r" .. rank, point = {center[1], center[2] - 17}, role = "code",
        fill = "muted", layer = LAYER.text, id = "placement:shard:" .. rank .. ":owner",
    }
end
logical:text {
    text = "partition shape is evidence", point = {-311, -132}, role = "code",
    fill = "focus", layer = LAYER.text, id = "placement:logical:note",
}

physical:text {
    text = "PHYSICAL PLACEMENT", point = {256, 157}, role = "code", fill = "muted",
    layer = LAYER.text, id = "placement:physical:title",
}
local rank_centers = {{164, 91}, {348, 91}, {164, -59}, {348, -59}}
for node = 0, 1 do
    local y = node == 0 and 86 or -64
    physical:rectangle {
        center = {256, y}, size = {416, 126}, corner = 8, fill = "surface",
        stroke = "border", width = 1.5, layer = LAYER.boundary,
        id = "placement:node:" .. node .. ":boundary",
    }
    physical:text {
        text = "NODE " .. node, point = {63, y + 48}, align = {0, 0.5}, role = "code",
        fill = "muted", layer = LAYER.text, id = "placement:node:" .. node .. ":label",
    }
end
local rank_bodies = {}
for index, center in ipairs(rank_centers) do
    local rank = index - 1
    rank_bodies[index] = physical:rectangle {
        center = center, size = {156, 68}, corner = 6,
        fill = rank == 0 and "#dbeafe" or "background",
        stroke = rank == 0 and "accent" or "border", width = rank == 0 and 2.1 or 1.1,
        layer = LAYER.node, id = "placement:rank:" .. rank .. ":body",
    }
    physical:text {
        text = "rank " .. rank .. " · GPU " .. rank, point = center, role = "code",
        fill = rank == 0 and "accent" or "foreground", layer = LAYER.text,
        id = "placement:rank:" .. rank .. ":label",
    }
end

local mapping_route = routes:arrow {
    from = {-175, 26}, to = {48, 26}, tip = 9, color = "accent", width = 2,
    layer = LAYER.route, id = "placement:route:owner-map",
}
local mapping_label = routes:text {
    text = "owner map  Ωᵢ → rank i", point = {-64, 49}, role = "code",
    fill = "accent", layer = LAYER.text, id = "placement:route:owner-map-label",
}
exchange:line {
    from = {-311, -67}, to = {-311, 119}, color = "focus", width = 2,
    layer = LAYER.focus, id = "placement:neighbor-interface",
}
exchange:text {
    text = "neighbor boundary", point = {-311, -101}, role = "code", fill = "focus",
    layer = LAYER.text, id = "placement:neighbor-label",
}
local conclusion = root:text {
    text = "Placement answers where state lives; add a separate schedule to prove when work overlaps.",
    point = {0, -221}, role = "code", fill = "result", layer = LAYER.text,
    id = "placement:conclusion",
}

scene:fade_in(header, {shift = {0, -6}, duration = 0.5, curve = "gentle"})
scene:fade_in(logical, {shift = {0, -6}, duration = 0.65, curve = "ease_out"})
scene:fade_in(physical, {shift = {0, -6}, duration = 0.65, curve = "gentle"})
scene:create(mapping_route, 0.65, "ease_out")
scene:fade_in(mapping_label, {duration = 0.25, curve = "gentle"})
scene:fade_in(exchange, {duration = 0.3, curve = "gentle"})
scene:indicate(rank_bodies[1], {color = "focus", scale = 1.02, duration = 0.42, curve = "ease_in_out"})
scene:fade_in(conclusion, {duration = 0.35, curve = "gentle"})
scene:wait(2.3)
return scene
