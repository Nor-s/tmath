-- Requires a Lua host built with -Ddiagram=enabled.
-- local question: Which video terms name a container, codec, or decoded memory format?
-- visible input: one MP4 container with video and audio tracks
-- subject object or field: the typed handoff from tracks to codecs to decoded sample formats
-- one dominant action: follow each track through decode into its in-memory representation
-- observable output: H.264/AAC and NV12/PCM are visibly separated from the MP4 container
-- coordinate frame and units: left-to-right semantic ranks; labels name formats rather than bytes
-- section bounds supplied by the parent: standalone 960 x 540 wrapper
-- final readable pose: complete container -> track -> codec -> decoded-format topology

local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = {
        preset = "3_blue_1_eyes",
        text = {text = {size = 15}, code = {size = 13}},
    },
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6.2},
}

local LAYER = {guide = -30, annotation = 10, text = 40}

local function text(id, value, point, role, fill, align)
    return scene:text {
        id = id, text = value, point = point, role = role or "code",
        fill = fill or "foreground", align = align or {0.5, 0.5}, layer = LAYER.text,
    }
end

local claim = text(
    "video-format-layer-claim",
    "Containers carry coded tracks; decoders produce memory formats",
    {0, 2.62}, "h3"
)
local distinction = text(
    "video-format-layer-distinction",
    ".mp4 names the container  ·  H.264 / AAC name codecs  ·  NV12 / PCM name memory",
    {0, 2.17}, "code", "muted"
)

local scaffold = scene:group {id = "video-format-layer-scaffold"}
local columns = {
    {id = "container", label = "Container", x = -4.25, width = 1.55},
    {id = "tracks", label = "Tracks", x = -2.05, width = 1.55},
    {id = "codec", label = "Codec", x = 0.35, width = 1.55},
    {id = "memory", label = "Decoded memory", x = 3.40, width = 2.10},
}
for _, column in ipairs(columns) do
    scaffold:text {
        id = "video-format-column-" .. column.id,
        text = column.label, point = {column.x, 1.50}, role = "code",
        fill = "muted", align = {0.5, 0.5}, layer = LAYER.annotation,
    }
    scaffold:line {
        id = "video-format-column-rule-" .. column.id,
        from = {column.x - column.width * 0.5, 1.27},
        to = {column.x + column.width * 0.5, 1.27},
        stroke = "#354052", width = 0.025, layer = LAYER.guide,
    }
end

local diagram = tmath.diagram(scene, {
    id = "video-format-layer-map",
    direction = "lr",
    origin = {-4.25, -0.05},
    node_size = {1.50, 0.96},
    rank_gap = 0.72,
    node_gap = 0.48,
    zone_padding = 0.34,
    route_width = 0.065,
    arrow_length = 0.25,
    arrow_width = 0.22,
    corner = 0.12,
    layers = {zones = -30, routes = -20, nodes = 0, annotations = 10},
})

local container = diagram:node {
    id = "container", label = "MP4", detail = "container", rank = 0,
    position = {-4.25, -0.02}, size = {1.45, 0.96},
}
local videoTrack = diagram:node {
    id = "video-track", label = "Video track", detail = "stream 0", rank = 1,
    position = {-2.05, 0.55}, size = {1.55, 0.96},
}
local audioTrack = diagram:node {
    id = "audio-track", label = "Audio track", detail = "stream 1", rank = 1,
    position = {-2.05, -0.65}, size = {1.55, 0.96},
}
local videoCodec = diagram:node {
    id = "video-codec", label = "H.264", detail = "coded packets", rank = 2,
    position = {0.35, 0.55}, size = {1.55, 0.96},
}
local audioCodec = diagram:node {
    id = "audio-codec", label = "AAC", detail = "coded packets", rank = 2,
    position = {0.35, -0.65}, size = {1.55, 0.96},
}
local videoMemory = diagram:node {
    id = "video-memory", label = "NV12", detail = "Y + interleaved UV", rank = 3,
    position = {3.40, 0.55}, size = {2.00, 0.96},
}
local audioMemory = diagram:node {
    id = "audio-memory", label = "PCM S16", detail = "interleaved samples", rank = 3,
    position = {3.40, -0.65}, size = {2.00, 0.96},
}

local edges = {
    diagram:connect {
        id = "video-codec-edge", from = videoTrack, to = videoCodec,
        route = "straight", flow = true,
    },
    diagram:connect {
        id = "audio-codec-edge", from = audioTrack, to = audioCodec,
        route = "straight", flow = true,
    },
    diagram:connect {
        id = "decode-video", from = videoCodec, to = videoMemory,
        route = "straight", flow = true,
    },
    diagram:connect {
        id = "decode-audio", from = audioCodec, to = audioMemory,
        route = "straight", flow = true,
    },
}

local built = diagram:build()
local branchRoutes = scene:group {id = "video-format-branch-routes"}
local selectVideo = branchRoutes:route {
    id = "video-format-select-video",
    points = {{-3.525, 0.20}, {-3.22, 0.20}, {-3.22, 0.55}, {-2.825, 0.55}},
    dash = {5, 4}, stroke = "accent", width = 0.065, tip = 11, layer = -20,
}
local selectAudio = branchRoutes:route {
    id = "video-format-select-audio",
    points = {{-3.525, -0.20}, {-3.02, -0.20}, {-3.02, -0.65}, {-2.825, -0.65}},
    dash = {5, 4}, stroke = "accent", width = 0.065, tip = 11, layer = -20,
}
local flows = {selectVideo, selectAudio}
for _, edge in ipairs(edges) do flows[#flows + 1] = built:edge(edge) end

local summary = text(
    "video-format-layer-summary",
    "Changing the container need not re-encode; changing the codec does",
    {0, -2.20}, "code", "result"
)

scene:fade_in(claim, {shift = {0, 0.08}, duration = 0.42, curve = "gentle"})
scene:fade_in(distinction, {shift = {0, 0.05}, duration = 0.34, curve = "gentle"})
scene:fade_in(scaffold, {duration = 0.36, curve = "gentle"})
scene:fade_in(built:nodes(), {shift = {0, 0.06}, duration = 0.58, curve = "ease_out"})
scene:fade_in(branchRoutes, {duration = 0.35, curve = "ease_out"})
scene:fade_in(built:routes(), {duration = 0.55, curve = "ease_out"})
scene:play({
    {target = flows[1], dash_offset = -9},
    {target = flows[2], dash_offset = -9},
    {target = flows[3], dash_offset = -9},
    {target = flows[4], dash_offset = -9},
    {target = flows[5], dash_offset = -9},
    {target = flows[6], dash_offset = -9},
}, 1.20, "linear")
scene:fade_in(summary, {shift = {0, -0.05}, duration = 0.34, curve = "gentle"})
scene:wait(2.0)
return scene
