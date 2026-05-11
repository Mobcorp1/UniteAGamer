#!/usr/bin/env python3
from __future__ import annotations

import re
import shutil
from pathlib import Path

ROOT = Path.cwd()
BACKUP = ROOT / "_patch_backups" / "tracker_qa_patch"

BLUEPRINT_SHEET = ROOT / "lib/features/trading_hub/arc_raiders/widgets/arc_blueprint_drop_report_sheet.dart"
SCRAPPY_SCREEN = ROOT / "lib/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart"
SCRAPPY_MENU = ROOT / "lib/features/trading_hub/arc_raiders/widgets/scrappy_actions_menu.dart"
PUBSPEC = ROOT / "pubspec.yaml"


def backup(path: Path) -> None:
    if not path.exists():
        raise FileNotFoundError(f"Required file not found: {path}")
    target = BACKUP / path.relative_to(ROOT)
    target.parent.mkdir(parents=True, exist_ok=True)
    if not target.exists():
        shutil.copy2(path, target)


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def write(path: Path, text: str) -> None:
    path.write_text(text, encoding="utf-8")


def find_matching_brace(text: str, open_pos: int) -> int:
    depth = 0
    in_single = False
    in_double = False
    in_line_comment = False
    in_block_comment = False
    escape = False

    i = open_pos
    while i < len(text):
        ch = text[i]
        nxt = text[i + 1] if i + 1 < len(text) else ""

        if in_line_comment:
            if ch == "\n":
                in_line_comment = False
            i += 1
            continue
        if in_block_comment:
            if ch == "*" and nxt == "/":
                in_block_comment = False
                i += 2
                continue
            i += 1
            continue
        if in_single:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == "'":
                in_single = False
            i += 1
            continue
        if in_double:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_double = False
            i += 1
            continue

        if ch == "/" and nxt == "/":
            in_line_comment = True
            i += 2
            continue
        if ch == "/" and nxt == "*":
            in_block_comment = True
            i += 2
            continue
        if ch == "'":
            in_single = True
            i += 1
            continue
        if ch == '"':
            in_double = True
            i += 1
            continue
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return i
        i += 1

    raise RuntimeError("Could not find matching brace")


def replace_method(text: str, method_name: str, replacement: str) -> tuple[str, bool]:
    pattern = re.compile(r"(?:Future<[^>]+>|Future|void|int|bool|String|ArcBlueprintState)\s+" + re.escape(method_name) + r"\s*\([^)]*\)\s*(?:async\s*)?\{", re.DOTALL)
    match = pattern.search(text)
    if not match:
        return text, False
    open_pos = text.find("{", match.start())
    close_pos = find_matching_brace(text, open_pos)
    return text[: match.start()] + replacement + text[close_pos + 1 :], True


def patch_pubspec() -> None:
    backup(PUBSPEC)
    text = read(PUBSPEC)
    if "assets/arc_raiders/items/" not in text:
        marker = "    - assets/arc_raiders/scrappy_resources/"
        if marker not in text:
            raise RuntimeError("Could not find scrappy_resources asset entry in pubspec.yaml")
        text = text.replace(marker, marker + "\n    - assets/arc_raiders/items/")
        write(PUBSPEC, text)
        print("OK pubspec.yaml: added assets/arc_raiders/items/")
    else:
        print("SKIP pubspec.yaml: items folder already registered")


def patch_blueprint_report_sheet() -> None:
    backup(BLUEPRINT_SHEET)
    text = read(BLUEPRINT_SHEET)
    if "UAG_PATCH_NO_AUTO_DUPE_ON_REPORT" in text:
        print("SKIP blueprint report sheet: no-auto-dupe patch already present")
        return

    replacement = """ArcBlueprintState _stateAfterFound({
    required ArcBlueprintState current,
    bool isPrimary = false,
  }) {
    // UAG_PATCH_NO_AUTO_DUPE_ON_REPORT
    // Posting a drop report must never create a duplicate by itself.
    // Dupes only change when the user explicitly enters a dupes value.
    if (isPrimary) {
      final manualDupes = _currentDupes;
      final nextDupes = manualDupes > current.dupesOwned
          ? manualDupes
          : current.dupesOwned;
      return current.copyWith(
        owned: true,
        dupesOwned: nextDupes,
        updatedAt: DateTime.now(),
      );
    }

    return current.copyWith(
      owned: true,
      dupesOwned: current.dupesOwned,
      updatedAt: DateTime.now(),
    );
  }"""

    text, changed = replace_method(text, "_stateAfterFound", replacement)
    if not changed:
        raise RuntimeError("Could not find _stateAfterFound in arc_blueprint_drop_report_sheet.dart")
    write(BLUEPRINT_SHEET, text)
    print("OK blueprint report sheet: drop reports no longer auto-add duplicates")


def patch_scrappy_actions_menu() -> None:
    backup(SCRAPPY_MENU)
    text = read(SCRAPPY_MENU)
    if "onShareMissing" in text and "Share Missing" in text:
        print("SKIP scrappy actions menu: share action already present")
        return

    # Constructor: add required onShareMissing before onResetGrid.
    text = text.replace(
        "const ScrappyActionsMenu({\n\n  super.key,\n\n  required this.onResetGrid,",
        "const ScrappyActionsMenu({\n\n  super.key,\n\n  required this.onShareMissing,\n\n  required this.onResetGrid,",
    )
    text = text.replace(
        "final VoidCallback onResetGrid;",
        "final VoidCallback onShareMissing;\n\n  final VoidCallback onResetGrid;",
    )

    # onSelected: add share branch before reset.
    text = text.replace(
        "if (value == 'reset') {\n\n  onResetGrid();\n\n  }",
        "if (value == 'share') {\n\n  onShareMissing();\n\n  return;\n\n  }\n\n  if (value == 'reset') {\n\n  onResetGrid();\n\n  }",
    )

    share_item = """PopupMenuItem<String>(

  value: 'share',

  child: Row(

  children: [

  Icon(

  Icons.ios_share_rounded,

  color: AppTheme.neonCyan.withValues(alpha: 0.92),

  ),

  const SizedBox(width: 10),

  Text(

  'Share Missing',

  style: AppTheme.bodyTextStyle(

  fontSize: 14,

  color: Colors.white,

  isBold: true,

  ),

  ),

  ],

  ),

  ),

  const PopupMenuDivider(),

  """
    text = text.replace("itemBuilder: (context) => [\n", "itemBuilder: (context) => [\n" + share_item, 1)

    if "onShareMissing" not in text or "Share Missing" not in text:
        raise RuntimeError("Could not patch scrappy_actions_menu.dart cleanly")
    write(SCRAPPY_MENU, text)
    print("OK scrappy actions menu: added Share Missing action")


def patch_scrappy_grid_screen() -> None:
    backup(SCRAPPY_SCREEN)
    text = read(SCRAPPY_SCREEN)

    if "package:share_plus/share_plus.dart" not in text:
        # Add after flutter import.
        text = text.replace(
            "import 'package:flutter/material.dart';",
            "import 'package:flutter/material.dart';\nimport 'package:share_plus/share_plus.dart';",
            1,
        )

    if "UAG_PATCH_SHARE_MISSING_TRACKER" not in text:
        method = """Future<void> _shareMissingList() async {
    // UAG_PATCH_SHARE_MISSING_TRACKER
    final items = _allItems;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to share yet.')),
      );
      return;
    }

    try {
      final states = await _repository.watchMyScrappyStates().first;
      final missing = items.where((item) {
        final state = states[item.id] ?? ArcScrappyState.empty(item.id);
        return state.collectedCount < item.neededCount;
      }).toList(growable: false);

      final title = switch (_mode) {
        ArcScrappyTrackerMode.scrappy => 'Scrappy Tracker',
        ArcScrappyTrackerMode.bench => 'Bench Tracker',
        ArcScrappyTrackerMode.quest => 'Quest Tracker',
      };

      final buffer = StringBuffer()
        ..writeln('ARC Raiders - $title')
        ..writeln('Here is what I am still looking for:')
        ..writeln();

      if (missing.isEmpty) {
        buffer.writeln('Nothing missing right now. Tracker is complete.');
      } else {
        for (final item in missing.take(80)) {
          final state = states[item.id] ?? ArcScrappyState.empty(item.id);
          final remaining = (item.neededCount - state.collectedCount).clamp(1, 9999);
          buffer.writeln('• ${item.name} x$remaining');
        }
        if (missing.length > 80) {
          buffer.writeln();
          buffer.writeln('+ ${missing.length - 80} more items');
        }
      }

      buffer
        ..writeln()
        ..writeln('Shared from UAG Traders Hub.');

      await Share.share(buffer.toString().trim());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not build share list: $e')),
      );
    }
  }

  """
        # Insert before existing reset method. It exists in current repo and is stable.
        marker = "Future<void> _confirmResetGrid() async {"
        idx = text.find(marker)
        if idx == -1:
            raise RuntimeError("Could not find _confirmResetGrid in scrappy_grid_screen.dart")
        text = text[:idx] + method + text[idx:]

    # Wire menu callback.
    old = "actions: [ScrappyActionsMenu(onResetGrid: _confirmResetGrid)]"
    new = "actions: [\n    ScrappyActionsMenu(\n      onShareMissing: _shareMissingList,\n      onResetGrid: _confirmResetGrid,\n    ),\n  ]"
    if old in text:
        text = text.replace(old, new, 1)
    elif "onShareMissing: _shareMissingList" not in text:
        # tolerate formatting variation
        text = re.sub(
            r"ScrappyActionsMenu\(\s*onResetGrid:\s*_confirmResetGrid\s*\)",
            "ScrappyActionsMenu(onShareMissing: _shareMissingList, onResetGrid: _confirmResetGrid)",
            text,
            count=1,
        )

    if "onShareMissing: _shareMissingList" not in text:
        raise RuntimeError("Could not wire ScrappyActionsMenu in scrappy_grid_screen.dart")

    write(SCRAPPY_SCREEN, text)
    print("OK scrappy grid screen: added WhatsApp/share missing list")


def main() -> None:
    BACKUP.mkdir(parents=True, exist_ok=True)
    patch_pubspec()
    patch_blueprint_report_sheet()
    patch_scrappy_actions_menu()
    patch_scrappy_grid_screen()
    print(f"Backups saved to: {BACKUP}")


if __name__ == "__main__":
    main()
