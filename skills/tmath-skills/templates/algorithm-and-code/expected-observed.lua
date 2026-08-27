-- Question: how does `lo < hi` lose the final singleton in a closed-range binary search?
-- Expected uses `lo <= hi`; observed uses `lo < hi` and has no post-loop equality check.
-- Both traces share the same input, geometry, midpoint formula, and zero-based indexing.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local VALUES = {2, 5, 8, 12, 16, 23, 38}
local TARGET = 38
local LAYER = {panel = 2, range = 8, slot = 10, body = 20, text = 40}

local function buildTrace(values, target, condition)
    local trace, lo, hi = {}, 0, #values - 1
    local function continues()
        return condition == "closed" and lo <= hi or lo < hi
    end
    while continues() do
        local mid = lo + math.floor((hi - lo) / 2)
        local value = values[mid + 1]
        local event = {lo = lo, hi = hi, mid = mid, value = value}
        if value < target then
            event.relation, event.rejectedLo, event.rejectedHi = "<", lo, mid
            lo = mid + 1
        elseif value > target then
            event.relation, event.rejectedLo, event.rejectedHi = ">", mid, hi
            hi = mid - 1
        else
            event.relation, event.found = "=", mid
            trace[#trace + 1] = event
            return trace, mid, lo, hi
        end
        event.nextLo, event.nextHi = lo, hi
        trace[#trace + 1] = event
    end
    return trace, nil, lo, hi
end

local EXPECTED_TRACE, EXPECTED_FOUND = buildTrace(VALUES, TARGET, "closed")
local OBSERVED_TRACE, OBSERVED_FOUND, OBSERVED_LO, OBSERVED_HI = buildTrace(VALUES, TARGET, "strict")
assert(EXPECTED_FOUND == #VALUES - 1 and not OBSERVED_FOUND)
assert(OBSERVED_LO == OBSERVED_HI and VALUES[OBSERVED_LO + 1] == TARGET)
local COMMON_STEPS = #OBSERVED_TRACE
for step = 1, COMMON_STEPS do
    local expected, observed = EXPECTED_TRACE[step], OBSERVED_TRACE[step]
    assert(expected.lo == observed.lo and expected.hi == observed.hi)
    assert(expected.mid == observed.mid and expected.relation == observed.relation)
end

local PANEL = {
    expected = {x = -240, startX = -390, color = "success"},
    observed = {x = 240, startX = 90, color = "danger"},
}
local STEP, ARRAY_Y = 50, 35

local title = scene:text {
    text = "Code review · expected vs observed divergence",
    point = {0, 230}, role = "h2", fill = "foreground",
    layer = LAYER.text, id = "scene-title",
}
local subtitle = scene:text {
    text = "same sorted input and target · only the loop condition changes",
    point = {0, 194}, role = "text", fill = "muted",
    layer = LAYER.text, id = "scene-subtitle",
}

local function makePanel(prefix, spec, heading, conditionText)
    local root = scene:group {id = prefix .. ":panel"}
    root:rectangle {
        center = {spec.x, 22}, size = {420, 300}, corner = 9,
        fill = "#00000000", stroke = "border", width = 2,
        layer = LAYER.panel, id = prefix .. ":panel:body",
    }
    root:text {
        text = heading, point = {spec.x, 147}, role = "h3", fill = spec.color,
        layer = LAYER.text, id = prefix .. ":heading",
    }
    root:text {
        text = conditionText, point = {spec.x, 112}, role = "code", fill = "muted",
        layer = LAYER.text, id = prefix .. ":condition",
    }
    local cells, bodies = {}, {}
    for index, value in ipairs(VALUES) do
        local logical, x = index - 1, spec.startX + (index - 1) * STEP
        local cell = root:group {id = prefix .. ":cell:" .. logical}
        bodies[index] = cell:rectangle {
            center = {x, ARRAY_Y}, size = {44, 48}, corner = 4,
            fill = "surface", stroke = "border", width = 2,
            layer = LAYER.body, id = prefix .. ":cell:" .. logical .. ":body",
        }
        cell:text {
            text = tostring(value), point = {x, ARRAY_Y}, role = "code",
            fill = "foreground", layer = LAYER.text,
            id = prefix .. ":cell:" .. logical .. ":value",
        }
        cell:text {
            text = tostring(logical), point = {x, ARRAY_Y - 37}, role = "code",
            fill = "muted", layer = LAYER.text,
            id = prefix .. ":cell:" .. logical .. ":index",
        }
        cells[index] = cell
    end
    return {root = root, cells = cells, bodies = bodies, spec = spec}
end

local expected = makePanel("expected", PANEL.expected, "EXPECTED", "while lo <= hi")
local observed = makePanel("observed", PANEL.observed, "OBSERVED", "while lo < hi")

local rangeVersion = {expected = 0, observed = 0}
local function rangeBox(prefix, panel, lo, hi, color, opacity)
    rangeVersion[prefix] = rangeVersion[prefix] + 1
    local left = panel.spec.startX + lo * STEP - 25
    local right = panel.spec.startX + hi * STEP + 25
    return scene:rectangle {
        center = {(left + right) / 2, ARRAY_Y}, size = {right - left + 6, 60}, corner = 6,
        fill = "#00000000", stroke = color, width = 3, opacity = opacity or 1,
        layer = LAYER.range, id = prefix .. ":range:" .. rangeVersion[prefix],
    }
end

local expectedRange = rangeBox("expected", expected, 0, #VALUES - 1, "success")
local observedRange = rangeBox("observed", observed, 0, #VALUES - 1, "danger")
local expectedStatus = scene:text {
    text = string.format("candidate [0, %d]", #VALUES - 1),
    point = {PANEL.expected.x, -65}, role = "code",
    fill = "focus", layer = LAYER.text, id = "expected:status:0",
}
local observedStatus = scene:text {
    text = string.format("candidate [0, %d]", #VALUES - 1),
    point = {PANEL.observed.x, -65}, role = "code",
    fill = "focus", layer = LAYER.text, id = "observed:status:0",
}
local statusVersion = 0

local function replaceStatuses(leftText, rightText, rightColor)
    statusVersion = statusVersion + 1
    local nextExpected = scene:text {
        text = leftText, point = {PANEL.expected.x, -65}, role = "code", fill = "focus",
        opacity = 0, layer = LAYER.text, id = "expected:status:" .. statusVersion,
    }
    local nextObserved = scene:text {
        text = rightText, point = {PANEL.observed.x, -65}, role = "code",
        fill = rightColor or "focus", opacity = 0,
        layer = LAYER.text, id = "observed:status:" .. statusVersion,
    }
    scene:play({
        {target = expectedStatus, opacity = 0}, {target = nextExpected, opacity = 1},
        {target = observedStatus, opacity = 0}, {target = nextObserved, opacity = 1},
    }, 0.18, "gentle", 0)
    expectedStatus, observedStatus = nextExpected, nextObserved
end

scene:fade_in(title, {shift = {0, -6}, duration = 0.42, curve = "gentle"})
scene:fade_in(subtitle, {shift = {0, -5}, duration = 0.34, curve = "gentle"})
scene:fade_in(expected.root, {duration = 0.42, curve = "gentle"})
scene:fade_in(observed.root, {duration = 0.42, curve = "gentle"})
scene:create({expectedRange, observedRange}, 0.42, "ease_out")
scene:fade_in(expectedStatus, {duration = 0.24, curve = "gentle"})
scene:fade_in(observedStatus, {duration = 0.24, curve = "gentle"})

for step = 1, COMMON_STEPS do
    local event = EXPECTED_TRACE[step]
    local message = string.format("a[%d]=%d < %d", event.mid, event.value, TARGET)
    replaceStatuses(message, message)
    scene:play({
        {target = expected.bodies[event.mid + 1], fill = "focus", stroke = "focus"},
        {target = observed.bodies[event.mid + 1], fill = "focus", stroke = "focus"},
    }, 0.34, "ease_in_out", 0)
    scene:wait(0.30)

    local commit = {
        {target = expected.bodies[event.mid + 1], fill = "surface", stroke = "border"},
        {target = observed.bodies[event.mid + 1], fill = "surface", stroke = "border"},
    }
    for logical = event.rejectedLo, event.rejectedHi do
        commit[#commit + 1] = {target = expected.cells[logical + 1], opacity = 0.28}
        commit[#commit + 1] = {target = observed.cells[logical + 1], opacity = 0.28}
    end
    scene:play(commit, 0.38, "ease_in_out", 0)

    local nextExpectedRange = rangeBox("expected", expected, event.nextLo, event.nextHi, "success", 0)
    local nextObservedRange = rangeBox("observed", observed, event.nextLo, event.nextHi, "danger", 0)
    scene:play({
        {target = expectedRange, opacity = 0}, {target = nextExpectedRange, opacity = 1},
        {target = observedRange, opacity = 0}, {target = nextObservedRange, opacity = 1},
    }, 0.30, "ease_in_out", 0)
    expectedRange, observedRange = nextExpectedRange, nextObservedRange
end

local foundEvent = EXPECTED_TRACE[#EXPECTED_TRACE]
replaceStatuses(
    string.format("a[%d]=%d = %d → found", foundEvent.mid, foundEvent.value, TARGET),
    string.format("lo < hi is false at [%d, %d]", OBSERVED_LO, OBSERVED_HI),
    "danger"
)
scene:play({
    {target = expected.bodies[EXPECTED_FOUND + 1], fill = "result", stroke = "result"},
    {target = expectedRange, stroke = "result"},
    {target = observedRange, stroke = "danger"},
    {target = observed.bodies[OBSERVED_LO + 1], fill = "surface", stroke = "danger"},
}, 0.48, "ease_in_out", 0)
scene:wait(0.55)

local expectedResult = scene:text {
    text = "return index " .. EXPECTED_FOUND, point = {PANEL.expected.x, -104}, role = "code",
    fill = "result", layer = LAYER.text, id = "expected:result",
}
local observedResult = scene:text {
    text = "return not_found", point = {PANEL.observed.x, -104}, role = "code",
    fill = "danger", layer = LAYER.text, id = "observed:result",
}
scene:fade_in(expectedResult, {duration = 0.30, curve = "gentle"})
scene:fade_in(observedResult, {duration = 0.30, curve = "gentle"})
local result = scene:text {
    text = string.format("first divergence: singleton [%d, %d] still contains target %d",
        OBSERVED_LO, OBSERVED_HI, TARGET),
    point = {0, -220}, role = "text", fill = "result",
    layer = LAYER.text, id = "result:review-finding",
}
scene:fade_in(result, {shift = {0, 4}, duration = 0.38, curve = "gentle"})
scene:wait(2.4)
return scene
