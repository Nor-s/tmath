import assert from "node:assert/strict";
import {mkdtempSync, readFileSync, rmSync} from "node:fs";
import {tmpdir} from "node:os";
import {join} from "node:path";
import {spawnSync} from "node:child_process";

const [cli, scene, font] = process.argv.slice(2);
assert(cli && scene && font);

const directory = mkdtempSync(join(tmpdir(), "tmath-lottie-"));
const output = join(directory, "scene.json");

try {
    const run = spawnSync(cli, [
        "render", scene, "--font", font, "--fps", "2", "-o", output,
    ], {encoding: "utf8"});
    assert.equal(run.status, 0, run.stderr);

    const source = readFileSync(output, "utf8");
    const lottie = JSON.parse(source);
    assert.equal(lottie.v, "5.7.4");
    assert.equal(lottie.fr, 2);
    assert.equal(lottie.ip, 0);
    assert(lottie.op > lottie.ip);
    assert(lottie.w > 0 && lottie.h > 0);
    assert(Array.isArray(lottie.assets));
    assert(Array.isArray(lottie.layers) && lottie.layers.length > 0);

    const indices = new Set();
    let shapeLayers = 0;
    let textLayers = 0;
    let maskedLayers = 0;
    let paths = 0;
    let gradientFills = 0;
    let gradientStrokes = 0;
    for (const layer of lottie.layers) {
        assert(!indices.has(layer.ind));
        indices.add(layer.ind);
        assert.equal(layer.op, layer.ip + 1);
        assert.equal(layer.st, layer.ip);
        assert(layer.ip >= lottie.ip && layer.op <= lottie.op);
        assert.equal(layer.ks.o.a, 0);
        if (layer.hasMask) {
            maskedLayers++;
            assert.equal(layer.masksProperties[0].mode, "a");
        }
        if (layer.ty === 4) {
            shapeLayers++;
            for (const group of layer.shapes) {
                for (const item of group.it) {
                    if (item.ty === "sh") {
                        paths++;
                        const path = item.ks.k;
                        assert.equal(path.i.length, path.v.length);
                        assert.equal(path.o.length, path.v.length);
                        assert(path.v.every(point => point.every(Number.isFinite)));
                    } else if (item.ty === "gf" || item.ty === "gs") {
                        assert.equal(item.t, 1);
                        assert.equal(item.g.p, 2);
                        assert.equal(item.g.k.a, 0);
                        assert.equal(item.g.k.k.length, 8);
                        assert(item.g.k.k.every(Number.isFinite));
                        assert.equal(item.s.a, 0);
                        assert.equal(item.e.a, 0);
                        assert(item.s.k.every(Number.isFinite));
                        assert(item.e.k.every(Number.isFinite));
                        if (item.ty === "gf") gradientFills++;
                        else gradientStrokes++;
                    }
                }
            }
        } else if (layer.ty === 5) {
            textLayers++;
            const document = layer.t.d.k[0].s;
            assert.equal(typeof document.t, "string");
            assert(document.t.length > 0);
            assert(document.s > 0);
        } else {
            assert.fail(`unexpected layer type ${layer.ty}`);
        }
    }
    assert(shapeLayers > 0);
    assert(textLayers > 0);
    assert(maskedLayers > 0);
    assert(paths > 0);
    assert(gradientFills > 0);
    assert(gradientStrokes > 0);
} finally {
    rmSync(directory, {recursive: true, force: true});
}
