-- Read one quadratic locally with a derivative and globally with an integral.
local function f(x) return 0.25 * x * x - 0.5 end
local function df(x) return 0.5 * x end
local function antiderivative(x) return x^3 / 12 - x / 2 end
local subscriptDigits = {'₀', '₁', '₂', '₃', '₄', '₅', '₆', '₇', '₈', '₉'}
local superscriptDigits = {'⁰', '¹', '²', '³', '⁴', '⁵', '⁶', '⁷', '⁸', '⁹'}
local function styledInteger(value, digits)
    if value == 0 then return digits[1] end
    local result, number = "", math.floor(value)
    while number > 0 do
        result = digits[number % 10 + 1] .. result
        number = math.floor(number / 10)
    end
    return result
end
local function subscript(value) return styledInteger(value, subscriptDigits) end
local function superscript(value) return styledInteger(value, superscriptDigits) end

local function diskPoints(center)
    local points = {}
    for i = 0, 11 do
        local angle = 2 * math.pi * i / 12
        points[#points + 1] = {center[1] + 0.09 * math.cos(angle), center[2] + 0.09 * math.sin(angle)}
    end
    return points
end

-- Build compatible point and tangent geometry for source-preserving state morphs.
local function derivativeState(space, x, suffix)
    local y, slope, half = f(x), df(x), 1.25
    local tangent = {{x - half, y - slope * half}, {x + half, y + slope * half}}
    return space:polygon {id = "derivative-point-" .. suffix, points = diskPoints({x, y}), fill = "secondary", stroke = "secondary", layer = 20},
           space:plot {id = "derivative-tangent-" .. suffix, points = tangent, stroke = "result", width = 4, layer = 10}
end
local function slopeText(scene, x, suffix)
    return scene:text {
        id = "derivative-value-" .. suffix,
        text = string.format("x = %.1f    f'(x) = %.2f", x, df(x)),
        point = {0, 2.75}, role = "code", fill = "result", align = {0.5, 0.5}, layer = 40,
    }
end

local function derivativePanel()
    local scene = tmath.scene {
        width = 480, height = 540, fps = 30, loop = false,
        camera = {mode = "fixed", view = "2d", target = {0, 0.25}, height = 7},
    }
    local space = scene:space {id = "derivative-space", x = {-3, 3, 1}, y = {-2, 2, 1}, numbers = true, stroke = "border", width = 1}
    local curve = space:plot {id = "derivative-curve", fn = f, x_range = {-3, 3, 0.06}, stroke = "accent", width = 4, layer = 5}
    local formula = scene:text {id = "derivative-function", text = "f(x) = x²/4 − 1/2", point = {0, -2.65}, role = "code", fill = "accent", layer = 40}
    local values = {-1.8, 0.6, 1.8}
    local suffixes = {"a", "b", "c"}
    local point, tangent = derivativeState(space, values[1], suffixes[1])
    local value = slopeText(scene, values[1], suffixes[1])

    scene:create(space, 0.45, "ease_out")
    scene:create(curve, 0.9, "ease_out")
    scene:create({point, tangent}, 0.55, "ease_out", 0.06)
    scene:fade_in(value, {shift = {0, 0.08}, duration = 0.28, curve = "gentle"})
    scene:wait(0.45)
    for i = 2, #values do
        local nextPoint, nextTangent = derivativeState(space, values[i], suffixes[i])
        scene:morph({point, tangent}, {nextPoint, nextTangent}, 0.85, "ease_in_out")
        point, tangent = nextPoint, nextTangent
        scene:fade_out(value, {duration = 0.14, curve = "ease_in"})
        local nextValue = slopeText(scene, values[i], suffixes[i])
        scene:fade_in(nextValue, {shift = {0, 0.05}, duration = 0.2, curve = "gentle"})
        value = nextValue
        scene:wait(0.38)
    end
    scene:fade_in(formula, {shift = {0, -0.08}, duration = 0.3, curve = "gentle"})
    scene:wait(1.25)
    return scene
end

local function integralPanel()
    local scene = tmath.scene {
        width = 480, height = 540, fps = 30, loop = false,
        camera = {mode = "fixed", view = "2d", target = {1.5, 0.25}, height = 7},
    }
    local space = scene:space {id = "integral-space", x = {-1, 4, 1}, y = {-2, 2, 1}, numbers = true, stroke = "border", width = 1}
    local curve = space:plot {id = "integral-curve", fn = f, x_range = {-1, 4, 0.06}, stroke = "accent", width = 4, layer = 5}
    local a, b, slices = 0, 3, 8
    local dx = (b - a) / slices
    local rectangles, riemannSum = {}, 0
    for i = 0, slices - 1 do
        local left, right = a + i * dx, a + (i + 1) * dx
        local height = f(right)
        riemannSum = riemannSum + height * dx
        rectangles[#rectangles + 1] = space:polygon {
            id = "integral-rect-" .. i,
            points = {{left, 0}, {right, 0}, {right, height}, {left, height}},
            fill = "result", stroke = "result", opacity = 0.25, width = 1.5, layer = 0,
        }
    end
    local dxMark = {
        space:line {from = {a, 0.18}, to = {a + dx, 0.18}, stroke = "secondary", width = 4, layer = 20},
        space:line {from = {a, 0.05}, to = {a, 0.31}, stroke = "secondary", width = 2, layer = 20},
        space:line {from = {a + dx, 0.05}, to = {a + dx, 0.31}, stroke = "secondary", width = 2, layer = 20},
    }
    local dxLabel = scene:text {id = "integral-dx", text = string.format("Δx = %.3f", dx), point = {1.5, 2.75}, role = "code", fill = "secondary", layer = 40}
    local integral = antiderivative(b) - antiderivative(a)
    local result = scene:text {
        id = "integral-result",
        text = string.format("Σ%s ≈ %.2f   →   ∫%s%s f(x) dx = %.2f",
                             subscript(slices), riemannSum, subscript(a), superscript(b), integral),
        point = {1.5, -2.65}, role = "code", fill = "result", layer = 40,
    }

    scene:create(space, 0.45, "ease_out")
    scene:create(curve, 0.9, "ease_out")
    scene:create(dxMark, 0.3, "ease_out", 0.04)
    scene:fade_in(dxLabel, {shift = {0, 0.08}, duration = 0.28, curve = "gentle"})
    scene:wait(0.35)
    scene:draw_border_then_fill(rectangles, 0.38, "ease_out", 0.09, "forward")
    scene:wait(0.55)
    scene:fade_in(result, {shift = {0, -0.08}, duration = 0.34, curve = "gentle"})
    scene:wait(1.25)
    return scene
end

-- Aspect-matched children keep each coordinate range independent in one figure.
local page = tmath.scene {width = 960, height = 540, fps = 30, loop = false}
page:viewport(derivativePanel(), {x = 0, y = 0, width = 0.5, height = 1})
page:viewport(integralPanel(), {x = 0.5, y = 0, width = 0.5, height = 1})
return page
