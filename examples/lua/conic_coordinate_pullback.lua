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
}
local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    loop = false,
    background = p.paper,
    camera = { mode = "fixed", view = "2d", height = 9 },
}
local root = scene:space { x = { -8, 8, 1 }, y = { -4.5, 4.5, 1 }, opacity = 0 }

local function text(value, point, size, color, id, align)
    return root:text {
        text = value,
        point = point,
        size = size,
        font = "Pretendard",
        fill = color or p.ink,
        id = id,
        align = align or { 0.5, 0.5 },
    }
end
local function matrix(a, b, c, d, x, y)
    return { a, b, 0, x, c, d, 0, y, 0, 0, 1, 0, 0, 0, 0, 1 }
end
local function header(number, title, subtitle, footer)
    text(
        number .. "  /  THORVG CPU RASTERIZER",
        { -7.2, 3.72 },
        12,
        p.accent,
        "eyebrow",
        { 0, 0.5 }
    )
    text(title, { -7.2, 3.25 }, 27, p.ink, "title", { 0, 0.5 })
    text(subtitle, { -7.2, 2.72 }, 14, p.soft, "subtitle", { 0, 0.5 })
    root:line { from = { -7.2, 2.48 }, to = { 7.2, 2.48 }, color = p.rule, width = 1 }
    text(footer, { 0, -4.05 }, 12, p.soft, "footer")
end

header(
    "01",
    "Inverse coefficients define pixel steps",
    "A Surface x increment becomes xStep; a Surface y increment becomes yStep.",
    "x += 1  ->  xStep = {a11, a21}      y += 1  ->  yStep = {a12, a22}"
)

local origin = { -3.75, -0.05 }
local geometry =
    root:group { matrix = matrix(1, 0, 0, 1, origin[1], origin[2]), id = "coordinate-geometry" }
local grid = {}
local step = 0.65
for i = 0, 7 do
    grid[#grid + 1] = geometry:line {
        from = { -2.275 + i * step, -1.95 },
        to = { -2.275 + i * step, 1.95 },
        color = p.rule,
        width = 1,
    }
end
for i = 0, 6 do
    grid[#grid + 1] = geometry:line {
        from = { -2.275, -1.95 + i * step },
        to = { 2.275, -1.95 + i * step },
        color = p.rule,
        width = 1,
    }
end
local axes = {
    geometry:line { from = { -2.45, 0 }, to = { 2.45, 0 }, color = p.solid, width = 1.5 },
    geometry:line { from = { 0, -2.15 }, to = { 0, 2.15 }, color = p.solid, width = 1.5 },
}
local footprint = geometry:polygon {
    points = { { 0, 0 }, { step, 0 }, { step, -step }, { 0, -step } },
    fill = p.tint,
    stroke = p.accent,
    width = 3,
    id = "unit-pixel",
}
local x_increment = geometry:arrow {
    from = { 0, 0 },
    to = { 1.15, 0 },
    tip = 13,
    color = p.blue,
    width = 4,
    id = "surface-x-step",
}
local y_increment = geometry:arrow {
    from = { 0, 0 },
    to = { 0, -1.15 },
    tip = 13,
    color = p.mustard,
    width = 4,
    id = "surface-y-step",
}
local surface_labels = {
    text("SURFACE COORDINATES / y-down", { -6.7, 1.98 }, 13, p.muted, "surface-label", { 0, 0.5 }),
    text("x += 1", { -2.62, 0.30 }, 14, p.blue, "x-label"),
    text("y += 1", { -3.33, -1.34 }, 14, p.mustard, "y-label"),
    text("unit pixel", { -3.42, -0.98 }, 13, p.accent, "pixel-label"),
}

text("INVERSE LINEAR PART", { 2.95, 1.83 }, 13, p.soft, "matrix-title", { 0, 0.5 })
text("itransform =", { 3.25, 0.70 }, 14, p.ink, "inverse-name")
local columns = {
    root:rectangle {
        center = { 4.90, 0.70 },
        size = { 0.88, 1.30 },
        fill = "#5e7a9b1a",
        stroke = p.blue,
        width = 2,
        id = "x-column",
    },
    root:rectangle {
        center = { 6.00, 0.70 },
        size = { 0.88, 1.30 },
        fill = "#b8915a1a",
        stroke = p.mustard,
        width = 2,
        id = "y-column",
    },
}
local entries = {
    text("[", { 4.35, 0.70 }, 32, p.ink),
    text("]", { 6.55, 0.70 }, 32, p.ink),
    text("a11", { 4.90, 1.02 }, 17, p.blue),
    text("a21", { 4.90, 0.38 }, 17, p.blue),
    text("a12", { 6.00, 1.02 }, 17, p.mustard),
    text("a22", { 6.00, 0.38 }, 17, p.mustard),
    text("xStep", { 4.90, 1.58 }, 11, p.blue),
    text("yStep", { 6.00, 1.58 }, 11, p.mustard),
}
local formulas = {
    text("xStep = {a11, a21}", { 4.85, -0.55 }, 16, p.blue, "x-formula"),
    text("yStep = {a12, a22}", { 4.85, -1.05 }, 16, p.mustard, "y-formula"),
    text(
        "Each matrix column stores one prepared pixel step.",
        { 4.70, -1.72 },
        13,
        p.muted,
        "column-note"
    ),
}

scene:create(grid, 0.72, "linear", 0.025)
scene:create(axes, 0.35, "ease_out", 0.08)
scene:create(surface_labels[1], 0.24, "ease_out")
scene:create(
    { x_increment, surface_labels[2], y_increment, surface_labels[3], footprint, surface_labels[4] },
    0.68,
    "ease_out",
    0.07
)
scene:create(columns, 0.45, "ease_out", 0.08)
scene:create(entries, 0.48, "ease_out", 0.035)
scene:fade_out(surface_labels[2], { duration = 0.25, easing = "ease_in" })
scene:fade_out(surface_labels[3], { duration = 0.25, easing = "ease_in" })
scene:fade_out(surface_labels[4], { duration = 0.25, easing = "ease_in" })
scene:transform(geometry, matrix(1.15, 0.35, -0.30, 0.90, origin[1], origin[2]), 2.0, "ease_in_out")
local gradient_labels = {
    text("GRADIENT SPACE", { -6.7, 1.98 }, 13, p.muted, "gradient-label", { 0, 0.5 }),
    text("xStep", { -2.75, 0.34 }, 14, p.blue, "xstep-label"),
    text("yStep", { -4.55, -0.66 }, 14, p.mustard, "ystep-label"),
    text("pixel footprint", { -2.57, -0.84 }, 12, p.accent, "footprint-label"),
}
scene:fade_out(surface_labels[1], { duration = 0.25, easing = "ease_in" })
scene:fade_in(gradient_labels[1], { duration = 0.35, easing = "ease_out" })
scene:create({ gradient_labels[2], gradient_labels[3], gradient_labels[4] }, 0.35, "ease_out", 0.05)
scene:fill(columns[1], "#5e7a9b42", 0.45, "ease_out")
scene:create(formulas[1], 0.35, "ease_out")
scene:fill(columns[1], "#5e7a9b1a", 0.30, "ease_in")
scene:fill(columns[2], "#b8915a42", 0.45, "ease_out")
scene:create(formulas[2], 0.35, "ease_out")
scene:fill(columns[2], "#b8915a1a", 0.30, "ease_in")
scene:create(formulas[3], 0.35, "ease_out")

local scan_start = { -6.00, -2.30 }
local scan_line = root:line {
    from = scan_start,
    to = { -2.90, -3.08 },
    color = p.blue,
    width = 2,
    id = "scan-path",
}
local scan = {}
for i = 0, 4 do
    scan[#scan + 1] = root:point {
        point = { scan_start[1] + i * 0.775, scan_start[2] - i * 0.195 },
        fill = p.blue,
        radius = 5,
        id = "scan-" .. i,
    }
    scan[#scan + 1] =
        text("i+" .. i, { scan_start[1] + i * 0.775, scan_start[2] - i * 0.195 + 0.20 }, 10, p.blue)
end
local recurrence = {
    text("rx += a11", { 4.85, -2.45 }, 15, p.blue),
    text("ry += a21", { 4.85, -2.80 }, 15, p.blue),
    text("=> {rx, ry} += xStep", { 4.85, -3.18 }, 16, p.accent),
}
scene:create(scan_line, 0.65, "linear")
scene:create(scan, 0.70, "ease_out", 0.035)
scene:create(recurrence, 0.55, "ease_out", 0.08)
scene:wait(1.1)
return scene
