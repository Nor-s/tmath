-- Inspired by MathBox's sampled data -> visual primitive composition.
-- One parametric function drives a 3D wire surface and a 2D parameter domain.

local p = {
    paper = "#f4f2ed",
    panel = "#fffefa",
    ink = "#172033",
    muted = "#667085",
    soft = "#98a2b3",
    rule = "#d9dde5",
    violet = "#5b5ce2",
    cyan = "#0ea5e9",
    teal = "#14b8a6",
    tangent = "#ef476f",
    width = "#06b6d4",
    normal = "#f59e0b",
    tracer = "#7c3aed",
}

local tau = 2 * math.pi
local radius, half_width = 2.25, 0.72

local function mobius(u, v)
    local radial = radius + v * math.cos(u / 2)
    return {
        radial * math.cos(u),
        v * math.sin(u / 2),
        radial * math.sin(u),
    }
end

local function subtract(a, b)
    return { a[1] - b[1], a[2] - b[2], a[3] - b[3] }
end

local function scale(a, value)
    return { a[1] * value, a[2] * value, a[3] * value }
end

local function length(a)
    return math.sqrt(a[1] * a[1] + a[2] * a[2] + a[3] * a[3])
end

local function normalize(a)
    return scale(a, 1 / length(a))
end

local function cross(a, b)
    return {
        a[2] * b[3] - a[3] * b[2],
        a[3] * b[1] - a[1] * b[3],
        a[1] * b[2] - a[2] * b[1],
    }
end

local page = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    loop = false,
    antialiasing = true,
    background = p.paper,
    camera = { mode = "fixed", view = "2d", height = 9 },
}
local page_root = page:space { x = { -8, 8, 1 }, y = { -4.5, 4.5, 1 }, opacity = 0 }

local function page_text(value, point, size, color, id, align)
    return page_root:text {
        text = value,
        point = point,
        size = size,
        font = "Pretendard",
        fill = color or p.ink,
        id = id,
        align = align or { 0.5, 0.5 },
    }
end

page_text(
    "ADVANCED VISUALIZATION  /  PARAMETRIC MANIFOLD",
    { -7.25, 3.78 },
    11,
    p.violet,
    "eyebrow",
    { 0, 0.5 }
)
page_text("A Möbius strip from one sampled area", { -7.25, 3.28 }, 27, p.ink, "title", { 0, 0.5 })
page_text(
    "The same (u, v) data becomes a 3D surface, a trajectory, and a local frame.",
    { -7.25, 2.72 },
    13,
    p.muted,
    "subtitle",
    { 0, 0.5 }
)
page_root:line { from = { -7.25, 2.40 }, to = { 7.25, 2.40 }, color = p.rule, width = 1 }
page_text(
    "sampled area  →  curves + vectors + linked parameter domain",
    { 0, -4.14 },
    10,
    p.soft,
    "pipeline"
)
page:create(page_root, 0.32, "ease_out")

-- The left Viewport is a sampled 3D manifold. Lines in each parameter direction
-- share one function, analogous to feeding one MathBox area into several views.
local surface_scene = tmath.scene {
    width = 614,
    height = 373,
    fps = 30,
    background = p.panel,
    camera = {
        mode = "fixed",
        view = "3d",
        eye = { 6.4, 4.8, 6.8 },
        target = { 0, 0, 0 },
        up = { 0, 1, 0 },
        projection = "perspective",
        fov = 0.62,
        near = 0.1,
        far = 100,
    },
}
local surface = surface_scene:group { id = "sampled-surface" }

local bands = {}
local band_colors = {
    "#5b5ce2b8",
    "#5268e0c0",
    "#4775ddc8",
    "#3982d8d0",
    "#2b8ed1d8",
    "#1999c8e0",
    "#0ea5bce8",
    "#10afb0ee",
    "#14b8a6f4",
    "#24b39df0",
    "#35ad94e8",
    "#47a78bde",
    "#5aa082d4",
}
for band = 0, 12 do
    local v = -half_width + 2 * half_width * band / 12
    local points = {}
    for sample = 0, 96 do
        points[#points + 1] = mobius(tau * sample / 96, v)
    end
    bands[#bands + 1] = surface:plot {
        points = points,
        color = band_colors[band + 1],
        width = 2.35,
        id = "surface-band-" .. band,
    }
end

local ribs = {}
for rib = 0, 31 do
    local u = tau * rib / 32
    local points = {}
    for sample = 0, 12 do
        points[#points + 1] = mobius(u, -half_width + 2 * half_width * sample / 12)
    end
    ribs[#ribs + 1] = surface:plot {
        points = points,
        color = "#17203334",
        width = 1.25,
        id = "surface-rib-" .. rib,
    }
end

local center_points = {}
for sample = 0, 128 do
    center_points[#center_points + 1] = mobius(tau * sample / 128, 0)
end
local centerline = surface:plot {
    points = center_points,
    color = p.ink,
    width = 3.0,
    id = "centerline",
}

-- A finite-difference local frame makes the differential geometry tangible.
local frame_u, frame_v = 1.18 * math.pi, 0.20
local frame_origin = mobius(frame_u, frame_v)
local epsilon = 0.001
local du =
    normalize(subtract(mobius(frame_u + epsilon, frame_v), mobius(frame_u - epsilon, frame_v)))
local dv =
    normalize(subtract(mobius(frame_u, frame_v + epsilon), mobius(frame_u, frame_v - epsilon)))
local normal = normalize(cross(du, dv))
local frame = {
    surface:point {
        point = frame_origin,
        fill = p.ink,
        stroke = p.panel,
        width = 2,
        radius = 7,
        layer = 8,
        id = "frame-origin",
    },
    surface:vector {
        origin = frame_origin,
        value = scale(du, 1.02),
        color = p.tangent,
        width = 4,
        tip = 11,
        layer = 9,
        id = "frame-du",
    },
    surface:vector {
        origin = frame_origin,
        value = scale(dv, 1.02),
        color = p.width,
        width = 4,
        tip = 11,
        layer = 9,
        id = "frame-dv",
    },
    surface:vector {
        origin = frame_origin,
        value = scale(normal, 1.02),
        color = p.normal,
        width = 4,
        tip = 11,
        layer = 9,
        id = "frame-normal",
    },
}

local tracer = surface:point {
    point = mobius(0, 0),
    fill = p.tracer,
    stroke = p.panel,
    width = 2,
    radius = 7,
    layer = 10,
    id = "surface-tracer",
}

surface_scene:create(bands, 0.62, "ease_out", 0.035)
surface_scene:create(ribs, 0.46, "ease_out", 0.013)
surface_scene:create(centerline, 0.72, "linear")
surface_scene:grow_from_center(tracer, 0.20, "snappy")
for sample = 1, 24 do
    local previous = mobius(tau * (sample - 1) / 24, 0)
    local current = mobius(tau * sample / 24, 0)
    surface_scene:shift(tracer, subtract(current, previous), 0.055, "linear")
end
surface_scene:create(frame, 0.44, "snappy", 0.055)
surface_scene:look({
    view = "3d",
    eye = { -5.8, 5.4, 6.1 },
    target = { 0, 0, 0 },
    up = { 0, 1, 0 },
    projection = "perspective",
    fov = 0.62,
    near = 0.1,
    far = 100,
}, 1.35, "ease_in_out")
surface_scene:wait(0.45)

-- The right Viewport explains where every sampled vertex comes from.
local domain_scene = tmath.scene {
    width = 274,
    height = 373,
    fps = 30,
    background = p.panel,
    camera = { mode = "fixed", view = "2d", height = 9 },
}
local domain = domain_scene:space { x = { -3.3, 3.3, 1 }, y = { -4.5, 4.5, 1 }, opacity = 0 }
local function domain_text(value, point, size, color, id, align)
    return domain:text {
        text = value,
        point = point,
        size = size,
        font = "Pretendard",
        fill = color or p.ink,
        id = id,
        align = align or { 0.5, 0.5 },
    }
end

domain_text("PARAMETER DOMAIN", { -2.72, 3.96 }, 11, p.violet, "domain-title", { 0, 0.5 })
domain_text("P(u, v)", { -2.72, 3.33 }, 22, p.ink, "domain-symbol", { 0, 0.5 })
domain_text("x = (R + v cos(u/2)) cos u", { -2.72, 2.68 }, 10, p.muted, "formula-x", { 0, 0.5 })
domain_text("y = v sin(u/2)", { -2.72, 2.20 }, 10, p.muted, "formula-y", { 0, 0.5 })
domain_text("z = (R + v cos(u/2)) sin u", { -2.72, 1.72 }, 10, p.muted, "formula-z", { 0, 0.5 })

local domain_box = domain:rectangle {
    center = { 0, 0.25 },
    size = { 5.42, 2.16 },
    corner = 0.08,
    fill = "#f4f6ff",
    stroke = p.rule,
    width = 1.5,
    id = "uv-domain",
}
local grid = {}
for column = 1, 7 do
    local x = -2.71 + 5.42 * column / 8
    grid[#grid + 1] = domain:line {
        from = { x, -0.83 },
        to = { x, 1.33 },
        color = "#5b5ce220",
        width = 1,
    }
end
for row = 1, 3 do
    local y = -0.83 + 2.16 * row / 4
    grid[#grid + 1] = domain:line {
        from = { -2.71, y },
        to = { 2.71, y },
        color = "#5b5ce220",
        width = 1,
    }
end
local domain_path = domain:line {
    from = { -2.55, 0.25 },
    to = { 2.55, 0.25 },
    color = p.tracer,
    width = 3,
    id = "domain-centerline",
}
local domain_tracer = domain:point {
    point = { -2.55, 0.25 },
    fill = p.tracer,
    stroke = p.panel,
    width = 2,
    radius = 6,
    layer = 8,
    id = "domain-tracer",
}
domain_text("u = 0", { -2.71, -1.12 }, 10, p.muted, "u-zero")
domain_text("u = 2pi", { 2.71, -1.12 }, 10, p.muted, "u-tau")
domain_text("v", { -2.96, 0.25 }, 11, p.muted, "v-axis")
domain_text("(0, v)  ~  (2pi, -v)", { 0, -1.62 }, 11, p.ink, "seam-rule")
domain_text("one turn flips the width direction", { 0, -2.16 }, 10, p.muted, "seam-note")

local legend = {
    { p.tangent, "dP/du", -2.68 },
    { p.width, "dP/dv", -3.11 },
    { p.normal, "N = normalize(du x dv)", -3.54 },
}
local legend_objects = {}
for index, item in ipairs(legend) do
    legend_objects[#legend_objects + 1] = domain:line {
        from = { -2.68, item[3] },
        to = { -2.20, item[3] },
        color = item[1],
        width = 3,
        id = "legend-line-" .. index,
    }
    legend_objects[#legend_objects + 1] = domain_text(
        item[2],
        { -2.02, item[3] },
        10,
        item[1],
        "legend-text-" .. index,
        { 0, 0.5 }
    )
end

domain_scene:create({ domain_box }, 0.30, "ease_out")
domain_scene:create(grid, 0.38, "ease_out", 0.018)
domain_scene:create(domain_path, 1.25, "linear")
domain_scene:grow_from_center(domain_tracer, 0.18, "snappy")
domain_scene:shift(domain_tracer, { 5.10, 0 }, 1.32, "linear")
domain_scene:create(legend_objects, 0.32, "ease_out", 0.035)
domain_scene:wait(0.45)

page:viewport(surface_scene, { x = 0.025, y = 0.225, width = 0.64, height = 0.69 })
page:viewport(domain_scene, { x = 0.69, y = 0.225, width = 0.285, height = 0.69 })

return page
