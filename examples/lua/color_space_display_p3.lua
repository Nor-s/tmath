local p = {
    paper = "#f3f0e8",
    panel = "#fffdfa",
    ink = "#202124",
    muted = "#666a73",
    soft = "#8a8e96",
    rule = "#d8d4cb",
    grid = "#d7d3ca",
    srgb = "#315f91",
    p3 = "#d23c72",
    white = "#fff6cf",
    highlight = "#19a974",
}

local function clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

local function gamma(value)
    if value <= 0.0031308 then
        return 12.92 * value
    end
    return 1.055 * value ^ (1 / 2.4) - 0.055
end

local function hex(rgb, alpha)
    local r = math.floor(clamp(gamma(clamp(rgb[1], 0, 1)), 0, 1) * 255 + 0.5)
    local g = math.floor(clamp(gamma(clamp(rgb[2], 0, 1)), 0, 1) * 255 + 0.5)
    local b = math.floor(clamp(gamma(clamp(rgb[3], 0, 1)), 0, 1) * 255 + 0.5)
    return string.format("#%02x%02x%02x%s", r, g, b, alpha or "ff")
end

-- CSS Color 4 matrices, D65. Display P3 uses the sRGB transfer curve.
local p3_to_xyz = {
    0.4865709486,
    0.2656676932,
    0.1982172852,
    0.2289745641,
    0.6917385218,
    0.0792869141,
    0.0000000000,
    0.0451133819,
    1.0439443689,
}
local xyz_to_p3 = {
    2.4934969119,
    -0.9313836179,
    -0.4027107845,
    -0.8294889696,
    1.7626640603,
    0.0236246858,
    0.0358458302,
    -0.0761723893,
    0.9568845240,
}
local srgb_to_xyz = {
    0.4123907993,
    0.3575843394,
    0.1804807884,
    0.2126390059,
    0.7151686788,
    0.0721923154,
    0.0193308187,
    0.1191947798,
    0.9505321522,
}
local xyz_to_srgb = {
    3.2409699419,
    -1.5373831776,
    -0.4986107603,
    -0.9692436363,
    1.8759675015,
    0.0415550574,
    0.0556300797,
    -0.2039769589,
    1.0569715142,
}

local function mul3(matrix, vector)
    return {
        matrix[1] * vector[1] + matrix[2] * vector[2] + matrix[3] * vector[3],
        matrix[4] * vector[1] + matrix[5] * vector[2] + matrix[6] * vector[3],
        matrix[7] * vector[1] + matrix[8] * vector[2] + matrix[9] * vector[3],
    }
end

local function rgb_to_xyY(rgb, matrix)
    local xyz = mul3(matrix, rgb)
    local total = xyz[1] + xyz[2] + xyz[3]
    if total < 1e-8 then
        return nil
    end
    return { xyz[1] / total, xyz[2] / total, xyz[2] }
end

local function xyY_to_rgb(x, y, Y, matrix)
    if y <= 0 or x + y > 1 then
        return nil
    end
    local xyz = { x * Y / y, Y, (1 - x - y) * Y / y }
    return mul3(matrix, xyz)
end

local function in_unit_cube(rgb)
    local e = 1e-5
    return rgb
        and rgb[1] >= -e
        and rgb[1] <= 1 + e
        and rgb[2] >= -e
        and rgb[2] <= 1 + e
        and rgb[3] >= -e
        and rgb[3] <= 1 + e
end

-- Official CIE 1931 2° spectrum-locus data, sampled every 10 nm from 380–700 nm.
local spectral_xy = {
    { 0.17411, 0.00496 },
    { 0.17380, 0.00492 },
    { 0.17334, 0.00480 },
    { 0.17258, 0.00480 },
    { 0.17141, 0.00510 },
    { 0.16888, 0.00690 },
    { 0.16441, 0.01086 },
    { 0.15664, 0.01771 },
    { 0.14396, 0.02970 },
    { 0.12412, 0.05780 },
    { 0.09129, 0.13270 },
    { 0.04539, 0.29498 },
    { 0.00817, 0.53842 },
    { 0.01387, 0.75019 },
    { 0.07430, 0.83380 },
    { 0.15472, 0.80586 },
    { 0.22962, 0.75433 },
    { 0.30160, 0.69231 },
    { 0.37310, 0.62445 },
    { 0.44406, 0.55472 },
    { 0.51249, 0.48659 },
    { 0.57515, 0.42423 },
    { 0.62704, 0.37249 },
    { 0.66576, 0.33401 },
    { 0.69151, 0.30834 },
    { 0.70792, 0.29203 },
    { 0.71903, 0.28094 },
    { 0.72599, 0.27401 },
    { 0.72997, 0.27003 },
    { 0.73199, 0.26801 },
    { 0.73342, 0.26658 },
    { 0.73439, 0.26561 },
    { 0.73469, 0.26531 },
}

local function inside_polygon(x, y, polygon)
    local inside, j = false, #polygon
    for i = 1, #polygon do
        local xi, yi = polygon[i][1], polygon[i][2]
        local xj, yj = polygon[j][1], polygon[j][2]
        if ((yi > y) ~= (yj > y)) and x < (xj - xi) * (y - yi) / (yj - yi) + xi then
            inside = not inside
        end
        j = i
    end
    return inside
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
page_text("COLOR SPACE  /  xyY VOLUME", { -7.25, 3.78 }, 12, p.p3, "eyebrow", { 0, 0.5 })
page_text(
    "Display P3 is a three-dimensional color volume",
    { -7.25, 3.29 },
    27,
    p.ink,
    "title",
    { 0, 0.5 }
)
page_text(
    "Chromaticity bends across x and y; luminance Y gives the gamut its depth.",
    { -7.25, 2.72 },
    14,
    p.muted,
    "subtitle",
    { 0, 0.5 }
)
page_root:line { from = { -7.25, 2.53 }, to = { 7.25, 2.53 }, color = p.rule, width = 1 }
page_text(
    "Visualization uses W3C D65 matrices; hex output is an sRGB-display proxy for P3 samples.",
    { 0, -4.13 },
    10,
    p.muted,
    "output-note"
)
page:create({ page_root }, 0.45, "ease_out")

local volume_scene = tmath.scene {
    width = 614,
    height = 373,
    fps = 30,
    background = p.panel,
    camera = {
        mode = "fixed",
        view = "3d",
        eye = { 8.8, 7.2, 9.4 },
        target = { 2.75, 2.8, 2.15 },
        up = { 0, 1, 0 },
        projection = "perspective",
        fov = 0.62,
        near = 0.1,
        far = 100,
    },
}
local volume = volume_scene:space {
    x = { 0, 0.8, 0.2 },
    y = { 0, 0.9, 0.2 },
    z = { 0, 1, 0.25 },
    color = p.grid,
    axis_x = "#716c65",
    axis_y = "#716c65",
    axis_z = "#716c65",
    width = 1,
    matrix = { 7, 0, 0, 0, 0, 7, 0, 0, 0, 0, 4.8, 0, 0, 0, 0, 1 },
    id = "xyY-space",
}
local raster = volume:space {
    x = { 0, 42, 1 },
    y = { 0, 46, 1 },
    z = { 0, 1, 1 },
    opacity = 0,
    matrix = { 0.8 / 42, 0, 0, 0, 0, 0.9 / 46, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 },
}

local slices = {}
for layer = 1, 13 do
    local Y = 0.03 + (layer - 1) * 0.078
    local patches = {}
    for row = 0, 45 do
        for column = 0, 41 do
            local x = (column + 0.5) * 0.8 / 42
            local y = (row + 0.5) * 0.9 / 46
            local rgb = xyY_to_rgb(x, y, Y, xyz_to_p3)
            if in_unit_cube(rgb) then
                patches[#patches + 1] = {
                    region = { column, row, 1, 1 },
                    color = hex(rgb, "dc"),
                }
            end
        end
    end
    slices[#slices + 1] = raster:cell {
        origin = { 0, 0, Y },
        size = { 42, 46 },
        depth = 0.010,
        mode = "full",
        color = "#00000000",
        patches = patches,
        id = "p3-slice-" .. layer,
    }
end

local function gamut_edges(matrix, color, prefix)
    local edges = {}
    for variable = 1, 3 do
        local a = variable % 3 + 1
        local b = (variable + 1) % 3 + 1
        for va = 0, 1 do
            for vb = 0, 1 do
                local points = {}
                for sample = 0, 40 do
                    local rgb = { 0, 0, 0 }
                    rgb[variable], rgb[a], rgb[b] = sample / 40, va, vb
                    local point = rgb_to_xyY(rgb, matrix)
                    if point then
                        points[#points + 1] = point
                    end
                end
                if #points > 1 then
                    edges[#edges + 1] = volume:plot {
                        points = points,
                        color = color,
                        width = 2.2,
                        id = prefix .. "-edge-" .. variable .. "-" .. va .. vb,
                    }
                end
            end
        end
    end
    return edges
end

local srgb_edges = gamut_edges(srgb_to_xyz, "#315f91bb", "srgb")
local p3_edges = gamut_edges(p3_to_xyz, "#d23c72dd", "p3")
local p3_primaries = {
    rgb_to_xyY({ 1, 0, 0 }, p3_to_xyz),
    rgb_to_xyY({ 0, 1, 0 }, p3_to_xyz),
    rgb_to_xyY({ 0, 0, 1 }, p3_to_xyz),
}
local markers = {}
local marker_colors = { "#ff4e48", "#40c85a", "#4d6cff" }
local marker_names = { "R", "G", "B" }
for i, point in ipairs(p3_primaries) do
    markers[#markers + 1] = volume:point {
        point = point,
        fill = marker_colors[i],
        stroke = p.panel,
        width = 2,
        radius = 6,
        id = "p3-primary-" .. marker_names[i],
    }
    markers[#markers + 1] = volume:text {
        text = marker_names[i],
        point = { point[1], point[2], point[3] + 0.045 },
        size = 12,
        font = "Pretendard",
        fill = marker_colors[i],
    }
end
local white = volume:point {
    point = { 0.3127, 0.3290, 1 },
    fill = p.white,
    stroke = p.ink,
    width = 2,
    radius = 6,
    id = "d65-white",
}
local axis_labels = {
    volume:text {
        text = "x",
        point = { 0.84, 0, 0 },
        size = 12,
        font = "Pretendard",
        fill = p.muted,
    },
    volume:text {
        text = "y",
        point = { 0, 0.69, 0 },
        size = 12,
        font = "Pretendard",
        fill = p.muted,
    },
    volume:text {
        text = "Y",
        point = { 0, 0, 1.06 },
        size = 12,
        font = "Pretendard",
        fill = p.muted,
    },
}

volume_scene:create(volume, 0.45, "ease_out")
volume_scene:create(srgb_edges, 0.75, "linear", 0.018)
volume_scene:create(slices, 1.45, "linear", 0.065)
volume_scene:create(p3_edges, 0.85, "ease_out", 0.018)
volume_scene:create(markers, 0.38, "ease_out", 0.035)
volume_scene:fade_in(white, { scale = 0.55, duration = 0.28, easing = "ease_out" })
volume_scene:create(axis_labels, 0.28, "ease_out", 0.04)
volume_scene:look({
    view = "3d",
    eye = { 9.5, 9.0, 6.9 },
    target = { 2.75, 2.8, 2.15 },
    up = { 0, 1, 0 },
    projection = "perspective",
    fov = 0.62,
    near = 0.1,
    far = 100,
}, 1.45, "ease_in_out")
volume_scene:wait(0.55)

local slice_scene = tmath.scene {
    width = 269,
    height = 373,
    fps = 30,
    background = p.panel,
    camera = { mode = "fixed", view = "2d", height = 9 },
}
local side = slice_scene:space { x = { -3.25, 3.25, 1 }, y = { -4.5, 4.5, 1 }, opacity = 0 }
local function side_text(value, point, size, color, align)
    return side:text {
        text = value,
        point = point,
        size = size,
        font = "Pretendard",
        fill = color or p.ink,
        align = align or { 0.5, 0.5 },
    }
end
side_text("CHROMATICITY SLICE", { -2.72, 3.90 }, 11, p.soft, { 0, 0.5 })
side_text("Y = 0.50", { -2.72, 3.48 }, 20, p.ink, { 0, 0.5 })
side_text("CIE locus · 10 nm samples", { -2.72, 3.04 }, 10, p.muted, { 0, 0.5 })

local columns, rows = 52, 58
local chart = side:space {
    x = { 0, columns, 1 },
    y = { 0, rows, 1 },
    opacity = 0,
    matrix = { 5.10 / columns, 0, 0, -2.55, 0, 5.72 / rows, 0, -2.55, 0, 0, 1, 0, 0, 0, 0, 1 },
}
local gradient_patches = {}
for row = 0, rows - 1 do
    for column = 0, columns - 1 do
        local x = (column + 0.5) * 0.78 / columns
        local y = (row + 0.5) * 0.87 / rows
        if inside_polygon(x, y, spectral_xy) then
            local rgb = xyY_to_rgb(x, y, 0.5, xyz_to_srgb)
            if rgb then
                local maximum = math.max(rgb[1], rgb[2], rgb[3])
                if maximum > 1 then
                    rgb = { rgb[1] / maximum, rgb[2] / maximum, rgb[3] / maximum }
                end
                gradient_patches[#gradient_patches + 1] = {
                    region = { column, row, 1, 1 },
                    color = hex(rgb),
                }
            end
        end
    end
end
local gradient = chart:cell {
    origin = { 0, 0 },
    size = { columns, rows },
    mode = "full",
    color = "#00000000",
    patches = gradient_patches,
    id = "chromaticity-gradient",
}
local function chart_xy(x, y)
    return { -2.55 + x / 0.78 * 5.10, -2.55 + y / 0.87 * 5.72 }
end
local locus_points = {}
for i, point in ipairs(spectral_xy) do
    locus_points[i] = chart_xy(point[1], point[2])
end
local spectrum =
    side:plot { points = locus_points, color = "#ffffffee", width = 2.5, id = "spectral-locus" }
local purple = side:line {
    from = locus_points[#locus_points],
    to = locus_points[1],
    color = "#9b5bc5",
    width = 2.5,
}
local srgb_xy = { { 0.640, 0.330 }, { 0.300, 0.600 }, { 0.150, 0.060 } }
local p3_xy = { { 0.680, 0.320 }, { 0.265, 0.690 }, { 0.150, 0.060 } }
local function triangle(points, color, width, id)
    local result = {}
    for i, point in ipairs(points) do
        result[i] = chart_xy(point[1], point[2])
    end
    return side:polygon {
        points = result,
        fill = "#00000000",
        stroke = color,
        width = width,
        id = id,
    }
end
local srgb_triangle = triangle(srgb_xy, p.srgb, 2.5, "srgb-slice")
local p3_triangle = triangle(p3_xy, p.p3, 3.4, "p3-slice")
local d65 = chart_xy(0.3127, 0.3290)
local d65_point =
    side:point { point = d65, fill = p.white, stroke = p.ink, width = 1.5, radius = 5 }
local legend = {
    side:line { from = { -2.60, -3.20 }, to = { -1.95, -3.20 }, color = p.srgb, width = 3 },
    side_text("sRGB", { -1.77, -3.20 }, 10, p.srgb, { 0, 0.5 }),
    side:line { from = { 0.15, -3.20 }, to = { 0.80, -3.20 }, color = p.p3, width = 3.5 },
    side_text("Display P3", { 0.98, -3.20 }, 10, p.p3, { 0, 0.5 }),
    side_text("curved xyY volume ≠ flat triangle", { 0, -3.72 }, 10, p.muted),
}

slice_scene:create(gradient, 1.35, "linear")
slice_scene:create({ spectrum, purple }, 0.75, "linear", 0.04)
slice_scene:create(srgb_triangle, 0.55, "ease_out")
slice_scene:create(p3_triangle, 0.65, "ease_out")
slice_scene:indicate(
    p3_triangle,
    { color = p.p3, scale = 1.025, duration = 0.58, easing = "ease_in_out" }
)
slice_scene:fade_in(d65_point, { scale = 0.55, duration = 0.25, easing = "ease_out" })
slice_scene:create(legend, 0.40, "ease_out", 0.04)
slice_scene:wait(1.80)

page:viewport(volume_scene, { x = 0.025, y = 0.225, width = 0.64, height = 0.69 })
page:viewport(slice_scene, { x = 0.69, y = 0.225, width = 0.285, height = 0.69 })
return page
