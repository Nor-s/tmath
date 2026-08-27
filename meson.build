project(
    'tmath',
    ['c', 'cpp'],
    version: '0.1.0',
    meson_version: '>=1.3.0',
    default_options: [
        'c_std=c11',
        'cpp_std=c++17',
        'cpp_eh=none',
        'cpp_rtti=false',
        'default_library=static',
        'warning_level=3',
    ],
)

cpp = meson.get_compiler('cpp')
lua_option = get_option('lua')
latex_option = get_option('latex')
ui_enabled = get_option('ui')
input_enabled = get_option('input')
lua_runtime_enabled = get_option('lua_runtime')
audio_enabled = get_option('audio')
diagram_enabled = get_option('diagram').enabled()
chart_enabled = get_option('chart').enabled()
engines = get_option('engines')
cpu_enabled = engines.contains('cpu')
gl_enabled = engines.contains('gl')

if engines.length() == 0
    error('Select at least one render engine: -Dengines=cpu, -Dengines=gl, or -Dengines=cpu,gl')
endif
if host_machine.system() == 'emscripten' and not cpu_enabled
    error('Emscripten builds require the CPU engine for the RGBA WebAssembly API')
endif

latex_enabled = false
if latex_option.enabled()
    if host_machine.system() == 'darwin' or host_machine.system() == 'linux'
        latex_enabled = true
    else
        error('Experimental LaTeX support currently requires a POSIX host')
    endif
endif

tvg_engines = []
if cpu_enabled
    tvg_engines += 'cpu'
endif
if gl_enabled
    tvg_engines += 'gl'
endif
tvg_options = [
    'engines=' + ','.join(tvg_engines),
    'default_library=static',
    'static=true',
    'loaders=svg,png,jpg,webp,ttf',
    'savers=',
    'tools=',
    'bindings=',
    'extra=',
    'threads=false',
    'tests=false',
    'werror=false',
]
if host_machine.system() == 'emscripten'
    tvg_options += 'file=false'
endif

tvg_fallback = false
tvg_bundled = get_option('bundled_thorvg') or host_machine.system() == 'emscripten'
if tvg_bundled
    tvg_fallback = true
    tvg_project = subproject('thorvg', default_options: tvg_options)
    tvg_dep = tvg_project.get_variable('thorvg_dep')
else
    tvg_dep = dependency('thorvg-1', required: false, allow_fallback: false)
    if not tvg_dep.found()
        tvg_fallback = true
        tvg_project = subproject('thorvg', default_options: tvg_options)
        tvg_dep = tvg_project.get_variable('thorvg_dep')
    endif
endif

if gl_enabled and not tvg_fallback
    warning(
        'External ThorVG GL availability is checked by the GL renderer at runtime',
    )
endif

tmath_args = []

lua_enabled = false
lua_fallback = false
lua_pc = ''
lua_link_whole = []
lua_dep = declare_dependency()
if not lua_option.disabled()
    lua_dep = dependency('lua-5.4', required: false, allow_fallback: false)
    if lua_dep.found()
        lua_pc = 'lua-5.4'
    endif
    if not lua_dep.found()
        lua_dep = dependency('lua54', required: false, allow_fallback: false)
        if lua_dep.found()
            lua_pc = 'lua54'
        endif
    endif
    if not lua_dep.found()
        lua_project = subproject('lua', required: lua_option)
        if lua_project.found()
            lua_fallback = true
            lua_dep = lua_project.get_variable('lua_dep')
            lua_link_whole += lua_project.get_variable('lua_lib')
        endif
    endif
    lua_enabled = lua_dep.found()
endif
if latex_enabled and not lua_enabled
    error('Experimental LaTeX support requires the native Lua CLI')
endif
if lua_runtime_enabled and not lua_enabled
    error('Experimental retained Lua runtime requires Lua support')
endif

tmath_inc = include_directories(
    'inc',
    'src/loaders',
    'src/bindings/lua',
    'src/scene',
    'src/renderer',
    'src/renderer/tvg',
    'src/savers',
)
tmath_sources = files(
    'src/common/tmathMath.cpp',
    'src/loaders/tmathAssetLoader.cpp',
    'src/renderer/tmathDisplayList.cpp',
    'src/renderer/tmathRenderer.cpp',
    'src/renderer/tmathRendererData.cpp',
    'src/renderer/tvg/tmathTvgRenderer.cpp',
    'src/savers/tmathSaver.cpp',
    'src/savers/gif/tmathGifSaver.cpp',
    'src/savers/lottie/tmathLottieSaver.cpp',
    'src/savers/video/tmathVideoSaver.cpp',
    'src/scene/tmathObject.cpp',
    'src/scene/tmathScene.cpp',
    'src/scene/tmathTheme.cpp',
)
if cpu_enabled
    tmath_sources += files(
        'src/loaders/tvg/tmathTvgAssetDecoder.cpp',
        'src/renderer/tvg/tmathTvgSwRenderer.cpp',
    )
else
    tmath_sources += files(
        'src/loaders/tvg/tmathTvgAssetDecoderStub.cpp',
        'src/renderer/tvg/tmathTvgSwRendererStub.cpp',
    )
endif
if gl_enabled
    tmath_sources += files('src/renderer/tvg/tmathTvgGlRenderer.cpp')
else
    tmath_sources += files('src/renderer/tvg/tmathTvgGlRendererStub.cpp')
endif
tmath_dependencies = [tvg_dep]
if host_machine.system() == 'linux'
    tmath_dependencies += dependency('threads')
endif
if lua_enabled
    tmath_sources += files('src/bindings/lua/tmathLua.cpp')
    tmath_dependencies += lua_dep
else
    tmath_sources += files('src/bindings/lua/tmathLuaStub.cpp')
endif
if host_machine.system() != 'emscripten'
    tmath_sources += files('bindings/wasm/tmathWasm.cpp')
endif

tmath_lib = static_library(
    'tmath',
    tmath_sources,
    include_directories: tmath_inc,
    dependencies: tmath_dependencies,
    link_whole: lua_link_whole,
    cpp_args: tmath_args,
    install: true,
)

tmath_dep = declare_dependency(
    link_with: tmath_lib,
    include_directories: include_directories('inc'),
    dependencies: tmath_dependencies,
)

install_headers('inc/tmath.h', 'inc/tmath_capi.h')

if ui_enabled
    tmath_ui_sources = files('src/ui/tmathUi.cpp')
    tmath_ui_dependencies = []
    if lua_enabled
        tmath_ui_sources += files('src/ui/tmathUiLua.cpp')
        tmath_ui_dependencies += lua_dep
    else
        tmath_ui_sources += files('src/ui/tmathUiLuaStub.cpp')
    endif
    tmath_ui_lib = static_library(
        'tmath-ui',
        tmath_ui_sources,
        include_directories: include_directories('inc', 'src/bindings/lua'),
        dependencies: tmath_ui_dependencies,
        install: true,
    )
    tmath_ui_dep = declare_dependency(
        link_with: tmath_ui_lib,
        include_directories: include_directories('inc'),
        dependencies: tmath_dep,
    )
    install_headers('inc/tmath_ui.h')
endif

if input_enabled
    tmath_input_sources = files(
        'src/input/tmathInput.cpp',
        'src/input/tmathInputState.cpp',
    )
    tmath_input_dependencies = []
    if lua_enabled
        tmath_input_sources += files('src/input/tmathInputLua.cpp')
        tmath_input_dependencies += lua_dep
    else
        tmath_input_sources += files('src/input/tmathInputLuaStub.cpp')
    endif
    tmath_input_lib = static_library(
        'tmath-input',
        tmath_input_sources,
        include_directories: include_directories('inc', 'src/bindings/lua'),
        dependencies: tmath_input_dependencies,
        install: true,
    )
    tmath_input_dep = declare_dependency(
        link_with: tmath_input_lib,
        include_directories: include_directories('inc'),
        dependencies: tmath_dep,
    )
    install_headers('inc/tmath_input.h')
endif

if lua_runtime_enabled
    tmath_lua_runtime_dependencies = [lua_dep]
    tmath_lua_runtime_args = []
    tmath_lua_runtime_public_dependencies = [tmath_dep]
    if input_enabled
        tmath_lua_runtime_dependencies += tmath_input_dep
        tmath_lua_runtime_public_dependencies += tmath_input_dep
        tmath_lua_runtime_args += '-DTMATH_INPUT'
    endif
    tmath_lua_runtime_lib = static_library(
        'tmath-lua-runtime',
        'src/lua_runtime/tmathLuaRuntime.cpp',
        include_directories: include_directories('inc', 'src/bindings/lua'),
        dependencies: tmath_lua_runtime_dependencies,
        cpp_args: tmath_lua_runtime_args,
        install: true,
    )
    tmath_lua_runtime_dep = declare_dependency(
        link_with: tmath_lua_runtime_lib,
        include_directories: include_directories('inc'),
        dependencies: tmath_lua_runtime_public_dependencies,
    )
    install_headers('inc/tmath_lua_runtime.h')
endif

if audio_enabled
    miniaudio_project = subproject('miniaudio')
    miniaudio_lib = miniaudio_project.get_variable('miniaudio_lib')
    miniaudio_include = miniaudio_project.get_variable('miniaudio_include')
    miniaudio_args = miniaudio_project.get_variable('miniaudio_args')
    miniaudio_system_deps = miniaudio_project.get_variable('miniaudio_system_deps')
    miniaudio_license = miniaudio_project.get_variable('miniaudio_license')
    tmath_audio_sources = files(
        'src/audio/tmathAudio.cpp',
        'src/audio/tmathAudioPlayer.cpp',
    )
    tmath_audio_dependencies = [tmath_dep]
    if lua_enabled
        tmath_audio_sources += files('src/audio/tmathAudioLua.cpp')
        tmath_audio_dependencies += lua_dep
    else
        tmath_audio_sources += files('src/audio/tmathAudioLuaStub.cpp')
    endif
    tmath_audio_lib = static_library(
        'tmath-audio',
        tmath_audio_sources,
        include_directories: [
            include_directories('inc', 'src/bindings/lua'),
            miniaudio_include,
        ],
        dependencies: tmath_audio_dependencies,
        cpp_args: miniaudio_args,
        link_whole: miniaudio_lib,
        install: true,
    )
    tmath_audio_dep = declare_dependency(
        link_with: tmath_audio_lib,
        include_directories: include_directories('inc'),
        dependencies: [tmath_dep] + miniaudio_system_deps,
    )
    install_headers('inc/tmath_audio.h')
    install_data(
        miniaudio_license,
        install_dir: get_option('datadir') / 'licenses' / 'tmath-audio',
        rename: 'LICENSE-miniaudio.txt',
    )
endif

if diagram_enabled
    tmath_diagram_sources = files('src/diagram/tmathDiagram.cpp')
    tmath_diagram_dependencies = []
    if lua_enabled
        tmath_diagram_sources += files('src/diagram/tmathDiagramLua.cpp')
        tmath_diagram_dependencies += lua_dep
    else
        tmath_diagram_sources += files('src/diagram/tmathDiagramLuaStub.cpp')
    endif
    tmath_diagram_lib = static_library(
        'tmath-diagram',
        tmath_diagram_sources,
        include_directories: include_directories('inc', 'src/bindings/lua'),
        dependencies: tmath_diagram_dependencies,
        install: true,
    )
    tmath_diagram_dep = declare_dependency(
        link_with: tmath_diagram_lib,
        include_directories: include_directories('inc'),
        dependencies: tmath_dep,
    )
    install_headers('inc/tmath_diagram.h')
endif

if chart_enabled
    tmath_chart_sources = files('src/chart/tmathChart.cpp')
    tmath_chart_dependencies = []
    if lua_enabled
        tmath_chart_sources += files('src/chart/tmathChartLua.cpp')
        tmath_chart_dependencies += lua_dep
    else
        tmath_chart_sources += files('src/chart/tmathChartLuaStub.cpp')
    endif
    tmath_chart_lib = static_library(
        'tmath-chart',
        tmath_chart_sources,
        include_directories: include_directories('inc', 'src/bindings/lua'),
        dependencies: tmath_chart_dependencies,
        install: true,
    )
    tmath_chart_dep = declare_dependency(
        link_with: tmath_chart_lib,
        include_directories: include_directories('inc'),
        dependencies: tmath_dep,
    )
    install_headers('inc/tmath_chart.h')
endif

if get_option('examples')
    install_data(
        'examples/lua/arrow_tails.lua',
        'examples/lua/dimension_transition.lua',
        'examples/lua/matrix_transform.lua',
        'examples/lua/image_cells.lua',
        'examples/lua/vector_transform.lua',
        'examples/lua/projection3d.lua',
        'examples/lua/calculus2d.lua',
        'examples/lua/calculus3d.lua',
        'examples/lua/mathbox_mobius.lua',
        'examples/lua/cell_field.lua',
        'examples/lua/voxel_field.lua',
        'examples/lua/manim_following_graph_camera.lua',
        'examples/lua/manim_brace_annotation.lua',
        'examples/lua/manim_moving_around.lua',
        'examples/lua/manim_sin_cos_function_plot.lua',
        'examples/lua/manim_graph_area_plot.lua',
        'examples/lua/manim_polygon_on_axes.lua',
        'examples/lua/manim_moving_zoomed_scene.lua',
        'examples/lua/manim_3d_light_source_position.lua',
        'examples/lua/manim_3d_camera_illusion_rotation.lua',
        'examples/lua/manim_3d_surface_plot.lua',
        'examples/lua/manim_opening.lua',
        'examples/lua/manim_sine_curve_unit_circle.lua',
        'examples/lua/circle_equation.lua',
        'examples/lua/sphere_equation.lua',
        'examples/lua/solids3d.lua',
        'examples/lua/space_numbers.lua',
        'examples/lua/text_font.lua',
        'examples/lua/sw_rle_span.lua',
        'examples/lua/sw_antialiasing.lua',
        'examples/lua/sw_linear_gradient.lua',
        'examples/lua/sw_radial_gradient.lua',
        'examples/lua/conic_vector_formula.lua',
        'examples/lua/conic_coordinate_pullback.lua',
        'examples/lua/conic_prepared_geometry.lua',
        'examples/lua/conic_scanline_range.lua',
        'examples/lua/conic_seam_reconstruction.lua',
        'examples/lua/conic_surface_to_gradient.lua',
        'examples/lua/conic_angular_parameterization.lua',
        'examples/lua/conic_scanline_recurrence.lua',
        'examples/lua/conic_angular_margin_aa.lua',
        'examples/lua/conic_fwidth_intuition.lua',
        'examples/lua/bezier_calculus.lua',
        'examples/lua/vector_operations.lua',
        'examples/lua/vector_dot_cross.lua',
        'examples/lua/trigonometry_circle.lua',
        'examples/lua/tmath_brand.lua',
        'examples/lua/theme_showcase.lua',
        'examples/lua/animation_gallery.lua',
        'examples/lua/anim_curve_effects.lua',
        'examples/lua/animatrix_surface_write.lua',
        'examples/lua/path_fill.lua',
        'examples/lua/scene_transition.lua',
        'examples/lua/ray_tracing_pixels.lua',
        'examples/lua/color_space_display_p3.lua',
        'examples/lua/forward_kinematics.lua',
        'examples/lua/ccd_inverse_kinematics.lua',
        'examples/lua/fabrik_inverse_kinematics.lua',
        'examples/lua/data_structure_composition.lua',
        'examples/lua/quick_sort.lua',
        'examples/lua/merge_sort.lua',
        'examples/lua/kd_tree.lua',
        'examples/lua/red_black_tree.lua',
        'examples/lua/diagram_architecture.lua',
        'examples/lua/diagram_sequence.lua',
        'examples/lua/diagram_event_flow.lua',
        'examples/lua/diagram_causal_loop.lua',
        'examples/lua/diagram_sankey.lua',
        'examples/lua/tmath_quickstart_cheatsheet.lua',
        'examples/lua/binary_search_cheatsheet.lua',
        install_dir: get_option('datadir') / 'tmath' / 'examples',
    )
    install_data(
        'examples/assets/pixels.svg',
        'examples/assets/Pretendard.ttf',
        'examples/assets/Pretendard-OFL.txt',
        install_dir: get_option('datadir') / 'tmath' / 'assets',
    )
    if diagram_enabled
        install_data(
            'examples/lua/diagram_native_flow.lua',
            install_dir: get_option('datadir') / 'tmath' / 'examples',
        )
    endif
    if chart_enabled
        install_data(
            'examples/lua/chart_line_bar.lua',
            install_dir: get_option('datadir') / 'tmath' / 'examples',
        )
    endif
endif

if host_machine.system() != 'emscripten'
    pkg = import('pkgconfig')
    private_requires = ['thorvg-1']
    if lua_enabled and not lua_fallback
        private_requires += lua_pc
    endif
    pkg.generate(
        tmath_lib,
        filebase: 'tmath',
        name: 'tmath',
        description: 'Lightweight ThorVG mathematical animation engine',
        subdirs: '.',
        requires_private: private_requires,
    )
    if ui_enabled
        pkg.generate(
            tmath_ui_lib,
            filebase: 'tmath-ui',
            name: 'tmath-ui',
            description: 'Experimental interactive control UI module for tmath',
            subdirs: '.',
            requires_private: ['tmath'],
        )
    endif
    if input_enabled
        pkg.generate(
            tmath_input_lib,
            filebase: 'tmath-input',
            name: 'tmath-input',
            description: 'Experimental keyboard, pointer, and camera input module for tmath',
            subdirs: '.',
            requires_private: ['tmath'],
        )
    endif
    if lua_runtime_enabled
        lua_runtime_requires = ['tmath']
        if input_enabled
            lua_runtime_requires += 'tmath-input'
        endif
        pkg.generate(
            tmath_lua_runtime_lib,
            filebase: 'tmath-lua-runtime',
            name: 'tmath-lua-runtime',
            description: 'Experimental retained Lua fixed-step runtime for tmath',
            subdirs: '.',
            requires_private: lua_runtime_requires,
        )
    endif
    if audio_enabled
        pkg.generate(
            tmath_audio_lib,
            filebase: 'tmath-audio',
            name: 'tmath-audio',
            description: 'Experimental synchronized audio module for tmath',
            subdirs: '.',
            requires_private: ['tmath'],
            libraries_private: miniaudio_system_deps,
        )
    endif
    if diagram_enabled
        pkg.generate(
            tmath_diagram_lib,
            filebase: 'tmath-diagram',
            name: 'tmath-diagram',
            description: 'Experimental semantic diagram authoring module for tmath',
            subdirs: '.',
            requires_private: ['tmath'],
        )
    endif
    if chart_enabled
        pkg.generate(
            tmath_chart_lib,
            filebase: 'tmath-chart',
            name: 'tmath-chart',
            description: 'Experimental quantitative chart authoring module for tmath',
            subdirs: '.',
            requires_private: ['tmath'],
        )
    endif
endif

if lua_enabled and host_machine.system() != 'emscripten'
    tmath_cli_sources = files('tools/tmath.cpp')
    tmath_cli_args = []
    tmath_cli_dependencies = [tmath_dep]
    if ui_enabled
        tmath_cli_args += '-DTMATH_UI'
        tmath_cli_dependencies += tmath_ui_dep
    endif
    if input_enabled
        tmath_cli_args += '-DTMATH_INPUT'
        tmath_cli_dependencies += tmath_input_dep
    endif
    if lua_runtime_enabled
        tmath_cli_args += '-DTMATH_LUA_RUNTIME'
        tmath_cli_dependencies += tmath_lua_runtime_dep
    endif
    if audio_enabled
        tmath_cli_args += '-DTMATH_AUDIO'
        tmath_cli_dependencies += tmath_audio_dep
    endif
    if diagram_enabled
        tmath_cli_args += '-DTMATH_DIAGRAM'
        tmath_cli_dependencies += tmath_diagram_dep
    endif
    if chart_enabled
        tmath_cli_args += '-DTMATH_CHART'
        tmath_cli_dependencies += tmath_chart_dep
    endif
    if latex_enabled
        tmath_cli_sources += files('tools/tmathLatex.cpp')
        tmath_cli_args += '-DTMATH_EXPERIMENTAL_LATEX'
    endif
    tmath_cli = executable(
        'tmath',
        tmath_cli_sources,
        dependencies: tmath_cli_dependencies,
        include_directories: include_directories('src/bindings/lua'),
        cpp_args: tmath_cli_args,
        install: true,
    )
endif

if lua_enabled and host_machine.system() == 'emscripten'
    wasm_exports = '[_malloc,_free,_tmath_create,_tmath_create_with_engine,_tmath_default_render_engine_set,_tmath_default_render_engine,_tmath_render_engine_enabled,_tmath_render_engine,_tmath_destroy,_tmath_host_theme,_tmath_adaptive_theme,_tmath_load_lua,_tmath_load_font,_tmath_load_asset,_tmath_render,_tmath_render_scaled,_tmath_render_gl,_tmath_lottie,_tmath_lottie_data,_tmath_lottie_size,_tmath_bounds,_tmath_intersects,_tmath_layout_report,_tmath_layout_report_data,_tmath_layout_report_size,_tmath_resize,_tmath_camera_mode,_tmath_camera_view,_tmath_pixels,_tmath_pixels_size,_tmath_width,_tmath_height,_tmath_duration,_tmath_loop,_tmath_last_error'
    wasm_dependencies = [tmath_dep]
    wasm_cpp_args = []
    if ui_enabled or input_enabled
        wasm_exports += ',_tmath_camera,_tmath_input'
    endif
    if ui_enabled
        wasm_exports += ',_tmath_ui_input,_tmath_ui_sample_handle,_tmath_ui_sample_tag,_tmath_ui_sample_type,_tmath_ui_sample_x,_tmath_ui_sample_y,_tmath_ui_sample_u,_tmath_ui_sample_v,_tmath_ui_sample_rgba'
        wasm_dependencies += tmath_ui_dep
        wasm_cpp_args += '-DTMATH_UI'
    endif
    if input_enabled
        wasm_exports += ',_tmath_input_begin,_tmath_input_release'
        wasm_exports += ',_tmath_input_key_state,_tmath_input_key_begin,_tmath_input_key_end'
        wasm_exports += ',_tmath_input_pointer_state,_tmath_input_pointer_x'
        wasm_exports += ',_tmath_input_pointer_y,_tmath_input_pointer_dx,_tmath_input_pointer_dy'
        wasm_exports += ',_tmath_input_pointer_wheel_x,_tmath_input_pointer_wheel_y'
        wasm_exports += ',_tmath_input_pointer_previous_buttons,_tmath_input_pointer_buttons'
        wasm_exports += ',_tmath_input_pointer_pressed,_tmath_input_pointer_released'
        wasm_dependencies += tmath_input_dep
        wasm_cpp_args += '-DTMATH_INPUT'
    endif
    if lua_runtime_enabled
        wasm_exports += ',_tmath_runtime_active,_tmath_runtime_advance,_tmath_runtime_time'
        wasm_exports += ',_tmath_runtime_dropped,_tmath_runtime_tick'
        wasm_exports += ',_tmath_runtime_steps,_tmath_runtime_interpolation'
        wasm_exports += ',_tmath_runtime_sound_count,_tmath_runtime_sound'
        wasm_dependencies += tmath_lua_runtime_dep
        wasm_cpp_args += '-DTMATH_LUA_RUNTIME'
    endif
    if audio_enabled
        wasm_exports += ',_tmath_audio_supported,_tmath_audio_load,_tmath_audio_start'
        wasm_exports += ',_tmath_audio_play,_tmath_audio_stop,_tmath_audio_active'
        wasm_exports += ',_tmath_audio_master_gain,_tmath_audio_bus_gain,_tmath_audio_transport'
        wasm_dependencies += tmath_audio_dep
        wasm_cpp_args += '-DTMATH_AUDIO'
    endif
    if diagram_enabled
        wasm_dependencies += tmath_diagram_dep
        wasm_cpp_args += '-DTMATH_DIAGRAM'
    endif
    if chart_enabled
        wasm_dependencies += tmath_chart_dep
        wasm_cpp_args += '-DTMATH_CHART'
    endif
    wasm_exports += ']'
    executable(
        'tmath-wasm',
        'bindings/wasm/tmathWasm.cpp',
        dependencies: wasm_dependencies,
        include_directories: tmath_inc,
        cpp_args: wasm_cpp_args,
        name_suffix: 'js',
        link_args: [
            '--no-entry',
            '-sALLOW_MEMORY_GROWTH=1',
            '-sMODULARIZE=1',
            '-sEXPORT_ES6=1',
            '-sENVIRONMENT=web,worker',
            '-sEXPORTED_FUNCTIONS=' + wasm_exports,
            '-sEXPORTED_RUNTIME_METHODS=[UTF8ToString,HEAPU8]',
            '-sFILESYSTEM=0',
        ],
    )
    foreach binding : ['client.js', 'client.d.ts', 'bindings.js', 'bindings.d.ts']
        configure_file(input: 'wasm' / binding, output: binding, copy: true)
    endforeach
    foreach demo : [
        'index.html', 'app.js', 'api.js', 'catalog.js', 'catalog_advanced.js', 'catalog_animations.js', 'catalog_animatrix.js', 'catalog_color.js',
        'catalog_conic.js', 'catalog_conic_article.js', 'catalog_kinematics.js', 'catalog_manim.js', 'catalog_math.js',
        'catalog_brand.js', 'catalog_composition.js', 'catalog_diagrams.js', 'catalog_rendering.js', 'catalog_sorts.js', 'catalog_tmath.js',
        'catalog_trees.js', 'catalog_cheatsheets.js',
        'savers.js', 'timeline.js', 'style.css',
    ]
        configure_file(input: 'examples/wasm' / demo, output: demo, copy: true)
    endforeach
    configure_file(input: 'examples/assets/pixels.svg', output: 'pixels.svg', copy: true)
    configure_file(input: 'examples/assets/Pretendard.ttf', output: 'Pretendard.ttf', copy: true)
    configure_file(input: 'examples/assets/Pretendard-OFL.txt', output: 'Pretendard-OFL.txt', copy: true)
    foreach manim_source : [
        'manim_following_graph_camera.lua', 'manim_brace_annotation.lua',
        'manim_moving_around.lua', 'manim_sin_cos_function_plot.lua', 'manim_graph_area_plot.lua',
        'manim_polygon_on_axes.lua', 'manim_moving_zoomed_scene.lua',
        'manim_3d_light_source_position.lua', 'manim_3d_camera_illusion_rotation.lua',
        'manim_3d_surface_plot.lua', 'manim_opening.lua', 'manim_sine_curve_unit_circle.lua',
    ]
        configure_file(input: 'examples/lua' / manim_source, output: manim_source, copy: true)
    endforeach
endif

if get_option('tests')
    test_math = executable(
        'testMath',
        'test/testMath.cpp',
        dependencies: tmath_dep,
    )
    test('math', test_math)

    renderer_test_args = []
    if cpu_enabled
        renderer_test_args += '-DTMATH_EXPECT_CPU'
    endif
    if gl_enabled
        renderer_test_args += '-DTMATH_EXPECT_GL'
    endif
    test_renderer = executable(
        'testRenderer',
        'test/testRenderer.cpp',
        dependencies: tmath_dep,
        cpp_args: renderer_test_args,
    )
    test('renderer', test_renderer)

    if diagram_enabled
        test_diagram = executable(
            'testDiagram',
            'test/testDiagram.cpp',
            dependencies: tmath_diagram_dep,
        )
        test('diagram', test_diagram)
    endif

    if chart_enabled
        test_chart = executable(
            'testChart',
            'test/testChart.cpp',
            dependencies: tmath_chart_dep,
        )
        test('chart', test_chart)
    endif

    if cpu_enabled
        test_scene = executable(
            'testScene',
            'test/testScene.cpp',
            dependencies: tmath_dep,
            cpp_args: (gl_enabled ? ['-DTMATH_EXPECT_GL'] : []) + [
                '-DTMATH_TEST_FONT="' + (meson.project_source_root() / 'examples/assets/Pretendard.ttf') + '"',
            ],
        )
        test('sw-scene', test_scene)

        if ui_enabled
            test_ui = executable(
                'testUi',
                'test/testUi.cpp',
                dependencies: tmath_ui_dep,
            )
            test('ui', test_ui)
        endif
        if input_enabled
            input_test_dependencies = [tmath_input_dep]
            input_test_args = lua_enabled ? ['-DTMATH_EXPECT_LUA'] : []
            if ui_enabled
                input_test_dependencies += tmath_ui_dep
                input_test_args += '-DTMATH_UI'
            endif
            test_input = executable(
                'testInput',
                'test/testInput.cpp',
                dependencies: input_test_dependencies,
                cpp_args: input_test_args,
            )
            test('input', test_input)
        endif
        if lua_runtime_enabled
            lua_runtime_test_args = ['-DTMATH_LUA_RUNTIME']
            if input_enabled
                lua_runtime_test_args += '-DTMATH_INPUT'
            endif
            test_lua_runtime = executable(
                'testLuaRuntime',
                'test/testLuaRuntime.cpp',
                dependencies: tmath_lua_runtime_dep,
                include_directories: include_directories('src/bindings/lua'),
                cpp_args: lua_runtime_test_args,
            )
            test('lua-runtime', test_lua_runtime)
        endif
        if audio_enabled
            audio_test_dependencies = [tmath_audio_dep]
            audio_test_args = lua_enabled ? ['-DTMATH_EXPECT_LUA'] : []
            audio_test_includes = []
            if lua_runtime_enabled
                audio_test_dependencies += tmath_lua_runtime_dep
                audio_test_args += [
                    '-DTMATH_AUDIO',
                    '-DTMATH_LUA_RUNTIME',
                    '-DTMATH_EXPECT_LUA_RUNTIME',
                ]
                audio_test_includes += include_directories('src/bindings/lua')
            endif
            test_audio = executable(
                'testAudio',
                'test/testAudio.cpp',
                dependencies: audio_test_dependencies,
                include_directories: audio_test_includes,
                cpp_args: audio_test_args,
            )
            test('audio', test_audio)
        endif
    endif

    if gl_enabled and host_machine.system() == 'darwin'
        gl_framework = dependency('appleframeworks', modules: 'OpenGL')
        test_gl = executable(
            'testGl',
            'test/testGl.cpp',
            dependencies: [tmath_dep, gl_framework],
            cpp_args: lua_enabled ? ['-DTMATH_EXPECT_LUA'] : [],
        )
        test('gl-offscreen', test_gl)
    endif

    if lua_enabled
        if diagram_enabled and chart_enabled
            authoring_module_dependencies = [tmath_diagram_dep, tmath_chart_dep]
            authoring_module_args = ['-DTMATH_DIAGRAM', '-DTMATH_CHART']
            if ui_enabled
                authoring_module_dependencies += tmath_ui_dep
                authoring_module_args += '-DTMATH_UI'
            endif
            if input_enabled
                authoring_module_dependencies += tmath_input_dep
                authoring_module_args += '-DTMATH_INPUT'
            endif
            test_authoring_modules = executable(
                'testAuthoringModules',
                'test/testAuthoringModules.cpp',
                dependencies: authoring_module_dependencies,
                include_directories: include_directories('src/bindings/lua'),
                cpp_args: authoring_module_args,
            )
            test('authoring-modules', test_authoring_modules)
        endif

        test_lua_extension = executable(
            'testLuaExtension',
            'test/testLuaExtension.cpp',
            dependencies: tmath_dep,
            include_directories: include_directories('src/bindings/lua'),
        )
        test('lua-extension', test_lua_extension)

        if cpu_enabled
            test_lua = executable(
                'testLua',
                'test/testLua.cpp',
                dependencies: tmath_dep,
                cpp_args: [
                    '-DTMATH_TEST_FONT="' + (meson.project_source_root() / 'examples/assets/Pretendard.ttf') + '"',
                ],
            )
            test('lua-scene', test_lua)

            test_capi = executable(
                'testCapi',
                'test/testCapi.cpp',
                dependencies: tmath_dep,
            )
            test('c-api', test_capi)
        endif

        if host_machine.system() != 'emscripten'
            test('example-arrow-tails', tmath_cli, args: ['inspect', files('examples/lua/arrow_tails.lua')])
            test('example-dimension-transition', tmath_cli, args: ['inspect', files('examples/lua/dimension_transition.lua')])
            test('example-matrix-transform', tmath_cli, args: ['inspect', files('examples/lua/matrix_transform.lua')])
            if cpu_enabled
                test('example-image-cells', tmath_cli, args: ['inspect', files('examples/lua/image_cells.lua')])
            endif
            test('example-projection', tmath_cli, args: ['inspect', files('examples/lua/projection3d.lua')])
            test('example-vector-transform', tmath_cli, args: ['inspect', files('examples/lua/vector_transform.lua')])
            example_scenes = {
                'calculus-2d': 'examples/lua/calculus2d.lua',
                'calculus-3d': 'examples/lua/calculus3d.lua',
                'mathbox-mobius': 'examples/lua/mathbox_mobius.lua',
                'cell-field': 'examples/lua/cell_field.lua',
                'voxel-field': 'examples/lua/voxel_field.lua',
                'manim-following-graph-camera': 'examples/lua/manim_following_graph_camera.lua',
                'manim-brace-annotation': 'examples/lua/manim_brace_annotation.lua',
                'manim-moving-around': 'examples/lua/manim_moving_around.lua',
                'manim-sin-cos-function-plot': 'examples/lua/manim_sin_cos_function_plot.lua',
                'manim-graph-area-plot': 'examples/lua/manim_graph_area_plot.lua',
                'manim-polygon-on-axes': 'examples/lua/manim_polygon_on_axes.lua',
                'manim-moving-zoomed-scene': 'examples/lua/manim_moving_zoomed_scene.lua',
                'manim-3d-light-source': 'examples/lua/manim_3d_light_source_position.lua',
                'manim-3d-camera-illusion': 'examples/lua/manim_3d_camera_illusion_rotation.lua',
                'manim-3d-surface-plot': 'examples/lua/manim_3d_surface_plot.lua',
                'manim-opening': 'examples/lua/manim_opening.lua',
                'manim-sine-curve-unit-circle': 'examples/lua/manim_sine_curve_unit_circle.lua',
                'circle-equation': 'examples/lua/circle_equation.lua',
                'sphere-equation': 'examples/lua/sphere_equation.lua',
                'solids-3d': 'examples/lua/solids3d.lua',
                'space-numbers': 'examples/lua/space_numbers.lua',
                'text-font': 'examples/lua/text_font.lua',
                'sw-rle-span': 'examples/lua/sw_rle_span.lua',
                'sw-antialiasing': 'examples/lua/sw_antialiasing.lua',
                'sw-linear-gradient': 'examples/lua/sw_linear_gradient.lua',
                'sw-radial-gradient': 'examples/lua/sw_radial_gradient.lua',
                'conic-vector-formula': 'examples/lua/conic_vector_formula.lua',
                'conic-coordinate-pullback': 'examples/lua/conic_coordinate_pullback.lua',
                'conic-prepared-geometry': 'examples/lua/conic_prepared_geometry.lua',
                'conic-scanline-range': 'examples/lua/conic_scanline_range.lua',
                'conic-seam-reconstruction': 'examples/lua/conic_seam_reconstruction.lua',
                'conic-surface-to-gradient': 'examples/lua/conic_surface_to_gradient.lua',
                'conic-angular-parameterization': 'examples/lua/conic_angular_parameterization.lua',
                'conic-scanline-recurrence': 'examples/lua/conic_scanline_recurrence.lua',
                'conic-angular-margin-aa': 'examples/lua/conic_angular_margin_aa.lua',
                'conic-fwidth-intuition': 'examples/lua/conic_fwidth_intuition.lua',
                'bezier-calculus': 'examples/lua/bezier_calculus.lua',
                'vector-operations': 'examples/lua/vector_operations.lua',
                'vector-dot-cross': 'examples/lua/vector_dot_cross.lua',
                'trigonometry-circle': 'examples/lua/trigonometry_circle.lua',
                'tmath-brand': 'examples/lua/tmath_brand.lua',
                'theme-showcase': 'examples/lua/theme_showcase.lua',
                'animation-gallery': 'examples/lua/animation_gallery.lua',
                'animatrix-surface-write': 'examples/lua/animatrix_surface_write.lua',
                'anim-curve-effects': 'examples/lua/anim_curve_effects.lua',
                'path-fill': 'examples/lua/path_fill.lua',
                'scene-transition': 'examples/lua/scene_transition.lua',
                'object-gallery': 'examples/lua/object_gallery.lua',
                'text-reveal-transitions': 'examples/lua/text_reveal_transitions.lua',
                'ray-tracing-pixels': 'examples/lua/ray_tracing_pixels.lua',
                'color-space-display-p3': 'examples/lua/color_space_display_p3.lua',
                'forward-kinematics': 'examples/lua/forward_kinematics.lua',
                'ccd-inverse-kinematics': 'examples/lua/ccd_inverse_kinematics.lua',
                'fabrik-inverse-kinematics': 'examples/lua/fabrik_inverse_kinematics.lua',
                'data-structure-composition': 'examples/lua/data_structure_composition.lua',
                'quick-sort': 'examples/lua/quick_sort.lua',
                'merge-sort': 'examples/lua/merge_sort.lua',
                'kd-tree': 'examples/lua/kd_tree.lua',
                'red-black-tree': 'examples/lua/red_black_tree.lua',
                'diagram-architecture': 'examples/lua/diagram_architecture.lua',
                'diagram-sequence': 'examples/lua/diagram_sequence.lua',
                'diagram-event-flow': 'examples/lua/diagram_event_flow.lua',
                'diagram-causal-loop': 'examples/lua/diagram_causal_loop.lua',
                'diagram-sankey': 'examples/lua/diagram_sankey.lua',
                'tmath-quickstart-cheatsheet': 'examples/lua/tmath_quickstart_cheatsheet.lua',
                'binary-search-cheatsheet': 'examples/lua/binary_search_cheatsheet.lua',
            }
            example_font = files('examples/assets/Pretendard.ttf')
            if diagram_enabled
                diagram_example = files('examples/lua/diagram_native_flow.lua')
                test('example-diagram-native-flow', tmath_cli, args: ['inspect', diagram_example])
                if cpu_enabled
                    test(
                        'render-diagram-native-flow',
                        tmath_cli,
                        args: [
                            'render', diagram_example, '--font', example_font,
                            '-o', 'example-diagram-native-flow.png',
                        ],
                    )
                endif
            endif
            if chart_enabled
                chart_example = files('examples/lua/chart_line_bar.lua')
                test('example-chart-line-bar', tmath_cli, args: ['inspect', chart_example])
                if cpu_enabled
                    test(
                        'render-chart-line-bar',
                        tmath_cli,
                        args: [
                            'render', chart_example, '--font', example_font,
                            '-o', 'example-chart-line-bar.png',
                        ],
                    )
                endif
            endif
            foreach name, source : example_scenes
                scene_file = files(source)
                test('example-' + name, tmath_cli, args: ['inspect', scene_file])
                if cpu_enabled
                    test(
                        'render-' + name,
                        tmath_cli,
                        args: [
                            'render', scene_file, '--font', example_font,
                            '-o', 'example-' + name + '.png',
                        ],
                    )
                endif
            endforeach
            if cpu_enabled
                test(
                    'layout-path-fill',
                    tmath_cli,
                    args: [
                        'layout', files('examples/lua/path_fill.lua'), '--time', '0.65',
                        '--padding', '4', '--font', example_font,
                    ],
                )
                cs_benchmarks = {
                    'quick-sort': 'examples/lua/quick_sort.lua',
                    'merge-sort': 'examples/lua/merge_sort.lua',
                    'kd-tree': 'examples/lua/kd_tree.lua',
                    'red-black-tree': 'examples/lua/red_black_tree.lua',
                    'data-structure-composition': 'examples/lua/data_structure_composition.lua',
                }
                foreach name, source : cs_benchmarks
                    benchmark(
                        'cs-' + name,
                        tmath_cli,
                        args: [
                            'benchmark', files(source), '--frames', '120', '--warmup', '5',
                            '--font', example_font,
                        ],
                    )
                endforeach
            endif
            test('skill-template', tmath_cli, args: ['inspect', files('skills/tmath-skills/templates/core/scene.lua')])
            math_shortform_skill_templates = {
                'circle-wave-projections': 'skills/tmath-skills/templates/math-shortform/circle-wave-projections.lua',
                'linear-space-transform': 'skills/tmath-skills/templates/math-shortform/linear-space-transform.lua',
                'spirograph-trace': 'skills/tmath-skills/templates/math-shortform/spirograph-trace.lua',
                'pendulum-phase-sync': 'skills/tmath-skills/templates/math-shortform/pendulum-phase-sync.lua',
                'recursive-affine-fractal': 'skills/tmath-skills/templates/math-shortform/recursive-affine-fractal.lua',
                'spherical-coordinate-orbit': 'skills/tmath-skills/templates/math-shortform/spherical-coordinate-orbit.lua',
                'dirichlet-cancellation': 'skills/tmath-skills/templates/math-shortform/dirichlet-cancellation.lua',
                'integration-by-parts-area': 'skills/tmath-skills/templates/math-shortform/integration-by-parts-area.lua',
                'function-transformations': 'skills/tmath-skills/templates/math-shortform/function-transformations.lua',
                'tangent-secant-identity': 'skills/tmath-skills/templates/math-shortform/tangent-secant-identity.lua',
            }
            foreach name, source : math_shortform_skill_templates
                test('skill-template-math-shortform-' + name, tmath_cli, args: ['inspect', files(source)])
            endforeach
            if ui_enabled
                interactive_skill_templates = {
                    'button-state-motion': 'skills/tmath-game/templates/button-state-motion.lua',
                    'toggle-button': 'skills/tmath-game/templates/toggle-button.lua',
                    'slider-function-translation': 'skills/tmath-game/templates/slider-function-translation.lua',
                    'slider-transform-atlas': 'skills/tmath-game/templates/slider-transform-atlas.lua',
                    'sample-area-inspector': 'skills/tmath-game/templates/sample-area-inspector.lua',
                }
                foreach name, source : interactive_skill_templates
                    test('skill-template-interactive-' + name, tmath_cli, args: ['inspect', files(source)])
                endforeach
            endif
            if ui_enabled and input_enabled
                test('skill-template-interactive-ui-input-routing', tmath_cli,
                     args: ['inspect', files('skills/tmath-game/templates/ui-input-routing.lua')])
            endif
            if input_enabled
                input_skill_templates = {
                    'pointer-follow-angle': 'skills/tmath-game/templates/pointer-follow-angle.lua',
                    'keyboard-object-motion': 'skills/tmath-game/templates/keyboard-object-motion.lua',
                    'camera-orbit-view': 'skills/tmath-game/templates/camera-orbit-view.lua',
                }
                foreach name, source : input_skill_templates
                    test('skill-template-input-' + name, tmath_cli, args: ['inspect', files(source)])
                endforeach
            endif
            if input_enabled and lua_runtime_enabled
                retained_game_template = files(
                    'skills/tmath-game/templates/retained-lua-2d-game.lua',
                )
                test('skill-template-input-retained-lua-2d-game', tmath_cli,
                     args: ['inspect', retained_game_template])
                if cpu_enabled
                    test(
                        'render-skill-template-input-retained-lua-2d-game',
                        tmath_cli,
                        args: [
                            'render', retained_game_template, '--font', example_font,
                            '-o', 'skill-template-input-retained-lua-2d-game.png',
                        ],
                    )
                endif
            endif
            diagram_skill_templates = {
                'architecture': 'skills/tmath-skills/templates/diagram/architecture.lua',
                'sequence': 'skills/tmath-skills/templates/diagram/sequence.lua',
                'event-flow': 'skills/tmath-skills/templates/diagram/event-flow.lua',
                'causal-loop': 'skills/tmath-skills/templates/diagram/causal-loop.lua',
                'orthogonal-route': 'skills/tmath-skills/templates/diagram/orthogonal-route.lua',
                'swimlane': 'skills/tmath-skills/templates/diagram/swimlane.lua',
                'state-flow': 'skills/tmath-skills/templates/diagram/state-flow.lua',
                'hierarchy-dependency': 'skills/tmath-skills/templates/diagram/hierarchy-dependency.lua',
                'timeline-gantt': 'skills/tmath-skills/templates/diagram/timeline-gantt.lua',
                'er-schema': 'skills/tmath-skills/templates/diagram/er-schema.lua',
                'reliability-stack': 'skills/tmath-skills/templates/diagram/reliability-stack.lua',
                'layered-system-structure': 'skills/tmath-skills/templates/diagram/layered-system-structure.lua',
                'bidirectional-render-flow': 'skills/tmath-skills/templates/diagram/bidirectional-render-flow.lua',
                'benchmark-report': 'skills/tmath-skills/templates/diagram/benchmark-report.lua',
                'threaded-workflow': 'skills/tmath-skills/templates/diagram/threaded-workflow.lua',
            }
            foreach name, source : diagram_skill_templates
                test('skill-template-diagram-' + name, tmath_cli, args: ['inspect', files(source)])
            endforeach
            if cpu_enabled
                production_diagram_skill_templates = {
                    'swimlane': 'skills/tmath-skills/templates/diagram/swimlane.lua',
                    'state-flow': 'skills/tmath-skills/templates/diagram/state-flow.lua',
                    'hierarchy-dependency': 'skills/tmath-skills/templates/diagram/hierarchy-dependency.lua',
                    'timeline-gantt': 'skills/tmath-skills/templates/diagram/timeline-gantt.lua',
                    'er-schema': 'skills/tmath-skills/templates/diagram/er-schema.lua',
                    'reliability-stack': 'skills/tmath-skills/templates/diagram/reliability-stack.lua',
                    'layered-system-structure': 'skills/tmath-skills/templates/diagram/layered-system-structure.lua',
                    'bidirectional-render-flow': 'skills/tmath-skills/templates/diagram/bidirectional-render-flow.lua',
                    'benchmark-report': 'skills/tmath-skills/templates/diagram/benchmark-report.lua',
                    'threaded-workflow': 'skills/tmath-skills/templates/diagram/threaded-workflow.lua',
                }
                foreach name, source : production_diagram_skill_templates
                    test(
                        'render-skill-template-diagram-' + name,
                        tmath_cli,
                        args: [
                            'render', files(source), '--font', example_font,
                            '-o', 'skill-template-diagram-' + name + '.png',
                        ],
                    )
                endforeach
            endif
            if diagram_enabled
                native_diagram_skill_templates = {
                    'native': 'skills/tmath-skills/templates/diagram/native-diagram.lua',
                }
                foreach name, source : native_diagram_skill_templates
                    template = files(source)
                    test('skill-template-diagram-' + name, tmath_cli, args: ['inspect', template])
                    if cpu_enabled
                        test(
                            'render-skill-template-diagram-' + name,
                            tmath_cli,
                            args: [
                                'render', template, '--font', example_font,
                                '-o', 'skill-template-diagram-' + name + '.png',
                            ],
                        )
                    endif
                endforeach
            endif
            if chart_enabled
                test(
                    'skill-template-chart-native',
                    tmath_cli,
                    args: ['inspect', files('skills/tmath-skills/templates/diagram/native-chart.lua')],
                )
            endif

            node = find_program('node', required: false)
            if node.found() and cpu_enabled
                test(
                    'lottie-saver',
                    node,
                    args: [
                        files('test/testLottie.mjs'), tmath_cli,
                        files('examples/lua/theme_showcase.lua'), example_font,
                    ],
                )
                test(
                    'js-binding',
                    node,
                    args: [
                        files('test/testJsBinding.mjs'), files('wasm/bindings.js'), tmath_cli,
                        files('examples/wasm/catalog.js'), files('examples/wasm/api.js'),
                        files('examples/wasm/timeline.js'),
                    ],
                )
            endif
            typescript = find_program('tsc', required: false)
            if typescript.found()
                test(
                    'ts-binding',
                    typescript,
                    args: [
                        '--noEmit', '--strict', '--target', 'ES2022', '--module', 'ES2022',
                        '--moduleResolution', 'bundler', '--lib', 'ES2022,DOM', files('test/testTypes.ts'),
                    ],
                )
            endif
        endif
    endif
endif

summary(
    {
        'ThorVG': tvg_dep.version(),
        'CPU engine': cpu_enabled,
        'GL engine': gl_enabled,
        'Lua': lua_enabled,
        'Experimental LaTeX': latex_enabled,
        'Experimental UI': ui_enabled,
        'Experimental Input': input_enabled,
        'Experimental retained Lua runtime': lua_runtime_enabled,
        'Experimental Audio': audio_enabled,
        'Experimental Diagram': diagram_enabled,
        'Experimental Chart': chart_enabled,
        'Tests': get_option('tests'),
    },
    section: 'tmath',
    bool_yn: true,
)
