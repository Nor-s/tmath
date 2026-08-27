local p = {
    paper = "#ffffff",
    ink = "#202124",
    muted = "#555b64",
    soft = "#6a717c",
    rule = "#d8dadd",
    solid = "#b9bec5",
    accent = "#9b3600",
    blue = "#5e7a9b",
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
text("07  /  THORVG CPU RASTERIZER", { -7.2, 3.72 }, 12, p.accent, "eyebrow", { 0, 0.5 })
text("Advance one transformed scanline", { -7.2, 3.25 }, 27, p.ink, "title", { 0, 0.5 })
text(
    "Only the first inverse-matrix column is added as the pixel index increases.",
    { -7.2, 2.82 },
    14,
    p.soft,
    "subtitle",
    { 0, 0.5 }
)
root:line { from = { -7.2, 2.48 }, to = { 7.2, 2.48 }, color = p.rule, width = 1 }
text(
    "rx += a11      ry += a21      distance(i) and seamProjection(i) are affine",
    { 0, -4.05 },
    12,
    p.soft,
    "footer"
)
local cells, centers, indices = {}, {}, {}
local start = -6.55
for i = 0, 9 do
    local x = start + i * 0.62
    cells[#cells + 1] = root:rectangle {
        center = { x, 1.15 },
        size = { 0.62, 0.62 },
        fill = p.paper,
        stroke = p.solid,
        width = 1.5,
        id = "surface-cell-" .. i,
    }
    centers[#centers + 1] =
        root:point { point = { x, 1.15 }, fill = p.blue, radius = 4, id = "surface-center-" .. i }
    indices[#indices + 1] = text(tostring(i), { x, 1.62 }, 9, p.soft)
end
scene:create(cells, 0.62, "ease_out", 0.025)
scene:create(
    text("SURFACE SCANLINE", { -6.55, 1.85 }, 13, p.muted, nil, { 0, 0.5 }),
    0.25,
    "ease_out"
)
scene:create(centers, 0.42, "ease_out", 0.025)
scene:create(indices, 0.36, "ease_out", 0.02)
local p0 = { -6.15, -0.85 }
local step = { 0.57, -0.23 }
local line = root:line {
    from = { p0[1] - 0.23, p0[2] + 0.09 },
    to = { p0[1] + 9.5 * step[1], p0[2] + 9.5 * step[2] },
    color = p.solid,
    width = 2,
    id = "gradient-line",
}
local map = root:arrow {
    from = { -3.75, 0.72 },
    to = { -3.75, -0.25 },
    tip = 12,
    color = p.accent,
    width = 3,
    id = "inverse-map",
}
scene:create({ map, line }, 0.58, "ease_out", 0.08)
scene:create({
    text("itransform", { -3.20, 0.22 }, 12, p.accent),
    text("GRADIENT-SPACE SAMPLES", { -6.55, -0.15 }, 13, p.muted, nil, { 0, 0.5 }),
}, 0.30, "ease_out", 0.05)
local mapped = {}
for i = 0, 9 do
    local source = { start + i * 0.62, 1.15 }
    local target = { p0[1] + i * step[1], p0[2] + i * step[2] }
    mapped[i + 1] = root:point { point = source, fill = p.blue, radius = 5, id = "mapped-" .. i }
    scene:shift(
        mapped[i + 1],
        { target[1] - source[1], target[2] - source[2] },
        0.12,
        "ease_in_out"
    )
end
local arrows = {}
for i = 0, 3 do
    arrows[#arrows + 1] = root:arrow {
        from = { p0[1] + i * step[1], p0[2] + i * step[2] },
        to = { p0[1] + (i + 1) * step[1], p0[2] + (i + 1) * step[2] },
        tip = 9,
        color = p.accent,
        width = 2.5,
        id = "step-" .. i,
    }
end
scene:create(arrows, 0.62, "ease_out", 0.10)
scene:create(text("xStep = {a11, a21}", { -4.72, -1.72 }, 12, p.accent), 0.28, "ease_out")
local formulas = {
    text("rx(i) = rx(0) + i x a11", { 3.90, 0.78 }, 15, p.blue),
    text("ry(i) = ry(0) + i x a21", { 3.90, 0.30 }, 15, p.blue),
    text("distance(i) = distance + i x distanceDx", { 3.90, -0.32 }, 13, p.ink),
    text("seamProjection(i) = projection + i x projectionDx", { 3.90, -0.82 }, 12, p.ink),
    text("One scanline becomes one affine line;", { 3.90, -1.72 }, 14, p.accent),
    text("its AA solution is one interval.", { 3.90, -2.10 }, 14, p.accent),
}
scene:create(formulas, 0.72, "ease_out", 0.09)
scene:wait(1.2)
return scene
