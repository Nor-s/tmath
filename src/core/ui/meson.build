tmath_ui_sources = files('tmathUi.cpp')
tmath_ui_dependencies = []
if lua_enabled
    tmath_ui_sources += files('tmathUiLua.cpp')
    tmath_ui_dependencies += lua_dep
else
    tmath_ui_sources += files('tmathUiLuaStub.cpp')
endif
tmath_ui_lib = static_library(
    'tmath-ui',
    tmath_ui_sources,
    include_directories: include_directories('../../inc', '../lua'),
    dependencies: tmath_ui_dependencies,
    install: true,
)
tmath_ui_dep = declare_dependency(
    link_with: tmath_ui_lib,
    include_directories: include_directories('../../inc'),
    dependencies: tmath_dep,
)
install_headers('../../inc/tmath_ui.h')
