-- Reference study: one triangle crosses the near plane, is clipped to a quad,
-- survives winding cull, then competes at one depth sample.
local page=tmath.scene {width=960,height=540,fps=30,loop=false,theme="adaptive_vscode",camera={mode="fixed",view="2d",target={0,0},height=6}}
local function add(a,b)return{a[1]+b[1],a[2]+b[2],a[3]+b[3]}end
local function sub(a,b)return{a[1]-b[1],a[2]-b[2],a[3]-b[3]}end
local function scale(v,s)return{v[1]*s,v[2]*s,v[3]*s}end
local function intersectNear(a,b,nearZ)
    local t=(nearZ-a[3])/(b[3]-a[3]); assert(t>=0 and t<=1,"edge must cross near plane")
    return add(a,scale(sub(b,a),t)),t
end
local nearZ=-1.0
local a,b,c={-1.15,-0.75,-0.48},{1.20,-0.62,-2.55},{0.15,1.05,-2.05}
local ab,tAB=intersectNear(a,b,nearZ); local ac,tAC=intersectNear(a,c,nearZ)
local clipped={ab,b,c,ac}
local sampleDepth,storedDepth,bias=0.63,0.48,0.01
local depthPass=sampleDepth<=storedDepth+bias
assert(#clipped==4 and not depthPass,"fixture must clip to four vertices and fail depth")

local spatial=tmath.scene {width=620,height=410,fps=30,loop=false,theme="adaptive_vscode",camera={mode="fixed",view="3d",eye={5.8,3.7,4.5},target={0,0,-1.5},up={0,1,0},projection="perspective",fov=0.66,near=0.1,far=30}}
local space=spatial:space {x={-3,3,1},y={-2.2,2.2,1},z={-3.5,1.0,1},opacity=0.13,id="clip:space"}
local nearPlane=space:polygon {points={{-2,-1.55,nearZ},{2,-1.55,nearZ},{2,1.55,nearZ},{-2,1.55,nearZ}},fill="#ffd86618",stroke="warning",width=2,id="clip:near-plane"}
local nearLabel=space:text {text="near plane",point={-1.9,1.76,nearZ},align={0,0.5},role="code",fill="warning",layer=20,id="clip:near-label"}
local original=space:polygon {points={a,b,c},fill="#4fc1ff35",stroke="accent",width=2.2,id="clip:original-triangle"}
local points={
    space:point {point=a,radius=7,fill="danger",layer=10,id="clip:v0-outside"},
    space:point {point=b,radius=6,fill="accent",layer=10,id="clip:v1"},
    space:point {point=c,radius=6,fill="accent",layer=10,id="clip:v2"},
}
local cutPoints={space:point {point=ab,radius=7,fill="result",layer=11,id="clip:i-ab"},space:point {point=ac,radius=7,fill="result",layer=11,id="clip:i-ac"}}
local cutLabels={space:text {text="i₀",point=add(ab,{0.12,0.16,0}),role="code",fill="result",layer=20,id="clip:i0-label"},space:text {text="i₁",point=add(ac,{0.12,0.16,0}),role="code",fill="result",layer=20,id="clip:i1-label"}}
spatial:create(space,0.28,"ease_out"); spatial:create(original,0.56,"ease_out"); spatial:create(points,0.28,"ease_out",0.05); spatial:wait(0.42)
spatial:draw_border_then_fill(nearPlane,0.42,"ease_out"); spatial:fade_in(nearLabel,{duration=0.20,curve="gentle"}); spatial:create(cutPoints,0.26,"ease_out",0.05); for _,v in ipairs(cutLabels)do spatial:fade_in(v,{duration=0.12,curve="gentle"})end
local clipReady=spatial:duration(); spatial:fade(original,0.12,0.34,"gentle")
local clippedShape=space:polygon {points=clipped,fill="#8b5cf654",stroke="result",width=2.4,id="clip:clipped-quad"}
spatial:draw_border_then_fill(clippedShape,0.62,"ease_out"); local polygonReady=spatial:duration(); spatial:indicate(clippedShape,{scale=1.02,duration=0.34,curve="gentle"}); spatial:wait(2.0); local spatialEnd=spatial:duration()

local ledger=tmath.scene {width=336,height=405,fps=30,loop=false,theme="adaptive_vscode",camera={mode="fixed",view="2d",target={0,0},height=7.4}}
local items={
ledger:text {text="1  CLIP",point={-2.72,2.92},align={0,0.5},role="h3",fill="accent",id="clip:stage1"},
ledger:text {text=string.format("i₀: t=%.2f   i₁: t=%.2f",tAB,tAC),point={-2.72,2.35},align={0,0.5},role="code",size=11,fill="foreground",id="clip:intersections"},
ledger:text {text="triangle → 4-vertex polygon",point={-2.72,1.87},align={0,0.5},role="code",fill="result",id="clip:polygon-result"},
ledger:text {text="2  CULL",point={-2.72,1.10},align={0,0.5},role="h3",fill="focus",id="clip:stage2"},
ledger:text {text="signed area > 0 → front facing",point={-2.72,0.55},align={0,0.5},role="code",size=11,fill="foreground",id="clip:cull-result"},
ledger:text {text="3  DEPTH",point={-2.72,-0.24},align={0,0.5},role="h3",fill="warning",id="clip:stage3"},
ledger:text {text=string.format("candidate z = %.2f\nstored z = %.2f\nbias = %.2f",sampleDepth,storedDepth,bias),point={-2.72,-1.12},align={0,0.5},role="code",size=11,fill="foreground",id="clip:depth-values"},
ledger:text {text=depthPass and "PASS → write fragment" or "FAIL → hidden by nearer surface",point={0,-2.66},role="code",fill=depthPass and "success" or "danger",id="clip:depth-result"},
}
ledger:fade_in(items[1],{duration=0.25,curve="gentle"}); ledger:fade_in(items[2],{duration=0.30,curve="gentle"})
local function waitUntil(scene,t)local d=t-scene:duration();if d>0 then scene:wait(d)end end
waitUntil(ledger,clipReady-0.25); ledger:fade_in(items[3],{duration=0.25,curve="gentle"}); waitUntil(ledger,polygonReady-0.55)
for i=4,8 do ledger:fade_in(items[i],{duration=i==8 and 0.36 or 0.24,curve="gentle"}) end
waitUntil(ledger,spatialEnd)
local title=page:text {text="Clip → Cull → Depth",point={0,2.65},role="h2",fill="foreground",id="clip:title"}
local subtitle=page:text {text="geometry is clipped first; visibility decisions follow",point={0,2.25},role="text",fill="muted",id="clip:subtitle"}
page:fade_in(title,{shift={0,-0.08},duration=0.38,curve="gentle"});page:fade_in(subtitle,{duration=0.28,curve="gentle"});page:viewport(spatial,{x=0.015,y=0.23,width=0.613,height=0.72});page:viewport(ledger,{x=0.638,y=0.23,width=0.336,height=0.72});return page
