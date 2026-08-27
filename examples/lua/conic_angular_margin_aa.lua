local p = {
    paper = "#ffffff",
    ink = "#202124",
    muted = "#555b64",
    soft = "#6a717c",
    rule = "#d8dadd",
    accent = "#9b3600",
    blue = "#5e7a9b",
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
text("08  /  THORVG CPU RASTERIZER", { -7.2, 3.72 }, 12, p.accent, "eyebrow", { 0, 0.5 })
text("Angular margin grows with radius", { -7.2, 3.25 }, 27, p.ink, "title", { 0, 0.5 })
text(
    "A fixed ColorTable transition becomes a widening sector; footprint AA stays one pixel wide.",
    { -7.2, 2.72 },
    14,
    p.soft,
    "subtitle",
    { 0, 0.5 }
)
root:line { from = { -7.2, 2.48 }, to = { 7.2, 2.48 }, color = p.rule, width = 1 }
text(
    "parameter-space blur: length(r) = r deltaTheta      fill-stage AA: width is about one device pixel",
    { 0, -4.05 },
    12,
    p.soft,
    "footer"
)
local c = { -4.55, -0.70 }
local d = 13 * math.pi / 180
local r = 3.2
local e0 = { c[1] + r, c[2] }
local e1 = { c[1] + r * math.cos(d), c[2] + r * math.sin(d) }
local wedge = root:polygon {
    points = { c, e0, e1 },
    fill = "#b8915a33",
    stroke = "#b8915a00",
    id = "angular-wedge",
}
local ray0 = root:line { from = c, to = e0, color = p.accent, width = 3, id = "ray-zero" }
local ray1 = root:line { from = c, to = e1, color = p.mustard, width = 3, id = "ray-delta" }
local center = root:point { point = c, fill = p.ink, radius = 6, id = "angular-center" }
scene:create(
    { text("FIXED ANGULAR MARGIN", { -6.65, 1.65 }, 13, p.muted, nil, { 0, 0.5 }), center, ray0 },
    0.52,
    "ease_out",
    0.08
)
scene:fade_in(wedge, { duration = 0.42, easing = "ease_out" })
scene:create(ray1, 0.52, "linear")
scene:create(text("deltaTheta", { -2.75, -0.45 }, 13, p.mustard), 0.25, "ease_out")
local function arc(radius, color, id)
    local pts = {}
    for i = 0, 24 do
        local a = d * i / 24
        pts[#pts + 1] = { c[1] + radius * math.cos(a), c[2] + radius * math.sin(a) }
    end
    return root:plot { points = pts, color = color, width = 5, id = id }
end
local near = arc(1.15, p.blue, "near-arc")
local far = arc(2.85, p.accent, "far-arc")
scene:create({ near, far }, 0.72, "ease_out", 0.15)
scene:create({
    text("r1 deltaTheta", { -3.40, -1.08 }, 11, p.blue),
    text("r2 deltaTheta", { -1.80, 0.08 }, 12, p.accent),
}, 0.32, "ease_out", 0.06)
local rc = { 1.05, -0.70 }
local re = { 6.55, -0.70 }
local strip = root:polygon {
    points = { { rc[1], -0.42 }, { re[1], -0.42 }, { re[1], -0.98 }, { rc[1], -0.98 } },
    fill = "#9b360021",
    stroke = "#9b360000",
    id = "footprint-strip",
}
local seam = root:line { from = rc, to = re, color = p.accent, width = 3, id = "footprint-seam" }
scene:create(
    text("PIXEL-FOOTPRINT AA", { 0.95, 1.65 }, 13, p.muted, nil, { 0, 0.5 }),
    0.25,
    "ease_out"
)
scene:fade_in(strip, { duration = 0.42, easing = "ease_out" })
scene:create(seam, 0.55, "linear")
local pixels = {}
local offsets = { -0.18, 0.10, -0.08, 0.16 }
for i = 1, 4 do
    pixels[#pixels + 1] = root:rectangle {
        center = { 2.0 + (i - 1) * 1.18, -0.70 + offsets[i] },
        size = { 0.56, 0.56 },
        fill = "#5e7a9b0f",
        stroke = p.blue,
        width = 2,
        id = "pixel-" .. i,
    }
end
scene:create(pixels, 0.62, "ease_out", 0.10)
local mark = root:line {
    from = { 6.25, -0.98 },
    to = { 6.25, -0.42 },
    color = p.blue,
    width = 4,
    id = "pixel-width",
}
scene:create(mark, 0.42, "linear")
scene:create(text("about 1 pixel", { 6.78, -0.70 }, 12, p.blue), 0.25, "ease_out")
local formulas = {
    text("length(r) = r deltaTheta", { -4.50, -2.30 }, 16, p.accent),
    text("Blur width increases with distance from center.", { -4.50, -2.72 }, 12, p.muted),
    text("-0.5 < distance < 0.5", { 3.85, -2.30 }, 15, p.accent),
    text("The test follows the transformed device-pixel footprint.", { 3.85, -2.72 }, 12, p.muted),
}
scene:create(formulas, 0.52, "ease_out", 0.08)
scene:wait(1.2)
return scene
