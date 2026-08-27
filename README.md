# tmath

![tmath quickstart cheatsheet](docs/assets/tmath-quickstart-cheatsheet.gif)

## Usage

Build and test:

```sh
meson setup build
meson compile -C build
meson test -C build --print-errorlogs
```

Create `scene.lua`:

```lua
local scene = tmath.scene {
    width = 960,
    height = 540,
    theme = "pro_white",
    camera = {mode = "fixed", view = "2d", height = 6},
}

local circle = scene:circle {
    id = "subject",
    center = {-2, 0},
    radius = 0.8,
    fill = "accent",
    stroke = "accent",
}

scene:shift(circle, {4, 0}, 1.2, "ease_in_out")
scene:wait(0.4)

return scene
```

Inspect and render:

```sh
build/tmath inspect scene.lua
build/tmath render scene.lua --time 0.6 -o frame.png
build/tmath render scene.lua --fps 30 -o scene.mp4
build/tmath render scene.lua --fps 20 -o scene.gif
```

## References

- [Authoring skill](skills/tmath-skills/SKILL.md) · [Lua API](skills/tmath-skills/references/lua.md) · [JavaScript/TypeScript API](skills/tmath-skills/references/javascript.md)
- [Themes](docs/themes.md) · [Scene composition](docs/scene-composition.md) · [Cells and voxels](docs/cell-voxel.md) · [Audio](docs/audio.md)
- [Lua examples](examples/lua) · [VS Code extension](vscode/README.md) · [Architecture](docs/architecture.md)
- [ThorVG](https://github.com/thorvg/thorvg) · [Manim Community](https://github.com/ManimCommunity/manim) · [ManimGL](https://github.com/3b1b/manim)
- [diagram-design](https://github.com/cathrynlavery/diagram-design) · [manim_skill](https://github.com/adithya-s-k/manim_skill) · [Hermes Agent manim-video](https://github.com/NousResearch/hermes-agent/tree/main/skills/creative/manim-video)
- [MIT License](LICENSE)
