import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import {fileURLToPath} from "node:url";
import {createTMath, tmath} from "../runtime/client.js";

const extensionRoot = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const wasmBinary = fs.readFileSync(path.join(extensionRoot, "runtime", "tmath-wasm.wasm"));
const font = fs.readFileSync(path.join(extensionRoot, "runtime", "Pretendard.ttf"));
const diagramTemplatesRoot = path.join(
    extensionRoot, "..", "skills", "tmath-skills", "templates", "diagram",
);
const diagramTemplates = [
    {file: "native-diagram.lua", root: "request-flow:root"},
    {
        file: "causal-loop.lua", root: "process-lifecycle:root",
        required: [
            "process-lifecycle:header-rule",
            "process-lifecycle:state:waiting:body",
            "process-lifecycle:transition:running-ready:route",
            "process-lifecycle:transition:waiting-ready:route",
        ],
        initiallyHidden: ["process-lifecycle:transition:waiting-ready:label"],
    },
    {
        file: "swimlane.lua", root: "release-handoff:root",
        required: [
            "release-handoff:header-rule",
            "release-handoff:handoff:submit-triage:route",
            "release-handoff:handoff:deploy-notify:route",
        ],
    },
    {
        file: "state-flow.lua", root: "job-state:root",
        required: [
            "job-state:start",
            "job-state:choice:validation",
            "job-state:final:complete:ring",
            "job-state:transition:retry-validate:route",
        ],
    },
    {
        file: "hierarchy-dependency.lua", root: "capability-tree:root",
        required: [
            "capability-tree:primary-rail",
            "capability-tree:leaf-buses",
            "capability-tree:dependency:scheduler-export",
        ],
    },
    {
        file: "timeline-gantt.lua", root: "release-plan:root",
        required: [
            "release-plan:axis",
            "release-plan:grid:10",
            "release-plan:task:build:bar",
            "release-plan:task:release:milestone",
        ],
        initiallyHidden: ["release-plan:task:release:milestone-label"],
    },
    {
        file: "er-schema.lua", root: "commerce-schema:root",
        required: [
            "commerce-schema:entity:order:header-divider",
            "commerce-schema:entity:order:type-divider",
            "commerce-schema:relation:user-orders:many-top",
            "commerce-schema:relation:user-orders:to-cardinality",
        ],
    },
    {
        file: "reliability-stack.lua", root: "reliability-stack:root",
        required: [
            "reliability-stack:request:api-store",
            "reliability-stack:trace-axis",
            "reliability-stack:span:store:bar",
        ],
        initiallyHidden: ["reliability-stack:span:edge:duration"],
    },
    {
        file: "layered-system-structure.lua", root: "system-structure:root",
        required: [
            "system-structure:boundary:core",
            "system-structure:route:core-gpu",
            "system-structure:module-rail",
        ],
    },
    {
        file: "bidirectional-render-flow.lua", root: "render-flow:root",
        required: [
            "render-flow:rail:commands",
            "render-flow:rail:frames",
            "render-flow:dispatch:gpu",
        ],
    },
    {
        file: "benchmark-report.lua", root: "benchmark-report:root",
        required: [
            "benchmark-report:grid:60",
            "benchmark-report:bar:image:b",
            "benchmark-report:table:image:4",
        ],
        initiallyHidden: ["benchmark-report:table:image:4"],
    },
    {
        file: "threaded-workflow.lua", root: "threaded-workflow:root",
        required: [
            "threaded-workflow:lifeline:runtime",
            "threaded-workflow:queue",
            "threaded-workflow:dispatch:three",
            "threaded-workflow:completion",
        ],
        initiallyHidden: ["threaded-workflow:message:sync:label"],
    },
].map((template) => ({
    ...template,
    source: fs.readFileSync(path.join(diagramTemplatesRoot, template.file), "utf8"),
}));
const nativeDiagram = diagramTemplates[0].source;

const runtime = await createTMath("return tmath.scene {width = 8, height = 8}", "bootstrap.lua", {
    wasmBinary,
});

try {
    runtime.font("Pretendard", font, "ttf");
    runtime.loadLua(`
local scene = tmath.scene {
    width = 320, height = 180, theme = "pro_white",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 10},
}

local diagram = tmath.diagram(scene, {
    id = "wasm-diagram", direction = "lr", origin = {-3.2, 2.2},
    node_size = {2, 0.8}, rank_gap = 1,
})
local input = diagram:node {id = "input", label = "Input"}
local output = diagram:node {id = "output", label = "Output"}
local edge = diagram:connect {id = "flow", from = input, to = output, flow = true}
local built_diagram = diagram:build()
built_diagram:node_body(input):label {
    text = "child", point = {-3.2, 2.2}, size = 12,
    role = "text", fill = "focus", id = "wasm-object-label",
}

local chart = tmath.chart(scene, {
    id = "wasm-chart", frame = {center = {0, -2}, size = {7.5, 3}},
    x = {0, 2}, y = {0, 4}, x_ticks = 3, y_ticks = 3,
    ticks = false, legend = false, padding = 0.35, line_width = 0.07, bar_gap = 0.08,
})
local line = chart:series {
    id = "line", mark = "line", data = {{0, 1}, {1, 3}, {2, 2}},
}
local bars = chart:series {
    id = "bars", mark = "bar", data = {{0.4, 1}, {1.2, 2.5}, {1.8, 3.5}},
}
local built_chart = chart:build()

scene:play({target = built_diagram:edge(edge), dash_offset = -9}, 0.4, "linear")
scene:create(built_chart:series(line), 0.3, "ease_out")
for index = 1, built_chart:mark_count(bars) do
    scene:grow_from_edge(built_chart:mark(bars, index), "bottom", 0.3, "linear")
end
return scene
`, "runtime-authoring-modules.lua");

    assert.ok(runtime.duration > 0);
    const growingBar = runtime.bounds("wasm-chart/series/bars/0", 0.85);
    const settledBar = runtime.bounds("wasm-chart/series/bars/0", 1.0);
    assert.ok(growingBar.height > 0 && growingBar.height < settledBar.height);
    assert.ok(Math.abs(
        growingBar.y + growingBar.height - settledBar.y - settledBar.height,
    ) <= 2);
    const settled = runtime.duration;
    assert.ok(runtime.bounds("wasm-diagram:root", settled).width > 0);
    assert.ok(runtime.bounds("wasm-diagram:edge:flow", settled).width > 0);
    assert.ok(runtime.bounds("wasm-object-label", settled).width > 0);
    assert.ok(runtime.bounds("wasm-chart/series/line", settled).width > 0);
    assert.ok(runtime.bounds("wasm-chart/series/bars/2", settled).height > 0);
    const pixels = runtime.render(settled, true);
    assert.equal(pixels.length, 320 * 180 * 4);
    assert.ok(pixels.some((value, index) => index % 4 !== 3 && value !== 255));
    for (const template of diagramTemplates) {
        runtime.loadLua(template.source, `diagram-template-${template.file}`);
        const templateTime = runtime.duration;
        assert.ok(
            runtime.bounds(template.root, templateTime).width > 0,
            `${template.file} should expose its semantic root`,
        );
        for (const objectId of template.required ?? []) {
            const bounds = runtime.bounds(objectId, templateTime);
            assert.ok(
                bounds.width > 0 && bounds.height > 0,
                `${template.file} should retain required grammar object ${objectId}`,
            );
        }
        for (const objectId of template.initiallyHidden ?? []) {
            assert.throws(
                () => runtime.bounds(objectId, 0),
                /InsufficientCondition/,
                `${template.file} should not reveal ${objectId} before its evidence mark`,
            );
            assert.ok(
                runtime.bounds(objectId, templateTime).width > 0,
                `${template.file} should reveal ${objectId} by the settled frame`,
            );
        }
        assert.equal(
            runtime.render(templateTime, true).length,
            960 * 540 * 4,
            `${template.file} should render a complete 960x540 frame`,
        );
    }
    for (let index = 0; index < 256; index += 1) {
        runtime.loadLua(nativeDiagram, `native-diagram-reload-${index}.lua`);
    }
} finally {
    runtime.destroy();
}

const definition = tmath.scene({
    width: 160,
    height: 90,
    camera: {mode: "fixed", view: "2d", target: [0, 0], height: 4},
});
const subject = definition.rectangle({center: [0, 0], size: [2, 1], id: "js-label-parent"});
subject.label({
    text: "Object label",
    point: [0, 0],
    size: 14,
    role: "text",
    fill: "focus",
    id: "js-object-label",
});
const jsRuntime = await createTMath(definition, "runtime-object-label.js", {wasmBinary});
try {
    jsRuntime.font("Pretendard", font, "ttf");
    assert.ok(jsRuntime.bounds("js-label-parent", 0).width > 0);
    assert.ok(jsRuntime.bounds("js-object-label", 0).width > 0);
} finally {
    jsRuntime.destroy();
}

console.log("runtime authoring modules, diagram family templates, edge growth, and Object labels passed");
