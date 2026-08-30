import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PASS 349 live scanner returns canonical decisions directly', () {
    final s = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_blueprint_live_scanner_screen.dart',
    ).readAsStringSync();
    expect(s, contains('ArcBlueprintLiveScanResultEngine'));
    expect(s, contains('decisions: decisionResult.decisions'));
  });
  test('PASS 349 live result bypasses photo re-analysis', () {
    final s = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_blueprint_photo_capture_screen.dart',
    ).readAsStringSync();
    expect(s, contains('_reviewLiveScannerResult'));
    expect(s, contains('result.decisions'));
    expect(s, isNot(contains("topFileName: 'blueprint_grid_top.jpg'")));
  });
  test('PASS 349 scanner UI has no mojibake', () {
    final s = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_blueprint_live_scanner_screen.dart',
    ).readAsStringSync();
    expect(s, isNot(contains('Ã')));
    expect(s, contains('Live scan - rows 1-5'));
    expect(s, contains('Live scan - next section'));
  });
}
