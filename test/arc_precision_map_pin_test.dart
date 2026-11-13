import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_precision_map_pin.dart';

void main() {
  testWidgets(
    'precision pin expands details while keeping a bottom-tip anchor',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ArcPrecisionMapPin(
                selected: true,
                accent: Colors.cyanAccent,
                head: const Icon(Icons.train_rounded),
                label: 'Metro Station',
                detail: 'Underground access',
                coordinateText: 'X 0.4231 • Y 0.6178',
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Metro Station'), findsOneWidget);
      expect(find.text('Underground access'), findsOneWidget);
      expect(find.text('X 0.4231 • Y 0.6178'), findsOneWidget);
      expect(ArcPrecisionMapPin.collapsedWidth, lessThanOrEqualTo(40));
      expect(ArcPrecisionMapPin.collapsedHeight, lessThanOrEqualTo(42));
      expect(tester.takeException(), isNull);
    },
  );

  test('admin and player maps share projection and precision tip anchoring', () {
    final admin = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_admin_map_editor_screen.dart',
    ).readAsStringSync();
    final player = File(
      'lib/features/trading_hub/arc_raiders/widgets/arc_raid_intelligence_map.dart',
    ).readAsStringSync();

    for (final source in [admin, player]) {
      expect(source, contains('ArcMapCoordinateProjection.canonicalToCanvas'));
      expect(source, contains('ArcPrecisionMapPin.heightFor(selected)'));
      expect(source, contains('top: anchor.dy - pinHeight'));
    }

    expect(admin, contains("Key('admin-map-zoom-out')"));
    expect(admin, contains("Key('admin-map-zoom-in')"));
    expect(admin, contains("Key('admin-map-fit')"));
    expect(admin, contains("Key('admin-map-zoom-percent')"));
    expect(admin, contains('trackpadScrollCausesScale: true'));
    expect(admin, contains('ArcQuestMapBinding.questsForMap'));
    expect(admin, contains('questId: result.questId'));

    expect(player, contains('_blueprintPinHead'));
    expect(player, contains('ArcBlueprintSeedData.blueprints'));
    expect(player, isNot(contains('ArcBlueprintOpportunityMarker(')));
  });
}
