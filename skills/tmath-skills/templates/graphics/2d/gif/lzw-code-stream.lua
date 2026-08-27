-- local question: How does GIF LZW replace repeated index phrases with codes?
-- visible input: the palette-index sequence 0 1 0 1 0 1 0 1
-- subject object or field: Clear/EOI codes and the growing phrase dictionary
-- one dominant action: add four phrases, then emit their dictionary codes
-- observable output: repeated phrases become codes and the code width grows from 3 to 4 bits
-- coordinate frame and units: values are palette indices, dictionary codes, and code bits
-- section bounds supplied by the parent: standalone 960 x 540 wrapper
-- final readable pose: source indices, emitted codes, additions, and width boundary

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false, theme = "3_blue_1_eyes",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local LAYER = {object = 0, arrow = 30, text = 40}
local figure = scene:group {id = "gif-lzw-code-stream-figure"}

local function text(parent, id, value, point, role, fill, align)
    return parent:text {
        id = id, text = value, point = point, role = role or "code",
        fill = fill or "foreground", align = align or {0.5, 0.5}, layer = LAYER.text,
    }
end

local function copySequence(values)
    local result = {}
    for _, value in ipairs(values) do result[#result + 1] = value end
    return result
end

local function sequenceKey(values)
    return table.concat(values, ",")
end

local function sequenceLabel(values)
    local parts = {}
    for index, value in ipairs(values) do parts[index] = tostring(value) end
    return table.concat(parts, "")
end

local input = {0, 1, 0, 1, 0, 1, 0, 1}
local minimumCodeSize = 2
local symbolCount = 1 << minimumCodeSize
local clearCode = symbolCount
local endCode = clearCode + 1
local firstFreeCode = endCode + 1
local initialCodeWidth = minimumCodeSize + 1
local widthGrowthCode = 1 << initialCodeWidth

local dictionary = {}
for symbol = 0, symbolCount - 1 do dictionary[tostring(symbol)] = symbol end
local nextCode = firstFreeCode
local emitted = {clearCode}
local additions = {}
local phrase = {input[1]}
for position = 2, #input do
    local candidate = copySequence(phrase)
    candidate[#candidate + 1] = input[position]
    local candidateKey = sequenceKey(candidate)
    if dictionary[candidateKey] then
        phrase = candidate
    else
        emitted[#emitted + 1] = dictionary[sequenceKey(phrase)]
        dictionary[candidateKey] = nextCode
        additions[#additions + 1] = {code = nextCode, phrase = candidate}
        nextCode = nextCode + 1
        phrase = {input[position]}
    end
end
emitted[#emitted + 1] = dictionary[sequenceKey(phrase)]
emitted[#emitted + 1] = endCode

local claim = text(
    figure, "gif-lzw-code-stream-claim",
    "GIF LZW learns repeated index phrases while it emits codes",
    {0, 2.55}, "h3"
)
local setup = text(
    figure, "gif-lzw-setup",
    string.format("minimum code size %d -> Clear %d · EOI %d · first free %d · initial width %d bits",
        minimumCodeSize, clearCode, endCode, firstFreeCode, initialCodeWidth),
    {0, 1.95}, "code", "muted"
)

local inputGroup = figure:group {id = "gif-lzw-input"}
local inputStart, inputStep = -2.62, 0.75
for index, value in ipairs(input) do
    local x = inputStart + (index - 1) * inputStep
    inputGroup:rectangle {
        id = string.format("gif-lzw-input-%02d-body", index),
        center = {x, 1.25}, size = {0.62, 0.58},
        fill = value == 0 and "info" or "warning", stroke = "border",
        width = 1.4, layer = LAYER.object,
    }
    text(
        inputGroup, string.format("gif-lzw-input-%02d-value", index), tostring(value),
        {x, 1.25}, "code", "#ffffffff"
    )
end
local inputLabel = text(
    figure, "gif-lzw-input-label", "palette indices", {-3.58, 1.25}, "code", "foreground", {1, 0.5}
)

local compressArrow = figure:arrow {
    id = "gif-lzw-compress-arrow", from = {0, 0.88}, to = {0, 0.57},
    stroke = "focus", width = 2, tip = 10, layer = LAYER.arrow,
}
local emittedLabel = text(
    figure, "gif-lzw-emitted-label", "emitted code stream", {0.28, 0.72}, "code", "focus", {0, 0.5}
)

local emittedGroup = figure:group {id = "gif-lzw-emitted-codes"}
local codeStart, codeStep = -3.72, 1.24
for index, code in ipairs(emitted) do
    local x = codeStart + (index - 1) * codeStep
    local title = tostring(code)
    local detail = "code"
    local stroke = code >= widthGrowthCode and "result" or "border"
    if code == clearCode then title, detail, stroke = "Clear", tostring(code), "warning" end
    if code == endCode then title, detail, stroke = "EOI", tostring(code), "result" end
    emittedGroup:rectangle {
        id = string.format("gif-lzw-code-%02d-body", index), center = {x, 0.08},
        size = {1.04, 0.76}, fill = "surface", stroke = stroke,
        width = 1.7, layer = LAYER.object,
    }
    text(
        emittedGroup, string.format("gif-lzw-code-%02d-title", index), title,
        {x, 0.23}, "code", stroke == "border" and "foreground" or stroke
    )
    text(
        emittedGroup, string.format("gif-lzw-code-%02d-detail", index), detail,
        {x, -0.09}, "code", "muted"
    )
end

local additionLabel = text(
    figure, "gif-lzw-addition-label", "dictionary additions", {0, -0.66}, "code", "muted"
)
local additionGroup = figure:group {id = "gif-lzw-dictionary-additions"}
local additionXs = {-2.78, -0.94, 0.94, 2.82}
for index, addition in ipairs(additions) do
    local x = additionXs[index]
    local stroke = addition.code >= widthGrowthCode and "result" or "focus"
    additionGroup:rectangle {
        id = string.format("gif-lzw-addition-%02d-body", index),
        center = {x, -1.20}, size = {1.54, 0.76}, fill = "surface",
        stroke = stroke, width = 1.7, layer = LAYER.object,
    }
    text(
        additionGroup, string.format("gif-lzw-addition-%02d-code", index),
        string.format("%d = %s", addition.code, sequenceLabel(addition.phrase)),
        {x, -1.20}, "code", stroke
    )
end

local widthSummary = text(
    figure, "gif-lzw-width-summary",
    string.format("next code reaches %d -> code width %d -> %d bits; GIF grows up to 12 bits",
        widthGrowthCode, initialCodeWidth, initialCodeWidth + 1),
    {0, -2.05}, "code", "result"
)

scene:fade_in(claim, {shift = {0, 0.08}, duration = 0.44, curve = "gentle"})
scene:fade_in(setup, {shift = {0, 0.05}, duration = 0.30, curve = "gentle"})
scene:fade_in(inputLabel, {shift = {0.05, 0}, duration = 0.24, curve = "gentle"})
scene:fade_in(inputGroup, {shift = {0, 0.08}, duration = 0.56, curve = "ease_out"})
scene:create(compressArrow, 0.28, "ease_out")
scene:fade_in(emittedLabel, {shift = {0, 0.04}, duration = 0.24, curve = "gentle"})
scene:fade_in(emittedGroup, {shift = {0, 0.08}, duration = 0.68, curve = "ease_out"})
scene:fade_in(additionLabel, {shift = {0, 0.04}, duration = 0.24, curve = "gentle"})
scene:fade_in(additionGroup, {shift = {0, 0.08}, duration = 0.70, curve = "ease_out"})
scene:fade_in(widthSummary, {shift = {0, -0.05}, duration = 0.34, curve = "gentle"})
scene:wait(2.0)
return scene
