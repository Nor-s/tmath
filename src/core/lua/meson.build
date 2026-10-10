tmath_inc += include_directories('.')

if lua_enabled
    tmath_sources += files('tmathLua.cpp')
    tmath_dependencies += lua_dep
else
    tmath_sources += files('tmathLuaStub.cpp')
endif
