export function resetTimelineClock(state, now) {
    state.previousFrame = now;
    state.previousDraw = now;
}

export function advanceTimeline(state, now, duration, active, fps = 30, loop = false) {
    const delta = Math.min(Math.max((now - state.previousFrame) / 1000, 0), 0.1);
    state.previousFrame = now;
    if (!active) return false;

    const previous = state.current;
    if (duration > 0) {
        state.current = loop
            ? (state.current + delta) % duration
            : Math.min(state.current + delta, duration);
    } else {
        state.current = 0;
    }
    const reachedEnd = !loop && duration > 0 && previous < duration && state.current >= duration;
    const interval = 1000 / fps;
    const elapsed = now - state.previousDraw;
    const tolerance = 0.001;
    if (!reachedEnd && elapsed + tolerance < interval) return false;
    state.previousDraw += Math.max(1, Math.floor((elapsed + tolerance) / interval)) * interval;
    return true;
}
