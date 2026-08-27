# Conic rasterizer article examples

The `Conic` browser category and `examples/lua` contain a nine-scene tmath port of every
`Scene` in the reference `conic_manim.py`. All scenes use a fixed 960×540 camera, the
repository-pinned Pretendard font, and `loop = false` by default.

| Manim scene | Browser example ID | Standalone Lua |
|---|---|---|
| `CoordinatePullback` | `conic-coordinate-pullback` | `conic_coordinate_pullback.lua` |
| `PreparedGeometry` | `conic-prepared-geometry` | `conic_prepared_geometry.lua` |
| `ScanlineRange` | `conic-scanline-range` | `conic_scanline_range.lua` |
| `SeamReconstruction` | `conic-seam-reconstruction` | `conic_seam_reconstruction.lua` |
| `SurfaceToGradient` | `conic-surface-to-gradient` | `conic_surface_to_gradient.lua` |
| `AngularParameterization` | `conic-angular-parameterization` | `conic_angular_parameterization.lua` |
| `ScanlineRecurrence` | `conic-scanline-recurrence` | `conic_scanline_recurrence.lua` |
| `AngularMarginVsFootprintAA` | `conic-angular-margin-aa` | `conic_angular_margin_aa.lua` |
| `ConicFwidthIntuition` | `conic-fwidth-intuition` | `conic_fwidth_intuition.lua` |

## Porting conventions

- Manim `TransformFromCopy` is represented by a newly created copy followed by
  `replacement_transform` / `replacementTransform`. The visible source stays in place.
- Manim `MathTex` is represented with color-matched Text and geometric tokens because the
  renderer does not provide glyph-outline correspondence for arbitrary font morphing.
- Dashed construction guides are reduced to restrained solid guides where a native dashed
  primitive is unavailable; the geometric relationship and animation timing remain intact.
- `Create`, lagged groups, fades, shifts, transforms, and copy morphs keep the original
  explanatory order while using tmath's deterministic timeline.
