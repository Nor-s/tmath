local p = {
    paper = "#ffffff",
    ink = "#202124",
    muted = "#555b64",
    soft = "#6a717c",
    rule = "#d8dadd",
    solid = "#b9bec5",
    accent = "#9b3600",
    tint = "#fff0e7",
    mustard = "#b8915a",
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
local function rectpts(cx, cy, w, h)
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
text("03  /  THORVG CPU RASTERIZER", { -7.2, 3.72 }, 12, p.accent, "eyebrow", { 0, 0.5 })
text("One range per scanline", { -7.2, 3.25 }, 27, p.ink, "title", { 0, 0.5 })
text(
    "Two affine predicates reduce pixel eligibility to one half-open interval.",
    { -7.2, 2.72 },
    14,
    p.soft,
    "subtitle",
    { 0, 0.5 }
)
root:line { from = { -7.2, 2.48 }, to = { 7.2, 2.48 }, color = p.rule, width = 1 }
text(
    "[begin, end) = scanline intersection AA strip intersection forward half-plane",
    { 0, -4.05 },
    12,
    p.soft,
    "footer"
)
local c = { -3.75, 0.05 }
local seam_a = { -6.92, 1.95 }
local seam_b = { -0.58, -1.85 }
local band = root:polygon {
    points = { { -7.05, 1.73 }, { -0.71, -2.07 }, { -0.45, -1.63 }, { -6.79, 2.17 } },
    fill = "#b8915a26",
    stroke = "#b8915a00",
    id = "infinite-strip",
}
local seam_line =
    root:line { from = seam_a, to = seam_b, color = p.muted, width = 2, id = "infinite-seam" }
local ray = root:line { from = c, to = seam_b, color = p.accent, width = 4, id = "forward-ray" }
local center = root:point { point = c, fill = p.ink, radius = 6, id = "center" }
local scan = root:line {
    from = { -6.9, 0.05 },
    to = { 0, 0.05 },
    color = p.ink,
    width = 2,
    id = "device-scanline",
}
local candidate = root:polygon {
    points = rectpts(-3.75, 0.05, 1.6, 0.46),
    fill = "#b8915a29",
    stroke = p.mustard,
    width = 2,
    id = "strip-candidate",
}
scene:fade_in(band, { duration = 0.45, easing = "ease_out" })
scene:create(seam_line, 0.62, "linear")
scene:fade_in(center, { scale = 0.6, duration = 0.25, easing = "ease_out" })
scene:create(scan, 0.62, "linear")
scene:create(
    text("device scanline", { -6.45, 0.38 }, 13, p.muted, nil, { 0, 0.5 }),
    0.25,
    "ease_out"
)
scene:fade_in(candidate, { scale = 0.85, duration = 0.42, easing = "ease_out" })
scene:create(text("strip candidate", { -3.75, -0.43 }, 13, p.mustard), 0.25, "ease_out")
scene:create(ray, 0.58, "ease_out")
local candidate_copy = root:polygon {
    points = rectpts(-3.75, 0.05, 1.6, 0.46),
    fill = "#b8915a29",
    stroke = p.mustard,
    width = 2,
    id = "candidate-copy",
}
local final_range = root:polygon {
    points = rectpts(-3.35, 0.05, 0.80, 0.46),
    fill = "#9b36002e",
    stroke = p.accent,
    width = 3,
    id = "forward-range",
}
scene:replacement_transform(candidate_copy, final_range, 0.82, "ease_in_out")
scene:create(text("forward range", { -2.20, 0.57 }, 13, p.accent), 0.30, "ease_out")
local equations = {
    text("distance + i x distanceDx", { 4.85, 1.25 }, 16, p.ink),
    text("-0.5 < distance(i) < 0.5", { 4.85, 0.65 }, 16, p.mustard),
    text("seamProjection + i x seamProjectionDx", { 4.85, -0.10 }, 14, p.ink),
    text("seamProjection(i) >= 0", { 4.85, -0.68 }, 16, p.accent),
    text("Both predicates are affine in i.", { 4.85, -1.38 }, 14, p.muted),
}
scene:create(equations, 0.62, "ease_out", 0.12)
local cells, indices = {}, {}
local x0 = -5.9
for i = 0, 15 do
    cells[#cells + 1] = root:rectangle {
        center = { x0 + i * 0.58, -2.83 },
        size = { 0.56, 0.48 },
        fill = p.paper,
        stroke = p.solid,
        width = 1.5,
        id = "cell-" .. i,
    }
    indices[#indices + 1] = text(tostring(i), { x0 + i * 0.58, -3.22 }, 9, p.soft)
end
scene:create(cells, 0.62, "ease_out", 0.025)
scene:create(indices, 0.48, "ease_out", 0.025)
local strip = {}
for i = 6, 9 do
    strip[#strip + 1] = root:rectangle {
        center = { x0 + i * 0.58, -2.83 },
        size = { 0.56, 0.48 },
        fill = "#f5ebdd",
        stroke = p.mustard,
        width = 2,
        id = "strip-" .. i,
    }
end
scene:create(strip, 0.52, "ease_out", 0.08)
scene:create(
    text("strip [6, 10)", { 4.65, -2.49 }, 12, p.mustard, nil, { 0, 0.5 }),
    0.24,
    "ease_out"
)
local cutx = x0 + 7.5 * 0.58
scene:create(
    root:line {
        from = { cutx, -3.18 },
        to = { cutx, -2.48 },
        color = p.accent,
        width = 3,
        id = "ray-cut",
    },
    0.42,
    "linear"
)
scene:create(text("ray [8, 16)", { 4.65, -2.82 }, 12, p.muted, nil, { 0, 0.5 }), 0.22, "ease_out")
scene:play({
    { target = strip[1], opacity = 0 },
    { target = strip[2], opacity = 0 },
    { target = strip[3], fill = p.tint, stroke = p.accent },
    { target = strip[4], fill = p.tint, stroke = p.accent },
}, 0.62, "ease_in_out", 0)
scene:create(
    text("final [8, 10)", { 4.65, -3.18 }, 13, p.accent, "final-interval", { 0, 0.5 }),
    0.30,
    "ease_out"
)
scene:wait(1.2)
return scene
