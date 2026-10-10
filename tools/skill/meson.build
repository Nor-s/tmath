# Skill templates are checked through the CLI.
# Each entry: test-name suffix, template path, build condition, and whether to
# add a CPU render ('render') or a layout audit ('audit') test.
skill_templates = [
    {'name': '', 'src': 'tmath-skills/templates/core/scene.lua'},
    {'name': '-math-shortform-circle-wave-projections', 'src': 'tmath-skills/templates/math-shortform/circle-wave-projections.lua'},
    {'name': '-math-shortform-linear-space-transform', 'src': 'tmath-skills/templates/math-shortform/linear-space-transform.lua'},
    {'name': '-interactive-button-state-motion', 'src': 'tmath-game/templates/button-state-motion.lua', 'when': ui_enabled},
    {'name': '-interactive-ui-input-routing', 'src': 'tmath-game/templates/ui-input-routing.lua', 'when': ui_enabled and input_enabled},
    {'name': '-input-keyboard-object-motion', 'src': 'tmath-game/templates/keyboard-object-motion.lua', 'when': input_enabled},
    {
        'name': '-input-retained-lua-2d-game', 'src': 'tmath-game/templates/retained-lua-2d-game.lua',
        'when': input_enabled and lua_runtime_enabled, 'render': true,
    },
    {'name': '-diagram-causal-loop', 'src': 'tmath-skills/templates/diagram/causal-loop.lua'},
    {'name': '-diagram-swimlane', 'src': 'tmath-skills/templates/diagram/swimlane.lua', 'render': true},
    {
        'name': '-diagram-native', 'src': 'tmath-skills/templates/diagram/native-diagram.lua',
        'when': diagram_enabled, 'render': true,
        'audit': [
            '--require-containment-ledger',
            '--allow-uncontained', 'request-flow:edge:request:label',
            '--allow-uncontained', 'request-flow:edge:dispatch:label',
            '--allow-uncontained', 'request-flow:edge:persist:label',
        ],
    },
]

foreach t : skill_templates
    if t.get('when', true)
        name = 'skill-template' + t['name']
        template = files(t['src'])
        test(name, tmath_cli, args: ['inspect', template])
        if t.get('render', false) and cpu_enabled
            test(
                'render-' + name,
                tmath_cli,
                args: ['render', template, '--font', example_font, '-o', name + '.png'],
            )
        endif
        if t.has_key('audit') and audit_enabled
            test('audit-' + name, tmath_cli, args: ['audit', template, '--font', example_font] + t['audit'])
        endif
    endif
endforeach
