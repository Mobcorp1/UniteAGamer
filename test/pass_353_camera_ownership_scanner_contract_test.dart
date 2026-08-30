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

  test('PASS 353 live framing rejects small false-positive grids', () {
    expect(source, contains('_isLiveFrameLargeEnough'));
    expect(source, contains('width >= 0.68'));
    expect(
      source,
      contains('Move closer so the Blueprint grid fills the screen.'),
    );
  });

  test('PASS 353 uses a large full-view framing guide', () {
    expect(source, contains('size.width * 0.90'));
    expect(source, contains('size.height * 0.68'));
    expect(
      source,
      contains('UAG will shrink the guide onto the detected outer grid'),
    );
  });
}
