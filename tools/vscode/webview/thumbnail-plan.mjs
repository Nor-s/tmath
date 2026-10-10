import {playbackBounds} from "../media/playback-range.mjs";

export const THUMBNAIL_MAX_WIDTH = 800;
export const THUMBNAIL_MAX_HEIGHT = 800;
export const THUMBNAIL_MAX_FRAMES = 24;
export const THUMBNAIL_FPS = 8;
export const THUMBNAIL_MAX_DURATION = 3;

export function thumbnailPlan(scene, range = null) {
    const [sourceWidth, sourceHeight] = scene.size();
    const scale = Math.min(1, THUMBNAIL_MAX_WIDTH / sourceWidth, THUMBNAIL_MAX_HEIGHT / sourceHeight);
    const width = Math.max(1, Math.round(sourceWidth * scale));
    const height = Math.max(1, Math.round(sourceHeight * scale));
    const sourceDuration = Math.max(0, Number(scene.duration) || 0);
    const {start, end} = playbackBounds(range, sourceDuration);
    const rangeDuration = end - start;
    const playbackDuration = rangeDuration > 0 ? Math.min(rangeDuration, THUMBNAIL_MAX_DURATION) : 1;
    const frames = rangeDuration > 0
        ? Math.min(THUMBNAIL_MAX_FRAMES, Math.max(1, Math.ceil(playbackDuration * THUMBNAIL_FPS)))
        : 1;
    const delay = Math.max(20, Math.round((playbackDuration * 100) / frames) * 10);
    return {sourceWidth, sourceHeight, width, height, sourceDuration, start, end, rangeDuration, playbackDuration, frames, delay};
}

export function thumbnailFrameTime(plan, frame) {
    if (plan.rangeDuration <= 0 || plan.frames <= 1) return plan.start;
    return plan.start + (plan.rangeDuration * frame) / plan.frames;
}
