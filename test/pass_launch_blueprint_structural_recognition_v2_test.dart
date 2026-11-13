import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scan pipeline registers lattice before ownership classification', () {
    final capture = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_blueprint_photo_capture_screen.dart',
    ).readAsStringSync();

    expect(capture, contains('ArcBlueprintGridLatticeRegistrar'));
    expect(capture, contains('registeredTopBytes'));
    expect(capture, contains('registeredBottomBytes'));
    expect(capture, contains('ArcBlueprintOwnedCellStructureVerifier'));
    expect(capture, contains('samples: structureVerification.samples'));
  });

  test('camera overlay no longer draws misleading internal 10x5 guide', () {
    final overlay = File(
      'lib/features/trading_hub/arc_raiders/widgets/'
      'arc_blueprint_edge_crop_overlay.dart',
    ).readAsStringSync();

    expect(
      overlay,
      isNot(contains('for (var column = 1; column < 10; column++)')),
    );
    expect(overlay, isNot(contains('for (var row = 1; row < 5; row++)')));
    expect(overlay, contains('cropRect'));
  });
}
