const PRETENDARD = [{ name: "Pretendard", url: "./Pretendard.ttf", mime: "ttf" }];

const KD_TREE_LUA = `local scene = tmath.scene {
    width = 960, height = 540, fps = 30, background = "#081018",
    camera = {mode = "fixed", view = "2d", height = 8}
}
local function translate(x, y)
    return {1,0,0,x, 0,1,0,y, 0,0,1,0, 0,0,0,1}
end

local title = scene:text {text="KD-TREE  |  partition, index, search",point={0,3.55},
    font="Pretendard",size=29,fill="#f4f7fb",id="title"}
local subtitle = scene:text {text="The same color names the split in space and the decision in the tree.",
    point={0,3.04},font="Pretendard",size=15,fill="#91a4b7",id="subtitle"}
local spatialFrame = scene:rectangle {center={-4.05,-0.05},size={5.35,4.65},corner=0.17,
    fill="#0d1b2a",stroke="#26394c",width=2,layer=-10,id="spatial-frame"}
local treeFrame = scene:rectangle {center={3.35,-0.05},size={5.7,4.65},corner=0.17,
    fill="#0d1b2a",stroke="#26394c",width=2,layer=-10,id="tree-frame"}
local spatialTitle = scene:text {text="2D POINT SET",point={-4.05,1.94},font="Pretendard",size=16,
    fill="#dbe7f3",id="spatial-title"}
local treeTitle = scene:text {text="ALTERNATING x / y DECISIONS",point={3.35,1.94},font="Pretendard",size=16,
    fill="#dbe7f3",id="tree-title"}
local legends = {
    scene:text {text="x split",point={-5.15,2.47},font="Pretendard",size=14,fill="#ff6b6b",id="x-legend"},
    scene:text {text="y split",point={-3.85,2.47},font="Pretendard",size=14,fill="#4cc9f0",id="y-legend"},
    scene:text {text="query",point={-2.65,2.47},font="Pretendard",size=14,fill="#ffd166",id="query-legend"},
    scene:text {text="nearest",point={-1.72,2.47},font="Pretendard",size=14,fill="#7bd88f",id="nearest-legend"}
}

local pointData = {
    {"A","(5,4)",-4.05,-0.64,"#ff6b6b"}, {"D","(1,5)",-5.96,-0.24,"#4cc9f0"},
    {"F","(8,6)",-2.62,0.16,"#4cc9f0"}, {"B","(2,3)",-5.48,-1.04,"#91a4b7"},
    {"C","(4,7)",-4.53,0.56,"#91a4b7"}, {"E","(7,2)",-3.10,-1.44,"#91a4b7"},
    {"G","(6,8)",-3.57,0.96,"#91a4b7"}
}
local pointItems, pointBodies = {}, {}
for _, p in ipairs(pointData) do
    local item = scene:group {matrix=translate(p[3],p[4]),id="point-" .. p[1]}
    local body = item:circle {radius=0.16,fill="#101b29",stroke=p[5],width=3,layer=2,
        id="point-" .. p[1] .. "-body"}
    item:text {text=p[1],point={0.29,0.22},font="Pretendard",size=13,fill=p[5],layer=3,
        id="point-" .. p[1] .. "-label"}
    item:text {text=p[2],point={0.34,-0.16},align={0,0.5},font="Pretendard",size=11,
        fill="#7f93a8",layer=3,id="point-" .. p[1] .. "-coordinate"}
    pointItems[#pointItems+1], pointBodies[p[1]] = item, body
end

local rootSplit = scene:line {from={-4.05,-2.15},to={-4.05,1.65},stroke="#ff6b6b",width=4,
    layer=1,id="split-x-5"}
local leftSplit = scene:line {from={-6.42,-0.24},to={-4.05,-0.24},stroke="#4cc9f0",width=4,
    layer=1,id="split-y-5-left"}
local rightSplit = scene:line {from={-4.05,0.16},to={-1.68,0.16},stroke="#4cc9f0",width=4,
    layer=1,id="split-y-6-right"}

local nodeData = {
    {"A","x = 5",3.35,1.23,"#ff6b6b"}, {"D","y = 5",1.85,0.02,"#4cc9f0"},
    {"F","y = 6",4.85,0.02,"#4cc9f0"}, {"B","(2,3)",1.12,-1.45,"#91a4b7"},
    {"C","(4,7)",2.58,-1.45,"#91a4b7"}, {"E","(7,2)",4.12,-1.45,"#91a4b7"},
    {"G","(6,8)",5.58,-1.45,"#91a4b7"}
}
local nodes, nodeBodies, nodeCaptions = {}, {}, {}
for _, n in ipairs(nodeData) do
    local item = scene:group {matrix=translate(n[3],n[4]),id="node-" .. n[1]}
    local body = item:circle {radius=0.41,fill="#132235",stroke=n[5],width=3,layer=2,
        id="node-" .. n[1] .. "-body"}
    item:text {text=n[1],point={0,0},font="Pretendard",size=19,fill="#f4f7fb",layer=3,
        id="node-" .. n[1] .. "-label"}
    local caption = scene:text {text=n[2],point={n[3],n[4]-0.58},font="Pretendard",size=11,
        fill="#7f93a8",layer=3,id="node-" .. n[1] .. "-coordinate"}
    nodes[n[1]], nodeBodies[n[1]], nodeCaptions[n[1]] = item, body, caption
end
local function edge(a, b, color, id)
    return scene:connector {from=nodes[a],to=nodes[b],padding=0.06,stroke=color,width=3,layer=1,id=id}
end
local edges = {
    AD=edge("A","D","#ff6b6b","edge-a-d"), AF=edge("A","F","#ff6b6b","edge-a-f"),
    DB=edge("D","B","#4cc9f0","edge-d-b"), DC=edge("D","C","#4cc9f0","edge-d-c"),
    FE=edge("F","E","#4cc9f0","edge-f-e"), FG=edge("F","G","#4cc9f0","edge-f-g")
}

local query = scene:group {matrix=translate(-5.00,0.96),opacity=0,id="query-q"}
query:circle {radius=0.21,fill="#ffd16633",stroke="#ffd166",width=4,layer=2,id="query-q-body"}
query:text {text="Q(3,8)",point={-0.08,0.34},font="Pretendard",size=13,fill="#ffd166",layer=3,
    id="query-q-label"}
local status1 = scene:text {text="Q.x < 5  ->  visit the left subtree",point={0,-2.80},font="Pretendard",
    size=17,fill="#ffd166",opacity=0,id="search-step-x"}
local status2 = scene:text {text="Q.y > 5  ->  visit D's upper branch",point={0,-2.80},font="Pretendard",
    size=17,fill="#ffd166",opacity=0,id="search-step-y"}
local status3 = scene:text {text="C(4,7), d = sqrt(2)   |   both split planes prune",point={0,-2.80},
    font="Pretendard",size=17,fill="#7bd88f",opacity=0,id="search-result"}

for _,item in ipairs({title,subtitle,spatialFrame,treeFrame,spatialTitle,treeTitle,
    legends[1],legends[2],legends[3],legends[4]}) do
    scene:fade_in(item,{shift={0,0.10},duration=0.07,curve="snappy"})
end
for _,point in ipairs(pointItems) do
    scene:grow_from_center(point,0.08,{preset="back",strength=0.40})
end
scene:create(rootSplit,0.28,"linear")
scene:grow_from_center(nodes.A,0.22,{preset="back",strength=0.55})
scene:fade_in(nodeCaptions.A,{shift={0,0.10},duration=0.12,curve="snappy"})
scene:create({leftSplit,rightSplit,edges.AD,edges.AF},0.36,"linear",0.05)
for _,node in ipairs({nodes.D,nodes.F}) do
    scene:grow_from_center(node,0.16,{preset="back",strength=0.50})
end
for _,caption in ipairs({nodeCaptions.D,nodeCaptions.F}) do
    scene:fade_in(caption,{shift={0,0.08},duration=0.09,curve="snappy"})
end
scene:create({edges.DB,edges.DC,edges.FE,edges.FG},0.34,"linear",0.045)
for _,node in ipairs({nodes.B,nodes.C,nodes.E,nodes.G}) do
    scene:grow_from_center(node,0.11,{preset="back",strength=0.42})
end
for _,caption in ipairs({nodeCaptions.B,nodeCaptions.C,nodeCaptions.E,nodeCaptions.G}) do
    scene:fade_in(caption,{shift={0,0.07},duration=0.07,curve="snappy"})
end
scene:play({
    {target=query,opacity=1},{target=status1,opacity=1},
    {target=pointBodies.A,fill="#6c4b1f",stroke="#ffd166"},
    {target=nodeBodies.A,fill="#6c4b1f",stroke="#ffd166"},{target=rootSplit,stroke="#ffd166"}
},0.62,"ease_in_out",0)
scene:wait(0.22)
scene:play({{target=status1,opacity=0}},0.16,"ease_out",0)
scene:play({
    {target=status2,opacity=1},
    {target=pointBodies.A,fill="#101b29",stroke="#ff6b6b"},
    {target=nodeBodies.A,fill="#132235",stroke="#ff6b6b"},{target=rootSplit,stroke="#ff6b6b"},
    {target=pointBodies.D,fill="#6c4b1f",stroke="#ffd166"},
    {target=nodeBodies.D,fill="#6c4b1f",stroke="#ffd166"},
    {target=leftSplit,stroke="#ffd166"},{target=edges.AD,stroke="#ffd166"}
},0.62,"ease_in_out",0)
scene:wait(0.22)
scene:play({{target=status2,opacity=0}},0.16,"ease_out",0)
scene:play({
    {target=status3,opacity=1},
    {target=pointBodies.D,fill="#101b29",stroke="#4cc9f0"},
    {target=nodeBodies.D,fill="#132235",stroke="#4cc9f0"},{target=leftSplit,stroke="#4cc9f0"},
    {target=pointBodies.C,fill="#214d3d",stroke="#7bd88f"},
    {target=nodeBodies.C,fill="#214d3d",stroke="#7bd88f"},{target=edges.DC,stroke="#7bd88f"}
},0.68,"ease_in_out",0)
scene:wait(0.65)
return scene
`;

const KD_TREE_JS = `const scene = tmath.scene({
    width: 960, height: 540, fps: 30, background: "#081018",
    camera: {mode: "fixed", view: "2d", height: 8},
});
const translate = (x, y) => [1,0,0,x, 0,1,0,y, 0,0,1,0, 0,0,0,1];

const title = scene.text({text: "KD-TREE  |  partition, index, search", point: [0,3.55],
    font: "Pretendard", size: 29, fill: "#f4f7fb", id: "title"});
const subtitle = scene.text({text: "The same color names the split in space and the decision in the tree.",
    point: [0,3.04], font: "Pretendard", size: 15, fill: "#91a4b7", id: "subtitle"});
const spatialFrame = scene.rectangle({center: [-4.05,-0.05], size: [5.35,4.65], corner: 0.17,
    fill: "#0d1b2a", stroke: "#26394c", width: 2, layer: -10, id: "spatial-frame"});
const treeFrame = scene.rectangle({center: [3.35,-0.05], size: [5.7,4.65], corner: 0.17,
    fill: "#0d1b2a", stroke: "#26394c", width: 2, layer: -10, id: "tree-frame"});
const spatialTitle = scene.text({text: "2D POINT SET", point: [-4.05,1.94], font: "Pretendard", size: 16,
    fill: "#dbe7f3", id: "spatial-title"});
const treeTitle = scene.text({text: "ALTERNATING x / y DECISIONS", point: [3.35,1.94], font: "Pretendard",
    size: 16, fill: "#dbe7f3", id: "tree-title"});
const legends = [
    scene.text({text: "x split", point: [-5.15,2.47], font: "Pretendard", size: 14, fill: "#ff6b6b", id: "x-legend"}),
    scene.text({text: "y split", point: [-3.85,2.47], font: "Pretendard", size: 14, fill: "#4cc9f0", id: "y-legend"}),
    scene.text({text: "query", point: [-2.65,2.47], font: "Pretendard", size: 14, fill: "#ffd166", id: "query-legend"}),
    scene.text({text: "nearest", point: [-1.72,2.47], font: "Pretendard", size: 14, fill: "#7bd88f", id: "nearest-legend"}),
];

const pointData = [
    ["A","(5,4)",-4.05,-0.64,"#ff6b6b"], ["D","(1,5)",-5.96,-0.24,"#4cc9f0"],
    ["F","(8,6)",-2.62,0.16,"#4cc9f0"], ["B","(2,3)",-5.48,-1.04,"#91a4b7"],
    ["C","(4,7)",-4.53,0.56,"#91a4b7"], ["E","(7,2)",-3.10,-1.44,"#91a4b7"],
    ["G","(6,8)",-3.57,0.96,"#91a4b7"],
];
const pointItems = [], pointBodies = {};
for (const p of pointData) {
    const item = scene.group({matrix: translate(p[2],p[3]), id: "point-" + p[0]});
    const body = item.circle({radius: 0.16, fill: "#101b29", stroke: p[4], width: 3, layer: 2,
        id: "point-" + p[0] + "-body"});
    item.text({text: p[0], point: [0.29,0.22], font: "Pretendard", size: 13, fill: p[4], layer: 3,
        id: "point-" + p[0] + "-label"});
    item.text({text: p[1], point: [0.34,-0.16], align: [0,0.5], font: "Pretendard", size: 11,
        fill: "#7f93a8", layer: 3, id: "point-" + p[0] + "-coordinate"});
    pointItems.push(item); pointBodies[p[0]] = body;
}
const rootSplit = scene.line({from: [-4.05,-2.15], to: [-4.05,1.65], stroke: "#ff6b6b", width: 4,
    layer: 1, id: "split-x-5"});
const leftSplit = scene.line({from: [-6.42,-0.24], to: [-4.05,-0.24], stroke: "#4cc9f0", width: 4,
    layer: 1, id: "split-y-5-left"});
const rightSplit = scene.line({from: [-4.05,0.16], to: [-1.68,0.16], stroke: "#4cc9f0", width: 4,
    layer: 1, id: "split-y-6-right"});

const nodeData = [
    ["A","x = 5",3.35,1.23,"#ff6b6b"], ["D","y = 5",1.85,0.02,"#4cc9f0"],
    ["F","y = 6",4.85,0.02,"#4cc9f0"], ["B","(2,3)",1.12,-1.45,"#91a4b7"],
    ["C","(4,7)",2.58,-1.45,"#91a4b7"], ["E","(7,2)",4.12,-1.45,"#91a4b7"],
    ["G","(6,8)",5.58,-1.45,"#91a4b7"],
];
const nodes = {}, nodeBodies = {}, nodeCaptions = {};
for (const n of nodeData) {
    const item = scene.group({matrix: translate(n[2],n[3]), id: "node-" + n[0]});
    const body = item.circle({radius: 0.41, fill: "#132235", stroke: n[4], width: 3, layer: 2,
        id: "node-" + n[0] + "-body"});
    item.text({text: n[0], point: [0,0], font: "Pretendard", size: 19, fill: "#f4f7fb", layer: 3,
        id: "node-" + n[0] + "-label"});
    const caption = scene.text({text: n[1], point: [n[2],n[3]-0.58], font: "Pretendard", size: 11,
        fill: "#7f93a8", layer: 3, id: "node-" + n[0] + "-coordinate"});
    nodes[n[0]] = item; nodeBodies[n[0]] = body; nodeCaptions[n[0]] = caption;
}
const edge = (a, b, color, id) => scene.connector(nodes[a], nodes[b],
    {padding: 0.06, stroke: color, width: 3, layer: 1, id});
const edges = {
    AD: edge("A","D","#ff6b6b","edge-a-d"), AF: edge("A","F","#ff6b6b","edge-a-f"),
    DB: edge("D","B","#4cc9f0","edge-d-b"), DC: edge("D","C","#4cc9f0","edge-d-c"),
    FE: edge("F","E","#4cc9f0","edge-f-e"), FG: edge("F","G","#4cc9f0","edge-f-g"),
};

const query = scene.group({matrix: translate(-5.00,0.96), opacity: 0, id: "query-q"});
query.circle({radius: 0.21, fill: "#ffd16633", stroke: "#ffd166", width: 4, layer: 2, id: "query-q-body"});
query.text({text: "Q(3,8)", point: [-0.08,0.34], font: "Pretendard", size: 13, fill: "#ffd166", layer: 3,
    id: "query-q-label"});
const status1 = scene.text({text: "Q.x < 5  ->  visit the left subtree", point: [0,-2.80], font: "Pretendard",
    size: 17, fill: "#ffd166", opacity: 0, id: "search-step-x"});
const status2 = scene.text({text: "Q.y > 5  ->  visit D's upper branch", point: [0,-2.80], font: "Pretendard",
    size: 17, fill: "#ffd166", opacity: 0, id: "search-step-y"});
const status3 = scene.text({text: "C(4,7), d = sqrt(2)   |   both split planes prune", point: [0,-2.80],
    font: "Pretendard", size: 17, fill: "#7bd88f", opacity: 0, id: "search-result"});

for (const item of [title,subtitle,spatialFrame,treeFrame,spatialTitle,treeTitle,...legends]) {
    scene.fadeIn(item,{shift: [0,0.10],duration: 0.07,curve: "snappy"});
}
for (const point of pointItems) {
    scene.growFromCenter(point,0.08,tmath.animCurve.preset("back",0.40));
}
scene.create(rootSplit,0.28,"linear");
scene.growFromCenter(nodes.A,0.22,tmath.animCurve.preset("back",0.55));
scene.fadeIn(nodeCaptions.A,{shift: [0,0.10],duration: 0.12,curve: "snappy"});
scene.create([leftSplit,rightSplit,edges.AD,edges.AF],0.36,"linear",0.05);
for (const node of [nodes.D,nodes.F]) {
    scene.growFromCenter(node,0.16,tmath.animCurve.preset("back",0.50));
}
for (const caption of [nodeCaptions.D,nodeCaptions.F]) {
    scene.fadeIn(caption,{shift: [0,0.08],duration: 0.09,curve: "snappy"});
}
scene.create([edges.DB,edges.DC,edges.FE,edges.FG],0.34,"linear",0.045);
for (const node of [nodes.B,nodes.C,nodes.E,nodes.G]) {
    scene.growFromCenter(node,0.11,tmath.animCurve.preset("back",0.42));
}
for (const caption of [nodeCaptions.B,nodeCaptions.C,nodeCaptions.E,nodeCaptions.G]) {
    scene.fadeIn(caption,{shift: [0,0.07],duration: 0.07,curve: "snappy"});
}
scene.play([
    {target: query, opacity: 1}, {target: status1, opacity: 1},
    {target: pointBodies.A, fill: "#6c4b1f", stroke: "#ffd166"},
    {target: nodeBodies.A, fill: "#6c4b1f", stroke: "#ffd166"}, {target: rootSplit, stroke: "#ffd166"},
],0.62,"ease_in_out",0);
scene.wait(0.22);
scene.play([{target: status1, opacity: 0}],0.16,"ease_out",0);
scene.play([
    {target: status2, opacity: 1},
    {target: pointBodies.A, fill: "#101b29", stroke: "#ff6b6b"},
    {target: nodeBodies.A, fill: "#132235", stroke: "#ff6b6b"}, {target: rootSplit, stroke: "#ff6b6b"},
    {target: pointBodies.D, fill: "#6c4b1f", stroke: "#ffd166"},
    {target: nodeBodies.D, fill: "#6c4b1f", stroke: "#ffd166"},
    {target: leftSplit, stroke: "#ffd166"}, {target: edges.AD, stroke: "#ffd166"},
],0.62,"ease_in_out",0);
scene.wait(0.22);
scene.play([{target: status2, opacity: 0}],0.16,"ease_out",0);
scene.play([
    {target: status3, opacity: 1},
    {target: pointBodies.D, fill: "#101b29", stroke: "#4cc9f0"},
    {target: nodeBodies.D, fill: "#132235", stroke: "#4cc9f0"}, {target: leftSplit, stroke: "#4cc9f0"},
    {target: pointBodies.C, fill: "#214d3d", stroke: "#7bd88f"},
    {target: nodeBodies.C, fill: "#214d3d", stroke: "#7bd88f"}, {target: edges.DC, stroke: "#7bd88f"},
],0.68,"ease_in_out",0);
scene.wait(0.65);
return scene;
`;

const RED_BLACK_TREE_LUA = `local scene = tmath.scene {
    width=960,height=540,fps=30,background="#081018",
    camera={mode="fixed",view="2d",height=8}
}
local function translate(x,y)
    return {1,0,0,x, 0,1,0,y, 0,0,1,0, 0,0,0,1}
end
local title=scene:text {text="RED-BLACK TREE  |  insert 10, 5, 1",point={0,3.55},
    font="Pretendard",size=29,fill="#f4f7fb",id="title"}
local subtitle=scene:text {text="A left-left violation is repaired by one right rotation and recoloring.",
    point={0,3.04},font="Pretendard",size=15,fill="#91a4b7",id="subtitle"}
local traceFrame=scene:rectangle {center={-4.52,-0.08},size={3.65,4.7},corner=0.17,
    fill="#0d1b2a",stroke="#26394c",width=2,layer=-10,id="trace-frame"}
local treeFrame=scene:rectangle {center={2.05,-0.08},size={8.4,4.7},corner=0.17,
    fill="#0d1b2a",stroke="#26394c",width=2,layer=-10,id="tree-frame"}
local traceTitle=scene:text {text="INSERTION ORDER",point={-4.52,1.95},font="Pretendard",size=16,
    fill="#dbe7f3",id="trace-title"}
local treeTitle=scene:text {text="LOCAL REPAIR",point={2.05,1.95},font="Pretendard",size=16,
    fill="#dbe7f3",id="tree-title"}

local cards=scene:group {matrix=translate(-4.52,0.82),id="insertion-cards"}
local cardBodies={}
for i,value in ipairs({10,5,1}) do
    local card=cards:group {id="insert-card-" .. value}
    local color=i == 1 and "#91a4b7" or "#ff5d73"
    cardBodies[i]=card:rectangle {size={0.82,0.72},corner=0.11,fill="#132235",stroke=color,
        width=3,layer=2,id="insert-card-" .. value .. "-body"}
    card:text {text=tostring(value),point={0,0},font="Pretendard",size=19,fill="#f4f7fb",layer=3,
        id="insert-card-" .. value .. "-label"}
end
cards:arrange({1,0,0},0.18)
local orderHint=scene:text {text="10  ->  5  ->  1",point={-4.52,-0.05},font="Pretendard",size=17,
    fill="#91a4b7",id="order-hint"}
local ruleBlack=scene:text {text="BLACK",point={-5.28,-0.82},font="Pretendard",size=14,fill="#b9c7d5",
    id="black-legend"}
local ruleRed=scene:text {text="RED",point={-3.76,-0.82},font="Pretendard",size=14,fill="#ff5d73",
    id="red-legend"}
local invariant=scene:text {text="No RED  ->  RED edge",point={-4.52,-1.55},font="Pretendard",size=14,
    fill="#7f93a8",id="red-parent-invariant"}

local function node(value,x,y,color)
    local item=scene:group {matrix=translate(x,y),id="node-" .. value}
    local body=item:circle {radius=0.5,fill=color,stroke="#f4f7fb",width=3,layer=2,
        id="node-" .. value .. "-body"}
    item:text {text=tostring(value),point={0,0},font="Pretendard",size=21,fill="#ffffff",layer=3,
        id="node-" .. value .. "-label"}
    return item,body
end
local node10,body10=node(10,2.7,1.15,"#263343")
local node5,body5=node(5,1.25,-0.15,"#c9364e")
local node1,body1=node(1,-0.20,-1.45,"#c9364e")
local edge10to5=scene:connector {from=node10,to=node5,padding=0.08,stroke="#718399",width=4,
    layer=1,id="edge-10-5"}
local edge5to1=scene:connector {from=node5,to=node1,padding=0.08,stroke="#718399",width=4,
    layer=1,id="edge-5-1"}
local rootBadge=scene:text {text="root",point={3.42,1.38},font="Pretendard",size=13,fill="#91a4b7",
    id="root-badge-before"}
local rootBadgeAfter=scene:text {text="new root",point={3.90,1.40},font="Pretendard",size=13,
    fill="#7bd88f",opacity=0,id="root-badge-after"}
local violation=scene:text {text="RED parent + RED child",point={3.60,-1.48},font="Pretendard",size=16,
    fill="#ff5d73",opacity=0,id="red-red-violation"}
local repair=scene:text {text="rotateRight(10)  +  recolor",point={2.05,-2.12},font="Pretendard",size=18,
    fill="#ffd166",opacity=0,id="repair-operation"}
local repaired=scene:text {text="Valid: black root, no red-red edge, equal black height",point={2.05,-2.12},
    font="Pretendard",size=16,fill="#7bd88f",opacity=0,id="repair-result"}

for _,item in ipairs({title,subtitle,traceFrame,treeFrame,traceTitle,treeTitle,cards,orderHint,
    ruleBlack,ruleRed,invariant}) do
    scene:fade_in(item,{shift={0,0.10},duration=0.07,curve="snappy"})
end
scene:grow_from_center(node10,0.28,{preset="back",strength=0.55})
scene:fade_in(rootBadge,{shift={-0.12,0},duration=0.14,curve="snappy"})
scene:play({{target=cardBodies[1],fill="#283b50",stroke="#ffd166"},
    {target=body10,stroke="#ffd166"}},0.38,"ease_out",0)
scene:create(edge10to5,0.25,"linear")
scene:grow_from_center(node5,0.26,{preset="back",strength=0.55})
scene:play({{target=cardBodies[1],fill="#132235",stroke="#91a4b7"},
    {target=cardBodies[2],fill="#512535",stroke="#ffd166"},{target=body10,stroke="#f4f7fb"},
    {target=body5,stroke="#ffd166"}},0.38,"ease_out",0)
scene:create(edge5to1,0.25,"linear")
scene:grow_from_center(node1,0.26,{preset="back",strength=0.55})
scene:play({{target=cardBodies[2],fill="#132235",stroke="#ff5d73"},
    {target=cardBodies[3],fill="#512535",stroke="#ffd166"},{target=body5,stroke="#ff5d73"},
    {target=body1,stroke="#ffd166"},{target=edge5to1,stroke="#ff5d73"},
    {target=violation,opacity=1},{target=repair,opacity=1}},0.50,"ease_in_out",0)
scene:play({{target=rootBadge,opacity=0},{target=violation,opacity=0},{target=repair,opacity=0}},
    0.24,"ease_out",0)
scene:play({
    {target=node5,shift={1.45,1.30}},{target=node1,shift={1.45,1.30}},
    {target=node10,shift={1.45,-1.30}},{target=body5,fill="#263343",stroke="#f4f7fb"},
    {target=body10,fill="#c9364e",stroke="#f4f7fb"},{target=body1,stroke="#f4f7fb"},
    {target=edge5to1,stroke="#718399"},{target=cardBodies[1],fill="#512535",stroke="#ff5d73"},
    {target=cardBodies[2],fill="#283b50",stroke="#91a4b7"},
    {target=cardBodies[3],fill="#512535",stroke="#ff5d73"}
},0.96,"ease_in_out",0)
scene:play({{target=rootBadgeAfter,opacity=1},{target=repaired,opacity=1}},0.32,"ease_out",0)
scene:wait(0.75)
return scene
`;

const RED_BLACK_TREE_JS = `const scene = tmath.scene({
    width: 960, height: 540, fps: 30, background: "#081018",
    camera: {mode: "fixed", view: "2d", height: 8},
});
const translate = (x,y) => [1,0,0,x, 0,1,0,y, 0,0,1,0, 0,0,0,1];
const title = scene.text({text: "RED-BLACK TREE  |  insert 10, 5, 1", point: [0,3.55],
    font: "Pretendard", size: 29, fill: "#f4f7fb", id: "title"});
const subtitle = scene.text({text: "A left-left violation is repaired by one right rotation and recoloring.",
    point: [0,3.04], font: "Pretendard", size: 15, fill: "#91a4b7", id: "subtitle"});
const traceFrame = scene.rectangle({center: [-4.52,-0.08], size: [3.65,4.7], corner: 0.17,
    fill: "#0d1b2a", stroke: "#26394c", width: 2, layer: -10, id: "trace-frame"});
const treeFrame = scene.rectangle({center: [2.05,-0.08], size: [8.4,4.7], corner: 0.17,
    fill: "#0d1b2a", stroke: "#26394c", width: 2, layer: -10, id: "tree-frame"});
const traceTitle = scene.text({text: "INSERTION ORDER", point: [-4.52,1.95], font: "Pretendard", size: 16,
    fill: "#dbe7f3", id: "trace-title"});
const treeTitle = scene.text({text: "LOCAL REPAIR", point: [2.05,1.95], font: "Pretendard", size: 16,
    fill: "#dbe7f3", id: "tree-title"});

const cards = scene.group({matrix: translate(-4.52,0.82), id: "insertion-cards"});
const cardBodies = [];
[10,5,1].forEach((value,i) => {
    const card = cards.group({id: "insert-card-" + value});
    const color = i === 0 ? "#91a4b7" : "#ff5d73";
    cardBodies.push(card.rectangle({size: [0.82,0.72], corner: 0.11, fill: "#132235", stroke: color,
        width: 3, layer: 2, id: "insert-card-" + value + "-body"}));
    card.text({text: String(value), point: [0,0], font: "Pretendard", size: 19, fill: "#f4f7fb", layer: 3,
        id: "insert-card-" + value + "-label"});
});
cards.arrange([1,0,0],0.18);
const orderHint = scene.text({text: "10  ->  5  ->  1", point: [-4.52,-0.05], font: "Pretendard", size: 17,
    fill: "#91a4b7", id: "order-hint"});
const ruleBlack = scene.text({text: "BLACK", point: [-5.28,-0.82], font: "Pretendard", size: 14, fill: "#b9c7d5",
    id: "black-legend"});
const ruleRed = scene.text({text: "RED", point: [-3.76,-0.82], font: "Pretendard", size: 14, fill: "#ff5d73",
    id: "red-legend"});
const invariant = scene.text({text: "No RED  ->  RED edge", point: [-4.52,-1.55], font: "Pretendard", size: 14,
    fill: "#7f93a8", id: "red-parent-invariant"});

const node = (value,x,y,color) => {
    const item = scene.group({matrix: translate(x,y), id: "node-" + value});
    const body = item.circle({radius: 0.5, fill: color, stroke: "#f4f7fb", width: 3, layer: 2,
        id: "node-" + value + "-body"});
    item.text({text: String(value), point: [0,0], font: "Pretendard", size: 21, fill: "#ffffff", layer: 3,
        id: "node-" + value + "-label"});
    return [item,body];
};
const [node10,body10] = node(10,2.7,1.15,"#263343");
const [node5,body5] = node(5,1.25,-0.15,"#c9364e");
const [node1,body1] = node(1,-0.20,-1.45,"#c9364e");
const edge10to5 = scene.connector(node10,node5,{padding: 0.08,stroke: "#718399",width: 4,
    layer: 1,id: "edge-10-5"});
const edge5to1 = scene.connector(node5,node1,{padding: 0.08,stroke: "#718399",width: 4,
    layer: 1,id: "edge-5-1"});
const rootBadge = scene.text({text: "root",point: [3.42,1.38],font: "Pretendard",size: 13,fill: "#91a4b7",
    id: "root-badge-before"});
const rootBadgeAfter = scene.text({text: "new root",point: [3.90,1.40],font: "Pretendard",size: 13,
    fill: "#7bd88f",opacity: 0,id: "root-badge-after"});
const violation = scene.text({text: "RED parent + RED child",point: [3.60,-1.48],font: "Pretendard",size: 16,
    fill: "#ff5d73",opacity: 0,id: "red-red-violation"});
const repair = scene.text({text: "rotateRight(10)  +  recolor",point: [2.05,-2.12],font: "Pretendard",size: 18,
    fill: "#ffd166",opacity: 0,id: "repair-operation"});
const repaired = scene.text({text: "Valid: black root, no red-red edge, equal black height",point: [2.05,-2.12],
    font: "Pretendard",size: 16,fill: "#7bd88f",opacity: 0,id: "repair-result"});

for (const item of [title,subtitle,traceFrame,treeFrame,traceTitle,treeTitle,cards,orderHint,
    ruleBlack,ruleRed,invariant]) {
    scene.fadeIn(item,{shift: [0,0.10],duration: 0.07,curve: "snappy"});
}
scene.growFromCenter(node10,0.28,tmath.animCurve.preset("back",0.55));
scene.fadeIn(rootBadge,{shift: [-0.12,0],duration: 0.14,curve: "snappy"});
scene.play([{target: cardBodies[0],fill: "#283b50",stroke: "#ffd166"},
    {target: body10,stroke: "#ffd166"}],0.38,"ease_out",0);
scene.create(edge10to5,0.25,"linear");
scene.growFromCenter(node5,0.26,tmath.animCurve.preset("back",0.55));
scene.play([{target: cardBodies[0],fill: "#132235",stroke: "#91a4b7"},
    {target: cardBodies[1],fill: "#512535",stroke: "#ffd166"},{target: body10,stroke: "#f4f7fb"},
    {target: body5,stroke: "#ffd166"}],0.38,"ease_out",0);
scene.create(edge5to1,0.25,"linear");
scene.growFromCenter(node1,0.26,tmath.animCurve.preset("back",0.55));
scene.play([{target: cardBodies[1],fill: "#132235",stroke: "#ff5d73"},
    {target: cardBodies[2],fill: "#512535",stroke: "#ffd166"},{target: body5,stroke: "#ff5d73"},
    {target: body1,stroke: "#ffd166"},{target: edge5to1,stroke: "#ff5d73"},
    {target: violation,opacity: 1},{target: repair,opacity: 1}],0.50,"ease_in_out",0);
scene.play([{target: rootBadge,opacity: 0},{target: violation,opacity: 0},{target: repair,opacity: 0}],
    0.24,"ease_out",0);
scene.play([
    {target: node5,shift: [1.45,1.30]},{target: node1,shift: [1.45,1.30]},
    {target: node10,shift: [1.45,-1.30]},{target: body5,fill: "#263343",stroke: "#f4f7fb"},
    {target: body10,fill: "#c9364e",stroke: "#f4f7fb"},{target: body1,stroke: "#f4f7fb"},
    {target: edge5to1,stroke: "#718399"},{target: cardBodies[0],fill: "#512535",stroke: "#ff5d73"},
    {target: cardBodies[1],fill: "#283b50",stroke: "#91a4b7"},
    {target: cardBodies[2],fill: "#512535",stroke: "#ff5d73"},
],0.96,"ease_in_out",0);
scene.play([{target: rootBadgeAfter,opacity: 1},{target: repaired,opacity: 1}],0.32,"ease_out",0);
scene.wait(0.75);
return scene;
`;

export const TREE_EXAMPLES = [
    {
        id: "kd-tree",
        title: "KD-tree partition and nearest search",
        description:
            "Build alternating x/y partitions beside their tree, then trace a nearest-neighbor query.",
        category: "Data structures",
        dimension: "2D",
        fonts: PRETENDARD,
        lua: KD_TREE_LUA,
        js: KD_TREE_JS,
    },
    {
        id: "red-black-tree",
        title: "Red-black tree rotation",
        description:
            "Insert 10, 5, 1; expose the red-red violation; then stage a right rotation, recolor, and invariant check.",
        category: "Data structures",
        dimension: "2D",
        fonts: PRETENDARD,
        lua: RED_BLACK_TREE_LUA,
        js: RED_BLACK_TREE_JS,
    },
];
