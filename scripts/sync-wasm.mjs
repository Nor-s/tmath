// Copy a WASM build plus the JS bindings into bundle directories and refresh
// each BUILD-MANIFEST.json (artifact sizes/hashes, source commit, build date).
// Usage: node scripts/sync-wasm.mjs <build-dir> <bundle-dir>...
import {execFileSync} from "node:child_process";
import {createHash} from "node:crypto";
import {copyFileSync, existsSync, readFileSync, writeFileSync} from "node:fs";
import {dirname, join, resolve} from "node:path";
import {fileURLToPath} from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const [build, ...bundles] = process.argv.slice(2);
if (!build || bundles.length === 0) {
    console.error("usage: node scripts/sync-wasm.mjs <build-dir> <bundle-dir>...");
    process.exit(2);
}

const sources = {
    "tmath-wasm.js": join(build, "tmath-wasm.js"),
    "tmath-wasm.wasm": join(build, "tmath-wasm.wasm"),
    "client.js": join(root, "src/bindings/js/client.js"),
    "client.d.ts": join(root, "src/bindings/js/client.d.ts"),
    "bindings.js": join(root, "src/bindings/js/bindings.js"),
    "bindings.d.ts": join(root, "src/bindings/js/bindings.d.ts"),
};
for (const [name, path] of Object.entries(sources)) {
    if (!existsSync(path)) throw new Error(`missing ${name}: ${path}`);
}

const git = (...args) => execFileSync("git", ["-C", root, ...args], {encoding: "utf8"}).trim();
const commit = git("rev-parse", "--short=12", "HEAD");
const dirty = git("status", "--porcelain").length > 0;

for (const bundle of bundles) {
    for (const [name, path] of Object.entries(sources)) copyFileSync(path, join(bundle, name));

    const manifestPath = join(bundle, "BUILD-MANIFEST.json");
    const manifest = JSON.parse(readFileSync(manifestPath, "utf8"));
    manifest.sourceCommit = commit;
    manifest.sourceDirty = dirty;
    manifest.buildDate = new Date().toISOString().slice(0, 10);
    manifest.artifacts = manifest.artifacts.map(({path}) => {
        const bytes = readFileSync(join(bundle, path));
        return {path, bytes: bytes.length, sha256: createHash("sha256").update(bytes).digest("hex")};
    });
    writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);
    console.log(`synced ${bundle}`);
}
