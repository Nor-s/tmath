local p = {
    paper = "#f7f5ef",
    panel = "#fffefa",
    ink = "#202124",
    muted = "#626873",
    soft = "#8b9098",
    rule = "#d9d7d0",
    bone = "#567596",
    joint = "#ffffff",
    active = "#d13d72",
    target = "#e26a3d",
    success = "#268768",
    guide = "#b9a9c9",
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
text("KINEMATICS  /  INVERSE", { -7.2, 3.72 }, 12, p.active, "eyebrow", { 0, 0.5 })
text("CCD IK rotates one joint at a time", { -7.2, 3.25 }, 27, p.ink, "title", { 0, 0.5 })
text(
    "Sweep from the end effector toward the base; each pivot aligns the current end vector with the target.",
    { -7.2, 2.72 },
    14,
    p.muted,
    "subtitle",
    { 0, 0.5 }
)
root:line { from = { -7.2, 2.48 }, to = { 7.2, 2.48 }, color = p.rule, width = 1 }
text(
    "CCDIK: distal-to-proximal rotations reduce end-effector error without changing link lengths.",
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
    id = "ccd-panel",
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
text("CYCLIC COORDINATE DESCENT", { -6.72, 1.92 }, 12, p.soft, "chain-label", { 0, 0.5 })
text("ONE PIVOT UPDATE", { 0.72, 1.92 }, 12, p.soft, "algorithm-label", { 0, 0.5 })

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
            -2.526,
            -0.543,
        },
    },
    {
        { -5.500, -1.700 },
        { -4.305, -1.595 },
        { -3.242, -1.311 },
        { -2.358, -0.844 },
        {
            -3.057,
            -0.277,
        },
    },
    {
        { -5.500, -1.700 },
        { -4.305, -1.595 },
        { -3.314, -1.117 },
        { -2.533, -0.492 },
        {
            -3.326,
            -0.066,
        },
    },
    {
        { -5.500, -1.700 },
        { -4.317, -1.500 },
        { -3.368, -0.944 },
        { -2.639, -0.259 },
        {
            -3.463,
            0.102,
        },
    },
    {
        { -5.500, -1.700 },
        { -4.317, -1.500 },
        { -3.368, -0.944 },
        { -2.639, -0.259 },
        {
            -2.901,
            0.602,
        },
    },
}
local target = { -2.900, 0.600 }
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
        stroke = i == 1 and p.active or p.bone,
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
local target_node = root:group { matrix = translate(target[1], target[2]), id = "ik-target" }
target_node:circle { radius = 0.32, fill = "#ffffff00", stroke = p.target, width = 3 }
target_node:line { from = { -0.18, 0 }, to = { 0.18, 0 }, color = p.target, width = 2 }
target_node:line { from = { 0, -0.18 }, to = { 0, 0.18 }, color = p.target, width = 2 }
target_node:text {
    text = "target",
    point = { 0.48, 0.20 },
    align = { 0, 0.5 },
    font = "Pretendard",
    size = 11,
    fill = p.target,
}
local sweep = root:arrow {
    from = { -1.45, 1.47 },
    to = { -5.75, 1.47 },
    tip = 12,
    color = p.active,
    width = 3,
    id = "sweep-direction",
}
local sweep_label = text("pivot order: J3  ->  J2  ->  J1  ->  J0", { -3.60, 1.64 }, 11, p.active)

local steps = {
    text("1  choose pivot J_i", { 0.88, 1.30 }, 13, p.active, nil, { 0, 0.5 }),
    text("2  v_e = p_end - p_i", { 0.88, 0.84 }, 13, p.ink, nil, { 0, 0.5 }),
    text("3  v_t = target - p_i", { 0.88, 0.42 }, 13, p.ink, nil, { 0, 0.5 }),
    text(
        "4  delta = atan2(cross(v_e,v_t), dot(v_e,v_t))",
        { 0.88, -0.04 },
        12,
        p.ink,
        nil,
        { 0, 0.5 }
    ),
    text("5  rotate joints i+1 ... n by delta", { 0.88, -0.50 }, 13, p.active, nil, { 0, 0.5 }),
}
local invariant = root:rectangle {
    center = { 3.66, -1.38 },
    size = { 5.35, 1.16 },
    corner = 0.10,
    fill = "#f6f2f7",
    stroke = p.guide,
    width = 1.5,
    id = "ccd-invariant",
}
local invariant_text = {
    text("LOCAL GUARANTEE", { 1.18, -1.02 }, 10, p.soft, nil, { 0, 0.5 }),
    text("each pivot minimizes local end error", { 1.18, -1.38 }, 12, p.ink, nil, { 0, 0.5 }),
    text(
        "repeat the full sweep until error < epsilon",
        { 1.18, -1.72 },
        11,
        p.muted,
        nil,
        { 0, 0.5 }
    ),
}
local error_bar_bg = root:rectangle {
    center = { 3.65, -2.45 },
    size = { 5.30, 0.18 },
    fill = "#e9e6df",
    stroke = "#e9e6df",
    width = 1,
    id = "error-track",
}
local error_bar = root:rectangle {
    center = { 3.65, -2.45 },
    size = { 5.30, 0.18 },
    fill = p.active,
    stroke = p.active,
    width = 1,
    id = "error-bar",
}
local error_labels = {
    text("END-EFFECTOR ERROR", { 1.00, -2.18 }, 9, p.soft, nil, { 0, 0.5 }),
    text("2.701", { 6.34, -2.45 }, 10, p.active),
}
local status = text("initial end error = 2.701", { -3.78, -2.76 }, 12, p.active, "ccd-status")
scene:create({
    base,
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
    sweep,
    sweep_label,
}, 0.82, "ease_out", 0.055)
scene:create(steps, 0.56, "ease_out", 0.07)
scene:create({
    invariant,
    invariant_text[1],
    invariant_text[2],
    invariant_text[3],
    error_bar_bg,
    error_bar,
    error_labels[1],
    error_labels[2],
    status,
}, 0.55, "ease_out", 0.04)

local function angle_guide(pivot, endp, name)
    local a0 = math.atan(endp[2] - pivot[2], endp[1] - pivot[1])
    local a1 = math.atan(target[2] - pivot[2], target[1] - pivot[1])
    while a1 - a0 > math.pi do
        a1 = a1 - 2 * math.pi
    end
    while a1 - a0 < -math.pi do
        a1 = a1 + 2 * math.pi
    end
    local g = root:group { id = name }
    g:line { from = pivot, to = target, color = "#b9a9c988", width = 1.5 }
    local pts = {}
    for i = 0, 20 do
        local a = a0 + (a1 - a0) * i / 20
        pts[#pts + 1] = { pivot[1] + 0.43 * math.cos(a), pivot[2] + 0.43 * math.sin(a) }
    end
    g:plot { points = pts, color = p.active, width = 3 }
    return g
end
local step_index = 0
local function step(pivot, nextpose, error, label)
    step_index = step_index + 1
    local guide = angle_guide(current[pivot + 1], current[5], "pivot-guide-" .. step_index)
    scene:create(guide, 0.30, "ease_out")
    scene:indicate(
        bodies[pivot + 1],
        { color = p.active, scale = 1.28, duration = 0.34, easing = "ease_in_out" }
    )
    local moves = {}
    for i = pivot + 2, 5 do
        moves[#moves + 1] = {
            target = joints[i],
            shift = { nextpose[i][1] - current[i][1], nextpose[i][2] - current[i][2] },
        }
    end
    scene:play(moves, 0.58, "ease_in_out", 0)
    for i = pivot + 2, 5 do
        current[i] = { nextpose[i][1], nextpose[i][2] }
    end
    local nextstatus = text(
        label .. "  /  error = " .. error,
        { -3.78, -2.76 },
        12,
        error == "0.002" and p.success or p.active,
        nil,
        nil,
        0
    )
    scene:fade(status, 0, 0.11, "ease_in")
    scene:fade(nextstatus, 1, 0.11, "ease_out")
    status = nextstatus
    scene:fade_out(guide, { duration = 0.14, easing = "ease_in" })
end
step(3, poses[2], "1.202", "iteration 1 · pivot J3")
step(2, poses[3], "0.891", "iteration 1 · pivot J2")
step(1, poses[4], "0.791", "iteration 1 · pivot J1")
step(0, poses[5], "0.752", "iteration 1 · pivot J0")
scene:fill(error_bar, "#d998b0", 0.30, "ease_out")
step(3, poses[6], "0.002", "iteration 2 · pivot J3")
scene:play(
    { { target = error_bar, opacity = 0.08 }, { target = error_labels[2], opacity = 0 } },
    0.38,
    "ease_out",
    0
)
scene:indicate(
    bodies[5],
    { color = p.success, scale = 1.32, duration = 0.55, easing = "ease_in_out" }
)
scene:wait(1.2)
return scene
