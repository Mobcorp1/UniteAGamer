#!/usr/bin/env python3
from __future__ import annotations

import re
import shutil
from pathlib import Path

ROOT = Path.cwd()
BACKUP = ROOT / 'stackfit_expand_backups'

TARGETS = [
    ROOT / 'lib/screens/build/auth/auth_landing_screen.dart',
    ROOT / 'lib/build/auth/auth_screen.dart',
    ROOT / 'lib/screens/build/app_entry_gate.dart',
    ROOT / 'lib/build/home_screen.dart',
    ROOT / 'lib/build/trading_hub_screen.dart',
    ROOT / 'lib/features/trading_hub/trading_hub_screen.dart',
]

# Also patch every Dart file under the ARC Raiders feature area because many screens use
# Stack + Positioned.fill watermarks. StackFit.loose lets the Stack shrink to the first
# non-positioned child on web, leaving the rest of the browser as plain scaffold background.
ARC_DIR = ROOT / 'lib/features/trading_hub/arc_raiders'
if ARC_DIR.exists():
    TARGETS.extend(sorted(ARC_DIR.rglob('*.dart')))


def backup(path: Path) -> None:
    rel = path.relative_to(ROOT)
    dest = BACKUP / rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    if not dest.exists():
        shutil.copy2(path, dest)


def patch_stack_fit(text: str) -> tuple[str, int]:
    # Handles:
    # Stack(
    #   children:
    # Stack(
    #   children: const
    # Stack(children:
    # Avoids stacks already patched with fit: StackFit.expand.
    pattern = re.compile(r"Stack\(\s*(?!fit\s*:)children\s*:", re.MULTILINE)
    text, count = pattern.subn("Stack(\n        fit: StackFit.expand,\n        children:", text)
    return text, count


def patch_web_index() -> None:
    path = ROOT / 'web/index.html'
    if not path.exists():
        return
    original = path.read_text(encoding='utf-8')
    text = original
    required = """
  <style id="uag-web-fullscreen-guard">
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
      overscroll-behavior: none;
      touch-action: manipulation;
    }
    flutter-view,
    flt-glass-pane,
    flutter-view > flt-glass-pane,
    flt-scene-host,
    flt-scene,
    flt-platform-view,
    canvas {
      width: 100vw !important;
      height: 100vh !important;
      min-width: 100vw !important;
      min-height: 100vh !important;
      display: block !important;
    }
  </style>
"""
    if 'uag-web-fullscreen-guard' not in text:
        text = text.replace('</head>', required + '\n</head>')
    if text != original:
        backup(path)
        path.write_text(text, encoding='utf-8')
        print('PATCHED web/index.html fullscreen guard')
    else:
        print('OK web/index.html fullscreen guard already present')


def main() -> None:
    if not (ROOT / 'pubspec.yaml').exists():
        raise RuntimeError('Run from project root: C:\\Users\\mikem\\uag_traders_hub')

    seen = set()
    total_files = 0
    total_replacements = 0

    for path in TARGETS:
        if not path.exists() or path in seen:
            continue
        seen.add(path)
        original = path.read_text(encoding='utf-8')
        patched, count = patch_stack_fit(original)
        if count > 0 and patched != original:
            backup(path)
            path.write_text(patched, encoding='utf-8')
            total_files += 1
            total_replacements += count
            print(f'PATCHED {path.relative_to(ROOT)} ({count} Stack widgets)')

    patch_web_index()

    print('')
    print(f'DONE: patched {total_replacements} Stack widgets across {total_files} files.')
    print(f'Backups saved to: {BACKUP.relative_to(ROOT)}')
    print('')
    print('Reason fixed: Flutter Stack defaults to StackFit.loose. On web, any page using')
    print('Positioned.fill inside a loose Stack can shrink to the content width, making')
    print('the app appear trapped on the left side of the browser.')

if __name__ == '__main__':
    main()
