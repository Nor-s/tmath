-- Question: which event and guard cause each application state transition?
-- Variant: Idle --start--> Loading --failure--> Error --retry--> Loading --success--> Ready.
local scene = tmath.scene {width = 960, height = 540, fps = 30, loop = false, theme = "adaptive_vscode", camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540}}
local LAYER = {route = 8, body = 20, text = 40}
local TRACE = {
    {from = "idle", event = "start", guard = "request != nil", to = "loading"},
    {from = "loading", event = "failure", guard = "attempt == 1", to = "error"},
    {from = "error", event = "retry", guard = "attempt < 3", to = "loading"},
    {from = "loading", event = "success", guard = "response.ok", to = "ready"},
}
local state = "idle"
for _, transition in ipairs(TRACE) do assert(state == transition.from); state = transition.to end
assert(state == "ready")

local title = scene:text {text = "Code to state machine · events and guards", point = {0, 230}, role = "h2", fill = "foreground", layer = LAYER.text, id = "scene-title"}
local subtitle = scene:text {text = "one event trace · topology stays fixed while state changes", point = {0, 194}, role = "code", fill = "muted", layer = LAYER.text, id = "scene-subtitle"}
local SPEC = {
    idle = {x = -310, y = 35, label = "Idle"}, loading = {x = -65, y = 35, label = "Loading"},
    ready = {x = 245, y = 105, label = "Ready"}, error = {x = 245, y = -55, label = "Error"},
}
local bodies = {}
for _, id in ipairs({"idle", "loading", "ready", "error"}) do
    local spec = SPEC[id]
    bodies[id] = scene:rectangle {center = {spec.x, spec.y}, size = {170, 62}, corner = 9, fill = "surface", stroke = "border", width = 2, layer = LAYER.body, id = "state:" .. id .. ":body"}
    scene:text {text = spec.label, point = {spec.x, spec.y}, role = "h3", fill = "foreground", layer = LAYER.text, id = "state:" .. id .. ":label"}
end
local routes = {
    start = scene:arrow {from = {-225, 35}, to = {-150, 35}, tip = 11, stroke = "muted", width = 2.5, layer = LAYER.route, id = "transition:start"},
    success = scene:route {points = {{20, 55}, {90, 55}, {90, 105}, {160, 105}}, tip = 11, stroke = "muted", width = 2.5, layer = LAYER.route, id = "transition:success"},
    failure = scene:route {points = {{20, 15}, {90, 15}, {90, -55}, {160, -55}}, tip = 11, stroke = "muted", width = 2.5, layer = LAYER.route, id = "transition:failure"},
    retry = scene:route {points = {{245, -86}, {245, -120}, {-65, -120}, {-65, 4}}, tip = 11, dash = {8, 6}, stroke = "muted", width = 2.5, layer = LAYER.route, id = "transition:retry"},
}
scene:text {text = "start", point = {-188, 62}, role = "code", fill = "muted", layer = LAYER.text, id = "transition:start:label"}
scene:text {text = "success [response.ok]", point = {145, 132}, align = {1, 0.5}, role = "code", fill = "muted", layer = LAYER.text, id = "transition:success:label"}
scene:text {text = "failure [attempt == 1]", point = {190, -8}, role = "code", fill = "muted", layer = LAYER.text, id = "transition:failure:label"}
scene:text {text = "retry [attempt < 3]", point = {90, -148}, role = "code", fill = "muted", layer = LAYER.text, id = "transition:retry:label"}

local status, version = nil, 0
local function setStatus(text, color)
    version = version + 1
    local nextStatus = scene:text {text = text, point = {0, -205}, role = "code", fill = color or "focus", layer = LAYER.text, id = "status:" .. version}
    if status then scene:fade_transform(status, nextStatus, 0.16, "gentle") else scene:fade_in(nextStatus, {duration = 0.22, curve = "gentle"}) end
    status = nextStatus
end
local current = "idle"
scene:fade_in(title, {shift = {0, -6}, duration = 0.42, curve = "gentle"}); scene:fade_in(subtitle, {duration = 0.32, curve = "gentle"})
scene:play({{target = bodies.idle, fill = "focus", stroke = "focus"}}, 0.30, "ease_in_out", 0)
for _, transition in ipairs(TRACE) do
    local route = routes[transition.event]
    setStatus(transition.event .. " [" .. transition.guard .. "] · " .. transition.from .. " → " .. transition.to)
    scene:play({{target = route, stroke = "focus"}, {target = bodies[current], fill = "surface", stroke = "border"}}, 0.28, "ease_in_out", 0)
    scene:play({{target = bodies[transition.to], fill = transition.to == "ready" and "result" or "focus", stroke = transition.to == "ready" and "result" or "focus"}, {target = route, stroke = "muted"}}, 0.34, "ease_in_out", 0)
    current = transition.to
    scene:wait(0.30)
end
local result = scene:text {text = "final state Ready · every edge names its event and guard", point = {0, -235}, role = "text", fill = "result", layer = LAYER.text, id = "result:state-machine"}
scene:fade_transform(status, result, 0.22, "gentle"); scene:wait(2.4)
return scene
