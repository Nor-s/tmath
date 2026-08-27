-- Reference study: two-bone linear blend skinning on an explicit ribbon mesh.
-- Column-vector convention: p' = sum_i w_i * (G_i * B_i^-1) * p.
local page = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6},
}

local function add(a, b) return {a[1] + b[1], a[2] + b[2], a[3] + b[3]} end
local function sub(a, b) return {a[1] - b[1], a[2] - b[2], a[3] - b[3]} end
local function scale(v, s) return {v[1] * s, v[2] * s, v[3] * s} end
local function dot(a, b) return a[1]*b[1] + a[2]*b[2] + a[3]*b[3] end
local function cross(a, b)
    return {a[2]*b[3]-a[3]*b[2], a[3]*b[1]-a[1]*b[3], a[1]*b[2]-a[2]*b[1]}
end
local function normalize(v)
    local n = math.sqrt(dot(v, v)); assert(n > 1e-9, "zero vector")
    return scale(v, 1 / n)
end
local function rotateZ(p, angle)
    local c, s = math.cos(angle), math.sin(angle)
    return {c*p[1]-s*p[2], s*p[1]+c*p[2], p[3]}
end
local function rotateAround(p, pivot, angle) return add(pivot, rotateZ(sub(p, pivot), angle)) end
local function frameFromX(origin, direction)
    local x = normalize(direction)
    local helper = math.abs(x[2]) > 0.92 and {0, 0, 1} or {0, 1, 0}
    local z = normalize(cross(x, helper)); local y = cross(z, x)
    return {x[1],y[1],z[1],origin[1], x[2],y[2],z[2],origin[2], x[3],y[3],z[3],origin[3], 0,0,0,1}
end

local root, bindJoint = {-1.45, 0, 0}, {0.35, 0, 0}
local a0, a1 = math.rad(24), math.rad(-54)
local posedJoint = rotateAround(bindJoint, root, a0)
local function bone0(p) return rotateAround(p, root, a0) end
local function bone1(p)
    local localPoint = sub(p, bindJoint)
    return add(posedJoint, rotateZ(localPoint, a0 + a1))
end
local function weights(x)
    local w1 = math.max(0, math.min(1, (x + 0.05) / 0.90))
    return 1 - w1, w1
end
local function skin(p)
    local w0, w1 = weights(p[1])
    return add(scale(bone0(p), w0), scale(bone1(p), w1)), w0, w1
end

local columns, bindVertices, posedVertices = 9, {}, {}
for i = 0, columns - 1 do
    local x = -1.45 + 3.60 * i / (columns - 1)
    local z = 0.10 * math.sin(i * 0.9)
    bindVertices[#bindVertices + 1] = {x, -0.34, z}
    bindVertices[#bindVertices + 1] = {x, 0.34, z}
end
for i, p in ipairs(bindVertices) do posedVertices[i] = skin(p) end
local selectedIndex = 9
local selectedBind, selectedPose = bindVertices[selectedIndex], posedVertices[selectedIndex]
local selectedW0, selectedW1 = weights(selectedBind[1])
assert(math.abs(selectedW0 + selectedW1 - 1) < 1e-9, "skin weights must sum to one")

local spatial = tmath.scene {
    width = 620, height = 410, fps = 30, loop = false, theme = "adaptive_vscode",
    camera = {mode="fixed", view="3d", eye={4.7,3.25,6.4}, target={0.35,0.25,0}, up={0,1,0}, projection="perspective", fov=0.62, near=0.1, far=30},
}
local space = spatial:space {x={-2.4,3.0,1}, y={-2.0,2.6,1}, z={-2.0,2.0,1}, opacity=0.13, id="lbs:space"}
local mesh = space:group {id="lbs:mesh"}
local bindFaces = {}
for i = 1, columns - 1 do
    bindFaces[i] = mesh:polygon {
        points={bindVertices[2*i-1],bindVertices[2*i+1],bindVertices[2*i+2],bindVertices[2*i]},
        fill=i % 2 == 0 and "#4fc1ff3d" or "#8b5cf63d", stroke="accent", width=1.4,
        id="lbs:bind-face:" .. i,
    }
end
local bindPoints = {}
for i, p in ipairs(bindVertices) do
    local w0, w1 = weights(p[1])
    bindPoints[i] = mesh:point {point=p, radius=4, fill=w1 > w0 and "focus" or "accent", layer=10, id="lbs:vertex:" .. i}
end

local function bipyramid(parent, id, origin, endpoint, fill)
    local d = sub(endpoint, origin); local length = math.sqrt(dot(d,d)); local owner = parent:group {matrix=frameFromX(origin,d), id=id}
    local waist, radius = length*0.43, 0.16
    local ring={{waist,radius,0},{waist,0,radius},{waist,-radius,0},{waist,0,-radius}}
    local faces={}
    for i=1,4 do local j=i%4+1
        faces[#faces+1]=owner:polygon {points={{0,0,0},ring[i],ring[j]},fill=fill,stroke="foreground",width=1,id=id..":a:"..i}
        faces[#faces+1]=owner:polygon {points={{length,0,0},ring[j],ring[i]},fill=fill,stroke="foreground",width=1,id=id..":b:"..i}
    end
    return owner, faces
end
local bone0Owner, bone0Faces = bipyramid(space,"lbs:bone:0",root,bindJoint,"#4fc1ff72")
local bindEnd = {2.15,0,0}
local bone1Owner, bone1Faces = bipyramid(space,"lbs:bone:1",bindJoint,bindEnd,"#8b5cf672")
local joint0 = space:point {point=root,radius=7,fill="accent",stroke="background",width=1,layer=12,id="lbs:joint:0"}
local joint1 = space:point {point=bindJoint,radius=8,fill="warning",stroke="background",width=1,layer=12,id="lbs:joint:1"}
local joint2 = space:point {point=bindEnd,radius=7,fill="focus",stroke="background",width=1,layer=12,id="lbs:joint:2"}
local selected = mesh:point {point=selectedBind,radius=8,fill="result",stroke="background",width=1.5,layer=14,id="lbs:selected"}
local selectedLabel = mesh:text {text="v*",point=add(selectedBind,{0,0.28,0}),role="code",fill="result",layer=20,id="lbs:selected-label"}

spatial:create(space,0.28,"ease_out")
spatial:draw_border_then_fill(bindFaces,0.62,"ease_out",0.025)
spatial:create(bindPoints,0.34,"ease_out",0.018)
spatial:create(bone0Faces,0.42,"ease_out",0.02)
spatial:create(bone1Faces,0.42,"ease_out",0.02)
spatial:create({joint0,joint1,joint2,selected},0.28,"ease_out",0.04)
spatial:fade_in(selectedLabel,{duration=0.18,curve="gentle"})
spatial:wait(0.60)
local deformStart = spatial:duration()
local posedEnd = bone1(bindEnd)
local changes = {
    {target=bone0Owner,transform=frameFromX(root,sub(posedJoint,root))},
    {target=bone1Owner,transform=frameFromX(posedJoint,sub(posedEnd,posedJoint))},
    {target=joint1,shift=sub(posedJoint,bindJoint)}, {target=joint2,shift=sub(posedEnd,bindEnd)},
    {target=selected,shift=sub(selectedPose,selectedBind)}, {target=selectedLabel,shift=sub(selectedPose,selectedBind)},
}
for i, point in ipairs(bindPoints) do changes[#changes + 1] = {target=point,shift=sub(posedVertices[i],bindVertices[i])} end
spatial:play(changes,1.15,"ease_in_out",0)
local posedFaces = {}
for i = 1, columns - 1 do
    posedFaces[i] = mesh:polygon {
        points={posedVertices[2*i-1],posedVertices[2*i+1],posedVertices[2*i+2],posedVertices[2*i]},
        fill=i % 2 == 0 and "#4fc1ff56" or "#8b5cf656", stroke="result", width=1.5,
        id="lbs:posed-face:" .. i,
    }
end
spatial:morph(bindFaces,posedFaces,1.15,"ease_in_out",0)
local deformEnd = spatial:duration()
spatial:indicate(selected,{scale=1.08,duration=0.38,curve="gentle"})
spatial:wait(2.0)
local spatialEnd = spatial:duration()

local ledger = tmath.scene {width=336,height=405,fps=30,loop=false,theme="adaptive_vscode",camera={mode="fixed",view="2d",target={0,0},height=7.4}}
local copy = {
    ledger:text {text="LBS · TWO BONES",point={-2.72,2.85},align={0,0.5},role="h3",fill="foreground",id="lbs:ledger:title"},
    ledger:text {text="p' = Σ wi · (Gi Bi⁻¹) · p",point={-2.72,2.22},align={0,0.5},role="code",fill="result",id="lbs:ledger:formula"},
    ledger:text {text=string.format("v* bind = (%.2f, %.2f, %.2f)",selectedBind[1],selectedBind[2],selectedBind[3]),point={-2.72,1.35},align={0,0.5},role="code",size=11,fill="muted",id="lbs:ledger:bind"},
    ledger:text {text=string.format("w0 = %.2f    w1 = %.2f",selectedW0,selectedW1),point={-2.72,0.78},align={0,0.5},role="code",fill="warning",id="lbs:ledger:weights"},
    ledger:text {text="invariant: w0 + w1 = 1",point={-2.72,0.20},align={0,0.5},role="code",size=11,fill="foreground",id="lbs:ledger:invariant"},
    ledger:text {text=string.format("v* posed = (%.2f, %.2f, %.2f)",selectedPose[1],selectedPose[2],selectedPose[3]),point={-2.72,-0.75},align={0,0.5},role="code",fill="result",id="lbs:ledger:posed"},
    ledger:text {text="one skeleton pose\nupdates every weighted vertex",point={0,-2.25},role="code",fill="muted",id="lbs:ledger:result"},
}
ledger:fade_in(copy[1],{duration=0.30,curve="gentle"})
ledger:fade_in(copy[2],{duration=0.30,curve="gentle"})
ledger:fade_in(copy[3],{duration=0.25,curve="gentle"})
ledger:fade_in(copy[4],{duration=0.25,curve="gentle"})
ledger:fade_in(copy[5],{duration=0.25,curve="gentle"})
local function waitUntil(scene,t) local d=t-scene:duration(); if d>0 then scene:wait(d) end end
waitUntil(ledger,deformStart)
ledger:fade_in(copy[6],{shift={0.10,0},duration=deformEnd-deformStart,curve="ease_out"})
ledger:fade_in(copy[7],{duration=0.34,curve="gentle"})
waitUntil(ledger,spatialEnd)

local title=page:text {text="Linear blend skinning · bones deform a mesh",point={0,2.65},role="h2",fill="foreground",id="lbs:title"}
local subtitle=page:text {text="bind pose → weighted bone matrices → posed vertices",point={0,2.25},role="text",fill="muted",id="lbs:subtitle"}
page:fade_in(title,{shift={0,-0.08},duration=0.38,curve="gentle"}); page:fade_in(subtitle,{duration=0.28,curve="gentle"})
page:viewport(spatial,{x=0.015,y=0.23,width=0.613,height=0.72}); page:viewport(ledger,{x=0.638,y=0.23,width=0.336,height=0.72})
return page
