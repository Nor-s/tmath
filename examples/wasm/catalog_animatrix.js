const PRETENDARD = [{ name: "Pretendard", url: "./Pretendard.ttf", mime: "ttf" }];

export const ANIMATRIX_EXAMPLES = [
    {
        id: "animatrix-surface-write",
        title: "Surface and spatial type",
        description: "A seamless sampled surface, plane-oriented 3D text, and traced fill.",
        category: "Computer graphics",
        dimension: "2D + 3D",
        fonts: PRETENDARD,
        lua: `local p = {
    paper = "#f7f8fc",
    panel = "#ffffff",
    ink = "#172033",
    muted = "#667085",
    rule = "#dde3ee",
    blue = "#5271e8",
    cyan = "#20b8cd",
    coral = "#ef6461",
    gold = "#f4b942",
}
local page = tmath.scene {
    width = 960,
    height = 540,
    fps = 60,
    loop = false,
    antialiasing = true,
    background = p.paper,
    camera = { mode = "fixed", view = "2d", height = 9 },
}
page:text {
    text = "GEOMETRY THAT EXPLAINS ITSELF",
    point = { -7.15, 3.78 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 25,
    fill = p.ink,
    id = "title",
}
page:text {
    text = "sampled surface  /  spatial type  /  traced fill",
    point = { -7.12, 3.22 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 12,
    fill = p.muted,
    id = "subtitle",
}
page:line {
    from = { -7.15, 2.87 },
    to = { 7.15, 2.87 },
    stroke = p.rule,
    width = 1,
    id = "title-rule",
}

local graph = tmath.scene {
    width = 620,
    height = 390,
    fps = 60,
    background = p.panel,
    camera = {
        mode = "fixed",
        view = "3d",
        eye = { 6.6, 4.8, 7.2 },
        target = { 0, 0, 0 },
        up = { 0, 1, 0 },
        projection = "perspective",
        fov = 0.62,
        near = 0.1,
        far = 100,
    },
}
local axes = {
    graph:arrow {
        from = { -3.55, -1.10, 0 },
        to = { 3.55, -1.10, 0 },
        stroke = p.coral,
        width = 2.5,
        tip = 10,
        id = "axis-x",
    },
    graph:arrow {
        from = { 0, -1.10, -3.35 },
        to = { 0, -1.10, 3.35 },
        stroke = p.cyan,
        width = 2.5,
        tip = 10,
        id = "axis-z",
    },
    graph:arrow {
        from = { 0, -1.10, 0 },
        to = { 0, 1.75, 0 },
        stroke = p.gold,
        width = 2.5,
        tip = 10,
        id = "axis-y",
    },
}
local columns, rows, points = 29, 23, {}
for row = 0, rows - 1 do
    local z = -3 + 6 * row / (rows - 1)
    for column = 0, columns - 1 do
        local x = -3 + 6 * column / (columns - 1)
        local radial = math.exp(-0.055 * (x * x + z * z))
        points[#points + 1] = { x, 0.82 * math.sin(x) * math.cos(z) * radial, z }
    end
end
local surface = graph:surface {
    points = points,
    size = { columns, rows },
    mode = "solid",
    fill = "#5271e8dc",
    id = "wave-surface",
}
local plane = graph:group {
    matrix = { 1, 0, 0, 0, 0, 0, 1, -1.12, 0, -1, 0, -2.75, 0, 0, 0, 1 },
    id = "ground-type-plane",
}
local planeLabel = plane:text {
    text = "f(x,z) = sin(x) cos(z)",
    point = { 0, 0, 0 },
    align = { 0.5, 0.5 },
    orientation = "plane",
    size = 0.52,
    font = "Pretendard",
    fill = p.ink,
    id = "plane-label",
}
local billboard = graph:text {
    text = "surface value",
    point = { 0.55, 1.33, 0.15 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = p.muted,
    id = "billboard-label",
}
local normal = graph:vector {
    origin = { 0.42, 0.29, 0.18 },
    value = { -0.55, 1.15, 0.40 },
    stroke = p.gold,
    width = 4,
    tip = 13,
    layer = 8,
    id = "surface-normal",
}
graph:create(axes, 0.45, "ease_out", 0.06)
graph:create(surface, 1.20, { preset = "gentle", strength = 0.85 })
graph:fade_in(planeLabel, { shift = { 0, 0.12, 0 }, duration = 0.42, curve = "ease_out" })
graph:create({ normal, billboard }, 0.42, "snappy", 0.08)
graph:look({
    view = "3d",
    eye = { -5.8, 5.2, 6.4 },
    target = { 0, -0.15, 0 },
    up = { 0, 1, 0 },
    projection = "perspective",
    fov = 0.62,
    near = 0.1,
    far = 100,
}, 1.40, "ease_in_out")
graph:wait(0.35)

local writing = tmath.scene {
    width = 300,
    height = 390,
    fps = 60,
    background = p.panel,
    camera = { mode = "fixed", view = "2d", height = 7.8 },
}
writing:text {
    text = "WRITE",
    point = { -2.45, 3.15 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 12,
    fill = p.coral,
    id = "write-eyebrow",
}
writing:text {
    text = "one contour,\\none continuous reveal",
    point = { -2.45, 2.57 },
    align = { 0, 0 },
    font = "Pretendard",
    size = 18,
    fill = p.ink,
    id = "write-title",
}
local contour = writing:path {
    commands = {
        { type = "move", to = { -1.70, -0.15 } },
        {
            type = "cubic",
            control1 = { -1.78, 1.18 },
            control2 = { -0.30, 1.62 },
            to = { 0.18, 0.52 },
        },
        {
            type = "cubic",
            control1 = { 0.82, -0.68 },
            control2 = { 1.74, 0.42 },
            to = { 1.58, -0.72 },
        },
        { type = "quadratic", control = { 0.08, -1.66 }, to = { -1.70, -0.15 } },
        { type = "close" },
    },
    samples = 42,
    fill = "#ef6461b8",
    stroke = p.coral,
    width = 4,
    id = "write-contour",
}
local note = writing:text {
    text = "fill is clipped to the\\nalready traced region",
    point = { 0, -2.35 },
    align = { 0.5, 0 },
    font = "Pretendard",
    size = 12,
    fill = p.muted,
    id = "write-note",
}
writing:wait(0.28)
writing:write(contour, 1.85, { preset = "gentle", strength = 0.80 })
writing:fade_in(note, { shift = { 0, -0.16 }, duration = 0.40, curve = "ease_out" })
writing:wait(1.31)
page:viewport(graph, { x = 0.025, y = 0.24, width = 0.64, height = 0.72 })
page:viewport(writing, { x = 0.69, y = 0.24, width = 0.285, height = 0.72 })
return page
`,
        js: `const p = {
    paper: "#f7f8fc",
    panel: "#ffffff",
    ink: "#172033",
    muted: "#667085",
    rule: "#dde3ee",
    blue: "#5271e8",
    cyan: "#20b8cd",
    coral: "#ef6461",
    gold: "#f4b942",
};
const page = tmath.scene({
    width: 960,
    height: 540,
    fps: 60,
    loop: false,
    antialiasing: true,
    background: p.paper,
    camera: { mode: "fixed", view: "2d", height: 9 },
});
page.text({
    text: "GEOMETRY THAT EXPLAINS ITSELF",
    point: [-7.15, 3.78],
    align: [0, 0.5],
    font: "Pretendard",
    size: 25,
    fill: p.ink,
    id: "title",
});
page.text({
    text: "sampled surface  /  spatial type  /  traced fill",
    point: [-7.12, 3.22],
    align: [0, 0.5],
    font: "Pretendard",
    size: 12,
    fill: p.muted,
    id: "subtitle",
});
page.line({ from: [-7.15, 2.87], to: [7.15, 2.87], stroke: p.rule, width: 1, id: "title-rule" });

const graph = tmath.scene({
    width: 620,
    height: 390,
    fps: 60,
    background: p.panel,
    camera: {
        mode: "fixed",
        view: "3d",
        eye: [6.6, 4.8, 7.2],
        target: [0, 0, 0],
        up: [0, 1, 0],
        projection: "perspective",
        fov: 0.62,
        near: 0.1,
        far: 100,
    },
});
const axes = [
    graph.arrow({
        from: [-3.55, -1.1, 0],
        to: [3.55, -1.1, 0],
        stroke: p.coral,
        width: 2.5,
        tip: 10,
        id: "axis-x",
    }),
    graph.arrow({
        from: [0, -1.1, -3.35],
        to: [0, -1.1, 3.35],
        stroke: p.cyan,
        width: 2.5,
        tip: 10,
        id: "axis-z",
    }),
    graph.arrow({
        from: [0, -1.1, 0],
        to: [0, 1.75, 0],
        stroke: p.gold,
        width: 2.5,
        tip: 10,
        id: "axis-y",
    }),
];
const columns = 29,
    rows = 23,
    points = [];
for (let row = 0; row < rows; row++) {
    const z = -3 + (6 * row) / (rows - 1);
    for (let column = 0; column < columns; column++) {
        const x = -3 + (6 * column) / (columns - 1);
        const radial = Math.exp(-0.055 * (x * x + z * z));
        points.push([x, 0.82 * Math.sin(x) * Math.cos(z) * radial, z]);
    }
}
const surface = graph.surface({
    points,
    size: [columns, rows],
    mode: "solid",
    fill: "#5271e8dc",
    id: "wave-surface",
});
const plane = graph.group({
    matrix: [1, 0, 0, 0, 0, 0, 1, -1.12, 0, -1, 0, -2.75, 0, 0, 0, 1],
    id: "ground-type-plane",
});
const planeLabel = plane.text({
    text: "f(x,z) = sin(x) cos(z)",
    point: [0, 0, 0],
    align: [0.5, 0.5],
    orientation: "plane",
    size: 0.52,
    font: "Pretendard",
    fill: p.ink,
    id: "plane-label",
});
const billboard = graph.text({
    text: "surface value",
    point: [0.55, 1.33, 0.15],
    align: [0, 0.5],
    font: "Pretendard",
    size: 13,
    fill: p.muted,
    id: "billboard-label",
});
const normal = graph.vector({
    origin: [0.42, 0.29, 0.18],
    value: [-0.55, 1.15, 0.4],
    stroke: p.gold,
    width: 4,
    tip: 13,
    layer: 8,
    id: "surface-normal",
});
graph
    .create(axes, 0.45, "ease_out", 0.06)
    .create(surface, 1.2, { preset: "gentle", strength: 0.85 });
graph.fadeIn(planeLabel, { shift: [0, 0.12, 0], duration: 0.42, curve: "ease_out" });
graph.create([normal, billboard], 0.42, "snappy", 0.08);
graph
    .look(
        {
            view: "3d",
            eye: [-5.8, 5.2, 6.4],
            target: [0, -0.15, 0],
            up: [0, 1, 0],
            projection: "perspective",
            fov: 0.62,
            near: 0.1,
            far: 100,
        },
        1.4,
        "ease_in_out",
    )
    .wait(0.35);

const writing = tmath.scene({
    width: 300,
    height: 390,
    fps: 60,
    background: p.panel,
    camera: { mode: "fixed", view: "2d", height: 7.8 },
});
writing.text({
    text: "WRITE",
    point: [-2.45, 3.15],
    align: [0, 0.5],
    font: "Pretendard",
    size: 12,
    fill: p.coral,
    id: "write-eyebrow",
});
writing.text({
    text: "one contour,\\none continuous reveal",
    point: [-2.45, 2.57],
    align: [0, 0],
    font: "Pretendard",
    size: 18,
    fill: p.ink,
    id: "write-title",
});
const contour = writing.path({
    commands: [
        { type: "move", to: [-1.7, -0.15] },
        { type: "cubic", control1: [-1.78, 1.18], control2: [-0.3, 1.62], to: [0.18, 0.52] },
        { type: "cubic", control1: [0.82, -0.68], control2: [1.74, 0.42], to: [1.58, -0.72] },
        { type: "quadratic", control: [0.08, -1.66], to: [-1.7, -0.15] },
        { type: "close" },
    ],
    samples: 42,
    fill: "#ef6461b8",
    stroke: p.coral,
    width: 4,
    id: "write-contour",
});
const note = writing.text({
    text: "fill is clipped to the\\nalready traced region",
    point: [0, -2.35],
    align: [0.5, 0],
    font: "Pretendard",
    size: 12,
    fill: p.muted,
    id: "write-note",
});
writing.wait(0.28).write(contour, 1.85, { preset: "gentle", strength: 0.8 });
writing.fadeIn(note, { shift: [0, -0.16], duration: 0.4, curve: "ease_out" }).wait(1.31);
page.viewport(graph, { x: 0.025, y: 0.24, width: 0.64, height: 0.72 });
page.viewport(writing, { x: 0.69, y: 0.24, width: 0.285, height: 0.72 });
return page;
`,
    },
];
