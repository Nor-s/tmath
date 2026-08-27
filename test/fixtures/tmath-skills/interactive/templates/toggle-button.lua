-- Retained binary-state template built from one Button.
-- Requires a tmath build configured with -Dui=true.
-- Replace the state names, endpoints, and semantic target together.
if not tmath.ui then
    error("toggle-button.lua requires a tmath build configured with -Dui=true")
end

local WIDTH, HEIGHT = 960, 540
local scene = tmath.scene {
    width = WIDTH, height = HEIGHT, fps = 30, loop = true,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = HEIGHT},
}

local LAYER = {panel = 10, rule = 20, face = 30, state = 40, text = 50}
local SWITCH = {x = -190, y = -6, width = 156, height = 56, travel = 96}

local function pixel_region(cx, cy, width, height)
    return {
        x = cx - width / 2 + WIDTH / 2,
        y = HEIGHT / 2 - (cy + height / 2),
        width = width,
        height = height,
    }
end

scene:text {
    text = "Toggle button with retained binary state",
    point = {-424, 226}, align = {0, 0.5}, role = "h2",
    layer = LAYER.text, id = "toggle-demo:title",
}
scene:text {
    text = "One completed click flips s and animates the bound target to its next endpoint.",
    point = {-424, 187}, align = {0, 0.5}, role = "text", fill = "muted",
    layer = LAYER.text, id = "toggle-demo:subtitle",
}

scene:rectangle {
    center = {0, -8}, size = {848, 326}, corner = 6,
    fill = "surface", stroke = "border", width = 1.5,
    layer = LAYER.panel, id = "toggle-demo:panel",
}
scene:line {
    from = {74, -144}, to = {74, 126}, color = "border", width = 1.5,
    layer = LAYER.rule, id = "toggle-demo:column-rule",
}

scene:text {
    text = "CONTROL", point = {-376, 112}, align = {0, 0.5},
    role = "code", fill = "muted", layer = LAYER.text,
    id = "toggle-demo:control:eyebrow",
}
scene:text {
    text = "Tracing", point = {-376, 73}, align = {0, 0.5},
    role = "h3", layer = LAYER.text, id = "toggle-demo:control:title",
}
scene:text {
    text = "Retained until the next click", point = {-376, 41}, align = {0, 0.5},
    role = "text", fill = "muted", layer = LAYER.text,
    id = "toggle-demo:control:description",
}

-- These independent faces are the Button visual states. They never move.
local function switch_face(state, stroke, width)
    return scene:rectangle {
        center = {SWITCH.x, SWITCH.y}, size = {SWITCH.width, SWITCH.height},
        corner = SWITCH.height / 2, fill = "background", stroke = stroke, width = width,
        layer = LAYER.face, id = "toggle-demo:switch:" .. state,
    }
end

local switch_idle = switch_face("idle", "border", 2)
local switch_hover = switch_face("hover", "accent", 2.5)
local switch_pressed = switch_face("pressed", "focus", 3)

local off_x = SWITCH.x - SWITCH.travel / 2
local on_x = SWITCH.x + SWITCH.travel / 2
scene:text {
    text = "OFF", point = {off_x, -62}, role = "code", fill = "muted",
    layer = LAYER.text, id = "toggle-demo:state:off-label",
}
scene:text {
    text = "ON", point = {on_x, -62}, role = "code", fill = "muted",
    layer = LAYER.text, id = "toggle-demo:state:on-label",
}

-- One semantic target carries both pieces of persistent state evidence.
local state_indicator = scene:group {id = "toggle-demo:state-indicator"}
state_indicator:circle {
    center = {off_x, SWITCH.y}, radius = 20,
    fill = "focus", stroke = "background", width = 3,
    layer = LAYER.state, id = "toggle-demo:switch:thumb",
}
state_indicator:rectangle {
    center = {off_x, -82}, size = {52, 3}, corner = 1.5,
    fill = "focus", stroke = "focus", width = 1,
    layer = LAYER.state, id = "toggle-demo:state:underline",
}

scene:text {
    text = "Click the switch", point = {SWITCH.x, -119},
    role = "text", fill = "foreground", layer = LAYER.text,
    id = "toggle-demo:instruction",
}

scene:text {
    text = "STATE CONTRACT", point = {122, 112}, align = {0, 0.5},
    role = "code", fill = "muted", layer = LAYER.text,
    id = "toggle-demo:contract:eyebrow",
}
scene:text {
    text = "s ∈ {0, 1}", point = {122, 66}, align = {0, 0.5},
    role = "h3", fill = "accent", layer = LAYER.text,
    id = "toggle-demo:contract:domain",
}
scene:text {
    text = "sₙ₊₁ = 1 − sₙ", point = {122, 18}, align = {0, 0.5},
    role = "h3", layer = LAYER.text, id = "toggle-demo:contract:update",
}
scene:text {
    text = "x(s) = (1 − s)x₀ + sx₁", point = {122, -33}, align = {0, 0.5},
    role = "code", fill = "foreground", layer = LAYER.text,
    id = "toggle-demo:contract:interpolation",
}
scene:line {
    from = {122, -69}, to = {376, -69}, color = "border", width = 1.5,
    layer = LAYER.rule, id = "toggle-demo:contract:rule",
}
scene:text {
    text = "Initial value", point = {122, -99}, align = {0, 0.5},
    role = "text", fill = "muted", layer = LAYER.text,
    id = "toggle-demo:contract:initial-label",
}
scene:text {
    text = "false / OFF", point = {376, -99}, align = {1, 0.5},
    role = "code", fill = "focus", layer = LAYER.text,
    id = "toggle-demo:contract:initial-value",
}

local panel = tmath.ui.panel(scene)
panel:toggle_button {
    visual = switch_idle,
    hover_visual = switch_hover,
    pressed_visual = switch_pressed,
    region = pixel_region(SWITCH.x, SWITCH.y, SWITCH.width + 6, SWITCH.height + 6),
    target = state_indicator,
    off = {},
    on = {shift = {SWITCH.travel, 0, 0}},
    value = false,
    duration = 0.28,
}

scene:wait(12)
return scene
