import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) =>
      File(path).readAsStringSync().replaceAll('\r\n', '\n');

  String compact(String source) {
    return source.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  test('Blueprint tracker exposes SCAN/UPDATE as the same camera action', () {
    final source = read(
      'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart',
    );
    final normalized = compact(source);

    expect(
      normalized,
      contains("label: hasOwnedBlueprints ? 'UPDATE' : 'SCAN'"),
    );
    expect(normalized, contains("'Update Blueprint ownership from game'"));
    expect(normalized, contains("'Scan Blueprint grid from game'"));
    expect(normalized, contains('primaryCameraAction: true'));
    expect(
      normalized,
      contains('AppTheme.neonPink.withValues( alpha: enabled ? 0.92 : 0.32, )'),
    );
    expect(
      normalized,
      contains('AppTheme.neonCyan.withValues( alpha: enabled ? 0.95 : 0.35, )'),
    );
  });

  test('landscape viewport hugs the fitted Blueprint grid width', () {
    final source = read(
      'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart',
    );

    expect(source, contains('final viewportWidth = fittedWidth;'));
    expect(source, contains('const commandRailWidth = 132.0;'));
    expect(source, contains('mainAxisSize: MainAxisSize.min'));
    expect(
      source,
      isNot(contains('SizedBox(width: availableGridWidth, child: viewport)')),
    );
  });

  test('live scanner shutter uses pink fill with cyan outline and icon', () {
    final source = read(
      'lib/features/trading_hub/arc_raiders/screens/arc_blueprint_live_scanner_screen.dart',
    );

    expect(
      source,
      contains(
        "key: const Key(\n                                  'blueprint-live-scanner-capture',",
      ),
    );
    expect(source, contains('backgroundColor: AppTheme.neonPink'));
    expect(source, contains('foregroundColor: AppTheme.neonCyan'));
    expect(
      source,
      contains(
        'color: AppTheme.neonCyan.withValues(\n                                      alpha: 0.96,',
      ),
    );
  });

  test(
    'completed second capture shows Blueprint processing state, not black',
    () {
      final source = read(
        'lib/features/trading_hub/arc_raiders/screens/arc_blueprint_live_scanner_screen.dart',
      );

      expect(source, contains('_captureSession.isComplete'));
      expect(source, contains('const _BlueprintScannerProcessingState()'));
      expect(source, contains("'SCANNING BLUEPRINT GRID'"));
      expect(
        source,
        contains(
          "'Checking grid positions and preparing your Blueprint update...'",
        ),
      );
      expect(source, contains('LinearProgressIndicator('));
    },
  );
}
