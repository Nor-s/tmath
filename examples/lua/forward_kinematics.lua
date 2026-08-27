local p = {
    paper = "#f7f5ef",
    panel = "#fffefa",
    ink = "#202124",
    muted = "#626873",
    soft = "#8b9098",
    rule = "#d9d7d0",
    grid = "#e8e5de",
    bone = "#567596",
    joint = "#ffffff",
    active = "#d13d72",
    target = "#e26a3d",
    success = "#268768",
    angle = "#b27b35",
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
local function translate(x, y)
    return { 1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, 0, 0, 0, 0, 1 }
end
local function arc(center, r, a0, a1, color, id)
    local pts = {}
    for i = 0, 24 do
        local a = a0 + (a1 - a0) * i / 24
        pts[#pts + 1] = { center[1] + r * math.cos(a), center[2] + r * math.sin(a) }
    end
    return root:plot { points = pts, color = color, width = 3, id = id }
end

text("KINEMATICS  /  FORWARD", { -7.2, 3.72 }, 12, p.active, "eyebrow", { 0, 0.5 })
text("Forward kinematics accumulates joint angles", { -7.2, 3.25 }, 27, p.ink, "title", { 0, 0.5 })
text(
    "Known rotations determine every joint position, from the fixed base to the end effector.",
    { -7.2, 2.72 },
    14,
    p.muted,
    "subtitle",
    { 0, 0.5 }
)
root:line { from = { -7.2, 2.48 }, to = { 7.2, 2.48 }, color = p.rule, width = 1 }
text("input: theta1, theta2, theta3  ->  output: p1, p2, p3", { 0, -4.08 }, 11, p.muted, "footer")
root:rectangle {
    center = { -3.78, -0.38 },
    size = { 6.55, 5.30 },
    corner = 0.14,
    fill = p.panel,
    stroke = p.rule,
    width = 1.5,
    id = "arm-panel",
}
root:rectangle {
    center = { 3.38, -0.38 },
    size = { 6.30, 5.30 },
    corner = 0.14,
    fill = p.panel,
    stroke = p.rule,
    width = 1.5,
    id = "formula-panel",
}
text("ARTICULATED CHAIN", { -6.72, 1.92 }, 12, p.soft, "chain-label", { 0, 0.5 })
text("ACCUMULATED TRANSFORMS", { 0.72, 1.92 }, 12, p.soft, "formula-label", { 0, 0.5 })

local initial = { { -5.8, -1.45 }, { -4.35, -1.45 }, { -3.00, -1.45 }, { -1.80, -1.45 } }
local pose1 = { { -5.8, -1.45 }, { -4.689, -0.518 }, { -3.655, 0.350 }, { -2.736, 1.121 } }
local pose2 = { { -5.8, -1.45 }, { -4.689, -0.518 }, { -3.385, -0.867 }, { -2.226, -1.178 } }
local pose3 = { { -5.8, -1.45 }, { -4.689, -0.518 }, { -3.385, -0.867 }, { -2.697, 0.116 } }
local current = { { -5.8, -1.45 }, { -4.35, -1.45 }, { -3.00, -1.45 }, { -1.80, -1.45 } }
local joints, bodies = {}, {}
for i, q in ipairs(initial) do
    local node = root:group { matrix = translate(q[1], q[2]), id = "joint-" .. (i - 1) }
    local body = node:circle {
        radius = 0.21,
        fill = p.joint,
        stroke = i == 1 and p.active or p.bone,
        width = 3,
        layer = 4,
        id = "joint-body-" .. (i - 1),
    }
    node:text {
        text = "J" .. (i - 1),
        point = { 0, 0 },
        font = "Pretendard",
        size = 10,
        fill = p.ink,
        layer = 5,
    }
    joints[i] = node
    bodies[i] = body
end
local links = {}
for i = 1, 3 do
    links[i] = root:connector {
        from = joints[i],
        to = joints[i + 1],
        padding = 0.05,
        stroke = p.bone,
        width = 7,
        layer = 2,
        id = "link-" .. i,
    }
end
local base = root:polygon {
    points = { { -6.16, -1.76 }, { -5.44, -1.76 }, { -5.58, -1.54 }, { -6.02, -1.54 } },
    fill = "#c9c6bf",
    stroke = p.soft,
    width = 1.5,
    id = "fixed-base",
}
local target = root:group { matrix = translate(pose3[4][1], pose3[4][2]), id = "fk-target" }
target:circle { radius = 0.30, fill = "#ffffff00", stroke = p.target, width = 3 }
target:line { from = { -0.17, 0 }, to = { 0.17, 0 }, color = p.target, width = 2 }
target:line { from = { 0, -0.17 }, to = { 0, 0.17 }, color = p.target, width = 2 }

local cards = {}
local card_text = { "1  theta1 = +40 deg", "2  theta2 = -55 deg", "3  theta3 = +70 deg" }
for i = 1, 3 do
    local y = 1.26 - (i - 1) * 0.54
    cards[i] = root:rectangle {
        center = { 1.65, y },
        size = { 1.92, 0.40 },
        corner = 0.08,
        fill = "#f1f2f2",
        stroke = p.rule,
        width = 1.5,
        id = "angle-card-" .. i,
    }
    text(card_text[i], { 1.65, y }, 11, i == 1 and p.active or p.ink)
end
local formulas = {
    text("phi1 = theta1", { 3.55, 1.26 }, 13, p.active, nil, { 0, 0.5 }),
    text("phi2 = theta1 + theta2", { 3.55, 0.72 }, 13, p.angle, nil, { 0, 0.5 }),
    text("phi3 = theta1 + theta2 + theta3", { 3.55, 0.18 }, 13, p.success, nil, { 0, 0.5 }),
    text(
        "p_k = p_0 + sum L_i [cos(phi_i), sin(phi_i)]",
        { 0.82, -0.48 },
        13,
        p.ink,
        nil,
        { 0, 0.5 }
    ),
    text("angles accumulate; lengths stay constant", { 0.82, -0.92 }, 11, p.muted, nil, { 0, 0.5 }),
}
local result_box = root:rectangle {
    center = { 3.65, -1.80 },
    size = { 5.25, 1.18 },
    corner = 0.10,
    fill = "#f7f4ee",
    stroke = p.rule,
    width = 1.5,
    id = "fk-result",
}
local results = {
    text("end effector", { 1.20, -1.55 }, 10, p.soft, nil, { 0, 0.5 }),
    text("p3 = (-2.697, 0.116)", { 1.20, -1.93 }, 16, p.success, nil, { 0, 0.5 }),
    text("T = R(theta1) * R(theta2) * R(theta3)", { 1.20, -2.28 }, 11, p.muted, nil, { 0, 0.5 }),
}
scene:create(
    { base, links[1], links[2], links[3], joints[1], joints[2], joints[3], joints[4], target },
    0.78,
    "ease_out",
    0.065
)
scene:create({
    cards[1],
    cards[2],
    cards[3],
    formulas[1],
    formulas[2],
    formulas[3],
    formulas[4],
    formulas[5],
    result_box,
}, 0.58, "ease_out", 0.04)

local function move_pose(nextpose, first, duration)
    local moves = {}
    for i = first, 4 do
        moves[#moves + 1] = {
            target = joints[i],
            shift = { nextpose[i][1] - current[i][1], nextpose[i][2] - current[i][2] },
        }
    end
    scene:play(moves, duration, "ease_in_out", 0)
    for i = first, 4 do
        current[i] = { nextpose[i][1], nextpose[i][2] }
    end
end
scene:fill(cards[1], "#f6dbe5", 0.30, "ease_out")
move_pose(pose1, 2, 1.05)
local a1 = arc(pose1[1], 0.58, 0, math.rad(40), p.active, "theta-1-arc")
scene:create({ a1, text("theta1", { -5.15, -0.91 }, 11, p.active) }, 0.42, "ease_out", 0.05)
scene:indicate(
    bodies[1],
    { color = p.active, scale = 1.25, duration = 0.42, easing = "ease_in_out" }
)
scene:fill(cards[1], "#f1f2f2", 0.20, "ease_in")
scene:fill(cards[2], "#f5ead8", 0.30, "ease_out")
move_pose(pose2, 3, 1.05)
local a2 = arc(pose2[2], 0.50, math.rad(40), math.rad(-15), p.angle, "theta-2-arc")
scene:create({ a2, text("theta2", { -4.10, -1.02 }, 11, p.angle) }, 0.42, "ease_out", 0.05)
scene:indicate(
    bodies[2],
    { color = p.angle, scale = 1.25, duration = 0.42, easing = "ease_in_out" }
)
scene:fill(cards[2], "#f1f2f2", 0.20, "ease_in")
scene:fill(cards[3], "#dceee7", 0.30, "ease_out")
move_pose(pose3, 4, 1.05)
local a3 = arc(pose3[3], 0.46, math.rad(-15), math.rad(55), p.success, "theta-3-arc")
scene:create({ a3, text("theta3", { -2.92, -0.35 }, 11, p.success) }, 0.42, "ease_out", 0.05)
scene:indicate(
    bodies[4],
    { color = p.success, scale = 1.24, duration = 0.48, easing = "ease_in_out" }
)
scene:create(results, 0.48, "ease_out", 0.07)
scene:wait(1.2)
return scene
