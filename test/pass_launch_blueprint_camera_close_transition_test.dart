import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('intentional scanner close never renders camera unavailable state', () {
    final scanner = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_blueprint_live_scanner_screen.dart',
    ).readAsStringSync();

    final closingIndex = scanner.indexOf('body: _scannerClosing');
    final cameraErrorIndex = scanner.indexOf(
      "message: _error ?? 'Camera unavailable.'",
    );

    expect(closingIndex, greaterThanOrEqualTo(0));
    expect(cameraErrorIndex, greaterThan(closingIndex));
    expect(scanner, contains('const ColoredBox(color: Colors.black)'));
    expect(scanner, contains('setState(() => _scannerClosing = true)'));
  });
}
