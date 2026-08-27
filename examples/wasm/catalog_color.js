const PRETENDARD = [{ name: "Pretendard", url: "./Pretendard.ttf", mime: "ttf" }];

const LUA = `local p={paper="#f3f0e8",panel="#fffdfa",ink="#202124",muted="#666a73",soft="#8a8e96",rule="#d8d4cb",grid="#d7d3ca",srgb="#315f91",p3="#d23c72",white="#fff6cf"}
local function clamp(v,a,b)return math.max(a,math.min(b,v))end
local function gamma(v)if v<=.0031308 then return 12.92*v end return 1.055*v^(1/2.4)-.055 end
local function hex(rgb,alpha)
 local r=math.floor(clamp(gamma(clamp(rgb[1],0,1)),0,1)*255+.5)
 local g=math.floor(clamp(gamma(clamp(rgb[2],0,1)),0,1)*255+.5)
 local b=math.floor(clamp(gamma(clamp(rgb[3],0,1)),0,1)*255+.5)
 return string.format("#%02x%02x%02x%s",r,g,b,alpha or "ff")
end
local p3xyz={.4865709486,.2656676932,.1982172852,.2289745641,.6917385218,.0792869141,0,.0451133819,1.0439443689}
local xyzp3={2.4934969119,-.9313836179,-.4027107845,-.8294889696,1.7626640603,.0236246858,.0358458302,-.0761723893,.9568845240}
local sxyz={.4123907993,.3575843394,.1804807884,.2126390059,.7151686788,.0721923154,.0193308187,.1191947798,.9505321522}
local xyzs={3.2409699419,-1.5373831776,-.4986107603,-.9692436363,1.8759675015,.0415550574,.0556300797,-.2039769589,1.0569715142}
local function mul(m,v)return{m[1]*v[1]+m[2]*v[2]+m[3]*v[3],m[4]*v[1]+m[5]*v[2]+m[6]*v[3],m[7]*v[1]+m[8]*v[2]+m[9]*v[3]}end
local function rgbxyY(rgb,m)local q=mul(m,rgb);local sum=q[1]+q[2]+q[3];if sum<1e-8 then return nil end return{q[1]/sum,q[2]/sum,q[2]}end
local function xyYrgb(x,y,Y,m)if y<=0 or x+y>1 then return nil end return mul(m,{x*Y/y,Y,(1-x-y)*Y/y})end
local function inside_cube(v)local e=1e-5;return v and v[1]>=-e and v[1]<=1+e and v[2]>=-e and v[2]<=1+e and v[3]>=-e and v[3]<=1+e end
local spectral={{.17411,.00496},{.17380,.00492},{.17334,.00480},{.17258,.00480},{.17141,.00510},{.16888,.00690},{.16441,.01086},{.15664,.01771},{.14396,.02970},{.12412,.05780},{.09129,.13270},{.04539,.29498},{.00817,.53842},{.01387,.75019},{.07430,.83380},{.15472,.80586},{.22962,.75433},{.30160,.69231},{.37310,.62445},{.44406,.55472},{.51249,.48659},{.57515,.42423},{.62704,.37249},{.66576,.33401},{.69151,.30834},{.70792,.29203},{.71903,.28094},{.72599,.27401},{.72997,.27003},{.73199,.26801},{.73342,.26658},{.73439,.26561},{.73469,.26531}}
local function inpoly(x,y,q)local inside,j=false,#q;for i=1,#q do local a,b=q[i],q[j];if((a[2]>y)~=(b[2]>y))and x<(b[1]-a[1])*(y-a[2])/(b[2]-a[2])+a[1] then inside=not inside end;j=i end;return inside end

local page=tmath.scene{width=960,height=540,fps=30,loop=false,antialiasing=true,background=p.paper,camera={mode="fixed",view="2d",height=9}}
local root=page:space{x={-8,8,1},y={-4.5,4.5,1},opacity=0}
local function text(v,q,s,c,id,a)return root:text{text=v,point=q,size=s,font="Pretendard",fill=c or p.ink,id=id,align=a or{.5,.5}}end
text("COLOR SPACE  /  xyY VOLUME",{-7.25,3.78},12,p.p3,"eyebrow",{0,.5})
text("Display P3 is a three-dimensional color volume",{-7.25,3.29},27,p.ink,"title",{0,.5})
text("Chromaticity bends across x and y; luminance Y gives the gamut its depth.",{-7.25,2.72},14,p.muted,"subtitle",{0,.5})
root:line{from={-7.25,2.53},to={7.25,2.53},color=p.rule,width=1}
text("Visualization uses W3C D65 matrices; hex output is an sRGB-display proxy for P3 samples.",{0,-4.13},10,p.muted,"output-note")
page:create(root,.45,"ease_out")

local volumeScene=tmath.scene{width=614,height=373,fps=30,background=p.panel,camera={mode="fixed",view="3d",eye={8.8,7.2,9.4},target={2.75,2.8,2.15},up={0,1,0},projection="perspective",fov=.62,near=.1,far=100}}
local volume=volumeScene:space{x={0,.8,.2},y={0,.9,.2},z={0,1,.25},color=p.grid,axis_x="#716c65",axis_y="#716c65",axis_z="#716c65",width=1,matrix={7,0,0,0,0,7,0,0,0,0,4.8,0,0,0,0,1},id="xyY-space"}
local raster=volume:space{x={0,42,1},y={0,46,1},z={0,1,1},opacity=0,matrix={.8/42,0,0,0,0,.9/46,0,0,0,0,1,0,0,0,0,1}}
local slices={}
for layer=1,13 do
 local Y=.03+(layer-1)*.078;local patches={}
 for row=0,45 do for column=0,41 do
  local x=(column+.5)*.8/42;local y=(row+.5)*.9/46;local rgb=xyYrgb(x,y,Y,xyzp3)
  if inside_cube(rgb)then patches[#patches+1]={region={column,row,1,1},color=hex(rgb,"dc")}end
 end end
 slices[#slices+1]=raster:cell{origin={0,0,Y},size={42,46},depth=.010,mode="full",color="#00000000",patches=patches,id="p3-slice-"..layer}
end
local function edges(matrix,color,prefix)
 local out={}
 for variable=1,3 do local a=variable%3+1;local b=(variable+1)%3+1
  for va=0,1 do for vb=0,1 do local points={}
   for sample=0,40 do local rgb={0,0,0};rgb[variable],rgb[a],rgb[b]=sample/40,va,vb;local q=rgbxyY(rgb,matrix);if q then points[#points+1]=q end end
   if #points>1 then out[#out+1]=volume:plot{points=points,color=color,width=2.2,id=prefix.."-edge-"..variable.."-"..va..vb}end
  end end
 end
 return out
end
local sedges=edges(sxyz,"#315f91bb","srgb");local pedges=edges(p3xyz,"#d23c72dd","p3")
local primaries={rgbxyY({1,0,0},p3xyz),rgbxyY({0,1,0},p3xyz),rgbxyY({0,0,1},p3xyz)}
local markers={};local mc={"#ff4e48","#40c85a","#4d6cff"};local mn={"R","G","B"}
for i,q in ipairs(primaries)do markers[#markers+1]=volume:point{point=q,fill=mc[i],stroke=p.panel,width=2,radius=6,id="p3-primary-"..mn[i]};markers[#markers+1]=volume:text{text=mn[i],point={q[1],q[2],q[3]+.045},size=12,font="Pretendard",fill=mc[i]}end
local white=volume:point{point={.3127,.3290,1},fill=p.white,stroke=p.ink,width=2,radius=6,id="d65-white"}
local labels={volume:text{text="x",point={.84,0,0},size=12,font="Pretendard",fill=p.muted},volume:text{text="y",point={0,.69,0},size=12,font="Pretendard",fill=p.muted},volume:text{text="Y",point={0,0,1.06},size=12,font="Pretendard",fill=p.muted}}
volumeScene:create(volume,.45,"ease_out");volumeScene:create(sedges,.75,"linear",.018);volumeScene:create(slices,1.45,"linear",.065);volumeScene:create(pedges,.85,"ease_out",.018);volumeScene:create(markers,.38,"ease_out",.035);volumeScene:fade_in(white,{scale=.55,duration=.28,easing="ease_out"});volumeScene:create(labels,.28,"ease_out",.04)
volumeScene:look({view="3d",eye={9.5,9,6.9},target={2.75,2.8,2.15},up={0,1,0},projection="perspective",fov=.62,near=.1,far=100},1.45,"ease_in_out");volumeScene:wait(.55)

local sliceScene=tmath.scene{width=269,height=373,fps=30,background=p.panel,camera={mode="fixed",view="2d",height=9}}
local side=sliceScene:space{x={-3.25,3.25,1},y={-4.5,4.5,1},opacity=0}
local function st(v,q,s,c,a)return side:text{text=v,point=q,size=s,font="Pretendard",fill=c or p.ink,align=a or{.5,.5}}end
st("CHROMATICITY SLICE",{-2.72,3.90},11,p.soft,{0,.5});st("Y = 0.50",{-2.72,3.48},20,p.ink,{0,.5});st("CIE locus · 10 nm samples",{-2.72,3.04},10,p.muted,{0,.5})
local cols,rows=52,58
local chart=side:space{x={0,cols,1},y={0,rows,1},opacity=0,matrix={5.1/cols,0,0,-2.55,0,5.72/rows,0,-2.55,0,0,1,0,0,0,0,1}}
local patches={}
for row=0,rows-1 do for col=0,cols-1 do local x=(col+.5)*.78/cols;local y=(row+.5)*.87/rows
 if inpoly(x,y,spectral)then local rgb=xyYrgb(x,y,.5,xyzs);if rgb then local maximum=math.max(rgb[1],rgb[2],rgb[3]);if maximum>1 then rgb={rgb[1]/maximum,rgb[2]/maximum,rgb[3]/maximum}end;patches[#patches+1]={region={col,row,1,1},color=hex(rgb)}end end
end end
local gradient=chart:cell{origin={0,0},size={cols,rows},mode="full",color="#00000000",patches=patches,id="chromaticity-gradient"}
local function xy(x,y)return{-2.55+x/.78*5.1,-2.55+y/.87*5.72}end
local locus={};for i,q in ipairs(spectral)do locus[i]=xy(q[1],q[2])end
local spectrum=side:plot{points=locus,color="#ffffffee",width=2.5,id="spectral-locus"};local purple=side:line{from=locus[#locus],to=locus[1],color="#9b5bc5",width=2.5}
local function triangle(q,c,w,id)local out={};for i,v in ipairs(q)do out[i]=xy(v[1],v[2])end;return side:polygon{points=out,fill="#00000000",stroke=c,width=w,id=id}end
local sg=triangle({{.64,.33},{.3,.6},{.15,.06}},p.srgb,2.5,"srgb-slice");local pg=triangle({{.68,.32},{.265,.69},{.15,.06}},p.p3,3.4,"p3-slice")
local d=xy(.3127,.3290);local dp=side:point{point=d,fill=p.white,stroke=p.ink,width=1.5,radius=5}
local legend={side:line{from={-2.6,-3.2},to={-1.95,-3.2},color=p.srgb,width=3},st("sRGB",{-1.77,-3.2},10,p.srgb,{0,.5}),side:line{from={.15,-3.2},to={.8,-3.2},color=p.p3,width=3.5},st("Display P3",{.98,-3.2},10,p.p3,{0,.5}),st("curved xyY volume ≠ flat triangle",{0,-3.72},10,p.muted)}
sliceScene:create(gradient,1.35,"linear");sliceScene:create({spectrum,purple},.75,"linear",.04);sliceScene:create(sg,.55,"ease_out");sliceScene:create(pg,.65,"ease_out");sliceScene:indicate(pg,{color=p.p3,scale=1.025,duration=.58,easing="ease_in_out"});sliceScene:fade_in(dp,{scale=.55,duration=.25,easing="ease_out"});sliceScene:create(legend,.4,"ease_out",.04);sliceScene:wait(1.8)
page:viewport(volumeScene,{x=.025,y=.225,width=.64,height=.69});page:viewport(sliceScene,{x=.69,y=.225,width=.285,height=.69})
return page
`;

const JS = `const p={paper:"#f3f0e8",panel:"#fffdfa",ink:"#202124",muted:"#666a73",soft:"#8a8e96",rule:"#d8d4cb",grid:"#d7d3ca",srgb:"#315f91",p3:"#d23c72",white:"#fff6cf"};
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
const gamma=v=>v<=.0031308?12.92*v:1.055*Math.pow(v,1/2.4)-.055;
const hex=(rgb,alpha="ff")=>"#"+rgb.map(v=>Math.round(clamp(gamma(clamp(v,0,1)),0,1)*255).toString(16).padStart(2,"0")).join("")+alpha;
const p3xyz=[.4865709486,.2656676932,.1982172852,.2289745641,.6917385218,.0792869141,0,.0451133819,1.0439443689];
const xyzp3=[2.4934969119,-.9313836179,-.4027107845,-.8294889696,1.7626640603,.0236246858,.0358458302,-.0761723893,.9568845240];
const sxyz=[.4123907993,.3575843394,.1804807884,.2126390059,.7151686788,.0721923154,.0193308187,.1191947798,.9505321522];
const xyzs=[3.2409699419,-1.5373831776,-.4986107603,-.9692436363,1.8759675015,.0415550574,.0556300797,-.2039769589,1.0569715142];
const mul=(m,v)=>[m[0]*v[0]+m[1]*v[1]+m[2]*v[2],m[3]*v[0]+m[4]*v[1]+m[5]*v[2],m[6]*v[0]+m[7]*v[1]+m[8]*v[2]];
const rgbxyY=(rgb,m)=>{const q=mul(m,rgb),sum=q[0]+q[1]+q[2];return sum<1e-8?null:[q[0]/sum,q[1]/sum,q[1]]};
const xyYrgb=(x,y,Y,m)=>y<=0||x+y>1?null:mul(m,[x*Y/y,Y,(1-x-y)*Y/y]);
const insideCube=v=>v&&v.every(c=>c>=-1e-5&&c<=1.00001);
const spectral=[[.17411,.00496],[.17380,.00492],[.17334,.00480],[.17258,.00480],[.17141,.00510],[.16888,.00690],[.16441,.01086],[.15664,.01771],[.14396,.02970],[.12412,.05780],[.09129,.13270],[.04539,.29498],[.00817,.53842],[.01387,.75019],[.07430,.83380],[.15472,.80586],[.22962,.75433],[.30160,.69231],[.37310,.62445],[.44406,.55472],[.51249,.48659],[.57515,.42423],[.62704,.37249],[.66576,.33401],[.69151,.30834],[.70792,.29203],[.71903,.28094],[.72599,.27401],[.72997,.27003],[.73199,.26801],[.73342,.26658],[.73439,.26561],[.73469,.26531]];
const inpoly=(x,y,q)=>{let inside=false,j=q.length-1;for(let i=0;i<q.length;j=i++){const a=q[i],b=q[j];if((a[1]>y)!==(b[1]>y)&&x<(b[0]-a[0])*(y-a[1])/(b[1]-a[1])+a[0])inside=!inside}return inside};

const page=tmath.scene({width:960,height:540,fps:30,loop:false,antialiasing:true,background:p.paper,camera:{mode:"fixed",view:"2d",height:9}});
const root=page.space({x:[-8,8,1],y:[-4.5,4.5,1],opacity:0});
const text=(v,q,s,c=p.ink,id,align=[.5,.5])=>{const o={text:v,point:q,size:s,font:"Pretendard",fill:c,align};if(id)o.id=id;return root.text(o)};
text("COLOR SPACE  /  xyY VOLUME",[-7.25,3.78],12,p.p3,"eyebrow",[0,.5]);
text("Display P3 is a three-dimensional color volume",[-7.25,3.29],27,p.ink,"title",[0,.5]);
text("Chromaticity bends across x and y; luminance Y gives the gamut its depth.",[-7.25,2.72],14,p.muted,"subtitle",[0,.5]);
root.line({from:[-7.25,2.53],to:[7.25,2.53],color:p.rule,width:1});
text("Visualization uses W3C D65 matrices; hex output is an sRGB-display proxy for P3 samples.",[0,-4.13],10,p.muted,"output-note");
page.create(root,.45,"ease_out");

const volumeScene=tmath.scene({width:614,height:373,fps:30,background:p.panel,camera:{mode:"fixed",view:"3d",eye:[8.8,7.2,9.4],target:[2.75,2.8,2.15],up:[0,1,0],projection:"perspective",fov:.62,near:.1,far:100}});
const volume=volumeScene.space({x:[0,.8,.2],y:[0,.9,.2],z:[0,1,.25],color:p.grid,axis_x:"#716c65",axis_y:"#716c65",axis_z:"#716c65",width:1,matrix:[7,0,0,0,0,7,0,0,0,0,4.8,0,0,0,0,1],id:"xyY-space"});
const raster=volume.space({x:[0,42,1],y:[0,46,1],z:[0,1,1],opacity:0,matrix:[.8/42,0,0,0,0,.9/46,0,0,0,0,1,0,0,0,0,1]});
const slices=[];
for(let layer=1;layer<=13;layer++){const Y=.03+(layer-1)*.078,patches=[];
 for(let row=0;row<46;row++)for(let column=0;column<42;column++){const x=(column+.5)*.8/42,y=(row+.5)*.9/46,rgb=xyYrgb(x,y,Y,xyzp3);if(insideCube(rgb))patches.push({region:[column,row,1,1],color:hex(rgb,"dc")})}
 slices.push(raster.cell({origin:[0,0,Y],size:[42,46],depth:.010,mode:"full",color:"#00000000",patches,id:"p3-slice-"+layer}));
}
const edges=(matrix,color,prefix)=>{const out=[];for(let variable=0;variable<3;variable++){const a=(variable+1)%3,b=(variable+2)%3;for(let va=0;va<=1;va++)for(let vb=0;vb<=1;vb++){const points=[];for(let sample=0;sample<=40;sample++){const rgb=[0,0,0];rgb[variable]=sample/40;rgb[a]=va;rgb[b]=vb;const q=rgbxyY(rgb,matrix);if(q)points.push(q)}if(points.length>1)out.push(volume.plot({points,color,width:2.2,id:prefix+"-edge-"+(variable+1)+"-"+va+vb}))}}return out};
const sedges=edges(sxyz,"#315f91bb","srgb"),pedges=edges(p3xyz,"#d23c72dd","p3");
const primaries=[rgbxyY([1,0,0],p3xyz),rgbxyY([0,1,0],p3xyz),rgbxyY([0,0,1],p3xyz)],markers=[],mc=["#ff4e48","#40c85a","#4d6cff"],mn=["R","G","B"];
primaries.forEach((q,i)=>{markers.push(volume.point({point:q,fill:mc[i],stroke:p.panel,width:2,radius:6,id:"p3-primary-"+mn[i]}));markers.push(volume.text({text:mn[i],point:[q[0],q[1],q[2]+.045],size:12,font:"Pretendard",fill:mc[i]}))});
const white=volume.point({point:[.3127,.329,1],fill:p.white,stroke:p.ink,width:2,radius:6,id:"d65-white"});
const labels=[volume.text({text:"x",point:[.84,0,0],size:12,font:"Pretendard",fill:p.muted}),volume.text({text:"y",point:[0,.69,0],size:12,font:"Pretendard",fill:p.muted}),volume.text({text:"Y",point:[0,0,1.06],size:12,font:"Pretendard",fill:p.muted})];
volumeScene.create(volume,.45,"ease_out").create(sedges,.75,"linear",.018).create(slices,1.45,"linear",.065).create(pedges,.85,"ease_out",.018).create(markers,.38,"ease_out",.035).fadeIn(white,{scale:.55,duration:.28,easing:"ease_out"}).create(labels,.28,"ease_out",.04);
volumeScene.look({view:"3d",eye:[9.5,9,6.9],target:[2.75,2.8,2.15],up:[0,1,0],projection:"perspective",fov:.62,near:.1,far:100},1.45,"ease_in_out").wait(.55);

const sliceScene=tmath.scene({width:269,height:373,fps:30,background:p.panel,camera:{mode:"fixed",view:"2d",height:9}});
const side=sliceScene.space({x:[-3.25,3.25,1],y:[-4.5,4.5,1],opacity:0});
const st=(v,q,s,c=p.ink,align=[.5,.5])=>side.text({text:v,point:q,size:s,font:"Pretendard",fill:c,align});
st("CHROMATICITY SLICE",[-2.72,3.9],11,p.soft,[0,.5]);st("Y = 0.50",[-2.72,3.48],20,p.ink,[0,.5]);st("CIE locus · 10 nm samples",[-2.72,3.04],10,p.muted,[0,.5]);
const cols=52,rows=58,chart=side.space({x:[0,cols,1],y:[0,rows,1],opacity:0,matrix:[5.1/cols,0,0,-2.55,0,5.72/rows,0,-2.55,0,0,1,0,0,0,0,1]}),patches=[];
for(let row=0;row<rows;row++)for(let col=0;col<cols;col++){const x=(col+.5)*.78/cols,y=(row+.5)*.87/rows;if(inpoly(x,y,spectral)){let rgb=xyYrgb(x,y,.5,xyzs);if(rgb){const maximum=Math.max(...rgb);if(maximum>1)rgb=rgb.map(v=>v/maximum);patches.push({region:[col,row,1,1],color:hex(rgb)})}}}
const gradient=chart.cell({origin:[0,0],size:[cols,rows],mode:"full",color:"#00000000",patches,id:"chromaticity-gradient"});
const xy=(x,y)=>[-2.55+x/.78*5.1,-2.55+y/.87*5.72],locus=spectral.map(q=>xy(q[0],q[1]));
const spectrum=side.plot({points:locus,color:"#ffffffee",width:2.5,id:"spectral-locus"}),purple=side.line({from:locus.at(-1),to:locus[0],color:"#9b5bc5",width:2.5});
const triangle=(q,c,w,id)=>side.polygon({points:q.map(v=>xy(v[0],v[1])),fill:"#00000000",stroke:c,width:w,id});
const sg=triangle([[.64,.33],[.3,.6],[.15,.06]],p.srgb,2.5,"srgb-slice"),pg=triangle([[.68,.32],[.265,.69],[.15,.06]],p.p3,3.4,"p3-slice"),d=xy(.3127,.329),dp=side.point({point:d,fill:p.white,stroke:p.ink,width:1.5,radius:5});
const legend=[side.line({from:[-2.6,-3.2],to:[-1.95,-3.2],color:p.srgb,width:3}),st("sRGB",[-1.77,-3.2],10,p.srgb,[0,.5]),side.line({from:[.15,-3.2],to:[.8,-3.2],color:p.p3,width:3.5}),st("Display P3",[.98,-3.2],10,p.p3,[0,.5]),st("curved xyY volume ≠ flat triangle",[0,-3.72],10,p.muted)];
sliceScene.create(gradient,1.35,"linear").create([spectrum,purple],.75,"linear",.04).create(sg,.55,"ease_out").create(pg,.65,"ease_out").indicate(pg,{color:p.p3,scale:1.025,duration:.58,easing:"ease_in_out"}).fadeIn(dp,{scale:.55,duration:.25,easing:"ease_out"}).create(legend,.4,"ease_out",.04).wait(1.8);
page.viewport(volumeScene,{x:.025,y:.225,width:.64,height:.69}).viewport(sliceScene,{x:.69,y:.225,width:.285,height:.69});
return page;
`;

export const COLOR_EXAMPLES = [
    {
        id: "color-space-display-p3",
        title: "Color Space · Display P3 xyY volume",
        description:
            "Build a sampled Display P3 volume in 3D xyY, orbit its curved RGB-cube boundary, and inspect a dense CIE 1931 gradient slice against sRGB.",
        category: "Color Space",
        dimension: "3D",
        fonts: PRETENDARD,
        lua: LUA,
        js: JS,
    },
];
