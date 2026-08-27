-- Question: when does each task start, how long does it run, and which work overlaps?
-- Replace task_specs and TOTAL_WEEKS; bar geometry is derived from start/span on one axis.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local LAYER = {guide = 0, bar = 20, text = 30, marker = 40}
local root = scene:group {id = "release-plan:root"}
local guides = root:group {id = "release-plan:guides"}
local labels = root:group {id = "release-plan:labels"}
local bars = root:group {id = "release-plan:bars"}
local milestones = root:group {id = "release-plan:milestones"}

local TOTAL_WEEKS = 10
local TIMELINE_LEFT = -190
local TIMELINE_RIGHT = 420
local TIMELINE_TOP = 180
local TIMELINE_BOTTOM = -165
local PITCH = (TIMELINE_RIGHT - TIMELINE_LEFT) / TOTAL_WEEKS

-- Measured time axis and row grid. The left column is reserved for task ownership labels.
guides:line {
    from = {TIMELINE_LEFT, TIMELINE_TOP}, to = {TIMELINE_RIGHT, TIMELINE_TOP},
    color = "border", width = 1.5, layer = LAYER.guide, id = "release-plan:axis",
}
guides:line {
    from = {-215, TIMELINE_TOP + 24}, to = {-215, TIMELINE_BOTTOM},
    color = "border", width = 1.5, layer = LAYER.guide, id = "release-plan:label-divider",
}
for week = 0, TOTAL_WEEKS do
    local x = TIMELINE_LEFT + week * PITCH
    guides:line {
        from = {x, TIMELINE_TOP}, to = {x, TIMELINE_BOTTOM}, color = "border",
        width = (week == 0 or week == TOTAL_WEEKS) and 1.5 or 1,
        opacity = (week == 0 or week == TOTAL_WEEKS) and 0.8 or 0.32,
        layer = LAYER.guide, id = "release-plan:grid:" .. week,
    }
    if week < TOTAL_WEEKS then
        labels:text {
            text = "W" .. (week + 1), point = {x + PITCH * 0.5, TIMELINE_TOP + 25},
            role = "code", fill = "muted", layer = LAYER.text,
            id = "release-plan:week:" .. (week + 1),
        }
    end
end

local row_y = {112, 66, -15, -62, -128}
for index, y in ipairs({89, 42, -39, -85, -151}) do
    guides:line {
        from = {-430, y}, to = {TIMELINE_RIGHT, y}, color = "border", width = 1,
        opacity = 0.3, layer = LAYER.guide, id = "release-plan:row-divider:" .. index,
    }
end
labels:text {
    text = "DISCOVERY", point = {-430, 150}, align = {0, 0.5}, role = "code",
    fill = "muted", layer = LAYER.text, id = "release-plan:phase:discovery",
}
labels:text {
    text = "DELIVERY", point = {-430, 18}, align = {0, 0.5}, role = "code",
    fill = "muted", layer = LAYER.text, id = "release-plan:phase:delivery",
}

-- Copy/paste edit surface. start is zero-based; span is measured in weeks.
local task_specs = {
    {id = "research", label = "Research", start = 0, span = 3, row = 1},
    {id = "design", label = "Design", start = 1, span = 4, row = 2},
    {id = "build", label = "Build", start = 3, span = 5, row = 3, focal = true},
    {id = "verify", label = "Verify", start = 6, span = 3, row = 4},
    {id = "release", label = "Release", start = 9, row = 5, milestone = true},
}

local barHandles = {}
local milestoneHandle = nil
local milestoneLabel = nil
for _, task in ipairs(task_specs) do
    local y = row_y[task.row]
    labels:text {
        text = task.label, point = {-430, y}, align = {0, 0.5}, role = "text",
        fill = task.focal and "accent" or "foreground", layer = LAYER.text,
        id = "release-plan:task:" .. task.id .. ":label",
    }
    if task.milestone then
        local x = TIMELINE_LEFT + (task.start + 0.5) * PITCH
        milestoneHandle = milestones:polygon {
            points = {{x, y + 12}, {x + 12, y}, {x, y - 12}, {x - 12, y}},
            fill = "result", stroke = "result", width = 1.5,
            layer = LAYER.marker, id = "release-plan:task:" .. task.id .. ":milestone",
        }
        milestoneLabel = milestones:text {
            text = "SHIP", point = {x - 20, y}, align = {1, 0.5}, role = "code",
            fill = "result", layer = LAYER.text,
            id = "release-plan:task:" .. task.id .. ":milestone-label",
        }
    else
        local left = TIMELINE_LEFT + task.start * PITCH + 4
        local width = task.span * PITCH - 8
        barHandles[#barHandles + 1] = bars:rectangle {
            center = {left + width * 0.5, y}, size = {width, 26}, corner = 4,
            fill = "surface", stroke = task.focal and "accent" or "muted",
            width = task.focal and 2.5 or 1.5, layer = LAYER.bar,
            id = "release-plan:task:" .. task.id .. ":bar",
        }
    end
end

-- One restrained review marker provides temporal context without becoming another task.
local reviewX = TIMELINE_LEFT + 6 * PITCH
local reviewMarker = root:line {
    from = {reviewX, TIMELINE_TOP + 10}, to = {reviewX, TIMELINE_BOTTOM},
    color = "muted", width = 2, dash = {6, 6}, layer = LAYER.marker,
    id = "release-plan:review-marker",
}
local reviewLabel = root:text {
    text = "REVIEW", point = {reviewX, TIMELINE_TOP + 48}, role = "code", fill = "muted",
    layer = LAYER.text, id = "release-plan:review-label",
}

scene:fade_in(guides, {duration = 0.5, curve = "gentle"})
scene:fade_in(labels, {shift = {0, -5}, duration = 0.45, curve = "gentle"})
scene:create(reviewMarker, 0.35, "ease_out")
scene:fade_in(reviewLabel, {shift = {0, -4}, duration = 0.2, curve = "gentle"})
for _, bar in ipairs(barHandles) do
    scene:grow_from_edge(bar, "left", 0.38, "ease_out")
end
scene:grow_from_center(milestoneHandle, 0.3, "ease_out")
scene:fade_in(milestoneLabel, {shift = {0, -4}, duration = 0.18, curve = "gentle"})
scene:wait(2.4)
return scene
