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
    'tmathLuaRuntime.cpp',
    include_directories: include_directories('../../inc', '../lua'),
    dependencies: tmath_lua_runtime_dependencies,
    cpp_args: tmath_lua_runtime_args,
    install: true,
)
tmath_lua_runtime_dep = declare_dependency(
    link_with: tmath_lua_runtime_lib,
    include_directories: include_directories('../../inc'),
    dependencies: tmath_lua_runtime_public_dependencies,
)
install_headers('../../inc/tmath_lua_runtime.h')
