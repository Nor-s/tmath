import assert from "node:assert/strict";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { spawnSync } from "node:child_process";

const bindingPath = process.argv[2];
const cliPath = process.argv[3];
const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "../..");

const { compileScene, evaluateScene, tmath } = await import(pathToFileURL(bindingPath));
const objectCount = (scene) =>
    scene.objects.length + scene.viewports.reduce((count, viewport) => count + objectCount(viewport.scene), 0);
const boundsOverlap = (scene, firstId, secondId) => {
    const first = scene.objects.find((object) => object.id === firstId)?.bounds;
    const second = scene.objects.find((object) => object.id === secondId)?.bounds;
    assert.ok(first && second, `Missing layout bounds for ${firstId} or ${secondId}`);
    return (
        first.x < second.x + second.width &&
        second.x < first.x + first.width &&
        first.y < second.y + second.height &&
        second.y < first.y + first.height
    );
};
const scene = tmath.scene({
    width: 320,
    height: 180,
    loop: true,
    background: "#0d1117",
    camera: { mode: "interactive", view: "2d", height: 6 },
});
const world = scene.space({ x: [-3, 3, 1], y: [-2, 2, 1], id: "world" });
const axis = world.arrow({
    from: [-2.8, 0],
    to: [2.8, 0],
    tail: 16,
    tip: 20,
    id: "double-arrow",
});
const point = world.point({ point: [2.2, 1.45], fill: "#ef5350", id: "target" });
scene.transform(axis, [0.72, -0.69, 0, 0, 0.69, 0.72, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1], 1.6, "ease_in_out");
scene.fade(point, 0.25, 0.5, "ease_out").wait(0.4);

const lua = compileScene(scene);
assert.match(lua, /object1:arrow/);
assert.match(lua, /\["tail"\]=16/);
assert.match(lua, /scene:transform\(object2/);
assert.match(lua, /\["loop"\]=true/);
assert.match(lua, /return scene\n$/);

const sampleScene = tmath.scene({ camera: { view: "3d" } });
const sampleSpace = sampleScene.space({ x: [-1, 1, 1], y: [0, 1, 1], z: [-1, 1, 1] });
const voxelCoordinates = [];
sampleSpace.voxel((x, y, z, time) => {
    voxelCoordinates.push([x, y, z, time]);
    const radius = 0.75 + time;
    return x * x + y * y + z * z <= radius * radius ? "#2563eb" : "#00000000";
}, { mode: "padd", padding: 0.1, duration: 0.5, fps: 2 });
const cellCoordinates = [];
sampleSpace.cell((x, y, time) => {
    cellCoordinates.push([x, y, time]);
    const axis = 1 + time;
    return x * x / (axis * axis) + y * y <= 1 ? "#0891b2" : "#00000000";
}, { mode: "padd", padding: 0.08, duration: 0.5, fps: 2 });
const sampleLua = compileScene(sampleScene);
assert.equal(voxelCoordinates.length, 36);
assert.deepEqual(voxelCoordinates[0], [-1, 0, -1, 0]);
assert.deepEqual(voxelCoordinates.at(-1), [1, 1, 1, 0.5]);
assert.equal(cellCoordinates.length, 12);
assert.deepEqual(cellCoordinates[0], [-1, 0, 0]);
assert.deepEqual(cellCoordinates.at(-1), [1, 1, 0.5]);
assert.match(sampleLua, /object1:voxel\(function\(x,y,z,time\)/);
assert.match(sampleLua, /mode="padd",padding=0\.1,duration=0\.5,fps=2/);
assert.match(sampleLua, /object1:cell\(function\(x,y,time\)/);
assert.doesNotMatch(sampleLua, /scene:morph/);

const invalidSampleScene = tmath.scene();
const invalidSampleSpace = invalidSampleScene.space({ x: [-1, 1, 1], y: [-1, 1, 1], z: [-1, 1, 1] });
const invalidSampleBefore = compileScene(invalidSampleScene);
assert.throws(() => invalidSampleSpace.voxel(null), /must be a function/);
assert.throws(() => invalidSampleSpace.voxel(() => "#fff", { mode: "mesh" }), /full or padd/);
assert.throws(() => invalidSampleSpace.voxel(() => "#fff", { padding: 0.5 }), /between 0 and 0\.5/);
assert.throws(() => invalidSampleSpace.voxel(() => "#fff", { duration: -1 }), /duration/);
assert.throws(() => invalidSampleSpace.voxel(() => "#fff", { duration: "1" }), /duration/);
assert.throws(() => invalidSampleSpace.voxel(() => "#fff", { duration: 1, fps: 0 }), /fps/);
assert.throws(() => invalidSampleSpace.voxel(() => "#fff", { duration: 200, fps: 30 }), /frame limit/);
assert.throws(() => invalidSampleSpace.voxel(() => "#fff", { depth: 1 }), /Unknown voxel option/);
assert.throws(() => invalidSampleSpace.voxel(() => 42), /must return/);
assert.throws(() => invalidSampleSpace.cell(() => "#fff", { depth: 1 }), /Unknown cell option/);
assert.throws(() => invalidSampleSpace.cell(() => 42), /must return/);
assert.throws(
    () => invalidSampleSpace.voxel(() => {
        invalidSampleScene.point({ point: [0, 0] });
        return "#fff";
    }),
    /authoring is unavailable/,
);
assert.equal(compileScene(invalidSampleScene), invalidSampleBefore);
assert.equal(typeof invalidSampleSpace.voxel(() => "#fff").arrange, "function");
assert.equal(typeof invalidSampleSpace.cell(() => "#fff").arrange, "function");
assert.equal(typeof invalidSampleSpace.cell({ size: [1, 1] }).moveTo, "function");
const oversizedVoxel = tmath.scene().space({
    x: [-100, 100, 1], y: [-100, 100, 1], z: [0, 0, 1],
});
assert.throws(() => oversizedVoxel.voxel(() => "#fff"), /limit/);
const oversizedTemporalCell = tmath.scene().space({
    x: [-25, 25, 1], y: [-25, 25, 1], z: [0, 0, 1],
});
assert.throws(
    () => oversizedTemporalCell.cell(() => "#fff", { duration: 4, fps: 30 }),
    /sample limit/,
);
assert.equal(world.point({ point: [0, 0] }).voxel, undefined);

const themed = tmath.scene({
    width: 320,
    height: 180,
    theme: {
        preset: "pro_black",
        background: "#ffffff",
        text: { h1: { font: "Pretendard", size: 36, color: "#202124" } },
        objects: ["#5e7a9b", "#b8915a", "#557b63"],
        object_width: 1.5,
        gradient: true,
        end_gradient_stop: "#778899",
        axis: { x: "#9b3600", y: "#557b63", z: "#5e7a9b" },
        colors: {accent: "#4cc9f0", danger: "#ff6b6b", surface: "#161b22", result: "#edc948", focus: "#6ea8fe"},
    },
});
themed.text({ text: "Theme", role: "h1", fill: "accent" });
const themedLua = compileScene(themed);
assert.match(themedLua, /\["preset"\]="pro_black"/);
assert.match(themedLua, /\["objects"\]=\{"#5e7a9b","#b8915a","#557b63"\}/);
assert.match(themedLua, /\["object_width"\]=1\.5/);
assert.match(themedLua, /\["gradient"\]=true/);
assert.match(themedLua, /\["end_gradient_stop"\]="#778899"/);
assert.match(themedLua, /\["colors"\]=\{\["accent"\]="#4cc9f0",\["danger"\]="#ff6b6b",\["focus"\]="#6ea8fe",\["result"\]="#edc948",\["surface"\]="#161b22"\}/);
assert.match(themedLua, /\["fill"\]="accent"/);
assert.match(themedLua, /\["role"\]="h1"/);

const freeform = tmath.scene({ width: 480, height: 270 });
const groupMatrix = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
const nodes = freeform.group({ id: "nodes", matrix: groupMatrix });
const boxCenter = [-1, 0];
const box = nodes.rectangle({ center: boxCenter, size: [1.5, 0.8], corner: 0.15, fill: "#264653" });
box.label({ text: "A", point: [-1, 0], fill: "#ffffff" });
const circle = nodes.circle({ center: [1, 0], radius: 0.45, fill: "#2a9d8f" });
nodes.circle({center: [2, 0], radius: 0.45, gradient: "#fedcba"});
nodes.line({from: [1.5, -1], to: [2.5, -1], gradient: false});
const connectorOptions = {
    padding: 0.1,
    tail: 8,
    tip: 12,
    stroke: "#e9c46a",
    dash: [8, 4],
    dash_offset: 2,
};
const connector = nodes.connector(box, circle, connectorOptions);
box.moveTo([-1.25, 0]).nextTo(circle, [1, 0, 0], 0.4).alignTo(circle, [0, 1, 0]);
nodes.arrange([1, 0, 0], 0.3).arrangeGrid(2, 0.2, 0.4);
const shift = [0.5, 0.25];
const firstAnimation = { target: box, shift, opacity: 0.5, fill: "#f4a261" };
freeform.play(firstAnimation, 0.8, "ease_out", 0.1);
const transform = [1, 0, 0, 0.5, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
const parallelAnimations = [
    { target: circle, transform },
    { target: connector, stroke: "#e76f51", dash_offset: -12, tail: 10, tip: 16 },
];
freeform.play(parallelAnimations, 1.2, "ease_in_out", 0.2);
groupMatrix[0] = 99;
boxCenter[0] = 99;
connectorOptions.padding = 99;
shift[0] = 99;
transform[0] = 99;
firstAnimation.opacity = 0.99;
firstAnimation.target = circle;
parallelAnimations.reverse();

const freeformLua = compileScene(freeform);
assert.match(freeformLua, /local object1 = scene:group/);
assert.match(freeformLua, /local object2 = object1:rectangle/);
assert.match(freeformLua, /local object3 = object2:label/);
assert.match(freeformLua, /local object4 = object1:circle/);
assert.match(freeformLua, /local object5 = object1:circle .*\["gradient"\]="#fedcba"/);
assert.match(freeformLua, /local object6 = object1:line .*\["gradient"\]=false/);

const gradients = tmath.scene({ width: 320, height: 180 });
gradients.circle({
    radius: 1,
    gradient: { type: "radial", stops: ["accent", [0.5, "#ffffff"], [1, "warning"]], center: [0, 0], radius: 2, focal: [0.2, 0], focalRadius: 0.1 },
});
gradients.rectangle({ gradient: { type: "linear", stops: ["#ff0000", "#0000ff"], from: [-1, 0], to: [1, 0] } });
gradients.circle({ gradient: { type: "conic", angle: 45 } });
const gradientLua = compileScene(gradients);
assert.match(
    gradientLua,
    /\["gradient"\]=\{\["center"\]=\{0,0\},\["focal"\]=\{0\.2,0\},\["focal_radius"\]=0\.1,\["radius"\]=2,\["stops"\]=\{"accent",\{0\.5,"#ffffff"\},\{1,"warning"\}\},\["type"\]="radial"\}/,
);
assert.match(gradientLua, /\["gradient"\]=\{\["from"\]=\{-1,0\},\["stops"\]=\{"#ff0000","#0000ff"\},\["to"\]=\{1,0\},\["type"\]="linear"\}/);
assert.match(gradientLua, /\["gradient"\]=\{\["angle"\]=45,\["type"\]="conic"\}/);
assert.throws(() => gradients.circle({ gradient: { type: "diamond" } }), /gradient\.type/);
assert.throws(() => gradients.circle({ gradient: { type: "linear", center: [0, 0] } }), /Unknown linear gradient option: center/);
assert.throws(() => gradients.circle({ gradient: { type: "conic", focal_radius: 1 } }), /Unknown conic gradient option/);
assert.throws(() => gradients.circle({ gradient: { type: "linear", stops: ["#fff"] } }), /2 to 8 stops/);
assert.match(freeformLua, /local object7 = object1:connector \{from=object2,to=object4,/);
assert.match(freeformLua, /\["dash"\]=\{8,4\}/);
assert.match(freeformLua, /\["dash_offset"\]=2/);
assert.match(freeformLua, /object2:move_to\(\{-1\.25,0\}\)/);
assert.match(freeformLua, /object2:next_to\(object4,\{1,0,0\},0\.4\)/);
assert.match(freeformLua, /object2:align_to\(object4,\{0,1,0\}\)/);
assert.match(freeformLua, /object1:arrange\(\{1,0,0\},0\.3\)/);
assert.match(freeformLua, /object1:arrange_grid\(2,0\.2,0\.4\)/);
assert.match(
    freeformLua,
    /scene:play\(\{\{target=object2,shift=\{0\.5,0\.25\},opacity=0\.5,fill="#f4a261"\}\},0\.8,"ease_out",0\.1\)/,
);
assert.match(
    freeformLua,
    /scene:play\(\{\{target=object4,transform=\{1,0,0,0\.5,0,1,0,0,0,0,1,0,0,0,0,1\}\},\{target=object7,stroke="#e76f51",dash_offset=-12,tail=10,tip=16\}\},1\.2,"ease_in_out",0\.2\)/,
);
assert.doesNotMatch(freeformLua, /99/);
for (const factory of [
    "group",
    "space",
    "point",
    "line",
    "arrow",
    "vector",
    "circle",
    "rectangle",
    "polygon",
    "plot",
    "route",
    "path",
    "curve",
    "surface",
    "text",
    "picture",
    "cell",
    "connector",
]) {
    assert.equal(typeof freeform[factory], "function", `SceneBuilder.${factory} is missing`);
    assert.equal(typeof box[factory], "function", `ObjectHandle.${factory} is missing`);
}

const validation = tmath.scene();
const validationBox = validation.rectangle();
const validationCircle = validation.circle();
const validationConnector = validation.connector(validationBox, validationCircle);
const foreign = tmath.scene().circle();
assert.throws(() => validation.connector(validationBox, foreign), /same scene/);
assert.throws(() => validationBox.connector(validationBox, foreign), /same scene/);
assert.throws(() => validationBox.nextTo(foreign, [1, 0]), /same scene/);
assert.throws(() => validationBox.alignTo(foreign, [1, 0]), /same scene/);
assert.throws(
    () => validation.connector(validationBox, validationCircle, { from: validationBox }),
    /passed as handles/,
);
const connectorValidationBefore = compileScene(validation);
assert.throws(() => validation.shift(validationConnector, [1, 0]), /cannot be shifted or transformed/);
assert.throws(
    () => validation.transform(validationConnector, [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]),
    /cannot be shifted or transformed/,
);
assert.throws(
    () => validation.play({ target: validationConnector, shift: [1, 0] }),
    /cannot be shifted or transformed/,
);
assert.equal(compileScene(validation), connectorValidationBefore);
const validBefore = compileScene(validation);
assert.throws(() => validation.play({ target: foreign, opacity: 0.5 }), /same scene/);
assert.throws(() => validation.play({ target: validationBox }), /at least one property/);
assert.throws(
    () =>
        validation.play({
            target: validationBox,
            shift: [1, 0],
            transform: [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1],
        }),
    /cannot combine/,
);
assert.throws(
    () =>
        validation.play([
            { target: validationBox, opacity: 0.5 },
            { target: validationBox, fill: "#ffffff" },
        ]),
    /duplicate targets/,
);
assert.throws(() => validation.play([]), /at least one descriptor/);
assert.throws(() => validation.play({ target: validationBox, opacity: 0.5, spin: 1 }), /Unknown animation property/);
assert.throws(() => validation.play(null), /plain objects/);
assert.equal(compileScene(validation), validBefore);

const effects = tmath.scene({ width: 320, height: 180 });
const effectSource = effects.polygon({
    id: "effect-source",
    points: [
        [-1, -0.5],
        [1, -0.5],
        [0, 1],
    ],
});
const effectAuxiliary = effects.rectangle({ id: "effect-auxiliary" });
const fadeShift = [0, 0.5];
const fadeOptions = { shift: fadeShift, scale: 0.9, duration: 0.6, easing: "ease_out" };
effects.create(effectSource, 0.5, "linear", 0, "clockwise");
effects.uncreate(effectSource, 0.4, "smooth", 0.1, "reverse");
effects.fillReveal(effectSource, 0.3, "ease_out", 0.05);
effects.drawBorderThenFill(effectSource, 0.6, "ease_in_out", 0, "counterclockwise");
effects.write(effectSource, 0.7, "gentle", 0.05, "forward");
effects.fadeIn(effectSource, fadeOptions);
effects.fadeOut(effectSource);
effects.growFromCenter(effectSource, 0.45, "ease_out");
effects.growFromEdge(effectSource, "bottom", 0.4, "ease_out");
effects.shrinkToCenter(effectSource, 0.35, "ease_in");
effects.indicate(effectSource, { color: "#4cc9f0", scale: 1.25, duration: 0.7, easing: "smooth" });
effects.indicate(effectAuxiliary);
const effectTarget = effects.polygon({
    id: "effect-target",
    points: [
        [-1, -1],
        [1, -1],
        [0, 1.25],
    ],
});
effects.morph(effectSource, effectTarget, 0.8, "ease_in_out");
const effectReplacement = effects.polygon({
    id: "effect-replacement",
    points: [
        [-1.2, 0],
        [0.6, -1],
        [0.6, 1],
    ],
});
effects.replacementTransform(effectTarget, effectReplacement, 0.9, "ease_out");
const effectLabel = effects.text({id: "effect-label", text: "result", point: [0, 0]});
effects.fadeTransform(effectReplacement, effectLabel, 0.25, "gentle");
const batchMorph = tmath.scene();
const batchSourceA = batchMorph.plot({points: [[-1, 0], [0, 1], [1, 0]]});
const batchSourceB = batchMorph.plot({points: [[-1, 1], [0, 0], [1, 1]]});
const batchTargetA = batchMorph.plot({points: [[-1, 0], [0, -1], [1, 0]]});
const batchTargetB = batchMorph.plot({points: [[-1, -1], [0, 0], [1, -1]]});
batchMorph.morph(
    [batchSourceA, batchSourceB],
    [batchTargetA, batchTargetB],
    0.8,
    "ease_in_out",
    0.1,
);
assert.match(
    compileScene(batchMorph),
    /scene:morph\(\{object1,object2\},\{object3,object4\},0\.8,"ease_in_out",0\.1\)/,
);
const backCurve = tmath.animCurve.preset("back", 1.4);
const customCurve = tmath.animCurve.cubicBezier(0.2, 0.9, 0.3, 1, 0.75);
const reversedBackCurve = tmath.animCurve.reverse(backCurve);
effects.shift(effectAuxiliary, [1, 0], 0.8, backCurve);
effects.shift(effectAuxiliary, [-1, 0], 0.8, reversedBackCurve);
effects.fadeIn(effectAuxiliary, { duration: 0.5, curve: customCurve });
fadeShift[0] = 99;
fadeOptions.scale = 99;
const effectsLua = compileScene(effects);
assert.match(effectsLua, /scene:create\(object1,0\.5,"linear",0,"clockwise"\)/);
assert.match(effectsLua, /scene:uncreate\(object1,0\.4,"smooth",0\.1,"reverse"\)/);
assert.match(effectsLua, /scene:fill_reveal\(object1,0\.3,"ease_out",0\.05\)/);
assert.match(effectsLua, /scene:draw_border_then_fill\(object1,0\.6,"ease_in_out",0,"counterclockwise"\)/);
assert.match(effectsLua, /scene:write\(object1,0\.7,"gentle",0\.05,"forward"\)/);
assert.match(
    effectsLua,
    /scene:fade_in\(object1,\{\["duration"\]=0\.6,\["easing"\]="ease_out",\["scale"\]=0\.9,\["shift"\]=\{0,0\.5\}\}\)/,
);
assert.match(
    effectsLua,
    /scene:fade_out\(object1,\{\["duration"\]=1,\["easing"\]="smooth",\["scale"\]=1,\["shift"\]=\{0,0,0\}\}\)/,
);
assert.match(effectsLua, /scene:grow_from_center\(object1,0\.45,"ease_out"\)/);
assert.match(effectsLua, /scene:grow_from_edge\(object1,"bottom",0\.4,"ease_out"\)/);
assert.match(effectsLua, /scene:shrink_to_center\(object1,0\.35,"ease_in"\)/);
assert.match(
    effectsLua,
    /scene:indicate\(object1,\{\["color"\]="#4cc9f0",\["duration"\]=0\.7,\["easing"\]="smooth",\["scale"\]=1\.25\}\)/,
);
assert.match(
    effectsLua,
    /scene:indicate\(object2,\{\["color"\]="focus",\["duration"\]=1,\["easing"\]="smooth",\["scale"\]=1\.2\}\)/,
);
assert.match(effectsLua, /scene:morph\(object1,object3,0\.8,"ease_in_out"\)/);
assert.match(effectsLua, /scene:replacement_transform\(object3,object4,0\.9,"ease_out"\)/);
assert.match(effectsLua, /scene:fade_transform\(object4,object5,0\.25,"gentle"\)/);
assert.match(effectsLua, /scene:shift\(object2,\{1,0\},0\.8,\{\["preset"\]="back",\["strength"\]=1\.4\}\)/);
assert.match(effectsLua, /scene:shift\(object2,\{-1,0\},0\.8,\{\["preset"\]="back",\["reverse"\]=true,\["strength"\]=1\.4\}\)/);
assert.match(
    effectsLua,
    /scene:fade_in\(object2,\{\["curve"\]=\{\["bezier"\]=\{0\.2,0\.9,0\.3,1\},\["strength"\]=0\.75\},\["duration"\]=0\.5,\["scale"\]=1,\["shift"\]=\{0,0,0\}\}\)/,
);
assert.doesNotMatch(effectsLua, /99/);
assert(Object.isFrozen(backCurve));
assert(Object.isFrozen(reversedBackCurve));
assert.deepEqual(tmath.animCurve.reverse(reversedBackCurve), backCurve);
assert(Object.isFrozen(customCurve.bezier));

const invalidEffects = tmath.scene();
const invalidEffectSource = invalidEffects.circle();
const invalidEffectTarget = invalidEffects.rectangle();
const invalidEffectForeign = tmath.scene().circle();
const invalidEffectsBefore = compileScene(invalidEffects);
assert.throws(() => invalidEffects.create(invalidEffectSource, 1, "smooth", 0, "diagonal"), /Create direction/);
assert.throws(() => invalidEffects.uncreate(invalidEffectSource, 1, "smooth", 0, "diagonal"), /Create direction/);
assert.throws(
    () => invalidEffects.drawBorderThenFill(invalidEffectSource, 1, "smooth", 0, "diagonal"),
    /Create direction/,
);
assert.throws(() => invalidEffects.fadeIn(invalidEffectSource, null), /plain object/);
assert.throws(() => invalidEffects.fadeOut(invalidEffectSource, []), /plain object/);
assert.throws(() => invalidEffects.fadeIn(invalidEffectSource, { scale: 0 }), /finite positive/);
assert.throws(() => invalidEffects.fadeOut(invalidEffectSource, { scale: Infinity }), /finite positive/);
assert.throws(() => invalidEffects.fadeIn(invalidEffectSource, { spin: 1 }), /Unknown FadeIn option/);
assert.throws(() => invalidEffects.growFromEdge(invalidEffectSource, "center"), /Growth edge/);
assert.throws(() => invalidEffects.indicate(invalidEffectSource, { scale: 1 }), /greater than 1/);
assert.throws(() => invalidEffects.indicate(invalidEffectSource, { scale: Number.NaN }), /greater than 1/);
assert.throws(() => invalidEffects.indicate(invalidEffectSource, { flash: true }), /Unknown Indicate option/);
assert.throws(
    () => invalidEffects.fadeIn(invalidEffectSource, { easing: "smooth", curve: "bounce" }),
    /either easing or curve/,
);
assert.throws(() => tmath.animCurve.preset("warp"), /Unknown animation curve preset/);
assert.throws(() => tmath.animCurve.preset("back", 2.1), /between 0 and 2/);
assert.throws(() => tmath.animCurve.cubicBezier(-0.1, 0, 0.5, 1), /x in 0\.\.1/);
assert.throws(() => tmath.animCurve.reverse({preset: "back", reverse: 1}), /reverse must be a boolean/);
assert.throws(() => invalidEffects.morph(invalidEffectSource, invalidEffectSource), /distinct handles/);
assert.throws(() => invalidEffects.morph(invalidEffectSource, invalidEffectForeign), /same scene/);
assert.throws(() => invalidEffects.morph([invalidEffectSource], invalidEffectTarget), /both be handles or arrays/);
assert.throws(() => invalidEffects.morph([], []), /non-empty and equally sized/);
assert.throws(
    () => invalidEffects.morph([invalidEffectSource], [invalidEffectTarget, invalidEffectSource]),
    /non-empty and equally sized/,
);
assert.throws(
    () => invalidEffects.morph(
        [invalidEffectSource, invalidEffectSource],
        [invalidEffectTarget, invalidEffectTarget],
    ),
    /distinct across all pairs/,
);
assert.throws(() => invalidEffects.replacementTransform(invalidEffectForeign, invalidEffectTarget), /same scene/);
assert.throws(() => invalidEffects.fadeTransform(invalidEffectSource, invalidEffectSource), /distinct handles/);
assert.throws(() => invalidEffects.fadeTransform(invalidEffectSource, invalidEffectForeign), /same scene/);
assert.equal(compileScene(invalidEffects), invalidEffectsBefore);

const dashboard = tmath.scene({ width: 320, height: 180 });
dashboard.space({ id: "dashboard" });
const panelConfig = { width: 160, height: 90, camera: { view: "2d", height: 6 } };
const panel = tmath.scene(panelConfig);
const panelWorld = panel.space({ id: "panel" });
const panelPoint = panelWorld.point({ point: [0, 0], id: "panel-point" });
panel.create(panelPoint, 0.5);
const insetConfig = { width: 80, height: 45 };
const inset = tmath.scene(insetConfig);
const insetWorld = inset.space({ id: "inset" });
insetWorld.circle({ radius: 0.5, id: "inset-circle" });
panel.viewport(inset, { x: 0.5, y: 0, width: 0.5, height: 0.5 });
dashboard.viewport(panel, { x: 0, y: 0, width: 0.5, height: 1 });
panelConfig.width = 999;
panelConfig.camera.height = 9;
insetConfig.height = 999;
assert.throws(() => {
    panel.config = { width: 999 };
}, TypeError);
assert.throws(() => {
    panel.lines = [() => "wait(7)"];
}, TypeError);

const viewportLua = compileScene(dashboard);
assert.doesNotMatch(viewportLua, /999|:wait\([79]\)/);
assert.match(viewportLua, /local object1 = scene:space/);
assert.match(viewportLua, /do\n    local viewportScene1 = tmath\.scene/);
assert.match(viewportLua, /    local object1 = viewportScene1:space/);
assert.match(viewportLua, /    viewportScene1:create\(object2/);
assert.match(viewportLua, /    do\n        local viewportScene2 = tmath\.scene/);
assert.match(viewportLua, /        local object1 = viewportScene2:space/);
assert.match(
    viewportLua,
    /        viewportScene1:viewport\(viewportScene2,\{\["height"\]=0\.5,\["width"\]=0\.5,\["x"\]=0\.5,\["y"\]=0\}\)/,
);
assert.match(
    viewportLua,
    /    scene:viewport\(viewportScene1,\{\["height"\]=1,\["width"\]=0\.5,\["x"\]=0,\["y"\]=0\}\)/,
);

const rect = { x: 0, y: 0, width: 1, height: 1 };
const self = tmath.scene();
assert.throws(() => self.viewport(self, rect), /own viewport child/);
assert.throws(() => self.viewport({}, rect), /tmath JS scene/);
const invalidBoundsChild = tmath.scene();
assert.throws(() => self.viewport(invalidBoundsChild, { x: -0.1, y: 0, width: 1, height: 1 }), /normalized/);
assert.throws(() => self.viewport(invalidBoundsChild, { x: 0, y: 0, width: 0, height: 1 }), /positive/);
assert.throws(() => self.viewport(invalidBoundsChild, { x: 0.5, y: 0, width: 0.6, height: 1 }), /normalized/);
const firstOwner = tmath.scene();
const secondOwner = tmath.scene();
const reused = tmath.scene();
const reusedGroup = reused.group();
const reusedBox = reusedGroup.rectangle();
firstOwner.viewport(reused, rect);
assert.throws(() => firstOwner.viewport(reused, rect), /already owned/);
assert.throws(() => secondOwner.viewport(reused, rect), /already owned/);
assert.throws(() => reused.wait(1), /sealed/);
assert.throws(() => reused.space(), /sealed/);
assert.throws(() => reused.point({ point: [0, 0] }), /sealed/);
assert.throws(() => reusedBox.point({ point: [0, 0] }), /sealed/);
assert.throws(() => reusedBox.moveTo([0, 0]), /sealed/);
assert.throws(() => reusedGroup.arrange(), /sealed/);
assert.throws(() => reused.play({ target: reusedBox, opacity: 0.5 }), /sealed/);
const ancestor = tmath.scene();
const descendant = tmath.scene();
ancestor.viewport(descendant, rect);
assert.throws(() => descendant.viewport(ancestor, rect), /cycle/);

const transitionRoot = tmath.scene({ width: 320, height: 180 });
const transitionFirst = tmath.scene({ width: 160, height: 90 });
transitionFirst.circle({ center: [-1, 0], radius: 0.7, fill: "#4cc9f0", id: "hero" });
const transitionSecond = tmath.scene({ width: 320, height: 180 });
transitionSecond.rectangle({ center: [1, 0], size: [1.8, 1.2], fill: "#f72585", id: "hero" });
transitionRoot.sceneTransition([transitionFirst, transitionSecond], {
    duration: 0.8,
    hold: 0.25,
    curve: tmath.animCurve.preset("snappy", 0.8),
    viewport: { x: 0.1, y: 0.1, width: 0.8, height: 0.8 },
});
const transitionLua = compileScene(transitionRoot);
assert.match(transitionLua, /local transitionScene1_1 = tmath\.scene/);
assert.match(transitionLua, /local transitionScene1_2 = tmath\.scene/);
assert.match(transitionLua, /scene:scene_transition\(\{transitionScene1_1,transitionScene1_2\}/);
assert.match(transitionLua, /\["duration"\]=0\.8/);
assert.throws(() => transitionFirst.wait(1), /sealed/);
assert.throws(() => tmath.scene().sceneTransition([], {}), /at least two/);
assert.throws(() => tmath.scene().sceneTransition([tmath.scene(), {}]), /tmath JS scenes/);
const duplicateTransitionStage = tmath.scene();
assert.throws(() => tmath.scene().sceneTransition([duplicateTransitionStage, duplicateTransitionStage]), /unique/);
assert.throws(() => tmath.scene().sceneTransition([tmath.scene(), tmath.scene()], { duration: 0 }), /positive/);
assert.throws(() => tmath.scene().sceneTransition([tmath.scene(), tmath.scene()], { hold: -1 }), /non-negative/);
assert.throws(
    () => tmath.scene().sceneTransition([tmath.scene(), tmath.scene()], { easing: "smooth", curve: "linear" }),
    /either/,
);
const invalidTransitionRoot = tmath.scene();
const invalidTransitionFirst = tmath.scene();
const invalidTransitionSecond = tmath.scene();
assert.throws(
    () => invalidTransitionRoot.sceneTransition([invalidTransitionFirst, invalidTransitionSecond], { curve() {} }),
    /plain objects/,
);
invalidTransitionFirst.wait(0.1);
invalidTransitionRoot.sceneTransition([invalidTransitionFirst, invalidTransitionSecond]);
assert.throws(() => invalidTransitionRoot.sceneTransition([tmath.scene(), tmath.scene()]), /only one/);

const evaluated = evaluateScene(
    `
const scene = tmath.scene({width: 64, height: 64});
const world = scene.space();
const frame = world.space({id: "frame"});
frame.point({point: [0, 0], id: "origin"});
frame.picture({asset: "pixels", center: [0, 0], width: 2, filter: "nearest"});
frame.picture({pixels: ["#ff0000", "#00ff00"], size: [2, 1], width: 2, filter: "nearest"});
frame.cell({size: [4, 2], texture: "pixels", source: [0, 0, 4, 2], mode: "padd"});
const row = scene.group({id: "row"});
const card = row.rectangle({size: [1.5, 0.8], corner: 0.1});
card.text({text: "card"});
row.arrange();
scene.play({target: card, opacity: 0.75});
const child = tmath.scene({width: 32, height: 32});
child.space().point({point: [0, 0], id: "child-origin"});
scene.viewport(child, {x: 0.5, y: 0.5, width: 0.5, height: 0.5});
return scene;
`,
    "evaluated.js",
);
assert.match(compileScene(evaluated), /\["id"\]="origin"/);
assert.match(compileScene(evaluated), /object1:space/);
assert.match(compileScene(evaluated), /object2:picture/);
assert.match(compileScene(evaluated), /\["pixels"\]=\{"#ff0000","#00ff00"\}/);
assert.match(compileScene(evaluated), /object2:cell/);
assert.match(compileScene(evaluated), /scene:group/);
assert.match(compileScene(evaluated), /:rectangle/);
assert.match(compileScene(evaluated), /:arrange\(/);
assert.match(compileScene(evaluated), /scene:play\(\{\{target=/);
assert.match(compileScene(evaluated), /scene:viewport\(viewportScene1/);
assert.throws(
    () =>
        tmath
            .scene()
            .space()
            .point({ point: [Number.NaN, 0] }),
    /finite/,
);
assert.equal(typeof tmath.scene().point, "function");
assert.equal(tmath.scene().grid, undefined);
assert.equal(world.grid, undefined);
assert.throws(() => tmath.scene().fade(point, 0), /same scene/);
assert.throws(
    () =>
        evaluateScene(
            "const scene=tmath.scene(); scene.viewport(scene,{x:0,y:0,width:1,height:1}); return scene",
            "self-viewport.js",
        ),
    /own viewport child/,
);
assert.throws(
    () =>
        evaluateScene(
            "const root=tmath.scene(); const child=tmath.scene(); root.viewport(child,{x:0,y:0,width:1,height:1}); return child",
            "owned-viewport.js",
        ),
    /owning root/,
);
assert.throws(() => evaluateScene("return 42", "invalid.js"), /must return/);

const audioScene = tmath.scene();
const music = audioScene.sound({
    asset: "theme.ogg", bus: "music", begin: 0.25, end: 8, gain: 0.6, loop: true,
});
music.gain(0.2, 4, 0.5, "ease_out").gain(0.8, 5, 1, "smooth");
const audioLua = compileScene(audioScene);
assert.match(audioLua, /local audio1=tmath\.audio\.cue\(scene,/);
assert.match(audioLua, /audio1:gain\(0\.2,4,0\.5,"ease_out"\)/);
assert.throws(() => tmath.scene().sound({asset: ""}), /asset/);
assert.throws(() => tmath.scene().sound({asset: "hit.wav", bus: "voice"}), /bus/);
assert.throws(() => tmath.scene().sound({asset: "hit.wav", gain: 5}), /gain/);
assert.throws(() => tmath.scene().sound({asset: "hit.wav", begin: 2, end: 1}), /end/);
assert.throws(() => tmath.scene().sound({asset: "hit.wav", unknown: true}), /Unknown/);
assert.throws(() => tmath.scene().sound({asset: "hit.wav"}).gain(1, -1), /begin/);

const directory = mkdtempSync(join(tmpdir(), "tmath-js-binding-"));
try {
    const luaPath = join(directory, "scene.lua");
    writeFileSync(luaPath, lua);
    const result = spawnSync(cliPath, ["inspect", luaPath], { encoding: "utf8" });
    assert.equal(result.status, 0, result.stderr);
    const inspected = JSON.parse(result.stdout);
    assert.equal(inspected.width, 320);
    assert.equal(inspected.height, 180);
    assert.equal(inspected.loop, true);
    assert.deepEqual(
        inspected.objects.map((object) => object.id),
        ["world", "double-arrow", "target"],
    );
    assert.equal(inspected.objects[0].type, "space");
    assert.equal(inspected.objects[0].space, null);
    assert.equal(inspected.objects[1].space, inspected.objects[0].handle);
    assert.equal(inspected.objects[2].space, inspected.objects[0].handle);

    const samplePath = join(directory, "cell-voxel.lua");
    writeFileSync(samplePath, sampleLua);
    const sampleResult = spawnSync(cliPath, ["inspect", samplePath], { encoding: "utf8" });
    assert.equal(sampleResult.status, 0, sampleResult.stderr);
    const inspectedSample = JSON.parse(sampleResult.stdout);
    assert.deepEqual(inspectedSample.objects.map((object) => object.type), [
        "space", "group", "cell", "cell", "cell", "group", "cell",
    ]);
    const voxelGroup = inspectedSample.objects[1];
    assert.equal(voxelGroup.parent, inspectedSample.objects[0].handle);
    for (const cell of inspectedSample.objects.slice(2, 5)) {
        assert.equal(cell.parent, voxelGroup.handle);
        assert.equal(cell.space, inspectedSample.objects[0].handle);
    }
    const cellGroup = inspectedSample.objects[5];
    assert.equal(cellGroup.parent, inspectedSample.objects[0].handle);
    assert.equal(inspectedSample.objects[6].parent, cellGroup.handle);
    assert.equal(inspectedSample.duration, 1);

    const freeformPath = join(directory, "freeform.lua");
    writeFileSync(freeformPath, freeformLua);
    const freeformResult = spawnSync(cliPath, ["inspect", freeformPath], { encoding: "utf8" });
    assert.equal(freeformResult.status, 0, freeformResult.stderr);
    const inspectedFreeform = JSON.parse(freeformResult.stdout);
    assert.equal(inspectedFreeform.width, 480);
    assert.equal(inspectedFreeform.height, 270);
    assert.ok(objectCount(inspectedFreeform) >= 5);
    for (const type of ["group", "rectangle", "text", "circle", "connector"]) {
        assert.ok(
            inspectedFreeform.objects.some((object) => object.type === type),
            `freeform scene is missing ${type}`,
        );
    }

    const viewportPath = join(directory, "viewport.lua");
    writeFileSync(viewportPath, viewportLua);
    const viewportResult = spawnSync(cliPath, ["inspect", viewportPath], { encoding: "utf8" });
    assert.equal(viewportResult.status, 0, viewportResult.stderr);
    const inspectedViewport = JSON.parse(viewportResult.stdout);
    assert.equal(inspectedViewport.viewports.length, 1);
    assert.equal(inspectedViewport.viewports[0].scene.viewports.length, 1);
    const viewportBenchmark = spawnSync(cliPath, ["benchmark", viewportPath, "--frames", "1", "--warmup", "0"], {
        encoding: "utf8",
    });
    assert.equal(viewportBenchmark.status, 0, viewportBenchmark.stderr);
    assert.equal(JSON.parse(viewportBenchmark.stdout).objects, 5);
    for (const invalidFrames of ["+1", "-1", " 1", "4294967296", "18446744073709551616"]) {
        const invalidBenchmark = spawnSync(cliPath, ["benchmark", viewportPath, "--frames", invalidFrames], {
            encoding: "utf8",
        });
        assert.equal(invalidBenchmark.status, 2, `Accepted invalid frame count ${JSON.stringify(invalidFrames)}`);
    }

    const maximumDuration = tmath.scene({ width: 16, height: 16 });
    maximumDuration.wait(3.4028234663852886e38);
    const maximumDurationPath = join(directory, "maximum-duration.lua");
    writeFileSync(maximumDurationPath, compileScene(maximumDuration));
    const maximumDurationBenchmark = spawnSync(
        cliPath,
        ["benchmark", maximumDurationPath, "--frames", "3", "--warmup", "0"],
        { encoding: "utf8" },
    );
    assert.equal(maximumDurationBenchmark.status, 0, maximumDurationBenchmark.stderr);

    const diagramFont = resolve(repoRoot, "src/examples/assets/Pretendard.ttf");
    const themeLayout = spawnSync(
        cliPath,
        [
            "layout",
            resolve(repoRoot, "src/examples/lua/theme_showcase.lua"),
            "--padding",
            "4",
            "--font",
            diagramFont,
        ],
        { encoding: "utf8" },
    );
    assert.equal(themeLayout.status, 0, `theme-showcase/layout: ${themeLayout.stderr}`);
    const themeReport = JSON.parse(themeLayout.stdout).scene;
    assert.equal(themeReport.viewports.length, 8);
    for (const viewport of themeReport.viewports) {
        const objects = new Map(viewport.scene.objects.map((object) => [object.handle, object]));
        const textCollisions = viewport.scene.intersections.filter((pair) => {
            return objects.get(pair.first)?.type === "text" && objects.get(pair.second)?.type === "text";
        });
        assert.deepEqual(textCollisions, [], "theme-showcase has colliding text roles");
        assert.equal(
            boundsOverlap(viewport.scene, "vector", "point"),
            false,
            "theme-showcase arrowhead overlaps its endpoint marker",
        );
    }
    const objectGalleryLayout = spawnSync(
        cliPath,
        [
            "layout",
            resolve(repoRoot, "src/examples/lua/object_gallery.lua"),
            "--font",
            diagramFont,
        ],
        { encoding: "utf8" },
    );
    assert.equal(objectGalleryLayout.status, 0, `object-gallery/layout: ${objectGalleryLayout.stderr}`);
    const galleryLayout = JSON.parse(objectGalleryLayout.stdout);
    const galleryReport = galleryLayout.scene;
    assert.ok(galleryLayout.report.visuals.length > 0, "object-gallery layout report has no rendered visuals");
    for (const visual of galleryLayout.report.visuals) {
        assert.ok(
            Number.isInteger(visual.object) && visual.object >= 0 && visual.object < galleryLayout.report.objects.length,
            "layout visual does not reference a semantic object",
        );
        assert.ok(
            visual.counterpart === null ||
                Number.isInteger(visual.counterpart) && visual.counterpart >= 0 &&
                visual.counterpart < galleryLayout.report.objects.length,
            "layout visual counterpart is neither null nor a semantic object",
        );
        assert.ok(
            visual.occluder === null ||
                Number.isInteger(visual.occluder) && visual.occluder >= 0 &&
                visual.occluder < galleryLayout.report.scenes.length,
            "layout visual occluder is neither null nor a Scene",
        );
        assert.ok(["stable", "morph", "fade-out", "fade-in"].includes(visual.kind), "unknown layout visual kind");
        assert.ok(Number.isInteger(visual.layer), "layout visual layer is not an integer");
        assert.ok(Number.isFinite(visual.opacity), "layout visual opacity is not finite");
        assert.equal(typeof visual.visible, "boolean");
        assert.equal(typeof visual.clipped, "boolean");
        assert.equal(typeof visual.occluded, "boolean");
    }
    assert.ok(galleryLayout.report.paths.length > 0, "object-gallery layout report has no sampled paths");
    for (const path of galleryLayout.report.paths) {
        assert.ok(
            Number.isInteger(path.visual) && path.visual >= 0 && path.visual < galleryLayout.report.visuals.length,
            "sampled path does not reference a physical visual",
        );
        assert.ok(path.points.length >= 2 && path.points.every((point) => {
            return Number.isFinite(point.x) && Number.isFinite(point.y);
        }), "sampled path has invalid root-pixel vertices");
        assert.ok(Number.isFinite(path.strokeWidth) && path.strokeWidth >= 0);
        assert.equal(typeof path.closed, "boolean");
        assert.equal(typeof path.filled, "boolean");
        assert.equal(typeof path.stroked, "boolean");
        assert.ok(Number.isFinite(path.paintBounds.x) && Number.isFinite(path.paintBounds.y));
        assert.ok(path.paintBounds.width >= 0 && path.paintBounds.height >= 0);
    }
    assert.equal(
        boundsOverlap(galleryReport.viewports[2].scene, "vector", "point"),
        false,
        "object-gallery vector arrowhead overlaps its endpoint marker",
    );
    assert.equal(
        boundsOverlap(galleryReport.viewports[4].scene, "space-vector", "space-point"),
        false,
        "object-gallery Space vector arrowhead overlaps its endpoint marker",
    );
} finally {
    rmSync(directory, { recursive: true, force: true });
}
