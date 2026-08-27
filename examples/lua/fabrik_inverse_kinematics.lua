local p = {
    paper = "#f7f5ef",
    panel = "#fffefa",
    ink = "#202124",
    muted = "#626873",
    soft = "#8b9098",
    rule = "#d9d7d0",
    bone = "#567596",
    joint = "#ffffff",
    backward = "#725a9a",
    forward = "#2d7f9d",
    target = "#e26a3d",
    success = "#268768",
    ring = "#c9bfd5",
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
local function text(v, q, s, c, id, a, o)
    return root:text {
        text = v,
        point = q,
        size = s,
        font = "Pretendard",
        fill = c or p.ink,
        id = id,
        align = a or { 0.5, 0.5 },
        opacity = o or 1,
    }
end
local function translate(x, y)
    return { 1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, 0, 0, 0, 0, 1 }
end
text("KINEMATICS  /  INVERSE", { -7.2, 3.72 }, 12, p.backward, "eyebrow", { 0, 0.5 })
text("FABRIK reaches with positions, not angles", { -7.2, 3.25 }, 27, p.ink, "title", { 0, 0.5 })
text(
    "Alternate backward and forward passes; every relocation projects a joint onto a fixed-length circle.",
    { -7.2, 2.72 },
    14,
    p.muted,
    "subtitle",
    { 0, 0.5 }
)
root:line { from = { -7.2, 2.48 }, to = { 7.2, 2.48 }, color = p.rule, width = 1 }
text(
    "FABRIK = Forward And Backward Reaching Inverse Kinematics",
    { 0, -4.08 },
    11,
    p.muted,
    "footer"
)
root:rectangle {
    center = { -3.78, -0.38 },
    size = { 6.55, 5.30 },
    corner = 0.14,
    fill = p.panel,
    stroke = p.rule,
    width = 1.5,
    id = "fabrik-panel",
}
root:rectangle {
    center = { 3.38, -0.38 },
    size = { 6.30, 5.30 },
    corner = 0.14,
    fill = p.panel,
    stroke = p.rule,
    width = 1.5,
    id = "algorithm-panel",
}
text("POSITION CONSTRAINTS", { -6.72, 1.92 }, 12, p.soft, "chain-label", { 0, 0.5 })
text("TWO-PASS ITERATION", { 0.72, 1.92 }, 12, p.soft, "algorithm-label", { 0, 0.5 })

local poses = {
    {
        { -5.500, -1.700 },
        { -4.305, -1.595 },
        { -3.242, -1.311 },
        { -2.246, -1.398 },
        {
            -1.377,
            -1.631,
        },
    },
    {
        { -5.500, -1.700 },
        { -4.305, -1.595 },
        { -3.242, -1.311 },
        { -2.246, -1.398 },
        {
            -2.900,
            0.600,
        },
    },
    {
        { -5.500, -1.700 },
        { -4.305, -1.595 },
        { -3.242, -1.311 },
        { -2.620, -0.255 },
        {
            -2.900,
            0.600,
        },
    },
    {
        { -5.500, -1.700 },
        { -4.305, -1.595 },
        { -3.128, -1.117 },
        { -2.620, -0.255 },
        {
            -2.900,
            0.600,
        },
    },
    {
        { -5.500, -1.700 },
        { -4.147, -1.531 },
        { -3.128, -1.117 },
        { -2.620, -0.255 },
        {
            -2.900,
            0.600,
        },
    },
    {
        { -5.337, -1.680 },
        { -4.147, -1.531 },
        { -3.128, -1.117 },
        { -2.620, -0.255 },
        {
            -2.900,
            0.600,
        },
    },
    {
        { -5.500, -1.700 },
        { -4.147, -1.531 },
        { -3.128, -1.117 },
        { -2.620, -0.255 },
        {
            -2.900,
            0.600,
        },
    },
    {
        { -5.500, -1.700 },
        { -4.309, -1.551 },
        { -3.128, -1.117 },
        { -2.620, -0.255 },
        {
            -2.900,
            0.600,
        },
    },
    {
        { -5.500, -1.700 },
        { -4.309, -1.551 },
        { -3.277, -1.172 },
        { -2.620, -0.255 },
        {
            -2.900,
            0.600,
        },
    },
    {
        { -5.500, -1.700 },
        { -4.309, -1.551 },
        { -3.277, -1.172 },
        { -2.694, -0.359 },
        {
            -2.900,
            0.600,
        },
    },
    {
        { -5.500, -1.700 },
        { -4.309, -1.551 },
        { -3.277, -1.172 },
        { -2.694, -0.359 },
        {
            -2.883,
            0.521,
        },
    },
    {
        { -5.500, -1.700 },
        { -4.311, -1.540 },
        { -3.286, -1.140 },
        { -2.730, -0.309 },
        {
            -2.896,
            0.576,
        },
    },
}
local lengths = { 1.2, 1.1, 1.0, 0.9 }
local target = { -2.900, 0.600 }
local basepoint = { -5.500, -1.700 }
local current = {}
for i, q in ipairs(poses[1]) do
    current[i] = { q[1], q[2] }
end
local joints, bodies = {}, {}
for i, q in ipairs(current) do
    local node = root:group { matrix = translate(q[1], q[2]), id = "joint-" .. (i - 1) }
    local body = node:circle {
        radius = 0.19,
        fill = p.joint,
        stroke = i == 1 and p.forward or p.bone,
        width = 3,
        layer = 4,
        id = "joint-body-" .. (i - 1),
    }
    node:text {
        text = "J" .. (i - 1),
        point = { 0, 0 },
        font = "Pretendard",
        size = 9,
        fill = p.ink,
        layer = 5,
    }
    joints[i] = node
    bodies[i] = body
end
local links = {}
for i = 1, 4 do
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
    points = { { -5.86, -2.01 }, { -5.14, -2.01 }, { -5.28, -1.79 }, { -5.72, -1.79 } },
    fill = "#c9c6bf",
    stroke = p.soft,
    width = 1.5,
    id = "fixed-base",
}
local baseghost = root:circle {
    center = basepoint,
    radius = 0.28,
    fill = "#ffffff00",
    stroke = p.forward,
    width = 2,
    id = "base-anchor",
}
local target_node = root:group { matrix = translate(target[1], target[2]), id = "ik-target" }
target_node:circle { radius = 0.32, fill = "#ffffff00", stroke = p.target, width = 3 }
target_node:line { from = { -0.18, 0 }, to = { 0.18, 0 }, color = p.target, width = 2 }
target_node:line { from = { 0, -0.18 }, to = { 0, 0.18 }, color = p.target, width = 2 }
target_node:text {
    text = "target",
    point = { 0.42, -0.35 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 11,
    fill = p.target,
}
local directions = {
    root:arrow {
        from = { -1.40, 1.48 },
        to = { -5.80, 1.48 },
        tip = 11,
        color = p.backward,
        width = 3,
        id = "backward-direction",
    },
    text("BACKWARD  target -> base", { -3.60, 1.64 }, 10, p.backward),
    root:arrow {
        from = { -5.80, 1.08 },
        to = { -1.40, 1.08 },
        tip = 11,
        color = p.forward,
        width = 3,
        id = "forward-direction",
    },
    text("FORWARD  base -> end", { -3.60, 0.82 }, 10, p.forward),
}
local backward_box = root:rectangle {
    center = { 3.62, 0.82 },
    size = { 5.45, 1.55 },
    corner = 0.10,
    fill = "#f4f0f7",
    stroke = p.ring,
    width = 1.5,
    id = "backward-box",
}
local backward_text = {
    text("BACKWARD", { 1.18, 1.30 }, 11, p.backward, nil, { 0, 0.5 }),
    text("p_n = target", { 1.18, 0.92 }, 14, p.ink, nil, { 0, 0.5 }),
    text(
        "p_i = p_(i+1) + L_i * normalize(p_i - p_(i+1))",
        { 1.18, 0.50 },
        11,
        p.ink,
        nil,
        { 0, 0.5 }
    ),
    text("anchor the end, then walk to the base", { 1.18, 0.20 }, 10, p.muted, nil, { 0, 0.5 }),
}
local forward_box = root:rectangle {
    center = { 3.62, -0.92 },
    size = { 5.45, 1.55 },
    corner = 0.10,
    fill = "#eef5f7",
    stroke = "#a9cbd8",
    width = 1.5,
    id = "forward-box",
}
local forward_text = {
    text("FORWARD", { 1.18, -0.44 }, 11, p.forward, nil, { 0, 0.5 }),
    text("p_0 = base", { 1.18, -0.82 }, 14, p.ink, nil, { 0, 0.5 }),
    text(
        "p_(i+1) = p_i + L_i * normalize(p_(i+1) - p_i)",
        { 1.18, -1.24 },
        11,
        p.ink,
        nil,
        { 0, 0.5 }
    ),
    text("restore the base, then walk to the end", { 1.18, -1.54 }, 10, p.muted, nil, { 0, 0.5 }),
}
local invariant = root:rectangle {
    center = { 3.62, -2.30 },
    size = { 5.45, 0.72 },
    corner = 0.10,
    fill = "#f6f4ef",
    stroke = p.rule,
    width = 1.5,
    id = "length-invariant",
}
local invariant_text = {
    text("L = {1.2, 1.1, 1.0, 0.9}", { 1.18, -2.18 }, 12, p.bone, nil, { 0, 0.5 }),
    text(
        "every completed projection preserves its link length",
        { 1.18, -2.48 },
        10,
        p.muted,
        nil,
        { 0, 0.5 }
    ),
}
local status = text("initial end error = 2.701", { -3.78, -2.76 }, 12, p.backward, "fabrik-status")
scene:create({
    base,
    baseghost,
    links[1],
    links[2],
    links[3],
    links[4],
    joints[1],
    joints[2],
    joints[3],
    joints[4],
    joints[5],
    target_node,
    directions[1],
    directions[2],
    directions[3],
    directions[4],
}, 0.82, "ease_out", 0.05)
scene:create({
    backward_box,
    backward_text[1],
    backward_text[2],
    backward_text[3],
    backward_text[4],
    forward_box,
    forward_text[1],
    forward_text[2],
    forward_text[3],
    forward_text[4],
    invariant,
    invariant_text[1],
    invariant_text[2],
    status,
}, 0.62, "ease_out", 0.035)

local function change_status(label, color)
    local nextstatus = text(label, { -3.78, -2.76 }, 12, color, nil, nil, 0)
    scene:fade(status, 0, 0.10, "ease_in")
    scene:fade(nextstatus, 1, 0.10, "ease_out")
    status = nextstatus
end
local move_index = 0
local function move_joint(index, nextpose, label, color, anchor, radius)
    move_index = move_index + 1
    local ring = nil
    if anchor then
        ring = root:circle {
            center = anchor,
            radius = radius,
            fill = "#ffffff00",
            stroke = p.ring,
            width = 2,
            id = "length-ring-" .. move_index,
        }
        scene:create(ring, 0.22, "linear")
    end
    scene:indicate(
        bodies[index],
        { color = color, scale = 1.25, duration = 0.30, easing = "ease_in_out" }
    )
    scene:shift(
        joints[index],
        { nextpose[index][1] - current[index][1], nextpose[index][2] - current[index][2] },
        0.46,
        "ease_in_out"
    )
    current[index] = { nextpose[index][1], nextpose[index][2] }
    change_status(label, color)
    if ring then
        scene:fade_out(ring, { duration = 0.12, easing = "ease_in" })
    end
end
move_joint(5, poses[2], "backward: pin p4 to target", p.backward, nil, nil)
move_joint(4, poses[3], "backward: project J3 at L4", p.backward, current[5], lengths[4])
move_joint(3, poses[4], "backward: project J2 at L3", p.backward, current[4], lengths[3])
move_joint(2, poses[5], "backward: project J1 at L2", p.backward, current[3], lengths[2])
move_joint(1, poses[6], "backward: project J0 at L1", p.backward, current[2], lengths[1])
move_joint(1, poses[7], "forward: restore fixed base", p.forward, nil, nil)
move_joint(2, poses[8], "forward: project J1 at L1", p.forward, current[1], lengths[1])
move_joint(3, poses[9], "forward: project J2 at L2", p.forward, current[2], lengths[2])
move_joint(4, poses[10], "forward: project J3 at L3", p.forward, current[3], lengths[3])
move_joint(
    5,
    poses[11],
    "iteration 1 complete  /  error = 0.081",
    p.forward,
    current[4],
    lengths[4]
)
local moves = {}
for i = 2, 5 do
    moves[#moves + 1] = {
        target = joints[i],
        shift = { poses[12][i][1] - current[i][1], poses[12][i][2] - current[i][2] },
    }
end
scene:play(moves, 0.72, "ease_in_out", 0)
for i = 2, 5 do
    current[i] = { poses[12][i][1], poses[12][i][2] }
end
change_status("iteration 2 complete  /  error = 0.024", p.success)
scene:indicate(
    bodies[5],
    { color = p.success, scale = 1.32, duration = 0.55, easing = "ease_in_out" }
)
scene:wait(1.2)
return scene
