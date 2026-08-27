import { ANIMATION_EXAMPLES } from "./catalog_animations.js";
import { ADVANCED_EXAMPLES } from "./catalog_advanced.js";
import { ANIMATRIX_EXAMPLES } from "./catalog_animatrix.js";
import { COLOR_EXAMPLES } from "./catalog_color.js";
import { CHEATSHEET_EXAMPLES } from "./catalog_cheatsheets.js";
import { CONIC_EXAMPLES } from "./catalog_conic.js";
import { CONIC_ARTICLE_EXAMPLES } from "./catalog_conic_article.js";
import { DIAGRAM_EXAMPLES } from "./catalog_diagrams.js";
import { KINEMATICS_EXAMPLES } from "./catalog_kinematics.js";
import { MANIM_EXAMPLES } from "./catalog_manim.js";
import { MATH_EXAMPLES } from "./catalog_math.js";
import { RENDERING_EXAMPLES } from "./catalog_rendering.js";
import { COMPOSITION_EXAMPLES } from "./catalog_composition.js";
import { SORT_EXAMPLES } from "./catalog_sorts.js";
import { TREE_EXAMPLES } from "./catalog_trees.js";
import { TMATH_EXAMPLES } from "./catalog_tmath.js";

export const EXAMPLES = [
    ...TMATH_EXAMPLES,
    ...CHEATSHEET_EXAMPLES,
    ...MANIM_EXAMPLES,
    ...DIAGRAM_EXAMPLES,
    ...ANIMATION_EXAMPLES,
    ...ANIMATRIX_EXAMPLES,
    ...COLOR_EXAMPLES,
    ...KINEMATICS_EXAMPLES,
    {
        id: "arrow-tails",
        title: "Arrow tails",
        description: "Independent start and end caps under a source-locked fixed camera.",
        category: "Basics",
        dimension: "2D",
        lua: `local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    camera = { mode = "fixed", view = "2d", height = 6 },
}

local world = scene:space {
    x = { -6, 6, 1 },
    y = { -3, 3, 1 },
    axis_x = "#ef5350",
    axis_y = "#66bb6a",
    id = "plane",
}
local axis = world:arrow {
    from = { -2.8, 0 },
    to = { 2.8, 0 },
    tail = 16,
    tip = 20,
    color = "#ffd166",
    width = 5,
    id = "double-arrow",
}
world:vector {
    value = { 2.2, 1.45 },
    color = "#4cc9f0",
    width = 5,
    id = "vector",
}
local point = world:point {
    point = { 2.2, 1.45 },
    fill = "#ef5350",
    radius = 7,
    id = "target",
}

scene:transform(axis, {
    0.72,
    -0.69,
    0,
    0,
    0.69,
    0.72,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    1,
}, 1.6, "ease_in_out")
scene:fade(point, 0.25, 0.5, "ease_out")
scene:wait(0.4)
return scene
`,
        js: `const scene = tmath.scene({
    width: 960,
    height: 540,
    fps: 30,
    camera: { mode: "fixed", view: "2d", height: 6 },
});

const world = scene.space({
    x: [-6, 6, 1],
    y: [-3, 3, 1],
    axis_x: "#ef5350",
    axis_y: "#66bb6a",
    id: "plane",
});
const axis = world.arrow({
    from: [-2.8, 0],
    to: [2.8, 0],
    tail: 16,
    tip: 20,
    color: "#ffd166",
    width: 5,
    id: "double-arrow",
});
world.vector({
    value: [2.2, 1.45],
    color: "#4cc9f0",
    width: 5,
    id: "vector",
});
const point = world.point({
    point: [2.2, 1.45],
    fill: "#ef5350",
    radius: 7,
    id: "target",
});

scene.transform(
    axis,
    [0.72, -0.69, 0, 0, 0.69, 0.72, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1],
    1.6,
    "ease_in_out",
);
scene.fade(point, 0.25, 0.5, "ease_out");
scene.wait(0.4);
return scene;
`,
    },
    {
        id: "matrix-transform",
        title: "Matrix transform",
        description:
            "Transform one local Space; its square and basis vector follow through hierarchy.",
        category: "Linear algebra",
        dimension: "2D",
        lua: `local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    camera = { mode = "interactive", view = "2d", height = 7 },
}

local world = scene:space {
    x = { -6, 6, 1 },
    y = { -4, 4, 1 },
    z = { 0, 0, 1 },
    color = "#28323d",
    id = "global-space",
}
local space = scene:space {
    x = { -3, 3, 1 },
    y = { -3, 3, 1 },
    z = { 0, 0, 1 },
    color = "#665c99",
    axis_x = "#ff8a80",
    axis_y = "#9ccc65",
    id = "local-space",
}
local square = space:polygon {
    points = { { 0, 0 }, { 2, 0 }, { 2, 2 }, { 0, 2 } },
    fill = "#4cc9f044",
    stroke = "#4cc9f0",
    width = 4,
    id = "unit-square",
}
local basis = space:vector { value = { 2, 0 }, color = "#ffd166", width = 5, id = "basis-x" }
local matrix = {
    1.0,
    0.65,
    0,
    0,
    0.35,
    1.0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    1,
}

scene:create({ world, space, square, basis }, 0.8, "ease_out", 0.12)
scene:transform(space, matrix, 1.4, "ease_in_out")
scene:wait(0.5)
return scene
`,
        js: `const scene = tmath.scene({
    width: 960,
    height: 540,
    fps: 30,
    camera: { mode: "interactive", view: "2d", height: 7 },
});

const world = scene.space({
    x: [-6, 6, 1],
    y: [-4, 4, 1],
    z: [0, 0, 1],
    color: "#28323d",
    id: "global-space",
});
const space = scene.space({
    x: [-3, 3, 1],
    y: [-3, 3, 1],
    z: [0, 0, 1],
    color: "#665c99",
    axis_x: "#ff8a80",
    axis_y: "#9ccc65",
    id: "local-space",
});
const square = space.polygon({
    points: [
        [0, 0],
        [2, 0],
        [2, 2],
        [0, 2],
    ],
    fill: "#4cc9f044",
    stroke: "#4cc9f0",
    width: 4,
    id: "unit-square",
});
const basis = space.vector({ value: [2, 0], color: "#ffd166", width: 5, id: "basis-x" });
const matrix = [1, 0.65, 0, 0, 0.35, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];

scene.create([world, space, square, basis], 0.8, "ease_out", 0.12);
scene.transform(space, matrix, 1.4, "ease_in_out");
scene.wait(0.5);
return scene;
`,
    },
    {
        id: "perspective-3d",
        title: "Perspective projection",
        description: "Project a 3D space, basis vectors, and a depth segment.",
        category: "Computer graphics",
        dimension: "3D",
        lua: `local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    camera = {
        mode = "interactive",
        view = "3d",
        eye = { 5.5, 4.2, 6.5 },
        target = { 0, 0, 0 },
        up = { 0, 1, 0 },
        projection = "perspective",
        fov = 0.72,
        near = 0.1,
        far = 100,
    },
}

local space = scene:space {
    x = { -3, 3, 1 },
    y = { -3, 3, 1 },
    z = { -3, 3, 1 },
    color = "#34404b",
    width = 1,
    id = "world-space",
}
local x = space:vector { value = { 2.5, 0, 0 }, color = "#ef5350", width = 5, id = "axis-x" }
local y = space:vector { value = { 0, 2.5, 0 }, color = "#7bd88f", width = 5, id = "axis-y" }
local z = space:vector { value = { 0, 0, 2.5 }, color = "#4cc9f0", width = 5, id = "axis-z" }
local depth = space:arrow {
    from = { -1.5, -1.2, -1.5 },
    to = { 1.4, 1.6, 1.8 },
    tail = 10,
    tip = 15,
    color = "#ffd166",
    width = 4,
    id = "depth",
}

scene:create(space, 0.8, "linear")
scene:create({ x, y, z }, 0.9, "ease_out", 0.12)
scene:create(depth, 0.8, "ease_out")
scene:wait(0.5)
return scene
`,
        js: `const scene = tmath.scene({
    width: 960,
    height: 540,
    fps: 30,
    camera: {
        mode: "interactive",
        view: "3d",
        eye: [5.5, 4.2, 6.5],
        target: [0, 0, 0],
        up: [0, 1, 0],
        projection: "perspective",
        fov: 0.72,
        near: 0.1,
        far: 100,
    },
});

const space = scene.space({
    x: [-3, 3, 1],
    y: [-3, 3, 1],
    z: [-3, 3, 1],
    color: "#34404b",
    width: 1,
    id: "world-space",
});
const x = space.vector({ value: [2.5, 0, 0], color: "#ef5350", width: 5, id: "axis-x" });
const y = space.vector({ value: [0, 2.5, 0], color: "#7bd88f", width: 5, id: "axis-y" });
const z = space.vector({ value: [0, 0, 2.5], color: "#4cc9f0", width: 5, id: "axis-z" });
const depth = space.arrow({
    from: [-1.5, -1.2, -1.5],
    to: [1.4, 1.6, 1.8],
    tail: 10,
    tip: 15,
    color: "#ffd166",
    width: 4,
    id: "depth",
});

scene.create(space, 0.8, "linear");
scene.create([x, y, z], 0.9, "ease_out", 0.12);
scene.create(depth, 0.8, "ease_out");
scene.wait(0.5);
return scene;
`,
    },
    {
        id: "dimension-transition",
        title: "2D / 3D / 2D",
        description:
            "Move one fixed camera around the same Space and objects, then return front-on.",
        category: "Computer graphics",
        dimension: "2D ↔ 3D",
        lua: `local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    camera = { mode = "fixed", view = "2d", target = { 0, 0 }, height = 8 },
}

local world = scene:space {
    x = { -4, 4, 1 },
    y = { -3, 3, 1 },
    z = { -3, 3, 1 },
    color = "#34404b",
    id = "world",
}
local square = world:polygon {
    points = { { 0, 0 }, { 2, 0 }, { 2, 2 }, { 0, 2 } },
    fill = "#4cc9f044",
    stroke = "#4cc9f0",
    width = 4,
    id = "square",
}
local x = world:vector { value = { 2.4, 0, 0 }, color = "#ef5350", width = 5, id = "basis-x" }
local y = world:vector { value = { 0, 2.4, 0 }, color = "#7bd88f", width = 5, id = "basis-y" }
local z = world:vector { value = { 0, 0, 2.4 }, color = "#ffd166", width = 5, id = "basis-z" }

scene:create({ world, square, x, y, z }, 0.7, "ease_out", 0.08)
scene:wait(0.35)
scene:look({
    view = "3d",
    eye = { 5.5, 4.2, 6.5 },
    target = { 0, 0, 0 },
    up = { 0, 1, 0 },
    projection = "perspective",
    fov = 0.76101275,
    near = 0.1,
    far = 100,
}, 1.2, "ease_in_out")
scene:wait(0.65)
scene:look({
    view = "2d",
    target = { 0, 0 },
    eye = { 0, 0, 10 },
    up = { 0, 1, 0 },
    projection = "orthographic",
    height = 8,
}, 1.2, "ease_in_out")
scene:wait(0.5)
return scene
`,
        js: `const scene = tmath.scene({
    width: 960,
    height: 540,
    fps: 30,
    camera: { mode: "fixed", view: "2d", target: [0, 0], height: 8 },
});

const world = scene.space({
    x: [-4, 4, 1],
    y: [-3, 3, 1],
    z: [-3, 3, 1],
    color: "#34404b",
    id: "world",
});
const square = world.polygon({
    points: [
        [0, 0],
        [2, 0],
        [2, 2],
        [0, 2],
    ],
    fill: "#4cc9f044",
    stroke: "#4cc9f0",
    width: 4,
    id: "square",
});
const x = world.vector({ value: [2.4, 0, 0], color: "#ef5350", width: 5, id: "basis-x" });
const y = world.vector({ value: [0, 2.4, 0], color: "#7bd88f", width: 5, id: "basis-y" });
const z = world.vector({ value: [0, 0, 2.4], color: "#ffd166", width: 5, id: "basis-z" });

scene.create([world, square, x, y, z], 0.7, "ease_out", 0.08);
scene.wait(0.35);
scene.look(
    {
        view: "3d",
        eye: [5.5, 4.2, 6.5],
        target: [0, 0, 0],
        up: [0, 1, 0],
        projection: "perspective",
        fov: 0.76101275,
        near: 0.1,
        far: 100,
    },
    1.2,
    "ease_in_out",
);
scene.wait(0.65);
scene.look(
    {
        view: "2d",
        target: [0, 0],
        eye: [0, 0, 10],
        up: [0, 1, 0],
        projection: "orthographic",
        height: 8,
    },
    1.2,
    "ease_in_out",
);
scene.wait(0.5);
return scene;
`,
    },
    {
        id: "image-cells",
        title: "Image cells / voxels",
        description:
            "Decode one ThorVG asset, preserve image scale, patch Space cells, then view them as shaded voxels.",
        category: "Image processing",
        dimension: "2D ↔ 3D",
        assets: [{ name: "../assets/pixels.svg", url: "./pixels.svg", mime: "svg" }],
        lua: `local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    antialiasing = true,
    camera = { mode = "fixed", view = "2d", height = 11 },
}

local world =
    scene:space { x = { -7, 7, 1 }, y = { -4, 4, 1 }, z = { -2, 2, 1 }, color = "#293540" }
local image = world:image {
    asset = "../assets/pixels.svg",
    center = { -3.8, 0, 0 },
    width = 4,
    filter = "nearest",
    id = "source-image",
}
local cells = world:cell {
    origin = { 0, -2, 0 },
    size = { 4, 4 },
    mode = "padd",
    padding = 0.05,
    depth = 1,
    texture = "../assets/pixels.svg",
    source = { 0, 0, 8, 8 },
    destination = { 0, 0, 4, 4 },
    patches = { { region = { 1, 1, 2, 2 }, color = "#ffffff" } },
    id = "pixel-cells",
}
scene:create({ image, cells }, 0.9, "ease_out", 0.15)
scene:wait(0.4)
scene:look({
    view = "3d",
    eye = { 7, 6, 9 },
    target = { 0, 0, 0 },
    up = { 0, 1, 0 },
    projection = "perspective",
    fov = 0.75,
    near = 0.1,
    far = 100,
}, 1.2, "ease_in_out")
scene:wait(0.7)
return scene
`,
        js: `const scene = tmath.scene({
    width: 960,
    height: 540,
    fps: 30,
    antialiasing: true,
    camera: { mode: "fixed", view: "2d", height: 11 },
});

const world = scene.space({ x: [-7, 7, 1], y: [-4, 4, 1], z: [-2, 2, 1], color: "#293540" });
const image = world.image({
    asset: "../assets/pixels.svg",
    center: [-3.8, 0, 0],
    width: 4,
    filter: "nearest",
    id: "source-image",
});
const cells = world.cell({
    origin: [0, -2, 0],
    size: [4, 4],
    mode: "padd",
    padding: 0.05,
    depth: 1,
    texture: "../assets/pixels.svg",
    source: [0, 0, 8, 8],
    destination: [0, 0, 4, 4],
    patches: [{ region: [1, 1, 2, 2], color: "#ffffff" }],
    id: "pixel-cells",
});
scene.create([image, cells], 0.9, "ease_out", 0.15);
scene.wait(0.4);
scene.look(
    {
        view: "3d",
        eye: [7, 6, 9],
        target: [0, 0, 0],
        up: [0, 1, 0],
        projection: "perspective",
        fov: 0.75,
        near: 0.1,
        far: 100,
    },
    1.2,
    "ease_in_out",
);
scene.wait(0.7);
return scene;
`,
    },
    ...COMPOSITION_EXAMPLES,
    ...SORT_EXAMPLES,
    ...TREE_EXAMPLES,
    ...CONIC_EXAMPLES,
    ...CONIC_ARTICLE_EXAMPLES,
    ...MATH_EXAMPLES,
    ...RENDERING_EXAMPLES,
    ...ADVANCED_EXAMPLES,
];
