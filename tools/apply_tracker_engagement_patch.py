from __future__ import annotations

import re
from pathlib import Path

ROOT = Path.cwd()

BLUEPRINT_GRID = ROOT / 'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart'
BLUEPRINT_SHEET = ROOT / 'lib/features/trading_hub/arc_raiders/widgets/arc_blueprint_drop_report_sheet.dart'
SCRAPPY_GRID = ROOT / 'lib/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart'


def read(path: Path) -> str:
    if not path.exists():
        raise FileNotFoundError(f'Missing required file: {path}')
    return path.read_text(encoding='utf-8')


def write(path: Path, text: str) -> None:
    path.write_text(text, encoding='utf-8')


def add_import(text: str, import_line: str) -> str:
    if import_line in text:
        return text
    first_import_match = re.search(r"import 'package:flutter/material\.dart';", text)
    if not first_import_match:
        raise RuntimeError('Could not find flutter/material import anchor.')
    return text[:first_import_match.end()] + ' ' + import_line + text[first_import_match.end():]


def patch_blueprint_report_sheet() -> None:
    text = read(BLUEPRINT_SHEET)
    old = text

    replacement = """ArcBlueprintState _stateAfterFound({ required ArcBlueprintState current, bool isPrimary = false, }) { final explicitDupes = isPrimary ? _currentDupes : current.dupesOwned; final nextDupes = explicitDupes > current.dupesOwned ? explicitDupes : current.dupesOwned; return current.copyWith( owned: true, dupesOwned: nextDupes, updatedAt: DateTime.now(), ); } Future _loadCurrentBlueprintState"""

    text, count = re.subn(
        r"ArcBlueprintState _stateAfterFound\(\{.*?\}\s*Future _loadCurrentBlueprintState",
        replacement,
        text,
        count=1,
        flags=re.DOTALL,
    )
    if count != 1:
        raise RuntimeError('Could not patch _stateAfterFound in arc_blueprint_drop_report_sheet.dart')

    if text != old:
        write(BLUEPRINT_SHEET, text)
        print('PATCHED blueprint report duplicate logic')


def patch_blueprint_grid() -> None:
    text = read(BLUEPRINT_GRID)
    old = text
    text = add_import(text, "import 'package:share_plus/share_plus.dart';")

    if 'Future _shareMissingBlueprints() async' not in text:
        method = """
  Future _shareMissingBlueprints() async { final states = await _repository.watchMyBlueprintStates().first; final missing = ArcBlueprintSeedData.blueprints.where((blueprint) { final state = states[blueprint.id] ?? ArcBlueprintState.empty(blueprint.id); return !state.owned; }).toList(growable: false); final buffer = StringBuffer() ..writeln('ARC Raiders Blueprints I am still looking for:') ..writeln(); if (missing.isEmpty) { buffer.writeln('All blueprints complete.'); } else { for (final blueprint in missing) { buffer.writeln('• ${blueprint.name}'); } } buffer ..writeln() ..writeln('Sent from UAG Traders Hub'); await Share.share(buffer.toString(), subject: 'ARC Raiders missing blueprints'); }
"""
        anchor = 'Future _confirmResetGrid() async'
        if anchor not in text:
            raise RuntimeError('Could not find _confirmResetGrid anchor in blueprint_grid_screen.dart')
        text = text.replace(anchor, method + ' ' + anchor, 1)

    if "label: 'Share Missing'" not in text:
        text, count = re.subn(
            r"miniButton\( label: 'Reset All', onPressed: \(\) => _confirmResetGrid\(\), \),",
            "miniButton( label: 'Reset All', onPressed: () => _confirmResetGrid(), ), miniButton( label: 'Share Missing', onPressed: () => _shareMissingBlueprints(), ),",
            text,
            count=1,
        )
        if count != 1:
            raise RuntimeError('Could not insert Share Missing button into blueprint bottom controls.')

    if text != old:
        write(BLUEPRINT_GRID, text)
        print('PATCHED blueprint share missing button')


def patch_scrappy_grid() -> None:
    text = read(SCRAPPY_GRID)
    old = text
    text = add_import(text, "import 'package:share_plus/share_plus.dart';")

    if 'Future _shareMissingForCurrentTracker() async' not in text:
        method = """
  Future _shareMissingForCurrentTracker() async { final states = await _repository.watchMyScrappyStates().first; final items = _allItems; final missing = items.where((item) { final state = states[item.id] ?? ArcScrappyState.empty(item.id); return !state.ownedFor(item.neededCount); }).toList(growable: false); final buffer = StringBuffer() ..writeln('ARC Raiders ${_modeTitle} items I am still looking for:') ..writeln(); if (missing.isEmpty) { buffer.writeln('All ${_modeWord()} items complete.'); } else { for (final item in missing) { final state = states[item.id] ?? ArcScrappyState.empty(item.id); final remaining = item.neededCount - state.collectedCount; final safeRemaining = remaining < 1 ? 1 : remaining; buffer.writeln('• ${item.name} x$safeRemaining'); } } buffer ..writeln() ..writeln('Sent from UAG Traders Hub'); await Share.share(buffer.toString(), subject: 'ARC Raiders ${_modeTitle} missing items'); }
"""
        anchor = 'Future _confirmResetGrid() async'
        if anchor not in text:
            raise RuntimeError('Could not find _confirmResetGrid anchor in scrappy_grid_screen.dart')
        text = text.replace(anchor, method + ' ' + anchor, 1)

    if 'tooltip: \'Share missing\'' not in text and 'tooltip: "Share missing"' not in text:
        text, count = re.subn(
            r"actions: \[ScrappyActionsMenu\(onResetGrid: _confirmResetGrid\)\],",
            "actions: [ IconButton( tooltip: 'Share missing', onPressed: _shareMissingForCurrentTracker, icon: const Icon(Icons.ios_share_rounded), color: AppTheme.neonCyan, ), IconButton( tooltip: 'Reset tracker', onPressed: _confirmResetGrid, icon: const Icon(Icons.restart_alt_rounded), color: Colors.redAccent, ), ScrappyActionsMenu(onResetGrid: _confirmResetGrid), ],",
            text,
            count=1,
        )
        if count != 1:
            raise RuntimeError('Could not insert Scrappy app bar action buttons.')

    if text != old:
        write(SCRAPPY_GRID, text)
        print('PATCHED scrappy/bench/quest share + reset actions')


def main() -> None:
    patch_blueprint_report_sheet()
    patch_blueprint_grid()
    patch_scrappy_grid()
    print('\nDone. Now run:')
    print('  flutter clean')
    print('  flutter pub get')
    print('  flutter analyze')
    print('  flutter run -d chrome')


if __name__ == '__main__':
    main()
