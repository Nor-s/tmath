import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import {fileURLToPath} from "node:url";

const extensionRoot = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const repositoryRoot = path.resolve(extensionRoot, "..", "..");
const api = JSON.parse(fs.readFileSync(path.join(extensionRoot, "api", "tmath-api.json"), "utf8"));
const binding = fs.readFileSync(path.join(repositoryRoot, "src", "core", "lua", "tmathLua.cpp"), "utf8");
const uiBinding = fs.readFileSync(path.join(repositoryRoot, "src", "core", "ui", "tmathUiLua.cpp"), "utf8");
const inputBinding = fs.readFileSync(path.join(repositoryRoot, "src", "core", "input", "tmathInputLua.cpp"), "utf8");
const runtimeBinding = fs.readFileSync(path.join(repositoryRoot, "src", "core", "lua_runtime", "tmathLuaRuntime.cpp"), "utf8");
const motionBinding = fs.readFileSync(path.join(repositoryRoot, "src", "core", "motion", "tmathMotionLua.cpp"), "utf8");
const diagramBinding = fs.readFileSync(path.join(repositoryRoot, "src", "core", "diagram", "tmathDiagramLua.cpp"), "utf8");

const sceneMethods = registrationNames(binding, "SCENE_METHODS");
const objectMethods = registrationNames(binding, "OBJECT_METHODS");
const panelMethods = registrationNames(uiBinding, "methods");
const inputMethods = registrationNames(inputBinding, "methods");
const runtimeMethods = registrationNames(runtimeBinding, "methods");
const motionMethods = registrationNames(motionBinding, "methods");
const diagramMethods = registrationNames(diagramBinding, "diagramMethods");
const diagramBuiltMethods = registrationNames(diagramBinding, "builtMethods");
const factories = Object.keys(api.factories);

assert.deepEqual(sceneMethods, [...factories, ...Object.keys(api.methods.Scene)].sort(), "Scene API schema differs from SCENE_METHODS");
assert.deepEqual(objectMethods, [...factories, ...Object.keys(api.methods.Object)].sort(), "Object API schema differs from OBJECT_METHODS");
assert.deepEqual(Object.keys(api.methods.Space).sort(), ["cell", "voxel"], "Space-only methods changed");
assert.deepEqual(Object.keys(api.methods.Panel).sort(), panelMethods, "Panel API schema differs from the optional UI binding");
assert.equal(api.namespaces.ui.type, "UI");
assert.equal(api.namespaces.ui.functions.panel.returns, "Panel");
assert.deepEqual(api.namespaces.ui.functions.panel.parameters, [{name: "scene", type: "Scene"}]);
assert.deepEqual(Object.keys(api.methods.InputController).sort(), inputMethods,
    "InputController API schema differs from the optional Input binding");
assert.equal(api.namespaces.input.type, "Input");
assert.equal(api.namespaces.input.functions.controller.returns, "InputController");
assert.deepEqual(api.namespaces.input.functions.controller.parameters, [{name: "scene", type: "Scene"}]);
assert.deepEqual(Object.keys(api.methods.Runtime).sort(), runtimeMethods,
    "Runtime API schema differs from the optional retained Lua binding");
assert.deepEqual(api.globals.runtime.parameters,
    [{name: "scene", type: "Scene"}, {name: "config", type: "RuntimeConfig"}]);
assert.equal(api.globals.runtime.returns, "Runtime");
assert.deepEqual(Object.keys(api.methods.MotionController).sort(), motionMethods,
    "MotionController API schema differs from the optional Motion binding");
assert.match(motionBinding, /lua_setfield\(lua, -2, "motion"\)/);
assert.deepEqual(api.globals.motion.parameters, [{name: "scene", type: "Scene"}]);
assert.equal(api.globals.motion.returns, "MotionController");
for (const factory of Object.values(api.factories)) assert.ok(api.configs[factory.config], `Missing ${factory.config}`);
for (const method of ["button", "toggle_button", "slider", "sample_area"]) {
    const config = api.methods.Panel[method].parameters[0]?.type;
    assert.ok(api.configs[config], `Missing Panel method config ${config}`);
}
for (const config of ["RegionConfig", "UITransformConfig", "SliderBindingConfig", "PanelButtonConfig", "PanelToggleButtonConfig", "PanelSliderConfig", "PanelSampleAreaConfig"]) {
    assert.ok(api.configs[config], `Missing experimental UI config ${config}`);
}
for (const method of ["pointer_follow", "key_move"]) {
    const config = api.methods.InputController[method].parameters[0]?.type;
    assert.ok(api.configs[config], `Missing InputController method config ${config}`);
}
assert.equal(api.configs.PanelButtonConfig.target.type, "Object");
assert.equal(api.configs.PanelButtonConfig.transform.type, "UITransformConfig");
assert.equal(api.configs.PanelButtonConfig.duration.type, "number");
assert.equal(api.configs.PanelButtonConfig.hover_visual.type, "Object");
assert.equal(api.configs.PanelButtonConfig.pressed_visual.type, "Object");
assert.equal(api.configs.PanelToggleButtonConfig.target.type, "Object");
assert.equal(api.configs.PanelToggleButtonConfig.off.type, "UITransformConfig");
assert.equal(api.configs.PanelToggleButtonConfig.on.type, "UITransformConfig");
assert.equal(api.configs.PanelToggleButtonConfig.value.type, "boolean");
assert.equal(api.configs.PanelSliderConfig.target.type, "Object");
assert.equal(api.configs.PanelSliderConfig.bindings.type, "SliderBindingConfig[]");
assert.equal(api.configs.SliderBindingConfig.target.required, true);
assert.equal(api.configs.PanelSampleAreaConfig.region.type, "RegionConfig");
assert.equal(api.configs.PanelSampleAreaConfig.targets.type, "Object[]");
assert.equal(api.configs.PanelSampleAreaConfig.marker.type, "Object");
assert.equal(api.configs.PanelSampleAreaConfig.swatch.type, "Object");
assert.equal(api.methods.Panel.toggle, undefined);

assert.deepEqual(Object.keys(api.methods.Diagram).sort(), diagramMethods,
    "Diagram API schema differs from the optional Diagram binding");
assert.deepEqual(Object.keys(api.methods.DiagramBuilt).sort(), diagramBuiltMethods,
    "DiagramBuilt API schema differs from the optional Diagram binding");
assert.match(diagramBinding, /lua_setfield\(lua, -2, "diagram"\)/);
assert.deepEqual(api.globals.diagram.parameters,
    [{name: "scene", type: "Scene"}, {name: "config", type: "DiagramConfig"}]);
assert.equal(api.globals.diagram.returns, "Diagram");

assertConfig("DiagramConfig", optionNames(diagramBinding, "_newDiagram"), []);
assertConfig("DiagramLayersConfig", optionNames(diagramBinding, "_fieldLayers"), []);
assertConfig("DiagramNodeConfig", optionNames(diagramBinding, "_addNode"), ["id"]);
assertConfig("DiagramEdgeConfig", optionNames(diagramBinding, "_addEdge"), ["from", "id", "to"]);
assertConfig("DiagramZoneConfig", optionNames(diagramBinding, "_addZone"), ["id", "members"]);
assertConfig("PanelToggleButtonConfig", optionNames(uiBinding, "_toggleButton"),
    ["off", "on", "region", "target", "visual"]);
assertConfig("PanelSliderConfig", optionNames(uiBinding, "_slider"),
    ["region", "visual"]);
assertConfig("InputPointerFollowConfig", optionNames(inputBinding, "_pointerFollow"),
    ["map_origin", "map_x", "map_y", "region", "target"]);
assertConfig("InputKeyMoveConfig", optionNames(inputBinding, "_keyMove"),
    ["key", "shift", "target"]);
assertConfig("RuntimeConfig", optionNames(runtimeBinding, "_newRuntime"), ["update"]);
assertConfig("RuntimeObjectState", optionNames(runtimeBinding, "_objectState"), []);
assertConfig("RuntimeSoundConfig", optionNames(runtimeBinding, "_sound"), []);
assertConfig("MotionState", optionNames(motionBinding, "_state"), []);
assertConfig("MotionTarget", optionNames(motionBinding, "_transitionMany"), ["object", "state"]);

const meta = fs.readFileSync(path.join(extensionRoot, "api", "tmath.d.lua"), "utf8");
for (const name of sceneMethods) assert.match(meta, new RegExp(`function Scene:${name}\\(`));
assert.match(meta, /function Library\.scene\(/);
assert.match(meta, /---@field ui\? tmath\.UI Experimental interactive UI module/);
assert.match(meta, /function UI\.panel\(scene\)/);
for (const name of panelMethods) assert.match(meta, new RegExp(`function Panel:${name}\\(`));
for (const config of ["RegionConfig", "UITransformConfig", "SliderBindingConfig", "PanelButtonConfig", "PanelToggleButtonConfig", "PanelSliderConfig", "PanelSampleAreaConfig"]) {
    assert.match(meta, new RegExp(`---@class tmath\\.${config}`));
}
assert.match(meta, /---@field input\? tmath\.Input Experimental keyboard, pointer, and camera Input module/);
assert.match(meta, /function Input\.controller\(scene\)/);
for (const name of inputMethods) assert.match(meta, new RegExp(`function InputController:${name}\\(`));
for (const config of ["InputPointerFollowConfig", "InputKeyMoveConfig"]) {
    assert.match(meta, new RegExp(`---@class tmath\\.${config}`));
}
assert.match(meta, /function Library\.runtime\(scene, config\)/);
for (const name of runtimeMethods) assert.match(meta, new RegExp(`function Runtime:${name}\\(`));
for (const config of [
    "RuntimeConfig", "RuntimeObjectState", "RuntimeActionState", "RuntimeKeyState",
    "RuntimePointerState", "RuntimeSoundConfig",
]) assert.match(meta, new RegExp(`---@class tmath\\.${config}`));
assert.match(meta, /function Library\.motion\(scene\)/);
for (const name of motionMethods) assert.match(meta, new RegExp(`function MotionController:${name}\\(`));
for (const config of ["MotionState", "MotionTarget", "MotionCurveRecord", "MotionEvent"]) {
    assert.match(meta, new RegExp(`---@class tmath\\.${config}`));
}
assert.match(meta, /function Library\.diagram\(scene, config\)/);
for (const [owner, methods] of [
    ["Diagram", diagramMethods], ["DiagramBuilt", diagramBuiltMethods],
]) {
    assert.match(meta, new RegExp(`---@class tmath\\.${owner}`));
    for (const name of methods) assert.match(meta, new RegExp(`function ${owner}:${name}\\(`));
}
for (const name of ["DiagramNode", "DiagramEdge", "DiagramZone"]) {
    assert.match(meta, new RegExp(`---@class tmath\\.${name}`));
}
for (const config of [
    "DiagramConfig", "DiagramLayersConfig", "DiagramNodeConfig", "DiagramEdgeConfig",
    "DiagramZoneConfig",
]) assert.match(meta, new RegExp(`---@class tmath\\.${config}`));

console.log("Lua API schema and generated LuaLS metadata are synchronized");

function registrationNames(source, constant) {
    const body = new RegExp(`static const luaL_Reg ${constant}\\[\\] = \\{([\\s\\S]*?)\\};`).exec(source)?.[1];
    assert.ok(body, `Could not find ${constant}`);
    return Array.from(body.matchAll(/\{"([^"]+)",/g), (match) => match[1]).sort();
}

function optionNames(source, functionName) {
    const escaped = functionName.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const start = new RegExp(`static [^\\n]+ ${escaped}\\(`).exec(source)?.index;
    assert.notEqual(start, undefined, `Could not find ${functionName}`);
    const end = source.indexOf("\nstatic ", start + 1);
    const body = source.slice(start, end < 0 ? source.length : end);
    const initializer = /static const char\* const options\[\]\s*=\s*\{([\s\S]*?)\};/.exec(body)?.[1];
    assert.ok(initializer, `Could not find options in ${functionName}`);
    return Array.from(initializer.matchAll(/"([^"]+)"/g), (match) => match[1]).sort();
}

function assertConfig(name, fields, required) {
    assert.ok(api.configs[name], `Missing ${name}`);
    assert.deepEqual(Object.keys(api.configs[name]).sort(), fields,
        `${name} differs from its binding options`);
    assert.deepEqual(Object.entries(api.configs[name])
        .filter(([, field]) => field.required)
        .map(([field]) => field)
        .sort(), required.sort(), `${name} required fields differ from the binding contract`);
}
