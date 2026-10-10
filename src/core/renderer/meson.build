tmath_inc += include_directories('.', 'tvg')
tmath_sources += files(
    'tmathDisplayList.cpp',
    'tmathRenderer.cpp',
    'tmathRendererData.cpp',
    'tvg/tmathTvgRenderer.cpp',
)

# Disabled engines link a stub so the backend table stays complete.
if cpu_enabled
    tmath_sources += files('tvg/tmathTvgSwRenderer.cpp')
else
    tmath_sources += files('tvg/tmathTvgSwRendererStub.cpp')
endif
if gl_enabled
    tmath_sources += files('tvg/tmathTvgGlRenderer.cpp')
else
    tmath_sources += files('tvg/tmathTvgGlRendererStub.cpp')
endif
