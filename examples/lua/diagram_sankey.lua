local p = {
    paper = "#f7f5f0",
    panel = "#fffefa",
    ink = "#111827",
    muted = "#64748b",
    soft = "#94a3b8",
    rule = "#d9dee7",
    accent = "#2563eb",
    cyan = "#0891b2",
    signal = "#db2777",
}

local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    loop = false,
    background = p.paper,
    camera = { mode = "fixed", view = "2d", target = { 0, 0 }, height = 540 },
}

local header = scene:group { id = "sankey-header" }
header:text {
    text = "SANKEY / MATERIAL BALANCE",
    point = { -432, 238 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 13,
    fill = p.accent,
    id = "sankey-eyebrow",
}
header:text {
    text = "100 units in · 72 units retained",
    point = { -432, 207 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 30,
    fill = p.ink,
    id = "sankey-title",
}
header:text {
    text = "Ribbon thickness is the quantity — every split conserves its incoming total",
    point = { -432, 168 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 15,
    fill = p.muted,
    id = "sankey-subtitle",
}
header:line { from = { -432, 148 }, to = { 432, 148 }, stroke = p.rule, width = 1 }

local function ribbon(x1, top1, bottom1, x2, top2, bottom2, color, id)
    local bend = (x2 - x1) * 0.48
    return scene:path {
        commands = {
            { type = "move", to = { x1, top1 } },
            {
                type = "cubic",
                control1 = { x1 + bend, top1 },
                control2 = { x2 - bend, top2 },
                to = { x2, top2 },
            },
            { type = "line", to = { x2, bottom2 } },
            {
                type = "cubic",
                control1 = { x2 - bend, bottom2 },
                control2 = { x1 + bend, bottom1 },
                to = { x1, bottom1 },
            },
            { type = "close" },
        },
        samples = 28,
        fill = color,
        stroke = "#00000000",
        width = 1,
        layer = 1,
        id = id,
    }
end

local ribbons = {
    ribbon(-350, 130, -57.2, -10, 130, -57.2, "#2563eb55", "flow-input-converted"),
    ribbon(-350, -57.2, -130, -10, -73, -145.8, "#db277744", "flow-input-loss"),
    ribbon(10, 130, -10.4, 350, 130, -10.4, "#2563eb88", "flow-converted-product"),
    ribbon(10, -10.4, -57.2, 350, -26, -72.8, "#0891b266", "flow-converted-recovery"),
    ribbon(10, -73, -145.8, 350, -89, -161.8, "#db277766", "flow-loss-waste"),
}

local columns = scene:group { id = "sankey-columns" }
local function bar(id, x, top, bottom, color)
    return columns:rectangle {
        center = { x, (top + bottom) * 0.5 },
        size = { 20, top - bottom },
        corner = 4,
        fill = color,
        stroke = color,
        width = 1,
        layer = 4,
        id = id,
    }
end
bar("bar-input", -360, 130, -130, p.ink)
bar("bar-converted", 0, 130, -57.2, p.accent)
bar("bar-loss", 0, -73, -145.8, p.signal)
bar("bar-product", 360, 130, -10.4, p.accent)
bar("bar-recovery", 360, -26, -72.8, p.cyan)
bar("bar-waste", 360, -89, -161.8, p.signal)

local labels = scene:group { id = "sankey-labels" }
local function label(title, value, x, y, align, color, maskWidth, id)
    local group = labels:group { id = id }
    local center = align[1] == 1 and x - maskWidth * 0.5 or x + maskWidth * 0.5
    group:rectangle {
        center = { center, y },
        size = { maskWidth, 50 },
        corner = 6,
        fill = p.paper,
        stroke = "#00000000",
        layer = 3,
        id = id .. "-mask",
    }
    group:text {
        text = title,
        point = { x, y + 12 },
        align = align,
        font = "Pretendard",
        size = 13,
        fill = p.muted,
        layer = 5,
        id = id .. "-title",
    }
    group:text {
        text = value,
        point = { x, y - 13 },
        align = align,
        font = "Pretendard",
        size = 20,
        fill = color,
        layer = 5,
        id = id .. "-value",
    }
end
label("INPUT", "100", -382, 0, { 1, 0.5 }, p.ink, 64, "label-input")
label("CONVERTED", "72", -22, 36.4, { 1, 0.5 }, p.accent, 112, "label-converted")
label("LOSS", "28", -22, -109.4, { 1, 0.5 }, p.signal, 58, "label-loss")
label("PRODUCT", "54", 382, 59.8, { 0, 0.5 }, p.accent, 88, "label-product")
label("RECOVERY", "18", 382, -49.4, { 0, 0.5 }, p.cyan, 96, "label-recovery")
label("WASTE", "28", 382, -125.4, { 0, 0.5 }, p.signal, 68, "label-waste")

local footer = scene:group { id = "sankey-footer" }
footer:rectangle {
    center = { 0, -215 },
    size = { 864, 34 },
    corner = 8,
    fill = p.panel,
    stroke = p.rule,
    width = 1,
    layer = 2,
    id = "balance-card",
}
footer:text {
    text = "INPUT 100  =  PRODUCT 54  +  RECOVERY 18  +  WASTE 28",
    point = { 0, -215 },
    font = "Pretendard",
    size = 14,
    fill = p.ink,
    layer = 3,
    id = "balance-equation",
}

scene:fade_in(header, { shift = { 0, 8 }, duration = 0.28, curve = "snappy" })
scene:fade_in(columns, { duration = 0.28, curve = "gentle" })
scene:fill_reveal(ribbons, 0.9, "ease_out", 0)
scene:fade_in(labels, { shift = { 0, -5 }, duration = 0.24, curve = "snappy" })
scene:fade_in(footer, { shift = { 0, -6 }, duration = 0.22, curve = "snappy" })
scene:wait(0.8)

return scene
