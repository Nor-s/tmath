miniaudio_project = subproject('miniaudio')
miniaudio_lib = miniaudio_project.get_variable('miniaudio_lib')
miniaudio_include = miniaudio_project.get_variable('miniaudio_include')
miniaudio_args = miniaudio_project.get_variable('miniaudio_args')
miniaudio_system_deps = miniaudio_project.get_variable('miniaudio_system_deps')
miniaudio_license = miniaudio_project.get_variable('miniaudio_license')
tmath_audio_sources = files('tmathAudio.cpp', 'tmathAudioPlayer.cpp')
tmath_audio_dependencies = [tmath_dep]
if lua_enabled
    tmath_audio_sources += files('tmathAudioLua.cpp')
    tmath_audio_dependencies += lua_dep
else
    tmath_audio_sources += files('tmathAudioLuaStub.cpp')
endif
tmath_audio_lib = static_library(
    'tmath-audio',
    tmath_audio_sources,
    include_directories: [
        include_directories('../../inc', '../lua'),
        miniaudio_include,
    ],
    dependencies: tmath_audio_dependencies,
    cpp_args: miniaudio_args,
    link_whole: miniaudio_lib,
    install: true,
)
tmath_audio_dep = declare_dependency(
    link_with: tmath_audio_lib,
    include_directories: include_directories('../../inc'),
    dependencies: [tmath_dep] + miniaudio_system_deps,
)
install_headers('../../inc/tmath_audio.h')
install_data(
    miniaudio_license,
    install_dir: get_option('datadir') / 'licenses' / 'tmath-audio',
    rename: 'LICENSE-miniaudio.txt',
)
