-- Standalone binary-search cheatsheet.
local scene = tmath.scene {["background"]="#FFFFFF",["camera"]={["height"]=14.6,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=24,["height"]=1460,["loop"]=true,["theme"]="pro_white",["width"]=1440}
local object1 = scene:group {["id"]="header"}
local object2 = object1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="header-title",["layer"]=40,["point"]={-6.62,6.65},["role"]="h1",["size"]=52,["text"]="Binary Search"}
local object3 = object1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="header-subtitle",["layer"]=40,["point"]={-6.58,5.95},["size"]=19,["text"]="Why one comparison can eliminate half of a sorted search interval"}
local object4 = object1:text {["align"]={1,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="header-guide",["layer"]=40,["point"]={6.62,5.95},["size"]=15,["text"]="Four comparisons locate 68"}
local object5 = object1:line {["from"]={-6.62,5.65},["id"]="header-rule",["layer"]=0,["stroke"]="#202124",["to"]={6.62,5.65},["width"]=1.4}
local object6 = scene:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-section-title",["layer"]=40,["point"]={-6.62,1.63},["size"]=15,["text"]="SEARCH TRACE  ·  Each row shows the closed interval [lo, hi] before comparison"}
local object7 = scene:text {["align"]={1,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-legend",["layer"]=40,["point"]={6.62,1.63},["role"]="code",["size"]=11,["text"]="blue = candidate   ochre = mid   rust = target / result"}
local object8 = scene:line {["from"]={-6.62,1.39},["id"]="trace-section-rule",["stroke"]="#D8DADD",["to"]={6.62,1.39},["width"]=1}
local object9 = scene:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="footer-section-title",["layer"]=40,["point"]={-6.62,-3.72},["size"]=15,["text"]="COMPLEXITY, INVARIANT, AND RETURN VALUE"}
local object10 = scene:line {["from"]={-6.62,-3.96},["id"]="footer-section-rule",["stroke"]="#D8DADD",["to"]={6.62,-3.96},["width"]=1}
local object11 = scene:line {["from"]={-2.09,-4.02},["id"]="footer-divider-1",["stroke"]="#D8DADD",["to"]={-2.09,-7.1},["width"]=1}
local object12 = scene:line {["from"]={3.31,-4.02},["id"]="footer-divider-2",["stroke"]="#D8DADD",["to"]={3.31,-7.1},["width"]=1}
do
    local viewportScene1 = tmath.scene {["background"]="#FFFFFF",["camera"]={["height"]=2.65,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=24,["height"]=190,["loop"]=false,["theme"]="pro_white",["width"]=1325}
    local object1 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="pseudocode-title",["layer"]=40,["point"]={-8.82,1.1},["size"]=16,["text"]="A  ·  Pseudocode"}
    local object2 = viewportScene1:text {["align"]={1,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="pseudocode-contract",["layer"]=40,["point"]={8.82,1.1},["role"]="code",["size"]=12,["text"]="Closed candidate interval [lo, hi]"}
    local object3 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="pseudocode-line-1",["layer"]=40,["point"]={-8.76,0.72},["role"]="code",["size"]=12.5,["text"]="1  lo ← 0; hi ← n - 1"}
    local object4 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="pseudocode-line-2",["layer"]=40,["point"]={-8.76,0.43},["role"]="code",["size"]=12.5,["text"]="2  while lo ≤ hi"}
    local object5 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="pseudocode-line-3",["layer"]=40,["point"]={-8.76,0.14},["role"]="code",["size"]=12.5,["text"]="3    mid ← floor((lo + hi) / 2)"}
    local object6 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="pseudocode-line-4",["layer"]=40,["point"]={-8.76,-0.1499999999999999},["role"]="code",["size"]=12.5,["text"]="4    if a[mid] < target: lo ← mid + 1"}
    local object7 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="pseudocode-line-5",["layer"]=40,["point"]={-8.76,-0.43999999999999995},["role"]="code",["size"]=12.5,["text"]="5    else if a[mid] > target: hi ← mid - 1"}
    local object8 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="pseudocode-line-6",["layer"]=40,["point"]={-8.76,-0.73},["role"]="code",["size"]=12.5,["text"]="6    else: return mid"}
    local object9 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="pseudocode-line-7",["layer"]=40,["point"]={-8.76,-1.0199999999999998},["role"]="code",["size"]=12.5,["text"]="7  return NOT_FOUND"}
    local object10 = viewportScene1:line {["from"]={0.72,0.84},["id"]="pseudocode-divider",["stroke"]="#D8DADD",["to"]={0.72,-1.16},["width"]=1}
    local object11 = viewportScene1:text {["align"]={0,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="pseudocode-map-range-1",["layer"]=40,["point"]={1.18,0.43},["role"]="code",["size"]=12,["text"]="L1–3"}
    local object12 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="pseudocode-map-destination-1",["layer"]=40,["point"]={2.65,0.43},["size"]=12,["text"]="→  B INPUT · C1–C4 TRACE"}
    local object13 = viewportScene1:text {["align"]={0,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="pseudocode-map-range-2",["layer"]=40,["point"]={1.18,-0.3},["role"]="code",["size"]=12,["text"]="L4–5"}
    local object14 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="pseudocode-map-destination-2",["layer"]=40,["point"]={2.65,-0.3},["size"]=12,["text"]="→  D CANDIDATES · E INVARIANT"}
    local object15 = viewportScene1:text {["align"]={0,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="pseudocode-map-range-3",["layer"]=40,["point"]={1.18,-0.88},["role"]="code",["size"]=12,["text"]="L6–7"}
    local object16 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="pseudocode-map-destination-3",["layer"]=40,["point"]={2.65,-0.88},["size"]=12,["text"]="→  F RESULT"}
    local object17 = viewportScene1:rectangle {["center"]={-4.05,0.43},["corner"]=0.025,["fill"]="#9B3600",["id"]="pseudocode-highlight-1",["layer"]=0,["opacity"]=0,["size"]={9.05,0.82},["stroke"]="#00000000"}
    local object18 = viewportScene1:rectangle {["center"]={-4.05,-0.295},["corner"]=0.025,["fill"]="#9B3600",["id"]="pseudocode-highlight-2",["layer"]=0,["opacity"]=0,["size"]={9.05,0.54},["stroke"]="#00000000"}
    local object19 = viewportScene1:rectangle {["center"]={-4.05,-0.875},["corner"]=0.025,["fill"]="#9B3600",["id"]="pseudocode-highlight-3",["layer"]=0,["opacity"]=0,["size"]={9.05,0.54},["stroke"]="#00000000"}
    viewportScene1:wait(0.2)
    viewportScene1:play({{target=object17,opacity=0.12}},0.45,"gentle",0)
    viewportScene1:wait(0.25)
    viewportScene1:play({{target=object17,opacity=0}},0.45,"gentle",0)
    viewportScene1:play({{target=object18,opacity=0.12}},0.45,"gentle",0)
    viewportScene1:wait(0.25)
    viewportScene1:play({{target=object18,opacity=0}},0.45,"gentle",0)
    viewportScene1:play({{target=object19,opacity=0.12}},0.45,"gentle",0)
    viewportScene1:wait(0.25)
    viewportScene1:play({{target=object19,opacity=0}},0.45,"gentle",0)
    viewportScene1:wait(0.2)
    viewportScene1:play({{target=object17,opacity=0.12}},0.45,"gentle",0)
    viewportScene1:wait(0.25)
    viewportScene1:play({{target=object17,opacity=0}},0.45,"gentle",0)
    viewportScene1:play({{target=object18,opacity=0.12}},0.45,"gentle",0)
    viewportScene1:wait(0.25)
    viewportScene1:play({{target=object18,opacity=0}},0.45,"gentle",0)
    viewportScene1:play({{target=object19,opacity=0.12}},0.45,"gentle",0)
    viewportScene1:wait(0.25)
    viewportScene1:play({{target=object19,opacity=0}},0.45,"gentle",0)
    viewportScene1:wait(0.7)
    scene:viewport(viewportScene1,{["height"]=0.13,["width"]=0.92,["x"]=0.04,["y"]=0.115})
end
do
    local viewportScene1 = tmath.scene {["background"]="#FFFFFF",["camera"]={["height"]=2.35,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=24,["height"]=167,["loop"]=false,["theme"]="pro_white",["width"]=1325}
    local object1 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="input-title",["layer"]=40,["point"]={-9.18,0.82},["size"]=17,["text"]="B  ·  Sorted input and target"}
    local object2 = viewportScene1:text {["align"]={1,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="input-target-code",["layer"]=40,["point"]={9.18,0.82},["role"]="code",["size"]=15,["text"]="target = 68"}
    local object3 = viewportScene1:rectangle {["center"]={-6.3,0.08},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="input-cell-0",["layer"]=10,["size"]={0.94,0.66},["stroke"]="#5E7A9B",["width"]=1.2}
    local object4 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="input-value-0",["layer"]=40,["point"]={-6.3,0.16},["size"]=16,["text"]="-12"}
    local object5 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="input-index-0",["layer"]=40,["point"]={-6.3,-0.31},["size"]=10,["text"]="0"}
    local object6 = viewportScene1:rectangle {["center"]={-5.29,0.08},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="input-cell-1",["layer"]=10,["size"]={0.94,0.66},["stroke"]="#5E7A9B",["width"]=1.2}
    local object7 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="input-value-1",["layer"]=40,["point"]={-5.29,0.16},["size"]=16,["text"]="-3"}
    local object8 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="input-index-1",["layer"]=40,["point"]={-5.29,-0.31},["size"]=10,["text"]="1"}
    local object9 = viewportScene1:rectangle {["center"]={-4.279999999999999,0.08},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="input-cell-2",["layer"]=10,["size"]={0.94,0.66},["stroke"]="#5E7A9B",["width"]=1.2}
    local object10 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="input-value-2",["layer"]=40,["point"]={-4.279999999999999,0.16},["size"]=16,["text"]="4"}
    local object11 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="input-index-2",["layer"]=40,["point"]={-4.279999999999999,-0.31},["size"]=10,["text"]="2"}
    local object12 = viewportScene1:rectangle {["center"]={-3.2699999999999996,0.08},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="input-cell-3",["layer"]=10,["size"]={0.94,0.66},["stroke"]="#5E7A9B",["width"]=1.2}
    local object13 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="input-value-3",["layer"]=40,["point"]={-3.2699999999999996,0.16},["size"]=16,["text"]="7"}
    local object14 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="input-index-3",["layer"]=40,["point"]={-3.2699999999999996,-0.31},["size"]=10,["text"]="3"}
    local object15 = viewportScene1:rectangle {["center"]={-2.26,0.08},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="input-cell-4",["layer"]=10,["size"]={0.94,0.66},["stroke"]="#5E7A9B",["width"]=1.2}
    local object16 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="input-value-4",["layer"]=40,["point"]={-2.26,0.16},["size"]=16,["text"]="11"}
    local object17 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="input-index-4",["layer"]=40,["point"]={-2.26,-0.31},["size"]=10,["text"]="4"}
    local object18 = viewportScene1:rectangle {["center"]={-1.25,0.08},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="input-cell-5",["layer"]=10,["size"]={0.94,0.66},["stroke"]="#5E7A9B",["width"]=1.2}
    local object19 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="input-value-5",["layer"]=40,["point"]={-1.25,0.16},["size"]=16,["text"]="18"}
    local object20 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="input-index-5",["layer"]=40,["point"]={-1.25,-0.31},["size"]=10,["text"]="5"}
    local object21 = viewportScene1:rectangle {["center"]={-0.23999999999999932,0.08},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="input-cell-6",["layer"]=10,["size"]={0.94,0.66},["stroke"]="#5E7A9B",["width"]=1.2}
    local object22 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="input-value-6",["layer"]=40,["point"]={-0.23999999999999932,0.16},["size"]=16,["text"]="23"}
    local object23 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="input-index-6",["layer"]=40,["point"]={-0.23999999999999932,-0.31},["size"]=10,["text"]="6"}
    local object24 = viewportScene1:rectangle {["center"]={0.7700000000000005,0.08},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="input-cell-7",["layer"]=10,["size"]={0.94,0.66},["stroke"]="#5E7A9B",["width"]=1.2}
    local object25 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="input-value-7",["layer"]=40,["point"]={0.7700000000000005,0.16},["size"]=16,["text"]="31"}
    local object26 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="input-index-7",["layer"]=40,["point"]={0.7700000000000005,-0.31},["size"]=10,["text"]="7"}
    local object27 = viewportScene1:rectangle {["center"]={1.7800000000000002,0.08},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="input-cell-8",["layer"]=10,["size"]={0.94,0.66},["stroke"]="#5E7A9B",["width"]=1.2}
    local object28 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="input-value-8",["layer"]=40,["point"]={1.7800000000000002,0.16},["size"]=16,["text"]="42"}
    local object29 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="input-index-8",["layer"]=40,["point"]={1.7800000000000002,-0.31},["size"]=10,["text"]="8"}
    local object30 = viewportScene1:rectangle {["center"]={2.79,0.08},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="input-cell-9",["layer"]=10,["size"]={0.94,0.66},["stroke"]="#5E7A9B",["width"]=1.2}
    local object31 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="input-value-9",["layer"]=40,["point"]={2.79,0.16},["size"]=16,["text"]="57"}
    local object32 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="input-index-9",["layer"]=40,["point"]={2.79,-0.31},["size"]=10,["text"]="9"}
    local object33 = viewportScene1:rectangle {["center"]={3.8,0.08},["corner"]=0.025,["fill"]="#F5E8E1",["id"]="input-cell-10",["layer"]=10,["size"]={0.94,0.66},["stroke"]="#9B3600",["width"]=2.4}
    local object34 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="input-value-10",["layer"]=40,["point"]={3.8,0.16},["size"]=16,["text"]="68"}
    local object35 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="input-index-10",["layer"]=40,["point"]={3.8,-0.31},["size"]=10,["text"]="10"}
    local object36 = viewportScene1:rectangle {["center"]={4.81,0.08},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="input-cell-11",["layer"]=10,["size"]={0.94,0.66},["stroke"]="#5E7A9B",["width"]=1.2}
    local object37 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="input-value-11",["layer"]=40,["point"]={4.81,0.16},["size"]=16,["text"]="79"}
    local object38 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="input-index-11",["layer"]=40,["point"]={4.81,-0.31},["size"]=10,["text"]="11"}
    local object39 = viewportScene1:rectangle {["center"]={5.820000000000001,0.08},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="input-cell-12",["layer"]=10,["size"]={0.94,0.66},["stroke"]="#5E7A9B",["width"]=1.2}
    local object40 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="input-value-12",["layer"]=40,["point"]={5.820000000000001,0.16},["size"]=16,["text"]="91"}
    local object41 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="input-index-12",["layer"]=40,["point"]={5.820000000000001,-0.31},["size"]=10,["text"]="12"}
    local object42 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="input-caption",["layer"]=40,["point"]={-9.18,-0.83},["size"]=13,["text"]="Value 68 is at index 10. Binary search compares only the current midpoint."}
    local object43 = viewportScene1:point {["fill"]="#9B3600",["id"]="input-target-marker",["layer"]=24,["opacity"]=0,["point"]={3.8,0.57},["radius"]=5,["stroke"]="#FFFFFF",["width"]=2}
    viewportScene1:wait(0.25)
    viewportScene1:play({{target=object43,opacity=1}},0.3,"gentle",0)
    viewportScene1:indicate(object33,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.7,["scale"]=1.035})
    viewportScene1:indicate(object34,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.055})
    viewportScene1:indicate(object35,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.6,["scale"]=1.1})
    viewportScene1:play({{target=object43,opacity=0}},0.3,"gentle",0)
    viewportScene1:wait(0.45)
    viewportScene1:play({{target=object43,opacity=1}},0.3,"gentle",0)
    viewportScene1:indicate(object33,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.7,["scale"]=1.035})
    viewportScene1:indicate(object34,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.055})
    viewportScene1:indicate(object35,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.6,["scale"]=1.1})
    viewportScene1:play({{target=object43,opacity=0}},0.3,"gentle",0)
    viewportScene1:wait(2.2)
    scene:viewport(viewportScene1,{["height"]=0.1144,["width"]=0.92,["x"]=0.04,["y"]=0.255})
end
do
    local viewportScene1 = tmath.scene {["background"]="#FFFFFF",["camera"]={["height"]=2.2,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=24,["height"]=114,["loop"]=false,["theme"]="pro_white",["width"]=1325}
    local object1 = viewportScene1:text {["align"]={0,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="trace-1-letter",["layer"]=40,["point"]={-12.28,0.45},["size"]=15,["text"]="C1"}
    local object2 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-1-title",["layer"]=40,["point"]={-12.28,-0.03},["size"]=16,["text"]="Comparison 1"}
    local object3 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-1-count",["layer"]=40,["point"]={-12.28,-0.52},["size"]=12,["text"]="13 candidates"}
    local object4 = viewportScene1:rectangle {["center"]={-7.25,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-1-cell-0",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object5 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-1-value-0",["layer"]=40,["point"]={-7.25,0.02},["size"]=13,["text"]="-12"}
    local object6 = viewportScene1:rectangle {["center"]={-6.32,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-1-cell-1",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object7 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-1-value-1",["layer"]=40,["point"]={-6.32,0.02},["size"]=13,["text"]="-3"}
    local object8 = viewportScene1:rectangle {["center"]={-5.39,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-1-cell-2",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object9 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-1-value-2",["layer"]=40,["point"]={-5.39,0.02},["size"]=13,["text"]="4"}
    local object10 = viewportScene1:rectangle {["center"]={-4.46,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-1-cell-3",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object11 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-1-value-3",["layer"]=40,["point"]={-4.46,0.02},["size"]=13,["text"]="7"}
    local object12 = viewportScene1:rectangle {["center"]={-3.53,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-1-cell-4",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object13 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-1-value-4",["layer"]=40,["point"]={-3.53,0.02},["size"]=13,["text"]="11"}
    local object14 = viewportScene1:rectangle {["center"]={-2.5999999999999996,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-1-cell-5",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object15 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-1-value-5",["layer"]=40,["point"]={-2.5999999999999996,0.02},["size"]=13,["text"]="18"}
    local object16 = viewportScene1:rectangle {["center"]={-1.67,0.02},["corner"]=0.025,["fill"]="#F4EEE5",["id"]="trace-1-cell-6",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#B8915A",["width"]=2.4}
    local object17 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-1-value-6",["layer"]=40,["point"]={-1.67,0.02},["size"]=13,["text"]="23"}
    local object18 = viewportScene1:rectangle {["center"]={-0.7399999999999993,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-1-cell-7",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object19 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-1-value-7",["layer"]=40,["point"]={-0.7399999999999993,0.02},["size"]=13,["text"]="31"}
    local object20 = viewportScene1:rectangle {["center"]={0.1900000000000004,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-1-cell-8",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object21 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-1-value-8",["layer"]=40,["point"]={0.1900000000000004,0.02},["size"]=13,["text"]="42"}
    local object22 = viewportScene1:rectangle {["center"]={1.120000000000001,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-1-cell-9",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object23 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-1-value-9",["layer"]=40,["point"]={1.120000000000001,0.02},["size"]=13,["text"]="57"}
    local object24 = viewportScene1:rectangle {["center"]={2.0500000000000007,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-1-cell-10",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object25 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-1-value-10",["layer"]=40,["point"]={2.0500000000000007,0.02},["size"]=13,["text"]="68"}
    local object26 = viewportScene1:rectangle {["center"]={2.9800000000000004,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-1-cell-11",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object27 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-1-value-11",["layer"]=40,["point"]={2.9800000000000004,0.02},["size"]=13,["text"]="79"}
    local object28 = viewportScene1:rectangle {["center"]={3.91,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-1-cell-12",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object29 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-1-value-12",["layer"]=40,["point"]={3.91,0.02},["size"]=13,["text"]="91"}
    local object30 = viewportScene1:line {["from"]={-7.64,-0.55},["id"]="trace-1-range",["layer"]=10,["stroke"]="#5E7A9B",["to"]={4.3,-0.55},["width"]=3}
    local object31 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-1-decision",["layer"]=40,["point"]={5.35,0.43},["size"]=15,["text"]="mid = 6  ·  23 < 68"}
    local object32 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-1-caption",["layer"]=40,["point"]={5.35,-0.16},["size"]=13,["text"]="lo = 7  →  keep right half"}
    local object33 = viewportScene1:point {["fill"]="#9B3600",["id"]="trace-1-mid-marker",["layer"]=24,["opacity"]=0,["point"]={-1.67,0.52},["radius"]=4.5,["stroke"]="#FFFFFF",["width"]=2}
    viewportScene1:wait(0.1)
    viewportScene1:play({{target=object33,opacity=1}},0.3,"gentle",0)
    viewportScene1:indicate(object16,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.035})
    viewportScene1:indicate(object17,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.6,["scale"]=1.055})
    viewportScene1:indicate(object31,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.035})
    viewportScene1:play({{target=object33,opacity=0}},0.3,"gentle",0)
    viewportScene1:wait(0.45)
    viewportScene1:play({{target=object33,opacity=1}},0.3,"gentle",0)
    viewportScene1:indicate(object16,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.035})
    viewportScene1:indicate(object17,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.6,["scale"]=1.055})
    viewportScene1:indicate(object31,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.035})
    viewportScene1:play({{target=object33,opacity=0}},0.3,"gentle",0)
    viewportScene1:wait(2.45)
    scene:viewport(viewportScene1,{["height"]=0.0781,["width"]=0.92,["x"]=0.04,["y"]=0.414})
end
do
    local viewportScene1 = tmath.scene {["background"]="#FFFFFF",["camera"]={["height"]=2.2,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=24,["height"]=114,["loop"]=false,["theme"]="pro_white",["width"]=1325}
    local object1 = viewportScene1:text {["align"]={0,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="trace-2-letter",["layer"]=40,["point"]={-12.28,0.45},["size"]=15,["text"]="C2"}
    local object2 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-2-title",["layer"]=40,["point"]={-12.28,-0.03},["size"]=16,["text"]="Comparison 2"}
    local object3 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-2-count",["layer"]=40,["point"]={-12.28,-0.52},["size"]=12,["text"]="6 candidates"}
    local object4 = viewportScene1:rectangle {["center"]={-7.25,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-2-cell-0",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object5 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-2-value-0",["layer"]=40,["point"]={-7.25,0.02},["size"]=13,["text"]="-12"}
    local object6 = viewportScene1:rectangle {["center"]={-6.32,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-2-cell-1",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object7 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-2-value-1",["layer"]=40,["point"]={-6.32,0.02},["size"]=13,["text"]="-3"}
    local object8 = viewportScene1:rectangle {["center"]={-5.39,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-2-cell-2",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object9 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-2-value-2",["layer"]=40,["point"]={-5.39,0.02},["size"]=13,["text"]="4"}
    local object10 = viewportScene1:rectangle {["center"]={-4.46,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-2-cell-3",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object11 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-2-value-3",["layer"]=40,["point"]={-4.46,0.02},["size"]=13,["text"]="7"}
    local object12 = viewportScene1:rectangle {["center"]={-3.53,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-2-cell-4",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object13 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-2-value-4",["layer"]=40,["point"]={-3.53,0.02},["size"]=13,["text"]="11"}
    local object14 = viewportScene1:rectangle {["center"]={-2.5999999999999996,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-2-cell-5",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object15 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-2-value-5",["layer"]=40,["point"]={-2.5999999999999996,0.02},["size"]=13,["text"]="18"}
    local object16 = viewportScene1:rectangle {["center"]={-1.67,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-2-cell-6",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object17 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-2-value-6",["layer"]=40,["point"]={-1.67,0.02},["size"]=13,["text"]="23"}
    local object18 = viewportScene1:rectangle {["center"]={-0.7399999999999993,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-2-cell-7",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object19 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-2-value-7",["layer"]=40,["point"]={-0.7399999999999993,0.02},["size"]=13,["text"]="31"}
    local object20 = viewportScene1:rectangle {["center"]={0.1900000000000004,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-2-cell-8",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object21 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-2-value-8",["layer"]=40,["point"]={0.1900000000000004,0.02},["size"]=13,["text"]="42"}
    local object22 = viewportScene1:rectangle {["center"]={1.120000000000001,0.02},["corner"]=0.025,["fill"]="#F4EEE5",["id"]="trace-2-cell-9",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#B8915A",["width"]=2.4}
    local object23 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-2-value-9",["layer"]=40,["point"]={1.120000000000001,0.02},["size"]=13,["text"]="57"}
    local object24 = viewportScene1:rectangle {["center"]={2.0500000000000007,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-2-cell-10",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object25 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-2-value-10",["layer"]=40,["point"]={2.0500000000000007,0.02},["size"]=13,["text"]="68"}
    local object26 = viewportScene1:rectangle {["center"]={2.9800000000000004,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-2-cell-11",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object27 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-2-value-11",["layer"]=40,["point"]={2.9800000000000004,0.02},["size"]=13,["text"]="79"}
    local object28 = viewportScene1:rectangle {["center"]={3.91,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-2-cell-12",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object29 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-2-value-12",["layer"]=40,["point"]={3.91,0.02},["size"]=13,["text"]="91"}
    local object30 = viewportScene1:line {["from"]={-1.1299999999999994,-0.55},["id"]="trace-2-range",["layer"]=10,["stroke"]="#5E7A9B",["to"]={4.3,-0.55},["width"]=3}
    local object31 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-2-decision",["layer"]=40,["point"]={5.35,0.43},["size"]=15,["text"]="mid = 9  ·  57 < 68"}
    local object32 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-2-caption",["layer"]=40,["point"]={5.35,-0.16},["size"]=13,["text"]="lo = 10  →  keep right half"}
    local object33 = viewportScene1:point {["fill"]="#9B3600",["id"]="trace-2-mid-marker",["layer"]=24,["opacity"]=0,["point"]={1.120000000000001,0.52},["radius"]=4.5,["stroke"]="#FFFFFF",["width"]=2}
    viewportScene1:wait(0.3)
    viewportScene1:play({{target=object33,opacity=1}},0.3,"gentle",0)
    viewportScene1:indicate(object22,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.035})
    viewportScene1:indicate(object23,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.6,["scale"]=1.055})
    viewportScene1:indicate(object31,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.035})
    viewportScene1:play({{target=object33,opacity=0}},0.3,"gentle",0)
    viewportScene1:wait(0.45)
    viewportScene1:play({{target=object33,opacity=1}},0.3,"gentle",0)
    viewportScene1:indicate(object22,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.035})
    viewportScene1:indicate(object23,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.6,["scale"]=1.055})
    viewportScene1:indicate(object31,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.035})
    viewportScene1:play({{target=object33,opacity=0}},0.3,"gentle",0)
    viewportScene1:wait(2.25)
    scene:viewport(viewportScene1,{["height"]=0.0781,["width"]=0.92,["x"]=0.04,["y"]=0.497})
end
do
    local viewportScene1 = tmath.scene {["background"]="#FFFFFF",["camera"]={["height"]=2.2,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=24,["height"]=114,["loop"]=false,["theme"]="pro_white",["width"]=1325}
    local object1 = viewportScene1:text {["align"]={0,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="trace-3-letter",["layer"]=40,["point"]={-12.28,0.45},["size"]=15,["text"]="C3"}
    local object2 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-3-title",["layer"]=40,["point"]={-12.28,-0.03},["size"]=16,["text"]="Comparison 3"}
    local object3 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-3-count",["layer"]=40,["point"]={-12.28,-0.52},["size"]=12,["text"]="3 candidates"}
    local object4 = viewportScene1:rectangle {["center"]={-7.25,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-3-cell-0",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object5 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-3-value-0",["layer"]=40,["point"]={-7.25,0.02},["size"]=13,["text"]="-12"}
    local object6 = viewportScene1:rectangle {["center"]={-6.32,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-3-cell-1",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object7 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-3-value-1",["layer"]=40,["point"]={-6.32,0.02},["size"]=13,["text"]="-3"}
    local object8 = viewportScene1:rectangle {["center"]={-5.39,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-3-cell-2",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object9 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-3-value-2",["layer"]=40,["point"]={-5.39,0.02},["size"]=13,["text"]="4"}
    local object10 = viewportScene1:rectangle {["center"]={-4.46,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-3-cell-3",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object11 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-3-value-3",["layer"]=40,["point"]={-4.46,0.02},["size"]=13,["text"]="7"}
    local object12 = viewportScene1:rectangle {["center"]={-3.53,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-3-cell-4",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object13 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-3-value-4",["layer"]=40,["point"]={-3.53,0.02},["size"]=13,["text"]="11"}
    local object14 = viewportScene1:rectangle {["center"]={-2.5999999999999996,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-3-cell-5",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object15 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-3-value-5",["layer"]=40,["point"]={-2.5999999999999996,0.02},["size"]=13,["text"]="18"}
    local object16 = viewportScene1:rectangle {["center"]={-1.67,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-3-cell-6",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object17 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-3-value-6",["layer"]=40,["point"]={-1.67,0.02},["size"]=13,["text"]="23"}
    local object18 = viewportScene1:rectangle {["center"]={-0.7399999999999993,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-3-cell-7",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object19 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-3-value-7",["layer"]=40,["point"]={-0.7399999999999993,0.02},["size"]=13,["text"]="31"}
    local object20 = viewportScene1:rectangle {["center"]={0.1900000000000004,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-3-cell-8",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object21 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-3-value-8",["layer"]=40,["point"]={0.1900000000000004,0.02},["size"]=13,["text"]="42"}
    local object22 = viewportScene1:rectangle {["center"]={1.120000000000001,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-3-cell-9",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object23 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-3-value-9",["layer"]=40,["point"]={1.120000000000001,0.02},["size"]=13,["text"]="57"}
    local object24 = viewportScene1:rectangle {["center"]={2.0500000000000007,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-3-cell-10",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object25 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-3-value-10",["layer"]=40,["point"]={2.0500000000000007,0.02},["size"]=13,["text"]="68"}
    local object26 = viewportScene1:rectangle {["center"]={2.9800000000000004,0.02},["corner"]=0.025,["fill"]="#F4EEE5",["id"]="trace-3-cell-11",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#B8915A",["width"]=2.4}
    local object27 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-3-value-11",["layer"]=40,["point"]={2.9800000000000004,0.02},["size"]=13,["text"]="79"}
    local object28 = viewportScene1:rectangle {["center"]={3.91,0.02},["corner"]=0.025,["fill"]="#E9EEF3",["id"]="trace-3-cell-12",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#5E7A9B",["width"]=1.2}
    local object29 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-3-value-12",["layer"]=40,["point"]={3.91,0.02},["size"]=13,["text"]="91"}
    local object30 = viewportScene1:line {["from"]={1.6600000000000006,-0.55},["id"]="trace-3-range",["layer"]=10,["stroke"]="#5E7A9B",["to"]={4.3,-0.55},["width"]=3}
    local object31 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-3-decision",["layer"]=40,["point"]={5.35,0.43},["size"]=15,["text"]="mid = 11  ·  79 > 68"}
    local object32 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-3-caption",["layer"]=40,["point"]={5.35,-0.16},["size"]=13,["text"]="hi = 10  →  keep left half"}
    local object33 = viewportScene1:point {["fill"]="#9B3600",["id"]="trace-3-mid-marker",["layer"]=24,["opacity"]=0,["point"]={2.9800000000000004,0.52},["radius"]=4.5,["stroke"]="#FFFFFF",["width"]=2}
    viewportScene1:wait(0.5)
    viewportScene1:play({{target=object33,opacity=1}},0.3,"gentle",0)
    viewportScene1:indicate(object26,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.035})
    viewportScene1:indicate(object27,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.6,["scale"]=1.055})
    viewportScene1:indicate(object31,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.035})
    viewportScene1:play({{target=object33,opacity=0}},0.3,"gentle",0)
    viewportScene1:wait(0.45)
    viewportScene1:play({{target=object33,opacity=1}},0.3,"gentle",0)
    viewportScene1:indicate(object26,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.035})
    viewportScene1:indicate(object27,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.6,["scale"]=1.055})
    viewportScene1:indicate(object31,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.035})
    viewportScene1:play({{target=object33,opacity=0}},0.3,"gentle",0)
    viewportScene1:wait(2.05)
    scene:viewport(viewportScene1,{["height"]=0.0781,["width"]=0.92,["x"]=0.04,["y"]=0.58})
end
do
    local viewportScene1 = tmath.scene {["background"]="#FFFFFF",["camera"]={["height"]=2.2,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=24,["height"]=114,["loop"]=false,["theme"]="pro_white",["width"]=1325}
    local object1 = viewportScene1:text {["align"]={0,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="trace-4-letter",["layer"]=40,["point"]={-12.28,0.45},["size"]=15,["text"]="C4"}
    local object2 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-4-title",["layer"]=40,["point"]={-12.28,-0.03},["size"]=16,["text"]="Comparison 4"}
    local object3 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-4-count",["layer"]=40,["point"]={-12.28,-0.52},["size"]=12,["text"]="1 candidates"}
    local object4 = viewportScene1:rectangle {["center"]={-7.25,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-4-cell-0",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object5 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-4-value-0",["layer"]=40,["point"]={-7.25,0.02},["size"]=13,["text"]="-12"}
    local object6 = viewportScene1:rectangle {["center"]={-6.32,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-4-cell-1",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object7 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-4-value-1",["layer"]=40,["point"]={-6.32,0.02},["size"]=13,["text"]="-3"}
    local object8 = viewportScene1:rectangle {["center"]={-5.39,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-4-cell-2",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object9 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-4-value-2",["layer"]=40,["point"]={-5.39,0.02},["size"]=13,["text"]="4"}
    local object10 = viewportScene1:rectangle {["center"]={-4.46,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-4-cell-3",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object11 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-4-value-3",["layer"]=40,["point"]={-4.46,0.02},["size"]=13,["text"]="7"}
    local object12 = viewportScene1:rectangle {["center"]={-3.53,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-4-cell-4",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object13 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-4-value-4",["layer"]=40,["point"]={-3.53,0.02},["size"]=13,["text"]="11"}
    local object14 = viewportScene1:rectangle {["center"]={-2.5999999999999996,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-4-cell-5",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object15 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-4-value-5",["layer"]=40,["point"]={-2.5999999999999996,0.02},["size"]=13,["text"]="18"}
    local object16 = viewportScene1:rectangle {["center"]={-1.67,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-4-cell-6",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object17 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-4-value-6",["layer"]=40,["point"]={-1.67,0.02},["size"]=13,["text"]="23"}
    local object18 = viewportScene1:rectangle {["center"]={-0.7399999999999993,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-4-cell-7",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object19 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-4-value-7",["layer"]=40,["point"]={-0.7399999999999993,0.02},["size"]=13,["text"]="31"}
    local object20 = viewportScene1:rectangle {["center"]={0.1900000000000004,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-4-cell-8",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object21 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-4-value-8",["layer"]=40,["point"]={0.1900000000000004,0.02},["size"]=13,["text"]="42"}
    local object22 = viewportScene1:rectangle {["center"]={1.120000000000001,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-4-cell-9",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object23 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-4-value-9",["layer"]=40,["point"]={1.120000000000001,0.02},["size"]=13,["text"]="57"}
    local object24 = viewportScene1:rectangle {["center"]={2.0500000000000007,0.02},["corner"]=0.025,["fill"]="#F5E8E1",["id"]="trace-4-cell-10",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#9B3600",["width"]=2.4}
    local object25 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="trace-4-value-10",["layer"]=40,["point"]={2.0500000000000007,0.02},["size"]=13,["text"]="68"}
    local object26 = viewportScene1:rectangle {["center"]={2.9800000000000004,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-4-cell-11",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object27 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-4-value-11",["layer"]=40,["point"]={2.9800000000000004,0.02},["size"]=13,["text"]="79"}
    local object28 = viewportScene1:rectangle {["center"]={3.91,0.02},["corner"]=0.025,["fill"]="#F3F4F5",["id"]="trace-4-cell-12",["layer"]=10,["size"]={0.86,0.7},["stroke"]="#D8DADD",["width"]=1.2}
    local object29 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="trace-4-value-12",["layer"]=40,["point"]={3.91,0.02},["size"]=13,["text"]="91"}
    local object30 = viewportScene1:line {["from"]={1.6600000000000006,-0.55},["id"]="trace-4-range",["layer"]=10,["stroke"]="#9B3600",["to"]={2.440000000000001,-0.55},["width"]=3}
    local object31 = viewportScene1:text {["align"]={0,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="trace-4-decision",["layer"]=40,["point"]={5.35,0.43},["size"]=15,["text"]="mid = 10  ·  68 = 68"}
    local object32 = viewportScene1:text {["align"]={0,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="trace-4-caption",["layer"]=40,["point"]={5.35,-0.16},["size"]=13,["text"]="return 10  →  search complete"}
    local object33 = viewportScene1:point {["fill"]="#9B3600",["id"]="trace-4-mid-marker",["layer"]=24,["opacity"]=0,["point"]={2.0500000000000007,0.52},["radius"]=4.5,["stroke"]="#FFFFFF",["width"]=2}
    viewportScene1:wait(0.7)
    viewportScene1:play({{target=object33,opacity=1}},0.3,"gentle",0)
    viewportScene1:indicate(object24,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.035})
    viewportScene1:indicate(object25,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.6,["scale"]=1.055})
    viewportScene1:indicate(object31,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.035})
    viewportScene1:play({{target=object33,opacity=0}},0.3,"gentle",0)
    viewportScene1:wait(0.45)
    viewportScene1:play({{target=object33,opacity=1}},0.3,"gentle",0)
    viewportScene1:indicate(object24,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.035})
    viewportScene1:indicate(object25,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.6,["scale"]=1.055})
    viewportScene1:indicate(object31,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.65,["scale"]=1.035})
    viewportScene1:play({{target=object33,opacity=0}},0.3,"gentle",0)
    viewportScene1:wait(1.8500000000000005)
    scene:viewport(viewportScene1,{["height"]=0.0781,["width"]=0.92,["x"]=0.04,["y"]=0.663})
end
do
    local viewportScene1 = tmath.scene {["background"]="#FFFFFF",["camera"]={["height"]=6.4,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=24,["height"]=316,["loop"]=false,["theme"]="pro_white",["width"]=439}
    local object1 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="complexity-title",["layer"]=40,["point"]={-4.05,2.63},["size"]=18,["text"]="D  ·  Candidate count"}
    local object2 = viewportScene1:text {["align"]={0,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="complexity-sequence",["layer"]=40,["point"]={-4.05,2.08},["role"]="code",["size"]=14,["text"]="13 → 6 → 3 → 1"}
    local object3 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="complexity-count-13",["layer"]=40,["point"]={-4.02,1.25},["size"]=13,["text"]="13"}
    local object4 = viewportScene1:rectangle {["center"]={-0.3999999999999999,1.25},["corner"]=0.015,["fill"]="#5E7A9B",["id"]="complexity-bar-13",["layer"]=10,["size"]={5.9,0.26},["stroke"]="#5E7A9B",["width"]=1}
    local object5 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="complexity-count-6",["layer"]=40,["point"]={-4.02,0.53},["size"]=13,["text"]="6"}
    local object6 = viewportScene1:rectangle {["center"]={-1.9884615384615383,0.53},["corner"]=0.015,["fill"]="#5E7A9B",["id"]="complexity-bar-6",["layer"]=10,["size"]={2.7230769230769236,0.26},["stroke"]="#5E7A9B",["width"]=1}
    local object7 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="complexity-count-3",["layer"]=40,["point"]={-4.02,-0.18999999999999995},["size"]=13,["text"]="3"}
    local object8 = viewportScene1:rectangle {["center"]={-2.669230769230769,-0.18999999999999995},["corner"]=0.015,["fill"]="#5E7A9B",["id"]="complexity-bar-3",["layer"]=10,["size"]={1.3615384615384618,0.26},["stroke"]="#5E7A9B",["width"]=1}
    local object9 = viewportScene1:text {["align"]={0,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="complexity-count-1",["layer"]=40,["point"]={-4.02,-0.9100000000000001},["size"]=13,["text"]="1"}
    local object10 = viewportScene1:rectangle {["center"]={-3.123076923076923,-0.9100000000000001},["corner"]=0.015,["fill"]="#9B3600",["id"]="complexity-bar-1",["layer"]=10,["size"]={0.4538461538461539,0.26},["stroke"]="#9B3600",["width"]=1}
    local object11 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="complexity-caption-1",["layer"]=40,["point"]={-4.05,-1.76},["size"]=12,["text"]="Each comparison roughly halves the candidate set."}
    local object12 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="complexity-caption-2",["layer"]=40,["point"]={-4.05,-2.28},["size"]=15,["text"]="Therefore: O(log n) comparisons."}
    local object13 = viewportScene1:point {["fill"]="#9B3600",["id"]="complexity-marker",["layer"]=24,["opacity"]=0,["point"]={2.5500000000000003,1.25},["radius"]=5,["stroke"]="#FFFFFF",["width"]=2}
    viewportScene1:wait(0.2)
    viewportScene1:play({{target=object13,opacity=1}},0.18,"gentle",0)
    viewportScene1:shift(object13,{-3.1769230769230767,-0.72},0.52,"ease_in_out")
    viewportScene1:shift(object13,{-1.3615384615384618,-0.72},0.52,"ease_in_out")
    viewportScene1:shift(object13,{-0.9076923076923078,-0.7200000000000002},0.52,"ease_in_out")
    viewportScene1:indicate(object10,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.46,["scale"]=1.035})
    viewportScene1:shift(object13,{5.446153846153846,2.16},0.82,"ease_in_out")
    viewportScene1:play({{target=object13,opacity=0}},0.18,"gentle",0)
    viewportScene1:wait(0.35)
    viewportScene1:play({{target=object13,opacity=1}},0.18,"gentle",0)
    viewportScene1:shift(object13,{-3.1769230769230767,-0.72},0.52,"ease_in_out")
    viewportScene1:shift(object13,{-1.3615384615384618,-0.72},0.52,"ease_in_out")
    viewportScene1:shift(object13,{-0.9076923076923078,-0.7200000000000002},0.52,"ease_in_out")
    viewportScene1:indicate(object10,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.46,["scale"]=1.035})
    viewportScene1:shift(object13,{5.446153846153846,2.16},0.82,"ease_in_out")
    viewportScene1:play({{target=object13,opacity=0}},0.18,"gentle",0)
    viewportScene1:wait(1.0499999999999998)
    scene:viewport(viewportScene1,{["height"]=0.216,["width"]=0.305,["x"]=0.04,["y"]=0.773})
end
do
    local viewportScene1 = tmath.scene {["background"]="#FFFFFF",["camera"]={["height"]=6.4,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=24,["height"]=316,["loop"]=false,["theme"]="pro_white",["width"]=504}
    local object1 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="invariant-title",["layer"]=40,["point"]={-4.72,2.63},["size"]=18,["text"]="E  ·  Range invariant"}
    local object2 = viewportScene1:text {["align"]={1,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="invariant-formula",["layer"]=40,["point"]={4.72,2.63},["role"]="code",["size"]=14,["text"]="68 ∈ a[lo ... hi]"}
    local object3 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="invariant-range-0",["layer"]=40,["point"]={-4.7,1.34},["size"]=12,["text"]="[0, 12]"}
    local object4 = viewportScene1:line {["from"]={-3.25,1.34},["id"]="invariant-line-0",["layer"]=10,["stroke"]="#5E7A9B",["to"]={3.85,1.34},["width"]=3}
    local object5 = viewportScene1:line {["from"]={-3.25,1.21},["id"]="invariant-left-0",["layer"]=10,["stroke"]="#5E7A9B",["to"]={-3.25,1.4700000000000002},["width"]=2}
    local object6 = viewportScene1:line {["from"]={3.85,1.21},["id"]="invariant-right-0",["layer"]=10,["stroke"]="#5E7A9B",["to"]={3.85,1.4700000000000002},["width"]=2}
    local object7 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="invariant-range-1",["layer"]=40,["point"]={-4.7,0.62},["size"]=12,["text"]="[7, 12]"}
    local object8 = viewportScene1:line {["from"]={0.35,0.62},["id"]="invariant-line-1",["layer"]=10,["stroke"]="#5E7A9B",["to"]={3.85,0.62},["width"]=3}
    local object9 = viewportScene1:line {["from"]={0.35,0.49},["id"]="invariant-left-1",["layer"]=10,["stroke"]="#5E7A9B",["to"]={0.35,0.75},["width"]=2}
    local object10 = viewportScene1:line {["from"]={3.85,0.49},["id"]="invariant-right-1",["layer"]=10,["stroke"]="#5E7A9B",["to"]={3.85,0.75},["width"]=2}
    local object11 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="invariant-range-2",["layer"]=40,["point"]={-4.7,-0.1},["size"]=12,["text"]="[10, 12]"}
    local object12 = viewportScene1:line {["from"]={1.72,-0.1},["id"]="invariant-line-2",["layer"]=10,["stroke"]="#5E7A9B",["to"]={3.85,-0.1},["width"]=3}
    local object13 = viewportScene1:line {["from"]={1.72,-0.23},["id"]="invariant-left-2",["layer"]=10,["stroke"]="#5E7A9B",["to"]={1.72,0.03},["width"]=2}
    local object14 = viewportScene1:line {["from"]={3.85,-0.23},["id"]="invariant-right-2",["layer"]=10,["stroke"]="#5E7A9B",["to"]={3.85,0.03},["width"]=2}
    local object15 = viewportScene1:text {["align"]={0,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="invariant-range-3",["layer"]=40,["point"]={-4.7,-0.82},["size"]=12,["text"]="[10, 10]"}
    local object16 = viewportScene1:line {["from"]={1.72,-0.82},["id"]="invariant-line-3",["layer"]=10,["stroke"]="#9B3600",["to"]={2.04,-0.82},["width"]=5}
    local object17 = viewportScene1:line {["from"]={1.72,-0.95},["id"]="invariant-left-3",["layer"]=10,["stroke"]="#9B3600",["to"]={1.72,-0.69},["width"]=2}
    local object18 = viewportScene1:line {["from"]={2.04,-0.95},["id"]="invariant-right-3",["layer"]=10,["stroke"]="#9B3600",["to"]={2.04,-0.69},["width"]=2}
    local object19 = viewportScene1:line {["dash"]={5,5},["from"]={1.88,1.62},["id"]="invariant-target-line",["layer"]=10,["stroke"]="#9B3600",["to"]={1.88,-1.1},["width"]=2}
    local object20 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="invariant-target-label",["layer"]=40,["point"]={1.88,1.92},["size"]=13,["text"]="68"}
    local object21 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="invariant-caption-1",["layer"]=40,["point"]={-4.72,-1.72},["size"]=12,["text"]="Discard only the half contradicted by the comparison."}
    local object22 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="invariant-caption-2",["layer"]=40,["point"]={-4.72,-2.24},["size"]=15,["text"]="Target 68 remains inside every retained interval."}
    local object23 = viewportScene1:point {["fill"]="#9B3600",["id"]="invariant-marker",["layer"]=24,["opacity"]=0,["point"]={1.88,1.34},["radius"]=6,["stroke"]="#FFFFFF",["width"]=2}
    viewportScene1:wait(0.35)
    viewportScene1:play({{target=object23,opacity=1}},0.18,"gentle",0)
    viewportScene1:shift(object23,{0,-0.7200000000000001},0.48,"ease_in_out")
    viewportScene1:shift(object23,{0,-0.72},0.48,"ease_in_out")
    viewportScene1:shift(object23,{0,-0.72},0.48,"ease_in_out")
    viewportScene1:indicate(object19,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.46,["scale"]=1.018})
    viewportScene1:shift(object23,{0,2.16},0.82,"ease_in_out")
    viewportScene1:play({{target=object23,opacity=0}},0.18,"gentle",0)
    viewportScene1:wait(0.35)
    viewportScene1:play({{target=object23,opacity=1}},0.18,"gentle",0)
    viewportScene1:shift(object23,{0,-0.7200000000000001},0.48,"ease_in_out")
    viewportScene1:shift(object23,{0,-0.72},0.48,"ease_in_out")
    viewportScene1:shift(object23,{0,-0.72},0.48,"ease_in_out")
    viewportScene1:indicate(object19,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.46,["scale"]=1.018})
    viewportScene1:shift(object23,{0,2.16},0.82,"ease_in_out")
    viewportScene1:play({{target=object23,opacity=0}},0.18,"gentle",0)
    viewportScene1:wait(1.1399999999999997)
    scene:viewport(viewportScene1,{["height"]=0.216,["width"]=0.35,["x"]=0.37,["y"]=0.773})
end
do
    local viewportScene1 = tmath.scene {["background"]="#FFFFFF",["camera"]={["height"]=6.4,["mode"]="fixed",["target"]={0,0},["view"]="2d"},["fps"]=24,["height"]=316,["loop"]=false,["theme"]="pro_white",["width"]=324}
    local object1 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="result-title",["layer"]=40,["point"]={-2.98,2.63},["size"]=18,["text"]="F  ·  Result"}
    local object2 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#5E7A9B",["font"]="Pretendard",["id"]="result-access",["layer"]=40,["point"]={-1.65,1.28},["role"]="code",["size"]=18,["text"]="a[10]"}
    local object3 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="result-equals",["layer"]=40,["point"]={0,1.28},["size"]=18,["text"]="="}
    local object4 = viewportScene1:circle {["center"]={1.62,1.28},["fill"]="#F5E8E1",["id"]="result-ring",["layer"]=10,["radius"]=0.54,["stroke"]="#9B3600",["width"]=2.5}
    local object5 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="result-value",["layer"]=40,["point"]={1.62,1.28},["size"]=20,["text"]="68"}
    local object6 = viewportScene1:line {["from"]={-2.35,0.38},["id"]="result-rule",["stroke"]="#D8DADD",["to"]={2.35,0.38},["width"]=1}
    local object7 = viewportScene1:text {["align"]={0.5,0.5},["fill"]="#9B3600",["font"]="Pretendard",["id"]="result-return",["layer"]=40,["point"]={0,-0.3},["role"]="code",["size"]=25,["text"]="return 10"}
    local object8 = viewportScene1:text {["align"]={0,0.5},["fill"]="#555B64",["font"]="Pretendard",["id"]="result-caption-1",["layer"]=40,["point"]={-2.98,-1.45},["size"]=12,["text"]="Equality terminates the search."}
    local object9 = viewportScene1:text {["align"]={0,0.5},["fill"]="#202124",["font"]="Pretendard",["id"]="result-caption-2",["layer"]=40,["point"]={-2.98,-1.98},["size"]=15,["text"]="Return index 10."}
    local object10 = viewportScene1:point {["fill"]="#9B3600",["id"]="result-token",["layer"]=24,["opacity"]=0,["point"]={-1.65,0.82},["radius"]=5,["stroke"]="#FFFFFF",["width"]=2}
    viewportScene1:wait(0.35)
    viewportScene1:play({{target=object10,opacity=1}},0.18,"gentle",0)
    viewportScene1:shift(object10,{3.27,0},0.85,"gentle")
    viewportScene1:indicate(object4,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.5,["scale"]=1.035})
    viewportScene1:shift(object10,{-3.27,0},0.85,"gentle")
    viewportScene1:play({{target=object10,opacity=0}},0.18,"gentle",0)
    viewportScene1:wait(0.45)
    viewportScene1:play({{target=object10,opacity=1}},0.18,"gentle",0)
    viewportScene1:shift(object10,{3.27,0},0.85,"gentle")
    viewportScene1:indicate(object4,{["color"]="#9B3600",["curve"]="gentle",["duration"]=0.5,["scale"]=1.035})
    viewportScene1:shift(object10,{-3.27,0},0.85,"gentle")
    viewportScene1:play({{target=object10,opacity=0}},0.18,"gentle",0)
    viewportScene1:wait(2.08)
    scene:viewport(viewportScene1,{["height"]=0.216,["width"]=0.225,["x"]=0.735,["y"]=0.773})
end
return scene
