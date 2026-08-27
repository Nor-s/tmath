-- Visual direction: the folded, periodic volume language of nimitz's
-- "Protean Clouds" on ShaderToy (https://www.shadertoy.com/view/3l23Rh).
-- This is an original, compact tmath field rather than a shader-code port.

local tau = 2 * math.pi
local duration = 6.0
local background = "#050713"

local function clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

local function mix(a, b, t)
    return a + (b - a) * t
end

local function fract(value)
    return value - math.floor(value)
end

local function rgba(red, green, blue, alpha)
    return string.format(
        "#%02x%02x%02x%02x",
        math.floor(clamp(red, 0, 255) + 0.5),
        math.floor(clamp(green, 0, 255) + 0.5),
        math.floor(clamp(blue, 0, 255) + 0.5),
        math.floor(clamp(alpha, 0, 255) + 0.5)
    )
end

local function phase_at(time)
    return tau * time / duration
end

local function nebula_density(x, y, z, phase)
    local qx = x + 0.34 * math.sin(1.15 * y + phase) + 0.16 * math.cos(1.45 * z - phase)
    local qy = y + 0.27 * math.sin(1.35 * z - 0.7 * phase) + 0.12 * math.cos(1.25 * x + phase)
    local qz = z + 0.32 * math.cos(1.10 * x + 0.8 * phase) + 0.15 * math.sin(1.55 * y - phase)

    local radius = math.sqrt(qx * qx + 0.72 * qy * qy + qz * qz)
    local envelope = 1.20 - radius / 2.35
    local folds = 0.18 * (
        math.sin(2.25 * qx + 0.55 * phase) +
        math.sin(2.05 * qy - 0.70 * phase) +
        math.cos(2.30 * qz + 0.45 * phase)
    )
    local ribbon = 0.28 * math.cos(2.75 * math.sqrt(qx * qx + qz * qz) - 1.20 * qy - phase)

    local orbit_x = 0.95 * math.cos(phase)
    local orbit_y = 0.42 * math.sin(2 * phase)
    local orbit_z = 0.95 * math.sin(phase)
    local dx = qx - orbit_x
    local dy = qy - orbit_y
    local dz = qz - orbit_z
    local knot = 0.55 - math.sqrt(dx * dx + dy * dy + dz * dz) / 0.78

    return math.max(envelope + folds + ribbon, knot + 0.42)
end

local function nebula_color(density, x, y, z, alpha_scale)
    local t = clamp((density - 0.18) / 1.04, 0, 1)
    local red, green, blue
    if t < 0.46 then
        local u = t / 0.46
        red = mix(20, 102, u)
        green = mix(18, 43, u)
        blue = mix(52, 168, u)
    elseif t < 0.78 then
        local u = (t - 0.46) / 0.32
        red = mix(102, 48, u)
        green = mix(43, 205, u)
        blue = mix(168, 225, u)
    else
        local u = (t - 0.78) / 0.22
        red = mix(48, 248, u)
        green = mix(205, 208, u)
        blue = mix(225, 166, u)
    end

    local shimmer = 0.88 + 0.12 * math.sin(1.8 * x - 1.4 * y + 1.2 * z)
    return rgba(red * shimmer, green * shimmer, blue * shimmer, alpha_scale * (0.52 + 0.48 * t))
end

local cell_view = tmath.scene {
    width = 480,
    height = 480,
    fps = 30,
    loop = true,
    antialiasing = false,
    background = background,
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.4},
}

local cell_space = cell_view:space {
    x = {-3.2, 3.2, 0.14},
    y = {-3.2, 3.2, 0.14},
    opacity = 0,
    id = "nebula-cell-space",
}

cell_space:cell(function(x, y, time)
    local phase = phase_at(time)
    local slice_z = 0.52 * math.sin(phase)
    local density = nebula_density(0.88 * x, 0.88 * y, slice_z, phase)
    if density > 0.20 then
        return nebula_color(density, x, y, slice_z, 255)
    end

    local star = fract(math.sin(91.7 * x + 151.3 * y) * 43758.5453)
    if star > 0.995 then
        local twinkle = 0.72 + 0.28 * math.sin(phase + star * tau)
        return rgba(196 * twinkle, 225 * twinkle, 255, 245)
    end
    return "#00000000"
end, {
    mode = "padd",
    padding = 0.035,
})
cell_view:wait(duration)

local voxel_view = tmath.scene {
    width = 480,
    height = 480,
    fps = 30,
    loop = true,
    antialiasing = true,
    background = background,
    camera = {
        mode = "fixed",
        view = "3d",
        eye = {5.1, 3.8, 6.0},
        target = {0, 0, 0},
        up = {0, 1, 0},
        projection = "perspective",
        fov = 0.68,
        near = 0.1,
        far = 100,
    },
}

local voxel_space = voxel_view:space {
    x = {-2.8, 2.8, 0.45},
    y = {-2.45, 2.45, 0.45},
    z = {-2.8, 2.8, 0.45},
    opacity = 0,
    id = "nebula-voxel-space",
}

voxel_space:voxel(function(x, y, z, time)
    local phase = phase_at(time)
    local density = nebula_density(x, y, z, phase)
    if density < 0.48 then
        return "#00000000"
    end
    return nebula_color(density, x, y, z, 235)
end, {
    mode = "padd",
    padding = 0.11,
})
voxel_view:look({eye = {-5.2, 3.7, 5.9}}, duration * 0.5, "ease_in_out")
voxel_view:look({eye = {5.1, 3.8, 6.0}}, duration * 0.5, "ease_in_out")

local page = tmath.scene {
    width = 960,
    height = 480,
    fps = 30,
    loop = true,
    antialiasing = true,
    background = background,
}

page:viewport(cell_view, {x = 0, y = 0, width = 0.5, height = 1})
page:viewport(voxel_view, {x = 0.5, y = 0, width = 0.5, height = 1})
return page
