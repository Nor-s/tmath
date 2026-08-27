local p = {
    paper = "#ffffff",
    ink = "#202124",
    muted = "#555b64",
    soft = "#6a717c",
    rule = "#d8dadd",
    solid = "#b9bec5",
    accent = "#9b3600",
    tint = "#fff0e7",
    blue = "#5e7a9b",
    mustard = "#b8915a",
    purple = "#6e6479",
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
local function arrow_points(a, b, shaft, head, headlen)
    local dx, dy = b[1] - a[1], b[2] - a[2]
    local len = math.sqrt(dx * dx + dy * dy)
    local ux, uy = dx / len, dy / len
    local nx, ny = -uy, ux
    local jx, jy = b[1] - ux * headlen, b[2] - uy * headlen
    return {
        { a[1] + nx * shaft, a[2] + ny * shaft },
        { jx + nx * shaft, jy + ny * shaft },
        { jx + nx * head, jy + ny * head },
        b,
        { jx - nx * head, jy - ny * head },
        { jx - nx * shaft, jy - ny * shaft },
        { a[1] - nx * shaft, a[2] - ny * shaft },
    }
end
local function chip(cx, cy, w, h)
    local x0, x1 = cx - w / 2, cx + w / 2
    local y0, y1 = cy - h / 2, cy + h / 2
    return { { x0, y0 }, { cx, y0 }, { x1, y0 }, { x1, y1 }, { cx, y1 }, { x0, y1 }, { x0, cy } }
end
text("02  /  THORVG CPU RASTERIZER", { -7.2, 3.72 }, 12, p.accent, "eyebrow", { 0, 0.5 })
text("Prepared seam geometry", { -7.2, 3.25 }, 27, p.ink, "title", { 0, 0.5 })
text(
    "The seam, normal, and pixel-footprint derivatives are computed once per update.",
    { -7.2, 2.72 },
    14,
    p.soft,
    "subtitle",
    { 0, 0.5 }
)
root:line { from = { -7.2, 2.48 }, to = { 7.2, 2.48 }, color = p.rule, width = 1 }
text(
    "seam = {cos(angle), sin(angle)}    normal = {-seam.y, seam.x}    invFwidth = 1 / fwidth",
    { 0, -4.05 },
    12,
    p.soft,
    "footer"
)

local center = { -4.05, -0.65 }
local grid = {}
for i = 0, 11 do
    grid[#grid + 1] = root:line {
        from = { -6.80 + i * 0.5, -2.65 },
        to = { -6.80 + i * 0.5, 1.35 },
        color = p.rule,
        width = 1,
    }
end
for i = 0, 8 do
    grid[#grid + 1] = root:line {
        from = { -6.80, -2.65 + i * 0.5 },
        to = { -1.30, -2.65 + i * 0.5 },
        color = p.rule,
        width = 1,
    }
end
local axes = {
    root:line {
        from = { -6.80, center[2] },
        to = { -1.30, center[2] },
        color = p.solid,
        width = 1.3,
    },
    root:line { from = { center[1], -2.65 }, to = { center[1], 1.35 }, color = p.solid, width = 1.3 },
}
text("GRADIENT SPACE / y-down", { -6.85, 1.98 }, 13, p.muted, "space-label", { 0, 0.5 })
local cpoint = root:point { point = center, fill = p.ink, radius = 6, id = "center" }
text("{cx, cy}", { -4.63, -0.35 }, 13, p.ink)
local seam_end = { -1.31, -2.10 }
local normal_end = { -5.15, -2.72 }
local band = root:polygon {
    points = { { -4.13, -0.80 }, { -1.39, -2.25 }, { -1.23, -1.95 }, { -3.97, -0.50 } },
    fill = "#9b360026",
    stroke = "#9b360000",
    id = "seam-band",
}
local seam =
    root:arrow { from = center, to = seam_end, tip = 15, color = p.accent, width = 4, id = "seam" }
local normal = root:arrow {
    from = center,
    to = normal_end,
    tip = 13,
    color = p.muted,
    width = 3,
    id = "normal",
}
local labels = {
    text("seam", { -1.04, -2.10 }, 15, p.accent),
    text("normal", { -5.32, -2.95 }, 14, p.muted),
    text("angle = 28°", { -3.02, -0.43 }, 13, p.accent),
    text("dot(normal, seam) = 0", { -6.72, -3.24 }, 12, p.muted, nil, { 0, 0.5 }),
}
local fo = { -6.10, 0.88 }
local xv = { 1.10, -0.28 }
local yv = { -0.28, -0.96 }
local sample = { -5.69, 0.26 }
local footprint = root:polygon {
    points = {
        fo,
        { fo[1] + xv[1], fo[2] + xv[2] },
        { fo[1] + xv[1] + yv[1], fo[2] + xv[2] + yv[2] },
        { fo[1] + yv[1], fo[2] + yv[2] },
    },
    fill = p.tint,
    stroke = p.accent,
    width = 2,
    id = "footprint",
}
local sample_point = root:point { point = sample, fill = p.purple, radius = 6, id = "sample" }
local offset =
    root:arrow { from = center, to = sample, tip = 12, color = p.purple, width = 3, id = "offset" }
local xstep = root:polygon {
    points = arrow_points(fo, { fo[1] + xv[1], fo[2] + xv[2] }, 0.025, 0.10, 0.23),
    fill = p.blue,
    stroke = p.blue,
    width = 1,
    id = "x-step",
}
local ystep = root:polygon {
    points = arrow_points(fo, { fo[1] + yv[1], fo[2] + yv[2] }, 0.025, 0.10, 0.23),
    fill = p.mustard,
    stroke = p.mustard,
    width = 1,
    id = "y-step",
}
local footprint_labels = {
    text("xStep", { -4.83, 0.85 }, 13, p.blue),
    text("yStep", { -6.60, -0.22 }, 13, p.mustard),
    text("sample center", { -5.05, 0.26 }, 10, p.purple),
    text("offset = {rx, ry}", { -5.15, -0.82 }, 11, p.purple),
}

scene:create(grid, 0.65, "linear", 0.018)
scene:create(axes, 0.30, "ease_out", 0.05)
scene:fade_in(cpoint, { scale = 0.6, duration = 0.28, easing = "ease_out" })
scene:fade_in(band, { duration = 0.35, easing = "ease_out" })
scene:create({ seam, normal }, 0.72, "ease_out", 0.12)
scene:create(labels, 0.42, "ease_out", 0.05)
scene:create(offset, 0.65, "ease_out")
scene:create({ footprint, sample_point }, 0.45, "ease_out", 0.08)
scene:create({ xstep, ystep }, 0.58, "ease_out", 0.12)
scene:create(footprint_labels, 0.35, "ease_out", 0.04)

local dfdx = -0.28
local dfdy = 0.95
local fwidth = 1.23
local inv = 0.81
local f = -1.36
local distance = -1.10
local projection_axis = root:line {
    from = { -6.58, -0.08 },
    to = { -5.68, 1.72 },
    color = p.solid,
    width = 1.5,
    id = "projection-axis",
}
scene:create(projection_axis, 0.50, "linear")
local xp = { -5.98, 1.18 }
local yp = { -5.72, 1.66 }
local xcopy = root:polygon {
    points = arrow_points(fo, { fo[1] + xv[1], fo[2] + xv[2] }, 0.025, 0.10, 0.23),
    fill = p.blue,
    stroke = p.blue,
    width = 1,
    id = "x-step-copy",
}
local xproj = root:polygon {
    points = arrow_points(fo, xp, 0.025, 0.10, 0.23),
    fill = p.blue,
    stroke = p.blue,
    width = 1,
    id = "dfdx-projection",
}
scene:replacement_transform(xcopy, xproj, 0.72, "ease_in_out")
scene:create(text("dFdx = -0.28", { -5.62, 1.14 }, 11, p.blue), 0.22, "ease_out")
local ycopy = root:polygon {
    points = arrow_points(fo, { fo[1] + yv[1], fo[2] + yv[2] }, 0.025, 0.10, 0.23),
    fill = p.mustard,
    stroke = p.mustard,
    width = 1,
    id = "y-step-copy",
}
local yproj = root:polygon {
    points = arrow_points(fo, yp, 0.025, 0.10, 0.23),
    fill = p.mustard,
    stroke = p.mustard,
    width = 1,
    id = "dfdy-projection",
}
scene:replacement_transform(ycopy, yproj, 0.72, "ease_in_out")
scene:create(text("dFdy = +0.95", { -5.05, 1.66 }, 11, p.mustard), 0.22, "ease_out")

text("PREPARED SCALARS", { 1.60, 1.82 }, 13, p.soft, "scalar-title", { 0, 0.5 })
local formulas = {
    text("dFdx = dot(normal, xStep)", { 4.15, 1.30 }, 14, p.blue, "dfdx-formula"),
    text("dFdy = dot(normal, yStep)", { 4.15, 0.86 }, 14, p.mustard, "dfdy-formula"),
    text("fwidth = |dFdx| + |dFdy| = 1.23", { 4.15, 0.36 }, 14, p.accent, "fwidth-formula"),
    text("invFwidth = 1 / 1.23 = 0.81", { 4.15, -0.18 }, 13, p.accent, "inverse-formula"),
    text("F = dot(normal, offset) = -1.36", { 4.15, -0.62 }, 13, p.purple, "f-formula"),
    text("distance = F x invFwidth = -1.10", { 4.15, -1.06 }, 13, p.ink, "distance-formula"),
}
local xformula_copy = root:polygon {
    points = arrow_points(fo, xp, 0.025, 0.10, 0.23),
    fill = p.blue,
    stroke = p.blue,
    width = 1,
    id = "dfdx-copy",
}
local xtoken = root:polygon {
    points = chip(1.65, 1.30, 0.35, 0.16),
    fill = p.blue,
    stroke = p.blue,
    width = 1,
    id = "dfdx-token",
}
scene:replacement_transform(xformula_copy, xtoken, 0.65, "ease_in_out")
scene:create(formulas[1], 0.28, "ease_out")
local yformula_copy = root:polygon {
    points = arrow_points(fo, yp, 0.025, 0.10, 0.23),
    fill = p.mustard,
    stroke = p.mustard,
    width = 1,
    id = "dfdy-copy",
}
local ytoken = root:polygon {
    points = chip(1.65, 0.86, 0.35, 0.16),
    fill = p.mustard,
    stroke = p.mustard,
    width = 1,
    id = "dfdy-token",
}
scene:replacement_transform(yformula_copy, ytoken, 0.65, "ease_in_out")
scene:create(formulas[2], 0.28, "ease_out")
local xsumcopy = root:polygon {
    points = chip(1.65, 1.30, 0.35, 0.16),
    fill = p.blue,
    stroke = p.blue,
    width = 1,
}
local xsumtarget = root:polygon {
    points = chip(1.64, 0.36, 0.22, 0.16),
    fill = p.blue,
    stroke = p.blue,
    width = 1,
}
scene:replacement_transform(xsumcopy, xsumtarget, 0.48, "ease_in_out")
local ysumcopy = root:polygon {
    points = chip(1.65, 0.86, 0.35, 0.16),
    fill = p.mustard,
    stroke = p.mustard,
    width = 1,
}
local ysumtarget = root:polygon {
    points = chip(1.87, 0.36, 0.24, 0.16),
    fill = p.mustard,
    stroke = p.mustard,
    width = 1,
}
scene:replacement_transform(ysumcopy, ysumtarget, 0.48, "ease_in_out")
scene:create(formulas[3], 0.30, "ease_out")
scene:create({ formulas[4], formulas[5], formulas[6] }, 0.48, "ease_out", 0.08)

local physical = root:polygon {
    points = { { 1.85, -1.76 }, { 6.45, -1.76 }, { 6.45, -1.68 }, { 1.85, -1.68 } },
    fill = p.solid,
    stroke = p.solid,
    width = 1,
    id = "physical-ruler",
}
local psample =
    root:point { point = { -0.91, -1.72 }, fill = p.purple, radius = 6, id = "physical-sample" }
scene:create(physical, 0.50, "linear")
scene:fade_in(psample, { scale = 0.7, duration = 0.30, easing = "ease_out" })
local ruler_copy = root:polygon {
    points = { { 1.85, -1.76 }, { 6.45, -1.76 }, { 6.45, -1.68 }, { 1.85, -1.68 } },
    fill = p.solid,
    stroke = p.solid,
    width = 1,
}
local normalized = root:polygon {
    points = { { 1.85, -2.77 }, { 6.45, -2.77 }, { 6.45, -2.67 }, { 1.85, -2.67 } },
    fill = p.accent,
    stroke = p.accent,
    width = 1,
    id = "normalized-ruler",
}
scene:replacement_transform(ruler_copy, normalized, 0.72, "ease_in_out")
scene:create({
    text("-0.5", { 1.85, -3.00 }, 11, p.accent),
    text("0", { 4.15, -3.00 }, 11, p.accent),
    text("+0.5", { 6.45, -3.00 }, 11, p.accent),
    text("distance = -1.10", { 4.15, -3.35 }, 13, p.accent),
}, 0.42, "ease_out", 0.05)
scene:wait(1.1)
return scene
