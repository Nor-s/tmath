import { BRAND_EXAMPLE } from "./catalog_brand.js";

const PRETENDARD = [{ name: "Pretendard", url: "./Pretendard.ttf", mime: "ttf" }];

const THEME_SHOWCASE_LUA = `local function custom_theme(gradient)
    return {preset="3_blue_1_eyes",background="#171225",text={
        h1={font="Pretendard",size=38,color="#f8fafc"},h2={font="Pretendard",size=29,color="#c4b5fd"},
        h3={font="Pretendard",size=22,color="#67e8f9"},text={font="Pretendard",size=16,color="#d8cff0"},
        code={font="Pretendard",size=15,color="#fbbf24"}},
        objects={"#8b5cf6","#22d3ee","#f472b6","#fbbf24","#34d399","#60a5fa"},
        object_width=3,gradient=gradient,end_gradient_stop="#fb7185",
        axis={x="#f472b6",y="#34d399",z="#60a5fa",grid="#493f63",label="#bdb4d7"}}
end
local custom=custom_theme(false)
local custom_gradient=custom_theme(true)
local gradient_three_blue_one_eyes={preset="3_blue_1_eyes",gradient=true}
local gradient_pro_white={preset="pro_white",gradient=true}
local gradient_pro_black={preset="pro_black",gradient=true}
local function translation(x,y)
    return {1,0,0,x,0,1,0,y,0,0,1,0,0,0,0,1}
end
local function vector_to_point(origin,target,clearance)
    local dx,dy=target[1]-origin[1],target[2]-origin[2]
    local length=math.sqrt(dx*dx+dy*dy)
    local scale=(length-clearance)/length
    return {dx*scale,dy*scale}
end
local function panel(theme,name)
    local scene=tmath.scene {width=480,height=500,fps=30,loop=false,theme=theme,
        camera={mode="fixed",view="2d",target={0,0},height=10}}
    local content=scene:group {id="content"}
    local typography=content:group {id="typography"}
    typography:text {text=name,point={-3.45,4.20},align={0,.5},role="h1",id="title"}
    typography:text {text="VISUAL SYSTEM",point={-3.35,3.40},align={0,.5},role="h2",id="heading"}
    typography:text {text="Semantic typography",point={-3.35,2.70},align={0,.5},role="h3",id="subheading"}
    typography:text {text="Text · labels · annotations",point={-3.35,2.02},align={0,.5},role="text",id="body"}
    typography:text {text="f(x) = sin(x) + 1",point={-3.35,1.45},align={0,.5},role="code",id="formula"}
    local space=content:space {x={-3,3,1},y={-1.5,1.5,.75},z={0,0,1},
        matrix=translation(0,-1.55),numbers=true,number_size=11,id="space"}
    local vectorOrigin,pointPosition={-.55,.10},{.70,.92}
    local vector=space:vector {origin=vectorOrigin,
        value=vector_to_point(vectorOrigin,pointPosition,.34),tip=13,id="vector"}
    local shapes=space:group {id="shapes"}
    shapes:point {point=pointPosition,radius=6,id="point"}
    shapes:circle {center={-2.30,.72},radius=.34,id="circle"}
    shapes:rectangle {center={-1.45,-.72},size={.72,.56},corner=.08,id="rectangle"}
    shapes:polygon {points={{-.45,-1.02},{.12,-.38},{.72,-1.02}},id="polygon"}
    local curve=space:curve {from={1.15,.52},control1={1.48,1.25},control2={2.18,1.25},
        to={2.52,.52},id="curve"}
    shapes:surface {points={{1.42,-1.02},{2.62,-1.02},{1.42,-.42},{2.62,-.42}},
        size={2,2},mode="solid",shading=false,id="filled-shape"}
    scene:fade_in(content,{shift={0,.16},scale=.985,duration=.62,curve="gentle"})
    scene:wait(.55)
    return scene
end
local page=tmath.scene {width=1920,height=1000,fps=30,loop=false,background="#111827"}
page:viewport(panel("3_blue_1_eyes","3 BLUE 1 EYES"),{x=0,y=0,width=.25,height=.5})
page:viewport(panel("pro_white","PRO WHITE"),{x=.25,y=0,width=.25,height=.5})
page:viewport(panel("pro_black","PRO BLACK"),{x=.5,y=0,width=.25,height=.5})
page:viewport(panel(custom,"CUSTOM"),{x=.75,y=0,width=.25,height=.5})
page:viewport(panel(gradient_three_blue_one_eyes,"3 BLUE 1 EYES · GRAD"),{x=0,y=.5,width=.25,height=.5})
page:viewport(panel(gradient_pro_white,"PRO WHITE · GRAD"),{x=.25,y=.5,width=.25,height=.5})
page:viewport(panel(gradient_pro_black,"PRO BLACK · GRAD"),{x=.5,y=.5,width=.25,height=.5})
page:viewport(panel(custom_gradient,"CUSTOM · GRAD"),{x=.75,y=.5,width=.25,height=.5})
return page
`;

const THEME_SHOWCASE_JS = `const customTheme=(gradient)=>({preset:"3_blue_1_eyes",background:"#171225",text:{
    h1:{font:"Pretendard",size:38,color:"#f8fafc"},h2:{font:"Pretendard",size:29,color:"#c4b5fd"},
    h3:{font:"Pretendard",size:22,color:"#67e8f9"},text:{font:"Pretendard",size:16,color:"#d8cff0"},
    code:{font:"Pretendard",size:15,color:"#fbbf24"}},
    objects:["#8b5cf6","#22d3ee","#f472b6","#fbbf24","#34d399","#60a5fa"],
    object_width:3,gradient,end_gradient_stop:"#fb7185",
    axis:{x:"#f472b6",y:"#34d399",z:"#60a5fa",grid:"#493f63",label:"#bdb4d7"}});
const custom=customTheme(false),customGradient=customTheme(true);
const gradientThreeBlueOneEyes={preset:"3_blue_1_eyes",gradient:true};
const gradientProWhite={preset:"pro_white",gradient:true};
const gradientProBlack={preset:"pro_black",gradient:true};
const translation=(x,y)=>[1,0,0,x,0,1,0,y,0,0,1,0,0,0,0,1];
const vectorToPoint=(origin,target,clearance)=>{
    const dx=target[0]-origin[0],dy=target[1]-origin[1];
    const length=Math.hypot(dx,dy),scale=(length-clearance)/length;
    return [dx*scale,dy*scale];
};
const panel=(theme,name)=>{
    const scene=tmath.scene({width:480,height:500,fps:30,loop:false,theme,
        camera:{mode:"fixed",view:"2d",target:[0,0],height:10}});
    const content=scene.group({id:"content"});
    const typography=content.group({id:"typography"});
    typography.text({text:name,point:[-3.45,4.20],align:[0,.5],role:"h1",id:"title"});
    typography.text({text:"VISUAL SYSTEM",point:[-3.35,3.40],align:[0,.5],role:"h2",id:"heading"});
    typography.text({text:"Semantic typography",point:[-3.35,2.70],align:[0,.5],role:"h3",id:"subheading"});
    typography.text({text:"Text · labels · annotations",point:[-3.35,2.02],align:[0,.5],role:"text",id:"body"});
    typography.text({text:"f(x) = sin(x) + 1",point:[-3.35,1.45],align:[0,.5],role:"code",id:"formula"});
    const space=content.space({x:[-3,3,1],y:[-1.5,1.5,.75],z:[0,0,1],
        matrix:translation(0,-1.55),numbers:true,number_size:11,id:"space"});
    const vectorOrigin=[-.55,.10],pointPosition=[.70,.92];
    const vector=space.vector({origin:vectorOrigin,value:vectorToPoint(vectorOrigin,pointPosition,.34),
        tip:13,id:"vector"});
    const shapes=space.group({id:"shapes"});
    shapes.point({point:pointPosition,radius:6,id:"point"});
    shapes.circle({center:[-2.30,.72],radius:.34,id:"circle"});
    shapes.rectangle({center:[-1.45,-.72],size:[.72,.56],corner:.08,id:"rectangle"});
    shapes.polygon({points:[[-.45,-1.02],[.12,-.38],[.72,-1.02]],id:"polygon"});
    const curve=space.curve({from:[1.15,.52],control1:[1.48,1.25],control2:[2.18,1.25],
        to:[2.52,.52],id:"curve"});
    shapes.surface({points:[[1.42,-1.02],[2.62,-1.02],[1.42,-.42],[2.62,-.42]],
        size:[2,2],mode:"solid",shading:false,id:"filled-shape"});
    scene.fadeIn(content,{shift:[0,.16],scale:.985,duration:.62,curve:"gentle"})
        .wait(.55);
    return scene;
};
const page=tmath.scene({width:1920,height:1000,fps:30,loop:false,background:"#111827"});
page.viewport(panel("3_blue_1_eyes","3 BLUE 1 EYES"),{x:0,y:0,width:.25,height:.5});
page.viewport(panel("pro_white","PRO WHITE"),{x:.25,y:0,width:.25,height:.5});
page.viewport(panel("pro_black","PRO BLACK"),{x:.5,y:0,width:.25,height:.5});
page.viewport(panel(custom,"CUSTOM"),{x:.75,y:0,width:.25,height:.5});
page.viewport(panel(gradientThreeBlueOneEyes,"3 BLUE 1 EYES · GRAD"),{x:0,y:.5,width:.25,height:.5});
page.viewport(panel(gradientProWhite,"PRO WHITE · GRAD"),{x:.25,y:.5,width:.25,height:.5});
page.viewport(panel(gradientProBlack,"PRO BLACK · GRAD"),{x:.5,y:.5,width:.25,height:.5});
page.viewport(panel(customGradient,"CUSTOM · GRAD"),{x:.75,y:.5,width:.25,height:.5});
return page;
`;

const TEXT_REVEAL_LUA = `local p = {
    background="#090d13",panel="#0f1722",panel_alt="#111a26",line="#263547",
    text="#f4f7fb",muted="#8fa1b7",cyan="#4cc9f0",gold="#ffd166",green="#7bd88f"
}
local scene=tmath.scene {width=960,height=540,fps=60,background=p.background,loop=false,
    camera={mode="fixed",view="2d",target={0,0},height=7}}
local function arrow_points(from,to,shaft,head,head_length)
    local dx,dy=to[1]-from[1],to[2]-from[2]
    local length=math.sqrt(dx*dx+dy*dy)
    local ux,uy=dx/length,dy/length
    local nx,ny=-uy,ux
    local joint={to[1]-ux*head_length,to[2]-uy*head_length}
    return {{from[1]+nx*shaft,from[2]+ny*shaft},{joint[1]+nx*shaft,joint[2]+ny*shaft},
        {joint[1]+nx*head,joint[2]+ny*head},{to[1],to[2]},
        {joint[1]-nx*head,joint[2]-ny*head},{joint[1]-nx*shaft,joint[2]-ny*shaft},
        {from[1]-nx*shaft,from[2]-ny*shaft},{from[1]-nx*shaft,from[2]+ny*shaft}}
end
local function ellipse_points(cx,cy,rx,ry)
    local points={}
    for index=0,7 do
        local angle=2*math.pi*index/8
        points[#points+1]={cx+rx*math.cos(angle),cy+ry*math.sin(angle)}
    end
    return points
end
local function box_points(cx,cy,width,height)
    local x0,x1=cx-width*0.5,cx+width*0.5
    local y0,y1=cy-height*0.5,cy+height*0.5
    return {{x0,y0},{cx,y0},{x1,y0},{x1,cy},{x1,y1},{cx,y1},{x0,y1},{x0,cy}}
end

local title=scene:text {text="OBJECT / SHAPE / TEXT",point={-5.55,3.05},align={0,0.5},
    font="Pretendard",size=29,fill=p.text,id="title"}
local subtitle=scene:text {text="Keep the original. Consume only its solid copy.",point={-5.53,2.56},
    align={0,0.5},font="Pretendard",size=14,fill=p.muted,id="subtitle"}
local divider=scene:line {from={-5.55,2.25},to={5.55,2.25},stroke=p.line,width=2,id="divider"}
local defaultPanel=scene:rectangle {center={0,1.36},size={11.1,1.25},corner=0.16,
    fill=p.panel,stroke=p.line,width=2,layer=-5,id="morph-fade-panel"}
local bulletPanel=scene:rectangle {center={0,-0.05},size={11.1,1.25},corner=0.16,
    fill=p.panel_alt,stroke=p.line,width=2,layer=-5,id="bullet-panel"}
local cursorPanel=scene:rectangle {center={0,-1.46},size={11.1,1.25},corner=0.16,
    fill=p.panel,stroke=p.line,width=2,layer=-5,id="cursor-panel"}
local defaultCaption=scene:text {text="01  MORPH FADE  ·  DEFAULT",point={-5.18,1.75},align={0,0.5},
    font="Pretendard",size=12,fill=p.muted,id="morph-fade-caption"}
local bulletCaption=scene:text {text="02  BULLET REVEAL",point={-5.18,0.34},align={0,0.5},
    font="Pretendard",size=12,fill=p.muted,id="bullet-caption"}
local cursorCaption=scene:text {text="03  CURSOR WRITE",point={-5.18,-1.07},align={0,0.5},
    font="Pretendard",size=12,fill=p.muted,id="cursor-caption"}
local handoffPoint=scene:point {point={-4.45,1.25},fill=p.green,stroke=p.green,width=1,radius=9,id="morph-fade-source"}
local handoffLabel=scene:text {text="SOURCE",point={-4.45,0.94},font="Pretendard",size=11,
    fill=p.green,id="morph-fade-source-label"}
local vectorFrom,vectorTo={-4.85,-0.25},{-3.38,0.08}
local vector=scene:vector {origin=vectorFrom,value={vectorTo[1]-vectorFrom[1],vectorTo[2]-vectorFrom[2]},
    color=p.cyan,width=7,tip=18,id="original-vector"}
local vectorLabel=scene:text {text="ORIGINAL",point={-4.12,-0.51},font="Pretendard",size=11,
    fill=p.cyan,id="original-vector-label"}
local point=scene:point {point={-4.45,-1.50},fill=p.gold,radius=9,id="original-point"}
local pointLabel=scene:text {text="ORIGINAL",point={-4.45,-1.92},font="Pretendard",size=11,
    fill=p.gold,id="original-point-label"}

scene:fade_in(title,{shift={0,0.14},duration=0.24,curve="snappy"})
scene:fade_in(subtitle,{shift={0,0.10},duration=0.18,curve="gentle"})
scene:fade_in(defaultPanel,{shift={-0.18,0},duration=0.25,curve="snappy"})
scene:fade_in(bulletPanel,{shift={0.18,0},duration=0.25,curve="snappy"})
scene:fade_in(cursorPanel,{shift={-0.18,0},duration=0.25,curve="snappy"})
scene:fade_in(defaultCaption,{duration=0.12,curve="gentle"})
scene:fade_in(bulletCaption,{duration=0.12,curve="gentle"})
scene:fade_in(cursorCaption,{duration=0.12,curve="gentle"})
scene:create(divider,0.24,"linear")
scene:grow_from_center(handoffPoint,0.24,{preset="back",strength=0.45})
scene:create(vector,0.36,"linear")
scene:grow_from_center(point,0.28,{preset="back",strength=0.55})
scene:fade_in(handoffLabel,{duration=0.12,curve="gentle"})
scene:fade_in(vectorLabel,{duration=0.12,curve="gentle"})
scene:fade_in(pointLabel,{duration=0.12,curve="gentle"})
scene:wait(0.20)
local handoffCopy=scene:polygon {points=ellipse_points(-4.45,1.25,0.16,0.16),
    fill=p.green,stroke=p.green,width=1,layer=7,id="morph-fade-solid-copy"}
local handoffSeed=scene:polygon {points=ellipse_points(-1.38,1.25,0.13,0.18),
    fill=p.green,stroke=p.green,width=1,layer=7,id="morph-fade-seed"}
scene:replacement_transform(handoffCopy,handoffSeed,0.58,"ease_in_out")
local handoffText=scene:text {text="normal vector",point={-1.50,1.25},align={0,0.5},
    font="Pretendard",size=21,fill=p.green,layer=8,id="morph-fade-text"}
scene:fade_transform(handoffSeed,handoffText,0.22,"gentle")
scene:wait(0.18)
local vectorCopy=scene:polygon {points=arrow_points(vectorFrom,vectorTo,0.055,0.18,0.34),
    fill=p.cyan,stroke=p.cyan,width=1,layer=4,id="vector-solid-copy"}
local bullet=scene:polygon {points=ellipse_points(-2.18,-0.16,0.12,0.12),
    fill=p.cyan,stroke=p.cyan,width=1,layer=4,id="vector-bullet-morph-proxy"}
scene:replacement_transform(vectorCopy,bullet,0.62,{preset="back",strength=0.45})
local bulletCircle=scene:circle {center={-2.18,-0.16},radius=0.12,fill=p.cyan,stroke=p.cyan,
    width=1,layer=4,id="vector-bullet"}
scene:remove(bullet)
local bulletWords={
    scene:text {text="vector",point={-1.78,-0.16},align={0,0.5},font="Pretendard",size=19,fill=p.cyan,id="bullet-word-vector"},
    scene:text {text="=",point={-0.62,-0.16},font="Pretendard",size=18,fill=p.muted,id="bullet-word-equals"},
    scene:text {text="magnitude",point={-0.28,-0.16},align={0,0.5},font="Pretendard",size=19,fill=p.text,id="bullet-word-magnitude"},
    scene:text {text="+",point={1.77,-0.16},font="Pretendard",size=18,fill=p.muted,id="bullet-word-plus"},
    scene:text {text="direction",point={2.15,-0.16},align={0,0.5},font="Pretendard",size=19,fill=p.text,id="bullet-word-direction"}}
scene:create(bulletWords,0.16,"ease_out",0.38)
scene:wait(0.24)
local pointCopy=scene:polygon {points=ellipse_points(-4.45,-1.50,0.16,0.16),
    fill=p.gold,stroke=p.gold,width=1,layer=5,id="point-solid-copy"}
local cursor=scene:polygon {points=box_points(-1.40,-1.50,0.075,0.54),
    fill=p.gold,stroke=p.gold,width=1,layer=8,id="text-cursor"}
scene:replacement_transform(pointCopy,cursor,0.58,{preset="snappy",strength=0.86})
local prefixData={{"dot(",0.947},{"dot(u",1.159},{"dot(u, ",1.329},
    {"dot(u, v",1.515},{"dot(u, v)",1.649},{"dot(u, v) = ",2.050},
    {"dot(u, v) = u",2.261},{"dot(u, v) = u · ",2.552},
    {"dot(u, v) = u · v",2.738}}
local typedFormula=scene:group {id="typed-formula"}
local prefixes={}
for index,prefix in ipairs(prefixData) do
    prefixes[index]=typedFormula:text {text=prefix[1],point={-1.20,-1.50},align={0,0.5},
        font="Pretendard",size=21,fill=p.text,opacity=0,id="typed-prefix-"..index}
end
local cursorPosition=0
for index,prefix in ipairs(prefixData) do
    local delta=prefix[2]-cursorPosition
    if index>1 then
        scene:play({{target=prefixes[index-1],opacity=0},
            {target=cursor,shift={delta/3,0}}},0.025,"linear",0)
        cursorPosition=cursorPosition+delta/3
    end
    scene:play({{target=prefixes[index],opacity=1},
        {target=cursor,shift={prefix[2]-cursorPosition,0}}},index>1 and 0.05 or 0.075,"linear",0)
    cursorPosition=prefix[2]
end
scene:fade(cursor,0,0.16,"ease_out")
scene:indicate(typedFormula,{color=p.gold,scale=1.035,duration=0.42,curve="gentle"})
scene:wait(0.65)
return scene
`;

const TEXT_REVEAL_JS = `const p = {
    background: "#090d13", panel: "#0f1722", panelAlt: "#111a26", line: "#263547",
    text: "#f4f7fb", muted: "#8fa1b7", cyan: "#4cc9f0", gold: "#ffd166", green: "#7bd88f",
};
const scene = tmath.scene({width: 960, height: 540, fps: 60, background: p.background, loop: false,
    camera: {mode: "fixed", view: "2d", target: [0,0], height: 7}});
const arrowPoints = (from,to,shaft,head,headLength) => {
    const dx = to[0]-from[0], dy = to[1]-from[1];
    const length = Math.hypot(dx,dy), ux = dx/length, uy = dy/length, nx = -uy, ny = ux;
    const joint = [to[0]-ux*headLength,to[1]-uy*headLength];
    return [[from[0]+nx*shaft,from[1]+ny*shaft],[joint[0]+nx*shaft,joint[1]+ny*shaft],
        [joint[0]+nx*head,joint[1]+ny*head],to,[joint[0]-nx*head,joint[1]-ny*head],
        [joint[0]-nx*shaft,joint[1]-ny*shaft],[from[0]-nx*shaft,from[1]-ny*shaft],
        [from[0]-nx*shaft,from[1]+ny*shaft]];
};
const ellipsePoints = (cx,cy,rx,ry) => Array.from({length: 8},(_,index) => {
    const angle = 2*Math.PI*index/8;
    return [cx+rx*Math.cos(angle),cy+ry*Math.sin(angle)];
});
const boxPoints = (cx,cy,width,height) => {
    const x0=cx-width*0.5,x1=cx+width*0.5,y0=cy-height*0.5,y1=cy+height*0.5;
    return [[x0,y0],[cx,y0],[x1,y0],[x1,cy],[x1,y1],[cx,y1],[x0,y1],[x0,cy]];
};
const title=scene.text({text:"OBJECT / SHAPE / TEXT",point:[-5.55,3.05],align:[0,0.5],
    font:"Pretendard",size:29,fill:p.text,id:"title"});
const subtitle=scene.text({text:"Keep the original. Consume only its solid copy.",point:[-5.53,2.56],
    align:[0,0.5],font:"Pretendard",size:14,fill:p.muted,id:"subtitle"});
const divider=scene.line({from:[-5.55,2.25],to:[5.55,2.25],stroke:p.line,width:2,id:"divider"});
const defaultPanel=scene.rectangle({center:[0,1.36],size:[11.1,1.25],corner:0.16,
    fill:p.panel,stroke:p.line,width:2,layer:-5,id:"morph-fade-panel"});
const bulletPanel=scene.rectangle({center:[0,-0.05],size:[11.1,1.25],corner:0.16,
    fill:p.panelAlt,stroke:p.line,width:2,layer:-5,id:"bullet-panel"});
const cursorPanel=scene.rectangle({center:[0,-1.46],size:[11.1,1.25],corner:0.16,
    fill:p.panel,stroke:p.line,width:2,layer:-5,id:"cursor-panel"});
const defaultCaption=scene.text({text:"01  MORPH FADE  ·  DEFAULT",point:[-5.18,1.75],align:[0,0.5],
    font:"Pretendard",size:12,fill:p.muted,id:"morph-fade-caption"});
const bulletCaption=scene.text({text:"02  BULLET REVEAL",point:[-5.18,0.34],align:[0,0.5],
    font:"Pretendard",size:12,fill:p.muted,id:"bullet-caption"});
const cursorCaption=scene.text({text:"03  CURSOR WRITE",point:[-5.18,-1.07],align:[0,0.5],
    font:"Pretendard",size:12,fill:p.muted,id:"cursor-caption"});
const handoffPoint=scene.point({point:[-4.45,1.25],fill:p.green,stroke:p.green,width:1,radius:9,id:"morph-fade-source"});
const handoffLabel=scene.text({text:"SOURCE",point:[-4.45,0.94],font:"Pretendard",size:11,
    fill:p.green,id:"morph-fade-source-label"});
const vectorFrom=[-4.85,-0.25],vectorTo=[-3.38,0.08];
const vector=scene.vector({origin:vectorFrom,value:[vectorTo[0]-vectorFrom[0],vectorTo[1]-vectorFrom[1]],
    color:p.cyan,width:7,tip:18,id:"original-vector"});
const vectorLabel=scene.text({text:"ORIGINAL",point:[-4.12,-0.51],font:"Pretendard",size:11,
    fill:p.cyan,id:"original-vector-label"});
const point=scene.point({point:[-4.45,-1.50],fill:p.gold,radius:9,id:"original-point"});
const pointLabel=scene.text({text:"ORIGINAL",point:[-4.45,-1.92],font:"Pretendard",size:11,
    fill:p.gold,id:"original-point-label"});
scene.fadeIn(title,{shift:[0,0.14],duration:0.24,curve:"snappy"});
scene.fadeIn(subtitle,{shift:[0,0.10],duration:0.18,curve:"gentle"});
scene.fadeIn(defaultPanel,{shift:[-0.18,0],duration:0.25,curve:"snappy"});
scene.fadeIn(bulletPanel,{shift:[0.18,0],duration:0.25,curve:"snappy"});
scene.fadeIn(cursorPanel,{shift:[-0.18,0],duration:0.25,curve:"snappy"});
scene.fadeIn(defaultCaption,{duration:0.12,curve:"gentle"});
scene.fadeIn(bulletCaption,{duration:0.12,curve:"gentle"});
scene.fadeIn(cursorCaption,{duration:0.12,curve:"gentle"});
scene.create(divider,0.24,"linear");
scene.growFromCenter(handoffPoint,0.24,tmath.animCurve.preset("back",0.45));
scene.create(vector,0.36,"linear");
scene.growFromCenter(point,0.28,tmath.animCurve.preset("back",0.55));
scene.fadeIn(handoffLabel,{duration:0.12,curve:"gentle"});
scene.fadeIn(vectorLabel,{duration:0.12,curve:"gentle"});
scene.fadeIn(pointLabel,{duration:0.12,curve:"gentle"});
scene.wait(0.20);
const handoffCopy=scene.polygon({points:ellipsePoints(-4.45,1.25,0.16,0.16),
    fill:p.green,stroke:p.green,width:1,layer:7,id:"morph-fade-solid-copy"});
const handoffSeed=scene.polygon({points:ellipsePoints(-1.38,1.25,0.13,0.18),
    fill:p.green,stroke:p.green,width:1,layer:7,id:"morph-fade-seed"});
scene.replacementTransform(handoffCopy,handoffSeed,0.58,"ease_in_out");
const handoffText=scene.text({text:"normal vector",point:[-1.50,1.25],align:[0,0.5],
    font:"Pretendard",size:21,fill:p.green,layer:8,id:"morph-fade-text"});
scene.fadeTransform(handoffSeed,handoffText,0.22,"gentle");
scene.wait(0.18);
const vectorCopy=scene.polygon({points:arrowPoints(vectorFrom,vectorTo,0.055,0.18,0.34),
    fill:p.cyan,stroke:p.cyan,width:1,layer:4,id:"vector-solid-copy"});
const bullet=scene.polygon({points:ellipsePoints(-2.18,-0.16,0.12,0.12),
    fill:p.cyan,stroke:p.cyan,width:1,layer:4,id:"vector-bullet-morph-proxy"});
scene.replacementTransform(vectorCopy,bullet,0.62,tmath.animCurve.preset("back",0.45));
const bulletCircle=scene.circle({center:[-2.18,-0.16],radius:0.12,fill:p.cyan,stroke:p.cyan,
    width:1,layer:4,id:"vector-bullet"});
scene.remove(bullet);
const bulletWords=[
    scene.text({text:"vector",point:[-1.78,-0.16],align:[0,0.5],font:"Pretendard",size:19,fill:p.cyan,id:"bullet-word-vector"}),
    scene.text({text:"=",point:[-0.62,-0.16],font:"Pretendard",size:18,fill:p.muted,id:"bullet-word-equals"}),
    scene.text({text:"magnitude",point:[-0.28,-0.16],align:[0,0.5],font:"Pretendard",size:19,fill:p.text,id:"bullet-word-magnitude"}),
    scene.text({text:"+",point:[1.77,-0.16],font:"Pretendard",size:18,fill:p.muted,id:"bullet-word-plus"}),
    scene.text({text:"direction",point:[2.15,-0.16],align:[0,0.5],font:"Pretendard",size:19,fill:p.text,id:"bullet-word-direction"}),
];
scene.create(bulletWords,0.16,"ease_out",0.38);
scene.wait(0.24);
const pointCopy=scene.polygon({points:ellipsePoints(-4.45,-1.50,0.16,0.16),
    fill:p.gold,stroke:p.gold,width:1,layer:5,id:"point-solid-copy"});
const cursor=scene.polygon({points:boxPoints(-1.40,-1.50,0.075,0.54),
    fill:p.gold,stroke:p.gold,width:1,layer:8,id:"text-cursor"});
scene.replacementTransform(pointCopy,cursor,0.58,tmath.animCurve.preset("snappy",0.86));
const prefixData=[["dot(",0.947],["dot(u",1.159],["dot(u, ",1.329],
    ["dot(u, v",1.515],["dot(u, v)",1.649],["dot(u, v) = ",2.050],
    ["dot(u, v) = u",2.261],["dot(u, v) = u · ",2.552],
    ["dot(u, v) = u · v",2.738]];
const typedFormula=scene.group({id:"typed-formula"});
const prefixes=prefixData.map((prefix,index)=>typedFormula.text({text:prefix[0],point:[-1.20,-1.50],
    align:[0,0.5],font:"Pretendard",size:21,fill:p.text,opacity:0,id:"typed-prefix-"+(index+1)}));
let cursorPosition=0;
prefixData.forEach((prefix,index) => {
    const delta=prefix[1]-cursorPosition;
    if(index>0){
        scene.play([{target:prefixes[index-1],opacity:0},
            {target:cursor,shift:[delta/3,0]}],0.025,"linear",0);
        cursorPosition+=delta/3;
    }
    scene.play([{target:prefixes[index],opacity:1},
        {target:cursor,shift:[prefix[1]-cursorPosition,0]}],index>0?0.05:0.075,"linear",0);
    cursorPosition=prefix[1];
});
scene.fade(cursor,0,0.16,"ease_out");
scene.indicate(typedFormula,{color:p.gold,scale:1.035,duration:0.42,curve:"gentle"});
scene.wait(0.65);
return scene;
`;

const OBJECT_GALLERY_LUA = `local p={background="#080d14",a="#0d1622",b="#101a27",rule="#253448",
    text="#f4f7fb",muted="#8fa1b7",cyan="#4cc9f0",gold="#ffd166",green="#7bd88f",
    magenta="#f72585",orange="#ff9f5a"}
local function translate(x,y) return {1,0,0,x,0,1,0,y,0,0,1,0,0,0,0,1} end
local function vector_to_point(origin,target,clearance)
    local dx,dy=target[1]-origin[1],target[2]-origin[2]
    local length=math.sqrt(dx*dx+dy*dy)
    local scale=(length-clearance)/length
    return {dx*scale,dy*scale}
end
local function panel(index,title,background)
    local child=tmath.scene {width=320,height=270,fps=60,background=background,loop=false,
        camera={mode="fixed",view="2d",target={0,0},height=6.4}}
    child:text {text=index,point={-3.42,2.70},align={0,0.5},font="Pretendard",size=10,
        fill=p.muted,id="panel-index-"..index}
    child:text {text=title,point={-2.78,2.70},align={0,0.5},font="Pretendard",size=17,
        fill=p.text,id="panel-title-"..index}
    child:line {from={-3.42,2.25},to={3.42,2.25},stroke=p.rule,width=1.5,id="panel-rule-"..index}
    child:wait(0.28)
    return child
end
local scenePanel=panel("01","SCENE / VIEWPORT",p.a)
local viewportCards={}
for index,spec in ipairs({{-2.18,0.15,p.cyan,"A"},{0,0.15,p.gold,"B"},{2.18,0.15,p.green,"C"}}) do
    local card=scenePanel:group {id="viewport-card-"..index}
    card:rectangle {center={spec[1],spec[2]},size={1.72,1.62},corner=0.12,fill=spec[3].."18",
        stroke=spec[3],width=3,id="viewport-body-"..index}
    card:text {text=spec[4],point={spec[1],spec[2]+0.15},font="Pretendard",size=23,
        fill=spec[3],id="viewport-label-"..index}
    card:text {text="timeline",point={spec[1],spec[2]-0.43},font="Pretendard",size=10,
        fill=p.muted,id="viewport-timeline-"..index}
    viewportCards[#viewportCards+1]=card
end
for _,card in ipairs(viewportCards) do
    scenePanel:fade_in(card,{shift={0,0.20},scale=0.94,duration=0.22,curve="snappy"})
end
scenePanel:wait(0.42)
local shapePanel=panel("02","SHAPES / PATHS",p.b)
local shapeCircle=shapePanel:circle {center={-2.30,0.82},radius=0.52,fill=p.cyan,stroke=p.cyan,width=2,id="shape-circle"}
local shapeRectangle=shapePanel:rectangle {center={0,0.82},size={1.18,0.94},corner=0.14,fill=p.gold,stroke=p.gold,width=2,id="shape-rectangle"}
local shapePolygon=shapePanel:polygon {points={{1.76,0.35},{2.30,1.34},{2.84,0.35}},fill=p.green,stroke=p.green,width=2,id="shape-polygon"}
local shapeCurve=shapePanel:curve {from={-3.05,-1.22},control1={-2.42,0.12},control2={-1.28,-2.32},to={-0.45,-0.92},stroke=p.magenta,width=4,id="shape-curve"}
local shapePath=shapePanel:path {commands={{type="move",to={0.48,-1.72}},{type="line",to={0.92,-0.58}},
    {type="quadratic",control={1.72,0.06},to={2.34,-0.68}},
    {type="cubic",control1={3.05,-1.24},control2={2.62,-2.04},to={1.78,-1.70}},{type="close"}},
    fill=p.orange.."30",stroke=p.orange,width=3,id="shape-path"}
shapePanel:text {text="CIRCLE",point={-2.30,0.08},font="Pretendard",size=9,fill=p.muted,id="circle-label"}
shapePanel:text {text="RECTANGLE",point={0,0.08},font="Pretendard",size=9,fill=p.muted,id="rectangle-label"}
shapePanel:text {text="POLYGON",point={2.30,0.08},font="Pretendard",size=9,fill=p.muted,id="polygon-label"}
shapePanel:text {text="CURVE",point={-1.74,-2.12},font="Pretendard",size=9,fill=p.magenta,id="curve-label"}
shapePanel:text {text="PATH",point={1.78,-2.12},font="Pretendard",size=9,fill=p.orange,id="path-label"}
shapePanel:grow_from_center(shapeCircle,0.34,{preset="back",strength=0.50})
shapePanel:grow_from_center(shapeRectangle,0.34,{preset="back",strength=0.50})
shapePanel:grow_from_center(shapePolygon,0.34,{preset="back",strength=0.50})
shapePanel:create(shapeCurve,0.42,"ease_out")
shapePanel:draw_border_then_fill(shapePath,0.72,"ease_in_out")
shapePanel:wait(0.42)
local vectorPanel=panel("03","LINE / VECTOR / POINT",p.a)
local line=vectorPanel:line {from={-2.85,0.72},to={-0.95,0.72},stroke=p.muted,width=4,id="line"}
local arrow=vectorPanel:arrow {from={-2.85,-0.18},to={-0.95,-0.18},color=p.gold,width=4,tip=14,id="arrow"}
local vectorOrigin,pointPosition={0.35,-0.55},{2.50,0.80}
local vector=vectorPanel:vector {origin=vectorOrigin,value=vector_to_point(vectorOrigin,pointPosition,.28),color=p.cyan,width=5,tip=16,id="vector"}
local point=vectorPanel:point {point=pointPosition,fill=p.magenta,radius=7,id="point"}
vectorPanel:text {text="LINE",point={-1.90,1.16},font="Pretendard",size=10,fill=p.muted,id="line-label"}
vectorPanel:text {text="ARROW",point={-1.90,-0.66},font="Pretendard",size=10,fill=p.gold,id="arrow-label"}
vectorPanel:text {text="VECTOR + POINT",point={1.45,-1.12},font="Pretendard",size=10,fill=p.cyan,id="vector-label"}
vectorPanel:create(line,0.28,"linear")
vectorPanel:create(arrow,0.34,"linear")
vectorPanel:create(vector,0.42,"linear")
vectorPanel:grow_from_center(point,0.24,{preset="back",strength=0.55})
vectorPanel:wait(0.42)
local textPanel=panel("04","TEXT",p.b)
local textLeft=textPanel:text {text="LEFT",point={-2.65,0.84},align={0,0.5},font="Pretendard",size=14,fill=p.cyan,id="text-left"}
local textCenter=textPanel:text {text="Type",point={0,0.10},font="Pretendard",size=32,fill=p.text,id="text-center"}
local textRight=textPanel:text {text="RIGHT",point={2.65,-0.72},align={1,0.5},font="Pretendard",size=14,fill=p.gold,id="text-right"}
textPanel:fade_in(textLeft,{shift={-0.22,0},duration=0.24,curve="snappy"})
textPanel:fade_in(textCenter,{scale=0.90,duration=0.30,curve="gentle"})
textPanel:fade_in(textRight,{shift={0.22,0},duration=0.24,curve="snappy"})
textPanel:wait(0.42)
local spacePanel=panel("05","SPACE / GRID",p.a)
local space=spacePanel:space {x={-3,3,1},y={-1.4,1.4,0.7},color=p.rule,axis_x=p.orange,axis_y=p.green,numbers=false,id="space"}
local spaceOrigin,spacePointPosition={0,0},{1.8,0.9}
local spaceVector=space:vector {origin=spaceOrigin,value=vector_to_point(spaceOrigin,spacePointPosition,.26),color=p.cyan,width=5,tip=15,id="space-vector"}
local spacePoint=space:point {point=spacePointPosition,fill=p.gold,radius=6,id="space-point"}
spacePanel:create(space,0.46,"linear")
spacePanel:create(spaceVector,0.38,"linear")
spacePanel:grow_from_center(spacePoint,0.24,{preset="back",strength=0.55})
spacePanel:wait(0.42)
local groupPanel=panel("06","GROUP / CONNECTOR",p.b)
local nodes=groupPanel:group {id="node-group"}
local nodeItems={}
for index,spec in ipairs({{-1.85,0.62,p.cyan,"A"},{0,-0.35,p.gold,"B"},{1.85,0.62,p.green,"C"}}) do
    local node=nodes:group {matrix=translate(spec[1],spec[2]),id="node-"..index}
    node:circle {radius=0.48,fill=spec[3],stroke=spec[3],width=2,id="node-body-"..index}
    node:text {text=spec[4],point={0,0},font="Pretendard",size=18,fill=p.background,id="node-label-"..index}
    nodeItems[#nodeItems+1]=node
end
local leftEdge=groupPanel:connector {from=nodeItems[1],to=nodeItems[2],padding=0.08,stroke=p.rule,width=3,id="edge-a-b"}
local rightEdge=groupPanel:connector {from=nodeItems[2],to=nodeItems[3],padding=0.08,stroke=p.rule,width=3,id="edge-b-c"}
for _,node in ipairs(nodeItems) do groupPanel:grow_from_center(node,0.24,{preset="back",strength=0.50}) end
groupPanel:create({leftEdge,rightEdge},0.34,"linear",0.08)
groupPanel:shift(nodes,{0,0.18},0.40,"ease_in_out")
groupPanel:wait(0.42)
local gallery=tmath.scene {width=960,height=540,fps=60,background=p.background,loop=false,
    camera={mode="fixed",view="2d",target={0,0},height=6.4}}
local panels={scenePanel,shapePanel,vectorPanel,textPanel,spacePanel,groupPanel}
for index,child in ipairs(panels) do
    gallery:viewport(child,{x=((index-1)%3)/3,y=math.floor((index-1)/3)/2,width=1/3,height=1/2})
end
return gallery
`;

const OBJECT_GALLERY_JS = `const p={background:"#080d14",a:"#0d1622",b:"#101a27",rule:"#253448",
    text:"#f4f7fb",muted:"#8fa1b7",cyan:"#4cc9f0",gold:"#ffd166",green:"#7bd88f",
    magenta:"#f72585",orange:"#ff9f5a"};
const translate=(x,y)=>[1,0,0,x,0,1,0,y,0,0,1,0,0,0,0,1];
const vectorToPoint=(origin,target,clearance)=>{
    const dx=target[0]-origin[0],dy=target[1]-origin[1];
    const length=Math.hypot(dx,dy),scale=(length-clearance)/length;
    return [dx*scale,dy*scale];
};
const panel=(index,title,background)=>{
    const child=tmath.scene({width:320,height:270,fps:60,background,loop:false,
        camera:{mode:"fixed",view:"2d",target:[0,0],height:6.4}});
    child.text({text:index,point:[-3.42,2.70],align:[0,0.5],font:"Pretendard",size:10,
        fill:p.muted,id:"panel-index-"+index});
    child.text({text:title,point:[-2.78,2.70],align:[0,0.5],font:"Pretendard",size:17,
        fill:p.text,id:"panel-title-"+index});
    child.line({from:[-3.42,2.25],to:[3.42,2.25],stroke:p.rule,width:1.5,id:"panel-rule-"+index});
    child.wait(0.28);
    return child;
};
const scenePanel=panel("01","SCENE / VIEWPORT",p.a);
const viewportCards=[];
[[-2.18,0.15,p.cyan,"A"],[0,0.15,p.gold,"B"],[2.18,0.15,p.green,"C"]].forEach((spec,index)=>{
    const card=scenePanel.group({id:"viewport-card-"+(index+1)});
    card.rectangle({center:[spec[0],spec[1]],size:[1.72,1.62],corner:0.12,fill:spec[2]+"18",
        stroke:spec[2],width:3,id:"viewport-body-"+(index+1)});
    card.text({text:spec[3],point:[spec[0],spec[1]+0.15],font:"Pretendard",size:23,
        fill:spec[2],id:"viewport-label-"+(index+1)});
    card.text({text:"timeline",point:[spec[0],spec[1]-0.43],font:"Pretendard",size:10,
        fill:p.muted,id:"viewport-timeline-"+(index+1)});
    viewportCards.push(card);
});
for(const card of viewportCards) scenePanel.fadeIn(card,{shift:[0,0.20],scale:0.94,duration:0.22,curve:"snappy"});
scenePanel.wait(0.42);
const shapePanel=panel("02","SHAPES / PATHS",p.b);
const shapeCircle=shapePanel.circle({center:[-2.30,0.82],radius:0.52,fill:p.cyan,stroke:p.cyan,width:2,id:"shape-circle"});
const shapeRectangle=shapePanel.rectangle({center:[0,0.82],size:[1.18,0.94],corner:0.14,fill:p.gold,stroke:p.gold,width:2,id:"shape-rectangle"});
const shapePolygon=shapePanel.polygon({points:[[1.76,0.35],[2.30,1.34],[2.84,0.35]],fill:p.green,stroke:p.green,width:2,id:"shape-polygon"});
const shapeCurve=shapePanel.curve({from:[-3.05,-1.22],control1:[-2.42,0.12],control2:[-1.28,-2.32],to:[-0.45,-0.92],stroke:p.magenta,width:4,id:"shape-curve"});
const shapePath=shapePanel.path({commands:[{type:"move",to:[0.48,-1.72]},{type:"line",to:[0.92,-0.58]},
    {type:"quadratic",control:[1.72,0.06],to:[2.34,-0.68]},
    {type:"cubic",control1:[3.05,-1.24],control2:[2.62,-2.04],to:[1.78,-1.70]},{type:"close"}],
    fill:p.orange+"30",stroke:p.orange,width:3,id:"shape-path"});
shapePanel.text({text:"CIRCLE",point:[-2.30,0.08],font:"Pretendard",size:9,fill:p.muted,id:"circle-label"});
shapePanel.text({text:"RECTANGLE",point:[0,0.08],font:"Pretendard",size:9,fill:p.muted,id:"rectangle-label"});
shapePanel.text({text:"POLYGON",point:[2.30,0.08],font:"Pretendard",size:9,fill:p.muted,id:"polygon-label"});
shapePanel.text({text:"CURVE",point:[-1.74,-2.12],font:"Pretendard",size:9,fill:p.magenta,id:"curve-label"});
shapePanel.text({text:"PATH",point:[1.78,-2.12],font:"Pretendard",size:9,fill:p.orange,id:"path-label"});
shapePanel.growFromCenter(shapeCircle,0.34,tmath.animCurve.preset("back",0.50));
shapePanel.growFromCenter(shapeRectangle,0.34,tmath.animCurve.preset("back",0.50));
shapePanel.growFromCenter(shapePolygon,0.34,tmath.animCurve.preset("back",0.50));
shapePanel.create(shapeCurve,0.42,"ease_out");
shapePanel.drawBorderThenFill(shapePath,0.72,"ease_in_out");
shapePanel.wait(0.42);
const vectorPanel=panel("03","LINE / VECTOR / POINT",p.a);
const line=vectorPanel.line({from:[-2.85,0.72],to:[-0.95,0.72],stroke:p.muted,width:4,id:"line"});
const arrow=vectorPanel.arrow({from:[-2.85,-0.18],to:[-0.95,-0.18],color:p.gold,width:4,tip:14,id:"arrow"});
const vectorOrigin=[0.35,-0.55],pointPosition=[2.50,0.80];
const vector=vectorPanel.vector({origin:vectorOrigin,value:vectorToPoint(vectorOrigin,pointPosition,.28),color:p.cyan,width:5,tip:16,id:"vector"});
const point=vectorPanel.point({point:pointPosition,fill:p.magenta,radius:7,id:"point"});
vectorPanel.text({text:"LINE",point:[-1.90,1.16],font:"Pretendard",size:10,fill:p.muted,id:"line-label"});
vectorPanel.text({text:"ARROW",point:[-1.90,-0.66],font:"Pretendard",size:10,fill:p.gold,id:"arrow-label"});
vectorPanel.text({text:"VECTOR + POINT",point:[1.45,-1.12],font:"Pretendard",size:10,fill:p.cyan,id:"vector-label"});
vectorPanel.create(line,0.28,"linear");
vectorPanel.create(arrow,0.34,"linear");
vectorPanel.create(vector,0.42,"linear");
vectorPanel.growFromCenter(point,0.24,tmath.animCurve.preset("back",0.55));
vectorPanel.wait(0.42);
const textPanel=panel("04","TEXT",p.b);
const textLeft=textPanel.text({text:"LEFT",point:[-2.65,0.84],align:[0,0.5],font:"Pretendard",size:14,fill:p.cyan,id:"text-left"});
const textCenter=textPanel.text({text:"Type",point:[0,0.10],font:"Pretendard",size:32,fill:p.text,id:"text-center"});
const textRight=textPanel.text({text:"RIGHT",point:[2.65,-0.72],align:[1,0.5],font:"Pretendard",size:14,fill:p.gold,id:"text-right"});
textPanel.fadeIn(textLeft,{shift:[-0.22,0],duration:0.24,curve:"snappy"});
textPanel.fadeIn(textCenter,{scale:0.90,duration:0.30,curve:"gentle"});
textPanel.fadeIn(textRight,{shift:[0.22,0],duration:0.24,curve:"snappy"});
textPanel.wait(0.42);
const spacePanel=panel("05","SPACE / GRID",p.a);
const space=spacePanel.space({x:[-3,3,1],y:[-1.4,1.4,0.7],color:p.rule,axis_x:p.orange,axis_y:p.green,numbers:false,id:"space"});
const spaceOrigin=[0,0],spacePointPosition=[1.8,0.9];
const spaceVector=space.vector({origin:spaceOrigin,value:vectorToPoint(spaceOrigin,spacePointPosition,.26),color:p.cyan,width:5,tip:15,id:"space-vector"});
const spacePoint=space.point({point:spacePointPosition,fill:p.gold,radius:6,id:"space-point"});
spacePanel.create(space,0.46,"linear");
spacePanel.create(spaceVector,0.38,"linear");
spacePanel.growFromCenter(spacePoint,0.24,tmath.animCurve.preset("back",0.55));
spacePanel.wait(0.42);
const groupPanel=panel("06","GROUP / CONNECTOR",p.b);
const nodes=groupPanel.group({id:"node-group"});
const nodeItems=[];
[[-1.85,0.62,p.cyan,"A"],[0,-0.35,p.gold,"B"],[1.85,0.62,p.green,"C"]].forEach((spec,index)=>{
    const node=nodes.group({matrix:translate(spec[0],spec[1]),id:"node-"+(index+1)});
    node.circle({radius:0.48,fill:spec[2],stroke:spec[2],width:2,id:"node-body-"+(index+1)});
    node.text({text:spec[3],point:[0,0],font:"Pretendard",size:18,fill:p.background,id:"node-label-"+(index+1)});
    nodeItems.push(node);
});
const leftEdge=groupPanel.connector(nodeItems[0],nodeItems[1],{padding:0.08,stroke:p.rule,width:3,id:"edge-a-b"});
const rightEdge=groupPanel.connector(nodeItems[1],nodeItems[2],{padding:0.08,stroke:p.rule,width:3,id:"edge-b-c"});
for(const node of nodeItems) groupPanel.growFromCenter(node,0.24,tmath.animCurve.preset("back",0.50));
groupPanel.create([leftEdge,rightEdge],0.34,"linear",0.08);
groupPanel.shift(nodes,[0,0.18],0.40,"ease_in_out");
groupPanel.wait(0.42);
const gallery=tmath.scene({width:960,height:540,fps:60,background:p.background,loop:false,
    camera:{mode:"fixed",view:"2d",target:[0,0],height:6.4}});
[scenePanel,shapePanel,vectorPanel,textPanel,spacePanel,groupPanel].forEach((child,index)=>{
    gallery.viewport(child,{x:(index%3)/3,y:Math.floor(index/3)/2,width:1/3,height:1/2});
});
return gallery;
`;

const CELL_FIELD_LUA = `local p={muted="#667085",grid="#d8dadd",blue="#0891b2",violet="#7c3aed"}
local scene=tmath.scene{width=960,height=540,fps=30,loop=false,theme="pro_white",
    camera={mode="fixed",view="2d",target={0,0},height=7.2}}
scene:text{text="Cell  ·  circle to ellipse",point={-5.95,3.02},align={0,.5},role="h2"}
scene:text{text="x² + y² ≤ r²    to    x²/a² + y²/b² ≤ 1",point={-5.92,2.53},
    align={0,.5},role="text",fill=p.muted}
scene:space{x={-3,3,1},y={-2,2,1},z={0,0,1},stroke=p.grid,width=1}
local field=scene:space{x={-3,3,.12},y={-2,2,.12},z={0,0,1},opacity=0}
local duration=1.8
field:cell(function(x,y,time)
    local progress=time/duration
    progress=progress*progress*(3-2*progress)
    local a=1.35+(2.05-1.35)*progress
    local b=1.35+(1.05-1.35)*progress
    local color=progress<.5 and p.blue or p.violet
    return x*x/(a*a)+y*y/(b*b)<=1 and color or"#00000000"
end,{mode="padd",padding=.045,duration=duration,fps=24})
scene:wait(.45)
return scene
`;

const CELL_FIELD_JS = `const p={muted:"#667085",grid:"#d8dadd",blue:"#0891b2",violet:"#7c3aed"};
const scene=tmath.scene({width:960,height:540,fps:30,loop:false,theme:"pro_white",
    camera:{mode:"fixed",view:"2d",target:[0,0],height:7.2}});
scene.text({text:"Cell  ·  circle to ellipse",point:[-5.95,3.02],align:[0,.5],role:"h2"});
scene.text({text:"x² + y² ≤ r²    to    x²/a² + y²/b² ≤ 1",point:[-5.92,2.53],
    align:[0,.5],role:"text",fill:p.muted});
scene.space({x:[-3,3,1],y:[-2,2,1],z:[0,0,1],stroke:p.grid,width:1});
const field=scene.space({x:[-3,3,.12],y:[-2,2,.12],z:[0,0,1],opacity:0});
const duration=1.8;
field.cell((x,y,time)=>{
    let progress=time/duration;
    progress=progress*progress*(3-2*progress);
    const a=1.35+(2.05-1.35)*progress;
    const b=1.35+(1.05-1.35)*progress;
    const color=progress<.5?p.blue:p.violet;
    return x*x/(a*a)+y*y/(b*b)<=1?color:"#00000000";
},{mode:"padd",padding:.045,duration,fps:24});
scene.wait(.45);
return scene;
`;

const VOXEL_FIELD_LUA = `local p={muted="#667085",grid="#d8dadd66",blue="#2563eb",violet="#7c3aed"}
local page=tmath.scene{width=960,height=540,fps=30,loop=false,theme="pro_white",
    camera={mode="fixed",view="2d",target={0,0},height=8}}
page:text{text="Voxel  ·  sphere to ellipsoid",point={-6.55,3.42},align={0,.5},role="h2"}
page:text{text="x² + y² + z² ≤ r²    to    x²/a² + y²/b² + z²/c² ≤ 1",
    point={-6.52,2.91},align={0,.5},role="text",fill=p.muted}
local view=tmath.scene{width=900,height=400,fps=30,loop=false,theme="pro_white",
    antialiasing=true,camera={mode="fixed",view="3d",eye={5.2,3.8,6},target={0,0,0},
        up={0,1,0},projection="perspective",fov=.66,near=.1,far=100}}
local field=view:space{x={-2.1,2.1,.35},y={-2.1,2.1,.35},z={-2.1,2.1,.35},
    stroke=p.grid,width=.8}
local duration=1.8
field:voxel(function(x,y,z,time)
    local progress=time/duration
    progress=progress*progress*(3-2*progress)
    local a=1.5+(1.9-1.5)*progress
    local b=1.5+(1.15-1.5)*progress
    local color=progress<.5 and p.blue or p.violet
    local value=x*x/(a*a)+y*y/(b*b)+z*z/(1.5*1.5)
    return value<=1 and color or"#00000000"
end,{mode="padd",padding=.055,duration=duration,fps=24})
view:wait(.35)
page:viewport(view,{x=.03,y=.18,width=.94,height=.78})
return page
`;

const VOXEL_FIELD_JS = `const p={muted:"#667085",grid:"#d8dadd66",blue:"#2563eb",violet:"#7c3aed"};
const page=tmath.scene({width:960,height:540,fps:30,loop:false,theme:"pro_white",
    camera:{mode:"fixed",view:"2d",target:[0,0],height:8}});
page.text({text:"Voxel  ·  sphere to ellipsoid",point:[-6.55,3.42],align:[0,.5],role:"h2"});
page.text({text:"x² + y² + z² ≤ r²    to    x²/a² + y²/b² + z²/c² ≤ 1",
    point:[-6.52,2.91],align:[0,.5],role:"text",fill:p.muted});
const view=tmath.scene({width:900,height:400,fps:30,loop:false,theme:"pro_white",
    antialiasing:true,camera:{mode:"fixed",view:"3d",eye:[5.2,3.8,6],target:[0,0,0],
        up:[0,1,0],projection:"perspective",fov:.66,near:.1,far:100}});
const field=view.space({x:[-2.1,2.1,.35],y:[-2.1,2.1,.35],z:[-2.1,2.1,.35],
    stroke:p.grid,width:.8});
const duration=1.8;
field.voxel((x,y,z,time)=>{
    let progress=time/duration;
    progress=progress*progress*(3-2*progress);
    const a=1.5+(1.9-1.5)*progress;
    const b=1.5+(1.15-1.5)*progress;
    const color=progress<.5?p.blue:p.violet;
    const value=x*x/(a*a)+y*y/(b*b)+z*z/(1.5*1.5);
    return value<=1?color:"#00000000";
},{mode:"padd",padding:.055,duration,fps:24});
view.wait(.35);
page.viewport(view,{x:.03,y:.18,width:.94,height:.78});
return page;
`;

export const TMATH_EXAMPLES = [
    {
        id: "theme-showcase",
        title: "Theme",
        description:
            "Compare solid and gradient variants of 3 Blue 1 Eyes, Pro White, Pro Black, and Custom Themes across eight isolated Viewports.",
        category: "tmath",
        dimension: "2D",
        fonts: PRETENDARD,
        lua: THEME_SHOWCASE_LUA,
        js: THEME_SHOWCASE_JS,
    },
    BRAND_EXAMPLE,
    {
        id: "cell-field",
        title: "Cell circle to ellipse",
        description: "Animate one sampled Cell field from a circle into an ellipse.",
        category: "tmath",
        dimension: "2D",
        fonts: PRETENDARD,
        lua: CELL_FIELD_LUA,
        js: CELL_FIELD_JS,
    },
    {
        id: "voxel-field",
        title: "Voxel sphere to ellipsoid",
        description: "Animate one sampled Voxel field from a sphere into an ellipsoid.",
        category: "tmath",
        dimension: "3D",
        fonts: PRETENDARD,
        lua: VOXEL_FIELD_LUA,
        js: VOXEL_FIELD_JS,
    },
    {
        id: "object-gallery",
        title: "Object gallery",
        description:
            "A compact inventory of Scene, Viewport, Shape, Text, Space, Group, and Connector composition.",
        category: "tmath",
        dimension: "2D",
        fonts: PRETENDARD,
        lua: OBJECT_GALLERY_LUA,
        js: OBJECT_GALLERY_JS,
    },
    {
        id: "text-reveal-transitions",
        title: "Object to text transitions",
        description:
            "Compare the default same-color morph-fade handoff with persistent bullet and cursor text reveals.",
        category: "tmath",
        dimension: "2D",
        fonts: PRETENDARD,
        lua: TEXT_REVEAL_LUA,
        js: TEXT_REVEAL_JS,
    },
];
