---@meta tmath

-- Generated from api/tmath-api.json. Do not edit directly.

---@alias tmath.Color string
---@alias tmath.ThemeColor 'background'|'foreground'|'muted'|'accent'|'secondary'|'success'|'warning'|'danger'|'info'|'surface'|'border'|'result'|'focus'
---@alias tmath.Vec2 {[1]: number, [2]: number}
---@alias tmath.Vec3 {[1]: number, [2]: number, [3]: number}
---@alias tmath.Range {[1]: number, [2]: number, [3]?: number}
---@alias tmath.Mat4 number[]
---@alias tmath.Curve 'linear'|'smooth'|'ease_in'|'ease_out'|'ease_in_out'|'gentle'|'snappy'|{preset: string, strength?: number, reverse?: boolean}|{bezier: number[], strength?: number}
---@alias tmath.CreateDirection 'forward'|'reverse'|'clockwise'|'counterclockwise'
---@alias tmath.PathCommand table

---@class tmath.RuntimeConfig
---@field fixed_step? number Deterministic callback step in seconds; defaults to 1/120 and must be at most 1.
---@field max_steps? integer Maximum catch-up callbacks per host advance, from 1 to 64; defaults to 8.
---@field update fun(ctx:tmath.Runtime, dt:number, time:number, tick:integer) Protected fixed-step callback retained with the Scene VM.

---@class tmath.RuntimeObjectState
---@field origin? tmath.Vec3 Optional fixed parent-space pivot; otherwise the authored Object family center is captured on first update.
---@field shift? tmath.Vec3 Parent-space translation over the authored Scene state.
---@field rotation? number|tmath.Vec3 Z radians or XYZ radians around origin.
---@field scale? tmath.Vec3 XYZ scale around origin.
---@field opacity? number Multiplicative opacity in [0, 1].
---@field progress? number Multiplicative draw progress in [0, 1].
---@field fill? tmath.Color|tmath.ThemeColor Optional solid fill override resolved during the callback.

---@class tmath.RuntimeSoundConfig
---@field bus? "music"|"effect"|"ui" Independent Audio bus description; defaults to effect.
---@field gain? number Linear playback gain in [0, 4].
---@field rate? number Playback rate in [0.125, 8].
---@field loop? boolean Whether an Audio-capable host should loop this immediate voice.

---@class tmath.RuntimeActionState
---@field previous tmath.Vec2 Aggregate action value in the previous consumed input frame.
---@field value tmath.Vec2 Current clamped aggregate action value.
---@field delta tmath.Vec2 Current value minus previous value.
---@field down boolean Whether any contributing source is currently held.
---@field pressed boolean Aggregate Down edge for the first fixed step consuming this host frame.
---@field released boolean Aggregate Up edge for the first fixed step consuming this host frame.

---@class tmath.RuntimeKeyState
---@field begin number Time of the latest accepted key press.
---@field end number Time of the latest accepted key transition.
---@field previous boolean Held state in the previous consumed input frame.
---@field down boolean Current held state.
---@field pressed boolean Down edge for the first fixed step consuming this host frame.
---@field released boolean Up edge for the first fixed step consuming this host frame.

---@class tmath.RuntimePointerState
---@field position tmath.Vec2 Latest logical Scene pixel position.
---@field delta tmath.Vec2 Accumulated logical-pixel motion in this input frame.
---@field wheel tmath.Vec2 Accumulated wheel motion in this input frame.
---@field pointer integer Stable pointer identifier.
---@field previous_buttons integer Previous consumed button mask.
---@field buttons integer Current button mask.
---@field pressed integer Button Down-edge mask for the first fixed step consuming this frame.
---@field released integer Button Up-edge mask for the first fixed step consuming this frame.
---@field active boolean Whether the pointer has not been cancelled or released by the host.

---@class tmath.Animation
---@field target tmath.Object Distinct live target owned by this Scene.
---@field shift? tmath.Vec2|tmath.Vec3 Parent-space shift; mutually exclusive with transform.
---@field transform? tmath.Mat4 Absolute local-to-parent transform; mutually exclusive with shift.
---@field opacity? number Target opacity from 0 to 1.
---@field stroke? tmath.Color|tmath.ThemeColor Target stroke color.
---@field fill? tmath.Color|tmath.ThemeColor Target fill color.
---@field dash_offset? number Target shaft dash offset; requires an existing non-empty dash pattern.
---@field tail? number Target solid tail-marker size for Arrow, Vector, Connector, or Route.
---@field tip? number Target solid tip-marker size for Arrow, Vector, Connector, or Route.

---@class tmath.DiagramLayersConfig
---@field zones? integer Sibling layer for zone backgrounds.
---@field routes? integer Sibling layer for edge routes.
---@field nodes? integer Sibling layer for nodes.
---@field annotations? integer Sibling layer for labels and annotations.

---@class tmath.DiagramConfig
---@field id? string Stable generated subtree identifier.
---@field layout? "ranked"|"manual"|"grid"|"timeline" Bounded node layout strategy.
---@field direction? "lr"|"left_to_right"|"tb"|"top_to_bottom" Rank direction and automatic port-routing bias.
---@field origin? tmath.Vec2 Layout origin; origin.x is time zero for timeline.
---@field node_size? tmath.Vec2 Default node width and height.
---@field rank_gap? number Gap between consecutive ranks or grid columns.
---@field node_gap? number Gap between nodes in one rank or layout rows.
---@field time_unit? number Positive world-space width per timeline unit.
---@field zone_padding? number Padding around zone members.
---@field route_width? number Base route stroke width.
---@field arrow_length? number Arrowhead length.
---@field arrow_width? number Arrowhead width.
---@field corner? number Node and zone corner radius.
---@field layers? tmath.DiagramLayersConfig Generated sibling layer assignments.

---@class tmath.DiagramNodeConfig
---@field id string Unique node identifier.
---@field label? string Primary node label; defaults to id.
---@field detail? string Optional secondary node label.
---@field kind? "default"|"state"|"decision"|"terminal"|"entity"|"cell"|"task"|"evidence" Semantic Theme-derived node treatment.
---@field rank? integer Explicit ranked-layout rank.
---@field row? integer Zero-based grid or timeline row.
---@field column? integer Zero-based grid column.
---@field start? number Finite timeline start relative to origin.x.
---@field span? number Positive timeline duration in time units.
---@field position? tmath.Vec2 Required node center for manual layout; optional ranked override.
---@field size? tmath.Vec2 Per-node width and height override.

---@class tmath.DiagramEdgeConfig
---@field id string Unique edge identifier.
---@field label? string Optional edge label.
---@field from tmath.DiagramNode Source node handle from this Diagram.
---@field to tmath.DiagramNode Destination node handle from this Diagram.
---@field from_port? "auto"|"left"|"right"|"top"|"bottom" Source attachment port.
---@field to_port? "auto"|"left"|"right"|"top"|"bottom" Destination attachment port.
---@field route? "auto"|"straight"|"orthogonal" Route strategy.
---@field kind? "directed"|"relation"|"return"|"error"|"optional" Semantic direction, marker, color, and dash treatment.
---@field waypoints? tmath.Vec2[] One to sixteen explicit intermediate route points.
---@field flow? boolean Render the edge itself as one dashed directed route.
---@field flow_offset? number Initial shaft dash offset for a flow edge.

---@class tmath.DiagramZoneConfig
---@field id string Unique zone identifier.
---@field label? string Optional zone label.
---@field members tmath.DiagramNode[] One or more node handles from this Diagram.
---@field full_width? boolean Span all diagram nodes horizontally while retaining member-derived vertical bounds.

---@class tmath.ChartFrameConfig
---@field center? tmath.Vec2 Chart frame center.
---@field size tmath.Vec2 Positive chart frame width and height.

---@class tmath.ChartRangeConfig
---@field min number Range minimum.
---@field max number Range maximum.
---@field step? number Positive tick step.

---@class tmath.ChartConfig
---@field id? string Stable generated subtree identifier.
---@field frame? tmath.ChartFrameConfig Chart position and dimensions.
---@field x? tmath.Range|tmath.ChartRangeConfig Horizontal data range.
---@field y? tmath.Range|tmath.ChartRangeConfig Vertical data range.
---@field x_ticks? integer Horizontal tick count.
---@field y_ticks? integer Vertical tick count.
---@field axes? boolean Generate axes.
---@field grid? boolean Generate grid lines.
---@field ticks? boolean Generate tick labels.
---@field legend? boolean Generate series legend labels.
---@field padding? number Inner frame padding.
---@field line_width? number Line-series stroke width.
---@field bar_gap? number Gap between adjacent bars.

---@class tmath.ChartSeriesConfig
---@field id string Unique series identifier.
---@field label? string Optional legend label.
---@field mark? "line"|"bar" Generated mark kind.
---@field data tmath.Vec2[] One to 4096 x/y samples.
---@field color_index? integer Zero-based Theme object-cycle color index; omit it or use -1 for automatic series order.

---@class tmath.SceneConfig
---@field width? integer Canvas width in pixels.
---@field height? integer Canvas height in pixels.
---@field fps? number Authored frame rate.
---@field loop? boolean Whether playback loops.
---@field background? tmath.Color Canvas background color.
---@field antialiasing? boolean Enable renderer antialiasing.
---@field theme? string|tmath.ThemeConfig Built-in theme name (including adaptive_vscode in supporting IDE hosts) or custom theme.
---@field camera? tmath.CameraConfig Camera view and interaction settings.

---@class tmath.StyleGroupConfig
---@field color? tmath.Color|tmath.ThemeColor Initial shared semantic color. When omitted, infer it from the first member's selected paint channel.
---@field members tmath.StyleGroupMember[] Live objects and the paint channels that carry this identity.

---@class tmath.StyleGroupMember
---@field target tmath.Object Clip-free live object to bind.
---@field channel? "stroke"|"fill"|"both" Paint channel that carries the identity.

---@class tmath.ThemeConfig
---@field preset? string Built-in Theme base preset.
---@field background? tmath.Color Canvas background color.
---@field text? table H1, H2, H3, text, and code typography overrides.
---@field objects? tmath.Color[] Automatic 1..10 color cycle shared in order by lhs, rhs, every later args member, and other peer categories.
---@field object_width? number Automatic object stroke width.
---@field gradient? boolean Enable automatic object gradients.
---@field end_gradient_stop? tmath.Color Automatic gradient end color.
---@field axis? table Axis, grid, and label color overrides.
---@field colors? tmath.SemanticThemeConfig Named semantic colors used by objects and emphasis effects.

---@class tmath.SemanticThemeConfig
---@field foreground? tmath.Color Primary foreground color.
---@field muted? tmath.Color De-emphasized foreground color.
---@field accent? tmath.Color Primary accent or non-result emphasis color.
---@field secondary? tmath.Color Secondary emphasis color.
---@field success? tmath.Color Successful or valid state color.
---@field warning? tmath.Color Warning state color.
---@field danger? tmath.Color Error or destructive state color.
---@field info? tmath.Color Informational state color.
---@field surface? tmath.Color Raised or grouped surface color.
---@field border? tmath.Color Boundary and divider color.
---@field result? tmath.Color Returned value, derived result, or output data-structure color.
---@field focus? tmath.Color Transient current-subject or important-region color.

---@class tmath.ObjectConfig
---@field id? string Stable object identifier.
---@field opacity? number Opacity from 0 to 1.
---@field color? tmath.Color|tmath.ThemeColor Apply one literal or semantic Theme color to available stroke and fill paints.
---@field fill? tmath.Color|tmath.ThemeColor Literal or semantic Theme fill color.
---@field stroke? tmath.Color|tmath.ThemeColor Literal or semantic Theme stroke color.
---@field gradient? boolean|tmath.Color|tmath.ThemeColor Enable a gradient or set its literal or semantic Theme end color.
---@field width? number Stroke width in pixels.
---@field radius? number Style radius in pixels.
---@field dash? number[] Stroke dash pattern.
---@field dash_offset? number Stroke dash offset.
---@field progress? number Draw progress from 0 to 1.
---@field layer? integer Sibling paint order.

---@class tmath.GroupConfig: tmath.ObjectConfig
---@field matrix? tmath.Mat4 Local-to-parent transform.
---@field id? string Stable object identifier.

---@class tmath.SpaceConfig: tmath.ObjectConfig
---@field x? tmath.Range Horizontal world range.
---@field y? tmath.Range Vertical world range.
---@field z? tmath.Range Depth world range.
---@field axis_x? tmath.Color|tmath.ThemeColor X-axis literal or semantic Theme color.
---@field axis_y? tmath.Color|tmath.ThemeColor Y-axis literal or semantic Theme color.
---@field axis_z? tmath.Color|tmath.ThemeColor Z-axis literal or semantic Theme color.
---@field numbers? boolean Draw axis numbers.
---@field number_mode? "fixed"|"relative" Number label sizing mode.
---@field number_size? number Number label size.
---@field number_color? tmath.Color|tmath.ThemeColor Number label literal or semantic Theme color.
---@field matrix? tmath.Mat4 Local-to-parent transform.
---@field id? string Stable object identifier.

---@class tmath.PointConfig: tmath.ObjectConfig
---@field point tmath.Vec2|tmath.Vec3 Point in parent coordinates.
---@field radius? number Marker radius in pixels.

---@class tmath.LineConfig: tmath.ObjectConfig
---@field from tmath.Vec2|tmath.Vec3 Start point.
---@field to tmath.Vec2|tmath.Vec3 End point.
---@field stroke? tmath.Color|tmath.ThemeColor Literal or semantic Theme stroke color.
---@field width? number Stroke width in pixels.

---@class tmath.ArrowConfig: tmath.ObjectConfig
---@field from tmath.Vec2|tmath.Vec3 Start point.
---@field to tmath.Vec2|tmath.Vec3 End point.
---@field tail? number Tail size in pixels.
---@field tip? number Tip size in pixels.

---@class tmath.VectorConfig: tmath.ObjectConfig
---@field origin? tmath.Vec2|tmath.Vec3 Vector origin.
---@field value tmath.Vec2|tmath.Vec3 Vector value.
---@field tail? number Tail size in pixels.
---@field tip? number Tip size in pixels.

---@class tmath.CircleConfig: tmath.ObjectConfig
---@field center? tmath.Vec2|tmath.Vec3 Circle center.
---@field radius? number Radius in world units.

---@class tmath.RectangleConfig: tmath.ObjectConfig
---@field center? tmath.Vec2|tmath.Vec3 Rectangle center.
---@field size tmath.Vec2 Width and height in world units.
---@field corner? number Corner radius.

---@class tmath.PolygonConfig: tmath.ObjectConfig
---@field points tmath.Vec2[]|tmath.Vec3[] At least three polygon vertices.

---@class tmath.PlotConfig: tmath.ObjectConfig
---@field points? tmath.Vec2[]|tmath.Vec3[] Explicit plot samples.
---@field fn? fun(x:number):number Deterministic function to sample.
---@field x_range? tmath.Range Inclusive sampling range.

---@class tmath.RouteConfig: tmath.ObjectConfig
---@field points tmath.Vec2[]|tmath.Vec3[] At least two ordered route vertices.
---@field tail? number Solid tail-marker size in pixels.
---@field tip? number Solid tip-marker size in pixels.

---@class tmath.PathConfig: tmath.ObjectConfig
---@field commands tmath.PathCommand[] Move, line, quadratic, cubic, and close commands.
---@field samples? integer Curve sampling count.

---@class tmath.CurveConfig: tmath.ObjectConfig
---@field from tmath.Vec2|tmath.Vec3 Start point.
---@field control1 tmath.Vec2|tmath.Vec3 First control point.
---@field control2 tmath.Vec2|tmath.Vec3 Second control point.
---@field to tmath.Vec2|tmath.Vec3 End point.
---@field samples? integer Curve sampling count.

---@class tmath.SurfaceConfig: tmath.ObjectConfig
---@field points tmath.Vec3[] Row-major surface vertices.
---@field size tmath.Vec2 Column and row count.
---@field mode? "solid"|"mesh"|"solid_mesh" Surface drawing mode.
---@field shading? boolean Enable surface shading.

---@class tmath.TextConfig: tmath.ObjectConfig
---@field text string Text content.
---@field point? tmath.Vec2|tmath.Vec3 Text anchor point.
---@field font? string Registered font or asset name.
---@field size? number Font size in pixels.
---@field align? tmath.Vec2 Horizontal and vertical alignment.
---@field role? string Theme typography role.
---@field fill? tmath.Color|tmath.ThemeColor Literal or semantic Theme text color.

---@class tmath.RulerConfig: tmath.ObjectConfig
---@field from tmath.Vec2|tmath.Vec3 Start point.
---@field to tmath.Vec2|tmath.Vec3 End point.
---@field step? number Tick interval in world units.
---@field tick? number Tick length in pixels.

---@class tmath.SvgConfig: tmath.ObjectConfig
---@field path string Trusted SVG path data.
---@field center? tmath.Vec2|tmath.Vec3 Object center.
---@field width? number Object width in world units.

---@class tmath.ImageConfig: tmath.ObjectConfig
---@field asset? string Registered or relative asset path.
---@field pixels? tmath.Color[] Dense row-major inline pixels.
---@field size? tmath.Vec2 Inline pixel dimensions.
---@field center? tmath.Vec2|tmath.Vec3 Image center.
---@field width? number Image width in world units.
---@field filter? "bilinear"|"nearest" Sampling filter.

---@class tmath.CellConfig: tmath.ObjectConfig
---@field color? tmath.Color|tmath.ThemeColor Base literal or semantic Theme cell color.
---@field origin? tmath.Vec2|tmath.Vec3 Grid origin.
---@field size tmath.Vec2 Grid columns and rows.
---@field mode? "full"|"padd" Cell rendering mode.
---@field padding? number Cell padding.
---@field depth? number Cell depth.
---@field texture? string Texture asset name.
---@field source? table Source texture region.
---@field destination? table Destination cell region.
---@field patches? table[] Region color patches supporting literal or semantic Theme colors.

---@class tmath.ConnectorConfig: tmath.ObjectConfig
---@field from tmath.Object Source object.
---@field to tmath.Object Destination object.
---@field padding? number Endpoint padding.
---@field tail? number Tail size in pixels.
---@field tip? number Tip size in pixels.

---@class tmath.ViewportConfig
---@field x number Normalized left coordinate.
---@field y number Normalized top coordinate.
---@field width number Normalized width.
---@field height number Normalized height.

---@class tmath.SceneTransitionConfig
---@field duration? number Transition duration in seconds.
---@field hold? number Hold duration in seconds.
---@field curve? tmath.Curve Animation curve.
---@field viewport? tmath.ViewportConfig Normalized viewport.

---@class tmath.FadeConfig
---@field shift? tmath.Vec2|tmath.Vec3 Parent-space offset.
---@field scale? number Relative scale.
---@field duration? number Duration in seconds.
---@field curve? tmath.Curve Animation curve.

---@class tmath.IndicateConfig
---@field color? tmath.Color|tmath.ThemeColor Temporary emphasis color; defaults to the Theme focus role.
---@field scale? number Temporary scale.
---@field duration? number Duration in seconds.
---@field curve? tmath.Curve Animation curve.

---@class tmath.RegionConfig
---@field x number Logical-pixel left coordinate in the Canvas.
---@field y number Logical-pixel top coordinate in the Canvas.
---@field width number Positive logical-pixel hit-region width.
---@field height number Positive logical-pixel hit-region height.

---@class tmath.UITransformConfig
---@field shift? tmath.Vec3 Runtime translation composed after the authored timeline.
---@field scale? tmath.Vec3 Runtime scale composed after the authored timeline.
---@field rotation? tmath.Vec3 Runtime XYZ rotation in radians composed after the authored timeline.
---@field opacity? number Runtime opacity factor from 0 to 1.
---@field progress? number Runtime draw-progress factor from 0 to 1.

---@class tmath.PanelButtonConfig
---@field visual tmath.Object Independent Scene object reserved as this control's idle button visual.
---@field hover_visual? tmath.Object Optional independent, non-nested Scene object reserved for this button and shown while the logical pointer is inside its region.
---@field pressed_visual? tmath.Object Optional independent, non-nested Scene object reserved for this button and shown while the primary pointer is pressed inside its region.
---@field region tmath.RegionConfig Explicit logical-pixel pointer region.
---@field camera? "move"|"pan"|"orbit"|"zoom"|"reset"|"view2d"|"view3d" Camera action performed after a completed click; use exactly one of camera or target.
---@field delta? tmath.Vec2 Pan, orbit, or zoom action delta.
---@field target? tmath.Object Scene object receiving a click-selected transform; use exactly one of target or camera.
---@field transform? tmath.UITransformConfig Transform selected after a completed click; the last clicked Button wins when several Buttons share a target.
---@field duration? number Optional smooth target-transition duration in Scene seconds; zero changes immediately.

---@class tmath.PanelToggleButtonConfig
---@field visual tmath.Object Independent Scene object reserved as this control's idle visual.
---@field hover_visual? tmath.Object Optional independent, non-nested Scene object shown while the logical pointer is inside the control region.
---@field pressed_visual? tmath.Object Optional independent, non-nested Scene object shown while the primary pointer is pressed inside the control region.
---@field region tmath.RegionConfig Explicit logical-pixel pointer region.
---@field target tmath.Object Scene object receiving the retained binary-state transform.
---@field off tmath.UITransformConfig Target transform while the retained value is false.
---@field on tmath.UITransformConfig Target transform while the retained value is true.
---@field value? boolean Initial retained state; false by default.
---@field duration? number Optional smooth off/on transition duration in Scene seconds; zero changes immediately.

---@class tmath.SliderBindingConfig
---@field target tmath.Object Scene object receiving this synchronized Slider transform.
---@field from? tmath.UITransformConfig Transform at slider value 0.
---@field to? tmath.UITransformConfig Transform at slider value 1.

---@class tmath.PanelSliderConfig
---@field visual tmath.Object Independent Scene object reserved as this control's slider visual.
---@field target? tmath.Object Scene object receiving the interpolated runtime transform. Use this single-target form or bindings, never both.
---@field bindings? tmath.SliderBindingConfig[] One to 256 synchronized target mappings. Cannot be combined with top-level target, from, or to.
---@field region tmath.RegionConfig Explicit logical-pixel pointer region.
---@field axis? "horizontal"|"vertical" Logical-pixel slider direction.
---@field value? number Initial clamped value from 0 to 1.
---@field from? tmath.UITransformConfig Transform at slider value 0.
---@field to? tmath.UITransformConfig Transform at slider value 1.

---@class tmath.PanelSampleAreaConfig
---@field region tmath.RegionConfig Logical-pixel click region. A successful sample stores normalized top-left-origin coordinates: (0, 0) at the region top-left and (1, 1) at the bottom-right.
---@field targets tmath.Object[] Between 1 and 64 distinct Scene-owned configured candidates with no ancestor/descendant relationship. The topmost candidate whose isolated family composite has nonzero raster alpha wins; returned identity is that configured candidate, not an internal leaf paint.
---@field marker? tmath.Object Optional independent childless Scene Object or Group hidden until the first successful sample, then shifted after the current composed state is sampled.
---@field marker_origin? tmath.Vec3 Marker parent-space runtime shift at normalized u=0 and v=0; marker is required when this field is supplied.
---@field marker_x? tmath.Vec3 Marker parent-space runtime-shift contribution at normalized u=1; marker is required when this field is supplied.
---@field marker_y? tmath.Vec3 Marker parent-space runtime-shift contribution at normalized top-to-bottom v=1; marker is required when this field is supplied.
---@field swatch? tmath.Object Optional independent, non-gradient Scene Rectangle whose solid fill becomes the selected candidate-family composite in straight RGBA, isolated from the background and non-family Objects and rasterized with the Scene AA policy.

---@class tmath.InputPointerFollowConfig
---@field target tmath.Object Scene object receiving the pointer-derived runtime transform.
---@field region tmath.RegionConfig Logical-pixel pointer region mapped to normalized coordinates u and v.
---@field target_origin? tmath.Vec3 Parent-space home pivot moved to the mapped point and used for pointer-facing rotation; defaults to the parent-space origin.
---@field map_origin tmath.Vec3 Parent-space position at the region's top-left corner.
---@field map_x tmath.Vec3 Parent-space contribution at normalized u=1.
---@field map_y tmath.Vec3 Parent-space contribution at normalized top-to-bottom v=1.
---@field period? number Smooth transition period in Scene seconds for each newest pointer sample; defaults to 0.18.
---@field rotate? boolean Rotate the target toward the newest mapped pointer position; true by default.
---@field angle_offset? number Additional Z rotation in radians after the pointer-facing angle.
---@field reset_on_leave? boolean Smoothly restore the authored transform after pointer cancel or leave.

---@class tmath.InputKeyMoveConfig
---@field target tmath.Object Scene object receiving continuous held-key motion.
---@field key "ArrowLeft"|"ArrowRight"|"ArrowUp"|"ArrowDown"|"tmath.Space"|"Enter"|"Escape"|"Shift"|"Tab"|"A-Z"|"0-9"|"Plus"|"Minus" Supported logical key name.
---@field shift tmath.Vec3 Parent-space displacement applied per period while the key is down.
---@field period? number Initial acceleration and displacement period in Scene seconds; zero applies one immediate Down-edge shift; defaults to 0.12.

---@class tmath.CameraConfig
---@field mode? "fixed"|"interactive" Camera interaction mode.
---@field view? "2d"|"3d" Camera view.
---@field target? tmath.Vec2|tmath.Vec3 Camera target.
---@field eye? tmath.Vec3 3D camera eye.
---@field up? tmath.Vec3 3D camera up vector.
---@field fov? number Perspective field of view in radians.
---@field height? number Orthographic view height.
---@field near? number Near clipping plane.
---@field far? number Far clipping plane.
---@field projection? "perspective"|"orthographic" 3D projection mode.

---@class tmath.SampleConfig
---@field mode? string Sampling display mode.
---@field padding? number Gap between cells.
---@field duration? number Sampling duration in seconds.
---@field fps? number Sampling frame rate.

---@class tmath.Object
local Object = {}

---Create a semantic object container.
---@param config? tmath.GroupConfig
---@return tmath.Group
function Object:group(config) end

---Create a 2D or 3D coordinate space.
---@param config? tmath.SpaceConfig
---@return tmath.Space
function Object:space(config) end

---Create a point marker.
---@param config? tmath.PointConfig
---@return tmath.Object
function Object:point(config) end

---Create a line segment.
---@param config? tmath.LineConfig
---@return tmath.Object
function Object:line(config) end

---Create an arrow between two points.
---@param config? tmath.ArrowConfig
---@return tmath.Object
function Object:arrow(config) end

---Create a vector from an origin and value.
---@param config? tmath.VectorConfig
---@return tmath.Object
function Object:vector(config) end

---Create a circle.
---@param config? tmath.CircleConfig
---@return tmath.Object
function Object:circle(config) end

---Create a rectangle.
---@param config? tmath.RectangleConfig
---@return tmath.Object
function Object:rectangle(config) end

---Create a polygon from at least three points.
---@param config? tmath.PolygonConfig
---@return tmath.Object
function Object:polygon(config) end

---Create a sampled function or polyline plot.
---@param config? tmath.PlotConfig
---@return tmath.Object
function Object:plot(config) end

---Create one directed polyline route whose dashed shaft and solid endpoint markers share one timeline state.
---@param config? tmath.RouteConfig
---@return tmath.Object
function Object:route(config) end

---Create a path from keyed contour commands.
---@param config? tmath.PathConfig
---@return tmath.Object
function Object:path(config) end

---Create a cubic Bézier curve.
---@param config? tmath.CurveConfig
---@return tmath.Object
function Object:curve(config) end

---Create a row-major 3D surface mesh.
---@param config? tmath.SurfaceConfig
---@return tmath.Object
function Object:surface(config) end

---Create a text object.
---@param config? tmath.TextConfig
---@return tmath.Object
function Object:text(config) end

---Create a measured ruler.
---@param config? tmath.RulerConfig
---@return tmath.Object
function Object:ruler(config) end

---Create an object from trusted SVG path data.
---@param config? tmath.SvgConfig
---@return tmath.Object
function Object:svg(config) end

---Create an image from an asset or inline pixels.
---@param config? tmath.ImageConfig
---@return tmath.Object
function Object:image(config) end

---Create a dense color cell grid.
---@param config? tmath.CellConfig
---@return tmath.Object
function Object:cell(config) end

---Create a connector between two object handles.
---@param config? tmath.ConnectorConfig
---@return tmath.Object
function Object:connector(config) end

---Create an ordinary child Text as this object's semantic label, using the complete Text configuration without automatic placement or color binding.
---@param config tmath.TextConfig
---@return tmath.Object
function Object:label(config) end

---Move this object to a parent-space point before animation begins.
---@param point tmath.Vec2|tmath.Vec3
function Object:move_to(point) end

---Place this object next to a sibling.
---@param other tmath.Object
---@param direction tmath.Vec2|tmath.Vec3
---@param gap? number
function Object:next_to(other, direction, gap) end

---Align this object to a sibling.
---@param other tmath.Object
---@param direction tmath.Vec2|tmath.Vec3
function Object:align_to(other, direction) end

---Arrange Group children in one direction.
---@param direction tmath.Vec2|tmath.Vec3
---@param gap? number
function Object:arrange(direction, gap) end

---Arrange Group children in a grid.
---@param columns integer
---@param columnGap? number
---@param rowGap? number
function Object:arrange_grid(columns, columnGap, rowGap) end

---@class tmath.Group: tmath.Object
local Group = {}

---Create a semantic object container.
---@param config? tmath.GroupConfig
---@return tmath.Group
function Group:group(config) end

---Create a 2D or 3D coordinate space.
---@param config? tmath.SpaceConfig
---@return tmath.Space
function Group:space(config) end

---Create a point marker.
---@param config? tmath.PointConfig
---@return tmath.Object
function Group:point(config) end

---Create a line segment.
---@param config? tmath.LineConfig
---@return tmath.Object
function Group:line(config) end

---Create an arrow between two points.
---@param config? tmath.ArrowConfig
---@return tmath.Object
function Group:arrow(config) end

---Create a vector from an origin and value.
---@param config? tmath.VectorConfig
---@return tmath.Object
function Group:vector(config) end

---Create a circle.
---@param config? tmath.CircleConfig
---@return tmath.Object
function Group:circle(config) end

---Create a rectangle.
---@param config? tmath.RectangleConfig
---@return tmath.Object
function Group:rectangle(config) end

---Create a polygon from at least three points.
---@param config? tmath.PolygonConfig
---@return tmath.Object
function Group:polygon(config) end

---Create a sampled function or polyline plot.
---@param config? tmath.PlotConfig
---@return tmath.Object
function Group:plot(config) end

---Create one directed polyline route whose dashed shaft and solid endpoint markers share one timeline state.
---@param config? tmath.RouteConfig
---@return tmath.Object
function Group:route(config) end

---Create a path from keyed contour commands.
---@param config? tmath.PathConfig
---@return tmath.Object
function Group:path(config) end

---Create a cubic Bézier curve.
---@param config? tmath.CurveConfig
---@return tmath.Object
function Group:curve(config) end

---Create a row-major 3D surface mesh.
---@param config? tmath.SurfaceConfig
---@return tmath.Object
function Group:surface(config) end

---Create a text object.
---@param config? tmath.TextConfig
---@return tmath.Object
function Group:text(config) end

---Create a measured ruler.
---@param config? tmath.RulerConfig
---@return tmath.Object
function Group:ruler(config) end

---Create an object from trusted SVG path data.
---@param config? tmath.SvgConfig
---@return tmath.Object
function Group:svg(config) end

---Create an image from an asset or inline pixels.
---@param config? tmath.ImageConfig
---@return tmath.Object
function Group:image(config) end

---Create a dense color cell grid.
---@param config? tmath.CellConfig
---@return tmath.Object
function Group:cell(config) end

---Create a connector between two object handles.
---@param config? tmath.ConnectorConfig
---@return tmath.Object
function Group:connector(config) end

---Create an ordinary child Text as this object's semantic label, using the complete Text configuration without automatic placement or color binding.
---@param config tmath.TextConfig
---@return tmath.Object
function Group:label(config) end

---Move this object to a parent-space point before animation begins.
---@param point tmath.Vec2|tmath.Vec3
function Group:move_to(point) end

---Place this object next to a sibling.
---@param other tmath.Object
---@param direction tmath.Vec2|tmath.Vec3
---@param gap? number
function Group:next_to(other, direction, gap) end

---Align this object to a sibling.
---@param other tmath.Object
---@param direction tmath.Vec2|tmath.Vec3
function Group:align_to(other, direction) end

---Arrange Group children in one direction.
---@param direction tmath.Vec2|tmath.Vec3
---@param gap? number
function Group:arrange(direction, gap) end

---Arrange Group children in a grid.
---@param columns integer
---@param columnGap? number
---@param rowGap? number
function Group:arrange_grid(columns, columnGap, rowGap) end

---@class tmath.Space: tmath.Object
local Space = {}

---Create a semantic object container.
---@param config? tmath.GroupConfig
---@return tmath.Group
function Space:group(config) end

---Create a 2D or 3D coordinate space.
---@param config? tmath.SpaceConfig
---@return tmath.Space
function Space:space(config) end

---Create a point marker.
---@param config? tmath.PointConfig
---@return tmath.Object
function Space:point(config) end

---Create a line segment.
---@param config? tmath.LineConfig
---@return tmath.Object
function Space:line(config) end

---Create an arrow between two points.
---@param config? tmath.ArrowConfig
---@return tmath.Object
function Space:arrow(config) end

---Create a vector from an origin and value.
---@param config? tmath.VectorConfig
---@return tmath.Object
function Space:vector(config) end

---Create a circle.
---@param config? tmath.CircleConfig
---@return tmath.Object
function Space:circle(config) end

---Create a rectangle.
---@param config? tmath.RectangleConfig
---@return tmath.Object
function Space:rectangle(config) end

---Create a polygon from at least three points.
---@param config? tmath.PolygonConfig
---@return tmath.Object
function Space:polygon(config) end

---Create a sampled function or polyline plot.
---@param config? tmath.PlotConfig
---@return tmath.Object
function Space:plot(config) end

---Create one directed polyline route whose dashed shaft and solid endpoint markers share one timeline state.
---@param config? tmath.RouteConfig
---@return tmath.Object
function Space:route(config) end

---Create a path from keyed contour commands.
---@param config? tmath.PathConfig
---@return tmath.Object
function Space:path(config) end

---Create a cubic Bézier curve.
---@param config? tmath.CurveConfig
---@return tmath.Object
function Space:curve(config) end

---Create a row-major 3D surface mesh.
---@param config? tmath.SurfaceConfig
---@return tmath.Object
function Space:surface(config) end

---Create a text object.
---@param config? tmath.TextConfig
---@return tmath.Object
function Space:text(config) end

---Create a measured ruler.
---@param config? tmath.RulerConfig
---@return tmath.Object
function Space:ruler(config) end

---Create an object from trusted SVG path data.
---@param config? tmath.SvgConfig
---@return tmath.Object
function Space:svg(config) end

---Create an image from an asset or inline pixels.
---@param config? tmath.ImageConfig
---@return tmath.Object
function Space:image(config) end

---Create a connector between two object handles.
---@param config? tmath.ConnectorConfig
---@return tmath.Object
function Space:connector(config) end

---Create an ordinary child Text as this object's semantic label, using the complete Text configuration without automatic placement or color binding.
---@param config tmath.TextConfig
---@return tmath.Object
function Space:label(config) end

---Move this object to a parent-space point before animation begins.
---@param point tmath.Vec2|tmath.Vec3
function Space:move_to(point) end

---Place this object next to a sibling.
---@param other tmath.Object
---@param direction tmath.Vec2|tmath.Vec3
---@param gap? number
function Space:next_to(other, direction, gap) end

---Align this object to a sibling.
---@param other tmath.Object
---@param direction tmath.Vec2|tmath.Vec3
function Space:align_to(other, direction) end

---Arrange Group children in one direction.
---@param direction tmath.Vec2|tmath.Vec3
---@param gap? number
function Space:arrange(direction, gap) end

---Arrange Group children in a grid.
---@param columns integer
---@param columnGap? number
---@param rowGap? number
function Space:arrange_grid(columns, columnGap, rowGap) end

---Sample a deterministic 2D color field.
---@param sample fun(x:number, y:number, time:number):tmath.Color
---@param config? tmath.SampleConfig
---@return tmath.Object
function Space:cell(sample, config) end

---Sample a deterministic 3D color field.
---@param sample fun(x:number, y:number, z:number, time:number):tmath.Color
---@param config? tmath.SampleConfig
---@return tmath.Object
function Space:voxel(sample, config) end

---@class tmath.StyleGroup
local StyleGroup = {}

---@class tmath.Scene
local Scene = {}

---Create a semantic object container.
---@param config? tmath.GroupConfig
---@return tmath.Group
function Scene:group(config) end

---Create a 2D or 3D coordinate space.
---@param config? tmath.SpaceConfig
---@return tmath.Space
function Scene:space(config) end

---Create a point marker.
---@param config? tmath.PointConfig
---@return tmath.Object
function Scene:point(config) end

---Create a line segment.
---@param config? tmath.LineConfig
---@return tmath.Object
function Scene:line(config) end

---Create an arrow between two points.
---@param config? tmath.ArrowConfig
---@return tmath.Object
function Scene:arrow(config) end

---Create a vector from an origin and value.
---@param config? tmath.VectorConfig
---@return tmath.Object
function Scene:vector(config) end

---Create a circle.
---@param config? tmath.CircleConfig
---@return tmath.Object
function Scene:circle(config) end

---Create a rectangle.
---@param config? tmath.RectangleConfig
---@return tmath.Object
function Scene:rectangle(config) end

---Create a polygon from at least three points.
---@param config? tmath.PolygonConfig
---@return tmath.Object
function Scene:polygon(config) end

---Create a sampled function or polyline plot.
---@param config? tmath.PlotConfig
---@return tmath.Object
function Scene:plot(config) end

---Create one directed polyline route whose dashed shaft and solid endpoint markers share one timeline state.
---@param config? tmath.RouteConfig
---@return tmath.Object
function Scene:route(config) end

---Create a path from keyed contour commands.
---@param config? tmath.PathConfig
---@return tmath.Object
function Scene:path(config) end

---Create a cubic Bézier curve.
---@param config? tmath.CurveConfig
---@return tmath.Object
function Scene:curve(config) end

---Create a row-major 3D surface mesh.
---@param config? tmath.SurfaceConfig
---@return tmath.Object
function Scene:surface(config) end

---Create a text object.
---@param config? tmath.TextConfig
---@return tmath.Object
function Scene:text(config) end

---Create a measured ruler.
---@param config? tmath.RulerConfig
---@return tmath.Object
function Scene:ruler(config) end

---Create an object from trusted SVG path data.
---@param config? tmath.SvgConfig
---@return tmath.Object
function Scene:svg(config) end

---Create an image from an asset or inline pixels.
---@param config? tmath.ImageConfig
---@return tmath.Object
function Scene:image(config) end

---Create a dense color cell grid.
---@param config? tmath.CellConfig
---@return tmath.Object
function Scene:cell(config) end

---Create a connector between two object handles.
---@param config? tmath.ConnectorConfig
---@return tmath.Object
function Scene:connector(config) end

---Mount a completed child scene into a normalized viewport.
---@param scene tmath.Scene
---@param viewport tmath.ViewportConfig
function Scene:viewport(scene, viewport) end

---Sequence complete child scenes in one viewport.
---@param scenes tmath.Scene[]
---@param config tmath.SceneTransitionConfig
function Scene:scene_transition(scenes, config) end

---Create a Scene-owned semantic color identity from explicit object paint channels, optionally inferred from the first member.
---@param config tmath.StyleGroupConfig
---@return tmath.StyleGroup
function Scene:style_group(config) end

---Add a clip-free live object channel to an existing StyleGroup.
---@param group tmath.StyleGroup
---@param target tmath.Object
---@param channel? "stroke"|"fill"|"both"
function Scene:style_bind(group, target, channel) end

---Animate every live member of a StyleGroup to one shared color in a single timeline operation.
---@param group tmath.StyleGroup
---@param color tmath.Color|tmath.ThemeColor
---@param duration? number
---@param curve? tmath.Curve
function Scene:style(group, color, duration, curve) end

---Animate one descriptor or an array of descriptors.
---@param animations tmath.Animation|tmath.Animation[]
---@param duration? number
---@param curve? tmath.Curve
---@param lag? number
function Scene:play(animations, duration, curve, lag) end

---Reveal targets by drawing their geometry.
---@param target tmath.Object|tmath.Object[]
---@param duration? number
---@param curve? tmath.Curve
---@param lag? number
---@param direction? tmath.CreateDirection
function Scene:create(target, duration, curve, lag, direction) end

---Hide targets by reversing their drawn geometry.
---@param target tmath.Object|tmath.Object[]
---@param duration? number
---@param curve? tmath.Curve
---@param lag? number
---@param direction? tmath.CreateDirection
function Scene:uncreate(target, duration, curve, lag, direction) end

---Reveal target fills.
---@param target tmath.Object|tmath.Object[]
---@param duration? number
---@param curve? tmath.Curve
---@param lag? number
function Scene:fill_reveal(target, duration, curve, lag) end

---Draw target borders and then reveal their fills.
---@param target tmath.Object|tmath.Object[]
---@param duration? number
---@param curve? tmath.Curve
---@param lag? number
---@param direction? tmath.CreateDirection
function Scene:draw_border_then_fill(target, duration, curve, lag, direction) end

---Reveal text or drawable targets in writing order.
---@param target tmath.Object|tmath.Object[]
---@param duration? number
---@param curve? tmath.Curve
---@param lag? number
---@param direction? tmath.CreateDirection
function Scene:write(target, duration, curve, lag, direction) end

---Animate targets by a parent-space vector.
---@param target tmath.Object
---@param vector tmath.Vec2|tmath.Vec3
---@param duration? number
---@param curve? tmath.Curve
function Scene:shift(target, vector, duration, curve) end

---Animate a target to an absolute local-to-parent matrix.
---@param target tmath.Object
---@param matrix tmath.Mat4
---@param duration? number
---@param curve? tmath.Curve
function Scene:transform(target, matrix, duration, curve) end

---Animate target opacity.
---@param target tmath.Object
---@param opacity number
---@param duration? number
---@param curve? tmath.Curve
function Scene:fade(target, opacity, duration, curve) end

---Fade a target in with optional shift and scale effects.
---@param target tmath.Object
---@param options? tmath.FadeConfig
function Scene:fade_in(target, options) end

---Fade a target out with optional shift and scale effects.
---@param target tmath.Object
---@param options? tmath.FadeConfig
function Scene:fade_out(target, options) end

---Reveal a target by growing it from its center.
---@param target tmath.Object
---@param duration? number
---@param curve? tmath.Curve
function Scene:grow_from_center(target, duration, curve) end

---Reveal a target by growing one dimension from a fixed geometry-bounds edge.
---@param target tmath.Object
---@param edge "left"|"right"|"bottom"|"top"
---@param duration? number
---@param curve? tmath.Curve
function Scene:grow_from_edge(target, edge, duration, curve) end

---Hide a target by shrinking it to its center.
---@param target tmath.Object
---@param duration? number
---@param curve? tmath.Curve
function Scene:shrink_to_center(target, duration, curve) end

---Briefly emphasize a target.
---@param target tmath.Object
---@param options? tmath.IndicateConfig
function Scene:indicate(target, options) end

---Morph source geometry into target geometry.
---@param source tmath.Object|tmath.Object[]
---@param target tmath.Object|tmath.Object[]
---@param duration? number
---@param curve? tmath.Curve
---@param lag? number
function Scene:morph(source, target, duration, curve, lag) end

---Morph source to target and transfer visual identity.
---@param source tmath.Object|tmath.Object[]
---@param target tmath.Object|tmath.Object[]
---@param duration? number
---@param curve? tmath.Curve
---@param lag? number
function Scene:replacement_transform(source, target, duration, curve, lag) end

---Cross-fade unrelated object families as one replacement.
---@param source tmath.Object
---@param target tmath.Object
---@param duration? number
---@param curve? tmath.Curve
function Scene:fade_transform(source, target, duration, curve) end

---Cross-fade independent outgoing and incoming targets.
---@param outgoing tmath.Object
---@param incoming tmath.Object
---@param duration? number
---@param curve? tmath.Curve
function Scene:transition(outgoing, incoming, duration, curve) end

---Animate a target stroke to a literal or semantic Theme color.
---@param target tmath.Object
---@param color tmath.Color|tmath.ThemeColor
---@param duration? number
---@param curve? tmath.Curve
function Scene:stroke(target, color, duration, curve) end

---Animate a target fill to a literal or semantic Theme color.
---@param target tmath.Object
---@param color tmath.Color|tmath.ThemeColor
---@param duration? number
---@param curve? tmath.Curve
function Scene:fill(target, color, duration, curve) end

---Animate the scene camera.
---@param camera tmath.CameraConfig
---@param duration? number
---@param curve? tmath.Curve
function Scene:look(camera, duration, curve) end

---Advance the timeline cursor.
---@param duration number
function Scene:wait(duration) end

---Remove a target at the current timeline cursor.
---@param target tmath.Object
function Scene:remove(target) end

---Return the authored scene duration in seconds.
---@return number
function Scene:duration() end

---Experimental Scene-owned interaction panel; available only with optional UI support.
---@class tmath.Panel
local Panel = {}

---Experimental: add a pointer button bound to exactly one camera action or target transform. Optional authored hover and pressed visuals are selected without mutating Scene objects; the last clicked Button transform wins for a shared target. The Panel-wide 256-control limit applies.
---@param config tmath.PanelButtonConfig
---@return tmath.Panel
function Panel:button(config) end

---Experimental: add a pointer button that retains one binary state and smoothly alternates a target between explicit off and on transforms after each completed click.
---@param config tmath.PanelToggleButtonConfig
---@return tmath.Panel
function Panel:toggle_button(config) end

---Experimental: add a clamped horizontal or vertical control that interpolates either one target transform or a bounded list of synchronized target transforms.
---@param config tmath.PanelSliderConfig
---@return tmath.Panel
function Panel:slider(config) end

---Experimental: add a click-only 2D sampler. A completed primary click evaluates the configured candidates in the currently composed Scene at the active render density, selects the topmost configured candidate whose isolated family composite has nonzero raster alpha under the Scene AA policy, then commits the optional marker and swatch bindings. Sampling has no Lua callback and does not run on hover or drag.
---@param config tmath.PanelSampleAreaConfig
---@return tmath.Panel
function Panel:sample_area(config) end

---Experimental: add a persistent camera pan delta without mutating the authored camera timeline.
---@param delta tmath.Vec2
---@return tmath.Panel
function Panel:camera_move(delta) end

---Experimental: add a persistent 3D camera orbit delta without mutating the authored camera timeline.
---@param delta tmath.Vec2
---@return tmath.Panel
function Panel:camera_orbit(delta) end

---Experimental: add a persistent camera zoom delta without mutating the authored camera timeline.
---@param delta number
---@return tmath.Panel
function Panel:camera_zoom(delta) end

---Experimental: clear persistent Panel camera deltas and its view override.
---@return tmath.Panel
function Panel:camera_reset() end

---Experimental: override the sampled camera with a 2D or 3D view until Panel camera reset.
---@param view "2d"|"3d"
---@return tmath.Panel
function Panel:camera_view(view) end

---Experimental semantic diagram builder; available only with optional Diagram support.
---@class tmath.Diagram
local Diagram = {}

---Add a semantic node and return its builder-owned handle.
---@param config tmath.DiagramNodeConfig
---@return tmath.DiagramNode
function Diagram:node(config) end

---Add a routed edge between two nodes and return its builder-owned handle.
---@param config tmath.DiagramEdgeConfig
---@return tmath.DiagramEdge
function Diagram:connect(config) end

---Add a labeled zone around one or more nodes.
---@param config tmath.DiagramZoneConfig
---@return tmath.DiagramZone
function Diagram:zone(config) end

---Resolve layout and attach one ordinary Object subtree to the Scene.
---@return tmath.DiagramBuilt
function Diagram:build() end

---Opaque node handle owned by one Diagram builder.
---@class tmath.DiagramNode
local DiagramNode = {}

---Opaque edge handle owned by one Diagram builder.
---@class tmath.DiagramEdge
local DiagramEdge = {}

---Opaque zone handle owned by one Diagram builder.
---@class tmath.DiagramZone
local DiagramZone = {}

---Built Diagram object tree and its stable semantic lookups.
---@class tmath.DiagramBuilt
local DiagramBuilt = {}

---Return the complete generated Diagram subtree.
---@return tmath.Group
function DiagramBuilt:root() end

---Return the generated zone layer.
---@return tmath.Group
function DiagramBuilt:zones() end

---Return the generated edge-route layer.
---@return tmath.Group
function DiagramBuilt:routes() end

---Return the generated node layer.
---@return tmath.Group
function DiagramBuilt:nodes() end

---Return the generated annotation layer.
---@return tmath.Group
function DiagramBuilt:annotations() end

---Return the generated node group; its text remains in the annotation layer.
---@param node tmath.DiagramNode
---@return tmath.Object
function DiagramBuilt:node(node) end

---Return the generated body object for a node.
---@param node tmath.DiagramNode
---@return tmath.Object
function DiagramBuilt:node_body(node) end

---Return the generated label object for a node.
---@param node tmath.DiagramNode
---@return tmath.Object
function DiagramBuilt:node_label(node) end

---Return the optional generated detail object for a node.
---@param node tmath.DiagramNode
---@return tmath.Object|nil
function DiagramBuilt:node_detail(node) end

---Return the complete generated route object for an edge.
---@param edge tmath.DiagramEdge
---@return tmath.Object
function DiagramBuilt:edge(edge) end

---Return the optional generated label object for an edge.
---@param edge tmath.DiagramEdge
---@return tmath.Object|nil
function DiagramBuilt:edge_label(edge) end

---Return the generated zone group; its text remains in the annotation layer.
---@param zone tmath.DiagramZone
---@return tmath.Object
function DiagramBuilt:zone(zone) end

---Return the generated body object for a zone.
---@param zone tmath.DiagramZone
---@return tmath.Object
function DiagramBuilt:zone_body(zone) end

---Return the generated label object for a zone.
---@param zone tmath.DiagramZone
---@return tmath.Object
function DiagramBuilt:zone_label(zone) end

---Experimental quantitative chart builder; available only with optional Chart support.
---@class tmath.Chart
local Chart = {}

---Add a line or bar series and return its builder-owned handle.
---@param config tmath.ChartSeriesConfig
---@return tmath.ChartSeries
function Chart:series(config) end

---Resolve the chart and attach one ordinary Object subtree to the Scene.
---@return tmath.ChartBuilt
function Chart:build() end

---Opaque series handle owned by one Chart builder.
---@class tmath.ChartSeries
local ChartSeries = {}

---Built Chart object tree and its stable semantic lookups.
---@class tmath.ChartBuilt
local ChartBuilt = {}

---Return the complete generated Chart subtree.
---@return tmath.Group
function ChartBuilt:root() end

---Return the generated axes layer.
---@return tmath.Group
function ChartBuilt:axes() end

---Return the generated grid layer.
---@return tmath.Group
function ChartBuilt:grid() end

---Return the generated labels layer.
---@return tmath.Group
function ChartBuilt:labels() end

---Return the complete generated object for a series.
---@param series tmath.ChartSeries
---@return tmath.Object
function ChartBuilt:series(series) end

---Return the generated mark count for a series.
---@param series tmath.ChartSeries
---@return integer
function ChartBuilt:mark_count(series) end

---Return a generated one-based mark from a series.
---@param series tmath.ChartSeries
---@param index integer
---@return tmath.Object
function ChartBuilt:mark(series, index) end

---Return the optional generated legend label for a series.
---@param series tmath.ChartSeries
---@return tmath.Object|nil
function ChartBuilt:legend(series) end

---Return the generated horizontal tick-label count.
---@return integer
function ChartBuilt:x_tick_count() end

---Return a generated one-based horizontal tick label.
---@param index integer
---@return tmath.Object
function ChartBuilt:x_tick(index) end

---Return the generated vertical tick-label count.
---@return integer
function ChartBuilt:y_tick_count() end

---Return a generated one-based vertical tick label.
---@param index integer
---@return tmath.Object
function ChartBuilt:y_tick(index) end

---Scene-owned input binding controller; available only with optional Input support.
---@class tmath.InputController
local InputController = {}

---Bind passive pointer motion in one logical-pixel region to an exact parent-space target map, optionally rotating the target toward the newest pointer sample.
---@param config tmath.InputPointerFollowConfig
---@return tmath.InputController
function InputController:pointer_follow(config) end

---Bind one supported key as retained Down state that moves continuously until keyup and ignores platform repeat.
---@param config tmath.InputKeyMoveConfig
---@return tmath.InputController
function InputController:key_move(config) end

---Experimental retained Lua fixed-step context; available only with optional Lua Runtime support.
---@class tmath.Runtime
local Runtime = {}

---Bind one logical key contribution to a named fixed-step action during authoring.
---@param action string
---@param key string
---@param value? tmath.Vec2
---@return tmath.Runtime
function Runtime:bind_key(action, key, value) end

---Bind one pointer button contribution to a named fixed-step action during authoring.
---@param action string
---@param button integer
---@param value? tmath.Vec2
---@param pointer? integer
---@return tmath.Runtime
function Runtime:bind_pointer(action, button, value, pointer) end

---Read a named Input action inside the fixed-step callback; transient edges are visible only in the first catch-up step.
---@param action string
---@return tmath.RuntimeActionState
function Runtime:action(action) end

---Read one logical key snapshot inside the fixed-step callback.
---@param key string
---@return tmath.RuntimeKeyState
function Runtime:key(key) end

---Read one logical-pixel pointer snapshot inside the fixed-step callback, or nil before that pointer is observed.
---@param pointer? integer
---@return tmath.RuntimePointerState|nil
function Runtime:pointer(pointer) end

---Queue one bounded data-only sound event inside the fixed-step callback; return false when the 64-event host-advance queue is full.
---@param asset string
---@param options? tmath.RuntimeSoundConfig
---@return boolean
function Runtime:sound(asset, options) end

---Atomically stage one bounded render-time Object overlay inside the fixed-step callback.
---@param object tmath.Object
---@param state tmath.RuntimeObjectState
---@return tmath.Runtime
function Runtime:update(object, state) end

---Atomically clear one Object overlay, or every runtime overlay when object is omitted, inside the fixed-step callback.
---@param object? tmath.Object
---@return tmath.Runtime
function Runtime:clear(object) end

---Experimental interactive UI module. It is available only when tmath is built with optional UI support; one Panel is limited to 256 controls and bindings.
---@class tmath.UI
local UI = {}

---Create the single experimental, Scene-owned UI Panel that composes interaction after timeline sampling.
---@param scene tmath.Scene
---@return tmath.Panel
function UI.panel(scene) end

---Experimental keyboard, pointer, and camera Input module. It is optional and independent from UI; one Controller is limited to 256 bindings.
---@class tmath.Input
local Input = {}

---Create the single Scene-owned Input Controller that composes pointer and keyboard state after timeline sampling.
---@param scene tmath.Scene
---@return tmath.InputController
function Input.controller(scene) end

---@class tmath.Library
---@field ui? tmath.UI Experimental interactive UI module. It is available only when tmath is built with optional UI support; one Panel is limited to 256 controls and bindings.
---@field input? tmath.Input Experimental keyboard, pointer, and camera Input module. It is optional and independent from UI; one Controller is limited to 256 bindings.
local Library = {}

---Create a tmath scene.
---@param config? tmath.SceneConfig
---@return tmath.Scene
function Library.scene(config) end

---Create an experimental semantic Diagram builder for a Scene. Available only when the optional Diagram module is enabled.
---@param scene tmath.Scene
---@param config tmath.DiagramConfig
---@return tmath.Diagram
function Library.diagram(scene, config) end

---Create an experimental quantitative Chart builder for a Scene. Available only when the optional Chart module is enabled.
---@param scene tmath.Scene
---@param config tmath.ChartConfig
---@return tmath.Chart
function Library.chart(scene, config) end

---Create the optional experimental retained Lua fixed-step runtime for one Scene.
---@param scene tmath.Scene
---@param config tmath.RuntimeConfig
---@return tmath.Runtime
function Library.runtime(scene, config) end

---@type tmath.Library
tmath = {}
