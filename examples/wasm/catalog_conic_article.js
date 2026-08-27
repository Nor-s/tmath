const PRETENDARD = [{ name: "Pretendard", url: "./Pretendard.ttf", mime: "ttf" }];

const luaSource = (
    body,
) => `local p={paper="#ffffff",ink="#202124",muted="#555b64",soft="#6a717c",rule="#d8dadd",solid="#b9bec5",accent="#9b3600",tint="#fff0e7",blue="#5e7a9b",mustard="#b8915a",purple="#6e6479",orange="#f28e2b"}
local scene=tmath.scene{width=960,height=540,fps=30,loop=false,background=p.paper,camera={mode="fixed",view="2d",height=9}}
local root=scene:space{x={-8,8,1},y={-4.5,4.5,1},opacity=0}
local function text(v,q,s,c,id,a)return root:text{text=v,point=q,size=s,font="Pretendard",fill=c or p.ink,id=id,align=a or{.5,.5}}end
local function rect(cx,cy,w,h)return{{cx-w/2,cy-h/2},{cx+w/2,cy-h/2},{cx+w/2,cy+h/2},{cx-w/2,cy+h/2}}end
local function mix(a,b,t)local function ch(c,o)return tonumber(string.sub(c,o,o+1),16)end;local function h(v)return string.format("%02x",math.floor(v+.5))end;return"#"..h(ch(a,2)+(ch(b,2)-ch(a,2))*t)..h(ch(a,4)+(ch(b,4)-ch(a,4))*t)..h(ch(a,6)+(ch(b,6)-ch(a,6))*t)end
local function arrowpts(a,b,sh,hd,hl)local dx,dy=b[1]-a[1],b[2]-a[2];local l=math.sqrt(dx*dx+dy*dy);local ux,uy=dx/l,dy/l;local nx,ny=-uy,ux;local jx,jy=b[1]-ux*hl,b[2]-uy*hl;return{{a[1]+nx*sh,a[2]+ny*sh},{jx+nx*sh,jy+ny*sh},{jx+nx*hd,jy+ny*hd},b,{jx-nx*hd,jy-ny*hd},{jx-nx*sh,jy-ny*sh},{a[1]-nx*sh,a[2]-ny*sh}}end
local function chip(cx,cy,w,h)local x0,x1=cx-w/2,cx+w/2;local y0,y1=cy-h/2,cy+h/2;return{{x0,y0},{cx,y0},{x1,y0},{x1,y1},{cx,y1},{x0,y1},{x0,cy}}end
local function header(n,title,subtitle,footer)text(n.."  /  THORVG CPU RASTERIZER",{-7.2,3.72},12,p.accent,"eyebrow",{0,.5});text(title,{-7.2,3.25},27,p.ink,"title",{0,.5});text(subtitle,{-7.2,2.72},14,p.soft,"subtitle",{0,.5});root:line{from={-7.2,2.48},to={7.2,2.48},color=p.rule,width=1};text(footer,{0,-4.05},12,p.soft,"footer")end
${body}
return scene
`;

const jsSource = (
    body,
) => `const p={paper:"#ffffff",ink:"#202124",muted:"#555b64",soft:"#6a717c",rule:"#d8dadd",solid:"#b9bec5",accent:"#9b3600",tint:"#fff0e7",blue:"#5e7a9b",mustard:"#b8915a",purple:"#6e6479",orange:"#f28e2b"};
const scene=tmath.scene({width:960,height:540,fps:30,loop:false,background:p.paper,camera:{mode:"fixed",view:"2d",height:9}});
const root=scene.space({x:[-8,8,1],y:[-4.5,4.5,1],opacity:0});
const text=(v,q,s,c=p.ink,id,align=[.5,.5])=>{const options={text:v,point:q,size:s,font:"Pretendard",fill:c,align};if(id!==undefined)options.id=id;return root.text(options)};
const rect=(cx,cy,w,h)=>[[cx-w/2,cy-h/2],[cx+w/2,cy-h/2],[cx+w/2,cy+h/2],[cx-w/2,cy+h/2]];
const mix=(a,b,t)=>"#"+[1,3,5].map(i=>Math.round(parseInt(a.slice(i,i+2),16)+(parseInt(b.slice(i,i+2),16)-parseInt(a.slice(i,i+2),16))*t).toString(16).padStart(2,"0")).join("");
const arrowpts=(a,b,sh,hd,hl)=>{const dx=b[0]-a[0],dy=b[1]-a[1],l=Math.hypot(dx,dy),ux=dx/l,uy=dy/l,nx=-uy,ny=ux,jx=b[0]-ux*hl,jy=b[1]-uy*hl;return[[a[0]+nx*sh,a[1]+ny*sh],[jx+nx*sh,jy+ny*sh],[jx+nx*hd,jy+ny*hd],b,[jx-nx*hd,jy-ny*hd],[jx-nx*sh,jy-ny*sh],[a[0]-nx*sh,a[1]-ny*sh]]};
const chip=(cx,cy,w,h)=>[[cx-w/2,cy-h/2],[cx,cy-h/2],[cx+w/2,cy-h/2],[cx+w/2,cy+h/2],[cx,cy+h/2],[cx-w/2,cy+h/2],[cx-w/2,cy]];
const header=(n,title,subtitle,footer)=>{text(n+"  /  THORVG CPU RASTERIZER",[-7.2,3.72],12,p.accent,"eyebrow",[0,.5]);text(title,[-7.2,3.25],27,p.ink,"title",[0,.5]);text(subtitle,[-7.2,2.72],14,p.soft,"subtitle",[0,.5]);root.line({from:[-7.2,2.48],to:[7.2,2.48],color:p.rule,width:1});text(footer,[0,-4.05],12,p.soft,"footer")};
${body}
return scene;
`;

const coordinatePullbackLua = `header("01","Inverse coefficients define pixel steps","A Surface x increment becomes xStep; a Surface y increment becomes yStep.","x += 1  ->  xStep = {a11, a21}      y += 1  ->  yStep = {a12, a22}")
local o={-3.75,-.05};local g=root:group{id="coordinate-geometry"};local grid={}
for i=0,7 do grid[#grid+1]=g:line{from={o[1]-2.275+i*.65,o[2]-1.95},to={o[1]-2.275+i*.65,o[2]+1.95},color=p.rule,width=1}end
for i=0,6 do grid[#grid+1]=g:line{from={o[1]-2.275,o[2]-1.95+i*.65},to={o[1]+2.275,o[2]-1.95+i*.65},color=p.rule,width=1}end
local pixel=g:polygon{points={{o[1],o[2]},{o[1]+.65,o[2]},{o[1]+.65,o[2]-.65},{o[1],o[2]-.65}},fill=p.tint,stroke=p.accent,width=3,id="unit-pixel"}
local xs=g:arrow{from=o,to={o[1]+1.15,o[2]},tip=13,color=p.blue,width=4,id="surface-x-step"};local ys=g:arrow{from=o,to={o[1],o[2]-1.15},tip=13,color=p.mustard,width=4,id="surface-y-step"}
local surface=text("SURFACE COORDINATES / y-down",{-6.7,1.98},13,p.muted,"surface-label",{0,.5});local labels={text("x += 1",{-2.62,.30},14,p.blue),text("y += 1",{-3.33,-1.34},14,p.mustard)}
local cols={root:rectangle{center={4.9,.70},size={.88,1.30},fill="#5e7a9b1a",stroke=p.blue,width=2},root:rectangle{center={6,.70},size={.88,1.30},fill="#b8915a1a",stroke=p.mustard,width=2}}
local entries={text("INVERSE LINEAR PART",{2.95,1.83},13,p.soft,nil,{0,.5}),text("[  a11   a12  ]",{5.45,1.02},17,p.ink),text("[  a21   a22  ]",{5.45,.38},17,p.ink)}
scene:create(grid,.72,"linear",.025);scene:create({xs,ys,pixel,surface,labels[1],labels[2]},.68,"ease_out",.06);scene:create(cols,.45,"ease_out",.08);scene:create(entries,.45,"ease_out",.05)
scene:fade_out(labels[1],{duration=.2});scene:fade_out(labels[2],{duration=.2});scene:transform(g,{1.15,.35,0,0,-.30,.90,0,0,0,0,1,0,0,0,0,1},1.7,"ease_in_out");scene:fade_out(surface,{duration=.2});scene:fade_in(text("GRADIENT SPACE",{-6.7,1.98},13,p.muted,nil,{0,.5}),{duration=.3})
scene:create({text("xStep = {a11, a21}",{4.9,-.55},16,p.blue),text("yStep = {a12, a22}",{4.9,-1.05},16,p.mustard),text("Each matrix column stores one prepared pixel step.",{4.7,-1.72},13,p.muted)},.55,"ease_out",.08)
local scan={};for i=0,4 do scan[#scan+1]=root:point{point={-6+i*.775,-2.30-i*.195},fill=p.blue,radius=5}end;scene:create(scan,.55,"ease_out",.04);scene:create({text("rx += a11",{4.9,-2.45},15,p.blue),text("ry += a21",{4.9,-2.80},15,p.blue),text("=> {rx, ry} += xStep",{4.9,-3.18},16,p.accent)},.5,"ease_out",.08);scene:wait(1)`;

const coordinatePullbackJs = `header("01","Inverse coefficients define pixel steps","A Surface x increment becomes xStep; a Surface y increment becomes yStep.","x += 1  ->  xStep = {a11, a21}      y += 1  ->  yStep = {a12, a22}");
const o=[-3.75,-.05],g=root.group({id:"coordinate-geometry"}),grid=[];
for(let i=0;i<8;i++)grid.push(g.line({from:[o[0]-2.275+i*.65,o[1]-1.95],to:[o[0]-2.275+i*.65,o[1]+1.95],color:p.rule,width:1}));
for(let i=0;i<7;i++)grid.push(g.line({from:[o[0]-2.275,o[1]-1.95+i*.65],to:[o[0]+2.275,o[1]-1.95+i*.65],color:p.rule,width:1}));
const pixel=g.polygon({points:[[o[0],o[1]],[o[0]+.65,o[1]],[o[0]+.65,o[1]-.65],[o[0],o[1]-.65]],fill:p.tint,stroke:p.accent,width:3,id:"unit-pixel"});
const xs=g.arrow({from:o,to:[o[0]+1.15,o[1]],tip:13,color:p.blue,width:4}),ys=g.arrow({from:o,to:[o[0],o[1]-1.15],tip:13,color:p.mustard,width:4});
const surface=text("SURFACE COORDINATES / y-down",[-6.7,1.98],13,p.muted,"surface-label",[0,.5]),lx=text("x += 1",[-2.62,.30],14,p.blue),ly=text("y += 1",[-3.33,-1.34],14,p.mustard);
const cols=[root.rectangle({center:[4.9,.70],size:[.88,1.30],fill:"#5e7a9b1a",stroke:p.blue,width:2}),root.rectangle({center:[6,.70],size:[.88,1.30],fill:"#b8915a1a",stroke:p.mustard,width:2})];
const entries=[text("INVERSE LINEAR PART",[2.95,1.83],13,p.soft,undefined,[0,.5]),text("[  a11   a12  ]",[5.45,1.02],17),text("[  a21   a22  ]",[5.45,.38],17)];
scene.create(grid,.72,"linear",.025).create([xs,ys,pixel,surface,lx,ly],.68,"ease_out",.06).create(cols,.45,"ease_out",.08).create(entries,.45,"ease_out",.05);
scene.fadeOut(lx,{duration:.2}).fadeOut(ly,{duration:.2}).transform(g,[1.15,.35,0,0,-.30,.90,0,0,0,0,1,0,0,0,0,1],1.7,"ease_in_out").fadeOut(surface,{duration:.2});
const gradient=text("GRADIENT SPACE",[-6.7,1.98],13,p.muted,undefined,[0,.5]);scene.fadeIn(gradient,{duration:.3});
scene.create([text("xStep = {a11, a21}",[4.9,-.55],16,p.blue),text("yStep = {a12, a22}",[4.9,-1.05],16,p.mustard),text("Each matrix column stores one prepared pixel step.",[4.7,-1.72],13,p.muted)],.55,"ease_out",.08);
const scan=[];for(let i=0;i<5;i++)scan.push(root.point({point:[-6+i*.775,-2.30-i*.195],fill:p.blue,radius:5}));scene.create(scan,.55,"ease_out",.04).create([text("rx += a11",[4.9,-2.45],15,p.blue),text("ry += a21",[4.9,-2.80],15,p.blue),text("=> {rx, ry} += xStep",[4.9,-3.18],16,p.accent)],.5,"ease_out",.08).wait(1);`;

const preparedGeometryLua = `header("02","Prepared seam geometry","The seam, normal, and pixel-footprint derivatives are computed once per update.","seam = {cos(angle), sin(angle)}    normal = {-seam.y, seam.x}    invFwidth = 1 / fwidth")
local c={-4.05,-.65};local seam=root:arrow{from=c,to={-1.31,-2.10},tip=15,color=p.accent,width=4};local normal=root:arrow{from=c,to={-5.15,-2.72},tip=13,color=p.muted,width=3};local fo={-6.1,.88};local xv={1.1,-.28};local yv={-.28,-.96}
local footprint=root:polygon{points={fo,{fo[1]+xv[1],fo[2]+xv[2]},{fo[1]+xv[1]+yv[1],fo[2]+xv[2]+yv[2]},{fo[1]+yv[1],fo[2]+yv[2]}},fill=p.tint,stroke=p.accent,width=2};local xs=root:polygon{points=arrowpts(fo,{fo[1]+xv[1],fo[2]+xv[2]},.025,.10,.23),fill=p.blue,stroke=p.blue};local ys=root:polygon{points=arrowpts(fo,{fo[1]+yv[1],fo[2]+yv[2]},.025,.10,.23),fill=p.mustard,stroke=p.mustard}
scene:create({seam,normal,footprint,xs,ys,text("GRADIENT SPACE / y-down",{-6.85,1.98},13,p.muted,nil,{0,.5})},.72,"ease_out",.08)
local xp={-5.98,1.18};local yp={-5.72,1.66};local xc=root:polygon{points=arrowpts(fo,{fo[1]+xv[1],fo[2]+xv[2]},.025,.10,.23),fill=p.blue,stroke=p.blue};local xt=root:polygon{points=arrowpts(fo,xp,.025,.10,.23),fill=p.blue,stroke=p.blue};scene:replacement_transform(xc,xt,.72,"ease_in_out")
local yc=root:polygon{points=arrowpts(fo,{fo[1]+yv[1],fo[2]+yv[2]},.025,.10,.23),fill=p.mustard,stroke=p.mustard};local yt=root:polygon{points=arrowpts(fo,yp,.025,.10,.23),fill=p.mustard,stroke=p.mustard};scene:replacement_transform(yc,yt,.72,"ease_in_out")
local f={text("dFdx = dot(normal, xStep)",{4.15,1.30},14,p.blue),text("dFdy = dot(normal, yStep)",{4.15,.86},14,p.mustard),text("fwidth = |dFdx| + |dFdy| = 1.23",{4.15,.36},14,p.accent),text("invFwidth = 1 / 1.23 = 0.81",{4.15,-.18},13,p.accent),text("distance = F x invFwidth = -1.10",{4.15,-.72},13,p.ink)}
local xfc=root:polygon{points=arrowpts(fo,xp,.025,.10,.23),fill=p.blue,stroke=p.blue};local xchip=root:polygon{points=chip(1.65,1.30,.35,.16),fill=p.blue,stroke=p.blue};scene:replacement_transform(xfc,xchip,.6,"ease_in_out");scene:create(f[1],.25,"ease_out")
local yfc=root:polygon{points=arrowpts(fo,yp,.025,.10,.23),fill=p.mustard,stroke=p.mustard};local ychip=root:polygon{points=chip(1.65,.86,.35,.16),fill=p.mustard,stroke=p.mustard};scene:replacement_transform(yfc,ychip,.6,"ease_in_out");scene:create({f[2],f[3],f[4],f[5]},.55,"ease_out",.08);scene:wait(1)`;

const preparedGeometryJs = `header("02","Prepared seam geometry","The seam, normal, and pixel-footprint derivatives are computed once per update.","seam = {cos(angle), sin(angle)}    normal = {-seam.y, seam.x}    invFwidth = 1 / fwidth");
const c=[-4.05,-.65],seam=root.arrow({from:c,to:[-1.31,-2.10],tip:15,color:p.accent,width:4}),normal=root.arrow({from:c,to:[-5.15,-2.72],tip:13,color:p.muted,width:3}),fo=[-6.1,.88],xv=[1.1,-.28],yv=[-.28,-.96];
const footprint=root.polygon({points:[fo,[fo[0]+xv[0],fo[1]+xv[1]],[fo[0]+xv[0]+yv[0],fo[1]+xv[1]+yv[1]],[fo[0]+yv[0],fo[1]+yv[1]]],fill:p.tint,stroke:p.accent,width:2});
const xs=root.polygon({points:arrowpts(fo,[fo[0]+xv[0],fo[1]+xv[1]],.025,.10,.23),fill:p.blue,stroke:p.blue}),ys=root.polygon({points:arrowpts(fo,[fo[0]+yv[0],fo[1]+yv[1]],.025,.10,.23),fill:p.mustard,stroke:p.mustard});scene.create([seam,normal,footprint,xs,ys,text("GRADIENT SPACE / y-down",[-6.85,1.98],13,p.muted,undefined,[0,.5])],.72,"ease_out",.08);
const xp=[-5.98,1.18],yp=[-5.72,1.66],xc=root.polygon({points:arrowpts(fo,[fo[0]+xv[0],fo[1]+xv[1]],.025,.10,.23),fill:p.blue,stroke:p.blue}),xt=root.polygon({points:arrowpts(fo,xp,.025,.10,.23),fill:p.blue,stroke:p.blue});scene.replacementTransform(xc,xt,.72,"ease_in_out");
const yc=root.polygon({points:arrowpts(fo,[fo[0]+yv[0],fo[1]+yv[1]],.025,.10,.23),fill:p.mustard,stroke:p.mustard}),yt=root.polygon({points:arrowpts(fo,yp,.025,.10,.23),fill:p.mustard,stroke:p.mustard});scene.replacementTransform(yc,yt,.72,"ease_in_out");
const f=[text("dFdx = dot(normal, xStep)",[4.15,1.30],14,p.blue),text("dFdy = dot(normal, yStep)",[4.15,.86],14,p.mustard),text("fwidth = |dFdx| + |dFdy| = 1.23",[4.15,.36],14,p.accent),text("invFwidth = 1 / 1.23 = 0.81",[4.15,-.18],13,p.accent),text("distance = F x invFwidth = -1.10",[4.15,-.72],13)];
const xfc=root.polygon({points:arrowpts(fo,xp,.025,.10,.23),fill:p.blue,stroke:p.blue}),xchip=root.polygon({points:chip(1.65,1.30,.35,.16),fill:p.blue,stroke:p.blue});scene.replacementTransform(xfc,xchip,.6,"ease_in_out").create(f[0],.25,"ease_out");const yfc=root.polygon({points:arrowpts(fo,yp,.025,.10,.23),fill:p.mustard,stroke:p.mustard}),ychip=root.polygon({points:chip(1.65,.86,.35,.16),fill:p.mustard,stroke:p.mustard});scene.replacementTransform(yfc,ychip,.6,"ease_in_out").create(f.slice(1),.55,"ease_out",.08).wait(1);`;

const scanlineRangeLua = `header("03","One range per scanline","Two affine predicates reduce pixel eligibility to one half-open interval.","[begin, end) = scanline intersection AA strip intersection forward half-plane")
local c={-3.75,.05};local band=root:polygon{points={{-7.05,1.73},{-.71,-2.07},{-.45,-1.63},{-6.79,2.17}},fill="#b8915a26",stroke="#b8915a00"};local scan=root:line{from={-6.9,.05},to={0,.05},color=p.ink,width=2};local candidate=root:polygon{points=rect(-3.75,.05,1.6,.46),fill="#b8915a29",stroke=p.mustard,width=2}
scene:fade_in(band,{duration=.45});scene:create(scan,.6,"linear");scene:fade_in(candidate,{scale=.85,duration=.4});local copy=root:polygon{points=rect(-3.75,.05,1.6,.46),fill="#b8915a29",stroke=p.mustard,width=2};local final=root:polygon{points=rect(-3.35,.05,.8,.46),fill="#9b36002e",stroke=p.accent,width=3};scene:replacement_transform(copy,final,.82,"ease_in_out")
scene:create({text("-0.5 < distance(i) < 0.5",{4.85,.65},16,p.mustard),text("seamProjection(i) >= 0",{4.85,-.18},16,p.accent),text("Both predicates are affine in i.",{4.85,-.88},14,p.muted)},.55,"ease_out",.1)
local cells,strip={},{};local x0=-5.9;for i=0,15 do cells[#cells+1]=root:rectangle{center={x0+i*.58,-2.83},size={.56,.48},fill=p.paper,stroke=p.solid,width=1.5};if i>=6 and i<=9 then strip[#strip+1]=root:rectangle{center={x0+i*.58,-2.83},size={.56,.48},fill="#f5ebdd",stroke=p.mustard,width=2}end end
scene:create(cells,.6,"ease_out",.025);scene:create(strip,.5,"ease_out",.08);scene:play({{target=strip[1],opacity=0},{target=strip[2],opacity=0},{target=strip[3],fill=p.tint,stroke=p.accent},{target=strip[4],fill=p.tint,stroke=p.accent}},.62,"ease_in_out",0);scene:create(text("final [8, 10)",{4.65,-3.14},13,p.accent),.3,"ease_out");scene:wait(1)`;

const scanlineRangeJs = `header("03","One range per scanline","Two affine predicates reduce pixel eligibility to one half-open interval.","[begin, end) = scanline intersection AA strip intersection forward half-plane");
const band=root.polygon({points:[[-7.05,1.73],[-.71,-2.07],[-.45,-1.63],[-6.79,2.17]],fill:"#b8915a26",stroke:"#b8915a00"}),scan=root.line({from:[-6.9,.05],to:[0,.05],color:p.ink,width:2}),candidate=root.polygon({points:rect(-3.75,.05,1.6,.46),fill:"#b8915a29",stroke:p.mustard,width:2});scene.fadeIn(band,{duration:.45}).create(scan,.6,"linear").fadeIn(candidate,{scale:.85,duration:.4});
const copy=root.polygon({points:rect(-3.75,.05,1.6,.46),fill:"#b8915a29",stroke:p.mustard,width:2}),finalRange=root.polygon({points:rect(-3.35,.05,.8,.46),fill:"#9b36002e",stroke:p.accent,width:3});scene.replacementTransform(copy,finalRange,.82,"ease_in_out").create([text("-0.5 < distance(i) < 0.5",[4.85,.65],16,p.mustard),text("seamProjection(i) >= 0",[4.85,-.18],16,p.accent),text("Both predicates are affine in i.",[4.85,-.88],14,p.muted)],.55,"ease_out",.1);
const cells=[],strip=[];for(let i=0;i<16;i++){cells.push(root.rectangle({center:[-5.9+i*.58,-2.83],size:[.56,.48],fill:p.paper,stroke:p.solid,width:1.5}));if(i>=6&&i<=9)strip.push(root.rectangle({center:[-5.9+i*.58,-2.83],size:[.56,.48],fill:"#f5ebdd",stroke:p.mustard,width:2}))}scene.create(cells,.6,"ease_out",.025).create(strip,.5,"ease_out",.08).play([{target:strip[0],opacity:0},{target:strip[1],opacity:0},{target:strip[2],fill:p.tint,stroke:p.accent},{target:strip[3],fill:p.tint,stroke:p.accent}],.62,"ease_in_out",0).create(text("final [8, 10)",[4.65,-3.14],13,p.accent),.3,"ease_out").wait(1);`;

const seamReconstructionLua = `header("04","Seam endpoint reconstruction","begin is the first eligible pixel; end is the one-past index returned by _conicAARange.","outside range: angular lookup    inside range: endpoint blend")
local e=root:rectangle{center={-5.7,1.2},size={.72,.72},fill=p.purple,stroke=p.solid};local b=root:rectangle{center={-3.55,1.2},size={.72,.72},fill=p.orange,stroke=p.solid};scene:create({e,b,text("rgbaEnd",{-5.7,.66},13,p.purple),text("rgbaBegin",{-3.55,.66},13,p.orange),text("dist = 255 x (distance + 0.5)",{2.6,1.4},17,p.accent),text("color = INTERPOLATE(rgbaBegin, rgbaEnd, dist)",{2.6,1},14,p.ink)},.65,"ease_out",.07)
local before,colors={},{};local x0=-4.9;for i=0,14 do local color;if i<7 then color=mix(p.purple,"#73778c",i/6)else color=mix(p.orange,"#f7b442",(i-7)/7)end;colors[i+1]=color;before[i+1]=root:polygon{points=rect(x0+i*.72,-.95,.72,.72),fill=color,stroke=p.paper,width=1}end;scene:create(before,.68,"ease_out",.025)
for i=0,14 do local pts=rect(x0+i*.72,-.95,.72,.72);local sc=colors[i+1];local tc=sc;if i==6 then pts=rect(-5.7,1.2,.72,.72);sc=p.purple;tc=mix(p.purple,p.orange,.13)elseif i==7 then pts=rect(-3.55,1.2,.72,.72);sc=p.orange;tc=mix(p.purple,p.orange,.87)end;local cp=root:polygon{points=pts,fill=sc,stroke=p.paper};local target=root:polygon{points=rect(x0+i*.72,-2.63,.72,.72),fill=tc,stroke=p.paper};scene:replacement_transform(cp,target,.12,"ease_in_out")end
scene:create({root:rectangle{center={x0+6.5*.72,-2.63},size={1.44,.88},fill="#ffffff00",stroke=p.accent,width=3},text("[begin, end) = [6, 8)",{x0+6.5*.72,-3.34},13,p.accent),text("all other pixels keep angular ColorTable lookup",{4.55,-3.43},12,p.muted)},.5,"ease_out",.06);scene:wait(1)`;

const seamReconstructionJs = `header("04","Seam endpoint reconstruction","begin is the first eligible pixel; end is the one-past index returned by _conicAARange.","outside range: angular lookup    inside range: endpoint blend");
const e=root.rectangle({center:[-5.7,1.2],size:[.72,.72],fill:p.purple,stroke:p.solid}),b=root.rectangle({center:[-3.55,1.2],size:[.72,.72],fill:p.orange,stroke:p.solid});scene.create([e,b,text("rgbaEnd",[-5.7,.66],13,p.purple),text("rgbaBegin",[-3.55,.66],13,p.orange),text("dist = 255 x (distance + 0.5)",[2.6,1.4],17,p.accent),text("color = INTERPOLATE(rgbaBegin, rgbaEnd, dist)",[2.6,1],14)],.65,"ease_out",.07);
const before=[],colors=[],x0=-4.9;for(let i=0;i<15;i++){const color=i<7?mix(p.purple,"#73778c",i/6):mix(p.orange,"#f7b442",(i-7)/7);colors.push(color);before.push(root.polygon({points:rect(x0+i*.72,-.95,.72,.72),fill:color,stroke:p.paper,width:1}))}scene.create(before,.68,"ease_out",.025);
for(let i=0;i<15;i++){let pts=rect(x0+i*.72,-.95,.72,.72),sc=colors[i],tc=sc;if(i===6){pts=rect(-5.7,1.2,.72,.72);sc=p.purple;tc=mix(p.purple,p.orange,.13)}else if(i===7){pts=rect(-3.55,1.2,.72,.72);sc=p.orange;tc=mix(p.purple,p.orange,.87)}const cp=root.polygon({points:pts,fill:sc,stroke:p.paper}),target=root.polygon({points:rect(x0+i*.72,-2.63,.72,.72),fill:tc,stroke:p.paper});scene.replacementTransform(cp,target,.12,"ease_in_out")}
scene.create([root.rectangle({center:[x0+6.5*.72,-2.63],size:[1.44,.88],fill:"#ffffff00",stroke:p.accent,width:3}),text("[begin, end) = [6, 8)",[x0+6.5*.72,-3.34],13,p.accent),text("all other pixels keep angular ColorTable lookup",[4.55,-3.43],12,p.muted)],.5,"ease_out",.06).wait(1);`;

const surfaceGradientLua = `header("05","Pull a Surface sample into Gradient Space","The composed forward transform is inverted once; every pixel reuses its coefficients.","{rx, ry} = itransform(x + 0.5, y + 0.5) - center")
local sg,gg={},{};for i=0,8 do sg[#sg+1]=root:line{from={-7.07+i*.58,-2.19},to={-7.07+i*.58,1.29},color=p.rule,width=1};gg[#gg+1]=root:line{from={2.10+i*.62,-2.19-i*.13},to={3.14+i*.62,1.29-i*.13},color=p.rule,width=1}end;scene:create(sg,.65,"linear",.02);scene:create(gg,.65,"linear",.02)
local ss={-3.88,-.16};local src=root:polygon{points=rect(-3.88,-.16,.58,.58),fill="#5e7a9b14",stroke=p.blue,width=2.5};local dot=root:point{point=ss,fill=p.blue,radius=7};scene:create({src,dot,text("SURFACE COORDINATES",{-6.75,1.75},13,p.muted,nil,{0,.5}),text("GRADIENT SPACE",{2.15,1.75},13,p.muted,nil,{0,.5})},.48,"ease_out",.06);scene:create({text("transform = pTransform x conic.transform()",{0,1.05},13,p.ink),text("itransform = inverse(transform)",{0,.48},14,p.accent)},.5,"ease_out",.08)
local gs={5.43,-.39};local cp=root:polygon{points=rect(-3.88,-.16,.58,.58),fill="#5e7a9b14",stroke=p.blue,width=2.5};local target=root:polygon{points={{5.03,-.58},{5.66,-.71},{5.83,-.21},{5.20,-.08}},fill="#5e7a9b14",stroke=p.blue,width=2.5};scene:replacement_transform(cp,target,1,"ease_in_out");local dc=root:point{point=ss,fill=p.blue,radius=7};scene:shift(dc,{gs[1]-ss[1],gs[2]-ss[2]},.85,"ease_in_out")
scene:create({root:arrow{from={3.85,-.20},to=gs,tip=13,color=p.purple,width=3},text("{rx, ry}",{4.65,-.55},14,p.purple),text("xStep = {a11, a21}",{4.4,-2.30},13,p.blue),text("yStep = {a12, a22}",{4.4,-2.67},13,p.mustard)},.55,"ease_out",.07);scene:wait(1)`;

const surfaceGradientJs = `header("05","Pull a Surface sample into Gradient Space","The composed forward transform is inverted once; every pixel reuses its coefficients.","{rx, ry} = itransform(x + 0.5, y + 0.5) - center");
const sg=[],gg=[];for(let i=0;i<9;i++){sg.push(root.line({from:[-7.07+i*.58,-2.19],to:[-7.07+i*.58,1.29],color:p.rule,width:1}));gg.push(root.line({from:[2.10+i*.62,-2.19-i*.13],to:[3.14+i*.62,1.29-i*.13],color:p.rule,width:1}))}scene.create(sg,.65,"linear",.02).create(gg,.65,"linear",.02);
const ss=[-3.88,-.16],src=root.polygon({points:rect(-3.88,-.16,.58,.58),fill:"#5e7a9b14",stroke:p.blue,width:2.5}),dot=root.point({point:ss,fill:p.blue,radius:7});scene.create([src,dot,text("SURFACE COORDINATES",[-6.75,1.75],13,p.muted,undefined,[0,.5]),text("GRADIENT SPACE",[2.15,1.75],13,p.muted,undefined,[0,.5])],.48,"ease_out",.06).create([text("transform = pTransform x conic.transform()",[0,1.05],13),text("itransform = inverse(transform)",[0,.48],14,p.accent)],.5,"ease_out",.08);
const gs=[5.43,-.39],cp=root.polygon({points:rect(-3.88,-.16,.58,.58),fill:"#5e7a9b14",stroke:p.blue,width:2.5}),target=root.polygon({points:[[5.03,-.58],[5.66,-.71],[5.83,-.21],[5.20,-.08]],fill:"#5e7a9b14",stroke:p.blue,width:2.5});scene.replacementTransform(cp,target,1,"ease_in_out");const dc=root.point({point:ss,fill:p.blue,radius:7});scene.shift(dc,[gs[0]-ss[0],gs[1]-ss[1]],.85,"ease_in_out").create([root.arrow({from:[3.85,-.20],to:gs,tip:13,color:p.purple,width:3}),text("{rx, ry}",[4.65,-.55],14,p.purple),text("xStep = {a11, a21}",[4.4,-2.30],13,p.blue),text("yStep = {a12, a22}",[4.4,-2.67],13,p.mustard)],.55,"ease_out",.07).wait(1);`;

const angularParameterLua = `header("06","Map an angle to the ColorTable","atan2f produces a signed angle; offset and fract convert it into lookup parameter t.","t in [0, 1)      index = round((SW_COLOR_TABLE - 1) x t)")
local c={-3.65,-.55};local palette={p.purple,p.blue,p.mustard,p.orange,p.purple};local sectors={};for i=0,31 do local phase=i/32*4;local k=math.floor(phase)+1;if k>4 then k=4 end;local color=mix(palette[k],palette[k+1],phase-math.floor(phase));local a0=-2*math.pi*i/32;local a1=-2*math.pi*(i+1)/32-.004;sectors[#sectors+1]=root:polygon{points={c,{c[1]+2.35*math.cos(a0),c[2]+2.35*math.sin(a0)},{c[1]+2.35*math.cos(a1),c[2]+2.35*math.sin(a1)}},fill=color,stroke=color}end;scene:create(sectors,.82,"ease_out",.012);scene:grow_from_center(root:circle{center=c,radius=1.25,fill=p.paper,stroke=p.paper,layer=5},.3,"ease_out")
local v=root:arrow{from=c,to={-1.60,-.55},tip=14,color=p.ink,width=3};scene:create(v,.35,"linear");local a=-.82;local co,si=math.cos(a),math.sin(a);local tx=c[1]-co*c[1]+si*c[2];local ty=c[2]-si*c[1]-co*c[2];scene:transform(v,{co,-si,0,tx,si,co,0,ty,0,0,1,0,0,0,0,1},1.25,"ease_in_out")
scene:create({text("offset = -angle / 360",{3.65,1.38},13,p.muted),text("t = atan2f(ry, rx) x (0.5 / pi) + offset",{3.65,.92},13,p.ink),text("t = t - floorf(t)",{3.65,.42},15,p.accent)},.62,"ease_out",.1)
local cells={};for i=0,11 do local phase=i/11*4;local k=math.floor(phase)+1;if k>4 then k=4 end;cells[#cells+1]=root:rectangle{center={.95+i*.50,-.72},size={.48,.62},fill=mix(palette[k],palette[k+1],phase-math.floor(phase)),stroke=p.paper,width=1}end;scene:create(cells,.62,"ease_out",.025);local vend={c[1]+2.05*co,c[2]+2.05*si};local cp=root:point{point=vend,fill=p.ink,radius=6};scene:shift(cp,{.95+10*.5-vend[1],-.72-vend[2]},.75,"ease_in_out");scene:create(text("index = round((N - 1) x t)",{3.7,-1.42},14,p.accent),.3,"ease_out");scene:wait(1)`;

const angularParameterJs = `header("06","Map an angle to the ColorTable","atan2f produces a signed angle; offset and fract convert it into lookup parameter t.","t in [0, 1)      index = round((SW_COLOR_TABLE - 1) x t)");
const c=[-3.65,-.55],palette=[p.purple,p.blue,p.mustard,p.orange,p.purple],sectors=[];for(let i=0;i<32;i++){const phase=i/32*4,k=Math.min(3,Math.floor(phase)),color=mix(palette[k],palette[k+1],phase-Math.floor(phase)),a0=-2*Math.PI*i/32,a1=-2*Math.PI*(i+1)/32-.004;sectors.push(root.polygon({points:[c,[c[0]+2.35*Math.cos(a0),c[1]+2.35*Math.sin(a0)],[c[0]+2.35*Math.cos(a1),c[1]+2.35*Math.sin(a1)]],fill:color,stroke:color}))}scene.create(sectors,.82,"ease_out",.012).growFromCenter(root.circle({center:c,radius:1.25,fill:p.paper,stroke:p.paper,layer:5}),.3,"ease_out");
const v=root.arrow({from:c,to:[-1.60,-.55],tip:14,color:p.ink,width:3});scene.create(v,.35,"linear");const a=-.82,co=Math.cos(a),si=Math.sin(a),tx=c[0]-co*c[0]+si*c[1],ty=c[1]-si*c[0]-co*c[1];scene.transform(v,[co,-si,0,tx,si,co,0,ty,0,0,1,0,0,0,0,1],1.25,"ease_in_out").create([text("offset = -angle / 360",[3.65,1.38],13,p.muted),text("t = atan2f(ry, rx) x (0.5 / pi) + offset",[3.65,.92],13),text("t = t - floorf(t)",[3.65,.42],15,p.accent)],.62,"ease_out",.1);
const cells=[];for(let i=0;i<12;i++){const phase=i/11*4,k=Math.min(3,Math.floor(phase));cells.push(root.rectangle({center:[.95+i*.50,-.72],size:[.48,.62],fill:mix(palette[k],palette[k+1],phase-Math.floor(phase)),stroke:p.paper,width:1}))}scene.create(cells,.62,"ease_out",.025);const vend=[c[0]+2.05*co,c[1]+2.05*si],cp=root.point({point:vend,fill:p.ink,radius:6});scene.shift(cp,[.95+10*.5-vend[0],-.72-vend[1]],.75,"ease_in_out").create(text("index = round((N - 1) x t)",[3.7,-1.42],14,p.accent),.3,"ease_out").wait(1);`;

const recurrenceLua = `header("07","Advance one transformed scanline","Only the first inverse-matrix column is added as the pixel index increases.","rx += a11      ry += a21      distance(i) and seamProjection(i) are affine")
local cells,points={},{};local x0=-6.55;for i=0,9 do cells[#cells+1]=root:rectangle{center={x0+i*.62,1.15},size={.62,.62},fill=p.paper,stroke=p.solid,width=1.5};points[#points+1]=root:point{point={x0+i*.62,1.15},fill=p.blue,radius=5}end;scene:create(cells,.62,"ease_out",.025);scene:create(points,.42,"ease_out",.025)
local p0={-6.15,-.85};local step={.57,-.23};scene:create(root:line{from={p0[1]-.23,p0[2]+.09},to={p0[1]+9.5*step[1],p0[2]+9.5*step[2]},color=p.solid,width=2},.5,"linear")
for i=0,9 do local source={x0+i*.62,1.15};local cp=root:point{point=source,fill=p.blue,radius=5};scene:shift(cp,{p0[1]+i*step[1]-source[1],p0[2]+i*step[2]-source[2]},.12,"ease_in_out")end
local arrows={};for i=0,3 do arrows[#arrows+1]=root:arrow{from={p0[1]+i*step[1],p0[2]+i*step[2]},to={p0[1]+(i+1)*step[1],p0[2]+(i+1)*step[2]},tip=9,color=p.accent,width=2.5}end;scene:create(arrows,.62,"ease_out",.1);scene:create({text("rx(i) = rx(0) + i x a11",{3.9,.78},15,p.blue),text("ry(i) = ry(0) + i x a21",{3.9,.30},15,p.blue),text("distance(i) = distance + i x distanceDx",{3.9,-.32},13,p.ink),text("One scanline becomes one affine line;",{3.9,-1.42},14,p.accent),text("its AA solution is one interval.",{3.9,-1.82},14,p.accent)},.7,"ease_out",.09);scene:wait(1)`;

const recurrenceJs = `header("07","Advance one transformed scanline","Only the first inverse-matrix column is added as the pixel index increases.","rx += a11      ry += a21      distance(i) and seamProjection(i) are affine");
const cells=[],points=[],x0=-6.55;for(let i=0;i<10;i++){cells.push(root.rectangle({center:[x0+i*.62,1.15],size:[.62,.62],fill:p.paper,stroke:p.solid,width:1.5}));points.push(root.point({point:[x0+i*.62,1.15],fill:p.blue,radius:5}))}scene.create(cells,.62,"ease_out",.025).create(points,.42,"ease_out",.025);const p0=[-6.15,-.85],step=[.57,-.23];scene.create(root.line({from:[p0[0]-.23,p0[1]+.09],to:[p0[0]+9.5*step[0],p0[1]+9.5*step[1]],color:p.solid,width:2}),.5,"linear");for(let i=0;i<10;i++){const source=[x0+i*.62,1.15],cp=root.point({point:source,fill:p.blue,radius:5});scene.shift(cp,[p0[0]+i*step[0]-source[0],p0[1]+i*step[1]-source[1]],.12,"ease_in_out")}
const arrows=[];for(let i=0;i<4;i++)arrows.push(root.arrow({from:[p0[0]+i*step[0],p0[1]+i*step[1]],to:[p0[0]+(i+1)*step[0],p0[1]+(i+1)*step[1]],tip:9,color:p.accent,width:2.5}));scene.create(arrows,.62,"ease_out",.1).create([text("rx(i) = rx(0) + i x a11",[3.9,.78],15,p.blue),text("ry(i) = ry(0) + i x a21",[3.9,.30],15,p.blue),text("distance(i) = distance + i x distanceDx",[3.9,-.32],13),text("One scanline becomes one affine line;",[3.9,-1.42],14,p.accent),text("its AA solution is one interval.",[3.9,-1.82],14,p.accent)],.7,"ease_out",.09).wait(1);`;

const angularMarginLua = `header("08","Angular margin grows with radius","A fixed ColorTable transition becomes a widening sector; footprint AA stays one pixel wide.","parameter-space blur: length(r) = r deltaTheta      fill-stage AA: width is about one device pixel")
local c={-4.55,-.70};local d=13*math.pi/180;local r=3.2;local e0={c[1]+r,c[2]};local e1={c[1]+r*math.cos(d),c[2]+r*math.sin(d)};local wedge=root:polygon{points={c,e0,e1},fill="#b8915a33",stroke="#b8915a00"};scene:create({root:line{from=c,to=e0,color=p.accent,width=3},text("FIXED ANGULAR MARGIN",{-6.65,1.65},13,p.muted,nil,{0,.5})},.52,"ease_out",.08);scene:fade_in(wedge,{duration=.42});scene:create(root:line{from=c,to=e1,color=p.mustard,width=3},.52,"linear")
local function arc(radius,color)local pts={};for i=0,24 do local a=d*i/24;pts[#pts+1]={c[1]+radius*math.cos(a),c[2]+radius*math.sin(a)}end;return root:plot{points=pts,color=color,width=5}end;scene:create({arc(1.15,p.blue),arc(2.85,p.accent)},.72,"ease_out",.15)
local strip=root:polygon{points={{1.05,-.42},{6.55,-.42},{6.55,-.98},{1.05,-.98}},fill="#9b360021",stroke="#9b360000"};scene:fade_in(strip,{duration=.42});scene:create(root:line{from={1.05,-.70},to={6.55,-.70},color=p.accent,width=3},.55,"linear");local pixels={};for i=1,4 do pixels[#pixels+1]=root:rectangle{center={2+(i-1)*1.18,-.70},size={.56,.56},fill="#5e7a9b0f",stroke=p.blue,width=2}end;scene:create(pixels,.62,"ease_out",.1);scene:create({text("length(r) = r deltaTheta",{-4.5,-2.3},16,p.accent),text("Blur width increases with radius.",{-4.5,-2.72},12,p.muted),text("-0.5 < distance < 0.5",{3.85,-2.3},15,p.accent),text("about 1 pixel",{6.7,-.70},12,p.blue)},.5,"ease_out",.08);scene:wait(1)`;

const angularMarginJs = `header("08","Angular margin grows with radius","A fixed ColorTable transition becomes a widening sector; footprint AA stays one pixel wide.","parameter-space blur: length(r) = r deltaTheta      fill-stage AA: width is about one device pixel");
const c=[-4.55,-.70],d=13*Math.PI/180,r=3.2,e0=[c[0]+r,c[1]],e1=[c[0]+r*Math.cos(d),c[1]+r*Math.sin(d)],wedge=root.polygon({points:[c,e0,e1],fill:"#b8915a33",stroke:"#b8915a00"});scene.create([root.line({from:c,to:e0,color:p.accent,width:3}),text("FIXED ANGULAR MARGIN",[-6.65,1.65],13,p.muted,undefined,[0,.5])],.52,"ease_out",.08).fadeIn(wedge,{duration:.42}).create(root.line({from:c,to:e1,color:p.mustard,width:3}),.52,"linear");const arc=(radius,color)=>{const pts=[];for(let i=0;i<=24;i++){const a=d*i/24;pts.push([c[0]+radius*Math.cos(a),c[1]+radius*Math.sin(a)])}return root.plot({points:pts,color,width:5})};scene.create([arc(1.15,p.blue),arc(2.85,p.accent)],.72,"ease_out",.15);
const strip=root.polygon({points:[[1.05,-.42],[6.55,-.42],[6.55,-.98],[1.05,-.98]],fill:"#9b360021",stroke:"#9b360000"});scene.fadeIn(strip,{duration:.42}).create(root.line({from:[1.05,-.70],to:[6.55,-.70],color:p.accent,width:3}),.55,"linear");const pixels=[];for(let i=0;i<4;i++)pixels.push(root.rectangle({center:[2+i*1.18,-.70],size:[.56,.56],fill:"#5e7a9b0f",stroke:p.blue,width:2}));scene.create(pixels,.62,"ease_out",.1).create([text("length(r) = r deltaTheta",[-4.5,-2.3],16,p.accent),text("Blur width increases with radius.",[-4.5,-2.72],12,p.muted),text("-0.5 < distance < 0.5",[3.85,-2.3],15,p.accent),text("about 1 pixel",[6.7,-.70],12,p.blue)],.5,"ease_out",.08).wait(1);`;

const fwidthLua = `header("09","fwidth is the shadow of one pixel","A transformed pixel becomes a parallelogram; its normal extent controls AA.","fwidth = |dot(normal, xStep)| + |dot(normal, yStep)|")
local o={-3.85,-.55};local corner={-3.733,-.596};local xv={1.15,-.18};local yv={-.30,-.96};local xe={corner[1]+xv[1],corner[2]+xv[2]};local ye={corner[1]+yv[1],corner[2]+yv[2]};local footprint=root:polygon{points={corner,xe,{xe[1]+yv[1],xe[2]+yv[2]},ye},fill="#5e7a9b1f",stroke=p.blue,width=2.5};local xa=root:polygon{points=arrowpts(corner,xe,.025,.10,.22),fill=p.blue,stroke=p.blue};local ya=root:polygon{points=arrowpts(corner,ye,.025,.10,.22),fill=p.mustard,stroke=p.mustard};scene:create({root:line{from={-6.44,.39},to={-1.27,-1.49},color=p.accent,width=3},root:arrow{from={-3.25,1.10},to={-4.70,-2.90},tip=12,color=p.purple,width=2.5},footprint,xa,ya},.68,"ease_out",.08)
local cp={-3.851,-.553};local xp={-3.774,-.342};local yp={-4.195,-1.497};local xc=root:polygon{points=arrowpts(corner,xe,.025,.10,.22),fill=p.blue,stroke=p.blue};local xt=root:polygon{points=arrowpts(cp,xp,.025,.10,.22),fill=p.blue,stroke=p.blue};scene:replacement_transform(xc,xt,.62,"ease_in_out");local yc=root:polygon{points=arrowpts(corner,ye,.025,.10,.22),fill=p.mustard,stroke=p.mustard};local yt=root:polygon{points=arrowpts(cp,yp,.025,.10,.22),fill=p.mustard,stroke=p.mustard};scene:replacement_transform(yc,yt,.62,"ease_in_out")
local formulas={text("dFdx = dot(normal, xStep) = -0.22",{4.1,1.30},12,p.blue),text("dFdy = dot(normal, yStep) = +1.00",{4.1,.88},12,p.mustard),text("fwidth = |dFdx| + |dFdy| = 1.23",{4.1,.42},13,p.accent)};local xfc=root:polygon{points=arrowpts(cp,xp,.025,.10,.22),fill=p.blue,stroke=p.blue};local xchip=root:polygon{points=chip(1.35,1.30,.30,.14),fill=p.blue,stroke=p.blue};scene:replacement_transform(xfc,xchip,.55,"ease_in_out");scene:create(formulas[1],.25,"ease_out");local yfc=root:polygon{points=arrowpts(cp,yp,.025,.10,.22),fill=p.mustard,stroke=p.mustard};local ychip=root:polygon{points=chip(1.35,.88,.30,.14),fill=p.mustard,stroke=p.mustard};scene:replacement_transform(yfc,ychip,.55,"ease_in_out");scene:create({formulas[2],formulas[3],text("invFwidth = 1 / 1.23 = 0.81",{3.85,-1.18},12,p.accent),text("distance = 0.39 x 0.81 = +0.32",{3.85,-1.52},12,p.ink)},.55,"ease_out",.08);scene:wait(1)`;

const fwidthJs = `header("09","fwidth is the shadow of one pixel","A transformed pixel becomes a parallelogram; its normal extent controls AA.","fwidth = |dot(normal, xStep)| + |dot(normal, yStep)|");
const o=[-3.85,-.55],corner=[-3.733,-.596],xv=[1.15,-.18],yv=[-.30,-.96],xe=[corner[0]+xv[0],corner[1]+xv[1]],ye=[corner[0]+yv[0],corner[1]+yv[1]],footprint=root.polygon({points:[corner,xe,[xe[0]+yv[0],xe[1]+yv[1]],ye],fill:"#5e7a9b1f",stroke:p.blue,width:2.5}),xa=root.polygon({points:arrowpts(corner,xe,.025,.10,.22),fill:p.blue,stroke:p.blue}),ya=root.polygon({points:arrowpts(corner,ye,.025,.10,.22),fill:p.mustard,stroke:p.mustard});scene.create([root.line({from:[-6.44,.39],to:[-1.27,-1.49],color:p.accent,width:3}),root.arrow({from:[-3.25,1.10],to:[-4.70,-2.90],tip:12,color:p.purple,width:2.5}),footprint,xa,ya],.68,"ease_out",.08);
const cp=[-3.851,-.553],xp=[-3.774,-.342],yp=[-4.195,-1.497],xc=root.polygon({points:arrowpts(corner,xe,.025,.10,.22),fill:p.blue,stroke:p.blue}),xt=root.polygon({points:arrowpts(cp,xp,.025,.10,.22),fill:p.blue,stroke:p.blue});scene.replacementTransform(xc,xt,.62,"ease_in_out");const yc=root.polygon({points:arrowpts(corner,ye,.025,.10,.22),fill:p.mustard,stroke:p.mustard}),yt=root.polygon({points:arrowpts(cp,yp,.025,.10,.22),fill:p.mustard,stroke:p.mustard});scene.replacementTransform(yc,yt,.62,"ease_in_out");
const formulas=[text("dFdx = dot(normal, xStep) = -0.22",[4.1,1.30],12,p.blue),text("dFdy = dot(normal, yStep) = +1.00",[4.1,.88],12,p.mustard),text("fwidth = |dFdx| + |dFdy| = 1.23",[4.1,.42],13,p.accent)],xfc=root.polygon({points:arrowpts(cp,xp,.025,.10,.22),fill:p.blue,stroke:p.blue}),xchip=root.polygon({points:chip(1.35,1.30,.30,.14),fill:p.blue,stroke:p.blue});scene.replacementTransform(xfc,xchip,.55,"ease_in_out").create(formulas[0],.25,"ease_out");const yfc=root.polygon({points:arrowpts(cp,yp,.025,.10,.22),fill:p.mustard,stroke:p.mustard}),ychip=root.polygon({points:chip(1.35,.88,.30,.14),fill:p.mustard,stroke:p.mustard});scene.replacementTransform(yfc,ychip,.55,"ease_in_out").create([formulas[1],formulas[2],text("invFwidth = 1 / 1.23 = 0.81",[3.85,-1.18],12,p.accent),text("distance = 0.39 x 0.81 = +0.32",[3.85,-1.52],12)],.55,"ease_out",.08).wait(1);`;

const example = (id, title, description, lua, js) => ({
    id,
    title,
    description,
    category: "Conic",
    dimension: "2D",
    fonts: PRETENDARD,
    lua: luaSource(lua),
    js: jsSource(js),
});

export const CONIC_ARTICLE_EXAMPLES = [
    example(
        "conic-coordinate-pullback",
        "Conic 01 · Coordinate pullback",
        "Inverse-transform columns become reusable xStep and yStep scanline increments.",
        coordinatePullbackLua,
        coordinatePullbackJs,
    ),
    example(
        "conic-prepared-geometry",
        "Conic 02 · Prepared geometry",
        "Prepare seam, normal, footprint projections, fwidth, and normalized signed distance.",
        preparedGeometryLua,
        preparedGeometryJs,
    ),
    example(
        "conic-scanline-range",
        "Conic 03 · Scanline range",
        "Intersect affine AA-strip and forward-ray predicates into one half-open interval.",
        scanlineRangeLua,
        scanlineRangeJs,
    ),
    example(
        "conic-seam-reconstruction",
        "Conic 04 · Seam reconstruction",
        "Preserve angular lookup outside the AA range and rebuild its endpoints from copied colors.",
        seamReconstructionLua,
        seamReconstructionJs,
    ),
    example(
        "conic-surface-to-gradient",
        "Conic 05 · Surface to gradient",
        "Pull a device-pixel center and footprint through the prepared inverse transform.",
        surfaceGradientLua,
        surfaceGradientJs,
    ),
    example(
        "conic-angular-parameterization",
        "Conic 06 · Angular parameterization",
        "Turn atan2 into a wrapped parameter and select the corresponding ColorTable entry.",
        angularParameterLua,
        angularParameterJs,
    ),
    example(
        "conic-scanline-recurrence",
        "Conic 07 · Scanline recurrence",
        "Advance transformed samples with one matrix column and expose the affine recurrence.",
        recurrenceLua,
        recurrenceJs,
    ),
    example(
        "conic-angular-margin-aa",
        "Conic 08 · Angular margin vs footprint AA",
        "Compare radius-dependent angular blur with device-pixel footprint antialiasing.",
        angularMarginLua,
        angularMarginJs,
    ),
    example(
        "conic-fwidth-intuition",
        "Conic 09 · fwidth intuition",
        "Project a transformed pixel onto the seam normal and morph those projections into fwidth.",
        fwidthLua,
        fwidthJs,
    ),
];
