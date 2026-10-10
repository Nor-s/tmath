import {GIFEncoder, applyPalette, quantize} from "gifenc";
import {BufferTarget, CanvasSource, Mp4OutputFormat, Output, Quality} from "mediabunny";
import {exportPlan, frameTime, gifDelay} from "./export-plan.mjs";
import {thumbnailFrameTime, thumbnailPlan} from "./thumbnail-plan.mjs";

function active(signal) {
    if (signal?.aborted) throw signal.reason || new DOMException("Operation aborted", "AbortError");
}

async function yieldFrame(signal) {
    active(signal);
    await new Promise((resolve, reject) => {
        let request = 0;
        const abort = () => {
            cancelAnimationFrame(request);
            reject(signal.reason || new DOMException("Operation aborted", "AbortError"));
        };
        request = requestAnimationFrame(() => {
            signal?.removeEventListener("abort", abort);
            resolve();
        });
        signal?.addEventListener("abort", abort, {once: true});
    });
    active(signal);
}

export async function saveGif(scene, fps, progress = () => {}, signal = null, range = null) {
    active(signal);
    const plan = exportPlan(scene, fps, range);
    const gif = GIFEncoder();
    for (let frame = 0; frame < plan.frames; frame += 1) {
        active(signal);
        const pixels = scene.render(frameTime(plan, frame), true);
        const palette = quantize(pixels, 256);
        const index = applyPalette(pixels, palette);
        gif.writeFrame(index, plan.width, plan.height, {
            palette,
            delay: gifDelay(frame, plan.fps),
            repeat: 0,
        });
        progress(frame + 1, plan.frames);
        if ((frame & 1) === 1) await yieldFrame(signal);
    }
    gif.finish();
    active(signal);
    return gif.bytes();
}

export async function saveThumbnailGif(scene, signal = null, range = null) {
    active(signal);
    const plan = thumbnailPlan(scene, range);
    const sourceCanvas = document.createElement("canvas");
    const targetCanvas = document.createElement("canvas");
    sourceCanvas.width = plan.sourceWidth;
    sourceCanvas.height = plan.sourceHeight;
    targetCanvas.width = plan.width;
    targetCanvas.height = plan.height;
    const sourceContext = sourceCanvas.getContext("2d");
    const targetContext = targetCanvas.getContext("2d", {willReadFrequently: true});
    targetContext.imageSmoothingEnabled = true;
    targetContext.imageSmoothingQuality = "high";

    const gif = GIFEncoder();
    for (let frame = 0; frame < plan.frames; frame += 1) {
        active(signal);
        const sourcePixels = scene.render(thumbnailFrameTime(plan, frame), true);
        sourceContext.putImageData(new ImageData(sourcePixels, plan.sourceWidth, plan.sourceHeight), 0, 0);
        targetContext.clearRect(0, 0, plan.width, plan.height);
        targetContext.drawImage(sourceCanvas, 0, 0, plan.width, plan.height);
        const pixels = targetContext.getImageData(0, 0, plan.width, plan.height).data;
        const palette = quantize(pixels, 256);
        gif.writeFrame(applyPalette(pixels, palette), plan.width, plan.height, {
            palette,
            delay: plan.delay,
            repeat: 0,
        });
        if ((frame & 1) === 1) await yieldFrame(signal);
    }
    gif.finish();
    active(signal);
    return gif.bytes();
}

export async function saveMp4(scene, fps, progress = () => {}, signal = null, range = null) {
    active(signal);
    const plan = exportPlan(scene, fps, range);
    const canvas = document.createElement("canvas");
    canvas.width = plan.width;
    canvas.height = plan.height;
    const target = new BufferTarget();
    const output = new Output({format: new Mp4OutputFormat(), target});
    const source = new CanvasSource(canvas, {codec: "avc", quality: new Quality("high")});
    output.addVideoTrack(source, {frameRate: plan.fps});
    try {
        await output.start();
        active(signal);
        for (let frame = 0; frame < plan.frames; frame += 1) {
            active(signal);
            scene.draw(canvas, frameTime(plan, frame));
            await source.add(frame / plan.fps, 1 / plan.fps, {
                keyFrame: frame % (plan.fps * 2) === 0,
            });
            active(signal);
            progress(frame + 1, plan.frames);
            if ((frame & 3) === 3) await yieldFrame(signal);
        }
        source.close();
        await output.finalize();
        active(signal);
        return target.buffer;
    } catch (error) {
        if (output.state === "started" || output.state === "finalizing") {
            await output.cancel().catch(() => {});
        }
        throw error;
    }
}
