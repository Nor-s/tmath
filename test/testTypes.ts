import {
    createTMath,
    tmath,
    type AnimCurve,
    type AudioCueHandle,
    type AnimationSpec,
    type BBox,
    type GroupHandle,
    type Mat4,
    type ObjectHandle,
    type RectangleOptions,
    type RenderEngine,
    type SceneTransitionOptions,
    type StyleGroupHandle,
    type ThemeOptions,
    type TMathInputSample,
    type TMathAudio,
    type ViewportBounds,
} from "../wasm/client.js";

declare const runtimeAudio: TMathAudio;
const clickVoice = runtimeAudio.play("click.wav", {bus: "ui", gain: 0.8, rate: 1.25});
runtimeAudio.active(clickVoice);
runtimeAudio.stop(clickVoice);
runtimeAudio.masterGain(0.75);
runtimeAudio.busGain("music", 0.5);
runtimeAudio.transport({time: 1.25, rate: 0.5, playing: true, seek: true});

const inputSample: TMathInputSample = {
    position: {x: 60, y: 50},
    value: {x: 0.3, y: 0.5},
    rgba: [205, 0, 50, 255],
    object: {handle: 42, id: "gradient", type: "rectangle"},
};
void inputSample;

const customTheme: ThemeOptions = {
    preset: "pro_black",
    background: "#ffffff",
    text: {
        h1: {font: "Pretendard", size: 36, color: "#202124"},
        code: {font: "Pretendard", size: 14, color: "#9b3600"},
    },
    objects: ["#5e7a9b", "#b8915a", "#557b63"],
    object_width: 1.5,
    gradient: true,
    end_gradient_stop: "#778899",
    axis: {x: "#9b3600", y: "#557b63", z: "#5e7a9b"},
    colors: {accent: "#4cc9f0", success: "#7bd88f", warning: "#ffd166", danger: "#ff6b6b"},
};
const namedTheme: ThemeOptions = {preset: "3_blue_1_eyes"};
void namedTheme;
const definition = tmath.scene({
    width: 960,
    height: 540,
    loop: true,
    theme: customTheme,
    camera: {mode: "interactive", view: "2d", target: [0, 0], height: 6},
});
const music: AudioCueHandle = definition.sound({
    asset: "theme.ogg", bus: "music", begin: 0, end: 12, gain: 0.6, loop: true,
});
music.gain(0.2, 4, 0.5, "ease_out").gain(0.8, 5, 1, "gentle");
const world = definition.space({
    x: [-3, 3, 1], y: [-2, 2, 1], numbers: true,
    number_mode: "relative", number_size: 14, number_color: "#aabbcc",
});
const frame = world.space({matrix: [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]});
const arrow = frame.arrow({
    from: [-2, 0],
    to: [2, 0],
    tail: 12,
    tip: 16,
    color: "accent",
});
const point = world.point({point: [0, 1, -2], radius: 5});
const identity: StyleGroupHandle = definition.styleGroup({
    members: [{target: arrow, channel: "stroke"}, {target: point, channel: "fill"}],
});
definition.style(identity, "result", 0.4, "gentle");
definition.indicate(point, {color: "focus", duration: 0.2});
const circleCells: GroupHandle = world.cell(
    (x, y, time) => x * x / ((1 + time) ** 2) + y * y <= 4 ? "#0891b2" : "#00000000",
    {mode: "padd", padding: 0.08, duration: 1, fps: 24},
);
const voxels: GroupHandle = world.voxel(
    (x, y, z, time) => x * x + y * y + z * z < (1 + time) ** 2 ? "#2563eb" : "#00000000",
    {mode: "padd", padding: 0.08, duration: 1, fps: 24},
);
world.image({asset: "pixels", width: 2, filter: "nearest"});
world.image({pixels: ["#ff0000", "#00ff00"], size: [2, 1], width: 2, filter: "nearest"});
world.cell({size: [4, 2], texture: "pixels", source: [0, 0, 4, 2], mode: "padd"});
world.surface({
    points: [[-1, 0, -1], [1, 0, -1], [-1, 0, 1], [1, 0, 1]],
    size: [2, 2],
    mode: "solid",
});
const matrix: Mat4 = [
    0.72, -0.69, 0, 0,
    0.69, 0.72, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1,
];
definition.create([arrow, point], 0.8, "ease_out", 0.1);
definition.create(arrow, 0.8, "ease_out", 0, "clockwise");
definition.uncreate(point, 0.6, "smooth", 0, "reverse");
definition.fillReveal(arrow, 0.3, "ease_out");
definition.drawBorderThenFill(arrow, 0.8, "ease_in_out", 0, "clockwise");
definition.write(arrow, 0.8, "gentle", 0, "forward");
definition.fadeIn(point, {shift: [0, 0.5], scale: 0.9, duration: 0.5, easing: "ease_out"});
definition.fadeOut(point, {shift: [0, -0.5], scale: 1.1});
definition.growFromCenter(point, 0.5, "ease_out");
definition.growFromEdge(point, "bottom", 0.5, "ease_out");
definition.shrinkToCenter(point, 0.5, "ease_in");
definition.indicate(point, {color: "warning", scale: 1.2, duration: 0.7});
const morphSource = definition.polygon({points: [[-1, -1], [1, -1], [0, 1]]});
const morphTarget = definition.polygon({points: [[-1, 0], [1, -1], [1, 1]]});
definition.morph(morphSource, morphTarget, 0.8, "ease_in_out");
const morphReplacement = definition.polygon({points: [[-1, -1], [1, 0], [-1, 1]]});
definition.replacementTransform(morphTarget, morphReplacement, 0.8, "ease_in_out");
const fadeTarget = definition.text({text: "result", point: [0, 0]});
definition.fadeTransform(morphReplacement, fadeTarget, 0.25, "gentle");
const batchSource = definition.plot({points: [[-1, 0], [0, 1], [1, 0]]});
const batchTarget = definition.plot({points: [[-1, 0], [0, -1], [1, 0]]});
definition.morph([batchSource], [batchTarget], 0.8, "ease_in_out", 0.1);
definition.transform(arrow, matrix, 1.2, "ease_in_out").wait(0.2);
definition.transition(arrow, point, 0.4, "smooth");
definition.transform(point, matrix);

const group: GroupHandle = definition.group({id: "nodes", matrix});
const rectangleOptions: RectangleOptions = {
    center: [-1, 0], size: [1.5, 0.8], corner: 0.1, fill: "#264653",
};
const rectangle: ObjectHandle = group.rectangle(rectangleOptions);
const label = rectangle.label({text: "node", point: [-1, 0]});
const sibling = group.circle({center: [1, 0], radius: 0.5});
definition.styleBind(identity, sibling, "fill");
const connector = group.connector(rectangle, sibling, {padding: 0.1, tail: 8, tip: 12, stroke: "#e9c46a"});
definition.line({from: [-2, -1], to: [2, -1], dash: [8, 4], dash_offset: 2});
const flowing = definition.line({from: [-2, -1.5], to: [2, -1.5], dash: [8, 4]});
definition.play({target: flowing, dash_offset: -12}, 0.8, "linear");
rectangle.moveTo([-1.25, 0]).nextTo(sibling, [1, 0], 0.4).alignTo(sibling, [0, 1, 0]);
group.arrange().arrange([1, 0, 0], 0.3).arrangeGrid(2, 0.2, 0.4);
rectangle.group().rectangle().circle().point({point: [0, 0]});
definition.point({point: [0, 0]});
definition.line({from: [-1, 0], to: [1, 0]});
definition.line({from: [-1, 0], to: [1, 0], gradient: "#fedcba"});
definition.circle({gradient: false});
definition.arrow({from: [-1, 0], to: [1, 0]});
definition.vector({value: [1, 2, 3]});
definition.rectangle({size: [2, 1]});
definition.polygon({points: [[-1, 0], [1, 0], [0, 1]]});
definition.plot({points: [[-1, 0], [1, 1]]});
definition.route({
    points: [[-2, 0], [0, 1], [2, 0]],
    tail: 8,
    tip: 14,
    dash: [8, 4],
    dash_offset: -2,
});
definition.path({commands: [
    {type: "move", to: [-2, 0]},
    {type: "line", to: [-1, 1]},
    {type: "quadratic", control: [0, 2], to: [1, 1]},
    {type: "cubic", control1: [1.5, 0.5], control2: [2, -0.5], to: [2.5, 0]},
    {type: "close"},
], samples: 24});
definition.curve({from: [-2, 0], control1: [-1, 2], control2: [1, -2], to: [2, 0], samples: 32});
definition.surface({points: [[-1, 0], [1, 0], [-1, 1], [1, 1]], size: [2, 2], mode: "mesh", shading: false});
definition.text({text: "root", orientation: "plane", size: 0.5, role: "code"});
// @ts-expect-error Label is an Object-only child Text convenience.
definition.label({text: "scene label"});
definition.ruler({from: [-1, 0], to: [1, 0]});
definition.svg({path: "M0 0L1 1"});
definition.image({asset: "pixels"});
definition.image({pixels: ["#ff0000"], size: [1, 1]});
definition.cell({size: [2, 2]});
definition.connector(rectangle, sibling);
const animation: AnimationSpec = {target: rectangle, shift: [0.5, 0], opacity: 0.5, fill: "#f4a261"};
definition.play(animation, 0.8, "ease_out", 0.1);
definition.play([
    {target: sibling, transform: matrix},
    {target: connector, stroke: "#e76f51", tail: 10, tip: 16},
] as const, 1.2, "ease_in_out", 0.2);
const backCurve: AnimCurve = tmath.animCurve.preset("back", 1.35);
const customCurve: AnimCurve = tmath.animCurve.cubicBezier(0.2, 0.9, 0.3, 1, 0.8);
const reversedCurve: AnimCurve = tmath.animCurve.reverse(backCurve);
definition.shift(sibling, [0.5, 0], 0.8, backCurve);
definition.shift(sibling, [-0.5, 0], 0.8, reversedCurve);
definition.fadeIn(point, {duration: 0.5, curve: customCurve});

// @ts-expect-error Effect options cannot specify both easing and curve.
definition.fadeOut(point, {easing: "smooth", curve: "bounce"});
// @ts-expect-error Image sources use either an asset or an inline pixel buffer.
definition.image({asset: "pixels", pixels: ["#fff"], size: [1, 1]});
// @ts-expect-error Inline image pixels require their buffer dimensions.
definition.image({pixels: ["#fff"]});
// @ts-expect-error Animation curve preset names are closed.
tmath.animCurve.preset("warp");

// @ts-expect-error Group matrices must be complete Mat4 values.
definition.group({matrix: [1, 0]});
// @ts-expect-error Rectangle size must be a two-dimensional vector.
definition.rectangle({size: [1, 2, 3]});
// @ts-expect-error Stroke dash patterns contain at most four values.
definition.line({from: [0, 0], to: [1, 0], dash: [1, 2, 3, 4, 5]});
// @ts-expect-error A quadratic Path command requires one control point.
definition.path({commands: [{type: "move", to: [0, 0]}, {type: "quadratic", to: [1, 1]}]});
// @ts-expect-error Curve endpoints and controls use world vectors.
definition.curve({from: [0, 0], control1: [0, 1], control2: [1, 1], to: "end"});
// @ts-expect-error Connector endpoints must be object handles.
definition.connector(rectangle, {point: [0, 0]});
// @ts-expect-error Connector endpoints belong in positional arguments, not options.
definition.connector(rectangle, sibling, {from: rectangle});
// @ts-expect-error Relative layout targets must be object handles.
rectangle.nextTo({point: [0, 0]}, [1, 0]);
// @ts-expect-error Only GroupHandle provides arrange.
rectangle.arrange();
// @ts-expect-error Only SpaceHandle provides voxel sampling.
rectangle.voxel(() => "#fff");
// @ts-expect-error ObjectHandle.cell accepts CellOptions, not a sampling callback.
rectangle.cell(() => "#fff");
// @ts-expect-error A cell callback returns a color string.
world.cell(() => 42);
// @ts-expect-error A voxel callback returns a color string.
world.voxel(() => 42);
// @ts-expect-error A play descriptor must animate at least one property.
definition.play({target: rectangle});
// @ts-expect-error shift and transform are mutually exclusive for one target.
definition.play({target: rectangle, shift: [1, 0], transform: matrix});
// @ts-expect-error play targets must be object handles.
definition.play({target: definition, opacity: 0.5});
// @ts-expect-error Unknown animation properties are rejected.
definition.play({target: rectangle, opacity: 0.5, spin: 1});
// @ts-expect-error Create direction is a closed string union.
definition.create(rectangle, 1, "smooth", 0, "diagonal");
// @ts-expect-error Fade scale must be numeric.
definition.fadeIn(rectangle, {scale: "small"});
// @ts-expect-error Fade options reject unknown properties.
definition.fadeOut(rectangle, {spin: 1});
// @ts-expect-error Indicate color must be a color string.
definition.indicate(rectangle, {color: 42});
// @ts-expect-error Morph targets must be object handles.
definition.morph(rectangle, definition);
// @ts-expect-error Theme presets are a closed string union.
tmath.scene({theme: "editorial"});
// @ts-expect-error Theme object colors are strings.
tmath.scene({theme: {objects: [42]}});
// @ts-expect-error Text roles are a closed string union.
definition.text({text: "caption", role: "caption"});

const detail = tmath.scene({width: 480, height: 270, camera: {view: "3d"}});
detail.space().vector({value: [1, 2, 3]});
const overview = tmath.scene({width: 480, height: 270});
overview.space().point({point: [0, 0]});
overview.viewport(detail, {x: 0.5, y: 0.5, width: 0.5, height: 0.5});
const overviewBounds: ViewportBounds = {x: 0, y: 0, width: 0.5, height: 1};
definition.viewport(overview, overviewBounds);

const transitionA = tmath.scene({width: 480, height: 270});
transitionA.circle({id: "hero"});
const transitionB = tmath.scene({width: 960, height: 540});
transitionB.rectangle({id: "hero"});
const transitionOptions: SceneTransitionOptions = {
    duration: 0.8, hold: 0.2, curve: "snappy",
    viewport: {x: 0, y: 0, width: 1, height: 1},
};
definition.sceneTransition([transitionA, transitionB], transitionOptions);

// @ts-expect-error A viewport child must be another SceneBuilder.
definition.viewport(world, overviewBounds);
// @ts-expect-error All normalized viewport bounds are required.
definition.viewport(tmath.scene(), {x: 0, y: 0, width: 1});
// @ts-expect-error Viewport bounds must contain numbers.
definition.viewport(tmath.scene(), {x: 0, y: 0, width: "1", height: 1});
// @ts-expect-error Scene transitions require SceneBuilder stages.
definition.sceneTransition([tmath.scene(), world]);
// @ts-expect-error Scene transition hold is numeric.
definition.sceneTransition([tmath.scene(), tmath.scene()], {hold: "short"});

async function preview(canvas: HTMLCanvasElement)
{
    const scene = await createTMath(definition, "typed-scene.ts", {renderEngine: "cpu"});
    const renderEngine: RenderEngine = scene.renderEngine;
    const loops: boolean = scene.loop;
    const bounds: BBox = scene.bounds("nodes", 0);
    const overlaps: boolean = scene.intersects("nodes", "target", 0, 4);
    const report = scene.layoutReport(0, 4);
    const containmentPassed: boolean = report.containments.every((item) => item.contained);
    const lottie: Uint8Array = scene.lottie(30);
    void loops;
    void bounds;
    void overlaps;
    void containmentPassed;
    void lottie;
    void renderEngine;
    scene.asset("pixels", new Uint8Array([1, 2, 3]), "png");
    scene.draw(canvas, scene.duration);
    scene.draw(canvas, scene.duration, 2);
    // @ts-expect-error Canvas pixel ratio is numeric.
    scene.draw(canvas, scene.duration, "2");
    // @ts-expect-error Render engine must be CPU or GL.
    void createTMath(definition, "invalid-engine.ts", {renderEngine: "gpu"});
    scene.destroy();
}

void preview;
void label;
