from __future__ import annotations
import re
from pathlib import Path

ROOT = Path.cwd()


def read(path: Path) -> str:
    return path.read_text(encoding='utf-8')


def write(path: Path, text: str) -> None:
    path.write_text(text, encoding='utf-8')
    print(f'PATCHED {path.relative_to(ROOT)}')


def patch_analysis_options() -> None:
    path = ROOT / 'analysis_options.yaml'
    if not path.exists():
        text = "include: package:flutter_lints/flutter.yaml\n\nanalyzer:\n  exclude:\n    - '**/_patch_backups/**'\n    - '**/_patch_backups_safe/**'\n    - '**/_patch_recovery_backups/**'\n    - '**/repair_backups/**'\n    - '**/.uag_patch_backups/**'\n"
        write(path, text)
        return
    text = read(path)
    excludes = [
        "    - '**/_patch_backups/**'",
        "    - '**/_patch_backups_safe/**'",
        "    - '**/_patch_recovery_backups/**'",
        "    - '**/repair_backups/**'",
        "    - '**/.uag_patch_backups/**'",
    ]
    if 'analyzer:' not in text:
        text += "\nanalyzer:\n  exclude:\n" + "\n".join(excludes) + "\n"
    elif 'exclude:' not in text:
        text += "\n  exclude:\n" + "\n".join(excludes) + "\n"
    else:
        for ex in excludes:
            if ex not in text:
                text += ex + "\n"
    write(path, text)


def patch_web_index() -> None:
    path = ROOT / 'web' / 'index.html'
    if not path.exists():
        print('SKIP web/index.html not found')
        return
    text = read(path)
    css = '''
  <style id="uag-full-viewport-fix">
    html, body {
      width: 100%;
      height: 100%;
      min-width: 100%;
      min-height: 100%;
      margin: 0;
      padding: 0;
      overflow: hidden;
      background: #090529;
    }

    body {
      position: fixed;
      inset: 0;
    }

    #flutter_target,
    flutter-view,
    flt-glass-pane,
    flt-scene-host,
    flt-scene,
    flt-canvas,
    canvas {
      width: 100% !important;
      height: 100% !important;
      min-width: 100% !important;
      min-height: 100% !important;
      max-width: none !important;
      max-height: none !important;
      display: block !important;
    }
  </style>
'''
    if 'uag-full-viewport-fix' not in text:
        if '</head>' in text:
            text = text.replace('</head>', css + '\n</head>', 1)
        else:
            text = css + text
    write(path, text)


def patch_main_builder() -> None:
    path = ROOT / 'lib' / 'main.dart'
    text = read(path)
    if 'UAG_FORCE_FULL_VIEWPORT_BUILDER' not in text:
        needle = "      onGenerateRoute: _buildRoute,\n"
        insert = """      // UAG_FORCE_FULL_VIEWPORT_BUILDER\n      builder: (context, child) {\n        return SizedBox.expand(\n          child: DecoratedBox(\n            decoration: const BoxDecoration(color: AppTheme.darkBackground),\n            child: child ?? const SizedBox.shrink(),\n          ),\n        );\n      },\n"""
        if needle in text:
            text = text.replace(needle, needle + insert, 1)
        else:
            text = re.sub(r"MaterialApp\(\s*", "MaterialApp(\n" + insert, text, count=1)
    # Clean the one-line route import/route formatting if generated patch left it ugly.
    text = text.replace("import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/play_like_a_pro_screen.dart'; import 'package:uag_traders_hub/features/trading_hub/arc_raiders/session_planner/session_planner_screen.dart';", "import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/play_like_a_pro_screen.dart';\nimport 'package:uag_traders_hub/features/trading_hub/arc_raiders/session_planner/session_planner_screen.dart';")
    text = text.replace("case SessionPlannerScreen.routeName: return MaterialPageRoute( builder: (_) => const FeatureAccessRouteGate( flag: FeatureAccessFlag.traderHub, title: 'Session Planner', child: SessionPlannerScreen(), ), settings: settings, ); case TraderHubScreen.routeName:", """case SessionPlannerScreen.routeName:\n        return MaterialPageRoute(\n          builder: (_) => const FeatureAccessRouteGate(\n            flag: FeatureAccessFlag.traderHub,\n            title: 'Session Planner',\n            child: SessionPlannerScreen(),\n          ),\n          settings: settings,\n        );\n\n      case TraderHubScreen.routeName:""")
    write(path, text)


def add_stack_fit_expand_to_file(path: Path) -> bool:
    text = read(path)
    original = text
    # Only patch files likely to be full-screen shell/auth/home screens.
    likely = any(part in str(path).replace('\\','/') for part in [
        'build/auth', 'screens/build', 'build/home_screen.dart', 'widgets/static_watermark.dart'
    ])
    if not likely:
        return False
    # Add fit only to Stack calls missing immediate fit in first argument block.
    text = re.sub(r"Stack\(\s*children\s*:", "Stack(\n      fit: StackFit.expand,\n      children:", text)
    text = re.sub(r"Stack\(\s*alignment\s*:", "Stack(\n      fit: StackFit.expand,\n      alignment:", text)
    if text != original:
        write(path, text)
        return True
    return False


def patch_common_shell_constraints() -> None:
    patched = 0
    for path in (ROOT / 'lib').rglob('*.dart'):
        if add_stack_fit_expand_to_file(path):
            patched += 1
    print(f'Stack full-screen shell files patched: {patched}')


def main() -> None:
    if not (ROOT / 'pubspec.yaml').exists():
        raise SystemExit('Run from Flutter project root.')
    patch_analysis_options()
    patch_web_index()
    patch_main_builder()
    patch_common_shell_constraints()
    print('WEB LAYOUT FORCE FIX COMPLETE')

if __name__ == '__main__':
    main()
