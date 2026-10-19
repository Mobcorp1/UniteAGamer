import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_conditions.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_match_rider_profile.dart';

void main() {
  test('new official event interests are selectable without overwriting maps', () {
    final options = ArcMapConditions.selectableEventOptions;
    expect(options.any((event) => event.label == 'ARC Frigate'), isTrue);
    expect(options.any((event) => event.label == 'Redirection'), isTrue);
    expect(ArcMapConditions.byId('arc_frigate'), isNotNull);
    expect(ArcMapConditions.byId('redirection')!.supportsMap('Pendola Pass'), isTrue);
    expect(ArcMapConditions.byId('redirection')!.supportsMap('Buried City'), isFalse);
  });

  test('rider alert opt-in and event interests survive public projection', () {
    final original = ArcMatchRiderProfile.empty('raider-a').copyWith(
      preferredMaps: ['Pendola Pass'],
      preferredEvents: ['ARC Frigate'],
      lookingNow: true,
      autoMatchAlertsEnabled: true,
    );
    final stored = original.toPublicMap();
    expect(stored['preferredEvents'], ['ARC Frigate']);
    expect(stored['autoMatchAlertsEnabled'], isTrue);
    final restored = ArcMatchRiderProfile.fromMap(stored, 'raider-a');
    expect(restored.preferredMaps, ['Pendola Pass']);
    expect(restored.preferredEvents, ['ARC Frigate']);
    expect(restored.autoMatchAlertsEnabled, isTrue);
    expect(ArcMatchRiderProfile.empty('default').autoMatchAlertsEnabled, isFalse);
  });
}
