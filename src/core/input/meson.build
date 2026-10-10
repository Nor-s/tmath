tmath_input_sources = files('tmathInput.cpp', 'tmathInputState.cpp')
tmath_input_dependencies = []
if lua_enabled
    tmath_input_sources += files('tmathInputLua.cpp')
    tmath_input_dependencies += lua_dep
else
    tmath_input_sources += files('tmathInputLuaStub.cpp')
endif
tmath_input_lib = static_library(
    'tmath-input',
    tmath_input_sources,
    include_directories: include_directories('../../inc', '../lua'),
    dependencies: tmath_input_dependencies,
    install: true,
)
tmath_input_dep = declare_dependency(
    link_with: tmath_input_lib,
    include_directories: include_directories('../../inc'),
    dependencies: tmath_dep,
)
install_headers('../../inc/tmath_input.h')
