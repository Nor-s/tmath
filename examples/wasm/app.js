import {
    basicSetup,
    EditorView,
} from "https://esm.sh/codemirror@6.0.2?deps=@codemirror/language@6.12.4";
import { StreamLanguage } from "https://esm.sh/@codemirror/language@6.12.4";
import { javascript } from "https://esm.sh/@codemirror/lang-javascript@6.2.4";
import { lua } from "https://esm.sh/@codemirror/legacy-modes@6.5.3/mode/lua?deps=@codemirror/language@6.12.4";

import { API } from "./api.js";
import { createTMath, evaluateScene } from "./client.js";
import { EXAMPLES } from "./catalog.js";
import { saveGif, saveLottie, saveMp4 } from "./savers.js";
import { advanceTimeline, resetTimelineClock } from "./timeline.js";

const $ = (selector) => document.querySelector(selector);
const canvas = $("#preview");
const errorBox = $("#error");
const fps = $("#fps");
const play = $("#play");
const loop = $("#loop");
const scrub = $("#scrub");
const status = $("#status");
const statusText = status.querySelector("span");
const time = $("#time");
const size = $("#size");
const sourceName = $("#source-name");
const editorPanel = $(".editor-panel");
const exampleList = $("#example-list");
const exampleCount = $("#example-count");
const exampleSearch = $("#example-search");
const exampleTitle = $("#example-title");
const exampleDescription = $("#example-description");
const apiList = $("#api-list");
const apiCount = $("#api-count");
const apiSearch = $("#api-search");
const apiGroup = $("#api-group");
const apiName = $("#api-name");
const apiSummary = $("#api-summary");
const apiSignature = $("#api-signature");
const apiLua = $("#api-lua");
const apiMeta = $("#api-meta");
const luaPrototype = $("#lua-prototype");
const playgroundView = $("#playground-view");
const apiView = $("#api-view");
const modeButtons = [...document.querySelectorAll("[data-mode]")];
const viewButtons = [...document.querySelectorAll(".primary-nav [data-view]")];
const exportButtons = [...document.querySelectorAll("[data-export]")];
const cameraButtons = [...document.querySelectorAll("[data-camera]")];
const cameraMode = $("#camera-mode");

let scene = null;
let editor = null;
let mode = "lua";
let view = "playground";
let selectedExample = EXAMPLES[0];
let selectedApi = API[0];
const drafts = Object.fromEntries(
    EXAMPLES.map((example) => [example.id, { lua: example.lua, js: example.js }]),
);
const initialFrame = performance.now();
const timeline = { current: 0, previousFrame: initialFrame, previousDraw: initialFrame };
let playing = true;
let looping = false;
let busy = false;
let dirty = false;
let reloadTimer = 0;
let reloadGeneration = 0;
let animationFrame = 0;
let disposed = false;
let pointer = null;
const lifecycle = new AbortController();
const registeredAssets = new Set();
const registeredFonts = new Set();
const BOOTSTRAP_SCENE = "return tmath.scene {width = 1, height = 1}";
const EXAMPLE_SECTIONS = [
    {
        id: "tmath",
        label: "tmath",
        categories: ["tmath", "Animation", "Basics", "Typography", "Coordinates"],
    },
    { id: "cheatsheets", label: "Cheatsheets", categories: ["Cheatsheets"] },
    { id: "manim-community", label: "MANIM Community", categories: ["MANIM Community"] },
    { id: "diagram", label: "Diagram", categories: ["Diagram"] },
    {
        id: "basic-math",
        label: "Basic Math",
        categories: [
            "Linear algebra",
            "Vectors",
            "Trigonometry",
            "Calculus",
            "Curves",
            "Graphs",
            "Geometry",
        ],
    },
    {
        id: "computer-science",
        label: "Computer Science",
        categories: [
            "Data structures",
            "Data structure",
            "Algorithms",
            "Algorithm",
            "Sorting",
            "Data structures / Algorithms",
        ],
    },
    {
        id: "computer-graphics",
        label: "Computer Graphics",
        categories: [
            "Computer graphics",
            "Rendering",
            "Conic",
            "ThorVG SW",
            "Color Space",
            "Kinematics",
            "Image processing",
        ],
    },
];
const FALLBACK_EXAMPLE_SECTION = { id: "more-examples", label: "More", categories: [] };
const sectionByCategory = new Map(
    EXAMPLE_SECTIONS.flatMap((section) => {
        return section.categories.map((category) => [category.toLowerCase(), section]);
    }),
);
const openExampleSections = new Set();

function sectionForExample(example) {
    return sectionByCategory.get(example.category.toLowerCase()) || FALLBACK_EXAMPLE_SECTION;
}

openExampleSections.add(sectionForExample(selectedExample).id);

function state(label, value = "ready") {
    status.dataset.state = value;
    statusText.textContent = label;
}

function message(value = "") {
    errorBox.textContent = value;
    errorBox.hidden = !value;
}

function clock() {
    const duration = scene ? scene.duration : 0;
    time.textContent = `${timeline.current.toFixed(2)} / ${duration.toFixed(2)} s`;
    scrub.max = Math.max(duration, 0.001);
    scrub.value = Math.min(timeline.current, duration);
}

function syncPlaybackControls() {
    play.textContent = playing ? "PAUSE" : "PLAY";
    play.setAttribute("aria-pressed", String(playing));
    loop.textContent = looping ? "LOOP ON" : "LOOP OFF";
    loop.setAttribute("aria-pressed", String(looping));
}

function draw() {
    if (!scene) return;
    scene.draw(canvas, Math.min(timeline.current, scene.duration));
    const [width, height] = scene.size();
    size.textContent = `${width} × ${height}`;
    syncCamera();
    clock();
}

function syncCamera() {
    if (!scene) return;
    cameraMode.textContent = scene.cameraMode.toUpperCase();
    cameraMode.dataset.mode = scene.cameraMode;
    canvas.dataset.cameraMode = scene.cameraMode;
    for (const button of cameraButtons) {
        button.disabled = scene.cameraMode !== "interactive";
        if (button.dataset.camera === "view2d")
            button.setAttribute("aria-pressed", String(scene.cameraView === "2d"));
        if (button.dataset.camera === "view3d")
            button.setAttribute("aria-pressed", String(scene.cameraView === "3d"));
    }
}

function moveCamera(action, x = 0, y = 0) {
    if (!scene || busy) return false;
    if (!scene.camera(action, x, y)) {
        state("FIXED CAMERA", "ready");
        return false;
    }
    message();
    state(`${scene.cameraView.toUpperCase()} VIEW`, "ready");
    draw();
    return true;
}

function saveEditor() {
    if (editor) drafts[selectedExample.id][mode] = editor.state.doc.toString();
}

async function prepareAssets(example, runtime, current) {
    for (const font of example.fonts || []) {
        if (registeredFonts.has(font.name)) continue;
        const response = await fetch(font.url, { signal: lifecycle.signal });
        if (!current()) return false;
        if (!response.ok) throw new Error(`Font fetch failed: ${font.url} (${response.status})`);
        const data = await response.arrayBuffer();
        if (!current()) return false;
        runtime.font(font.name, data, font.mime || "ttf");
        registeredFonts.add(font.name);
    }
    for (const asset of example.assets || []) {
        if (registeredAssets.has(asset.name)) continue;
        const response = await fetch(asset.url, { signal: lifecycle.signal });
        if (!current()) return false;
        if (!response.ok) throw new Error(`Asset fetch failed: ${asset.url} (${response.status})`);
        const data = await response.arrayBuffer();
        if (!current()) return false;
        runtime.asset(asset.name, data, asset.mime);
        registeredAssets.add(asset.name);
    }
    return true;
}

async function loadExampleSource(example, runtime, language, source, current) {
    if (!(await prepareAssets(example, runtime, current)) || !current()) return false;
    const name = `${example.id}.${language}`;
    if (language === "lua") runtime.loadLua(source, name);
    else runtime.loadScene(evaluateScene(source, name), name);
    return true;
}

async function reload() {
    if (disposed) return;
    if (!scene || busy) {
        dirty = true;
        return;
    }
    const generation = ++reloadGeneration;
    const runtime = scene;
    const example = selectedExample;
    const language = mode;
    const source = editor.state.doc.toString();
    const oldDuration = runtime.duration;
    const phase = oldDuration > 0 ? timeline.current / oldDuration : 0;
    const current = () => !disposed && generation === reloadGeneration && runtime === scene;
    try {
        if (!(await loadExampleSource(example, runtime, language, source, current))) return;
        timeline.current = Math.min(runtime.duration, runtime.duration * phase);
        looping = runtime.loop;
        syncPlaybackControls();
        dirty = false;
        message();
        state("LIVE", "ready");
        draw();
        resetTimelineClock(timeline, performance.now());
    } catch (error) {
        if (!current()) return;
        message(error.message);
        state(`${language.toUpperCase()} ERROR`, "error");
    }
}

function scheduleReload() {
    if (disposed) return;
    reloadGeneration++;
    clearTimeout(reloadTimer);
    reloadTimer = setTimeout(() => void reload(), 420);
    state("EDITING", "loading");
}

function mountEditor() {
    editor?.destroy();
    editor = new EditorView({
        doc: drafts[selectedExample.id][mode],
        extensions: [
            basicSetup,
            mode === "lua" ? StreamLanguage.define(lua) : javascript(),
            EditorView.lineWrapping,
            EditorView.updateListener.of((update) => {
                if (!update.docChanged) return;
                drafts[selectedExample.id][mode] = update.state.doc.toString();
                scheduleReload();
            }),
            EditorView.theme(
                {
                    "&": { height: "100%", background: "#090c0f", color: "#d9e1e8" },
                    ".cm-content": { padding: "18px 0", caretColor: "#ffd166" },
                    ".cm-gutters": { background: "#090c0f", color: "#55616d", border: "0" },
                    ".cm-activeLine, .cm-activeLineGutter": { background: "#14191e" },
                    ".cm-selectionBackground, ::selection": { background: "#29404a !important" },
                    ".cm-cursor": { borderLeftColor: "#ffd166" },
                },
                { dark: true },
            ),
        ],
        parent: $("#editor"),
    });
}

function syncExample() {
    sourceName.textContent = `${selectedExample.id}.${mode}`.toUpperCase();
    exampleTitle.textContent = selectedExample.title;
    exampleDescription.textContent = selectedExample.description;
    editorPanel.setAttribute("aria-label", `${mode === "lua" ? "Lua" : "JavaScript"} code editor`);
    for (const button of modeButtons)
        button.setAttribute("aria-pressed", String(button.dataset.mode === mode));
}

function selectMode(next) {
    if (next === mode || busy) return;
    saveEditor();
    mode = next;
    syncExample();
    mountEditor();
    editor.focus();
    scheduleReload();
}

function renderExamples() {
    const query = exampleSearch.value.trim().toLowerCase();
    const matches = EXAMPLES.filter((example) => {
        const section = sectionForExample(example);
        return `${example.title} ${example.description} ${example.category} ${example.dimension} ${section.label} ${section.categories.join(" ")}`
            .toLowerCase()
            .includes(query);
    });
    exampleCount.textContent = matches.length;
    exampleList.replaceChildren();
    if (!matches.length) {
        const empty = document.createElement("p");
        empty.className = "empty-list";
        empty.textContent = "NO MATCHING SCENES";
        exampleList.append(empty);
        return;
    }

    const sectionGroups = new Map();
    for (const example of matches) {
        const section = sectionForExample(example);
        if (!sectionGroups.has(section)) sectionGroups.set(section, []);
        sectionGroups.get(section).push(example);
    }

    const orderedSections = [...EXAMPLE_SECTIONS, FALLBACK_EXAMPLE_SECTION];
    for (const section of orderedSections) {
        const examples = sectionGroups.get(section);
        if (!examples) continue;

        const details = document.createElement("details");
        details.className = "example-section";
        details.dataset.section = section.id;
        details.open = Boolean(query) || openExampleSections.has(section.id);
        const summary = document.createElement("summary");
        const label = document.createElement("strong");
        label.textContent = section.label;
        const toggle = document.createElement("span");
        toggle.className = "example-section-toggle";
        toggle.setAttribute("aria-hidden", "true");
        summary.append(label, toggle);
        details.append(summary);

        const body = document.createElement("div");
        body.className = "example-section-body";
        for (const example of examples) {
            const button = document.createElement("button");
            button.type = "button";
            button.className = "example-card";
            button.dataset.id = example.id;
            button.setAttribute("aria-pressed", String(example === selectedExample));
            const title = document.createElement("strong");
            title.textContent = example.title;
            button.append(title);
            button.addEventListener("click", () => selectExample(example));
            body.append(button);
        }
        details.append(body);
        summary.addEventListener("click", () => {
            if (details.open) openExampleSections.delete(section.id);
            else openExampleSections.add(section.id);
        });
        exampleList.append(details);
    }
}

function selectExample(example) {
    if (example === selectedExample || busy) return;
    saveEditor();
    selectedExample = example;
    openExampleSections.add(sectionForExample(example).id);
    timeline.current = 0;
    playing = true;
    syncPlaybackControls();
    syncExample();
    renderExamples();
    mountEditor();
    editor.focus();
    void reload();
}

function selectApi(entry) {
    selectedApi = entry;
    apiGroup.textContent = entry.group.toUpperCase();
    apiName.textContent = entry.name;
    apiSummary.textContent = entry.summary;
    apiSignature.textContent = entry.signature;
    apiLua.textContent = entry.lua;
    luaPrototype.hidden = entry.lua === "—";
    apiMeta.replaceChildren();
    const fields = [
        ["RETURNS", entry.returns || "void"],
        ["GROUP", entry.group],
    ];
    for (const [label, value] of fields) {
        const term = document.createElement("dt");
        const detail = document.createElement("dd");
        term.textContent = label;
        detail.textContent = value;
        apiMeta.append(term, detail);
    }
    for (const button of apiList.querySelectorAll(".api-item")) {
        button.setAttribute("aria-pressed", String(button.dataset.name === entry.name));
    }
}

function renderApi() {
    const query = apiSearch.value.trim().toLowerCase();
    const matches = API.filter((entry) => {
        return `${entry.name} ${entry.signature} ${entry.lua} ${entry.summary} ${entry.group}`
            .toLowerCase()
            .includes(query);
    });
    apiCount.textContent = matches.length;
    apiList.replaceChildren();
    const groups = new Map();
    for (const entry of matches) {
        if (!groups.has(entry.group)) groups.set(entry.group, []);
        groups.get(entry.group).push(entry);
    }
    for (const [group, entries] of groups) {
        const section = document.createElement("section");
        section.className = "api-list-group";
        const title = document.createElement("h2");
        title.textContent = group;
        section.append(title);
        for (const entry of entries) {
            const button = document.createElement("button");
            button.type = "button";
            button.className = "api-item";
            button.dataset.name = entry.name;
            button.textContent = entry.name;
            button.setAttribute("aria-pressed", String(entry === selectedApi));
            button.addEventListener("click", () => selectApi(entry));
            section.append(button);
        }
        apiList.append(section);
    }
    if (!matches.length) {
        const empty = document.createElement("p");
        empty.className = "empty-list";
        empty.textContent = "NO MATCHING API";
        apiList.append(empty);
    } else if (!matches.includes(selectedApi)) {
        selectApi(matches[0]);
    }
}

function selectView(next) {
    if (next === view) return;
    view = next;
    document.body.dataset.view = view;
    playgroundView.hidden = view !== "playground";
    apiView.hidden = view !== "api";
    for (const button of viewButtons)
        button.setAttribute("aria-pressed", String(button.dataset.view === view));
    if (view === "playground") {
        draw();
        resetTimelineClock(timeline, performance.now());
    } else {
        apiSearch.focus();
    }
}

async function boot() {
    let runtime = null;
    try {
        runtime = await createTMath(BOOTSTRAP_SCENE, "bootstrap.lua");
        if (disposed) {
            runtime.destroy();
            return;
        }

        const example = selectedExample;
        const language = mode;
        if (
            !(await loadExampleSource(
                example,
                runtime,
                language,
                drafts[example.id][language],
                () => !disposed,
            ))
        ) {
            runtime.destroy();
            return;
        }

        scene = runtime;
        looping = runtime.loop;
        syncPlaybackControls();
        state("LIVE", "ready");
        draw();
        runtime = null;
        if (dirty) scheduleReload();
        resetTimelineClock(timeline, performance.now());
        animationFrame = requestAnimationFrame(frame);
    } catch (error) {
        if (runtime) {
            if (scene === runtime) scene = null;
            runtime.destroy();
        }
        if (disposed) return;
        message(error.message);
        state("BOOT ERROR", "error");
    }
}

function frame(now) {
    if (disposed) return;
    const active = view === "playground" && scene && playing && !busy;
    if (advanceTimeline(timeline, now, scene?.duration || 0, active, 30, looping)) {
        draw();
    }
    if (active && !looping && scene.duration > 0 && timeline.current >= scene.duration) {
        playing = false;
        syncPlaybackControls();
    }
    animationFrame = requestAnimationFrame(frame);
}

for (const button of modeButtons)
    button.addEventListener("click", () => selectMode(button.dataset.mode));
for (const button of viewButtons)
    button.addEventListener("click", () => selectView(button.dataset.view));
exampleSearch.addEventListener("input", renderExamples);
apiSearch.addEventListener("input", renderApi);

$("#reset").addEventListener("click", () => {
    if (busy) return;
    drafts[selectedExample.id][mode] = selectedExample[mode];
    mountEditor();
    editor.focus();
    timeline.current = 0;
    playing = true;
    syncPlaybackControls();
    void reload();
});

$("#copy-api").addEventListener("click", async (event) => {
    try {
        await navigator.clipboard.writeText(selectedApi.signature);
        event.currentTarget.textContent = "COPIED";
        setTimeout(() => (event.currentTarget.textContent = "COPY PROTOTYPE"), 900);
    } catch {
        event.currentTarget.textContent = "COPY FAILED";
    }
});

play.addEventListener("click", () => {
    if (!playing && !looping && scene && timeline.current >= scene.duration) {
        timeline.current = 0;
        draw();
    }
    playing = !playing;
    if (playing) resetTimelineClock(timeline, performance.now());
    syncPlaybackControls();
});

loop.addEventListener("click", () => {
    looping = !looping;
    if (looping && !playing && scene && timeline.current >= scene.duration) {
        timeline.current = 0;
        playing = true;
        resetTimelineClock(timeline, performance.now());
        draw();
    }
    syncPlaybackControls();
});

scrub.addEventListener("input", () => {
    timeline.current = Number(scrub.value);
    draw();
});

for (const button of exportButtons) {
    button.addEventListener("click", async () => {
        if (!scene || busy) return;
        const runtime = scene;
        busy = true;
        const resume = playing;
        playing = false;
        exportButtons.forEach((item) => (item.disabled = true));
        const format = button.dataset.export.toUpperCase();
        try {
            const saver = format === "GIF" ? saveGif : format === "LOTTIE" ? saveLottie : saveMp4;
            await saver(
                runtime,
                Number(fps.value),
                (done, total) => {
                    if (!disposed && runtime === scene)
                        state(`${format} ${done}/${total}`, "loading");
                },
                lifecycle.signal,
            );
            if (disposed || runtime !== scene) return;
            message();
            state(`${format} SAVED`, "ready");
        } catch (error) {
            if (disposed || runtime !== scene) return;
            message(error.message);
            state(`${format} ERROR`, "error");
        } finally {
            if (!disposed && runtime === scene) {
                busy = false;
                playing = resume;
                exportButtons.forEach((item) => (item.disabled = false));
                draw();
                if (dirty) scheduleReload();
                resetTimelineClock(timeline, performance.now());
            }
        }
    });
}

for (const button of cameraButtons) {
    button.addEventListener("click", () => moveCamera(button.dataset.camera));
}

canvas.addEventListener("contextmenu", (event) => event.preventDefault());
canvas.addEventListener("pointerdown", (event) => {
    if (!scene || scene.cameraMode !== "interactive") return;
    pointer = {
        id: event.pointerId,
        x: event.clientX,
        y: event.clientY,
        pan: event.button === 2 || event.shiftKey,
    };
    canvas.setPointerCapture(event.pointerId);
    canvas.dataset.dragging = "true";
    event.preventDefault();
});
canvas.addEventListener("pointermove", (event) => {
    if (!pointer || pointer.id !== event.pointerId) return;
    const bounds = canvas.getBoundingClientRect();
    const dx = (event.clientX - pointer.x) / Math.max(bounds.width, 1);
    const dy = (event.clientY - pointer.y) / Math.max(bounds.height, 1);
    pointer.x = event.clientX;
    pointer.y = event.clientY;
    const action = scene.cameraView === "3d" && !pointer.pan ? "orbit" : "pan";
    moveCamera(action, dx, dy);
});
const endPointer = (event) => {
    if (!pointer || pointer.id !== event.pointerId) return;
    pointer = null;
    canvas.dataset.dragging = "false";
};
canvas.addEventListener("pointerup", endPointer);
canvas.addEventListener("pointercancel", endPointer);
canvas.addEventListener(
    "wheel",
    (event) => {
        if (!scene || scene.cameraMode !== "interactive") return;
        event.preventDefault();
        moveCamera("zoom", 0, Math.max(-1, Math.min(1, event.deltaY * 0.0015)));
    },
    { passive: false },
);

window.addEventListener("keydown", (event) => {
    if (view !== "playground" || !scene || scene.cameraMode !== "interactive") return;
    if (
        event.target instanceof HTMLInputElement ||
        event.target instanceof HTMLSelectElement ||
        event.target.closest(".cm-editor")
    )
        return;
    const actions = {
        ArrowLeft: ["pan", 0.04, 0],
        ArrowRight: ["pan", -0.04, 0],
        ArrowUp: ["pan", 0, -0.04],
        ArrowDown: ["pan", 0, 0.04],
        "+": ["zoom", 0, -0.12],
        "=": ["zoom", 0, -0.12],
        "-": ["zoom", 0, 0.12],
        2: ["view2d", 0, 0],
        3: ["view3d", 0, 0],
        r: ["reset", 0, 0],
        R: ["reset", 0, 0],
    };
    const command = actions[event.key];
    if (!command) return;
    event.preventDefault();
    moveCamera(...command);
});

window.addEventListener("beforeunload", () => {
    disposed = true;
    lifecycle.abort();
    cancelAnimationFrame(animationFrame);
    clearTimeout(reloadTimer);
    reloadGeneration++;
    const runtime = scene;
    scene = null;
    runtime?.destroy();
});
renderExamples();
renderApi();
selectApi(selectedApi);
syncExample();
mountEditor();
boot();
