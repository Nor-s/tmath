local p = {
    paper = "#ffffff",
    ink = "#202124",
    muted = "#555b64",
    soft = "#6a717c",
    rule = "#d8dadd",
    solid = "#b9bec5",
    accent = "#9b3600",
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
local function arrowpts(a, b, sh, hd, hl)
    local dx, dy = b[1] - a[1], b[2] - a[2]
    local l = math.sqrt(dx * dx + dy * dy)
    local ux, uy = dx / l, dy / l
    local nx, ny = -uy, ux
    local jx, jy = b[1] - ux * hl, b[2] - uy * hl
    return {
        { a[1] + nx * sh, a[2] + ny * sh },
        { jx + nx * sh, jy + ny * sh },
        { jx + nx * hd, jy + ny * hd },
        b,
        { jx - nx * hd, jy - ny * hd },
        { jx - nx * sh, jy - ny * sh },
        { a[1] - nx * sh, a[2] - ny * sh },
    }
end
local function chip(cx, cy, w, h)
    local x0, x1 = cx - w / 2, cx + w / 2
    local y0, y1 = cy - h / 2, cy + h / 2
    return { { x0, y0 }, { cx, y0 }, { x1, y0 }, { x1, y1 }, { cx, y1 }, { x0, y1 }, { x0, cy } }
end
local function barpts(a, b, w)
    local dx, dy = b[1] - a[1], b[2] - a[2]
    local l = math.sqrt(dx * dx + dy * dy)
    local nx, ny = -dy / l * w / 2, dx / l * w / 2
    return {
        { a[1] + nx, a[2] + ny },
        { b[1] + nx, b[2] + ny },
        { b[1] - nx, b[2] - ny },
        {
            a[1] - nx,
            a[2] - ny,
        },
    }
end
text("09  /  THORVG CPU RASTERIZER", { -7.2, 3.72 }, 12, p.accent, "eyebrow", { 0, 0.5 })
text("fwidth is the shadow of one pixel", { -7.2, 3.25 }, 27, p.ink, "title", { 0, 0.5 })
text(
    "A transformed pixel becomes a parallelogram; its normal extent controls AA.",
    { -7.2, 2.72 },
    14,
    p.soft,
    "subtitle",
    { 0, 0.5 }
)
root:line { from = { -7.2, 2.48 }, to = { 7.2, 2.48 }, color = p.rule, width = 1 }
text("fwidth = |dot(normal, xStep)| + |dot(normal, yStep)|", { 0, -4.05 }, 12, p.soft, "footer")
local o = { -3.85, -0.55 }
local seam = { 0.940, -0.342 }
local normal = { -0.342, -0.940 }
local xv = { 1.15, -0.18 }
local yv = { -0.30, -0.96 }
local sample = { -3.308, -1.166 }
local corner = { -3.733, -0.596 }
local grid = {}
for i = 0, 9 do
    grid[#grid + 1] = root:line {
        from = { o[1] - 2.16 + i * 0.48, o[2] - 1.68 },
        to = { o[1] - 2.16 + i * 0.48, o[2] + 1.68 },
        color = p.rule,
        width = 1,
    }
end
for i = 0, 7 do
    grid[#grid + 1] = root:line {
        from = { o[1] - 2.16, o[2] - 1.68 + i * 0.48 },
        to = { o[1] + 2.16, o[2] - 1.68 + i * 0.48 },
        color = p.rule,
        width = 1,
    }
end
local seamline = root:line {
    from = { o[1] - 2.75 * seam[1], o[2] - 2.75 * seam[2] },
    to = { o[1] + 2.75 * seam[1], o[2] + 2.75 * seam[2] },
    color = p.accent,
    width = 3,
    id = "seam",
}
local normalaxis = root:arrow {
    from = { o[1] - 1.75 * normal[1], o[2] - 1.75 * normal[2] },
    to = { o[1] + 2.50 * normal[1], o[2] + 2.50 * normal[2] },
    tip = 12,
    color = p.purple,
    width = 2.5,
    id = "normal",
}
local cpoint = root:point { point = o, fill = p.ink, radius = 6, id = "center" }
scene:create(grid, 0.65, "linear", 0.015)
scene:create({ seamline, normalaxis }, 0.62, "ease_out", 0.08)
scene:create({
    text("seam: F = 0", { -1.10, -1.70 }, 11, p.accent),
    text("normal", { -4.95, -2.95 }, 12, p.purple),
    text("GRADIENT SPACE / y-down", { -6.75, 1.78 }, 12, p.muted, nil, { 0, 0.5 }),
    cpoint,
    text("C", { -3.85, -0.24 }, 12, p.ink),
}, 0.42, "ease_out", 0.04)
local corners = {
    corner,
    { corner[1] + xv[1], corner[2] + xv[2] },
    { corner[1] + xv[1] + yv[1], corner[2] + xv[2] + yv[2] },
    { corner[1] + yv[1], corner[2] + yv[2] },
}
local footprint = root:polygon {
    points = corners,
    fill = "#5e7a9b1f",
    stroke = p.blue,
    width = 2.5,
    id = "pixel-footprint",
}
local spoint = root:point { point = sample, fill = p.ink, radius = 6, id = "sample" }
local offset =
    root:arrow { from = o, to = sample, tip = 11, color = p.purple, width = 2.5, id = "offset" }
scene:create({ footprint, spoint, offset }, 0.58, "ease_out", 0.08)
scene:create(text("fixed sample center P", { -3.30, -1.78 }, 10, p.ink), 0.24, "ease_out")
local xend = { corner[1] + xv[1], corner[2] + xv[2] }
local yend = { corner[1] + yv[1], corner[2] + yv[2] }
local xarrow = root:polygon {
    points = arrowpts(corner, xend, 0.025, 0.10, 0.22),
    fill = p.blue,
    stroke = p.blue,
    width = 1,
    id = "x-step",
}
local yarrow = root:polygon {
    points = arrowpts(corner, yend, 0.025, 0.10, 0.22),
    fill = p.mustard,
    stroke = p.mustard,
    width = 1,
    id = "y-step",
}
scene:create({ xarrow, yarrow }, 0.52, "ease_out", 0.10)
scene:create(
    { text("xStep", { -2.95, -0.95 }, 11, p.blue), text("yStep", { -4.18, -1.18 }, 11, p.mustard) },
    0.26,
    "ease_out",
    0.05
)
local cp = { -3.851, -0.553 }
local xp = { -3.774, -0.342 }
local yp = { -4.195, -1.497 }
local minp = xp
local maxp = yp
local guides = {
    root:line { from = corner, to = cp, color = p.soft, width = 1 },
    root:line { from = xend, to = xp, color = p.blue, width = 1 },
    root:line { from = yend, to = yp, color = p.mustard, width = 1 },
}
local shadow = root:polygon {
    points = barpts(minp, maxp, 0.16),
    fill = p.purple,
    stroke = p.purple,
    width = 1,
    id = "fwidth-shadow",
}
scene:create(guides, 0.48, "linear", 0.06)
scene:create(shadow, 0.52, "linear")
local xcopy = root:polygon {
    points = arrowpts(corner, xend, 0.025, 0.10, 0.22),
    fill = p.blue,
    stroke = p.blue,
    width = 1,
}
local xproj = root:polygon {
    points = arrowpts(cp, xp, 0.025, 0.10, 0.22),
    fill = p.blue,
    stroke = p.blue,
    width = 1,
    id = "dfdx-projection",
}
scene:replacement_transform(xcopy, xproj, 0.62, "ease_in_out")
local ycopy = root:polygon {
    points = arrowpts(corner, yend, 0.025, 0.10, 0.22),
    fill = p.mustard,
    stroke = p.mustard,
    width = 1,
}
local yproj = root:polygon {
    points = arrowpts(cp, yp, 0.025, 0.10, 0.22),
    fill = p.mustard,
    stroke = p.mustard,
    width = 1,
    id = "dfdy-projection",
}
scene:replacement_transform(ycopy, yproj, 0.62, "ease_in_out")
scene:create({
    text("dFdx = -0.22", { -2.65, 0.58 }, 10, p.blue),
    text("dFdy = +1.00", { -5.62, -1.72 }, 10, p.mustard),
}, 0.32, "ease_out", 0.05)
text("SIGNED NORMAL PROJECTIONS", { 1.20, 1.78 }, 12, p.muted, "formula-title", { 0, 0.5 })
local formulas = {
    text("dFdx = dot(normal, xStep) = -0.22", { 4.10, 1.30 }, 12, p.blue),
    text("dFdy = dot(normal, yStep) = +1.00", { 4.10, 0.88 }, 12, p.mustard),
    text("fwidth = |dFdx| + |dFdy| = 1.23", { 4.10, 0.42 }, 13, p.accent),
}
local xfcopy = root:polygon {
    points = arrowpts(cp, xp, 0.025, 0.10, 0.22),
    fill = p.blue,
    stroke = p.blue,
    width = 1,
}
local xtoken = root:polygon {
    points = chip(1.35, 1.30, 0.30, 0.14),
    fill = p.blue,
    stroke = p.blue,
    width = 1,
}
scene:replacement_transform(xfcopy, xtoken, 0.55, "ease_in_out")
scene:create(formulas[1], 0.25, "ease_out")
local yfcopy = root:polygon {
    points = arrowpts(cp, yp, 0.025, 0.10, 0.22),
    fill = p.mustard,
    stroke = p.mustard,
    width = 1,
}
local ytoken = root:polygon {
    points = chip(1.35, 0.88, 0.30, 0.14),
    fill = p.mustard,
    stroke = p.mustard,
    width = 1,
}
scene:replacement_transform(yfcopy, ytoken, 0.55, "ease_in_out")
scene:create(formulas[2], 0.25, "ease_out")
local xbcopy = root:polygon {
    points = chip(1.35, 1.30, 0.30, 0.14),
    fill = p.blue,
    stroke = p.blue,
    width = 1,
}
local xbar = root:polygon {
    points = chip(1.70, -0.12, 0.50, 0.16),
    fill = p.blue,
    stroke = p.blue,
    width = 1,
}
scene:replacement_transform(xbcopy, xbar, 0.48, "ease_in_out")
local ybcopy = root:polygon {
    points = chip(1.35, 0.88, 0.30, 0.14),
    fill = p.mustard,
    stroke = p.mustard,
    width = 1,
}
local ybar = root:polygon {
    points = chip(3.08, -0.12, 2.26, 0.16),
    fill = p.mustard,
    stroke = p.mustard,
    width = 1,
}
scene:replacement_transform(ybcopy, ybar, 0.48, "ease_in_out")
scene:create(
    { formulas[3], text("0.22 + 1.00 = 1.23", { 4.65, -0.12 }, 12, p.accent) },
    0.35,
    "ease_out",
    0.06
)
local fproj = { o[1] + 0.393 * normal[1], o[2] + 0.393 * normal[2] }
local offcopy = root:polygon {
    points = arrowpts(o, sample, 0.025, 0.10, 0.22),
    fill = p.purple,
    stroke = p.purple,
    width = 1,
}
local ftarget = root:polygon {
    points = arrowpts(o, fproj, 0.025, 0.10, 0.22),
    fill = p.ink,
    stroke = p.ink,
    width = 1,
    id = "signed-f",
}
scene:replacement_transform(offcopy, ftarget, 0.58, "ease_in_out")
scene:create({
    text("NORMALIZE THE SIGNED DISTANCE", { 1.20, -0.82 }, 12, p.muted, nil, { 0, 0.5 }),
    text("invFwidth = 1 / 1.23 = 0.81", { 1.20, -1.18 }, 12, p.accent, nil, { 0, 0.5 }),
    text("distance = 0.39 x 0.81 = +0.32", { 1.20, -1.52 }, 12, p.ink, nil, { 0, 0.5 }),
}, 0.48, "ease_out", 0.06)
local shadowcopy = root:polygon {
    points = barpts(minp, maxp, 0.16),
    fill = p.purple,
    stroke = p.purple,
    width = 1,
}
local physical = root:polygon {
    points = { { 1.55, -2.13 }, { 6.35, -2.13 }, { 6.35, -2.03 }, { 1.55, -2.03 } },
    fill = p.solid,
    stroke = p.solid,
    width = 1,
    id = "physical-ruler",
}
scene:replacement_transform(shadowcopy, physical, 0.62, "ease_in_out")
local rulercopy = root:polygon {
    points = { { 1.55, -2.13 }, { 6.35, -2.13 }, { 6.35, -2.03 }, { 1.55, -2.03 } },
    fill = p.solid,
    stroke = p.solid,
    width = 1,
}
local normalized = root:polygon {
    points = { { 1.55, -2.92 }, { 6.35, -2.92 }, { 6.35, -2.80 }, { 1.55, -2.80 } },
    fill = p.accent,
    stroke = p.accent,
    width = 1,
    id = "normalized-ruler",
}
scene:replacement_transform(rulercopy, normalized, 0.68, "ease_in_out")
scene:create({
    text("-0.5", { 1.55, -3.16 }, 10, p.accent),
    text("0", { 3.95, -3.16 }, 10, p.accent),
    text("+0.32", { 5.49, -2.60 }, 10, p.blue),
    text("+0.5", { 6.35, -3.16 }, 10, p.accent),
    text("-0.5 < +0.32 < +0.5  ->  seam AA", { 4.0, -3.52 }, 13, p.accent),
}, 0.52, "ease_out", 0.05)
scene:wait(1.2)
return scene
