const GIF_MODULE = "https://unpkg.com/gifenc@1.0.3";
const MP4_MODULE = "https://esm.sh/mediabunny@1.55.1";
const FRAME_LIMIT = 3600;
const PIXEL_LIMIT = 8294400;
const PIXEL_SAMPLE_LIMIT = 268435456;

function _active(signal) {
    if (signal?.aborted) throw signal.reason || new DOMException("Operation aborted", "AbortError");
}

function _plan(scene, fps) {
    if (!Number.isInteger(fps) || fps < 1 || fps > 60)
        throw new Error("FPS must be an integer from 1 to 60");
    const [width, height] = scene.size();
    const duration = scene.duration;
    const samples = duration * fps;
    const integer = Math.round(samples);
    const snapped = Math.abs(samples - integer) <= Math.max(1, samples) * 1e-6 ? integer : samples;
    const frames = Math.max(1, Math.ceil(snapped));
    if (
        width * height > PIXEL_LIMIT ||
        frames > FRAME_LIMIT ||
        width * height * frames > PIXEL_SAMPLE_LIMIT
    ) {
        throw new Error(
            "Export is limited to 3840×2160, 3600 frames, and 268 million sampled pixels",
        );
    }
    return { width, height, duration, fps, frames };
}

function _download(data, type, name) {
    const url = URL.createObjectURL(new Blob([data], { type }));
    const link = document.createElement("a");
    link.href = url;
    link.download = name;
    link.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
}

function _frameTime(plan, frame) {
    return Math.min(frame / plan.fps, plan.duration);
}

function _gifDelay(frame, fps) {
    const begin = Math.round((frame * 100) / fps);
    const end = Math.round(((frame + 1) * 100) / fps);
    return Math.max(1, end - begin) * 10;
}

async function _yield(signal) {
    _active(signal);
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
        signal?.addEventListener("abort", abort, { once: true });
    });
    _active(signal);
}

export async function saveGif(scene, fps, progress = () => {}, signal = null) {
    _active(signal);
    const plan = _plan(scene, fps);
    const { GIFEncoder, quantize, applyPalette } = await import(GIF_MODULE);
    _active(signal);
    const gif = GIFEncoder();
    for (let frame = 0; frame < plan.frames; frame++) {
        _active(signal);
        const pixels = scene.render(_frameTime(plan, frame), true);
        const palette = quantize(pixels, 256);
        const index = applyPalette(pixels, palette);
        gif.writeFrame(index, plan.width, plan.height, {
            palette,
            delay: _gifDelay(frame, plan.fps),
            repeat: 0,
        });
        progress(frame + 1, plan.frames);
        if ((frame & 1) === 1) await _yield(signal);
    }
    gif.finish();
    _active(signal);
    _download(gif.bytes(), "image/gif", "tmath-scene.gif");
}

export async function saveLottie(scene, fps, progress = () => {}, signal = null) {
    _active(signal);
    progress(0, 1);
    await _yield(signal);
    const data = scene.lottie(fps);
    _active(signal);
    progress(1, 1);
    _download(data, "application/json", "tmath-scene.json");
}

export async function saveMp4(scene, fps, progress = () => {}, signal = null) {
    _active(signal);
    const plan = _plan(scene, fps);
    const { BufferTarget, CanvasSource, Mp4OutputFormat, Output, Quality } = await import(
        MP4_MODULE
    );
    _active(signal);
    const canvas = document.createElement("canvas");
    canvas.width = plan.width;
    canvas.height = plan.height;
    const target = new BufferTarget();
    const output = new Output({ format: new Mp4OutputFormat(), target });
    const source = new CanvasSource(canvas, { codec: "avc", quality: new Quality("high") });
    output.addVideoTrack(source, { frameRate: plan.fps });
    try {
        await output.start();
        _active(signal);
        for (let frame = 0; frame < plan.frames; frame++) {
            _active(signal);
            scene.draw(canvas, _frameTime(plan, frame));
            await source.add(frame / plan.fps, 1 / plan.fps, {
                keyFrame: frame % (plan.fps * 2) === 0,
            });
            _active(signal);
            progress(frame + 1, plan.frames);
            if ((frame & 3) === 3) await _yield(signal);
        }
        source.close();
        await output.finalize();
        _active(signal);
    } catch (error) {
        if (output.state === "started" || output.state === "finalizing")
            await output.cancel().catch(() => {});
        throw error;
    }
    _active(signal);
    _download(target.buffer, "video/mp4", "tmath-scene.mp4");
}
