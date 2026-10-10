import assert from "node:assert/strict";
import {thumbnailSidecarPath} from "../out/thumbnailPath.js";

assert.equal(
    thumbnailSidecarPath(".vscode/tmath/software-fill/animations/tvggSwFill.function.lua"),
    ".vscode/tmath/software-fill/animations/tvggSwFill.function.gif",
);
assert.equal(thumbnailSidecarPath("animations/scene.LUA"), "animations/scene.gif");
assert.equal(thumbnailSidecarPath("animations/scene"), "animations/scene.gif");

console.log("hover thumbnail sidecar path passed");
