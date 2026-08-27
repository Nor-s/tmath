const PRETENDARD = [{ name: "Pretendard", url: "./Pretendard.ttf", mime: "ttf" }];

export const SORT_EXAMPLES = [
    {
        id: "quick-sort",
        title: "Quick Sort partition",
        description:
            "Choose a pivot, classify every value into partition lanes, rearrange the objects, and recurse to a sorted row.",
        category: "Sorting",
        dimension: "2D",
        fonts: PRETENDARD,
        lua: `local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    background = "#0b1020",
    camera = { mode = "fixed", view = "2d", height = 6 },
}
local function translate(x, y)
    return { 1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, 0, 0, 0, 0, 1 }
end
local colors = {
    text = "#f4f7fb",
    muted = "#8b9bb4",
    surface = "#17233d",
    outline = "#42526b",
    active = "#c77dff",
    activeFill = "#53356f",
    pivot = "#ffd166",
    pivotFill = "#62501f",
    less = "#4cc9f0",
    lessFill = "#17445a",
    greater = "#f07178",
    greaterFill = "#4a2635",
    sorted = "#7bd88f",
    sortedFill = "#1f5343",
}
local title = scene:text {
    text = "QUICK SORT",
    point = { 0, 2.55 },
    font = "Pretendard",
    size = 32,
    fill = colors.text,
    id = "title",
}
local subtitle = scene:text {
    text = "partition around pivot = 4",
    point = { 0, 2.08 },
    font = "Pretendard",
    size = 20,
    fill = colors.pivot,
    id = "pivot-equation",
}
local greaterLabel = scene:text {
    text = "> pivot",
    point = { -4.25, 1.35 },
    font = "Pretendard",
    size = 18,
    fill = colors.greater,
    id = "greater-label",
}
local lessLabel = scene:text {
    text = "<= pivot",
    point = { -4.25, -0.45 },
    font = "Pretendard",
    size = 18,
    fill = colors.less,
    id = "less-label",
}
local hint = scene:text {
    text = "compare  |  classify  |  place pivot  |  recurse",
    point = { 0, -2.25 },
    font = "Pretendard",
    size = 18,
    fill = colors.muted,
    id = "algorithm-hint",
}
local partition = scene:text {
    text = "partition:  [2, 3]   4   [6, 8, 7]",
    point = { 0, -1.42 },
    font = "Pretendard",
    size = 21,
    fill = colors.pivot,
    id = "partition-result",
}
local recurse = scene:text {
    text = "recurse on the left and right partitions",
    point = { 0, -1.82 },
    font = "Pretendard",
    size = 18,
    fill = colors.muted,
    id = "recurse-label",
}
local result = scene:text {
    text = "sorted:  2   3   4   6   7   8",
    point = { 0, -1.42 },
    font = "Pretendard",
    size = 21,
    fill = colors.sorted,
    id = "sorted-result",
}
local values = { 6, 2, 8, 3, 7, 4 }
local cells = {}
local bodies = {}
local reveal = { title, subtitle, greaterLabel, lessLabel, hint }
local startX = -2.875
local step = 1.15
for i, value in ipairs(values) do
    local cell = scene:group {
        matrix = translate(startX + (i - 1) * step, 0.45),
        id = "value-" .. value,
    }
    local body = cell:rectangle {
        size = { 0.98, 0.78 },
        corner = 0.12,
        fill = colors.surface,
        stroke = colors.outline,
        width = 3,
        id = "value-" .. value .. "-body",
    }
    cell:text {
        text = tostring(value),
        point = { 0, 0 },
        font = "Pretendard",
        size = 25,
        fill = colors.text,
        id = "value-" .. value .. "-text",
    }
    cells[i] = cell
    bodies[i] = body
    reveal[#reveal + 1] = cell
end
for _, item in ipairs(reveal) do
    scene:fade_in(item, {
        shift = { 0, 0.16 },
        scale = 0.96,
        duration = 0.10,
        curve = {
            preset = "snappy",
            strength = 0.80,
        },
    })
end
scene:play({
    { target = bodies[6], fill = colors.pivotFill, stroke = colors.pivot },
    {
        target = cells[6],
        shift = { 0, 0.12 },
    },
}, 0.4, "ease_out", 0)
local function classify(index, isLess)
    scene:play({
        { target = bodies[index], fill = colors.activeFill, stroke = colors.active },
        { target = bodies[6], fill = colors.pivotFill, stroke = colors.pivot },
    }, 0.22, "ease_in_out", 0)
    scene:play({
        {
            target = bodies[index],
            fill = isLess and colors.lessFill or colors.greaterFill,
            stroke = isLess and colors.less or colors.greater,
        },
        { target = cells[index], shift = { 0, isLess and -0.9 or 0.9 } },
    }, 0.32, "ease_out", 0)
end
classify(1, false)
classify(2, true)
classify(3, false)
classify(4, true)
classify(5, false)
scene:fade_in(partition, { shift = { 0, -0.16 }, duration = 0.24, curve = "snappy" })
scene:play({
    { target = cells[1], shift = { 3.45, 0 } },
    { target = cells[2], shift = { -1.15, 0 } },
    { target = cells[3], shift = { 2.3, 0 } },
    { target = cells[4], shift = { -2.3, 0 } },
    { target = cells[5], shift = { 1.15, 0 } },
    { target = cells[6], shift = { -3.45, 0 } },
}, 0.8, "ease_in_out", 0)
scene:play({
    { target = cells[1], shift = { 0, -0.9 } },
    { target = cells[2], shift = { 0, 0.9 } },
    { target = cells[3], shift = { 0, -0.9 } },
    { target = cells[4], shift = { 0, 0.9 } },
    { target = cells[5], shift = { 0, -0.9 } },
    { target = cells[6], shift = { 0, -0.12 } },
}, 0.48, "ease_in_out", 0)
scene:fade_in(recurse, { shift = { 0, -0.14 }, duration = 0.22, curve = "gentle" })
scene:play({
    { target = cells[3], shift = { 1.15, 0 } },
    { target = cells[5], shift = { -1.15, 0 } },
    { target = bodies[1], fill = colors.sortedFill, stroke = colors.sorted },
    { target = bodies[2], fill = colors.sortedFill, stroke = colors.sorted },
    { target = bodies[3], fill = colors.sortedFill, stroke = colors.sorted },
    { target = bodies[4], fill = colors.sortedFill, stroke = colors.sorted },
    { target = bodies[5], fill = colors.sortedFill, stroke = colors.sorted },
    { target = bodies[6], fill = colors.sortedFill, stroke = colors.sorted },
}, 0.72, "ease_in_out", 0)
scene:fade(partition, 0, 0.2, "ease_out")
scene:fade_in(result, { shift = { 0, -0.18 }, duration = 0.28, curve = "snappy" })
scene:wait(0.55)
return scene
`,
        js: `const scene = tmath.scene({
    width: 960,
    height: 540,
    fps: 30,
    background: "#0b1020",
    camera: { mode: "fixed", view: "2d", height: 6 },
});
const translate = (x, y) => [1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, 0, 0, 0, 0, 1];
const colors = {
    text: "#f4f7fb",
    muted: "#8b9bb4",
    surface: "#17233d",
    outline: "#42526b",
    active: "#c77dff",
    activeFill: "#53356f",
    pivot: "#ffd166",
    pivotFill: "#62501f",
    less: "#4cc9f0",
    lessFill: "#17445a",
    greater: "#f07178",
    greaterFill: "#4a2635",
    sorted: "#7bd88f",
    sortedFill: "#1f5343",
};
const title = scene.text({
    text: "QUICK SORT",
    point: [0, 2.55],
    font: "Pretendard",
    size: 32,
    fill: colors.text,
    id: "title",
});
const subtitle = scene.text({
    text: "partition around pivot = 4",
    point: [0, 2.08],
    font: "Pretendard",
    size: 20,
    fill: colors.pivot,
    id: "pivot-equation",
});
const greaterLabel = scene.text({
    text: "> pivot",
    point: [-4.25, 1.35],
    font: "Pretendard",
    size: 18,
    fill: colors.greater,
    id: "greater-label",
});
const lessLabel = scene.text({
    text: "<= pivot",
    point: [-4.25, -0.45],
    font: "Pretendard",
    size: 18,
    fill: colors.less,
    id: "less-label",
});
const hint = scene.text({
    text: "compare  |  classify  |  place pivot  |  recurse",
    point: [0, -2.25],
    font: "Pretendard",
    size: 18,
    fill: colors.muted,
    id: "algorithm-hint",
});
const partition = scene.text({
    text: "partition:  [2, 3]   4   [6, 8, 7]",
    point: [0, -1.42],
    font: "Pretendard",
    size: 21,
    fill: colors.pivot,
    id: "partition-result",
});
const recurse = scene.text({
    text: "recurse on the left and right partitions",
    point: [0, -1.82],
    font: "Pretendard",
    size: 18,
    fill: colors.muted,
    id: "recurse-label",
});
const result = scene.text({
    text: "sorted:  2   3   4   6   7   8",
    point: [0, -1.42],
    font: "Pretendard",
    size: 21,
    fill: colors.sorted,
    id: "sorted-result",
});
const values = [6, 2, 8, 3, 7, 4],
    cells = [],
    bodies = [],
    startX = -2.875,
    step = 1.15;
for (let i = 0; i < values.length; i++) {
    const value = values[i],
        cell = scene.group({ matrix: translate(startX + i * step, 0.45), id: "value-" + value });
    const body = cell.rectangle({
        size: [0.98, 0.78],
        corner: 0.12,
        fill: colors.surface,
        stroke: colors.outline,
        width: 3,
        id: "value-" + value + "-body",
    });
    cell.text({
        text: String(value),
        point: [0, 0],
        font: "Pretendard",
        size: 25,
        fill: colors.text,
        id: "value-" + value + "-text",
    });
    cells.push(cell);
    bodies.push(body);
}
for (const item of [title, subtitle, greaterLabel, lessLabel, hint, ...cells])
    scene.fadeIn(item, {
        shift: [0, 0.16],
        scale: 0.96,
        duration: 0.1,
        curve: tmath.animCurve.preset("snappy", 0.8),
    });
scene.play(
    [
        { target: bodies[5], fill: colors.pivotFill, stroke: colors.pivot },
        { target: cells[5], shift: [0, 0.12] },
    ],
    0.4,
    "ease_out",
    0,
);
function classify(index, isLess) {
    scene.play(
        [
            { target: bodies[index], fill: colors.activeFill, stroke: colors.active },
            { target: bodies[5], fill: colors.pivotFill, stroke: colors.pivot },
        ],
        0.22,
        "ease_in_out",
        0,
    );
    scene.play(
        [
            {
                target: bodies[index],
                fill: isLess ? colors.lessFill : colors.greaterFill,
                stroke: isLess ? colors.less : colors.greater,
            },
            { target: cells[index], shift: [0, isLess ? -0.9 : 0.9] },
        ],
        0.32,
        "ease_out",
        0,
    );
}
classify(0, false);
classify(1, true);
classify(2, false);
classify(3, true);
classify(4, false);
scene.fadeIn(partition, { shift: [0, -0.16], duration: 0.24, curve: "snappy" });
scene.play(
    [
        { target: cells[0], shift: [3.45, 0] },
        { target: cells[1], shift: [-1.15, 0] },
        { target: cells[2], shift: [2.3, 0] },
        { target: cells[3], shift: [-2.3, 0] },
        { target: cells[4], shift: [1.15, 0] },
        { target: cells[5], shift: [-3.45, 0] },
    ],
    0.8,
    "ease_in_out",
    0,
);
scene.play(
    [
        { target: cells[0], shift: [0, -0.9] },
        { target: cells[1], shift: [0, 0.9] },
        { target: cells[2], shift: [0, -0.9] },
        { target: cells[3], shift: [0, 0.9] },
        { target: cells[4], shift: [0, -0.9] },
        { target: cells[5], shift: [0, -0.12] },
    ],
    0.48,
    "ease_in_out",
    0,
);
scene.fadeIn(recurse, { shift: [0, -0.14], duration: 0.22, curve: "gentle" });
scene.play(
    [
        { target: cells[2], shift: [1.15, 0] },
        { target: cells[4], shift: [-1.15, 0] },
        ...bodies.map((target) => ({ target, fill: colors.sortedFill, stroke: colors.sorted })),
    ],
    0.72,
    "ease_in_out",
    0,
);
scene.fade(partition, 0, 0.2, "ease_out");
scene.fadeIn(result, { shift: [0, -0.18], duration: 0.28, curve: "snappy" });
scene.wait(0.55);
return scene;
`,
    },
    {
        id: "merge-sort",
        title: "Merge Sort buffer",
        description:
            "Compare two sorted runs and move each winning head into an explicit output buffer.",
        category: "Sorting",
        dimension: "2D",
        fonts: PRETENDARD,
        lua: `local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    background = "#0b1020",
    camera = { mode = "fixed", view = "2d", height = 6 },
}
local function translate(x, y)
    return { 1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, 0, 0, 0, 0, 1 }
end
local colors = {
    text = "#f4f7fb",
    muted = "#8b9bb4",
    surface = "#17233d",
    slot = "#10182b",
    outline = "#42526b",
    left = "#4cc9f0",
    leftFill = "#17384a",
    right = "#f07178",
    rightFill = "#3d2535",
    active = "#c77dff",
    activeFill = "#53356f",
    output = "#7bd88f",
    outputFill = "#1f5343",
}
local title = scene:text {
    text = "MERGE SORT",
    point = { 0, 2.55 },
    font = "Pretendard",
    size = 32,
    fill = colors.text,
    id = "title",
}
local subtitle = scene:text {
    text = "compare both run heads, then emit the smaller value",
    point = { 0, 2.08 },
    font = "Pretendard",
    size = 19,
    fill = colors.muted,
    id = "merge-rule",
}
local leftLabel = scene:text {
    text = "LEFT RUN  [2, 6, 8]",
    point = { -2.55, 1.5 },
    font = "Pretendard",
    size = 19,
    fill = colors.left,
    id = "left-run-label",
}
local rightLabel = scene:text {
    text = "RIGHT RUN  [1, 3, 7]",
    point = { 2.55, 1.5 },
    font = "Pretendard",
    size = 19,
    fill = colors.right,
    id = "right-run-label",
}
local outputLabel = scene:text {
    text = "OUTPUT BUFFER",
    point = { 0, -0.55 },
    font = "Pretendard",
    size = 19,
    fill = colors.output,
    id = "output-label",
}
local hint = scene:text {
    text = "purple = comparing     green = emitted",
    point = { 0, -2.32 },
    font = "Pretendard",
    size = 17,
    fill = colors.muted,
    id = "merge-hint",
}
local result = scene:text {
    text = "merged:  [1, 2, 3, 6, 7, 8]",
    point = { 0, -1.85 },
    font = "Pretendard",
    size = 21,
    fill = colors.output,
    id = "merged-result",
}
local function makeCell(value, x, color, fill, run)
    local cell = scene:group { matrix = translate(x, 0.65), id = run .. "-value-" .. value }
    local body = cell:rectangle {
        size = { 1.02, 0.76 },
        corner = 0.12,
        fill = fill,
        stroke = color,
        width = 3,
        id = run .. "-value-" .. value .. "-body",
    }
    cell:text {
        text = tostring(value),
        point = { 0, 0 },
        font = "Pretendard",
        size = 24,
        fill = colors.text,
        id = run .. "-value-" .. value .. "-text",
    }
    return cell, body
end
local leftCells, leftBodies = {}, {}
local rightCells, rightBodies = {}, {}
local leftValues = { 2, 6, 8 }
local rightValues = { 1, 3, 7 }
local inputX = { -3.7, -2.55, -1.4 }
local reveal = { title, subtitle, leftLabel, rightLabel, outputLabel, hint }
local outputX = { -3, -1.8, -0.6, 0.6, 1.8, 3 }
for i, x in ipairs(outputX) do
    reveal[#reveal + 1] = scene:rectangle {
        center = { x, -1.2 },
        size = { 1.02, 0.76 },
        corner = 0.12,
        fill = colors.slot,
        stroke = colors.outline,
        width = 2,
        id = "output-slot-" .. i,
    }
end
for i, value in ipairs(leftValues) do
    leftCells[i], leftBodies[i] = makeCell(value, inputX[i], colors.left, colors.leftFill, "left")
    reveal[#reveal + 1] = leftCells[i]
end
for i, value in ipairs(rightValues) do
    rightCells[i], rightBodies[i] =
        makeCell(value, -inputX[4 - i], colors.right, colors.rightFill, "right")
    reveal[#reveal + 1] = rightCells[i]
end
for _, item in ipairs(reveal) do
    scene:fade_in(item, {
        shift = { 0, 0.15 },
        scale = 0.96,
        duration = 0.09,
        curve = {
            preset = "snappy",
            strength = 0.78,
        },
    })
end
local function compare(leftBody, rightBody)
    scene:play({
        { target = leftBody, fill = colors.activeFill, stroke = colors.active },
        { target = rightBody, fill = colors.activeFill, stroke = colors.active },
    }, 0.22, "ease_in_out", 0)
end
local function emit(winner, winnerBody, loserBody, loserFill, loserStroke, shift)
    scene:play({
        { target = winner, shift = shift },
        { target = winnerBody, fill = colors.outputFill, stroke = colors.output },
        { target = loserBody, fill = loserFill, stroke = loserStroke },
    }, 0.38, "ease_out", 0)
end
compare(leftBodies[1], rightBodies[1])
emit(rightCells[1], rightBodies[1], leftBodies[1], colors.leftFill, colors.left, { -4.4, -1.85 })
compare(leftBodies[1], rightBodies[2])
emit(leftCells[1], leftBodies[1], rightBodies[2], colors.rightFill, colors.right, { 1.9, -1.85 })
compare(leftBodies[2], rightBodies[2])
emit(rightCells[2], rightBodies[2], leftBodies[2], colors.leftFill, colors.left, { -3.15, -1.85 })
compare(leftBodies[2], rightBodies[3])
emit(leftCells[2], leftBodies[2], rightBodies[3], colors.rightFill, colors.right, { 3.15, -1.85 })
compare(leftBodies[3], rightBodies[3])
emit(rightCells[3], rightBodies[3], leftBodies[3], colors.leftFill, colors.left, { -1.9, -1.85 })
scene:play(
    { { target = leftBodies[3], fill = colors.activeFill, stroke = colors.active } },
    0.22,
    "ease_in_out",
    0
)
scene:play({
    { target = leftCells[3], shift = { 4.4, -1.85 } },
    { target = leftBodies[3], fill = colors.outputFill, stroke = colors.output },
}, 0.38, "ease_out", 0)
scene:fade_in(result, { shift = { 0, -0.18 }, duration = 0.28, curve = "snappy" })
scene:wait(0.6)
return scene
`,
        js: `const scene = tmath.scene({
    width: 960,
    height: 540,
    fps: 30,
    background: "#0b1020",
    camera: { mode: "fixed", view: "2d", height: 6 },
});
const translate = (x, y) => [1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, 0, 0, 0, 0, 1];
const colors = {
    text: "#f4f7fb",
    muted: "#8b9bb4",
    surface: "#17233d",
    slot: "#10182b",
    outline: "#42526b",
    left: "#4cc9f0",
    leftFill: "#17384a",
    right: "#f07178",
    rightFill: "#3d2535",
    active: "#c77dff",
    activeFill: "#53356f",
    output: "#7bd88f",
    outputFill: "#1f5343",
};
const title = scene.text({
    text: "MERGE SORT",
    point: [0, 2.55],
    font: "Pretendard",
    size: 32,
    fill: colors.text,
    id: "title",
});
const subtitle = scene.text({
    text: "compare both run heads, then emit the smaller value",
    point: [0, 2.08],
    font: "Pretendard",
    size: 19,
    fill: colors.muted,
    id: "merge-rule",
});
const leftLabel = scene.text({
    text: "LEFT RUN  [2, 6, 8]",
    point: [-2.55, 1.5],
    font: "Pretendard",
    size: 19,
    fill: colors.left,
    id: "left-run-label",
});
const rightLabel = scene.text({
    text: "RIGHT RUN  [1, 3, 7]",
    point: [2.55, 1.5],
    font: "Pretendard",
    size: 19,
    fill: colors.right,
    id: "right-run-label",
});
const outputLabel = scene.text({
    text: "OUTPUT BUFFER",
    point: [0, -0.55],
    font: "Pretendard",
    size: 19,
    fill: colors.output,
    id: "output-label",
});
const hint = scene.text({
    text: "purple = comparing     green = emitted",
    point: [0, -2.32],
    font: "Pretendard",
    size: 17,
    fill: colors.muted,
    id: "merge-hint",
});
const result = scene.text({
    text: "merged:  [1, 2, 3, 6, 7, 8]",
    point: [0, -1.85],
    font: "Pretendard",
    size: 21,
    fill: colors.output,
    id: "merged-result",
});
function makeCell(value, x, color, fill, run) {
    const cell = scene.group({ matrix: translate(x, 0.65), id: run + "-value-" + value });
    const body = cell.rectangle({
        size: [1.02, 0.76],
        corner: 0.12,
        fill,
        stroke: color,
        width: 3,
        id: run + "-value-" + value + "-body",
    });
    cell.text({
        text: String(value),
        point: [0, 0],
        font: "Pretendard",
        size: 24,
        fill: colors.text,
        id: run + "-value-" + value + "-text",
    });
    return [cell, body];
}
const leftValues = [2, 6, 8],
    rightValues = [1, 3, 7],
    inputX = [-3.7, -2.55, -1.4],
    leftCells = [],
    leftBodies = [],
    rightCells = [],
    rightBodies = [];
const outputX = [-3, -1.8, -0.6, 0.6, 1.8, 3],
    slots = outputX.map((x, i) =>
        scene.rectangle({
            center: [x, -1.2],
            size: [1.02, 0.76],
            corner: 0.12,
            fill: colors.slot,
            stroke: colors.outline,
            width: 2,
            id: "output-slot-" + (i + 1),
        }),
    );
for (let i = 0; i < 3; i++) {
    const [cell, body] = makeCell(leftValues[i], inputX[i], colors.left, colors.leftFill, "left");
    leftCells.push(cell);
    leftBodies.push(body);
}
for (let i = 0; i < 3; i++) {
    const [cell, body] = makeCell(
        rightValues[i],
        -inputX[2 - i],
        colors.right,
        colors.rightFill,
        "right",
    );
    rightCells.push(cell);
    rightBodies.push(body);
}
for (const item of [
    title,
    subtitle,
    leftLabel,
    rightLabel,
    outputLabel,
    hint,
    ...slots,
    ...leftCells,
    ...rightCells,
])
    scene.fadeIn(item, {
        shift: [0, 0.15],
        scale: 0.96,
        duration: 0.09,
        curve: tmath.animCurve.preset("snappy", 0.78),
    });
function compare(leftBody, rightBody) {
    scene.play(
        [
            { target: leftBody, fill: colors.activeFill, stroke: colors.active },
            { target: rightBody, fill: colors.activeFill, stroke: colors.active },
        ],
        0.22,
        "ease_in_out",
        0,
    );
}
function emit(winner, winnerBody, loserBody, loserFill, loserStroke, shift) {
    scene.play(
        [
            { target: winner, shift },
            { target: winnerBody, fill: colors.outputFill, stroke: colors.output },
            { target: loserBody, fill: loserFill, stroke: loserStroke },
        ],
        0.38,
        "ease_out",
        0,
    );
}
compare(leftBodies[0], rightBodies[0]);
emit(rightCells[0], rightBodies[0], leftBodies[0], colors.leftFill, colors.left, [-4.4, -1.85]);
compare(leftBodies[0], rightBodies[1]);
emit(leftCells[0], leftBodies[0], rightBodies[1], colors.rightFill, colors.right, [1.9, -1.85]);
compare(leftBodies[1], rightBodies[1]);
emit(rightCells[1], rightBodies[1], leftBodies[1], colors.leftFill, colors.left, [-3.15, -1.85]);
compare(leftBodies[1], rightBodies[2]);
emit(leftCells[1], leftBodies[1], rightBodies[2], colors.rightFill, colors.right, [3.15, -1.85]);
compare(leftBodies[2], rightBodies[2]);
emit(rightCells[2], rightBodies[2], leftBodies[2], colors.leftFill, colors.left, [-1.9, -1.85]);
scene.play(
    { target: leftBodies[2], fill: colors.activeFill, stroke: colors.active },
    0.22,
    "ease_in_out",
    0,
);
scene.play(
    [
        { target: leftCells[2], shift: [4.4, -1.85] },
        { target: leftBodies[2], fill: colors.outputFill, stroke: colors.output },
    ],
    0.38,
    "ease_out",
    0,
);
scene.fadeIn(result, { shift: [0, -0.18], duration: 0.28, curve: "snappy" });
scene.wait(0.6);
return scene;
`,
    },
];
