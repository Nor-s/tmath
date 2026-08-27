const PRETENDARD = [{ name: "Pretendard", url: "./Pretendard.ttf", mime: "ttf" }];

async function loadLua(filename) {
    const url = new URL(filename, import.meta.url);
    if (url.protocol === "file:") {
        const { readFile } = await import("node:fs/promises");
        return readFile(new URL(`../lua/${filename}`, import.meta.url), "utf8");
    }
    const response = await fetch(url);
    if (!response.ok) throw new Error(`Could not load ${filename}: ${response.status}`);
    return response.text();
}

const filenames = [
    "manim_following_graph_camera.lua",
    "manim_brace_annotation.lua",
    "manim_moving_around.lua",
    "manim_sin_cos_function_plot.lua",
    "manim_graph_area_plot.lua",
    "manim_polygon_on_axes.lua",
    "manim_moving_zoomed_scene.lua",
    "manim_3d_light_source_position.lua",
    "manim_3d_camera_illusion_rotation.lua",
    "manim_3d_surface_plot.lua",
    "manim_opening.lua",
    "manim_sine_curve_unit_circle.lua",
];
const luaSources = Object.fromEntries(
    await Promise.all(
        filenames.map(async (filename) => {
            return [filename, await loadLua(filename)];
        }),
    ),
);

const FOLLOWING_GRAPH_CAMERA_JS = `const p={paper:"#f7f8fb",ink:"#182033",muted:"#687086",grid:"#dce2ed",blue:"#2563eb",orange:"#f97316"};
const scene=tmath.scene({width:960,height:540,fps:60,background:p.paper,camera:{mode:"fixed",view:"2d",height:7}});
scene.rectangle({center:[0,2.58],size:[12.5,1.85],fill:p.paper,stroke:"#00000000",layer:18,id:"fixed-header"});
scene.text({text:"FOLLOWING GRAPH CAMERA",point:[-5.7,2.62],align:[0,.5],font:"Pretendard",size:27,fill:p.ink,layer:20});
scene.text({text:"the camera frame stays locked to a moving sample",point:[-5.68,2.1],align:[0,.5],font:"Pretendard",size:13,fill:p.muted,layer:20});
const world=scene.group({id:"moving-camera-world"});
const grid=world.space({x:[-1,10,1],y:[-2,2,.5],color:p.grid,axis_x:p.ink,axis_y:p.ink,numbers:false,id:"axes"});
const sampleCount=120,points=[];for(let sample=0;sample<=sampleCount;sample++){const x=3*Math.PI*sample/sampleCount;points.push([x,Math.sin(x)]);}const graph=grid.plot({points,stroke:p.blue,width:4,id:"sine-path"});
grid.point({point:[0,0],fill:p.ink,radius:4,id:"start"});grid.point({point:[3*Math.PI,0],fill:p.ink,radius:4,id:"end"});
const focus=scene.point({point:[0,-.15],fill:p.orange,stroke:p.paper,width:3,radius:9,layer:10,id:"camera-focus"});
const frame=scene.rectangle({center:[0,-.15],size:[4,2.35],corner:.08,fill:"#00000000",stroke:p.orange+"88",width:2,layer:9,id:"camera-frame"});
const cameraMatrix=point=>[1.65,0,0,-1.65*point[0],0,1.65,0,-.15-1.65*point[1],0,0,1,0,0,0,0,1];
scene.create(grid,.42,"ease_out").create(graph,.75,"ease_out").growFromCenter(focus,.2,"snappy").create(frame,.3,"ease_out").transform(world,cameraMatrix(points[0]),.6,"ease_in_out");
for(let step=1;step<=sampleCount;step++)scene.transform(world,cameraMatrix(points[step]),.025,"linear");
scene.transform(world,[1,0,0,-4.5,0,1,0,-.15,0,0,1,0,0,0,0,1],.65,"ease_in_out").wait(.8);return scene;`;

const BRACE_ANNOTATION_JS = `const p={paper:"#f7f8fb",ink:"#182033",muted:"#687086",blue:"#2563eb",orange:"#f97316",rule:"#d8deea"};
const scene=tmath.scene({width:960,height:540,fps:60,background:p.paper,camera:{mode:"fixed",view:"2d",height:7.2}});
scene.text({text:"BRACE ANNOTATION",point:[-5.75,2.75],align:[0,.5],font:"Pretendard",size:27,fill:p.ink});scene.text({text:"one segment, two measured directions",point:[-5.72,2.25],align:[0,.5],font:"Pretendard",size:13,fill:p.muted});scene.line({from:[-5.75,1.92],to:[5.75,1.92],stroke:p.rule,width:1});
const a=[-3.2,-.7],b=[2.9,1.05],segment=scene.line({from:a,to:b,stroke:p.ink,width:4,id:"segment"});
const endpoints=[scene.point({point:a,fill:p.orange,stroke:p.paper,width:2,radius:7}),scene.point({point:b,fill:p.orange,stroke:p.paper,width:2,radius:7})];
const horizontal=scene.path({commands:[{type:"move",to:[-3.2,-1.25]},{type:"cubic",control1:[-2.9,-1.25],control2:[-2.9,-1.55],to:[-2.6,-1.55]},{type:"line",to:[-.45,-1.55]},{type:"cubic",control1:[-.1,-1.55],control2:[-.18,-1.85],to:[-.02,-1.85]},{type:"cubic",control1:[.14,-1.85],control2:[.06,-1.55],to:[.41,-1.55]},{type:"line",to:[2.55,-1.55]},{type:"cubic",control1:[2.85,-1.55],control2:[2.85,-1.25],to:[3.15,-1.25]}],samples:10,fill:"#00000000",stroke:p.blue,width:4,id:"horizontal-brace"});
const vertical=scene.path({commands:[{type:"move",to:[3.65,-.7]},{type:"cubic",control1:[3.65,-.5],control2:[3.95,-.5],to:[3.95,-.28]},{type:"line",to:[3.95,-.05]},{type:"cubic",control1:[3.95,.18],control2:[4.22,.05],to:[4.22,.18]},{type:"cubic",control1:[4.22,.31],control2:[3.95,.18],to:[3.95,.41]},{type:"line",to:[3.95,.66]},{type:"cubic",control1:[3.95,.88],control2:[3.65,.88],to:[3.65,1.08]}],samples:10,fill:"#00000000",stroke:p.orange,width:4,id:"vertical-brace"});
const labels=[scene.text({text:"horizontal distance",point:[0,-2.22],font:"Pretendard",size:16,fill:p.blue}),scene.text({text:"y₂ − y₁",point:[4.85,.18],font:"Pretendard",size:16,fill:p.orange})];
scene.create(segment,.55,"ease_out");for(const endpoint of endpoints)scene.growFromCenter(endpoint,.11,"snappy");scene.create([horizontal,vertical],.75,"ease_out",0).fadeIn(labels[0],{shift:[0,.16],duration:.32,curve:"ease_out"}).fadeIn(labels[1],{shift:[-.16,0],duration:.32,curve:"ease_out"}).wait(.8);return scene;`;

const MOVING_AROUND_JS = `const scene=tmath.scene({width:960,height:540,fps:60,background:"#f7f8fb",camera:{mode:"fixed",view:"2d",height:7}});
scene.text({text:"MOVING AROUND",point:[-5.7,2.62],align:[0,.5],font:"Pretendard",size:27,fill:"#182033"});scene.text({text:"shift  ·  fill  ·  scale  ·  rotate",point:[-5.68,2.1],align:[0,.5],font:"Pretendard",size:13,fill:"#687086"});
const square=scene.rectangle({center:[0,0],size:[2.2,2.2],corner:.08,fill:"#2563eb",stroke:"#1d4ed8",width:4,id:"square"});
scene.fadeIn(square,{scale:.8,duration:.3,curve:"snappy"}).shift(square,[-2.2,0],.65,"ease_in_out").fill(square,"#f97316",.52,"ease_in_out").transform(square,[.42,0,0,-2.2,0,.42,0,0,0,0,1,0,0,0,0,1],.55,"snappy").transform(square,[.36,-.22,0,-2.2,.22,.36,0,0,0,0,1,0,0,0,0,1],.65,tmath.animCurve.preset("back",.55)).wait(.8);return scene;`;

const SIN_COS_FUNCTION_PLOT_JS = `const p={paper:"#f7f8fb",ink:"#182033",muted:"#687086",grid:"#dce2ed",blue:"#2563eb",red:"#ef4444",yellow:"#eab308"};
const scene=tmath.scene({width:960,height:540,fps:60,background:p.paper,camera:{mode:"fixed",view:"2d",height:7.4}});scene.text({text:"SINE AND COSINE",point:[-5.75,2.92],align:[0,.5],font:"Pretendard",size:27,fill:p.ink});scene.text({text:"phase-aligned function plots",point:[-5.72,2.42],align:[0,.5],font:"Pretendard",size:13,fill:p.muted});
const axes=scene.space({x:[-2*Math.PI,2*Math.PI,Math.PI/2],y:[-1.5,1.5,.5],matrix:[.72,0,0,0,0,1.25,0,-.35,0,0,1,0,0,0,0,1],color:p.grid,axis_x:p.ink,axis_y:p.ink,width:1.2,numbers:false,id:"axes"});
const sinePoints=[],cosinePoints=[];for(let sample=0;sample<=160;sample++){const x=-2*Math.PI+4*Math.PI*sample/160;sinePoints.push([x,Math.sin(x)]);cosinePoints.push([x,Math.cos(x)]);}const sine=axes.plot({points:sinePoints,stroke:p.blue,width:4,id:"sine"}),cosine=axes.plot({points:cosinePoints,stroke:p.red,width:4,id:"cosine"});
const tau=axes.line({from:[2*Math.PI,-1.18],to:[2*Math.PI,1.18],stroke:p.yellow,width:3,id:"tau-line"});const labels=[scene.text({text:"sin(x)",point:[-4.8,1.48],font:"Pretendard",size:16,fill:p.blue}),scene.text({text:"cos(x)",point:[-4.8,1.05],font:"Pretendard",size:16,fill:p.red}),scene.text({text:"x = 2π",point:[4.58,1.62],font:"Pretendard",size:13,fill:p.yellow})];
scene.create(axes,.45,"ease_out").create([sine,cosine],1.15,"ease_out",0).create(tau,.35,"ease_out").fadeIn(labels[0],{shift:[.14,0],duration:.25,curve:"ease_out"}).fadeIn(labels[1],{shift:[.14,0],duration:.25,curve:"ease_out"}).fadeIn(labels[2],{shift:[0,-.12],duration:.25,curve:"ease_out"}).wait(.8);return scene;`;

const GRAPH_AREA_PLOT_JS = `const p={paper:"#f7f8fb",ink:"#182033",muted:"#687086",grid:"#dce2ed",blue:"#2563eb",green:"#16a34a",gold:"#eab308"};const scene=tmath.scene({width:960,height:540,fps:60,background:p.paper,camera:{mode:"fixed",view:"2d",height:8}});scene.text({text:"GRAPH AREA PLOT",point:[-5.8,3.15],align:[0,.5],font:"Pretendard",size:27,fill:p.ink});scene.text({text:"Riemann rectangles and bounded area",point:[-5.77,2.65],align:[0,.5],font:"Pretendard",size:13,fill:p.muted});
const axes=scene.space({x:[0,5,1],y:[0,6,1],matrix:[1.15,0,0,-2.75,0,.82,0,-2.55,0,0,1,0,0,0,0,1],color:p.grid,axis_x:p.ink,axis_y:p.ink,numbers:true,number_size:10,id:"axes"});const a=[],b=[];for(let sample=0;sample<=100;sample++){const x=4*sample/100;a.push([x,4*x-x*x]);b.push([x,.8*x*x-3*x+4]);}const curveA=axes.plot({points:a,stroke:p.blue,width:4,id:"curve-a"}),curveB=axes.plot({points:b,stroke:p.green,width:4,id:"curve-b"});
const rectangles=[];for(let index=0;index<8;index++){const x0=.3+index*.0375,x1=x0+.034,x=(x0+x1)/2,y=4*x-x*x;rectangles.push(axes.polygon({points:[[x0,0],[x1,0],[x1,y],[x0,y]],fill:p.blue+"66",stroke:p.blue+"aa",width:1}));}const band=[];for(let index=0;index<18;index++){const x0=2+index/18,x1=2+(index+1)/18,a0=4*x0-x0*x0,a1=4*x1-x1*x1,b0=.8*x0*x0-3*x0+4,b1=.8*x1*x1-3*x1+4;band.push(axes.polygon({points:[[x0,b0],[x1,b1],[x1,a1],[x0,a0]],fill:p.gold+"68",stroke:"#00000000",width:0}));}const bounds=[axes.line({from:[2,0],to:[2,4],stroke:p.gold,width:2}),axes.line({from:[3,0],to:[3,3],stroke:p.gold,width:2})];scene.create(axes,.4,"ease_out").create([curveA,curveB],.85,"ease_out",0).create(rectangles,.42,"ease_out",.025).create(band,.62,"ease_out",.012).create(bounds,.35,"ease_out",0).wait(.8);return scene;`;

const POLYGON_ON_AXES_JS = `const p={paper:"#f7f8fb",ink:"#182033",muted:"#687086",grid:"#dce2ed",blue:"#2563eb",gold:"#eab308",orange:"#f97316"};const scene=tmath.scene({width:960,height:540,fps:60,background:p.paper,camera:{mode:"fixed",view:"2d",height:8}});scene.text({text:"POLYGON ON AXES",point:[-5.8,3.15],align:[0,.5],font:"Pretendard",size:27,fill:p.ink});scene.text({text:"xy = 25  ·  constant-area rectangle",point:[-5.77,2.65],align:[0,.5],font:"Pretendard",size:13,fill:p.muted});const axes=scene.space({x:[0,10,1],y:[0,10,1],matrix:[.52,0,0,-2.6,0,.52,0,-2.85,0,0,1,0,0,0,0,1],color:p.grid,axis_x:p.ink,axis_y:p.ink,numbers:true,number_size:9,id:"axes"});
const curvePoints=[];for(let sample=0;sample<=60;sample++){const x=2.5+.125*sample;curvePoints.push([x,25/x]);}const curve=axes.plot({points:curvePoints,stroke:p.gold,width:4,id:"hyperbola"});const rectanglePoints=index=>{const [x,y]=curvePoints[index];return [[x,y],[0,y],[0,0],[x,0]];},trackerPoints=index=>{const [x,y]=curvePoints[index],r=.13;return [[x-r,y],[x,y+r],[x+r,y],[x,y-r]];};const makeState=(index,stage)=>{const rectangle=axes.polygon({points:rectanglePoints(index),fill:p.blue+"3d",stroke:p.blue,width:2.5,id:"area-"+stage}),tracker=axes.polygon({points:trackerPoints(index),fill:p.orange,stroke:p.paper,width:1.25,layer:10,id:"tracker-"+stage});return [rectangle,tracker];};let currentIndex=20,stage=0,[rectangle,tracker]=makeState(currentIndex,stage);scene.create(axes,.48,"gentle").create(curve,1,"gentle").drawBorderThenFill(rectangle,.78,"gentle").growFromCenter(tracker,.26,"gentle");const animateTo=(targetIndex,duration)=>{const direction=targetIndex>currentIndex?1:-1,count=Math.abs(targetIndex-currentIndex),weights=[];let totalWeight=0;for(let step=1;step<=count;step++){const phase=(step-.5)/count,weight=.55+1.45*Math.cos(Math.PI*phase)**2;weights.push(weight);totalWeight+=weight;}for(let step=0;step<count;step++){currentIndex+=direction;stage++;const [nextRectangle,nextTracker]=makeState(currentIndex,stage);scene.morph([rectangle,tracker],[nextRectangle,nextTracker],duration*weights[step]/totalWeight,"linear",0);rectangle=nextRectangle;tracker=nextTracker;}};animateTo(48,1.35);scene.wait(.18);animateTo(6,2.1);scene.wait(.22);animateTo(20,1.25);scene.wait(.8);return scene;`;

const MOVING_ZOOMED_SCENE_JS = `const p={paper:"#f7f8fb",panel:"#ffffff",ink:"#182033",muted:"#687086",purple:"#7c3aed",red:"#ef4444"},columns=48,rows=30,buffer=[],channel=value=>Math.max(0,Math.min(255,Math.floor(value+.5))),hex=value=>value.toString(16).padStart(2,"0");for(let row=0;row<rows;row++){const v=row/(rows-1);for(let column=0;column<columns;column++){const u=column/(columns-1),glow=Math.exp(-10*((u-.68)**2+(v-.34)**2)),r=channel(28+205*u+42*glow),g=channel(48+150*(1-v)+50*glow),b=channel(118+105*v-62*u+30*Math.sin(6.28*(u+v)));buffer.push("#"+hex(r)+hex(g)+hex(b));}}
const imageWidth=8.4,zoomScale=3,first=[-2.6,1.15],second=[2.35,-1.1],third=[-.3,0],delta=(from,to)=>[to[0]-from[0],to[1]-from[1]],scaled=(value,scale)=>value.map(component=>component*scale);const source=tmath.scene({width:570,height:360,fps:60,background:p.panel,camera:{mode:"fixed",view:"2d",height:6.2}}),sourceImage=source.image({pixels:buffer,size:[columns,rows],center:[0,0],width:imageWidth,filter:"bilinear",layer:0,id:"gradient-buffer-source"}),frame=source.rectangle({center:first,size:[1.894,2.067],corner:.04,fill:"#00000010",stroke:p.purple,width:5,layer:30,id:"zoom-frame"});source.fadeIn(sourceImage,{scale:.96,duration:.45,curve:"ease_out"}).create(frame,.25,"ease_out").wait(.2).shift(frame,delta(first,second),1,"ease_in_out").shift(frame,delta(second,third),.85,"ease_in_out").wait(.45);
const zoom=tmath.scene({width:330,height:360,fps:60,background:p.panel,camera:{mode:"fixed",view:"2d",height:6.2}}),zoomImage=zoom.image({pixels:buffer,size:[columns,rows],center:scaled(first,-zoomScale),width:imageWidth*zoomScale,filter:"nearest",id:"gradient-buffer-zoom"});zoom.fadeIn(zoomImage,{scale:.96,duration:.45,curve:"ease_out"}).wait(.45).shift(zoomImage,scaled(delta(first,second),-zoomScale),1,"ease_in_out").shift(zoomImage,scaled(delta(second,third),-zoomScale),.85,"ease_in_out").wait(.45);
const page=tmath.scene({width:960,height:540,fps:60,background:p.paper,camera:{mode:"fixed",view:"2d",height:7}});page.text({text:"IMAGE BUFFER  /  MOVING ZOOM",point:[-5.7,2.72],align:[0,.5],font:"Pretendard",size:27,fill:p.ink});page.text({text:"one generated pixel buffer, sampled through two image filters",point:[-5.68,2.2],align:[0,.5],font:"Pretendard",size:13,fill:p.muted});page.text({text:"BILINEAR SOURCE",point:[-5.28,1.72],align:[0,.5],font:"Pretendard",size:11,fill:p.purple});page.text({text:"NEAREST  ·  3×",point:[2.02,1.72],align:[0,.5],font:"Pretendard",size:11,fill:p.red});page.viewport(source,{x:.03,y:.29,width:.58,height:.66}).viewport(zoom,{x:.63,y:.29,width:.34,height:.66});return page;`;

const THREE_D_LIGHT_SOURCE_JS = `const p={paper:"#f7f8fb",ink:"#182033",muted:"#687086",red:"#ef4444",gold:"#f59e0b",x:"#ef4444",y:"#16a34a",z:"#2563eb"};const scene=tmath.scene({width:960,height:540,fps:60,background:p.paper,camera:{mode:"fixed",view:"3d",eye:[5.7,4.2,6.4],target:[0,0,0],up:[0,1,0],projection:"perspective",fov:.68,near:.1,far:100}});scene.text({text:"LIGHT SOURCE POSITION",point:[-3.7,3.05,0],align:[0,.5],orientation:"billboard",font:"Pretendard",size:25,fill:p.ink});scene.text({text:"surface luminance follows n · l",point:[-3.68,2.58,0],align:[0,.5],orientation:"billboard",font:"Pretendard",size:12,fill:p.muted});const axes=[scene.arrow({from:[-2.3,0,0],to:[2.3,0,0],stroke:p.x,width:2.5,tip:10}),scene.arrow({from:[0,-2.3,0],to:[0,2.3,0],stroke:p.y,width:2.5,tip:10}),scene.arrow({from:[0,0,-2.3],to:[0,0,2.3],stroke:p.z,width:2.5,tip:10})];const lightA=[3.2,2.4,3.8],lightB=[-3,1.4,2.4];const normalize=v=>{const l=Math.hypot(...v);return v.map(x=>x/l);};const hex=n=>Math.max(0,Math.min(255,Math.floor(n))).toString(16).padStart(2,"0");const shade=(normal,light)=>{const l=normalize(light);let amount=Math.max(0,normal[0]*l[0]+normal[1]*l[1]+normal[2]*l[2]);amount=.16+.84*amount;return "#"+hex(72+178*amount)+hex(22+72*amount)+hex(30+62*amount);};const spherePoint=(u,v)=>[1.55*Math.cos(u)*Math.cos(v),1.55*Math.sin(u),1.55*Math.cos(u)*Math.sin(v)];const cells=[],normals=[],rows=9,columns=18;for(let row=0;row<rows;row++){const u0=-1.43+2.86*row/rows,u1=-1.43+2.86*(row+1)/rows;for(let column=0;column<columns;column++){const v0=2*Math.PI*column/columns,v1=2*Math.PI*(column+1)/columns,um=(u0+u1)/2,vm=(v0+v1)/2,normal=[Math.cos(um)*Math.cos(vm),Math.sin(um),Math.cos(um)*Math.sin(vm)];normals.push(normal);cells.push(scene.polygon({points:[spherePoint(u0,v0),spherePoint(u0,v1),spherePoint(u1,v1),spherePoint(u1,v0)],fill:shade(normal,lightA),stroke:"#ffffff22",width:.5}));}}const light=scene.point({point:lightA,fill:p.gold,stroke:p.paper,width:3,radius:10,layer:20,id:"light"});scene.create(axes,.4,"ease_out",0).create(cells,.65,"ease_out",.002).growFromCenter(light,.22,"snappy");const forward=[{target:light,shift:lightB.map((x,i)=>x-lightA[i])}];cells.forEach((cell,index)=>forward.push({target:cell,fill:shade(normals[index],lightB)}));scene.play(forward,1,"ease_in_out",0);const backward=[{target:light,shift:lightA.map((x,i)=>x-lightB[i])}];cells.forEach((cell,index)=>backward.push({target:cell,fill:shade(normals[index],lightA)}));scene.play(backward,1,"ease_in_out",0).wait(.7);return scene;`;

const THREE_D_CAMERA_ILLUSION_JS = `const p={paper:"#f7f8fb",ink:"#182033",muted:"#687086",blue:"#2563eb",x:"#ef4444",y:"#16a34a",z:"#2563eb"};const scene=tmath.scene({width:960,height:540,fps:60,background:p.paper,camera:{mode:"fixed",view:"3d",eye:[5.8,4.6,6.2],target:[0,0,0],up:[0,1,0],projection:"perspective",fov:.68,near:.1,far:100}});scene.text({text:"3D CAMERA ILLUSION",point:[-3.8,3.05,0],align:[0,.5],font:"Pretendard",size:25,fill:p.ink});scene.text({text:"the object is still; only the view orbits",point:[-3.77,2.58,0],align:[0,.5],font:"Pretendard",size:12,fill:p.muted});const axes=[scene.arrow({from:[-2.6,0,0],to:[2.6,0,0],stroke:p.x,width:3,tip:10}),scene.arrow({from:[0,-2.6,0],to:[0,2.6,0],stroke:p.y,width:3,tip:10}),scene.arrow({from:[0,0,-2.6],to:[0,0,2.6],stroke:p.z,width:3,tip:10})],circlePoints=[];for(let sample=0;sample<=96;sample++){const a=2*Math.PI*sample/96;circlePoints.push([2*Math.cos(a),0,2*Math.sin(a)]);}const circle=scene.plot({points:circlePoints,stroke:p.blue,width:6,id:"fixed-circle"}),normal=scene.vector({origin:[0,0,0],value:[0,1.8,0],stroke:"#f59e0b",width:4,tip:13,id:"normal"});scene.create(axes,.4,"ease_out",0).create(circle,.8,"ease_out").create(normal,.35,"ease_out");[[-5.8,4.6,6.2],[-5.8,4.6,-6.2],[5.8,4.6,-6.2],[5.8,4.6,6.2]].forEach(eye=>scene.look({view:"3d",eye,target:[0,0,0],up:[0,1,0],projection:"perspective",fov:.68,near:.1,far:100},.65,"linear"));scene.wait(.7);return scene;`;

const THREE_D_SURFACE_PLOT_JS = `const p={paper:"#f7f8fb",ink:"#182033",muted:"#687086",blue:"#2563eb"};const scene=tmath.scene({width:960,height:540,fps:60,background:p.paper,camera:{mode:"fixed",view:"3d",eye:[5.8,4.4,6.4],target:[0,.25,0],up:[0,1,0],projection:"perspective",fov:.66,near:.1,far:100}});scene.text({text:"3D SURFACE PLOT",point:[-3.8,3.05,0],align:[0,.5],font:"Pretendard",size:25,fill:p.ink});scene.text({text:"Gaussian density sampled as a surface",point:[-3.77,2.58,0],align:[0,.5],font:"Pretendard",size:12,fill:p.muted});const columns=31,rows=31,points=[],gaussian=(x,z)=>2.35*Math.exp(-(x*x+z*z)/1.45)-.75;for(let row=0;row<rows;row++){const z=-2.7+5.4*row/(rows-1);for(let column=0;column<columns;column++){const x=-2.7+5.4*column/(columns-1);points.push([x,gaussian(x,z),z]);}}const surface=scene.surface({points,size:[columns,rows],mode:"solid_mesh",shading:false,fill:p.blue+"4d",stroke:p.blue+"b8",width:.75,id:"gaussian-surface"});scene.create(surface,1,"gentle").look({view:"3d",eye:[-5.4,4.8,6],target:[0,.25,0],up:[0,1,0],projection:"perspective",fov:.66,near:.1,far:100},1.2,"ease_in_out").wait(.8);return scene;`;

const OPENING_JS = `const p={paper:"#f7f8fb",ink:"#182033",muted:"#687086",grid:"#b9c5d8",blue:"#2563eb"};const scene=tmath.scene({width:960,height:540,fps:60,background:p.paper,camera:{mode:"fixed",view:"2d",height:7}});const title=scene.text({text:"TMATH",point:[0,.55],font:"Pretendard",size:58,fill:p.ink,id:"opening-title"}),formula=scene.text({text:"Σ 1/n²  =  π²/6",point:[0,-.45],font:"Pretendard",size:24,fill:p.blue,id:"opening-formula"});scene.write(title,.65,"ease_out").fadeIn(formula,{shift:[0,-.2],duration:.42,curve:"ease_out"}).wait(.35).fadeOut(title,{shift:[-.4,0],duration:.3,curve:"ease_in"}).fadeOut(formula,{shift:[0,-.2],duration:.3,curve:"ease_in"});
const originals=[],warpedOptions=[],warp=(x,y)=>[x+.34*Math.sin(1.2*y),y+.34*Math.sin(1.2*x)];for(let index=-7;index<=7;index++){const vertical=[],verticalWarped=[],horizontal=[],horizontalWarped=[],coordinate=index*.48;for(let sample=0;sample<=32;sample++){const value=-3.4+6.8*sample/32;vertical.push([coordinate,value]);verticalWarped.push(warp(coordinate,value));horizontal.push([value,coordinate]);horizontalWarped.push(warp(value,coordinate));}const color=index===0?p.blue:p.grid,width=index===0?2.4:1.2;originals.push(scene.plot({points:vertical,stroke:color,width,id:"grid-v-"+index}),scene.plot({points:horizontal,stroke:color,width,id:"grid-h-"+index}));warpedOptions.push({points:verticalWarped,stroke:color,width,id:"warped-v-"+index},{points:horizontalWarped,stroke:color,width,id:"warped-h-"+index});}const gridTitle=scene.text({text:"a nonlinear function applied to a grid",point:[-5.55,2.72],align:[0,.5],font:"Pretendard",size:18,fill:p.ink,id:"grid-title"});scene.create(originals,.75,"ease_out",.008).fadeIn(gridTitle,{shift:[0,.15],duration:.3,curve:"ease_out"});const warped=warpedOptions.map(options=>scene.plot(options));scene.morph(originals,warped,1.2,"ease_in_out",0);const restored=[];for(let index=0;index<originals.length;index++){const points=[],lineIndex=Math.floor(index/2)-7,vertical=index%2===0,coordinate=lineIndex*.48;for(let sample=0;sample<=32;sample++){const value=-3.4+6.8*sample/32;points.push(vertical?[coordinate,value]:[value,coordinate]);}restored.push(scene.plot({points,stroke:lineIndex===0?p.blue:p.grid,width:lineIndex===0?2.4:1.2,id:"restored-"+(index+1)}));}scene.morph(warped,restored,1,"ease_in_out",0).wait(.7);return scene;`;

const SINE_CURVE_UNIT_CIRCLE_JS = `const p={paper:"#f7f8fb",ink:"#182033",muted:"#687086",blue:"#2563eb",yellow:"#eab308",orange:"#f97316",grid:"#d8deea"};const scene=tmath.scene({width:960,height:540,fps:60,background:p.paper,camera:{mode:"fixed",view:"2d",height:7}});scene.text({text:"SINE CURVE  /  UNIT CIRCLE",point:[-5.7,2.72],align:[0,.5],font:"Pretendard",size:27,fill:p.ink});scene.text({text:"one rotating coordinate writes the wave",point:[-5.68,2.2],align:[0,.5],font:"Pretendard",size:13,fill:p.muted});const origin=[-3.7,-.25],circle=scene.circle({center:origin,radius:1.25,fill:"#00000000",stroke:p.blue,width:4,id:"unit-circle"}),axes=[scene.line({from:[-2.15,-.25],to:[5.55,-.25],stroke:p.ink,width:2}),scene.line({from:[-2.15,-1.75],to:[-2.15,1.45],stroke:p.ink,width:2})],samples=32;const state=step=>{const angle=2*Math.PI*step/samples,circlePoint=[origin[0]+1.25*Math.cos(angle),origin[1]+1.25*Math.sin(angle)],wavePoint=[-1.75+6.75*step/samples,circlePoint[1]],diamond=[[circlePoint[0]-.08,circlePoint[1]],[circlePoint[0],circlePoint[1]+.08],[circlePoint[0]+.08,circlePoint[1]],[circlePoint[0],circlePoint[1]-.08]],trace=[];for(let index=0;index<=samples;index++){const visible=Math.min(index,step),a=2*Math.PI*visible/samples;trace.push([-1.75+6.75*visible/samples,origin[1]+1.25*Math.sin(a)]);}return [diamond,[origin,circlePoint],[circlePoint,wavePoint],trace];};let values=state(0),dot=scene.polygon({points:values[0],fill:p.orange,stroke:p.orange,width:2,id:"circle-dot-0"}),radius=scene.plot({points:values[1],stroke:p.blue,width:3,id:"radius-0"}),bridge=scene.plot({points:values[2],stroke:p.yellow,width:2,id:"bridge-0"}),trace=scene.plot({points:values[3],stroke:p.orange,width:4,id:"trace-0"});scene.create([circle,...axes],.5,"ease_out",0).growFromCenter(dot,.18,"snappy");for(let step=1;step<=samples;step++){values=state(step);const nextDot=scene.polygon({points:values[0],fill:p.orange,stroke:p.orange,width:2,id:"circle-dot-"+step}),nextRadius=scene.plot({points:values[1],stroke:p.blue,width:3,id:"radius-"+step}),nextBridge=scene.plot({points:values[2],stroke:p.yellow,width:2,id:"bridge-"+step}),nextTrace=scene.plot({points:values[3],stroke:p.orange,width:4,id:"trace-"+step});scene.morph([dot,radius,bridge,trace],[nextDot,nextRadius,nextBridge,nextTrace],.055,"linear",0);dot=nextDot;radius=nextRadius;bridge=nextBridge;trace=nextTrace;}scene.wait(.8);return scene;`;

const examples = [
    [
        "following-graph-camera",
        "FollowingGraphCamera",
        "manim_following_graph_camera.lua",
        FOLLOWING_GRAPH_CAMERA_JS,
        "2D",
    ],
    [
        "brace-annotation",
        "BraceAnnotation",
        "manim_brace_annotation.lua",
        BRACE_ANNOTATION_JS,
        "2D",
    ],
    ["moving-around", "MovingAround", "manim_moving_around.lua", MOVING_AROUND_JS, "2D"],
    [
        "sin-cos-function-plot",
        "SinAndCosFunctionPlot",
        "manim_sin_cos_function_plot.lua",
        SIN_COS_FUNCTION_PLOT_JS,
        "2D",
    ],
    ["graph-area-plot", "GraphAreaPlot", "manim_graph_area_plot.lua", GRAPH_AREA_PLOT_JS, "2D"],
    ["polygon-on-axes", "PolygonOnAxes", "manim_polygon_on_axes.lua", POLYGON_ON_AXES_JS, "2D"],
    [
        "moving-zoomed-scene",
        "MovingZoomedSceneAround",
        "manim_moving_zoomed_scene.lua",
        MOVING_ZOOMED_SCENE_JS,
        "2D",
    ],
    [
        "three-d-light-source",
        "ThreeDLightSourcePosition",
        "manim_3d_light_source_position.lua",
        THREE_D_LIGHT_SOURCE_JS,
        "3D",
    ],
    [
        "three-d-camera-illusion",
        "ThreeDCameraIllusionRotation",
        "manim_3d_camera_illusion_rotation.lua",
        THREE_D_CAMERA_ILLUSION_JS,
        "3D",
    ],
    [
        "three-d-surface-plot",
        "ThreeDSurfacePlot",
        "manim_3d_surface_plot.lua",
        THREE_D_SURFACE_PLOT_JS,
        "3D",
    ],
    ["opening-manim", "OpeningManim", "manim_opening.lua", OPENING_JS, "2D"],
    [
        "sine-curve-unit-circle",
        "SineCurveUnitCircle",
        "manim_sine_curve_unit_circle.lua",
        SINE_CURVE_UNIT_CIRCLE_JS,
        "2D",
    ],
];

export const MANIM_EXAMPLES = examples.map(([id, title, lua, js, dimension, assets]) => ({
    id: `manim-${id}`,
    title,
    description: "TMATH interpretation of the Manim Community example.",
    category: "MANIM Community",
    dimension,
    fonts: PRETENDARD,
    assets,
    lua: luaSources[lua],
    js,
}));
