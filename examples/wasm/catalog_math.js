const PRETENDARD = [{ name: "Pretendard", url: "./Pretendard.ttf", mime: "ttf" }];

export const MATH_EXAMPLES = [
    {
        id: "calculus-2d",
        title: "Derivative and integral in 2D",
        description:
            "Follow one curve from a sampled tangent and slope to Δx strips and their accumulated signed area.",
        category: "Calculus",
        dimension: "2D",
        fonts: PRETENDARD,
        lua: `local p = {
    bg = "#0b111a",
    grid = "#263447",
    axis = "#66758a",
    muted = "#94a3b8",
    curve = "#4cc9f0",
    tangent = "#ffd166",
    area = "#7bd88f",
    point = "#ff6b6b",
}
local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    background = p.bg,
    camera = { mode = "interactive", view = "2d", target = { 0, 0.2 }, height = 7.6 },
}
local space = scene:space {
    x = { -5, 5, 1 },
    y = { -3, 4, 1 },
    numbers = true,
    color = p.grid,
    axis_x = p.axis,
    axis_y = p.axis,
    number_color = p.muted,
    number_size = 13,
}
local curve = space:plot {
    fn = function(x)
        return 0.25 * x * x - 0.5
    end,
    x_range = { -4, 4, 0.06 },
    color = p.curve,
    width = 4,
}
local curveLabel = space:text {
    text = "f(x) = x²/4 − 1/2",
    point = { -5.65, 3.45 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 21,
    fill = p.curve,
}
local sample = space:point { point = { 1, -0.25 }, fill = p.point, radius = 7, layer = 5 }
local tangent =
    space:line { from = { -2.6, -2.05 }, to = { 4.2, 1.35 }, color = p.tangent, width = 4 }
local pointLabel = space:text {
    text = "P = (1, −0.25)",
    point = { 1.22, -0.72 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 16,
    fill = p.point,
}
local tangentLabel = space:text {
    text = "f′(1) = slope = 1/2",
    point = { 1.45, 3.45 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 20,
    fill = p.tangent,
}
local dx = 0.375
local dxMarker = {
    space:line { from = { 0, 0.08 }, to = { dx, 0.08 }, color = p.area, width = 5 },
    space:line { from = { 0, -0.08 }, to = { 0, 0.24 }, color = p.area, width = 2 },
    space:line { from = { dx, -0.08 }, to = { dx, 0.24 }, color = p.area, width = 2 },
}
local dxLabel = space:text {
    text = "Δx = 0.375",
    point = { 0.02, 0.42 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 15,
    fill = p.area,
}
local rectangles = {}
for i = 0, 7 do
    local left = i * dx
    local right = left + dx
    local h = 0.25 * right * right - 0.5
    rectangles[#rectangles + 1] = space:polygon {
        points = { { left, 0 }, { right, 0 }, { right, h }, { left, h } },
        fill = "#7bd88f55",
        stroke = p.area,
        width = 1.5,
    }
end
local integral = space:text {
    text = "Σ f(x_i) Δx  ->  ∫₀³ f(x) dx",
    point = { 1.45, 2.88 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 19,
    fill = p.area,
}
local note = space:text {
    text = "accumulated signed area",
    point = { 1.48, 2.52 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 14,
    fill = p.muted,
}
scene:create(space, 0.42, "ease_out")
scene:create(curve, 1.05, "ease_in_out")
scene:create(curveLabel, 0.32, "ease_out")
scene:create(sample, 0.28, "ease_out")
scene:create(tangent, 0.62, "ease_out")
scene:create({ pointLabel, tangentLabel }, 0.34, "ease_out", 0.08)
scene:create(dxMarker, 0.34, "ease_out", 0.04)
scene:create(dxLabel, 0.24, "ease_out")
scene:create(rectangles, 0.78, "ease_out", 0.055)
scene:create({ integral, note }, 0.38, "ease_out", 0.06)
scene:wait(0.65)
return scene
`,
        js: `const p = {
    bg: "#0b111a",
    grid: "#263447",
    axis: "#66758a",
    muted: "#94a3b8",
    curve: "#4cc9f0",
    tangent: "#ffd166",
    area: "#7bd88f",
    point: "#ff6b6b",
};
const scene = tmath.scene({
    width: 960,
    height: 540,
    fps: 30,
    background: p.bg,
    camera: { mode: "interactive", view: "2d", target: [0, 0.2], height: 7.6 },
});
const space = scene.space({
    x: [-5, 5, 1],
    y: [-3, 4, 1],
    numbers: true,
    color: p.grid,
    axis_x: p.axis,
    axis_y: p.axis,
    number_color: p.muted,
    number_size: 13,
});
const points = Array.from({ length: 135 }, (_, i) => {
    const x = -4 + (i * 8) / 134;
    return [x, 0.25 * x * x - 0.5];
});
const curve = space.plot({ points, color: p.curve, width: 4 });
const curveLabel = space.text({
    text: "f(x) = x²/4 − 1/2",
    point: [-5.65, 3.45],
    align: [0, 0.5],
    font: "Pretendard",
    size: 21,
    fill: p.curve,
});
const sample = space.point({ point: [1, -0.25], fill: p.point, radius: 7, layer: 5 });
const tangent = space.line({ from: [-2.6, -2.05], to: [4.2, 1.35], color: p.tangent, width: 4 });
const pointLabel = space.text({
    text: "P = (1, −0.25)",
    point: [1.22, -0.72],
    align: [0, 0.5],
    font: "Pretendard",
    size: 16,
    fill: p.point,
});
const tangentLabel = space.text({
    text: "f′(1) = slope = 1/2",
    point: [1.45, 3.45],
    align: [0, 0.5],
    font: "Pretendard",
    size: 20,
    fill: p.tangent,
});
const dx = 0.375;
const dxMarker = [
    space.line({ from: [0, 0.08], to: [dx, 0.08], color: p.area, width: 5 }),
    space.line({ from: [0, -0.08], to: [0, 0.24], color: p.area, width: 2 }),
    space.line({ from: [dx, -0.08], to: [dx, 0.24], color: p.area, width: 2 }),
];
const dxLabel = space.text({
    text: "Δx = 0.375",
    point: [0.02, 0.42],
    align: [0, 0.5],
    font: "Pretendard",
    size: 15,
    fill: p.area,
});
const rectangles = Array.from({ length: 8 }, (_, i) => {
    const left = i * dx,
        right = left + dx,
        h = 0.25 * right * right - 0.5;
    return space.polygon({
        points: [
            [left, 0],
            [right, 0],
            [right, h],
            [left, h],
        ],
        fill: "#7bd88f55",
        stroke: p.area,
        width: 1.5,
    });
});
const integral = space.text({
    text: "Σ f(x_i) Δx  ->  ∫₀³ f(x) dx",
    point: [1.45, 2.88],
    align: [0, 0.5],
    font: "Pretendard",
    size: 19,
    fill: p.area,
});
const note = space.text({
    text: "accumulated signed area",
    point: [1.48, 2.52],
    align: [0, 0.5],
    font: "Pretendard",
    size: 14,
    fill: p.muted,
});
scene.create(space, 0.42, "ease_out");
scene.create(curve, 1.05, "ease_in_out");
scene.create(curveLabel, 0.32, "ease_out");
scene.create(sample, 0.28, "ease_out");
scene.create(tangent, 0.62, "ease_out");
scene.create([pointLabel, tangentLabel], 0.34, "ease_out", 0.08);
scene.create(dxMarker, 0.34, "ease_out", 0.04);
scene.create(dxLabel, 0.24, "ease_out");
scene.create(rectangles, 0.78, "ease_out", 0.055);
scene.create([integral, note], 0.38, "ease_out", 0.06);
scene.wait(0.65);
return scene;
`,
    },
    {
        id: "calculus-3d",
        title: "Derivative and integral on a 3D curve",
        description:
            "Reveal a helix tangent at t₀, then highlight the exact arc accumulated by its length integral.",
        category: "Calculus",
        dimension: "3D",
        fonts: PRETENDARD,
        lua: `local p = {
    bg = "#0b111a",
    grid = "#263447",
    axis = "#66758a",
    muted = "#94a3b8",
    curve = "#4cc9f0",
    tangent = "#ffd166",
    arc = "#7bd88f",
    point = "#ff6b6b",
}
local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    background = p.bg,
    camera = {
        mode = "interactive",
        view = "3d",
        eye = { 6, 4.8, 7 },
        target = { 0, 1.25, 0 },
        up = { 0, 1, 0 },
        projection = "perspective",
        fov = 0.72,
        near = 0.1,
        far = 100,
    },
}
local space = scene:space {
    x = { -3, 3, 1 },
    y = { -1, 4, 1 },
    z = { -3, 3, 1 },
    numbers = false,
    color = p.grid,
    axis_x = p.axis,
    axis_y = p.axis,
    axis_z = p.axis,
}
local points = {}
for i = 0, 120 do
    local t = i * 6.28318530718 / 120
    points[#points + 1] = { 2 * math.cos(t), 0.45 * t, 2 * math.sin(t) }
end
local curve = space:plot { points = points, color = p.curve, width = 4 }
local curveLabel = space:text {
    text = "r(t) = (2 cos t, 0.45t, 2 sin t)",
    point = { -2.85, 3.65, 0.15 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 20,
    fill = p.curve,
}
local t0 = 2.2
local samplePosition = { 2 * math.cos(t0), 0.45 * t0, 2 * math.sin(t0) }
local sample = space:point { point = samplePosition, fill = p.point, radius = 8, layer = 5 }
local tangent = space:vector {
    origin = samplePosition,
    value = { -1.2 * math.sin(t0), 0.27, 1.2 * math.cos(t0) },
    color = p.tangent,
    width = 5,
    tip = 14,
}
local pointLabel = space:text {
    text = "P = r(t₀)",
    point = { samplePosition[1] + 0.18, samplePosition[2] + 0.42, samplePosition[3] + 0.06 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 17,
    fill = p.point,
}
local tangentLabel = space:text {
    text = "r′(t₀)  ->  tangent direction",
    point = { -2.85, 3.18, 0.15 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 19,
    fill = p.tangent,
}
local accumulated = {}
for i = 0, 44 do
    local t = t0 * i / 44
    accumulated[#accumulated + 1] = { 2 * math.cos(t), 0.45 * t, 2 * math.sin(t) }
end
local arc = space:plot { points = accumulated, color = p.arc, width = 7 }
local start = space:point { point = { 2, 0, 0 }, fill = p.arc, radius = 5, layer = 5 }
local arcLabel = space:text {
    text = "s(t₀) = integral[0, t₀] |r′(u)| du",
    point = { -2.85, 2.72, 0.15 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 20,
    fill = p.arc,
}
local arcNote = space:text {
    text = "accumulated length along the curve",
    point = { -2.82, 2.30, 0.15 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 14,
    fill = p.muted,
}
scene:create(space, 0.42, "ease_out")
scene:create(curve, 1.35, "linear")
scene:create(curveLabel, 0.34, "ease_out")
scene:create(sample, 0.28, "ease_out")
scene:create(tangent, 0.68, "ease_out")
scene:create({ pointLabel, tangentLabel }, 0.36, "ease_out", 0.08)
scene:create({ arc, start }, 0.92, "ease_in_out", 0.08)
scene:create({ arcLabel, arcNote }, 0.40, "ease_out", 0.07)
scene:wait(0.72)
return scene
`,
        js: `const p = {
    bg: "#0b111a",
    grid: "#263447",
    axis: "#66758a",
    muted: "#94a3b8",
    curve: "#4cc9f0",
    tangent: "#ffd166",
    arc: "#7bd88f",
    point: "#ff6b6b",
};
const scene = tmath.scene({
    width: 960,
    height: 540,
    fps: 30,
    background: p.bg,
    camera: {
        mode: "interactive",
        view: "3d",
        eye: [6, 4.8, 7],
        target: [0, 1.25, 0],
        up: [0, 1, 0],
        projection: "perspective",
        fov: 0.72,
        near: 0.1,
        far: 100,
    },
});
const space = scene.space({
    x: [-3, 3, 1],
    y: [-1, 4, 1],
    z: [-3, 3, 1],
    numbers: false,
    color: p.grid,
    axis_x: p.axis,
    axis_y: p.axis,
    axis_z: p.axis,
});
const points = Array.from({ length: 121 }, (_, i) => {
    const t = (i * Math.PI * 2) / 120;
    return [2 * Math.cos(t), 0.45 * t, 2 * Math.sin(t)];
});
const curve = space.plot({ points, color: p.curve, width: 4 });
const curveLabel = space.text({
    text: "r(t) = (2 cos t, 0.45t, 2 sin t)",
    point: [-2.85, 3.65, 0.15],
    align: [0, 0.5],
    font: "Pretendard",
    size: 20,
    fill: p.curve,
});
const t0 = 2.2,
    samplePosition = [2 * Math.cos(t0), 0.45 * t0, 2 * Math.sin(t0)];
const sample = space.point({ point: samplePosition, fill: p.point, radius: 8, layer: 5 });
const tangent = space.vector({
    origin: samplePosition,
    value: [-1.2 * Math.sin(t0), 0.27, 1.2 * Math.cos(t0)],
    color: p.tangent,
    width: 5,
    tip: 14,
});
const pointLabel = space.text({
    text: "P = r(t₀)",
    point: [samplePosition[0] + 0.18, samplePosition[1] + 0.42, samplePosition[2] + 0.06],
    align: [0, 0.5],
    font: "Pretendard",
    size: 17,
    fill: p.point,
});
const tangentLabel = space.text({
    text: "r′(t₀)  ->  tangent direction",
    point: [-2.85, 3.18, 0.15],
    align: [0, 0.5],
    font: "Pretendard",
    size: 19,
    fill: p.tangent,
});
const accumulated = Array.from({ length: 45 }, (_, i) => {
    const t = (t0 * i) / 44;
    return [2 * Math.cos(t), 0.45 * t, 2 * Math.sin(t)];
});
const arc = space.plot({ points: accumulated, color: p.arc, width: 7 });
const start = space.point({ point: [2, 0, 0], fill: p.arc, radius: 5, layer: 5 });
const arcLabel = space.text({
    text: "s(t₀) = integral[0, t₀] |r′(u)| du",
    point: [-2.85, 2.72, 0.15],
    align: [0, 0.5],
    font: "Pretendard",
    size: 20,
    fill: p.arc,
});
const arcNote = space.text({
    text: "accumulated length along the curve",
    point: [-2.82, 2.3, 0.15],
    align: [0, 0.5],
    font: "Pretendard",
    size: 14,
    fill: p.muted,
});
scene.create(space, 0.42, "ease_out");
scene.create(curve, 1.35, "linear");
scene.create(curveLabel, 0.34, "ease_out");
scene.create(sample, 0.28, "ease_out");
scene.create(tangent, 0.68, "ease_out");
scene.create([pointLabel, tangentLabel], 0.36, "ease_out", 0.08);
scene.create([arc, start], 0.92, "ease_in_out", 0.08);
scene.create([arcLabel, arcNote], 0.4, "ease_out", 0.07);
scene.wait(0.72);
return scene;
`,
    },
    {
        id: "circle-equation",
        title: "Circle equation",
        description: "Relate one radius vector and sampled point to x² + y² = r².",
        category: "Geometry",
        dimension: "2D",
        fonts: PRETENDARD,
        lua: `local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    camera = { mode = "interactive", view = "2d", height = 7 },
}
local space = scene:space { x = { -5, 5, 1 }, y = { -3, 3, 1 }, numbers = true, number_size = 14 }
local circle = space:circle {
    center = { 0, 0 },
    radius = 2.25,
    fill = "#4cc9f022",
    stroke = "#4cc9f0",
    width = 4,
}
local a = 0.68
local p = { 2.25 * math.cos(a), 2.25 * math.sin(a) }
local radius = space:vector { value = p, color = "#ffd166", width = 4, tip = 13 }
local sample = space:point { point = p, fill = "#ef5350", radius = 7 }
local circleLabel = space:text {
    text = "x² + y² = r²",
    point = { -4.2, 2.7 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 24,
    fill = "#4cc9f0",
}
local radiusLabel = space:text {
    text = "r = 2.25",
    point = { 0.1, 2.7 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 22,
    fill = "#ffd166",
}
local pointLabel = space:text {
    text = "P = (x, y)",
    point = { 2.25, 2.7 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 21,
    fill = "#ef5350",
}
scene:create(circle, 1.1, "ease_in_out")
scene:create({ radius, sample }, 0.75, "ease_out", 0.12)
scene:create({ circleLabel, radiusLabel, pointLabel }, 0.45, "ease_out", 0.08)
scene:wait(0.6)
return scene
`,
        js: `const scene = tmath.scene({
    width: 960,
    height: 540,
    fps: 30,
    camera: { mode: "interactive", view: "2d", height: 7 },
});
const space = scene.space({ x: [-5, 5, 1], y: [-3, 3, 1], numbers: true, number_size: 14 });
const circle = space.circle({
    center: [0, 0],
    radius: 2.25,
    fill: "#4cc9f022",
    stroke: "#4cc9f0",
    width: 4,
});
const a = 0.68,
    p = [2.25 * Math.cos(a), 2.25 * Math.sin(a)];
const radius = space.vector({ value: p, color: "#ffd166", width: 4, tip: 13 });
const sample = space.point({ point: p, fill: "#ef5350", radius: 7 });
const circleLabel = space.text({
    text: "x² + y² = r²",
    point: [-4.2, 2.7],
    align: [0, 0.5],
    font: "Pretendard",
    size: 24,
    fill: "#4cc9f0",
});
const radiusLabel = space.text({
    text: "r = 2.25",
    point: [0.1, 2.7],
    align: [0, 0.5],
    font: "Pretendard",
    size: 22,
    fill: "#ffd166",
});
const pointLabel = space.text({
    text: "P = (x, y)",
    point: [2.25, 2.7],
    align: [0, 0.5],
    font: "Pretendard",
    size: 21,
    fill: "#ef5350",
});
scene.create(circle, 1.1, "ease_in_out");
scene.create([radius, sample], 0.75, "ease_out", 0.12);
scene.create([circleLabel, radiusLabel, pointLabel], 0.45, "ease_out", 0.08);
scene.wait(0.6);
return scene;
`,
    },
    {
        id: "sphere-equation",
        title: "Sphere equation",
        description:
            "Construct a wire sphere from latitude and longitude curves, then mark one radial vector.",
        category: "Geometry",
        dimension: "3D",
        fonts: PRETENDARD,
        lua: `local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    camera = {
        mode = "interactive",
        view = "3d",
        eye = { 6.5, 4.9, 7.6 },
        target = { 0, -0.1, 0 },
        up = { 0, 1, 0 },
        projection = "perspective",
        fov = 0.7,
        near = 0.1,
        far = 100,
    },
}
local space = scene:space {
    x = { -2.6, 2.6, 1 },
    y = { -2.6, 2.6, 1 },
    z = { -2.6, 2.6, 1 },
    color = "#28333d",
}
local curves = {}
local r = 2.2
for lat = -3, 3 do
    local phi = lat * 3.14159265359 / 8
    local points = {}
    for i = 0, 64 do
        local theta = i * 6.28318530718 / 64
        points[#points + 1] = {
            r * math.cos(phi) * math.cos(theta),
            r * math.sin(phi),
            r * math.cos(phi) * math.sin(theta),
        }
    end
    curves[#curves + 1] = space:plot { points = points, color = "#4cc9f0aa", width = 2 }
end
for lon = 0, 7 do
    local theta = lon * 3.14159265359 / 8
    local points = {}
    for i = 0, 128 do
        local phi = -3.14159265359 / 2 + i * 6.28318530718 / 128
        points[#points + 1] = {
            r * math.cos(phi) * math.cos(theta),
            r * math.sin(phi),
            r * math.cos(phi) * math.sin(theta),
        }
    end
    curves[#curves + 1] = space:plot { points = points, color = "#4cc9f088", width = 2 }
end
local p = { 1.27017, 1.27017, 1.27017 }
local radial = space:vector { value = p, color = "#ffd166", width = 4, tip = 13 }
local point = space:point { point = p, fill = "#ef5350", radius = 7 }
local sphereLabel = space:text {
    text = "x² + y² + z² = r²",
    point = { -2.7, 2.45, 0 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 24,
    fill = "#4cc9f0",
}
local radiusLabel = space:text {
    text = "r = 2.2",
    point = { 0.9, 2.45, 0 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 24,
    fill = "#ffd166",
}
local pointLabel = space:text {
    text = "P(x, y, z)",
    point = { p[1] + 0.2, p[2] + 0.3, p[3] },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 17,
    fill = "#ef5350",
}
scene:create(curves, 1.2, "ease_out", 0.025)
scene:create({ radial, point }, 0.7, "ease_out", 0.12)
scene:create({ sphereLabel, radiusLabel, pointLabel }, 0.45, "ease_out", 0.08)
scene:wait(0.7)
return scene
`,
        js: `const scene = tmath.scene({
    width: 960,
    height: 540,
    fps: 30,
    camera: {
        mode: "interactive",
        view: "3d",
        eye: [6.5, 4.9, 7.6],
        target: [0, -0.1, 0],
        up: [0, 1, 0],
        projection: "perspective",
        fov: 0.7,
        near: 0.1,
        far: 100,
    },
});
const space = scene.space({
    x: [-2.6, 2.6, 1],
    y: [-2.6, 2.6, 1],
    z: [-2.6, 2.6, 1],
    color: "#28333d",
});
const curves = [],
    r = 2.2;
for (let lat = -3; lat <= 3; lat++) {
    const phi = (lat * Math.PI) / 8,
        points = [];
    for (let i = 0; i <= 64; i++) {
        const theta = (i * Math.PI * 2) / 64;
        points.push([
            r * Math.cos(phi) * Math.cos(theta),
            r * Math.sin(phi),
            r * Math.cos(phi) * Math.sin(theta),
        ]);
    }
    curves.push(space.plot({ points, color: "#4cc9f0aa", width: 2 }));
}
for (let lon = 0; lon < 8; lon++) {
    const theta = (lon * Math.PI) / 8,
        points = [];
    for (let i = 0; i <= 128; i++) {
        const phi = -Math.PI / 2 + (i * Math.PI * 2) / 128;
        points.push([
            r * Math.cos(phi) * Math.cos(theta),
            r * Math.sin(phi),
            r * Math.cos(phi) * Math.sin(theta),
        ]);
    }
    curves.push(space.plot({ points, color: "#4cc9f088", width: 2 }));
}
const p = [1.27017, 1.27017, 1.27017];
const radial = space.vector({ value: p, color: "#ffd166", width: 4, tip: 13 });
const point = space.point({ point: p, fill: "#ef5350", radius: 7 });
const sphereLabel = space.text({
    text: "x² + y² + z² = r²",
    point: [-2.7, 2.45, 0],
    align: [0, 0.5],
    font: "Pretendard",
    size: 24,
    fill: "#4cc9f0",
});
const radiusLabel = space.text({
    text: "r = 2.2",
    point: [0.9, 2.45, 0],
    align: [0, 0.5],
    font: "Pretendard",
    size: 24,
    fill: "#ffd166",
});
const pointLabel = space.text({
    text: "P(x, y, z)",
    point: [p[0] + 0.2, p[1] + 0.3, p[2]],
    align: [0, 0.5],
    font: "Pretendard",
    size: 17,
    fill: "#ef5350",
});
scene.create(curves, 1.2, "ease_out", 0.025);
scene.create([radial, point], 0.7, "ease_out", 0.12);
scene.create([sphereLabel, radiusLabel, pointLabel], 0.45, "ease_out", 0.08);
scene.wait(0.7);
return scene;
`,
    },
    {
        id: "solids-3d",
        title: "3D solids",
        description:
            "Compose cube, pyramid, and cylinder wireframes from the same unified line and plot objects.",
        category: "Geometry",
        dimension: "3D",
        fonts: PRETENDARD,
        lua: `local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    camera = {
        mode = "interactive",
        view = "3d",
        eye = { 8, 6, 10 },
        target = { 0, 0, 0 },
        up = { 0, 1, 0 },
        projection = "perspective",
        fov = 0.72,
        near = 0.1,
        far = 100,
    },
}
local space =
    scene:space { x = { -5, 5, 1 }, y = { -3, 3, 1 }, z = { -4, 4, 1 }, color = "#26313b" }
local shapes = {}
local function edge(a, b, c)
    shapes[#shapes + 1] = space:line { from = a, to = b, color = c, width = 2.5 }
end
local cube = {
    { -3.8, -1, -1 },
    { -1.8, -1, -1 },
    { -1.8, 1, -1 },
    { -3.8, 1, -1 },
    { -3.8, -1, 1 },
    { -1.8, -1, 1 },
    { -1.8, 1, 1 },
    { -3.8, 1, 1 },
}
local edges = {
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
for i = 1, #edges do
    edge(cube[edges[i][1]], cube[edges[i][2]], "#4cc9f0")
end
local base = { { -0.8, -1, -1 }, { 1.2, -1, -1 }, { 1.2, -1, 1 }, { -0.8, -1, 1 } }
for i = 1, 4 do
    edge(base[i], base[i % 4 + 1], "#ffd166")
    edge(base[i], { 0.2, 1.4, 0 }, "#ffd166")
end
for ring = 0, 2 do
    local points = {}
    local y = -1 + ring
    for i = 0, 48 do
        local a = i * 6.28318530718 / 48
        points[#points + 1] = { 3.2 + math.cos(a), y, math.sin(a) }
    end
    shapes[#shapes + 1] = space:plot { points = points, color = "#7bd88f", width = 2.5 }
end
for i = 0, 3 do
    local a = i * 1.57079632679
    edge({ 3.2 + math.cos(a), -1, math.sin(a) }, { 3.2 + math.cos(a), 1, math.sin(a) }, "#7bd88f")
end
local cubeLabel = space:text {
    text = "cube",
    point = { -4.4, 2.15, 0 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 22,
    fill = "#4cc9f0",
}
local pyramidLabel = space:text {
    text = "pyramid",
    point = { -0.9, 2.15, 0 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 22,
    fill = "#ffd166",
}
local cylinderLabel = space:text {
    text = "cylinder",
    point = { 2.2, 2.15, 0 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 22,
    fill = "#7bd88f",
}
scene:create(shapes, 1.2, "ease_out", 0.025)
scene:create({ cubeLabel, pyramidLabel, cylinderLabel }, 0.45, "ease_out", 0.08)
scene:wait(0.7)
return scene
`,
        js: `const scene = tmath.scene({
    width: 960,
    height: 540,
    fps: 30,
    camera: {
        mode: "interactive",
        view: "3d",
        eye: [8, 6, 10],
        target: [0, 0, 0],
        up: [0, 1, 0],
        projection: "perspective",
        fov: 0.72,
        near: 0.1,
        far: 100,
    },
});
const space = scene.space({ x: [-5, 5, 1], y: [-3, 3, 1], z: [-4, 4, 1], color: "#26313b" });
const shapes = [],
    edge = (a, b, color) => shapes.push(space.line({ from: a, to: b, color, width: 2.5 }));
const cube = [
    [-3.8, -1, -1],
    [-1.8, -1, -1],
    [-1.8, 1, -1],
    [-3.8, 1, -1],
    [-3.8, -1, 1],
    [-1.8, -1, 1],
    [-1.8, 1, 1],
    [-3.8, 1, 1],
];
for (const [a, b] of [
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
])
    edge(cube[a], cube[b], "#4cc9f0");
const base = [
    [-0.8, -1, -1],
    [1.2, -1, -1],
    [1.2, -1, 1],
    [-0.8, -1, 1],
];
for (let i = 0; i < 4; i++) {
    edge(base[i], base[(i + 1) % 4], "#ffd166");
    edge(base[i], [0.2, 1.4, 0], "#ffd166");
}
for (let ring = 0; ring < 3; ring++) {
    const y = -1 + ring,
        points = Array.from({ length: 49 }, (_, i) => {
            const a = (i * Math.PI * 2) / 48;
            return [3.2 + Math.cos(a), y, Math.sin(a)];
        });
    shapes.push(space.plot({ points, color: "#7bd88f", width: 2.5 }));
}
for (let i = 0; i < 4; i++) {
    const a = (i * Math.PI) / 2;
    edge([3.2 + Math.cos(a), -1, Math.sin(a)], [3.2 + Math.cos(a), 1, Math.sin(a)], "#7bd88f");
}
const cubeLabel = space.text({
    text: "cube",
    point: [-4.4, 2.15, 0],
    align: [0, 0.5],
    font: "Pretendard",
    size: 22,
    fill: "#4cc9f0",
});
const pyramidLabel = space.text({
    text: "pyramid",
    point: [-0.9, 2.15, 0],
    align: [0, 0.5],
    font: "Pretendard",
    size: 22,
    fill: "#ffd166",
});
const cylinderLabel = space.text({
    text: "cylinder",
    point: [2.2, 2.15, 0],
    align: [0, 0.5],
    font: "Pretendard",
    size: 22,
    fill: "#7bd88f",
});
scene.create(shapes, 1.2, "ease_out", 0.025);
scene.create([cubeLabel, pyramidLabel, cylinderLabel], 0.45, "ease_out", 0.08);
scene.wait(0.7);
return scene;
`,
    },
    {
        id: "space-numbers",
        title: "Space coordinate number modes",
        description:
            "Apply the same scale(0.1) matrix in three isolated Viewports and compare fixed, relative, and disabled coordinate labels.",
        category: "Coordinates",
        dimension: "2D",
        fonts: PRETENDARD,
        lua: `local p = {
    bg = "#0b111a",
    panelA = "#101925",
    panelB = "#0f1722",
    grid = "#263447",
    axis = "#66758a",
    text = "#f4f7fb",
    muted = "#94a3b8",
    fixed = "#ffd166",
    relative = "#4cc9f0",
    off = "#7bd88f",
    point = "#ff6b6b",
}
local function panel(index, title, mode, color, note, background)
    local child = tmath.scene {
        width = 320,
        height = 540,
        fps = 30,
        background = background,
        camera = { mode = "fixed", view = "2d", target = { 0, 0 }, height = 0.72 },
    }
    local options = {
        x = { 0, 3, 1 },
        y = { 0, 2, 1 },
        z = { 0, 0, 1 },
        numbers = mode ~= "off",
        number_size = 15,
        number_color = color,
        color = p.grid,
        axis_x = p.axis,
        axis_y = p.axis,
        matrix = { 0.1, 0, 0, -0.15, 0, 0.1, 0, -0.08, 0, 0, 1, 0, 0, 0, 0, 1 },
        id = mode .. "-numbers",
    }
    if mode ~= "off" then
        options.number_mode = mode
    end
    local grid = child:space(options)
    local sample = grid:point { point = { 3, 1 }, fill = p.point, radius = 6, layer = 5 }
    local step = child:text {
        text = index,
        point = { -0.185, 0.292 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 13,
        fill = p.muted,
    }
    local heading = child:text {
        text = title,
        point = { -0.132, 0.292 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 19,
        fill = p.text,
    }
    local matrix = child:text {
        text = "M = scale(0.1)",
        point = { -0.185, 0.242 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 14,
        fill = p.muted,
    }
    local result = child:text {
        text = note,
        point = { -0.185, -0.265 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 16,
        fill = color,
    }
    local caption = child:text {
        text = mode == "fixed" and "grid units"
            or (mode == "relative" and "world units" or "labels disabled"),
        point = { -0.185, -0.305 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 13,
        fill = p.muted,
    }
    child:create({ step, heading, matrix }, 0.38, "ease_out", 0.05)
    child:create(grid, 0.72, "ease_out")
    child:create(sample, 0.28, "ease_out")
    child:create({ result, caption }, 0.34, "ease_out", 0.05)
    child:wait(0.65)
    return child
end
local fixed = panel("01", "FIXED", "fixed", p.fixed, "1   2   3", p.panelA)
local relative = panel("02", "RELATIVE", "relative", p.relative, "0.1   0.2   0.3", p.panelB)
local off = panel("03", "OFF", "off", p.off, "numbers = false", p.panelA)
local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    background = p.bg,
    camera = { mode = "fixed", view = "2d", height = 6 },
}
scene:viewport(fixed, { x = 0, y = 0, width = 1 / 3, height = 1 })
scene:viewport(relative, { x = 1 / 3, y = 0, width = 1 / 3, height = 1 })
scene:viewport(off, { x = 2 / 3, y = 0, width = 1 / 3, height = 1 })
return scene
`,
        js: `const p = {
    bg: "#0b111a",
    panelA: "#101925",
    panelB: "#0f1722",
    grid: "#263447",
    axis: "#66758a",
    text: "#f4f7fb",
    muted: "#94a3b8",
    fixed: "#ffd166",
    relative: "#4cc9f0",
    off: "#7bd88f",
    point: "#ff6b6b",
};
const panel = (index, title, mode, color, note, background) => {
    const child = tmath.scene({
        width: 320,
        height: 540,
        fps: 30,
        background,
        camera: { mode: "fixed", view: "2d", target: [0, 0], height: 0.72 },
    });
    const options = {
        x: [0, 3, 1],
        y: [0, 2, 1],
        z: [0, 0, 1],
        numbers: mode !== "off",
        number_size: 15,
        number_color: color,
        color: p.grid,
        axis_x: p.axis,
        axis_y: p.axis,
        matrix: [0.1, 0, 0, -0.15, 0, 0.1, 0, -0.08, 0, 0, 1, 0, 0, 0, 0, 1],
        id: mode + "-numbers",
    };
    if (mode !== "off") options.number_mode = mode;
    const grid = child.space(options),
        sample = grid.point({ point: [3, 1], fill: p.point, radius: 6, layer: 5 });
    const step = child.text({
        text: index,
        point: [-0.185, 0.292],
        align: [0, 0.5],
        font: "Pretendard",
        size: 13,
        fill: p.muted,
    });
    const heading = child.text({
        text: title,
        point: [-0.132, 0.292],
        align: [0, 0.5],
        font: "Pretendard",
        size: 19,
        fill: p.text,
    });
    const matrix = child.text({
        text: "M = scale(0.1)",
        point: [-0.185, 0.242],
        align: [0, 0.5],
        font: "Pretendard",
        size: 14,
        fill: p.muted,
    });
    const result = child.text({
        text: note,
        point: [-0.185, -0.265],
        align: [0, 0.5],
        font: "Pretendard",
        size: 16,
        fill: color,
    });
    const caption = child.text({
        text:
            mode === "fixed"
                ? "grid units"
                : mode === "relative"
                  ? "world units"
                  : "labels disabled",
        point: [-0.185, -0.305],
        align: [0, 0.5],
        font: "Pretendard",
        size: 13,
        fill: p.muted,
    });
    child.create([step, heading, matrix], 0.38, "ease_out", 0.05).create(grid, 0.72, "ease_out");
    child
        .create(sample, 0.28, "ease_out")
        .create([result, caption], 0.34, "ease_out", 0.05)
        .wait(0.65);
    return child;
};
const fixed = panel("01", "FIXED", "fixed", p.fixed, "1   2   3", p.panelA);
const relative = panel("02", "RELATIVE", "relative", p.relative, "0.1   0.2   0.3", p.panelB);
const off = panel("03", "OFF", "off", p.off, "numbers = false", p.panelA);
const scene = tmath.scene({
    width: 960,
    height: 540,
    fps: 30,
    background: p.bg,
    camera: { mode: "fixed", view: "2d", height: 6 },
});
scene.viewport(fixed, { x: 0, y: 0, width: 1 / 3, height: 1 });
scene.viewport(relative, { x: 1 / 3, y: 0, width: 1 / 3, height: 1 });
scene.viewport(off, { x: 2 / 3, y: 0, width: 1 / 3, height: 1 });
return scene;
`,
    },
    {
        id: "text-font",
        title: "Text and font specimen",
        description:
            "Inspect one loaded Pretendard TTF through hierarchy, size, anchor alignment, semantic color, and supported UTF-8 math glyphs.",
        category: "Typography",
        dimension: "2D",
        fonts: PRETENDARD,
        lua: `local p = {
    bg = "#0b111a",
    panel = "#101925",
    line = "#263447",
    text = "#f4f7fb",
    muted = "#94a3b8",
    cyan = "#4cc9f0",
    magenta = "#f72585",
    gold = "#ffd166",
    green = "#7bd88f",
    point = "#ff6b6b",
}
local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    background = p.bg,
    camera = { mode = "fixed", view = "2d", height = 6.8 },
}
local s = scene:space { x = { -6, 6, 1 }, y = { -3.4, 3.4, 1 }, progress = 0 }
local frame = {
    s:rectangle {
        center = { 2.5, 2.12 },
        size = { 5.65, 1.25 },
        corner = 0.12,
        fill = p.panel,
        stroke = p.line,
        width = 2,
    },
    s:line { from = { -5.45, 1.28 }, to = { 5.45, 1.28 }, color = p.line, width = 2 },
    s:line { from = { -5.45, -1.55 }, to = { 5.45, -1.55 }, color = p.line, width = 2 },
    s:text {
        text = "TEXT / FONT SPECIMEN",
        point = { -5.35, 2.86 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 14,
        fill = p.muted,
    },
}
local hero = {
    s:text {
        text = "Pretendard",
        point = { -5.35, 2.12 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 43,
        fill = p.text,
    },
    s:text {
        text = "ThorVG text object · loaded TTF",
        point = { -5.32, 1.62 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 15,
        fill = p.muted,
    },
    s:text {
        text = "Aa 0123",
        point = { -0.08, 2.10 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 50,
        fill = p.cyan,
    },
}
local sizeLabel = s:text {
    text = "SIZE",
    point = { -5.35, 0.92 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = p.muted,
}
local sizes = {
    s:text {
        text = "18 px",
        point = { -3.85, 0.45 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 18,
        fill = p.text,
    },
    s:text {
        text = "28 px",
        point = { -1.45, 0.45 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 28,
        fill = p.cyan,
    },
    s:text {
        text = "40 px",
        point = { 1.65, 0.45 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 40,
        fill = p.gold,
    },
}
local alignLabel = s:text {
    text = "ALIGN",
    point = { -5.35, -0.15 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = p.muted,
}
local guides = {}
for _, x in ipairs { -2.7, 0, 2.7 } do
    guides[#guides + 1] =
        s:line { from = { x, -1.30 }, to = { x, -0.22 }, color = p.line, width = 2 }
    guides[#guides + 1] = s:point { point = { x, -0.73 }, fill = p.point, radius = 4, layer = 5 }
end
local aligned = {
    s:text {
        text = "left",
        point = { -2.7, -0.73 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 21,
        fill = p.green,
    },
    s:text {
        text = "center",
        point = { 0, -0.73 },
        align = { 0.5, 0.5 },
        font = "Pretendard",
        size = 21,
        fill = p.green,
    },
    s:text {
        text = "right",
        point = { 2.7, -0.73 },
        align = { 1, 0.5 },
        font = "Pretendard",
        size = 21,
        fill = p.green,
    },
}
local lowerLabels = {
    s:text {
        text = "SEMANTIC COLOR",
        point = { -5.35, -1.90 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 13,
        fill = p.muted,
    },
    s:text {
        text = "UTF-8 / MATH",
        point = { 0.15, -1.90 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 13,
        fill = p.muted,
    },
}
local lower = {
    s:text {
        text = "a",
        point = { -5.35, -2.48 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 30,
        fill = p.cyan,
    },
    s:text {
        text = "+",
        point = { -4.92, -2.48 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 30,
        fill = p.muted,
    },
    s:text {
        text = "b",
        point = { -4.40, -2.48 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 30,
        fill = p.magenta,
    },
    s:text {
        text = "=",
        point = { -3.88, -2.48 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 30,
        fill = p.muted,
    },
    s:text {
        text = "c",
        point = { -3.30, -2.48 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 30,
        fill = p.gold,
    },
    s:text {
        text = "π  λ  α  β  θ   Σ  ∫",
        point = { 0.15, -2.48 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 28,
        fill = p.text,
    },
}
scene:create(frame, 0.42, "ease_out", 0.05)
scene:create(hero, 0.62, "ease_out", 0.08)
scene:create(sizeLabel, 0.24, "ease_out")
scene:create(sizes, 0.52, "ease_out", 0.08)
scene:create(alignLabel, 0.24, "ease_out")
scene:create(guides, 0.38, "ease_out", 0.04)
scene:create(aligned, 0.42, "ease_out", 0.08)
scene:create(lowerLabels, 0.26, "ease_out", 0.06)
scene:create(lower, 0.46, "ease_out", 0.06)
scene:wait(0.72)
return scene
`,
        js: `const p = {
    bg: "#0b111a",
    panel: "#101925",
    line: "#263447",
    text: "#f4f7fb",
    muted: "#94a3b8",
    cyan: "#4cc9f0",
    magenta: "#f72585",
    gold: "#ffd166",
    green: "#7bd88f",
    point: "#ff6b6b",
};
const scene = tmath.scene({
    width: 960,
    height: 540,
    fps: 30,
    background: p.bg,
    camera: { mode: "fixed", view: "2d", height: 6.8 },
});
const s = scene.space({ x: [-6, 6, 1], y: [-3.4, 3.4, 1], progress: 0 });
const frame = [
    s.rectangle({
        center: [2.5, 2.12],
        size: [5.65, 1.25],
        corner: 0.12,
        fill: p.panel,
        stroke: p.line,
        width: 2,
    }),
    s.line({ from: [-5.45, 1.28], to: [5.45, 1.28], color: p.line, width: 2 }),
    s.line({ from: [-5.45, -1.55], to: [5.45, -1.55], color: p.line, width: 2 }),
    s.text({
        text: "TEXT / FONT SPECIMEN",
        point: [-5.35, 2.86],
        align: [0, 0.5],
        font: "Pretendard",
        size: 14,
        fill: p.muted,
    }),
];
const hero = [
    s.text({
        text: "Pretendard",
        point: [-5.35, 2.12],
        align: [0, 0.5],
        font: "Pretendard",
        size: 43,
        fill: p.text,
    }),
    s.text({
        text: "ThorVG text object · loaded TTF",
        point: [-5.32, 1.62],
        align: [0, 0.5],
        font: "Pretendard",
        size: 15,
        fill: p.muted,
    }),
    s.text({
        text: "Aa 0123",
        point: [-0.08, 2.1],
        align: [0, 0.5],
        font: "Pretendard",
        size: 50,
        fill: p.cyan,
    }),
];
const sizeLabel = s.text({
    text: "SIZE",
    point: [-5.35, 0.92],
    align: [0, 0.5],
    font: "Pretendard",
    size: 13,
    fill: p.muted,
});
const sizes = [
    s.text({
        text: "18 px",
        point: [-3.85, 0.45],
        align: [0, 0.5],
        font: "Pretendard",
        size: 18,
        fill: p.text,
    }),
    s.text({
        text: "28 px",
        point: [-1.45, 0.45],
        align: [0, 0.5],
        font: "Pretendard",
        size: 28,
        fill: p.cyan,
    }),
    s.text({
        text: "40 px",
        point: [1.65, 0.45],
        align: [0, 0.5],
        font: "Pretendard",
        size: 40,
        fill: p.gold,
    }),
];
const alignLabel = s.text({
    text: "ALIGN",
    point: [-5.35, -0.15],
    align: [0, 0.5],
    font: "Pretendard",
    size: 13,
    fill: p.muted,
});
const guides = [];
for (const x of [-2.7, 0, 2.7]) {
    guides.push(s.line({ from: [x, -1.3], to: [x, -0.22], color: p.line, width: 2 }));
    guides.push(s.point({ point: [x, -0.73], fill: p.point, radius: 4, layer: 5 }));
}
const aligned = [
    s.text({
        text: "left",
        point: [-2.7, -0.73],
        align: [0, 0.5],
        font: "Pretendard",
        size: 21,
        fill: p.green,
    }),
    s.text({
        text: "center",
        point: [0, -0.73],
        align: [0.5, 0.5],
        font: "Pretendard",
        size: 21,
        fill: p.green,
    }),
    s.text({
        text: "right",
        point: [2.7, -0.73],
        align: [1, 0.5],
        font: "Pretendard",
        size: 21,
        fill: p.green,
    }),
];
const lowerLabels = [
    s.text({
        text: "SEMANTIC COLOR",
        point: [-5.35, -1.9],
        align: [0, 0.5],
        font: "Pretendard",
        size: 13,
        fill: p.muted,
    }),
    s.text({
        text: "UTF-8 / MATH",
        point: [0.15, -1.9],
        align: [0, 0.5],
        font: "Pretendard",
        size: 13,
        fill: p.muted,
    }),
];
const lower = [
    s.text({
        text: "a",
        point: [-5.35, -2.48],
        align: [0, 0.5],
        font: "Pretendard",
        size: 30,
        fill: p.cyan,
    }),
    s.text({
        text: "+",
        point: [-4.92, -2.48],
        align: [0, 0.5],
        font: "Pretendard",
        size: 30,
        fill: p.muted,
    }),
    s.text({
        text: "b",
        point: [-4.4, -2.48],
        align: [0, 0.5],
        font: "Pretendard",
        size: 30,
        fill: p.magenta,
    }),
    s.text({
        text: "=",
        point: [-3.88, -2.48],
        align: [0, 0.5],
        font: "Pretendard",
        size: 30,
        fill: p.muted,
    }),
    s.text({
        text: "c",
        point: [-3.3, -2.48],
        align: [0, 0.5],
        font: "Pretendard",
        size: 30,
        fill: p.gold,
    }),
    s.text({
        text: "π  λ  α  β  θ   Σ  ∫",
        point: [0.15, -2.48],
        align: [0, 0.5],
        font: "Pretendard",
        size: 28,
        fill: p.text,
    }),
];
scene.create(frame, 0.42, "ease_out", 0.05).create(hero, 0.62, "ease_out", 0.08);
scene.create(sizeLabel, 0.24, "ease_out").create(sizes, 0.52, "ease_out", 0.08);
scene.create(alignLabel, 0.24, "ease_out").create(guides, 0.38, "ease_out", 0.04);
scene.create(aligned, 0.42, "ease_out", 0.08).create(lowerLabels, 0.26, "ease_out", 0.06);
scene.create(lower, 0.46, "ease_out", 0.06).wait(0.72);
return scene;
`,
    },
    {
        id: "sw-rle-span",
        title: "SW raster: RLE / Span",
        description:
            "Follow one coverage scanline as three colored runs become compact SwSpan records.",
        category: "ThorVG SW",
        dimension: "2D",
        fonts: PRETENDARD,
        lua: `local p = {
    background = "#0b111a",
    panel = "#101925",
    panel_alt = "#131e2b",
    line = "#2a3a4d",
    text = "#f4f7fb",
    muted = "#94a3b8",
    cyan = "#4cc9f0",
    gold = "#ffd166",
    coral = "#ff6b6b",
    green = "#7bd88f",
}
local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    antialiasing = true,
    background = p.background,
    camera = { mode = "fixed", view = "2d", height = 7.4 },
}
local s = scene:space { x = { -6.5, 6.5, 1 }, y = { -3.5, 3.5, 1 }, opacity = 0 }
local eyebrow = s:text {
    text = "THORVG · SOFTWARE RASTERIZER / 01",
    point = { -5.85, 3.28 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = p.muted,
}
local title = s:text {
    text = "Run-length spans",
    point = { -5.85, 2.82 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 30,
    fill = p.text,
}
local subtitle = s:text {
    text = "Compress one scanline into contiguous coverage records",
    point = { -5.83, 2.34 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 15,
    fill = p.muted,
}
local divider = s:line { from = { -5.85, 2.08 }, to = { 5.85, 2.08 }, color = p.line, width = 2 }
local inputPanel = s:rectangle {
    center = { 0, 1.08 },
    size = { 12.4, 1.55 },
    corner = 0.14,
    fill = p.panel,
    stroke = p.line,
    width = 2,
}
local inputLabel = s:text {
    text = "MECHANISM · COVERAGE SCANLINE",
    point = { -5.7, 1.72 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = p.muted,
}
local patches = {
    { region = { 1, 0, 3, 1 }, color = p.cyan },
    { region = { 5, 0, 2, 1 }, color = p.gold },
    { region = { 8, 0, 4, 1 }, color = p.coral },
}
local pixels = s:cell {
    origin = { -6, 0.58 },
    size = { 12, 1 },
    mode = "padd",
    padding = 0.055,
    color = "#1b2734",
    patches = patches,
    id = "coverage-scanline",
}
local coverageLabels = {
    s:text {
        text = "cov 255",
        point = { -3.5, 1.3 },
        font = "Pretendard",
        size = 13,
        fill = p.background,
        layer = 8,
    },
    s:text {
        text = "cov 160",
        point = { 0, 1.3 },
        font = "Pretendard",
        size = 13,
        fill = p.background,
        layer = 8,
    },
    s:text {
        text = "cov 224",
        point = { 4, 1.3 },
        font = "Pretendard",
        size = 13,
        fill = p.background,
        layer = 8,
    },
}
local indices = {}
for i = 0, 11 do
    indices[#indices + 1] = s:text {
        text = tostring(i),
        point = { -5.5 + i, 0.42 },
        font = "Pretendard",
        size = 11,
        fill = p.muted,
    }
end
local boundary = s:text {
    text = "RUN BOUNDARIES",
    point = { -5.7, -0.04 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = p.muted,
}
local arrows = {
    s:arrow { from = { -3.5, 0.28 }, to = { -3.5, -0.22 }, tip = 9, color = p.cyan, width = 2 },
    s:arrow { from = { 0, 0.28 }, to = { 0, -0.22 }, tip = 9, color = p.gold, width = 2 },
    s:arrow { from = { 4, 0.28 }, to = { 4, -0.22 }, tip = 9, color = p.coral, width = 2 },
}
local outputLabel = s:text {
    text = "RESULT · SwSpan { x, y, len, coverage }",
    point = { -5.7, -0.62 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = p.muted,
}
local specs = {
    { -3.75, p.cyan, "x 1   ·   len 3", "coverage 255" },
    { 0, p.gold, "x 5   ·   len 2", "coverage 160" },
    { 3.75, p.coral, "x 8   ·   len 4", "coverage 224" },
}
local cards, records = {}, {}
for _, v in ipairs(specs) do
    cards[#cards + 1] = s:rectangle {
        center = { v[1], -1.45 },
        size = { 3.35, 1.02 },
        corner = 0.13,
        fill = p.panel_alt,
        stroke = v[2],
        width = 2,
    }
    records[#records + 1] = s:text {
        text = v[3],
        point = { v[1], -1.28 },
        font = "Pretendard",
        size = 16,
        fill = p.text,
    }
    records[#records + 1] =
        s:text { text = v[4], point = { v[1], -1.68 }, font = "Pretendard", size = 13, fill = v[2] }
end
local conclusion = s:text {
    text = "3 spans encode 9 covered pixels  ·  blend loops over runs, not empty cells",
    point = { 0, -2.48 },
    font = "Pretendard",
    size = 17,
    fill = p.green,
}
scene:create({ eyebrow, title, subtitle, divider }, 0.52, "ease_out", 0.06)
scene:create({ inputPanel, inputLabel }, 0.36, "ease_out", 0.05)
scene:create(pixels, 0.72, "linear")
scene:create(coverageLabels, 0.3, "ease_out", 0.06)
scene:create(indices, 0.34, "ease_out", 0.025)
scene:create(boundary, 0.28, "ease_out")
scene:create(arrows, 0.42, "ease_out", 0.08)
scene:create(outputLabel, 0.25, "ease_out")
scene:create(cards, 0.48, "ease_out", 0.08)
scene:create(records, 0.38, "ease_out", 0.045)
scene:create(conclusion, 0.4, "ease_out")
scene:wait(0.7)
return scene
`,
        js: `const p = {
    background: "#0b111a",
    panel: "#101925",
    panelAlt: "#131e2b",
    line: "#2a3a4d",
    text: "#f4f7fb",
    muted: "#94a3b8",
    cyan: "#4cc9f0",
    gold: "#ffd166",
    coral: "#ff6b6b",
    green: "#7bd88f",
};
const scene = tmath.scene({
    width: 960,
    height: 540,
    fps: 30,
    antialiasing: true,
    background: p.background,
    camera: { mode: "fixed", view: "2d", height: 7.4 },
});
const s = scene.space({ x: [-6.5, 6.5, 1], y: [-3.5, 3.5, 1], opacity: 0 });
const eyebrow = s.text({
    text: "THORVG · SOFTWARE RASTERIZER / 01",
    point: [-5.85, 3.28],
    align: [0, 0.5],
    font: "Pretendard",
    size: 13,
    fill: p.muted,
});
const title = s.text({
    text: "Run-length spans",
    point: [-5.85, 2.82],
    align: [0, 0.5],
    font: "Pretendard",
    size: 30,
    fill: p.text,
});
const subtitle = s.text({
    text: "Compress one scanline into contiguous coverage records",
    point: [-5.83, 2.34],
    align: [0, 0.5],
    font: "Pretendard",
    size: 15,
    fill: p.muted,
});
const divider = s.line({ from: [-5.85, 2.08], to: [5.85, 2.08], color: p.line, width: 2 });
const inputPanel = s.rectangle({
    center: [0, 1.08],
    size: [12.4, 1.55],
    corner: 0.14,
    fill: p.panel,
    stroke: p.line,
    width: 2,
});
const inputLabel = s.text({
    text: "MECHANISM · COVERAGE SCANLINE",
    point: [-5.7, 1.72],
    align: [0, 0.5],
    font: "Pretendard",
    size: 13,
    fill: p.muted,
});
const patches = [
    { region: [1, 0, 3, 1], color: p.cyan },
    { region: [5, 0, 2, 1], color: p.gold },
    { region: [8, 0, 4, 1], color: p.coral },
];
const pixels = s.cell({
    origin: [-6, 0.58],
    size: [12, 1],
    mode: "padd",
    padding: 0.055,
    color: "#1b2734",
    patches,
    id: "coverage-scanline",
});
const coverageLabels = [
    s.text({
        text: "cov 255",
        point: [-3.5, 1.3],
        font: "Pretendard",
        size: 13,
        fill: p.background,
        layer: 8,
    }),
    s.text({
        text: "cov 160",
        point: [0, 1.3],
        font: "Pretendard",
        size: 13,
        fill: p.background,
        layer: 8,
    }),
    s.text({
        text: "cov 224",
        point: [4, 1.3],
        font: "Pretendard",
        size: 13,
        fill: p.background,
        layer: 8,
    }),
];
const indices = Array.from({ length: 12 }, (_, i) =>
    s.text({
        text: String(i),
        point: [-5.5 + i, 0.42],
        font: "Pretendard",
        size: 11,
        fill: p.muted,
    }),
);
const boundary = s.text({
    text: "RUN BOUNDARIES",
    point: [-5.7, -0.04],
    align: [0, 0.5],
    font: "Pretendard",
    size: 13,
    fill: p.muted,
});
const arrows = [
    s.arrow({ from: [-3.5, 0.28], to: [-3.5, -0.22], tip: 9, color: p.cyan, width: 2 }),
    s.arrow({ from: [0, 0.28], to: [0, -0.22], tip: 9, color: p.gold, width: 2 }),
    s.arrow({ from: [4, 0.28], to: [4, -0.22], tip: 9, color: p.coral, width: 2 }),
];
const outputLabel = s.text({
    text: "RESULT · SwSpan { x, y, len, coverage }",
    point: [-5.7, -0.62],
    align: [0, 0.5],
    font: "Pretendard",
    size: 13,
    fill: p.muted,
});
const specs = [
    [-3.75, p.cyan, "x 1   ·   len 3", "coverage 255"],
    [0, p.gold, "x 5   ·   len 2", "coverage 160"],
    [3.75, p.coral, "x 8   ·   len 4", "coverage 224"],
];
const cards = specs.map((v) =>
    s.rectangle({
        center: [v[0], -1.45],
        size: [3.35, 1.02],
        corner: 0.13,
        fill: p.panelAlt,
        stroke: v[1],
        width: 2,
    }),
);
const records = specs.flatMap((v) => [
    s.text({ text: v[2], point: [v[0], -1.28], font: "Pretendard", size: 16, fill: p.text }),
    s.text({ text: v[3], point: [v[0], -1.68], font: "Pretendard", size: 13, fill: v[1] }),
]);
const conclusion = s.text({
    text: "3 spans encode 9 covered pixels  ·  blend loops over runs, not empty cells",
    point: [0, -2.48],
    font: "Pretendard",
    size: 17,
    fill: p.green,
});
scene.create([eyebrow, title, subtitle, divider], 0.52, "ease_out", 0.06);
scene.create([inputPanel, inputLabel], 0.36, "ease_out", 0.05);
scene.create(pixels, 0.72, "linear");
scene.create(coverageLabels, 0.3, "ease_out", 0.06);
scene.create(indices, 0.34, "ease_out", 0.025);
scene.create(boundary, 0.28, "ease_out");
scene.create(arrows, 0.42, "ease_out", 0.08);
scene.create(outputLabel, 0.25, "ease_out");
scene.create(cards, 0.48, "ease_out", 0.08);
scene.create(records, 0.38, "ease_out", 0.045);
scene.create(conclusion, 0.4, "ease_out");
scene.wait(0.7);
return scene;
`,
    },
    {
        id: "sw-antialiasing",
        title: "SW raster: Anti-aliasing",
        description:
            "Conceptually compare a binary edge test with fractional coverage and alpha blending.",
        category: "ThorVG SW",
        dimension: "2D",
        fonts: PRETENDARD,
        lua: `local p = {
    background = "#0b111a",
    panel = "#101925",
    line = "#2a3a4d",
    text = "#f4f7fb",
    muted = "#94a3b8",
    cyan = "#4cc9f0",
    cyan_mid = "#388faa",
    cyan_low = "#244f62",
    coral = "#ff6b6b",
    gold = "#ffd166",
    green = "#7bd88f",
}
local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    antialiasing = true,
    background = p.background,
    camera = { mode = "fixed", view = "2d", height = 7.4 },
}
local s = scene:space { x = { -6.5, 6.5, 1 }, y = { -3.5, 3.5, 1 }, opacity = 0 }
local eyebrow = s:text {
    text = "THORVG · SOFTWARE RASTERIZER / 02",
    point = { -5.85, 3.28 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = p.muted,
}
local title = s:text {
    text = "Edge coverage and anti-aliasing",
    point = { -5.85, 2.82 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 30,
    fill = p.text,
}
local subtitle = s:text {
    text = "Conceptual map · binary test -> fractional pixel coverage",
    point = { -5.83, 2.34 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 15,
    fill = p.muted,
}
local divider = s:line { from = { -5.85, 2.08 }, to = { 5.85, 2.08 }, color = p.line, width = 2 }
local panels = {
    s:rectangle {
        center = { -3.1, -0.24 },
        size = { 5.65, 4.2 },
        corner = 0.15,
        fill = p.panel,
        stroke = p.line,
        width = 2,
    },
    s:rectangle {
        center = { 3.1, -0.24 },
        size = { 5.65, 4.2 },
        corner = 0.15,
        fill = p.panel,
        stroke = p.line,
        width = 2,
    },
}
local panelTitles = {
    s:text {
        text = "A  ·  BINARY COVERAGE",
        point = { -5.63, 1.48 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 13,
        fill = p.muted,
    },
    s:text {
        text = "B  ·  FRACTIONAL COVERAGE",
        point = { 0.58, 1.48 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 13,
        fill = p.muted,
    },
}
local hardPatches, aaPatches = {}, {}
for y = 0, 7 do
    for x = 0, 7 do
        hardPatches[#hardPatches + 1] =
            { region = { x, y, 1, 1 }, color = x >= y and p.cyan or "#1b2734" }
        local d = x - y
        local c = "#1b2734"
        if d >= 1 then
            c = p.cyan
        elseif d == 0 then
            c = p.cyan_mid
        elseif d == -1 then
            c = p.cyan_low
        end
        aaPatches[#aaPatches + 1] = { region = { x, y, 1, 1 }, color = c }
    end
end
local hardSpace = s:space {
    x = { 0, 8, 1 },
    y = { 0, 8, 1 },
    opacity = 0,
    matrix = { 0.37, 0, 0, -4.58, 0, 0.37, 0, -1.72, 0, 0, 1, 0, 0, 0, 0, 1 },
}
local aaSpace = s:space {
    x = { 0, 8, 1 },
    y = { 0, 8, 1 },
    opacity = 0,
    matrix = { 0.37, 0, 0, 1.62, 0, 0.37, 0, -1.72, 0, 0, 1, 0, 0, 0, 0, 1 },
}
local hard = hardSpace:cell {
    origin = { 0, 0 },
    size = { 8, 8 },
    mode = "padd",
    padding = 0.04,
    color = "#1b2734",
    patches = hardPatches,
    id = "binary-coverage",
}
local aa = aaSpace:cell {
    origin = { 0, 0 },
    size = { 8, 8 },
    mode = "padd",
    padding = 0.04,
    color = "#1b2734",
    patches = aaPatches,
    id = "fractional-coverage",
}
local edges = {
    hardSpace:line { from = { 0, 0 }, to = { 8, 8 }, color = p.coral, width = 2 },
    aaSpace:line { from = { 0, 0 }, to = { 8, 8 }, color = p.coral, width = 2 },
}
local labels = {
    s:text {
        text = "alpha = 0 or 1",
        point = { -3.1, -2.05 },
        font = "Pretendard",
        size = 16,
        fill = p.text,
    },
    s:text {
        text = "alpha = covered area / pixel area",
        point = { 3.1, -2.05 },
        font = "Pretendard",
        size = 16,
        fill = p.text,
    },
}
local result = s:text {
    text = "RESULT  ·  out = α · source + (1 − α) · destination",
    point = { 0, -2.78 },
    font = "Pretendard",
    size = 18,
    fill = p.gold,
}
local conclusion = s:text {
    text = "fractional coverage softens the staircase without moving the edge",
    point = { 0, -3.14 },
    font = "Pretendard",
    size = 13,
    fill = p.green,
}
scene:create({ eyebrow, title, subtitle, divider }, 0.52, "ease_out", 0.06)
scene:create(panels, 0.42, "ease_out", 0.08)
scene:create(panelTitles, 0.3, "ease_out", 0.08)
scene:create(hard, 0.72, "linear")
scene:create({ edges[1], labels[1] }, 0.38, "ease_out", 0.06)
scene:create(aa, 0.78, "linear")
scene:create({ edges[2], labels[2] }, 0.42, "ease_out", 0.06)
scene:create(result, 0.38, "ease_out")
scene:create(conclusion, 0.3, "ease_out")
scene:wait(0.7)
return scene
`,
        js: `const p = {
    background: "#0b111a",
    panel: "#101925",
    line: "#2a3a4d",
    text: "#f4f7fb",
    muted: "#94a3b8",
    cyan: "#4cc9f0",
    cyanMid: "#388faa",
    cyanLow: "#244f62",
    coral: "#ff6b6b",
    gold: "#ffd166",
    green: "#7bd88f",
};
const scene = tmath.scene({
    width: 960,
    height: 540,
    fps: 30,
    antialiasing: true,
    background: p.background,
    camera: { mode: "fixed", view: "2d", height: 7.4 },
});
const s = scene.space({ x: [-6.5, 6.5, 1], y: [-3.5, 3.5, 1], opacity: 0 });
const eyebrow = s.text({
    text: "THORVG · SOFTWARE RASTERIZER / 02",
    point: [-5.85, 3.28],
    align: [0, 0.5],
    font: "Pretendard",
    size: 13,
    fill: p.muted,
});
const title = s.text({
    text: "Edge coverage and anti-aliasing",
    point: [-5.85, 2.82],
    align: [0, 0.5],
    font: "Pretendard",
    size: 30,
    fill: p.text,
});
const subtitle = s.text({
    text: "Conceptual map · binary test -> fractional pixel coverage",
    point: [-5.83, 2.34],
    align: [0, 0.5],
    font: "Pretendard",
    size: 15,
    fill: p.muted,
});
const divider = s.line({ from: [-5.85, 2.08], to: [5.85, 2.08], color: p.line, width: 2 });
const panels = [
    s.rectangle({
        center: [-3.1, -0.24],
        size: [5.65, 4.2],
        corner: 0.15,
        fill: p.panel,
        stroke: p.line,
        width: 2,
    }),
    s.rectangle({
        center: [3.1, -0.24],
        size: [5.65, 4.2],
        corner: 0.15,
        fill: p.panel,
        stroke: p.line,
        width: 2,
    }),
];
const panelTitles = [
    s.text({
        text: "A  ·  BINARY COVERAGE",
        point: [-5.63, 1.48],
        align: [0, 0.5],
        font: "Pretendard",
        size: 13,
        fill: p.muted,
    }),
    s.text({
        text: "B  ·  FRACTIONAL COVERAGE",
        point: [0.58, 1.48],
        align: [0, 0.5],
        font: "Pretendard",
        size: 13,
        fill: p.muted,
    }),
];
const hardPatches = [],
    aaPatches = [];
for (let y = 0; y < 8; y++)
    for (let x = 0; x < 8; x++) {
        hardPatches.push({ region: [x, y, 1, 1], color: x >= y ? p.cyan : "#1b2734" });
        const d = x - y,
            c = d >= 1 ? p.cyan : d === 0 ? p.cyanMid : d === -1 ? p.cyanLow : "#1b2734";
        aaPatches.push({ region: [x, y, 1, 1], color: c });
    }
const hardSpace = s.space({
    x: [0, 8, 1],
    y: [0, 8, 1],
    opacity: 0,
    matrix: [0.37, 0, 0, -4.58, 0, 0.37, 0, -1.72, 0, 0, 1, 0, 0, 0, 0, 1],
});
const aaSpace = s.space({
    x: [0, 8, 1],
    y: [0, 8, 1],
    opacity: 0,
    matrix: [0.37, 0, 0, 1.62, 0, 0.37, 0, -1.72, 0, 0, 1, 0, 0, 0, 0, 1],
});
const hard = hardSpace.cell({
    origin: [0, 0],
    size: [8, 8],
    mode: "padd",
    padding: 0.04,
    color: "#1b2734",
    patches: hardPatches,
    id: "binary-coverage",
});
const aa = aaSpace.cell({
    origin: [0, 0],
    size: [8, 8],
    mode: "padd",
    padding: 0.04,
    color: "#1b2734",
    patches: aaPatches,
    id: "fractional-coverage",
});
const edges = [
    hardSpace.line({ from: [0, 0], to: [8, 8], color: p.coral, width: 2 }),
    aaSpace.line({ from: [0, 0], to: [8, 8], color: p.coral, width: 2 }),
];
const labels = [
    s.text({
        text: "alpha = 0 or 1",
        point: [-3.1, -2.05],
        font: "Pretendard",
        size: 16,
        fill: p.text,
    }),
    s.text({
        text: "alpha = covered area / pixel area",
        point: [3.1, -2.05],
        font: "Pretendard",
        size: 16,
        fill: p.text,
    }),
];
const result = s.text({
    text: "RESULT  ·  out = α · source + (1 − α) · destination",
    point: [0, -2.78],
    font: "Pretendard",
    size: 18,
    fill: p.gold,
});
const conclusion = s.text({
    text: "fractional coverage softens the staircase without moving the edge",
    point: [0, -3.14],
    font: "Pretendard",
    size: 13,
    fill: p.green,
});
scene.create([eyebrow, title, subtitle, divider], 0.52, "ease_out", 0.06);
scene.create(panels, 0.42, "ease_out", 0.08);
scene.create(panelTitles, 0.3, "ease_out", 0.08);
scene.create(hard, 0.72, "linear");
scene.create([edges[0], labels[0]], 0.38, "ease_out", 0.06);
scene.create(aa, 0.78, "linear");
scene.create([edges[1], labels[1]], 0.42, "ease_out", 0.06);
scene.create(result, 0.38, "ease_out");
scene.create(conclusion, 0.3, "ease_out");
scene.wait(0.7);
return scene;
`,
    },
    {
        id: "sw-linear-gradient",
        title: "SW raster: LinearGradient",
        description:
            "Project a sample onto the gradient vector, then interpolate 32 visible color samples.",
        category: "ThorVG SW",
        dimension: "2D",
        fonts: PRETENDARD,
        lua: `local p = {
    background = "#0b111a",
    panel = "#101925",
    line = "#2a3a4d",
    text = "#f4f7fb",
    muted = "#94a3b8",
    cyan = "#4cc9f0",
    gold = "#ffd166",
    coral = "#ff6b6b",
    green = "#7bd88f",
}
local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    antialiasing = true,
    background = p.background,
    camera = { mode = "fixed", view = "2d", height = 7.4 },
}
local s = scene:space { x = { -6.5, 6.5, 1 }, y = { -3.5, 3.5, 1 }, opacity = 0 }
local eyebrow = s:text {
    text = "THORVG · SOFTWARE RASTERIZER / 03",
    point = { -5.85, 3.28 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = p.muted,
}
local title = s:text {
    text = "Linear gradient sampling",
    point = { -5.85, 2.82 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 30,
    fill = p.text,
}
local subtitle = s:text {
    text = "Project each pixel onto the gradient vector, then interpolate the stops",
    point = { -5.83, 2.34 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 15,
    fill = p.muted,
}
local divider = s:line { from = { -5.85, 2.08 }, to = { 5.85, 2.08 }, color = p.line, width = 2 }
local mechanism = s:text {
    text = "MECHANISM · PROJECT p ONTO d",
    point = { -5.75, 1.72 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = p.muted,
}
local projection = s:text {
    text = "t = clamp( dot(p − p₀, d) / dot(d, d), 0, 1 )",
    point = { 5.75, 1.72 },
    align = { 1, 0.5 },
    font = "Pretendard",
    size = 15,
    fill = p.text,
}
local direction = s:arrow {
    from = { -5.45, 1.16 },
    to = { 5.45, 1.16 },
    tail = 8,
    tip = 13,
    color = p.text,
    width = 3,
    id = "gradient-direction",
}
local stops = {
    s:point { point = { -5.45, 1.16 }, fill = p.cyan, radius = 7, layer = 5 },
    s:point { point = { 5.45, 1.16 }, fill = p.coral, radius = 7, layer = 5 },
}
local stopLabels = {
    s:text {
        text = "p₀  ·  t = 0",
        point = { -5.45, 0.82 },
        font = "Pretendard",
        size = 14,
        fill = p.cyan,
    },
    s:text {
        text = "p₁  ·  t = 1",
        point = { 5.45, 0.82 },
        font = "Pretendard",
        size = 14,
        fill = p.coral,
    },
}
local sampleX = -1.63
local sample = s:point { point = { sampleX, 1.16 }, fill = p.gold, radius = 7, layer = 6 }
local sampleGuide =
    s:line { from = { sampleX, 0.98 }, to = { sampleX, 0.18 }, color = p.gold, width = 2 }
local sampleLabel = s:text {
    text = "sample p  ·  t = 0.35",
    point = { sampleX + 0.18, 0.63 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 14,
    fill = p.gold,
}
local resultPanel = s:rectangle {
    center = { 0, -0.73 },
    size = { 12, 2.4 },
    corner = 0.15,
    fill = p.panel,
    stroke = p.line,
    width = 2,
}
local resultLabel = s:text {
    text = "RESULT · 32 PIXEL SAMPLES",
    point = { -5.65, 0.22 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = p.muted,
}
local pixelSpace = s:space {
    x = { 0, 32, 1 },
    y = { 0, 5, 1 },
    opacity = 0,
    matrix = { 0.35, 0, 0, -5.6, 0, 0.27, 0, -1.42, 0, 0, 1, 0, 0, 0, 0, 1 },
}
local patches = {}
for x = 0, 31 do
    local t = x / 31
    local r = math.floor(76 + (255 - 76) * t + 0.5)
    local g = math.floor(201 + (107 - 201) * t + 0.5)
    local b = math.floor(240 + (107 - 240) * t + 0.5)
    patches[#patches + 1] =
        { region = { x, 0, 1, 5 }, color = string.format("#%02x%02x%02x", r, g, b) }
end
local gradient = pixelSpace:cell {
    origin = { 0, 0 },
    size = { 32, 5 },
    mode = "full",
    color = p.panel,
    patches = patches,
    id = "linear-gradient",
}
local mixFormula = s:text {
    text = "color(p) = mix(stop₀, stop₁, t)",
    point = { 0, -1.7 },
    font = "Pretendard",
    size = 16,
    fill = p.text,
}
local conclusion = s:text {
    text = "one projected scalar t drives every color channel",
    point = { 0, -2.52 },
    font = "Pretendard",
    size = 17,
    fill = p.green,
}
scene:create({ eyebrow, title, subtitle, divider }, 0.52, "ease_out", 0.06)
scene:create({ mechanism, projection }, 0.36, "ease_out", 0.06)
scene:create(direction, 0.62, "ease_out")
scene:create({ stops[1], stops[2], stopLabels[1], stopLabels[2] }, 0.36, "ease_out", 0.06)
scene:create({ sample, sampleGuide, sampleLabel }, 0.42, "ease_out", 0.06)
scene:create({ resultPanel, resultLabel }, 0.38, "ease_out", 0.05)
scene:create(gradient, 1, "linear")
scene:create(mixFormula, 0.32, "ease_out")
scene:create(conclusion, 0.38, "ease_out")
scene:wait(0.7)
return scene
`,
        js: `const p = {
    background: "#0b111a",
    panel: "#101925",
    line: "#2a3a4d",
    text: "#f4f7fb",
    muted: "#94a3b8",
    cyan: "#4cc9f0",
    gold: "#ffd166",
    coral: "#ff6b6b",
    green: "#7bd88f",
};
const scene = tmath.scene({
    width: 960,
    height: 540,
    fps: 30,
    antialiasing: true,
    background: p.background,
    camera: { mode: "fixed", view: "2d", height: 7.4 },
});
const s = scene.space({ x: [-6.5, 6.5, 1], y: [-3.5, 3.5, 1], opacity: 0 });
const eyebrow = s.text({
    text: "THORVG · SOFTWARE RASTERIZER / 03",
    point: [-5.85, 3.28],
    align: [0, 0.5],
    font: "Pretendard",
    size: 13,
    fill: p.muted,
});
const title = s.text({
    text: "Linear gradient sampling",
    point: [-5.85, 2.82],
    align: [0, 0.5],
    font: "Pretendard",
    size: 30,
    fill: p.text,
});
const subtitle = s.text({
    text: "Project each pixel onto the gradient vector, then interpolate the stops",
    point: [-5.83, 2.34],
    align: [0, 0.5],
    font: "Pretendard",
    size: 15,
    fill: p.muted,
});
const divider = s.line({ from: [-5.85, 2.08], to: [5.85, 2.08], color: p.line, width: 2 });
const mechanism = s.text({
    text: "MECHANISM · PROJECT p ONTO d",
    point: [-5.75, 1.72],
    align: [0, 0.5],
    font: "Pretendard",
    size: 13,
    fill: p.muted,
});
const projection = s.text({
    text: "t = clamp( dot(p − p₀, d) / dot(d, d), 0, 1 )",
    point: [5.75, 1.72],
    align: [1, 0.5],
    font: "Pretendard",
    size: 15,
    fill: p.text,
});
const direction = s.arrow({
    from: [-5.45, 1.16],
    to: [5.45, 1.16],
    tail: 8,
    tip: 13,
    color: p.text,
    width: 3,
    id: "gradient-direction",
});
const stops = [
    s.point({ point: [-5.45, 1.16], fill: p.cyan, radius: 7, layer: 5 }),
    s.point({ point: [5.45, 1.16], fill: p.coral, radius: 7, layer: 5 }),
];
const stopLabels = [
    s.text({
        text: "p₀  ·  t = 0",
        point: [-5.45, 0.82],
        font: "Pretendard",
        size: 14,
        fill: p.cyan,
    }),
    s.text({
        text: "p₁  ·  t = 1",
        point: [5.45, 0.82],
        font: "Pretendard",
        size: 14,
        fill: p.coral,
    }),
];
const sampleX = -1.63,
    sample = s.point({ point: [sampleX, 1.16], fill: p.gold, radius: 7, layer: 6 });
const sampleGuide = s.line({ from: [sampleX, 0.98], to: [sampleX, 0.18], color: p.gold, width: 2 });
const sampleLabel = s.text({
    text: "sample p  ·  t = 0.35",
    point: [sampleX + 0.18, 0.63],
    align: [0, 0.5],
    font: "Pretendard",
    size: 14,
    fill: p.gold,
});
const resultPanel = s.rectangle({
    center: [0, -0.73],
    size: [12, 2.4],
    corner: 0.15,
    fill: p.panel,
    stroke: p.line,
    width: 2,
});
const resultLabel = s.text({
    text: "RESULT · 32 PIXEL SAMPLES",
    point: [-5.65, 0.22],
    align: [0, 0.5],
    font: "Pretendard",
    size: 13,
    fill: p.muted,
});
const pixelSpace = s.space({
    x: [0, 32, 1],
    y: [0, 5, 1],
    opacity: 0,
    matrix: [0.35, 0, 0, -5.6, 0, 0.27, 0, -1.42, 0, 0, 1, 0, 0, 0, 0, 1],
});
const hex = (n) => Math.round(n).toString(16).padStart(2, "0"),
    patches = [];
for (let x = 0; x < 32; x++) {
    const t = x / 31,
        r = 76 + (255 - 76) * t,
        g = 201 + (107 - 201) * t,
        b = 240 + (107 - 240) * t;
    patches.push({ region: [x, 0, 1, 5], color: "#" + hex(r) + hex(g) + hex(b) });
}
const gradient = pixelSpace.cell({
    origin: [0, 0],
    size: [32, 5],
    mode: "full",
    color: p.panel,
    patches,
    id: "linear-gradient",
});
const mixFormula = s.text({
    text: "color(p) = mix(stop₀, stop₁, t)",
    point: [0, -1.7],
    font: "Pretendard",
    size: 16,
    fill: p.text,
});
const conclusion = s.text({
    text: "one projected scalar t drives every color channel",
    point: [0, -2.52],
    font: "Pretendard",
    size: 17,
    fill: p.green,
});
scene.create([eyebrow, title, subtitle, divider], 0.52, "ease_out", 0.06);
scene.create([mechanism, projection], 0.36, "ease_out", 0.06);
scene.create(direction, 0.62, "ease_out");
scene.create([stops[0], stops[1], stopLabels[0], stopLabels[1]], 0.36, "ease_out", 0.06);
scene.create([sample, sampleGuide, sampleLabel], 0.42, "ease_out", 0.06);
scene.create([resultPanel, resultLabel], 0.38, "ease_out", 0.05);
scene.create(gradient, 1, "linear");
scene.create(mixFormula, 0.32, "ease_out");
scene.create(conclusion, 0.38, "ease_out");
scene.wait(0.7);
return scene;
`,
    },
    {
        id: "sw-radial-gradient",
        title: "SW raster: RadialGradient",
        description: "Relate normalized elliptical distance to the sampled radial color field.",
        category: "ThorVG SW",
        dimension: "2D",
        fonts: PRETENDARD,
        lua: `local p = {
    background = "#0b111a",
    panel = "#101925",
    line = "#2a3a4d",
    text = "#f4f7fb",
    muted = "#94a3b8",
    cyan = "#4cc9f0",
    gold = "#ffd166",
    coral = "#ff6b6b",
    green = "#7bd88f",
    outer = "#25314a",
}
local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    antialiasing = true,
    background = p.background,
    camera = { mode = "fixed", view = "2d", height = 7.4 },
}
local s = scene:space { x = { -6.5, 6.5, 1 }, y = { -3.5, 3.5, 1 }, opacity = 0 }
local eyebrow = s:text {
    text = "THORVG · SOFTWARE RASTERIZER / 04",
    point = { -5.85, 3.28 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = p.muted,
}
local title = s:text {
    text = "Radial gradient sampling",
    point = { -5.85, 2.82 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 30,
    fill = p.text,
}
local subtitle = s:text {
    text = "Normalize distance from the center before interpolating the stops",
    point = { -5.83, 2.34 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 15,
    fill = p.muted,
}
local divider = s:line { from = { -5.85, 2.08 }, to = { 5.85, 2.08 }, color = p.line, width = 2 }
local panels = {
    s:rectangle {
        center = { -3.1, -0.3 },
        size = { 5.65, 4.2 },
        corner = 0.15,
        fill = p.panel,
        stroke = p.line,
        width = 2,
    },
    s:rectangle {
        center = { 3.1, -0.3 },
        size = { 5.65, 4.2 },
        corner = 0.15,
        fill = p.panel,
        stroke = p.line,
        width = 2,
    },
}
local panelTitles = {
    s:text {
        text = "MECHANISM · NORMALIZED DISTANCE",
        point = { -5.62, 1.48 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 13,
        fill = p.muted,
    },
    s:text {
        text = "RESULT · COLOR FIELD",
        point = { 0.58, 1.48 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 13,
        fill = p.muted,
    },
}
local center = { -3.15, -0.38 }
local function ellipse(rx, ry, color, width)
    local points = {}
    for i = 0, 64 do
        local a = i * math.pi * 2 / 64
        points[#points + 1] = { center[1] + rx * math.cos(a), center[2] + ry * math.sin(a) }
    end
    return s:plot { points = points, color = color, width = width, layer = 2 }
end
local rings =
    { ellipse(2.25, 1.35, p.line, 2), ellipse(1.5, 0.9, p.cyan, 2), ellipse(0.75, 0.45, p.gold, 2) }
local centerPoint = s:point { point = center, fill = p.gold, radius = 7, layer = 6 }
local samplePoint = { -1.42, 0.34 }
local radius = s:arrow {
    from = center,
    to = samplePoint,
    tip = 11,
    color = p.coral,
    width = 3,
    id = "radial-distance",
}
local sample = s:point { point = samplePoint, fill = p.coral, radius = 6, layer = 6 }
local guideLabels = {
    s:text { text = "c", point = { -3.42, -0.67 }, font = "Pretendard", size = 15, fill = p.gold },
    s:text { text = "p", point = { -1.2, 0.52 }, font = "Pretendard", size = 15, fill = p.coral },
    s:text {
        text = "t = length((p - c) / radius)",
        point = { -3.1, -2.08 },
        font = "Pretendard",
        size = 17,
        fill = p.text,
    },
}
local pixelSpace = s:space {
    x = { 0, 24, 1 },
    y = { 0, 16, 1 },
    opacity = 0,
    matrix = { 0.18, 0, 0, 0.94, 0, 0.18, 0, -1.75, 0, 0, 1, 0, 0, 0, 0, 1 },
}
local patches = {}
for y = 0, 15 do
    for x = 0, 23 do
        local dx = (x - 11.5) / 11.5
        local dy = (y - 7.5) / 7.5
        local t = math.min(1, math.sqrt(dx * dx + dy * dy))
        local r = math.floor(255 + (37 - 255) * t + 0.5)
        local g = math.floor(209 + (49 - 209) * t + 0.5)
        local b = math.floor(102 + (74 - 102) * t + 0.5)
        patches[#patches + 1] =
            { region = { x, y, 1, 1 }, color = string.format("#%02x%02x%02x", r, g, b) }
    end
end
local gradient = pixelSpace:cell {
    origin = { 0, 0 },
    size = { 24, 16 },
    mode = "full",
    color = p.outer,
    patches = patches,
    id = "radial-gradient",
}
local colorFormula = s:text {
    text = "color(p) = mix(center, outer, clamp(t, 0, 1))",
    point = { 3.1, -2.08 },
    font = "Pretendard",
    size = 14,
    fill = p.text,
}
local conclusion = s:text {
    text = "RESULT  ·  equal normalized distance produces equal color",
    point = { 0, -2.92 },
    font = "Pretendard",
    size = 17,
    fill = p.green,
}
local note = s:text {
    text = "ellipse radii scale x and y independently",
    point = { 0, -3.27 },
    font = "Pretendard",
    size = 13,
    fill = p.muted,
}
scene:create({ eyebrow, title, subtitle, divider }, 0.52, "ease_out", 0.06)
scene:create(panels, 0.42, "ease_out", 0.08)
scene:create(panelTitles, 0.3, "ease_out", 0.08)
scene:create(rings, 0.68, "ease_out", 0.08)
scene:create(centerPoint, 0.24, "ease_out")
scene:create({ radius, sample }, 0.48, "ease_out", 0.07)
scene:create(guideLabels, 0.36, "ease_out", 0.06)
scene:create(gradient, 1.1, "linear")
scene:create(colorFormula, 0.34, "ease_out")
scene:create({ conclusion, note }, 0.42, "ease_out", 0.07)
scene:wait(0.7)
return scene
`,
        js: `const p = {
    background: "#0b111a",
    panel: "#101925",
    line: "#2a3a4d",
    text: "#f4f7fb",
    muted: "#94a3b8",
    cyan: "#4cc9f0",
    gold: "#ffd166",
    coral: "#ff6b6b",
    green: "#7bd88f",
    outer: "#25314a",
};
const scene = tmath.scene({
    width: 960,
    height: 540,
    fps: 30,
    antialiasing: true,
    background: p.background,
    camera: { mode: "fixed", view: "2d", height: 7.4 },
});
const s = scene.space({ x: [-6.5, 6.5, 1], y: [-3.5, 3.5, 1], opacity: 0 });
const eyebrow = s.text({
    text: "THORVG · SOFTWARE RASTERIZER / 04",
    point: [-5.85, 3.28],
    align: [0, 0.5],
    font: "Pretendard",
    size: 13,
    fill: p.muted,
});
const title = s.text({
    text: "Radial gradient sampling",
    point: [-5.85, 2.82],
    align: [0, 0.5],
    font: "Pretendard",
    size: 30,
    fill: p.text,
});
const subtitle = s.text({
    text: "Normalize distance from the center before interpolating the stops",
    point: [-5.83, 2.34],
    align: [0, 0.5],
    font: "Pretendard",
    size: 15,
    fill: p.muted,
});
const divider = s.line({ from: [-5.85, 2.08], to: [5.85, 2.08], color: p.line, width: 2 });
const panels = [
    s.rectangle({
        center: [-3.1, -0.3],
        size: [5.65, 4.2],
        corner: 0.15,
        fill: p.panel,
        stroke: p.line,
        width: 2,
    }),
    s.rectangle({
        center: [3.1, -0.3],
        size: [5.65, 4.2],
        corner: 0.15,
        fill: p.panel,
        stroke: p.line,
        width: 2,
    }),
];
const panelTitles = [
    s.text({
        text: "MECHANISM · NORMALIZED DISTANCE",
        point: [-5.62, 1.48],
        align: [0, 0.5],
        font: "Pretendard",
        size: 13,
        fill: p.muted,
    }),
    s.text({
        text: "RESULT · COLOR FIELD",
        point: [0.58, 1.48],
        align: [0, 0.5],
        font: "Pretendard",
        size: 13,
        fill: p.muted,
    }),
];
const center = [-3.15, -0.38],
    ellipse = (rx, ry, color, width) =>
        s.plot({
            points: Array.from({ length: 65 }, (_, i) => {
                const a = (i * Math.PI * 2) / 64;
                return [center[0] + rx * Math.cos(a), center[1] + ry * Math.sin(a)];
            }),
            color,
            width,
            layer: 2,
        });
const rings = [
    ellipse(2.25, 1.35, p.line, 2),
    ellipse(1.5, 0.9, p.cyan, 2),
    ellipse(0.75, 0.45, p.gold, 2),
];
const centerPoint = s.point({ point: center, fill: p.gold, radius: 7, layer: 6 }),
    samplePoint = [-1.42, 0.34];
const radius = s.arrow({
    from: center,
    to: samplePoint,
    tip: 11,
    color: p.coral,
    width: 3,
    id: "radial-distance",
});
const sample = s.point({ point: samplePoint, fill: p.coral, radius: 6, layer: 6 });
const guideLabels = [
    s.text({ text: "c", point: [-3.42, -0.67], font: "Pretendard", size: 15, fill: p.gold }),
    s.text({ text: "p", point: [-1.2, 0.52], font: "Pretendard", size: 15, fill: p.coral }),
    s.text({
        text: "t = length((p - c) / radius)",
        point: [-3.1, -2.08],
        font: "Pretendard",
        size: 17,
        fill: p.text,
    }),
];
const pixelSpace = s.space({
    x: [0, 24, 1],
    y: [0, 16, 1],
    opacity: 0,
    matrix: [0.18, 0, 0, 0.94, 0, 0.18, 0, -1.75, 0, 0, 1, 0, 0, 0, 0, 1],
});
const hex = (n) => Math.round(n).toString(16).padStart(2, "0"),
    patches = [];
for (let y = 0; y < 16; y++)
    for (let x = 0; x < 24; x++) {
        const dx = (x - 11.5) / 11.5,
            dy = (y - 7.5) / 7.5,
            t = Math.min(1, Math.hypot(dx, dy));
        patches.push({
            region: [x, y, 1, 1],
            color:
                "#" +
                hex(255 + (37 - 255) * t) +
                hex(209 + (49 - 209) * t) +
                hex(102 + (74 - 102) * t),
        });
    }
const gradient = pixelSpace.cell({
    origin: [0, 0],
    size: [24, 16],
    mode: "full",
    color: p.outer,
    patches,
    id: "radial-gradient",
});
const colorFormula = s.text({
    text: "color(p) = mix(center, outer, clamp(t, 0, 1))",
    point: [3.1, -2.08],
    font: "Pretendard",
    size: 14,
    fill: p.text,
});
const conclusion = s.text({
    text: "RESULT  ·  equal normalized distance produces equal color",
    point: [0, -2.92],
    font: "Pretendard",
    size: 17,
    fill: p.green,
});
const note = s.text({
    text: "ellipse radii scale x and y independently",
    point: [0, -3.27],
    font: "Pretendard",
    size: 13,
    fill: p.muted,
});
scene.create([eyebrow, title, subtitle, divider], 0.52, "ease_out", 0.06);
scene.create(panels, 0.42, "ease_out", 0.08);
scene.create(panelTitles, 0.3, "ease_out", 0.08);
scene.create(rings, 0.68, "ease_out", 0.08);
scene.create(centerPoint, 0.24, "ease_out");
scene.create([radius, sample], 0.48, "ease_out", 0.07);
scene.create(guideLabels, 0.36, "ease_out", 0.06);
scene.create(gradient, 1.1, "linear");
scene.create(colorFormula, 0.34, "ease_out");
scene.create([conclusion, note], 0.42, "ease_out", 0.07);
scene.wait(0.7);
return scene;
`,
    },
    {
        id: "bezier-calculus",
        title: "Bézier interpolation and derivative",
        description:
            "Build de Casteljau's two interpolation levels, locate B(0.62), and match its derivative to the tangent.",
        category: "Curves",
        dimension: "2D",
        fonts: PRETENDARD,
        lua: `local p = {
    bg = "#0b111a",
    grid = "#263447",
    axis = "#66758a",
    text = "#f4f7fb",
    muted = "#94a3b8",
    control = "#66758a",
    curve = "#4cc9f0",
    l1 = "#7bd88f",
    l2 = "#ffd166",
    derivative = "#ff6b6b",
}
local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    background = p.bg,
    camera = { mode = "interactive", view = "2d", target = { 0, 0.1 }, height = 7.6 },
}
local space = scene:space {
    x = { -6, 6, 1 },
    y = { -3, 4, 1 },
    numbers = false,
    color = p.grid,
    axis_x = p.axis,
    axis_y = p.axis,
}
local p0, p1, p2, p3 = { -4.7, -1.7 }, { -2.4, 2.15 }, { 2.1, 2.0 }, { 4.65, -1.35 }
local function mix(a, b, t)
    return { a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t }
end
local controls = {
    space:line { from = p0, to = p1, color = p.control, width = 2 },
    space:line { from = p1, to = p2, color = p.control, width = 2 },
    space:line { from = p2, to = p3, color = p.control, width = 2 },
}
local controlPoints = {
    space:point { point = p0, fill = p.text, radius = 6 },
    space:point { point = p1, fill = p.text, radius = 6 },
    space:point { point = p2, fill = p.text, radius = 6 },
    space:point { point = p3, fill = p.text, radius = 6 },
}
local u = 0.62
local a, b, c = mix(p0, p1, u), mix(p1, p2, u), mix(p2, p3, u)
local d, e = mix(a, b, u), mix(b, c, u)
local q = mix(d, e, u)
local level1 = {
    space:line { from = a, to = b, color = p.l1, width = 3 },
    space:line { from = b, to = c, color = p.l1, width = 3 },
    space:point { point = a, fill = p.l1, radius = 5 },
    space:point { point = b, fill = p.l1, radius = 5 },
    space:point { point = c, fill = p.l1, radius = 5 },
}
local level2 = {
    space:line { from = d, to = e, color = p.l2, width = 4 },
    space:point { point = d, fill = p.l2, radius = 6 },
    space:point { point = e, fill = p.l2, radius = 6 },
}
local curvePoints = {}
for i = 0, 100 do
    local t = i / 100
    local o = 1 - t
    curvePoints[#curvePoints + 1] = {
        o ^ 3 * p0[1] + 3 * o ^ 2 * t * p1[1] + 3 * o * t ^ 2 * p2[1] + t ^ 3 * p3[1],
        o ^ 3 * p0[2] + 3 * o ^ 2 * t * p1[2] + 3 * o * t ^ 2 * p2[2] + t ^ 3 * p3[2],
    }
end
local curve = space:plot { points = curvePoints, color = p.curve, width = 5 }
local o = 1 - u
local derivative = {
    3 * (o ^ 2 * (p1[1] - p0[1]) + 2 * o * u * (p2[1] - p1[1]) + u ^ 2 * (p3[1] - p2[1])),
    3 * (o ^ 2 * (p1[2] - p0[2]) + 2 * o * u * (p2[2] - p1[2]) + u ^ 2 * (p3[2] - p2[2])),
}
local tangent = space:vector {
    origin = q,
    value = { derivative[1] * 0.32, derivative[2] * 0.32 },
    color = p.derivative,
    width = 4,
    tip = 13,
}
local point = space:point { point = q, fill = p.derivative, radius = 8, layer = 5 }
local heading = space:text {
    text = "DE CASTELJAU  ·  t = 0.62",
    point = { -5.72, 3.34 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 15,
    fill = p.muted,
}
local l1Label = space:text {
    text = "A, B, C : first lerp",
    point = { 0.45, 3.34 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 16,
    fill = p.l1,
}
local l2Label = space:text {
    text = "D, E : second lerp",
    point = { 0.45, 2.96 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 16,
    fill = p.l2,
}
local pointLabel = space:text {
    text = "Q = B(0.62)",
    point = { q[1] - 1.08, q[2] + 0.36 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 16,
    fill = p.derivative,
}
local curveLabel = space:text {
    text = "B(t)",
    point = { 4.75, -0.92 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 18,
    fill = p.curve,
}
local conclusion = space:text {
    text = "interpolation -> Q",
    point = { -5.72, -2.56 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 15,
    fill = p.muted,
}
local tangentLabel = space:text {
    text = "B′(0.62) = tangent direction",
    point = { 0.78, -2.56 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 19,
    fill = p.derivative,
}
scene:create(space, 0.40, "ease_out")
scene:create(controls, 0.58, "linear", 0.07)
scene:create(controlPoints, 0.30, "ease_out", 0.04)
scene:create(heading, 0.30, "ease_out")
scene:create(level1, 0.55, "ease_out", 0.05)
scene:create(l1Label, 0.28, "ease_out")
scene:create(level2, 0.48, "ease_out", 0.05)
scene:create(l2Label, 0.28, "ease_out")
scene:create(point, 0.28, "ease_out")
scene:create({ pointLabel, curve }, 1.05, "ease_in_out", 0.08)
scene:create({ tangent, curveLabel }, 0.62, "ease_out", 0.08)
scene:create({ conclusion, tangentLabel }, 0.42, "ease_out", 0.08)
scene:wait(0.72)
return scene
`,
        js: `const p = {
    bg: "#0b111a",
    grid: "#263447",
    axis: "#66758a",
    text: "#f4f7fb",
    muted: "#94a3b8",
    control: "#66758a",
    curve: "#4cc9f0",
    l1: "#7bd88f",
    l2: "#ffd166",
    derivative: "#ff6b6b",
};
const scene = tmath.scene({
    width: 960,
    height: 540,
    fps: 30,
    background: p.bg,
    camera: { mode: "interactive", view: "2d", target: [0, 0.1], height: 7.6 },
});
const space = scene.space({
    x: [-6, 6, 1],
    y: [-3, 4, 1],
    numbers: false,
    color: p.grid,
    axis_x: p.axis,
    axis_y: p.axis,
});
const p0 = [-4.7, -1.7],
    p1 = [-2.4, 2.15],
    p2 = [2.1, 2.0],
    p3 = [4.65, -1.35];
const controls = [
    space.line({ from: p0, to: p1, color: p.control, width: 2 }),
    space.line({ from: p1, to: p2, color: p.control, width: 2 }),
    space.line({ from: p2, to: p3, color: p.control, width: 2 }),
];
const controlPoints = [
    space.point({ point: p0, fill: p.text, radius: 6 }),
    space.point({ point: p1, fill: p.text, radius: 6 }),
    space.point({ point: p2, fill: p.text, radius: 6 }),
    space.point({ point: p3, fill: p.text, radius: 6 }),
];
const mix = (a, b, t) => [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t],
    u = 0.62;
const a = mix(p0, p1, u),
    b = mix(p1, p2, u),
    c = mix(p2, p3, u),
    d = mix(a, b, u),
    e = mix(b, c, u),
    q = mix(d, e, u);
const level1 = [
    space.line({ from: a, to: b, color: p.l1, width: 3 }),
    space.line({ from: b, to: c, color: p.l1, width: 3 }),
    space.point({ point: a, fill: p.l1, radius: 5 }),
    space.point({ point: b, fill: p.l1, radius: 5 }),
    space.point({ point: c, fill: p.l1, radius: 5 }),
];
const level2 = [
    space.line({ from: d, to: e, color: p.l2, width: 4 }),
    space.point({ point: d, fill: p.l2, radius: 6 }),
    space.point({ point: e, fill: p.l2, radius: 6 }),
];
const curvePoints = Array.from({ length: 101 }, (_, i) => {
    const t = i / 100,
        o = 1 - t;
    return [
        o ** 3 * p0[0] + 3 * o ** 2 * t * p1[0] + 3 * o * t ** 2 * p2[0] + t ** 3 * p3[0],
        o ** 3 * p0[1] + 3 * o ** 2 * t * p1[1] + 3 * o * t ** 2 * p2[1] + t ** 3 * p3[1],
    ];
});
const curve = space.plot({ points: curvePoints, color: p.curve, width: 5 }),
    o = 1 - u;
const derivative = [
    3 * (o ** 2 * (p1[0] - p0[0]) + 2 * o * u * (p2[0] - p1[0]) + u ** 2 * (p3[0] - p2[0])),
    3 * (o ** 2 * (p1[1] - p0[1]) + 2 * o * u * (p2[1] - p1[1]) + u ** 2 * (p3[1] - p2[1])),
];
const tangent = space.vector({
    origin: q,
    value: [derivative[0] * 0.32, derivative[1] * 0.32],
    color: p.derivative,
    width: 4,
    tip: 13,
});
const point = space.point({ point: q, fill: p.derivative, radius: 8, layer: 5 });
const heading = space.text({
    text: "DE CASTELJAU  ·  t = 0.62",
    point: [-5.72, 3.34],
    align: [0, 0.5],
    font: "Pretendard",
    size: 15,
    fill: p.muted,
});
const l1Label = space.text({
    text: "A, B, C : first lerp",
    point: [0.45, 3.34],
    align: [0, 0.5],
    font: "Pretendard",
    size: 16,
    fill: p.l1,
});
const l2Label = space.text({
    text: "D, E : second lerp",
    point: [0.45, 2.96],
    align: [0, 0.5],
    font: "Pretendard",
    size: 16,
    fill: p.l2,
});
const pointLabel = space.text({
    text: "Q = B(0.62)",
    point: [q[0] - 1.08, q[1] + 0.36],
    align: [0, 0.5],
    font: "Pretendard",
    size: 16,
    fill: p.derivative,
});
const curveLabel = space.text({
    text: "B(t)",
    point: [4.75, -0.92],
    align: [0, 0.5],
    font: "Pretendard",
    size: 18,
    fill: p.curve,
});
const conclusion = space.text({
    text: "interpolation -> Q",
    point: [-5.72, -2.56],
    align: [0, 0.5],
    font: "Pretendard",
    size: 15,
    fill: p.muted,
});
const tangentLabel = space.text({
    text: "B′(0.62) = tangent direction",
    point: [0.78, -2.56],
    align: [0, 0.5],
    font: "Pretendard",
    size: 19,
    fill: p.derivative,
});
scene.create(space, 0.4, "ease_out");
scene.create(controls, 0.58, "linear", 0.07);
scene.create(controlPoints, 0.3, "ease_out", 0.04);
scene.create(heading, 0.3, "ease_out");
scene.create(level1, 0.55, "ease_out", 0.05);
scene.create(l1Label, 0.28, "ease_out");
scene.create(level2, 0.48, "ease_out", 0.05);
scene.create(l2Label, 0.28, "ease_out");
scene.create(point, 0.28, "ease_out");
scene.create([pointLabel, curve], 1.05, "ease_in_out", 0.08);
scene.create([tangent, curveLabel], 0.62, "ease_out", 0.08);
scene.create([conclusion, tangentLabel], 0.42, "ease_out", 0.08);
scene.wait(0.72);
return scene;
`,
    },
    {
        id: "vector-operations",
        title: "Vector operations in four Viewports",
        description:
            "Compare operands first, then reveal the color-matched result for addition, subtraction, scaling, and negation.",
        category: "Vectors",
        dimension: "2D",
        fonts: PRETENDARD,
        lua: `local p = {
    bg = "#0b111a",
    panelA = "#101925",
    panelB = "#0f1722",
    grid = "#263447",
    axis = "#66758a",
    text = "#f4f7fb",
    muted = "#94a3b8",
    a = "#4cc9f0",
    b = "#f72585",
    result = "#ffd166",
    related = "#7bd88f",
}
local function panel(index, title, background)
    local child = tmath.scene {
        width = 480,
        height = 270,
        fps = 30,
        background = background,
        camera = { mode = "fixed", view = "2d", height = 6.4 },
    }
    local space = child:space {
        x = { -5.3, 5.3, 1 },
        y = { -2.05, 2.05, 1 },
        color = p.grid,
        axis_x = p.axis,
        axis_y = p.axis,
    }
    local step = space:text {
        text = index,
        point = { -5.02, 2.72 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 14,
        fill = p.muted,
    }
    local heading = space:text {
        text = title,
        point = { -4.32, 2.72 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 19,
        fill = p.text,
    }
    return child, space, { step, heading }
end
local function label(space, text, x, color)
    return space:text {
        text = text,
        point = { x, -2.62 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 15,
        fill = color,
    }
end
local function start(child, space, heading)
    child:create(space, 0.38, "ease_out")
    child:create(heading, 0.24, "ease_out", 0.04)
end

local add, as, at = panel("01", "Addition", p.panelA)
local aa = as:vector { value = { 2, 1 }, color = "#4cc9f0", width = 4, tip = 13 }
local ab =
    as:vector { origin = { 2, 1 }, value = { -0.75, 1.25 }, color = "#f72585", width = 4, tip = 13 }
local ar = as:vector { value = { 1.25, 2.25 }, color = "#ffd166", width = 5, tip = 15 }
start(add, as, at)
add:create({ aa, ab }, 0.62, "ease_out", 0.08)
add:create(
    { label(as, "a = (2, 1)", -5.02, p.a), label(as, "b = (-.75, 1.25)", -2.65, p.b) },
    0.30,
    "ease_out",
    0.04
)
add:create(ar, 0.58, "ease_out")
add:create(label(as, "a + b = (1.25, 2.25)", 0.68, p.result), 0.32, "ease_out")
add:wait(0.5)

local sub, ss, st = panel("02", "Subtraction", p.panelB)
local sa = ss:vector { value = { 2, 1 }, color = "#4cc9f0", width = 4, tip = 13 }
local sn =
    ss:vector { origin = { 2, 1 }, value = { 0.75, -1.25 }, color = "#f72585", width = 4, tip = 13 }
local sr = ss:vector { value = { 2.75, -0.25 }, color = "#ffd166", width = 5, tip = 15 }
start(sub, ss, st)
sub:create({ sa, sn }, 0.62, "ease_out", 0.08)
sub:create(
    { label(ss, "a = (2, 1)", -5.02, p.a), label(ss, "-b = (.75, -1.25)", -2.65, p.b) },
    0.30,
    "ease_out",
    0.04
)
sub:create(sr, 0.58, "ease_out")
sub:create(label(ss, "a - b = (2.75, -.25)", 0.68, p.result), 0.32, "ease_out")
sub:wait(0.5)

local scale, ks, kt = panel("03", "Scalar multiplication", p.panelB)
local kh =
    ks:vector { origin = { -3, 1 }, value = { 0.7, 0.45 }, color = "#7bd88f", width = 3, tip = 11 }
local kv = ks:vector {
    origin = { -3, -0.1 },
    value = { 1.4, 0.9 },
    color = "#4cc9f0",
    width = 4,
    tip = 13,
}
local kd = ks:vector {
    origin = { -2.4, -1.4 },
    value = { 2.8, 1.8 },
    color = "#ffd166",
    width = 5,
    tip = 15,
}
start(scale, ks, kt)
scale:create(kv, 0.62, "ease_out")
scale:create(label(ks, "v = (1.4, .9)", -5.02, p.a), 0.30, "ease_out")
scale:create({ kh, kd }, 0.58, "ease_out", 0.08)
scale:create({
    label(ks, "0.5v", -2.22, p.related),
    label(ks, "2v", -0.82, p.result),
    label(ks, "|kv| = |k||v|", 0.38, p.text),
}, 0.32, "ease_out", 0.04)
scale:wait(0.5)

local neg, ns, nt = panel("04", "Negation and cancellation", p.panelA)
local nv = ns:vector { value = { 2.2, 1.25 }, color = "#4cc9f0", width = 4, tip = 13 }
local nn = ns:vector { value = { -2.2, -1.25 }, color = "#f72585", width = 4, tip = 13 }
local nc = ns:vector {
    origin = { 2.2, 1.25 },
    value = { -2.2, -1.25 },
    color = "#ffd166",
    width = 3,
    tip = 11,
}
start(neg, ns, nt)
neg:create({ nv, nn }, 0.62, "ease_out", 0.08)
neg:create(
    { label(ns, "v = (2.2, 1.25)", -5.02, p.a), label(ns, "-v = (-2.2, -1.25)", -2.02, p.b) },
    0.30,
    "ease_out",
    0.04
)
neg:create(nc, 0.58, "ease_out")
neg:create(label(ns, "v + (-v) = 0", 1.48, p.result), 0.32, "ease_out")
neg:wait(0.5)

local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    background = p.bg,
    camera = { mode = "fixed", view = "2d", height = 6 },
}
scene:viewport(add, { x = 0, y = 0, width = 0.5, height = 0.5 })
scene:viewport(sub, { x = 0.5, y = 0, width = 0.5, height = 0.5 })
scene:viewport(scale, { x = 0, y = 0.5, width = 0.5, height = 0.5 })
scene:viewport(neg, { x = 0.5, y = 0.5, width = 0.5, height = 0.5 })
return scene
`,
        js: `const p = {
    bg: "#0b111a",
    panelA: "#101925",
    panelB: "#0f1722",
    grid: "#263447",
    axis: "#66758a",
    text: "#f4f7fb",
    muted: "#94a3b8",
    a: "#4cc9f0",
    b: "#f72585",
    result: "#ffd166",
    related: "#7bd88f",
};
const panel = (index, title, background) => {
    const child = tmath.scene({
        width: 480,
        height: 270,
        fps: 30,
        background,
        camera: { mode: "fixed", view: "2d", height: 6.4 },
    });
    const space = child.space({
        x: [-5.3, 5.3, 1],
        y: [-2.05, 2.05, 1],
        color: p.grid,
        axis_x: p.axis,
        axis_y: p.axis,
    });
    const step = space.text({
        text: index,
        point: [-5.02, 2.72],
        align: [0, 0.5],
        font: "Pretendard",
        size: 14,
        fill: p.muted,
    });
    const heading = space.text({
        text: title,
        point: [-4.32, 2.72],
        align: [0, 0.5],
        font: "Pretendard",
        size: 19,
        fill: p.text,
    });
    return [child, space, [step, heading]];
};
const label = (space, text, x, color) =>
    space.text({
        text,
        point: [x, -2.62],
        align: [0, 0.5],
        font: "Pretendard",
        size: 15,
        fill: color,
    });
const start = (child, space, heading) => {
    child.create(space, 0.38, "ease_out");
    child.create(heading, 0.24, "ease_out", 0.04);
};

const [add, as, at] = panel("01", "Addition", p.panelA);
const aa = as.vector({ value: [2, 1], color: "#4cc9f0", width: 4, tip: 13 });
const ab = as.vector({ origin: [2, 1], value: [-0.75, 1.25], color: "#f72585", width: 4, tip: 13 });
const ar = as.vector({ value: [1.25, 2.25], color: "#ffd166", width: 5, tip: 15 });
start(add, as, at);
add.create([aa, ab], 0.62, "ease_out", 0.08);
add.create(
    [label(as, "a = (2, 1)", -5.02, p.a), label(as, "b = (-.75, 1.25)", -2.65, p.b)],
    0.3,
    "ease_out",
    0.04,
);
add.create(ar, 0.58, "ease_out");
add.create(label(as, "a + b = (1.25, 2.25)", 0.68, p.result), 0.32, "ease_out");
add.wait(0.5);

const [sub, ss, st] = panel("02", "Subtraction", p.panelB);
const sa = ss.vector({ value: [2, 1], color: "#4cc9f0", width: 4, tip: 13 });
const sn = ss.vector({ origin: [2, 1], value: [0.75, -1.25], color: "#f72585", width: 4, tip: 13 });
const sr = ss.vector({ value: [2.75, -0.25], color: "#ffd166", width: 5, tip: 15 });
start(sub, ss, st);
sub.create([sa, sn], 0.62, "ease_out", 0.08);
sub.create(
    [label(ss, "a = (2, 1)", -5.02, p.a), label(ss, "-b = (.75, -1.25)", -2.65, p.b)],
    0.3,
    "ease_out",
    0.04,
);
sub.create(sr, 0.58, "ease_out");
sub.create(label(ss, "a - b = (2.75, -.25)", 0.68, p.result), 0.32, "ease_out");
sub.wait(0.5);

const [scale, ks, kt] = panel("03", "Scalar multiplication", p.panelB);
const kh = ks.vector({ origin: [-3, 1], value: [0.7, 0.45], color: "#7bd88f", width: 3, tip: 11 });
const kv = ks.vector({
    origin: [-3, -0.1],
    value: [1.4, 0.9],
    color: "#4cc9f0",
    width: 4,
    tip: 13,
});
const kd = ks.vector({
    origin: [-2.4, -1.4],
    value: [2.8, 1.8],
    color: "#ffd166",
    width: 5,
    tip: 15,
});
start(scale, ks, kt);
scale.create(kv, 0.62, "ease_out");
scale.create(label(ks, "v = (1.4, .9)", -5.02, p.a), 0.3, "ease_out");
scale.create([kh, kd], 0.58, "ease_out", 0.08);
scale.create(
    [
        label(ks, "0.5v", -2.22, p.related),
        label(ks, "2v", -0.82, p.result),
        label(ks, "|kv| = |k||v|", 0.38, p.text),
    ],
    0.32,
    "ease_out",
    0.04,
);
scale.wait(0.5);

const [neg, ns, nt] = panel("04", "Negation and cancellation", p.panelA);
const nv = ns.vector({ value: [2.2, 1.25], color: "#4cc9f0", width: 4, tip: 13 });
const nn = ns.vector({ value: [-2.2, -1.25], color: "#f72585", width: 4, tip: 13 });
const nc = ns.vector({
    origin: [2.2, 1.25],
    value: [-2.2, -1.25],
    color: "#ffd166",
    width: 3,
    tip: 11,
});
start(neg, ns, nt);
neg.create([nv, nn], 0.62, "ease_out", 0.08);
neg.create(
    [label(ns, "v = (2.2, 1.25)", -5.02, p.a), label(ns, "-v = (-2.2, -1.25)", -2.02, p.b)],
    0.3,
    "ease_out",
    0.04,
);
neg.create(nc, 0.58, "ease_out");
neg.create(label(ns, "v + (-v) = 0", 1.48, p.result), 0.32, "ease_out");
neg.wait(0.5);

const scene = tmath.scene({
    width: 960,
    height: 540,
    fps: 30,
    background: p.bg,
    camera: { mode: "fixed", view: "2d", height: 6 },
});
scene.viewport(add, { x: 0, y: 0, width: 0.5, height: 0.5 });
scene.viewport(sub, { x: 0.5, y: 0, width: 0.5, height: 0.5 });
scene.viewport(scale, { x: 0, y: 0.5, width: 0.5, height: 0.5 });
scene.viewport(neg, { x: 0.5, y: 0.5, width: 0.5, height: 0.5 });
return scene;
`,
    },
    {
        id: "vector-dot-cross",
        title: "Dot and cross products in 2D / 3D",
        description:
            "Compare projection, signed area, and the perpendicular 3D result with one semantic color map across four Viewports.",
        category: "Vectors",
        dimension: "2D / 3D",
        fonts: PRETENDARD,
        lua: `local p = {
    bg = "#0b111a",
    panelA = "#101925",
    panelB = "#0f1722",
    grid = "#263447",
    axis = "#66758a",
    text = "#f4f7fb",
    a = "#4cc9f0",
    b = "#f72585",
    result = "#ffd166",
    relation = "#7bd88f",
    residual = "#ff6b6b",
}
local function panel2d(title, background)
    local child = tmath.scene {
        width = 480,
        height = 270,
        fps = 30,
        background = background,
        camera = { mode = "fixed", view = "2d", height = 6.4 },
    }
    local space = child:space {
        x = { -5.3, 5.3, 1 },
        y = { -2.05, 2.05, 1 },
        color = p.grid,
        axis_x = p.axis,
        axis_y = p.axis,
    }
    local heading = space:text {
        text = title,
        point = { -5.02, 2.72 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 19,
        fill = p.text,
    }
    return child, space, heading
end
local function panel3d(title, background)
    local child = tmath.scene {
        width = 480,
        height = 270,
        fps = 30,
        background = background,
        camera = {
            mode = "fixed",
            view = "3d",
            eye = { 6, 5, 7 },
            target = { 0, 0, 0 },
            up = { 0, 1, 0 },
            projection = "orthographic",
            height = 6.4,
            near = 0.1,
            far = 100,
        },
    }
    local space = child:space {
        x = { -2.25, 2.25, 1 },
        y = { -2.25, 2.25, 1 },
        z = { -2.25, 2.25, 1 },
        color = p.grid,
        axis_x = p.axis,
        axis_y = p.axis,
        axis_z = p.axis,
    }
    local heading = space:text {
        text = title,
        point = { -4.55, 2.45, 1.7 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 18,
        fill = p.text,
    }
    return child, space, heading
end
local function label2d(space, text, x, color)
    return space:text {
        text = text,
        point = { x, -2.62 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 15,
        fill = color,
    }
end

local d2, s2, t2 = panel2d("01  2D dot · projection", p.panelA)
local d2a = s2:vector { value = { 2, 3 }, color = "#4cc9f0", width = 5, tip = 14 }
local d2b = s2:vector { value = { 2, 1 }, color = "#f72585", width = 4, tip = 13 }
local d2p = s2:vector { value = { 2.8, 1.4 }, color = "#7bd88f", width = 4, tip = 13 }
local d2r = s2:line { from = { 2.8, 1.4 }, to = { 2, 3 }, color = "#ef5350", width = 3 }
local d2f = {
    label2d(s2, "a = (2, 3)", -5.02, p.a),
    label2d(s2, "b = (2, 1)", -3.02, p.b),
    label2d(s2, "a · b = 7", 1.2, p.result),
}
d2:create({ s2, t2 }, 0.42, "ease_out")
d2:create({ d2a, d2b }, 0.62, "ease_out", 0.08)
d2:create({ d2p, d2r }, 0.58, "ease_out", 0.08)
d2:create(d2f, 0.34, "ease_out", 0.04)
d2:wait(0.5)

local c2, cs2, ct2 = panel2d("02  2D cross · signed area", p.panelB)
local c2area = cs2:polygon {
    points = { { 0, 0 }, { 3, 1 }, { 4, 3 }, { 1, 2 } },
    fill = "#7bd88f3f",
    stroke = "#7bd88f",
    width = 2,
}
local c2a = cs2:vector { value = { 3, 1 }, color = "#4cc9f0", width = 5, tip = 14 }
local c2b = cs2:vector { value = { 1, 2 }, color = "#f72585", width = 4, tip = 13 }
local c2f = {
    label2d(cs2, "a = (3, 1)", -5.02, p.a),
    label2d(cs2, "b = (1, 2)", -3.02, p.b),
    label2d(cs2, "det(a, b) = +5", 0.72, p.relation),
}
c2:create({ cs2, ct2 }, 0.42, "ease_out")
c2:create({ c2a, c2b }, 0.62, "ease_out", 0.08)
c2:create(c2area, 0.58, "ease_out")
c2:create(c2f, 0.34, "ease_out", 0.04)
c2:wait(0.5)

local d3, s3, t3 = panel3d("03  3D dot · projection", p.panelB)
local d3a = s3:vector { value = { 2, 2, 2 }, color = "#4cc9f0", width = 5, tip = 14 }
local d3b = s3:vector { value = { 2, 0, 1 }, color = "#f72585", width = 4, tip = 13 }
local d3p = s3:vector { value = { 2.4, 0, 1.2 }, color = "#7bd88f", width = 4, tip = 13 }
local d3r = s3:line { from = { 2.4, 0, 1.2 }, to = { 2, 2, 2 }, color = "#ef5350", width = 3 }
local d3f = {
    s3:text {
        text = "a",
        point = { 2.15, 2.2, 2.05 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 16,
        fill = "#4cc9f0",
    },
    s3:text {
        text = "b",
        point = { 2.2, 0.15, 1 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 16,
        fill = "#f72585",
    },
    s3:text {
        text = "a · b = 6",
        point = { -4.05, -2.25, 1.7 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 17,
        fill = p.result,
    },
}
d3:create({ s3, t3 }, 0.42, "ease_out")
d3:create({ d3a, d3b }, 0.62, "ease_out", 0.08)
d3:create({ d3p, d3r }, 0.58, "ease_out", 0.08)
d3:create(d3f, 0.34, "ease_out", 0.04)
d3:wait(0.5)

local c3, cs3, ct3 = panel3d("04  3D cross · perpendicular", p.panelA)
local c3plane = cs3:polygon {
    points = { { 0, 0, 0 }, { 1.6, 0.8, 0 }, { 1.6, 1.6, 1.6 }, { 0, 0.8, 1.6 } },
    fill = "#7bd88f35",
    stroke = "#7bd88f",
    width = 2,
}
local c3a = cs3:vector { value = { 1.6, 0.8, 0 }, color = "#4cc9f0", width = 5, tip = 14 }
local c3b = cs3:vector { value = { 0, 0.8, 1.6 }, color = "#f72585", width = 4, tip = 13 }
local c3r = cs3:vector { value = { 1.28, -2.56, 1.28 }, color = "#ffd166", width = 5, tip = 15 }
local c3f = {
    cs3:text {
        text = "a",
        point = { 1.75, 0.95, 0 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 16,
        fill = "#4cc9f0",
    },
    cs3:text {
        text = "b",
        point = { 0, 0.95, 1.75 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 16,
        fill = "#f72585",
    },
    cs3:text {
        text = "span(a, b)",
        point = { 0.65, 1.25, 0.7 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 15,
        fill = p.relation,
    },
    cs3:text {
        text = "a × b = (1.28, -2.56, 1.28)",
        point = { -4.05, -2.25, 1.7 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 16,
        fill = p.result,
    },
}
c3:create({ cs3, ct3 }, 0.42, "ease_out")
c3:create({ c3a, c3b }, 0.62, "ease_out", 0.08)
c3:create(c3plane, 0.58, "ease_out")
c3:create(c3r, 0.48, "ease_out")
c3:create(c3f, 0.34, "ease_out", 0.04)
c3:wait(0.5)

local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    background = p.bg,
    camera = { mode = "fixed", view = "2d", height = 6 },
}
scene:viewport(d2, { x = 0, y = 0, width = 0.5, height = 0.5 })
scene:viewport(c2, { x = 0.5, y = 0, width = 0.5, height = 0.5 })
scene:viewport(d3, { x = 0, y = 0.5, width = 0.5, height = 0.5 })
scene:viewport(c3, { x = 0.5, y = 0.5, width = 0.5, height = 0.5 })
return scene
`,
        js: `const p = {
    bg: "#0b111a",
    panelA: "#101925",
    panelB: "#0f1722",
    grid: "#263447",
    axis: "#66758a",
    text: "#f4f7fb",
    a: "#4cc9f0",
    b: "#f72585",
    result: "#ffd166",
    relation: "#7bd88f",
    residual: "#ff6b6b",
};
const panel2d = (title, background) => {
    const child = tmath.scene({
        width: 480,
        height: 270,
        fps: 30,
        background,
        camera: { mode: "fixed", view: "2d", height: 6.4 },
    });
    const space = child.space({
        x: [-5.3, 5.3, 1],
        y: [-2.05, 2.05, 1],
        color: p.grid,
        axis_x: p.axis,
        axis_y: p.axis,
    });
    const heading = space.text({
        text: title,
        point: [-5.02, 2.72],
        align: [0, 0.5],
        font: "Pretendard",
        size: 19,
        fill: p.text,
    });
    return [child, space, heading];
};
const panel3d = (title, background) => {
    const child = tmath.scene({
        width: 480,
        height: 270,
        fps: 30,
        background,
        camera: {
            mode: "fixed",
            view: "3d",
            eye: [6, 5, 7],
            target: [0, 0, 0],
            up: [0, 1, 0],
            projection: "orthographic",
            height: 6.4,
            near: 0.1,
            far: 100,
        },
    });
    const space = child.space({
        x: [-2.25, 2.25, 1],
        y: [-2.25, 2.25, 1],
        z: [-2.25, 2.25, 1],
        color: p.grid,
        axis_x: p.axis,
        axis_y: p.axis,
        axis_z: p.axis,
    });
    const heading = space.text({
        text: title,
        point: [-4.55, 2.45, 1.7],
        align: [0, 0.5],
        font: "Pretendard",
        size: 18,
        fill: p.text,
    });
    return [child, space, heading];
};
const label2d = (space, text, x, color) =>
    space.text({
        text,
        point: [x, -2.62],
        align: [0, 0.5],
        font: "Pretendard",
        size: 15,
        fill: color,
    });

const [d2, s2, t2] = panel2d("01  2D dot · projection", p.panelA);
const d2a = s2.vector({ value: [2, 3], color: "#4cc9f0", width: 5, tip: 14 });
const d2b = s2.vector({ value: [2, 1], color: "#f72585", width: 4, tip: 13 });
const d2p = s2.vector({ value: [2.8, 1.4], color: "#7bd88f", width: 4, tip: 13 });
const d2r = s2.line({ from: [2.8, 1.4], to: [2, 3], color: "#ef5350", width: 3 });
const d2f = [
    label2d(s2, "a = (2, 3)", -5.02, p.a),
    label2d(s2, "b = (2, 1)", -3.02, p.b),
    label2d(s2, "a · b = 7", 1.2, p.result),
];
d2.create([s2, t2], 0.42, "ease_out").create([d2a, d2b], 0.62, "ease_out", 0.08);
d2.create([d2p, d2r], 0.58, "ease_out", 0.08).create(d2f, 0.34, "ease_out", 0.04).wait(0.5);

const [c2, cs2, ct2] = panel2d("02  2D cross · signed area", p.panelB);
const c2area = cs2.polygon({
    points: [
        [0, 0],
        [3, 1],
        [4, 3],
        [1, 2],
    ],
    fill: "#7bd88f3f",
    stroke: "#7bd88f",
    width: 2,
});
const c2a = cs2.vector({ value: [3, 1], color: "#4cc9f0", width: 5, tip: 14 });
const c2b = cs2.vector({ value: [1, 2], color: "#f72585", width: 4, tip: 13 });
const c2f = [
    label2d(cs2, "a = (3, 1)", -5.02, p.a),
    label2d(cs2, "b = (1, 2)", -3.02, p.b),
    label2d(cs2, "det(a, b) = +5", 0.72, p.relation),
];
c2.create([cs2, ct2], 0.42, "ease_out").create([c2a, c2b], 0.62, "ease_out", 0.08);
c2.create(c2area, 0.58, "ease_out").create(c2f, 0.34, "ease_out", 0.04).wait(0.5);

const [d3, s3, t3] = panel3d("03  3D dot · projection", p.panelB);
const d3a = s3.vector({ value: [2, 2, 2], color: "#4cc9f0", width: 5, tip: 14 });
const d3b = s3.vector({ value: [2, 0, 1], color: "#f72585", width: 4, tip: 13 });
const d3p = s3.vector({ value: [2.4, 0, 1.2], color: "#7bd88f", width: 4, tip: 13 });
const d3r = s3.line({ from: [2.4, 0, 1.2], to: [2, 2, 2], color: "#ef5350", width: 3 });
const d3f = [
    s3.text({
        text: "a",
        point: [2.15, 2.2, 2.05],
        align: [0, 0.5],
        font: "Pretendard",
        size: 16,
        fill: "#4cc9f0",
    }),
    s3.text({
        text: "b",
        point: [2.2, 0.15, 1],
        align: [0, 0.5],
        font: "Pretendard",
        size: 16,
        fill: "#f72585",
    }),
    s3.text({
        text: "a · b = 6",
        point: [-4.05, -2.25, 1.7],
        align: [0, 0.5],
        font: "Pretendard",
        size: 17,
        fill: p.result,
    }),
];
d3.create([s3, t3], 0.42, "ease_out").create([d3a, d3b], 0.62, "ease_out", 0.08);
d3.create([d3p, d3r], 0.58, "ease_out", 0.08).create(d3f, 0.34, "ease_out", 0.04).wait(0.5);

const [c3, cs3, ct3] = panel3d("04  3D cross · perpendicular", p.panelA);
const c3plane = cs3.polygon({
    points: [
        [0, 0, 0],
        [1.6, 0.8, 0],
        [1.6, 1.6, 1.6],
        [0, 0.8, 1.6],
    ],
    fill: "#7bd88f35",
    stroke: "#7bd88f",
    width: 2,
});
const c3a = cs3.vector({ value: [1.6, 0.8, 0], color: "#4cc9f0", width: 5, tip: 14 });
const c3b = cs3.vector({ value: [0, 0.8, 1.6], color: "#f72585", width: 4, tip: 13 });
const c3r = cs3.vector({ value: [1.28, -2.56, 1.28], color: "#ffd166", width: 5, tip: 15 });
const c3f = [
    cs3.text({
        text: "a",
        point: [1.75, 0.95, 0],
        align: [0, 0.5],
        font: "Pretendard",
        size: 16,
        fill: "#4cc9f0",
    }),
    cs3.text({
        text: "b",
        point: [0, 0.95, 1.75],
        align: [0, 0.5],
        font: "Pretendard",
        size: 16,
        fill: "#f72585",
    }),
    cs3.text({
        text: "span(a, b)",
        point: [0.65, 1.25, 0.7],
        align: [0, 0.5],
        font: "Pretendard",
        size: 15,
        fill: p.relation,
    }),
    cs3.text({
        text: "a × b = (1.28, -2.56, 1.28)",
        point: [-4.05, -2.25, 1.7],
        align: [0, 0.5],
        font: "Pretendard",
        size: 16,
        fill: p.result,
    }),
];
c3.create([cs3, ct3], 0.42, "ease_out").create([c3a, c3b], 0.62, "ease_out", 0.08);
c3.create(c3plane, 0.58, "ease_out").create(c3r, 0.48, "ease_out");
c3.create(c3f, 0.34, "ease_out", 0.04).wait(0.5);

const scene = tmath.scene({
    width: 960,
    height: 540,
    fps: 30,
    background: p.bg,
    camera: { mode: "fixed", view: "2d", height: 6 },
});
scene.viewport(d2, { x: 0, y: 0, width: 0.5, height: 0.5 });
scene.viewport(c2, { x: 0.5, y: 0, width: 0.5, height: 0.5 });
scene.viewport(d3, { x: 0, y: 0.5, width: 0.5, height: 0.5 });
scene.viewport(c3, { x: 0.5, y: 0.5, width: 0.5, height: 0.5 });
return scene;
`,
    },
    {
        id: "trigonometry-circle",
        title: "Unit circle and trigonometric graphs",
        description:
            "Move one angle through a unit circle while its sine, cosine, and tangent components advance in lock-step across four Viewports.",
        category: "Trigonometry",
        dimension: "2D",
        fonts: PRETENDARD,
        lua: `local p = {
    bg = "#0b111a",
    panelA = "#101925",
    panelB = "#0f1722",
    grid = "#263447",
    axis = "#66758a",
    text = "#f4f7fb",
    muted = "#94a3b8",
    cos = "#4cc9f0",
    sin = "#f72585",
    tan = "#ffd166",
    warning = "#ff6b6b",
}
local pi = 3.141592653589793
local twoPi = 2 * pi
local thetaFinal = 0.85
local steps = 36
local stepDuration = 0.065
local function graphAt(x, y)
    return { 1, 0, 0, x, 0, y, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 }
end
local function xAt(x, v)
    return { v, 0, 0, x, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 }
end
local function yAt(x, v)
    return { 1, 0, 0, x, 0, v, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 }
end
local function rotateAt(x, a)
    local c = math.cos(a)
    local s = math.sin(a)
    return { c, -s, 0, x, s, c, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 }
end

local circlePanel = tmath.scene {
    width = 480,
    height = 270,
    fps = 30,
    background = p.panelA,
    camera = { mode = "fixed", view = "2d", height = 3.8 },
}
local cs = circlePanel:space { x = { -3, 3, 1 }, y = { -1.6, 1.6, 0.5 }, progress = 0 }
local cx = -1.45
local base = {
    cs:circle { center = { cx, 0 }, radius = 1, stroke = p.text, width = 3 },
    cs:line { from = { -2.75, 0 }, to = { -0.15, 0 }, color = p.axis, width = 2 },
    cs:line { from = { cx, -1.35 }, to = { cx, 1.35 }, color = p.axis, width = 2 },
    cs:line { from = { cx + 1, -1.35 }, to = { cx + 1, 1.35 }, color = "#ffd16666", width = 2 },
    cs:text {
        text = "UNIT CIRCLE",
        point = { -2.78, 1.58 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 14,
        fill = p.muted,
    },
}
local motion = cs:space {
    x = { -0.1, 0.1, 0.1 },
    y = { -0.1, 0.1, 0.1 },
    progress = 0,
    matrix = rotateAt(cx, 0),
}
local radius = motion:vector { value = { 1, 0 }, color = p.text, width = 4, tip = 12 }
local marker = motion:point { point = { 1, 0 }, fill = p.text, radius = 6, layer = 5 }
local cosTrack =
    cs:space { x = { -0.1, 0.1, 0.1 }, y = { -0.1, 0.1, 0.1 }, progress = 0, matrix = xAt(cx, 1) }
local cosPart = cosTrack:vector { value = { 1, 0 }, color = p.cos, width = 5, tip = 11 }
local sinTrack = cs:space {
    x = { -0.1, 0.1, 0.1 },
    y = { -0.1, 0.1, 0.1 },
    progress = 0,
    matrix = yAt(cx + 1, 0),
}
local sinPart = sinTrack:vector { value = { 0, 1 }, color = p.sin, width = 5, tip = 11 }
local tanTrack = cs:space {
    x = { -0.1, 0.1, 0.1 },
    y = { -0.1, 0.1, 0.1 },
    progress = 0,
    matrix = yAt(cx + 1, 0),
}
local tanPart = tanTrack:vector { value = { 0, 1 }, color = p.tan, width = 4, tip = 11 }
local rayTrack = cs:space {
    x = { -0.1, 0.1, 0.1 },
    y = { -0.1, 0.1, 0.1 },
    progress = 0,
    matrix = graphAt(cx, 0),
}
local tanRay = rayTrack:line { from = { 0, 0 }, to = { 1, 1 }, color = "#ffd166aa", width = 2 }
local labels = {
    cs:text {
        text = "cos θ  ->  x",
        point = { 0.05, 0.72 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 17,
        fill = p.cos,
    },
    cs:text {
        text = "sin θ  ->  y",
        point = { 0.05, 0.32 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 17,
        fill = p.sin,
    },
    cs:text {
        text = "tan θ  ->  tangent",
        point = { 0.05, -0.08 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 17,
        fill = p.tan,
    },
    cs:text {
        text = "θ = 0.85 rad",
        point = { 0.05, -0.62 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 16,
        fill = p.text,
    },
    cs:text {
        text = "P = (0.660, 0.751)",
        point = { 0.05, -1.02 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 15,
        fill = p.text,
    },
}
circlePanel:create(base, 0.50, "ease_out")
circlePanel:create({ radius, marker, cosPart, sinPart, tanPart, tanRay }, 0.28, "ease_out")
for i = 1, steps do
    local a = thetaFinal * i / steps
    local c = math.cos(a)
    local s = math.sin(a)
    local t = math.tan(a)
    circlePanel:play({
        { target = motion, transform = rotateAt(cx, a) },
        { target = cosTrack, transform = xAt(cx, c) },
        { target = sinTrack, transform = yAt(cx + c, s) },
        { target = tanTrack, transform = yAt(cx + 1, t) },
        { target = rayTrack, transform = graphAt(cx, t) },
    }, stepDuration, "linear", 0)
end
circlePanel:create(labels, 0.38, "ease_out")
circlePanel:wait(0.45)

local function wave(name, value, color, fn, background)
    local child = tmath.scene {
        width = 480,
        height = 270,
        fps = 30,
        background = background,
        camera = { mode = "fixed", view = "2d", target = { pi, 0 }, height = 3.8 },
    }
    local space = child:space {
        x = { 0, twoPi, pi / 2 },
        y = { -1.4, 1.4, 0.5 },
        color = p.grid,
        axis_x = p.axis,
        axis_y = p.axis,
    }
    local curve = space:plot { fn = fn, x_range = { 0, twoPi, 0.035 }, color = color, width = 4 }
    local heading = space:text {
        text = name,
        point = { 0.12, 1.62 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 19,
        fill = color,
    }
    local cursor = space:space {
        x = { -0.1, 0.1, 0.1 },
        y = { -0.1, 0.1, 0.1 },
        progress = 0,
        matrix = graphAt(0, fn(0)),
    }
    local guide = cursor:line { from = { 0, 0 }, to = { 0, 1 }, color = color, width = 3 }
    local point = cursor:point { point = { 0, 1 }, fill = color, radius = 6, layer = 5 }
    local result = space:text {
        text = value,
        point = { 4.08, 1.62 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 15,
        fill = color,
    }
    child:create({ space, curve, heading }, 0.50, "ease_out")
    child:create({ guide, point }, 0.28, "ease_out")
    for i = 1, steps do
        local a = thetaFinal * i / steps
        child:transform(cursor, graphAt(a, fn(a)), stepDuration, "linear")
    end
    child:create(result, 0.38, "ease_out")
    child:wait(0.45)
    return child
end
local sine = wave("y = sin θ", "sin(0.85) = 0.751", p.sin, math.sin, p.panelB)
local cosine = wave("y = cos θ", "cos(0.85) = 0.660", p.cos, math.cos, p.panelB)

local tangent = tmath.scene {
    width = 480,
    height = 270,
    fps = 30,
    background = p.panelA,
    camera = { mode = "fixed", view = "2d", target = { 1.55 * pi, 0 }, height = 6.4 },
}
local ts = tangent:space {
    x = { 0, twoPi, pi / 2 },
    y = { -2.8, 2.8, 1 },
    matrix = { 1.55, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 },
    color = p.grid,
    axis_x = p.axis,
    axis_y = p.axis,
}
local limit = 1.2490457723982544
local function segment(a, b)
    local pts = {}
    for i = 0, 44 do
        local x = a + (b - a) * i / 44
        pts[#pts + 1] = { x, math.tan(x) }
    end
    return ts:plot { points = pts, color = p.tan, width = 4 }
end
local curves = { segment(0, limit), segment(pi - limit, pi + limit), segment(twoPi - limit, twoPi) }
local asymA =
    ts:line { from = { pi / 2, -2.8 }, to = { pi / 2, 2.8 }, color = "#ff6b6b77", width = 2 }
local asymB = ts:line {
    from = { 3 * pi / 2, -2.8 },
    to = { 3 * pi / 2, 2.8 },
    color = "#ff6b6b77",
    width = 2,
}
local formula = {
    ts:text {
        text = "tan θ",
        point = { 0.08, 2.95 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 18,
        fill = p.tan,
    },
    ts:text {
        text = "=",
        point = { 1.10, 2.95 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 18,
        fill = p.text,
    },
    ts:text {
        text = "sin θ",
        point = { 1.52, 2.95 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 18,
        fill = p.sin,
    },
    ts:text {
        text = "/",
        point = { 2.58, 2.95 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 18,
        fill = p.text,
    },
    ts:text {
        text = "cos θ",
        point = { 2.90, 2.95 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 18,
        fill = p.cos,
    },
    ts:text {
        text = "undefined at π/2 + kπ",
        point = { 3.72, 2.48 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 11,
        fill = p.warning,
    },
}
local cursor = ts:space {
    x = { -0.1, 0.1, 0.1 },
    y = { -0.1, 0.1, 0.1 },
    progress = 0,
    matrix = graphAt(0, 0),
}
local guide = cursor:line { from = { 0, 0 }, to = { 0, 1 }, color = p.tan, width = 3 }
local point = cursor:point { point = { 0, 1 }, fill = p.tan, radius = 6, layer = 5 }
local result = ts:text {
    text = "tan(0.85) = 1.138",
    point = { 0.08, -2.38 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 16,
    fill = p.tan,
}
tangent:create({
    ts,
    curves[1],
    curves[2],
    curves[3],
    asymA,
    asymB,
    formula[1],
    formula[2],
    formula[3],
    formula[4],
    formula[5],
    formula[6],
}, 0.50, "ease_out")
tangent:create({ guide, point }, 0.28, "ease_out")
for i = 1, steps do
    local a = thetaFinal * i / steps
    tangent:transform(cursor, graphAt(a, math.tan(a)), stepDuration, "linear")
end
tangent:create(result, 0.38, "ease_out")
tangent:wait(0.45)

local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    background = p.bg,
    camera = { mode = "fixed", view = "2d", height = 6 },
}
scene:viewport(circlePanel, { x = 0, y = 0, width = 0.5, height = 0.5 })
scene:viewport(sine, { x = 0.5, y = 0, width = 0.5, height = 0.5 })
scene:viewport(cosine, { x = 0, y = 0.5, width = 0.5, height = 0.5 })
scene:viewport(tangent, { x = 0.5, y = 0.5, width = 0.5, height = 0.5 })
return scene
`,
        js: `const p = {
    bg: "#0b111a",
    panelA: "#101925",
    panelB: "#0f1722",
    grid: "#263447",
    axis: "#66758a",
    text: "#f4f7fb",
    muted: "#94a3b8",
    cos: "#4cc9f0",
    sin: "#f72585",
    tan: "#ffd166",
    warning: "#ff6b6b",
};
const pi = Math.PI,
    twoPi = 2 * pi,
    thetaFinal = 0.85,
    steps = 36,
    stepDuration = 0.065;
const graphAt = (x, y) => [1, 0, 0, x, 0, y, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
const xAt = (x, v) => [v, 0, 0, x, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
const yAt = (x, v) => [1, 0, 0, x, 0, v, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
const rotateAt = (x, a) => {
    const c = Math.cos(a),
        s = Math.sin(a);
    return [c, -s, 0, x, s, c, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
};

const circlePanel = tmath.scene({
    width: 480,
    height: 270,
    fps: 30,
    background: p.panelA,
    camera: { mode: "fixed", view: "2d", height: 3.8 },
});
const cs = circlePanel.space({ x: [-3, 3, 1], y: [-1.6, 1.6, 0.5], progress: 0 }),
    cx = -1.45;
const base = [
    cs.circle({ center: [cx, 0], radius: 1, stroke: p.text, width: 3 }),
    cs.line({ from: [-2.75, 0], to: [-0.15, 0], color: p.axis, width: 2 }),
    cs.line({ from: [cx, -1.35], to: [cx, 1.35], color: p.axis, width: 2 }),
    cs.line({ from: [cx + 1, -1.35], to: [cx + 1, 1.35], color: "#ffd16666", width: 2 }),
    cs.text({
        text: "UNIT CIRCLE",
        point: [-2.78, 1.58],
        align: [0, 0.5],
        font: "Pretendard",
        size: 14,
        fill: p.muted,
    }),
];
const motion = cs.space({
    x: [-0.1, 0.1, 0.1],
    y: [-0.1, 0.1, 0.1],
    progress: 0,
    matrix: rotateAt(cx, 0),
});
const radius = motion.vector({ value: [1, 0], color: p.text, width: 4, tip: 12 });
const marker = motion.point({ point: [1, 0], fill: p.text, radius: 6, layer: 5 });
const cosTrack = cs.space({
    x: [-0.1, 0.1, 0.1],
    y: [-0.1, 0.1, 0.1],
    progress: 0,
    matrix: xAt(cx, 1),
});
const cosPart = cosTrack.vector({ value: [1, 0], color: p.cos, width: 5, tip: 11 });
const sinTrack = cs.space({
    x: [-0.1, 0.1, 0.1],
    y: [-0.1, 0.1, 0.1],
    progress: 0,
    matrix: yAt(cx + 1, 0),
});
const sinPart = sinTrack.vector({ value: [0, 1], color: p.sin, width: 5, tip: 11 });
const tanTrack = cs.space({
    x: [-0.1, 0.1, 0.1],
    y: [-0.1, 0.1, 0.1],
    progress: 0,
    matrix: yAt(cx + 1, 0),
});
const tanPart = tanTrack.vector({ value: [0, 1], color: p.tan, width: 4, tip: 11 });
const rayTrack = cs.space({
    x: [-0.1, 0.1, 0.1],
    y: [-0.1, 0.1, 0.1],
    progress: 0,
    matrix: graphAt(cx, 0),
});
const tanRay = rayTrack.line({ from: [0, 0], to: [1, 1], color: "#ffd166aa", width: 2 });
const labels = [
    cs.text({
        text: "cos θ  ->  x",
        point: [0.05, 0.72],
        align: [0, 0.5],
        font: "Pretendard",
        size: 17,
        fill: p.cos,
    }),
    cs.text({
        text: "sin θ  ->  y",
        point: [0.05, 0.32],
        align: [0, 0.5],
        font: "Pretendard",
        size: 17,
        fill: p.sin,
    }),
    cs.text({
        text: "tan θ  ->  tangent",
        point: [0.05, -0.08],
        align: [0, 0.5],
        font: "Pretendard",
        size: 17,
        fill: p.tan,
    }),
    cs.text({
        text: "θ = 0.85 rad",
        point: [0.05, -0.62],
        align: [0, 0.5],
        font: "Pretendard",
        size: 16,
        fill: p.text,
    }),
    cs.text({
        text: "P = (0.660, 0.751)",
        point: [0.05, -1.02],
        align: [0, 0.5],
        font: "Pretendard",
        size: 15,
        fill: p.text,
    }),
];
circlePanel
    .create(base, 0.5, "ease_out")
    .create([radius, marker, cosPart, sinPart, tanPart, tanRay], 0.28, "ease_out");
for (let i = 1; i <= steps; i++) {
    const a = (thetaFinal * i) / steps,
        c = Math.cos(a),
        s = Math.sin(a),
        t = Math.tan(a);
    circlePanel.play(
        [
            { target: motion, transform: rotateAt(cx, a) },
            { target: cosTrack, transform: xAt(cx, c) },
            { target: sinTrack, transform: yAt(cx + c, s) },
            { target: tanTrack, transform: yAt(cx + 1, t) },
            { target: rayTrack, transform: graphAt(cx, t) },
        ],
        stepDuration,
        "linear",
        0,
    );
}
circlePanel.create(labels, 0.38, "ease_out").wait(0.45);

const wave = (name, value, color, fn, background) => {
    const child = tmath.scene({
        width: 480,
        height: 270,
        fps: 30,
        background,
        camera: { mode: "fixed", view: "2d", target: [pi, 0], height: 3.8 },
    });
    const space = child.space({
        x: [0, twoPi, pi / 2],
        y: [-1.4, 1.4, 0.5],
        color: p.grid,
        axis_x: p.axis,
        axis_y: p.axis,
    });
    const points = Array.from({ length: 181 }, (_, i) => {
        const x = (twoPi * i) / 180;
        return [x, fn(x)];
    });
    const curve = space.plot({ points, color, width: 4 });
    const heading = space.text({
        text: name,
        point: [0.12, 1.62],
        align: [0, 0.5],
        font: "Pretendard",
        size: 19,
        fill: color,
    });
    const cursor = space.space({
        x: [-0.1, 0.1, 0.1],
        y: [-0.1, 0.1, 0.1],
        progress: 0,
        matrix: graphAt(0, fn(0)),
    });
    const guide = cursor.line({ from: [0, 0], to: [0, 1], color, width: 3 });
    const point = cursor.point({ point: [0, 1], fill: color, radius: 6, layer: 5 });
    const result = space.text({
        text: value,
        point: [4.08, 1.62],
        align: [0, 0.5],
        font: "Pretendard",
        size: 15,
        fill: color,
    });
    child.create([space, curve, heading], 0.5, "ease_out").create([guide, point], 0.28, "ease_out");
    for (let i = 1; i <= steps; i++) {
        const a = (thetaFinal * i) / steps;
        child.transform(cursor, graphAt(a, fn(a)), stepDuration, "linear");
    }
    child.create(result, 0.38, "ease_out").wait(0.45);
    return child;
};
const sine = wave("y = sin θ", "sin(0.85) = 0.751", p.sin, Math.sin, p.panelB);
const cosine = wave("y = cos θ", "cos(0.85) = 0.660", p.cos, Math.cos, p.panelB);

const tangent = tmath.scene({
    width: 480,
    height: 270,
    fps: 30,
    background: p.panelA,
    camera: { mode: "fixed", view: "2d", target: [1.55 * pi, 0], height: 6.4 },
});
const ts = tangent.space({
    x: [0, twoPi, pi / 2],
    y: [-2.8, 2.8, 1],
    matrix: [1.55, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1],
    color: p.grid,
    axis_x: p.axis,
    axis_y: p.axis,
});
const limit = 1.2490457723982544;
const segment = (a, b) =>
    Array.from({ length: 45 }, (_, i) => {
        const x = a + ((b - a) * i) / 44;
        return [x, Math.tan(x)];
    });
const curves = [
    [0, limit],
    [pi - limit, pi + limit],
    [twoPi - limit, twoPi],
].map(([a, b]) => ts.plot({ points: segment(a, b), color: p.tan, width: 4 }));
const asymA = ts.line({ from: [pi / 2, -2.8], to: [pi / 2, 2.8], color: "#ff6b6b77", width: 2 });
const asymB = ts.line({
    from: [(3 * pi) / 2, -2.8],
    to: [(3 * pi) / 2, 2.8],
    color: "#ff6b6b77",
    width: 2,
});
const formula = [
    ts.text({
        text: "tan θ",
        point: [0.08, 2.95],
        align: [0, 0.5],
        font: "Pretendard",
        size: 18,
        fill: p.tan,
    }),
    ts.text({
        text: "=",
        point: [1.1, 2.95],
        align: [0, 0.5],
        font: "Pretendard",
        size: 18,
        fill: p.text,
    }),
    ts.text({
        text: "sin θ",
        point: [1.52, 2.95],
        align: [0, 0.5],
        font: "Pretendard",
        size: 18,
        fill: p.sin,
    }),
    ts.text({
        text: "/",
        point: [2.58, 2.95],
        align: [0, 0.5],
        font: "Pretendard",
        size: 18,
        fill: p.text,
    }),
    ts.text({
        text: "cos θ",
        point: [2.9, 2.95],
        align: [0, 0.5],
        font: "Pretendard",
        size: 18,
        fill: p.cos,
    }),
    ts.text({
        text: "undefined at π/2 + kπ",
        point: [3.72, 2.48],
        align: [0, 0.5],
        font: "Pretendard",
        size: 11,
        fill: p.warning,
    }),
];
const cursor = ts.space({
    x: [-0.1, 0.1, 0.1],
    y: [-0.1, 0.1, 0.1],
    progress: 0,
    matrix: graphAt(0, 0),
});
const guide = cursor.line({ from: [0, 0], to: [0, 1], color: p.tan, width: 3 });
const point = cursor.point({ point: [0, 1], fill: p.tan, radius: 6, layer: 5 });
const result = ts.text({
    text: "tan(0.85) = 1.138",
    point: [0.08, -2.38],
    align: [0, 0.5],
    font: "Pretendard",
    size: 16,
    fill: p.tan,
});
tangent.create(
    [
        ts,
        curves[0],
        curves[1],
        curves[2],
        asymA,
        asymB,
        formula[0],
        formula[1],
        formula[2],
        formula[3],
        formula[4],
        formula[5],
    ],
    0.5,
    "ease_out",
);
tangent.create([guide, point], 0.28, "ease_out");
for (let i = 1; i <= steps; i++) {
    const a = (thetaFinal * i) / steps;
    tangent.transform(cursor, graphAt(a, Math.tan(a)), stepDuration, "linear");
}
tangent.create(result, 0.38, "ease_out").wait(0.45);

const scene = tmath.scene({
    width: 960,
    height: 540,
    fps: 30,
    background: p.bg,
    camera: { mode: "fixed", view: "2d", height: 6 },
});
scene.viewport(circlePanel, { x: 0, y: 0, width: 0.5, height: 0.5 });
scene.viewport(sine, { x: 0.5, y: 0, width: 0.5, height: 0.5 });
scene.viewport(cosine, { x: 0, y: 0.5, width: 0.5, height: 0.5 });
scene.viewport(tangent, { x: 0.5, y: 0.5, width: 0.5, height: 0.5 });
return scene;
`,
    },
];
