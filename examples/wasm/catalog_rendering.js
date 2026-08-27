const PRETENDARD = [{ name: "Pretendard", url: "./Pretendard.ttf", mime: "ttf" }];

export const RENDERING_EXAMPLES = [
    {
        id: "ray-tracing-pixels",
        title: "Primary-ray pixel tracing",
        description:
            "Trace one primary ray through every tilted image-plane pixel, mark 3D intersections, and accumulate the nearest object's color into a tiny RGB hit buffer.",
        category: "Rendering",
        dimension: "3D",
        fonts: PRETENDARD,
        lua: `local p = {
    bg = "#080d14",
    grid = "#52657a",
    dark = "#111d2a",
    text = "#f4f7fb",
    muted = "#8fa1b7",
    ray = "#7890aa",
    cyan = "#4cc9f0",
    gold = "#ffd166",
    magenta = "#f72585",
}
local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 60,
    background = p.bg,
    loop = false,
    camera = {
        mode = "fixed",
        view = "3d",
        eye = { 9, 6, 11 },
        target = { -0.6, 0, 0 },
        up = { 0, 1, 0 },
        projection = "perspective",
        fov = 0.66,
        near = 0.1,
        far = 100,
    },
}
local function translate(x, y, z)
    return { 1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, z, 0, 0, 0, 1 }
end
scene:text {
    text = "PRIMARY RAYS  >  INTERSECTION  >  PIXEL SHADE",
    point = { -6, 3.15, 0 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 18,
    fill = p.text,
    id = "ray-tracing-title",
}
scene:text {
    text = "one sample per pixel · nearest visible object wins",
    point = { -6, 2.72, 0 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 12,
    fill = p.muted,
    id = "ray-tracing-subtitle",
}

local screen = scene:group {
    matrix = { 0, 0, 1, -3, 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 0, 1 },
    id = "image-plane",
}
local pixels = {}
for row = 1, 3 do
    pixels[row] = {}
    for column = 1, 5 do
        local u = (column - 3) * 0.48
        local v = (2 - row) * 0.48
        pixels[row][column] = screen:rectangle {
            center = { u, v },
            size = { 0.42, 0.42 },
            corner = 0.035,
            fill = p.dark,
            stroke = p.grid,
            width = 1.6,
            id = "screen-pixel-" .. row .. "-" .. column,
        }
    end
end
screen:line { from = { -1.29, -0.8 }, to = { 1.29, -0.8 }, stroke = p.cyan, width = 2.5 }
screen:line { from = { 1.29, -0.8 }, to = { 1.29, 0.8 }, stroke = p.cyan, width = 2.5 }
screen:line { from = { 1.29, 0.8 }, to = { -1.29, 0.8 }, stroke = p.cyan, width = 2.5 }
screen:line { from = { -1.29, 0.8 }, to = { -1.29, -0.8 }, stroke = p.cyan, width = 2.5 }
local screenLabel = scene:text {
    text = "IMAGE PLANE  5 × 3",
    point = { -3.35, 1.2, 0 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 15,
    fill = p.cyan,
    id = "image-plane-label",
}
local origin = { -6, 0, 0 }
local pinhole = scene:point { point = origin, fill = p.text, radius = 7, layer = 9, id = "pinhole" }
local pinholeLabel = scene:text {
    text = "PINHOLE",
    point = { -6.2, 0.62, 0 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = p.text,
    id = "pinhole-label",
}

local sphere = scene:group { matrix = translate(2.2, 0.656, 1.968), id = "sphere" }
for latitude = -2, 2 do
    local phi = latitude * math.pi / 7
    local points = {}
    for i = 0, 40 do
        local a = i * 2 * math.pi / 40
        points[#points + 1] = {
            0.98 * math.cos(phi) * math.cos(a),
            0.98 * math.sin(phi),
            0.98 * math.cos(phi) * math.sin(a),
        }
    end
    sphere:plot { points = points, stroke = p.cyan, width = 2.2 }
end
for longitude = 0, 5 do
    local theta = longitude * math.pi / 6
    local points = {}
    for i = 0, 48 do
        local phi = -math.pi / 2 + i * 2 * math.pi / 48
        points[#points + 1] = {
            0.98 * math.cos(phi) * math.cos(theta),
            0.98 * math.sin(phi),
            0.98 * math.cos(phi) * math.sin(theta),
        }
    end
    sphere:plot { points = points, stroke = p.cyan .. "aa", width = 1.8 }
end
local cube = scene:group { matrix = translate(2.2, -0.656, -1.968), id = "cube" }
local cp = {
    { -0.82, -0.82, -0.82 },
    { 0.82, -0.82, -0.82 },
    { 0.82, 0.82, -0.82 },
    { -0.82, 0.82, -0.82 },
    { -0.82, -0.82, 0.82 },
    { 0.82, -0.82, 0.82 },
    { 0.82, 0.82, 0.82 },
    { -0.82, 0.82, 0.82 },
}
local ce = {
    { 1, 2 },
    { 2, 3 },
    { 3, 4 },
    { 4, 1 },
    { 5, 6 },
    { 6, 7 },
    { 7, 8 },
    { 8, 5 },
    { 1, 5 },
    {
        2,
        6,
    },
    {
        3,
        7,
    },
    {
        4,
        8,
    },
}
for _, edge in ipairs(ce) do
    cube:line { from = cp[edge[1]], to = cp[edge[2]], stroke = p.gold, width = 2.5 }
end
local pyramid = scene:group { matrix = translate(2.2, -1.312, 0), id = "pyramid" }
local base = {
    { -0.72, -0.55, -0.72 },
    { 0.72, -0.55, -0.72 },
    { 0.72, -0.55, 0.72 },
    {
        -0.72,
        -0.55,
        0.72,
    },
}
for i = 1, 4 do
    pyramid:line { from = base[i], to = base[i % 4 + 1], stroke = p.magenta, width = 2.5 }
    pyramid:line { from = base[i], to = { 0, 0.82, 0 }, stroke = p.magenta, width = 2.5 }
end
local labels = {
    scene:text {
        text = "SPHERE",
        point = { 2.2, 1.95, 1.968 },
        font = "Pretendard",
        size = 14,
        fill = p.cyan,
    },
    scene:text {
        text = "CUBE",
        point = { 2.2, 0.62, -1.968 },
        font = "Pretendard",
        size = 14,
        fill = p.gold,
    },
    scene:text {
        text = "PYRAMID",
        point = { 2.2, -2.72, 0 },
        font = "Pretendard",
        size = 14,
        fill = p.magenta,
    },
}
local hits = {
    { p.cyan, p.cyan, false, false, false },
    { p.cyan, p.cyan, false, p.gold, p.gold },
    { false, false, p.magenta, p.gold, p.gold },
}
local function sample(column, row, x)
    local u = (column - 3) * 0.48
    local v = (2 - row) * 0.48
    local scale = (x - origin[1]) / 3
    return { x, v * scale, -u * scale }
end

scene:create({ screen, pinhole, sphere, cube, pyramid }, 0.9, "ease_out", 0.08)
scene:create({ screenLabel, pinholeLabel, labels[1], labels[2], labels[3] }, 0.4, "ease_out", 0.06)
scene:wait(0.3)
for row = 1, 3 do
    local rays = {}
    local fades = {}
    local points = {}
    local shades = {}
    for column = 1, 5 do
        local color = hits[row][column]
        local endpoint = sample(column, row, color and 2.2 or 3.8)
        local ray = scene:arrow {
            from = origin,
            to = endpoint,
            stroke = color or p.ray,
            width = color and 2.8 or 1.7,
            tip = 8,
            id = "primary-ray-" .. row .. "-" .. column,
        }
        rays[#rays + 1] = ray
        fades[#fades + 1] = { target = ray, opacity = color and 0.28 or 0.1 }
        if color then
            points[#points + 1] = scene:point {
                point = endpoint,
                fill = color,
                radius = 4.5,
                layer = 10,
                id = "hit-" .. row .. "-" .. column,
            }
            shades[#shades + 1] = { target = pixels[row][column], fill = color }
        end
    end
    scene:create(rays, 0.52, "linear", 0.08)
    for _, point in ipairs(points) do
        scene:grow_from_center(point, 0.1, "snappy")
    end
    scene:play(shades, 0.3, { preset = "snappy", strength = 0.85 }, 0.05)
    scene:play(fades, 0.22, "ease_out", 0)
    scene:wait(0.16)
end
local result = scene:text {
    text = "RGB HIT BUFFER",
    point = { -6, -2.2, 0 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 14,
    fill = p.text,
    id = "result-label",
}
scene:fade_in(result, { shift = { 0, -0.18 }, duration = 0.38, curve = "snappy" })
scene:wait(0.65)
return scene
`,
        js: `const p = {
    bg: "#080d14",
    grid: "#52657a",
    dark: "#111d2a",
    text: "#f4f7fb",
    muted: "#8fa1b7",
    ray: "#7890aa",
    cyan: "#4cc9f0",
    gold: "#ffd166",
    magenta: "#f72585",
};
const scene = tmath.scene({
    width: 960,
    height: 540,
    fps: 60,
    background: p.bg,
    loop: false,
    camera: {
        mode: "fixed",
        view: "3d",
        eye: [9, 6, 11],
        target: [-0.6, 0, 0],
        up: [0, 1, 0],
        projection: "perspective",
        fov: 0.66,
        near: 0.1,
        far: 100,
    },
});
const translate = (x, y, z) => [1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, z, 0, 0, 0, 1];
scene.text({
    text: "PRIMARY RAYS  >  INTERSECTION  >  PIXEL SHADE",
    point: [-6, 3.15, 0],
    align: [0, 0.5],
    font: "Pretendard",
    size: 18,
    fill: p.text,
    id: "ray-tracing-title",
});
scene.text({
    text: "one sample per pixel · nearest visible object wins",
    point: [-6, 2.72, 0],
    align: [0, 0.5],
    font: "Pretendard",
    size: 12,
    fill: p.muted,
    id: "ray-tracing-subtitle",
});

const screen = scene.group({
    matrix: [0, 0, 1, -3, 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 0, 1],
    id: "image-plane",
});
const pixels = [];
for (let row = 0; row < 3; row++) {
    pixels[row] = [];
    for (let column = 0; column < 5; column++) {
        const u = (column - 2) * 0.48,
            v = (1 - row) * 0.48;
        pixels[row][column] = screen.rectangle({
            center: [u, v],
            size: [0.42, 0.42],
            corner: 0.035,
            fill: p.dark,
            stroke: p.grid,
            width: 1.6,
            id: "screen-pixel-" + (row + 1) + "-" + (column + 1),
        });
    }
}
screen.line({ from: [-1.29, -0.8], to: [1.29, -0.8], stroke: p.cyan, width: 2.5 });
screen.line({ from: [1.29, -0.8], to: [1.29, 0.8], stroke: p.cyan, width: 2.5 });
screen.line({ from: [1.29, 0.8], to: [-1.29, 0.8], stroke: p.cyan, width: 2.5 });
screen.line({ from: [-1.29, 0.8], to: [-1.29, -0.8], stroke: p.cyan, width: 2.5 });
const screenLabel = scene.text({
    text: "IMAGE PLANE  5 × 3",
    point: [-3.35, 1.2, 0],
    align: [0, 0.5],
    font: "Pretendard",
    size: 15,
    fill: p.cyan,
    id: "image-plane-label",
});
const origin = [-6, 0, 0];
const pinhole = scene.point({ point: origin, fill: p.text, radius: 7, layer: 9, id: "pinhole" });
const pinholeLabel = scene.text({
    text: "PINHOLE",
    point: [-6.2, 0.62, 0],
    align: [0, 0.5],
    font: "Pretendard",
    size: 13,
    fill: p.text,
    id: "pinhole-label",
});

const sphere = scene.group({ matrix: translate(2.2, 0.656, 1.968), id: "sphere" });
for (let latitude = -2; latitude <= 2; latitude++) {
    const phi = (latitude * Math.PI) / 7,
        points = [];
    for (let i = 0; i <= 40; i++) {
        const a = (i * 2 * Math.PI) / 40;
        points.push([
            0.98 * Math.cos(phi) * Math.cos(a),
            0.98 * Math.sin(phi),
            0.98 * Math.cos(phi) * Math.sin(a),
        ]);
    }
    sphere.plot({ points, stroke: p.cyan, width: 2.2 });
}
for (let longitude = 0; longitude <= 5; longitude++) {
    const theta = (longitude * Math.PI) / 6,
        points = [];
    for (let i = 0; i <= 48; i++) {
        const phi = -Math.PI / 2 + (i * 2 * Math.PI) / 48;
        points.push([
            0.98 * Math.cos(phi) * Math.cos(theta),
            0.98 * Math.sin(phi),
            0.98 * Math.cos(phi) * Math.sin(theta),
        ]);
    }
    sphere.plot({ points, stroke: p.cyan + "aa", width: 1.8 });
}
const cube = scene.group({ matrix: translate(2.2, -0.656, -1.968), id: "cube" });
const cp = [
    [-0.82, -0.82, -0.82],
    [0.82, -0.82, -0.82],
    [0.82, 0.82, -0.82],
    [-0.82, 0.82, -0.82],
    [-0.82, -0.82, 0.82],
    [0.82, -0.82, 0.82],
    [0.82, 0.82, 0.82],
    [-0.82, 0.82, 0.82],
];
const ce = [
    [0, 1],
    [1, 2],
    [2, 3],
    [3, 0],
    [4, 5],
    [5, 6],
    [6, 7],
    [7, 4],
    [0, 4],
    [1, 5],
    [2, 6],
    [3, 7],
];
for (const edge of ce)
    cube.line({ from: cp[edge[0]], to: cp[edge[1]], stroke: p.gold, width: 2.5 });
const pyramid = scene.group({ matrix: translate(2.2, -1.312, 0), id: "pyramid" });
const base = [
    [-0.72, -0.55, -0.72],
    [0.72, -0.55, -0.72],
    [0.72, -0.55, 0.72],
    [-0.72, -0.55, 0.72],
];
for (let i = 0; i < 4; i++) {
    pyramid.line({ from: base[i], to: base[(i + 1) % 4], stroke: p.magenta, width: 2.5 });
    pyramid.line({ from: base[i], to: [0, 0.82, 0], stroke: p.magenta, width: 2.5 });
}
const labels = [
    scene.text({
        text: "SPHERE",
        point: [2.2, 1.95, 1.968],
        font: "Pretendard",
        size: 14,
        fill: p.cyan,
    }),
    scene.text({
        text: "CUBE",
        point: [2.2, 0.62, -1.968],
        font: "Pretendard",
        size: 14,
        fill: p.gold,
    }),
    scene.text({
        text: "PYRAMID",
        point: [2.2, -2.72, 0],
        font: "Pretendard",
        size: 14,
        fill: p.magenta,
    }),
];
const hits = [
    [p.cyan, p.cyan, false, false, false],
    [p.cyan, p.cyan, false, p.gold, p.gold],
    [false, false, p.magenta, p.gold, p.gold],
];
const sample = (column, row, x) => {
    const u = (column - 2) * 0.48,
        v = (1 - row) * 0.48,
        scale = (x - origin[0]) / 3;
    return [x, v * scale, -u * scale];
};

scene.create([screen, pinhole, sphere, cube, pyramid], 0.9, "ease_out", 0.08);
scene.create([screenLabel, pinholeLabel, ...labels], 0.4, "ease_out", 0.06);
scene.wait(0.3);
for (let row = 0; row < 3; row++) {
    const rays = [],
        fades = [],
        points = [],
        shades = [];
    for (let column = 0; column < 5; column++) {
        const color = hits[row][column],
            endpoint = sample(column, row, color ? 2.2 : 3.8);
        const ray = scene.arrow({
            from: origin,
            to: endpoint,
            stroke: color || p.ray,
            width: color ? 2.8 : 1.7,
            tip: 8,
            id: "primary-ray-" + (row + 1) + "-" + (column + 1),
        });
        rays.push(ray);
        fades.push({ target: ray, opacity: color ? 0.28 : 0.1 });
        if (color) {
            points.push(
                scene.point({
                    point: endpoint,
                    fill: color,
                    radius: 4.5,
                    layer: 10,
                    id: "hit-" + (row + 1) + "-" + (column + 1),
                }),
            );
            shades.push({ target: pixels[row][column], fill: color });
        }
    }
    scene.create(rays, 0.52, "linear", 0.08);
    for (const point of points) scene.growFromCenter(point, 0.1, "snappy");
    scene.play(shades, 0.3, tmath.animCurve.preset("snappy", 0.85), 0.05);
    scene.play(fades, 0.22, "ease_out", 0).wait(0.16);
}
const result = scene.text({
    text: "RGB HIT BUFFER",
    point: [-6, -2.2, 0],
    align: [0, 0.5],
    font: "Pretendard",
    size: 14,
    fill: p.text,
    id: "result-label",
});
scene.fadeIn(result, { shift: [0, -0.18], duration: 0.38, curve: "snappy" }).wait(0.65);
return scene;
`,
    },
];
