-- Question: which parent owns each capability, and which cross-tree dependency remains?
-- Edit node labels and the measured tier coordinates below; keep the two bus corridors clear.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local LAYER = {route = 10, node = 20, text = 30}
local root = scene:group {id = "capability-tree:root"}
local primaryBus = root:group {id = "capability-tree:primary-bus"}
local leafBuses = root:group {id = "capability-tree:leaf-buses"}

local function segment(parent, id, from, to)
    return parent:line {
        from = from, to = to, color = "border", width = 2,
        layer = LAYER.route, id = id,
    }
end

-- Root -> two capability groups: one trunk, one sibling bus, distinct drops.
segment(primaryBus, "capability-tree:root-trunk", {0, 156}, {0, 125})
segment(primaryBus, "capability-tree:primary-rail", {-190, 125}, {190, 125})
segment(primaryBus, "capability-tree:runtime-drop", {-190, 125}, {-190, 94})
segment(primaryBus, "capability-tree:delivery-drop", {190, 125}, {190, 94})

-- Each parent owns its own second-level bus; no child edges share a shaft.
segment(leafBuses, "capability-tree:runtime-trunk", {-190, 36}, {-190, 0})
segment(leafBuses, "capability-tree:runtime-rail", {-330, 0}, {-110, 0})
segment(leafBuses, "capability-tree:scheduler-drop", {-330, 0}, {-330, -53})
segment(leafBuses, "capability-tree:storage-drop", {-110, 0}, {-110, -53})
segment(leafBuses, "capability-tree:delivery-trunk", {190, 36}, {190, 0})
segment(leafBuses, "capability-tree:delivery-rail", {110, 0}, {330, 0})
segment(leafBuses, "capability-tree:preview-drop", {110, 0}, {110, -53})
segment(leafBuses, "capability-tree:export-drop", {330, 0}, {330, -53})

-- A separate lower corridor carries the only non-hierarchical dependency.
local dependency = root:route {
    points = {{-330, -107}, {-330, -185}, {330, -185}, {330, -107}},
    tip = 11, color = "muted", width = 2, dash = {8, 6},
    layer = LAYER.route, id = "capability-tree:dependency:scheduler-export",
}
local dependencyLabel = root:text {
    text = "uses release artifact", point = {0, -165}, role = "code", fill = "muted",
    layer = LAYER.text, id = "capability-tree:dependency:scheduler-export:label",
}

local rootNode = root:group {id = "capability-tree:tier-root"}
local groupNodes = root:group {id = "capability-tree:tier-groups"}
local leafNodes = root:group {id = "capability-tree:tier-leaves"}

local function node(parent, spec)
    local group = parent:group {id = "capability-tree:node:" .. spec.id}
    group:rectangle {
        center = spec.center, size = spec.size, corner = 4, fill = "surface",
        stroke = spec.focal and "accent" or "border",
        width = spec.focal and 2 or 1.5, layer = LAYER.node,
        id = "capability-tree:node:" .. spec.id .. ":body",
    }
    group:text {
        text = spec.label, point = {spec.center[1], spec.center[2] + 9},
        role = "text", fill = spec.focal and "accent" or "foreground",
        layer = LAYER.text, id = "capability-tree:node:" .. spec.id .. ":label",
    }
    group:text {
        text = spec.detail, point = {spec.center[1], spec.center[2] - 16},
        role = "code", fill = "muted", layer = LAYER.text,
        id = "capability-tree:node:" .. spec.id .. ":detail",
    }
    return group
end

node(rootNode, {
    id = "platform", label = "Platform", detail = "capability root",
    center = {0, 185}, size = {180, 70}, focal = true,
})
node(groupNodes, {
    id = "runtime", label = "Runtime", detail = "execution",
    center = {-190, 65}, size = {170, 70},
})
node(groupNodes, {
    id = "delivery", label = "Delivery", detail = "release",
    center = {190, 65}, size = {170, 70},
})
node(leafNodes, {
    id = "scheduler", label = "Scheduler", detail = "jobs",
    center = {-330, -80}, size = {150, 70},
})
node(leafNodes, {
    id = "storage", label = "Storage", detail = "state",
    center = {-110, -80}, size = {150, 70},
})
node(leafNodes, {
    id = "preview", label = "Preview", detail = "inspection",
    center = {110, -80}, size = {150, 70},
})
node(leafNodes, {
    id = "export", label = "Export", detail = "artifact",
    center = {330, -80}, size = {150, 70},
})

-- Construction follows semantic tiers; the settled frame remains fully inspectable.
scene:fade_in(rootNode, {shift = {0, -8}, duration = 0.45, curve = "gentle"})
scene:fade_in(groupNodes, {shift = {0, -8}, duration = 0.55, curve = "gentle"})
scene:create(primaryBus, 0.65, "ease_out")
scene:fade_in(leafNodes, {shift = {0, -8}, duration = 0.55, curve = "gentle"})
scene:create(leafBuses, 0.75, "ease_out")
scene:create(dependency, 0.75, "ease_out")
scene:fade_in(dependencyLabel, {shift = {0, -5}, duration = 0.3, curve = "gentle"})
scene:wait(2.4)
return scene
