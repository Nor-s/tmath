-- Question: how do fixed array slots differ from the values that occupy them?
-- Edit VALUES and SWAP. Preserve slot/index IDs and move only value Groups.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local VALUES = {7, 3, 9, 2, 6}
local SWAP = {2, 4}
local STEP, START_X, Y = 104, -208, -15
local SWAP_LANE_NEAR, SWAP_LANE_FAR = 72, 146
local LAYER = {slot = 10, token = 20, text = 40}

assert(SWAP[1] >= 1 and SWAP[1] <= #VALUES and SWAP[2] >= 1 and SWAP[2] <= #VALUES)
assert(SWAP[1] ~= SWAP[2])

local RESULT_VALUES = {}
for index, value in ipairs(VALUES) do RESULT_VALUES[index] = value end
RESULT_VALUES[SWAP[1]], RESULT_VALUES[SWAP[2]] = RESULT_VALUES[SWAP[2]], RESULT_VALUES[SWAP[1]]

local function translate(x, y)
    return {1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, 0, 0, 0, 0, 1}
end

local title = scene:text {
    text = "Array = fixed slots + movable values", point = {0, 228},
    role = "h2", fill = "foreground", layer = LAYER.text, id = "scene-title",
}
local subtitle = scene:text {
    text = string.format(
        "indices stay attached to storage while values %s and %s swap",
        tostring(VALUES[SWAP[1]]),
        tostring(VALUES[SWAP[2]])
    ),
    point = {0, 190}, role = "text", fill = "muted",
    layer = LAYER.text, id = "scene-subtitle",
}

local slots = scene:group {id = "array:slots"}
local values = scene:group {id = "array:values"}
local tokens, tokenBodies = {}, {}

for index, value in ipairs(VALUES) do
    local x = START_X + (index - 1) * STEP
    slots:rectangle {
        center = {x, Y}, size = {88, 88}, corner = 6,
        fill = "surface", stroke = "border", width = 2,
        layer = LAYER.slot, id = "array-slot:" .. (index - 1),
    }
    slots:text {
        text = tostring(index - 1), point = {x, Y - 82},
        role = "code", fill = "muted", layer = LAYER.text,
        id = "array-index:" .. (index - 1),
    }

    local token = values:group {
        matrix = translate(x, Y), id = "value:item-" .. index,
    }
    local body = token:rectangle {
        center = {0, 0}, size = {70, 70}, corner = 5,
        fill = "surface", stroke = "foreground", width = 2,
        layer = LAYER.token, id = "value:item-" .. index .. ":body",
    }
    token:text {
        text = tostring(value), point = {0, 0}, role = "h3",
        fill = "foreground", layer = LAYER.text,
        id = "value:item-" .. index .. ":label",
    }
    tokens[index], tokenBodies[index] = token, body
end

local status = scene:text {
    text = string.format("read: a[%d] = %s", SWAP[1] - 1, tostring(VALUES[SWAP[1]])),
    point = {0, -145}, role = "code",
    fill = "focus", layer = LAYER.text, id = "status:read",
}

scene:fade_in(title, {shift = {0, -6}, duration = 0.45, curve = "gentle"})
scene:fade_in(subtitle, {shift = {0, -5}, duration = 0.35, curve = "gentle"})
scene:fade_in(slots, {duration = 0.45, curve = "gentle"})
scene:fade_in(values, {shift = {0, 8}, duration = 0.55, curve = "ease_out"})
scene:fade_in(status, {shift = {0, 5}, duration = 0.30, curve = "gentle"})
scene:indicate(tokens[SWAP[1]], {scale = 1.05, duration = 0.42, curve = "ease_in_out"})
scene:wait(0.45)

local swapStatus = scene:text {
    text = string.format("swap values; slots %d and %d do not move", SWAP[1] - 1, SWAP[2] - 1),
    point = {0, -145},
    role = "code", fill = "focus", layer = LAYER.text, id = "status:swap",
}
scene:fade_transform(status, swapStatus, 0.22, "gentle")
scene:play({
    {target = tokenBodies[SWAP[1]], fill = "focus"},
    {target = tokenBodies[SWAP[2]], fill = "focus"},
}, 0.30, "ease_in_out", 0)
local distance = (SWAP[2] - SWAP[1]) * STEP
scene:play({
    {target = tokens[SWAP[1]], shift = {0, SWAP_LANE_NEAR}},
    {target = tokens[SWAP[2]], shift = {0, SWAP_LANE_FAR}},
}, 0.24, "ease_out", 0)
scene:play({
    {target = tokens[SWAP[1]], shift = {distance, 0}},
    {target = tokens[SWAP[2]], shift = {-distance, 0}},
}, 0.58, "ease_in_out", 0)
scene:play({
    {target = tokens[SWAP[1]], shift = {0, -SWAP_LANE_NEAR}},
    {target = tokens[SWAP[2]], shift = {0, -SWAP_LANE_FAR}},
    {target = tokenBodies[SWAP[1]], fill = "surface"},
    {target = tokenBodies[SWAP[2]], fill = "surface"},
}, 0.24, "ease_in", 0)

local result = scene:text {
    text = "result: [" .. table.concat(RESULT_VALUES, ", ") .. "]", point = {0, -205},
    role = "text", fill = "result", layer = LAYER.text, id = "result:array",
}
scene:fade_in(result, {shift = {0, 6}, duration = 0.38, curve = "gentle"})
scene:wait(2.0)
return scene
