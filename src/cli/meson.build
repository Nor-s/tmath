# tmath CLI (inspect/render/layout, plus the optional layout audit).
# The executable itself is declared in the root meson.build as `tmath_cli`.
tmath_cli_sources = files('tmath.cpp')
tmath_cli_args = cpu_enabled ? ['-DTMATH_ENGINE_CPU'] : []
tmath_cli_args += tmath_module_args
tmath_cli_dependencies = [tmath_dep] + tmath_module_deps
tmath_cli_inc = include_directories('../core/lua', '../core/savers')

if audit_enabled
    tmath_cli_sources += files('tmathAudit.cpp')
    tmath_cli_args += '-DTMATH_AUDIT'
endif
