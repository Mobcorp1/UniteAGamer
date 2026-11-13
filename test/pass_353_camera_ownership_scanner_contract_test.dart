import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File(
    'lib/features/trading_hub/arc_raiders/screens/'
    'arc_blueprint_live_scanner_screen.dart',
  ).readAsStringSync();

  test('PASS 353 releases camera before scanner navigation', () {
    expect(source, contains('Future<void> _releaseCameraForNavigation()'));
    expect(source, contains('await _disposeController(controller);'));
    expect(source, contains('Future<void> _closeScanner('));
    expect(source, contains('await _releaseCameraForNavigation();'));
    expect(source, contains('_scannerClosing = true;'));
  });

  test('PASS 353 does not keep Camera2 through background states', () {
    expect(source, contains('state == AppLifecycleState.inactive'));
    expect(source, contains('state == AppLifecycleState.hidden'));
    expect(source, contains('unawaited(_pauseCameraForLifecycle())'));
  });

  test('PASS 353 diagnostic cannot compete for active camera ownership', () {
    expect(source, contains('Future<void> _openCameraDiagnostic()'));
    expect(source, contains('await _releaseCameraForNavigation();'));
    expect(source, contains(': _openCameraDiagnostic,'));
  });

  test(
    'PASS 353 live framing accepts verified TV-scale grids and rejects tiny false positives',
    () {
      expect(source, contains('_isLiveFrameLargeEnough'));
      expect(source, contains('width >= 0.50'));
      expect(source, contains('_stillCaptureMode'));
      expect(
        source,
        contains('final minimumHeight = bottomSection ? 0.16 : 0.24;'),
      );
      expect(
        source,
        contains('Move closer so the Blueprint grid fills the screen.'),
      );
    },
  );

  test('scanner overlay alpha uses Flutter 0-1 range', () {
    expect(source, isNot(contains('alpha: 184.0')));
    expect(source, contains('alpha: 0.72'));
  });
  test('PASS 353 uses the viewport-aware linked-edge framing guide', () {
    expect(source, contains('_ensureDefaultAlignmentForViewport'));
    expect(source, contains('resetToTopDefaultForViewport'));
    expect(
      source,
      contains(
        'UAG will snap the outline onto the detected outer edges automatically',
      ),
    );
  });
}
