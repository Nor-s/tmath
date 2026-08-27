# Scene themes

A `Theme` defines the default visual language of one Scene: its background, five text roles, an object-color cycle, semantic colors, object stroke width, optional gradients, and Space axis colors. Themes are Scene-scoped. Every child mounted in a Viewport keeps its own Theme and its own object-color cursor.

Set the Theme before creating any Object, mounting a Viewport, or scheduling a timeline command. A successful assignment copies the complete Theme, including font names, into the Scene.

## Built-in presets

`ProWhite` is the default Theme. `ThreeBlueOneEyes` preserves the original dark, colorful lesson palette under the canonical Lua/JavaScript token `"3_blue_1_eyes"`. `ProWhite` and `ProBlack` are restrained professional presets for papers, lecture material, and LaTeX-oriented figures with light and dark polarity respectively.

| Token | 3 Blue 1 Eyes | Pro White (default) | Pro Black |
|---|---|---|---|
| Background | `#0d1117` | `#ffffff` | `#000000` |
| H1 / H2 | `#f4f7fb` | `#202124` | `#ffffff` |
| H3 | `#dbe7f3` | `#3c4043` | `#e8eaed` |
| Text | `#dbe7f3` | `#555b64` | `#d8dadd` |
| Code | `#ffd166` | `#9b3600` | `#f6c49f` |
| Object cycle | `#f28e2b`, `#ff6b6b`, `#76b7b2`, `#7bc96f`, `#c29bc0`, `#ff9da7`, `#c49a83`, `#bab0ac` | `#b45f06`, `#b63a3c`, `#2e7f7a`, `#3f7d35`, `#815681`, `#b95668`, `#76503d`, `#62666a` | `#f28e2b`, `#ff6b6b`, `#76b7b2`, `#7bc96f`, `#c29bc0`, `#ff9da7`, `#c49a83`, `#bab0ac` |
| Object stroke width | `2.0` | `1.25` | `1.25` |
| X / Y / Z axes | red / green / blue | `#d8dadd` | `#d8dadd` |
| Grid | blue-gray | `#d8dadd` | `#d8dadd` |
| Gradient enabled | `false` | `false` | `false` |
| End gradient stop | `#f72585` | `#666666` | `#999999` |

All presets use Pretendard. H1, H2, H3, Text, and Code have independent sizes and colors. Register every selected font with the renderer before rendering text. Each preset has eight opaque cyclic object colors for peer inputs and categories; shapes that already carry a fill, such as Point and solid Surface, therefore receive the same solid color without a translucent Theme fill.

Lua and JavaScript use the canonical names `"3_blue_1_eyes"`, `"pro_white"`, `"pro_black"`, and `"adaptive_vscode"`. C++ uses `ThemePreset::ThreeBlueOneEyes`, `ThemePreset::ProWhite`, `ThemePreset::ProBlack`, and `ThemePreset::AdaptiveVscode`. The former `"pro"` and `ThemePreset::Pro` spellings remain compatibility aliases for Pro White; the former `"default"` and `ThemePreset::Default` names are removed.

`adaptive_vscode` is a host-resolved preset rather than a fixed palette. The tmath VS Code Preview supplies the active editor background, foreground, description, link, status, surface, border, focus, and chart colors before loading Lua, and rebuilds only adaptive Scenes when the workbench theme changes. Its object cycle uses the host chart categories, `result` uses the host yellow chart role, and `focus` uses the host focus border. This keeps the distinction semantic without requiring result and focus to look identical across light and dark editors. Explicit Scene and Object style fields still win. Hosts that do not supply a palette, including direct `Theme::preset(ThemePreset::AdaptiveVscode)` calls, receive Pro White.

## Semantic colors

Themes expose reusable meaning rather than forcing each object to repeat a literal color. Lua and JavaScript style fields, Space axis fields, Cell colors, gradient end stops, color animation targets, and `indicate` options accept these names:

| Role | Intended use |
|---|---|
| `background` | Scene canvas background |
| `foreground` | Primary marks and high-emphasis content |
| `muted` | Secondary labels and de-emphasized structure |
| `accent` | Primary accent or emphasis that is not a returned result or transient focus |
| `secondary` | A second emphasis channel |
| `success` | Valid, completed, or accepted state |
| `warning` | Caution or recoverable problem |
| `danger` | Error, invalid, or destructive state |
| `info` | Informational state |
| `surface` | Raised panel or grouped region |
| `border` | Boundaries, dividers, and panel outlines |
| `result` | A returned value, derived mathematical result, or output data structure |
| `focus` | The current subject or temporarily important object or region |

Use roles only for their meaning. `lhs` and `rhs` conventionally name the first two operand slots; every later operand belongs to `args...`. These are positional authoring names, not Theme color roles. Omit their explicit colors so `lhs`, `rhs`, and each `args...` member consume one shared automatic `objects` cycle in order, without resetting or switching palettes after `rhs`. A result keeps `result` even while attention moves elsewhere; `focus` is transient salience and must not redefine that identity. `scene:indicate(target)` uses `focus` by default and restores the incoming color afterward.

## Resolution rules

- An explicit object `stroke`, `fill`, or `color` always wins and does not advance the palette cursor.
- A semantic color name is resolved from the Scene Theme when Lua is loaded. Rebuilding an `adaptive_vscode` Scene after a host-theme change resolves the same roles against the new palette.
- An object omitting `width` receives `object_width`. An explicit object width wins.
- With Theme `gradient` enabled, an eligible shape blends its resolved object color toward `end_gradient_stop`. Open shapes use a stroke gradient; closed filled shapes use a fill gradient.
- An explicit shape `gradient=false`, `gradient=true`, or `gradient=<color>` wins over the Theme. A color enables the gradient and replaces its end stop; `true` uses the Theme end stop.
- An eligible shape with no explicit color receives the next object color when it joins the Scene. The cursor wraps after the configured color count.
- `result` and `focus` never consume or advance the automatic object cycle.
- Group, Text, Space, Svg, Image, and Cell do not consume object colors and do not receive gradients. A Group's eligible descendants consume colors in depth-first attachment order.
- Text omitting `font`, `size`, or color receives those fields independently from its `role`. Explicit text fields remain unchanged.
- A Space receives themed X/Y/Z axes, grid, and number-label colors for fields left at their constructor defaults.
- An automatically themed morph or Scene-transition target inherits the source object's color and gradient. An explicitly styled target retains its authored paint.
- The Lua/JavaScript top-level `background` field is an explicit override applied after `theme`.

There is no global palette state. Two Scenes using the same preset both start at object color 1, including two Scenes later mounted in separate Viewports.

## C++

```cpp
auto scene = tmath::Scene::gen();
auto theme = tmath::Theme::preset(tmath::ThemePreset::ProWhite);
theme.objects[0] = tmath::Color::hex("#164e63");
theme.objects[1] = tmath::Color::hex("#c2410c");
theme.objectCount = 2;
theme.objectWidth = 1.5f;
theme.gradient = true;
theme.endGradientStop = tmath::Color::hex("#7c3aed");
theme.colors.result = tmath::Color::hex("#a16207");
theme.colors.focus = tmath::Color::hex("#2563eb");
theme.colors.danger = tmath::Color::hex("#dc2626");

if (scene->theme(theme) != tmath::Result::Success) {
    delete scene;
    return;
}
```

`Theme::ColorLimit` is 10. `objectCount` must be between 1 and 10, `objectWidth` and every text size must be positive and finite, and every font name must be non-empty. `Theme::color(ThemeColorRole)` resolves the same semantic roles for C++ authors. `Scene::theme()` returns the Scene's copied Theme. `Object::strokeWidth()` marks a C++ object's width as explicit; `Object::gradient(bool)` explicitly enables or disables the effect and `Object::gradient(Color)` enables it with an explicit end stop. Directly authored non-default `style.gradient`/`style.gradientEnd` fields are also preserved at attachment.

## Lua and JavaScript

Use a preset name for the complete built-in Theme:

```lua
local scene = tmath.scene {
    theme = "pro_white",
    camera = {view="2d", height=8}
}
scene:text {text="A professional figure", role="h1"}
```

A custom Theme starts from Pro White unless `preset` selects another base. All sections are partial overrides except `objects`, which replaces the complete cycle:

```lua
local scene = tmath.scene {
    theme = {
        preset = "3_blue_1_eyes",
        background = "#171225",
        text = {
            h1 = {font="Pretendard", size=38, color="#f7f2ff"},
            text = {font="Pretendard", size=17, color="#d8cff0"},
            code = {font="Pretendard", size=15, color="#fbbf24"}
        },
        objects = {"#8b5cf6", "#22d3ee", "#f472b6", "#fbbf24"},
        colors = {
            accent = "#8b5cf6", secondary = "#22d3ee",
            success = "#16a34a", warning = "#ca8a04", danger = "#dc2626",
            info = "#0284c7", surface = "#211a35", border = "#493f63",
            result = "#facc15", focus = "#60a5fa"
        },
        object_width = 3,
        gradient = true,
        end_gradient_stop = "#fb7185",
        axis = {
            x="#f472b6", y="#34d399", z="#60a5fa",
            grid="#493f63", label="#bdb4d7"
        }
    }
}

local subject = scene:circle {center={0, 0}, radius=1}
local result = scene:text {text="42", point={0, -1.5}, fill="result"}
scene:indicate(subject) -- Theme focus; the subject's cyclic identity is restored afterward
```

JavaScript uses the same shape through `SceneConfig.theme`; `TextOptions.role` accepts `"h1"`, `"h2"`, `"h3"`, `"text"`, or `"code"`.

Every gradient is linear. Open paths run from their first to last point; closed shapes use their local bounding-box diagonal. The end stop contributes RGB while the resolved stroke/fill opacity remains unchanged. Gradient paint is exported to Lottie as `gs` (stroke) or `gf` (fill).
