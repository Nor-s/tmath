-- Reference study: derive one TBN frame from a triangle's positions and UVs,
-- then transform a tangent-space normal into world space on the actual mesh.
local page=tmath.scene {width=960,height=540,fps=30,loop=false,theme="adaptive_vscode",camera={mode="fixed",view="2d",target={0,0},height=6}}
local function add(a,b)return{a[1]+b[1],a[2]+b[2],a[3]+b[3]}end
local function sub(a,b)return{a[1]-b[1],a[2]-b[2],a[3]-b[3]}end
local function scale(v,s)return{v[1]*s,v[2]*s,v[3]*s}end
local function dot(a,b)return a[1]*b[1]+a[2]*b[2]+a[3]*b[3]end
local function cross(a,b)return{a[2]*b[3]-a[3]*b[2],a[3]*b[1]-a[1]*b[3],a[1]*b[2]-a[2]*b[1]}end
local function normalize(v)local n=math.sqrt(dot(v,v));assert(n>1e-9,"zero vector");return scale(v,1/n)end
local p0,p1,p2={-1.35,-0.72,-0.80},{1.25,-0.42,-0.92},{-1.05,0.82,1.08}
local p3=add(p1,sub(p2,p0)); local e1,e2=sub(p1,p0),sub(p2,p0)
local T=normalize(e1); local B=normalize(sub(e2,scale(T,dot(T,e2)))); local N=normalize(cross(T,B))
assert(math.abs(dot(T,B))<1e-9 and math.abs(dot(T,N))<1e-9 and math.abs(dot(B,N))<1e-9,"TBN must be orthogonal")
local sample=scale(add(add(p0,p1),p2),1/3)
local tangentNormal=normalize({0.42,-0.28,0.86})
local worldNormal=normalize(add(add(scale(T,tangentNormal[1]),scale(B,tangentNormal[2])),scale(N,tangentNormal[3])))

local spatial=tmath.scene {width=620,height=410,fps=30,loop=false,theme="adaptive_vscode",camera={mode="fixed",view="3d",eye={4.6,3.3,5.7},target={0,0.25,0},up={0,1,0},projection="perspective",fov=0.62,near=0.1,far=30}}
local space=spatial:space {x={-2.5,2.5,1},y={-1.8,2.2,1},z={-2.3,2.3,1},opacity=0.13,id="tbn:space"}
local mesh={space:polygon {points={p0,p1,p2},fill="#4fc1ff40",stroke="accent",width=2,id="tbn:face:0"},space:polygon {points={p1,p3,p2},fill="#8b5cf638",stroke="accent",width=2,id="tbn:face:1"}}
local samplePoint=space:point {point=sample,radius=8,fill="result",stroke="background",width=1.4,layer=10,id="tbn:sample"}
local vectors={
space:vector {origin=sample,value=scale(T,1.25),color="accent",width=4,tip=12,layer=12,id="tbn:T"},
space:vector {origin=sample,value=scale(B,1.25),color="focus",width=4,tip=12,layer=12,id="tbn:B"},
space:vector {origin=sample,value=scale(N,1.25),color="warning",width=4,tip=12,layer=12,id="tbn:N"},
}
local labels={space:text {text="T",point=add(sample,scale(T,1.48)),role="code",fill="accent",layer=20,id="tbn:T-label"},space:text {text="B",point=add(sample,scale(B,1.48)),role="code",fill="focus",layer=20,id="tbn:B-label"},space:text {text="N",point=add(sample,scale(N,1.48)),role="code",fill="warning",layer=20,id="tbn:N-label"}}
local mapped=space:vector {origin=sample,value=scale(worldNormal,1.65),color="result",width=5,tip=14,layer=14,id="tbn:mapped-normal"}
local mappedLabel=space:text {text="TBN · nₜ",point=add(sample,scale(worldNormal,1.90)),role="code",fill="result",layer=20,id="tbn:mapped-label"}
spatial:create(space,0.28,"ease_out");spatial:draw_border_then_fill(mesh,0.62,"ease_out",0.06);spatial:create(samplePoint,0.24,"ease_out");spatial:wait(0.42)
spatial:create(vectors,0.62,"ease_out",0.10);for _,v in ipairs(labels)do spatial:fade_in(v,{duration=0.13,curve="gentle"})end;local frameReady=spatial:duration();spatial:wait(0.44);spatial:create(mapped,0.66,"ease_out");spatial:fade_in(mappedLabel,{duration=0.22,curve="gentle"});local mappedReady=spatial:duration();spatial:wait(2.0);local spatialEnd=spatial:duration()

local uv=tmath.scene {width=336,height=405,fps=30,loop=false,theme="adaptive_vscode",camera={mode="fixed",view="2d",target={0,0},height=7.4}}
local square=uv:rectangle {center={0,1.55},size={4.2,2.55},fill="#4fc1ff14",stroke="border",width=1.5,id="tbn:uv-square"}
local diag=uv:line {from={-2.1,0.28},to={2.1,2.82},color="accent",width=2,id="tbn:uv-diagonal"}
local uvPoint=uv:point {point={-0.62,1.23},radius=7,fill="result",id="tbn:uv-sample"}
local text={uv:text {text="UV DOMAIN",point={0,3.18},role="h3",fill="foreground",id="tbn:uv-title"},uv:text {text="uv0=(0,0)    uv1=(1,0)\nuv2=(0,1)    uv3=(1,1)",point={0,0.02},role="code",size=10.5,fill="muted",id="tbn:uv-values"},uv:text {text=string.format("nₜ = (%.2f, %.2f, %.2f)",tangentNormal[1],tangentNormal[2],tangentNormal[3]),point={0,-1.12},role="code",fill="focus",id="tbn:tangent-normal"},uv:text {text="nʷ = normalize(T nx + B ny + N nz)",point={0,-1.82},role="code",size=11,fill="result",id="tbn:formula"},uv:text {text=string.format("nʷ = (%.2f, %.2f, %.2f)",worldNormal[1],worldNormal[2],worldNormal[3]),point={0,-2.52},role="code",fill="result",id="tbn:world-normal"}}
uv:create(square,0.34,"ease_out");uv:create(diag,0.28,"ease_out");uv:create(uvPoint,0.22,"ease_out");uv:fade_in(text[1],{duration=0.24,curve="gentle"});uv:fade_in(text[2],{duration=0.28,curve="gentle"});local function waitUntil(scene,t)local d=t-scene:duration();if d>0 then scene:wait(d)end end;waitUntil(uv,frameReady);uv:fade_in(text[3],{duration=0.28,curve="gentle"});waitUntil(uv,mappedReady-0.50);uv:fade_in(text[4],{duration=0.26,curve="gentle"});uv:fade_in(text[5],{duration=0.28,curve="gentle"});waitUntil(uv,spatialEnd)
local title=page:text {text="UV coordinates → tangent space → world normal",point={0,2.65},role="h2",fill="foreground",id="tbn:title"};local subtitle=page:text {text="one mesh sample keeps the same identity across texture and world space",point={0,2.25},role="text",fill="muted",id="tbn:subtitle"};page:fade_in(title,{shift={0,-0.08},duration=0.38,curve="gentle"});page:fade_in(subtitle,{duration=0.28,curve="gentle"});page:viewport(spatial,{x=0.015,y=0.23,width=0.613,height=0.72});page:viewport(uv,{x=0.638,y=0.23,width=0.336,height=0.72});return page
