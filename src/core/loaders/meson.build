tmath_inc += include_directories('.')
tmath_sources += files('tmathAssetLoader.cpp')

# ThorVG-backed asset decoding is only available with the CPU engine.
if cpu_enabled
    tmath_sources += files('tvg/tmathTvgAssetDecoder.cpp')
else
    tmath_sources += files('tvg/tmathTvgAssetDecoderStub.cpp')
endif
