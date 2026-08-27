const PRETENDARD = [{ name: "Pretendard", url: "./Pretendard.ttf", mime: "ttf" }];

export const CONIC_EXAMPLES = [
    {
        id: "conic-vector-formula",
        title: "Conic angle · vectors become formula",
        description:
            "Keep the vector construction visible while solid color-matched copies become formula bullets, then sample a conic ColorTable.",
        category: "Conic",
        dimension: "2D",
        fonts: PRETENDARD,
        lua: `local p = {
    paper = "#f7f4ed",
    panel = "#fffdf8",
    line = "#d7d2c8",
    ink = "#25272d",
    muted = "#737780",
    soft = "#aaa59c",
    seam = "#b44709",
    offset = "#6f6581",
    dot = "#597493",
    cross = "#c58a35",
    green = "#557b63",
}

local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    antialiasing = true,
    loop = false,
    background = p.paper,
    camera = { mode = "fixed", view = "2d", height = 7.4 },
}
local space = scene:space {
    x = { -6.5, 6.5, 1 },
    y = { -3.5, 3.5, 1 },
    opacity = 0,
}

local function arrow_points(from, to, shaft, head, head_length)
    local dx, dy = to[1] - from[1], to[2] - from[2]
    local length = math.sqrt(dx * dx + dy * dy)
    local ux, uy = dx / length, dy / length
    local nx, ny = -uy, ux
    local jx, jy = to[1] - ux * head_length, to[2] - uy * head_length
    return {
        { from[1] + nx * shaft, from[2] + ny * shaft },
        { jx + nx * shaft, jy + ny * shaft },
        { jx + nx * head, jy + ny * head },
        { to[1], to[2] },
        { jx - nx * head, jy - ny * head },
        { jx - nx * shaft, jy - ny * shaft },
        { from[1] - nx * shaft, from[2] - ny * shaft },
    }
end

local function bullet_points(cx, cy, radius, count)
    local points = {}
    for i = 0, count - 1 do
        local angle = 2 * math.pi * i / count
        points[#points + 1] = { cx + radius * math.cos(angle), cy + radius * math.sin(angle) }
    end
    return points
end

local function mix_color(a, b, t)
    local function channel(color, offset)
        return tonumber(string.sub(color, offset, offset + 1), 16)
    end
    local r = math.floor(channel(a, 2) + (channel(b, 2) - channel(a, 2)) * t + 0.5)
    local g = math.floor(channel(a, 4) + (channel(b, 4) - channel(a, 4)) * t + 0.5)
    local blue = math.floor(channel(a, 6) + (channel(b, 6) - channel(a, 6)) * t + 0.5)
    return string.format("#%02x%02x%02x", r, g, blue)
end

local eyebrow = space:text {
    text = "CONIC / VECTOR GEOMETRY · 01",
    point = { -5.85, 3.25 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = p.seam,
}
local title = space:text {
    text = "A vector becomes the angle formula",
    point = { -5.85, 2.80 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 29,
    fill = p.ink,
}
local subtitle = space:text {
    text = "Solid geometry copies become bullets that introduce color-matched formula terms",
    point = { -5.83, 2.34 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 14,
    fill = p.muted,
}
local divider = space:line {
    from = { -5.85, 2.08 },
    to = { 5.85, 2.08 },
    color = p.line,
    width = 2,
}
local panels = {
    space:rectangle {
        center = { -3.10, -0.25 },
        size = { 5.45, 4.25 },
        corner = 0.14,
        fill = p.panel,
        stroke = p.line,
        width = 2,
    },
    space:rectangle {
        center = { 3.08, -0.25 },
        size = { 5.65, 4.25 },
        corner = 0.14,
        fill = p.panel,
        stroke = p.line,
        width = 2,
    },
}
local panel_labels = {
    space:text {
        text = "GEOMETRY · SIGNED ANGLE",
        point = { -5.58, 1.52 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 13,
        fill = p.muted,
    },
    space:text {
        text = "TRANSFORM FROM COPY",
        point = { 0.48, 1.52 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 13,
        fill = p.muted,
    },
}

local origin = { -3.55, -0.42 }
local seam_end = { -1.30, -0.42 }
local offset_end = { -2.05, 1.02 }
local projection_end = { -2.05, -0.42 }
local grid = {}
for i = -2, 2 do
    grid[#grid + 1] = space:line {
        from = { origin[1] + i * 0.58, -1.82 },
        to = { origin[1] + i * 0.58, 1.18 },
        color = "#e5e0d7",
        width = 1,
    }
end
for i = -2, 2 do
    grid[#grid + 1] = space:line {
        from = { -5.15, origin[2] + i * 0.58 },
        to = { -1.05, origin[2] + i * 0.58 },
        color = "#e5e0d7",
        width = 1,
    }
end
local axes = {
    space:line {
        from = { -5.28, origin[2] },
        to = { -0.92, origin[2] },
        color = p.soft,
        width = 1.5,
    },
    space:line { from = { origin[1], -1.92 }, to = { origin[1], 1.30 }, color = p.soft, width = 1.5 },
}
local origin_point = space:point { point = origin, fill = p.ink, radius = 5, layer = 8 }
local sample_point = space:point { point = offset_end, fill = p.offset, radius = 6, layer = 8 }
local seam_arrow = space:polygon {
    points = arrow_points(origin, seam_end, 0.035, 0.13, 0.30),
    fill = p.seam,
    stroke = p.seam,
    width = 1.5,
    id = "seam-vector-morph-source",
}
local offset_arrow = space:polygon {
    points = arrow_points(origin, offset_end, 0.035, 0.13, 0.30),
    fill = p.offset,
    stroke = p.offset,
    width = 1.5,
    id = "offset-vector-morph-source",
}
local seam_label = space:text {
    text = "s = seam",
    point = { -1.62, -0.75 },
    font = "Pretendard",
    size = 15,
    fill = p.seam,
}
local offset_label = space:text {
    text = "p = offset",
    point = { -2.25, 1.27 },
    font = "Pretendard",
    size = 15,
    fill = p.offset,
}
local projection_guide = space:line {
    from = offset_end,
    to = projection_end,
    color = p.dot,
    width = 2,
}
local dot_arrow = space:polygon {
    points = arrow_points(origin, projection_end, 0.027, 0.10, 0.24),
    fill = p.dot,
    stroke = p.dot,
    width = 1,
    id = "dot-morph-source",
}
local cross_area = space:polygon {
    points = { origin, seam_end, offset_end, origin },
    fill = "#c58a3542",
    stroke = p.cross,
    width = 2,
    id = "cross-morph-source",
}
local angle_points = {}
local theta = math.atan(offset_end[2] - origin[2], offset_end[1] - origin[1])
for i = 0, 24 do
    local a = theta * i / 24
    angle_points[#angle_points + 1] =
        { origin[1] + 0.62 * math.cos(a), origin[2] + 0.62 * math.sin(a) }
end
local angle_arc = space:plot { points = angle_points, color = p.ink, width = 2 }
local angle_label = space:text {
    text = "θ",
    point = { -2.88, -0.06 },
    font = "Pretendard",
    size = 19,
    fill = p.ink,
}
local geometry_notes = {
    space:text {
        text = "dot(s, p) · projection",
        point = { -5.12, -2.05 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 13,
        fill = p.dot,
    },
    space:text {
        text = "cross₂D(s, p) · area",
        point = { -2.52, -2.05 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 13,
        fill = p.cross,
    },
}

local seam_token = space:text {
    text = "s = seam",
    point = { 1.03, 1.00 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 16,
    fill = p.seam,
}
local offset_token = space:text {
    text = "p = (rx, ry)",
    point = { 3.62, 1.00 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 16,
    fill = p.offset,
}
local cross_token = space:text {
    text = "cross₂D(s, p) = signed area",
    point = { 1.03, 0.45 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 16,
    fill = p.cross,
}
local dot_token = space:text {
    text = "dot(s, p) = projected length",
    point = { 1.03, -0.43 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 16,
    fill = p.dot,
}
local final_formula = {
    space:text {
        text = "θ = atan2(",
        point = { 0.72, -1.26 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 20,
        fill = p.ink,
    },
    space:text {
        text = "cross₂D(s,p),",
        point = { 2.42, -1.26 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 15,
        fill = p.cross,
    },
    space:text {
        text = "dot(s,p)",
        point = { 4.08, -1.26 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 15,
        fill = p.dot,
    },
    space:text {
        text = ")",
        point = { 5.12, -1.26 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 20,
        fill = p.ink,
    },
}
local parameter_formula = space:text {
    text = "t = fract( θ / 2π + offset )",
    point = { 3.08, -1.84 },
    font = "Pretendard",
    size = 18,
    fill = p.seam,
}
local conclusion = space:text {
    text = "geometry -> formula tokens -> ColorTable",
    point = { 3.08, -2.17 },
    font = "Pretendard",
    size = 13,
    fill = p.green,
}

local ring = {}
local ring_colors = { p.offset, p.dot, "#87929b", "#b49b72", p.cross, "#ef9234", p.seam, "#9c5a43" }
local ring_center = { -3.55, -0.35 }
local ring_radius = 1.35
for i = 0, 31 do
    local a0 = 2 * math.pi * i / 32
    local a1 = 2 * math.pi * (i + 1) / 32 + 0.006
    local phase = i * #ring_colors / 32
    local index = math.floor(phase) + 1
    local next_index = index % #ring_colors + 1
    local color = mix_color(ring_colors[index], ring_colors[next_index], phase - math.floor(phase))
    ring[#ring + 1] = space:polygon {
        points = {
            ring_center,
            {
                ring_center[1] + ring_radius * math.cos(a0),
                ring_center[2] + ring_radius * math.sin(a0),
            },
            {
                ring_center[1] + ring_radius * math.cos(a1),
                ring_center[2] + ring_radius * math.sin(a1),
            },
        },
        fill = color,
        stroke = color,
        width = 1,
    }
end
local ring_hole = space:circle {
    center = ring_center,
    radius = 0.62,
    fill = p.panel,
    stroke = p.panel,
    width = 2,
    layer = 7,
}
local ring_center_point = space:point { point = ring_center, fill = p.ink, radius = 4, layer = 9 }
local ring_seam = space:arrow {
    from = ring_center,
    to = { -1.90, -0.35 },
    tip = 12,
    color = p.seam,
    width = 3,
}
local ring_labels = {
    space:text {
        text = "t = 0",
        point = { -1.76, -0.35 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 13,
        fill = p.seam,
    },
    space:text {
        text = "atan2 -> [0, 1)",
        point = { -3.55, -1.96 },
        font = "Pretendard",
        size = 14,
        fill = p.muted,
    },
}

scene:create({ eyebrow, title, subtitle, divider }, 0.52, "ease_out", 0.06)
scene:create(panels, 0.42, "ease_out", 0.08)
scene:create(panel_labels, 0.30, "ease_out", 0.08)
scene:create(grid, 0.62, "linear", 0.025)
scene:create(axes, 0.36, "ease_out", 0.05)
scene:create({ origin_point, seam_arrow, offset_arrow, sample_point }, 0.92, "ease_out", 0.10)
scene:create({ seam_label, offset_label }, 0.30, "ease_out", 0.06)
scene:create(cross_area, 0.64, "ease_out")
scene:create({ projection_guide, dot_arrow }, 0.58, "ease_out", 0.08)
scene:create(
    { angle_arc, angle_label, geometry_notes[1], geometry_notes[2] },
    0.46,
    "ease_out",
    0.06
)
scene:wait(0.25)
local seam_morph_copy = space:polygon {
    points = arrow_points(origin, seam_end, 0.035, 0.13, 0.30),
    fill = p.seam,
    stroke = p.seam,
    width = 1.5,
    id = "seam-vector-morph-copy",
}
local seam_bullet = space:polygon {
    points = bullet_points(0.78, 1.00, 0.10, 7),
    fill = p.seam,
    stroke = p.seam,
    width = 1,
    id = "seam-formula-bullet",
}
scene:replacement_transform(seam_morph_copy, seam_bullet, 0.72, "ease_in_out")
scene:fade_in(seam_token, { shift = { -0.12, 0 }, duration = 0.20, curve = "snappy" })
local offset_morph_copy = space:polygon {
    points = arrow_points(origin, offset_end, 0.035, 0.13, 0.30),
    fill = p.offset,
    stroke = p.offset,
    width = 1.5,
    id = "offset-vector-morph-copy",
}
local offset_bullet = space:polygon {
    points = bullet_points(3.36, 1.00, 0.10, 7),
    fill = p.offset,
    stroke = p.offset,
    width = 1,
    id = "offset-formula-bullet",
}
scene:replacement_transform(offset_morph_copy, offset_bullet, 0.72, "ease_in_out")
scene:fade_in(offset_token, { shift = { -0.12, 0 }, duration = 0.20, curve = "snappy" })
local cross_morph_copy = space:polygon {
    points = { origin, seam_end, offset_end, origin },
    fill = p.cross,
    stroke = p.cross,
    width = 2,
    id = "cross-area-morph-copy",
}
local cross_bullet = space:polygon {
    points = bullet_points(0.78, 0.45, 0.11, 4),
    fill = p.cross,
    stroke = p.cross,
    width = 1,
    id = "cross-formula-bullet",
}
scene:replacement_transform(cross_morph_copy, cross_bullet, 0.82, "ease_in_out")
scene:fade_in(cross_token, { shift = { -0.12, 0 }, duration = 0.22, curve = "snappy" })
local dot_morph_copy = space:polygon {
    points = arrow_points(origin, projection_end, 0.027, 0.10, 0.24),
    fill = p.dot,
    stroke = p.dot,
    width = 1,
    id = "dot-vector-morph-copy",
}
local dot_bullet = space:polygon {
    points = bullet_points(0.78, -0.43, 0.10, 7),
    fill = p.dot,
    stroke = p.dot,
    width = 1,
    id = "dot-formula-bullet",
}
scene:replacement_transform(dot_morph_copy, dot_bullet, 0.82, "ease_in_out")
scene:fade_in(dot_token, { shift = { -0.12, 0 }, duration = 0.22, curve = "snappy" })
local fade_geometry = {}
for _, object in ipairs(grid) do
    fade_geometry[#fade_geometry + 1] = { target = object, opacity = 0 }
end
for _, object in ipairs {
    axes[1],
    axes[2],
    origin_point,
    sample_point,
    seam_arrow,
    offset_arrow,
    cross_area,
    projection_guide,
    dot_arrow,
    angle_arc,
    angle_label,
    seam_label,
    offset_label,
    geometry_notes[1],
    geometry_notes[2],
} do
    fade_geometry[#fade_geometry + 1] = { target = object, opacity = 0 }
end
scene:play(fade_geometry, 0.46, "ease_in", 0)
scene:create(final_formula, 0.54, "ease_out", 0.07)
scene:create(parameter_formula, 0.32, "ease_out")
scene:create(ring, 0.96, "ease_out", 0.025)
scene:grow_from_center(ring_hole, 0.42, "ease_out")
scene:create(
    { ring_center_point, ring_seam, ring_labels[1], ring_labels[2] },
    0.48,
    "ease_out",
    0.06
)
scene:create(conclusion, 0.30, "ease_out")
scene:indicate(
    parameter_formula,
    { color = p.cross, scale = 1.06, duration = 0.72, easing = "smooth" }
)
scene:wait(0.90)
return scene
`,
        js: `const p = {
    paper: "#f7f4ed",
    panel: "#fffdf8",
    line: "#d7d2c8",
    ink: "#25272d",
    muted: "#737780",
    soft: "#aaa59c",
    seam: "#b44709",
    offset: "#6f6581",
    dot: "#597493",
    cross: "#c58a35",
    green: "#557b63",
};
const scene = tmath.scene({
    width: 960,
    height: 540,
    fps: 30,
    antialiasing: true,
    loop: false,
    background: p.paper,
    camera: { mode: "fixed", view: "2d", height: 7.4 },
});
const space = scene.space({ x: [-6.5, 6.5, 1], y: [-3.5, 3.5, 1], opacity: 0 });

const arrowPoints = (from, to, shaft, head, headLength) => {
    const dx = to[0] - from[0],
        dy = to[1] - from[1],
        length = Math.hypot(dx, dy);
    const ux = dx / length,
        uy = dy / length,
        nx = -uy,
        ny = ux;
    const jx = to[0] - ux * headLength,
        jy = to[1] - uy * headLength;
    return [
        [from[0] + nx * shaft, from[1] + ny * shaft],
        [jx + nx * shaft, jy + ny * shaft],
        [jx + nx * head, jy + ny * head],
        [to[0], to[1]],
        [jx - nx * head, jy - ny * head],
        [jx - nx * shaft, jy - ny * shaft],
        [from[0] - nx * shaft, from[1] - ny * shaft],
    ];
};
const bulletPoints = (cx, cy, radius, count) =>
    Array.from({ length: count }, (_, index) => {
        const angle = (2 * Math.PI * index) / count;
        return [cx + radius * Math.cos(angle), cy + radius * Math.sin(angle)];
    });
const mixColor = (a, b, t) => {
    const channel = (color, offset) => parseInt(color.slice(offset, offset + 2), 16);
    const values = [1, 3, 5].map((offset) =>
        Math.round(channel(a, offset) + (channel(b, offset) - channel(a, offset)) * t),
    );
    return "#" + values.map((value) => value.toString(16).padStart(2, "0")).join("");
};

const eyebrow = space.text({
    text: "CONIC / VECTOR GEOMETRY · 01",
    point: [-5.85, 3.25],
    align: [0, 0.5],
    font: "Pretendard",
    size: 13,
    fill: p.seam,
});
const title = space.text({
    text: "A vector becomes the angle formula",
    point: [-5.85, 2.8],
    align: [0, 0.5],
    font: "Pretendard",
    size: 29,
    fill: p.ink,
});
const subtitle = space.text({
    text: "Solid geometry copies become bullets that introduce color-matched formula terms",
    point: [-5.83, 2.34],
    align: [0, 0.5],
    font: "Pretendard",
    size: 14,
    fill: p.muted,
});
const divider = space.line({ from: [-5.85, 2.08], to: [5.85, 2.08], color: p.line, width: 2 });
const panels = [
    space.rectangle({
        center: [-3.1, -0.25],
        size: [5.45, 4.25],
        corner: 0.14,
        fill: p.panel,
        stroke: p.line,
        width: 2,
    }),
    space.rectangle({
        center: [3.08, -0.25],
        size: [5.65, 4.25],
        corner: 0.14,
        fill: p.panel,
        stroke: p.line,
        width: 2,
    }),
];
const panelLabels = [
    space.text({
        text: "GEOMETRY · SIGNED ANGLE",
        point: [-5.58, 1.52],
        align: [0, 0.5],
        font: "Pretendard",
        size: 13,
        fill: p.muted,
    }),
    space.text({
        text: "TRANSFORM FROM COPY",
        point: [0.48, 1.52],
        align: [0, 0.5],
        font: "Pretendard",
        size: 13,
        fill: p.muted,
    }),
];

const origin = [-3.55, -0.42],
    seamEnd = [-1.3, -0.42],
    offsetEnd = [-2.05, 1.02],
    projectionEnd = [-2.05, -0.42];
const grid = [];
for (let i = -2; i <= 2; i++)
    grid.push(
        space.line({
            from: [origin[0] + i * 0.58, -1.82],
            to: [origin[0] + i * 0.58, 1.18],
            color: "#e5e0d7",
            width: 1,
        }),
    );
for (let i = -2; i <= 2; i++)
    grid.push(
        space.line({
            from: [-5.15, origin[1] + i * 0.58],
            to: [-1.05, origin[1] + i * 0.58],
            color: "#e5e0d7",
            width: 1,
        }),
    );
const axes = [
    space.line({ from: [-5.28, origin[1]], to: [-0.92, origin[1]], color: p.soft, width: 1.5 }),
    space.line({ from: [origin[0], -1.92], to: [origin[0], 1.3], color: p.soft, width: 1.5 }),
];
const originPoint = space.point({ point: origin, fill: p.ink, radius: 5, layer: 8 });
const samplePoint = space.point({ point: offsetEnd, fill: p.offset, radius: 6, layer: 8 });
const seamArrow = space.polygon({
    points: arrowPoints(origin, seamEnd, 0.035, 0.13, 0.3),
    fill: p.seam,
    stroke: p.seam,
    width: 1.5,
    id: "seam-vector-morph-source",
});
const offsetArrow = space.polygon({
    points: arrowPoints(origin, offsetEnd, 0.035, 0.13, 0.3),
    fill: p.offset,
    stroke: p.offset,
    width: 1.5,
    id: "offset-vector-morph-source",
});
const seamLabel = space.text({
    text: "s = seam",
    point: [-1.62, -0.75],
    font: "Pretendard",
    size: 15,
    fill: p.seam,
});
const offsetLabel = space.text({
    text: "p = offset",
    point: [-2.25, 1.27],
    font: "Pretendard",
    size: 15,
    fill: p.offset,
});
const projectionGuide = space.line({ from: offsetEnd, to: projectionEnd, color: p.dot, width: 2 });
const dotArrow = space.polygon({
    points: arrowPoints(origin, projectionEnd, 0.027, 0.1, 0.24),
    fill: p.dot,
    stroke: p.dot,
    width: 1,
    id: "dot-morph-source",
});
const crossArea = space.polygon({
    points: [origin, seamEnd, offsetEnd, origin],
    fill: "#c58a3542",
    stroke: p.cross,
    width: 2,
    id: "cross-morph-source",
});
const theta = Math.atan2(offsetEnd[1] - origin[1], offsetEnd[0] - origin[0]);
const anglePoints = Array.from({ length: 25 }, (_, i) => {
    const a = (theta * i) / 24;
    return [origin[0] + 0.62 * Math.cos(a), origin[1] + 0.62 * Math.sin(a)];
});
const angleArc = space.plot({ points: anglePoints, color: p.ink, width: 2 });
const angleLabel = space.text({
    text: "θ",
    point: [-2.88, -0.06],
    font: "Pretendard",
    size: 19,
    fill: p.ink,
});
const geometryNotes = [
    space.text({
        text: "dot(s, p) · projection",
        point: [-5.12, -2.05],
        align: [0, 0.5],
        font: "Pretendard",
        size: 13,
        fill: p.dot,
    }),
    space.text({
        text: "cross₂D(s, p) · area",
        point: [-2.52, -2.05],
        align: [0, 0.5],
        font: "Pretendard",
        size: 13,
        fill: p.cross,
    }),
];

const seamToken = space.text({
    text: "s = seam",
    point: [1.03, 1],
    align: [0, 0.5],
    font: "Pretendard",
    size: 16,
    fill: p.seam,
});
const offsetToken = space.text({
    text: "p = (rx, ry)",
    point: [3.62, 1],
    align: [0, 0.5],
    font: "Pretendard",
    size: 16,
    fill: p.offset,
});
const crossToken = space.text({
    text: "cross₂D(s, p) = signed area",
    point: [1.03, 0.45],
    align: [0, 0.5],
    font: "Pretendard",
    size: 16,
    fill: p.cross,
});
const dotToken = space.text({
    text: "dot(s, p) = projected length",
    point: [1.03, -0.43],
    align: [0, 0.5],
    font: "Pretendard",
    size: 16,
    fill: p.dot,
});
const finalFormula = [
    space.text({
        text: "θ = atan2(",
        point: [0.72, -1.26],
        align: [0, 0.5],
        font: "Pretendard",
        size: 20,
        fill: p.ink,
    }),
    space.text({
        text: "cross₂D(s,p),",
        point: [2.42, -1.26],
        align: [0, 0.5],
        font: "Pretendard",
        size: 15,
        fill: p.cross,
    }),
    space.text({
        text: "dot(s,p)",
        point: [4.08, -1.26],
        align: [0, 0.5],
        font: "Pretendard",
        size: 15,
        fill: p.dot,
    }),
    space.text({
        text: ")",
        point: [5.12, -1.26],
        align: [0, 0.5],
        font: "Pretendard",
        size: 20,
        fill: p.ink,
    }),
];
const parameterFormula = space.text({
    text: "t = fract( θ / 2π + offset )",
    point: [3.08, -1.84],
    font: "Pretendard",
    size: 18,
    fill: p.seam,
});
const conclusion = space.text({
    text: "geometry -> formula tokens -> ColorTable",
    point: [3.08, -2.17],
    font: "Pretendard",
    size: 13,
    fill: p.green,
});

const ring = [];
const ringColors = [p.offset, p.dot, "#87929b", "#b49b72", p.cross, "#ef9234", p.seam, "#9c5a43"];
const ringCenter = [-3.55, -0.35],
    ringRadius = 1.35;
for (let i = 0; i < 32; i++) {
    const a0 = (2 * Math.PI * i) / 32,
        a1 = (2 * Math.PI * (i + 1)) / 32 + 0.006;
    const phase = (i * ringColors.length) / 32,
        index = Math.floor(phase),
        next = (index + 1) % ringColors.length;
    const color = mixColor(ringColors[index], ringColors[next], phase - Math.floor(phase));
    ring.push(
        space.polygon({
            points: [
                ringCenter,
                [
                    ringCenter[0] + ringRadius * Math.cos(a0),
                    ringCenter[1] + ringRadius * Math.sin(a0),
                ],
                [
                    ringCenter[0] + ringRadius * Math.cos(a1),
                    ringCenter[1] + ringRadius * Math.sin(a1),
                ],
            ],
            fill: color,
            stroke: color,
            width: 1,
        }),
    );
}
const ringHole = space.circle({
    center: ringCenter,
    radius: 0.62,
    fill: p.panel,
    stroke: p.panel,
    width: 2,
    layer: 7,
});
const ringCenterPoint = space.point({ point: ringCenter, fill: p.ink, radius: 4, layer: 9 });
const ringSeam = space.arrow({
    from: ringCenter,
    to: [-1.9, -0.35],
    tip: 12,
    color: p.seam,
    width: 3,
});
const ringLabels = [
    space.text({
        text: "t = 0",
        point: [-1.76, -0.35],
        align: [0, 0.5],
        font: "Pretendard",
        size: 13,
        fill: p.seam,
    }),
    space.text({
        text: "atan2 -> [0, 1)",
        point: [-3.55, -1.96],
        font: "Pretendard",
        size: 14,
        fill: p.muted,
    }),
];

scene.create([eyebrow, title, subtitle, divider], 0.52, "ease_out", 0.06);
scene.create(panels, 0.42, "ease_out", 0.08);
scene.create(panelLabels, 0.3, "ease_out", 0.08);
scene.create(grid, 0.62, "linear", 0.025);
scene.create(axes, 0.36, "ease_out", 0.05);
scene.create([originPoint, seamArrow, offsetArrow, samplePoint], 0.92, "ease_out", 0.1);
scene.create([seamLabel, offsetLabel], 0.3, "ease_out", 0.06);
scene.create(crossArea, 0.64, "ease_out");
scene.create([projectionGuide, dotArrow], 0.58, "ease_out", 0.08);
scene.create([angleArc, angleLabel, geometryNotes[0], geometryNotes[1]], 0.46, "ease_out", 0.06);
scene.wait(0.25);
const seamMorphCopy = space.polygon({
    points: arrowPoints(origin, seamEnd, 0.035, 0.13, 0.3),
    fill: p.seam,
    stroke: p.seam,
    width: 1.5,
    id: "seam-vector-morph-copy",
});
const seamBullet = space.polygon({
    points: bulletPoints(0.78, 1, 0.1, 7),
    fill: p.seam,
    stroke: p.seam,
    width: 1,
    id: "seam-formula-bullet",
});
scene.replacementTransform(seamMorphCopy, seamBullet, 0.72, "ease_in_out");
scene.fadeIn(seamToken, { shift: [-0.12, 0], duration: 0.2, curve: "snappy" });
const offsetMorphCopy = space.polygon({
    points: arrowPoints(origin, offsetEnd, 0.035, 0.13, 0.3),
    fill: p.offset,
    stroke: p.offset,
    width: 1.5,
    id: "offset-vector-morph-copy",
});
const offsetBullet = space.polygon({
    points: bulletPoints(3.36, 1, 0.1, 7),
    fill: p.offset,
    stroke: p.offset,
    width: 1,
    id: "offset-formula-bullet",
});
scene.replacementTransform(offsetMorphCopy, offsetBullet, 0.72, "ease_in_out");
scene.fadeIn(offsetToken, { shift: [-0.12, 0], duration: 0.2, curve: "snappy" });
const crossMorphCopy = space.polygon({
    points: [origin, seamEnd, offsetEnd, origin],
    fill: p.cross,
    stroke: p.cross,
    width: 2,
    id: "cross-area-morph-copy",
});
const crossBullet = space.polygon({
    points: bulletPoints(0.78, 0.45, 0.11, 4),
    fill: p.cross,
    stroke: p.cross,
    width: 1,
    id: "cross-formula-bullet",
});
scene.replacementTransform(crossMorphCopy, crossBullet, 0.82, "ease_in_out");
scene.fadeIn(crossToken, { shift: [-0.12, 0], duration: 0.22, curve: "snappy" });
const dotMorphCopy = space.polygon({
    points: arrowPoints(origin, projectionEnd, 0.027, 0.1, 0.24),
    fill: p.dot,
    stroke: p.dot,
    width: 1,
    id: "dot-vector-morph-copy",
});
const dotBullet = space.polygon({
    points: bulletPoints(0.78, -0.43, 0.1, 7),
    fill: p.dot,
    stroke: p.dot,
    width: 1,
    id: "dot-formula-bullet",
});
scene.replacementTransform(dotMorphCopy, dotBullet, 0.82, "ease_in_out");
scene.fadeIn(dotToken, { shift: [-0.12, 0], duration: 0.22, curve: "snappy" });
const fadeGeometry = grid
    .concat(axes, [
        originPoint,
        samplePoint,
        seamArrow,
        offsetArrow,
        crossArea,
        projectionGuide,
        dotArrow,
        angleArc,
        angleLabel,
        seamLabel,
        offsetLabel,
        geometryNotes[0],
        geometryNotes[1],
    ])
    .map((target) => ({ target, opacity: 0 }));
scene.play(fadeGeometry, 0.46, "ease_in");
scene.create(finalFormula, 0.54, "ease_out", 0.07);
scene.create(parameterFormula, 0.32, "ease_out");
scene.create(ring, 0.96, "ease_out", 0.025);
scene.growFromCenter(ringHole, 0.42, "ease_out");
scene.create([ringCenterPoint, ringSeam, ringLabels[0], ringLabels[1]], 0.48, "ease_out", 0.06);
scene.create(conclusion, 0.3, "ease_out");
scene.indicate(parameterFormula, { color: p.cross, scale: 1.06, duration: 0.72, easing: "smooth" });
scene.wait(0.9);
return scene;
`,
    },
];
