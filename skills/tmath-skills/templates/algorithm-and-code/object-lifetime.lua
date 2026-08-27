-- Question: how do ownership, borrowing, moving, and release affect one resource lifetime?
-- Variant: unique owner a borrows file@F0, moves ownership to b, then b releases it.
local scene = tmath.scene {width = 960, height = 540, fps = 30, loop = false, theme = "adaptive_vscode", camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540}}
local LAYER = {rail = 6, route = 10, body = 20, text = 40, preview = 50}
local TRACE = {
    {kind = "allocate"}, {kind = "own", owner = "a"}, {kind = "borrow", ref = "view"},
    {kind = "move", from = "a", to = "b"}, {kind = "end_borrow", ref = "view"}, {kind = "release", owner = "b"},
}
local state = {alive = false, owner = nil, borrowed = false}
for _, e in ipairs(TRACE) do
    if e.kind == "allocate" then assert(not state.alive); state.alive = true
    elseif e.kind == "own" then assert(state.alive and not state.owner); state.owner = e.owner
    elseif e.kind == "borrow" then assert(state.owner and state.alive); state.borrowed = true
    elseif e.kind == "move" then assert(state.owner == e.from); state.owner = e.to
    elseif e.kind == "end_borrow" then assert(state.borrowed); state.borrowed = false
    else assert(state.owner == e.owner and not state.borrowed); state.owner = nil; state.alive = false end
end
assert(not state.alive and not state.owner)

local title = scene:text {text = "Object lifetime · ownership moves, identity does not", point = {0, 230}, role = "h2", fill = "foreground", layer = LAYER.text, id = "scene-title"}
local subtitle = scene:text {text = "illustrative unique ownership · borrow must end before release", point = {0, 194}, role = "code", fill = "muted", layer = LAYER.text, id = "scene-subtitle"}
local ownerBody, ownerLabel = {}, {}
for index, id in ipairs({"a", "b"}) do
    local y = 70 - (index - 1) * 130
    ownerBody[id] = scene:rectangle {center = {-280, y}, size = {190, 72}, corner = 7, fill = "surface", stroke = "border", width = 2, layer = LAYER.body, id = "owner:" .. id .. ":body"}
    ownerLabel[id] = scene:text {text = "unique owner " .. id, point = {-280, y}, role = "code", fill = "foreground", layer = LAYER.text, id = "owner:" .. id .. ":label"}
end
local borrowBody = scene:rectangle {center = {0, 125}, size = {185, 58}, corner = 6, fill = "surface", stroke = "border", width = 2, layer = LAYER.body, id = "borrow:view:body"}
local borrowLabel = scene:text {text = "borrowed view", point = {0, 125}, role = "code", fill = "foreground", layer = LAYER.text, id = "borrow:view:label"}
local resourceBody = scene:rectangle {center = {275, 5}, size = {270, 118}, corner = 9, fill = "surface", stroke = "border", width = 2, opacity = 0, layer = LAYER.body, id = "resource:file:body"}
local resourceAddress = scene:text {text = "file@F0 (illustrative)", point = {275, 35}, role = "code", fill = "muted", opacity = 0, layer = LAYER.text, id = "resource:file:address"}
local resourceState = scene:text {text = "OPEN", point = {275, -15}, role = "h3", fill = "success", opacity = 0, layer = LAYER.text, id = "resource:file:state:open"}
local routeA = scene:arrow {from = {-185, 70}, to = {140, 25}, tip = 11, stroke = "foreground", width = 3, opacity = 0, layer = LAYER.route, id = "ownership:a-to-file"}
local routeBPreview = scene:arrow {from = {-185, -60}, to = {140, -15}, tip = 11, dash = {8, 6}, stroke = "focus", width = 3, opacity = 0, layer = LAYER.preview, id = "preview:ownership:b-to-file"}
local routeB = scene:arrow {from = {-185, -60}, to = {140, -15}, tip = 11, stroke = "foreground", width = 3, opacity = 0, layer = LAYER.route, id = "ownership:b-to-file"}
local routeBorrow = scene:arrow {from = {90, 125}, to = {205, 64}, tip = 10, dash = {7, 5}, stroke = "info", width = 2.5, opacity = 0, layer = LAYER.route, id = "borrow:view-to-file"}
local rail = scene:line {from = {-330, -145}, to = {330, -145}, stroke = "muted", width = 2, layer = LAYER.rail, id = "lifetime-rail"}
for index, text in ipairs({"allocate", "borrow", "move", "release"}) do
    local x = -300 + (index - 1) * 200
    scene:point {point = {x, -145}, radius = 5, fill = "muted", layer = LAYER.body, id = "lifetime:" .. text .. ":mark"}
    scene:text {text = text, point = {x, -170}, role = "code", fill = "muted", layer = LAYER.text, id = "lifetime:" .. text .. ":label"}
end

local status, version = nil, 0
local function setStatus(text, color)
    version = version + 1
    local nextStatus = scene:text {text = text, point = {0, -215}, role = "code", fill = color or "focus", layer = LAYER.text, id = "status:" .. version}
    if status then scene:fade_transform(status, nextStatus, 0.16, "gentle") else scene:fade_in(nextStatus, {duration = 0.22, curve = "gentle"}) end
    status = nextStatus
end
scene:fade_in(title, {shift = {0, -6}, duration = 0.42, curve = "gentle"}); scene:fade_in(subtitle, {duration = 0.32, curve = "gentle"}); scene:create(rail, 0.30, "ease_out")
setStatus("allocate file@F0 · storage exists before ownership")
scene:play({{target = resourceBody, opacity = 1}, {target = resourceAddress, opacity = 1}, {target = resourceState, opacity = 1}}, 0.36, "ease_out", 0)
setStatus("a owns the only release responsibility")
scene:play({{target = routeA, opacity = 1}, {target = ownerBody.a, stroke = "focus"}}, 0.36, "ease_out", 0)
setStatus("view borrows file@F0 · it does not become an owner")
scene:play({{target = routeBorrow, opacity = 1}, {target = borrowBody, stroke = "info"}}, 0.36, "ease_out", 0)
setStatus("preview move a → b · resource identity stays file@F0")
scene:play({{target = routeBPreview, opacity = 1}}, 0.30, "ease_out", 0)
setStatus("commit move · a becomes empty, b owns release")
scene:play({{target = routeBPreview, opacity = 0}, {target = routeA, opacity = 0}, {target = routeB, opacity = 1}, {target = ownerBody.a, opacity = 0.35, stroke = "muted"}, {target = ownerBody.b, stroke = "focus"}}, 0.48, "ease_in_out", 0)
setStatus("borrow ends before destruction")
scene:play({{target = routeBorrow, opacity = 0}, {target = borrowBody, opacity = 0.35, stroke = "muted"}}, 0.32, "ease_in_out", 0)
setStatus("b releases file@F0 exactly once", "result")
local closed = scene:text {text = "CLOSED", point = {275, -15}, role = "h3", fill = "result", layer = LAYER.text, id = "resource:file:state:closed"}
scene:fade_transform(resourceState, closed, 0.22, "gentle")
scene:play({{target = routeB, opacity = 0}, {target = ownerBody.b, opacity = 0.35, stroke = "muted"}, {target = resourceBody, stroke = "result"}}, 0.38, "ease_in_out", 0)
local result = scene:text {text = "lifetime ends after the last valid borrow and the unique release", point = {0, -238}, role = "text", fill = "result", layer = LAYER.text, id = "result:lifetime"}
scene:fade_transform(status, result, 0.22, "gentle"); scene:wait(2.4)
return scene
