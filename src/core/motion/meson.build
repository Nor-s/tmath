tmath_motion_sources = files('tmathMotion.cpp')
tmath_motion_dependencies = []
if lua_enabled
    tmath_motion_sources += files('tmathMotionLua.cpp')
    tmath_motion_dependencies += lua_dep
else
    tmath_motion_sources += files('tmathMotionLuaStub.cpp')
endif
tmath_motion_lib = static_library(
    'tmath-motion',
    tmath_motion_sources,
    include_directories: include_directories(
        '../../inc', '../common', '../lua',
    ),
    dependencies: tmath_motion_dependencies,
    install: true,
)
tmath_motion_dep = declare_dependency(
    link_with: tmath_motion_lib,
    include_directories: include_directories('../../inc'),
    dependencies: tmath_dep,
)
install_headers('../../inc/tmath_motion.h')
