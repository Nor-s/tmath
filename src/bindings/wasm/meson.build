# Emscripten runtime. The executable is declared in the root meson.build as
# `tmath_wasm` so tmath-wasm.js and its copied companions stay in the build root.
wasm_exports = [
    'malloc', 'free', 'tmath_create', 'tmath_create_with_engine',
    'tmath_default_render_engine_set', 'tmath_default_render_engine',
    'tmath_render_engine_enabled', 'tmath_render_engine', 'tmath_destroy',
    'tmath_host_theme', 'tmath_adaptive_theme', 'tmath_load_lua', 'tmath_load_font',
    'tmath_load_asset', 'tmath_render', 'tmath_render_scaled', 'tmath_render_gl',
    'tmath_bounds', 'tmath_intersects', 'tmath_layout_report', 'tmath_layout_report_data',
    'tmath_layout_report_size', 'tmath_resize', 'tmath_camera_mode', 'tmath_camera_view',
    'tmath_pixels', 'tmath_pixels_size', 'tmath_width', 'tmath_height', 'tmath_duration',
    'tmath_loop', 'tmath_last_error',
]
if ui_enabled or input_enabled
    wasm_exports += ['tmath_camera', 'tmath_input']
endif
if ui_enabled
    wasm_exports += [
        'tmath_ui_input', 'tmath_ui_sample_handle', 'tmath_ui_sample_tag', 'tmath_ui_sample_type',
        'tmath_ui_sample_x', 'tmath_ui_sample_y', 'tmath_ui_sample_u', 'tmath_ui_sample_v',
        'tmath_ui_sample_rgba',
    ]
endif
if input_enabled
    wasm_exports += [
        'tmath_input_begin', 'tmath_input_release',
        'tmath_input_key_state', 'tmath_input_key_begin', 'tmath_input_key_end',
        'tmath_input_pointer_state', 'tmath_input_pointer_x',
        'tmath_input_pointer_y', 'tmath_input_pointer_dx', 'tmath_input_pointer_dy',
        'tmath_input_pointer_wheel_x', 'tmath_input_pointer_wheel_y',
        'tmath_input_pointer_previous_buttons', 'tmath_input_pointer_buttons',
        'tmath_input_pointer_pressed', 'tmath_input_pointer_released',
    ]
endif
if lua_runtime_enabled
    wasm_exports += [
        'tmath_runtime_active', 'tmath_runtime_advance', 'tmath_runtime_time',
        'tmath_runtime_dropped', 'tmath_runtime_tick',
        'tmath_runtime_steps', 'tmath_runtime_interpolation',
        'tmath_runtime_sound_count', 'tmath_runtime_sound',
    ]
endif
if audio_enabled
    wasm_exports += [
        'tmath_audio_supported', 'tmath_audio_load', 'tmath_audio_start',
        'tmath_audio_play', 'tmath_audio_stop', 'tmath_audio_active',
        'tmath_audio_master_gain', 'tmath_audio_bus_gain', 'tmath_audio_transport',
    ]
endif

wasm_sources = files('tmathWasm.cpp')
wasm_dependencies = [tmath_dep] + tmath_module_deps
wasm_cpp_args = tmath_module_args
wasm_link_args = [
    '--no-entry',
    '-sALLOW_MEMORY_GROWTH=1',
    '-sMODULARIZE=1',
    '-sEXPORT_ES6=1',
    '-sENVIRONMENT=web,worker',
    '-sEXPORTED_FUNCTIONS=[_' + ',_'.join(wasm_exports) + ']',
    '-sEXPORTED_RUNTIME_METHODS=[UTF8ToString,HEAPU8]',
    '-sFILESYSTEM=0',
]

# Files copied next to tmath-wasm.js: JS bindings plus runtime assets.
wasm_copy_files = tmath_js_files + files(
    '../../examples/assets/pixels.svg',
    '../../examples/assets/Pretendard.ttf',
    '../../examples/assets/Pretendard-OFL.txt',
    '../../examples/lua/manim_3d_surface_plot.lua',
)
