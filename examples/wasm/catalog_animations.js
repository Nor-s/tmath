const PRETENDARD = [{ name: "Pretendard", url: "./Pretendard.ttf", mime: "ttf" }];

export const ANIMATION_EXAMPLES = [
    {
        id: "path-fill",
        title: "Path fill · side by side",
        description:
            "Compare manual draw/pause/fill, the combined two-phase clip, and clockwise snappy timing from the same start time.",
        category: "Animation",
        dimension: "2D",
        fonts: PRETENDARD,
        lua: `local p = {
    background = "#09111b",
    panel_a = "#101b29",
    panel_b = "#0d1825",
    rule = "#26384e",
    text = "#f4f7fb",
    muted = "#91a1b5",
    cyan = "#4cc9f0",
    magenta = "#f72585",
    gold = "#ffd166",
}
local function contour(scene, color, id)
    return scene:path {
        commands = {
            { type = "move", to = { -1.10, -0.30 } },
            {
                type = "cubic",
                control1 = { -1.05, 0.95 },
                control2 = { -0.25, 1.25 },
                to = {
                    0.15,
                    0.55,
                },
            },
            { type = "quadratic", control = { 0.85, -0.35 }, to = { 1.10, 0.35 } },
            { type = "line", to = { 0.78, -0.88 } },
            { type = "quadratic", control = { -0.10, -1.18 }, to = { -1.10, -0.30 } },
            { type = "close" },
        },
        samples = 36,
        fill = color .. "42",
        stroke = color,
        width = 5,
        id = id,
    }
end
local function timeline(scene, split, color, left, right, caption)
    local start_x, end_x = -1.30, 1.30
    local division = start_x + (end_x - start_x) * split
    scene:line { from = { start_x, -1.52 }, to = { end_x, -1.52 }, stroke = p.rule, width = 6 }
    scene:line {
        from = { start_x, -1.52 },
        to = { division - 0.03, -1.52 },
        stroke = color,
        width = 6,
    }
    scene:line {
        from = { division + 0.03, -1.52 },
        to = { end_x, -1.52 },
        stroke = color .. "88",
        width = 6,
    }
    scene:text {
        text = left,
        point = { (start_x + division) * 0.5, -1.78 },
        font = "Pretendard",
        size = 9,
        fill = color,
    }
    scene:text {
        text = right,
        point = { (division + end_x) * 0.5, -1.78 },
        font = "Pretendard",
        size = 9,
        fill = color,
    }
    scene:text {
        text = caption,
        point = { 0, -2.20 },
        font = "Pretendard",
        size = 10,
        fill = p.muted,
    }
end
local function panel(index, title, color, background, id)
    local scene = tmath.scene {
        width = 320,
        height = 410,
        fps = 60,
        background = background,
        camera = { mode = "fixed", view = "2d", target = { 0, 0 }, height = 5.2 },
    }
    scene:rectangle {
        center = { 0, 0 },
        size = { 3.72, 4.78 },
        corner = 0.16,
        fill = "#00000000",
        stroke = p.rule,
        width = 2,
        layer = -2,
        id = id .. "-frame",
    }
    scene:text {
        text = index,
        point = { -1.48, 2.14 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 11,
        fill = color,
        id = id .. "-index",
    }
    scene:text {
        text = title,
        point = { 0, 2.14 },
        font = "Pretendard",
        size = 12,
        fill = p.text,
        id = id .. "-title",
    }
    scene:line {
        from = { -1.48, 1.78 },
        to = { 1.48, 1.78 },
        stroke = p.rule,
        width = 1.5,
        id = id .. "-rule",
    }
    return scene
end
local explicit = panel("01", "MANUAL SEQUENCE", p.cyan, p.panel_a, "explicit")
local explicit_path = contour(explicit, p.cyan, "explicit-path")
timeline(explicit, 0.52, p.cyan, "DRAW", "FILL", "create  >  pause  >  fill_reveal")
explicit:wait(0.35)
explicit:create(explicit_path, 0.58, "linear")
explicit:wait(0.16)
explicit:fill_reveal(explicit_path, 0.66, "ease_out")
explicit:wait(0.65)
local combined = panel("02", "COMBINED PHASES", p.magenta, p.panel_b, "combined")
local combined_path = contour(combined, p.magenta, "combined-path")
timeline(combined, 2 / 3, p.magenta, "2/3 BORDER", "1/3 FILL", "draw_border_then_fill · one clip")
combined:wait(0.35)
combined:draw_border_then_fill(combined_path, 1.40, "ease_in_out")
combined:wait(0.65)
local curved = panel("03", "DIRECTION + CURVE", p.gold, p.panel_a, "curved")
local curved_path = contour(curved, p.gold, "curved-path")
timeline(curved, 2 / 3, p.gold, "CLOCKWISE", "FILL", "snappy curve · strength 0.90")
curved:point {
    point = { -1.10, -0.30 },
    fill = p.gold,
    radius = 5,
    layer = 5,
    id = "direction-start",
}
curved:text {
    text = "CW",
    point = { -1.46, -0.06 },
    font = "Pretendard",
    size = 10,
    fill = p.gold,
    id = "direction-label",
}
curved:wait(0.35)
curved:draw_border_then_fill(
    curved_path,
    1.40,
    { preset = "snappy", strength = 0.90 },
    0,
    "clockwise"
)
curved:wait(0.65)
local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 60,
    background = p.background,
    loop = false,
    camera = { mode = "fixed", view = "2d", target = { 0, 0 }, height = 7 },
}
scene:text {
    text = "PATH TO FILL · SIDE BY SIDE",
    point = { -5.70, 2.95 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 27,
    fill = p.text,
    id = "title",
}
scene:text {
    text = "same contour · same start time · three timing models",
    point = { -5.68, 2.47 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = p.muted,
    id = "subtitle",
}
scene:line { from = { -5.70, 2.13 }, to = { 5.70, 2.13 }, stroke = p.rule, width = 2, id = "divider" }
scene:viewport(explicit, { x = 0, y = 0.245, width = 1 / 3, height = 0.755 })
scene:viewport(combined, { x = 1 / 3, y = 0.245, width = 1 / 3, height = 0.755 })
scene:viewport(curved, { x = 2 / 3, y = 0.245, width = 1 / 3, height = 0.755 })
return scene
`,
        js: `const p = {
    background: "#09111b",
    panelA: "#101b29",
    panelB: "#0d1825",
    rule: "#26384e",
    text: "#f4f7fb",
    muted: "#91a1b5",
    cyan: "#4cc9f0",
    magenta: "#f72585",
    gold: "#ffd166",
};
const contour = (scene, color, id) =>
    scene.path({
        commands: [
            { type: "move", to: [-1.1, -0.3] },
            { type: "cubic", control1: [-1.05, 0.95], control2: [-0.25, 1.25], to: [0.15, 0.55] },
            { type: "quadratic", control: [0.85, -0.35], to: [1.1, 0.35] },
            { type: "line", to: [0.78, -0.88] },
            { type: "quadratic", control: [-0.1, -1.18], to: [-1.1, -0.3] },
            { type: "close" },
        ],
        samples: 36,
        fill: color + "42",
        stroke: color,
        width: 5,
        id,
    });
const timeline = (scene, split, color, left, right, caption) => {
    const startX = -1.3,
        endX = 1.3,
        division = startX + (endX - startX) * split;
    scene.line({ from: [startX, -1.52], to: [endX, -1.52], stroke: p.rule, width: 6 });
    scene.line({ from: [startX, -1.52], to: [division - 0.03, -1.52], stroke: color, width: 6 });
    scene.line({
        from: [division + 0.03, -1.52],
        to: [endX, -1.52],
        stroke: color + "88",
        width: 6,
    });
    scene.text({
        text: left,
        point: [(startX + division) * 0.5, -1.78],
        font: "Pretendard",
        size: 9,
        fill: color,
    });
    scene.text({
        text: right,
        point: [(division + endX) * 0.5, -1.78],
        font: "Pretendard",
        size: 9,
        fill: color,
    });
    scene.text({ text: caption, point: [0, -2.2], font: "Pretendard", size: 10, fill: p.muted });
};
const panel = (index, title, color, background, id) => {
    const scene = tmath.scene({
        width: 320,
        height: 410,
        fps: 60,
        background,
        camera: { mode: "fixed", view: "2d", target: [0, 0], height: 5.2 },
    });
    scene.rectangle({
        center: [0, 0],
        size: [3.72, 4.78],
        corner: 0.16,
        fill: "#00000000",
        stroke: p.rule,
        width: 2,
        layer: -2,
        id: id + "-frame",
    });
    scene.text({
        text: index,
        point: [-1.48, 2.14],
        align: [0, 0.5],
        font: "Pretendard",
        size: 11,
        fill: color,
        id: id + "-index",
    });
    scene.text({
        text: title,
        point: [0, 2.14],
        font: "Pretendard",
        size: 12,
        fill: p.text,
        id: id + "-title",
    });
    scene.line({
        from: [-1.48, 1.78],
        to: [1.48, 1.78],
        stroke: p.rule,
        width: 1.5,
        id: id + "-rule",
    });
    return scene;
};
const explicit = panel("01", "MANUAL SEQUENCE", p.cyan, p.panelA, "explicit");
const explicitPath = contour(explicit, p.cyan, "explicit-path");
timeline(explicit, 0.52, p.cyan, "DRAW", "FILL", "create  >  pause  >  fill_reveal");
explicit.wait(0.35);
explicit.create(explicitPath, 0.58, "linear");
explicit.wait(0.16);
explicit.fillReveal(explicitPath, 0.66, "ease_out");
explicit.wait(0.65);
const combined = panel("02", "COMBINED PHASES", p.magenta, p.panelB, "combined");
const combinedPath = contour(combined, p.magenta, "combined-path");
timeline(combined, 2 / 3, p.magenta, "2/3 BORDER", "1/3 FILL", "draw_border_then_fill · one clip");
combined.wait(0.35);
combined.drawBorderThenFill(combinedPath, 1.4, "ease_in_out");
combined.wait(0.65);
const curved = panel("03", "DIRECTION + CURVE", p.gold, p.panelA, "curved");
const curvedPath = contour(curved, p.gold, "curved-path");
timeline(curved, 2 / 3, p.gold, "CLOCKWISE", "FILL", "snappy curve · strength 0.90");
curved.point({ point: [-1.1, -0.3], fill: p.gold, radius: 5, layer: 5, id: "direction-start" });
curved.text({
    text: "CW",
    point: [-1.46, -0.06],
    font: "Pretendard",
    size: 10,
    fill: p.gold,
    id: "direction-label",
});
curved.wait(0.35);
curved.drawBorderThenFill(curvedPath, 1.4, tmath.animCurve.preset("snappy", 0.9), 0, "clockwise");
curved.wait(0.65);
const scene = tmath.scene({
    width: 960,
    height: 540,
    fps: 60,
    background: p.background,
    loop: false,
    camera: { mode: "fixed", view: "2d", target: [0, 0], height: 7 },
});
scene.text({
    text: "PATH TO FILL · SIDE BY SIDE",
    point: [-5.7, 2.95],
    align: [0, 0.5],
    font: "Pretendard",
    size: 27,
    fill: p.text,
    id: "title",
});
scene.text({
    text: "same contour · same start time · three timing models",
    point: [-5.68, 2.47],
    align: [0, 0.5],
    font: "Pretendard",
    size: 13,
    fill: p.muted,
    id: "subtitle",
});
scene.line({ from: [-5.7, 2.13], to: [5.7, 2.13], stroke: p.rule, width: 2, id: "divider" });
scene.viewport(explicit, { x: 0, y: 0.245, width: 1 / 3, height: 0.755 });
scene.viewport(combined, { x: 1 / 3, y: 0.245, width: 1 / 3, height: 0.755 });
scene.viewport(curved, { x: 2 / 3, y: 0.245, width: 1 / 3, height: 0.755 });
return scene;
`,
    },
    {
        id: "scene-transition",
        title: "Scene to scene · many / few / more",
        description:
            "Reuse A, B, and C by semantic ID while unmatched objects leave or enter across independently authored scenes.",
        category: "Animation",
        dimension: "2D",
        fonts: PRETENDARD,
        lua: `local p = {
    background = "#08111c",
    text = "#f4f7fb",
    muted = "#8fa1b7",
    rule = "#293b50",
    cyan = "#4cc9f0",
    magenta = "#f72585",
    gold = "#ffd166",
    green = "#7bd88f",
    retired = "#60748a",
}
local function polygon(center, radius, sides, rotation)
    local points = {}
    for i = 0, sides - 1 do
        local angle = rotation + i * 2 * math.pi / sides
        points[#points + 1] =
            { center[1] + radius * math.cos(angle), center[2] + radius * math.sin(angle) }
    end
    return points
end
local function stage(index, title, count, accent, summary)
    local s = tmath.scene {
        width = 960,
        height = 540,
        fps = 60,
        background = p.background,
        camera = { mode = "fixed", view = "2d", target = { 0, 0 }, height = 8 },
    }
    s:text {
        text = "SEMANTIC SCENE TRANSITION",
        point = { -6.45, 3.25 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 13,
        fill = p.muted,
        id = "chrome-kicker",
    }
    s:text {
        text = index,
        point = { -6.45, 2.75 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 13,
        fill = accent,
        id = "stage-index",
    }
    s:text {
        text = title,
        point = { -5.45, 2.75 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 28,
        fill = p.text,
        id = "stage-title",
    }
    s:rectangle {
        center = { 5.38, 2.86 },
        size = { 2.15, 0.62 },
        corner = 0.14,
        fill = accent .. "20",
        stroke = accent,
        width = 2,
        id = "count-chip",
    }
    s:text {
        text = count,
        point = { 5.38, 2.86 },
        font = "Pretendard",
        size = 13,
        fill = accent,
        id = "count-label",
    }
    s:line {
        from = { -6.45, 2.25 },
        to = { 6.45, 2.25 },
        stroke = p.rule,
        width = 2,
        id = "chrome-rule",
    }
    s:text {
        text = summary,
        point = { 0, -3.13 },
        font = "Pretendard",
        size = 14,
        fill = p.muted,
        id = "stage-summary",
    }
    return s
end
local function node(s, item)
    s:polygon {
        points = polygon(item.center, item.radius, item.sides, item.rotation or 0),
        fill = item.color .. "24",
        stroke = item.color,
        width = item.width or 4,
        id = item.id,
    }
    s:text {
        text = item.label,
        point = item.center,
        font = "Pretendard",
        size = item.size or 19,
        fill = p.text,
        id = item.id .. "-label",
    }
end
local function link(s, a, b, color, id, bend)
    local x = (a[1] + b[1]) * 0.5
    local y = (a[2] + b[2]) * 0.5 + bend
    s:curve {
        from = a,
        control1 = { x - 0.45, y },
        control2 = { x + 0.45, y },
        to = b,
        samples = 36,
        stroke = color,
        width = 3,
        layer = -1,
        id = id,
    }
end

local many = stage(
    "01 / 03",
    "DISCOVER / MANY",
    "7 OBJECTS",
    p.cyan,
    "retain A / B / C by id   ·   D / E / F / G leave the next scene"
)
local ma, mb, mc = { -3.55, 0.45 }, { -0.2, 1.02 }, { 3.35, 0.30 }
link(many, ma, mb, p.cyan, "route-ab", 0.48)
link(many, mb, mc, p.magenta, "route-bc", -0.38)
for _, item in ipairs {
    {
        id = "node-a",
        label = "A",
        center = ma,
        radius = 0.82,
        sides = 8,
        rotation = math.pi / 8,
        color = p.cyan,
    },
    {
        id = "node-b",
        label = "B",
        center = mb,
        radius = 0.88,
        sides = 4,
        rotation = math.pi / 4,
        color = p.magenta,
    },
    { id = "node-c", label = "C", center = mc, radius = 0.80, sides = 6, color = p.gold },
    {
        id = "candidate-d",
        label = "D",
        center = { -4.70, -1.52 },
        radius = 0.43,
        sides = 5,
        rotation = -0.2,
        color = p.retired,
        width = 2.5,
        size = 13,
    },
    {
        id = "candidate-e",
        label = "E",
        center = { -2.05, -1.35 },
        radius = 0.43,
        sides = 6,
        color = p.retired,
        width = 2.5,
        size = 13,
    },
    {
        id = "candidate-f",
        label = "F",
        center = { 1.15, -1.48 },
        radius = 0.43,
        sides = 4,
        rotation = math.pi / 4,
        color = p.retired,
        width = 2.5,
        size = 13,
    },
    {
        id = "candidate-g",
        label = "G",
        center = { 4.65, -1.42 },
        radius = 0.43,
        sides = 7,
        color = p.retired,
        width = 2.5,
        size = 13,
    },
} do
    node(many, item)
end

local few = stage(
    "02 / 03",
    "FOCUS / FEW",
    "3 REUSED",
    p.magenta,
    "same ids, new geometry   ·   matched contours move and morph instead of redrawing"
)
local fa, fb, fc = { -2.85, -0.15 }, { 0, 0.72 }, { 2.85, -0.15 }
link(few, fa, fb, p.cyan, "route-ab", 0.62)
link(few, fb, fc, p.magenta, "route-bc", -0.52)
node(few, {
    id = "node-a",
    label = "A",
    center = fa,
    radius = 1.02,
    sides = 6,
    rotation = math.pi / 6,
    color = p.cyan,
})
node(few, {
    id = "node-b",
    label = "B",
    center = fb,
    radius = 1.05,
    sides = 12,
    rotation = math.pi / 12,
    color = p.magenta,
})
node(few, {
    id = "node-c",
    label = "C",
    center = fc,
    radius = 1.02,
    sides = 5,
    rotation = -math.pi / 2,
    color = p.gold,
})

local expanded = stage(
    "03 / 03",
    "EXPAND / MORE",
    "9 OBJECTS",
    p.green,
    "morph A / B / C   ·   create six objects that have no predecessor"
)
local ea, eb, ec = { -3.55, 0.75 }, { 0, 1.18 }, { 3.55, 0.75 }
link(expanded, ea, eb, p.cyan, "route-ab", 0.35)
link(expanded, eb, ec, p.magenta, "route-bc", -0.30)
node(expanded, {
    id = "node-a",
    label = "A",
    center = ea,
    radius = 0.78,
    sides = 5,
    rotation = -math.pi / 2,
    color = p.cyan,
})
node(expanded, {
    id = "node-b",
    label = "B",
    center = eb,
    radius = 0.82,
    sides = 8,
    rotation = math.pi / 8,
    color = p.magenta,
})
node(expanded, {
    id = "node-c",
    label = "C",
    center = ec,
    radius = 0.78,
    sides = 4,
    rotation = math.pi / 4,
    color = p.gold,
})
local additions = {
    { "D", { -4.85, -1.28 }, p.green, 6, ea },
    { "E", { -2.65, -1.65 }, p.green, 4, ea },
    { "F", { -0.95, -1.25 }, p.cyan, 5, eb },
    { "G", { 0.95, -1.25 }, p.magenta, 7, eb },
    { "H", { 2.65, -1.65 }, p.gold, 4, ec },
    { "I", { 4.85, -1.28 }, p.gold, 6, ec },
}
for i, item in ipairs(additions) do
    link(expanded, item[5], item[2], item[3], "new-route-" .. i, -0.08)
    node(expanded, {
        id = "new-" .. string.lower(item[1]),
        label = item[1],
        center = item[2],
        radius = 0.46,
        sides = item[4],
        rotation = math.pi / item[4],
        color = item[3],
        width = 2.5,
        size = 13,
    })
end

local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 60,
    background = p.background,
    loop = false,
    camera = { mode = "fixed", view = "2d", target = { 0, 0 }, height = 8 },
}
scene:rectangle {
    center = { 0, 0 },
    size = { 13.75, 7.55 },
    corner = 0.10,
    fill = "#00000000",
    stroke = p.rule,
    width = 1,
    id = "outer-frame",
}
scene:scene_transition(
    { many, few, expanded },
    { duration = 1.4, hold = 0.9, curve = { preset = "smooth", strength = 1 } }
)
return scene
`,
        js: `const p = {
    background: "#08111c",
    text: "#f4f7fb",
    muted: "#8fa1b7",
    rule: "#293b50",
    cyan: "#4cc9f0",
    magenta: "#f72585",
    gold: "#ffd166",
    green: "#7bd88f",
    retired: "#60748a",
};
const polygon = (center, radius, sides, rotation = 0) =>
    Array.from({ length: sides }, (_, i) => {
        const angle = rotation + (i * 2 * Math.PI) / sides;
        return [center[0] + radius * Math.cos(angle), center[1] + radius * Math.sin(angle)];
    });
const stage = (index, title, count, accent, summary) => {
    const s = tmath.scene({
        width: 960,
        height: 540,
        fps: 60,
        background: p.background,
        camera: { mode: "fixed", view: "2d", target: [0, 0], height: 8 },
    });
    s.text({
        text: "SEMANTIC SCENE TRANSITION",
        point: [-6.45, 3.25],
        align: [0, 0.5],
        font: "Pretendard",
        size: 13,
        fill: p.muted,
        id: "chrome-kicker",
    });
    s.text({
        text: index,
        point: [-6.45, 2.75],
        align: [0, 0.5],
        font: "Pretendard",
        size: 13,
        fill: accent,
        id: "stage-index",
    });
    s.text({
        text: title,
        point: [-5.45, 2.75],
        align: [0, 0.5],
        font: "Pretendard",
        size: 28,
        fill: p.text,
        id: "stage-title",
    });
    s.rectangle({
        center: [5.38, 2.86],
        size: [2.15, 0.62],
        corner: 0.14,
        fill: accent + "20",
        stroke: accent,
        width: 2,
        id: "count-chip",
    });
    s.text({
        text: count,
        point: [5.38, 2.86],
        font: "Pretendard",
        size: 13,
        fill: accent,
        id: "count-label",
    });
    s.line({ from: [-6.45, 2.25], to: [6.45, 2.25], stroke: p.rule, width: 2, id: "chrome-rule" });
    s.text({
        text: summary,
        point: [0, -3.13],
        font: "Pretendard",
        size: 14,
        fill: p.muted,
        id: "stage-summary",
    });
    return s;
};
const node = (s, item) => {
    s.polygon({
        points: polygon(item.center, item.radius, item.sides, item.rotation),
        fill: item.color + "24",
        stroke: item.color,
        width: item.width ?? 4,
        id: item.id,
    });
    s.text({
        text: item.label,
        point: item.center,
        font: "Pretendard",
        size: item.size ?? 19,
        fill: p.text,
        id: item.id + "-label",
    });
};
const link = (s, a, b, color, id, bend) => {
    const x = (a[0] + b[0]) * 0.5,
        y = (a[1] + b[1]) * 0.5 + bend;
    s.curve({
        from: a,
        control1: [x - 0.45, y],
        control2: [x + 0.45, y],
        to: b,
        samples: 36,
        stroke: color,
        width: 3,
        layer: -1,
        id,
    });
};

const many = stage(
        "01 / 03",
        "DISCOVER / MANY",
        "7 OBJECTS",
        p.cyan,
        "retain A / B / C by id   ·   D / E / F / G leave the next scene",
    ),
    ma = [-3.55, 0.45],
    mb = [-0.2, 1.02],
    mc = [3.35, 0.3];
link(many, ma, mb, p.cyan, "route-ab", 0.48);
link(many, mb, mc, p.magenta, "route-bc", -0.38);
[
    {
        id: "node-a",
        label: "A",
        center: ma,
        radius: 0.82,
        sides: 8,
        rotation: Math.PI / 8,
        color: p.cyan,
    },
    {
        id: "node-b",
        label: "B",
        center: mb,
        radius: 0.88,
        sides: 4,
        rotation: Math.PI / 4,
        color: p.magenta,
    },
    { id: "node-c", label: "C", center: mc, radius: 0.8, sides: 6, color: p.gold },
    {
        id: "candidate-d",
        label: "D",
        center: [-4.7, -1.52],
        radius: 0.43,
        sides: 5,
        rotation: -0.2,
        color: p.retired,
        width: 2.5,
        size: 13,
    },
    {
        id: "candidate-e",
        label: "E",
        center: [-2.05, -1.35],
        radius: 0.43,
        sides: 6,
        color: p.retired,
        width: 2.5,
        size: 13,
    },
    {
        id: "candidate-f",
        label: "F",
        center: [1.15, -1.48],
        radius: 0.43,
        sides: 4,
        rotation: Math.PI / 4,
        color: p.retired,
        width: 2.5,
        size: 13,
    },
    {
        id: "candidate-g",
        label: "G",
        center: [4.65, -1.42],
        radius: 0.43,
        sides: 7,
        color: p.retired,
        width: 2.5,
        size: 13,
    },
].forEach((item) => node(many, item));

const few = stage(
        "02 / 03",
        "FOCUS / FEW",
        "3 REUSED",
        p.magenta,
        "same ids, new geometry   ·   matched contours move and morph instead of redrawing",
    ),
    fa = [-2.85, -0.15],
    fb = [0, 0.72],
    fc = [2.85, -0.15];
link(few, fa, fb, p.cyan, "route-ab", 0.62);
link(few, fb, fc, p.magenta, "route-bc", -0.52);
node(few, {
    id: "node-a",
    label: "A",
    center: fa,
    radius: 1.02,
    sides: 6,
    rotation: Math.PI / 6,
    color: p.cyan,
});
node(few, {
    id: "node-b",
    label: "B",
    center: fb,
    radius: 1.05,
    sides: 12,
    rotation: Math.PI / 12,
    color: p.magenta,
});
node(few, {
    id: "node-c",
    label: "C",
    center: fc,
    radius: 1.02,
    sides: 5,
    rotation: -Math.PI / 2,
    color: p.gold,
});

const expanded = stage(
        "03 / 03",
        "EXPAND / MORE",
        "9 OBJECTS",
        p.green,
        "morph A / B / C   ·   create six objects that have no predecessor",
    ),
    ea = [-3.55, 0.75],
    eb = [0, 1.18],
    ec = [3.55, 0.75];
link(expanded, ea, eb, p.cyan, "route-ab", 0.35);
link(expanded, eb, ec, p.magenta, "route-bc", -0.3);
node(expanded, {
    id: "node-a",
    label: "A",
    center: ea,
    radius: 0.78,
    sides: 5,
    rotation: -Math.PI / 2,
    color: p.cyan,
});
node(expanded, {
    id: "node-b",
    label: "B",
    center: eb,
    radius: 0.82,
    sides: 8,
    rotation: Math.PI / 8,
    color: p.magenta,
});
node(expanded, {
    id: "node-c",
    label: "C",
    center: ec,
    radius: 0.78,
    sides: 4,
    rotation: Math.PI / 4,
    color: p.gold,
});
const additions = [
    ["D", [-4.85, -1.28], p.green, 6, ea],
    ["E", [-2.65, -1.65], p.green, 4, ea],
    ["F", [-0.95, -1.25], p.cyan, 5, eb],
    ["G", [0.95, -1.25], p.magenta, 7, eb],
    ["H", [2.65, -1.65], p.gold, 4, ec],
    ["I", [4.85, -1.28], p.gold, 6, ec],
];
additions.forEach(([label, center, color, sides, parent], i) => {
    link(expanded, parent, center, color, "new-route-" + (i + 1), -0.08);
    node(expanded, {
        id: "new-" + label.toLowerCase(),
        label,
        center,
        radius: 0.46,
        sides,
        rotation: Math.PI / sides,
        color,
        width: 2.5,
        size: 13,
    });
});

const scene = tmath.scene({
    width: 960,
    height: 540,
    fps: 60,
    background: p.background,
    loop: false,
    camera: { mode: "fixed", view: "2d", target: [0, 0], height: 8 },
});
scene.rectangle({
    center: [0, 0],
    size: [13.75, 7.55],
    corner: 0.1,
    fill: "#00000000",
    stroke: p.rule,
    width: 1,
    id: "outer-frame",
});
scene.sceneTransition([many, few, expanded], {
    duration: 1.4,
    hold: 0.9,
    curve: tmath.animCurve.preset("smooth"),
});
return scene;
`,
    },
    {
        id: "animation-gallery",
        title: "Animation primitives",
        description:
            "Compare directional creation, fades, growth, shape morphs, replacement semantics, and temporary indication in six isolated timelines.",
        category: "Animation",
        dimension: "2D",
        fonts: PRETENDARD,
        lua: `local p = {
    background = "#0b111a",
    panel_a = "#101925",
    panel_b = "#0f1722",
    rule = "#263447",
    text = "#f4f7fb",
    muted = "#94a3b8",
    cyan = "#4cc9f0",
    magenta = "#f72585",
    gold = "#ffd166",
    green = "#7bd88f",
    red = "#ff6b6b",
}

local function make_panel(background, prefix, index, title, caption)
    local panel = tmath.scene {
        width = 320,
        height = 270,
        fps = 30,
        background = background,
        camera = { mode = "fixed", view = "2d", target = { 0, 0 }, height = 6.4 },
    }
    panel:text {
        text = index,
        point = { -3.45, 2.72 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 11,
        fill = p.muted,
        id = prefix .. "-step",
    }
    panel:text {
        text = title,
        point = { -2.75, 2.72 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 18,
        fill = p.text,
        id = prefix .. "-title",
    }
    panel:line {
        from = { -3.45, 2.28 },
        to = { 3.45, 2.28 },
        stroke = p.rule,
        width = 1.5,
        id = prefix .. "-rule",
    }
    panel:text {
        text = caption,
        point = { 0, -2.68 },
        align = { 0.5, 0.5 },
        font = "Pretendard",
        size = 11,
        fill = p.muted,
        id = prefix .. "-caption",
    }
    return panel
end

local function direction_panel(background, index, title, direction, color)
    local panel = tmath.scene {
        width = 160,
        height = 270,
        fps = 30,
        background = background,
        camera = { mode = "fixed", view = "2d", target = { 0, 0 }, height = 6.4 },
    }
    panel:text {
        text = index,
        point = { -1.68, 2.72 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 10,
        fill = p.muted,
        id = "direction-" .. direction .. "-step",
    }
    panel:text {
        text = title,
        point = { -0.90, 2.72 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 12,
        fill = p.text,
        id = "direction-" .. direction .. "-title",
    }
    panel:line {
        from = { -1.68, 2.28 },
        to = { 1.68, 2.28 },
        stroke = p.rule,
        width = 1.5,
        id = "direction-" .. direction .. "-rule",
    }
    panel:circle {
        center = { 0, -0.12 },
        radius = 1.05,
        fill = "#00000000",
        stroke = p.rule,
        width = 2,
        id = "direction-" .. direction .. "-guide",
    }
    local path = panel:circle {
        center = { 0, -0.12 },
        radius = 1.05,
        fill = "#00000000",
        stroke = color,
        width = 5,
        id = "direction-" .. direction .. "-path",
    }
    panel:point {
        point = { 1.05, -0.12 },
        fill = p.gold,
        radius = 5,
        layer = 6,
        id = "direction-" .. direction .. "-start",
    }
    local tangentFrom = direction == "counterclockwise" and { 1.38, -0.46 } or { 1.38, 0.22 }
    local tangentTo = direction == "counterclockwise" and { 1.38, 0.22 } or { 1.38, -0.46 }
    panel:arrow {
        from = tangentFrom,
        to = tangentTo,
        color = color,
        width = 3,
        tip = 9,
        id = "direction-" .. direction .. "-tangent",
    }
    panel:text {
        text = direction == "counterclockwise" and "CCW" or "CW",
        point = { 0, -1.62 },
        font = "Pretendard",
        size = 17,
        fill = color,
        id = "direction-" .. direction .. "-label",
    }
    panel:text {
        text = "CREATE / UNCREATE",
        point = { 0, -2.68 },
        align = { 0.5, 0.5 },
        font = "Pretendard",
        size = 10,
        fill = p.muted,
        id = "direction-" .. direction .. "-caption",
    }

    panel:wait(0.35)
    panel:create(path, 1.20, "linear", 0, direction)
    panel:wait(0.35)
    panel:uncreate(path, 1.00, "linear", 0, direction)
    panel:wait(0.55)
    return panel
end

local direction = tmath.scene {
    width = 320,
    height = 270,
    fps = 30,
    background = p.panel_a,
    camera = { mode = "fixed", view = "2d", target = { 0, 0 }, height = 6.4 },
}
local ccw = direction_panel(p.panel_a, "01A", "CCW PATH", "counterclockwise", p.cyan)
local cw = direction_panel(p.panel_b, "01B", "CW PATH", "clockwise", p.magenta)
direction:viewport(ccw, { x = 0, y = 0, width = 0.5, height = 1 })
direction:viewport(cw, { x = 0.5, y = 0, width = 0.5, height = 1 })

local fade = make_panel(p.panel_b, "fade", "02", "FADE IN / OUT", "opacity + shift + scale")
local fadeCard = fade:group { id = "fade-card" }
fadeCard:rectangle {
    center = { 0, -0.12 },
    size = { 3.45, 1.48 },
    corner = 0.18,
    fill = "#4cc9f02e",
    stroke = p.cyan,
    width = 3,
    id = "fade-card-body",
}
fadeCard:text {
    text = "OPACITY",
    point = { 0, 0.06 },
    font = "Pretendard",
    size = 22,
    fill = p.text,
    id = "fade-card-label",
}
fadeCard:text {
    text = "0  ->  1  ->  0",
    point = { 0, -0.48 },
    font = "Pretendard",
    size = 14,
    fill = p.cyan,
    id = "fade-opacity-caption",
}
fade:wait(0.35)
fade:fade_in(fadeCard, {
    shift = { 0, -0.42 },
    scale = 0.86,
    duration = 1.20,
    easing = "ease_out",
})
fade:wait(0.35)
fade:fade_out(fadeCard, {
    shift = { 0, 0.42 },
    scale = 0.86,
    duration = 1.00,
    easing = "ease_in",
})
fade:wait(0.55)

local grow = make_panel(p.panel_a, "grow", "03", "GROW / SHRINK", "fixed center anchor")
local growSubject = grow:group { id = "grow-subject" }
growSubject:circle {
    center = { 0, -0.12 },
    radius = 1.02,
    fill = "#f7258533",
    stroke = p.magenta,
    width = 4,
    id = "grow-subject-body",
}
growSubject:text {
    text = "CENTER",
    point = { 0, -0.58 },
    font = "Pretendard",
    size = 13,
    fill = p.magenta,
    id = "grow-subject-label",
}
growSubject:point {
    point = { 0, -0.12 },
    fill = p.gold,
    radius = 4,
    layer = 8,
    id = "grow-anchor",
}
grow:wait(0.35)
grow:grow_from_center(growSubject, 1.20, "ease_out")
grow:wait(0.35)
grow:shrink_to_center(growSubject, 1.00, "ease_in")
grow:wait(0.55)

local function radial_points(radius, square, count)
    local points = {}
    for i = 0, count - 1 do
        local angle = 6.28318530718 * i / count
        local x = math.cos(angle)
        local y = math.sin(angle)
        local scale = radius
        if square then
            scale = radius / math.max(math.abs(x), math.abs(y))
        end
        points[#points + 1] = { x * scale, y * scale - 0.12 }
    end
    return points
end

local function star_points(outer, inner, count)
    local points = {}
    for i = 0, count - 1 do
        local angle = 6.28318530718 * i / count
        local radius = i % 2 == 0 and outer or inner
        points[#points + 1] = { math.cos(angle) * radius, math.sin(angle) * radius - 0.12 }
    end
    return points
end

local morph = make_panel(p.panel_b, "morph", "04", "MORPH", "single contour / target identity")
local morphSubject = morph:polygon {
    points = radial_points(1.02, false, 32),
    fill = "#4cc9f033",
    stroke = p.cyan,
    width = 4,
    id = "morph-subject",
}
morph:text {
    text = "A",
    point = { -1.05, -1.73 },
    font = "Pretendard",
    size = 16,
    fill = p.cyan,
    id = "morph-id-a0",
}
morph:arrow {
    from = { -0.68, -1.70 },
    to = { -0.30, -1.70 },
    color = p.muted,
    width = 2,
    tip = 7,
    id = "morph-flow-ab",
}
morph:text {
    text = "B",
    point = { 0, -1.73 },
    font = "Pretendard",
    size = 16,
    fill = p.green,
    id = "morph-id-b",
}
morph:arrow {
    from = { 0.30, -1.70 },
    to = { 0.68, -1.70 },
    color = p.muted,
    width = 2,
    tip = 7,
    id = "morph-flow-ba",
}
morph:text {
    text = "A",
    point = { 1.05, -1.73 },
    font = "Pretendard",
    size = 16,
    fill = p.cyan,
    id = "morph-id-a1",
}
morph:wait(0.35)
local morphSquare = morph:polygon {
    points = radial_points(1.02, true, 32),
    fill = "#7bd88f33",
    stroke = p.green,
    width = 4,
    id = "morph-square-template",
}
morph:morph(morphSubject, morphSquare, 1.20, "ease_in_out")
morph:wait(0.35)
local morphOrigin = morph:polygon {
    points = radial_points(1.02, false, 32),
    fill = "#4cc9f033",
    stroke = p.cyan,
    width = 4,
    id = "morph-origin-template",
}
morph:morph(morphSquare, morphOrigin, 1.00, "ease_in_out")
morph:wait(0.55)

local replacement =
    make_panel(p.panel_a, "replacement", "05", "REPLACEMENT", "A leaves / B owns the next beat")
local replacementSource = replacement:polygon {
    points = radial_points(0.98, false, 16),
    fill = "#ff6b6b33",
    stroke = p.red,
    width = 4,
    id = "replacement-source",
}
replacement:text {
    text = "A / SOURCE",
    point = { -1.65, -1.92 },
    align = { 0.5, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = p.red,
    id = "replacement-source-badge",
}
replacement:arrow {
    from = { -0.48, -1.90 },
    to = { 0.48, -1.90 },
    color = p.muted,
    width = 2,
    tip = 8,
    id = "replacement-flow",
}
replacement:text {
    text = "B / TARGET",
    point = { 1.65, -1.92 },
    align = { 0.5, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = p.green,
    id = "replacement-target-badge",
}
replacement:wait(0.35)
local replacementTarget = replacement:polygon {
    points = star_points(1.08, 0.62, 16),
    fill = "#7bd88f33",
    stroke = p.green,
    width = 4,
    id = "replacement-target",
}
replacement:replacement_transform(replacementSource, replacementTarget, 1.20, "ease_in_out")
replacement:wait(0.35)
replacement:indicate(replacementTarget, {
    color = p.gold,
    scale = 1.16,
    duration = 1.00,
    easing = "ease_in_out",
})
replacement:wait(0.55)

local indicate =
    make_panel(p.panel_b, "indicate", "06", "INDICATE", "temporary emphasis / exact restore")
local function translate(x, y)
    return {
        1,
        0,
        0,
        x,
        0,
        1,
        0,
        y,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        1,
    }
end
local function node(scene, name, x, label, color)
    local item = scene:group { matrix = translate(x, -0.12), id = name }
    item:circle {
        center = { 0, 0 },
        radius = 0.56,
        fill = color .. "33",
        stroke = color,
        width = 3,
        id = name .. "-body",
    }
    item:text {
        text = label,
        point = { 0, 0 },
        font = "Pretendard",
        size = 18,
        fill = p.text,
        id = name .. "-label",
    }
    return item
end
local indicateLeft = node(indicate, "indicate-left", -1.75, "1", p.muted)
local indicateSubject = node(indicate, "indicate-subject", 0, "2", p.cyan)
local indicateResult = node(indicate, "indicate-result", 1.75, "3", p.green)
indicate:connector {
    from = indicateLeft,
    to = indicateSubject,
    padding = 0.08,
    stroke = p.rule,
    width = 2,
    id = "indicate-edge-left",
}
indicate:connector {
    from = indicateSubject,
    to = indicateResult,
    padding = 0.08,
    stroke = p.rule,
    width = 2,
    id = "indicate-edge-right",
}
indicate:wait(0.35)
indicate:indicate(indicateSubject, {
    color = p.gold,
    scale = 1.16,
    duration = 1.20,
    easing = "ease_in_out",
})
indicate:wait(0.35)
indicate:indicate(indicateResult, {
    color = p.gold,
    scale = 1.12,
    duration = 1.00,
    easing = "ease_in_out",
})
indicate:wait(0.55)

local gallery = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    background = p.background,
    camera = { mode = "fixed", view = "2d", target = { 0, 0 }, height = 6.4 },
}
gallery:viewport(direction, { x = 0, y = 0, width = 1 / 3, height = 0.5 })
gallery:viewport(fade, { x = 1 / 3, y = 0, width = 1 / 3, height = 0.5 })
gallery:viewport(grow, { x = 2 / 3, y = 0, width = 1 / 3, height = 0.5 })
gallery:viewport(morph, { x = 0, y = 0.5, width = 1 / 3, height = 0.5 })
gallery:viewport(replacement, { x = 1 / 3, y = 0.5, width = 1 / 3, height = 0.5 })
gallery:viewport(indicate, { x = 2 / 3, y = 0.5, width = 1 / 3, height = 0.5 })
return gallery
`,
        js: `const p = {
    background: "#0b111a",
    panel_a: "#101925",
    panel_b: "#0f1722",
    rule: "#263447",
    text: "#f4f7fb",
    muted: "#94a3b8",
    cyan: "#4cc9f0",
    magenta: "#f72585",
    gold: "#ffd166",
    green: "#7bd88f",
    red: "#ff6b6b",
};

const makePanel = (background, prefix, index, title, caption) => {
    const panel = tmath.scene({
        width: 320,
        height: 270,
        fps: 30,
        background,
        camera: { mode: "fixed", view: "2d", target: [0, 0], height: 6.4 },
    });
    panel.text({
        text: index,
        point: [-3.45, 2.72],
        align: [0, 0.5],
        font: "Pretendard",
        size: 11,
        fill: p.muted,
        id: prefix + "-step",
    });
    panel.text({
        text: title,
        point: [-2.75, 2.72],
        align: [0, 0.5],
        font: "Pretendard",
        size: 18,
        fill: p.text,
        id: prefix + "-title",
    });
    panel.line({
        from: [-3.45, 2.28],
        to: [3.45, 2.28],
        stroke: p.rule,
        width: 1.5,
        id: prefix + "-rule",
    });
    panel.text({
        text: caption,
        point: [0, -2.68],
        align: [0.5, 0.5],
        font: "Pretendard",
        size: 11,
        fill: p.muted,
        id: prefix + "-caption",
    });
    return panel;
};

const directionPanel = (background, index, title, direction, color) => {
    const panel = tmath.scene({
        width: 160,
        height: 270,
        fps: 30,
        background,
        camera: { mode: "fixed", view: "2d", target: [0, 0], height: 6.4 },
    });
    panel.text({
        text: index,
        point: [-1.68, 2.72],
        align: [0, 0.5],
        font: "Pretendard",
        size: 10,
        fill: p.muted,
        id: "direction-" + direction + "-step",
    });
    panel.text({
        text: title,
        point: [-0.9, 2.72],
        align: [0, 0.5],
        font: "Pretendard",
        size: 12,
        fill: p.text,
        id: "direction-" + direction + "-title",
    });
    panel.line({
        from: [-1.68, 2.28],
        to: [1.68, 2.28],
        stroke: p.rule,
        width: 1.5,
        id: "direction-" + direction + "-rule",
    });
    panel.circle({
        center: [0, -0.12],
        radius: 1.05,
        fill: "#00000000",
        stroke: p.rule,
        width: 2,
        id: "direction-" + direction + "-guide",
    });
    const path = panel.circle({
        center: [0, -0.12],
        radius: 1.05,
        fill: "#00000000",
        stroke: color,
        width: 5,
        id: "direction-" + direction + "-path",
    });
    panel.point({
        point: [1.05, -0.12],
        fill: p.gold,
        radius: 5,
        layer: 6,
        id: "direction-" + direction + "-start",
    });
    const tangentFrom = direction === "counterclockwise" ? [1.38, -0.46] : [1.38, 0.22];
    const tangentTo = direction === "counterclockwise" ? [1.38, 0.22] : [1.38, -0.46];
    panel.arrow({
        from: tangentFrom,
        to: tangentTo,
        color,
        width: 3,
        tip: 9,
        id: "direction-" + direction + "-tangent",
    });
    panel.text({
        text: direction === "counterclockwise" ? "CCW" : "CW",
        point: [0, -1.62],
        font: "Pretendard",
        size: 17,
        fill: color,
        id: "direction-" + direction + "-label",
    });
    panel.text({
        text: "CREATE / UNCREATE",
        point: [0, -2.68],
        align: [0.5, 0.5],
        font: "Pretendard",
        size: 10,
        fill: p.muted,
        id: "direction-" + direction + "-caption",
    });
    panel.wait(0.35);
    panel.create(path, 1.2, "linear", 0, direction);
    panel.wait(0.35);
    panel.uncreate(path, 1.0, "linear", 0, direction);
    panel.wait(0.55);
    return panel;
};

const direction = tmath.scene({
    width: 320,
    height: 270,
    fps: 30,
    background: p.panel_a,
    camera: { mode: "fixed", view: "2d", target: [0, 0], height: 6.4 },
});
const ccw = directionPanel(p.panel_a, "01A", "CCW PATH", "counterclockwise", p.cyan);
const cw = directionPanel(p.panel_b, "01B", "CW PATH", "clockwise", p.magenta);
direction.viewport(ccw, { x: 0, y: 0, width: 0.5, height: 1 });
direction.viewport(cw, { x: 0.5, y: 0, width: 0.5, height: 1 });

const fade = makePanel(p.panel_b, "fade", "02", "FADE IN / OUT", "opacity + shift + scale");
const fadeCard = fade.group({ id: "fade-card" });
fadeCard.rectangle({
    center: [0, -0.12],
    size: [3.45, 1.48],
    corner: 0.18,
    fill: "#4cc9f02e",
    stroke: p.cyan,
    width: 3,
    id: "fade-card-body",
});
fadeCard.text({
    text: "OPACITY",
    point: [0, 0.06],
    font: "Pretendard",
    size: 22,
    fill: p.text,
    id: "fade-card-label",
});
fadeCard.text({
    text: "0  ->  1  ->  0",
    point: [0, -0.48],
    font: "Pretendard",
    size: 14,
    fill: p.cyan,
    id: "fade-opacity-caption",
});
fade.wait(0.35);
fade.fadeIn(fadeCard, {
    shift: [0, -0.42],
    scale: 0.86,
    duration: 1.2,
    easing: "ease_out",
});
fade.wait(0.35);
fade.fadeOut(fadeCard, {
    shift: [0, 0.42],
    scale: 0.86,
    duration: 1.0,
    easing: "ease_in",
});
fade.wait(0.55);

const grow = makePanel(p.panel_a, "grow", "03", "GROW / SHRINK", "fixed center anchor");
const growSubject = grow.group({ id: "grow-subject" });
growSubject.circle({
    center: [0, -0.12],
    radius: 1.02,
    fill: "#f7258533",
    stroke: p.magenta,
    width: 4,
    id: "grow-subject-body",
});
growSubject.text({
    text: "CENTER",
    point: [0, -0.58],
    font: "Pretendard",
    size: 13,
    fill: p.magenta,
    id: "grow-subject-label",
});
growSubject.point({
    point: [0, -0.12],
    fill: p.gold,
    radius: 4,
    layer: 8,
    id: "grow-anchor",
});
grow.wait(0.35);
grow.growFromCenter(growSubject, 1.2, "ease_out");
grow.wait(0.35);
grow.shrinkToCenter(growSubject, 1.0, "ease_in");
grow.wait(0.55);

const radialPoints = (radius, square, count) =>
    Array.from({ length: count }, (_, index) => {
        const angle = (Math.PI * 2 * index) / count;
        const x = Math.cos(angle);
        const y = Math.sin(angle);
        const scale = square ? radius / Math.max(Math.abs(x), Math.abs(y)) : radius;
        return [x * scale, y * scale - 0.12];
    });
const starPoints = (outer, inner, count) =>
    Array.from({ length: count }, (_, index) => {
        const angle = (Math.PI * 2 * index) / count;
        const radius = index % 2 === 0 ? outer : inner;
        return [Math.cos(angle) * radius, Math.sin(angle) * radius - 0.12];
    });

const morph = makePanel(p.panel_b, "morph", "04", "MORPH", "single contour / target identity");
const morphSubject = morph.polygon({
    points: radialPoints(1.02, false, 32),
    fill: "#4cc9f033",
    stroke: p.cyan,
    width: 4,
    id: "morph-subject",
});
morph.text({
    text: "A",
    point: [-1.05, -1.73],
    font: "Pretendard",
    size: 16,
    fill: p.cyan,
    id: "morph-id-a0",
});
morph.arrow({
    from: [-0.68, -1.7],
    to: [-0.3, -1.7],
    color: p.muted,
    width: 2,
    tip: 7,
    id: "morph-flow-ab",
});
morph.text({
    text: "B",
    point: [0, -1.73],
    font: "Pretendard",
    size: 16,
    fill: p.green,
    id: "morph-id-b",
});
morph.arrow({
    from: [0.3, -1.7],
    to: [0.68, -1.7],
    color: p.muted,
    width: 2,
    tip: 7,
    id: "morph-flow-ba",
});
morph.text({
    text: "A",
    point: [1.05, -1.73],
    font: "Pretendard",
    size: 16,
    fill: p.cyan,
    id: "morph-id-a1",
});
morph.wait(0.35);
const morphSquare = morph.polygon({
    points: radialPoints(1.02, true, 32),
    fill: "#7bd88f33",
    stroke: p.green,
    width: 4,
    id: "morph-square-template",
});
morph.morph(morphSubject, morphSquare, 1.2, "ease_in_out");
morph.wait(0.35);
const morphOrigin = morph.polygon({
    points: radialPoints(1.02, false, 32),
    fill: "#4cc9f033",
    stroke: p.cyan,
    width: 4,
    id: "morph-origin-template",
});
morph.morph(morphSquare, morphOrigin, 1.0, "ease_in_out");
morph.wait(0.55);

const replacement = makePanel(
    p.panel_a,
    "replacement",
    "05",
    "REPLACEMENT",
    "A leaves / B owns the next beat",
);
const replacementSource = replacement.polygon({
    points: radialPoints(0.98, false, 16),
    fill: "#ff6b6b33",
    stroke: p.red,
    width: 4,
    id: "replacement-source",
});
replacement.text({
    text: "A / SOURCE",
    point: [-1.65, -1.92],
    align: [0.5, 0.5],
    font: "Pretendard",
    size: 13,
    fill: p.red,
    id: "replacement-source-badge",
});
replacement.arrow({
    from: [-0.48, -1.9],
    to: [0.48, -1.9],
    color: p.muted,
    width: 2,
    tip: 8,
    id: "replacement-flow",
});
replacement.text({
    text: "B / TARGET",
    point: [1.65, -1.92],
    align: [0.5, 0.5],
    font: "Pretendard",
    size: 13,
    fill: p.green,
    id: "replacement-target-badge",
});
replacement.wait(0.35);
const replacementTarget = replacement.polygon({
    points: starPoints(1.08, 0.62, 16),
    fill: "#7bd88f33",
    stroke: p.green,
    width: 4,
    id: "replacement-target",
});
replacement.replacementTransform(replacementSource, replacementTarget, 1.2, "ease_in_out");
replacement.wait(0.35);
replacement.indicate(replacementTarget, {
    color: p.gold,
    scale: 1.16,
    duration: 1.0,
    easing: "ease_in_out",
});
replacement.wait(0.55);

const indicate = makePanel(
    p.panel_b,
    "indicate",
    "06",
    "INDICATE",
    "temporary emphasis / exact restore",
);
const translate = (x, y) => [1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, 0, 0, 0, 0, 1];
const node = (scene, name, x, label, color) => {
    const item = scene.group({ matrix: translate(x, -0.12), id: name });
    item.circle({
        center: [0, 0],
        radius: 0.56,
        fill: color + "33",
        stroke: color,
        width: 3,
        id: name + "-body",
    });
    item.text({
        text: label,
        point: [0, 0],
        font: "Pretendard",
        size: 18,
        fill: p.text,
        id: name + "-label",
    });
    return item;
};
const indicateLeft = node(indicate, "indicate-left", -1.75, "1", p.muted);
const indicateSubject = node(indicate, "indicate-subject", 0, "2", p.cyan);
const indicateResult = node(indicate, "indicate-result", 1.75, "3", p.green);
indicate.connector(indicateLeft, indicateSubject, {
    padding: 0.08,
    stroke: p.rule,
    width: 2,
    id: "indicate-edge-left",
});
indicate.connector(indicateSubject, indicateResult, {
    padding: 0.08,
    stroke: p.rule,
    width: 2,
    id: "indicate-edge-right",
});
indicate.wait(0.35);
indicate.indicate(indicateSubject, {
    color: p.gold,
    scale: 1.16,
    duration: 1.2,
    easing: "ease_in_out",
});
indicate.wait(0.35);
indicate.indicate(indicateResult, {
    color: p.gold,
    scale: 1.12,
    duration: 1.0,
    easing: "ease_in_out",
});
indicate.wait(0.55);

const gallery = tmath.scene({
    width: 960,
    height: 540,
    fps: 30,
    background: p.background,
    camera: { mode: "fixed", view: "2d", target: [0, 0], height: 6.4 },
});
gallery.viewport(direction, { x: 0, y: 0, width: 1 / 3, height: 0.5 });
gallery.viewport(fade, { x: 1 / 3, y: 0, width: 1 / 3, height: 0.5 });
gallery.viewport(grow, { x: 2 / 3, y: 0, width: 1 / 3, height: 0.5 });
gallery.viewport(morph, { x: 0, y: 0.5, width: 1 / 3, height: 0.5 });
gallery.viewport(replacement, { x: 1 / 3, y: 0.5, width: 1 / 3, height: 0.5 });
gallery.viewport(indicate, { x: 2 / 3, y: 0.5, width: 1 / 3, height: 0.5 });
return gallery;
`,
    },
    {
        id: "anim-curve-effects",
        title: "Animation curves & strength",
        description:
            "Compare gentle, snappy, overshoot, bounce, elastic, and custom cubic-bezier timing with adjustable effect strength.",
        category: "Animation",
        dimension: "2D",
        fonts: PRETENDARD,
        lua: `local p = {
    a = "#0d1622",
    b = "#101a27",
    rule = "#253448",
    text = "#f4f7fb",
    muted = "#8fa1b7",
    cyan = "#4cc9f0",
    violet = "#9b8cff",
    magenta = "#f72585",
    gold = "#ffd166",
    green = "#7bd88f",
    orange = "#ff9f5a",
}

local specs = {
    { "GENTLE", "strength 0.65", p.cyan, { preset = "gentle", strength = 0.65 } },
    { "SNAPPY", "strength 1.00", p.violet, { preset = "snappy", strength = 1.00 } },
    { "BACK", "strength 1.45", p.magenta, { preset = "back", strength = 1.45 } },
    { "BOUNCE", "strength 1.00", p.gold, { preset = "bounce", strength = 1.00 } },
    { "ELASTIC", "strength 0.80", p.green, { preset = "elastic", strength = 0.80 } },
    {
        "CUSTOM CUBIC",
        "(.18,.90,.28,1)",
        p.orange,
        { bezier = { 0.18, 0.90, 0.28, 1.00 }, strength = 1.00 },
    },
}

local function value(index, t)
    local v = t
    if index == 1 then
        v = t * t * t * (t * (t * 6 - 15) + 10)
    end
    if index == 2 then
        v = 1 - (1 - t) ^ 4
    end
    if index == 3 then
        v = 1 + 2.70158 * (t - 1) ^ 3 + 1.70158 * (t - 1) ^ 2
    end
    if index == 4 then
        local n, d = 7.5625, 2.75
        if t < 1 / d then
            v = n * t * t
        elseif t < 2 / d then
            t = t - 1.5 / d
            v = n * t * t + 0.75
        elseif t < 2.5 / d then
            t = t - 2.25 / d
            v = n * t * t + 0.9375
        else
            t = t - 2.625 / d
            v = n * t * t + 0.984375
        end
    end
    if index == 5 and t > 0 and t < 1 then
        v = 2 ^ (-10 * t) * math.sin((t * 10 - 0.75) * 2.09439510239) + 1
    end
    if index == 6 then
        v = 3 * (1 - t) ^ 2 * t * 0.90 + 3 * (1 - t) * t ^ 2 + t ^ 3
    end
    local strength = specs[index][4].strength
    return t + (v - t) * strength
end

local function make_panel(index)
    local spec = specs[index]
    local scene = tmath.scene {
        width = 320,
        height = 270,
        fps = 60,
        background = index % 2 == 0 and p.b or p.a,
        loop = false,
        camera = { mode = "fixed", view = "2d", target = { 0, 0 }, height = 6.4 },
    }
    scene:text {
        text = string.format("%02d", index),
        point = { -3.42, 2.70 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 10,
        fill = p.muted,
        id = "curve-index-" .. index,
    }
    scene:text {
        text = spec[1],
        point = { -2.78, 2.70 },
        align = { 0, 0.5 },
        font = "Pretendard",
        size = 17,
        fill = p.text,
        id = "curve-title-" .. index,
    }
    scene:text {
        text = spec[2],
        point = { 3.35, 2.70 },
        align = { 1, 0.5 },
        font = "Pretendard",
        size = 10,
        fill = spec[3],
        id = "curve-detail-" .. index,
    }
    scene:line {
        from = { -3.42, 2.26 },
        to = { 3.42, 2.26 },
        stroke = p.rule,
        width = 1.4,
        id = "curve-rule-" .. index,
    }
    scene:line {
        from = { -2.25, 0.20 },
        to = { 2.25, 0.20 },
        stroke = p.rule,
        width = 3,
        id = "motion-track-" .. index,
    }
    scene:line {
        from = { 2.25, -0.13 },
        to = { 2.25, 0.53 },
        stroke = spec[3],
        width = 2,
        id = "motion-stop-" .. index,
    }
    scene:text {
        text = "0",
        point = { -2.25, -0.58 },
        font = "Pretendard",
        size = 10,
        fill = p.muted,
        id = "motion-zero-" .. index,
    }
    scene:text {
        text = "1",
        point = { 2.25, -0.58 },
        font = "Pretendard",
        size = 10,
        fill = spec[3],
        id = "motion-one-" .. index,
    }
    local subject = scene:group { id = "curve-subject-" .. index }
    subject:circle {
        center = { -2.25, 0.20 },
        radius = 0.52,
        fill = spec[3] .. "33",
        stroke = spec[3],
        width = 4,
        id = "curve-body-" .. index,
    }
    subject:text {
        text = "t",
        point = { -2.25, 0.20 },
        font = "Pretendard",
        size = 18,
        fill = p.text,
        id = "curve-symbol-" .. index,
    }
    scene:line {
        from = { -2.25, -2.04 },
        to = { 2.25, -2.04 },
        stroke = p.rule,
        width = 1,
        id = "graph-x-" .. index,
    }
    scene:line {
        from = { -2.25, -2.04 },
        to = { -2.25, -1.00 },
        stroke = p.rule,
        width = 1,
        id = "graph-y-" .. index,
    }
    local points = {}
    for i = 0, 60 do
        local t = i / 60
        points[#points + 1] = { -2.25 + 4.5 * t, -2.04 + 0.92 * value(index, t) }
    end
    local graph =
        scene:plot { points = points, stroke = spec[3], width = 3, id = "curve-graph-" .. index }
    scene:wait(0.30)
    scene:create(graph, 0.65, "ease_out")
    scene:wait(0.20)
    scene:shift(subject, { 4.5, 0 }, 1.80, spec[4])
    scene:wait(0.45)
    return scene
end

local gallery = tmath.scene {
    width = 960,
    height = 540,
    fps = 60,
    background = "#080d14",
    loop = false,
    camera = { mode = "fixed", view = "2d", target = { 0, 0 }, height = 6.4 },
}
for index = 1, 6 do
    gallery:viewport(make_panel(index), {
        x = ((index - 1) % 3) / 3,
        y = math.floor((index - 1) / 3) / 2,
        width = 1 / 3,
        height = 1 / 2,
    })
end
return gallery
`,
        js: `const p = {
    a: "#0d1622",
    b: "#101a27",
    rule: "#253448",
    text: "#f4f7fb",
    muted: "#8fa1b7",
    cyan: "#4cc9f0",
    violet: "#9b8cff",
    magenta: "#f72585",
    gold: "#ffd166",
    green: "#7bd88f",
    orange: "#ff9f5a",
};
const specs = [
    ["GENTLE", "strength 0.65", p.cyan, tmath.animCurve.preset("gentle", 0.65)],
    ["SNAPPY", "strength 1.00", p.violet, tmath.animCurve.preset("snappy")],
    ["BACK", "strength 1.45", p.magenta, tmath.animCurve.preset("back", 1.45)],
    ["BOUNCE", "strength 1.00", p.gold, tmath.animCurve.preset("bounce")],
    ["ELASTIC", "strength 0.80", p.green, tmath.animCurve.preset("elastic", 0.8)],
    [
        "CUSTOM CUBIC",
        "(.18,.90,.28,1)",
        p.orange,
        tmath.animCurve.cubicBezier(0.18, 0.9, 0.28, 1.0),
    ],
];
const curveValue = (index, input) => {
    let t = input;
    let value = t;
    if (index === 0) value = t * t * t * (t * (t * 6 - 15) + 10);
    if (index === 1) value = 1 - (1 - t) ** 4;
    if (index === 2) value = 1 + 2.70158 * (t - 1) ** 3 + 1.70158 * (t - 1) ** 2;
    if (index === 3) {
        const n = 7.5625;
        const d = 2.75;
        if (t < 1 / d) value = n * t * t;
        else if (t < 2 / d) {
            t -= 1.5 / d;
            value = n * t * t + 0.75;
        } else if (t < 2.5 / d) {
            t -= 2.25 / d;
            value = n * t * t + 0.9375;
        } else {
            t -= 2.625 / d;
            value = n * t * t + 0.984375;
        }
    }
    if (index === 4 && t > 0 && t < 1) {
        value = 2 ** (-10 * t) * Math.sin((t * 10 - 0.75) * 2.09439510239) + 1;
    }
    if (index === 5) value = 3 * (1 - t) ** 2 * t * 0.9 + 3 * (1 - t) * t ** 2 + t ** 3;
    const strength = specs[index][3].strength;
    return input + (value - input) * strength;
};
const makePanel = (index) => {
    const spec = specs[index];
    const scene = tmath.scene({
        width: 320,
        height: 270,
        fps: 60,
        background: index % 2 ? p.b : p.a,
        loop: false,
        camera: { mode: "fixed", view: "2d", target: [0, 0], height: 6.4 },
    });
    const number = String(index + 1).padStart(2, "0");
    scene.text({
        text: number,
        point: [-3.42, 2.7],
        align: [0, 0.5],
        font: "Pretendard",
        size: 10,
        fill: p.muted,
        id: "curve-index-" + (index + 1),
    });
    scene.text({
        text: spec[0],
        point: [-2.78, 2.7],
        align: [0, 0.5],
        font: "Pretendard",
        size: 17,
        fill: p.text,
        id: "curve-title-" + (index + 1),
    });
    scene.text({
        text: spec[1],
        point: [3.35, 2.7],
        align: [1, 0.5],
        font: "Pretendard",
        size: 10,
        fill: spec[2],
        id: "curve-detail-" + (index + 1),
    });
    scene.line({
        from: [-3.42, 2.26],
        to: [3.42, 2.26],
        stroke: p.rule,
        width: 1.4,
        id: "curve-rule-" + (index + 1),
    });
    scene.line({
        from: [-2.25, 0.2],
        to: [2.25, 0.2],
        stroke: p.rule,
        width: 3,
        id: "motion-track-" + (index + 1),
    });
    scene.line({
        from: [2.25, -0.13],
        to: [2.25, 0.53],
        stroke: spec[2],
        width: 2,
        id: "motion-stop-" + (index + 1),
    });
    scene.text({
        text: "0",
        point: [-2.25, -0.58],
        font: "Pretendard",
        size: 10,
        fill: p.muted,
        id: "motion-zero-" + (index + 1),
    });
    scene.text({
        text: "1",
        point: [2.25, -0.58],
        font: "Pretendard",
        size: 10,
        fill: spec[2],
        id: "motion-one-" + (index + 1),
    });
    const subject = scene.group({ id: "curve-subject-" + (index + 1) });
    subject.circle({
        center: [-2.25, 0.2],
        radius: 0.52,
        fill: spec[2] + "33",
        stroke: spec[2],
        width: 4,
        id: "curve-body-" + (index + 1),
    });
    subject.text({
        text: "t",
        point: [-2.25, 0.2],
        font: "Pretendard",
        size: 18,
        fill: p.text,
        id: "curve-symbol-" + (index + 1),
    });
    scene.line({
        from: [-2.25, -2.04],
        to: [2.25, -2.04],
        stroke: p.rule,
        width: 1,
        id: "graph-x-" + (index + 1),
    });
    scene.line({
        from: [-2.25, -2.04],
        to: [-2.25, -1.0],
        stroke: p.rule,
        width: 1,
        id: "graph-y-" + (index + 1),
    });
    const points = Array.from({ length: 61 }, (_, point) => {
        const t = point / 60;
        return [-2.25 + 4.5 * t, -2.04 + 0.92 * curveValue(index, t)];
    });
    const graph = scene.plot({
        points,
        stroke: spec[2],
        width: 3,
        id: "curve-graph-" + (index + 1),
    });
    scene.wait(0.3);
    scene.create(graph, 0.65, "ease_out");
    scene.wait(0.2);
    scene.shift(subject, [4.5, 0], 1.8, spec[3]);
    scene.wait(0.45);
    return scene;
};
const gallery = tmath.scene({
    width: 960,
    height: 540,
    fps: 60,
    background: "#080d14",
    loop: false,
    camera: { mode: "fixed", view: "2d", target: [0, 0], height: 6.4 },
});
for (let index = 0; index < 6; index++) {
    gallery.viewport(makePanel(index), {
        x: (index % 3) / 3,
        y: Math.floor(index / 3) / 2,
        width: 1 / 3,
        height: 1 / 2,
    });
}
return gallery;
`,
    },
];
