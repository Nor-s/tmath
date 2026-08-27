-- Symbolic forward-only pipeline schedule generated from interval records.
-- Replace records with a source-derived schedule; do not infer overlap from placement alone.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "pro_white",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local LAYER = {grid = 0, bar = 20, text = 30, focus = 40}
local root = scene:group {id = "pipeline:root"}
local header = root:group {id = "pipeline:header"}
local chart = root:group {id = "pipeline:chart"}
local bars = root:group {id = "pipeline:bars"}
local notes = root:group {id = "pipeline:notes"}

header:text {
    text = "Pipeline schedule", point = {0, 232}, role = "h2",
    fill = "foreground", layer = LAYER.text, id = "pipeline:title",
}
header:text {
    text = "forward-only symbolic trace · four stages × four microbatches",
    point = {0, 199}, role = "code", fill = "muted", layer = LAYER.text,
    id = "pipeline:subtitle",
}

local stages, microbatches, slots = 4, 4, 7
local x0, y0, slot_w, lane_h = -340, 102, 96, 65
for slot = 0, slots do
    local x = x0 + slot * slot_w
    chart:line {
        from = {x, y0 + 34}, to = {x, y0 - stages * lane_h + 34},
        color = "border", width = 0.8, layer = LAYER.grid,
        id = "pipeline:grid:vertical:" .. slot,
    }
    if slot < slots then
        chart:text {
            text = "t" .. slot, point = {x + slot_w * 0.5, y0 + 54}, role = "code",
            fill = "muted", layer = LAYER.text, id = "pipeline:time:" .. slot,
        }
    end
end
for stage = 0, stages - 1 do
    local y = y0 - stage * lane_h
    chart:line {
        from = {x0, y - 32}, to = {x0 + slots * slot_w, y - 32},
        color = "border", width = 0.8, layer = LAYER.grid,
        id = "pipeline:grid:horizontal:" .. stage,
    }
    chart:text {
        text = "stage " .. stage, point = {x0 - 65, y}, role = "code",
        fill = "foreground", layer = LAYER.text, id = "pipeline:stage:" .. stage,
    }
end

-- Single source of truth for the schedule.
local intervals = {}
for stage = 0, stages - 1 do
    for microbatch = 0, microbatches - 1 do
        intervals[#intervals + 1] = {
            stage = stage, microbatch = microbatch, start = stage + microbatch, span = 1,
        }
    end
end

local bar_handles = {}
for index, item in ipairs(intervals) do
    local x = x0 + (item.start + item.span * 0.5) * slot_w
    local y = y0 - item.stage * lane_h
    local group = bars:group {id = "pipeline:interval:" .. index}
    bar_handles[index] = group:rectangle {
        center = {x, y}, size = {slot_w - 10, 42}, corner = 5,
        fill = item.microbatch % 2 == 0 and "#dbeafe" or "#dcfce7",
        stroke = item.stage == 0 and "accent" or "border", width = item.stage == 0 and 1.8 or 1,
        layer = LAYER.bar, id = "pipeline:interval:" .. index .. ":body",
    }
    group:text {
        text = "F m" .. item.microbatch, point = {x, y}, role = "code",
        fill = "foreground", layer = LAYER.text, id = "pipeline:interval:" .. index .. ":label",
    }
end

notes:text {
    text = "fill", point = {x0 + slot_w * 0.7, -181}, role = "code",
    fill = "focus", layer = LAYER.text, id = "pipeline:phase:fill",
}
notes:text {
    text = "steady overlap", point = {x0 + slot_w * 3.5, -181}, role = "code",
    fill = "accent", layer = LAYER.text, id = "pipeline:phase:steady",
}
notes:text {
    text = "drain", point = {x0 + slot_w * 6.3, -181}, role = "code",
    fill = "focus", layer = LAYER.text, id = "pipeline:phase:drain",
}
local conclusion = root:text {
    text = "Empty cells are visible bubble time; replace this symbolic trace with measured or derived intervals.",
    point = {0, -229}, role = "code", fill = "result", layer = LAYER.text,
    id = "pipeline:conclusion",
}

scene:fade_in(header, {shift = {0, -6}, duration = 0.5, curve = "gentle"})
scene:fade_in(chart, {duration = 0.55, curve = "gentle"})
scene:fade_in(bars, {shift = {-5, 0}, duration = 0.9, curve = "ease_out"})
scene:indicate(bar_handles[7], {color = "focus", scale = 1.025, duration = 0.42, curve = "ease_in_out"})
scene:fade_in(notes, {duration = 0.35, curve = "gentle"})
scene:fade_in(conclusion, {duration = 0.35, curve = "gentle"})
scene:wait(2.4)
return scene
