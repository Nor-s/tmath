-- Question: which static relations were added for error-handler creation?
-- Source-derived example: CppKorea/DesignPattern compiler abstract-factory PlantUML diff.
-- Edit surface: SPEC, COMMON_NODES, and ADDITIONS. Keep shared stable IDs aligned across revisions.
-- Preserve: matched layout, identical scale, first semantic divergence, and explicit evidence limits.
local SPEC = {
    question = "What static relations were added for error-handler creation?",
    before = "Compiler_Abstract_Factory.txt",
    after = "Compiler_Abstract_Factory_Add_Error_Handler.txt",
    evidence = "PlantUML declarations only · runtime use unresolved",
}

local scene = tmath.scene {
    width = 1280, height = 720, fps = 30, loop = false,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 720},
}

local LAYER = {boundary = 0, route = 10, body = 20, text = 40, focus = 50}
local root = scene:group {id = "before-after-review:root"}

local title = root:text {
    text = SPEC.question, point = {0, 318}, role = "h2", fill = "foreground",
    layer = LAYER.text, id = "before-after-review:title",
}
local subtitle = root:text {
    text = SPEC.before .. " → " .. SPEC.after .. " · " .. SPEC.evidence,
    point = {0, 280}, role = "code", fill = "muted", layer = LAYER.text,
    id = "before-after-review:subtitle",
}
local divider = root:line {
    from = {-600, 252}, to = {600, 252}, stroke = "border", width = 1.5,
    layer = LAYER.boundary, id = "before-after-review:header-divider",
}

local function revision_panel(id, heading, fileName, offset)
    local group = root:group {id = id}
    local body = group:rectangle {
        center = {offset, -20}, size = {570, 500}, corner = 10, fill = "surface",
        stroke = "border", width = 1.5, opacity = 0,
        layer = LAYER.boundary, id = id .. ":body",
    }
    local headingText = group:text {
        text = heading, point = {offset - 260, 206}, align = {0, 0.5}, role = "h3",
        fill = "foreground", opacity = 0, layer = LAYER.text, id = id .. ":heading",
    }
    local sourceText = group:text {
        text = fileName, point = {offset + 260, 206}, align = {1, 0.5}, role = "code",
        fill = "muted", opacity = 0, layer = LAYER.text, id = id .. ":source",
    }
    return {group = group, body = body, heading = headingText, source = sourceText, offset = offset}
end

local before = revision_panel("revision:before", "BEFORE", "baseline", -310)
local after = revision_panel("revision:after", "AFTER", "revised", 310)

local COMMON_NODES = {
    client = {stable = "obj:Client", label = "Client", x = -210, y = 126, w = 110, h = 52},
    factory = {stable = "type:CompilerFactory", label = "CompilerFactory", x = 70, y = 126, w = 320, h = 118},
    hp = {stable = "type:HPCompilerFactory", label = "HPCompilerFactory", x = -90, y = 5, w = 220, h = 58},
    sun = {stable = "type:SunCompilerFactory", label = "SunCompilerFactory", x = 150, y = 5, w = 220, h = 58},
}

local function common_node(parent, revisionId, spec, offset, emphasis)
    local id = revisionId .. ":" .. spec.stable
    local group = parent:group {id = id}
    local body = group:rectangle {
        center = {offset + spec.x, spec.y}, size = {spec.w, spec.h}, corner = 7,
        fill = "surface", stroke = emphasis or "border", width = emphasis and 2 or 1.5,
        layer = LAYER.body, id = id .. ":body",
    }
    local label = group:text {
        text = spec.label, point = {offset + spec.x, spec.y}, role = "code",
        fill = emphasis or "foreground", layer = LAYER.text, id = id .. ":label",
    }
    return {group = group, body = body, label = label}
end

local function build_common(panel, revisionId)
    local nodes = panel.group:group {id = revisionId .. ":common-nodes", opacity = 0}
    local routes = panel.group:group {id = revisionId .. ":common-routes"}
    local offset = panel.offset
    local handles = {}

    handles.client = common_node(nodes, revisionId, COMMON_NODES.client, offset, nil)
    handles.factory = common_node(nodes, revisionId, COMMON_NODES.factory, offset, "accent")
    handles.hp = common_node(nodes, revisionId, COMMON_NODES.hp, offset, nil)
    handles.sun = common_node(nodes, revisionId, COMMON_NODES.sun, offset, nil)

    local factoryTitle = handles.factory.label
    factoryTitle:move_to({offset + 70, 151})
    local existingMethods = nodes:text {
        text = "CreateScanner … CreateOptimizer", point = {offset + 70, 116}, role = "code",
        fill = "muted", layer = LAYER.text, id = revisionId .. ":type:CompilerFactory:methods:1",
    }

    local relations = {
        routes:arrow {
            from = {offset - 155, 126}, to = {offset - 92, 126}, tip = 10,
            stroke = "foreground", width = 2, layer = LAYER.route,
            id = revisionId .. ":relation:Client:uses:CompilerFactory",
        },
        routes:arrow {
            from = {offset - 90, 34}, to = {offset + 8, 67}, tip = 9,
            stroke = "foreground", width = 1.8, layer = LAYER.route,
            id = revisionId .. ":relation:HPCompilerFactory:inherits:CompilerFactory",
        },
        routes:arrow {
            from = {offset + 150, 34}, to = {offset + 132, 67}, tip = 9,
            stroke = "foreground", width = 1.8, layer = LAYER.route,
            id = revisionId .. ":relation:SunCompilerFactory:inherits:CompilerFactory",
        },
    }
    return {
        nodes = nodes, routes = routes, relations = relations, handles = handles,
        existingMethods = existingMethods,
    }
end

local beforeCommon = build_common(before, "before")
local afterCommon = build_common(after, "after")

local beforeWitnessBody = before.group:rectangle {
    center = {-310, -176}, size = {500, 76}, corner = 8, fill = "surface", stroke = "muted",
    width = 1.5, layer = LAYER.body, id = "before:witness:body",
}
local beforeWitnessLabel = before.group:text {
    text = "baseline: no CreateErrorHandler declaration\nor error-handler creation dependency",
    point = {-310, -176}, role = "code", fill = "muted", layer = LAYER.text,
    id = "before:witness:label",
}

local additions = after.group:group {id = "after:additions"}
local addedMethodBody = additions:rectangle {
    center = {380, 84}, size = {260, 34}, corner = 4, fill = "surface", stroke = "result",
    width = 1.5, layer = LAYER.body, id = "after:addition:CreateErrorHandler:body",
}
local addedMethodLabel = additions:text {
    text = "+ CreateErrorHandler()", point = {380, 84}, role = "code", fill = "result",
    layer = LAYER.text, id = "after:addition:CreateErrorHandler:label",
}

local function added_node(id, label, center, size, stroke)
    local group = additions:group {id = id}
    local body = group:rectangle {
        center = center, size = size, corner = 7, fill = "surface", stroke = stroke,
        width = 2, layer = LAYER.body, id = id .. ":body",
    }
    local textHandle = group:text {
        text = label, point = center, role = "code", fill = stroke,
        layer = LAYER.text, id = id .. ":label",
    }
    return {group = group, body = body, label = textHandle}
end

local errorBase = added_node("after:type:ErrorHandler", "ErrorHandler", {350, -80}, {210, 54}, "result")
local hpError = added_node("after:type:HPErrorHandler", "HPErrorHandler", {230, -170}, {190, 54}, "result")
local sunError = added_node("after:type:SunErrorHandler", "SunErrorHandler", {470, -170}, {190, 54}, "result")

local additionRoutes = after.group:group {id = "after:addition-routes"}
local routeHandles = {
    additionRoutes:arrow {
        from = {210, -24}, to = {210, -143}, tip = 9, stroke = "result", width = 2,
        layer = LAYER.route, id = "after:relation:HPCompilerFactory:creates:HPErrorHandler",
    },
    additionRoutes:arrow {
        from = {490, -24}, to = {490, -143}, tip = 9, stroke = "result", width = 2,
        layer = LAYER.route, id = "after:relation:SunCompilerFactory:creates:SunErrorHandler",
    },
    additionRoutes:arrow {
        from = {190, -143}, to = {300, -107}, tip = 9, stroke = "foreground", width = 1.7,
        layer = LAYER.route, id = "after:relation:HPErrorHandler:inherits:ErrorHandler",
    },
    additionRoutes:arrow {
        from = {510, -143}, to = {400, -107}, tip = 9, stroke = "foreground", width = 1.7,
        layer = LAYER.route, id = "after:relation:SunErrorHandler:inherits:ErrorHandler",
    },
}
local hpCreateLabel = after.group:text {
    text = "+ create", point = {190, -70}, role = "code", fill = "result",
    layer = LAYER.text, id = "after:relation:HPCompilerFactory:creates:label",
}
local sunCreateLabel = after.group:text {
    text = "+ create", point = {490, -70}, role = "code", fill = "result",
    layer = LAYER.text, id = "after:relation:SunCompilerFactory:creates:label",
}

local afterWitnessBody = after.group:rectangle {
    center = {310, -238}, size = {520, 42}, corner = 7, fill = "surface", stroke = "warning",
    width = 1.5, layer = LAYER.body, id = "after:witness:body",
}
local afterWitnessLabel = after.group:text {
    text = "runtime call, ownership, and failures unresolved",
    point = {310, -238}, role = "code", fill = "warning", layer = LAYER.text,
    id = "after:witness:label",
}

scene:fade_in(title, {shift = {0, -6}, duration = 0.42, curve = "gentle"})
scene:fade_in(subtitle, {shift = {0, -4}, duration = 0.32, curve = "gentle"})
scene:create(divider, 0.28, "ease_out")
scene:play({
    {target = before.body, opacity = 0.52},
    {target = after.body, opacity = 0.52},
}, 0.42, "gentle", 0)
scene:play({
    {target = before.heading, opacity = 1},
    {target = before.source, opacity = 1},
    {target = after.heading, opacity = 1},
    {target = after.source, opacity = 1},
}, 0.30, "gentle", 0)
scene:play({
    {target = beforeCommon.nodes, opacity = 1},
    {target = afterCommon.nodes, opacity = 1},
}, 0.52, "ease_out", 0)
scene:create({
    beforeCommon.relations[1], beforeCommon.relations[2], beforeCommon.relations[3],
    afterCommon.relations[1], afterCommon.relations[2], afterCommon.relations[3],
}, 0.72, "ease_out", 0.06, "forward")
scene:fade_in(beforeWitnessBody, {duration = 0.24, curve = "gentle"})
scene:fade_in(beforeWitnessLabel, {duration = 0.20, curve = "gentle"})
scene:wait(0.72)

scene:indicate(afterCommon.handles.factory.body, {
    color = "result", scale = 1.025, duration = 0.38, curve = "ease_in_out",
})
scene:fade_in(addedMethodBody, {scale = 0.97, duration = 0.28, curve = "gentle"})
scene:fade_in(addedMethodLabel, {duration = 0.20, curve = "gentle"})
scene:wait(0.46)

scene:fade_in(errorBase.group, {shift = {0, 5}, duration = 0.32, curve = "gentle"})
scene:fade_in(hpError.group, {shift = {0, 5}, duration = 0.28, curve = "gentle"})
scene:fade_in(sunError.group, {shift = {0, 5}, duration = 0.28, curve = "gentle"})
scene:create(routeHandles, 0.66, "ease_out", 0.08, "forward")
scene:fade_in(hpCreateLabel, {duration = 0.20, curve = "gentle"})
scene:fade_in(sunCreateLabel, {duration = 0.20, curve = "gentle"})
scene:fade_in(afterWitnessBody, {scale = 0.985, duration = 0.28, curve = "gentle"})
scene:fade_in(afterWitnessLabel, {duration = 0.22, curve = "gentle"})
scene:wait(2.8)
return scene
