local p = {
    paper = "#ffffff",
    ink = "#202124",
    muted = "#555b64",
    soft = "#6a717c",
    rule = "#d8dadd",
    solid = "#b9bec5",
    accent = "#9b3600",
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
local function rect(cx, cy, w, h)
    return {
        { cx - w / 2, cy - h / 2 },
        { cx + w / 2, cy - h / 2 },
        { cx + w / 2, cy + h / 2 },
        {
            cx - w / 2,
            cy + h / 2,
        },
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
text("04  /  THORVG CPU RASTERIZER", { -7.2, 3.72 }, 12, p.accent, "eyebrow", { 0, 0.5 })
text("Seam endpoint reconstruction", { -7.2, 3.25 }, 27, p.ink, "title", { 0, 0.5 })
text(
    "begin is the first eligible pixel; end is the one-past index returned by _conicAARange.",
    { -7.2, 2.72 },
    14,
    p.soft,
    "subtitle",
    { 0, 0.5 }
)
root:line { from = { -7.2, 2.48 }, to = { 7.2, 2.48 }, color = p.rule, width = 1 }
text(
    "outside range: angular lookup    inside range: endpoint blend",
    { 0, -4.05 },
    12,
    p.soft,
    "footer"
)
local end_swatch = root:rectangle {
    center = { -5.7, 1.2 },
    size = { 0.72, 0.72 },
    fill = p.purple,
    stroke = p.solid,
    width = 1,
    id = "rgba-end",
}
local begin_swatch = root:rectangle {
    center = { -3.55, 1.2 },
    size = { 0.72, 0.72 },
    fill = p.orange,
    stroke = p.solid,
    width = 1,
    id = "rgba-begin",
}
local swatch_labels = {
    text("rgbaEnd", { -5.7, 0.66 }, 13, p.purple),
    text("rgbaBegin", { -3.55, 0.66 }, 13, p.orange),
}
local blend = root:arrow {
    from = { -5.15, 1.2 },
    to = { -4.1, 1.2 },
    tip = 11,
    color = p.muted,
    width = 2,
    id = "blend-direction",
}
scene:create(
    { end_swatch, swatch_labels[1], blend, begin_swatch, swatch_labels[2] },
    0.62,
    "ease_out",
    0.08
)
local formulas = {
    text("dist = 255 x (distance + 0.5)", { 2.60, 1.40 }, 17, p.accent, "distance-map"),
    text(
        "color = INTERPOLATE(rgbaBegin, rgbaEnd, dist)",
        { 2.60, 1.00 },
        14,
        p.ink,
        "blend-formula"
    ),
}
scene:create(formulas, 0.50, "ease_out", 0.08)
text("NORMAL LOOKUP", { -5.95, -0.42 }, 13, p.muted, "normal-label", { 0, 0.5 })
text("SEAM AA", { -5.95, -2.10 }, 13, p.accent, "aa-label", { 0, 0.5 })
local before = {}
local before_colors = {}
local count = 15
local w = 0.72
local x0 = -4.9
for i = 0, count - 1 do
    local color
    if i < 7 then
        color = mix(p.purple, "#73778c", i / 6)
    else
        color = mix(p.orange, "#f7b442", (i - 7) / 7)
    end
    before_colors[i + 1] = color
    before[i + 1] = root:polygon {
        points = rect(x0 + i * w, -0.95, w, 0.72),
        fill = color,
        stroke = p.paper,
        width = 1,
        id = "lookup-" .. i,
    }
end
local seam_top = root:line {
    from = { x0 + 6.25 * w, -1.46 },
    to = { x0 + 6.75 * w, -0.44 },
    color = p.accent,
    width = 3,
    id = "lookup-seam",
}
scene:create(before, 0.68, "ease_out", 0.025)
scene:create(seam_top, 0.45, "linear")
local after = {}
for i = 0, count - 1 do
    local source_points = rect(x0 + i * w, -0.95, w, 0.72)
    local source_color = before_colors[i + 1]
    local target_color = source_color
    if i == 6 then
        source_points = rect(-5.7, 1.2, 0.72, 0.72)
        source_color = p.purple
        target_color = mix(p.purple, p.orange, 0.13)
    elseif i == 7 then
        source_points = rect(-3.55, 1.2, 0.72, 0.72)
        source_color = p.orange
        target_color = mix(p.purple, p.orange, 0.87)
    end
    local copy = root:polygon {
        points = source_points,
        fill = source_color,
        stroke = p.paper,
        width = 1,
        id = "copy-" .. i,
    }
    after[i + 1] = root:polygon {
        points = rect(x0 + i * w, -2.63, w, 0.72),
        fill = target_color,
        stroke = p.paper,
        width = 1,
        id = "aa-" .. i,
    }
    scene:replacement_transform(copy, after[i + 1], 0.12, "ease_in_out")
end
local seam_bottom = root:line {
    from = { x0 + 6.25 * w, -3.14 },
    to = { x0 + 6.75 * w, -2.12 },
    color = p.accent,
    width = 3,
    id = "aa-seam",
}
scene:create(seam_bottom, 0.42, "linear")
local range = root:rectangle {
    center = { x0 + 6.5 * w, -2.63 },
    size = { 1.44, 0.88 },
    fill = "#ffffff00",
    stroke = p.accent,
    width = 3,
    id = "aa-range",
}
local notes = {
    text("normalized distance", { x0 + 4.15 * w, -2.10 }, 10, p.muted),
    text("-0.37", { x0 + 6 * w, -2.10 }, 10, p.purple),
    text("+0.37", { x0 + 7 * w, -2.10 }, 10, p.orange),
    text("[begin, end) = [6, 8)", { x0 + 6.5 * w, -3.34 }, 13, p.accent),
    text("all other pixels keep angular ColorTable lookup", { 4.55, -3.43 }, 12, p.muted),
}
scene:create(range, 0.42, "ease_out")
scene:create(notes, 0.48, "ease_out", 0.05)
scene:wait(1.2)
return scene
