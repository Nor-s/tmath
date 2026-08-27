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
local function grid(origin, a, b)
    local lines = {}
    local step = 0.58
    for i = 0, 8 do
        local x = -2.32 + i * step
        lines[#lines + 1] = root:line {
            from = { origin[1] + a * x + b * -1.74, origin[2] + (-0.22 * x) + 0.86 * -1.74 },
            to = { origin[1] + a * x + b * 1.74, origin[2] + (-0.22 * x) + 0.86 * 1.74 },
            color = p.rule,
            width = 1,
        }
    end
    for i = 0, 6 do
        local y = -1.74 + i * step
        lines[#lines + 1] = root:line {
            from = { origin[1] + a * -2.32 + b * y, origin[2] + (-0.22 * -2.32) + 0.86 * y },
            to = { origin[1] + a * 2.32 + b * y, origin[2] + (-0.22 * 2.32) + 0.86 * y },
            color = p.rule,
            width = 1,
        }
    end
    return lines
end
text("05  /  THORVG CPU RASTERIZER", { -7.2, 3.72 }, 12, p.accent, "eyebrow", { 0, 0.5 })
text("Pull a Surface sample into Gradient Space", { -7.2, 3.25 }, 27, p.ink, "title", { 0, 0.5 })
text(
    "The composed forward transform is inverted once; every pixel reuses its coefficients.",
    { -7.2, 2.72 },
    14,
    p.soft,
    "subtitle",
    { 0, 0.5 }
)
root:line { from = { -7.2, 2.48 }, to = { 7.2, 2.48 }, color = p.rule, width = 1 }
text("{rx, ry} = itransform(x + 0.5, y + 0.5) - center", { 0, -4.05 }, 12, p.soft, "footer")
local so = { -4.75, -0.45 }
local go = { 4.4, -0.45 }
local surface_grid = grid(so, 1, 0)
local gradient_grid = grid(go, 1.08, 0.30)
local labels = {
    text("SURFACE COORDINATES", { -6.75, 1.75 }, 13, p.muted, nil, { 0, 0.5 }),
    text("GRADIENT SPACE", { 2.15, 1.75 }, 13, p.muted, nil, { 0, 0.5 }),
}
scene:create(surface_grid, 0.70, "linear", 0.02)
scene:create(labels[1], 0.24, "ease_out")
scene:create(gradient_grid, 0.70, "linear", 0.02)
scene:create(labels[2], 0.24, "ease_out")
local ss = { -3.88, -0.16 }
local source_pixel = root:polygon {
    points = { { -4.17, -0.45 }, { -3.59, -0.45 }, { -3.59, 0.13 }, { -4.17, 0.13 } },
    fill = "#5e7a9b14",
    stroke = p.blue,
    width = 2.5,
    id = "surface-pixel",
}
local source_dot = root:point { point = ss, fill = p.blue, radius = 7, id = "surface-sample" }
scene:create({ source_pixel, source_dot }, 0.45, "ease_out", 0.08)
scene:create(
    text("pixel center: {x + 0.5, y + 0.5}", { -3.88, -0.75 }, 11, p.blue),
    0.30,
    "ease_out"
)
local map = {
    text("transform = pTransform x conic.transform()", { 0, 1.05 }, 13, p.ink),
    text("itransform = inverse(transform)", { 0, 0.48 }, 14, p.accent),
}
local pull = root:arrow {
    from = { -1.25, -0.28 },
    to = { 1.25, -0.28 },
    tip = 13,
    color = p.accent,
    width = 3,
    id = "inverse-arrow",
}
scene:create({ map[1], map[2], pull }, 0.62, "ease_out", 0.10)
scene:create(text("itransform", { 0, 0.04 }, 12, p.accent), 0.22, "ease_out")
local gc = { 3.85, -0.20 }
local gs = { 5.43, -0.39 }
local xstep = { 0.626, -0.128 }
local ystep = { 0.174, 0.499 }
local target_pixel = root:polygon {
    points = {
        { gs[1] - 0.5 * xstep[1] - 0.5 * ystep[1], gs[2] - 0.5 * xstep[2] - 0.5 * ystep[2] },
        { gs[1] + 0.5 * xstep[1] - 0.5 * ystep[1], gs[2] + 0.5 * xstep[2] - 0.5 * ystep[2] },
        { gs[1] + 0.5 * xstep[1] + 0.5 * ystep[1], gs[2] + 0.5 * xstep[2] + 0.5 * ystep[2] },
        { gs[1] - 0.5 * xstep[1] + 0.5 * ystep[1], gs[2] - 0.5 * xstep[2] + 0.5 * ystep[2] },
    },
    fill = "#5e7a9b14",
    stroke = p.blue,
    width = 2.5,
    id = "gradient-pixel",
}
local pixel_copy = root:polygon {
    points = { { -4.17, -0.45 }, { -3.59, -0.45 }, { -3.59, 0.13 }, { -4.17, 0.13 } },
    fill = "#5e7a9b14",
    stroke = p.blue,
    width = 2.5,
    id = "surface-pixel-copy",
}
scene:replacement_transform(pixel_copy, target_pixel, 1.0, "ease_in_out")
local dot_copy = root:point { point = ss, fill = p.blue, radius = 7, id = "surface-sample-copy" }
scene:shift(dot_copy, { gs[1] - ss[1], gs[2] - ss[2] }, 0.85, "ease_in_out")
local center = root:point { point = gc, fill = p.ink, radius = 6, id = "gradient-center" }
scene:fade_in(center, { scale = 0.6, duration = 0.28, easing = "ease_out" })
scene:create(text("center = {cx, cy}", { 3.85, 0.15 }, 12, p.ink), 0.25, "ease_out")
local offset =
    root:arrow { from = gc, to = gs, tip = 13, color = p.purple, width = 3, id = "gradient-offset" }
scene:create(offset, 0.62, "ease_out")
scene:create(text("{rx, ry}", { 4.65, -0.55 }, 14, p.purple), 0.25, "ease_out")
local formulas = {
    text("xStep = {a11, a21}", { 4.4, -2.30 }, 13, p.blue),
    text("yStep = {a12, a22}", { 4.4, -2.67 }, 13, p.mustard),
    text("The inverse coefficients are prepared once,", { -4.7, -2.42 }, 13, p.muted),
    text("not recomputed inside the pixel loop.", { -4.7, -2.76 }, 13, p.muted),
}
scene:create(formulas, 0.52, "ease_out", 0.06)
scene:wait(1.2)
return scene
