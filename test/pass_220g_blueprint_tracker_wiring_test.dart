import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('PASS 220 routes missing tile taps through owned/report/dupe flow', () {
    final grid = read(
      'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart',
    );

    final directTapFlow = RegExp(
      r'if \(!state\.owned\)\s*\{\s*await _markMissingAsOwned\(blueprint, state\);\s*return;\s*\}\s*await _openBlueprintPreview\(blueprint, state\);',
      multiLine: true,
    );

    expect(directTapFlow.allMatches(grid), hasLength(2));
    expect(grid, contains("title: 'Add drop report?'"));
    expect(grid, contains("title: 'Add duplicates?'"));
    expect(
      grid,
      contains('await _blueprintRepository.saveBlueprintState(ownedState);'),
    );
  });

  test(
    'PASS 220G mounts tracker summary without blocking compact landscape tools',
    () {
      final grid = read(
        'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart',
      );
      final header = read(
        'lib/features/trading_hub/arc_raiders/widgets/blueprint_progress_header.dart',
      );

      expect(grid, contains("widgets/blueprint_progress_header.dart"));
      expect(grid, contains('bool _showProgressHeader = true;'));
      expect(grid, contains('BlueprintProgressHeader('));
      expect(
        grid,
        contains('onClose: () => setState(() => _showProgressHeader = false),'),
      );
      expect(grid, contains('final compactBlueprintToolsLandscape ='));
      expect(
        grid,
        contains(
          'if (_showProgressHeader && !compactBlueprintToolsLandscape) ...[',
        ),
      );

      final searchIndex = grid.indexOf('_buildSearchAppBarTitle()');
      final filtersIndex = grid.indexOf(
        'for (final filter in ArcBlueprintFilter.values)',
      );
      final mountedHeaderIndex = grid.indexOf('BlueprintProgressHeader(');
      expect(searchIndex, greaterThanOrEqualTo(0));
      expect(filtersIndex, greaterThan(searchIndex));
      expect(mountedHeaderIndex, greaterThan(filtersIndex));

      expect(header, contains('final VoidCallback? onClose;'));
      expect(header, contains("tooltip: 'Hide tracker card'"));
    },
  );

  test(
    'PASS 220 preserves multi-select row column and visible selection tools',
    () {
      final grid = read(
        'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart',
      );

      expect(grid, contains("'Select All Visible'"));
      expect(grid, contains("'Select Row'"));
      expect(grid, contains("'Select Column'"));
      expect(grid, contains('void _selectAll(List<ArcBlueprint> filtered)'));
      expect(
        grid,
        contains('Future<void> _selectRow(List<ArcBlueprint> filtered)'),
      );
      expect(
        grid,
        contains('Future<void> _selectColumn(List<ArcBlueprint> filtered)'),
      );
    },
  );

  test('PASS 220 preserves locked Blueprint grid and ad invariants', () {
    final grid = read(
      'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart',
    );
    final tile = read(
      'lib/features/trading_hub/arc_raiders/widgets/blueprint_tile.dart',
    );

    expect(grid, contains('static const int _gridColumns = 10;'));
    expect(grid, contains('int sumDupesOwned()'));
    expect(grid, contains('ArcBlueprintGridViewMode.inGameFramed'));
    expect(grid, contains("Key('blueprint-landscape-static-ad')"));
    expect(
      grid,
      contains('widget.bannerSlot ?? const ArcBlueprintBannerSlot()'),
    );
    expect(grid, contains('InteractiveViewer('));
    expect(grid, contains("tooltip: 'Reset grid view'"));
    expect(grid, contains('_openBlueprintPhotoImport'));

    // Keep the already-tightened portrait tile footprint from the certified base.
    expect(tile, contains('landscape ? 3 : 4'));
    expect(tile, contains('(landscape ? 9 : 10) * contentScale'));
  });
}
