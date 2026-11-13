import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'admin Quest authoring requires canonical map-filtered Quest identity',
    () {
      final source = File(
        'lib/features/trading_hub/arc_raiders/screens/arc_admin_map_editor_screen.dart',
      ).readAsStringSync();

      expect(source, contains("labelText: 'Linked Quest (required)'"));
      expect(
        source,
        contains('ArcQuestMapBinding.questsForMap(widget.mapName)'),
      );
      expect(source, contains('questId: result.questId'));
      expect(source, contains('clearQuestId: result.questId == null'));
    },
  );

  test('Raid Intelligence goal map uses canonical Quest map relevance', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_raid_intelligence_screen.dart',
    ).readAsStringSync();

    expect(source, contains('ArcQuestMapBinding.questSupportsMap'));
    expect(source, contains('objective.questLocationOnly ? 180 : 35'));
  });
}
