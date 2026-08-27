local palette = {
    background = "#0b111a",
    panel = "#101925",
    panel_alt = "#131e2b",
    line = "#2a3a4d",
    text = "#f4f7fb",
    muted = "#94a3b8",
    cyan = "#4cc9f0",
    gold = "#ffd166",
    coral = "#ff6b6b",
    green = "#7bd88f",
}

local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    antialiasing = true,
    background = palette.background,
    camera = { mode = "fixed", view = "2d", height = 7.4 },
}
local space = scene:space {
    x = { -6.5, 6.5, 1 },
    y = { -3.5, 3.5, 1 },
    opacity = 0,
}

local eyebrow = space:text {
    text = "THORVG · SOFTWARE RASTERIZER / 01",
    point = { -5.85, 3.28 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = palette.muted,
}
local title = space:text {
    text = "Run-length spans",
    point = { -5.85, 2.82 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 30,
    fill = palette.text,
}
local subtitle = space:text {
    text = "Compress one scanline into contiguous coverage records",
    point = { -5.83, 2.34 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 15,
    fill = palette.muted,
}
local divider = space:line {
    from = { -5.85, 2.08 },
    to = { 5.85, 2.08 },
    color = palette.line,
    width = 2,
}

local input_panel = space:rectangle {
    center = { 0, 1.08 },
    size = { 12.4, 1.55 },
    corner = 0.14,
    fill = palette.panel,
    stroke = palette.line,
    width = 2,
}
local input_label = space:text {
    text = "MECHANISM · COVERAGE SCANLINE",
    point = { -5.7, 1.72 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = palette.muted,
}
local patches = {
    { region = { 1, 0, 3, 1 }, color = palette.cyan },
    { region = { 5, 0, 2, 1 }, color = palette.gold },
    { region = { 8, 0, 4, 1 }, color = palette.coral },
}
local pixels = space:cell {
    origin = { -6.0, 0.58 },
    size = { 12, 1 },
    mode = "padd",
    padding = 0.055,
    color = "#1b2734",
    patches = patches,
    id = "coverage-scanline",
}
local coverage_labels = {
    space:text {
        text = "cov 255",
        point = { -3.50, 1.30 },
        font = "Pretendard",
        size = 13,
        fill = palette.background,
        layer = 8,
    },
    space:text {
        text = "cov 160",
        point = { 0, 1.30 },
        font = "Pretendard",
        size = 13,
        fill = palette.background,
        layer = 8,
    },
    space:text {
        text = "cov 224",
        point = { 4.0, 1.30 },
        font = "Pretendard",
        size = 13,
        fill = palette.background,
        layer = 8,
    },
}
local indices = {}
for i = 0, 11 do
    indices[#indices + 1] = space:text {
        text = tostring(i),
        point = { -5.50 + i, 0.42 },
        font = "Pretendard",
        size = 11,
        fill = palette.muted,
    }
end

local emit_label = space:text {
    text = "RUN BOUNDARIES",
    point = { -5.7, -0.04 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = palette.muted,
}
local run_arrows = {
    space:arrow {
        from = { -3.50, 0.28 },
        to = { -3.50, -0.22 },
        tip = 9,
        color = palette.cyan,
        width = 2,
    },
    space:arrow {
        from = { 0, 0.28 },
        to = { 0, -0.22 },
        tip = 9,
        color = palette.gold,
        width = 2,
    },
    space:arrow {
        from = { 4.0, 0.28 },
        to = { 4.0, -0.22 },
        tip = 9,
        color = palette.coral,
        width = 2,
    },
}
local output_label = space:text {
    text = "RESULT · SwSpan { x, y, len, coverage }",
    point = { -5.7, -0.62 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = palette.muted,
}

local card_specs = {
    { -3.75, palette.cyan, "x 1   ·   len 3", "coverage 255" },
    { 0, palette.gold, "x 5   ·   len 2", "coverage 160" },
    { 3.75, palette.coral, "x 8   ·   len 4", "coverage 224" },
}
local cards = {}
local records = {}
for _, spec in ipairs(card_specs) do
    cards[#cards + 1] = space:rectangle {
        center = { spec[1], -1.45 },
        size = { 3.35, 1.02 },
        corner = 0.13,
        fill = palette.panel_alt,
        stroke = spec[2],
        width = 2,
    }
    records[#records + 1] = space:text {
        text = spec[3],
        point = { spec[1], -1.28 },
        font = "Pretendard",
        size = 16,
        fill = palette.text,
    }
    records[#records + 1] = space:text {
        text = spec[4],
        point = { spec[1], -1.68 },
        font = "Pretendard",
        size = 13,
        fill = spec[2],
    }
end
local conclusion = space:text {
    text = "3 spans encode 9 covered pixels  ·  blend loops over runs, not empty cells",
    point = { 0, -2.48 },
    font = "Pretendard",
    size = 17,
    fill = palette.green,
}

scene:create({ eyebrow, title, subtitle, divider }, 0.52, "ease_out", 0.06)
scene:create({ input_panel, input_label }, 0.36, "ease_out", 0.05)
scene:create(pixels, 0.72, "linear")
scene:create(coverage_labels, 0.30, "ease_out", 0.06)
scene:create(indices, 0.34, "ease_out", 0.025)
scene:create(emit_label, 0.28, "ease_out")
scene:create(run_arrows, 0.42, "ease_out", 0.08)
scene:create(output_label, 0.25, "ease_out")
scene:create(cards, 0.48, "ease_out", 0.08)
scene:create(records, 0.38, "ease_out", 0.045)
scene:create(conclusion, 0.40, "ease_out")
scene:wait(0.70)
return scene
