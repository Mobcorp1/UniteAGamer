import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_match_compatibility_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_match_rider_profile.dart';

void main() {
  group('ArcMatchCompatibilityEngine', () {
    const engine = ArcMatchCompatibilityEngine();

    test('prioritizes shared Rat Hunter identity and session fit', () {
      final me = _profile(
        uid: 'me',
        archetypes: const <String>['Rat Hunter', 'PvP Hunter'],
        playstyles: const <String>['PvP focused'],
        goals: const <String>['Rat hunting', 'Blueprint farming'],
        comms: const <String>['Pings'],
        squadPreferences: const <String>['Duos'],
      );
      final other = _profile(
        uid: 'other',
        archetypes: const <String>['Rat Hunter'],
        playstyles: const <String>['PvP focused'],
        goals: const <String>['Rat hunting'],
        comms: const <String>['Pings'],
        squadPreferences: const <String>['Duos'],
      );

      final result = engine.score(me: me, other: other);

      expect(result.score, greaterThanOrEqualTo(90));
      expect(result.reasons, contains('Shared archetypes: Rat Hunter'));
      expect(result.reasons, contains('Shared goals: Rat hunting'));
    });

    test('keeps weak fits lower when intent and comms do not overlap', () {
      final me = _profile(
        uid: 'me',
        archetypes: const <String>['Rat Hunter'],
        playstyles: const <String>['PvP focused'],
        goals: const <String>['Rat hunting'],
        comms: const <String>['Pings'],
      );
      final other = _profile(
        uid: 'other',
        archetypes: const <String>['Quest-driven Raider'],
        playstyles: const <String>['PvE defensive'],
        goals: const <String>['Quests'],
        comms: const <String>['Voice'],
        platform: 'Xbox',
        region: 'US',
        serverPreference: 'North America',
        crossplayEnabled: false,
        lookingNow: false,
      );

      final result = engine.score(me: me, other: other);

      expect(result.score, lessThan(25));
      expect(result.reasons, isEmpty);
    });
  });
}

ArcMatchRiderProfile _profile({
  required String uid,
  required List<String> archetypes,
  required List<String> playstyles,
  required List<String> goals,
  required List<String> comms,
  List<String> squadPreferences = const <String>[],
  String platform = 'PC',
  String region = 'UK',
  String serverPreference = 'Europe',
  bool crossplayEnabled = true,
  bool lookingNow = true,
}) {
  return ArcMatchRiderProfile.empty(uid).copyWith(
    uid: uid,
    displayName: uid,
    archetypes: archetypes,
    playstyles: playstyles,
    goals: goals,
    comms: comms,
    squadPreferences: squadPreferences,
    platform: platform,
    region: region,
    serverPreference: serverPreference,
    crossplayEnabled: crossplayEnabled,
    lookingNow: lookingNow,
  );
}
