-- Question: when two references alias one object, which state changes and which identity stays fixed?
-- Variant: a and b initially point to object@A; b is then rebound to object@B.
-- Addresses are explicitly illustrative, while object and reference identities are stable.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local LAYER = {route = 10, body = 20, text = 40, preview = 50}
local TRACE = {
    {kind = "allocate", object = "A", value = 10},
    {kind = "bind", reference = "a", to = "A"},
    {kind = "bind", reference = "b", to = "A"},
    {kind = "write", through = "a", object = "A", old = 10, new = 42},
    {kind = "allocate", object = "B", value = 7},
    {kind = "rebind", reference = "b", old = "A", new = "B"},
    {kind = "write", through = "b", object = "B", old = 7, new = 9},
}
local state = {objects = {}, refs = {}}
for _, event in ipairs(TRACE) do
    if event.kind == "allocate" then assert(not state.objects[event.object]); state.objects[event.object] = event.value
    elseif event.kind == "bind" then assert(state.objects[event.to]); state.refs[event.reference] = event.to
    elseif event.kind == "rebind" then assert(state.refs[event.reference] == event.old); state.refs[event.reference] = event.new
    elseif event.kind == "write" then
        assert(state.refs[event.through] == event.object and state.objects[event.object] == event.old)
        state.objects[event.object] = event.new
    end
end
assert(state.refs.a == "A" and state.refs.b == "B" and state.objects.A == 42 and state.objects.B == 9)

local title = scene:text {
    text = "Memory aliasing · references share objects",
    point = {0, 230}, role = "h2", fill = "foreground",
    layer = LAYER.text, id = "scene-title",
}
local subtitle = scene:text {
    text = "illustrative addresses · mutation follows an edge · rebinding replaces an edge",
    point = {0, 194}, role = "code", fill = "muted",
    layer = LAYER.text, id = "scene-subtitle",
}
local refsLabel = scene:text {
    text = "REFERENCES", point = {-285, 142}, role = "code", fill = "accent",
    layer = LAYER.text, id = "references-label",
}
local heapLabel = scene:text {
    text = "HEAP OBJECTS", point = {235, 142}, role = "code", fill = "accent",
    layer = LAYER.text, id = "heap-label",
}

local refBodies, refText = {}, {}
for index, name in ipairs({"a", "b"}) do
    local y = 70 - (index - 1) * 130
    refBodies[name] = scene:rectangle {
        center = {-285, y}, size = {170, 76}, corner = 7,
        fill = "surface", stroke = "border", width = 2,
        layer = LAYER.body, id = "reference:" .. name .. ":body",
    }
    refText[name] = scene:text {
        text = "ref " .. name, point = {-285, y}, role = "code", fill = "foreground",
        layer = LAYER.text, id = "reference:" .. name .. ":label",
    }
end

local objectSpec = {A = {x = 235, y = 70, address = "0xA0"}, B = {x = 235, y = -60, address = "0xB0"}}
local objectBodies, objectValue, objectAddress = {}, {}, {}
for _, id in ipairs({"A", "B"}) do
    local spec = objectSpec[id]
    objectBodies[id] = scene:rectangle {
        center = {spec.x, spec.y}, size = {250, 92}, corner = 8,
        fill = "surface", stroke = "border", width = 2, opacity = 0,
        layer = LAYER.body, id = "object:" .. id .. ":body",
    }
    objectAddress[id] = scene:text {
        text = spec.address .. " (illustrative)", point = {spec.x, spec.y + 23},
        role = "code", fill = "muted", opacity = 0,
        layer = LAYER.text, id = "object:" .. id .. ":address",
    }
    objectValue[id] = scene:text {
        text = "value = " .. (id == "A" and 10 or 7), point = {spec.x, spec.y - 15},
        role = "code", fill = "foreground", opacity = 0,
        layer = LAYER.text, id = "object:" .. id .. ":value:0",
    }
end

local routes = {
    aA = scene:arrow {from = {-200, 70}, to = {105, 70}, tip = 12, stroke = "foreground", width = 3, opacity = 0, layer = LAYER.route, id = "reference:a:to-A"},
    bA = scene:route {points = {{-200, -60}, {-80, -60}, {-80, 35}, {105, 35}}, tip = 12, stroke = "foreground", width = 3, opacity = 0, layer = LAYER.route, id = "reference:b:to-A"},
    bB = scene:arrow {from = {-200, -60}, to = {105, -60}, tip = 12, stroke = "foreground", width = 3, opacity = 0, layer = LAYER.route, id = "reference:b:to-B"},
    bBPreview = scene:arrow {from = {-200, -60}, to = {105, -60}, tip = 12, dash = {8, 6}, stroke = "focus", width = 3, opacity = 0, layer = LAYER.preview, id = "preview:reference:b:to-B"},
}

local status, version = nil, 0
local function setStatus(text, color)
    version = version + 1
    local nextStatus = scene:text {text = text, point = {0, -170}, role = "code", fill = color or "focus", layer = LAYER.text, id = "status:" .. version}
    if status then scene:fade_transform(status, nextStatus, 0.17, "gentle") else scene:fade_in(nextStatus, {duration = 0.24, curve = "gentle"}) end
    status = nextStatus
end
local valueVersion = {A = 0, B = 0}
local function replaceValue(id, value, color)
    valueVersion[id] = valueVersion[id] + 1
    local spec = objectSpec[id]
    local nextValue = scene:text {
        text = "value = " .. value, point = {spec.x, spec.y - 15}, role = "code",
        fill = color or "foreground", layer = LAYER.text,
        id = "object:" .. id .. ":value:" .. valueVersion[id],
    }
    scene:fade_transform(objectValue[id], nextValue, 0.22, "gentle")
    objectValue[id] = nextValue
end

scene:fade_in(title, {shift = {0, -6}, duration = 0.42, curve = "gentle"})
scene:fade_in(subtitle, {shift = {0, -5}, duration = 0.34, curve = "gentle"})
scene:fade_in(refsLabel, {duration = 0.24, curve = "gentle"})
scene:fade_in(heapLabel, {duration = 0.24, curve = "gentle"})
scene:fade_in(refBodies.a, {duration = 0.26, curve = "gentle"}); scene:fade_in(refText.a, {duration = 0.20, curve = "gentle"})
scene:fade_in(refBodies.b, {duration = 0.26, curve = "gentle"}); scene:fade_in(refText.b, {duration = 0.20, curve = "gentle"})

setStatus("allocate object A before any reference reaches it")
scene:play({{target = objectBodies.A, opacity = 1}, {target = objectAddress.A, opacity = 1}, {target = objectValue.A, opacity = 1}}, 0.36, "ease_out", 0)
setStatus("bind a → A")
scene:play({{target = routes.aA, opacity = 1}}, 0.34, "ease_out", 0)
setStatus("bind b → A · two references, one object")
scene:play({{target = routes.bA, opacity = 1}}, 0.42, "ease_out", 0)
scene:play({{target = objectBodies.A, fill = "focus", stroke = "focus"}}, 0.28, "ease_in_out", 0)

setStatus("a.value = 42 mutates A · b observes the same state", "success")
replaceValue("A", 42, "result")
scene:play({{target = objectBodies.A, fill = "surface", stroke = "result"}}, 0.28, "ease_in_out", 0)

setStatus("allocate object B independently")
scene:play({{target = objectBodies.B, opacity = 1}, {target = objectAddress.B, opacity = 1}, {target = objectValue.B, opacity = 1}}, 0.36, "ease_out", 0)
setStatus("preview rebind b: A → B · object A is unchanged")
scene:play({{target = routes.bBPreview, opacity = 1}}, 0.32, "ease_out", 0)
setStatus("commit rebind · replace only b's relation")
scene:play({{target = routes.bBPreview, opacity = 0}, {target = routes.bA, opacity = 0.18}, {target = routes.bB, opacity = 1}}, 0.48, "ease_in_out", 0)
scene:fade_out(routes.bA, {duration = 0.18, curve = "gentle"})

setStatus("b.value = 9 mutates B · a still reaches A=42", "success")
replaceValue("B", 9, "result")
scene:play({{target = objectBodies.B, stroke = "result"}}, 0.28, "ease_in_out", 0)
local result = scene:text {
    text = "final: a → A(value 42) · b → B(value 9) · rebinding is not mutation",
    point = {0, -220}, role = "text", fill = "result",
    layer = LAYER.text, id = "result:aliasing",
}
scene:fade_transform(status, result, 0.24, "gentle")
scene:wait(2.4)
return scene
