-- Question: which branch decisions lead to the first positive even value?
-- Variant: scan left-to-right; skip non-positive and odd values; return the first match.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local VALUES = {-3, 5, 7, 8, 10}
local LAYER = {route = 8, body = 20, text = 40}
local function buildTrace(values)
    local trace = {}
    for index, value in ipairs(values) do
        trace[#trace + 1] = {kind = "read", index = index - 1, value = value, anchor = "line 2"}
        if value <= 0 then
            trace[#trace + 1] = {kind = "reject", test = "positive", index = index - 1, value = value, anchor = "line 3"}
        elseif value % 2 ~= 0 then
            trace[#trace + 1] = {kind = "reject", test = "even", index = index - 1, value = value, anchor = "line 4"}
        else
            trace[#trace + 1] = {kind = "return", index = index - 1, value = value, anchor = "line 5"}
            return trace, index - 1
        end
    end
    trace[#trace + 1] = {kind = "return", index = -1, anchor = "line 7"}
    return trace, -1
end
local TRACE, RESULT = buildTrace(VALUES)
assert(RESULT == 3 and VALUES[RESULT + 1] == 8)

local title = scene:text {text = "Control flow · decisions select one executed path", point = {0, 230}, role = "h2", fill = "foreground", layer = LAYER.text, id = "scene-title"}
local subtitle = scene:text {text = "first positive even value · zero-based return index", point = {0, 194}, role = "code", fill = "muted", layer = LAYER.text, id = "scene-subtitle"}

local NODE = {
    read = {x = -285, y = 105, label = "read next item"},
    positive = {x = -285, y = 35, label = "x > 0 ?"},
    even = {x = -285, y = -35, label = "x % 2 == 0 ?"},
    result = {x = -285, y = -105, label = "return index"},
}
local bodies = {}
for _, id in ipairs({"read", "positive", "even", "result"}) do
    local spec = NODE[id]
    bodies[id] = scene:rectangle {center = {spec.x, spec.y}, size = {230, 46}, corner = 6, fill = "surface", stroke = "border", width = 2, layer = LAYER.body, id = "flow:" .. id .. ":body"}
    scene:text {text = spec.label, point = {spec.x, spec.y}, role = "code", fill = "foreground", layer = LAYER.text, id = "flow:" .. id .. ":label"}
end
local routes = {
    scene:arrow {from = {-285, 82}, to = {-285, 58}, tip = 9, stroke = "foreground", layer = LAYER.route, id = "flow:read-to-positive"},
    scene:arrow {from = {-285, 12}, to = {-285, -12}, tip = 9, stroke = "foreground", layer = LAYER.route, id = "flow:positive-to-even"},
    scene:arrow {from = {-285, -58}, to = {-285, -82}, tip = 9, stroke = "foreground", layer = LAYER.route, id = "flow:even-to-result"},
}
scene:text {text = "true", point = {-250, -72}, role = "code", fill = "muted", layer = LAYER.text, id = "flow:true-label"}
local loopRoute = scene:route {points = {{-170, 35}, {-130, 35}, {-130, 130}, {-285, 130}, {-285, 128}}, tip = 9, stroke = "muted", dash = {7, 5}, layer = LAYER.route, id = "flow:reject-loop"}
local evenLoopRoute = scene:route {points = {{-170, -35}, {-95, -35}, {-95, 145}, {-245, 145}, {-245, 128}}, tip = 9, stroke = "muted", dash = {7, 5}, layer = LAYER.route, id = "flow:even-reject-loop"}
scene:text {text = "false → continue", point = {-78, 84}, role = "code", fill = "muted", layer = LAYER.text, id = "flow:continue-label"}

local cells, cellBodies = {}, {}
for index, value in ipairs(VALUES) do
    local x = 80 + (index - 1) * 76
    cellBodies[index] = scene:rectangle {center = {x, 70}, size = {66, 58}, corner = 5, fill = "surface", stroke = "border", width = 2, layer = LAYER.body, id = "array:" .. (index - 1) .. ":body"}
    scene:text {text = tostring(value), point = {x, 80}, role = "code", fill = "foreground", layer = LAYER.text, id = "array:" .. (index - 1) .. ":value"}
    scene:text {text = tostring(index - 1), point = {x, 56}, role = "code", fill = "muted", layer = LAYER.text, id = "array:" .. (index - 1) .. ":index"}
    cells[index] = scene:group {id = "array:" .. (index - 1)}
end
scene:text {text = "INPUT", point = {232, 125}, role = "code", fill = "accent", layer = LAYER.text, id = "input-label"}

local status, version = nil, 0
local function setStatus(text, color)
    version = version + 1
    local nextStatus = scene:text {text = text, point = {230, -35}, role = "code", fill = color or "focus", layer = LAYER.text, id = "status:" .. version}
    if status then scene:fade_transform(status, nextStatus, 0.16, "gentle") else scene:fade_in(nextStatus, {duration = 0.22, curve = "gentle"}) end
    status = nextStatus
end
local function focusNode(id)
    local clips = {}
    for _, other in ipairs({"read", "positive", "even", "result"}) do clips[#clips + 1] = {target = bodies[other], fill = "surface", stroke = other == id and "focus" or "border"} end
    scene:play(clips, 0.22, "ease_in_out", 0)
end

scene:fade_in(title, {shift = {0, -6}, duration = 0.42, curve = "gentle"})
scene:fade_in(subtitle, {duration = 0.32, curve = "gentle"})
scene:create(routes, 0.32, "ease_out", 0.05)
scene:create(loopRoute, 0.32, "ease_out")
scene:create(evenLoopRoute, 0.32, "ease_out")
for _, event in ipairs(TRACE) do
    if event.kind == "read" then
        focusNode("read")
        setStatus(string.format("%s · read a[%d] = %d", event.anchor, event.index, event.value))
        scene:play({{target = cellBodies[event.index + 1], fill = "focus", stroke = "focus"}}, 0.24, "ease_in_out", 0)
    elseif event.kind == "reject" then
        focusNode(event.test)
        setStatus(string.format("%s · %s test fails → continue", event.anchor, event.test), "warning")
        scene:play({{target = cellBodies[event.index + 1], fill = "surface", stroke = "muted", opacity = 0.35}}, 0.28, "ease_in_out", 0)
    else
        focusNode("result")
        setStatus(string.format("%s · %d satisfies both predicates", event.anchor, event.value), "result")
        scene:play({{target = cellBodies[event.index + 1], fill = "surface", stroke = "result"}}, 0.34, "ease_in_out", 0)
    end
    scene:wait(0.18)
end
local result = scene:text {text = "return 3 · untaken values remain visible but never execute", point = {180, -120}, role = "text", fill = "result", layer = LAYER.text, id = "result:control-flow"}
scene:fade_transform(status, result, 0.22, "gentle")
scene:wait(2.3)
return scene
