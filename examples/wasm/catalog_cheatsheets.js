// Browser-editable tmath and binary-search cheatsheets.
// Lua variants mirror the standalone files under examples/lua.

export const CHEATSHEET_EXAMPLES = [
    {
        id: "tmath-api-atlas",
        title: "tmath",
        description: "A complete animated reference for scene composition, retained objects, spaces, cameras, surfaces, and technical diagrams.",
        category: "Cheatsheets",
        dimension: "2D / 3D",
        fonts: [{name: "Pretendard", url: "./Pretendard.ttf", mime: "ttf"}],
        lua: `-- Standalone tmath API cheatsheet.
local scene = tmath.scene {["camera"]={["height"]=30,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=30,["height"]=3000,["loop"]=true,["theme"]="pro_white",["width"]=1200}
local object1 = scene:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="header-title",["layer"]=40,["point"]={-5.7,14.18},["role"]="h1",["size"]=68,["text"]="TMATH"}
local object3 = scene:line {["from"]={-5.7,13.55},["id"]="header-rule",["stroke"]="#202124",["to"]={5.7,13.55},["width"]=1.3}
local object4 = scene:line {["from"]={-5.7,13.48},["id"]="header-accent",["stroke"]="#9b3600",["to"]={-3.9000000000000004,13.48},["width"]=4}
local object5 = scene:group {["id"]="theme-inline",["matrix"]={0.4674999999999998,0,0,-2.9250000000000003,0,0.4674999999999998,0,4.215,0,0,1,0,0,0,0,1}}
local object6 = object5:rectangle {["center"]={-3.977005347593583,0},["corner"]=0.06,["fill"]="#10161f",["id"]="theme-panel-0",["size"]={3.4427807486631012,2.75},["stroke"]="#d8dadd",["width"]=1}
local object7 = object5:rectangle {["center"]={-4.511229946524065,0.15},["corner"]=0.05,["fill"]="#f4f7fb",["id"]="theme-block-0",["size"]={1.4245989304812834,1.05},["stroke"]="#f28e2b",["width"]=1.8}
local object8 = object5:circle {["center"]={-3.086631016042781,0.15},["fill"]="#f28e2b55",["id"]="theme-circle-0",["radius"]=0.38,["stroke"]="#f28e2b",["width"]=2}
local object9 = object5:rectangle {["center"]={0,0},["corner"]=0.06,["fill"]="#ffffff",["id"]="theme-panel-1",["size"]={3.4427807486631012,2.75},["stroke"]="#d8dadd",["width"]=1}
local object10 = object5:rectangle {["center"]={-0.5342245989304812,0.15},["corner"]=0.05,["fill"]="#202124",["id"]="theme-block-1",["size"]={1.4245989304812834,1.05},["stroke"]="#9b3600",["width"]=1.8}
local object11 = object5:circle {["center"]={0.890374331550802,0.15},["fill"]="#9b360055",["id"]="theme-circle-1",["radius"]=0.38,["stroke"]="#9b3600",["width"]=2}
local object12 = object5:rectangle {["center"]={3.977005347593583,0},["corner"]=0.06,["fill"]="#050608",["id"]="theme-panel-2",["size"]={3.4427807486631012,2.75},["stroke"]="#d8dadd",["width"]=1}
local object13 = object5:rectangle {["center"]={3.4427807486631017,0.15},["corner"]=0.05,["fill"]="#f4f7fb",["id"]="theme-block-2",["size"]={1.4245989304812834,1.05},["stroke"]="#5e7a9b",["width"]=1.8}
local object14 = object5:circle {["center"]={4.867379679144385,0.15},["fill"]="#5e7a9b55",["id"]="theme-circle-2",["radius"]=0.38,["stroke"]="#5e7a9b",["width"]=2}
local object15 = object5:text {["align"]={0.5,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="theme-label-0",["layer"]=40,["point"]={-3.977005347593583,1.62},["size"]=12,["text"]="DEFAULT"}
local object16 = object5:text {["align"]={0.5,0.5},["fill"]="#9b3600",["font"]="Pretendard",["id"]="theme-label-1",["layer"]=40,["point"]={0,1.62},["size"]=12,["text"]="PRO WHITE"}
local object17 = object5:text {["align"]={0.5,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="theme-label-2",["layer"]=40,["point"]={3.977005347593583,1.62},["size"]=12,["text"]="PRO BLACK"}
local object18 = scene:line {["from"]={-5.7,13.3},["id"]="scene-rule",["stroke"]="#d8dadd",["to"]={5.7,13.3},["width"]=1.2}
local object19 = scene:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="scene-title",["layer"]=40,["point"]={-5.7,13.020000000000001},["role"]="h2",["size"]=24,["text"]="Build the scene graph"}
local object20 = scene:text {["align"]={1,0.5},["fill"]="#9b3600",["font"]="Pretendard",["id"]="scene-number",["layer"]=40,["point"]={5.7,13.180000000000001},["size"]=10.5,["text"]="01 / SCENE"}
do
    local viewportScene1 = tmath.scene {["camera"]={["height"]=4,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=30,["height"]=277,["theme"]="pro_white",["width"]=1140}
    local object1 = viewportScene1:line {["from"]={-1.6462093862815885,1.72},["id"]="scene-code-divider",["stroke"]="#d8dadd",["to"]={-1.6462093862815885,-1.68},["width"]=1}
    local object2 = viewportScene1:text {["align"]={0,0.5},["fill"]="#9b3600",["font"]="Pretendard",["id"]="scene-code-1",["layer"]=40,["point"]={-7.737184115523465,1.42},["role"]="code",["size"]=9.4,["text"]="1  const scene = tmath.scene({ width, height, theme: \\"pro_white\\" });"}
    local object3 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="scene-code-2",["layer"]=40,["point"]={-7.737184115523465,0.95},["role"]="code",["size"]=9.4,["text"]="2  const space = scene.space({ x, y, z });"}
    local object4 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="scene-code-3",["layer"]=40,["point"]={-7.737184115523465,0.48},["role"]="code",["size"]=9.4,["text"]="3  const mark = space.vector({ origin, value });"}
    local object5 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="scene-code-4",["layer"]=40,["point"]={-7.737184115523465,0.010000000000000009},["role"]="code",["size"]=9.4,["text"]="4  scene.play([{ target: mark, shift }], 0.8);"}
    local object6 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="scene-code-5",["layer"]=40,["point"]={-7.737184115523465,-0.45999999999999996},["role"]="code",["size"]=9.4,["text"]="5  scene.look({ view: \\"3d\\", eye, target }, 1.2);"}
    local object7 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="scene-code-6",["layer"]=40,["point"]={-7.737184115523465,-0.9299999999999997},["role"]="code",["size"]=9.4,["text"]="6  scene.text({ text, point, role });"}
    local object8 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="scene-code-7",["layer"]=40,["point"]={-7.737184115523465,-1.4},["role"]="code",["size"]=9.4,["text"]="7  scene.surface({ points, size, mode: \\"solid_mesh\\" });"}
    local object9 = viewportScene1:group {["id"]="scene-graph"}
    local object10 = object9:line {["from"]={3.292418772563177,1.08},["id"]="scene-edge-space",["layer"]=1,["stroke"]="#d8dadd",["to"]={0.24693140794223867,0.55},["width"]=1.5}
    local object11 = object9:line {["from"]={3.292418772563177,1.08},["id"]="scene-edge-text",["layer"]=1,["stroke"]="#d8dadd",["to"]={3.292418772563177,0.55},["width"]=1.5}
    local object12 = object9:line {["from"]={3.292418772563177,1.08},["id"]="scene-edge-surface",["layer"]=1,["stroke"]="#d8dadd",["to"]={6.337906137184115,0.55},["width"]=1.5}
    local object13 = object9:line {["from"]={0.24693140794223867,0.01},["id"]="scene-edge-vector",["layer"]=1,["stroke"]="#d8dadd",["to"]={0.24693140794223867,-0.75},["width"]=1.5}
    local object14 = object9:rectangle {["center"]={3.292418772563177,1.35},["corner"]=0.035,["fill"]="#ffffff",["id"]="scene-node-1",["layer"]=10,["size"]={2.65,0.54},["stroke"]="#9b3600",["width"]=2.2}
    local object15 = object9:text {["align"]={0.5,0.5},["fill"]="#9b3600",["font"]="Pretendard",["id"]="scene-node-label-1",["layer"]=40,["point"]={3.292418772563177,1.35},["role"]="code",["size"]=8.5,["text"]="L1  SCENE"}
    local object16 = object9:rectangle {["center"]={0.24693140794223867,0.28},["corner"]=0.035,["fill"]="#ffffff",["id"]="scene-node-2",["layer"]=10,["size"]={2.65,0.54},["stroke"]="#5e7a9b",["width"]=1.5}
    local object17 = object9:text {["align"]={0.5,0.5},["fill"]="#5e7a9b",["font"]="Pretendard",["id"]="scene-node-label-2",["layer"]=40,["point"]={0.24693140794223867,0.28},["role"]="code",["size"]=8.5,["text"]="L2  SPACE"}
    local object18 = object9:rectangle {["center"]={3.292418772563177,0.28},["corner"]=0.035,["fill"]="#ffffff",["id"]="scene-node-6",["layer"]=10,["size"]={2.65,0.54},["stroke"]="#6e6479",["width"]=1.5}
    local object19 = object9:text {["align"]={0.5,0.5},["fill"]="#6e6479",["font"]="Pretendard",["id"]="scene-node-label-6",["layer"]=40,["point"]={3.292418772563177,0.28},["role"]="code",["size"]=8.5,["text"]="L6  TEXT"}
    local object20 = object9:rectangle {["center"]={6.337906137184115,0.28},["corner"]=0.035,["fill"]="#ffffff",["id"]="scene-node-7",["layer"]=10,["size"]={2.65,0.54},["stroke"]="#b8915a",["width"]=1.5}
    local object21 = object9:text {["align"]={0.5,0.5},["fill"]="#b8915a",["font"]="Pretendard",["id"]="scene-node-label-7",["layer"]=40,["point"]={6.337906137184115,0.28},["role"]="code",["size"]=8.5,["text"]="L7  SURFACE"}
    local object22 = object9:rectangle {["center"]={0.24693140794223867,-1.02},["corner"]=0.035,["fill"]="#ffffff",["id"]="scene-node-3",["layer"]=10,["size"]={2.65,0.54},["stroke"]="#5e7a9b",["width"]=1.5}
    local object23 = object9:text {["align"]={0.5,0.5},["fill"]="#5e7a9b",["font"]="Pretendard",["id"]="scene-node-label-3",["layer"]=40,["point"]={0.24693140794223867,-1.02},["role"]="code",["size"]=8.5,["text"]="L3  VECTOR"}
    local object24 = object9:rectangle {["center"]={3.292418772563177,-1.02},["corner"]=0.035,["fill"]="#ffffff",["id"]="scene-node-5",["layer"]=10,["size"]={2.65,0.54},["stroke"]="#6e6479",["width"]=1.5}
    local object25 = object9:text {["align"]={0.5,0.5},["fill"]="#6e6479",["font"]="Pretendard",["id"]="scene-node-label-5",["layer"]=40,["point"]={3.292418772563177,-1.02},["role"]="code",["size"]=8.5,["text"]="L5  CAMERA"}
    local object26 = object9:rectangle {["center"]={6.337906137184115,-1.02},["corner"]=0.035,["fill"]="#ffffff",["id"]="scene-node-4",["layer"]=10,["size"]={2.65,0.54},["stroke"]="#9b3600",["width"]=1.5}
    local object27 = object9:text {["align"]={0.5,0.5},["fill"]="#9b3600",["font"]="Pretendard",["id"]="scene-node-label-4",["layer"]=40,["point"]={6.337906137184115,-1.02},["role"]="code",["size"]=8.5,["text"]="L4  TIMELINE"}
    local object28 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="scene-graph-label",["layer"]=40,["point"]={-1.3030685920577614,1.7},["size"]=9.5,["text"]="OBJECT OWNERSHIP"}
    local object29 = viewportScene1:line {["from"]={1.742418772563177,-0.6},["id"]="scene-state-rule",["stroke"]="#d8dadd",["to"]={7.887906137184115,-0.6},["width"]=1}
    local object30 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="scene-state-label",["layer"]=40,["point"]={1.742418772563177,-0.48},["size"]=8.5,["text"]="SCENE STATE"}
    local object31 = viewportScene1:point {["fill"]="#9b3600",["id"]="scene-registration-token-1",["layer"]=20,["opacity"]=0,["point"]={-1.8962093862815885,1.42},["radius"]=4.5,["stroke"]="#ffffff",["width"]=1.5}
    local object32 = viewportScene1:point {["fill"]="#5e7a9b",["id"]="scene-registration-token-2",["layer"]=20,["opacity"]=0,["point"]={-1.8962093862815885,0.95},["radius"]=4.5,["stroke"]="#ffffff",["width"]=1.5}
    local object33 = viewportScene1:point {["fill"]="#5e7a9b",["id"]="scene-registration-token-3",["layer"]=20,["opacity"]=0,["point"]={-1.8962093862815885,0.48},["radius"]=4.5,["stroke"]="#ffffff",["width"]=1.5}
    local object34 = viewportScene1:point {["fill"]="#9b3600",["id"]="scene-registration-token-4",["layer"]=20,["opacity"]=0,["point"]={-1.8962093862815885,0.010000000000000009},["radius"]=4.5,["stroke"]="#ffffff",["width"]=1.5}
    local object35 = viewportScene1:point {["fill"]="#6e6479",["id"]="scene-registration-token-5",["layer"]=20,["opacity"]=0,["point"]={-1.8962093862815885,-0.45999999999999996},["radius"]=4.5,["stroke"]="#ffffff",["width"]=1.5}
    local object36 = viewportScene1:point {["fill"]="#6e6479",["id"]="scene-registration-token-6",["layer"]=20,["opacity"]=0,["point"]={-1.8962093862815885,-0.9299999999999997},["radius"]=4.5,["stroke"]="#ffffff",["width"]=1.5}
    local object37 = viewportScene1:point {["fill"]="#b8915a",["id"]="scene-registration-token-7",["layer"]=20,["opacity"]=0,["point"]={-1.8962093862815885,-1.4},["radius"]=4.5,["stroke"]="#ffffff",["width"]=1.5}
    viewportScene1:play({{target=object31,opacity=1}},0.12,"gentle",0)
    viewportScene1:play({{target=object31,shift={3.6886281588447654,-0.06999999999999984}}},0.85,"gentle",0)
    viewportScene1:play({{target=object32,opacity=1},{target=object33,opacity=1},{target=object34,opacity=1},{target=object35,opacity=1},{target=object36,opacity=1},{target=object37,opacity=1}},0.12,"gentle",0)
    viewportScene1:play({{target=object32,shift={0.6431407942238272,-0.6699999999999999}},{target=object33,shift={0.6431407942238272,-1.5}},{target=object34,shift={6.734115523465704,-1.03}},{target=object35,shift={3.6886281588447654,-0.56}},{target=object36,shift={3.6886281588447654,1.2099999999999997}},{target=object37,shift={6.734115523465704,1.68}}},0.9,"gentle",0)
    viewportScene1:wait(0.45)
    viewportScene1:play({{target=object31,opacity=0},{target=object32,opacity=0},{target=object33,opacity=0},{target=object34,opacity=0},{target=object35,opacity=0},{target=object36,opacity=0},{target=object37,opacity=0}},0.25,"gentle",0)
    viewportScene1:play({{target=object31,shift={-3.6886281588447654,0.06999999999999984}},{target=object32,shift={-0.6431407942238272,0.6699999999999999}},{target=object33,shift={-0.6431407942238272,1.5}},{target=object34,shift={-6.734115523465704,1.03}},{target=object35,shift={-3.6886281588447654,0.56}},{target=object36,shift={-3.6886281588447654,-1.2099999999999997}},{target=object37,shift={-6.734115523465704,-1.68}}},0.45,"gentle",0)
    viewportScene1:wait(0.66)
    viewportScene1:play({{target=object31,opacity=1}},0.12,"gentle",0)
    viewportScene1:play({{target=object31,shift={3.6886281588447654,-0.06999999999999984}}},0.85,"gentle",0)
    viewportScene1:play({{target=object32,opacity=1},{target=object33,opacity=1},{target=object34,opacity=1},{target=object35,opacity=1},{target=object36,opacity=1},{target=object37,opacity=1}},0.12,"gentle",0)
    viewportScene1:play({{target=object32,shift={0.6431407942238272,-0.6699999999999999}},{target=object33,shift={0.6431407942238272,-1.5}},{target=object34,shift={6.734115523465704,-1.03}},{target=object35,shift={3.6886281588447654,-0.56}},{target=object36,shift={3.6886281588447654,1.2099999999999997}},{target=object37,shift={6.734115523465704,1.68}}},0.9,"gentle",0)
    viewportScene1:wait(0.45)
    viewportScene1:play({{target=object31,opacity=0},{target=object32,opacity=0},{target=object33,opacity=0},{target=object34,opacity=0},{target=object35,opacity=0},{target=object36,opacity=0},{target=object37,opacity=0}},0.25,"gentle",0)
    viewportScene1:play({{target=object31,shift={-3.6886281588447654,0.06999999999999984}},{target=object32,shift={-0.6431407942238272,0.6699999999999999}},{target=object33,shift={-0.6431407942238272,1.5}},{target=object34,shift={-6.734115523465704,1.03}},{target=object35,shift={-3.6886281588447654,0.56}},{target=object36,shift={-3.6886281588447654,-1.2099999999999997}},{target=object37,shift={-6.734115523465704,-1.68}}},0.45,"gentle",0)
    viewportScene1:wait(0.66)
    viewportScene1:wait(0.4)
    scene:viewport(viewportScene1,{["height"]=0.09233333333333338,["width"]=0.9500000000000001,["x"]=0.024999999999999984,["y"]=0.07166666666666661})
end
local object21 = scene:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="scene-caption-1",["layer"]=40,["point"]={-5.7,9.83},["size"]=12.5,["text"]="Factories attach retained objects to Scene; Space owns coordinate-aware marks."}
local object22 = scene:text {["align"]={0,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="scene-caption-2",["layer"]=40,["point"]={-5.7,9.59},["size"]=12.5,["text"]="Camera configuration and timeline operations remain Scene state outside the object tree."}
local object23 = scene:line {["from"]={-5.7,9.15},["id"]="object-rule",["stroke"]="#d8dadd",["to"]={-0.15,9.15},["width"]=1.2}
local object24 = scene:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="object-title",["layer"]=40,["point"]={-5.7,8.870000000000001},["role"]="h2",["size"]=24,["text"]="Group children; connect bounds"}
local object25 = scene:text {["align"]={1,0.5},["fill"]="#9b3600",["font"]="Pretendard",["id"]="object-number",["layer"]=40,["point"]={-0.15,9.030000000000001},["size"]=10.5,["text"]="02 / OBJECT"}
do
    local viewportScene1 = tmath.scene {["camera"]={["height"]=4,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=30,["height"]=207,["theme"]="pro_white",["width"]=555}
    local object1 = viewportScene1:text {["align"]={0,0.5},["fill"]="#9b3600",["font"]="Pretendard",["id"]="object-group-label",["layer"]=40,["point"]={-5.25,1.62},["size"]=10,["text"]="A  ·  PARENT TRANSFORM"}
    local object2 = viewportScene1:text {["align"]={0,0.5},["fill"]="#9b3600",["font"]="Pretendard",["id"]="object-connector-label",["layer"]=40,["point"]={0.38,1.62},["size"]=10,["text"]="B  ·  BOUNDS CONNECTOR"}
    local object3 = viewportScene1:line {["from"]={0,1.72},["id"]="object-divider",["stroke"]="#d8dadd",["to"]={0,-1.65},["width"]=1}
    local object4 = viewportScene1:group {["id"]="object-moving-group"}
    local object5 = object4:rectangle {["center"]={-3.15,0.15},["corner"]=0.06,["dash"]={5,4},["fill"]="#00000000",["id"]="object-moving-group-boundary",["size"]={4.2,1.55},["stroke"]="#d8dadd",["width"]=1.3}
    local object6 = object4:text {["align"]={0,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="object-moving-group-name",["layer"]=40,["point"]={-5.02,0.69},["role"]="code",["size"]=9,["text"]="group"}
    local object7 = object4:circle {["center"]={-4.15,0.08},["fill"]="#5e7a9b22",["id"]="object-moving-a",["radius"]=0.36,["stroke"]="#5e7a9b",["width"]=2.2}
    local object8 = object4:rectangle {["center"]={-2.15,0.08},["corner"]=0.05,["fill"]="#b8915a22",["id"]="object-moving-b",["size"]={0.78,0.64},["stroke"]="#b8915a",["width"]=2.2}
    local object9 = object4:connector {from=object7,to=object8,["id"]="object-moving-edge",["padding"]=0.12,["stroke"]="#202124",["width"]=1.8}
    local object10 = object4:text {["align"]={0.5,0.5},["fill"]="#5e7a9b",["font"]="Pretendard",["id"]="object-moving-a-label",["layer"]=40,["point"]={-4.15,0.08},["role"]="code",["size"]=10,["text"]="a"}
    local object11 = object4:text {["align"]={0.5,0.5},["fill"]="#b8915a",["font"]="Pretendard",["id"]="object-moving-b-label",["layer"]=40,["point"]={-2.15,0.08},["role"]="code",["size"]=10,["text"]="b"}
    local object12 = viewportScene1:line {["from"]={-3.15,-1.22},["id"]="object-group-shift-guide",["stroke"]="#d8dadd",["to"]={-2.43,-1.22},["width"]=1.4}
    local object13 = viewportScene1:line {["from"]={-3.15,-1.34},["id"]="object-group-shift-start",["stroke"]="#555b64",["to"]={-3.15,-1.1},["width"]=1.2}
    local object14 = viewportScene1:line {["from"]={-2.43,-1.34},["id"]="object-group-shift-end",["stroke"]="#555b64",["to"]={-2.43,-1.1},["width"]=1.2}
    local object15 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="object-group-shift-label",["layer"]=40,["point"]={-2.79,-1.48},["role"]="code",["size"]=9,["text"]="group.x"}
    local object16 = viewportScene1:group {["id"]="object-bounds-group"}
    local object17 = viewportScene1:rectangle {["center"]={2.8,0.15},["corner"]=0.06,["dash"]={5,4},["fill"]="#00000000",["id"]="object-bounds-group-boundary",["size"]={4.7,1.55},["stroke"]="#d8dadd",["width"]=1.3}
    local object18 = object16:text {["align"]={0,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="object-bounds-group-name",["layer"]=40,["point"]={0.68,0.69},["role"]="code",["size"]=9,["text"]="group"}
    local object19 = object16:circle {["center"]={1.55,0.08},["fill"]="#5e7a9b22",["id"]="object-bounds-a",["radius"]=0.36,["stroke"]="#5e7a9b",["width"]=2.2}
    local object20 = object16:rectangle {["center"]={3.8,0.08},["corner"]=0.05,["fill"]="#b8915a22",["id"]="object-bounds-b",["size"]={0.78,0.64},["stroke"]="#b8915a",["width"]=2.2}
    local object21 = object16:connector {from=object19,to=object20,["id"]="object-bounds-edge",["padding"]=0.12,["stroke"]="#202124",["width"]=1.8}
    local object22 = object16:text {["align"]={0.5,0.5},["fill"]="#5e7a9b",["font"]="Pretendard",["id"]="object-bounds-a-label",["layer"]=40,["point"]={1.55,0.08},["role"]="code",["size"]=10,["text"]="a"}
    local object23 = object16:text {["align"]={0.5,0.5},["fill"]="#b8915a",["font"]="Pretendard",["id"]="object-bounds-b-label",["layer"]=40,["point"]={3.8,0.08},["role"]="code",["size"]=10,["text"]="b"}
    local object24 = viewportScene1:line {["from"]={3.8,-1.22},["id"]="object-bounds-shift-guide",["stroke"]="#d8dadd",["to"]={4.52,-1.22},["width"]=1.4}
    local object25 = viewportScene1:line {["from"]={3.8,-1.34},["id"]="object-bounds-shift-start",["stroke"]="#555b64",["to"]={3.8,-1.1},["width"]=1.2}
    local object26 = viewportScene1:line {["from"]={4.52,-1.34},["id"]="object-bounds-shift-end",["stroke"]="#555b64",["to"]={4.52,-1.1},["width"]=1.2}
    local object27 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="object-bounds-shift-label",["layer"]=40,["point"]={4.16,-1.48},["role"]="code",["size"]=9,["text"]="b bounds"}
    viewportScene1:play({{target=object4,shift={0.72,0}},{target=object20,shift={0.72,0}},{target=object23,shift={0.72,0}},{target=object17,transform={1.1531914893617021,0,0,-0.06893617021276596,0,1,0,0,0,0,1,0,0,0,0,1}}},1.15,"ease_in_out",0)
    viewportScene1:wait(0.75)
    viewportScene1:play({{target=object4,shift={-0.72,0}},{target=object20,shift={-0.72,0}},{target=object23,shift={-0.72,0}},{target=object17,transform={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}}},1.15,"ease_in_out",0)
    viewportScene1:wait(0.75)
    viewportScene1:play({{target=object4,shift={0.72,0}},{target=object20,shift={0.72,0}},{target=object23,shift={0.72,0}},{target=object17,transform={1.1531914893617021,0,0,-0.06893617021276596,0,1,0,0,0,0,1,0,0,0,0,1}}},1.15,"ease_in_out",0)
    viewportScene1:wait(0.75)
    viewportScene1:play({{target=object4,shift={-0.72,0}},{target=object20,shift={-0.72,0}},{target=object23,shift={-0.72,0}},{target=object17,transform={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}}},1.15,"ease_in_out",0)
    viewportScene1:wait(0.75)
    viewportScene1:wait(0.4)
    scene:viewport(viewportScene1,{["height"]=0.06900000000000003,["width"]=0.46249999999999997,["x"]=0.024999999999999984,["y"]=0.20999999999999996})
end
local object26 = scene:text {["align"]={0,0.5},["fill"]="#9b3600",["font"]="Pretendard",["id"]="object-api-1",["layer"]=40,["point"]={-5.7,6.47},["role"]="code",["size"]=13,["text"]="const group = scene.group(); const a = group.circle(...)"}
local object27 = scene:text {["align"]={0,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="object-api-2",["layer"]=40,["point"]={-5.7,6.25},["role"]="code",["size"]=13,["text"]="const b = group.rectangle(...); group.connector(a, b)"}
local object28 = scene:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="object-caption-1",["layer"]=40,["point"]={-5.7,6.01},["size"]=11,["text"]="A parent transform carries every child; moving b also expands the Group bounds."}
local object29 = scene:text {["align"]={0,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="object-caption-2",["layer"]=40,["point"]={-5.7,5.77},["size"]=11,["text"]="Connector recomputes its endpoints from the current child bounds."}
local object30 = scene:line {["from"]={0.15,9.15},["id"]="animate-rule",["stroke"]="#d8dadd",["to"]={5.7,9.15},["width"]=1.2}
local object31 = scene:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="animate-title",["layer"]=40,["point"]={0.15,8.870000000000001},["role"]="h2",["size"]=24,["text"]="Schedule target-state changes"}
local object32 = scene:text {["align"]={1,0.5},["fill"]="#9b3600",["font"]="Pretendard",["id"]="animate-number",["layer"]=40,["point"]={5.7,9.030000000000001},["size"]=10.5,["text"]="03 / ANIMATE"}
do
    local viewportScene1 = tmath.scene {["camera"]={["height"]=4.6,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=30,["height"]=189,["theme"]="pro_white",["width"]=555}
    local object1 = viewportScene1:text {["align"]={0,0.5},["fill"]="#9b3600",["font"]="Pretendard",["id"]="animate-window-label",["layer"]=40,["point"]={-6.213650793650794,1.82},["size"]=10,["text"]="ONE PLAY CALL"}
    local object2 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="animate-start-label",["layer"]=40,["point"]={-4.187460317460317,1.42},["role"]="code",["size"]=10,["text"]="t = 0"}
    local object3 = viewportScene1:text {["align"]={1,0.5},["fill"]="#9b3600",["font"]="Pretendard",["id"]="animate-end-label",["layer"]=40,["point"]={4.862857142857143,1.42},["role"]="code",["size"]=10,["text"]="t = duration"}
    local object4 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="animate-target-label-0",["layer"]=40,["point"]={-6.213650793650794,0.72},["role"]="code",["size"]=10,["text"]="target a"}
    local object5 = viewportScene1:line {["from"]={-4.187460317460317,0.72},["id"]="animate-track-0",["stroke"]="#d8dadd",["to"]={4.862857142857143,0.72},["width"]=2}
    local object6 = viewportScene1:point {["fill"]="#555b64",["point"]={4.862857142857143,0.72},["radius"]=3,["stroke"]="#555b64"}
    local object7 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="animate-target-label-1",["layer"]=40,["point"]={-6.213650793650794,0},["role"]="code",["size"]=10,["text"]="target b"}
    local object8 = viewportScene1:line {["from"]={-4.187460317460317,0},["id"]="animate-track-1",["stroke"]="#d8dadd",["to"]={4.862857142857143,0},["width"]=2}
    local object9 = viewportScene1:point {["fill"]="#555b64",["point"]={4.862857142857143,0},["radius"]=3,["stroke"]="#555b64"}
    local object10 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="animate-target-label-2",["layer"]=40,["point"]={-6.213650793650794,-0.72},["role"]="code",["size"]=10,["text"]="target c"}
    local object11 = viewportScene1:line {["from"]={-4.187460317460317,-0.72},["id"]="animate-track-2",["stroke"]="#d8dadd",["to"]={4.862857142857143,-0.72},["width"]=2}
    local object12 = viewportScene1:point {["fill"]="#555b64",["point"]={4.862857142857143,-0.72},["radius"]=3,["stroke"]="#555b64"}
    local object13 = viewportScene1:circle {["center"]={-4.187460317460317,0.72},["fill"]="#202124",["id"]="animate-circle",["radius"]=0.24,["stroke"]="#202124"}
    local object14 = viewportScene1:rectangle {["center"]={-4.187460317460317,0},["corner"]=0.05,["fill"]="#202124",["id"]="animate-square",["size"]={0.48,0.48},["stroke"]="#202124"}
    local object15 = viewportScene1:point {["fill"]="#202124",["id"]="animate-dot",["point"]={-4.187460317460317,-0.72},["radius"]=8,["stroke"]="#202124"}
    viewportScene1:play({{target=object13,shift={9.05031746031746,0},stroke="#5e7a9b",fill="#5e7a9b"},{target=object14,shift={9.05031746031746,0},stroke="#b8915a",fill="#b8915a"},{target=object15,shift={9.05031746031746,0},stroke="#9b3600",fill="#9b3600"}},1.2,"ease_in_out",0)
    viewportScene1:wait(0.7)
    viewportScene1:play({{target=object13,shift={-9.05031746031746,0},stroke="#202124",fill="#202124"},{target=object14,shift={-9.05031746031746,0},stroke="#202124",fill="#202124"},{target=object15,shift={-9.05031746031746,0},stroke="#202124",fill="#202124"}},1.2,"ease_in_out",0)
    viewportScene1:wait(0.7)
    viewportScene1:play({{target=object13,shift={9.05031746031746,0},stroke="#5e7a9b",fill="#5e7a9b"},{target=object14,shift={9.05031746031746,0},stroke="#b8915a",fill="#b8915a"},{target=object15,shift={9.05031746031746,0},stroke="#9b3600",fill="#9b3600"}},1.2,"ease_in_out",0)
    viewportScene1:wait(0.7)
    viewportScene1:play({{target=object13,shift={-9.05031746031746,0},stroke="#202124",fill="#202124"},{target=object14,shift={-9.05031746031746,0},stroke="#202124",fill="#202124"},{target=object15,shift={-9.05031746031746,0},stroke="#202124",fill="#202124"}},1.2,"ease_in_out",0)
    viewportScene1:wait(0.7)
    viewportScene1:wait(0.4)
    scene:viewport(viewportScene1,{["height"]=0.06300000000000004,["width"]=0.46249999999999997,["x"]=0.5125000000000001,["y"]=0.20999999999999996})
end
local object33 = scene:text {["align"]={0,0.5},["fill"]="#9b3600",["font"]="Pretendard",["id"]="animate-api-1",["layer"]=40,["point"]={0.15,6.47},["role"]="code",["size"]=13,["text"]="scene.play([{ target, shift, fill }], duration, curve)"}
local object34 = scene:text {["align"]={0,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="animate-api-2",["layer"]=40,["point"]={0.15,6.25},["role"]="code",["size"]=13,["text"]="one call · explicit targets · one bounded time interval"}
local object35 = scene:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="animate-caption-1",["layer"]=40,["point"]={0.15,6.01},["size"]=11,["text"]="play moves related targets from their current state to the requested state together."}
local object36 = scene:text {["align"]={0,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="animate-caption-2",["layer"]=40,["point"]={0.15,5.77},["size"]=11,["text"]="Sampling the same timeline time reproduces the same intermediate state."}
local object37 = scene:line {["from"]={-5.7,5.6},["id"]="theme-rule",["stroke"]="#d8dadd",["to"]={-0.15,5.6},["width"]=1.2}
local object38 = scene:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="theme-title",["layer"]=40,["point"]={-5.7,5.319999999999999},["role"]="h2",["size"]=24,["text"]="Style at scene creation"}
local object39 = scene:text {["align"]={1,0.5},["fill"]="#9b3600",["font"]="Pretendard",["id"]="theme-number",["layer"]=40,["point"]={-0.15,5.4799999999999995},["size"]=10.5,["text"]="04 / THEME"}
local object40 = scene:text {["align"]={0,0.5},["fill"]="#9b3600",["font"]="Pretendard",["id"]="theme-api-1",["layer"]=40,["point"]={-5.7,3.12},["role"]="code",["size"]=13,["text"]="theme: \\"3_blue_1_eyes\\" | \\"pro_white\\" | \\"pro_black\\""}
local object41 = scene:text {["align"]={0,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="theme-api-2",["layer"]=40,["point"]={-5.7,2.9},["role"]="code",["size"]=13,["text"]="{ preset, text, objects, axis }"}
local object42 = scene:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="theme-caption-1",["layer"]=40,["point"]={-5.7,2.66},["size"]=11,["text"]="Theme belongs to SceneConfig; it is not a live switch."}
local object43 = scene:text {["align"]={0,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="theme-caption-2",["layer"]=40,["point"]={-5.7,2.42},["size"]=11,["text"]="Swatches compare background, foreground, and accent roles."}
local object44 = scene:line {["from"]={0.15,5.6},["id"]="text-rule",["stroke"]="#d8dadd",["to"]={5.7,5.6},["width"]=1.2}
local object45 = scene:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="text-title",["layer"]=40,["point"]={0.15,5.319999999999999},["role"]="h2",["size"]=24,["text"]="Text roles select typography"}
local object46 = scene:text {["align"]={1,0.5},["fill"]="#9b3600",["font"]="Pretendard",["id"]="text-number",["layer"]=40,["point"]={5.7,5.4799999999999995},["size"]=10.5,["text"]="05 / TEXT"}
do
    local viewportScene1 = tmath.scene {["camera"]={["height"]=4,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=30,["height"]=187,["theme"]="pro_white",["width"]=555}
    local object1 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="text-role-label",["layer"]=40,["point"]={-5.104812834224599,1.62},["size"]=10,["text"]="ROLE INPUT"}
    local object2 = viewportScene1:text {["align"]={0,0.5},["fill"]="#9b3600",["font"]="Pretendard",["id"]="text-render-label",["layer"]=40,["point"]={0.7122994652406417,1.62},["size"]=10,["text"]="RENDERED TEXT"}
    local object3 = viewportScene1:text {["align"]={0,0.5},["fill"]="#5e7a9b",["font"]="Pretendard",["id"]="text-role-0",["layer"]=40,["point"]={-5.104812834224599,0.92},["role"]="code",["size"]=11,["text"]="role: \\"h1\\""}
    local object4 = viewportScene1:line {["from"]={-1.1871657754010696,0.92},["id"]="text-role-arrow-0",["stroke"]="#d8dadd",["to"]={0.11871657754010695,0.92},["width"]=1.5}
    local object5 = viewportScene1:point {["fill"]="#5e7a9b",["id"]="text-role-end-0",["point"]={0.11871657754010695,0.92},["radius"]=3,["stroke"]="#5e7a9b"}
    local object6 = viewportScene1:text {["align"]={0,0.5},["fill"]="#b8915a",["font"]="Pretendard",["id"]="text-role-1",["layer"]=40,["point"]={-5.104812834224599,0},["role"]="code",["size"]=11,["text"]="role: \\"text\\""}
    local object7 = viewportScene1:line {["from"]={-1.1871657754010696,0},["id"]="text-role-arrow-1",["stroke"]="#d8dadd",["to"]={0.11871657754010695,0},["width"]=1.5}
    local object8 = viewportScene1:point {["fill"]="#b8915a",["id"]="text-role-end-1",["point"]={0.11871657754010695,0},["radius"]=3,["stroke"]="#b8915a"}
    local object9 = viewportScene1:text {["align"]={0,0.5},["fill"]="#9b3600",["font"]="Pretendard",["id"]="text-role-2",["layer"]=40,["point"]={-5.104812834224599,-0.92},["role"]="code",["size"]=11,["text"]="role: \\"code\\""}
    local object10 = viewportScene1:line {["from"]={-1.1871657754010696,-0.92},["id"]="text-role-arrow-2",["stroke"]="#d8dadd",["to"]={0.11871657754010695,-0.92},["width"]=1.5}
    local object11 = viewportScene1:point {["fill"]="#9b3600",["id"]="text-role-end-2",["point"]={0.11871657754010695,-0.92},["radius"]=3,["stroke"]="#9b3600"}
    local object12 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="text-heading",["layer"]=40,["point"]={0.8310160427807487,0.92},["role"]="h1",["size"]=24,["text"]="Heading"}
    local object13 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="text-body",["layer"]=40,["point"]={0.8310160427807487,0},["role"]="text",["size"]=16,["text"]="Body annotation"}
    local object14 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="text-code",["layer"]=40,["point"]={0.8310160427807487,-0.92},["role"]="code",["size"]=16,["text"]="f(x) = sin(x)"}
    local object15 = viewportScene1:point {["fill"]="#5e7a9b",["id"]="text-role-token-0",["layer"]=20,["opacity"]=0,["point"]={-1.1871657754010696,0.92},["radius"]=4.5,["stroke"]="#ffffff",["width"]=1.5}
    local object16 = viewportScene1:point {["fill"]="#b8915a",["id"]="text-role-token-1",["layer"]=20,["opacity"]=0,["point"]={-1.1871657754010696,0},["radius"]=4.5,["stroke"]="#ffffff",["width"]=1.5}
    local object17 = viewportScene1:point {["fill"]="#9b3600",["id"]="text-role-token-2",["layer"]=20,["opacity"]=0,["point"]={-1.1871657754010696,-0.92},["radius"]=4.5,["stroke"]="#ffffff",["width"]=1.5}
    viewportScene1:play({{target=object15,opacity=1},{target=object16,opacity=1},{target=object17,opacity=1}},0.2,"gentle",0)
    viewportScene1:play({{target=object15,shift={1.3058823529411765,0}},{target=object16,shift={1.3058823529411765,0}},{target=object17,shift={1.3058823529411765,0}}},1.1,"gentle",0)
    viewportScene1:wait(0.5)
    viewportScene1:play({{target=object12,fill="#5e7a9b"},{target=object13,fill="#b8915a"},{target=object14,fill="#9b3600"}},0.45,"gentle",0)
    viewportScene1:play({{target=object12,fill="#202124"},{target=object13,fill="#202124"},{target=object14,fill="#202124"}},0.45,"gentle",0)
    viewportScene1:play({{target=object15,opacity=0},{target=object16,opacity=0},{target=object17,opacity=0}},0.25,"gentle",0)
    viewportScene1:play({{target=object15,shift={-1.3058823529411765,0}},{target=object16,shift={-1.3058823529411765,0}},{target=object17,shift={-1.3058823529411765,0}}},0.35,"gentle",0)
    viewportScene1:wait(0.5)
    viewportScene1:play({{target=object15,opacity=1},{target=object16,opacity=1},{target=object17,opacity=1}},0.2,"gentle",0)
    viewportScene1:play({{target=object15,shift={1.3058823529411765,0}},{target=object16,shift={1.3058823529411765,0}},{target=object17,shift={1.3058823529411765,0}}},1.1,"gentle",0)
    viewportScene1:wait(0.5)
    viewportScene1:play({{target=object12,fill="#5e7a9b"},{target=object13,fill="#b8915a"},{target=object14,fill="#9b3600"}},0.45,"gentle",0)
    viewportScene1:play({{target=object12,fill="#202124"},{target=object13,fill="#202124"},{target=object14,fill="#202124"}},0.45,"gentle",0)
    viewportScene1:play({{target=object15,opacity=0},{target=object16,opacity=0},{target=object17,opacity=0}},0.25,"gentle",0)
    viewportScene1:play({{target=object15,shift={-1.3058823529411765,0}},{target=object16,shift={-1.3058823529411765,0}},{target=object17,shift={-1.3058823529411765,0}}},0.35,"gentle",0)
    viewportScene1:wait(0.5)
    viewportScene1:wait(0.4)
    scene:viewport(viewportScene1,{["height"]=0.06233333333333331,["width"]=0.46249999999999997,["x"]=0.5125000000000001,["y"]=0.32833333333333337})
end
local object47 = scene:text {["align"]={0,0.5},["fill"]="#9b3600",["font"]="Pretendard",["id"]="text-api-1",["layer"]=40,["point"]={0.15,3.12},["role"]="code",["size"]=13,["text"]="scene.text({ text, point, align, role, orientation })"}
local object48 = scene:text {["align"]={0,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="text-api-2",["layer"]=40,["point"]={0.15,2.9},["role"]="code",["size"]=13,["text"]="role: \\"h1\\" | \\"text\\" | \\"code\\""}
local object49 = scene:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="text-caption-1",["layer"]=40,["point"]={0.15,2.66},["size"]=11,["text"]="role selects heading, body, or code typography."}
local object50 = scene:text {["align"]={0,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="text-caption-2",["layer"]=40,["point"]={0.15,2.42},["size"]=11,["text"]="orientation selects billboard or plane text in 3D."}
local object51 = scene:line {["from"]={-5.7,2.25},["id"]="curve-rule",["stroke"]="#d8dadd",["to"]={5.7,2.25},["width"]=1.2}
local object52 = scene:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="curve-title",["layer"]=40,["point"]={-5.7,1.97},["role"]="h2",["size"]=24,["text"]="Map time to motion progress"}
local object53 = scene:text {["align"]={1,0.5},["fill"]="#9b3600",["font"]="Pretendard",["id"]="curve-number",["layer"]=40,["point"]={5.7,2.13},["size"]=10.5,["text"]="06 / CURVE"}
do
    local viewportScene1 = tmath.scene {["camera"]={["height"]=4,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=30,["height"]=217,["theme"]="pro_white",["width"]=1140}
    local object1 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="curve-lane-label-0",["layer"]=40,["point"]={-9.546280447662935,1.3333333333333333},["role"]="code",["size"]=13,["text"]="BACK  ·  0.65"}
    local object2 = viewportScene1:line {["from"]={-5.163396971691903,1.3333333333333333},["id"]="curve-track-0",["stroke"]="#d8dadd",["to"]={0.5403554970375246,1.3333333333333333},["width"]=2}
    local object3 = viewportScene1:line {["from"]={-5.163396971691903,1.2233333333333332},["id"]="curve-start-0",["stroke"]="#202124",["to"]={-5.163396971691903,1.4433333333333334},["width"]=2}
    local object4 = viewportScene1:line {["from"]={0.5403554970375246,1.2233333333333332},["id"]="curve-stop-0",["stroke"]="#9b3600",["to"]={0.5403554970375246,1.4433333333333334},["width"]=2}
    local object5 = viewportScene1:line {["from"]={2.461619486504279,1.0179487179487179},["id"]="curve-axis-x-0",["stroke"]="#d8dadd",["to"]={8.165371955233708,1.0179487179487179},["width"]=1}
    local object6 = viewportScene1:line {["from"]={2.461619486504279,0.9233333333333333},["id"]="curve-axis-y-0",["stroke"]="#d8dadd",["to"]={2.461619486504279,1.7433333333333332},["width"]=1}
    local object7 = viewportScene1:line {["from"]={8.165371955233708,0.9233333333333333},["id"]="curve-axis-r-0",["stroke"]="#d8dadd",["to"]={8.165371955233708,1.7433333333333332},["width"]=1}
    local object8 = viewportScene1:plot {["id"]="curve-plot-0",["points"]={{2.461619486504279,1.017948717948718},{2.5566820276497695,1.053031547682835},{2.6517445687952597,1.0866866478558406},{2.7468071099407503,1.1189447864621798},{2.841869651086241,1.1498367314962963},{2.936932192231731,1.1793932509526355},{3.0319947333772217,1.207645112825641},{3.1270572745227123,1.234623085109758},{3.2221198156682025,1.2603579357994301},{3.317182356813693,1.2848804328891026},{3.4122448979591837,1.3082213443732194},{3.507307439104674,1.330411438246225},{3.6023699802501645,1.351481482502564},{3.697432521395655,1.371462245136681},{3.7924950625411453,1.39038449414302},{3.887557603686636,1.4082789975160257},{3.9826201448321266,1.4251765232501423},{4.077682685977617,1.441107839339815},{4.172745227123107,1.4561037137794872},{4.2678077682685975,1.470194914563604},{4.362870309414088,1.4834122096866098},{4.457932850559579,1.4957863671429488},{4.552995391705069,1.5073481549270658},{4.64805793285056,1.5181283410334045},{4.743120473996051,1.5281576934564103},{4.83818301514154,1.5374669801905272},{4.933245556287032,1.5460869692301995},{5.028308097432522,1.5540484285698717},{5.123370638578012,1.5613821262039886},{5.218433179723503,1.5681188301269944},{5.313495720868993,1.5742893083333334},{5.408558262014484,1.5799243288174503},{5.503620803159974,1.585054659573789},{5.598683344305465,1.5897110685967948},{5.693745885450955,1.5939243238809118},{5.788808426596446,1.597725193420584},{5.883870967741936,1.6011444452102563},{5.978933508887426,1.6042128472443733},{6.073996050032917,1.6069611675173787},{6.169058591178407,1.6094201740237177},{6.264121132323897,1.6116206347578346},{6.3591836734693885,1.613593317714174},{6.454246214614878,1.6153689908871793},{6.54930875576037,1.6169784222712962},{6.6443712969058595,1.6184523798609685},{6.739433838051351,1.619821631650641},{6.834496379196841,1.6211169456347578},{6.9295589203423305,1.6223690898077634},{7.024621461487822,1.6236088321641025},{7.119684002633312,1.6248669406982192},{7.214746543778803,1.6261741834045584},{7.309809084924293,1.6275613282775638},{7.404871626069784,1.629059143311681},{7.499934167215274,1.6306983965013533},{7.594996708360764,1.6325098558410254},{7.690059249506255,1.6345242893251424},{7.785121790651745,1.636772464948148},{7.880184331797235,1.6392851507044872},{7.975246872942726,1.642093114588604},{8.070309414088216,1.645227124594943},{8.165371955233708,1.6487179487179486}},["stroke"]="#9b3600",["width"]=1.6}
    local object9 = viewportScene1:point {["fill"]="#9b3600",["id"]="curve-runner-0",["point"]={-5.163396971691903,1.3333333333333333},["radius"]=6}
    viewportScene1:shift(object9,{5.703752468729427,0},1.9,{["preset"]="back",["strength"]=0.65})
    viewportScene1:shift(object9,{-5.703752468729427,0},1.9,{["preset"]="back",["reverse"]=true,["strength"]=0.65})
    viewportScene1:shift(object9,{5.703752468729427,0},1.9,{["preset"]="back",["strength"]=0.65})
    viewportScene1:shift(object9,{-5.703752468729427,0},1.9,{["preset"]="back",["reverse"]=true,["strength"]=0.65})
    viewportScene1:wait(0.4)
    do
        local viewportScene2 = tmath.scene {["camera"]={["height"]=1.4,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=30,["height"]=72,["theme"]="pro_white",["width"]=1140}
        local object1 = viewportScene2:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="curve-lane-label-1",["layer"]=40,["point"]={-10.07,0},["role"]="code",["size"]=13,["text"]="ELASTIC  ·  0.55"}
        local object2 = viewportScene2:line {["from"]={-5.446666666666667,0},["id"]="curve-track-1",["stroke"]="#d8dadd",["to"]={0.5700000000000001,0},["width"]=2}
        local object3 = viewportScene2:line {["from"]={-5.446666666666667,-0.12},["id"]="curve-start-1",["stroke"]="#202124",["to"]={-5.446666666666667,0.12},["width"]=2}
        local object4 = viewportScene2:line {["from"]={0.5700000000000001,-0.12},["id"]="curve-stop-1",["stroke"]="#9b3600",["to"]={0.5700000000000001,0.12},["width"]=2}
        local object5 = viewportScene2:line {["from"]={2.5966666666666667,-0.33076923076923076},["id"]="curve-axis-x-1",["stroke"]="#d8dadd",["to"]={8.613333333333335,-0.33076923076923076},["width"]=1}
        local object6 = viewportScene2:line {["from"]={2.5966666666666667,-0.43},["id"]="curve-axis-y-1",["stroke"]="#d8dadd",["to"]={2.5966666666666667,0.43},["width"]=1}
        local object7 = viewportScene2:line {["from"]={8.613333333333335,-0.43},["id"]="curve-axis-r-1",["stroke"]="#d8dadd",["to"]={8.613333333333335,0.43},["width"]=1}
        local object8 = viewportScene2:plot {["id"]="curve-plot-1",["points"]={{2.5966666666666667,-0.33076923076923076},{2.6969444444444446,-0.2665629692052617},{2.7972222222222225,-0.1782220554036424},{2.8975,-0.08067750288509112},{2.997777777777778,0.01312140141822049},{3.098055555555556,0.09334387707173003},{3.1983333333333337,0.15380769230769237},{3.2986111111111116,0.19196437302748343},{3.398888888888889,0.20845374286587898},{3.499166666666667,0.20636981057739906},{3.599444444444445,0.1903851763113134},{3.6997222222222224,0.1658676539158171},{3.8000000000000007,0.13809615384615398},{3.900277777777778,0.11164894040295842},{4.000555555555556,0.09000171934104811},{4.100833333333334,0.07534023966334275},{4.2011111111111115,0.06856552302824986},{4.301388888888889,0.06945135762031307},{4.401666666666667,0.07690384615384621},{4.501944444444445,0.08927097500318854},{4.602222222222222,0.10465493538223708},{4.702500000000001,0.12118935060090213},{4.802777777777779,0.1372555597926623},{4.903055555555556,0.15162471540319705},{5.003333333333334,0.16352403846153857},{5.103611111111112,0.17263496970535858},{5.20388888888889,0.1790374870890043},{5.304166666666667,0.18311834170679037},{5.4044444444444455,0.18546160857737576},{5.504722222222223,0.18673826443178493},{5.605,0.1876081730769233},{5.705277777777779,0.1886436175503698},{5.805555555555556,0.19027906107147735},{5.905833333333335,0.1927877222656102},{6.006111111111112,0.1962822288400698},{6.10638888888889,0.20073430431792388},{6.206666666666667,0.20600721153846163},{6.306944444444445,0.21189444879847558},{6.407222222222224,0.21815878999970278},{6.507500000000001,0.22456693805588207},{6.607777777777779,0.2309165603586983},{6.708055555555557,0.23705405096386128},{6.8083333333333345,0.24288281250000004},{6.908611111111113,0.24836302505932378},{7.00888888888889,0.25350468588612557},{7.109166666666668,0.25835613886719505},{7.209444444444446,0.26299039337986424},{7.309722222222224,0.26749132151551175},{7.410000000000002,0.27194140625},{7.510277777777779,0.2764121829630271},{7.610555555555557,0.2809579595570117},{7.710833333333334,0.2856128883601244},{7.811111111111113,0.290391047835778},{7.91138888888889,0.29528890342435593},{8.011666666666668,0.3002893629807693},{8.111944444444447,0.3053666137921172},{8.212222222222223,0.31049100259611667},{8.312500000000002,0.31563336725698526},{8.41277777777778,0.3207684161986835},{8.513055555555557,0.325876948678175},{8.613333333333335,0.33076923076923087}},["stroke"]="#9b3600",["width"]=1.6}
        local object9 = viewportScene2:point {["fill"]="#9b3600",["id"]="curve-runner-1",["point"]={-5.446666666666667,0},["radius"]=6}
        viewportScene2:shift(object9,{6.0166666666666675,0},1.9,{["preset"]="elastic",["strength"]=0.55})
        viewportScene2:shift(object9,{-6.0166666666666675,0},1.9,{["preset"]="elastic",["reverse"]=true,["strength"]=0.55})
        viewportScene2:shift(object9,{6.0166666666666675,0},1.9,{["preset"]="elastic",["strength"]=0.55})
        viewportScene2:shift(object9,{-6.0166666666666675,0},1.9,{["preset"]="elastic",["reverse"]=true,["strength"]=0.55})
        viewportScene2:wait(0.4)
        viewportScene1:viewport(viewportScene2,{["height"]=0.3333333333333333,["width"]=1,["x"]=0,["y"]=0.3333333333333333})
    end
    do
        local viewportScene2 = tmath.scene {["camera"]={["height"]=1.4,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=30,["height"]=72,["theme"]="pro_white",["width"]=1140}
        local object1 = viewportScene2:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="curve-lane-label-2",["layer"]=40,["point"]={-10.07,0},["role"]="code",["size"]=13,["text"]="BOUNCE  ·  0.80"}
        local object2 = viewportScene2:line {["from"]={-5.446666666666667,0},["id"]="curve-track-2",["stroke"]="#d8dadd",["to"]={0.5700000000000001,0},["width"]=2}
        local object3 = viewportScene2:line {["from"]={-5.446666666666667,-0.12},["id"]="curve-start-2",["stroke"]="#202124",["to"]={-5.446666666666667,0.12},["width"]=2}
        local object4 = viewportScene2:line {["from"]={0.5700000000000001,-0.12},["id"]="curve-stop-2",["stroke"]="#9b3600",["to"]={0.5700000000000001,0.12},["width"]=2}
        local object5 = viewportScene2:line {["from"]={2.5966666666666667,-0.33076923076923076},["id"]="curve-axis-x-2",["stroke"]="#d8dadd",["to"]={8.613333333333335,-0.33076923076923076},["width"]=1}
        local object6 = viewportScene2:line {["from"]={2.5966666666666667,-0.43},["id"]="curve-axis-y-2",["stroke"]="#d8dadd",["to"]={2.5966666666666667,0.43},["width"]=1}
        local object7 = viewportScene2:line {["from"]={8.613333333333335,-0.43},["id"]="curve-axis-r-2",["stroke"]="#d8dadd",["to"]={8.613333333333335,0.43},["width"]=1}
        local object8 = viewportScene2:plot {["id"]="curve-plot-2",["points"]={{2.5966666666666667,-0.33076923076923076},{2.6969444444444446,-0.32745235042735044},{2.7972222222222225,-0.3219119658119658},{2.8975,-0.3141480769230769},{2.997777777777778,-0.3041606837606837},{3.098055555555556,-0.2919497863247863},{3.1983333333333337,-0.2775153846153846},{3.2986111111111116,-0.2608574786324786},{3.398888888888889,-0.24197606837606836},{3.499166666666667,-0.22087115384615383},{3.599444444444445,-0.197542735042735},{3.6997222222222224,-0.171990811965812},{3.8000000000000007,-0.14421538461538452},{3.900277777777778,-0.11421645299145289},{4.000555555555556,-0.08199401709401699},{4.100833333333334,-0.04754807692307683},{4.2011111111111115,-0.010878632478632466},{4.301388888888889,0.028014316239316217},{4.401666666666667,0.06913076923076933},{4.501944444444445,0.11247072649572659},{4.602222222222222,0.15803418803418817},{4.702500000000001,0.2058211538461538},{4.802777777777779,0.24260085470085463},{4.903055555555556,0.2220655982905984},{5.003333333333334,0.20375384615384612},{5.103611111111112,0.18766559829059842},{5.20388888888889,0.17380085470085466},{5.304166666666667,0.16215961538461549},{5.4044444444444455,0.15274188034188046},{5.504722222222223,0.1455476495726497},{5.605,0.1405769230769231},{5.705277777777779,0.13782970085470098},{5.805555555555556,0.137305982905983},{5.905833333333335,0.1390057692307694},{6.006111111111112,0.14292905982905996},{6.10638888888889,0.14907585470085488},{6.206666666666667,0.15744615384615385},{6.306944444444445,0.1680399572649574},{6.407222222222224,0.180857264957265},{6.507500000000001,0.1958980769230771},{6.607777777777779,0.21316239316239333},{6.708055555555557,0.23265021367521382},{6.8083333333333345,0.2543615384615386},{6.908611111111113,0.2782963675213676},{7.00888888888889,0.29122393162393184},{7.109166666666668,0.28322115384615393},{7.209444444444446,0.2774418803418804},{7.309722222222224,0.2738861111111111},{7.410000000000002,0.2725538461538461},{7.510277777777779,0.27344508547008556},{7.610555555555557,0.2765598290598292},{7.710833333333334,0.28189807692307706},{7.811111111111113,0.2894598290598292},{7.91138888888889,0.2992450854700855},{8.011666666666668,0.31125384615384616},{8.111944444444447,0.3172168803418805},{8.212222222222223,0.31548034188034196},{8.312500000000002,0.3159673076923077},{8.41277777777778,0.3186777777777778},{8.513055555555557,0.32361175213675214},{8.613333333333335,0.33076923076923087}},["stroke"]="#9b3600",["width"]=1.6}
        local object9 = viewportScene2:point {["fill"]="#9b3600",["id"]="curve-runner-2",["point"]={-5.446666666666667,0},["radius"]=6}
        viewportScene2:shift(object9,{6.0166666666666675,0},1.9,{["preset"]="bounce",["strength"]=0.8})
        viewportScene2:shift(object9,{-6.0166666666666675,0},1.9,{["preset"]="bounce",["reverse"]=true,["strength"]=0.8})
        viewportScene2:shift(object9,{6.0166666666666675,0},1.9,{["preset"]="bounce",["strength"]=0.8})
        viewportScene2:shift(object9,{-6.0166666666666675,0},1.9,{["preset"]="bounce",["reverse"]=true,["strength"]=0.8})
        viewportScene2:wait(0.4)
        viewportScene1:viewport(viewportScene2,{["height"]=0.3333333333333333,["width"]=1,["x"]=0,["y"]=0.6666666666666666})
    end
    scene:viewport(viewportScene1,{["height"]=0.07233333333333333,["width"]=0.9500000000000001,["x"]=0.024999999999999984,["y"]=0.44})
end
local object54 = scene:text {["align"]={0,0.5},["fill"]="#9b3600",["font"]="Pretendard",["id"]="curve-api-1",["layer"]=40,["point"]={-5.7,-0.5299999999999999},["role"]="code",["size"]=13,["text"]="tmath.animCurve.preset(name, strength)"}
local object55 = scene:text {["align"]={0,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="curve-api-2",["layer"]=40,["point"]={-5.7,-0.7499999999999999},["role"]="code",["size"]=13,["text"]="tmath.animCurve.reverse(curve)"}
local object56 = scene:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="curve-caption-1",["layer"]=40,["point"]={-5.7,-0.9899999999999999},["size"]=12.5,["text"]="Each preset maps normalized time t to progress p(t)."}
local object57 = scene:text {["align"]={0,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="curve-caption-2",["layer"]=40,["point"]={-5.7,-1.23},["size"]=12.5,["text"]="The graph and runner expose overshoot, elasticity, or bounce directly."}
local object58 = scene:line {["from"]={-5.7,-1.4},["id"]="space-rule",["stroke"]="#d8dadd",["to"]={5.7,-1.4},["width"]=1.2}
local object59 = scene:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="space-title",["layer"]=40,["point"]={-5.7,-1.68},["role"]="h2",["size"]=24,["text"]="Coordinates, pixels, and voxels"}
local object60 = scene:text {["align"]={1,0.5},["fill"]="#9b3600",["font"]="Pretendard",["id"]="space-number",["layer"]=40,["point"]={5.7,-1.52},["size"]=10.5,["text"]="07 / SPACE"}
do
    local viewportScene1 = tmath.scene {["camera"]={["height"]=4,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=30,["height"]=237,["theme"]="pro_white",["width"]=1140}
    local object1 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#9b3600",["font"]="Pretendard",["id"]="space-label-0",["layer"]=40,["point"]={-7.215189873417721,1.62},["size"]=10.5,["text"]="2D SPACE"}
    local object2 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="space-api-0",["layer"]=40,["point"]={-7.215189873417721,-1.62},["role"]="code",["size"]=8.7,["text"]="scene.space({ x, y, numbers: true })"}
    local object3 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="space-label-1",["layer"]=40,["point"]={-2.4050632911392404,1.62},["size"]=10.5,["text"]="3D SPACE"}
    local object4 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="space-api-1",["layer"]=40,["point"]={-2.4050632911392404,-1.62},["role"]="code",["size"]=8.7,["text"]="scene.space({ x, y, z })"}
    local object5 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="space-label-2",["layer"]=40,["point"]={2.4050632911392404,1.62},["size"]=10.5,["text"]="CELL"}
    local object6 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="space-api-2",["layer"]=40,["point"]={2.4050632911392404,-1.62},["role"]="code",["size"]=8.7,["text"]="space.cell((x,y) => color)"}
    local object7 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="space-label-3",["layer"]=40,["point"]={7.215189873417721,1.62},["size"]=10.5,["text"]="VOXEL"}
    local object8 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="space-api-3",["layer"]=40,["point"]={7.215189873417721,-1.62},["role"]="code",["size"]=8.7,["text"]="space.voxel((x,y,z) => color)"}
    local object9 = viewportScene1:group {["id"]="space-plane-group",["matrix"]={1,0,0,-7.215189873417721,0,1,0,0,0,0,1,0,0,0,0,1}}
    local object10 = object9:space {["axis_x"]="#202124",["axis_y"]="#202124",["color"]="#d8dadd",["id"]="space-plane-inline",["number_color"]="#555b64",["number_mode"]="fixed",["number_size"]=8,["numbers"]=true,["x"]={-1.35,1.35,0.5},["y"]={-1.05,1.05,0.5}}
    local object11 = object10:vector {["id"]="space-vector-inline",["origin"]={-0.85,-0.55},["stroke"]="#5e7a9b",["tip"]=8,["value"]={1.55,1.05},["width"]=2.2}
    do
        local viewportScene2 = tmath.scene {["camera"]={["eye"]={3.6,2.8,4.1},["far"]=100,["fov"]=0.54,["mode"]="fixed",["near"]=0.1,["projection"]="perspective",["target"]={0,0.1,0},["up"]={0,1,0},["view"]="3d"},["fps"]=30,["height"]=166,["theme"]="pro_white",["width"]=251}
        local object1 = viewportScene2:space {["axis_x"]="#9b3600",["axis_y"]="#b8915a",["axis_z"]="#5e7a9b",["color"]="#d8daddaa",["id"]="space-volume-inline",["numbers"]=false,["x"]={-1.25,1.25,0.5},["y"]={-1.05,1.05,0.5},["z"]={-1.25,1.25,0.5}}
        local object2 = object1:line {["from"]={-0.82,-0.62,-0.82},["id"]="space-volume-edge-0",["stroke"]="#d8daddc8",["to"]={0.82,-0.62,-0.82},["width"]=1.25}
        local object3 = object1:line {["from"]={0.82,-0.62,-0.82},["id"]="space-volume-edge-1",["stroke"]="#d8daddc8",["to"]={0.82,0.62,-0.82},["width"]=1.25}
        local object4 = object1:line {["from"]={0.82,0.62,-0.82},["id"]="space-volume-edge-2",["stroke"]="#d8daddc8",["to"]={-0.82,0.62,-0.82},["width"]=1.25}
        local object5 = object1:line {["from"]={-0.82,0.62,-0.82},["id"]="space-volume-edge-3",["stroke"]="#d8daddc8",["to"]={-0.82,-0.62,-0.82},["width"]=1.25}
        local object6 = object1:line {["from"]={-0.82,-0.62,0.82},["id"]="space-volume-edge-4",["stroke"]="#d8daddc8",["to"]={0.82,-0.62,0.82},["width"]=1.25}
        local object7 = object1:line {["from"]={0.82,-0.62,0.82},["id"]="space-volume-edge-5",["stroke"]="#d8daddc8",["to"]={0.82,0.62,0.82},["width"]=1.25}
        local object8 = object1:line {["from"]={0.82,0.62,0.82},["id"]="space-volume-edge-6",["stroke"]="#d8daddc8",["to"]={-0.82,0.62,0.82},["width"]=1.25}
        local object9 = object1:line {["from"]={-0.82,0.62,0.82},["id"]="space-volume-edge-7",["stroke"]="#d8daddc8",["to"]={-0.82,-0.62,0.82},["width"]=1.25}
        local object10 = object1:line {["from"]={-0.82,-0.62,-0.82},["id"]="space-volume-edge-8",["stroke"]="#d8daddc8",["to"]={-0.82,-0.62,0.82},["width"]=1.25}
        local object11 = object1:line {["from"]={0.82,-0.62,-0.82},["id"]="space-volume-edge-9",["stroke"]="#d8daddc8",["to"]={0.82,-0.62,0.82},["width"]=1.25}
        local object12 = object1:line {["from"]={0.82,0.62,-0.82},["id"]="space-volume-edge-10",["stroke"]="#d8daddc8",["to"]={0.82,0.62,0.82},["width"]=1.25}
        local object13 = object1:line {["from"]={-0.82,0.62,-0.82},["id"]="space-volume-edge-11",["stroke"]="#d8daddc8",["to"]={-0.82,0.62,0.82},["width"]=1.25}
        local object14 = object1:vector {["id"]="space-volume-vector",["stroke"]="#202124",["tip"]=8,["value"]={0.78,0.62,0.92},["width"]=2.4}
        local object15 = object1:point {["fill"]="#9b3600",["id"]="space-volume-point",["layer"]=20,["point"]={0.78,0.62,0.92},["radius"]=4.5,["stroke"]="#ffffff",["width"]=1.4}
        viewportScene2:look({["eye"]={-3.6,2.8,4.1},["far"]=100,["fov"]=0.54,["near"]=0.1,["projection"]="perspective",["target"]={0,0.1,0},["up"]={0,1,0},["view"]="3d"},1.6,"ease_in_out")
        viewportScene2:look({["eye"]={-3.6,2.8,-4.1},["far"]=100,["fov"]=0.54,["near"]=0.1,["projection"]="perspective",["target"]={0,0.1,0},["up"]={0,1,0},["view"]="3d"},1.6,"ease_in_out")
        viewportScene2:look({["eye"]={3.6,2.8,-4.1},["far"]=100,["fov"]=0.54,["near"]=0.1,["projection"]="perspective",["target"]={0,0.1,0},["up"]={0,1,0},["view"]="3d"},1.6,"ease_in_out")
        viewportScene2:look({["eye"]={3.6,2.8,4.1},["far"]=100,["fov"]=0.54,["near"]=0.1,["projection"]="perspective",["target"]={0,0.1,0},["up"]={0,1,0},["view"]="3d"},1.6,"ease_in_out")
        viewportScene2:wait(1.6)
        viewportScene1:viewport(viewportScene2,{["height"]=0.7,["width"]=0.22,["x"]=0.27,["y"]=0.15})
    end
    local object12 = viewportScene1:group {["id"]="space-cell-group",["matrix"]={1,0,0,2.4050632911392404,0,1,0,0,0,0,1,0,0,0,0,1}}
    local object13 = object12:space {["axis_x"]="#d8dadd",["axis_y"]="#d8dadd",["color"]="#d8dadd",["id"]="space-cell-inline",["numbers"]=false,["x"]={-1.35,1.35,0.24},["y"]={-1.05,1.05,0.24}}
    local object14Colors={"#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#9b3600c8","#9b3600c8","#9b3600c8","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#9b3600c8","#9b3600c8","#9b3600c8","#9b3600c8","#9b3600c8","#9b3600c8","#9b3600c8","#00000000","#00000000","#00000000","#00000000","#9b3600c8","#9b3600c8","#9b3600c8","#9b3600c8","#9b3600c8","#9b3600c8","#9b3600c8","#00000000","#00000000","#00000000","#00000000","#9b3600c8","#9b3600c8","#9b3600c8","#9b3600c8","#9b3600c8","#9b3600c8","#9b3600c8","#00000000","#00000000","#00000000","#00000000","#9b3600c8","#9b3600c8","#9b3600c8","#9b3600c8","#9b3600c8","#9b3600c8","#9b3600c8","#00000000","#00000000","#00000000","#00000000","#9b3600c8","#9b3600c8","#9b3600c8","#9b3600c8","#9b3600c8","#9b3600c8","#9b3600c8","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#9b3600c8","#9b3600c8","#9b3600c8","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000"};local object14Index=0;local object14=object13:cell(function(x,y,time) object14Index=object14Index+1;return object14Colors[object14Index] end,{mode="padd",padding=0.045,duration=0,fps=30})
    local object15 = viewportScene1:group {["id"]="space-voxel-group",["matrix"]={1,0,0.42,7.215189873417721,0,1,0.3,0,0,0,1,0,0,0,0,1}}
    local object16 = object15:space {["id"]="space-voxel-inline",["numbers"]=false,["opacity"]=0,["x"]={-1.25,1.25,0.42},["y"]={-1.05,1.05,0.42},["z"]={-1.25,1.25,0.42}}
    local object17Colors={"#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#5e7a9ba8","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#5e7a9ba8","#5e7a9ba8","#5e7a9ba8","#00000000","#00000000","#5e7a9ba8","#5e7a9ba8","#5e7a9ba8","#00000000","#00000000","#5e7a9ba8","#5e7a9ba8","#5e7a9ba8","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#5e7a9ba8","#5e7a9ba8","#5e7a9ba8","#00000000","#5e7a9ba8","#5e7a9ba8","#5e7a9ba8","#5e7a9ba8","#5e7a9ba8","#00000000","#5e7a9ba8","#5e7a9ba8","#5e7a9ba8","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#5e7a9ba8","#5e7a9ba8","#5e7a9ba8","#00000000","#00000000","#5e7a9ba8","#5e7a9ba8","#5e7a9ba8","#00000000","#00000000","#5e7a9ba8","#5e7a9ba8","#5e7a9ba8","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#9b3600d8","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000","#00000000"};local object17Index=0;local object17=object16:voxel(function(x,y,z,time) object17Index=object17Index+1;return object17Colors[object17Index] end,{mode="padd",padding=0.07,duration=0,fps=30})
    viewportScene1:play({{target=object9,transform={1.08,0,0,-7.215189873417721,0,1.08,0,0,0,0,1,0,0,0,0,1}},{target=object12,transform={1.18,0,0,2.4050632911392404,0,0.84,0,0,0,0,1,0,0,0,0,1}},{target=object15,transform={1.08,0,-0.52,7.215189873417721,0,0.92,0.36,0,0,0,1,0,0,0,0,1}}},1.35,"ease_in_out",0)
    viewportScene1:wait(0.55)
    viewportScene1:play({{target=object9,transform={1,0,0,-7.215189873417721,0,1,0,0,0,0,1,0,0,0,0,1}},{target=object12,transform={1,0,0,2.4050632911392404,0,1,0,0,0,0,1,0,0,0,0,1}},{target=object15,transform={1,0,0.42,7.215189873417721,0,1,0.3,0,0,0,1,0,0,0,0,1}}},1.35,"ease_in_out",0)
    viewportScene1:wait(0.55)
    viewportScene1:play({{target=object9,transform={1.08,0,0,-7.215189873417721,0,1.08,0,0,0,0,1,0,0,0,0,1}},{target=object12,transform={1.18,0,0,2.4050632911392404,0,0.84,0,0,0,0,1,0,0,0,0,1}},{target=object15,transform={1.08,0,-0.52,7.215189873417721,0,0.92,0.36,0,0,0,1,0,0,0,0,1}}},1.35,"ease_in_out",0)
    viewportScene1:wait(0.55)
    viewportScene1:play({{target=object9,transform={1,0,0,-7.215189873417721,0,1,0,0,0,0,1,0,0,0,0,1}},{target=object12,transform={1,0,0,2.4050632911392404,0,1,0,0,0,0,1,0,0,0,0,1}},{target=object15,transform={1,0,0.42,7.215189873417721,0,1,0.3,0,0,0,1,0,0,0,0,1}}},1.35,"ease_in_out",0)
    viewportScene1:wait(0.55)
    viewportScene1:wait(0.4)
    scene:viewport(viewportScene1,{["height"]=0.07900000000000003,["width"]=0.9500000000000001,["x"]=0.024999999999999984,["y"]=0.5616666666666668})
end
local object61 = scene:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="space-caption-1",["layer"]=40,["point"]={-5.7,-4.470000000000001},["size"]=12.5,["text"]="Each figure calls the Space API printed directly beneath it."}
local object62 = scene:text {["align"]={0,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="space-caption-2",["layer"]=40,["point"]={-5.7,-4.710000000000001},["size"]=12.5,["text"]="The coordinate systems and sampled Cell / Voxel results remain retained objects."}
local object63 = scene:line {["from"]={-5.7,-5.15},["id"]="advanced-rule",["stroke"]="#d8dadd",["to"]={1.8,-5.15},["width"]=1.2}
local object64 = scene:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="advanced-title",["layer"]=40,["point"]={-5.7,-5.430000000000001},["role"]="h2",["size"]=24,["text"]="Advanced camera recipes"}
local object65 = scene:text {["align"]={1,0.5},["fill"]="#9b3600",["font"]="Pretendard",["id"]="advanced-number",["layer"]=40,["point"]={1.8,-5.2700000000000005},["size"]=10.5,["text"]="08 / ADVANCED"}
do
    local viewportScene1 = tmath.scene {["camera"]={["height"]=4,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=30,["height"]=277,["theme"]="pro_white",["width"]=750}
    local object1 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#9b3600",["font"]="Pretendard",["id"]="advanced-follow-label",["layer"]=40,["point"]={-3.303249097472924,1.62},["size"]=10.5,["text"]="FOLLOW CAMERA"}
    local object2 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#5e7a9b",["font"]="Pretendard",["id"]="advanced-orbit-label",["layer"]=40,["point"]={0.16245487364620953,1.62},["size"]=10.5,["text"]="ORBIT CAMERA"}
    local object3 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="advanced-dimension-label",["layer"]=40,["point"]={3.465703971119134,1.62},["size"]=10.5,["text"]="2D ↔ 3D VIEW"}
    local object4 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="advanced-follow-api",["layer"]=40,["point"]={-3.303249097472924,-1.62},["role"]="code",["size"]=7.8,["text"]="scene.transform(world, cameraMatrix(sample), dt)"}
    local object5 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="advanced-orbit-api",["layer"]=40,["point"]={0.16245487364620953,-1.62},["role"]="code",["size"]=7.8,["text"]="scene.look({ eye, target }, duration)"}
    local object6 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="advanced-dimension-api",["layer"]=40,["point"]={3.465703971119134,-1.62},["role"]="code",["size"]=7.8,["text"]="scene.look({ view: \\"2d\\" | \\"3d\\", ... }, duration)"}
    do
        local viewportScene2 = tmath.scene {["camera"]={["height"]=4,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=30,["height"]=177,["theme"]="pro_white",["width"]=278}
        local object1 = viewportScene2:group {["id"]="advanced-follow-world",["matrix"]={1.2,0,0,0,0,1.2,0,-0.15,0,0,1,0,0,0,0,1}}
        local object2 = object1:space {["axis_x"]="#202124",["axis_y"]="#202124",["color"]="#d8dadd",["id"]="advanced-follow-grid",["numbers"]=false,["x"]={-1,10,1},["y"]={-2,2,0.5}}
        local object3 = object2:plot {["id"]="advanced-follow-path",["points"]={{0,0},{0.07853981633974483,0.07845909572784494},{0.15707963267948966,0.15643446504023087},{0.23561944901923448,0.2334453638559054},{0.3141592653589793,0.3090169943749474},{0.3926990816987241,0.3826834323650897},{0.47123889803846897,0.4539904997395468},{0.5497787143782138,0.5224985647159488},{0.6283185307179586,0.5877852522924731},{0.7068583470577035,0.6494480483301837},{0.7853981633974482,0.7071067811865475},{0.8639379797371931,0.7604059656000309},{0.9424777960769379,0.8090169943749475},{1.0210176124166828,0.8526401643540922},{1.0995574287564276,0.8910065241883678},{1.1780972450961724,0.9238795325112867},{1.2566370614359172,0.9510565162951535},{1.335176877775662,0.9723699203976766},{1.413716694115407,0.9876883405951378},{1.4922565104551517,0.996917333733128},{1.5707963267948963,1},{1.6493361431346414,0.996917333733128},{1.7278759594743862,0.9876883405951378},{1.806415775814131,0.9723699203976767},{1.8849555921538759,0.9510565162951536},{1.9634954084936207,0.9238795325112867},{2.0420352248333655,0.8910065241883679},{2.1205750411731104,0.8526401643540923},{2.199114857512855,0.8090169943749475},{2.2776546738526,0.760405965600031},{2.356194490192345,0.7071067811865476},{2.4347343065320897,0.6494480483301838},{2.5132741228718345,0.5877852522924732},{2.5918139392115793,0.5224985647159489},{2.670353755551324,0.45399049973954686},{2.748893571891069,0.3826834323650899},{2.827433388230814,0.3090169943749475},{2.9059732045705586,0.23344536385590553},{2.9845130209103035,0.15643446504023098},{3.0630528372500483,0.07845909572784507},{3.1415926535897927,5.66553889764798e-16},{3.220132469929538,-0.07845909572784482},{3.2986722862692828,-0.15643446504023073},{3.3772121026090276,-0.23344536385590528},{3.4557519189487724,-0.3090169943749473},{3.5342917352885173,-0.3826834323650896},{3.612831551628262,-0.4539904997395467},{3.691371367968007,-0.5224985647159487},{3.7699111843077517,-0.587785252292473},{3.8484510006474966,-0.6494480483301835},{3.9269908169872414,-0.7071067811865475},{4.005530633326987,-0.7604059656000312},{4.084070449666731,-0.8090169943749473},{4.162610266006476,-0.8526401643540924},{4.241150082346221,-0.8910065241883678},{4.319689898685965,-0.9238795325112865},{4.39822971502571,-0.9510565162951535},{4.476769531365455,-0.9723699203976764},{4.5553093477052,-0.9876883405951377},{4.633849164044945,-0.996917333733128},{4.71238898038469,-1},{4.790928796724434,-0.9969173337331281},{4.869468613064179,-0.9876883405951378},{4.948008429403925,-0.9723699203976766},{5.026548245743669,-0.9510565162951536},{5.105088062083413,-0.923879532511287},{5.183627878423159,-0.891006524188368},{5.262167694762904,-0.8526401643540921},{5.340707511102648,-0.8090169943749476},{5.419247327442393,-0.7604059656000314},{5.497787143782138,-0.7071067811865477},{5.576326960121883,-0.6494480483301834},{5.654866776461628,-0.5877852522924734},{5.733406592801373,-0.5224985647159487},{5.811946409141117,-0.45399049973954697},{5.890486225480862,-0.3826834323650904},{5.969026041820607,-0.3090169943749476},{6.047565858160352,-0.2334453638559052},{6.126105674500097,-0.15643446504023112},{6.204645490839841,-0.07845909572784562},{6.283185307179585,-1.133107779529596e-15},{6.3617251235193315,0.07845909572784514},{6.440264939859076,0.15643446504023062},{6.51880475619882,0.23344536385590473},{6.5973445725385655,0.3090169943749472},{6.675884388878311,0.38268343236508995},{6.754424205218055,0.4539904997395466},{6.8329640215578,0.5224985647159482},{6.911503837897545,0.5877852522924729},{6.990043654237289,0.6494480483301831},{7.0685834705770345,0.7071067811865474},{7.14712328691678,0.760405965600031},{7.225663103256524,0.8090169943749472},{7.3042029195962686,0.8526401643540918},{7.382742735936014,0.8910065241883678},{7.461282552275759,0.9238795325112868},{7.5398223686155035,0.9510565162951535},{7.618362184955248,0.9723699203976764},{7.696902001294993,0.9876883405951377},{7.775441817634738,0.996917333733128},{7.853981633974483,1},{7.932521450314227,0.9969173337331281},{8.011061266653973,0.9876883405951377},{8.089601082993717,0.9723699203976768},{8.168140899333462,0.9510565162951536},{8.246680715673207,0.9238795325112867},{8.325220532012953,0.8910065241883676},{8.403760348352696,0.8526401643540926},{8.482300164692441,0.8090169943749476},{8.560839981032187,0.7604059656000308},{8.63937979737193,0.7071067811865483},{8.717919613711675,0.6494480483301842},{8.79645943005142,0.5877852522924734},{8.874999246391164,0.5224985647159504},{8.95353906273091,0.4539904997395479},{9.032078879070657,0.38268343236508884},{9.1106186954104,0.3090169943749478},{9.189158511750145,0.23344536385590534},{9.26769832808989,0.15643446504023034},{9.346238144429634,0.07845909572784575},{9.42477796076938,3.6739403974420594e-16}},["stroke"]="#5e7a9b",["width"]=3.4}
        local object4 = object2:point {["fill"]="#202124",["id"]="advanced-follow-start",["point"]={0,0},["radius"]=4}
        local object5 = object2:point {["fill"]="#202124",["id"]="advanced-follow-end",["point"]={9.42477796076938,0},["radius"]=4}
        local object6 = viewportScene2:rectangle {["center"]={0,-0.15},["corner"]=0.08,["fill"]="#00000000",["id"]="advanced-follow-frame",["layer"]=1,["size"]={3.5,2.15},["stroke"]="#9b360088",["width"]=2}
        local object7 = viewportScene2:point {["fill"]="#9b3600",["id"]="advanced-follow-focus",["layer"]=20,["point"]={0,-0.15},["radius"]=8,["stroke"]="#ffffff",["width"]=3}
        viewportScene2:transform(object1,{1.2,0,0,-0.09424777960769379,0,1.2,0,-0.24415091487341392,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-0.18849555921538758,0,1.2,0,-0.337721358048277,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-0.2827433388230814,0,1.2,0,-0.4301344366270865,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-0.37699111843077515,0,1.2,0,-0.5208203932499369,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-0.47123889803846886,0,1.2,0,-0.6092201188381077,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-0.5654866776461628,0,1.2,0,-0.6947885996874562,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-0.6597344572538565,0,1.2,0,-0.7769982776591385,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-0.7539822368615503,0,1.2,0,-0.8553423027509678,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-0.8482300164692441,0,1.2,0,-0.9293376579962204,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-0.9424777960769377,0,1.2,0,-0.9985281374238569,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-1.0367255756846316,0,1.2,0,-1.062487158720037,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-1.1309733552923256,0,1.2,0,-1.1208203932499368,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-1.2252211349000193,0,1.2,0,-1.1731681972249104,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-1.319468914507713,0,1.2,0,-1.2192078290260413,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-1.413716694115407,0,1.2,0,-1.258655439013544,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-1.5079644737231006,0,1.2,0,-1.291267819554184,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-1.6022122533307945,0,1.2,0,-1.3168439044772118,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-1.6964600329384882,0,1.2,0,-1.3352260087141652,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-1.790707812546182,0,1.2,0,-1.3463008004797534,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-1.8849555921538754,0,1.2,0,-1.3499999999999999,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-1.9792033717615696,0,1.2,0,-1.3463008004797534,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-2.0734511513692633,0,1.2,0,-1.3352260087141652,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-2.167698930976957,0,1.2,0,-1.3168439044772118,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-2.261946710584651,0,1.2,0,-1.2912678195541842,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-2.356194490192345,0,1.2,0,-1.258655439013544,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-2.4504422698000385,0,1.2,0,-1.2192078290260413,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-2.5446900494077322,0,1.2,0,-1.1731681972249106,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-2.638937829015426,0,1.2,0,-1.1208203932499368,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-2.73318560862312,0,1.2,0,-1.062487158720037,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-2.827433388230814,0,1.2,0,-0.998528137423857,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-2.9216811678385075,0,1.2,0,-0.9293376579962205,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-3.015928947446201,0,1.2,0,-0.8553423027509679,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-3.110176727053895,0,1.2,0,-0.7769982776591386,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-3.204424506661589,0,1.2,0,-0.6947885996874562,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-3.2986722862692828,0,1.2,0,-0.6092201188381079,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-3.3929200658769765,0,1.2,0,-0.520820393249937,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-3.48716784548467,0,1.2,0,-0.4301344366270866,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-3.581415625092364,0,1.2,0,-0.3377213580482772,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-3.6756634047000576,0,1.2,0,-0.24415091487341406,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-3.769911184307751,0,1.2,0,-0.15000000000000066,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-3.8641589639154454,0,1.2,0,-0.05584908512658622,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-3.958406743523139,0,1.2,0,0.037721358048276865,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-4.052654523130833,0,1.2,0,0.13013443662708632,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-4.146902302738527,0,1.2,0,0.22082039324993671,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-4.241150082346221,0,1.2,0,0.3092201188381075,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-4.335397861953914,0,1.2,0,0.39478859968745594,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-4.429645641561608,0,1.2,0,0.4769982776591384,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-4.523893421169302,0,1.2,0,0.5553423027509676,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-4.6181412007769955,0,1.2,0,0.6293376579962202,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-4.71238898038469,0,1.2,0,0.6985281374238569,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-4.806636759992384,0,1.2,0,0.7624871587200374,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-4.900884539600077,0,1.2,0,0.8208203932499367,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-4.995132319207771,0,1.2,0,0.8731681972249109,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-5.0893800988154645,0,1.2,0,0.9192078290260414,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-5.183627878423158,0,1.2,0,0.9586554390135437,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-5.277875658030852,0,1.2,0,0.9912678195541841,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-5.372123437638545,0,1.2,0,1.0168439044772117,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-5.46637121724624,0,1.2,0,1.0352260087141651,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-5.560618996853934,0,1.2,0,1.0463008004797536,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-5.654866776461628,0,1.2,0,1.05,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-5.749114556069321,0,1.2,0,1.0463008004797538,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-5.843362335677015,0,1.2,0,1.0352260087141654,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-5.937610115284709,0,1.2,0,1.016843904477212,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-6.031857894892402,0,1.2,0,0.9912678195541843,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-6.126105674500096,0,1.2,0,0.9586554390135443,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-6.22035345410779,0,1.2,0,0.9192078290260416,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-6.314601233715485,0,1.2,0,0.8731681972249105,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-6.408849013323178,0,1.2,0,0.820820393249937,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-6.503096792930871,0,1.2,0,0.7624871587200376,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-6.5973445725385655,0,1.2,0,0.6985281374238572,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-6.69159235214626,0,1.2,0,0.6293376579962201,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-6.785840131753953,0,1.2,0,0.555342302750968,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-6.880087911361647,0,1.2,0,0.4769982776591384,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-6.97433569096934,0,1.2,0,0.3947885996874563,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-7.068583470577034,0,1.2,0,0.3092201188381084,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-7.162831250184728,0,1.2,0,0.22082039324993716,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-7.257079029792422,0,1.2,0,0.1301344366270862,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-7.351326809400115,0,1.2,0,0.03772135804827734,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-7.445574589007808,0,1.2,0,-0.05584908512658525,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-7.539822368615502,0,1.2,0,-0.14999999999999863,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-7.634070148223198,0,1.2,0,-0.24415091487341417,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-7.728317927830891,0,1.2,0,-0.33772135804827674,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-7.822565707438584,0,1.2,0,-0.4301344366270856,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-7.916813487046278,0,1.2,0,-0.5208203932499366,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-8.011061266653973,0,1.2,0,-0.6092201188381079,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-8.105309046261667,0,1.2,0,-0.6947885996874559,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-8.19955682586936,0,1.2,0,-0.7769982776591379,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-8.293804605477053,0,1.2,0,-0.8553423027509675,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-8.388052385084746,0,1.2,0,-0.9293376579962197,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-8.482300164692441,0,1.2,0,-0.9985281374238568,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-8.576547944300135,0,1.2,0,-1.062487158720037,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-8.670795723907828,0,1.2,0,-1.1208203932499365,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-8.765043503515521,0,1.2,0,-1.1731681972249102,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-8.859291283123216,0,1.2,0,-1.2192078290260413,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-8.953539062730911,0,1.2,0,-1.258655439013544,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-9.047786842338605,0,1.2,0,-1.291267819554184,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-9.142034621946298,0,1.2,0,-1.3168439044772116,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-9.236282401553991,0,1.2,0,-1.335226008714165,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-9.330530181161686,0,1.2,0,-1.3463008004797534,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-9.42477796076938,0,1.2,0,-1.3499999999999999,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-9.519025740377073,0,1.2,0,-1.3463008004797536,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-9.613273519984768,0,1.2,0,-1.335226008714165,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-9.70752129959246,0,1.2,0,-1.316843904477212,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-9.801769079200154,0,1.2,0,-1.2912678195541842,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-9.89601685880785,0,1.2,0,-1.258655439013544,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-9.990264638415542,0,1.2,0,-1.2192078290260409,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-10.084512418023236,0,1.2,0,-1.173168197224911,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-10.178760197630929,0,1.2,0,-1.120820393249937,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-10.273007977238624,0,1.2,0,-1.0624871587200369,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-10.367255756846316,0,1.2,0,-0.998528137423858,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-10.46150353645401,0,1.2,0,-0.929337657996221,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-10.555751316061704,0,1.2,0,-0.855342302750968,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-10.649999095669397,0,1.2,0,-0.7769982776591404,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-10.74424687527709,0,1.2,0,-0.6947885996874575,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-10.838494654884787,0,1.2,0,-0.6092201188381066,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-10.93274243449248,0,1.2,0,-0.5208203932499373,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-11.026990214100174,0,1.2,0,-0.4301344366270864,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-11.121237993707869,0,1.2,0,-0.3377213580482764,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-11.21548577331556,0,1.2,0,-0.2441509148734149,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-11.309733552923255,0,1.2,0,-0.15000000000000044,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,0,0,1.2,0,-0.15,0,0,1,0,0,0,0,1},0.6,"ease_in_out")
        viewportScene2:wait(0.2)
        viewportScene2:transform(object1,{1.2,0,0,-0.09424777960769379,0,1.2,0,-0.24415091487341392,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-0.18849555921538758,0,1.2,0,-0.337721358048277,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-0.2827433388230814,0,1.2,0,-0.4301344366270865,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-0.37699111843077515,0,1.2,0,-0.5208203932499369,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-0.47123889803846886,0,1.2,0,-0.6092201188381077,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-0.5654866776461628,0,1.2,0,-0.6947885996874562,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-0.6597344572538565,0,1.2,0,-0.7769982776591385,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-0.7539822368615503,0,1.2,0,-0.8553423027509678,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-0.8482300164692441,0,1.2,0,-0.9293376579962204,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-0.9424777960769377,0,1.2,0,-0.9985281374238569,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-1.0367255756846316,0,1.2,0,-1.062487158720037,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-1.1309733552923256,0,1.2,0,-1.1208203932499368,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-1.2252211349000193,0,1.2,0,-1.1731681972249104,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-1.319468914507713,0,1.2,0,-1.2192078290260413,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-1.413716694115407,0,1.2,0,-1.258655439013544,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-1.5079644737231006,0,1.2,0,-1.291267819554184,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-1.6022122533307945,0,1.2,0,-1.3168439044772118,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-1.6964600329384882,0,1.2,0,-1.3352260087141652,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-1.790707812546182,0,1.2,0,-1.3463008004797534,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-1.8849555921538754,0,1.2,0,-1.3499999999999999,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-1.9792033717615696,0,1.2,0,-1.3463008004797534,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-2.0734511513692633,0,1.2,0,-1.3352260087141652,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-2.167698930976957,0,1.2,0,-1.3168439044772118,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-2.261946710584651,0,1.2,0,-1.2912678195541842,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-2.356194490192345,0,1.2,0,-1.258655439013544,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-2.4504422698000385,0,1.2,0,-1.2192078290260413,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-2.5446900494077322,0,1.2,0,-1.1731681972249106,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-2.638937829015426,0,1.2,0,-1.1208203932499368,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-2.73318560862312,0,1.2,0,-1.062487158720037,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-2.827433388230814,0,1.2,0,-0.998528137423857,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-2.9216811678385075,0,1.2,0,-0.9293376579962205,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-3.015928947446201,0,1.2,0,-0.8553423027509679,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-3.110176727053895,0,1.2,0,-0.7769982776591386,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-3.204424506661589,0,1.2,0,-0.6947885996874562,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-3.2986722862692828,0,1.2,0,-0.6092201188381079,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-3.3929200658769765,0,1.2,0,-0.520820393249937,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-3.48716784548467,0,1.2,0,-0.4301344366270866,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-3.581415625092364,0,1.2,0,-0.3377213580482772,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-3.6756634047000576,0,1.2,0,-0.24415091487341406,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-3.769911184307751,0,1.2,0,-0.15000000000000066,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-3.8641589639154454,0,1.2,0,-0.05584908512658622,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-3.958406743523139,0,1.2,0,0.037721358048276865,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-4.052654523130833,0,1.2,0,0.13013443662708632,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-4.146902302738527,0,1.2,0,0.22082039324993671,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-4.241150082346221,0,1.2,0,0.3092201188381075,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-4.335397861953914,0,1.2,0,0.39478859968745594,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-4.429645641561608,0,1.2,0,0.4769982776591384,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-4.523893421169302,0,1.2,0,0.5553423027509676,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-4.6181412007769955,0,1.2,0,0.6293376579962202,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-4.71238898038469,0,1.2,0,0.6985281374238569,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-4.806636759992384,0,1.2,0,0.7624871587200374,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-4.900884539600077,0,1.2,0,0.8208203932499367,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-4.995132319207771,0,1.2,0,0.8731681972249109,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-5.0893800988154645,0,1.2,0,0.9192078290260414,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-5.183627878423158,0,1.2,0,0.9586554390135437,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-5.277875658030852,0,1.2,0,0.9912678195541841,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-5.372123437638545,0,1.2,0,1.0168439044772117,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-5.46637121724624,0,1.2,0,1.0352260087141651,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-5.560618996853934,0,1.2,0,1.0463008004797536,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-5.654866776461628,0,1.2,0,1.05,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-5.749114556069321,0,1.2,0,1.0463008004797538,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-5.843362335677015,0,1.2,0,1.0352260087141654,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-5.937610115284709,0,1.2,0,1.016843904477212,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-6.031857894892402,0,1.2,0,0.9912678195541843,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-6.126105674500096,0,1.2,0,0.9586554390135443,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-6.22035345410779,0,1.2,0,0.9192078290260416,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-6.314601233715485,0,1.2,0,0.8731681972249105,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-6.408849013323178,0,1.2,0,0.820820393249937,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-6.503096792930871,0,1.2,0,0.7624871587200376,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-6.5973445725385655,0,1.2,0,0.6985281374238572,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-6.69159235214626,0,1.2,0,0.6293376579962201,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-6.785840131753953,0,1.2,0,0.555342302750968,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-6.880087911361647,0,1.2,0,0.4769982776591384,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-6.97433569096934,0,1.2,0,0.3947885996874563,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-7.068583470577034,0,1.2,0,0.3092201188381084,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-7.162831250184728,0,1.2,0,0.22082039324993716,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-7.257079029792422,0,1.2,0,0.1301344366270862,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-7.351326809400115,0,1.2,0,0.03772135804827734,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-7.445574589007808,0,1.2,0,-0.05584908512658525,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-7.539822368615502,0,1.2,0,-0.14999999999999863,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-7.634070148223198,0,1.2,0,-0.24415091487341417,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-7.728317927830891,0,1.2,0,-0.33772135804827674,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-7.822565707438584,0,1.2,0,-0.4301344366270856,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-7.916813487046278,0,1.2,0,-0.5208203932499366,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-8.011061266653973,0,1.2,0,-0.6092201188381079,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-8.105309046261667,0,1.2,0,-0.6947885996874559,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-8.19955682586936,0,1.2,0,-0.7769982776591379,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-8.293804605477053,0,1.2,0,-0.8553423027509675,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-8.388052385084746,0,1.2,0,-0.9293376579962197,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-8.482300164692441,0,1.2,0,-0.9985281374238568,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-8.576547944300135,0,1.2,0,-1.062487158720037,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-8.670795723907828,0,1.2,0,-1.1208203932499365,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-8.765043503515521,0,1.2,0,-1.1731681972249102,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-8.859291283123216,0,1.2,0,-1.2192078290260413,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-8.953539062730911,0,1.2,0,-1.258655439013544,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-9.047786842338605,0,1.2,0,-1.291267819554184,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-9.142034621946298,0,1.2,0,-1.3168439044772116,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-9.236282401553991,0,1.2,0,-1.335226008714165,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-9.330530181161686,0,1.2,0,-1.3463008004797534,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-9.42477796076938,0,1.2,0,-1.3499999999999999,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-9.519025740377073,0,1.2,0,-1.3463008004797536,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-9.613273519984768,0,1.2,0,-1.335226008714165,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-9.70752129959246,0,1.2,0,-1.316843904477212,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-9.801769079200154,0,1.2,0,-1.2912678195541842,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-9.89601685880785,0,1.2,0,-1.258655439013544,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-9.990264638415542,0,1.2,0,-1.2192078290260409,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-10.084512418023236,0,1.2,0,-1.173168197224911,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-10.178760197630929,0,1.2,0,-1.120820393249937,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-10.273007977238624,0,1.2,0,-1.0624871587200369,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-10.367255756846316,0,1.2,0,-0.998528137423858,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-10.46150353645401,0,1.2,0,-0.929337657996221,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-10.555751316061704,0,1.2,0,-0.855342302750968,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-10.649999095669397,0,1.2,0,-0.7769982776591404,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-10.74424687527709,0,1.2,0,-0.6947885996874575,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-10.838494654884787,0,1.2,0,-0.6092201188381066,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-10.93274243449248,0,1.2,0,-0.5208203932499373,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-11.026990214100174,0,1.2,0,-0.4301344366270864,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-11.121237993707869,0,1.2,0,-0.3377213580482764,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-11.21548577331556,0,1.2,0,-0.2441509148734149,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,-11.309733552923255,0,1.2,0,-0.15000000000000044,0,0,1,0,0,0,0,1},0.025,"linear")
        viewportScene2:transform(object1,{1.2,0,0,0,0,1.2,0,-0.15,0,0,1,0,0,0,0,1},0.6,"ease_in_out")
        viewportScene2:wait(0.2)
        viewportScene2:wait(0.4)
        viewportScene1:viewport(viewportScene2,{["height"]=0.64,["width"]=0.37,["x"]=0.01,["y"]=0.16})
    end
    do
        local viewportScene2 = tmath.scene {["camera"]={["eye"]={5.8,4.6,6.2},["far"]=100,["fov"]=0.68,["mode"]="fixed",["near"]=0.1,["projection"]="perspective",["target"]={0,0,0},["up"]={0,1,0},["view"]="3d"},["fps"]=30,["height"]=177,["theme"]="pro_white",["width"]=173}
        local object1 = viewportScene2:arrow {["from"]={-2.6,0,0},["id"]="camera-axis-x",["stroke"]="#9b3600",["tip"]=10,["to"]={2.6,0,0},["width"]=3}
        local object2 = viewportScene2:arrow {["from"]={0,-2.6,0},["id"]="camera-axis-y",["stroke"]="#b8915a",["tip"]=10,["to"]={0,2.6,0},["width"]=3}
        local object3 = viewportScene2:arrow {["from"]={0,0,-2.6},["id"]="camera-axis-z",["stroke"]="#5e7a9b",["tip"]=10,["to"]={0,0,2.6},["width"]=3}
        local object4 = viewportScene2:plot {["id"]="camera-fixed-circle",["points"]={{2,0,0},{1.995717846477207,0,0.13080625846028612},{1.9828897227476208,0,0.26105238444010315},{1.9615705608064609,0,0.3901806440322565},{1.9318516525781366,0,0.5176380902050415},{1.8938602589902114,0,0.6428789306063232},{1.8477590650225735,0,0.7653668647301796},{1.7937454830653767,0,0.8845773804380025},{1.7320508075688774,0,0.9999999999999999},{1.6629392246050905,0,1.1111404660392044},{1.5867066805824703,0,1.2175228580174413},{1.5036796149579548,0,1.3186916302001377},{1.4142135623730951,0,1.414213562373095},{1.3186916302001377,0,1.5036796149579548},{1.2175228580174413,0,1.5867066805824703},{1.1111404660392048,0,1.6629392246050902},{1.0000000000000002,0,1.7320508075688772},{0.8845773804380025,0,1.7937454830653767},{0.7653668647301797,0,1.8477590650225735},{0.6428789306063234,0,1.8938602589902112},{0.5176380902050415,0,1.9318516525781366},{0.39018064403225666,0,1.9615705608064609},{0.2610523844401034,0,1.9828897227476208},{0.13080625846028654,0,1.995717846477207},{1.2246467991473532e-16,0,2},{-0.1308062584602863,0,1.995717846477207},{-0.2610523844401032,0,1.9828897227476208},{-0.3901806440322564,0,1.9615705608064609},{-0.5176380902050413,0,1.9318516525781366},{-0.6428789306063232,0,1.8938602589902114},{-0.765366864730179,0,1.8477590650225737},{-0.8845773804380023,0,1.7937454830653767},{-0.9999999999999996,0,1.7320508075688774},{-1.1111404660392046,0,1.6629392246050902},{-1.2175228580174413,0,1.5867066805824703},{-1.3186916302001377,0,1.5036796149579548},{-1.414213562373095,0,1.4142135623730951},{-1.5036796149579545,0,1.318691630200138},{-1.58670668058247,0,1.2175228580174418},{-1.66293922460509,0,1.111140466039205},{-1.7320508075688774,0,0.9999999999999999},{-1.7937454830653763,0,0.8845773804380034},{-1.8477590650225735,0,0.7653668647301798},{-1.8938602589902112,0,0.6428789306063235},{-1.9318516525781364,0,0.517638090205042},{-1.9615705608064609,0,0.39018064403225633},{-1.9828897227476208,0,0.261052384440104},{-1.995717846477207,0,0.13080625846028623},{-2,0,2.4492935982947064e-16},{-1.995717846477207,0,-0.13080625846028573},{-1.9828897227476208,0,-0.26105238444010354},{-1.961570560806461,0,-0.39018064403225583},{-1.9318516525781366,0,-0.5176380902050416},{-1.8938602589902114,0,-0.6428789306063231},{-1.8477590650225737,0,-0.7653668647301792},{-1.7937454830653765,0,-0.8845773804380029},{-1.7320508075688776,0,-0.9999999999999994},{-1.662939224605091,0,-1.111140466039204},{-1.5867066805824703,0,-1.2175228580174413},{-1.5036796149579548,0,-1.3186916302001377},{-1.4142135623730958,0,-1.4142135623730943},{-1.3186916302001381,0,-1.5036796149579545},{-1.2175228580174418,0,-1.5867066805824699},{-1.1111404660392044,0,-1.6629392246050905},{-1.0000000000000009,0,-1.732050807568877},{-0.8845773804380027,0,-1.7937454830653765},{-0.765366864730179,0,-1.8477590650225737},{-0.6428789306063236,0,-1.8938602589902112},{-0.5176380902050413,0,-1.9318516525781366},{-0.39018064403225733,0,-1.9615705608064606},{-0.26105238444010326,0,-1.9828897227476208},{-0.13080625846028546,0,-1.995717846477207},{-3.6739403974420594e-16,0,-2},{0.13080625846028474,0,-1.9957178464772072},{0.26105238444010254,0,-1.982889722747621},{0.3901806440322566,0,-1.9615705608064609},{0.5176380902050406,0,-1.9318516525781368},{0.642878930606323,0,-1.8938602589902114},{0.7653668647301783,0,-1.847759065022574},{0.884577380438002,0,-1.793745483065377},{1.0000000000000002,0,-1.7320508075688772},{1.1111404660392037,0,-1.662939224605091},{1.2175228580174398,0,-1.5867066805824714},{1.3186916302001381,0,-1.5036796149579543},{1.4142135623730947,0,-1.4142135623730954},{1.503679614957955,0,-1.3186916302001375},{1.5867066805824699,0,-1.2175228580174418},{1.6629392246050894,0,-1.111140466039206},{1.7320508075688767,0,-1.0000000000000009},{1.7937454830653765,0,-0.8845773804380028},{1.8477590650225737,0,-0.7653668647301791},{1.8938602589902112,0,-0.6428789306063237},{1.9318516525781362,0,-0.5176380902050431},{1.9615705608064606,0,-0.39018064403225744},{1.9828897227476208,0,-0.26105238444010337},{1.995717846477207,0,-0.1308062584602856},{2,0,-4.898587196589413e-16}},["stroke"]="#5e7a9b",["width"]=5}
        local object5 = viewportScene2:vector {["id"]="camera-normal",["origin"]={0,0,0},["stroke"]="#9b3600",["tip"]=12,["value"]={0,1.8,0},["width"]=4}
        viewportScene2:look({["eye"]={-5.8,4.6,6.2},["far"]=100,["fov"]=0.68,["near"]=0.1,["projection"]="perspective",["target"]={0,0,0},["up"]={0,1,0},["view"]="3d"},1.6,"linear")
        viewportScene2:look({["eye"]={-5.8,4.6,-6.2},["far"]=100,["fov"]=0.68,["near"]=0.1,["projection"]="perspective",["target"]={0,0,0},["up"]={0,1,0},["view"]="3d"},1.6,"linear")
        viewportScene2:look({["eye"]={5.8,4.6,-6.2},["far"]=100,["fov"]=0.68,["near"]=0.1,["projection"]="perspective",["target"]={0,0,0},["up"]={0,1,0},["view"]="3d"},1.6,"linear")
        viewportScene2:look({["eye"]={5.8,4.6,6.2},["far"]=100,["fov"]=0.68,["near"]=0.1,["projection"]="perspective",["target"]={0,0,0},["up"]={0,1,0},["view"]="3d"},1.6,"linear")
        viewportScene2:wait(1.6)
        viewportScene1:viewport(viewportScene2,{["height"]=0.64,["width"]=0.23,["x"]=0.4,["y"]=0.16})
    end
    do
        local viewportScene2 = tmath.scene {["camera"]={["height"]=8,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=30,["height"]=177,["theme"]="pro_white",["width"]=255}
        local object1 = viewportScene2:space {["axis_x"]="#202124",["axis_y"]="#202124",["axis_z"]="#5e7a9b",["color"]="#d8dadd",["id"]="dimension-space",["numbers"]=false,["x"]={-4,4,1},["y"]={-3,3,1},["z"]={-3,3,1}}
        local object2 = object1:polygon {["fill"]="#5e7a9b44",["id"]="dimension-square",["points"]={{0,0},{2,0},{2,2},{0,2}},["stroke"]="#5e7a9b",["width"]=4}
        local object3 = object1:vector {["id"]="dimension-x",["stroke"]="#9b3600",["tip"]=10,["value"]={2.4,0,0},["width"]=5}
        local object4 = object1:vector {["id"]="dimension-y",["stroke"]="#b8915a",["tip"]=10,["value"]={0,2.4,0},["width"]=5}
        local object5 = object1:vector {["id"]="dimension-z",["stroke"]="#5e7a9b",["tip"]=10,["value"]={0,0,2.4},["width"]=5}
        viewportScene2:look({["eye"]={5.5,4.2,6.5},["far"]=100,["fov"]=0.76,["near"]=0.1,["projection"]="perspective",["target"]={0,0,0},["up"]={0,1,0},["view"]="3d"},1.2,"ease_in_out")
        viewportScene2:wait(0.65)
        viewportScene2:look({["eye"]={0,0,10},["height"]=8,["projection"]="orthographic",["target"]={0,0},["up"]={0,1,0},["view"]="2d"},1.2,"ease_in_out")
        viewportScene2:wait(0.75)
        viewportScene2:look({["eye"]={5.5,4.2,6.5},["far"]=100,["fov"]=0.76,["near"]=0.1,["projection"]="perspective",["target"]={0,0,0},["up"]={0,1,0},["view"]="3d"},1.2,"ease_in_out")
        viewportScene2:wait(0.65)
        viewportScene2:look({["eye"]={0,0,10},["height"]=8,["projection"]="orthographic",["target"]={0,0},["up"]={0,1,0},["view"]="2d"},1.2,"ease_in_out")
        viewportScene2:wait(0.75)
        viewportScene2:wait(0.4)
        viewportScene1:viewport(viewportScene2,{["height"]=0.64,["width"]=0.34,["x"]=0.65,["y"]=0.16})
    end
    scene:viewport(viewportScene1,{["height"]=0.09233333333333335,["width"]=0.625,["x"]=0.024999999999999984,["y"]=0.6866666666666668})
end
local object66 = scene:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="advanced-caption-1",["layer"]=40,["point"]={-5.7,-8.620000000000001},["size"]=12.5,["text"]="Follow holds a moving sample at a fixed focus; orbit changes only the eye around retained geometry."}
local object67 = scene:text {["align"]={0,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="advanced-caption-2",["layer"]=40,["point"]={-5.7,-8.860000000000001},["size"]=12.5,["text"]="The third view interpolates one Space between orthographic 2D and perspective 3D."}
local object68 = scene:line {["from"]={2.1,-5.15},["id"]="surface-rule",["stroke"]="#d8dadd",["to"]={5.7,-5.15},["width"]=1.2}
local object69 = scene:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="surface-title",["layer"]=40,["point"]={2.1,-5.430000000000001},["role"]="h2",["size"]=17,["text"]="Sample a real 3D field"}
local object70 = scene:text {["align"]={1,0.5},["fill"]="#9b3600",["font"]="Pretendard",["id"]="surface-number",["layer"]=40,["point"]={5.7,-5.2700000000000005},["size"]=10.5,["text"]="09 / SURFACE"}
do
    local viewportScene1 = tmath.scene {["camera"]={["eye"]={5.8,4.4,6.4},["far"]=100,["fov"]=0.66,["mode"]="fixed",["near"]=0.1,["projection"]="perspective",["target"]={0,0.2,0},["up"]={0,1,0},["view"]="3d"},["fps"]=30,["height"]=267,["theme"]="pro_white",["width"]=360}
    local object1 = viewportScene1:space {["axis_x"]="#d8dadd",["axis_y"]="#d8dadd",["axis_z"]="#d8dadd",["color"]="#00000000",["id"]="surface-space",["x"]={-3,3,6},["y"]={-1,2.2,6},["z"]={-3,3,6}}
    local object2 = viewportScene1:surface {["fill"]="#5e7a9b42",["id"]="gaussian-surface",["mode"]="solid_mesh",["points"]={{-2.7,-0.7498990370646933,-2.7},{-2.475,-0.7497746238658689,-2.7},{-2.25,-0.7495308322554061,-2.7},{-2.025,-0.7490892008163907,-2.7},{-1.8000000000000003,-0.7483511111420806,-2.7},{-1.5750000000000002,-0.7472162232798156,-2.7},{-1.3499999999999999,-0.7456171997415533,-2.7},{-1.125,-0.7435650789466224,-2.7},{-0.9000000000000001,-0.7411893280300503,-2.7},{-0.6750000000000003,-0.7387500884959748,-2.7},{-0.4500000000000002,-0.7366043607106301,-2.7},{-0.2250000000000001,-0.7351251687454086,-2.7},{4.440892098500626e-16,-0.7345966595190934,-2.7},{0.2250000000000001,-0.7351251687454086,-2.7},{0.4500000000000002,-0.7366043607106301,-2.7},{0.6749999999999998,-0.7387500884959748,-2.7},{0.8999999999999999,-0.7411893280300503,-2.7},{1.1250000000000004,-0.7435650789466224,-2.7},{1.3499999999999996,-0.7456171997415533,-2.7},{1.5750000000000002,-0.7472162232798156,-2.7},{1.7999999999999998,-0.7483511111420806,-2.7},{2.0250000000000004,-0.7490892008163907,-2.7},{2.25,-0.7495308322554061,-2.7},{2.4749999999999996,-0.7497746238658689,-2.7},{2.700000000000001,-0.7498990370646933,-2.7},{-2.7,-0.7497746238658689,-2.475},{-2.475,-0.749496900504313,-2.475},{-2.25,-0.748952692765772,-2.475},{-2.025,-0.7479668538919945,-2.475},{-1.8000000000000003,-0.7463192413603976,-2.475},{-1.5750000000000002,-0.7437858696998707,-2.475},{-1.3499999999999999,-0.7402164237210717,-2.475},{-1.125,-0.7356355441128606,-2.475},{-0.9000000000000001,-0.7303322359670646,-2.475},{-0.6750000000000003,-0.7248872043350134,-2.475},{-0.4500000000000002,-0.7200973690188185,-2.475},{-0.2250000000000001,-0.7167954189938243,-2.475},{4.440892098500626e-16,-0.7156156457838072,-2.475},{0.2250000000000001,-0.7167954189938243,-2.475},{0.4500000000000002,-0.7200973690188185,-2.475},{0.6749999999999998,-0.7248872043350133,-2.475},{0.8999999999999999,-0.7303322359670646,-2.475},{1.1250000000000004,-0.7356355441128606,-2.475},{1.3499999999999996,-0.7402164237210717,-2.475},{1.5750000000000002,-0.7437858696998707,-2.475},{1.7999999999999998,-0.7463192413603976,-2.475},{2.0250000000000004,-0.7479668538919945,-2.475},{2.25,-0.748952692765772,-2.475},{2.4749999999999996,-0.749496900504313,-2.475},{2.700000000000001,-0.7497746238658689,-2.475},{-2.7,-0.7495308322554061,-2.25},{-2.475,-0.748952692765772,-2.25},{-2.25,-0.747819810092697,-2.25},{-2.025,-0.7457675794839576,-2.25},{-1.8000000000000003,-0.7423377280562805,-2.25},{-1.5750000000000002,-0.7370639830221407,-2.25},{-1.3499999999999999,-0.7296334317537942,-2.25},{-1.125,-0.7200973690188184,-2.25},{-0.9000000000000001,-0.7090574195971903,-2.25},{-0.6750000000000003,-0.6977224429817609,-2.25},{-0.4500000000000002,-0.6877513950669534,-2.25},{-0.2250000000000001,-0.6808776927915957,-2.25},{4.440892098500626e-16,-0.6784217471422929,-2.25},{0.2250000000000001,-0.6808776927915957,-2.25},{0.4500000000000002,-0.6877513950669534,-2.25},{0.6749999999999998,-0.6977224429817609,-2.25},{0.8999999999999999,-0.7090574195971903,-2.25},{1.1250000000000004,-0.7200973690188185,-2.25},{1.3499999999999996,-0.7296334317537942,-2.25},{1.5750000000000002,-0.7370639830221407,-2.25},{1.7999999999999998,-0.7423377280562805,-2.25},{2.0250000000000004,-0.7457675794839576,-2.25},{2.25,-0.747819810092697,-2.25},{2.4749999999999996,-0.748952692765772,-2.25},{2.700000000000001,-0.7495308322554061,-2.25},{-2.7,-0.7490892008163907,-2.025},{-2.475,-0.7479668538919945,-2.025},{-2.25,-0.7457675794839576,-2.025},{-2.025,-0.7417835674018063,-2.025},{-1.8000000000000003,-0.7351251687454086,-2.025},{-1.5750000000000002,-0.7248872043350134,-2.025},{-1.3499999999999999,-0.7104622143245972,-2.025},{-1.125,-0.6919497776664032,-2.025},{-0.9000000000000001,-0.670517833471242,-2.025},{-0.6750000000000003,-0.6485131505693968,-2.025},{-0.4500000000000002,-0.6291562736204156,-2.025},{-0.2250000000000001,-0.6158122991189553,-2.025},{4.440892098500626e-16,-0.6110445517233839,-2.025},{0.2250000000000001,-0.6158122991189553,-2.025},{0.4500000000000002,-0.6291562736204156,-2.025},{0.6749999999999998,-0.6485131505693968,-2.025},{0.8999999999999999,-0.670517833471242,-2.025},{1.1250000000000004,-0.6919497776664032,-2.025},{1.3499999999999996,-0.7104622143245972,-2.025},{1.5750000000000002,-0.7248872043350134,-2.025},{1.7999999999999998,-0.7351251687454085,-2.025},{2.0250000000000004,-0.7417835674018063,-2.025},{2.25,-0.7457675794839576,-2.025},{2.4749999999999996,-0.7479668538919945,-2.025},{2.700000000000001,-0.7490892008163907,-2.025},{-2.7,-0.7483511111420806,-1.8000000000000003},{-2.475,-0.7463192413603976,-1.8000000000000003},{-2.25,-0.7423377280562805,-1.8000000000000003},{-2.025,-0.7351251687454086,-1.8000000000000003},{-1.8000000000000003,-0.7230709645325623,-1.8000000000000003},{-1.5750000000000002,-0.7045364008791564,-1.8000000000000003},{-1.3499999999999999,-0.6784217471422929,-1.8000000000000003},{-1.125,-0.6449072786535613,-1.8000000000000003},{-0.9000000000000001,-0.6061074041884651,-1.8000000000000003},{-0.6750000000000003,-0.5662706573930619,-1.8000000000000003},{-0.4500000000000002,-0.531227434584262,-1.8000000000000003},{-0.2250000000000001,-0.5070698252321904,-1.8000000000000003},{4.440892098500626e-16,-0.49843841042703113,-1.8000000000000003},{0.2250000000000001,-0.5070698252321904,-1.8000000000000003},{0.4500000000000002,-0.531227434584262,-1.8000000000000003},{0.6749999999999998,-0.5662706573930618,-1.8000000000000003},{0.8999999999999999,-0.606107404188465,-1.8000000000000003},{1.1250000000000004,-0.6449072786535615,-1.8000000000000003},{1.3499999999999996,-0.6784217471422929,-1.8000000000000003},{1.5750000000000002,-0.7045364008791564,-1.8000000000000003},{1.7999999999999998,-0.7230709645325621,-1.8000000000000003},{2.0250000000000004,-0.7351251687454086,-1.8000000000000003},{2.25,-0.7423377280562805,-1.8000000000000003},{2.4749999999999996,-0.7463192413603976,-1.8000000000000003},{2.700000000000001,-0.7483511111420806,-1.8000000000000003},{-2.7,-0.7472162232798156,-1.5750000000000002},{-2.475,-0.7437858696998707,-1.5750000000000002},{-2.25,-0.7370639830221407,-1.5750000000000002},{-2.025,-0.7248872043350134,-1.5750000000000002},{-1.8000000000000003,-0.7045364008791564,-1.5750000000000002},{-1.5750000000000002,-0.6732449729764703,-1.5750000000000002},{-1.3499999999999999,-0.6291562736204156,-1.5750000000000002},{-1.125,-0.5725746570243716,-1.5750000000000002},{-0.9000000000000001,-0.5070698252321904,-1.5750000000000002},{-0.6750000000000003,-0.43981446850859923,-1.5750000000000002},{-0.4500000000000002,-0.38065189524792137,-1.5750000000000002},{-0.2250000000000001,-0.33986722367553734,-1.5750000000000002},{4.440892098500626e-16,-0.3252950276894623,-1.5750000000000002},{0.2250000000000001,-0.33986722367553734,-1.5750000000000002},{0.4500000000000002,-0.38065189524792137,-1.5750000000000002},{0.6749999999999998,-0.4398144685085991,-1.5750000000000002},{0.8999999999999999,-0.5070698252321902,-1.5750000000000002},{1.1250000000000004,-0.5725746570243717,-1.5750000000000002},{1.3499999999999996,-0.6291562736204155,-1.5750000000000002},{1.5750000000000002,-0.6732449729764703,-1.5750000000000002},{1.7999999999999998,-0.7045364008791563,-1.5750000000000002},{2.0250000000000004,-0.7248872043350134,-1.5750000000000002},{2.25,-0.7370639830221407,-1.5750000000000002},{2.4749999999999996,-0.7437858696998707,-1.5750000000000002},{2.700000000000001,-0.7472162232798156,-1.5750000000000002},{-2.7,-0.7456171997415533,-1.3499999999999999},{-2.475,-0.7402164237210717,-1.3499999999999999},{-2.25,-0.7296334317537942,-1.3499999999999999},{-2.025,-0.7104622143245972,-1.3499999999999999},{-1.8000000000000003,-0.6784217471422929,-1.3499999999999999},{-1.5750000000000002,-0.6291562736204156,-1.3499999999999999},{-1.3499999999999999,-0.5597426739120658,-1.3499999999999999},{-1.125,-0.4706601257168731,-1.3499999999999999},{-0.9000000000000001,-0.3675287963876761,-1.3499999999999999},{-0.6750000000000003,-0.2616414266525902,-1.3499999999999999},{-0.4500000000000002,-0.16849539971113958,-1.3499999999999999},{-0.2250000000000001,-0.1042836876826424,-1.3499999999999999},{4.440892098500626e-16,-0.08134110616350465,-1.3499999999999999},{0.2250000000000001,-0.1042836876826424,-1.3499999999999999},{0.4500000000000002,-0.16849539971113958,-1.3499999999999999},{0.6749999999999998,-0.26164142665259005,-1.3499999999999999},{0.8999999999999999,-0.36752879638767594,-1.3499999999999999},{1.1250000000000004,-0.4706601257168734,-1.3499999999999999},{1.3499999999999996,-0.5597426739120657,-1.3499999999999999},{1.5750000000000002,-0.6291562736204156,-1.3499999999999999},{1.7999999999999998,-0.6784217471422928,-1.3499999999999999},{2.0250000000000004,-0.7104622143245973,-1.3499999999999999},{2.25,-0.7296334317537942,-1.3499999999999999},{2.4749999999999996,-0.7402164237210717,-1.3499999999999999},{2.700000000000001,-0.7456171997415533,-1.3499999999999999},{-2.7,-0.7435650789466224,-1.125},{-2.475,-0.7356355441128606,-1.125},{-2.25,-0.7200973690188184,-1.125},{-2.025,-0.6919497776664032,-1.125},{-1.8000000000000003,-0.6449072786535613,-1.125},{-1.5750000000000002,-0.5725746570243716,-1.125},{-1.3499999999999999,-0.4706601257168731,-1.125},{-1.125,-0.3398672236755371,-1.125},{-0.9000000000000001,-0.18844760077936185,-1.125},{-0.6750000000000003,-0.032981500429044464,-1.125},{-0.4500000000000002,0.10377748799367625,-1.125},{-0.2250000000000001,0.19805449658179508,-1.125},{4.440892098500626e-16,0.23173928533113497,-1.125},{0.2250000000000001,0.19805449658179508,-1.125},{0.4500000000000002,0.10377748799367625,-1.125},{0.6749999999999998,-0.03298150042904413,-1.125},{0.8999999999999999,-0.1884476007793615,-1.125},{1.1250000000000004,-0.33986722367553734,-1.125},{1.3499999999999996,-0.470660125716873,-1.125},{1.5750000000000002,-0.5725746570243716,-1.125},{1.7999999999999998,-0.6449072786535612,-1.125},{2.0250000000000004,-0.6919497776664032,-1.125},{2.25,-0.7200973690188184,-1.125},{2.4749999999999996,-0.7356355441128606,-1.125},{2.700000000000001,-0.7435650789466224,-1.125},{-2.7,-0.7411893280300503,-0.9000000000000001},{-2.475,-0.7303322359670646,-0.9000000000000001},{-2.25,-0.7090574195971903,-0.9000000000000001},{-2.025,-0.670517833471242,-0.9000000000000001},{-1.8000000000000003,-0.6061074041884651,-0.9000000000000001},{-1.5750000000000002,-0.5070698252321904,-0.9000000000000001},{-1.3499999999999999,-0.3675287963876761,-0.9000000000000001},{-1.125,-0.18844760077936185,-0.9000000000000001},{-0.9000000000000001,0.018875630707903768,-0.9000000000000001},{-0.6750000000000003,0.23173928533113453,-0.9000000000000001},{-0.4500000000000002,0.41898922607474076,-0.9000000000000001},{-0.2250000000000001,0.5480729848478263,-0.9000000000000001},{4.440892098500626e-16,0.5941940827736054,-0.9000000000000001},{0.2250000000000001,0.5480729848478263,-0.9000000000000001},{0.4500000000000002,0.41898922607474076,-0.9000000000000001},{0.6749999999999998,0.23173928533113497,-0.9000000000000001},{0.8999999999999999,0.01887563070790399,-0.9000000000000001},{1.1250000000000004,-0.1884476007793623,-0.9000000000000001},{1.3499999999999996,-0.36752879638767594,-0.9000000000000001},{1.5750000000000002,-0.5070698252321904,-0.9000000000000001},{1.7999999999999998,-0.606107404188465,-0.9000000000000001},{2.0250000000000004,-0.6705178334712422,-0.9000000000000001},{2.25,-0.7090574195971903,-0.9000000000000001},{2.4749999999999996,-0.7303322359670646,-0.9000000000000001},{2.700000000000001,-0.7411893280300503,-0.9000000000000001},{-2.7,-0.7387500884959748,-0.6750000000000003},{-2.475,-0.7248872043350134,-0.6750000000000003},{-2.25,-0.6977224429817609,-0.6750000000000003},{-2.025,-0.6485131505693968,-0.6750000000000003},{-1.8000000000000003,-0.5662706573930619,-0.6750000000000003},{-1.5750000000000002,-0.43981446850859923,-0.6750000000000003},{-1.3499999999999999,-0.2616414266525902,-0.6750000000000003},{-1.125,-0.032981500429044464,-0.6750000000000003},{-0.9000000000000001,0.23173928533113453,-0.6750000000000003},{-0.6750000000000003,0.5035343635161194,-0.6750000000000003},{-0.4500000000000002,0.7426245566006267,-0.6750000000000003},{-0.2250000000000001,0.9074452272324536,-0.6750000000000003},{4.440892098500626e-16,0.9663349772881984,-0.6750000000000003},{0.2250000000000001,0.9074452272324536,-0.6750000000000003},{0.4500000000000002,0.7426245566006267,-0.6750000000000003},{0.6749999999999998,0.5035343635161196,-0.6750000000000003},{0.8999999999999999,0.23173928533113486,-0.6750000000000003},{1.1250000000000004,-0.03298150042904502,-0.6750000000000003},{1.3499999999999996,-0.26164142665259005,-0.6750000000000003},{1.5750000000000002,-0.43981446850859923,-0.6750000000000003},{1.7999999999999998,-0.5662706573930617,-0.6750000000000003},{2.0250000000000004,-0.6485131505693971,-0.6750000000000003},{2.25,-0.6977224429817609,-0.6750000000000003},{2.4749999999999996,-0.7248872043350133,-0.6750000000000003},{2.700000000000001,-0.7387500884959749,-0.6750000000000003},{-2.7,-0.7366043607106301,-0.4500000000000002},{-2.475,-0.7200973690188185,-0.4500000000000002},{-2.25,-0.6877513950669534,-0.4500000000000002},{-2.025,-0.6291562736204156,-0.4500000000000002},{-1.8000000000000003,-0.531227434584262,-0.4500000000000002},{-1.5750000000000002,-0.38065189524792137,-0.4500000000000002},{-1.3499999999999999,-0.16849539971113958,-0.4500000000000002},{-1.125,0.10377748799367625,-0.4500000000000002},{-0.9000000000000001,0.41898922607474076,-0.4500000000000002},{-0.6750000000000003,0.7426245566006267,-0.4500000000000002},{-0.4500000000000002,1.0273171057855635,-0.4500000000000002},{-0.2250000000000001,1.2235744941593327,-0.4500000000000002},{4.440892098500626e-16,1.2936964546125909,-0.4500000000000002},{0.2250000000000001,1.2235744941593327,-0.4500000000000002},{0.4500000000000002,1.0273171057855635,-0.4500000000000002},{0.6749999999999998,0.7426245566006271,-0.4500000000000002},{0.8999999999999999,0.418989226074741,-0.4500000000000002},{1.1250000000000004,0.1037774879936757,-0.4500000000000002},{1.3499999999999996,-0.16849539971113925,-0.4500000000000002},{1.5750000000000002,-0.38065189524792137,-0.4500000000000002},{1.7999999999999998,-0.5312274345842618,-0.4500000000000002},{2.0250000000000004,-0.6291562736204157,-0.4500000000000002},{2.25,-0.6877513950669534,-0.4500000000000002},{2.4749999999999996,-0.7200973690188184,-0.4500000000000002},{2.700000000000001,-0.7366043607106301,-0.4500000000000002},{-2.7,-0.7351251687454086,-0.2250000000000001},{-2.475,-0.7167954189938243,-0.2250000000000001},{-2.25,-0.6808776927915957,-0.2250000000000001},{-2.025,-0.6158122991189553,-0.2250000000000001},{-1.8000000000000003,-0.5070698252321904,-0.2250000000000001},{-1.5750000000000002,-0.33986722367553734,-0.2250000000000001},{-1.3499999999999999,-0.1042836876826424,-0.2250000000000001},{-1.125,0.19805449658179508,-0.2250000000000001},{-0.9000000000000001,0.5480729848478263,-0.2250000000000001},{-0.6750000000000003,0.9074452272324536,-0.2250000000000001},{-0.4500000000000002,1.2235744941593327,-0.2250000000000001},{-0.2250000000000001,1.4415032896027307,-0.2250000000000001},{4.440892098500626e-16,1.5193683549759869,-0.2250000000000001},{0.2250000000000001,1.4415032896027307,-0.2250000000000001},{0.4500000000000002,1.2235744941593327,-0.2250000000000001},{0.6749999999999998,0.9074452272324545,-0.2250000000000001},{0.8999999999999999,0.5480729848478267,-0.2250000000000001},{1.1250000000000004,0.1980544965817943,-0.2250000000000001},{1.3499999999999996,-0.10428368768264218,-0.2250000000000001},{1.5750000000000002,-0.33986722367553734,-0.2250000000000001},{1.7999999999999998,-0.50706982523219,-0.2250000000000001},{2.0250000000000004,-0.6158122991189554,-0.2250000000000001},{2.25,-0.6808776927915957,-0.2250000000000001},{2.4749999999999996,-0.7167954189938242,-0.2250000000000001},{2.700000000000001,-0.7351251687454086,-0.2250000000000001},{-2.7,-0.7345966595190934,4.440892098500626e-16},{-2.475,-0.7156156457838072,4.440892098500626e-16},{-2.25,-0.6784217471422929,4.440892098500626e-16},{-2.025,-0.6110445517233839,4.440892098500626e-16},{-1.8000000000000003,-0.49843841042703113,4.440892098500626e-16},{-1.5750000000000002,-0.3252950276894623,4.440892098500626e-16},{-1.3499999999999999,-0.08134110616350465,4.440892098500626e-16},{-1.125,0.23173928533113497,4.440892098500626e-16},{-0.9000000000000001,0.5941940827736054,4.440892098500626e-16},{-0.6750000000000003,0.9663349772881984,4.440892098500626e-16},{-0.4500000000000002,1.2936964546125909,4.440892098500626e-16},{-0.2250000000000001,1.5193683549759869,4.440892098500626e-16},{4.440892098500626e-16,1.6,4.440892098500626e-16},{0.2250000000000001,1.5193683549759869,4.440892098500626e-16},{0.4500000000000002,1.2936964546125909,4.440892098500626e-16},{0.6749999999999998,0.9663349772881991,4.440892098500626e-16},{0.8999999999999999,0.5941940827736059,4.440892098500626e-16},{1.1250000000000004,0.2317392853311342,4.440892098500626e-16},{1.3499999999999996,-0.08134110616350443,4.440892098500626e-16},{1.5750000000000002,-0.3252950276894623,4.440892098500626e-16},{1.7999999999999998,-0.49843841042703085,4.440892098500626e-16},{2.0250000000000004,-0.611044551723384,4.440892098500626e-16},{2.25,-0.6784217471422929,4.440892098500626e-16},{2.4749999999999996,-0.7156156457838072,4.440892098500626e-16},{2.700000000000001,-0.7345966595190935,4.440892098500626e-16},{-2.7,-0.7351251687454086,0.2250000000000001},{-2.475,-0.7167954189938243,0.2250000000000001},{-2.25,-0.6808776927915957,0.2250000000000001},{-2.025,-0.6158122991189553,0.2250000000000001},{-1.8000000000000003,-0.5070698252321904,0.2250000000000001},{-1.5750000000000002,-0.33986722367553734,0.2250000000000001},{-1.3499999999999999,-0.1042836876826424,0.2250000000000001},{-1.125,0.19805449658179508,0.2250000000000001},{-0.9000000000000001,0.5480729848478263,0.2250000000000001},{-0.6750000000000003,0.9074452272324536,0.2250000000000001},{-0.4500000000000002,1.2235744941593327,0.2250000000000001},{-0.2250000000000001,1.4415032896027307,0.2250000000000001},{4.440892098500626e-16,1.5193683549759869,0.2250000000000001},{0.2250000000000001,1.4415032896027307,0.2250000000000001},{0.4500000000000002,1.2235744941593327,0.2250000000000001},{0.6749999999999998,0.9074452272324545,0.2250000000000001},{0.8999999999999999,0.5480729848478267,0.2250000000000001},{1.1250000000000004,0.1980544965817943,0.2250000000000001},{1.3499999999999996,-0.10428368768264218,0.2250000000000001},{1.5750000000000002,-0.33986722367553734,0.2250000000000001},{1.7999999999999998,-0.50706982523219,0.2250000000000001},{2.0250000000000004,-0.6158122991189554,0.2250000000000001},{2.25,-0.6808776927915957,0.2250000000000001},{2.4749999999999996,-0.7167954189938242,0.2250000000000001},{2.700000000000001,-0.7351251687454086,0.2250000000000001},{-2.7,-0.7366043607106301,0.4500000000000002},{-2.475,-0.7200973690188185,0.4500000000000002},{-2.25,-0.6877513950669534,0.4500000000000002},{-2.025,-0.6291562736204156,0.4500000000000002},{-1.8000000000000003,-0.531227434584262,0.4500000000000002},{-1.5750000000000002,-0.38065189524792137,0.4500000000000002},{-1.3499999999999999,-0.16849539971113958,0.4500000000000002},{-1.125,0.10377748799367625,0.4500000000000002},{-0.9000000000000001,0.41898922607474076,0.4500000000000002},{-0.6750000000000003,0.7426245566006267,0.4500000000000002},{-0.4500000000000002,1.0273171057855635,0.4500000000000002},{-0.2250000000000001,1.2235744941593327,0.4500000000000002},{4.440892098500626e-16,1.2936964546125909,0.4500000000000002},{0.2250000000000001,1.2235744941593327,0.4500000000000002},{0.4500000000000002,1.0273171057855635,0.4500000000000002},{0.6749999999999998,0.7426245566006271,0.4500000000000002},{0.8999999999999999,0.418989226074741,0.4500000000000002},{1.1250000000000004,0.1037774879936757,0.4500000000000002},{1.3499999999999996,-0.16849539971113925,0.4500000000000002},{1.5750000000000002,-0.38065189524792137,0.4500000000000002},{1.7999999999999998,-0.5312274345842618,0.4500000000000002},{2.0250000000000004,-0.6291562736204157,0.4500000000000002},{2.25,-0.6877513950669534,0.4500000000000002},{2.4749999999999996,-0.7200973690188184,0.4500000000000002},{2.700000000000001,-0.7366043607106301,0.4500000000000002},{-2.7,-0.7387500884959748,0.6749999999999998},{-2.475,-0.7248872043350133,0.6749999999999998},{-2.25,-0.6977224429817609,0.6749999999999998},{-2.025,-0.6485131505693968,0.6749999999999998},{-1.8000000000000003,-0.5662706573930618,0.6749999999999998},{-1.5750000000000002,-0.4398144685085991,0.6749999999999998},{-1.3499999999999999,-0.26164142665259005,0.6749999999999998},{-1.125,-0.03298150042904413,0.6749999999999998},{-0.9000000000000001,0.23173928533113497,0.6749999999999998},{-0.6750000000000003,0.5035343635161196,0.6749999999999998},{-0.4500000000000002,0.7426245566006271,0.6749999999999998},{-0.2250000000000001,0.9074452272324545,0.6749999999999998},{4.440892098500626e-16,0.9663349772881991,0.6749999999999998},{0.2250000000000001,0.9074452272324545,0.6749999999999998},{0.4500000000000002,0.7426245566006271,0.6749999999999998},{0.6749999999999998,0.5035343635161202,0.6749999999999998},{0.8999999999999999,0.23173928533113541,0.6749999999999998},{1.1250000000000004,-0.032981500429044575,0.6749999999999998},{1.3499999999999996,-0.26164142665258994,0.6749999999999998},{1.5750000000000002,-0.4398144685085991,0.6749999999999998},{1.7999999999999998,-0.5662706573930616,0.6749999999999998},{2.0250000000000004,-0.648513150569397,0.6749999999999998},{2.25,-0.6977224429817609,0.6749999999999998},{2.4749999999999996,-0.7248872043350133,0.6749999999999998},{2.700000000000001,-0.7387500884959748,0.6749999999999998},{-2.7,-0.7411893280300503,0.8999999999999999},{-2.475,-0.7303322359670646,0.8999999999999999},{-2.25,-0.7090574195971903,0.8999999999999999},{-2.025,-0.670517833471242,0.8999999999999999},{-1.8000000000000003,-0.606107404188465,0.8999999999999999},{-1.5750000000000002,-0.5070698252321902,0.8999999999999999},{-1.3499999999999999,-0.36752879638767594,0.8999999999999999},{-1.125,-0.1884476007793615,0.8999999999999999},{-0.9000000000000001,0.01887563070790399,0.8999999999999999},{-0.6750000000000003,0.23173928533113486,0.8999999999999999},{-0.4500000000000002,0.418989226074741,0.8999999999999999},{-0.2250000000000001,0.5480729848478267,0.8999999999999999},{4.440892098500626e-16,0.5941940827736059,0.8999999999999999},{0.2250000000000001,0.5480729848478267,0.8999999999999999},{0.4500000000000002,0.418989226074741,0.8999999999999999},{0.6749999999999998,0.23173928533113541,0.8999999999999999},{0.8999999999999999,0.018875630707904323,0.8999999999999999},{1.1250000000000004,-0.18844760077936196,0.8999999999999999},{1.3499999999999996,-0.3675287963876758,0.8999999999999999},{1.5750000000000002,-0.5070698252321902,0.8999999999999999},{1.7999999999999998,-0.6061074041884649,0.8999999999999999},{2.0250000000000004,-0.6705178334712422,0.8999999999999999},{2.25,-0.7090574195971903,0.8999999999999999},{2.4749999999999996,-0.7303322359670646,0.8999999999999999},{2.700000000000001,-0.7411893280300503,0.8999999999999999},{-2.7,-0.7435650789466224,1.1250000000000004},{-2.475,-0.7356355441128606,1.1250000000000004},{-2.25,-0.7200973690188185,1.1250000000000004},{-2.025,-0.6919497776664032,1.1250000000000004},{-1.8000000000000003,-0.6449072786535615,1.1250000000000004},{-1.5750000000000002,-0.5725746570243717,1.1250000000000004},{-1.3499999999999999,-0.4706601257168734,1.1250000000000004},{-1.125,-0.33986722367553734,1.1250000000000004},{-0.9000000000000001,-0.1884476007793623,1.1250000000000004},{-0.6750000000000003,-0.03298150042904502,1.1250000000000004},{-0.4500000000000002,0.1037774879936757,1.1250000000000004},{-0.2250000000000001,0.1980544965817943,1.1250000000000004},{4.440892098500626e-16,0.2317392853311342,1.1250000000000004},{0.2250000000000001,0.1980544965817943,1.1250000000000004},{0.4500000000000002,0.1037774879936757,1.1250000000000004},{0.6749999999999998,-0.032981500429044575,1.1250000000000004},{0.8999999999999999,-0.18844760077936196,1.1250000000000004},{1.1250000000000004,-0.3398672236755378,1.1250000000000004},{1.3499999999999996,-0.4706601257168732,1.1250000000000004},{1.5750000000000002,-0.5725746570243717,1.1250000000000004},{1.7999999999999998,-0.6449072786535613,1.1250000000000004},{2.0250000000000004,-0.6919497776664032,1.1250000000000004},{2.25,-0.7200973690188185,1.1250000000000004},{2.4749999999999996,-0.7356355441128606,1.1250000000000004},{2.700000000000001,-0.7435650789466224,1.1250000000000004},{-2.7,-0.7456171997415533,1.3499999999999996},{-2.475,-0.7402164237210717,1.3499999999999996},{-2.25,-0.7296334317537942,1.3499999999999996},{-2.025,-0.7104622143245972,1.3499999999999996},{-1.8000000000000003,-0.6784217471422929,1.3499999999999996},{-1.5750000000000002,-0.6291562736204155,1.3499999999999996},{-1.3499999999999999,-0.5597426739120657,1.3499999999999996},{-1.125,-0.470660125716873,1.3499999999999996},{-0.9000000000000001,-0.36752879638767594,1.3499999999999996},{-0.6750000000000003,-0.26164142665259005,1.3499999999999996},{-0.4500000000000002,-0.16849539971113925,1.3499999999999996},{-0.2250000000000001,-0.10428368768264218,1.3499999999999996},{4.440892098500626e-16,-0.08134110616350443,1.3499999999999996},{0.2250000000000001,-0.10428368768264218,1.3499999999999996},{0.4500000000000002,-0.16849539971113925,1.3499999999999996},{0.6749999999999998,-0.26164142665258994,1.3499999999999996},{0.8999999999999999,-0.3675287963876758,1.3499999999999996},{1.1250000000000004,-0.4706601257168732,1.3499999999999996},{1.3499999999999996,-0.5597426739120656,1.3499999999999996},{1.5750000000000002,-0.6291562736204155,1.3499999999999996},{1.7999999999999998,-0.6784217471422928,1.3499999999999996},{2.0250000000000004,-0.7104622143245973,1.3499999999999996},{2.25,-0.7296334317537942,1.3499999999999996},{2.4749999999999996,-0.7402164237210715,1.3499999999999996},{2.700000000000001,-0.7456171997415533,1.3499999999999996},{-2.7,-0.7472162232798156,1.5750000000000002},{-2.475,-0.7437858696998707,1.5750000000000002},{-2.25,-0.7370639830221407,1.5750000000000002},{-2.025,-0.7248872043350134,1.5750000000000002},{-1.8000000000000003,-0.7045364008791564,1.5750000000000002},{-1.5750000000000002,-0.6732449729764703,1.5750000000000002},{-1.3499999999999999,-0.6291562736204156,1.5750000000000002},{-1.125,-0.5725746570243716,1.5750000000000002},{-0.9000000000000001,-0.5070698252321904,1.5750000000000002},{-0.6750000000000003,-0.43981446850859923,1.5750000000000002},{-0.4500000000000002,-0.38065189524792137,1.5750000000000002},{-0.2250000000000001,-0.33986722367553734,1.5750000000000002},{4.440892098500626e-16,-0.3252950276894623,1.5750000000000002},{0.2250000000000001,-0.33986722367553734,1.5750000000000002},{0.4500000000000002,-0.38065189524792137,1.5750000000000002},{0.6749999999999998,-0.4398144685085991,1.5750000000000002},{0.8999999999999999,-0.5070698252321902,1.5750000000000002},{1.1250000000000004,-0.5725746570243717,1.5750000000000002},{1.3499999999999996,-0.6291562736204155,1.5750000000000002},{1.5750000000000002,-0.6732449729764703,1.5750000000000002},{1.7999999999999998,-0.7045364008791563,1.5750000000000002},{2.0250000000000004,-0.7248872043350134,1.5750000000000002},{2.25,-0.7370639830221407,1.5750000000000002},{2.4749999999999996,-0.7437858696998707,1.5750000000000002},{2.700000000000001,-0.7472162232798156,1.5750000000000002},{-2.7,-0.7483511111420806,1.7999999999999998},{-2.475,-0.7463192413603976,1.7999999999999998},{-2.25,-0.7423377280562805,1.7999999999999998},{-2.025,-0.7351251687454085,1.7999999999999998},{-1.8000000000000003,-0.7230709645325621,1.7999999999999998},{-1.5750000000000002,-0.7045364008791563,1.7999999999999998},{-1.3499999999999999,-0.6784217471422928,1.7999999999999998},{-1.125,-0.6449072786535612,1.7999999999999998},{-0.9000000000000001,-0.606107404188465,1.7999999999999998},{-0.6750000000000003,-0.5662706573930617,1.7999999999999998},{-0.4500000000000002,-0.5312274345842618,1.7999999999999998},{-0.2250000000000001,-0.50706982523219,1.7999999999999998},{4.440892098500626e-16,-0.49843841042703085,1.7999999999999998},{0.2250000000000001,-0.50706982523219,1.7999999999999998},{0.4500000000000002,-0.5312274345842618,1.7999999999999998},{0.6749999999999998,-0.5662706573930616,1.7999999999999998},{0.8999999999999999,-0.6061074041884649,1.7999999999999998},{1.1250000000000004,-0.6449072786535613,1.7999999999999998},{1.3499999999999996,-0.6784217471422928,1.7999999999999998},{1.5750000000000002,-0.7045364008791563,1.7999999999999998},{1.7999999999999998,-0.7230709645325621,1.7999999999999998},{2.0250000000000004,-0.7351251687454086,1.7999999999999998},{2.25,-0.7423377280562805,1.7999999999999998},{2.4749999999999996,-0.7463192413603976,1.7999999999999998},{2.700000000000001,-0.7483511111420806,1.7999999999999998},{-2.7,-0.7490892008163907,2.0250000000000004},{-2.475,-0.7479668538919945,2.0250000000000004},{-2.25,-0.7457675794839576,2.0250000000000004},{-2.025,-0.7417835674018063,2.0250000000000004},{-1.8000000000000003,-0.7351251687454086,2.0250000000000004},{-1.5750000000000002,-0.7248872043350134,2.0250000000000004},{-1.3499999999999999,-0.7104622143245973,2.0250000000000004},{-1.125,-0.6919497776664032,2.0250000000000004},{-0.9000000000000001,-0.6705178334712422,2.0250000000000004},{-0.6750000000000003,-0.6485131505693971,2.0250000000000004},{-0.4500000000000002,-0.6291562736204157,2.0250000000000004},{-0.2250000000000001,-0.6158122991189554,2.0250000000000004},{4.440892098500626e-16,-0.611044551723384,2.0250000000000004},{0.2250000000000001,-0.6158122991189554,2.0250000000000004},{0.4500000000000002,-0.6291562736204157,2.0250000000000004},{0.6749999999999998,-0.648513150569397,2.0250000000000004},{0.8999999999999999,-0.6705178334712422,2.0250000000000004},{1.1250000000000004,-0.6919497776664032,2.0250000000000004},{1.3499999999999996,-0.7104622143245973,2.0250000000000004},{1.5750000000000002,-0.7248872043350134,2.0250000000000004},{1.7999999999999998,-0.7351251687454086,2.0250000000000004},{2.0250000000000004,-0.7417835674018063,2.0250000000000004},{2.25,-0.7457675794839576,2.0250000000000004},{2.4749999999999996,-0.7479668538919945,2.0250000000000004},{2.700000000000001,-0.7490892008163907,2.0250000000000004},{-2.7,-0.7495308322554061,2.25},{-2.475,-0.748952692765772,2.25},{-2.25,-0.747819810092697,2.25},{-2.025,-0.7457675794839576,2.25},{-1.8000000000000003,-0.7423377280562805,2.25},{-1.5750000000000002,-0.7370639830221407,2.25},{-1.3499999999999999,-0.7296334317537942,2.25},{-1.125,-0.7200973690188184,2.25},{-0.9000000000000001,-0.7090574195971903,2.25},{-0.6750000000000003,-0.6977224429817609,2.25},{-0.4500000000000002,-0.6877513950669534,2.25},{-0.2250000000000001,-0.6808776927915957,2.25},{4.440892098500626e-16,-0.6784217471422929,2.25},{0.2250000000000001,-0.6808776927915957,2.25},{0.4500000000000002,-0.6877513950669534,2.25},{0.6749999999999998,-0.6977224429817609,2.25},{0.8999999999999999,-0.7090574195971903,2.25},{1.1250000000000004,-0.7200973690188185,2.25},{1.3499999999999996,-0.7296334317537942,2.25},{1.5750000000000002,-0.7370639830221407,2.25},{1.7999999999999998,-0.7423377280562805,2.25},{2.0250000000000004,-0.7457675794839576,2.25},{2.25,-0.747819810092697,2.25},{2.4749999999999996,-0.748952692765772,2.25},{2.700000000000001,-0.7495308322554061,2.25},{-2.7,-0.7497746238658689,2.4749999999999996},{-2.475,-0.749496900504313,2.4749999999999996},{-2.25,-0.748952692765772,2.4749999999999996},{-2.025,-0.7479668538919945,2.4749999999999996},{-1.8000000000000003,-0.7463192413603976,2.4749999999999996},{-1.5750000000000002,-0.7437858696998707,2.4749999999999996},{-1.3499999999999999,-0.7402164237210717,2.4749999999999996},{-1.125,-0.7356355441128606,2.4749999999999996},{-0.9000000000000001,-0.7303322359670646,2.4749999999999996},{-0.6750000000000003,-0.7248872043350133,2.4749999999999996},{-0.4500000000000002,-0.7200973690188184,2.4749999999999996},{-0.2250000000000001,-0.7167954189938242,2.4749999999999996},{4.440892098500626e-16,-0.7156156457838072,2.4749999999999996},{0.2250000000000001,-0.7167954189938242,2.4749999999999996},{0.4500000000000002,-0.7200973690188184,2.4749999999999996},{0.6749999999999998,-0.7248872043350133,2.4749999999999996},{0.8999999999999999,-0.7303322359670646,2.4749999999999996},{1.1250000000000004,-0.7356355441128606,2.4749999999999996},{1.3499999999999996,-0.7402164237210715,2.4749999999999996},{1.5750000000000002,-0.7437858696998707,2.4749999999999996},{1.7999999999999998,-0.7463192413603976,2.4749999999999996},{2.0250000000000004,-0.7479668538919945,2.4749999999999996},{2.25,-0.748952692765772,2.4749999999999996},{2.4749999999999996,-0.749496900504313,2.4749999999999996},{2.700000000000001,-0.7497746238658689,2.4749999999999996},{-2.7,-0.7498990370646933,2.700000000000001},{-2.475,-0.7497746238658689,2.700000000000001},{-2.25,-0.7495308322554061,2.700000000000001},{-2.025,-0.7490892008163907,2.700000000000001},{-1.8000000000000003,-0.7483511111420806,2.700000000000001},{-1.5750000000000002,-0.7472162232798156,2.700000000000001},{-1.3499999999999999,-0.7456171997415533,2.700000000000001},{-1.125,-0.7435650789466224,2.700000000000001},{-0.9000000000000001,-0.7411893280300503,2.700000000000001},{-0.6750000000000003,-0.7387500884959749,2.700000000000001},{-0.4500000000000002,-0.7366043607106301,2.700000000000001},{-0.2250000000000001,-0.7351251687454086,2.700000000000001},{4.440892098500626e-16,-0.7345966595190935,2.700000000000001},{0.2250000000000001,-0.7351251687454086,2.700000000000001},{0.4500000000000002,-0.7366043607106301,2.700000000000001},{0.6749999999999998,-0.7387500884959748,2.700000000000001},{0.8999999999999999,-0.7411893280300503,2.700000000000001},{1.1250000000000004,-0.7435650789466224,2.700000000000001},{1.3499999999999996,-0.7456171997415533,2.700000000000001},{1.5750000000000002,-0.7472162232798156,2.700000000000001},{1.7999999999999998,-0.7483511111420806,2.700000000000001},{2.0250000000000004,-0.7490892008163907,2.700000000000001},{2.25,-0.7495308322554061,2.700000000000001},{2.4749999999999996,-0.7497746238658689,2.700000000000001},{2.700000000000001,-0.7498990370646933,2.700000000000001}},["shading"]=false,["size"]={25,25},["stroke"]="#5e7a9bb8",["width"]=0.72}
    local object3 = object1:point {["fill"]="#9b3600",["id"]="surface-peak",["point"]={0,1.6,0},["radius"]=5,["stroke"]="#ffffff",["width"]=2}
    viewportScene1:look({["eye"]={-5.4,4.8,6},["far"]=100,["fov"]=0.66,["near"]=0.1,["projection"]="perspective",["target"]={0,0.2,0},["up"]={0,1,0},["view"]="3d"},1.8,"ease_in_out")
    viewportScene1:look({["eye"]={-5.8,3.4,-5.8},["far"]=100,["fov"]=0.66,["near"]=0.1,["projection"]="perspective",["target"]={0,0.2,0},["up"]={0,1,0},["view"]="3d"},1.8,"ease_in_out")
    viewportScene1:look({["eye"]={-5.4,4.8,6},["far"]=100,["fov"]=0.66,["near"]=0.1,["projection"]="perspective",["target"]={0,0.2,0},["up"]={0,1,0},["view"]="3d"},1.8,"ease_in_out")
    viewportScene1:look({["eye"]={5.8,4.4,6.4},["far"]=100,["fov"]=0.66,["near"]=0.1,["projection"]="perspective",["target"]={0,0.2,0},["up"]={0,1,0},["view"]="3d"},1.8,"ease_in_out")
    viewportScene1:wait(0.8)
    scene:viewport(viewportScene1,{["height"]=0.08900000000000002,["width"]=0.3,["x"]=0.6749999999999999,["y"]=0.6866666666666668})
end
local object71 = scene:text {["align"]={0,0.5},["fill"]="#9b3600",["font"]="Pretendard",["id"]="surface-api-1",["layer"]=40,["point"]={2.1,-8.430000000000001},["role"]="code",["size"]=10.5,["text"]="scene.surface({ points, size: [cols, rows] })"}
local object72 = scene:text {["align"]={0,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="surface-api-2",["layer"]=40,["point"]={2.1,-8.65},["role"]="code",["size"]=10.5,["text"]="mode: \\"mesh\\" | \\"solid_mesh\\""}
local object73 = scene:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="surface-caption-1",["layer"]=40,["point"]={2.1,-8.89},["size"]=9.5,["text"]="Surface consumes a row-major columns × rows point field."}
local object74 = scene:text {["align"]={0,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="surface-caption-2",["layer"]=40,["point"]={2.1,-9.13},["size"]=9.5,["text"]="Orbit the camera to inspect the retained geometry."}
local object75 = scene:line {["from"]={-5.7,-9.3},["id"]="demo-rule",["stroke"]="#d8dadd",["to"]={5.7,-9.3},["width"]=1.2}
local object76 = scene:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="demo-title",["layer"]=40,["point"]={-5.7,-9.58},["role"]="h2",["size"]=24,["text"]="Compose complete technical scenes"}
local object77 = scene:text {["align"]={1,0.5},["fill"]="#9b3600",["font"]="Pretendard",["id"]="demo-number",["layer"]=40,["point"]={5.7,-9.42},["size"]=10.5,["text"]="10 / DEMO"}
do
    local viewportScene1 = tmath.scene {["camera"]={["height"]=4,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=30,["height"]=287,["theme"]="pro_white",["width"]=1140}
    local object1 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#9b3600",["font"]="Pretendard",["id"]="demo-ray-label",["layer"]=40,["point"]={-3.177700348432056,1.66},["size"]=10.5,["text"]="RAY TRACING"}
    local object2 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="demo-diagram-label",["layer"]=40,["point"]={4.925435540069686,1.66},["size"]=10.5,["text"]="ARCHITECTURE DIAGRAM"}
    local object3 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="demo-ray-api",["layer"]=40,["point"]={-3.177700348432056,-1.66},["role"]="code",["size"]=8.8,["text"]="scene.arrow({ from, to }) · scene.play([{ target: ray, opacity }], dt)"}
    local object4 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="demo-diagram-api",["layer"]=40,["point"]={4.925435540069686,-1.66},["role"]="code",["size"]=8.8,["text"]="scene.group({ id }) · group.rectangle(...) · scene.path({ commands, dash })"}
    do
        local viewportScene2 = tmath.scene {["camera"]={["eye"]={9,6,11},["far"]=100,["fov"]=0.66,["mode"]="fixed",["near"]=0.1,["projection"]="perspective",["target"]={-0.6,0,0},["up"]={0,1,0},["view"]="3d"},["fps"]=30,["height"]=198,["theme"]="pro_white",["width"]=228}
        local object1 = viewportScene2:group {["id"]="ray-image-plane",["matrix"]={0,0,1,-3,0,1,0,0,-1,0,0,0,0,0,0,1}}
        local object2 = object1:rectangle {["center"]={-0.96,0.48},["corner"]=0.035,["fill"]="#5e7a9baa",["id"]="ray-pixel-0-0",["size"]={0.42,0.42},["stroke"]="#d8dadd",["width"]=1.6}
        local object3 = object1:rectangle {["center"]={-0.48,0.48},["corner"]=0.035,["fill"]="#5e7a9baa",["id"]="ray-pixel-0-1",["size"]={0.42,0.42},["stroke"]="#d8dadd",["width"]=1.6}
        local object4 = object1:rectangle {["center"]={0,0.48},["corner"]=0.035,["fill"]="#ffffff",["id"]="ray-pixel-0-2",["size"]={0.42,0.42},["stroke"]="#d8dadd",["width"]=1.6}
        local object5 = object1:rectangle {["center"]={0.48,0.48},["corner"]=0.035,["fill"]="#ffffff",["id"]="ray-pixel-0-3",["size"]={0.42,0.42},["stroke"]="#d8dadd",["width"]=1.6}
        local object6 = object1:rectangle {["center"]={0.96,0.48},["corner"]=0.035,["fill"]="#ffffff",["id"]="ray-pixel-0-4",["size"]={0.42,0.42},["stroke"]="#d8dadd",["width"]=1.6}
        local object7 = object1:rectangle {["center"]={-0.96,0},["corner"]=0.035,["fill"]="#5e7a9baa",["id"]="ray-pixel-1-0",["size"]={0.42,0.42},["stroke"]="#d8dadd",["width"]=1.6}
        local object8 = object1:rectangle {["center"]={-0.48,0},["corner"]=0.035,["fill"]="#5e7a9baa",["id"]="ray-pixel-1-1",["size"]={0.42,0.42},["stroke"]="#d8dadd",["width"]=1.6}
        local object9 = object1:rectangle {["center"]={0,0},["corner"]=0.035,["fill"]="#ffffff",["id"]="ray-pixel-1-2",["size"]={0.42,0.42},["stroke"]="#d8dadd",["width"]=1.6}
        local object10 = object1:rectangle {["center"]={0.48,0},["corner"]=0.035,["fill"]="#b8915aaa",["id"]="ray-pixel-1-3",["size"]={0.42,0.42},["stroke"]="#d8dadd",["width"]=1.6}
        local object11 = object1:rectangle {["center"]={0.96,0},["corner"]=0.035,["fill"]="#b8915aaa",["id"]="ray-pixel-1-4",["size"]={0.42,0.42},["stroke"]="#d8dadd",["width"]=1.6}
        local object12 = object1:rectangle {["center"]={-0.96,-0.48},["corner"]=0.035,["fill"]="#ffffff",["id"]="ray-pixel-2-0",["size"]={0.42,0.42},["stroke"]="#d8dadd",["width"]=1.6}
        local object13 = object1:rectangle {["center"]={-0.48,-0.48},["corner"]=0.035,["fill"]="#ffffff",["id"]="ray-pixel-2-1",["size"]={0.42,0.42},["stroke"]="#d8dadd",["width"]=1.6}
        local object14 = object1:rectangle {["center"]={0,-0.48},["corner"]=0.035,["fill"]="#9b3600aa",["id"]="ray-pixel-2-2",["size"]={0.42,0.42},["stroke"]="#d8dadd",["width"]=1.6}
        local object15 = object1:rectangle {["center"]={0.48,-0.48},["corner"]=0.035,["fill"]="#b8915aaa",["id"]="ray-pixel-2-3",["size"]={0.42,0.42},["stroke"]="#d8dadd",["width"]=1.6}
        local object16 = object1:rectangle {["center"]={0.96,-0.48},["corner"]=0.035,["fill"]="#b8915aaa",["id"]="ray-pixel-2-4",["size"]={0.42,0.42},["stroke"]="#d8dadd",["width"]=1.6}
        local object17 = object1:line {["from"]={-1.29,-0.8},["id"]="ray-frame-0",["stroke"]="#5e7a9b",["to"]={1.29,-0.8},["width"]=2.5}
        local object18 = object1:line {["from"]={1.29,-0.8},["id"]="ray-frame-1",["stroke"]="#5e7a9b",["to"]={1.29,0.8},["width"]=2.5}
        local object19 = object1:line {["from"]={1.29,0.8},["id"]="ray-frame-2",["stroke"]="#5e7a9b",["to"]={-1.29,0.8},["width"]=2.5}
        local object20 = object1:line {["from"]={-1.29,0.8},["id"]="ray-frame-3",["stroke"]="#5e7a9b",["to"]={-1.29,-0.8},["width"]=2.5}
        local object21 = viewportScene2:point {["fill"]="#202124",["id"]="ray-pinhole",["layer"]=20,["point"]={-6,0,0},["radius"]=7}
        local object22 = viewportScene2:group {["id"]="ray-sphere",["matrix"]={1,0,0,2.2,0,1,0,0.656,0,0,1,1.968,0,0,0,1}}
        local object23 = object22:plot {["points"]={{0.6110200058215589,-0.7661948528186692,0},{0.6034973356203269,-0.7661948528186692,0.09558458773957432},{0.5811145581232963,-0.7661948528186692,0.188815565701941},{0.5444228115966235,-0.7661948528186692,0.2773972777937903},{0.4943255686127205,-0.7661948528186692,0.3591485482775734},{0.4320563895570681,-0.7661948528186692,0.432056389557068},{0.3591485482775734,-0.7661948528186692,0.4943255686127205},{0.27739727779379036,-0.7661948528186692,0.5444228115966234},{0.18881556570194102,-0.7661948528186692,0.5811145581232963},{0.09558458773957436,-0.7661948528186692,0.6034973356203269},{3.741418471721846e-17,-0.7661948528186692,0.6110200058215589},{-0.09558458773957415,-0.7661948528186692,0.6034973356203269},{-0.18881556570194097,-0.7661948528186692,0.5811145581232963},{-0.2773972777937903,-0.7661948528186692,0.5444228115966235},{-0.35914854827757337,-0.7661948528186692,0.4943255686127205},{-0.432056389557068,-0.7661948528186692,0.4320563895570681},{-0.4943255686127204,-0.7661948528186692,0.3591485482775735},{-0.5444228115966234,-0.7661948528186692,0.27739727779379036},{-0.5811145581232963,-0.7661948528186692,0.18881556570194105},{-0.6034973356203269,-0.7661948528186692,0.09558458773957439},{-0.6110200058215589,-0.7661948528186692,7.482836943443692e-17},{-0.6034973356203269,-0.7661948528186692,-0.09558458773957423},{-0.5811145581232964,-0.7661948528186692,-0.1888155657019407},{-0.5444228115966235,-0.7661948528186692,-0.27739727779379025},{-0.4943255686127205,-0.7661948528186692,-0.35914854827757337},{-0.43205638955706815,-0.7661948528186692,-0.432056389557068},{-0.3591485482775735,-0.7661948528186692,-0.4943255686127204},{-0.2773972777937904,-0.7661948528186692,-0.5444228115966234},{-0.1888155657019411,-0.7661948528186692,-0.5811145581232963},{-0.09558458773957441,-0.7661948528186692,-0.6034973356203269},{-1.1224255415165537e-16,-0.7661948528186692,-0.6110200058215589},{0.0955845877395742,-0.7661948528186692,-0.6034973356203269},{0.18881556570194089,-0.7661948528186692,-0.5811145581232963},{0.2773972777937902,-0.7661948528186692,-0.5444228115966236},{0.35914854827757325,-0.7661948528186692,-0.49432556861272053},{0.43205638955706793,-0.7661948528186692,-0.43205638955706815},{0.4943255686127204,-0.7661948528186692,-0.35914854827757353},{0.5444228115966234,-0.7661948528186692,-0.2773972777937904},{0.5811145581232963,-0.7661948528186692,-0.18881556570194113},{0.6034973356203269,-0.7661948528186692,-0.09558458773957447},{0.6110200058215589,-0.7661948528186692,-1.4965673886887384e-16}},["stroke"]="#5e7a9b",["width"]=2}
        local object24 = object22:plot {["points"]={{0.8829494905443708,-0.42520606433520697,0},{0.8720789171450919,-0.42520606433520697,0.13812373121085303},{0.8397348665417099,-0.42520606433520697,0.2728463977529125},{0.78671375660383,-0.42520606433520697,0.40085068045701716},{0.714321143025098,-0.42520606433520697,0.5189846890611336},{0.624339572209132,-0.42520606433520697,0.6243395722091319},{0.5189846890611336,-0.42520606433520697,0.714321143025098},{0.4008506804570172,-0.42520606433520697,0.7867137566038299},{0.27284639775291253,-0.42520606433520697,0.8397348665417099},{0.13812373121085308,-0.42520606433520697,0.8720789171450919},{5.406506337019749e-17,-0.42520606433520697,0.8829494905443708},{-0.13812373121085278,-0.42520606433520697,0.8720789171450919},{-0.2728463977529124,-0.42520606433520697,0.8397348665417099},{-0.4008506804570171,-0.42520606433520697,0.78671375660383},{-0.5189846890611335,-0.42520606433520697,0.714321143025098},{-0.6243395722091319,-0.42520606433520697,0.624339572209132},{-0.7143211430250979,-0.42520606433520697,0.5189846890611337},{-0.7867137566038299,-0.42520606433520697,0.4008506804570172},{-0.8397348665417099,-0.42520606433520697,0.2728463977529126},{-0.8720789171450918,-0.42520606433520697,0.1381237312108531},{-0.8829494905443708,-0.42520606433520697,1.0813012674039498e-16},{-0.8720789171450919,-0.42520606433520697,-0.1381237312108529},{-0.83973486654171,-0.42520606433520697,-0.27284639775291203},{-0.78671375660383,-0.42520606433520697,-0.40085068045701705},{-0.714321143025098,-0.42520606433520697,-0.5189846890611335},{-0.6243395722091322,-0.42520606433520697,-0.6243395722091319},{-0.5189846890611337,-0.42520606433520697,-0.7143211430250979},{-0.4008506804570172,-0.42520606433520697,-0.7867137566038299},{-0.27284639775291264,-0.42520606433520697,-0.8397348665417099},{-0.13812373121085317,-0.42520606433520697,-0.8720789171450918},{-1.6219519011059246e-16,-0.42520606433520697,-0.8829494905443708},{0.13812373121085286,-0.42520606433520697,-0.8720789171450919},{0.27284639775291236,-0.42520606433520697,-0.8397348665417099},{0.400850680457017,-0.42520606433520697,-0.7867137566038301},{0.5189846890611334,-0.42520606433520697,-0.714321143025098},{0.6243395722091318,-0.42520606433520697,-0.6243395722091322},{0.7143211430250979,-0.42520606433520697,-0.5189846890611338},{0.7867137566038299,-0.42520606433520697,-0.40085068045701727},{0.8397348665417099,-0.42520606433520697,-0.2728463977529127},{0.8720789171450918,-0.42520606433520697,-0.13812373121085325},{0.8829494905443708,-0.42520606433520697,-2.1626025348078997e-16}},["stroke"]="#5e7a9b",["width"]=2}
        local object25 = object22:plot {["points"]={{0.98,0,0},{0.967934573783235,0,0.15330577573942625},{0.9320353859692504,0,0.30283665448744845},{0.8731863937046005,0,0.44491068974475584},{0.7928366544874484,0,0.5760295472466237},{0.6929646455628166,0,0.6929646455628165},{0.5760295472466237,0,0.7928366544874484},{0.4449106897447559,0,0.8731863937046004},{0.3028366544874485,0,0.9320353859692504},{0.1533057757394263,0,0.967934573783235},{6.000769315822031e-17,0,0.98},{-0.15330577573942597,0,0.967934573783235},{-0.3028366544874484,0,0.9320353859692505},{-0.4449106897447558,0,0.8731863937046005},{-0.5760295472466236,0,0.7928366544874484},{-0.6929646455628165,0,0.6929646455628166},{-0.7928366544874483,0,0.5760295472466238},{-0.8731863937046004,0,0.4449106897447559},{-0.9320353859692504,0,0.30283665448744856},{-0.9679345737832349,0,0.15330577573942636},{-0.98,0,1.2001538631644062e-16},{-0.967934573783235,0,-0.1533057757394261},{-0.9320353859692506,0,-0.30283665448744795},{-0.8731863937046005,0,-0.4449106897447557},{-0.7928366544874484,0,-0.5760295472466236},{-0.6929646455628167,0,-0.6929646455628165},{-0.5760295472466238,0,-0.7928366544874483},{-0.44491068974475595,0,-0.8731863937046004},{-0.3028366544874486,0,-0.9320353859692504},{-0.15330577573942641,0,-0.9679345737832349},{-1.8002307947466092e-16,0,-0.98},{0.15330577573942605,0,-0.967934573783235},{0.3028366544874483,0,-0.9320353859692505},{0.44491068974475567,0,-0.8731863937046006},{0.5760295472466235,0,-0.7928366544874486},{0.6929646455628163,0,-0.6929646455628167},{0.7928366544874483,0,-0.5760295472466239},{0.8731863937046004,0,-0.444910689744756},{0.9320353859692504,0,-0.3028366544874487},{0.9679345737832349,0,-0.1533057757394265},{0.98,0,-2.4003077263288124e-16}},["stroke"]="#5e7a9b",["width"]=2}
        local object26 = object22:plot {["points"]={{0.8829494905443708,0.42520606433520697,0},{0.8720789171450919,0.42520606433520697,0.13812373121085303},{0.8397348665417099,0.42520606433520697,0.2728463977529125},{0.78671375660383,0.42520606433520697,0.40085068045701716},{0.714321143025098,0.42520606433520697,0.5189846890611336},{0.624339572209132,0.42520606433520697,0.6243395722091319},{0.5189846890611336,0.42520606433520697,0.714321143025098},{0.4008506804570172,0.42520606433520697,0.7867137566038299},{0.27284639775291253,0.42520606433520697,0.8397348665417099},{0.13812373121085308,0.42520606433520697,0.8720789171450919},{5.406506337019749e-17,0.42520606433520697,0.8829494905443708},{-0.13812373121085278,0.42520606433520697,0.8720789171450919},{-0.2728463977529124,0.42520606433520697,0.8397348665417099},{-0.4008506804570171,0.42520606433520697,0.78671375660383},{-0.5189846890611335,0.42520606433520697,0.714321143025098},{-0.6243395722091319,0.42520606433520697,0.624339572209132},{-0.7143211430250979,0.42520606433520697,0.5189846890611337},{-0.7867137566038299,0.42520606433520697,0.4008506804570172},{-0.8397348665417099,0.42520606433520697,0.2728463977529126},{-0.8720789171450918,0.42520606433520697,0.1381237312108531},{-0.8829494905443708,0.42520606433520697,1.0813012674039498e-16},{-0.8720789171450919,0.42520606433520697,-0.1381237312108529},{-0.83973486654171,0.42520606433520697,-0.27284639775291203},{-0.78671375660383,0.42520606433520697,-0.40085068045701705},{-0.714321143025098,0.42520606433520697,-0.5189846890611335},{-0.6243395722091322,0.42520606433520697,-0.6243395722091319},{-0.5189846890611337,0.42520606433520697,-0.7143211430250979},{-0.4008506804570172,0.42520606433520697,-0.7867137566038299},{-0.27284639775291264,0.42520606433520697,-0.8397348665417099},{-0.13812373121085317,0.42520606433520697,-0.8720789171450918},{-1.6219519011059246e-16,0.42520606433520697,-0.8829494905443708},{0.13812373121085286,0.42520606433520697,-0.8720789171450919},{0.27284639775291236,0.42520606433520697,-0.8397348665417099},{0.400850680457017,0.42520606433520697,-0.7867137566038301},{0.5189846890611334,0.42520606433520697,-0.714321143025098},{0.6243395722091318,0.42520606433520697,-0.6243395722091322},{0.7143211430250979,0.42520606433520697,-0.5189846890611338},{0.7867137566038299,0.42520606433520697,-0.40085068045701727},{0.8397348665417099,0.42520606433520697,-0.2728463977529127},{0.8720789171450918,0.42520606433520697,-0.13812373121085325},{0.8829494905443708,0.42520606433520697,-2.1626025348078997e-16}},["stroke"]="#5e7a9b",["width"]=2}
        local object27 = object22:plot {["points"]={{0.6110200058215589,0.7661948528186692,0},{0.6034973356203269,0.7661948528186692,0.09558458773957432},{0.5811145581232963,0.7661948528186692,0.188815565701941},{0.5444228115966235,0.7661948528186692,0.2773972777937903},{0.4943255686127205,0.7661948528186692,0.3591485482775734},{0.4320563895570681,0.7661948528186692,0.432056389557068},{0.3591485482775734,0.7661948528186692,0.4943255686127205},{0.27739727779379036,0.7661948528186692,0.5444228115966234},{0.18881556570194102,0.7661948528186692,0.5811145581232963},{0.09558458773957436,0.7661948528186692,0.6034973356203269},{3.741418471721846e-17,0.7661948528186692,0.6110200058215589},{-0.09558458773957415,0.7661948528186692,0.6034973356203269},{-0.18881556570194097,0.7661948528186692,0.5811145581232963},{-0.2773972777937903,0.7661948528186692,0.5444228115966235},{-0.35914854827757337,0.7661948528186692,0.4943255686127205},{-0.432056389557068,0.7661948528186692,0.4320563895570681},{-0.4943255686127204,0.7661948528186692,0.3591485482775735},{-0.5444228115966234,0.7661948528186692,0.27739727779379036},{-0.5811145581232963,0.7661948528186692,0.18881556570194105},{-0.6034973356203269,0.7661948528186692,0.09558458773957439},{-0.6110200058215589,0.7661948528186692,7.482836943443692e-17},{-0.6034973356203269,0.7661948528186692,-0.09558458773957423},{-0.5811145581232964,0.7661948528186692,-0.1888155657019407},{-0.5444228115966235,0.7661948528186692,-0.27739727779379025},{-0.4943255686127205,0.7661948528186692,-0.35914854827757337},{-0.43205638955706815,0.7661948528186692,-0.432056389557068},{-0.3591485482775735,0.7661948528186692,-0.4943255686127204},{-0.2773972777937904,0.7661948528186692,-0.5444228115966234},{-0.1888155657019411,0.7661948528186692,-0.5811145581232963},{-0.09558458773957441,0.7661948528186692,-0.6034973356203269},{-1.1224255415165537e-16,0.7661948528186692,-0.6110200058215589},{0.0955845877395742,0.7661948528186692,-0.6034973356203269},{0.18881556570194089,0.7661948528186692,-0.5811145581232963},{0.2773972777937902,0.7661948528186692,-0.5444228115966236},{0.35914854827757325,0.7661948528186692,-0.49432556861272053},{0.43205638955706793,0.7661948528186692,-0.43205638955706815},{0.4943255686127204,0.7661948528186692,-0.35914854827757353},{0.5444228115966234,0.7661948528186692,-0.2773972777937904},{0.5811145581232963,0.7661948528186692,-0.18881556570194113},{0.6034973356203269,0.7661948528186692,-0.09558458773957447},{0.6110200058215589,0.7661948528186692,-1.4965673886887384e-16}},["stroke"]="#5e7a9b",["width"]=2}
        local object28 = object22:plot {["points"]={{6.000769315822031e-17,-0.98,0},{0.06409506664554018,-0.9779017447738314,0},{0.1279156683756507,-0.9716159641463341,0},{0.19118851557580577,-0.9611695747951658,0},{0.2536426642004703,-0.9466073097632869,0},{0.3150106759970985,-0.9279915269052035,0},{0.375029763717788,-0.9054019418610609,0},{0.43344291641462124,-0.8789352867020346,0},{0.4899999999999999,-0.84870489570875,0},{0.5444588283592102,-0.8148402200564944,0},{0.5965862004285463,-0.7774862734854104,0},{0.6461588987980674,-0.7368030113293979,0},{0.6929646455628166,-0.6929646455628165,0},{0.7368030113293979,-0.6461588987980674,0},{0.7774862734854104,-0.5965862004285463,0},{0.8148402200564944,-0.5444588283592102,0},{0.8487048957087499,-0.49,0},{0.8789352867020346,-0.4334429164146212,0},{0.9054019418610609,-0.37502976371778796,0},{0.9279915269052036,-0.3150106759970984,0},{0.9466073097632869,-0.25364266420047027,0},{0.9611695747951658,-0.19118851557580568,0},{0.9716159641463341,-0.12791566837565063,0},{0.9779017447738314,-0.06409506664554035,0},{0.98,0,0},{0.9779017447738314,0.06409506664554035,0},{0.9716159641463341,0.12791566837565063,0},{0.9611695747951658,0.19118851557580568,0},{0.9466073097632869,0.25364266420047027,0},{0.9279915269052036,0.3150106759970984,0},{0.905401941861061,0.37502976371778773,0},{0.8789352867020346,0.4334429164146212,0},{0.84870489570875,0.4899999999999998,0},{0.8148402200564943,0.5444588283592103,0},{0.7774862734854103,0.5965862004285464,0},{0.7368030113293979,0.6461588987980675,0},{0.6929646455628166,0.6929646455628165,0},{0.6461588987980675,0.7368030113293977,0},{0.5965862004285464,0.7774862734854103,0},{0.5444588283592103,0.8148402200564943,0},{0.4899999999999999,0.84870489570875,0},{0.43344291641462157,0.8789352867020344,0},{0.375029763717788,0.9054019418610609,0},{0.3150106759970985,0.9279915269052035,0},{0.25364266420047055,0.9466073097632868,0},{0.19118851557580555,0.9611695747951658,0},{0.12791566837565088,0.9716159641463341,0},{0.06409506664554018,0.9779017447738314,0},{6.000769315822031e-17,0.98,0}},["stroke"]="#5e7a9baa",["width"]=1.6}
        local object29 = object22:plot {["points"]={{5.1968186697520443e-17,-0.98,3.000384657911015e-17},{0.055507955972294444,-0.9779017447738314,0.032047533322770085},{0.11077821835537924,-0.9716159641463341,0.06395783418782533},{0.16557411140048464,-0.9611695747951658,0.09559425778790287},{0.21966099068117312,-0.9466073097632869,0.12682133210023513},{0.2728072478767962,-0.9279915269052035,0.1575053379985492},{0.32478530255488003,-0.9054019418610609,0.18751488185889398},{0.3753725767054771,-0.8789352867020346,0.2167214582073106},{0.42435244785437487,-0.84870489570875,0.2449999999999999},{0.47151517667378745,-0.8148402200564944,0.27222941417960506},{0.5166588051183558,-0.7774862734854104,0.2982931002142731},{0.5595900212405046,-0.7368030113293979,0.32307944939903366},{0.6001249869818787,-0.6929646455628165,0.3464823227814082},{0.6380901253961322,-0.6461588987980674,0.36840150566469887},{0.6733228639320611,-0.5965862004285463,0.38874313674270516},{0.7056723305942264,-0.5444588283592102,0.40742011002824713},{0.735,-0.49,0.42435244785437487},{0.7611802865665209,-0.4334429164146212,0.43946764335101723},{0.7841010822874402,-0.37502976371778796,0.4527009709305304},{0.8036642367966168,-0.3150106759970984,0.46399576345260174},{0.8197859776630517,-0.25364266420047027,0.4733036548816434},{0.8323972691173007,-0.19118851557580568,0.48058478739758287},{0.8414441076732357,-0.12791566837565063,0.485807982073167},{0.8468877533792645,-0.06409506664554035,0.48895087238691565},{0.84870489570875,0,0.48999999999999994},{0.8468877533792645,0.06409506664554035,0.48895087238691565},{0.8414441076732357,0.12791566837565063,0.485807982073167},{0.8323972691173007,0.19118851557580568,0.48058478739758287},{0.8197859776630517,0.25364266420047027,0.4733036548816434},{0.8036642367966168,0.3150106759970984,0.46399576345260174},{0.7841010822874402,0.37502976371778773,0.45270097093053047},{0.7611802865665209,0.4334429164146212,0.43946764335101723},{0.7350000000000001,0.4899999999999998,0.4243524478543749},{0.7056723305942263,0.5444588283592103,0.4074201100282471},{0.673322863932061,0.5965862004285464,0.3887431367427051},{0.6380901253961322,0.6461588987980675,0.36840150566469887},{0.6001249869818787,0.6929646455628165,0.3464823227814082},{0.5595900212405047,0.7368030113293977,0.3230794493990337},{0.5166588051183559,0.7774862734854103,0.29829310021427313},{0.47151517667378756,0.8148402200564943,0.2722294141796051},{0.42435244785437487,0.84870489570875,0.2449999999999999},{0.37537257670547736,0.8789352867020344,0.21672145820731076},{0.32478530255488003,0.9054019418610609,0.18751488185889398},{0.2728072478767962,0.9279915269052035,0.1575053379985492},{0.2196609906811733,0.9466073097632868,0.12682133210023525},{0.16557411140048445,0.9611695747951658,0.09559425778790276},{0.11077821835537942,0.9716159641463341,0.06395783418782543},{0.055507955972294444,0.9779017447738314,0.032047533322770085},{5.1968186697520443e-17,0.98,3.000384657911015e-17}},["stroke"]="#5e7a9baa",["width"]=1.6}
        local object30 = object22:plot {["points"]={{3.000384657911016e-17,-0.98,5.196818669752044e-17},{0.0320475333227701,-0.9779017447738314,0.05550795597229444},{0.06395783418782536,-0.9716159641463341,0.11077821835537922},{0.09559425778790291,-0.9611695747951658,0.1655741114004846},{0.1268213321002352,-0.9466073097632869,0.2196609906811731},{0.15750533799854927,-0.9279915269052035,0.27280724787679617},{0.18751488185889406,-0.9054019418610609,0.32478530255488},{0.21672145820731067,-0.8789352867020346,0.375372576705477},{0.245,-0.84870489570875,0.4243524478543748},{0.27222941417960517,-0.8148402200564944,0.4715151766737874},{0.2982931002142732,-0.7774862734854104,0.5166588051183558},{0.32307944939903377,-0.7368030113293979,0.5595900212405045},{0.34648232278140834,-0.6929646455628165,0.6001249869818785},{0.368401505664699,-0.6461588987980674,0.6380901253961321},{0.38874313674270533,-0.5965862004285463,0.673322863932061},{0.4074201100282473,-0.5444588283592102,0.7056723305942263},{0.42435244785437504,-0.49,0.735},{0.4394676433510174,-0.4334429164146212,0.7611802865665208},{0.4527009709305306,-0.37502976371778796,0.7841010822874401},{0.4639957634526019,-0.3150106759970984,0.8036642367966167},{0.47330365488164355,-0.25364266420047027,0.8197859776630517},{0.48058478739758304,-0.19118851557580568,0.8323972691173006},{0.48580798207316717,-0.12791566837565063,0.8414441076732356},{0.4889508723869158,-0.06409506664554035,0.8468877533792644},{0.4900000000000001,0,0.8487048957087499},{0.4889508723869158,0.06409506664554035,0.8468877533792644},{0.48580798207316717,0.12791566837565063,0.8414441076732356},{0.48058478739758304,0.19118851557580568,0.8323972691173006},{0.47330365488164355,0.25364266420047027,0.8197859776630517},{0.4639957634526019,0.3150106759970984,0.8036642367966167},{0.45270097093053063,0.37502976371778773,0.7841010822874402},{0.4394676433510174,0.4334429164146212,0.7611802865665208},{0.4243524478543751,0.4899999999999998,0.735},{0.40742011002824724,0.5444588283592103,0.7056723305942263},{0.3887431367427053,0.5965862004285464,0.673322863932061},{0.368401505664699,0.6461588987980675,0.6380901253961321},{0.34648232278140834,0.6929646455628165,0.6001249869818785},{0.3230794493990338,0.7368030113293977,0.5595900212405046},{0.29829310021427324,0.7774862734854103,0.5166588051183559},{0.2722294141796052,0.8148402200564943,0.47151517667378745},{0.245,0.84870489570875,0.4243524478543748},{0.21672145820731084,0.8789352867020344,0.3753725767054773},{0.18751488185889406,0.9054019418610609,0.32478530255488},{0.15750533799854927,0.9279915269052035,0.27280724787679617},{0.1268213321002353,0.9466073097632868,0.21966099068117328},{0.0955942577879028,0.9611695747951658,0.16557411140048442},{0.06395783418782545,0.9716159641463341,0.1107782183553794},{0.0320475333227701,0.9779017447738314,0.05550795597229444},{3.000384657911016e-17,0.98,5.196818669752044e-17}},["stroke"]="#5e7a9baa",["width"]=1.6}
        local object31 = object22:plot {["points"]={{3.674411467521551e-33,-0.98,6.000769315822031e-17},{3.924690910429853e-18,-0.9779017447738314,0.06409506664554018},{7.832575691851747e-18,-0.9716159641463341,0.1279156683756507},{1.170692018168222e-17,-0.9611695747951658,0.19118851557580577},{1.5531133842015647e-17,-0.9466073097632869,0.2536426642004703},{1.928884080285453e-17,-0.9279915269052035,0.3150106759970985},{2.2963949986098864e-17,-0.9054019418610609,0.375029763717788},{2.6540724010012984e-17,-0.8789352867020346,0.43344291641462124},{3.000384657911015e-17,-0.84870489570875,0.4899999999999999},{3.333848807088125e-17,-0.8148402200564944,0.5444588283592102},{3.6530369038515023e-17,-0.7774862734854104,0.5965862004285463},{3.956582135768159e-17,-0.7368030113293979,0.6461588987980674},{4.243184675553917e-17,-0.6929646455628165,0.6929646455628166},{4.5116172471333903e-17,-0.6461588987980674,0.7368030113293979},{4.7607303810245576e-17,-0.5965862004285463,0.7774862734854104},{4.989457336543554e-17,-0.5444588283592102,0.8148402200564944},{5.196818669752044e-17,-0.49,0.8487048957087499},{5.381926427586539e-17,-0.4334429164146212,0.8789352867020346},{5.543987950209731e-17,-0.37502976371778796,0.9054019418610609},{5.682309265301613e-17,-0.3150106759970984,0.9279915269052036},{5.796298059755482e-17,-0.25364266420047027,0.9466073097632869},{5.885466216053611e-17,-0.19118851557580568,0.9611695747951658},{5.949431902461388e-17,-0.12791566837565063,0.9716159641463341},{5.987921208089423e-17,-0.06409506664554035,0.9779017447738314},{6.000769315822031e-17,0,0.98},{5.987921208089423e-17,0.06409506664554035,0.9779017447738314},{5.949431902461388e-17,0.12791566837565063,0.9716159641463341},{5.885466216053611e-17,0.19118851557580568,0.9611695747951658},{5.796298059755482e-17,0.25364266420047027,0.9466073097632869},{5.682309265301613e-17,0.3150106759970984,0.9279915269052036},{5.5439879502097316e-17,0.37502976371778773,0.905401941861061},{5.381926427586539e-17,0.4334429164146212,0.8789352867020346},{5.1968186697520443e-17,0.4899999999999998,0.84870489570875},{4.989457336543553e-17,0.5444588283592103,0.8148402200564943},{4.760730381024557e-17,0.5965862004285464,0.7774862734854103},{4.5116172471333903e-17,0.6461588987980675,0.7368030113293979},{4.243184675553917e-17,0.6929646455628165,0.6929646455628166},{3.95658213576816e-17,0.7368030113293977,0.6461588987980675},{3.653036903851503e-17,0.7774862734854103,0.5965862004285464},{3.3338488070881255e-17,0.8148402200564943,0.5444588283592103},{3.000384657911015e-17,0.84870489570875,0.4899999999999999},{2.6540724010013002e-17,0.8789352867020344,0.43344291641462157},{2.2963949986098864e-17,0.9054019418610609,0.375029763717788},{1.928884080285453e-17,0.9279915269052035,0.3150106759970985},{1.553113384201566e-17,0.9466073097632868,0.25364266420047055},{1.1706920181682207e-17,0.9611695747951658,0.19118851557580555},{7.832575691851758e-18,0.9716159641463341,0.12791566837565088},{3.924690910429853e-18,0.9779017447738314,0.06409506664554018},{3.674411467521551e-33,0.98,6.000769315822031e-17}},["stroke"]="#5e7a9baa",["width"]=1.6}
        local object32 = object22:plot {["points"]={{-3.000384657911014e-17,-0.98,5.1968186697520443e-17},{-0.03204753332277008,-0.9779017447738314,0.055507955972294444},{-0.06395783418782532,-0.9716159641463341,0.11077821835537924},{-0.09559425778790284,-0.9611695747951658,0.16557411140048464},{-0.1268213321002351,-0.9466073097632869,0.21966099068117312},{-0.15750533799854916,-0.9279915269052035,0.2728072478767962},{-0.18751488185889392,-0.9054019418610609,0.32478530255488003},{-0.21672145820731054,-0.8789352867020346,0.3753725767054771},{-0.24499999999999983,-0.84870489570875,0.42435244785437487},{-0.272229414179605,-0.8148402200564944,0.47151517667378745},{-0.298293100214273,-0.7774862734854104,0.5166588051183558},{-0.32307944939903355,-0.7368030113293979,0.5595900212405046},{-0.3464823227814081,-0.6929646455628165,0.6001249869818787},{-0.36840150566469876,-0.6461588987980674,0.6380901253961322},{-0.38874313674270505,-0.5965862004285463,0.6733228639320611},{-0.407420110028247,-0.5444588283592102,0.7056723305942264},{-0.42435244785437476,-0.49,0.735},{-0.43946764335101707,-0.4334429164146212,0.7611802865665209},{-0.45270097093053024,-0.37502976371778796,0.7841010822874402},{-0.4639957634526016,-0.3150106759970984,0.8036642367966168},{-0.4733036548816432,-0.25364266420047027,0.8197859776630517},{-0.4805847873975827,-0.19118851557580568,0.8323972691173007},{-0.48580798207316683,-0.12791566837565063,0.8414441076732357},{-0.4889508723869155,-0.06409506664554035,0.8468877533792645},{-0.48999999999999977,0,0.84870489570875},{-0.4889508723869155,0.06409506664554035,0.8468877533792645},{-0.48580798207316683,0.12791566837565063,0.8414441076732357},{-0.4805847873975827,0.19118851557580568,0.8323972691173007},{-0.4733036548816432,0.25364266420047027,0.8197859776630517},{-0.4639957634526016,0.3150106759970984,0.8036642367966168},{-0.4527009709305303,0.37502976371778773,0.7841010822874402},{-0.43946764335101707,0.4334429164146212,0.7611802865665209},{-0.4243524478543748,0.4899999999999998,0.7350000000000001},{-0.40742011002824696,0.5444588283592103,0.7056723305942263},{-0.388743136742705,0.5965862004285464,0.673322863932061},{-0.36840150566469876,0.6461588987980675,0.6380901253961322},{-0.3464823227814081,0.6929646455628165,0.6001249869818787},{-0.3230794493990336,0.7368030113293977,0.5595900212405047},{-0.2982931002142731,0.7774862734854103,0.5166588051183559},{-0.27222941417960506,0.8148402200564943,0.47151517667378756},{-0.24499999999999983,0.84870489570875,0.42435244785437487},{-0.2167214582073107,0.8789352867020344,0.37537257670547736},{-0.18751488185889392,0.9054019418610609,0.32478530255488003},{-0.15750533799854916,0.9279915269052035,0.2728072478767962},{-0.12682133210023522,0.9466073097632868,0.2196609906811733},{-0.09559425778790273,0.9611695747951658,0.16557411140048445},{-0.06395783418782541,0.9716159641463341,0.11077821835537942},{-0.03204753332277008,0.9779017447738314,0.055507955972294444},{-3.000384657911014e-17,0.98,5.1968186697520443e-17}},["stroke"]="#5e7a9baa",["width"]=1.6}
        local object33 = object22:plot {["points"]={{-5.1968186697520443e-17,-0.98,3.000384657911015e-17},{-0.055507955972294444,-0.9779017447738314,0.032047533322770085},{-0.11077821835537924,-0.9716159641463341,0.06395783418782533},{-0.16557411140048464,-0.9611695747951658,0.09559425778790287},{-0.21966099068117312,-0.9466073097632869,0.12682133210023513},{-0.2728072478767962,-0.9279915269052035,0.1575053379985492},{-0.32478530255488003,-0.9054019418610609,0.18751488185889398},{-0.3753725767054771,-0.8789352867020346,0.2167214582073106},{-0.42435244785437487,-0.84870489570875,0.2449999999999999},{-0.47151517667378745,-0.8148402200564944,0.27222941417960506},{-0.5166588051183558,-0.7774862734854104,0.2982931002142731},{-0.5595900212405046,-0.7368030113293979,0.32307944939903366},{-0.6001249869818787,-0.6929646455628165,0.3464823227814082},{-0.6380901253961322,-0.6461588987980674,0.36840150566469887},{-0.6733228639320611,-0.5965862004285463,0.38874313674270516},{-0.7056723305942264,-0.5444588283592102,0.40742011002824713},{-0.735,-0.49,0.42435244785437487},{-0.7611802865665209,-0.4334429164146212,0.43946764335101723},{-0.7841010822874402,-0.37502976371778796,0.4527009709305304},{-0.8036642367966168,-0.3150106759970984,0.46399576345260174},{-0.8197859776630517,-0.25364266420047027,0.4733036548816434},{-0.8323972691173007,-0.19118851557580568,0.48058478739758287},{-0.8414441076732357,-0.12791566837565063,0.485807982073167},{-0.8468877533792645,-0.06409506664554035,0.48895087238691565},{-0.84870489570875,0,0.48999999999999994},{-0.8468877533792645,0.06409506664554035,0.48895087238691565},{-0.8414441076732357,0.12791566837565063,0.485807982073167},{-0.8323972691173007,0.19118851557580568,0.48058478739758287},{-0.8197859776630517,0.25364266420047027,0.4733036548816434},{-0.8036642367966168,0.3150106759970984,0.46399576345260174},{-0.7841010822874402,0.37502976371778773,0.45270097093053047},{-0.7611802865665209,0.4334429164146212,0.43946764335101723},{-0.7350000000000001,0.4899999999999998,0.4243524478543749},{-0.7056723305942263,0.5444588283592103,0.4074201100282471},{-0.673322863932061,0.5965862004285464,0.3887431367427051},{-0.6380901253961322,0.6461588987980675,0.36840150566469887},{-0.6001249869818787,0.6929646455628165,0.3464823227814082},{-0.5595900212405047,0.7368030113293977,0.3230794493990337},{-0.5166588051183559,0.7774862734854103,0.29829310021427313},{-0.47151517667378756,0.8148402200564943,0.2722294141796051},{-0.42435244785437487,0.84870489570875,0.2449999999999999},{-0.37537257670547736,0.8789352867020344,0.21672145820731076},{-0.32478530255488003,0.9054019418610609,0.18751488185889398},{-0.2728072478767962,0.9279915269052035,0.1575053379985492},{-0.2196609906811733,0.9466073097632868,0.12682133210023525},{-0.16557411140048445,0.9611695747951658,0.09559425778790276},{-0.11077821835537942,0.9716159641463341,0.06395783418782543},{-0.055507955972294444,0.9779017447738314,0.032047533322770085},{-5.1968186697520443e-17,0.98,3.000384657911015e-17}},["stroke"]="#5e7a9baa",["width"]=1.6}
        local object34 = viewportScene2:group {["id"]="ray-cube",["matrix"]={1,0,0,2.2,0,1,0,-0.656,0,0,1,-1.968,0,0,0,1}}
        local object35 = object34:line {["from"]={-0.82,-0.82,-0.82},["stroke"]="#b8915a",["to"]={0.82,-0.82,-0.82},["width"]=2.4}
        local object36 = object34:line {["from"]={0.82,-0.82,-0.82},["stroke"]="#b8915a",["to"]={0.82,0.82,-0.82},["width"]=2.4}
        local object37 = object34:line {["from"]={0.82,0.82,-0.82},["stroke"]="#b8915a",["to"]={-0.82,0.82,-0.82},["width"]=2.4}
        local object38 = object34:line {["from"]={-0.82,0.82,-0.82},["stroke"]="#b8915a",["to"]={-0.82,-0.82,-0.82},["width"]=2.4}
        local object39 = object34:line {["from"]={-0.82,-0.82,0.82},["stroke"]="#b8915a",["to"]={0.82,-0.82,0.82},["width"]=2.4}
        local object40 = object34:line {["from"]={0.82,-0.82,0.82},["stroke"]="#b8915a",["to"]={0.82,0.82,0.82},["width"]=2.4}
        local object41 = object34:line {["from"]={0.82,0.82,0.82},["stroke"]="#b8915a",["to"]={-0.82,0.82,0.82},["width"]=2.4}
        local object42 = object34:line {["from"]={-0.82,0.82,0.82},["stroke"]="#b8915a",["to"]={-0.82,-0.82,0.82},["width"]=2.4}
        local object43 = object34:line {["from"]={-0.82,-0.82,-0.82},["stroke"]="#b8915a",["to"]={-0.82,-0.82,0.82},["width"]=2.4}
        local object44 = object34:line {["from"]={0.82,-0.82,-0.82},["stroke"]="#b8915a",["to"]={0.82,-0.82,0.82},["width"]=2.4}
        local object45 = object34:line {["from"]={0.82,0.82,-0.82},["stroke"]="#b8915a",["to"]={0.82,0.82,0.82},["width"]=2.4}
        local object46 = object34:line {["from"]={-0.82,0.82,-0.82},["stroke"]="#b8915a",["to"]={-0.82,0.82,0.82},["width"]=2.4}
        local object47 = viewportScene2:group {["id"]="ray-pyramid",["matrix"]={1,0,0,2.2,0,1,0,-1.312,0,0,1,0,0,0,0,1}}
        local object48 = object47:line {["from"]={-0.72,-0.55,-0.72},["stroke"]="#9b3600",["to"]={0.72,-0.55,-0.72},["width"]=2.4}
        local object49 = object47:line {["from"]={-0.72,-0.55,-0.72},["stroke"]="#9b3600",["to"]={0,0.82,0},["width"]=2.4}
        local object50 = object47:line {["from"]={0.72,-0.55,-0.72},["stroke"]="#9b3600",["to"]={0.72,-0.55,0.72},["width"]=2.4}
        local object51 = object47:line {["from"]={0.72,-0.55,-0.72},["stroke"]="#9b3600",["to"]={0,0.82,0},["width"]=2.4}
        local object52 = object47:line {["from"]={0.72,-0.55,0.72},["stroke"]="#9b3600",["to"]={-0.72,-0.55,0.72},["width"]=2.4}
        local object53 = object47:line {["from"]={0.72,-0.55,0.72},["stroke"]="#9b3600",["to"]={0,0.82,0},["width"]=2.4}
        local object54 = object47:line {["from"]={-0.72,-0.55,0.72},["stroke"]="#9b3600",["to"]={-0.72,-0.55,-0.72},["width"]=2.4}
        local object55 = object47:line {["from"]={-0.72,-0.55,0.72},["stroke"]="#9b3600",["to"]={0,0.82,0},["width"]=2.4}
        local object56 = viewportScene2:arrow {["from"]={-6,0,0},["id"]="ray-primary-0-0",["opacity"]=0.28,["stroke"]="#5e7a9b",["tip"]=8,["to"]={2.2,1.3119999999999998,2.6239999999999997},["width"]=2.8}
        local object57 = viewportScene2:point {["fill"]="#5e7a9b",["id"]="ray-hit-0-0",["layer"]=20,["opacity"]=0.45,["point"]={2.2,1.3119999999999998,2.6239999999999997},["radius"]=4.5}
        local object58 = viewportScene2:arrow {["from"]={-6,0,0},["id"]="ray-primary-0-1",["opacity"]=0.28,["stroke"]="#5e7a9b",["tip"]=8,["to"]={2.2,1.3119999999999998,1.3119999999999998},["width"]=2.8}
        local object59 = viewportScene2:point {["fill"]="#5e7a9b",["id"]="ray-hit-0-1",["layer"]=20,["opacity"]=0.45,["point"]={2.2,1.3119999999999998,1.3119999999999998},["radius"]=4.5}
        local object60 = viewportScene2:arrow {["from"]={-6,0,0},["id"]="ray-primary-0-2",["opacity"]=0.1,["stroke"]="#555b64",["tip"]=8,["to"]={3.8,1.568,0},["width"]=1.7}
        local object61 = viewportScene2:arrow {["from"]={-6,0,0},["id"]="ray-primary-0-3",["opacity"]=0.1,["stroke"]="#555b64",["tip"]=8,["to"]={3.8,1.568,-1.568},["width"]=1.7}
        local object62 = viewportScene2:arrow {["from"]={-6,0,0},["id"]="ray-primary-0-4",["opacity"]=0.1,["stroke"]="#555b64",["tip"]=8,["to"]={3.8,1.568,-3.136},["width"]=1.7}
        local object63 = viewportScene2:arrow {["from"]={-6,0,0},["id"]="ray-primary-1-0",["opacity"]=0.28,["stroke"]="#5e7a9b",["tip"]=8,["to"]={2.2,0,2.6239999999999997},["width"]=2.8}
        local object64 = viewportScene2:point {["fill"]="#5e7a9b",["id"]="ray-hit-1-0",["layer"]=20,["opacity"]=0.45,["point"]={2.2,0,2.6239999999999997},["radius"]=4.5}
        local object65 = viewportScene2:arrow {["from"]={-6,0,0},["id"]="ray-primary-1-1",["opacity"]=0.28,["stroke"]="#5e7a9b",["tip"]=8,["to"]={2.2,0,1.3119999999999998},["width"]=2.8}
        local object66 = viewportScene2:point {["fill"]="#5e7a9b",["id"]="ray-hit-1-1",["layer"]=20,["opacity"]=0.45,["point"]={2.2,0,1.3119999999999998},["radius"]=4.5}
        local object67 = viewportScene2:arrow {["from"]={-6,0,0},["id"]="ray-primary-1-2",["opacity"]=0.1,["stroke"]="#555b64",["tip"]=8,["to"]={3.8,0,0},["width"]=1.7}
        local object68 = viewportScene2:arrow {["from"]={-6,0,0},["id"]="ray-primary-1-3",["opacity"]=0.28,["stroke"]="#b8915a",["tip"]=8,["to"]={2.2,0,-1.3119999999999998},["width"]=2.8}
        local object69 = viewportScene2:point {["fill"]="#b8915a",["id"]="ray-hit-1-3",["layer"]=20,["opacity"]=0.45,["point"]={2.2,0,-1.3119999999999998},["radius"]=4.5}
        local object70 = viewportScene2:arrow {["from"]={-6,0,0},["id"]="ray-primary-1-4",["opacity"]=0.28,["stroke"]="#b8915a",["tip"]=8,["to"]={2.2,0,-2.6239999999999997},["width"]=2.8}
        local object71 = viewportScene2:point {["fill"]="#b8915a",["id"]="ray-hit-1-4",["layer"]=20,["opacity"]=0.45,["point"]={2.2,0,-2.6239999999999997},["radius"]=4.5}
        local object72 = viewportScene2:arrow {["from"]={-6,0,0},["id"]="ray-primary-2-0",["opacity"]=0.1,["stroke"]="#555b64",["tip"]=8,["to"]={3.8,-1.568,3.136},["width"]=1.7}
        local object73 = viewportScene2:arrow {["from"]={-6,0,0},["id"]="ray-primary-2-1",["opacity"]=0.1,["stroke"]="#555b64",["tip"]=8,["to"]={3.8,-1.568,1.568},["width"]=1.7}
        local object74 = viewportScene2:arrow {["from"]={-6,0,0},["id"]="ray-primary-2-2",["opacity"]=0.28,["stroke"]="#9b3600",["tip"]=8,["to"]={2.2,-1.3119999999999998,0},["width"]=2.8}
        local object75 = viewportScene2:point {["fill"]="#9b3600",["id"]="ray-hit-2-2",["layer"]=20,["opacity"]=0.45,["point"]={2.2,-1.3119999999999998,0},["radius"]=4.5}
        local object76 = viewportScene2:arrow {["from"]={-6,0,0},["id"]="ray-primary-2-3",["opacity"]=0.28,["stroke"]="#b8915a",["tip"]=8,["to"]={2.2,-1.3119999999999998,-1.3119999999999998},["width"]=2.8}
        local object77 = viewportScene2:point {["fill"]="#b8915a",["id"]="ray-hit-2-3",["layer"]=20,["opacity"]=0.45,["point"]={2.2,-1.3119999999999998,-1.3119999999999998},["radius"]=4.5}
        local object78 = viewportScene2:arrow {["from"]={-6,0,0},["id"]="ray-primary-2-4",["opacity"]=0.28,["stroke"]="#b8915a",["tip"]=8,["to"]={2.2,-1.3119999999999998,-2.6239999999999997},["width"]=2.8}
        local object79 = viewportScene2:point {["fill"]="#b8915a",["id"]="ray-hit-2-4",["layer"]=20,["opacity"]=0.45,["point"]={2.2,-1.3119999999999998,-2.6239999999999997},["radius"]=4.5}
        viewportScene2:play({{target=object56,opacity=0.92},{target=object58,opacity=0.92},{target=object60,opacity=0.92},{target=object61,opacity=0.92},{target=object62,opacity=0.92},{target=object57,opacity=1},{target=object59,opacity=1},{target=object2,stroke="#9b3600"},{target=object3,stroke="#9b3600"},{target=object4,stroke="#9b3600"},{target=object5,stroke="#9b3600"},{target=object6,stroke="#9b3600"}},0.45,"ease_in_out",0)
        viewportScene2:wait(0.25)
        viewportScene2:play({{target=object56,opacity=0.28},{target=object58,opacity=0.28},{target=object60,opacity=0.1},{target=object61,opacity=0.1},{target=object62,opacity=0.1},{target=object57,opacity=0.45},{target=object59,opacity=0.45},{target=object2,stroke="#d8dadd"},{target=object3,stroke="#d8dadd"},{target=object4,stroke="#d8dadd"},{target=object5,stroke="#d8dadd"},{target=object6,stroke="#d8dadd"}},0.35,"ease_in_out",0)
        viewportScene2:play({{target=object63,opacity=0.92},{target=object65,opacity=0.92},{target=object67,opacity=0.92},{target=object68,opacity=0.92},{target=object70,opacity=0.92},{target=object64,opacity=1},{target=object66,opacity=1},{target=object69,opacity=1},{target=object71,opacity=1},{target=object7,stroke="#9b3600"},{target=object8,stroke="#9b3600"},{target=object9,stroke="#9b3600"},{target=object10,stroke="#9b3600"},{target=object11,stroke="#9b3600"}},0.45,"ease_in_out",0)
        viewportScene2:wait(0.25)
        viewportScene2:play({{target=object63,opacity=0.28},{target=object65,opacity=0.28},{target=object67,opacity=0.1},{target=object68,opacity=0.28},{target=object70,opacity=0.28},{target=object64,opacity=0.45},{target=object66,opacity=0.45},{target=object69,opacity=0.45},{target=object71,opacity=0.45},{target=object7,stroke="#d8dadd"},{target=object8,stroke="#d8dadd"},{target=object9,stroke="#d8dadd"},{target=object10,stroke="#d8dadd"},{target=object11,stroke="#d8dadd"}},0.35,"ease_in_out",0)
        viewportScene2:play({{target=object72,opacity=0.92},{target=object73,opacity=0.92},{target=object74,opacity=0.92},{target=object76,opacity=0.92},{target=object78,opacity=0.92},{target=object75,opacity=1},{target=object77,opacity=1},{target=object79,opacity=1},{target=object12,stroke="#9b3600"},{target=object13,stroke="#9b3600"},{target=object14,stroke="#9b3600"},{target=object15,stroke="#9b3600"},{target=object16,stroke="#9b3600"}},0.45,"ease_in_out",0)
        viewportScene2:wait(0.25)
        viewportScene2:play({{target=object72,opacity=0.1},{target=object73,opacity=0.1},{target=object74,opacity=0.28},{target=object76,opacity=0.28},{target=object78,opacity=0.28},{target=object75,opacity=0.45},{target=object77,opacity=0.45},{target=object79,opacity=0.45},{target=object12,stroke="#d8dadd"},{target=object13,stroke="#d8dadd"},{target=object14,stroke="#d8dadd"},{target=object15,stroke="#d8dadd"},{target=object16,stroke="#d8dadd"}},0.35,"ease_in_out",0)
        viewportScene2:wait(0.65)
        viewportScene2:play({{target=object56,opacity=0.92},{target=object58,opacity=0.92},{target=object60,opacity=0.92},{target=object61,opacity=0.92},{target=object62,opacity=0.92},{target=object57,opacity=1},{target=object59,opacity=1},{target=object2,stroke="#9b3600"},{target=object3,stroke="#9b3600"},{target=object4,stroke="#9b3600"},{target=object5,stroke="#9b3600"},{target=object6,stroke="#9b3600"}},0.45,"ease_in_out",0)
        viewportScene2:wait(0.25)
        viewportScene2:play({{target=object56,opacity=0.28},{target=object58,opacity=0.28},{target=object60,opacity=0.1},{target=object61,opacity=0.1},{target=object62,opacity=0.1},{target=object57,opacity=0.45},{target=object59,opacity=0.45},{target=object2,stroke="#d8dadd"},{target=object3,stroke="#d8dadd"},{target=object4,stroke="#d8dadd"},{target=object5,stroke="#d8dadd"},{target=object6,stroke="#d8dadd"}},0.35,"ease_in_out",0)
        viewportScene2:play({{target=object63,opacity=0.92},{target=object65,opacity=0.92},{target=object67,opacity=0.92},{target=object68,opacity=0.92},{target=object70,opacity=0.92},{target=object64,opacity=1},{target=object66,opacity=1},{target=object69,opacity=1},{target=object71,opacity=1},{target=object7,stroke="#9b3600"},{target=object8,stroke="#9b3600"},{target=object9,stroke="#9b3600"},{target=object10,stroke="#9b3600"},{target=object11,stroke="#9b3600"}},0.45,"ease_in_out",0)
        viewportScene2:wait(0.25)
        viewportScene2:play({{target=object63,opacity=0.28},{target=object65,opacity=0.28},{target=object67,opacity=0.1},{target=object68,opacity=0.28},{target=object70,opacity=0.28},{target=object64,opacity=0.45},{target=object66,opacity=0.45},{target=object69,opacity=0.45},{target=object71,opacity=0.45},{target=object7,stroke="#d8dadd"},{target=object8,stroke="#d8dadd"},{target=object9,stroke="#d8dadd"},{target=object10,stroke="#d8dadd"},{target=object11,stroke="#d8dadd"}},0.35,"ease_in_out",0)
        viewportScene2:play({{target=object72,opacity=0.92},{target=object73,opacity=0.92},{target=object74,opacity=0.92},{target=object76,opacity=0.92},{target=object78,opacity=0.92},{target=object75,opacity=1},{target=object77,opacity=1},{target=object79,opacity=1},{target=object12,stroke="#9b3600"},{target=object13,stroke="#9b3600"},{target=object14,stroke="#9b3600"},{target=object15,stroke="#9b3600"},{target=object16,stroke="#9b3600"}},0.45,"ease_in_out",0)
        viewportScene2:wait(0.25)
        viewportScene2:play({{target=object72,opacity=0.1},{target=object73,opacity=0.1},{target=object74,opacity=0.28},{target=object76,opacity=0.28},{target=object78,opacity=0.28},{target=object75,opacity=0.45},{target=object77,opacity=0.45},{target=object79,opacity=0.45},{target=object12,stroke="#d8dadd"},{target=object13,stroke="#d8dadd"},{target=object14,stroke="#d8dadd"},{target=object15,stroke="#d8dadd"},{target=object16,stroke="#d8dadd"}},0.35,"ease_in_out",0)
        viewportScene2:wait(0.65)
        viewportScene2:wait(0.4)
        viewportScene1:viewport(viewportScene2,{["height"]=0.69,["width"]=0.2,["x"]=0.2,["y"]=0.13})
    end
    local object5 = viewportScene1:rectangle {["center"]={1.6682926829268292,-0.1},["corner"]=0.08,["fill"]="#5e7a9b0c",["id"]="diagram-zone-public",["layer"]=1,["size"]={1.3505226480836237,2.32},["stroke"]="#d8dadd",["width"]=1}
    local object6 = viewportScene1:rectangle {["center"]={4.488501742160278,-0.1},["corner"]=0.08,["fill"]="#b8915a0c",["id"]="diagram-zone-platform",["layer"]=1,["size"]={3.3365853658536584,2.32},["stroke"]="#d8dadd",["width"]=1}
    local object7 = viewportScene1:rectangle {["center"]={7.229268292682927,-0.1},["corner"]=0.08,["fill"]="#6e64790c",["id"]="diagram-zone-data",["layer"]=1,["size"]={1.3505226480836237,2.32},["stroke"]="#d8dadd",["width"]=1}
    local object8 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#5e7a9b",["font"]="Pretendard",["id"]="diagram-zone-label-0",["layer"]=40,["point"]={1.6682926829268292,1.23},["size"]=8.5,["text"]="PUBLIC"}
    local object9 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="diagram-zone-label-1",["layer"]=40,["point"]={3.5749128919860627,1.23},["size"]=8.5,["text"]="PLATFORM"}
    local object10 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="diagram-zone-label-2",["layer"]=40,["point"]={7.229268292682927,1.23},["size"]=8.5,["text"]="DATA"}
    local object11 = viewportScene1:group {["id"]="diagram-client"}
    local object12 = object11:rectangle {["center"]={1.6682926829268292,0.38},["corner"]=0.06,["fill"]="#ffffff",["id"]="diagram-client-body",["layer"]=10,["size"]={1.0168641114982577,0.68},["stroke"]="#d8dadd",["width"]=1.4}
    local object13 = object11:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="diagram-client-label",["layer"]=40,["point"]={1.6682926829268292,0.49},["size"]=9.2,["text"]="CLIENT"}
    local object14 = object11:text {["align"]={0.5,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="diagram-client-detail",["layer"]=40,["point"]={1.6682926829268292,0.25},["size"]=7.4,["text"]="web / mobile"}
    local object15 = viewportScene1:group {["id"]="diagram-edge"}
    local object16 = object15:rectangle {["center"]={3.5749128919860627,0.38},["corner"]=0.06,["fill"]="#ffffff",["id"]="diagram-edge-body",["layer"]=10,["size"]={1.0168641114982577,0.68},["stroke"]="#d8dadd",["width"]=1.4}
    local object17 = object15:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="diagram-edge-label",["layer"]=40,["point"]={3.5749128919860627,0.49},["size"]=9.2,["text"]="EDGE"}
    local object18 = object15:text {["align"]={0.5,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="diagram-edge-detail",["layer"]=40,["point"]={3.5749128919860627,0.25},["size"]=7.4,["text"]="TLS · routing"}
    local object19 = viewportScene1:group {["id"]="diagram-api"}
    local object20 = object19:rectangle {["center"]={5.402090592334495,0.38},["corner"]=0.06,["fill"]="#ffffff",["id"]="diagram-api-body",["layer"]=10,["size"]={1.0168641114982577,0.68},["stroke"]="#9b3600",["width"]=2}
    local object21 = object19:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="diagram-api-label",["layer"]=40,["point"]={5.402090592334495,0.49},["size"]=9.2,["text"]="API"}
    local object22 = object19:text {["align"]={0.5,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="diagram-api-detail",["layer"]=40,["point"]={5.402090592334495,0.25},["size"]=7.4,["text"]="auth · policy"}
    local object23 = viewportScene1:group {["id"]="diagram-cache"}
    local object24 = object23:rectangle {["center"]={7.229268292682927,0.38},["corner"]=0.06,["fill"]="#ffffff",["id"]="diagram-cache-body",["layer"]=10,["size"]={1.0168641114982577,0.68},["stroke"]="#d8dadd",["width"]=1.4}
    local object25 = object23:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="diagram-cache-label",["layer"]=40,["point"]={7.229268292682927,0.49},["size"]=9.2,["text"]="CACHE"}
    local object26 = object23:text {["align"]={0.5,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="diagram-cache-detail",["layer"]=40,["point"]={7.229268292682927,0.25},["size"]=7.4,["text"]="read-through"}
    local object27 = viewportScene1:group {["id"]="diagram-worker"}
    local object28 = object27:rectangle {["center"]={5.402090592334495,-0.66},["corner"]=0.06,["fill"]="#ffffff",["id"]="diagram-worker-body",["layer"]=10,["size"]={1.0168641114982577,0.68},["stroke"]="#d8dadd",["width"]=1.4}
    local object29 = object27:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="diagram-worker-label",["layer"]=40,["point"]={5.402090592334495,-0.55},["size"]=9.2,["text"]="WORKER"}
    local object30 = object27:text {["align"]={0.5,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="diagram-worker-detail",["layer"]=40,["point"]={5.402090592334495,-0.79},["size"]=7.4,["text"]="async jobs"}
    local object31 = viewportScene1:group {["id"]="diagram-store"}
    local object32 = object31:rectangle {["center"]={7.229268292682927,-0.66},["corner"]=0.06,["fill"]="#ffffff",["id"]="diagram-store-body",["layer"]=10,["size"]={1.0168641114982577,0.68},["stroke"]="#d8dadd",["width"]=1.4}
    local object33 = object31:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="diagram-store-label",["layer"]=40,["point"]={7.229268292682927,-0.55},["size"]=9.2,["text"]="STORE"}
    local object34 = object31:text {["align"]={0.5,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="diagram-store-detail",["layer"]=40,["point"]={7.229268292682927,-0.79},["size"]=7.4,["text"]="durable state"}
    local object35 = viewportScene1:path {["commands"]={{["to"]={2.176724738675958,0.38},["type"]="move"},{["to"]={3.066480836236934,0.38},["type"]="line"}},["fill"]="#00000000",["id"]="diagram-route-https",["layer"]=1,["samples"]=12,["stroke"]="#5e7a9b",["width"]=1.8}
    local object36 = viewportScene1:path {["commands"]={{["to"]={4.083344947735192,0.38},["type"]="move"},{["to"]={4.893658536585366,0.38},["type"]="line"}},["fill"]="#00000000",["id"]="diagram-route-json",["layer"]=1,["samples"]=12,["stroke"]="#5e7a9b",["width"]=1.8}
    local object37 = viewportScene1:path {["commands"]={{["to"]={5.9105226480836235,0.38},["type"]="move"},{["to"]={6.720836236933798,0.38},["type"]="line"}},["fill"]="#00000000",["id"]="diagram-route-get",["layer"]=1,["samples"]=12,["stroke"]="#5e7a9b",["width"]=1.8}
    local object38 = viewportScene1:path {["commands"]={{["to"]={5.402090592334495,0.03999999999999998},["type"]="move"},{["to"]={5.402090592334495,-0.32},["type"]="line"}},["fill"]="#00000000",["id"]="diagram-route-job",["layer"]=1,["samples"]=12,["stroke"]="#5e7a9b",["width"]=1.8}
    local object39 = viewportScene1:path {["commands"]={{["to"]={5.9105226480836235,-0.66},["type"]="move"},{["to"]={6.720836236933798,-0.66},["type"]="line"}},["fill"]="#00000000",["id"]="diagram-route-write",["layer"]=1,["samples"]=12,["stroke"]="#5e7a9b",["width"]=1.8}
    local object40 = viewportScene1:path {["commands"]={{["to"]={6.720836236933798,0.69},["type"]="move"},{["to"]={5.9105226480836235,0.69},["type"]="line"}},["dash"]={6,5},["fill"]="#00000000",["id"]="diagram-route-hit",["layer"]=1,["samples"]=12,["stroke"]="#6e6479",["width"]=1.8}
    local object41 = viewportScene1:polygon {["fill"]="#5e7a9b",["id"]="diagram-head-https",["layer"]=2,["points"]={{3.066480836236934,0.38},{2.976480836236934,0.4295},{2.976480836236934,0.3305}},["stroke"]="#5e7a9b",["width"]=1}
    local object42 = viewportScene1:polygon {["fill"]="#5e7a9b",["id"]="diagram-head-json",["layer"]=2,["points"]={{4.893658536585366,0.38},{4.803658536585366,0.4295},{4.803658536585366,0.3305}},["stroke"]="#5e7a9b",["width"]=1}
    local object43 = viewportScene1:polygon {["fill"]="#5e7a9b",["id"]="diagram-head-get",["layer"]=2,["points"]={{6.720836236933798,0.38},{6.630836236933798,0.4295},{6.630836236933798,0.3305}},["stroke"]="#5e7a9b",["width"]=1}
    local object44 = viewportScene1:polygon {["fill"]="#5e7a9b",["id"]="diagram-head-job",["layer"]=2,["points"]={{5.402090592334495,-0.32},{5.3525905923344945,-0.23},{5.451590592334495,-0.23}},["stroke"]="#5e7a9b",["width"]=1}
    local object45 = viewportScene1:polygon {["fill"]="#5e7a9b",["id"]="diagram-head-write",["layer"]=2,["points"]={{6.720836236933798,-0.66},{6.630836236933798,-0.6105},{6.630836236933798,-0.7095}},["stroke"]="#5e7a9b",["width"]=1}
    local object46 = viewportScene1:polygon {["fill"]="#6e6479",["id"]="diagram-head-hit",["layer"]=2,["points"]={{5.9105226480836235,0.69},{6.000522648083623,0.7394999999999999},{6.000522648083623,0.6405}},["stroke"]="#6e6479",["width"]=1}
    local object47 = viewportScene1:rectangle {["center"]={2.621602787456446,0.61},["corner"]=0.04,["fill"]="#ffffff",["id"]="diagram-route-mask-0",["layer"]=39,["size"]={0.5402090592334495,0.24},["stroke"]="#00000000"}
    local object48 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="diagram-route-label-0",["layer"]=40,["point"]={2.621602787456446,0.61},["role"]="code",["size"]=7.5,["text"]="HTTPS"}
    local object49 = viewportScene1:rectangle {["center"]={4.488501742160278,0.15},["corner"]=0.04,["fill"]="#ffffff",["id"]="diagram-route-mask-1",["layer"]=39,["size"]={0.5402090592334495,0.24},["stroke"]="#00000000"}
    local object50 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="diagram-route-label-1",["layer"]=40,["point"]={4.488501742160278,0.15},["role"]="code",["size"]=7.5,["text"]="JSON"}
    local object51 = viewportScene1:rectangle {["center"]={6.315679442508711,0.61},["corner"]=0.04,["fill"]="#ffffff",["id"]="diagram-route-mask-2",["layer"]=39,["size"]={0.5402090592334495,0.24},["stroke"]="#00000000"}
    local object52 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="diagram-route-label-2",["layer"]=40,["point"]={6.315679442508711,0.61},["role"]="code",["size"]=7.5,["text"]="GET"}
    local object53 = viewportScene1:rectangle {["center"]={5.799303135888501,-0.14},["corner"]=0.04,["fill"]="#ffffff",["id"]="diagram-route-mask-3",["layer"]=39,["size"]={0.5402090592334495,0.24},["stroke"]="#00000000"}
    local object54 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="diagram-route-label-3",["layer"]=40,["point"]={5.799303135888501,-0.14},["role"]="code",["size"]=7.5,["text"]="JOB"}
    local object55 = viewportScene1:rectangle {["center"]={6.315679442508711,-0.43000000000000005},["corner"]=0.04,["fill"]="#ffffff",["id"]="diagram-route-mask-4",["layer"]=39,["size"]={0.5402090592334495,0.24},["stroke"]="#00000000"}
    local object56 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="diagram-route-label-4",["layer"]=40,["point"]={6.315679442508711,-0.43000000000000005},["role"]="code",["size"]=7.5,["text"]="WRITE"}
    local object57 = viewportScene1:rectangle {["center"]={6.315679442508711,0.91},["corner"]=0.04,["fill"]="#ffffff",["id"]="diagram-route-mask-5",["layer"]=39,["size"]={0.5402090592334495,0.24},["stroke"]="#00000000"}
    local object58 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#6e6479",["font"]="Pretendard",["id"]="diagram-route-label-5",["layer"]=40,["point"]={6.315679442508711,0.91},["role"]="code",["size"]=7.5,["text"]="HIT"}
    local object59 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="diagram-legend",["layer"]=40,["point"]={4.925435540069686,-1.38},["size"]=7.8,["text"]="solid request  ·  dashed cached response"}
    scene:viewport(viewportScene1,{["height"]=0.0956666666666667,["width"]=0.9500000000000001,["x"]=0.024999999999999984,["y"]=0.825})
end
local object78 = scene:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="demo-caption-1",["layer"]=40,["point"]={-5.7,-12.870000000000001},["size"]=12.5,["text"]="Primary rays map intersections into pixels; Groups, Paths, and labels expose system boundaries."}
local object79 = scene:text {["align"]={0,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="demo-caption-2",["layer"]=40,["point"]={-5.7,-13.110000000000001},["size"]=12.5,["text"]="Ray rows replay sample-to-pixel correspondence while the architecture remains stable for inspection."}
local object80 = scene:line {["from"]={-5.7,-13.65},["id"]="footer-rule",["stroke"]="#202124",["to"]={5.7,-13.65},["width"]=1.2}
local object81 = scene:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="footer-summary",["layer"]=40,["point"]={-5.7,-14},["size"]=12.5,["text"]="SceneBuilder records objects, camera state, and timeline operations."}
local object82 = scene:text {["align"]={1,0.5},["fill"]="#555b64",["font"]="Pretendard",["id"]="footer-note",["layer"]=40,["point"]={5.7,-14},["size"]=10.5,["text"]="TMathScene renders frames and exposes assets, bounds, resize, and camera controls."}
scene:play({{target=object7,shift={0,0.35}},{target=object10,shift={0,0.35}},{target=object13,shift={0,0.35}}},1.15,"ease_in_out",0)
scene:wait(0.75)
scene:play({{target=object7,shift={0,-0.35}},{target=object10,shift={0,-0.35}},{target=object13,shift={0,-0.35}}},1.15,"ease_in_out",0)
scene:wait(0.75)
scene:play({{target=object7,shift={0,0.35}},{target=object10,shift={0,0.35}},{target=object13,shift={0,0.35}}},1.15,"ease_in_out",0)
scene:wait(0.75)
scene:play({{target=object7,shift={0,-0.35}},{target=object10,shift={0,-0.35}},{target=object13,shift={0,-0.35}}},1.15,"ease_in_out",0)
scene:wait(0.75)
scene:wait(0.4)
return scene
`,
        js: `// Browser-editable tmath API cheatsheet for the WASM playground.
const WIDTH = 1200;
const HEIGHT = 3000;
const FPS = 30;
const DURATION = 8;
const THEME = "pro_white";

const ROOT_CAMERA_HEIGHT = HEIGHT / 100;
const ROOT_CAMERA_WIDTH = WIDTH / 100;
const ROOT_HALF_WIDTH = ROOT_CAMERA_WIDTH / 2;
const ROOT_HALF_HEIGHT = ROOT_CAMERA_HEIGHT / 2;
const CONTENT_LEFT = -5.7;
const CONTENT_RIGHT = 5.7;

const P = {
    paper: "#ffffff",
    ink: "#202124",
    muted: "#555b64",
    rule: "#d8dadd",
    accent: "#9b3600",
    blue: "#5e7a9b",
    mustard: "#b8915a",
    purple: "#6e6479",
    orange: "#f28e2b",
};

const L = {guide: 1, object: 10, accent: 20, text: 40};
const TEXT_IDS = [];
const TEXT_CONTENTS = [];
const GAP_PAIRS = [];

function addText(scene, options, registry = null) {
    if (registry) registry.push(options.id);
    else {
        TEXT_IDS.push(options.id);
        TEXT_CONTENTS.push(options.text);
    }
    return scene.text({font: "Pretendard", layer: L.text, ...options});
}

function pair(first, second, gap = 6) {
    GAP_PAIRS.push([first, second, gap]);
}

function scene2d(width, height, cameraHeight = 4) {
    return tmath.scene({
        width,
        height,
        fps: FPS,
        theme: THEME,
        camera: {mode: "fixed", view: "2d", target: [0, 0], height: cameraHeight},
    });
}

function worldWidth(width, height, cameraHeight) {
    return cameraHeight * width / height;
}

function twoCycles(scene, authorCycle) {
    authorCycle();
    authorCycle();
    scene.wait(0.4);
}

function buildSceneModule(width, height) {
    const cameraHeight = 4;
    const scene = scene2d(width, height, cameraHeight);
    const w = worldWidth(width, height, cameraHeight);
    const textIds = [];
    const code = [
        '1  const scene = tmath.scene({ width, height, theme: "pro_white" });',
        '2  const space = scene.space({ x, y, z });',
        '3  const mark = space.vector({ origin, value });',
        '4  scene.play([{ target: mark, shift }], 0.8);',
        '5  scene.look({ view: "3d", eye, target }, 1.2);',
        '6  scene.text({ text, point, role });',
        '7  scene.surface({ points, size, mode: "solid_mesh" });',
    ];
    const codeX = -0.47 * w;
    const dividerX = -0.10 * w;
    const graphCenter = 0.20 * w;
    const graphGap = Math.min(4.2, Math.max(2.9, 0.185 * w));
    const graphX = {left: graphCenter - graphGap, middle: graphCenter, right: graphCenter + graphGap};
    const y0 = 1.42;
    const step = 0.47;
    scene.line({from: [dividerX, 1.72], to: [dividerX, -1.68], stroke: P.rule, width: 1, id: "scene-code-divider"});
    code.forEach((line, index) => {
        const y = y0 - index * step;
        addText(scene, {
            text: line, point: [codeX, y], align: [0, 0.5], role: "code",
            size: 9.4, fill: index === 0 ? P.accent : P.ink, id: \`scene-code-\${index + 1}\`,
        }, textIds);
    });

    const graph = scene.group({id: "scene-graph"});
    const nodes = [
        {line: 1, label: "SCENE", center: [graphX.middle, 1.35], color: P.accent},
        {line: 2, label: "SPACE", center: [graphX.left, 0.28], color: P.blue},
        {line: 6, label: "TEXT", center: [graphX.middle, 0.28], color: P.purple},
        {line: 7, label: "SURFACE", center: [graphX.right, 0.28], color: P.mustard},
        {line: 3, label: "VECTOR", center: [graphX.left, -1.02], color: P.blue},
        {line: 5, label: "CAMERA", center: [graphX.middle, -1.02], color: P.purple},
        {line: 4, label: "TIMELINE", center: [graphX.right, -1.02], color: P.accent},
    ];
    const byLine = new Map(nodes.map((node) => [node.line, node]));
    const edge = (from, to, id) => graph.line({
        from, to, stroke: P.rule, width: 1.5, layer: L.guide, id,
    });
    edge([graphX.middle, 1.08], [graphX.left, 0.55], "scene-edge-space");
    edge([graphX.middle, 1.08], [graphX.middle, 0.55], "scene-edge-text");
    edge([graphX.middle, 1.08], [graphX.right, 0.55], "scene-edge-surface");
    edge([graphX.left, 0.01], [graphX.left, -0.75], "scene-edge-vector");
    nodes.forEach((node) => {
        graph.rectangle({
            center: node.center, size: [2.65, 0.54], corner: 0.035,
            fill: P.paper, stroke: node.color, width: node.line === 1 ? 2.2 : 1.5,
            layer: L.object, id: \`scene-node-\${node.line}\`,
        });
        addText(graph, {
            text: \`L\${node.line}  \${node.label}\`, point: node.center, align: [0.5, 0.5],
            role: "code", size: 8.5, fill: node.color, id: \`scene-node-label-\${node.line}\`,
        }, textIds);
    });
    addText(scene, {
        text: "OBJECT OWNERSHIP", point: [graphX.left - 1.55, 1.70], align: [0, 0.5],
        size: 9.5, fill: P.muted, id: "scene-graph-label",
    }, textIds);
    scene.line({from: [graphX.middle - 1.55, -0.60], to: [graphX.right + 1.55, -0.60], stroke: P.rule, width: 1, id: "scene-state-rule"});
    addText(scene, {
        text: "SCENE STATE", point: [graphX.middle - 1.55, -0.48], align: [0, 0.5],
        size: 8.5, fill: P.muted, id: "scene-state-label",
    }, textIds);

    const tokenStart = (line) => [dividerX - 0.25, y0 - (line - 1) * step];
    const makeToken = (line) => {
        const node = byLine.get(line);
        const handle = scene.point({
            point: tokenStart(line), radius: 4.5, fill: node.color, stroke: P.paper,
            width: 1.5, opacity: 0, layer: L.accent, id: \`scene-registration-token-\${line}\`,
        });
        return {line, handle};
    };
    const rootToken = makeToken(1);
    const childTokens = [2, 3, 4, 5, 6, 7].map(makeToken);
    const allTokens = [rootToken, ...childTokens];
    const shifts = (tokens) => tokens.map(({line, handle}) => {
        const start = tokenStart(line);
        const nodeCenter = byLine.get(line).center;
        const target = [nodeCenter[0] - 1.50, nodeCenter[1]];
        return {target: handle, shift: [target[0] - start[0], target[1] - start[1]]};
    });
    twoCycles(scene, () => {
        scene.play({target: rootToken.handle, opacity: 1}, 0.12, "gentle", 0)
            .play(shifts([rootToken]), 0.85, "gentle", 0)
            .play(childTokens.map(({handle}) => ({target: handle, opacity: 1})), 0.12, "gentle", 0)
            .play(shifts(childTokens), 0.90, "gentle", 0)
            .wait(0.45)
            .play(allTokens.map(({handle}) => ({target: handle, opacity: 0})), 0.25, "gentle", 0)
            .play(shifts(allTokens).map((spec) => ({target: spec.target, shift: [-spec.shift[0], -spec.shift[1]]})), 0.45, "gentle", 0)
            .wait(0.66);
    });
    return {definition: scene, textIds, peakTime: 2.10};
}

function buildObjectModule(width, height) {
    const cameraHeight = 4;
    const scene = scene2d(width, height, cameraHeight);
    const textIds = [];
    addText(scene, {text: "A  ·  PARENT TRANSFORM", point: [-5.25, 1.62], align: [0, 0.5], size: 10, fill: P.accent, id: "object-group-label"}, textIds);
    addText(scene, {text: "B  ·  BOUNDS CONNECTOR", point: [0.38, 1.62], align: [0, 0.5], size: 10, fill: P.accent, id: "object-connector-label"}, textIds);
    scene.line({from: [0, 1.72], to: [0, -1.65], stroke: P.rule, width: 1, id: "object-divider"});

    const movingGroup = scene.group({id: "object-moving-group"});
    movingGroup.rectangle({center: [-3.15, 0.15], size: [4.20, 1.55], corner: 0.06, fill: "#00000000", stroke: P.rule, width: 1.3, dash: [5, 4], id: "object-moving-group-boundary"});
    addText(movingGroup, {text: "group", point: [-5.02, 0.69], align: [0, 0.5], role: "code", size: 9, fill: P.muted, id: "object-moving-group-name"}, textIds);
    const movingA = movingGroup.circle({center: [-4.15, 0.08], radius: 0.36, fill: \`\${P.blue}22\`, stroke: P.blue, width: 2.2, id: "object-moving-a"});
    const movingB = movingGroup.rectangle({center: [-2.15, 0.08], size: [0.78, 0.64], corner: 0.05, fill: \`\${P.mustard}22\`, stroke: P.mustard, width: 2.2, id: "object-moving-b"});
    movingGroup.connector(movingA, movingB, {padding: 0.12, stroke: P.ink, width: 1.8, id: "object-moving-edge"});
    addText(movingGroup, {text: "a", point: [-4.15, 0.08], align: [0.5, 0.5], role: "code", size: 10, fill: P.blue, id: "object-moving-a-label"}, textIds);
    addText(movingGroup, {text: "b", point: [-2.15, 0.08], align: [0.5, 0.5], role: "code", size: 10, fill: P.mustard, id: "object-moving-b-label"}, textIds);
    scene.line({from: [-3.15, -1.22], to: [-2.43, -1.22], stroke: P.rule, width: 1.4, id: "object-group-shift-guide"});
    scene.line({from: [-3.15, -1.34], to: [-3.15, -1.10], stroke: P.muted, width: 1.2, id: "object-group-shift-start"});
    scene.line({from: [-2.43, -1.34], to: [-2.43, -1.10], stroke: P.muted, width: 1.2, id: "object-group-shift-end"});
    addText(scene, {text: "group.x", point: [-2.79, -1.48], align: [0.5, 0.5], role: "code", size: 9, fill: P.muted, id: "object-group-shift-label"}, textIds);

    const boundsGroup = scene.group({id: "object-bounds-group"});
    const boundsBoundary = scene.rectangle({center: [2.80, 0.15], size: [4.70, 1.55], corner: 0.06, fill: "#00000000", stroke: P.rule, width: 1.3, dash: [5, 4], id: "object-bounds-group-boundary"});
    addText(boundsGroup, {text: "group", point: [0.68, 0.69], align: [0, 0.5], role: "code", size: 9, fill: P.muted, id: "object-bounds-group-name"}, textIds);
    const boundsA = boundsGroup.circle({center: [1.55, 0.08], radius: 0.36, fill: \`\${P.blue}22\`, stroke: P.blue, width: 2.2, id: "object-bounds-a"});
    const boundsB = boundsGroup.rectangle({center: [3.80, 0.08], size: [0.78, 0.64], corner: 0.05, fill: \`\${P.mustard}22\`, stroke: P.mustard, width: 2.2, id: "object-bounds-b"});
    boundsGroup.connector(boundsA, boundsB, {padding: 0.12, stroke: P.ink, width: 1.8, id: "object-bounds-edge"});
    addText(boundsGroup, {text: "a", point: [1.55, 0.08], align: [0.5, 0.5], role: "code", size: 10, fill: P.blue, id: "object-bounds-a-label"}, textIds);
    const boundsBLabel = addText(boundsGroup, {text: "b", point: [3.80, 0.08], align: [0.5, 0.5], role: "code", size: 10, fill: P.mustard, id: "object-bounds-b-label"}, textIds);
    scene.line({from: [3.80, -1.22], to: [4.52, -1.22], stroke: P.rule, width: 1.4, id: "object-bounds-shift-guide"});
    scene.line({from: [3.80, -1.34], to: [3.80, -1.10], stroke: P.muted, width: 1.2, id: "object-bounds-shift-start"});
    scene.line({from: [4.52, -1.34], to: [4.52, -1.10], stroke: P.muted, width: 1.2, id: "object-bounds-shift-end"});
    addText(scene, {text: "b bounds", point: [4.16, -1.48], align: [0.5, 0.5], role: "code", size: 9, fill: P.muted, id: "object-bounds-shift-label"}, textIds);

    const shift = 0.72;
    const boundaryScale = (4.70 + shift) / 4.70;
    const expandedBoundary = [boundaryScale, 0, 0, 0.45 * (1 - boundaryScale), 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
    const identity = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
    twoCycles(scene, () => {
        scene.play([
            {target: movingGroup, shift: [shift, 0]},
            {target: boundsB, shift: [shift, 0]},
            {target: boundsBLabel, shift: [shift, 0]},
            {target: boundsBoundary, transform: expandedBoundary},
        ], 1.15, "ease_in_out", 0)
            .wait(0.75)
            .play([
                {target: movingGroup, shift: [-shift, 0]},
                {target: boundsB, shift: [-shift, 0]},
                {target: boundsBLabel, shift: [-shift, 0]},
                {target: boundsBoundary, transform: identity},
            ], 1.15, "ease_in_out", 0)
            .wait(0.75);
    });
    return {definition: scene, textIds, peakTime: 1.30};
}

function buildAnimateModule(width, height) {
    const cameraHeight = 4.6;
    const scene = scene2d(width, height, cameraHeight);
    const w = worldWidth(width, height, cameraHeight);
    const textIds = [];
    const x0 = -0.31 * w;
    const distance = 0.67 * w;
    const ys = [0.72, 0, -0.72];
    addText(scene, {text: "ONE PLAY CALL", point: [-0.46 * w, 1.82], align: [0, 0.5], size: 10, fill: P.accent, id: "animate-window-label"}, textIds);
    addText(scene, {text: "t = 0", point: [x0, 1.42], align: [0, 0.5], role: "code", size: 10, fill: P.muted, id: "animate-start-label"}, textIds);
    addText(scene, {text: "t = duration", point: [x0 + distance, 1.42], align: [1, 0.5], role: "code", size: 10, fill: P.accent, id: "animate-end-label"}, textIds);
    ys.forEach((y, index) => {
        addText(scene, {text: \`target \${String.fromCharCode(97 + index)}\`, point: [-0.46 * w, y], align: [0, 0.5], role: "code", size: 10, fill: P.muted, id: \`animate-target-label-\${index}\`}, textIds);
        scene.line({from: [x0, y], to: [x0 + distance, y], stroke: P.rule, width: 2, id: \`animate-track-\${index}\`});
        scene.point({point: [x0 + distance, y], radius: 3, fill: P.muted, stroke: P.muted});
    });
    const runners = [
        scene.circle({center: [x0, ys[0]], radius: 0.24, fill: P.ink, stroke: P.ink, id: "animate-circle"}),
        scene.rectangle({center: [x0, ys[1]], size: [0.48, 0.48], corner: 0.05, fill: P.ink, stroke: P.ink, id: "animate-square"}),
        scene.point({point: [x0, ys[2]], radius: 8, fill: P.ink, stroke: P.ink, id: "animate-dot"}),
    ];
    const colors = [P.blue, P.mustard, P.accent];
    twoCycles(scene, () => {
        scene.play(runners.map((target, index) => ({target, shift: [distance, 0], fill: colors[index], stroke: colors[index]})), 1.2, "ease_in_out", 0)
            .wait(0.7)
            .play(runners.map((target) => ({target, shift: [-distance, 0], fill: P.ink, stroke: P.ink})), 1.2, "ease_in_out", 0)
            .wait(0.7);
    });
    return {definition: scene, textIds, peakTime: 1.25};
}

function buildThemePreview(width, height, theme, accent) {
    const scene = tmath.scene({
        width, height, fps: FPS, theme,
        camera: {mode: "fixed", view: "2d", target: [0, 0], height: 3.2},
    });
    const w = worldWidth(width, height, 3.2);
    const block = scene.rectangle({center: [-0.18 * w, 0.15], size: [0.55 * w, 1.25], corner: 0.06, id: \`\${theme}-block\`});
    const circle = scene.circle({center: [0.24 * w, 0.15], radius: 0.46, id: \`\${theme}-circle\`});
    const sample = scene.vector({value: [0.52 * w, 0.55], origin: [-0.28 * w, -1.12], stroke: accent, width: 2.4, tip: 9, id: \`\${theme}-vector\`});
    twoCycles(scene, () => {
        scene.indicate(block, {color: accent, scale: 1.035, duration: 0.5})
            .shift(sample, [0.28 * w, 0], 0.9, "ease_in_out")
            .indicate(circle, {color: accent, scale: 1.12, duration: 0.5})
            .shift(sample, [-0.28 * w, 0], 0.9, "ease_in_out")
            .wait(1.0);
    });
    return scene;
}

function authorThemeFigure(container, timeline, w, textIds = null, authorMotion = true) {
    const labels = ["DEFAULT", "PRO WHITE", "PRO BLACK"];
    const accents = [P.orange, P.accent, P.blue];
    const backgrounds = ["#10161f", P.paper, "#050608"];
    const foregrounds = ["#f4f7fb", P.ink, "#f4f7fb"];
    const centers = [-0.335, 0, 0.335].map((value) => value * w);
    const blocks = [];
    centers.forEach((x, index) => {
        container.rectangle({center: [x, 0], size: [0.29 * w, 2.75], corner: 0.06, fill: backgrounds[index], stroke: P.rule, width: 1, id: \`theme-panel-\${index}\`});
        blocks.push(container.rectangle({center: [x - 0.045 * w, 0.15], size: [0.12 * w, 1.05], corner: 0.05, fill: foregrounds[index], stroke: accents[index], width: 1.8, id: \`theme-block-\${index}\`}));
        container.circle({center: [x + 0.075 * w, 0.15], radius: 0.38, fill: \`\${accents[index]}55\`, stroke: accents[index], width: 2, id: \`theme-circle-\${index}\`});
    });
    labels.forEach((label, index) => addText(container, {
        text: label, point: [(-0.335 + index * 0.335) * w, 1.62],
        align: [0.5, 0.5], size: 12, fill: index === 1 ? P.accent : P.muted, id: \`theme-label-\${index}\`,
    }, textIds));
    const motion = () => twoCycles(timeline, () => {
        timeline.play(blocks.map((target) => ({target, shift: [0, 0.35]})), 1.15, "ease_in_out", 0).wait(0.75)
            .play(blocks.map((target) => ({target, shift: [0, -0.35]})), 1.15, "ease_in_out", 0).wait(0.75);
    });
    if (authorMotion) motion();
    return motion;
}

function buildThemeModule(width, height) {
    const cameraHeight = 4;
    const scene = scene2d(width, height, cameraHeight);
    const textIds = [];
    authorThemeFigure(scene, scene, worldWidth(width, height, cameraHeight), textIds);
    return {definition: scene, textIds, peakTime: 1.0};
}

function buildTextModule(width, height) {
    const cameraHeight = 4;
    const scene = scene2d(width, height, cameraHeight);
    const textIds = [];
    const w = worldWidth(width, height, cameraHeight);
    addText(scene, {text: "ROLE INPUT", point: [-0.43 * w, 1.62], align: [0, 0.5], size: 10, fill: P.muted, id: "text-role-label"}, textIds);
    addText(scene, {text: "RENDERED TEXT", point: [0.06 * w, 1.62], align: [0, 0.5], size: 10, fill: P.accent, id: "text-render-label"}, textIds);
    const ys = [0.92, 0.0, -0.92];
    const roleNames = ['role: "h1"', 'role: "text"', 'role: "code"'];
    const colors = [P.blue, P.mustard, P.accent];
    roleNames.forEach((role, index) => {
        addText(scene, {text: role, point: [-0.43 * w, ys[index]], align: [0, 0.5], role: "code", size: 11, fill: colors[index], id: \`text-role-\${index}\`}, textIds);
        scene.line({from: [-0.10 * w, ys[index]], to: [0.01 * w, ys[index]], stroke: P.rule, width: 1.5, id: \`text-role-arrow-\${index}\`});
        scene.point({point: [0.01 * w, ys[index]], radius: 3, fill: colors[index], stroke: colors[index], id: \`text-role-end-\${index}\`});
    });
    const heading = addText(scene, {text: "Heading", point: [0.07 * w, ys[0]], align: [0, 0.5], role: "h1", size: 24, fill: P.ink, id: "text-heading"}, textIds);
    const body = addText(scene, {text: "Body annotation", point: [0.07 * w, ys[1]], align: [0, 0.5], role: "text", size: 16, fill: P.ink, id: "text-body"}, textIds);
    const code = addText(scene, {text: "f(x) = sin(x)", point: [0.07 * w, ys[2]], align: [0, 0.5], role: "code", size: 16, fill: P.ink, id: "text-code"}, textIds);
    const outputs = [heading, body, code];
    const tokens = ys.map((y, index) => scene.point({
        point: [-0.10 * w, y], radius: 4.5, fill: colors[index], stroke: P.paper,
        width: 1.5, opacity: 0, layer: L.accent, id: \`text-role-token-\${index}\`,
    }));
    const distance = 0.11 * w;
    twoCycles(scene, () => {
        scene.play(tokens.map((target) => ({target, opacity: 1})), 0.20, "gentle", 0)
            .play(tokens.map((target) => ({target, shift: [distance, 0]})), 1.10, "gentle", 0)
            .wait(0.50)
            .play(outputs.map((target, index) => ({target, fill: colors[index]})), 0.45, "gentle", 0)
            .play(outputs.map((target) => ({target, fill: P.ink})), 0.45, "gentle", 0)
            .play(tokens.map((target) => ({target, opacity: 0})), 0.25, "gentle", 0)
            .play(tokens.map((target) => ({target, shift: [-distance, 0]})), 0.35, "gentle", 0)
            .wait(0.50);
    });
    return {definition: scene, textIds, peakTime: 1.70};
}

function curveValue(name, t, strength = 1) {
    let value = t;
    if (name === "gentle") value = t * t * t * (t * (t * 6 - 15) + 10);
    if (name === "back") {
        const c1 = 1.70158;
        const c3 = c1 + 1;
        value = 1 + c3 * (t - 1) ** 3 + c1 * (t - 1) ** 2;
    }
    if (name === "bounce") {
        const n1 = 7.5625;
        const d1 = 2.75;
        if (t < 1 / d1) value = n1 * t * t;
        else if (t < 2 / d1) { const u = t - 1.5 / d1; value = n1 * u * u + 0.75; }
        else if (t < 2.5 / d1) { const u = t - 2.25 / d1; value = n1 * u * u + 0.9375; }
        else { const u = t - 2.625 / d1; value = n1 * u * u + 0.984375; }
    }
    if (name === "elastic" && t > 0 && t < 1) value = 2 ** (-10 * t) * Math.sin((10 * t - 0.75) * 2 * Math.PI / 3) + 1;
    return t + (value - t) * strength;
}

function buildCurveLane(width, height, spec, index) {
    const cameraHeight = 1.4;
    const scene = scene2d(width, height, cameraHeight);
    const w = worldWidth(width, height, cameraHeight);
    const x = (value) => value / 7 * w;
    scene.text({text: spec.label, point: [x(-3.18), 0], align: [0, 0.5], role: "code", font: "Pretendard", size: 13, fill: P.ink, layer: L.text, id: \`curve-lane-label-\${index}\`});
    const trackX0 = x(-1.72);
    const trackX1 = x(0.18);
    scene.line({from: [trackX0, 0], to: [trackX1, 0], stroke: P.rule, width: 2, id: \`curve-track-\${index}\`});
    scene.line({from: [trackX0, -0.12], to: [trackX0, 0.12], stroke: P.ink, width: 2, id: \`curve-start-\${index}\`});
    scene.line({from: [trackX1, -0.12], to: [trackX1, 0.12], stroke: P.accent, width: 2, id: \`curve-stop-\${index}\`});
    const graphX0 = x(0.82);
    const graphX1 = x(2.72);
    const graphBottom = -0.43;
    const graphTop = 0.43;
    const yMin = -0.15;
    const yMax = 1.15;
    const zeroY = graphBottom + (0 - yMin) / (yMax - yMin) * (graphTop - graphBottom);
    scene.line({from: [graphX0, zeroY], to: [graphX1, zeroY], stroke: P.rule, width: 1, id: \`curve-axis-x-\${index}\`});
    scene.line({from: [graphX0, graphBottom], to: [graphX0, graphTop], stroke: P.rule, width: 1, id: \`curve-axis-y-\${index}\`});
    scene.line({from: [graphX1, graphBottom], to: [graphX1, graphTop], stroke: P.rule, width: 1, id: \`curve-axis-r-\${index}\`});
    const points = [];
    for (let sample = 0; sample <= 60; sample += 1) {
        const t = sample / 60;
        points.push([
            graphX0 + (graphX1 - graphX0) * t,
            graphBottom + (curveValue(spec.name, t, spec.strength) - yMin) / (yMax - yMin) * (graphTop - graphBottom),
        ]);
    }
    scene.plot({points, stroke: P.accent, width: 1.6, id: \`curve-plot-\${index}\`});
    const runner = scene.point({point: [trackX0, 0], radius: 6, fill: P.accent, id: \`curve-runner-\${index}\`});
    const distance = trackX1 - trackX0;
    const curve = tmath.animCurve.preset(spec.name, spec.strength);
    scene.shift(runner, [distance, 0], 1.9, curve)
        .shift(runner, [-distance, 0], 1.9, tmath.animCurve.reverse(curve))
        .shift(runner, [distance, 0], 1.9, curve)
        .shift(runner, [-distance, 0], 1.9, tmath.animCurve.reverse(curve))
        .wait(0.4);
    return scene;
}

function buildCurveModule(width, height) {
    const cameraHeight = 4;
    const scene = scene2d(width, height, cameraHeight);
    const textIds = [];
    const w = worldWidth(width, height, cameraHeight);
    const specs = [
        {name: "back", label: "BACK  ·  0.65", strength: 0.65},
        {name: "elastic", label: "ELASTIC  ·  0.55", strength: 0.55},
        {name: "bounce", label: "BOUNCE  ·  0.80", strength: 0.8},
    ];
    const direct = specs[0];
    const laneY = 4 / 3;
    const sourceX = (value) => value / 7 * w;
    addText(scene, {text: direct.label, point: [sourceX(-3.18), laneY], align: [0, 0.5], role: "code", size: 13, fill: P.ink, id: "curve-lane-label-0"}, textIds);
    const trackX0 = sourceX(-1.72);
    const trackX1 = sourceX(0.18);
    scene.line({from: [trackX0, laneY], to: [trackX1, laneY], stroke: P.rule, width: 2, id: "curve-track-0"});
    scene.line({from: [trackX0, laneY - 0.11], to: [trackX0, laneY + 0.11], stroke: P.ink, width: 2, id: "curve-start-0"});
    scene.line({from: [trackX1, laneY - 0.11], to: [trackX1, laneY + 0.11], stroke: P.accent, width: 2, id: "curve-stop-0"});
    const graphX0 = sourceX(0.82);
    const graphX1 = sourceX(2.72);
    const graphBottom = laneY - 0.41;
    const graphTop = laneY + 0.41;
    const yMin = -0.15;
    const yMax = 1.15;
    const zeroY = graphBottom + (0 - yMin) / (yMax - yMin) * (graphTop - graphBottom);
    scene.line({from: [graphX0, zeroY], to: [graphX1, zeroY], stroke: P.rule, width: 1, id: "curve-axis-x-0"});
    scene.line({from: [graphX0, graphBottom], to: [graphX0, graphTop], stroke: P.rule, width: 1, id: "curve-axis-y-0"});
    scene.line({from: [graphX1, graphBottom], to: [graphX1, graphTop], stroke: P.rule, width: 1, id: "curve-axis-r-0"});
    const graphPoints = [];
    for (let sample = 0; sample <= 60; sample += 1) {
        const t = sample / 60;
        graphPoints.push([
            graphX0 + (graphX1 - graphX0) * t,
            graphBottom + (curveValue(direct.name, t, direct.strength) - yMin) / (yMax - yMin) * (graphTop - graphBottom),
        ]);
    }
    scene.plot({points: graphPoints, stroke: P.accent, width: 1.6, id: "curve-plot-0"});
    const runner = scene.point({point: [trackX0, laneY], radius: 6, fill: P.accent, id: "curve-runner-0"});
    const distance = trackX1 - trackX0;
    const curve = tmath.animCurve.preset(direct.name, direct.strength);
    scene.shift(runner, [distance, 0], 1.9, curve)
        .shift(runner, [-distance, 0], 1.9, tmath.animCurve.reverse(curve))
        .shift(runner, [distance, 0], 1.9, curve)
        .shift(runner, [-distance, 0], 1.9, tmath.animCurve.reverse(curve))
        .wait(0.4);
    specs.slice(1).forEach((spec, index) => {
        scene.viewport(buildCurveLane(width, Math.max(1, Math.round(height / 3)), spec, index + 1), {x: 0, y: (index + 1) / 3, width: 1, height: 1 / 3});
    });
    return {definition: scene, textIds, peakTime: 0.82};
}

function buildSpace3DPreview(width, height) {
    const start = [3.6, 2.8, 4.1];
    const target = [0, 0.1, 0];
    const scene = tmath.scene({
        width, height, fps: FPS, theme: THEME,
        camera: {...cameraConfig(start), target, fov: 0.54},
    });
    const space = scene.space({
        x: [-1.25, 1.25, 0.5], y: [-1.05, 1.05, 0.5], z: [-1.25, 1.25, 0.5],
        numbers: false, color: \`\${P.rule}aa\`, axis_x: P.accent, axis_y: P.mustard,
        axis_z: P.blue, id: "space-volume-inline",
    });
    const corners = [
        [-0.82, -0.62, -0.82], [0.82, -0.62, -0.82], [0.82, 0.62, -0.82], [-0.82, 0.62, -0.82],
        [-0.82, -0.62, 0.82], [0.82, -0.62, 0.82], [0.82, 0.62, 0.82], [-0.82, 0.62, 0.82],
    ];
    [[0,1],[1,2],[2,3],[3,0],[4,5],[5,6],[6,7],[7,4],[0,4],[1,5],[2,6],[3,7]].forEach(([a, b], index) => {
        space.line({from: corners[a], to: corners[b], stroke: \`\${P.rule}c8\`, width: 1.25, id: \`space-volume-edge-\${index}\`});
    });
    space.vector({value: [0.78, 0.62, 0.92], stroke: P.ink, width: 2.4, tip: 8, id: "space-volume-vector"});
    space.point({point: [0.78, 0.62, 0.92], fill: P.accent, stroke: P.paper, width: 1.4, radius: 4.5, layer: L.accent, id: "space-volume-point"});
    const look = (eye) => ({...lookConfig(eye, target), fov: 0.54});
    scene.look(look([-3.6, 2.8, 4.1]), 1.6, "ease_in_out")
        .look(look([-3.6, 2.8, -4.1]), 1.6, "ease_in_out")
        .look(look([3.6, 2.8, -4.1]), 1.6, "ease_in_out")
        .look(look(start), 1.6, "ease_in_out")
        .wait(1.6);
    return scene;
}

function buildSpaceModule(width, height) {
    const cameraHeight = 4;
    const scene = scene2d(width, height, cameraHeight);
    const textIds = [];
    const w = worldWidth(width, height, cameraHeight);
    const centers = [-0.375, -0.125, 0.125, 0.375].map((value) => value * w);
    const labels = ["2D SPACE", "3D SPACE", "CELL", "VOXEL"];
    const calls = [
        "scene.space({ x, y, numbers: true })",
        "scene.space({ x, y, z })",
        "space.cell((x,y) => color)",
        "space.voxel((x,y,z) => color)",
    ];
    labels.forEach((label, index) => {
        addText(scene, {text: label, point: [centers[index], 1.62], align: [0.5, 0.5], size: 10.5, fill: index === 0 ? P.accent : P.muted, id: \`space-label-\${index}\`}, textIds);
        addText(scene, {text: calls[index], point: [centers[index], -1.62], align: [0.5, 0.5], role: "code", size: 8.7, fill: P.muted, id: \`space-api-\${index}\`}, textIds);
    });

    const translate = (x) => [1, 0, 0, x, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
    const scaled = (x, sx, sy) => [sx, 0, 0, x, 0, sy, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
    const projected = (x, xz, yz, sx = 1, sy = 1) => [sx, 0, xz, x, 0, sy, yz, 0, 0, 0, 1, 0, 0, 0, 0, 1];

    const planeGroup = scene.group({matrix: translate(centers[0]), id: "space-plane-group"});
    const plane = planeGroup.space({x: [-1.35, 1.35, 0.5], y: [-1.05, 1.05, 0.5], numbers: true, number_mode: "fixed", number_size: 8, number_color: P.muted, color: P.rule, axis_x: P.ink, axis_y: P.ink, id: "space-plane-inline"});
    plane.vector({origin: [-0.85, -0.55], value: [1.55, 1.05], stroke: P.blue, width: 2.2, tip: 8, id: "space-vector-inline"});

    const volumeViewport = {x: 0.27, y: 0.15, width: 0.22, height: 0.70};
    scene.viewport(
        buildSpace3DPreview(
            Math.max(1, Math.round(width * volumeViewport.width)),
            Math.max(1, Math.round(height * volumeViewport.height)),
        ),
        volumeViewport,
    );

    const cellGroup = scene.group({matrix: translate(centers[2]), id: "space-cell-group"});
    const cellSpace = cellGroup.space({x: [-1.35, 1.35, 0.24], y: [-1.05, 1.05, 0.24], numbers: false, color: P.rule, axis_x: P.rule, axis_y: P.rule, id: "space-cell-inline"});
    cellSpace.cell((x, y) => x * x / 0.95 ** 2 + y * y / 0.78 ** 2 <= 1 ? \`\${P.accent}c8\` : "#00000000", {mode: "padd", padding: 0.045});

    const voxelGroup = scene.group({matrix: projected(centers[3], 0.42, 0.30), id: "space-voxel-group"});
    const voxelSpace = voxelGroup.space({x: [-1.25, 1.25, 0.42], y: [-1.05, 1.05, 0.42], z: [-1.25, 1.25, 0.42], numbers: false, opacity: 0, id: "space-voxel-inline"});
    voxelSpace.voxel((x, y, z) => {
        if (x * x / 0.92 ** 2 + y * y / 0.72 ** 2 + z * z / 0.92 ** 2 > 1) return "#00000000";
        return z > 0.47 ? \`\${P.accent}d8\` : \`\${P.blue}a8\`;
    }, {mode: "padd", padding: 0.07});

    twoCycles(scene, () => {
        scene.play([
            {target: planeGroup, transform: scaled(centers[0], 1.08, 1.08)},
            {target: cellGroup, transform: scaled(centers[2], 1.18, 0.84)},
            {target: voxelGroup, transform: projected(centers[3], -0.52, 0.36, 1.08, 0.92)},
        ], 1.35, "ease_in_out", 0).wait(0.55)
            .play([
                {target: planeGroup, transform: translate(centers[0])},
                {target: cellGroup, transform: translate(centers[2])},
                {target: voxelGroup, transform: projected(centers[3], 0.42, 0.30)},
            ], 1.35, "ease_in_out", 0).wait(0.55);
    });
    return {definition: scene, textIds, peakTime: 1.0};
}

function cameraConfig(eye) {
    return {mode: "fixed", view: "3d", eye, target: [0, 0, 0], up: [0, 1, 0], projection: "perspective", fov: 0.68, near: 0.1, far: 100};
}

function lookConfig(eye, target = [0, 0, 0]) {
    return {view: "3d", eye, target, up: [0, 1, 0], projection: "perspective", fov: 0.68, near: 0.1, far: 100};
}

function buildOrbitCameraPreview(width, height) {
    const start = [5.8, 4.6, 6.2];
    const scene = tmath.scene({width, height, fps: FPS, theme: THEME, camera: cameraConfig(start)});
    scene.arrow({from: [-2.6, 0, 0], to: [2.6, 0, 0], stroke: P.accent, width: 3, tip: 10, id: "camera-axis-x"});
    scene.arrow({from: [0, -2.6, 0], to: [0, 2.6, 0], stroke: P.mustard, width: 3, tip: 10, id: "camera-axis-y"});
    scene.arrow({from: [0, 0, -2.6], to: [0, 0, 2.6], stroke: P.blue, width: 3, tip: 10, id: "camera-axis-z"});
    const circlePoints = [];
    for (let sample = 0; sample <= 96; sample += 1) {
        const angle = 2 * Math.PI * sample / 96;
        circlePoints.push([2 * Math.cos(angle), 0, 2 * Math.sin(angle)]);
    }
    scene.plot({points: circlePoints, stroke: P.blue, width: 5, id: "camera-fixed-circle"});
    scene.vector({origin: [0, 0, 0], value: [0, 1.8, 0], stroke: P.accent, width: 4, tip: 12, id: "camera-normal"});
    [[-5.8, 4.6, 6.2], [-5.8, 4.6, -6.2], [5.8, 4.6, -6.2], start].forEach((eye) => scene.look(lookConfig(eye), 1.6, "linear"));
    scene.wait(1.6);
    return scene;
}

function buildDimensionPreview(width, height) {
    const scene = tmath.scene({width, height, fps: FPS, theme: THEME, camera: {mode: "fixed", view: "2d", target: [0, 0], height: 8}});
    const space = scene.space({x: [-4, 4, 1], y: [-3, 3, 1], z: [-3, 3, 1], numbers: false, color: P.rule, axis_x: P.ink, axis_y: P.ink, axis_z: P.blue, id: "dimension-space"});
    space.polygon({points: [[0, 0], [2, 0], [2, 2], [0, 2]], fill: \`\${P.blue}44\`, stroke: P.blue, width: 4, id: "dimension-square"});
    space.vector({value: [2.4, 0, 0], stroke: P.accent, width: 5, tip: 10, id: "dimension-x"});
    space.vector({value: [0, 2.4, 0], stroke: P.mustard, width: 5, tip: 10, id: "dimension-y"});
    space.vector({value: [0, 0, 2.4], stroke: P.blue, width: 5, tip: 10, id: "dimension-z"});
    const threeD = {view: "3d", eye: [5.5, 4.2, 6.5], target: [0, 0, 0], up: [0, 1, 0], projection: "perspective", fov: 0.76, near: 0.1, far: 100};
    const twoD = {view: "2d", eye: [0, 0, 10], target: [0, 0], up: [0, 1, 0], projection: "orthographic", height: 8};
    twoCycles(scene, () => {
        scene.look(threeD, 1.2, "ease_in_out").wait(0.65)
            .look(twoD, 1.2, "ease_in_out").wait(0.75);
    });
    return scene;
}

function buildFollowCameraPreview(width, height) {
    const scene = scene2d(width, height, 4);
    const cameraMatrix = ([x, y]) => {
        const scale = 1.20;
        return [scale, 0, 0, -scale * x, 0, scale, 0, -0.15 - scale * y, 0, 0, 1, 0, 0, 0, 0, 1];
    };
    const world = scene.group({matrix: cameraMatrix([0, 0]), id: "advanced-follow-world"});
    const grid = world.space({x: [-1, 10, 1], y: [-2, 2, 0.5], color: P.rule, axis_x: P.ink, axis_y: P.ink, numbers: false, id: "advanced-follow-grid"});
    const sampleCount = 120;
    const points = [];
    for (let sample = 0; sample <= sampleCount; sample += 1) {
        const x = 3 * Math.PI * sample / sampleCount;
        points.push([x, Math.sin(x)]);
    }
    grid.plot({points, stroke: P.blue, width: 3.4, id: "advanced-follow-path"});
    grid.point({point: [0, 0], fill: P.ink, radius: 4, id: "advanced-follow-start"});
    grid.point({point: [3 * Math.PI, 0], fill: P.ink, radius: 4, id: "advanced-follow-end"});
    scene.rectangle({center: [0, -0.15], size: [3.5, 2.15], corner: 0.08, fill: "#00000000", stroke: \`\${P.accent}88\`, width: 2, layer: L.guide, id: "advanced-follow-frame"});
    scene.point({point: [0, -0.15], fill: P.accent, stroke: P.paper, width: 3, radius: 8, layer: L.accent, id: "advanced-follow-focus"});
    twoCycles(scene, () => {
        for (let step = 1; step <= sampleCount; step += 1) {
            scene.transform(world, cameraMatrix(points[step]), 0.025, "linear");
        }
        scene.transform(world, cameraMatrix(points[0]), 0.6, "ease_in_out").wait(0.2);
    });
    return scene;
}

function buildAdvancedCameraModule(width, height) {
    const cameraHeight = 4;
    const scene = scene2d(width, height, cameraHeight);
    const textIds = [];
    const w = worldWidth(width, height, cameraHeight);
    const followViewport = {x: 0.01, y: 0.16, width: 0.37, height: 0.64};
    const orbitViewport = {x: 0.40, y: 0.16, width: 0.23, height: 0.64};
    const dimensionViewport = {x: 0.65, y: 0.16, width: 0.34, height: 0.64};
    const worldX = (normalized) => (normalized - 0.5) * w;
    const centers = [followViewport, orbitViewport, dimensionViewport]
        .map((viewport) => worldX(viewport.x + viewport.width / 2));
    const childSize = (viewport) => [
        Math.max(1, Math.round(width * viewport.width)),
        Math.max(1, Math.round(height * viewport.height)),
    ];

    addText(scene, {text: "FOLLOW CAMERA", point: [centers[0], 1.62], align: [0.5, 0.5], size: 10.5, fill: P.accent, id: "advanced-follow-label"}, textIds);
    addText(scene, {text: "ORBIT CAMERA", point: [centers[1], 1.62], align: [0.5, 0.5], size: 10.5, fill: P.blue, id: "advanced-orbit-label"}, textIds);
    addText(scene, {text: "2D ↔ 3D VIEW", point: [centers[2], 1.62], align: [0.5, 0.5], size: 10.5, fill: P.muted, id: "advanced-dimension-label"}, textIds);
    addText(scene, {text: "scene.transform(world, cameraMatrix(sample), dt)", point: [centers[0], -1.62], align: [0.5, 0.5], role: "code", size: 7.8, fill: P.muted, id: "advanced-follow-api"}, textIds);
    addText(scene, {text: "scene.look({ eye, target }, duration)", point: [centers[1], -1.62], align: [0.5, 0.5], role: "code", size: 7.8, fill: P.muted, id: "advanced-orbit-api"}, textIds);
    addText(scene, {text: "scene.look({ view: \\"2d\\" | \\"3d\\", ... }, duration)", point: [centers[2], -1.62], align: [0.5, 0.5], role: "code", size: 7.8, fill: P.muted, id: "advanced-dimension-api"}, textIds);

    const [followWidth, followHeight] = childSize(followViewport);
    const [orbitWidth, orbitHeight] = childSize(orbitViewport);
    const [dimensionWidth, dimensionHeight] = childSize(dimensionViewport);
    scene.viewport(buildFollowCameraPreview(followWidth, followHeight), followViewport);
    scene.viewport(buildOrbitCameraPreview(orbitWidth, orbitHeight), orbitViewport);
    scene.viewport(buildDimensionPreview(dimensionWidth, dimensionHeight), dimensionViewport);
    return {definition: scene, textIds, peakTime: 1.5};
}

function buildSurfaceModule(width, height) {
    const start = [5.8, 4.4, 6.4];
    const target = [0, 0.2, 0];
    const scene = tmath.scene({width, height, fps: FPS, theme: THEME, camera: {...cameraConfig(start), target, fov: 0.66}});
    const axes = scene.space({x: [-3, 3, 6], y: [-1, 2.2, 6], z: [-3, 3, 6], color: "#00000000", axis_x: P.rule, axis_y: P.rule, axis_z: P.rule, id: "surface-space"});
    const columns = 25;
    const rows = 25;
    const points = [];
    for (let row = 0; row < rows; row += 1) {
        const z = -2.7 + 5.4 * row / (rows - 1);
        for (let column = 0; column < columns; column += 1) {
            const x = -2.7 + 5.4 * column / (columns - 1);
            const y = 2.35 * Math.exp(-(x * x + z * z) / 1.45) - 0.75;
            points.push([x, y, z]);
        }
    }
    scene.surface({points, size: [columns, rows], mode: "solid_mesh", shading: false, fill: \`\${P.blue}42\`, stroke: \`\${P.blue}b8\`, width: 0.72, id: "gaussian-surface"});
    axes.point({point: [0, 1.6, 0], radius: 5, fill: P.accent, stroke: P.paper, width: 2, id: "surface-peak"});
    const look = (eye) => ({...lookConfig(eye, target), fov: 0.66});
    scene.look(look([-5.4, 4.8, 6.0]), 1.8, "ease_in_out")
        .look(look([-5.8, 3.4, -5.8]), 1.8, "ease_in_out")
        .look(look([-5.4, 4.8, 6.0]), 1.8, "ease_in_out")
        .look(look(start), 1.8, "ease_in_out")
        .wait(0.8);
    return {definition: scene, textIds: [], peakTime: 2.8};
}

function buildRayDemo(width, height) {
    const scene = tmath.scene({
        width, height, fps: FPS, theme: THEME,
        camera: {mode: "fixed", view: "3d", eye: [9, 6, 11], target: [-0.6, 0, 0], up: [0, 1, 0], projection: "perspective", fov: 0.66, near: 0.1, far: 100},
    });
    const translate = (x, y, z) => [1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, z, 0, 0, 0, 1];
    const screen = scene.group({matrix: [0, 0, 1, -3, 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 0, 1], id: "ray-image-plane"});
    const hitColors = [[P.blue, P.blue, null, null, null], [P.blue, P.blue, null, P.mustard, P.mustard], [null, null, P.accent, P.mustard, P.mustard]];
    const pixels = [];
    for (let row = 0; row < 3; row += 1) {
        pixels[row] = [];
        for (let column = 0; column < 5; column += 1) {
            const color = hitColors[row][column];
            pixels[row][column] = screen.rectangle({center: [(column - 2) * 0.48, (1 - row) * 0.48], size: [0.42, 0.42], corner: 0.035, fill: color ? \`\${color}aa\` : P.paper, stroke: P.rule, width: 1.6, id: \`ray-pixel-\${row}-\${column}\`});
        }
    }
    [[[-1.29,-0.80],[1.29,-0.80]],[[1.29,-0.80],[1.29,0.80]],[[1.29,0.80],[-1.29,0.80]],[[-1.29,0.80],[-1.29,-0.80]]].forEach(([from,to], index) => screen.line({from, to, stroke: P.blue, width: 2.5, id: \`ray-frame-\${index}\`}));
    const origin = [-6, 0, 0];
    scene.point({point: origin, fill: P.ink, radius: 7, layer: L.accent, id: "ray-pinhole"});

    const sphereCenter = [2.2, 0.656, 1.968];
    const sphere = scene.group({matrix: translate(...sphereCenter), id: "ray-sphere"});
    for (let latitude = -2; latitude <= 2; latitude += 1) {
        const phi = latitude * Math.PI / 7;
        const points = [];
        for (let index = 0; index <= 40; index += 1) { const angle = 2 * Math.PI * index / 40; points.push([0.98 * Math.cos(phi) * Math.cos(angle), 0.98 * Math.sin(phi), 0.98 * Math.cos(phi) * Math.sin(angle)]); }
        sphere.plot({points, stroke: P.blue, width: 2.0});
    }
    for (let longitude = 0; longitude < 6; longitude += 1) {
        const theta = longitude * Math.PI / 6;
        const points = [];
        for (let index = 0; index <= 48; index += 1) { const phi = -Math.PI / 2 + Math.PI * index / 48; points.push([0.98 * Math.cos(phi) * Math.cos(theta), 0.98 * Math.sin(phi), 0.98 * Math.cos(phi) * Math.sin(theta)]); }
        sphere.plot({points, stroke: \`\${P.blue}aa\`, width: 1.6});
    }

    const cubeCenter = [2.2, -0.656, -1.968];
    const cube = scene.group({matrix: translate(...cubeCenter), id: "ray-cube"});
    const cubePoints = [[-0.82,-0.82,-0.82],[0.82,-0.82,-0.82],[0.82,0.82,-0.82],[-0.82,0.82,-0.82],[-0.82,-0.82,0.82],[0.82,-0.82,0.82],[0.82,0.82,0.82],[-0.82,0.82,0.82]];
    [[0,1],[1,2],[2,3],[3,0],[4,5],[5,6],[6,7],[7,4],[0,4],[1,5],[2,6],[3,7]].forEach(([a,b]) => cube.line({from: cubePoints[a], to: cubePoints[b], stroke: P.mustard, width: 2.4}));

    const pyramid = scene.group({matrix: translate(2.2, -1.312, 0), id: "ray-pyramid"});
    const base = [[-0.72,-0.55,-0.72],[0.72,-0.55,-0.72],[0.72,-0.55,0.72],[-0.72,-0.55,0.72]];
    base.forEach((point, index) => { pyramid.line({from: point, to: base[(index + 1) % 4], stroke: P.accent, width: 2.4}); pyramid.line({from: point, to: [0, 0.82, 0], stroke: P.accent, width: 2.4}); });
    const samplePoint = (column, row, x) => { const u = (column - 2) * 0.48; const v = (1 - row) * 0.48; const scale = (x - origin[0]) / 3; return [x, v * scale, -u * scale]; };
    const rayRows = [];
    const hitRows = [];
    for (let row = 0; row < 3; row += 1) {
        rayRows[row] = [];
        hitRows[row] = [];
        for (let column = 0; column < 5; column += 1) {
            const color = hitColors[row][column];
            const endpoint = samplePoint(column, row, color ? 2.2 : 3.8);
            rayRows[row].push(scene.arrow({from: origin, to: endpoint, stroke: color || P.muted, opacity: color ? 0.28 : 0.10, width: color ? 2.8 : 1.7, tip: 8, id: \`ray-primary-\${row}-\${column}\`}));
            if (color) hitRows[row].push(scene.point({point: endpoint, fill: color, opacity: 0.45, radius: 4.5, layer: L.accent, id: \`ray-hit-\${row}-\${column}\`}));
        }
    }
    twoCycles(scene, () => {
        for (let row = 0; row < 3; row += 1) {
            scene.play([...rayRows[row].map((target) => ({target, opacity: 0.92})), ...hitRows[row].map((target) => ({target, opacity: 1})), ...pixels[row].map((target) => ({target, stroke: P.accent}))], 0.45, "ease_in_out", 0)
                .wait(0.25)
                .play([...rayRows[row].map((target, column) => ({target, opacity: hitColors[row][column] ? 0.28 : 0.10})), ...hitRows[row].map((target) => ({target, opacity: 0.45})), ...pixels[row].map((target) => ({target, stroke: P.rule}))], 0.35, "ease_in_out", 0);
        }
        scene.wait(0.65);
    });
    return scene;
}

function buildDemoModule(width, height) {
    const scene = scene2d(width, height, 4);
    const textIds = [];
    const w = worldWidth(width, height, 4);
    const rayCenter = -0.20 * w;
    const diagramCenter = 0.31 * w;
    addText(scene, {text: "RAY TRACING", point: [rayCenter, 1.66], align: [0.5, 0.5], size: 10.5, fill: P.accent, id: "demo-ray-label"}, textIds);
    addText(scene, {text: "ARCHITECTURE DIAGRAM", point: [diagramCenter, 1.66], align: [0.5, 0.5], size: 10.5, fill: P.muted, id: "demo-diagram-label"}, textIds);
    addText(scene, {text: "scene.arrow({ from, to }) · scene.play([{ target: ray, opacity }], dt)", point: [rayCenter, -1.66], align: [0.5, 0.5], role: "code", size: 8.8, fill: P.muted, id: "demo-ray-api"}, textIds);
    addText(scene, {text: "scene.group({ id }) · group.rectangle(...) · scene.path({ commands, dash })", point: [diagramCenter, -1.66], align: [0.5, 0.5], role: "code", size: 8.8, fill: P.muted, id: "demo-diagram-api"}, textIds);
    const rayViewport = {x: 0.20, y: 0.13, width: 0.20, height: 0.69};
    scene.viewport(
        buildRayDemo(
            Math.max(1, Math.round(width * rayViewport.width)),
            Math.max(1, Math.round(height * rayViewport.height)),
        ),
        rayViewport,
    );

    const x = {
        client: 0.105 * w, edge: 0.225 * w, api: 0.34 * w, data: 0.455 * w,
    };
    const topY = 0.38;
    const lowY = -0.66;
    scene.rectangle({center: [x.client, -0.10], size: [0.085 * w, 2.32], corner: 0.08, fill: \`\${P.blue}0c\`, stroke: P.rule, width: 1, layer: L.guide, id: "diagram-zone-public"});
    scene.rectangle({center: [(x.edge + x.api) / 2, -0.10], size: [0.21 * w, 2.32], corner: 0.08, fill: \`\${P.mustard}0c\`, stroke: P.rule, width: 1, layer: L.guide, id: "diagram-zone-platform"});
    scene.rectangle({center: [x.data, -0.10], size: [0.085 * w, 2.32], corner: 0.08, fill: \`\${P.purple}0c\`, stroke: P.rule, width: 1, layer: L.guide, id: "diagram-zone-data"});
    [["PUBLIC", x.client], ["PLATFORM", x.edge], ["DATA", x.data]].forEach(([text, px], index) => addText(scene, {text, point: [px, 1.23], align: [0.5, 0.5], size: 8.5, fill: index === 0 ? P.blue : P.muted, id: \`diagram-zone-label-\${index}\`}, textIds));

    const makeNode = (id, label, detail, px, py, color = P.rule) => {
        const group = scene.group({id: \`diagram-\${id}\`});
        group.rectangle({center: [px, py], size: [0.064 * w, 0.68], corner: 0.06, fill: P.paper, stroke: color, width: color === P.rule ? 1.4 : 2, layer: L.object, id: \`diagram-\${id}-body\`});
        addText(group, {text: label, point: [px, py + 0.11], align: [0.5, 0.5], size: 9.2, fill: P.ink, id: \`diagram-\${id}-label\`}, textIds);
        addText(group, {text: detail, point: [px, py - 0.13], align: [0.5, 0.5], size: 7.4, fill: P.muted, id: \`diagram-\${id}-detail\`}, textIds);
        return group;
    };
    makeNode("client", "CLIENT", "web / mobile", x.client, topY);
    makeNode("edge", "EDGE", "TLS · routing", x.edge, topY);
    makeNode("api", "API", "auth · policy", x.api, topY, P.accent);
    makeNode("cache", "CACHE", "read-through", x.data, topY);
    makeNode("worker", "WORKER", "async jobs", x.api, lowY);
    makeNode("store", "STORE", "durable state", x.data, lowY);
    const route = (from, to, id, dash = null) => {
        const options = {
            commands: [{type: "move", to: from}, {type: "line", to}],
            samples: 12, fill: "#00000000", stroke: dash ? P.purple : P.blue,
            width: 1.8, layer: L.guide, id,
        };
        if (dash) options.dash = dash;
        return scene.path(options);
    };
    const halfNode = 0.032 * w;
    const requestRoutes = [
        [[x.client + halfNode, topY], [x.edge - halfNode, topY], "https"],
        [[x.edge + halfNode, topY], [x.api - halfNode, topY], "json"],
        [[x.api + halfNode, topY], [x.data - halfNode, topY], "get"],
        [[x.api, topY - 0.34], [x.api, lowY + 0.34], "job"],
        [[x.api + halfNode, lowY], [x.data - halfNode, lowY], "write"],
    ];
    requestRoutes.forEach(([from, to, name]) => route(from, to, \`diagram-route-\${name}\`));
    route([x.data - halfNode, topY + 0.31], [x.api + halfNode, topY + 0.31], "diagram-route-hit", [6, 5]);
    const arrowhead = (point, direction, id, color = P.blue) => {
        const s = 0.09;
        const [px, py] = point;
        const points = direction === "left"
            ? [[px, py], [px + s, py + s * 0.55], [px + s, py - s * 0.55]]
            : direction === "down"
                ? [[px, py], [px - s * 0.55, py + s], [px + s * 0.55, py + s]]
                : [[px, py], [px - s, py + s * 0.55], [px - s, py - s * 0.55]];
        scene.polygon({points, fill: color, stroke: color, width: 1, layer: L.guide + 1, id});
    };
    requestRoutes.forEach(([, to, name]) => arrowhead(to, name === "job" ? "down" : "right", \`diagram-head-\${name}\`));
    arrowhead([x.api + halfNode, topY + 0.31], "left", "diagram-head-hit", P.purple);
    const routeLabels = [["HTTPS",(x.client+x.edge)/2,topY+0.23],["JSON",(x.edge+x.api)/2,topY-0.23],["GET",(x.api+x.data)/2,topY+0.23],["JOB",x.api+0.025*w,(topY+lowY)/2],["WRITE",(x.api+x.data)/2,lowY+0.23],["HIT",(x.api+x.data)/2,topY+0.53]];
    routeLabels.forEach(([text, px, py], index) => {
        scene.rectangle({center: [px, py], size: [0.034 * w, 0.24], corner: 0.04, fill: P.paper, stroke: "#00000000", layer: L.text - 1, id: \`diagram-route-mask-\${index}\`});
        addText(scene, {text, point: [px, py], align: [0.5, 0.5], role: "code", size: 7.5, fill: index === 5 ? P.purple : P.muted, layer: L.text, id: \`diagram-route-label-\${index}\`}, textIds);
    });
    addText(scene, {text: "solid request  ·  dashed cached response", point: [diagramCenter, -1.38], align: [0.5, 0.5], size: 7.8, fill: P.muted, id: "diagram-legend"}, textIds);
    return {definition: scene, textIds, peakTime: 1.55};
}

const MODULE_LAYOUT = [
    {id: "scene", number: "01", title: "Build the scene graph", x0: CONTENT_LEFT, x1: CONTENT_RIGHT, top: 13.30, bottom: 9.40, api: ["", ""], caption: ["Factories attach retained objects to Scene; Space owns coordinate-aware marks.", "Camera configuration and timeline operations remain Scene state outside the object tree."], build: buildSceneModule},
    {id: "object", number: "02", title: "Group children; connect bounds", x0: CONTENT_LEFT, x1: -0.15, top: 9.15, bottom: 5.85, api: ["const group = scene.group(); const a = group.circle(...)", "const b = group.rectangle(...); group.connector(a, b)"], caption: ["A parent transform carries every child; moving b also expands the Group bounds.", "Connector recomputes its endpoints from the current child bounds."], build: buildObjectModule},
    {id: "animate", number: "03", title: "Schedule target-state changes", x0: 0.15, x1: CONTENT_RIGHT, top: 9.15, bottom: 5.85, visualBottomInset: 0.96, api: ["scene.play([{ target, shift, fill }], duration, curve)", "one call · explicit targets · one bounded time interval"], caption: ["play moves related targets from their current state to the requested state together.", "Sampling the same timeline time reproduces the same intermediate state."], build: buildAnimateModule},
    {id: "theme", number: "04", title: "Style at scene creation", x0: CONTENT_LEFT, x1: -0.15, top: 5.60, bottom: 2.50, api: ["theme: \\"3_blue_1_eyes\\" | \\"pro_white\\" | \\"pro_black\\"", "{ preset, text, objects, axis }"], caption: ["Theme belongs to SceneConfig; it is not a live switch.", "Swatches compare background, foreground, and accent roles."], build: buildThemeModule},
    {id: "text", number: "05", title: "Text roles select typography", x0: 0.15, x1: CONTENT_RIGHT, top: 5.60, bottom: 2.50, api: ["scene.text({ text, point, align, role, orientation })", "role: \\"h1\\" | \\"text\\" | \\"code\\""], caption: ["role selects heading, body, or code typography.", "orientation selects billboard or plane text in 3D."], build: buildTextModule},
    {id: "curve", number: "06", title: "Map time to motion progress", x0: CONTENT_LEFT, x1: CONTENT_RIGHT, top: 2.25, bottom: -1.15, api: ["tmath.animCurve.preset(name, strength)", "tmath.animCurve.reverse(curve)"], caption: ["Each preset maps normalized time t to progress p(t).", "The graph and runner expose overshoot, elasticity, or bounce directly."], build: buildCurveModule},
    {id: "space", number: "07", title: "Coordinates, pixels, and voxels", x0: CONTENT_LEFT, x1: CONTENT_RIGHT, top: -1.40, bottom: -4.90, api: ["", ""], caption: ["Each figure calls the Space API printed directly beneath it.", "The coordinate systems and sampled Cell / Voxel results remain retained objects."], build: buildSpaceModule},
    {id: "advanced", number: "08", title: "Advanced camera recipes", x0: CONTENT_LEFT, x1: 1.80, top: -5.15, bottom: -9.05, api: ["", ""], caption: ["Follow holds a moving sample at a fixed focus; orbit changes only the eye around retained geometry.", "The third view interpolates one Space between orthographic 2D and perspective 3D."], build: buildAdvancedCameraModule},
    {id: "surface", number: "09", title: "Sample a real 3D field", x0: 2.10, x1: CONTENT_RIGHT, top: -5.15, bottom: -9.05, api: ["scene.surface({ points, size: [cols, rows] })", "mode: \\"mesh\\" | \\"solid_mesh\\""], caption: ["Surface consumes a row-major columns × rows point field.", "Orbit the camera to inspect the retained geometry."], build: buildSurfaceModule},
    {id: "demo", number: "10", title: "Compose complete technical scenes", x0: CONTENT_LEFT, x1: CONTENT_RIGHT, top: -9.30, bottom: -13.30, api: ["", ""], caption: ["Primary rays map intersections into pixels; Groups, Paths, and labels expose system boundaries.", "Ray rows replay sample-to-pixel correspondence while the architecture remains stable for inspection."], build: buildDemoModule},
];

function moduleDimensions(item) {
    const visualTop = item.top - 0.45;
    const visualBottom = item.bottom + (item.visualBottomInset ?? (item.api.some(Boolean) ? 0.78 : 0.68));
    return {visualTop, visualBottom, width: Math.round((item.x1 - item.x0) * 100), height: Math.round((visualTop - visualBottom) * 100)};
}

function buildModules() {
    return MODULE_LAYOUT.map((item) => {
        const dimensions = moduleDimensions(item);
        return {...item, dimensions, ...item.build(dimensions.width, dimensions.height)};
    });
}

const definition = tmath.scene({
    width: WIDTH,
    height: HEIGHT,
    fps: FPS,
    loop: true,
    theme: THEME,
    camera: {mode: "fixed", view: "2d", target: [0, 0], height: ROOT_CAMERA_HEIGHT},
});

addText(definition, {text: "TMATH", point: [CONTENT_LEFT, 14.18], align: [0, 0.5], role: "h1", size: 68, fill: P.ink, id: "header-title"});
definition.line({from: [CONTENT_LEFT, 13.55], to: [CONTENT_RIGHT, 13.55], stroke: P.ink, width: 1.3, id: "header-rule"});
definition.line({from: [CONTENT_LEFT, 13.48], to: [CONTENT_LEFT + 1.8, 13.48], stroke: P.accent, width: 4, id: "header-accent"});

const mountedModules = buildModules();
const inlineTheme = mountedModules.find((item) => item.id === "theme");
let authorInlineThemeMotion = null;
if (inlineTheme) {
    const scale = (inlineTheme.dimensions.visualTop - inlineTheme.dimensions.visualBottom) / 4;
    const centerX = (inlineTheme.x0 + inlineTheme.x1) / 2;
    const centerY = (inlineTheme.dimensions.visualTop + inlineTheme.dimensions.visualBottom) / 2;
    const group = definition.group({matrix: [scale, 0, 0, centerX, 0, scale, 0, centerY, 0, 0, 1, 0, 0, 0, 0, 1], id: "theme-inline"});
    authorInlineThemeMotion = authorThemeFigure(
        group,
        definition,
        worldWidth(inlineTheme.dimensions.width, inlineTheme.dimensions.height, 4),
        null,
        false,
    );
}
for (const item of mountedModules) {
    const moduleWidth = item.x1 - item.x0;
    const titleSize = moduleWidth < 4 ? 17 : moduleWidth < 5 ? 20 : 24;
    const apiSize = moduleWidth < 4 ? 10.5 : moduleWidth < 5 ? 11.5 : 13;
    const captionSize = moduleWidth < 4 ? 9.5 : moduleWidth < 5 ? 10.5 : moduleWidth < 6 ? 11 : 12.5;
    const hasApi = item.api.some(Boolean);
    definition.line({from: [item.x0, item.top], to: [item.x1, item.top], stroke: P.rule, width: 1.2, id: \`\${item.id}-rule\`});
    addText(definition, {text: item.title, point: [item.x0, item.top - 0.28], align: [0, 0.5], role: "h2", size: titleSize, fill: P.ink, id: \`\${item.id}-title\`});
    addText(definition, {text: \`\${item.number} / \${item.id.toUpperCase()}\`, point: [item.x1, item.top - 0.12], align: [1, 0.5], size: 10.5, fill: P.accent, id: \`\${item.id}-number\`});
    if (item.id !== "theme") {
        definition.viewport(item.definition, {
            x: (item.x0 + ROOT_HALF_WIDTH) / ROOT_CAMERA_WIDTH,
            y: (ROOT_HALF_HEIGHT - item.dimensions.visualTop) / ROOT_CAMERA_HEIGHT,
            width: (item.x1 - item.x0) / ROOT_CAMERA_WIDTH,
            height: (item.dimensions.visualTop - item.dimensions.visualBottom) / ROOT_CAMERA_HEIGHT,
        });
    }
    if (item.api[0]) addText(definition, {text: item.api[0], point: [item.x0, item.bottom + 0.62], align: [0, 0.5], role: "code", size: apiSize, fill: P.accent, id: \`\${item.id}-api-1\`});
    if (item.api[1]) addText(definition, {text: item.api[1], point: [item.x0, item.bottom + 0.40], align: [0, 0.5], role: "code", size: apiSize, fill: P.muted, id: \`\${item.id}-api-2\`});
    const captionY = hasApi ? item.bottom + 0.16 : item.bottom + 0.43;
    addText(definition, {text: item.caption[0], point: [item.x0, captionY], align: [0, 0.5], size: captionSize, fill: P.ink, id: \`\${item.id}-caption-1\`});
    if (item.caption[1]) addText(definition, {text: item.caption[1], point: [item.x0, captionY - 0.24], align: [0, 0.5], size: captionSize, fill: P.muted, id: \`\${item.id}-caption-2\`});
    if (item.api[0] && item.api[1]) pair(\`\${item.id}-api-1\`, \`\${item.id}-api-2\`, 4);
    if (item.caption[1]) pair(\`\${item.id}-caption-1\`, \`\${item.id}-caption-2\`, 4);
}

definition.line({from: [CONTENT_LEFT, -13.65], to: [CONTENT_RIGHT, -13.65], stroke: P.ink, width: 1.2, id: "footer-rule"});
addText(definition, {text: "SceneBuilder records objects, camera state, and timeline operations.", point: [CONTENT_LEFT, -14.00], align: [0, 0.5], size: 12.5, fill: P.ink, id: "footer-summary"});
addText(definition, {text: "TMathScene renders frames and exposes assets, bounds, resize, and camera controls.", point: [CONTENT_RIGHT, -14.00], align: [1, 0.5], size: 10.5, fill: P.muted, id: "footer-note"});
authorInlineThemeMotion?.();

const MODULE_IDS = mountedModules.map((item) => item.id);
return definition;
`,
    },
    {
        id: "binary-search-cheatsheet",
        title: "Binary Search Cheatsheet",
        description: "A persistent binary-search trace with pseudocode, candidate ranges, the search invariant, and logarithmic complexity.",
        category: "Cheatsheets",
        dimension: "2D",
        fonts: [{name: "Pretendard", url: "./Pretendard.ttf", mime: "ttf"}],
        lua: `-- Standalone binary-search cheatsheet.
local scene = tmath.scene {["background"]="#FFFFFF",["camera"]={["height"]=14.6,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=24,["height"]=1460,["loop"]=true,["theme"]="pro_white",["width"]=1440}
local object1 = scene:group {["id"]="header"}
local object2 = object1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="header-title",["layer"]=40,["point"]={-6.62,6.65},["role"]="h1",["size"]=52,["text"]="Binary Search"}
local object3 = object1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="header-subtitle",["layer"]=40,["point"]={-6.58,5.95},["size"]=19,["text"]="Why one comparison can eliminate half of a sorted search interval"}
local object4 = object1:text {["align"]={1,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="header-guide",["layer"]=40,["point"]={6.62,5.95},["size"]=15,["text"]="Four comparisons locate 68"}
local object5 = object1:line {["from"]={-6.62,5.65},["id"]="header-rule",["layer"]=0,["stroke"]="#202124",["to"]={6.62,5.65},["width"]=1.4}
local object6 = scene:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-section-title",["layer"]=40,["point"]={-6.62,1.63},["size"]=15,["text"]="SEARCH TRACE  ·  Each row shows the closed interval [lo, hi] before comparison"}
local object7 = scene:text {["align"]={1,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-legend",["layer"]=40,["point"]={6.62,1.63},["role"]="code",["size"]=11,["text"]="blue = candidate   ochre = mid   rust = target / result"}
local object8 = scene:line {["from"]={-6.62,1.39},["id"]="trace-section-rule",["stroke"]="#D8DADD",["to"]={6.62,1.39},["width"]=1}
local object9 = scene:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="footer-section-title",["layer"]=40,["point"]={-6.62,-3.72},["size"]=15,["text"]="COMPLEXITY, INVARIANT, AND RETURN VALUE"}
local object10 = scene:line {["from"]={-6.62,-3.96},["id"]="footer-section-rule",["stroke"]="#D8DADD",["to"]={6.62,-3.96},["width"]=1}
local object11 = scene:line {["from"]={-2.09,-4.02},["id"]="footer-divider-1",["stroke"]="#D8DADD",["to"]={-2.09,-7.1},["width"]=1}
local object12 = scene:line {["from"]={3.31,-4.02},["id"]="footer-divider-2",["stroke"]="#D8DADD",["to"]={3.31,-7.1},["width"]=1}
do
    local viewportScene1 = tmath.scene {["background"]="#FFFFFF",["camera"]={["height"]=2.65,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=24,["height"]=190,["loop"]=false,["theme"]="pro_white",["width"]=1325}
    local object1 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="pseudocode-title",["layer"]=40,["point"]={-8.82,1.1},["size"]=16,["text"]="A  ·  Pseudocode"}
    local object2 = viewportScene1:text {["align"]={1,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="pseudocode-contract",["layer"]=40,["point"]={8.82,1.1},["role"]="code",["size"]=12,["text"]="Closed candidate interval [lo, hi]"}
    local object3 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="pseudocode-line-1",["layer"]=40,["point"]={-8.76,0.72},["role"]="code",["size"]=12.5,["text"]="1  lo ← 0; hi ← n - 1"}
    local object4 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="pseudocode-line-2",["layer"]=40,["point"]={-8.76,0.43},["role"]="code",["size"]=12.5,["text"]="2  while lo ≤ hi"}
    local object5 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="pseudocode-line-3",["layer"]=40,["point"]={-8.76,0.14},["role"]="code",["size"]=12.5,["text"]="3    mid ← floor((lo + hi) / 2)"}
    local object6 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="pseudocode-line-4",["layer"]=40,["point"]={-8.76,-0.1499999999999999},["role"]="code",["size"]=12.5,["text"]="4    if a[mid] < target: lo ← mid + 1"}
    local object7 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="pseudocode-line-5",["layer"]=40,["point"]={-8.76,-0.43999999999999995},["role"]="code",["size"]=12.5,["text"]="5    else if a[mid] > target: hi ← mid - 1"}
    local object8 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="pseudocode-line-6",["layer"]=40,["point"]={-8.76,-0.73},["role"]="code",["size"]=12.5,["text"]="6    else: return mid"}
    local object9 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="pseudocode-line-7",["layer"]=40,["point"]={-8.76,-1.0199999999999998},["role"]="code",["size"]=12.5,["text"]="7  return NOT_FOUND"}
    local object10 = viewportScene1:line {["from"]={0.72,0.84},["id"]="pseudocode-divider",["stroke"]="#D8DADD",["to"]={0.72,-1.16},["width"]=1}
    local object11 = viewportScene1:text {["align"]={0,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="pseudocode-map-range-1",["layer"]=40,["point"]={1.18,0.43},["role"]="code",["size"]=12,["text"]="L1–3"}
    local object12 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="pseudocode-map-destination-1",["layer"]=40,["point"]={2.65,0.43},["size"]=12,["text"]="→  B INPUT · C1–C4 TRACE"}
    local object13 = viewportScene1:text {["align"]={0,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="pseudocode-map-range-2",["layer"]=40,["point"]={1.18,-0.3},["role"]="code",["size"]=12,["text"]="L4–5"}
    local object14 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="pseudocode-map-destination-2",["layer"]=40,["point"]={2.65,-0.3},["size"]=12,["text"]="→  D CANDIDATES · E INVARIANT"}
    local object15 = viewportScene1:text {["align"]={0,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="pseudocode-map-range-3",["layer"]=40,["point"]={1.18,-0.88},["role"]="code",["size"]=12,["text"]="L6–7"}
    local object16 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="pseudocode-map-destination-3",["layer"]=40,["point"]={2.65,-0.88},["size"]=12,["text"]="→  F RESULT"}
    local object17 = viewportScene1:rectangle {["center"]={-4.05,0.43},["corner"]=0.025,["fill"]="#9B3600",["id"]="pseudocode-highlight-1",["layer"]=0,["opacity"]=0,["size"]={9.05,0.82},["stroke"]="#00000000"}
    local object18 = viewportScene1:rectangle {["center"]={-4.05,-0.295},["corner"]=0.025,["fill"]="#9B3600",["id"]="pseudocode-highlight-2",["layer"]=0,["opacity"]=0,["size"]={9.05,0.54},["stroke"]="#00000000"}
    local object19 = viewportScene1:rectangle {["center"]={-4.05,-0.875},["corner"]=0.025,["fill"]="#9B3600",["id"]="pseudocode-highlight-3",["layer"]=0,["opacity"]=0,["size"]={9.05,0.54},["stroke"]="#00000000"}
    viewportScene1:wait(0.2)
    viewportScene1:play({{target=object17,opacity=0.12}},0.45,"gentle",0)
    viewportScene1:wait(0.25)
    viewportScene1:play({{target=object17,opacity=0}},0.45,"gentle",0)
    viewportScene1:play({{target=object18,opacity=0.12}},0.45,"gentle",0)
    viewportScene1:wait(0.25)
    viewportScene1:play({{target=object18,opacity=0}},0.45,"gentle",0)
    viewportScene1:play({{target=object19,opacity=0.12}},0.45,"gentle",0)
    viewportScene1:wait(0.25)
    viewportScene1:play({{target=object19,opacity=0}},0.45,"gentle",0)
    viewportScene1:wait(0.2)
    viewportScene1:play({{target=object17,opacity=0.12}},0.45,"gentle",0)
    viewportScene1:wait(0.25)
    viewportScene1:play({{target=object17,opacity=0}},0.45,"gentle",0)
    viewportScene1:play({{target=object18,opacity=0.12}},0.45,"gentle",0)
    viewportScene1:wait(0.25)
    viewportScene1:play({{target=object18,opacity=0}},0.45,"gentle",0)
    viewportScene1:play({{target=object19,opacity=0.12}},0.45,"gentle",0)
    viewportScene1:wait(0.25)
    viewportScene1:play({{target=object19,opacity=0}},0.45,"gentle",0)
    viewportScene1:wait(0.7)
    scene:viewport(viewportScene1,{["height"]=0.13,["width"]=0.92,["x"]=0.04,["y"]=0.115})
end
do
    local viewportScene1 = tmath.scene {["background"]="#FFFFFF",["camera"]={["height"]=2.35,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=24,["height"]=167,["loop"]=false,["theme"]="pro_white",["width"]=1325}
    local object1 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="input-title",["layer"]=40,["point"]={-9.18,0.82},["size"]=17,["text"]="B  ·  Sorted input and target"}
    local object2 = viewportScene1:text {["align"]={1,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="input-target-code",["layer"]=40,["point"]={9.18,0.82},["role"]="code",["size"]=15,["text"]="target = 68"}
    local object3 = viewportScene1:rectangle {["center"]={-6.3,0.08},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="input-cell-0",["layer"]=10,["size"]={0.94,0.66},["stroke"]="#5E7A9B",["width"]=1.2}
    local object4 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="input-value-0",["layer"]=40,["point"]={-6.3,0.16},["size"]=16,["text"]="-12"}
    local object5 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="input-index-0",["layer"]=40,["point"]={-6.3,-0.31},["size"]=10,["text"]="0"}
    local object6 = viewportScene1:rectangle {["center"]={-5.29,0.08},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="input-cell-1",["layer"]=10,["size"]={0.94,0.66},["stroke"]="#5E7A9B",["width"]=1.2}
    local object7 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="input-value-1",["layer"]=40,["point"]={-5.29,0.16},["size"]=16,["text"]="-3"}
    local object8 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="input-index-1",["layer"]=40,["point"]={-5.29,-0.31},["size"]=10,["text"]="1"}
    local object9 = viewportScene1:rectangle {["center"]={-4.279999999999999,0.08},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="input-cell-2",["layer"]=10,["size"]={0.94,0.66},["stroke"]="#5E7A9B",["width"]=1.2}
    local object10 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="input-value-2",["layer"]=40,["point"]={-4.279999999999999,0.16},["size"]=16,["text"]="4"}
    local object11 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="input-index-2",["layer"]=40,["point"]={-4.279999999999999,-0.31},["size"]=10,["text"]="2"}
    local object12 = viewportScene1:rectangle {["center"]={-3.2699999999999996,0.08},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="input-cell-3",["layer"]=10,["size"]={0.94,0.66},["stroke"]="#5E7A9B",["width"]=1.2}
    local object13 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="input-value-3",["layer"]=40,["point"]={-3.2699999999999996,0.16},["size"]=16,["text"]="7"}
    local object14 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="input-index-3",["layer"]=40,["point"]={-3.2699999999999996,-0.31},["size"]=10,["text"]="3"}
    local object15 = viewportScene1:rectangle {["center"]={-2.26,0.08},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="input-cell-4",["layer"]=10,["size"]={0.94,0.66},["stroke"]="#5E7A9B",["width"]=1.2}
    local object16 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="input-value-4",["layer"]=40,["point"]={-2.26,0.16},["size"]=16,["text"]="11"}
    local object17 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="input-index-4",["layer"]=40,["point"]={-2.26,-0.31},["size"]=10,["text"]="4"}
    local object18 = viewportScene1:rectangle {["center"]={-1.25,0.08},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="input-cell-5",["layer"]=10,["size"]={0.94,0.66},["stroke"]="#5E7A9B",["width"]=1.2}
    local object19 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="input-value-5",["layer"]=40,["point"]={-1.25,0.16},["size"]=16,["text"]="18"}
    local object20 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="input-index-5",["layer"]=40,["point"]={-1.25,-0.31},["size"]=10,["text"]="5"}
    local object21 = viewportScene1:rectangle {["center"]={-0.23999999999999932,0.08},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="input-cell-6",["layer"]=10,["size"]={0.94,0.66},["stroke"]="#5E7A9B",["width"]=1.2}
    local object22 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="input-value-6",["layer"]=40,["point"]={-0.23999999999999932,0.16},["size"]=16,["text"]="23"}
    local object23 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="input-index-6",["layer"]=40,["point"]={-0.23999999999999932,-0.31},["size"]=10,["text"]="6"}
    local object24 = viewportScene1:rectangle {["center"]={0.7700000000000005,0.08},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="input-cell-7",["layer"]=10,["size"]={0.94,0.66},["stroke"]="#5E7A9B",["width"]=1.2}
    local object25 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="input-value-7",["layer"]=40,["point"]={0.7700000000000005,0.16},["size"]=16,["text"]="31"}
    local object26 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="input-index-7",["layer"]=40,["point"]={0.7700000000000005,-0.31},["size"]=10,["text"]="7"}
    local object27 = viewportScene1:rectangle {["center"]={1.7800000000000002,0.08},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="input-cell-8",["layer"]=10,["size"]={0.94,0.66},["stroke"]="#5E7A9B",["width"]=1.2}
    local object28 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="input-value-8",["layer"]=40,["point"]={1.7800000000000002,0.16},["size"]=16,["text"]="42"}
    local object29 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="input-index-8",["layer"]=40,["point"]={1.7800000000000002,-0.31},["size"]=10,["text"]="8"}
    local object30 = viewportScene1:rectangle {["center"]={2.79,0.08},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="input-cell-9",["layer"]=10,["size"]={0.94,0.66},["stroke"]="#5E7A9B",["width"]=1.2}
    local object31 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="input-value-9",["layer"]=40,["point"]={2.79,0.16},["size"]=16,["text"]="57"}
    local object32 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="input-index-9",["layer"]=40,["point"]={2.79,-0.31},["size"]=10,["text"]="9"}
    local object33 = viewportScene1:rectangle {["center"]={3.8,0.08},["corner"]=0.025,["fill"]="#F5E8E1",["id"]="input-cell-10",["layer"]=10,["size"]={0.94,0.66},["stroke"]="#9B3600",["width"]=2.4}
    local object34 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="input-value-10",["layer"]=40,["point"]={3.8,0.16},["size"]=16,["text"]="68"}
    local object35 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="input-index-10",["layer"]=40,["point"]={3.8,-0.31},["size"]=10,["text"]="10"}
    local object36 = viewportScene1:rectangle {["center"]={4.81,0.08},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="input-cell-11",["layer"]=10,["size"]={0.94,0.66},["stroke"]="#5E7A9B",["width"]=1.2}
    local object37 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="input-value-11",["layer"]=40,["point"]={4.81,0.16},["size"]=16,["text"]="79"}
    local object38 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="input-index-11",["layer"]=40,["point"]={4.81,-0.31},["size"]=10,["text"]="11"}
    local object39 = viewportScene1:rectangle {["center"]={5.820000000000001,0.08},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="input-cell-12",["layer"]=10,["size"]={0.94,0.66},["stroke"]="#5E7A9B",["width"]=1.2}
    local object40 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="input-value-12",["layer"]=40,["point"]={5.820000000000001,0.16},["size"]=16,["text"]="91"}
    local object41 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="input-index-12",["layer"]=40,["point"]={5.820000000000001,-0.31},["size"]=10,["text"]="12"}
    local object42 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="input-caption",["layer"]=40,["point"]={-9.18,-0.83},["size"]=13,["text"]="Value 68 is at index 10. Binary search compares only the current midpoint."}
    local object43 = viewportScene1:point {["fill"]="#9B3600",["id"]="input-target-marker",["layer"]=24,["opacity"]=0,["point"]={3.8,0.57},["radius"]=5,["stroke"]="#FFFFFF",["width"]=2}
    viewportScene1:wait(0.25)
    viewportScene1:play({{target=object43,opacity=1}},0.3,"gentle",0)
    viewportScene1:indicate(object33,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.7,["scale"]=1.035})
    viewportScene1:indicate(object34,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.055})
    viewportScene1:indicate(object35,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.6,["scale"]=1.1})
    viewportScene1:play({{target=object43,opacity=0}},0.3,"gentle",0)
    viewportScene1:wait(0.45)
    viewportScene1:play({{target=object43,opacity=1}},0.3,"gentle",0)
    viewportScene1:indicate(object33,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.7,["scale"]=1.035})
    viewportScene1:indicate(object34,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.055})
    viewportScene1:indicate(object35,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.6,["scale"]=1.1})
    viewportScene1:play({{target=object43,opacity=0}},0.3,"gentle",0)
    viewportScene1:wait(2.2)
    scene:viewport(viewportScene1,{["height"]=0.1144,["width"]=0.92,["x"]=0.04,["y"]=0.255})
end
do
    local viewportScene1 = tmath.scene {["background"]="#FFFFFF",["camera"]={["height"]=2.2,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=24,["height"]=114,["loop"]=false,["theme"]="pro_white",["width"]=1325}
    local object1 = viewportScene1:text {["align"]={0,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="trace-1-letter",["layer"]=40,["point"]={-12.28,0.45},["size"]=15,["text"]="C1"}
    local object2 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-1-title",["layer"]=40,["point"]={-12.28,-0.03},["size"]=16,["text"]="Comparison 1"}
    local object3 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-1-count",["layer"]=40,["point"]={-12.28,-0.52},["size"]=12,["text"]="13 candidates"}
    local object4 = viewportScene1:rectangle {["center"]={-7.25,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-1-cell-0",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object5 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-1-value-0",["layer"]=40,["point"]={-7.25,0.02},["size"]=13,["text"]="-12"}
    local object6 = viewportScene1:rectangle {["center"]={-6.32,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-1-cell-1",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object7 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-1-value-1",["layer"]=40,["point"]={-6.32,0.02},["size"]=13,["text"]="-3"}
    local object8 = viewportScene1:rectangle {["center"]={-5.39,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-1-cell-2",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object9 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-1-value-2",["layer"]=40,["point"]={-5.39,0.02},["size"]=13,["text"]="4"}
    local object10 = viewportScene1:rectangle {["center"]={-4.46,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-1-cell-3",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object11 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-1-value-3",["layer"]=40,["point"]={-4.46,0.02},["size"]=13,["text"]="7"}
    local object12 = viewportScene1:rectangle {["center"]={-3.53,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-1-cell-4",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object13 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-1-value-4",["layer"]=40,["point"]={-3.53,0.02},["size"]=13,["text"]="11"}
    local object14 = viewportScene1:rectangle {["center"]={-2.5999999999999996,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-1-cell-5",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object15 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-1-value-5",["layer"]=40,["point"]={-2.5999999999999996,0.02},["size"]=13,["text"]="18"}
    local object16 = viewportScene1:rectangle {["center"]={-1.67,0.02},["corner"]=0.025,["fill"]="#F4EEE5",["id"]="trace-1-cell-6",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#B8915A",["width"]=2.4}
    local object17 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-1-value-6",["layer"]=40,["point"]={-1.67,0.02},["size"]=13,["text"]="23"}
    local object18 = viewportScene1:rectangle {["center"]={-0.7399999999999993,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-1-cell-7",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object19 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-1-value-7",["layer"]=40,["point"]={-0.7399999999999993,0.02},["size"]=13,["text"]="31"}
    local object20 = viewportScene1:rectangle {["center"]={0.1900000000000004,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-1-cell-8",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object21 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-1-value-8",["layer"]=40,["point"]={0.1900000000000004,0.02},["size"]=13,["text"]="42"}
    local object22 = viewportScene1:rectangle {["center"]={1.120000000000001,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-1-cell-9",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object23 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-1-value-9",["layer"]=40,["point"]={1.120000000000001,0.02},["size"]=13,["text"]="57"}
    local object24 = viewportScene1:rectangle {["center"]={2.0500000000000007,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-1-cell-10",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object25 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-1-value-10",["layer"]=40,["point"]={2.0500000000000007,0.02},["size"]=13,["text"]="68"}
    local object26 = viewportScene1:rectangle {["center"]={2.9800000000000004,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-1-cell-11",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object27 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-1-value-11",["layer"]=40,["point"]={2.9800000000000004,0.02},["size"]=13,["text"]="79"}
    local object28 = viewportScene1:rectangle {["center"]={3.91,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-1-cell-12",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object29 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-1-value-12",["layer"]=40,["point"]={3.91,0.02},["size"]=13,["text"]="91"}
    local object30 = viewportScene1:line {["from"]={-7.64,-0.55},["id"]="trace-1-range",["layer"]=10,["stroke"]="#5E7A9B",["to"]={4.3,-0.55},["width"]=3}
    local object31 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-1-decision",["layer"]=40,["point"]={5.35,0.43},["size"]=15,["text"]="mid = 6  ·  23 < 68"}
    local object32 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-1-caption",["layer"]=40,["point"]={5.35,-0.16},["size"]=13,["text"]="lo = 7  →  keep right half"}
    local object33 = viewportScene1:point {["fill"]="#9B3600",["id"]="trace-1-mid-marker",["layer"]=24,["opacity"]=0,["point"]={-1.67,0.52},["radius"]=4.5,["stroke"]="#FFFFFF",["width"]=2}
    viewportScene1:wait(0.1)
    viewportScene1:play({{target=object33,opacity=1}},0.3,"gentle",0)
    viewportScene1:indicate(object16,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.035})
    viewportScene1:indicate(object17,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.6,["scale"]=1.055})
    viewportScene1:indicate(object31,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.035})
    viewportScene1:play({{target=object33,opacity=0}},0.3,"gentle",0)
    viewportScene1:wait(0.45)
    viewportScene1:play({{target=object33,opacity=1}},0.3,"gentle",0)
    viewportScene1:indicate(object16,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.035})
    viewportScene1:indicate(object17,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.6,["scale"]=1.055})
    viewportScene1:indicate(object31,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.035})
    viewportScene1:play({{target=object33,opacity=0}},0.3,"gentle",0)
    viewportScene1:wait(2.45)
    scene:viewport(viewportScene1,{["height"]=0.0781,["width"]=0.92,["x"]=0.04,["y"]=0.414})
end
do
    local viewportScene1 = tmath.scene {["background"]="#FFFFFF",["camera"]={["height"]=2.2,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=24,["height"]=114,["loop"]=false,["theme"]="pro_white",["width"]=1325}
    local object1 = viewportScene1:text {["align"]={0,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="trace-2-letter",["layer"]=40,["point"]={-12.28,0.45},["size"]=15,["text"]="C2"}
    local object2 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-2-title",["layer"]=40,["point"]={-12.28,-0.03},["size"]=16,["text"]="Comparison 2"}
    local object3 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-2-count",["layer"]=40,["point"]={-12.28,-0.52},["size"]=12,["text"]="6 candidates"}
    local object4 = viewportScene1:rectangle {["center"]={-7.25,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-2-cell-0",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object5 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-2-value-0",["layer"]=40,["point"]={-7.25,0.02},["size"]=13,["text"]="-12"}
    local object6 = viewportScene1:rectangle {["center"]={-6.32,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-2-cell-1",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object7 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-2-value-1",["layer"]=40,["point"]={-6.32,0.02},["size"]=13,["text"]="-3"}
    local object8 = viewportScene1:rectangle {["center"]={-5.39,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-2-cell-2",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object9 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-2-value-2",["layer"]=40,["point"]={-5.39,0.02},["size"]=13,["text"]="4"}
    local object10 = viewportScene1:rectangle {["center"]={-4.46,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-2-cell-3",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object11 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-2-value-3",["layer"]=40,["point"]={-4.46,0.02},["size"]=13,["text"]="7"}
    local object12 = viewportScene1:rectangle {["center"]={-3.53,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-2-cell-4",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object13 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-2-value-4",["layer"]=40,["point"]={-3.53,0.02},["size"]=13,["text"]="11"}
    local object14 = viewportScene1:rectangle {["center"]={-2.5999999999999996,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-2-cell-5",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object15 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-2-value-5",["layer"]=40,["point"]={-2.5999999999999996,0.02},["size"]=13,["text"]="18"}
    local object16 = viewportScene1:rectangle {["center"]={-1.67,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-2-cell-6",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object17 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-2-value-6",["layer"]=40,["point"]={-1.67,0.02},["size"]=13,["text"]="23"}
    local object18 = viewportScene1:rectangle {["center"]={-0.7399999999999993,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-2-cell-7",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object19 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-2-value-7",["layer"]=40,["point"]={-0.7399999999999993,0.02},["size"]=13,["text"]="31"}
    local object20 = viewportScene1:rectangle {["center"]={0.1900000000000004,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-2-cell-8",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object21 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-2-value-8",["layer"]=40,["point"]={0.1900000000000004,0.02},["size"]=13,["text"]="42"}
    local object22 = viewportScene1:rectangle {["center"]={1.120000000000001,0.02},["corner"]=0.025,["fill"]="#F4EEE5",["id"]="trace-2-cell-9",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#B8915A",["width"]=2.4}
    local object23 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-2-value-9",["layer"]=40,["point"]={1.120000000000001,0.02},["size"]=13,["text"]="57"}
    local object24 = viewportScene1:rectangle {["center"]={2.0500000000000007,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-2-cell-10",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object25 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-2-value-10",["layer"]=40,["point"]={2.0500000000000007,0.02},["size"]=13,["text"]="68"}
    local object26 = viewportScene1:rectangle {["center"]={2.9800000000000004,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-2-cell-11",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object27 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-2-value-11",["layer"]=40,["point"]={2.9800000000000004,0.02},["size"]=13,["text"]="79"}
    local object28 = viewportScene1:rectangle {["center"]={3.91,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-2-cell-12",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object29 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-2-value-12",["layer"]=40,["point"]={3.91,0.02},["size"]=13,["text"]="91"}
    local object30 = viewportScene1:line {["from"]={-1.1299999999999994,-0.55},["id"]="trace-2-range",["layer"]=10,["stroke"]="#5E7A9B",["to"]={4.3,-0.55},["width"]=3}
    local object31 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-2-decision",["layer"]=40,["point"]={5.35,0.43},["size"]=15,["text"]="mid = 9  ·  57 < 68"}
    local object32 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-2-caption",["layer"]=40,["point"]={5.35,-0.16},["size"]=13,["text"]="lo = 10  →  keep right half"}
    local object33 = viewportScene1:point {["fill"]="#9B3600",["id"]="trace-2-mid-marker",["layer"]=24,["opacity"]=0,["point"]={1.120000000000001,0.52},["radius"]=4.5,["stroke"]="#FFFFFF",["width"]=2}
    viewportScene1:wait(0.3)
    viewportScene1:play({{target=object33,opacity=1}},0.3,"gentle",0)
    viewportScene1:indicate(object22,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.035})
    viewportScene1:indicate(object23,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.6,["scale"]=1.055})
    viewportScene1:indicate(object31,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.035})
    viewportScene1:play({{target=object33,opacity=0}},0.3,"gentle",0)
    viewportScene1:wait(0.45)
    viewportScene1:play({{target=object33,opacity=1}},0.3,"gentle",0)
    viewportScene1:indicate(object22,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.035})
    viewportScene1:indicate(object23,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.6,["scale"]=1.055})
    viewportScene1:indicate(object31,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.035})
    viewportScene1:play({{target=object33,opacity=0}},0.3,"gentle",0)
    viewportScene1:wait(2.25)
    scene:viewport(viewportScene1,{["height"]=0.0781,["width"]=0.92,["x"]=0.04,["y"]=0.497})
end
do
    local viewportScene1 = tmath.scene {["background"]="#FFFFFF",["camera"]={["height"]=2.2,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=24,["height"]=114,["loop"]=false,["theme"]="pro_white",["width"]=1325}
    local object1 = viewportScene1:text {["align"]={0,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="trace-3-letter",["layer"]=40,["point"]={-12.28,0.45},["size"]=15,["text"]="C3"}
    local object2 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-3-title",["layer"]=40,["point"]={-12.28,-0.03},["size"]=16,["text"]="Comparison 3"}
    local object3 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-3-count",["layer"]=40,["point"]={-12.28,-0.52},["size"]=12,["text"]="3 candidates"}
    local object4 = viewportScene1:rectangle {["center"]={-7.25,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-3-cell-0",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object5 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-3-value-0",["layer"]=40,["point"]={-7.25,0.02},["size"]=13,["text"]="-12"}
    local object6 = viewportScene1:rectangle {["center"]={-6.32,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-3-cell-1",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object7 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-3-value-1",["layer"]=40,["point"]={-6.32,0.02},["size"]=13,["text"]="-3"}
    local object8 = viewportScene1:rectangle {["center"]={-5.39,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-3-cell-2",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object9 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-3-value-2",["layer"]=40,["point"]={-5.39,0.02},["size"]=13,["text"]="4"}
    local object10 = viewportScene1:rectangle {["center"]={-4.46,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-3-cell-3",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object11 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-3-value-3",["layer"]=40,["point"]={-4.46,0.02},["size"]=13,["text"]="7"}
    local object12 = viewportScene1:rectangle {["center"]={-3.53,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-3-cell-4",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object13 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-3-value-4",["layer"]=40,["point"]={-3.53,0.02},["size"]=13,["text"]="11"}
    local object14 = viewportScene1:rectangle {["center"]={-2.5999999999999996,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-3-cell-5",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object15 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-3-value-5",["layer"]=40,["point"]={-2.5999999999999996,0.02},["size"]=13,["text"]="18"}
    local object16 = viewportScene1:rectangle {["center"]={-1.67,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-3-cell-6",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object17 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-3-value-6",["layer"]=40,["point"]={-1.67,0.02},["size"]=13,["text"]="23"}
    local object18 = viewportScene1:rectangle {["center"]={-0.7399999999999993,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-3-cell-7",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object19 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-3-value-7",["layer"]=40,["point"]={-0.7399999999999993,0.02},["size"]=13,["text"]="31"}
    local object20 = viewportScene1:rectangle {["center"]={0.1900000000000004,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-3-cell-8",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object21 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-3-value-8",["layer"]=40,["point"]={0.1900000000000004,0.02},["size"]=13,["text"]="42"}
    local object22 = viewportScene1:rectangle {["center"]={1.120000000000001,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-3-cell-9",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object23 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-3-value-9",["layer"]=40,["point"]={1.120000000000001,0.02},["size"]=13,["text"]="57"}
    local object24 = viewportScene1:rectangle {["center"]={2.0500000000000007,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-3-cell-10",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object25 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-3-value-10",["layer"]=40,["point"]={2.0500000000000007,0.02},["size"]=13,["text"]="68"}
    local object26 = viewportScene1:rectangle {["center"]={2.9800000000000004,0.02},["corner"]=0.025,["fill"]="#F4EEE5",["id"]="trace-3-cell-11",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#B8915A",["width"]=2.4}
    local object27 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-3-value-11",["layer"]=40,["point"]={2.9800000000000004,0.02},["size"]=13,["text"]="79"}
    local object28 = viewportScene1:rectangle {["center"]={3.91,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-3-cell-12",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object29 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-3-value-12",["layer"]=40,["point"]={3.91,0.02},["size"]=13,["text"]="91"}
    local object30 = viewportScene1:line {["from"]={1.6600000000000006,-0.55},["id"]="trace-3-range",["layer"]=10,["stroke"]="#5E7A9B",["to"]={4.3,-0.55},["width"]=3}
    local object31 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-3-decision",["layer"]=40,["point"]={5.35,0.43},["size"]=15,["text"]="mid = 11  ·  79 > 68"}
    local object32 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-3-caption",["layer"]=40,["point"]={5.35,-0.16},["size"]=13,["text"]="hi = 10  →  keep left half"}
    local object33 = viewportScene1:point {["fill"]="#9B3600",["id"]="trace-3-mid-marker",["layer"]=24,["opacity"]=0,["point"]={2.9800000000000004,0.52},["radius"]=4.5,["stroke"]="#FFFFFF",["width"]=2}
    viewportScene1:wait(0.5)
    viewportScene1:play({{target=object33,opacity=1}},0.3,"gentle",0)
    viewportScene1:indicate(object26,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.035})
    viewportScene1:indicate(object27,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.6,["scale"]=1.055})
    viewportScene1:indicate(object31,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.035})
    viewportScene1:play({{target=object33,opacity=0}},0.3,"gentle",0)
    viewportScene1:wait(0.45)
    viewportScene1:play({{target=object33,opacity=1}},0.3,"gentle",0)
    viewportScene1:indicate(object26,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.035})
    viewportScene1:indicate(object27,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.6,["scale"]=1.055})
    viewportScene1:indicate(object31,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.035})
    viewportScene1:play({{target=object33,opacity=0}},0.3,"gentle",0)
    viewportScene1:wait(2.05)
    scene:viewport(viewportScene1,{["height"]=0.0781,["width"]=0.92,["x"]=0.04,["y"]=0.58})
end
do
    local viewportScene1 = tmath.scene {["background"]="#FFFFFF",["camera"]={["height"]=2.2,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=24,["height"]=114,["loop"]=false,["theme"]="pro_white",["width"]=1325}
    local object1 = viewportScene1:text {["align"]={0,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="trace-4-letter",["layer"]=40,["point"]={-12.28,0.45},["size"]=15,["text"]="C4"}
    local object2 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-4-title",["layer"]=40,["point"]={-12.28,-0.03},["size"]=16,["text"]="Comparison 4"}
    local object3 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-4-count",["layer"]=40,["point"]={-12.28,-0.52},["size"]=12,["text"]="1 candidates"}
    local object4 = viewportScene1:rectangle {["center"]={-7.25,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-4-cell-0",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object5 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-4-value-0",["layer"]=40,["point"]={-7.25,0.02},["size"]=13,["text"]="-12"}
    local object6 = viewportScene1:rectangle {["center"]={-6.32,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-4-cell-1",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object7 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-4-value-1",["layer"]=40,["point"]={-6.32,0.02},["size"]=13,["text"]="-3"}
    local object8 = viewportScene1:rectangle {["center"]={-5.39,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-4-cell-2",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object9 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-4-value-2",["layer"]=40,["point"]={-5.39,0.02},["size"]=13,["text"]="4"}
    local object10 = viewportScene1:rectangle {["center"]={-4.46,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-4-cell-3",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object11 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-4-value-3",["layer"]=40,["point"]={-4.46,0.02},["size"]=13,["text"]="7"}
    local object12 = viewportScene1:rectangle {["center"]={-3.53,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-4-cell-4",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object13 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-4-value-4",["layer"]=40,["point"]={-3.53,0.02},["size"]=13,["text"]="11"}
    local object14 = viewportScene1:rectangle {["center"]={-2.5999999999999996,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-4-cell-5",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object15 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-4-value-5",["layer"]=40,["point"]={-2.5999999999999996,0.02},["size"]=13,["text"]="18"}
    local object16 = viewportScene1:rectangle {["center"]={-1.67,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-4-cell-6",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object17 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-4-value-6",["layer"]=40,["point"]={-1.67,0.02},["size"]=13,["text"]="23"}
    local object18 = viewportScene1:rectangle {["center"]={-0.7399999999999993,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-4-cell-7",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object19 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-4-value-7",["layer"]=40,["point"]={-0.7399999999999993,0.02},["size"]=13,["text"]="31"}
    local object20 = viewportScene1:rectangle {["center"]={0.1900000000000004,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-4-cell-8",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object21 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-4-value-8",["layer"]=40,["point"]={0.1900000000000004,0.02},["size"]=13,["text"]="42"}
    local object22 = viewportScene1:rectangle {["center"]={1.120000000000001,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-4-cell-9",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object23 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-4-value-9",["layer"]=40,["point"]={1.120000000000001,0.02},["size"]=13,["text"]="57"}
    local object24 = viewportScene1:rectangle {["center"]={2.0500000000000007,0.02},["corner"]=0.025,["fill"]="#F5E8E1",["id"]="trace-4-cell-10",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#9B3600",["width"]=2.4}
    local object25 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-4-value-10",["layer"]=40,["point"]={2.0500000000000007,0.02},["size"]=13,["text"]="68"}
    local object26 = viewportScene1:rectangle {["center"]={2.9800000000000004,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-4-cell-11",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object27 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-4-value-11",["layer"]=40,["point"]={2.9800000000000004,0.02},["size"]=13,["text"]="79"}
    local object28 = viewportScene1:rectangle {["center"]={3.91,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-4-cell-12",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object29 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-4-value-12",["layer"]=40,["point"]={3.91,0.02},["size"]=13,["text"]="91"}
    local object30 = viewportScene1:line {["from"]={1.6600000000000006,-0.55},["id"]="trace-4-range",["layer"]=10,["stroke"]="#9B3600",["to"]={2.440000000000001,-0.55},["width"]=3}
    local object31 = viewportScene1:text {["align"]={0,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="trace-4-decision",["layer"]=40,["point"]={5.35,0.43},["size"]=15,["text"]="mid = 10  ·  68 = 68"}
    local object32 = viewportScene1:text {["align"]={0,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="trace-4-caption",["layer"]=40,["point"]={5.35,-0.16},["size"]=13,["text"]="return 10  →  search complete"}
    local object33 = viewportScene1:point {["fill"]="#9B3600",["id"]="trace-4-mid-marker",["layer"]=24,["opacity"]=0,["point"]={2.0500000000000007,0.52},["radius"]=4.5,["stroke"]="#FFFFFF",["width"]=2}
    viewportScene1:wait(0.7)
    viewportScene1:play({{target=object33,opacity=1}},0.3,"gentle",0)
    viewportScene1:indicate(object24,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.035})
    viewportScene1:indicate(object25,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.6,["scale"]=1.055})
    viewportScene1:indicate(object31,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.035})
    viewportScene1:play({{target=object33,opacity=0}},0.3,"gentle",0)
    viewportScene1:wait(0.45)
    viewportScene1:play({{target=object33,opacity=1}},0.3,"gentle",0)
    viewportScene1:indicate(object24,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.035})
    viewportScene1:indicate(object25,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.6,["scale"]=1.055})
    viewportScene1:indicate(object31,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.035})
    viewportScene1:play({{target=object33,opacity=0}},0.3,"gentle",0)
    viewportScene1:wait(1.8500000000000005)
    scene:viewport(viewportScene1,{["height"]=0.0781,["width"]=0.92,["x"]=0.04,["y"]=0.663})
end
do
    local viewportScene1 = tmath.scene {["background"]="#FFFFFF",["camera"]={["height"]=6.4,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=24,["height"]=316,["loop"]=false,["theme"]="pro_white",["width"]=439}
    local object1 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="complexity-title",["layer"]=40,["point"]={-4.05,2.63},["size"]=18,["text"]="D  ·  Candidate count"}
    local object2 = viewportScene1:text {["align"]={0,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="complexity-sequence",["layer"]=40,["point"]={-4.05,2.08},["role"]="code",["size"]=14,["text"]="13 → 6 → 3 → 1"}
    local object3 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="complexity-count-13",["layer"]=40,["point"]={-4.02,1.25},["size"]=13,["text"]="13"}
    local object4 = viewportScene1:rectangle {["center"]={-0.3999999999999999,1.25},["corner"]=0.015,["fill"]="#5E7A9B",["id"]="complexity-bar-13",["layer"]=10,["size"]={5.9,0.26},["stroke"]="#5E7A9B",["width"]=1}
    local object5 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="complexity-count-6",["layer"]=40,["point"]={-4.02,0.53},["size"]=13,["text"]="6"}
    local object6 = viewportScene1:rectangle {["center"]={-1.9884615384615383,0.53},["corner"]=0.015,["fill"]="#5E7A9B",["id"]="complexity-bar-6",["layer"]=10,["size"]={2.7230769230769236,0.26},["stroke"]="#5E7A9B",["width"]=1}
    local object7 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="complexity-count-3",["layer"]=40,["point"]={-4.02,-0.18999999999999995},["size"]=13,["text"]="3"}
    local object8 = viewportScene1:rectangle {["center"]={-2.669230769230769,-0.18999999999999995},["corner"]=0.015,["fill"]="#5E7A9B",["id"]="complexity-bar-3",["layer"]=10,["size"]={1.3615384615384618,0.26},["stroke"]="#5E7A9B",["width"]=1}
    local object9 = viewportScene1:text {["align"]={0,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="complexity-count-1",["layer"]=40,["point"]={-4.02,-0.9100000000000001},["size"]=13,["text"]="1"}
    local object10 = viewportScene1:rectangle {["center"]={-3.123076923076923,-0.9100000000000001},["corner"]=0.015,["fill"]="#9B3600",["id"]="complexity-bar-1",["layer"]=10,["size"]={0.4538461538461539,0.26},["stroke"]="#9B3600",["width"]=1}
    local object11 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="complexity-caption-1",["layer"]=40,["point"]={-4.05,-1.76},["size"]=12,["text"]="Each comparison roughly halves the candidate set."}
    local object12 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="complexity-caption-2",["layer"]=40,["point"]={-4.05,-2.28},["size"]=15,["text"]="Therefore: O(log n) comparisons."}
    local object13 = viewportScene1:point {["fill"]="#9B3600",["id"]="complexity-marker",["layer"]=24,["opacity"]=0,["point"]={2.5500000000000003,1.25},["radius"]=5,["stroke"]="#FFFFFF",["width"]=2}
    viewportScene1:wait(0.2)
    viewportScene1:play({{target=object13,opacity=1}},0.18,"gentle",0)
    viewportScene1:shift(object13,{-3.1769230769230767,-0.72},0.52,"ease_in_out")
    viewportScene1:shift(object13,{-1.3615384615384618,-0.72},0.52,"ease_in_out")
    viewportScene1:shift(object13,{-0.9076923076923078,-0.7200000000000002},0.52,"ease_in_out")
    viewportScene1:indicate(object10,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.46,["scale"]=1.035})
    viewportScene1:shift(object13,{5.446153846153846,2.16},0.82,"ease_in_out")
    viewportScene1:play({{target=object13,opacity=0}},0.18,"gentle",0)
    viewportScene1:wait(0.35)
    viewportScene1:play({{target=object13,opacity=1}},0.18,"gentle",0)
    viewportScene1:shift(object13,{-3.1769230769230767,-0.72},0.52,"ease_in_out")
    viewportScene1:shift(object13,{-1.3615384615384618,-0.72},0.52,"ease_in_out")
    viewportScene1:shift(object13,{-0.9076923076923078,-0.7200000000000002},0.52,"ease_in_out")
    viewportScene1:indicate(object10,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.46,["scale"]=1.035})
    viewportScene1:shift(object13,{5.446153846153846,2.16},0.82,"ease_in_out")
    viewportScene1:play({{target=object13,opacity=0}},0.18,"gentle",0)
    viewportScene1:wait(1.0499999999999998)
    scene:viewport(viewportScene1,{["height"]=0.216,["width"]=0.305,["x"]=0.04,["y"]=0.773})
end
do
    local viewportScene1 = tmath.scene {["background"]="#FFFFFF",["camera"]={["height"]=6.4,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=24,["height"]=316,["loop"]=false,["theme"]="pro_white",["width"]=504}
    local object1 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="invariant-title",["layer"]=40,["point"]={-4.72,2.63},["size"]=18,["text"]="E  ·  Range invariant"}
    local object2 = viewportScene1:text {["align"]={1,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="invariant-formula",["layer"]=40,["point"]={4.72,2.63},["role"]="code",["size"]=14,["text"]="68 ∈ a[lo ... hi]"}
    local object3 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="invariant-range-0",["layer"]=40,["point"]={-4.7,1.34},["size"]=12,["text"]="[0, 12]"}
    local object4 = viewportScene1:line {["from"]={-3.25,1.34},["id"]="invariant-line-0",["layer"]=10,["stroke"]="#5E7A9B",["to"]={3.85,1.34},["width"]=3}
    local object5 = viewportScene1:line {["from"]={-3.25,1.21},["id"]="invariant-left-0",["layer"]=10,["stroke"]="#5E7A9B",["to"]={-3.25,1.4700000000000002},["width"]=2}
    local object6 = viewportScene1:line {["from"]={3.85,1.21},["id"]="invariant-right-0",["layer"]=10,["stroke"]="#5E7A9B",["to"]={3.85,1.4700000000000002},["width"]=2}
    local object7 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="invariant-range-1",["layer"]=40,["point"]={-4.7,0.62},["size"]=12,["text"]="[7, 12]"}
    local object8 = viewportScene1:line {["from"]={0.35,0.62},["id"]="invariant-line-1",["layer"]=10,["stroke"]="#5E7A9B",["to"]={3.85,0.62},["width"]=3}
    local object9 = viewportScene1:line {["from"]={0.35,0.49},["id"]="invariant-left-1",["layer"]=10,["stroke"]="#5E7A9B",["to"]={0.35,0.75},["width"]=2}
    local object10 = viewportScene1:line {["from"]={3.85,0.49},["id"]="invariant-right-1",["layer"]=10,["stroke"]="#5E7A9B",["to"]={3.85,0.75},["width"]=2}
    local object11 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="invariant-range-2",["layer"]=40,["point"]={-4.7,-0.1},["size"]=12,["text"]="[10, 12]"}
    local object12 = viewportScene1:line {["from"]={1.72,-0.1},["id"]="invariant-line-2",["layer"]=10,["stroke"]="#5E7A9B",["to"]={3.85,-0.1},["width"]=3}
    local object13 = viewportScene1:line {["from"]={1.72,-0.23},["id"]="invariant-left-2",["layer"]=10,["stroke"]="#5E7A9B",["to"]={1.72,0.03},["width"]=2}
    local object14 = viewportScene1:line {["from"]={3.85,-0.23},["id"]="invariant-right-2",["layer"]=10,["stroke"]="#5E7A9B",["to"]={3.85,0.03},["width"]=2}
    local object15 = viewportScene1:text {["align"]={0,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="invariant-range-3",["layer"]=40,["point"]={-4.7,-0.82},["size"]=12,["text"]="[10, 10]"}
    local object16 = viewportScene1:line {["from"]={1.72,-0.82},["id"]="invariant-line-3",["layer"]=10,["stroke"]="#9B3600",["to"]={2.04,-0.82},["width"]=5}
    local object17 = viewportScene1:line {["from"]={1.72,-0.95},["id"]="invariant-left-3",["layer"]=10,["stroke"]="#9B3600",["to"]={1.72,-0.69},["width"]=2}
    local object18 = viewportScene1:line {["from"]={2.04,-0.95},["id"]="invariant-right-3",["layer"]=10,["stroke"]="#9B3600",["to"]={2.04,-0.69},["width"]=2}
    local object19 = viewportScene1:line {["dash"]={5,5},["from"]={1.88,1.62},["id"]="invariant-target-line",["layer"]=10,["stroke"]="#9B3600",["to"]={1.88,-1.1},["width"]=2}
    local object20 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="invariant-target-label",["layer"]=40,["point"]={1.88,1.92},["size"]=13,["text"]="68"}
    local object21 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="invariant-caption-1",["layer"]=40,["point"]={-4.72,-1.72},["size"]=12,["text"]="Discard only the half contradicted by the comparison."}
    local object22 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="invariant-caption-2",["layer"]=40,["point"]={-4.72,-2.24},["size"]=15,["text"]="Target 68 remains inside every retained interval."}
    local object23 = viewportScene1:point {["fill"]="#9B3600",["id"]="invariant-marker",["layer"]=24,["opacity"]=0,["point"]={1.88,1.34},["radius"]=6,["stroke"]="#FFFFFF",["width"]=2}
    viewportScene1:wait(0.35)
    viewportScene1:play({{target=object23,opacity=1}},0.18,"gentle",0)
    viewportScene1:shift(object23,{0,-0.7200000000000001},0.48,"ease_in_out")
    viewportScene1:shift(object23,{0,-0.72},0.48,"ease_in_out")
    viewportScene1:shift(object23,{0,-0.72},0.48,"ease_in_out")
    viewportScene1:indicate(object19,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.46,["scale"]=1.018})
    viewportScene1:shift(object23,{0,2.16},0.82,"ease_in_out")
    viewportScene1:play({{target=object23,opacity=0}},0.18,"gentle",0)
    viewportScene1:wait(0.35)
    viewportScene1:play({{target=object23,opacity=1}},0.18,"gentle",0)
    viewportScene1:shift(object23,{0,-0.7200000000000001},0.48,"ease_in_out")
    viewportScene1:shift(object23,{0,-0.72},0.48,"ease_in_out")
    viewportScene1:shift(object23,{0,-0.72},0.48,"ease_in_out")
    viewportScene1:indicate(object19,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.46,["scale"]=1.018})
    viewportScene1:shift(object23,{0,2.16},0.82,"ease_in_out")
    viewportScene1:play({{target=object23,opacity=0}},0.18,"gentle",0)
    viewportScene1:wait(1.1399999999999997)
    scene:viewport(viewportScene1,{["height"]=0.216,["width"]=0.35,["x"]=0.37,["y"]=0.773})
end
do
    local viewportScene1 = tmath.scene {["background"]="#FFFFFF",["camera"]={["height"]=6.4,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=24,["height"]=316,["loop"]=false,["theme"]="pro_white",["width"]=324}
    local object1 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="result-title",["layer"]=40,["point"]={-2.98,2.63},["size"]=18,["text"]="F  ·  Result"}
    local object2 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#5E7A9B",["font"]="Pretendard",["id"]="result-access",["layer"]=40,["point"]={-1.65,1.28},["role"]="code",["size"]=18,["text"]="a[10]"}
    local object3 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="result-equals",["layer"]=40,["point"]={0,1.28},["size"]=18,["text"]="="}
    local object4 = viewportScene1:circle {["center"]={1.62,1.28},["fill"]="#F5E8E1",["id"]="result-ring",["layer"]=10,["radius"]=0.54,["stroke"]="#9B3600",["width"]=2.5}
    local object5 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="result-value",["layer"]=40,["point"]={1.62,1.28},["size"]=20,["text"]="68"}
    local object6 = viewportScene1:line {["from"]={-2.35,0.38},["id"]="result-rule",["stroke"]="#D8DADD",["to"]={2.35,0.38},["width"]=1}
    local object7 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="result-return",["layer"]=40,["point"]={0,-0.3},["role"]="code",["size"]=25,["text"]="return 10"}
    local object8 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="result-caption-1",["layer"]=40,["point"]={-2.98,-1.45},["size"]=12,["text"]="Equality terminates the search."}
    local object9 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="result-caption-2",["layer"]=40,["point"]={-2.98,-1.98},["size"]=15,["text"]="Return index 10."}
    local object10 = viewportScene1:point {["fill"]="#9B3600",["id"]="result-token",["layer"]=24,["opacity"]=0,["point"]={-1.65,0.82},["radius"]=5,["stroke"]="#FFFFFF",["width"]=2}
    viewportScene1:wait(0.35)
    viewportScene1:play({{target=object10,opacity=1}},0.18,"gentle",0)
    viewportScene1:shift(object10,{3.27,0},0.85,"gentle")
    viewportScene1:indicate(object4,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.5,["scale"]=1.035})
    viewportScene1:shift(object10,{-3.27,0},0.85,"gentle")
    viewportScene1:play({{target=object10,opacity=0}},0.18,"gentle",0)
    viewportScene1:wait(0.45)
    viewportScene1:play({{target=object10,opacity=1}},0.18,"gentle",0)
    viewportScene1:shift(object10,{3.27,0},0.85,"gentle")
    viewportScene1:indicate(object4,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.5,["scale"]=1.035})
    viewportScene1:shift(object10,{-3.27,0},0.85,"gentle")
    viewportScene1:play({{target=object10,opacity=0}},0.18,"gentle",0)
    viewportScene1:wait(2.08)
    scene:viewport(viewportScene1,{["height"]=0.216,["width"]=0.225,["x"]=0.735,["y"]=0.773})
end
return scene
`,
        js: `// Browser-editable binary-search cheatsheet for the WASM playground.
const WIDTH = 1440;
const HEIGHT = 1460;
const FPS = 24;
const DURATION = 8;
const TARGET = 68;
const VALUES = [-12, -3, 4, 7, 11, 18, 23, 31, 42, 57, 68, 79, 91];

const C = {
    paper: "#FFFFFF",
    ink: "#202124",
    muted: "#555B64",
    soft: "#F3F4F5",
    rule: "#D8DADD",
    accent: "#9B3600",
    accentWash: "#F5E8E1",
    blue: "#5E7A9B",
    blueWash: "#E9EEF3",
    mustard: "#B8915A",
    mustardWash: "#F4EEE5",
};

const LAYER = {structure: 0, data: 10, cursor: 24, text: 40};
const ROOT_TEXT_IDS = [];
const TEXT_CONTENTS = [];

function addText(parent, ids, options) {
    ids.push(options.id);
    TEXT_CONTENTS.push(options.text);
    return parent.text({font: "Pretendard", layer: LAYER.text, ...options});
}

function rootText(parent, options) {
    return addText(parent, ROOT_TEXT_IDS, options);
}

function moduleScene({id, width, height, cameraHeight}) {
    const textIds = [];
    const scene = tmath.scene({
        width,
        height,
        fps: FPS,
        loop: false,
        theme: "pro_white",
        background: C.paper,
        camera: {mode: "fixed", view: "2d", target: [0, 0], height: cameraHeight},
    });
    const text = (parent, options) => addText(parent, textIds, options);
    return {id, scene, text, textIds, nonIntersectPairs: [], width, height};
}

function waitTo(scene, elapsed, target) {
    const remaining = target - elapsed;
    if (remaining < -1e-9) throw new Error(\`Module exceeds \${target}s by \${-remaining}s\`);
    if (remaining > 1e-9) scene.wait(remaining);
    return target;
}

function arrayX(index, start, step) {
    return start + index * step;
}

function addArrayCells(parent, text, {
    prefix,
    y,
    start,
    step,
    cellSize,
    activeLo = 0,
    activeHi = VALUES.length - 1,
    mid = -1,
    targetIndex = -1,
    found = false,
    showIndex = false,
}) {
    const cells = [];
    const valueLabels = [];
    const indexLabels = [];
    VALUES.forEach((value, index) => {
        const active = index >= activeLo && index <= activeHi;
        const isMid = index === mid;
        const isTarget = index === targetIndex;
        const fill = isTarget
            ? C.accentWash
            : isMid
                ? found ? C.accentWash : C.mustardWash
                : active ? C.blueWash : C.soft;
        const stroke = isTarget
            ? C.accent
            : isMid
                ? found ? C.accent : C.mustard
                : active ? C.blue : C.rule;
        const valueColor = active || isTarget ? C.ink : C.muted;
        const x = arrayX(index, start, step);
        const cell = parent.rectangle({
            center: [x, y],
            size: cellSize,
            corner: 0.025,
            fill,
            stroke,
            width: isTarget || isMid ? 2.4 : 1.2,
            layer: LAYER.data,
            id: \`\${prefix}-cell-\${index}\`,
        });
        cells.push(cell);
        const valueLabel = text(parent, {
            text: String(value),
            point: [x, y + (showIndex ? 0.08 : 0)],
            align: [0.5, 0.5],
            size: showIndex ? 16 : 13,
            fill: valueColor,
            id: \`\${prefix}-value-\${index}\`,
        });
        valueLabels.push(valueLabel);
        if (showIndex) {
            const indexLabel = text(parent, {
                text: String(index),
                point: [x, y - 0.39],
                align: [0.5, 0.5],
                size: 10,
                fill: isTarget ? C.accent : C.muted,
                id: \`\${prefix}-index-\${index}\`,
            });
            indexLabels.push(indexLabel);
        } else {
            indexLabels.push(null);
        }
    });
    return {cells, valueLabels, indexLabels};
}

function scheduleInput(module, marker, targetCell, targetValue, targetIndexLabel) {
    const {scene} = module;
    let elapsed = 0;
    const wait = (duration) => { scene.wait(duration); elapsed += duration; };
    const play = (spec, duration, curve = "ease_in_out") => {
        scene.play(spec, duration, curve, 0);
        elapsed += duration;
    };
    const cycle = () => {
        play({target: marker, opacity: 1}, 0.30, "gentle");
        scene.indicate(targetCell, {color: C.accent, scale: 1.035, duration: 0.70, curve: "gentle"});
        elapsed += 0.70;
        scene.indicate(targetValue, {color: C.accent, scale: 1.055, duration: 0.65, curve: "gentle"});
        elapsed += 0.65;
        scene.indicate(targetIndexLabel, {color: C.accent, scale: 1.10, duration: 0.60, curve: "gentle"});
        elapsed += 0.60;
        play({target: marker, opacity: 0}, 0.30, "gentle");
    };

    wait(0.25);
    cycle();
    wait(0.45);
    cycle();
    elapsed = waitTo(scene, elapsed, DURATION);
    return elapsed;
}

function makePseudocodeModule() {
    const module = moduleScene({id: "pseudocode", width: 1325, height: 190, cameraHeight: 2.65});
    const {scene, text} = module;
    text(scene, {
        text: "A  ·  Pseudocode",
        point: [-8.82, 1.10],
        align: [0, 0.5],
        size: 16,
        fill: C.ink,
        id: "pseudocode-title",
    });
    text(scene, {
        text: "Closed candidate interval [lo, hi]",
        point: [8.82, 1.10],
        align: [1, 0.5],
        size: 12,
        fill: C.accent,
        role: "code",
        id: "pseudocode-contract",
    });

    const lines = [
        "1  lo ← 0; hi ← n - 1",
        "2  while lo ≤ hi",
        "3    mid ← floor((lo + hi) / 2)",
        "4    if a[mid] < target: lo ← mid + 1",
        "5    else if a[mid] > target: hi ← mid - 1",
        "6    else: return mid",
        "7  return NOT_FOUND",
    ];
    const y0 = 0.72;
    const step = 0.29;
    lines.forEach((line, index) => text(scene, {
        text: line,
        point: [-8.76, y0 - index * step],
        align: [0, 0.5],
        size: 12.5,
        fill: C.ink,
        role: "code",
        id: \`pseudocode-line-\${index + 1}\`,
    }));

    scene.line({
        from: [0.72, 0.84],
        to: [0.72, -1.16],
        stroke: C.rule,
        width: 1,
        id: "pseudocode-divider",
    });
    const mappings = [
        {range: "L1–3", destination: "B INPUT · C1–C4 TRACE", y: 0.43},
        {range: "L4–5", destination: "D CANDIDATES · E INVARIANT", y: -0.30},
        {range: "L6–7", destination: "F RESULT", y: -0.88},
    ];
    mappings.forEach((mapping, index) => {
        text(scene, {
            text: mapping.range,
            point: [1.18, mapping.y],
            align: [0, 0.5],
            size: 12,
            fill: C.accent,
            role: "code",
            id: \`pseudocode-map-range-\${index + 1}\`,
        });
        text(scene, {
            text: \`→  \${mapping.destination}\`,
            point: [2.65, mapping.y],
            align: [0, 0.5],
            size: 12,
            fill: C.muted,
            id: \`pseudocode-map-destination-\${index + 1}\`,
        });
    });

    const highlights = [
        scene.rectangle({center: [-4.05, 0.43], size: [9.05, 0.82], corner: 0.025, fill: C.accent, stroke: "#00000000", opacity: 0, layer: LAYER.structure, id: "pseudocode-highlight-1"}),
        scene.rectangle({center: [-4.05, -0.295], size: [9.05, 0.54], corner: 0.025, fill: C.accent, stroke: "#00000000", opacity: 0, layer: LAYER.structure, id: "pseudocode-highlight-2"}),
        scene.rectangle({center: [-4.05, -0.875], size: [9.05, 0.54], corner: 0.025, fill: C.accent, stroke: "#00000000", opacity: 0, layer: LAYER.structure, id: "pseudocode-highlight-3"}),
    ];
    scene.wait(0.20);
    for (let cycle = 0; cycle < 2; cycle += 1) {
        for (const highlight of highlights) {
            scene.play({target: highlight, opacity: 0.12}, 0.45, "gentle", 0)
                .wait(0.25)
                .play({target: highlight, opacity: 0}, 0.45, "gentle", 0);
        }
        if (cycle === 0) scene.wait(0.20);
    }
    scene.wait(0.70);
    return {...module, peakTime: 0.43, claim: "pseudocode maps initialization, range updates, and returns to the detailed figures"};
}

function makeInputModule() {
    const module = moduleScene({id: "input", width: 1325, height: 167, cameraHeight: 2.35});
    const {scene, text} = module;
    text(scene, {
        text: "B  ·  Sorted input and target",
        point: [-9.18, 0.82],
        align: [0, 0.5],
        size: 17,
        fill: C.ink,
        id: "input-title",
    });
    text(scene, {
        text: "target = 68",
        point: [9.18, 0.82],
        align: [1, 0.5],
        size: 15,
        fill: C.accent,
        role: "code",
        id: "input-target-code",
    });

    const start = -6.3;
    const step = 1.01;
    const {cells, valueLabels, indexLabels} = addArrayCells(scene, text, {
        prefix: "input",
        y: 0.08,
        start,
        step,
        cellSize: [0.94, 0.66],
        targetIndex: 10,
        showIndex: true,
    });
    text(scene, {
        text: "Value 68 is at index 10. Binary search compares only the current midpoint.",
        point: [-9.18, -0.83],
        align: [0, 0.5],
        size: 13,
        fill: C.muted,
        id: "input-caption",
    });

    const targetX = arrayX(10, start, step);
    const marker = scene.point({
        point: [targetX, 0.57],
        radius: 5,
        fill: C.accent,
        stroke: C.paper,
        width: 2,
        opacity: 0,
        layer: LAYER.cursor,
        id: "input-target-marker",
    });
    scheduleInput(module, marker, cells[10], valueLabels[10], indexLabels[10]);
    return {...module, peakTime: 1.58, claim: "value 68 and index 10 are identified without implying a linear scan"};
}

const TRACE = [
    {id: "trace-1", letter: "C1", lo: 0, hi: 12, mid: 6, value: 23, candidates: 13, decision: "23 < 68", next: "lo = 7", direction: "keep right half", phase: 0.10},
    {id: "trace-2", letter: "C2", lo: 7, hi: 12, mid: 9, value: 57, candidates: 6, decision: "57 < 68", next: "lo = 10", direction: "keep right half", phase: 0.30},
    {id: "trace-3", letter: "C3", lo: 10, hi: 12, mid: 11, value: 79, candidates: 3, decision: "79 > 68", next: "hi = 10", direction: "keep left half", phase: 0.50},
    {id: "trace-4", letter: "C4", lo: 10, hi: 10, mid: 10, value: 68, candidates: 1, decision: "68 = 68", next: "return 10", direction: "search complete", phase: 0.70},
];

function scheduleTrace(module, marker, pivotCell, pivotValue, decisionLabel, phase) {
    const {scene} = module;
    let elapsed = 0;
    const wait = (duration) => { scene.wait(duration); elapsed += duration; };
    const play = (spec, duration, curve = "ease_in_out") => {
        scene.play(spec, duration, curve, 0);
        elapsed += duration;
    };
    const cycle = () => {
        play({target: marker, opacity: 1}, 0.30, "gentle");
        scene.indicate(pivotCell, {color: C.accent, scale: 1.035, duration: 0.65, curve: "gentle"});
        elapsed += 0.65;
        scene.indicate(pivotValue, {color: C.accent, scale: 1.055, duration: 0.60, curve: "gentle"});
        elapsed += 0.60;
        scene.indicate(decisionLabel, {color: C.accent, scale: 1.035, duration: 0.65, curve: "gentle"});
        elapsed += 0.65;
        play({target: marker, opacity: 0}, 0.30, "gentle");
    };

    wait(phase);
    cycle();
    wait(0.45);
    cycle();
    elapsed = waitTo(scene, elapsed, DURATION);
    return elapsed;
}

function makeTraceModule(spec, index) {
    const module = moduleScene({id: spec.id, width: 1325, height: 114, cameraHeight: 2.2});
    const {scene, text} = module;
    text(scene, {
        text: spec.letter,
        point: [-12.28, 0.45],
        align: [0, 0.5],
        size: 15,
        fill: C.accent,
        id: \`\${spec.id}-letter\`,
    });
    text(scene, {
        text: \`Comparison \${index + 1}\`,
        point: [-12.28, -0.03],
        align: [0, 0.5],
        size: 16,
        fill: C.ink,
        id: \`\${spec.id}-title\`,
    });
    text(scene, {
        text: \`\${spec.candidates} candidates\`,
        point: [-12.28, -0.52],
        align: [0, 0.5],
        size: 12,
        fill: C.muted,
        id: \`\${spec.id}-count\`,
    });

    const start = -7.25;
    const step = 0.93;
    const found = spec.value === TARGET;
    const {cells, valueLabels} = addArrayCells(scene, text, {
        prefix: spec.id,
        y: 0.02,
        start,
        step,
        cellSize: [0.86, 0.70],
        activeLo: spec.lo,
        activeHi: spec.hi,
        mid: spec.mid,
        targetIndex: found ? spec.mid : -1,
        found,
    });
    const rangeStartX = arrayX(spec.lo, start, step);
    const rangeEndX = arrayX(spec.hi, start, step);
    scene.line({
        from: [rangeStartX - 0.39, -0.55],
        to: [rangeEndX + 0.39, -0.55],
        stroke: found ? C.accent : C.blue,
        width: 3,
        layer: LAYER.data,
        id: \`\${spec.id}-range\`,
    });

    const decisionLabel = text(scene, {
        text: \`mid = \${spec.mid}  ·  \${spec.decision}\`,
        point: [5.35, 0.43],
        align: [0, 0.5],
        size: 15,
        fill: found ? C.accent : C.ink,
        id: \`\${spec.id}-decision\`,
    });
    text(scene, {
        text: \`\${spec.next}  →  \${spec.direction}\`,
        point: [5.35, -0.16],
        align: [0, 0.5],
        size: 13,
        fill: found ? C.accent : C.muted,
        id: \`\${spec.id}-caption\`,
    });

    const pivotX = arrayX(spec.mid, start, step);
    const marker = scene.point({
        point: [pivotX, 0.52],
        radius: 4.5,
        fill: C.accent,
        stroke: C.paper,
        width: 2,
        opacity: 0,
        layer: LAYER.cursor,
        id: \`\${spec.id}-mid-marker\`,
    });
    scheduleTrace(module, marker, cells[spec.mid], valueLabels[spec.mid], decisionLabel, spec.phase);
    return {...module, peakTime: spec.phase + 1.88, claim: spec.decision};
}

function scheduleComplexity(module, marker, barEnds, finalBar) {
    const {scene} = module;
    let elapsed = 0;
    const wait = (duration) => { scene.wait(duration); elapsed += duration; };
    const play = (spec, duration, curve = "ease_in_out") => {
        scene.play(spec, duration, curve, 0);
        elapsed += duration;
    };
    const shift = (from, to, duration) => {
        scene.shift(marker, [to[0] - from[0], to[1] - from[1]], duration, "ease_in_out");
        elapsed += duration;
    };
    const cycle = () => {
        play({target: marker, opacity: 1}, 0.18, "gentle");
        shift(barEnds[0], barEnds[1], 0.52);
        shift(barEnds[1], barEnds[2], 0.52);
        shift(barEnds[2], barEnds[3], 0.52);
        scene.indicate(finalBar, {color: C.accent, scale: 1.035, duration: 0.46, curve: "gentle"});
        elapsed += 0.46;
        shift(barEnds[3], barEnds[0], 0.82);
        play({target: marker, opacity: 0}, 0.18, "gentle");
    };
    wait(0.20);
    cycle();
    wait(0.35);
    cycle();
    elapsed = waitTo(scene, elapsed, DURATION);
    return elapsed;
}

function makeComplexityModule() {
    const module = moduleScene({id: "complexity", width: 439, height: 316, cameraHeight: 6.4});
    const {scene, text} = module;
    text(scene, {
        text: "D  ·  Candidate count",
        point: [-4.05, 2.63],
        align: [0, 0.5],
        size: 18,
        fill: C.ink,
        id: "complexity-title",
    });
    text(scene, {
        text: "13 → 6 → 3 → 1",
        point: [-4.05, 2.08],
        align: [0, 0.5],
        size: 14,
        fill: C.accent,
        role: "code",
        id: "complexity-sequence",
    });

    const counts = [13, 6, 3, 1];
    const barEnds = [];
    const bars = [];
    counts.forEach((count, index) => {
        const y = 1.25 - index * 0.72;
        const width = 5.9 * count / 13;
        text(scene, {
            text: String(count),
            point: [-4.02, y],
            align: [0, 0.5],
            size: 13,
            fill: index === 3 ? C.accent : C.muted,
            id: \`complexity-count-\${count}\`,
        });
        const bar = scene.rectangle({
            center: [-3.35 + width / 2, y],
            size: [width, 0.26],
            corner: 0.015,
            fill: index === 3 ? C.accent : C.blue,
            stroke: index === 3 ? C.accent : C.blue,
            width: 1,
            layer: LAYER.data,
            id: \`complexity-bar-\${count}\`,
        });
        bars.push(bar);
        barEnds.push([-3.35 + width, y]);
    });
    text(scene, {
        text: "Each comparison roughly halves the candidate set.",
        point: [-4.05, -1.76],
        align: [0, 0.5],
        size: 12,
        fill: C.muted,
        id: "complexity-caption-1",
    });
    text(scene, {
        text: "Therefore: O(log n) comparisons.",
        point: [-4.05, -2.28],
        align: [0, 0.5],
        size: 15,
        fill: C.ink,
        id: "complexity-caption-2",
    });
    const marker = scene.point({
        point: barEnds[0],
        radius: 5,
        fill: C.accent,
        stroke: C.paper,
        width: 2,
        opacity: 0,
        layer: LAYER.cursor,
        id: "complexity-marker",
    });
    scheduleComplexity(module, marker, barEnds, bars[3]);
    return {...module, peakTime: 1.70, claim: "candidate count halves to logarithmic comparisons"};
}

function scheduleInvariant(module, marker, points, targetLine) {
    const {scene} = module;
    let elapsed = 0;
    const wait = (duration) => { scene.wait(duration); elapsed += duration; };
    const play = (spec, duration, curve = "ease_in_out") => {
        scene.play(spec, duration, curve, 0);
        elapsed += duration;
    };
    const shift = (from, to, duration) => {
        scene.shift(marker, [to[0] - from[0], to[1] - from[1]], duration, "ease_in_out");
        elapsed += duration;
    };
    const cycle = () => {
        play({target: marker, opacity: 1}, 0.18, "gentle");
        shift(points[0], points[1], 0.48);
        shift(points[1], points[2], 0.48);
        shift(points[2], points[3], 0.48);
        scene.indicate(targetLine, {color: C.accent, scale: 1.018, duration: 0.46, curve: "gentle"});
        elapsed += 0.46;
        shift(points[3], points[0], 0.82);
        play({target: marker, opacity: 0}, 0.18, "gentle");
    };
    wait(0.35);
    cycle();
    wait(0.35);
    cycle();
    elapsed = waitTo(scene, elapsed, DURATION);
    return elapsed;
}

function makeInvariantModule() {
    const module = moduleScene({id: "invariant", width: 504, height: 316, cameraHeight: 6.4});
    const {scene, text} = module;
    text(scene, {
        text: "E  ·  Range invariant",
        point: [-4.72, 2.63],
        align: [0, 0.5],
        size: 18,
        fill: C.ink,
        id: "invariant-title",
    });
    text(scene, {
        text: "68 ∈ a[lo ... hi]",
        point: [4.72, 2.63],
        align: [1, 0.5],
        size: 14,
        fill: C.accent,
        role: "code",
        id: "invariant-formula",
    });

    const intervals = [
        {label: "[0, 12]", from: -3.25, to: 3.85, y: 1.34},
        {label: "[7, 12]", from: 0.35, to: 3.85, y: 0.62},
        {label: "[10, 12]", from: 1.72, to: 3.85, y: -0.10},
        {label: "[10, 10]", from: 1.72, to: 2.04, y: -0.82},
    ];
    const targetX = 1.88;
    intervals.forEach((interval, index) => {
        text(scene, {
            text: interval.label,
            point: [-4.70, interval.y],
            align: [0, 0.5],
            size: 12,
            fill: index === 3 ? C.accent : C.muted,
            id: \`invariant-range-\${index}\`,
        });
        const intervalLine = scene.line({
            from: [interval.from, interval.y],
            to: [interval.to, interval.y],
            stroke: index === 3 ? C.accent : C.blue,
            width: index === 3 ? 5 : 3,
            layer: LAYER.data,
            id: \`invariant-line-\${index}\`,
        });
        module.nonIntersectPairs.push([\`invariant-range-\${index}\`, \`invariant-line-\${index}\`, 6]);
        scene.line({
            from: [interval.from, interval.y - 0.13],
            to: [interval.from, interval.y + 0.13],
            stroke: index === 3 ? C.accent : C.blue,
            width: 2,
            layer: LAYER.data,
            id: \`invariant-left-\${index}\`,
        });
        scene.line({
            from: [interval.to, interval.y - 0.13],
            to: [interval.to, interval.y + 0.13],
            stroke: index === 3 ? C.accent : C.blue,
            width: 2,
            layer: LAYER.data,
            id: \`invariant-right-\${index}\`,
        });
    });
    const targetLine = scene.line({
        from: [targetX, 1.62],
        to: [targetX, -1.10],
        stroke: C.accent,
        width: 2,
        dash: [5, 5],
        layer: LAYER.data,
        id: "invariant-target-line",
    });
    text(scene, {
        text: "68",
        point: [targetX, 1.92],
        align: [0.5, 0.5],
        size: 13,
        fill: C.accent,
        id: "invariant-target-label",
    });
    text(scene, {
        text: "Discard only the half contradicted by the comparison.",
        point: [-4.72, -1.72],
        align: [0, 0.5],
        size: 12,
        fill: C.muted,
        id: "invariant-caption-1",
    });
    text(scene, {
        text: "Target 68 remains inside every retained interval.",
        point: [-4.72, -2.24],
        align: [0, 0.5],
        size: 15,
        fill: C.ink,
        id: "invariant-caption-2",
    });
    const points = intervals.map((interval) => [targetX, interval.y]);
    const marker = scene.point({
        point: points[0],
        radius: 6,
        fill: C.accent,
        stroke: C.paper,
        width: 2,
        opacity: 0,
        layer: LAYER.cursor,
        id: "invariant-marker",
    });
    scheduleInvariant(module, marker, points, targetLine);
    return {...module, peakTime: 2.15, claim: "the target remains inside every retained interval"};
}

function scheduleResult(module, token, from, to, resultRing) {
    const {scene} = module;
    let elapsed = 0;
    const wait = (duration) => { scene.wait(duration); elapsed += duration; };
    const play = (spec, duration, curve = "ease_in_out") => {
        scene.play(spec, duration, curve, 0);
        elapsed += duration;
    };
    const cycle = () => {
        play({target: token, opacity: 1}, 0.18, "gentle");
        scene.shift(token, [to[0] - from[0], to[1] - from[1]], 0.85, "gentle");
        elapsed += 0.85;
        scene.indicate(resultRing, {color: C.accent, scale: 1.035, duration: 0.50, curve: "gentle"});
        elapsed += 0.50;
        scene.shift(token, [from[0] - to[0], from[1] - to[1]], 0.85, "gentle");
        elapsed += 0.85;
        play({target: token, opacity: 0}, 0.18, "gentle");
    };
    wait(0.35);
    cycle();
    wait(0.45);
    cycle();
    elapsed = waitTo(scene, elapsed, DURATION);
    return elapsed;
}

function makeResultModule() {
    const module = moduleScene({id: "result", width: 324, height: 316, cameraHeight: 6.4});
    const {scene, text} = module;
    text(scene, {
        text: "F  ·  Result",
        point: [-2.98, 2.63],
        align: [0, 0.5],
        size: 18,
        fill: C.ink,
        id: "result-title",
    });
    text(scene, {
        text: "a[10]",
        point: [-1.65, 1.28],
        align: [0.5, 0.5],
        size: 18,
        fill: C.blue,
        role: "code",
        id: "result-access",
    });
    text(scene, {
        text: "=",
        point: [0, 1.28],
        align: [0.5, 0.5],
        size: 18,
        fill: C.muted,
        id: "result-equals",
    });
    const ring = scene.circle({
        center: [1.62, 1.28],
        radius: 0.54,
        fill: C.accentWash,
        stroke: C.accent,
        width: 2.5,
        layer: LAYER.data,
        id: "result-ring",
    });
    text(scene, {
        text: "68",
        point: [1.62, 1.28],
        align: [0.5, 0.5],
        size: 20,
        fill: C.accent,
        id: "result-value",
    });
    scene.line({
        from: [-2.35, 0.38],
        to: [2.35, 0.38],
        stroke: C.rule,
        width: 1,
        id: "result-rule",
    });
    text(scene, {
        text: "return 10",
        point: [0, -0.30],
        align: [0.5, 0.5],
        size: 25,
        fill: C.accent,
        role: "code",
        id: "result-return",
    });
    text(scene, {
        text: "Equality terminates the search.",
        point: [-2.98, -1.45],
        align: [0, 0.5],
        size: 12,
        fill: C.muted,
        id: "result-caption-1",
    });
    text(scene, {
        text: "Return index 10.",
        point: [-2.98, -1.98],
        align: [0, 0.5],
        size: 15,
        fill: C.ink,
        id: "result-caption-2",
    });
    const from = [-1.65, 0.82];
    const to = [1.62, 0.82];
    const token = scene.point({
        point: from,
        radius: 5,
        fill: C.accent,
        stroke: C.paper,
        width: 2,
        opacity: 0,
        layer: LAYER.cursor,
        id: "result-token",
    });
    scheduleResult(module, token, from, to, ring);
    return {...module, peakTime: 1.63, claim: "a[10] equals 68, so return index 10"};
}

const pseudocodeModule = makePseudocodeModule();
const inputModule = makeInputModule();
const traceModules = TRACE.map(makeTraceModule);
const complexityModule = makeComplexityModule();
const invariantModule = makeInvariantModule();
const resultModule = makeResultModule();

const MODULES = [pseudocodeModule, inputModule, ...traceModules, complexityModule, invariantModule, resultModule];
for (const module of MODULES) module.source = module.scene.compile();

const definition = tmath.scene({
    width: WIDTH,
    height: HEIGHT,
    fps: FPS,
    loop: true,
    theme: "pro_white",
    background: C.paper,
    camera: {mode: "fixed", view: "2d", target: [0, 0], height: 14.6},
});

const header = definition.group({id: "header"});
rootText(header, {
    text: "Binary Search",
    point: [-6.62, 6.65],
    align: [0, 0.5],
    size: 52,
    fill: C.ink,
    role: "h1",
    id: "header-title",
});
rootText(header, {
    text: "Why one comparison can eliminate half of a sorted search interval",
    point: [-6.58, 5.95],
    align: [0, 0.5],
    size: 19,
    fill: C.muted,
    id: "header-subtitle",
});
rootText(header, {
    text: "Four comparisons locate 68",
    point: [6.62, 5.95],
    align: [1, 0.5],
    size: 15,
    fill: C.accent,
    id: "header-guide",
});
header.line({
    from: [-6.62, 5.65],
    to: [6.62, 5.65],
    stroke: C.ink,
    width: 1.4,
    layer: LAYER.structure,
    id: "header-rule",
});

rootText(definition, {
    text: "SEARCH TRACE  ·  Each row shows the closed interval [lo, hi] before comparison",
    point: [-6.62, 1.63],
    align: [0, 0.5],
    size: 15,
    fill: C.ink,
    id: "trace-section-title",
});
rootText(definition, {
    text: "blue = candidate   ochre = mid   rust = target / result",
    point: [6.62, 1.63],
    align: [1, 0.5],
    size: 11,
    fill: C.muted,
    role: "code",
    id: "trace-legend",
});
definition.line({
    from: [-6.62, 1.39],
    to: [6.62, 1.39],
    stroke: C.rule,
    width: 1,
    id: "trace-section-rule",
});

rootText(definition, {
    text: "COMPLEXITY, INVARIANT, AND RETURN VALUE",
    point: [-6.62, -3.72],
    align: [0, 0.5],
    size: 15,
    fill: C.ink,
    id: "footer-section-title",
});
definition.line({
    from: [-6.62, -3.96],
    to: [6.62, -3.96],
    stroke: C.rule,
    width: 1,
    id: "footer-section-rule",
});
definition.line({
    from: [-2.09, -4.02],
    to: [-2.09, -7.10],
    stroke: C.rule,
    width: 1,
    id: "footer-divider-1",
});
definition.line({
    from: [3.31, -4.02],
    to: [3.31, -7.10],
    stroke: C.rule,
    width: 1,
    id: "footer-divider-2",
});

definition.viewport(pseudocodeModule.scene, {x: 0.04, y: 0.115, width: 0.92, height: 0.130});
definition.viewport(inputModule.scene, {x: 0.04, y: 0.255, width: 0.92, height: 0.1144});
traceModules.forEach((module, index) => {
    definition.viewport(module.scene, {x: 0.04, y: 0.414 + index * 0.083, width: 0.92, height: 0.0781});
});
definition.viewport(complexityModule.scene, {x: 0.04, y: 0.773, width: 0.305, height: 0.216});
definition.viewport(invariantModule.scene, {x: 0.37, y: 0.773, width: 0.35, height: 0.216});
definition.viewport(resultModule.scene, {x: 0.735, y: 0.773, width: 0.225, height: 0.216});
return definition;
`,
    },
];
