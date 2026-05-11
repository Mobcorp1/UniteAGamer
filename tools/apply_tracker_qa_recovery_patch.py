#!/usr/bin/env python3
from __future__ import annotations

import re
import shutil
import sys
import urllib.request
from pathlib import Path

ROOT = Path.cwd()
BASE = "https://raw.githubusercontent.com/Mobcorp1/UniteAGamer/main/"
FILES_TO_RESTORE = [
    "lib/features/trading_hub/arc_raiders/widgets/arc_blueprint_drop_report_sheet.dart",
    "lib/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart",
    "lib/features/trading_hub/arc_raiders/widgets/scrappy_actions_menu.dart",
]

STATE_AFTER_FOUND_REPLACEMENT = """ArcBlueprintState _stateAfterFound({
    required ArcBlueprintState current,
    bool isPrimary = false,
  }) {
    if (isPrimary) {
      final manualDupes = _currentDupes;
      return current.copyWith(
        owned: true,
        dupesOwned: manualDupes,
        updatedAt: DateTime.now(),
      );
    }

    if (current.owned) {
      return current.copyWith(
        owned: true,
        dupesOwned: current.dupesOwned + 1,
        updatedAt: DateTime.now(),
      );
    }

    return current.copyWith(
      owned: true,
      dupesOwned: current.dupesOwned,
      updatedAt: DateTime.now(),
    );
  }

  Future"""


def download_text(rel_path: str) -> str:
    url = BASE + rel_path
    with urllib.request.urlopen(url, timeout=60) as response:
        data = response.read()
    return data.decode("utf-8")


def backup_file(path: Path) -> None:
    if not path.exists():
        return
    rel = path.relative_to(ROOT)
    backup = ROOT / "_patch_recovery_backups" / rel
    backup.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, backup)


def restore_from_github(rel_path: str) -> None:
    dest = ROOT / rel_path
    dest.parent.mkdir(parents=True, exist_ok=True)
    backup_file(dest)
    text = download_text(rel_path)
    dest.write_text(text, encoding="utf-8")
    print(f"RESTORED {rel_path}")


def patch_blueprint_report_sheet() -> None:
    path = ROOT / "lib/features/trading_hub/arc_raiders/widgets/arc_blueprint_drop_report_sheet.dart"
    text = path.read_text(encoding="utf-8")
    patched, count = re.subn(
        r"ArcBlueprintState\s+_stateAfterFound\s*\(\s*\{\s*required\s+ArcBlueprintState\s+current,\s*bool\s+isPrimary\s*=\s*false,\s*\}\s*\)\s*\{.*?\}\s*Future",
        STATE_AFTER_FOUND_REPLACEMENT,
        text,
        count=1,
        flags=re.DOTALL,
    )
    if count != 1:
        raise RuntimeError("Could not safely replace _stateAfterFound in arc_blueprint_drop_report_sheet.dart")
    path.write_text(patched, encoding="utf-8")
    print("PATCHED blueprint report duplicate handling")


def patch_pubspec_assets() -> None:
    path = ROOT / "pubspec.yaml"
    if not path.exists():
        print("SKIP pubspec.yaml not found")
        return
    text = path.read_text(encoding="utf-8")
    if "assets/arc_raiders/items/" in text:
        print("OK pubspec already includes assets/arc_raiders/items/")
        return
    marker = "    - assets/arc_raiders/scrappy_resources/"
    if marker not in text:
        raise RuntimeError("Could not find scrappy_resources asset entry in pubspec.yaml")
    backup_file(path)
    text = text.replace(marker, marker + "\n    - assets/arc_raiders/items/", 1)
    path.write_text(text, encoding="utf-8")
    print("PATCHED pubspec assets/arc_raiders/items/")


def remove_old_patch_backups() -> None:
    path = ROOT / "_patch_backups"
    if path.exists():
        shutil.rmtree(path)
        print("REMOVED _patch_backups so flutter analyze stops scanning backup Dart files")
    else:
        print("OK no _patch_backups folder found")


def main() -> int:
    if not (ROOT / "pubspec.yaml").exists():
        print("ERROR: Run this from your project root: C:\\Users\\mikem\\uag_traders_hub")
        return 1

    remove_old_patch_backups()

    for rel in FILES_TO_RESTORE:
        restore_from_github(rel)

    patch_blueprint_report_sheet()
    patch_pubspec_assets()

    print("\nRECOVERY PATCH COMPLETE")
    print("Backups of changed files are in: _patch_recovery_backups")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
