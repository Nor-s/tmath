-- Question: what stays alive while an async function is suspended, and what resumes it?
-- Variant: fetchUser awaits one promise while the event loop runs renderFrame.
local scene = tmath.scene {width = 960, height = 540, fps = 30, loop = false, theme = "adaptive_vscode", camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540}}
local LAYER = {guide = 8, body = 20, text = 40}
local EVENTS = {
    {lane = "caller", text = "call fetchUser()", state = "running"},
    {lane = "task", text = "await networkPromise", state = "suspended"},
    {lane = "loop", text = "run renderFrame()", state = "suspended"},
    {lane = "loop", text = "promise resolves", state = "queued"},
    {lane = "task", text = "resume with response", state = "running"},
    {lane = "caller", text = "receive user", state = "done"},
}
local state = "new"
for index, event in ipairs(EVENTS) do
    if index == 1 then assert(state == "new")
    elseif index == 2 then assert(state == "running")
    elseif index == 3 then assert(state == "suspended")
    elseif index == 4 then assert(state == "suspended")
    elseif index == 5 then assert(state == "queued")
    elseif index == 6 then assert(state == "running") end
    state = event.state
end
assert(state == "done")

local title = scene:text {text = "Async / await · suspension preserves state", point = {0, 230}, role = "h2", fill = "foreground", layer = LAYER.text, id = "scene-title"}
local subtitle = scene:text {text = "await yields control · promise resolution queues continuation · resume returns", point = {0, 194}, role = "code", fill = "muted", layer = LAYER.text, id = "scene-subtitle"}
local LANE = {caller = -300, task = 0, loop = 300}
local laneName = {caller = "CALLER", task = "ASYNC TASK", loop = "EVENT LOOP"}
for _, id in ipairs({"caller", "task", "loop"}) do
    scene:text {text = laneName[id], point = {LANE[id], 145}, role = "code", fill = "accent", layer = LAYER.text, id = "lane:" .. id .. ":label"}
    scene:line {from = {LANE[id], 122}, to = {LANE[id], -92}, stroke = "muted", width = 2, dash = {7, 6}, layer = LAYER.guide, id = "lane:" .. id .. ":lifeline"}
end
local eventBody, eventLabel = {}, {}
for index, event in ipairs(EVENTS) do
    local y = 108 - (index - 1) * 38
    local x = LANE[event.lane]
    eventBody[index] = scene:rectangle {center = {x, y}, size = {230, 36}, corner = 5, fill = "surface", stroke = "border", width = 2, opacity = 0, layer = LAYER.body, id = "event:" .. index .. ":body"}
    eventLabel[index] = scene:text {text = event.text, point = {x, y}, role = "code", fill = "foreground", opacity = 0, layer = LAYER.text, id = "event:" .. index .. ":label"}
end
local frameBody = scene:rectangle {center = {0, -135}, size = {360, 58}, corner = 7, fill = "surface", stroke = "border", width = 2, layer = LAYER.body, id = "coroutine-frame:body"}
local frameState = scene:text {text = "fetchUser frame · new", point = {0, -135}, role = "code", fill = "muted", layer = LAYER.text, id = "coroutine-frame:state:0"}
local frameVersion = 0
local function setFrame(stateName, color)
    frameVersion = frameVersion + 1
    local nextState = scene:text {text = "fetchUser frame · " .. stateName, point = {0, -135}, role = "code", fill = color or "focus", layer = LAYER.text, id = "coroutine-frame:state:" .. frameVersion}
    scene:fade_transform(frameState, nextState, 0.18, "gentle"); frameState = nextState
end
local status, statusVersion = nil, 0
local function setStatus(text, color)
    statusVersion = statusVersion + 1
    local nextStatus = scene:text {text = text, point = {0, -215}, role = "code", fill = color or "focus", layer = LAYER.text, id = "status:" .. statusVersion}
    if status then scene:fade_transform(status, nextStatus, 0.16, "gentle") else scene:fade_in(nextStatus, {duration = 0.22, curve = "gentle"}) end
    status = nextStatus
end
scene:fade_in(title, {shift = {0, -6}, duration = 0.42, curve = "gentle"}); scene:fade_in(subtitle, {duration = 0.32, curve = "gentle"})
for index, event in ipairs(EVENTS) do
    scene:play({{target = eventBody[index], opacity = 1, stroke = "focus"}, {target = eventLabel[index], opacity = 1}}, 0.24, "ease_out", 0)
    setFrame(event.state, event.state == "done" and "result" or event.state == "suspended" and "warning" or "focus")
    setStatus(index == 3 and "event loop progresses while fetchUser remains suspended" or event.text)
    scene:play({{target = eventBody[index], stroke = event.state == "done" and "result" or "border"}}, 0.18, "ease_in_out", 0)
    scene:wait(0.18)
end
local result = scene:text {text = "await pauses execution, not the lifetime of the coroutine frame", point = {0, -240}, role = "text", fill = "result", layer = LAYER.text, id = "result:async-await"}
scene:fade_transform(status, result, 0.22, "gentle"); scene:play({{target = frameBody, stroke = "result"}}, 0.28, "ease_in_out", 0); scene:wait(2.4)
return scene
