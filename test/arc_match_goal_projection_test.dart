import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_match_rider_profile.dart';

void main() {
  test(
    'public Match Raider profile publishes only derived quest alignment',
    () {
      final profile = ArcMatchRiderProfile.empty('user-a').copyWith(
        questFocusIds: const <String>['quest-alpha'],
        questChainIds: const <String>['quest-beta'],
        matchRecommendedMapIds: const <String>['Spaceport'],
        matchRecommendedConditionIds: const <String>['Hidden Bunker'],
      );

      final public = profile.toPublicMap();

      expect(public['matchQuestIds'], <String>['quest-alpha', 'quest-beta']);
      expect(public['matchRecommendedMapIds'], <String>['Spaceport']);
      expect(public['matchRecommendedConditionIds'], <String>['Hidden Bunker']);
      expect(public.containsKey('questFocusIds'), isTrue);
      expect(public.containsKey('questChainIds'), isTrue);
      expect(public['questFocusIds'], isA<FieldValue>());
      expect(public['questChainIds'], isA<FieldValue>());
      expect(public['questFocusIds'], isNot(<String>['quest-alpha']));
      expect(public['questChainIds'], isNot(<String>['quest-beta']));
    },
  );

  test('derived quest alignment survives public profile round trip', () {
    final profile = ArcMatchRiderProfile.fromMap(<String, dynamic>{
      'uid': 'user-b',
      'matchQuestIds': <String>['quest-alpha'],
      'matchRecommendedMapIds': <String>['Buried City'],
      'matchRecommendedConditionIds': <String>['Night Raid'],
    }, 'user-b');

    expect(profile.matchQuestIds, <String>['quest-alpha']);
    expect(profile.matchRecommendedMapIds, <String>['Buried City']);
    expect(profile.matchRecommendedConditionIds, <String>['Night Raid']);
  });
}
