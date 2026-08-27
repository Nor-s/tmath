-- Question: how many value comparisons do linear and binary search perform on the same input?
-- Cost unit: exactly one target-versus-array-value comparison; animation time is not a metric.
-- Variants: linear scan from index 0; closed-range binary search returning any match.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local VALUES = {2, 5, 8, 12, 16, 23, 38, 56}
local TARGET = 38
local LAYER = {range = 8, slot = 10, body = 20, text = 40}

local function buildLinearTrace(values, target)
    local trace = {}
    for index, value in ipairs(values) do
        local logical = index - 1
        trace[#trace + 1] = {
            index = logical, value = value, count = #trace + 1,
            found = value == target,
        }
        if value == target then return trace, logical end
    end
    return trace, nil
end

local function buildBinaryTrace(values, target)
    local trace, lo, hi = {}, 0, #values - 1
    while lo <= hi do
        local mid = lo + math.floor((hi - lo) / 2)
        local value = values[mid + 1]
        local event = {lo = lo, hi = hi, mid = mid, value = value, count = #trace + 1}
        if value < target then
            event.relation, event.rejectedLo, event.rejectedHi = "<", lo, mid
            lo = mid + 1
        elseif value > target then
            event.relation, event.rejectedLo, event.rejectedHi = ">", mid, hi
            hi = mid - 1
        else
            event.relation, event.found = "=", mid
            trace[#trace + 1] = event
            return trace, mid
        end
        event.nextLo, event.nextHi = lo, hi
        trace[#trace + 1] = event
    end
    return trace, nil
end

local LINEAR_TRACE, LINEAR_FOUND = buildLinearTrace(VALUES, TARGET)
local BINARY_TRACE, BINARY_FOUND = buildBinaryTrace(VALUES, TARGET)
assert(LINEAR_FOUND == BINARY_FOUND and LINEAR_FOUND == 6)
assert(#LINEAR_TRACE == 7 and #BINARY_TRACE == 3)

local START_X, STEP = -245, 70
local ROW = {linear = 82, binary = -48}

local title = scene:text {
    text = "Search cost · count comparisons, not animation time",
    point = {0, 230}, role = "h2", fill = "foreground",
    layer = LAYER.text, id = "scene-title",
}
local subtitle = scene:text {
    text = "same sorted input · target = " .. TARGET .. " · one filled square = one value comparison",
    point = {0, 194}, role = "code", fill = "muted",
    layer = LAYER.text, id = "scene-subtitle",
}
local linearHeading = scene:text {
    text = "LINEAR", point = {-390, ROW.linear + 8}, role = "code",
    fill = "accent", layer = LAYER.text, id = "linear:heading",
}
local binaryHeading = scene:text {
    text = "BINARY", point = {-390, ROW.binary + 8}, role = "code",
    fill = "secondary", layer = LAYER.text, id = "binary:heading",
}

local function makeArray(prefix, y)
    local root = scene:group {id = prefix .. ":array"}
    local cells, bodies = {}, {}
    for index, value in ipairs(VALUES) do
        local logical, x = index - 1, START_X + (index - 1) * STEP
        local cell = root:group {id = prefix .. ":cell:" .. logical}
        bodies[index] = cell:rectangle {
            center = {x, y}, size = {58, 54}, corner = 5,
            fill = "surface", stroke = "border", width = 2,
            layer = LAYER.body, id = prefix .. ":cell:" .. logical .. ":body",
        }
        cell:text {
            text = tostring(value), point = {x, y}, role = "code", fill = "foreground",
            layer = LAYER.text, id = prefix .. ":cell:" .. logical .. ":value",
        }
        cell:text {
            text = tostring(logical), point = {x, y - 39}, role = "code", fill = "muted",
            layer = LAYER.text, id = prefix .. ":cell:" .. logical .. ":index",
        }
        cells[index] = cell
    end
    return {root = root, cells = cells, bodies = bodies}
end

local linear = makeArray("linear", ROW.linear)
local binary = makeArray("binary", ROW.binary)

local comparisonLabel = scene:text {
    text = "comparisons", point = {365, 145}, role = "code", fill = "muted",
    layer = LAYER.text, id = "cost:label",
}
local costTicks = {linear = {}, binary = {}}
local costTickGroups = {
    linear = scene:group {id = "linear:comparison-ticks"},
    binary = scene:group {id = "binary:comparison-ticks"},
}
for index = 1, #LINEAR_TRACE do
    local x = 305 + (index - 1) * 20
    costTicks.linear[index] = costTickGroups.linear:rectangle {
        center = {x, ROW.linear}, size = {14, 14}, corner = 2,
        fill = "surface", stroke = "border", width = 1.5,
        layer = LAYER.body, id = "linear:comparison:" .. index,
    }
    costTicks.binary[index] = costTickGroups.binary:rectangle {
        center = {x, ROW.binary}, size = {14, 14}, corner = 2,
        fill = "surface", stroke = "border", width = 1.5,
        layer = LAYER.body, id = "binary:comparison:" .. index,
    }
end

local rangeVersion = 0
local function rangeBox(lo, hi, opacity)
    rangeVersion = rangeVersion + 1
    local left = START_X + lo * STEP - 32
    local right = START_X + hi * STEP + 32
    return scene:rectangle {
        center = {(left + right) / 2, ROW.binary}, size = {right - left + 6, 66}, corner = 7,
        fill = "#00000000", stroke = "secondary", width = 3,
        opacity = opacity or 1, layer = LAYER.range, id = "binary:range:" .. rangeVersion,
    }
end
local binaryRange = rangeBox(0, #VALUES - 1)

local status, statusIndex = nil, 0
local function setStatus(message)
    statusIndex = statusIndex + 1
    local nextStatus = scene:text {
        text = message, point = {0, -145}, role = "code", fill = "focus",
        layer = LAYER.text, id = "status:" .. statusIndex,
    }
    if status then scene:fade_transform(status, nextStatus, 0.17, "gentle")
    else scene:fade_in(nextStatus, {duration = 0.24, curve = "gentle"}) end
    status = nextStatus
end

scene:fade_in(title, {shift = {0, -6}, duration = 0.42, curve = "gentle"})
scene:fade_in(subtitle, {shift = {0, -5}, duration = 0.34, curve = "gentle"})
scene:fade_in(linearHeading, {duration = 0.24, curve = "gentle"})
scene:fade_in(binaryHeading, {duration = 0.24, curve = "gentle"})
scene:fade_in(linear.root, {shift = {0, 5}, duration = 0.42, curve = "gentle"})
scene:fade_in(binary.root, {shift = {0, 5}, duration = 0.42, curve = "gentle"})
scene:fade_in(comparisonLabel, {duration = 0.22, curve = "gentle"})
scene:fade_in(costTickGroups.linear, {duration = 0.30, curve = "gentle"})
scene:fade_in(costTickGroups.binary, {duration = 0.30, curve = "gentle"})
scene:create(binaryRange, 0.34, "ease_out")

for round = 1, #LINEAR_TRACE do
    local linearEvent, binaryEvent = LINEAR_TRACE[round], BINARY_TRACE[round]
    local message = string.format("comparison %d · linear a[%d]=%d", round,
        linearEvent.index, linearEvent.value)
    if binaryEvent then
        message = message .. string.format(" · binary a[%d]=%d", binaryEvent.mid, binaryEvent.value)
    else
        message = message .. " · binary already found"
    end
    setStatus(message)

    local focus = {
        {target = linear.bodies[linearEvent.index + 1], fill = "focus", stroke = "focus"},
        {target = costTicks.linear[linearEvent.count], fill = "accent", stroke = "accent"},
    }
    if binaryEvent then
        focus[#focus + 1] = {
            target = binary.bodies[binaryEvent.mid + 1], fill = "focus", stroke = "focus",
        }
        focus[#focus + 1] = {
            target = costTicks.binary[binaryEvent.count], fill = "secondary", stroke = "secondary",
        }
    end
    scene:play(focus, 0.32, "ease_in_out", 0)
    scene:wait(0.22)

    if linearEvent.found then
        scene:play({{
            target = linear.bodies[linearEvent.index + 1], fill = "result", stroke = "result",
        }}, 0.30, "ease_in_out", 0)
    else
        scene:play({{
            target = linear.bodies[linearEvent.index + 1], fill = "surface", stroke = "border",
        }}, 0.18, "ease_in_out", 0)
        scene:play({{target = linear.cells[linearEvent.index + 1], opacity = 0.30}},
            0.22, "ease_in_out", 0)
    end

    if binaryEvent then
        if binaryEvent.found then
            scene:play({{
                target = binary.bodies[binaryEvent.mid + 1], fill = "result", stroke = "result",
            }}, 0.30, "ease_in_out", 0)
            scene:play({{target = binaryRange, stroke = "result"}}, 0.24, "ease_in_out", 0)
        else
            scene:play({{
                target = binary.bodies[binaryEvent.mid + 1], fill = "surface", stroke = "border",
            }}, 0.18, "ease_in_out", 0)
            local reject = {}
            for logical = binaryEvent.rejectedLo, binaryEvent.rejectedHi do
                reject[#reject + 1] = {target = binary.cells[logical + 1], opacity = 0.28}
            end
            local nextRange = rangeBox(binaryEvent.nextLo, binaryEvent.nextHi, 0)
            reject[#reject + 1] = {target = binaryRange, opacity = 0}
            reject[#reject + 1] = {target = nextRange, opacity = 1}
            scene:play(reject, 0.30, "ease_in_out", 0)
            binaryRange = nextRange
        end
    end
end

local linearCount = scene:text {
    text = "count = " .. #LINEAR_TRACE, point = {365, ROW.linear - 28},
    role = "code", fill = "accent", layer = LAYER.text, id = "linear:cost-result",
}
local binaryCount = scene:text {
    text = "count = " .. #BINARY_TRACE, point = {365, ROW.binary - 28},
    role = "code", fill = "secondary", layer = LAYER.text, id = "binary:cost-result",
}
scene:fade_in(linearCount, {duration = 0.28, curve = "gentle"})
scene:fade_in(binaryCount, {duration = 0.28, curve = "gentle"})
local result = scene:text {
    text = string.format("same result index %d · linear %d comparisons · binary %d comparisons",
        LINEAR_FOUND, #LINEAR_TRACE, #BINARY_TRACE),
    point = {0, -220}, role = "text", fill = "result",
    layer = LAYER.text, id = "result:cost-comparison",
}
scene:fade_transform(status, result, 0.24, "gentle")
scene:wait(2.4)
return scene
