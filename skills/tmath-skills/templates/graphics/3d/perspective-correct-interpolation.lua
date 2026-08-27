-- Reference study: a screen-space barycentric sample is reconstructed on a
-- depth-varying 3D triangle with lambda_i / w_i normalization.
local page=tmath.scene {width=960,height=540,fps=30,loop=false,theme="adaptive_vscode",camera={mode="fixed",view="2d",target={0,0},height=6}}
local function add(a,b)return{a[1]+b[1],a[2]+b[2],a[3]+b[3]}end
local function scale(v,s)return{v[1]*s,v[2]*s,v[3]*s}end
local p={{-1.20,-0.82,-2.0},{1.35,-0.72,-5.2},{0.05,1.15,-3.0}}
local attr={0.0,1.0,0.35};local lambda={0.25,0.35,0.40};local w={-p[1][3],-p[2][3],-p[3][3]}
local denom=lambda[1]/w[1]+lambda[2]/w[2]+lambda[3]/w[3]
local corrected={lambda[1]/w[1]/denom,lambda[2]/w[2]/denom,lambda[3]/w[3]/denom}
local affine=lambda[1]*attr[1]+lambda[2]*attr[2]+lambda[3]*attr[3]
local perspective=corrected[1]*attr[1]+corrected[2]*attr[2]+corrected[3]*attr[3]
local hit={0,0,0};for i=1,3 do hit=add(hit,scale(p[i],corrected[i]))end
assert(math.abs(corrected[1]+corrected[2]+corrected[3]-1)<1e-9,"corrected weights must normalize")

local spatial=tmath.scene {width=584,height=405,fps=30,loop=false,theme="adaptive_vscode",camera={mode="fixed",view="3d",eye={4.8,3.4,5.4},target={0,0,-2.6},up={0,1,0},projection="perspective",fov=0.60,near=0.1,far=30}}
local space=spatial:space {x={-2.5,2.5,1},y={-2.0,2.2,1},z={-6.0,1.0,1},opacity=0.13,id="persp:space"}
local triangle=space:polygon {points=p,fill="#4fc1ff3b",stroke="accent",width=2.2,id="persp:triangle"}
local vertices={};for i=1,3 do vertices[i]=space:point {point=p[i],radius=7,fill=i==2 and "focus" or "accent",layer=10,id="persp:v"..(i-1)} end
local labels={};for i=1,3 do labels[i]=space:text {text=string.format("v%d · u=%.2f · w=%.1f",i-1,attr[i],w[i]),point=add(p[i],{0,0.22,0}),role="code",size=10.5,fill=i==2 and "focus" or "foreground",layer=20,id="persp:v-label:"..i} end
local ray=space:line {from={0,0,0},to=hit,color="result",width=4,layer=8,id="persp:view-ray"};local hitPoint=space:point {point=hit,radius=9,fill="result",stroke="background",width=1.4,layer=12,id="persp:hit"};local hitLabel=space:text {text="screen sample → surface hit",point=add(hit,{0.12,0.30,0}),align={0,0.5},role="code",fill="result",layer=20,id="persp:hit-label"}
spatial:create(space,0.28,"ease_out");spatial:draw_border_then_fill(triangle,0.58,"ease_out");spatial:create(vertices,0.28,"ease_out",0.05);for _,v in ipairs(labels)do spatial:fade_in(v,{duration=0.13,curve="gentle"})end;spatial:wait(0.55);spatial:create(ray,0.72,"linear");spatial:create(hitPoint,0.24,"ease_out");spatial:fade_in(hitLabel,{duration=0.24,curve="gentle"});local hitReady=spatial:duration();spatial:wait(2.2);local spatialEnd=spatial:duration()

local screen=tmath.scene {width=366,height=405,fps=30,loop=false,theme="adaptive_vscode",camera={mode="fixed",view="2d",target={0,0},height=7.4}}
local function project(q)return{q[1]/-q[3]*3.2,q[2]/-q[3]*3.2+1.55}end
local sp={project(p[1]),project(p[2]),project(p[3])};local sample={0,0};for i=1,3 do sample[1]=sample[1]+lambda[i]*sp[i][1];sample[2]=sample[2]+lambda[i]*sp[i][2]end
local tri=screen:polygon {points=sp,fill="#4fc1ff20",stroke="accent",width=2,id="persp:screen-triangle"};local sdot=screen:point {point=sample,radius=8,fill="result",id="persp:screen-sample"}
local items={screen:text {text="SCREEN BARYCENTRICS",point={0,3.20},role="h3",fill="foreground",id="persp:screen-title"},screen:text {text="λ = (0.25, 0.35, 0.40)",point={0,0.52},role="code",fill="accent",id="persp:lambda"},screen:text {text=string.format("affine u = %.3f",affine),point={-2.65,-0.40},align={0,0.5},role="code",fill="danger",id="persp:affine"},screen:text {text="λᵢ' = (λᵢ / wᵢ) / Σ(λⱼ / wⱼ)",point={-2.65,-1.16},align={0,0.5},role="code",size=10.5,fill="warning",id="persp:formula"},screen:text {text=string.format("perspective-correct u = %.3f",perspective),point={-2.65,-1.90},align={0,0.5},role="code",fill="result",id="persp:correct"},screen:text {text="same pixel · different reconstructed attribute",point={0,-2.78},role="code",size=11,fill="muted",id="persp:result"}}
screen:create(tri,0.42,"ease_out");screen:create(sdot,0.22,"ease_out");screen:fade_in(items[1],{duration=0.25,curve="gentle"});screen:fade_in(items[2],{duration=0.25,curve="gentle"});screen:fade_in(items[3],{duration=0.28,curve="gentle"});local function waitUntil(scene,t)local d=t-scene:duration();if d>0 then scene:wait(d)end end;waitUntil(screen,hitReady-0.75);screen:fade_in(items[4],{duration=0.30,curve="gentle"});screen:fade_in(items[5],{duration=0.32,curve="gentle"});screen:fade_in(items[6],{duration=0.28,curve="gentle"});waitUntil(screen,spatialEnd)
local title=page:text {text="Perspective-correct interpolation",point={0,2.65},role="h2",fill="foreground",id="persp:title"};local subtitle=page:text {text="screen weights must be divided by clip w before attributes are reconstructed",point={0,2.25},role="text",fill="muted",id="persp:subtitle"};page:fade_in(title,{shift={0,-0.08},duration=0.38,curve="gentle"});page:fade_in(subtitle,{duration=0.28,curve="gentle"});page:viewport(spatial,{x=0.015,y=0.23,width=0.584,height=0.72});page:viewport(screen,{x=0.609,y=0.23,width=0.366,height=0.72});return page
