local p = {
    paper = "#ffffff",
    ink = "#202124",
    muted = "#555b64",
    soft = "#6a717c",
    rule = "#d8dadd",
    accent = "#9b3600",
    blue = "#5e7a9b",
    mustard = "#b8915a",
    purple = "#6e6479",
    orange = "#f28e2b",
}
local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    loop = false,
    background = p.paper,
    camera = { view = "2d", height = 9 },
}
local root = scene:space { x = { -8, 8, 1 }, y = { -4.5, 4.5, 1 }, opacity = 0 }
local function text(v, q, s, c, id, a)
    return root:text {
        text = v,
        point = q,
        size = s,
        font = "Pretendard",
        fill = c or p.ink,
        id = id,
        align = a or { 0.5, 0.5 },
    }
end
local function mix(a, b, t)
    local function ch(c, o)
        return tonumber(string.sub(c, o, o + 1), 16)
    end
    local function h(v)
        return string.format("%02x", math.floor(v + 0.5))
    end
    return "#"
        .. h(ch(a, 2) + (ch(b, 2) - ch(a, 2)) * t)
        .. h(ch(a, 4) + (ch(b, 4) - ch(a, 4)) * t)
        .. h(ch(a, 6) + (ch(b, 6) - ch(a, 6)) * t)
end
text("06  /  THORVG CPU RASTERIZER", { -7.2, 3.72 }, 12, p.accent, "eyebrow", { 0, 0.5 })
text("Map an angle to the ColorTable", { -7.2, 3.25 }, 27, p.ink, "title", { 0, 0.5 })
text(
    "atan2f produces a signed angle; offset and fract convert it into lookup parameter t.",
    { -7.2, 2.72 },
    14,
    p.soft,
    "subtitle",
    { 0, 0.5 }
)
root:line { from = { -7.2, 2.48 }, to = { 7.2, 2.48 }, color = p.rule, width = 1 }
text("t in [0, 1)      index = round((SW_COLOR_TABLE - 1) x t)", { 0, -4.05 }, 12, p.soft, "footer")
local center = { -3.65, -0.55 }
local palette = { p.purple, p.blue, p.mustard, p.orange, p.purple }
local sectors = {}
local n = 32
for i = 0, n - 1 do
    local phase = i / n * 4
    local k = math.floor(phase) + 1
    if k > 4 then
        k = 4
    end
    local color = mix(palette[k], palette[k + 1], phase - math.floor(phase))
    local a0 = -2 * math.pi * i / n
    local a1 = -2 * math.pi * (i + 1) / n - 0.004
    sectors[#sectors + 1] = root:polygon {
        points = {
            center,
            { center[1] + 2.35 * math.cos(a0), center[2] + 2.35 * math.sin(a0) },
            { center[1] + 2.35 * math.cos(a1), center[2] + 2.35 * math.sin(a1) },
        },
        fill = color,
        stroke = color,
        width = 1,
    }
end
local hole = root:circle {
    center = center,
    radius = 1.25,
    fill = p.paper,
    stroke = p.paper,
    width = 1,
    layer = 5,
    id = "ring-hole",
}
local cpoint = root:point { point = center, fill = p.ink, radius = 6, layer = 7, id = "center" }
scene:create(sectors, 0.82, "ease_out", 0.012)
scene:grow_from_center(hole, 0.30, "ease_out")
scene:fade_in(cpoint, { scale = 0.6, duration = 0.25, easing = "ease_out" })
scene:create(text("center", { -4.15, -0.55 }, 12, p.ink), 0.22, "ease_out")
local seam = root:arrow {
    from = center,
    to = { -1.0, -0.55 },
    tip = 14,
    color = p.accent,
    width = 3,
    id = "seam",
}
scene:create(seam, 0.62, "ease_out")
scene:create(
    text("seam / t = 0", { -0.78, -0.55 }, 12, p.accent, nil, { 0, 0.5 }),
    0.28,
    "ease_out"
)
local vector = root:arrow {
    from = center,
    to = { -1.60, -0.55 },
    tip = 14,
    color = p.ink,
    width = 3,
    id = "angle-vector",
}
scene:create(vector, 0.35, "linear")
local angle = -0.82
local c, s = math.cos(angle), math.sin(angle)
local tx = center[1] - c * center[1] + s * center[2]
local ty = center[2] - s * center[1] - c * center[2]
scene:transform(vector, { c, -s, 0, tx, s, c, 0, ty, 0, 0, 1, 0, 0, 0, 0, 1 }, 1.25, "ease_in_out")
local vend = { center[1] + 2.05 * c, center[2] + 2.05 * s }
local arcpts = {}
for i = 0, 24 do
    local a = angle * i / 24
    arcpts[#arcpts + 1] = { center[1] + 0.72 * math.cos(a), center[2] + 0.72 * math.sin(a) }
end
local arc = root:plot { points = arcpts, color = p.ink, width = 2, id = "theta-arc" }
local sample = root:point { point = vend, fill = p.ink, radius = 6, id = "angular-sample" }
scene:create(arc, 0.52, "linear")
scene:fade_in(sample, { scale = 0.6, duration = 0.25, easing = "ease_out" })
scene:create(text("atan2f(ry, rx)", { -2.55, -1.10 }, 12, p.ink), 0.25, "ease_out")
local formulas = {
    text("offset = -angle / 360", { 3.65, 1.38 }, 13, p.muted),
    text("t = atan2f(ry, rx) x (0.5 / pi) + offset", { 3.65, 0.92 }, 13, p.ink),
    text("t = t - floorf(t)", { 3.65, 0.42 }, 15, p.accent),
}
scene:create(formulas, 0.62, "ease_out", 0.10)
local cells = {}
local celln = 12
local start = 0.95
for i = 0, celln - 1 do
    local phase = i / (celln - 1) * 4
    local k = math.floor(phase) + 1
    if k > 4 then
        k = 4
    end
    local color = mix(palette[k], palette[k + 1], phase - math.floor(phase))
    cells[#cells + 1] = root:rectangle {
        center = { start + i * 0.50, -0.72 },
        size = { 0.48, 0.62 },
        fill = color,
        stroke = p.paper,
        width = 1,
        id = "ctable-" .. i,
    }
end
scene:create(cells, 0.62, "ease_out", 0.025)
scene:create(text("ctable[0 ... N-1]", { 3.70, -0.20 }, 12, p.muted), 0.25, "ease_out")
local chosen = 10
local target = { start + chosen * 0.50, -0.72 }
local sample_copy = root:point { point = vend, fill = p.ink, radius = 6, id = "sample-copy" }
scene:shift(sample_copy, { target[1] - vend[1], target[2] - vend[2] }, 0.75, "ease_in_out")
local selector = root:rectangle {
    center = target,
    size = { 0.54, 0.76 },
    fill = "#ffffff00",
    stroke = p.accent,
    width = 3,
    id = "table-selector",
}
scene:create(selector, 0.34, "ease_out")
scene:create(text("index = round((N - 1) x t)", { 3.70, -1.42 }, 14, p.accent), 0.30, "ease_out")
scene:wait(1.2)
return scene
