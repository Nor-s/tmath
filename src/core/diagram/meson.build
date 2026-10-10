tmath_diagram_sources = files(
    'tmathDiagram.cpp',
    'tmathDiagramAudit.cpp',
)
tmath_diagram_dependencies = []
if lua_enabled
    tmath_diagram_sources += files('tmathDiagramLua.cpp')
    tmath_diagram_dependencies += lua_dep
else
    tmath_diagram_sources += files('tmathDiagramLuaStub.cpp')
endif
tmath_diagram_lib = static_library(
    'tmath-diagram',
    tmath_diagram_sources,
    include_directories: include_directories('../../inc', '../lua'),
    dependencies: tmath_diagram_dependencies,
    install: true,
)
tmath_diagram_dep = declare_dependency(
    link_with: tmath_diagram_lib,
    include_directories: include_directories('../../inc'),
    dependencies: tmath_dep,
)
install_headers('../../inc/tmath_diagram.h')
