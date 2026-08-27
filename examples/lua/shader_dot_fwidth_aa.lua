-- Audience: shader authors who know vectors but have not connected dot products
-- to derivative-based edge coverage.
-- Goal: show that dot gives a signed edge distance and fwidth converts that
-- distance into an approximately one-device-pixel transition band.
-- Final frame: hard step and fwidth + smoothstep compared beside the complete code.

local palette = {
    background = "#08111b",
    panel = "#0f1b29",
    panel_alt = "#132235",
    grid = "#26384d",
    text = "#f4f8fc",
    muted = "#94a7bb",
    cyan = "#45d3e8",
    cyan_dim = "#245968",
    magenta = "#f26aa8",
    gold = "#f4c95d",
    coral = "#ff7a6b",
    green = "#75dfa2",
}

local LAYER = {
    background = 0,
    band = 5,
    dot = 10,
    vector = 20,
    arrow = 30,
    transition = 39,
    text = 40,
}

local scene = tmath.scene {
    width = 960,
    height = 540,
    fps = 30,
    loop = false,
    antialiasing = true,
    background = palette.background,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 9},
}

local root = scene:space {
    x = {-8, 8, 1},
    y = {-4.5, 4.5, 1},
    opacity = 0,
    id = "root-space",
}

local function label(parent, value, point, size, color, id, align)
    return parent:text {
        text = value,
        point = point,
        size = size,
        font = "Pretendard",
        fill = color or palette.text,
        layer = LAYER.text,
        id = id,
        align = align or {0.5, 0.5},
    }
end

local function arrow_points(from, to, shaft_half, head_half, head_length)
    local dx = to[1] - from[1]
    local dy = to[2] - from[2]
    local length = math.sqrt(dx * dx + dy * dy)
    local ux = dx / length
    local uy = dy / length
    local px = -uy
    local py = ux
    local base = {to[1] - head_length * ux, to[2] - head_length * uy}
    return {
        {from[1] + shaft_half * px, from[2] + shaft_half * py},
        {base[1] + shaft_half * px, base[2] + shaft_half * py},
        {base[1] + head_half * px, base[2] + head_half * py},
        {to[1], to[2]},
        {base[1] - head_half * px, base[2] - head_half * py},
        {base[1] - shaft_half * px, base[2] - shaft_half * py},
        {from[1] - shaft_half * px, from[2] - shaft_half * py},
    }
end

local function chip_points(center, width, height)
    local x0 = center[1] - width * 0.5
    local x1 = center[1] + width * 0.5
    local y0 = center[2] - height * 0.5
    local y1 = center[2] + height * 0.5
    return {
        {x0, y0}, {center[1], y0}, {x1, y0}, {x1, y1},
        {center[1], y1}, {x0, y1}, {x0, center[2]},
    }
end

local function smoothstep(edge0, edge1, value)
    local t = (value - edge0) / (edge1 - edge0)
    t = math.max(0, math.min(1, t))
    return t * t * (3 - 2 * t)
end

local function coverage_color(alpha)
    local outside = {15, 27, 41}
    local inside = {69, 211, 232}
    local r = math.floor(outside[1] + (inside[1] - outside[1]) * alpha + 0.5)
    local g = math.floor(outside[2] + (inside[2] - outside[2]) * alpha + 0.5)
    local b = math.floor(outside[3] + (inside[3] - outside[3]) * alpha + 0.5)
    return string.format("#%02x%02x%02x", r, g, b)
end

local header = root:group {id = "header"}
label(header, "dot → fwidth · 1픽셀 안티앨리어싱", {-7.12, 3.90}, 24, palette.text, "title", {0, 0.5})
label(
    header,
    "벡터 투영이 signed distance와 coverage가 되는 과정",
    {-7.12, 3.44},
    13,
    palette.muted,
    "subtitle",
    {0, 0.5}
)
header:line {
    from = {-7.25, 3.10},
    to = {7.25, 3.10},
    color = palette.grid,
    width = 2,
    layer = LAYER.background,
    id = "header-rule",
}

local code_panel = root:rectangle {
    center = {3.70, -0.35},
    size = {6.70, 5.36},
    corner = 0.16,
    fill = palette.panel,
    stroke = palette.grid,
    width = 2,
    layer = LAYER.background,
    id = "code-panel",
}
local code_heading = label(
    root,
    "FRAGMENT SHADER",
    {0.70, 1.93},
    12,
    palette.muted,
    "code-heading",
    {0, 0.5}
)
local caption_1 = label(
    root,
    "1  ·  dot은 경계 법선 방향의 거리를 남긴다",
    {-7.20, 2.72},
    13,
    palette.text,
    "caption-dot",
    {0, 0.5}
)

scene:fade_in(header, {shift = {0, 0.10}, scale = 0.98, duration = 0.52, curve = "gentle"})
scene:fade_in(code_panel, {scale = 0.98, duration = 0.38, curve = "gentle"})
scene:fade_in(code_heading, {duration = 0.24, curve = "ease_out"})
scene:wait(0.60)

-- Beat 1: a dot product turns an offset vector into signed distance.
local geometry = root:group {id = "signed-distance-geometry"}
local p0 = {-4.55, -0.55}
local p = {-3.15, 1.15}
local tangent = {0.94, 0.342}
local normal = {-0.342, 0.94}
local distance = (p[1] - p0[1]) * normal[1] + (p[2] - p0[2]) * normal[2]
local projection = {p0[1] + distance * normal[1], p0[2] + distance * normal[2]}
local normal_end = {p0[1] + 1.85 * normal[1], p0[2] + 1.85 * normal[2]}

local edge = geometry:line {
    from = {p0[1] - 3.05 * tangent[1], p0[2] - 3.05 * tangent[2]},
    to = {p0[1] + 3.05 * tangent[1], p0[2] + 3.05 * tangent[2]},
    color = palette.coral,
    width = 3,
    layer = LAYER.vector,
    id = "implicit-edge",
}
local origin_dot = geometry:point {
    point = p0,
    radius = 7,
    fill = palette.coral,
    layer = LAYER.dot,
    id = "edge-origin",
}
local sample_dot = geometry:point {
    point = p,
    radius = 7,
    fill = palette.text,
    layer = LAYER.dot,
    id = "sample-p",
}
local offset_arrow = geometry:arrow {
    from = p0,
    to = p,
    tail = 3,
    tip = 14,
    color = palette.cyan,
    width = 3,
    layer = LAYER.arrow,
    id = "offset-vector",
}
local normal_vector = geometry:vector {
    origin = p0,
    value = {1.85 * normal[1], 1.85 * normal[2]},
    tail = 3,
    tip = 14,
    color = palette.magenta,
    width = 3,
    layer = LAYER.vector,
    id = "edge-normal",
}
local projection_vector = geometry:vector {
    origin = p0,
    value = {distance * normal[1], distance * normal[2]},
    tail = 2,
    tip = 12,
    color = palette.gold,
    width = 4,
    layer = LAYER.vector,
    id = "normal-projection",
}
local projection_guide = geometry:line {
    from = p,
    to = projection,
    color = palette.muted,
    width = 1.5,
    layer = LAYER.background,
    id = "projection-guide",
}
local geometry_labels = {
    label(geometry, "p0", {p0[1] - 0.18, p0[2] - 0.35}, 13, palette.coral, "p0-label"),
    label(geometry, "p", {p[1] + 0.20, p[2] + 0.28}, 13, palette.text, "p-label"),
    label(geometry, "p - p0", {-3.45, 0.02}, 13, palette.cyan, "offset-label"),
    label(geometry, "n", {p0[1] - 0.82, p0[2] + 1.63}, 14, palette.magenta, "normal-label"),
    label(geometry, "signed distance d", {-6.07, 0.30}, 12, palette.gold, "distance-label"),
}

scene:create({edge, origin_dot}, 0.46, "ease_out", 0.06)
scene:create({offset_arrow, normal_vector, sample_dot}, 0.64, "ease_out", 0.08)
scene:create({projection_guide, projection_vector}, 0.58, "ease_in_out", 0.05)
scene:wait(0.85)
scene:fade_in(caption_1, {shift = {0, 0.06}, duration = 0.30, curve = "ease_out"})
scene:create(geometry_labels, 0.26, "ease_out", 0.035)
scene:wait(0.45)

-- Reveal neutral syntax, then hand visible inputs and the measured result into
-- their same-color semantic terms. The source geometry remains on screen.
local code_dot_open = label(root, " = dot(", {1.587, 1.22}, 15, palette.muted, "code-dot-open", {0, 0.5})
local code_dot_comma = label(root, ", ", {3.578, 1.22}, 15, palette.muted, "code-dot-comma", {0, 0.5})
local code_dot_close = label(root, ");", {3.932, 1.22}, 15, palette.muted, "code-dot-close", {0, 0.5})
scene:fade_in(code_dot_open, {duration = 0.16, curve = "ease_out"})
scene:fade_in(code_dot_comma, {duration = 0.12, curve = "ease_out"})
scene:fade_in(code_dot_close, {duration = 0.12, curve = "ease_out"})

local normal_copy = root:polygon {
    points = arrow_points(p0, normal_end, 0.035, 0.12, 0.24),
    fill = palette.magenta,
    stroke = palette.magenta,
    width = 1,
    layer = LAYER.transition,
    id = "normal-copy-proxy",
}
local normal_seed = root:polygon {
    points = chip_points({3.75, 1.22}, 0.12, 0.20),
    fill = palette.magenta,
    stroke = palette.magenta,
    width = 1,
    layer = LAYER.transition,
    id = "normal-formula-seed",
}
scene:replacement_transform(normal_copy, normal_seed, 0.68, "ease_in_out")
local code_dot_normal = label(root, "n", {3.698, 1.22}, 15, palette.magenta, "code-dot-normal", {0, 0.5})
scene:fade_transform(normal_seed, code_dot_normal, 0.24, "gentle")

local offset_copy = root:polygon {
    points = arrow_points(p0, p, 0.035, 0.12, 0.24),
    fill = palette.cyan,
    stroke = palette.cyan,
    width = 1,
    layer = LAYER.transition,
    id = "offset-copy-proxy",
}
local offset_seed = root:polygon {
    points = chip_points({2.70, 1.22}, 0.12, 0.20),
    fill = palette.cyan,
    stroke = palette.cyan,
    width = 1,
    layer = LAYER.transition,
    id = "offset-formula-seed",
}
scene:replacement_transform(offset_copy, offset_seed, 0.72, "ease_in_out")
local code_dot_offset = label(root, "p - p0", {2.625, 1.22}, 15, palette.cyan, "code-dot-offset", {0, 0.5})
scene:fade_transform(offset_seed, code_dot_offset, 0.24, "gentle")

local result_copy = root:polygon {
    points = arrow_points(p0, projection, 0.045, 0.13, 0.24),
    fill = palette.gold,
    stroke = palette.gold,
    width = 1,
    layer = LAYER.transition,
    id = "distance-copy-proxy",
}
local result_seed = root:polygon {
    points = chip_points({0.78, 1.22}, 0.12, 0.20),
    fill = palette.gold,
    stroke = palette.gold,
    width = 1,
    layer = LAYER.transition,
    id = "distance-formula-seed",
}
scene:replacement_transform(result_copy, result_seed, 0.76, "ease_in_out")
local code_dot_result = label(root, "float d", {0.70, 1.22}, 15, palette.gold, "code-dot-result", {0, 0.5})
scene:fade_transform(result_seed, code_dot_result, 0.26, "gentle")

local code_dot_note = label(root, "n은 normalize된 상수 법선", {0.70, 0.79}, 12, palette.muted, "code-dot-note", {0, 0.5})
scene:fade_in(code_dot_note, {duration = 0.35, curve = "gentle"})
scene:wait(1.30)

-- Beat 2: a hard threshold turns the distance into a jagged binary edge.
local caption_2 = label(
    root,
    "2  ·  step은 픽셀을 0 또는 1로만 분류한다",
    {-7.20, 2.72},
    13,
    palette.text,
    "caption-hard-step",
    {0, 0.5}
)
scene:fade_out(caption_1, {duration = 0.25, curve = "ease_in"})
scene:fade_out(geometry, {shift = {-0.10, 0}, duration = 0.34, curve = "ease_in"})

local grid_scale = 0.47
local grid_x = -6.75
local grid_y = -2.62
local slope = 0.56
local intercept = 1.05
local inv_length = 1 / math.sqrt(1 + slope * slope)
local nx = -slope * inv_length
local ny = inv_length
local pixel_fwidth = math.abs(nx) + math.abs(ny)
local half_width = 0.5 * pixel_fwidth

local hard_patches = {}
local aa_patches = {}
for y = 0, 7 do
    for x = 0, 11 do
        local px = x + 0.5
        local py = y + 0.5
        local d = (py - slope * px - intercept) * inv_length
        local hard_alpha = d <= 0 and 1 or 0
        local aa_alpha = 1 - smoothstep(-half_width, half_width, d)
        hard_patches[#hard_patches + 1] = {
            region = {x, y, 1, 1},
            color = coverage_color(hard_alpha),
        }
        aa_patches[#aa_patches + 1] = {
            region = {x, y, 1, 1},
            color = coverage_color(aa_alpha),
        }
    end
end

local hard_group = root:group {id = "hard-grid-group"}
local hard_space = hard_group:space {
    x = {0, 12, 1},
    y = {0, 8, 1},
    opacity = 0,
    matrix = {
        grid_scale, 0, 0, grid_x,
        0, grid_scale, 0, grid_y,
        0, 0, 1, 0,
        0, 0, 0, 1,
    },
    id = "hard-grid-space",
}
local hard_cell = hard_space:cell {
    origin = {0, 0},
    size = {12, 8},
    mode = "padd",
    padding = 0.055,
    color = palette.panel,
    patches = hard_patches,
    layer = LAYER.background,
    id = "hard-coverage",
}
local hard_edge = hard_space:line {
    from = {0, intercept},
    to = {12, slope * 12 + intercept},
    color = palette.coral,
    width = 2.5,
    layer = LAYER.vector,
    id = "hard-edge",
}
local hard_heading = label(
    root,
    "HARD STEP  ·  계단 모양이 경계를 따라 보인다",
    {-6.75, 1.65},
    13,
    palette.coral,
    "hard-heading",
    {0, 0.5}
)
local code_hard = label(
    root,
    "float alpha = step(0.0, -d);",
    {0.70, -0.68},
    15,
    palette.coral,
    "code-hard-step",
    {0, 0.5}
)
local code_hard_note = label(
    root,
    "step(0, -d)는 -d의 부호를 0/1로 분류",
    {0.70, -1.12},
    12,
    palette.muted,
    "code-hard-note",
    {0, 0.5}
)

scene:fade_in(hard_group, {scale = 0.98, duration = 0.58, curve = "gentle"})
scene:wait(0.80)
scene:fade_in(caption_2, {shift = {0, 0.06}, duration = 0.30, curve = "ease_out"})
scene:fade_in(hard_heading, {duration = 0.28, curve = "ease_out"})
scene:fade_in(code_hard, {shift = {0.08, 0}, duration = 0.55, curve = "ease_out"})
scene:fade_in(code_hard_note, {duration = 0.35, curve = "gentle"})
scene:wait(0.45)

local inside_cell_center = {grid_x + 2.5 * grid_scale, grid_y + 1.5 * grid_scale}
local inside_copy = root:polygon {
    points = chip_points(inside_cell_center, grid_scale * 0.78, grid_scale * 0.78),
    fill = palette.cyan,
    stroke = palette.cyan,
    width = 1,
    layer = LAYER.transition,
    id = "inside-cell-copy",
}
local inside_seed = root:polygon {
    points = chip_points({0.78, -1.49}, 0.12, 0.18),
    fill = palette.cyan,
    stroke = palette.cyan,
    width = 1,
    layer = LAYER.transition,
    id = "inside-case-seed",
}
scene:replacement_transform(inside_copy, inside_seed, 0.62, "ease_in_out")
local hard_case_inside = label(
    root,
    "inside · d ≤ 0 → -d ≥ 0 → alpha = 1",
    {0.70, -1.49},
    11,
    palette.cyan,
    "hard-case-inside",
    {0, 0.5}
)
scene:fade_transform(inside_seed, hard_case_inside, 0.24, "gentle")

local outside_cell_center = {grid_x + 3.5 * grid_scale, grid_y + 4.5 * grid_scale}
local outside_copy = root:polygon {
    points = chip_points(outside_cell_center, grid_scale * 0.78, grid_scale * 0.78),
    fill = palette.panel,
    stroke = palette.coral,
    width = 2,
    layer = LAYER.transition,
    id = "outside-cell-copy",
}
local outside_seed = root:polygon {
    points = chip_points({0.78, -1.86}, 0.12, 0.18),
    fill = palette.coral,
    stroke = palette.coral,
    width = 1,
    layer = LAYER.transition,
    id = "outside-case-seed",
}
scene:replacement_transform(outside_copy, outside_seed, 0.62, "ease_in_out")
local hard_case_outside = label(
    root,
    "outside · d > 0 → -d < 0 → alpha = 0",
    {0.70, -1.86},
    11,
    palette.coral,
    "hard-case-outside",
    {0, 0.5}
)
scene:fade_transform(outside_seed, hard_case_outside, 0.24, "gentle")
scene:wait(1.20)

-- Beat 3: fwidth measures the distance change across the fragment quad.
local caption_3 = label(
    root,
    "3  ·  fwidth는 x/y 픽셀 스텝의 법선 투영을 합친다",
    {-7.20, 2.72},
    13,
    palette.text,
    "caption-fwidth",
    {0, 0.5}
)
scene:fade_out(caption_2, {duration = 0.25, curve = "ease_in"})
scene:fade_out(code_hard_note, {duration = 0.22, curve = "ease_in"})
scene:fade_out(hard_case_inside, {duration = 0.20, curve = "ease_in"})
scene:fade_out(hard_case_outside, {duration = 0.20, curve = "ease_in"})

local footprint = root:group {id = "pixel-footprint-explanation"}
local selected = {6, 4}
local selected_center = {
    grid_x + (selected[1] + 0.5) * grid_scale,
    grid_y + (selected[2] + 0.5) * grid_scale,
}
local selected_pixel = footprint:rectangle {
    center = selected_center,
    size = {grid_scale * 1.08, grid_scale * 1.08},
    corner = 0.05,
    fill = "#00000000",
    stroke = palette.gold,
    width = 3,
    layer = LAYER.transition,
    id = "selected-pixel",
}
local pixel_center = footprint:point {
    point = selected_center,
    radius = 5,
    fill = palette.text,
    layer = LAYER.dot,
    id = "selected-pixel-center",
}
local x_step = footprint:arrow {
    from = selected_center,
    to = {selected_center[1] + 0.82, selected_center[2]},
    tail = 2,
    tip = 11,
    color = palette.cyan,
    width = 2.5,
    layer = LAYER.arrow,
    id = "pixel-x-step",
}
local y_step = footprint:arrow {
    from = selected_center,
    to = {selected_center[1], selected_center[2] + 0.82},
    tail = 2,
    tip = 11,
    color = palette.magenta,
    width = 2.5,
    layer = LAYER.arrow,
    id = "pixel-y-step",
}
local footprint_labels = {
    label(footprint, "dFdx(p)", {selected_center[1] + 0.48, selected_center[2] - 0.30}, 11, palette.cyan, "x-step-label"),
    label(footprint, "dFdy(p)", {selected_center[1] - 0.62, selected_center[2] + 0.73}, 11, palette.magenta, "y-step-label"),
}

local lower0 = {-half_width * nx, intercept - half_width * ny}
local lower1 = {12 - half_width * nx, slope * 12 + intercept - half_width * ny}
local upper1 = {12 + half_width * nx, slope * 12 + intercept + half_width * ny}
local upper0 = {half_width * nx, intercept + half_width * ny}
local band_cell_points = {lower0, lower1, upper1, upper0}
local band = hard_space:polygon {
    points = band_cell_points,
    fill = "#f4c95d35",
    stroke = palette.gold,
    width = 2,
    layer = LAYER.band,
    id = "fwidth-band",
}

scene:create({selected_pixel, pixel_center, x_step, y_step}, 0.48, "ease_out", 0.05)
scene:fill_reveal(band, 0.65, "ease_out")
scene:wait(0.80)
local footprint_heading = label(
    root,
    "PIXEL FOOTPRINT  ·  x/y 스텝이 거리 변화를 만든다",
    {-6.75, 1.65},
    13,
    palette.gold,
    "footprint-heading",
    {0, 0.5}
)
scene:fade_transform(hard_heading, footprint_heading, 0.35, "gentle")
scene:fade_in(caption_3, {shift = {0, 0.06}, duration = 0.30, curve = "ease_out"})
scene:fade_in(footprint_labels[1], {duration = 0.30, curve = "ease_out"})
scene:fade_in(footprint_labels[2], {duration = 0.30, curve = "ease_out"})

local derivative_x_prefix = label(root, "dFdx(d) = dot(", {0.70, -1.56}, 12, palette.cyan, "derivative-x-prefix", {0, 0.5})
local derivative_x_suffix = label(root, ", n)", {3.46, -1.56}, 12, palette.muted, "derivative-x-suffix", {0, 0.5})
local derivative_y_prefix = label(root, "dFdy(d) = dot(", {0.70, -1.94}, 12, palette.magenta, "derivative-y-prefix", {0, 0.5})
local derivative_y_suffix = label(root, ", n)", {3.47, -1.94}, 12, palette.muted, "derivative-y-suffix", {0, 0.5})
scene:fade_in(derivative_x_prefix, {duration = 0.22, curve = "ease_out"})
scene:fade_in(derivative_x_suffix, {duration = 0.14, curve = "ease_out"})

local x_step_copy = root:polygon {
    points = arrow_points(selected_center, {selected_center[1] + 0.82, selected_center[2]}, 0.030, 0.10, 0.20),
    fill = palette.cyan,
    stroke = palette.cyan,
    width = 1,
    layer = LAYER.transition,
    id = "x-step-copy-proxy",
}
local x_derivative_seed = root:polygon {
    points = chip_points({2.60, -1.56}, 0.12, 0.18),
    fill = palette.cyan,
    stroke = palette.cyan,
    width = 1,
    layer = LAYER.transition,
    id = "x-derivative-seed",
}
scene:replacement_transform(x_step_copy, x_derivative_seed, 0.66, "ease_in_out")
local derivative_x_source = label(root, "dFdx(p)", {2.48, -1.56}, 12, palette.cyan, "derivative-x-source", {0, 0.5})
scene:fade_transform(x_derivative_seed, derivative_x_source, 0.24, "gentle")

scene:fade_in(derivative_y_prefix, {duration = 0.22, curve = "ease_out"})
scene:fade_in(derivative_y_suffix, {duration = 0.14, curve = "ease_out"})
local y_step_copy = root:polygon {
    points = arrow_points(selected_center, {selected_center[1], selected_center[2] + 0.82}, 0.030, 0.10, 0.20),
    fill = palette.magenta,
    stroke = palette.magenta,
    width = 1,
    layer = LAYER.transition,
    id = "y-step-copy-proxy",
}
local y_derivative_seed = root:polygon {
    points = chip_points({2.61, -1.94}, 0.12, 0.18),
    fill = palette.magenta,
    stroke = palette.magenta,
    width = 1,
    layer = LAYER.transition,
    id = "y-derivative-seed",
}
scene:replacement_transform(y_step_copy, y_derivative_seed, 0.66, "ease_in_out")
local derivative_y_source = label(root, "dFdy(p)", {2.49, -1.94}, 12, palette.magenta, "derivative-y-source", {0, 0.5})
scene:fade_transform(y_derivative_seed, derivative_y_source, 0.24, "gentle")
scene:wait(0.60)

-- The opaque copy carries the visible band into its formula, then fades into Text.
local function to_world(point)
    return {grid_x + point[1] * grid_scale, grid_y + point[2] * grid_scale}
end
local band_world_points = {
    to_world(lower0),
    to_world(lower1),
    to_world(upper1),
    to_world(upper0),
}
local band_copy = root:polygon {
    points = band_world_points,
    fill = palette.gold,
    stroke = palette.gold,
    width = 1,
    layer = LAYER.transition,
    id = "fwidth-band-copy",
}
local seed = root:polygon {
    points = {
        {0.52, 0.04},
        {0.66, 0.04},
        {0.66, 0.20},
        {0.52, 0.20},
    },
    fill = palette.gold,
    stroke = palette.gold,
    width = 1,
    layer = LAYER.transition,
    id = "fwidth-formula-seed",
}
scene:replacement_transform(band_copy, seed, 0.72, "ease_in_out")
local code_fwidth = label(
    root,
    "float w = 0.5 * fwidth(d);",
    {0.70, 0.12},
    15,
    palette.gold,
    "code-fwidth",
    {0, 0.5}
)
scene:fade_transform(seed, code_fwidth, 0.35, "gentle")
local fwidth_note = label(
    root,
    "fwidth(d) = |dFdx(d)| + |dFdy(d)|",
    {0.70, -0.28},
    12,
    palette.gold,
    "fwidth-expansion",
    {0, 0.5}
)
scene:fade_in(fwidth_note, {duration = 0.35, curve = "ease_out"})
scene:wait(1.50)

-- Beat 4: smoothstep maps that one-pixel band to fractional coverage.
local caption_4 = label(
    root,
    "4  ·  smoothstep이 그 폭 안에서 coverage를 연속적으로 만든다",
    {-7.20, 2.72},
    13,
    palette.text,
    "caption-smoothstep",
    {0, 0.5}
)
scene:fade_out(caption_3, {duration = 0.25, curve = "ease_in"})
scene:play({
    {target = footprint, opacity = 0},
    {target = band, opacity = 0},
}, 0.35, "ease_in", 0)
scene:fade_out(footprint_heading, {duration = 0.24, curve = "ease_in"})

local final_scale = 0.55
local initial_center = {grid_x + 6 * grid_scale, grid_y + 4 * grid_scale}
local final_y = -0.52
local hard_final_x = -5.30
local aa_final_x = -1.83
local hard_tx = hard_final_x - final_scale * initial_center[1]
local hard_ty = final_y - final_scale * initial_center[2]
local aa_tx = aa_final_x - final_scale * initial_center[1]
local aa_ty = final_y - final_scale * initial_center[2]
local hard_final_matrix = {
    final_scale, 0, 0, hard_tx,
    0, final_scale, 0, hard_ty,
    0, 0, 1, 0,
    0, 0, 0, 1,
}
scene:transform(hard_group, hard_final_matrix, 0.85, "ease_in_out")

local aa_group = root:group {matrix = {
    final_scale, 0, 0, aa_tx,
    0, final_scale, 0, aa_ty,
    0, 0, 1, 0,
    0, 0, 0, 1,
}, id = "aa-grid-group"}
local aa_space = aa_group:space {
    x = {0, 12, 1},
    y = {0, 8, 1},
    opacity = 0,
    matrix = {
        grid_scale, 0, 0, grid_x,
        0, grid_scale, 0, grid_y,
        0, 0, 1, 0,
        0, 0, 0, 1,
    },
    id = "aa-grid-space",
}
aa_space:cell {
    origin = {0, 0},
    size = {12, 8},
    mode = "padd",
    padding = 0.055,
    color = palette.panel,
    patches = aa_patches,
    layer = LAYER.background,
    id = "aa-coverage",
}
aa_space:line {
    from = {0, intercept},
    to = {12, slope * 12 + intercept},
    color = palette.coral,
    width = 2.5,
    layer = LAYER.vector,
    id = "aa-edge",
}
scene:fade_in(aa_group, {scale = 0.98, duration = 0.65, curve = "gentle"})
scene:wait(0.90)
scene:fade_in(caption_4, {shift = {0, 0.06}, duration = 0.30, curve = "ease_out"})

local code_smooth = label(
    root,
    "float alpha = 1.0 - smoothstep(-w, w, d);",
    {0.70, -0.68},
    14,
    palette.green,
    "code-smoothstep",
    {0, 0.5}
)
scene:fade_transform(code_hard, code_smooth, 0.55, "gentle")
local code_final_note = label(
    root,
    "fwidth는 비균일 분기 밖에서 계산",
    {0.70, -2.43},
    12,
    palette.muted,
    "code-final-note",
    {0, 0.5}
)
scene:fade_in(code_final_note, {duration = 0.35, curve = "gentle"})
scene:wait(0.90)

local final_labels = {
    label(root, "hard step", {hard_final_x, -1.82}, 13, palette.coral, "hard-final-label"),
    label(root, "fwidth + smoothstep", {aa_final_x, -1.82}, 13, palette.green, "aa-final-label"),
    label(root, "dot  →  경계에 수직인 signed distance", {-6.85, -2.45}, 13, palette.cyan, "takeaway-dot", {0, 0.5}),
    label(root, "fwidth  →  화면 공간 한 픽셀의 거리 변화", {-6.85, -2.84}, 13, palette.gold, "takeaway-fwidth", {0, 0.5}),
}
scene:create(final_labels, 0.45, "ease_out", 0.055)
scene:indicate(code_smooth, {scale = 1.035, duration = 0.55, curve = "gentle"})
scene:wait(2.50)

return scene
