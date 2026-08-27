import assert from "node:assert/strict";
import {thumbnailFrameTime, thumbnailPlan} from "../webview/thumbnail-plan.mjs";

const animated = thumbnailPlan({size: () => [1920, 1080], duration: 10});
assert.deepEqual(animated, {
    sourceWidth: 1920,
    sourceHeight: 1080,
    width: 800,
    height: 450,
    sourceDuration: 10,
    start: 0,
    end: 10,
    rangeDuration: 10,
    playbackDuration: 3,
    frames: 24,
    delay: 130,
});
assert.equal(thumbnailFrameTime(animated, 12), 5);

const range = thumbnailPlan({size: () => [1920, 1080], duration: 10}, {start: 2, end: 4});
assert.equal(range.rangeDuration, 2);
assert.equal(range.playbackDuration, 2);
assert.equal(range.frames, 16);
assert.equal(thumbnailFrameTime(range, 8), 3);

const portrait = thumbnailPlan({size: () => [1080, 1920], duration: 0});
assert.equal(portrait.width, 450);
assert.equal(portrait.height, 800);
assert.equal(portrait.frames, 1);
assert.equal(thumbnailFrameTime(portrait, 0), 0);

const square = thumbnailPlan({size: () => [1200, 1200], duration: 1});
assert.equal(square.width, 800);
assert.equal(square.height, 800);

console.log("hover thumbnail planning passed");
