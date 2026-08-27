const PRETENDARD = [{ name: "Pretendard", url: "./Pretendard.ttf", mime: "ttf" }];

export const ADVANCED_EXAMPLES = [
    {
        id: "mathbox-mobius",
        title: "Sampled Möbius manifold",
        description:
            "Map one sampled (u, v) domain into a 3D Möbius wire surface, trajectory, and differential frame.",
        category: "Computer graphics",
        dimension: "2D + 3D",
        fonts: PRETENDARD,
        lua: `-- Inspired by MathBox's sampled data -> visual primitive composition.
local p = {
    paper = "#f4f2ed",
    panel = "#fffefa",
    ink = "#172033",
    muted = "#667085",
    soft = "#98a2b3",
    rule = "#d9dde5",
    violet = "#5b5ce2",
    tangent = "#ef476f",
    width = "#06b6d4",
    normal = "#f59e0b",
    tracer = "#7c3aed",
}
local tau, R, W = 2 * math.pi, 2.25, 0.72
local function P(u, v)
    local r = R + v * math.cos(u / 2)
    return { r * math.cos(u), v * math.sin(u / 2), r * math.sin(u) }
end
local function sub(a, b)
    return { a[1] - b[1], a[2] - b[2], a[3] - b[3] }
end
local function scale(a, s)
    return { a[1] * s, a[2] * s, a[3] * s }
end
local function norm(a)
    local l = math.sqrt(a[1] ^ 2 + a[2] ^ 2 + a[3] ^ 2)
    return scale(a, 1 / l)
end
local function cross(a, b)
    return { a[2] * b[3] - a[3] * b[2], a[3] * b[1] - a[1] * b[3], a[1] * b[2] - a[2] * b[1] }
end

local page = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    loop = false,
    antialiasing = true,
    background = p.paper,
    camera = { mode = "fixed", view = "2d", height = 9 },
}
local root = page:space { x = { -8, 8, 1 }, y = { -4.5, 4.5, 1 }, opacity = 0 }
local function label(parent, text, point, size, color, id, align)
    return parent:text {
        text = text,
        point = point,
        size = size,
        font = "Pretendard",
        fill = color or p.ink,
        id = id,
        align = align or { 0.5, 0.5 },
    }
end
label(
    root,
    "ADVANCED VISUALIZATION  /  PARAMETRIC MANIFOLD",
    { -7.25, 3.78 },
    11,
    p.violet,
    "eyebrow",
    { 0, 0.5 }
)
label(
    root,
    "A Möbius strip from one sampled area",
    { -7.25, 3.28 },
    27,
    p.ink,
    "title",
    { 0, 0.5 }
)
label(
    root,
    "The same (u, v) data becomes a 3D surface, a trajectory, and a local frame.",
    { -7.25, 2.72 },
    13,
    p.muted,
    "subtitle",
    { 0, 0.5 }
)
root:line { from = { -7.25, 2.40 }, to = { 7.25, 2.40 }, color = p.rule, width = 1 }
label(
    root,
    "sampled area  →  curves + vectors + linked parameter domain",
    { 0, -4.14 },
    10,
    p.soft,
    "pipeline"
)
page:create(root, 0.32, "ease_out")

local view = tmath.scene {
    width = 614,
    height = 373,
    fps = 30,
    background = p.panel,
    camera = {
        mode = "fixed",
        view = "3d",
        eye = { 6.4, 4.8, 6.8 },
        target = { 0, 0, 0 },
        up = { 0, 1, 0 },
        projection = "perspective",
        fov = 0.62,
        near = 0.1,
        far = 100,
    },
}
local surface = view:group { id = "sampled-surface" }
local colors = {
    "#5b5ce2b8",
    "#5268e0c0",
    "#4775ddc8",
    "#3982d8d0",
    "#2b8ed1d8",
    "#1999c8e0",
    "#0ea5bce8",
    "#10afb0ee",
    "#14b8a6f4",
    "#24b39df0",
    "#35ad94e8",
    "#47a78bde",
    "#5aa082d4",
}
local bands = {}
for band = 0, 12 do
    local v = -W + 2 * W * band / 12
    local points = {}
    for sample = 0, 96 do
        points[#points + 1] = P(tau * sample / 96, v)
    end
    bands[#bands + 1] = surface:plot {
        points = points,
        color = colors[band + 1],
        width = 2.35,
        id = "surface-band-" .. band,
    }
end
local ribs = {}
for rib = 0, 31 do
    local u = tau * rib / 32
    local points = {}
    for sample = 0, 12 do
        points[#points + 1] = P(u, -W + 2 * W * sample / 12)
    end
    ribs[#ribs + 1] = surface:plot {
        points = points,
        color = "#17203334",
        width = 1.25,
        id = "surface-rib-" .. rib,
    }
end
local center = {}
for sample = 0, 128 do
    center[#center + 1] = P(tau * sample / 128, 0)
end
local centerline = surface:plot { points = center, color = p.ink, width = 3, id = "centerline" }
local u, v, e = 1.18 * math.pi, 0.20, 0.001
local origin = P(u, v)
local du = norm(sub(P(u + e, v), P(u - e, v)))
local dv = norm(sub(P(u, v + e), P(u, v - e)))
local normal = norm(cross(du, dv))
local frame = {
    surface:point {
        point = origin,
        fill = p.ink,
        stroke = p.panel,
        width = 2,
        radius = 7,
        layer = 8,
        id = "frame-origin",
    },
    surface:vector {
        origin = origin,
        value = scale(du, 1.02),
        color = p.tangent,
        width = 4,
        tip = 11,
        layer = 9,
        id = "frame-du",
    },
    surface:vector {
        origin = origin,
        value = scale(dv, 1.02),
        color = p.width,
        width = 4,
        tip = 11,
        layer = 9,
        id = "frame-dv",
    },
    surface:vector {
        origin = origin,
        value = scale(normal, 1.02),
        color = p.normal,
        width = 4,
        tip = 11,
        layer = 9,
        id = "frame-normal",
    },
}
local tracer = surface:point {
    point = P(0, 0),
    fill = p.tracer,
    stroke = p.panel,
    width = 2,
    radius = 7,
    layer = 10,
    id = "surface-tracer",
}
view:create(bands, 0.62, "ease_out", 0.035)
view:create(ribs, 0.46, "ease_out", 0.013)
view:create(centerline, 0.72, "linear")
view:grow_from_center(tracer, 0.20, "snappy")
for sample = 1, 24 do
    view:shift(tracer, sub(P(tau * sample / 24, 0), P(tau * (sample - 1) / 24, 0)), 0.055, "linear")
end
view:create(frame, 0.44, "snappy", 0.055)
view:look({
    view = "3d",
    eye = { -5.8, 5.4, 6.1 },
    target = { 0, 0, 0 },
    up = { 0, 1, 0 },
    projection = "perspective",
    fov = 0.62,
    near = 0.1,
    far = 100,
}, 1.35, "ease_in_out")
view:wait(0.45)

local domainScene = tmath.scene {
    width = 274,
    height = 373,
    fps = 30,
    background = p.panel,
    camera = { mode = "fixed", view = "2d", height = 9 },
}
local domain = domainScene:space { x = { -3.3, 3.3, 1 }, y = { -4.5, 4.5, 1 }, opacity = 0 }
label(domain, "PARAMETER DOMAIN", { -2.72, 3.96 }, 11, p.violet, "domain-title", { 0, 0.5 })
label(domain, "P(u, v)", { -2.72, 3.33 }, 22, p.ink, "domain-symbol", { 0, 0.5 })
label(domain, "x = (R + v cos(u/2)) cos u", { -2.72, 2.68 }, 10, p.muted, "formula-x", { 0, 0.5 })
label(domain, "y = v sin(u/2)", { -2.72, 2.20 }, 10, p.muted, "formula-y", { 0, 0.5 })
label(domain, "z = (R + v cos(u/2)) sin u", { -2.72, 1.72 }, 10, p.muted, "formula-z", { 0, 0.5 })
local box = domain:rectangle {
    center = { 0, 0.25 },
    size = { 5.42, 2.16 },
    corner = 0.08,
    fill = "#f4f6ff",
    stroke = p.rule,
    width = 1.5,
    id = "uv-domain",
}
local grid = {}
for column = 1, 7 do
    local x = -2.71 + 5.42 * column / 8
    grid[#grid + 1] =
        domain:line { from = { x, -0.83 }, to = { x, 1.33 }, color = "#5b5ce220", width = 1 }
end
for row = 1, 3 do
    local y = -0.83 + 2.16 * row / 4
    grid[#grid + 1] =
        domain:line { from = { -2.71, y }, to = { 2.71, y }, color = "#5b5ce220", width = 1 }
end
local path = domain:line {
    from = { -2.55, 0.25 },
    to = { 2.55, 0.25 },
    color = p.tracer,
    width = 3,
    id = "domain-centerline",
}
local dot = domain:point {
    point = { -2.55, 0.25 },
    fill = p.tracer,
    stroke = p.panel,
    width = 2,
    radius = 6,
    layer = 8,
    id = "domain-tracer",
}
label(domain, "u = 0", { -2.71, -1.12 }, 10, p.muted, "u-zero")
label(domain, "u = 2pi", { 2.71, -1.12 }, 10, p.muted, "u-tau")
label(domain, "v", { -2.96, 0.25 }, 11, p.muted, "v-axis")
label(domain, "(0, v)  ~  (2pi, -v)", { 0, -1.62 }, 11, p.ink, "seam-rule")
label(domain, "one turn flips the width direction", { 0, -2.16 }, 10, p.muted, "seam-note")
local specs = {
    { p.tangent, "dP/du", -2.68 },
    { p.width, "dP/dv", -3.11 },
    { p.normal, "N = normalize(du x dv)", -3.54 },
}
local legend = {}
for i, item in ipairs(specs) do
    legend[#legend + 1] = domain:line {
        from = { -2.68, item[3] },
        to = { -2.20, item[3] },
        color = item[1],
        width = 3,
        id = "legend-line-" .. i,
    }
    legend[#legend + 1] = label(
        domain,
        item[2],
        { -2.02, item[3] },
        10,
        item[1],
        "legend-text-" .. i,
        { 0, 0.5 }
    )
end
domainScene:create(box, 0.30, "ease_out")
domainScene:create(grid, 0.38, "ease_out", 0.018)
domainScene:create(path, 1.25, "linear")
domainScene:grow_from_center(dot, 0.18, "snappy")
domainScene:shift(dot, { 5.10, 0 }, 1.32, "linear")
domainScene:create(legend, 0.32, "ease_out", 0.035)
domainScene:wait(0.45)
page:viewport(view, { x = 0.025, y = 0.225, width = 0.64, height = 0.69 })
page:viewport(domainScene, { x = 0.69, y = 0.225, width = 0.285, height = 0.69 })
return page
`,
        js: `// Inspired by MathBox's sampled data -> visual primitive composition.
const p = {
    paper: "#f4f2ed",
    panel: "#fffefa",
    ink: "#172033",
    muted: "#667085",
    soft: "#98a2b3",
    rule: "#d9dde5",
    violet: "#5b5ce2",
    tangent: "#ef476f",
    width: "#06b6d4",
    normal: "#f59e0b",
    tracer: "#7c3aed",
};
const tau = 2 * Math.PI,
    R = 2.25,
    W = 0.72;
const P = (u, v) => {
    const r = R + v * Math.cos(u / 2);
    return [r * Math.cos(u), v * Math.sin(u / 2), r * Math.sin(u)];
};
const sub = (a, b) => [a[0] - b[0], a[1] - b[1], a[2] - b[2]];
const scale = (a, s) => [a[0] * s, a[1] * s, a[2] * s];
const norm = (a) => scale(a, 1 / Math.hypot(...a));
const cross = (a, b) => [
    a[1] * b[2] - a[2] * b[1],
    a[2] * b[0] - a[0] * b[2],
    a[0] * b[1] - a[1] * b[0],
];

const page = tmath.scene({
    width: 960,
    height: 540,
    fps: 30,
    loop: false,
    antialiasing: true,
    background: p.paper,
    camera: { mode: "fixed", view: "2d", height: 9 },
});
const root = page.space({ x: [-8, 8, 1], y: [-4.5, 4.5, 1], opacity: 0 });
const label = (parent, text, point, size, color, id, align) =>
    parent.text({
        text,
        point,
        size,
        font: "Pretendard",
        fill: color || p.ink,
        id,
        align: align || [0.5, 0.5],
    });
label(
    root,
    "ADVANCED VISUALIZATION  /  PARAMETRIC MANIFOLD",
    [-7.25, 3.78],
    11,
    p.violet,
    "eyebrow",
    [0, 0.5],
);
label(root, "A Möbius strip from one sampled area", [-7.25, 3.28], 27, p.ink, "title", [0, 0.5]);
label(
    root,
    "The same (u, v) data becomes a 3D surface, a trajectory, and a local frame.",
    [-7.25, 2.72],
    13,
    p.muted,
    "subtitle",
    [0, 0.5],
);
root.line({ from: [-7.25, 2.4], to: [7.25, 2.4], color: p.rule, width: 1 });
label(
    root,
    "sampled area  →  curves + vectors + linked parameter domain",
    [0, -4.14],
    10,
    p.soft,
    "pipeline",
);
page.create(root, 0.32, "ease_out");

const view = tmath.scene({
    width: 614,
    height: 373,
    fps: 30,
    background: p.panel,
    camera: {
        mode: "fixed",
        view: "3d",
        eye: [6.4, 4.8, 6.8],
        target: [0, 0, 0],
        up: [0, 1, 0],
        projection: "perspective",
        fov: 0.62,
        near: 0.1,
        far: 100,
    },
});
const surface = view.group({ id: "sampled-surface" });
const colors = [
    "#5b5ce2b8",
    "#5268e0c0",
    "#4775ddc8",
    "#3982d8d0",
    "#2b8ed1d8",
    "#1999c8e0",
    "#0ea5bce8",
    "#10afb0ee",
    "#14b8a6f4",
    "#24b39df0",
    "#35ad94e8",
    "#47a78bde",
    "#5aa082d4",
];
const bands = [];
for (let band = 0; band <= 12; band++) {
    const v = -W + (2 * W * band) / 12,
        points = [];
    for (let sample = 0; sample <= 96; sample++) points.push(P((tau * sample) / 96, v));
    bands.push(
        surface.plot({ points, color: colors[band], width: 2.35, id: "surface-band-" + band }),
    );
}
const ribs = [];
for (let rib = 0; rib < 32; rib++) {
    const u = (tau * rib) / 32,
        points = [];
    for (let sample = 0; sample <= 12; sample++) points.push(P(u, -W + (2 * W * sample) / 12));
    ribs.push(surface.plot({ points, color: "#17203334", width: 1.25, id: "surface-rib-" + rib }));
}
const center = [];
for (let sample = 0; sample <= 128; sample++) center.push(P((tau * sample) / 128, 0));
const centerline = surface.plot({ points: center, color: p.ink, width: 3, id: "centerline" });
const u = 1.18 * Math.PI,
    v = 0.2,
    e = 0.001,
    origin = P(u, v);
const du = norm(sub(P(u + e, v), P(u - e, v))),
    dv = norm(sub(P(u, v + e), P(u, v - e))),
    normal = norm(cross(du, dv));
const frame = [
    surface.point({
        point: origin,
        fill: p.ink,
        stroke: p.panel,
        width: 2,
        radius: 7,
        layer: 8,
        id: "frame-origin",
    }),
    surface.vector({
        origin,
        value: scale(du, 1.02),
        color: p.tangent,
        width: 4,
        tip: 11,
        layer: 9,
        id: "frame-du",
    }),
    surface.vector({
        origin,
        value: scale(dv, 1.02),
        color: p.width,
        width: 4,
        tip: 11,
        layer: 9,
        id: "frame-dv",
    }),
    surface.vector({
        origin,
        value: scale(normal, 1.02),
        color: p.normal,
        width: 4,
        tip: 11,
        layer: 9,
        id: "frame-normal",
    }),
];
const tracer = surface.point({
    point: P(0, 0),
    fill: p.tracer,
    stroke: p.panel,
    width: 2,
    radius: 7,
    layer: 10,
    id: "surface-tracer",
});
view.create(bands, 0.62, "ease_out", 0.035)
    .create(ribs, 0.46, "ease_out", 0.013)
    .create(centerline, 0.72, "linear");
view.growFromCenter(tracer, 0.2, "snappy");
for (let sample = 1; sample <= 24; sample++)
    view.shift(
        tracer,
        sub(P((tau * sample) / 24, 0), P((tau * (sample - 1)) / 24, 0)),
        0.055,
        "linear",
    );
view.create(frame, 0.44, "snappy", 0.055);
view.look(
    {
        view: "3d",
        eye: [-5.8, 5.4, 6.1],
        target: [0, 0, 0],
        up: [0, 1, 0],
        projection: "perspective",
        fov: 0.62,
        near: 0.1,
        far: 100,
    },
    1.35,
    "ease_in_out",
).wait(0.45);

const domainScene = tmath.scene({
    width: 274,
    height: 373,
    fps: 30,
    background: p.panel,
    camera: { mode: "fixed", view: "2d", height: 9 },
});
const domain = domainScene.space({ x: [-3.3, 3.3, 1], y: [-4.5, 4.5, 1], opacity: 0 });
label(domain, "PARAMETER DOMAIN", [-2.72, 3.96], 11, p.violet, "domain-title", [0, 0.5]);
label(domain, "P(u, v)", [-2.72, 3.33], 22, p.ink, "domain-symbol", [0, 0.5]);
label(domain, "x = (R + v cos(u/2)) cos u", [-2.72, 2.68], 10, p.muted, "formula-x", [0, 0.5]);
label(domain, "y = v sin(u/2)", [-2.72, 2.2], 10, p.muted, "formula-y", [0, 0.5]);
label(domain, "z = (R + v cos(u/2)) sin u", [-2.72, 1.72], 10, p.muted, "formula-z", [0, 0.5]);
const box = domain.rectangle({
    center: [0, 0.25],
    size: [5.42, 2.16],
    corner: 0.08,
    fill: "#f4f6ff",
    stroke: p.rule,
    width: 1.5,
    id: "uv-domain",
});
const grid = [];
for (let column = 1; column <= 7; column++) {
    const x = -2.71 + (5.42 * column) / 8;
    grid.push(domain.line({ from: [x, -0.83], to: [x, 1.33], color: "#5b5ce220", width: 1 }));
}
for (let row = 1; row <= 3; row++) {
    const y = -0.83 + (2.16 * row) / 4;
    grid.push(domain.line({ from: [-2.71, y], to: [2.71, y], color: "#5b5ce220", width: 1 }));
}
const path = domain.line({
    from: [-2.55, 0.25],
    to: [2.55, 0.25],
    color: p.tracer,
    width: 3,
    id: "domain-centerline",
});
const dot = domain.point({
    point: [-2.55, 0.25],
    fill: p.tracer,
    stroke: p.panel,
    width: 2,
    radius: 6,
    layer: 8,
    id: "domain-tracer",
});
label(domain, "u = 0", [-2.71, -1.12], 10, p.muted, "u-zero");
label(domain, "u = 2pi", [2.71, -1.12], 10, p.muted, "u-tau");
label(domain, "v", [-2.96, 0.25], 11, p.muted, "v-axis");
label(domain, "(0, v)  ~  (2pi, -v)", [0, -1.62], 11, p.ink, "seam-rule");
label(domain, "one turn flips the width direction", [0, -2.16], 10, p.muted, "seam-note");
const specs = [
        [p.tangent, "dP/du", -2.68],
        [p.width, "dP/dv", -3.11],
        [p.normal, "N = normalize(du x dv)", -3.54],
    ],
    legend = [];
for (let i = 0; i < specs.length; i++) {
    const item = specs[i];
    legend.push(
        domain.line({
            from: [-2.68, item[2]],
            to: [-2.2, item[2]],
            color: item[0],
            width: 3,
            id: "legend-line-" + (i + 1),
        }),
    );
    legend.push(
        label(domain, item[1], [-2.02, item[2]], 10, item[0], "legend-text-" + (i + 1), [0, 0.5]),
    );
}
domainScene
    .create(box, 0.3, "ease_out")
    .create(grid, 0.38, "ease_out", 0.018)
    .create(path, 1.25, "linear");
domainScene.growFromCenter(dot, 0.18, "snappy").shift(dot, [5.1, 0], 1.32, "linear");
domainScene.create(legend, 0.32, "ease_out", 0.035).wait(0.45);
page.viewport(view, { x: 0.025, y: 0.225, width: 0.64, height: 0.69 });
page.viewport(domainScene, { x: 0.69, y: 0.225, width: 0.285, height: 0.69 });
return page;
`,
    },
];
