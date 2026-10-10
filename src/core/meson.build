# Everything compiled into libtmath (and the optional module libraries).
# Each core folder appends to these shared variables.
tmath_inc = [include_directories('../inc')]
tmath_sources = []
tmath_dependencies = [tvg_dep]
if host_machine.system() == 'linux'
    tmath_dependencies += dependency('threads')
endif

subdir('common')
subdir('loaders')
subdir('lua')
subdir('scene')
subdir('renderer')
subdir('savers')

# Native builds expose the WebAssembly C ABI through the library as well.
if host_machine.system() != 'emscripten'
    tmath_sources += files('../bindings/wasm/tmathWasm.cpp')
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
    include_directories: include_directories('../inc'),
    dependencies: tmath_dependencies,
)

install_headers('../inc/tmath.h', '../inc/tmath_capi.h')

# Optional modules. Each records its define/dependency for hosts (CLI, WASM)
# and its pkg-config metadata.
tmath_module_args = []
tmath_module_deps = []
tmath_module_pkgs = []

if ui_enabled
    subdir('ui')
    tmath_module_args += '-DTMATH_UI'
    tmath_module_deps += tmath_ui_dep
    tmath_module_pkgs += {
        'lib': tmath_ui_lib, 'name': 'tmath-ui',
        'description': 'Experimental interactive control UI module for tmath',
    }
endif
if input_enabled
    subdir('input')
    tmath_module_args += '-DTMATH_INPUT'
    tmath_module_deps += tmath_input_dep
    tmath_module_pkgs += {
        'lib': tmath_input_lib, 'name': 'tmath-input',
        'description': 'Experimental keyboard, pointer, and camera input module for tmath',
    }
endif
if lua_runtime_enabled
    subdir('lua_runtime')
    tmath_module_args += '-DTMATH_LUA_RUNTIME'
    tmath_module_deps += tmath_lua_runtime_dep
    tmath_module_pkgs += {
        'lib': tmath_lua_runtime_lib, 'name': 'tmath-lua-runtime',
        'description': 'Experimental retained Lua fixed-step runtime for tmath',
        'requires': input_enabled ? ['tmath', 'tmath-input'] : ['tmath'],
    }
endif
if audio_enabled
    subdir('audio')
    tmath_module_args += '-DTMATH_AUDIO'
    tmath_module_deps += tmath_audio_dep
    tmath_module_pkgs += {
        'lib': tmath_audio_lib, 'name': 'tmath-audio',
        'description': 'Experimental synchronized audio module for tmath',
        'libraries': miniaudio_system_deps,
    }
endif
if motion_enabled
    subdir('motion')
    tmath_module_args += '-DTMATH_MOTION'
    tmath_module_deps += tmath_motion_dep
    tmath_module_pkgs += {
        'lib': tmath_motion_lib, 'name': 'tmath-motion',
        'description': 'Experimental semantic runtime motion module for tmath',
    }
endif
if diagram_enabled
    subdir('diagram')
    tmath_module_args += '-DTMATH_DIAGRAM'
    tmath_module_deps += tmath_diagram_dep
    tmath_module_pkgs += {
        'lib': tmath_diagram_lib, 'name': 'tmath-diagram',
        'description': 'Experimental semantic diagram authoring module for tmath',
    }
endif
