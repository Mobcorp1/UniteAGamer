import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_match_compatibility_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_match_objective_signals.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_match_rider_profile.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_match_rider_repository.dart';

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

      expect(result.score, greaterThanOrEqualTo(70));
      expect(result.publicLabel, 'Good fit');
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
      expect(result.publicLabel, 'Worth a look');
      expect(
        result.exclusionReasons,
        contains('Incompatible platform preferences'),
      );
      expect(result.reasons, isEmpty);
    });

    test(
      'free tier uses basic compatibility without advanced objective boosts',
      () {
        final meSignals = const ArcMatchObjectiveSignals(
          ownedBlueprintIds: <String>['Wolfpack'],
          neededBlueprintIds: <String>['Tempest'],
        );
        final otherSignals = const ArcMatchObjectiveSignals(
          ownedBlueprintIds: <String>['Tempest'],
          neededBlueprintIds: <String>['Wolfpack'],
        );

        final basic = engine.score(
          me: _neutralProfile('me'),
          other: _neutralProfile('other'),
          meSignals: meSignals,
          otherSignals: otherSignals,
          tier: ArcMatchIntelligenceTier.basic,
        );
        final advanced = engine.score(
          me: _neutralProfile('me'),
          other: _neutralProfile('other'),
          meSignals: meSignals,
          otherSignals: otherSignals,
          tier: ArcMatchIntelligenceTier.advanced,
        );

        expect(basic.tier, ArcMatchIntelligenceTier.basic);
        expect(basic.breakdown.blueprintComplementarity, 0);
        expect(advanced.breakdown.blueprintComplementarity, greaterThan(0));
        expect(advanced.score, greaterThanOrEqualTo(basic.score));
      },
    );

    test('essential tier adds communication, squad and archetype fit', () {
      final me = _profile(
        uid: 'me',
        archetypes: const <String>['Helper / Support Player'],
        playstyles: const <String>['Quest-focused'],
        goals: const <String>['Quests'],
        comms: const <String>['Voice'],
        squadPreferences: const <String>['Trios'],
      ).copyWith(sessionIntent: 'Quests', currentPriority: 'Quest progress');
      final other = _profile(
        uid: 'other',
        archetypes: const <String>['Quest-driven Raider'],
        playstyles: const <String>['Quest-focused'],
        goals: const <String>['Quests'],
        comms: const <String>['Voice'],
        squadPreferences: const <String>['Trios'],
      ).copyWith(sessionIntent: 'Quests', currentPriority: 'Quest progress');

      final basic = engine.score(
        me: me,
        other: other,
        tier: ArcMatchIntelligenceTier.basic,
      );
      final enhanced = engine.score(
        me: me,
        other: other,
        tier: ArcMatchIntelligenceTier.enhanced,
      );

      expect(enhanced.tier, ArcMatchIntelligenceTier.enhanced);
      expect(enhanced.breakdown.communication, greaterThan(0));
      expect(enhanced.breakdown.squadIntent, greaterThan(0));
      expect(enhanced.score, greaterThanOrEqualTo(basic.score));
    });

    test(
      'premium tier rewards mutual blueprint complementarity above one-way help',
      () {
        final oneWay = engine.score(
          me: _neutralProfile('me'),
          other: _neutralProfile('other'),
          meSignals: const ArcMatchObjectiveSignals(
            ownedBlueprintIds: <String>['Bettina'],
          ),
          otherSignals: const ArcMatchObjectiveSignals(
            neededBlueprintIds: <String>['Bettina'],
          ),
        );
        final complementary = engine.score(
          me: _neutralProfile('me'),
          other: _neutralProfile('other'),
          meSignals: const ArcMatchObjectiveSignals(
            ownedBlueprintIds: <String>['Wolfpack'],
            neededBlueprintIds: <String>['Tempest'],
          ),
          otherSignals: const ArcMatchObjectiveSignals(
            ownedBlueprintIds: <String>['Tempest'],
            neededBlueprintIds: <String>['Wolfpack'],
          ),
        );

        expect(oneWay.breakdown.blueprintComplementarity, greaterThan(0));
        expect(
          complementary.breakdown.blueprintComplementarity,
          greaterThan(oneWay.breakdown.blueprintComplementarity),
        );
        expect(complementary.score, greaterThan(oneWay.score));
      },
    );

    test('competing blueprint needs apply a mild private penalty', () {
      final competing = engine.score(
        me: _neutralProfile('me'),
        other: _neutralProfile('other'),
        meSignals: const ArcMatchObjectiveSignals(
          neededBlueprintIds: <String>['Wolfpack'],
        ),
        otherSignals: const ArcMatchObjectiveSignals(
          neededBlueprintIds: <String>['Wolfpack'],
        ),
      );
      final neutral = engine.score(
        me: _neutralProfile('me'),
        other: _neutralProfile('other'),
      );

      expect(competing.breakdown.competitionPenalty, greaterThan(0));
      expect(competing.score, lessThanOrEqualTo(neutral.score));
    });

    test(
      'public result hides private reasons, breakdowns and blueprint data',
      () {
        final result = engine.score(
          me: _neutralProfile('me'),
          other: _neutralProfile('other'),
          meSignals: const ArcMatchObjectiveSignals(
            ownedBlueprintIds: <String>['Wolfpack'],
            neededBlueprintIds: <String>['Tempest'],
          ),
          otherSignals: const ArcMatchObjectiveSignals(
            ownedBlueprintIds: <String>['Tempest'],
            neededBlueprintIds: <String>['Wolfpack'],
          ),
        );
        final public = result.toPublicMap();
        final publicText = public.toString().toLowerCase();

        expect(result.reasons, isNotEmpty);
        expect(public.containsKey('breakdown'), isFalse);
        expect(public.containsKey('reasons'), isFalse);
        expect(publicText, isNot(contains('wolfpack')));
        expect(publicText, isNot(contains('tempest')));
        expect(publicText, isNot(contains('blueprint')));
        expect(publicText, isNot(contains('weight')));
      },
    );

    test('incomplete profiles keep a graceful low-confidence fallback', () {
      final result = engine.score(
        me: ArcMatchRiderProfile.empty('me'),
        other: ArcMatchRiderProfile.empty('other'),
        tier: ArcMatchIntelligenceTier.basic,
      );

      expect(result.score, inInclusiveRange(0, 100));
      expect(result.confidence, ArcMatchConfidenceLevel.low);
      expect(result.ranking.dataCompleteness, lessThan(40));
    });

    test('blocked, hidden, incompatible and unsafe matches are excluded', () {
      final me = _neutralProfile('me');
      final other = _neutralProfile('other').copyWith(
        visibleInSearch: false,
        crossplayEnabled: false,
        platform: 'Xbox',
      );
      final result = engine.score(
        me: me,
        other: other,
        otherSignals: const ArcMatchObjectiveSignals(betrayalFlags: 3),
        blockedUserIds: const <String>{'other'},
      );

      expect(result.isExcluded, isTrue);
      expect(result.exclusionReasons, contains('Blocked by you'));
      expect(result.exclusionReasons, contains('Hidden from search'));
      expect(
        result.exclusionReasons,
        contains('Incompatible platform preferences'),
      );
      expect(result.exclusionReasons, contains('Reputation safety threshold'));
      expect(result.ranking.rankScore, lessThan(0));
    });

    test('stale profile handling reduces confidence and ranking', () {
      final fresh = engine.score(
        me: _neutralProfile('me'),
        other: _neutralProfile(
          'fresh',
        ).copyWith(updatedAt: DateTime(2026, 7, 15)),
        now: DateTime(2026, 7, 22),
      );
      final stale = engine.score(
        me: _neutralProfile('me'),
        other: _neutralProfile(
          'stale',
        ).copyWith(updatedAt: DateTime(2026, 5, 1)),
        now: DateTime(2026, 7, 22),
      );

      expect(stale.ranking.staleProfile, isTrue);
      expect(stale.ranking.rankScore, lessThan(fresh.ranking.rankScore));
    });

    test('candidate sorting is deterministic with stable tie-breaking', () {
      final alpha = _candidate('alpha');
      final beta = _candidate('beta');
      final better = _candidate('zeta', score: 80);
      final sorted = <ArcMatchCandidate>[beta, better, alpha]
        ..sort(ArcMatchRiderRepository.compareCandidates);

      expect(sorted.map((candidate) => candidate.profile.uid), <String>[
        'zeta',
        'alpha',
        'beta',
      ]);
    });
  });
}

ArcMatchCandidate _candidate(String uid, {int score = 70}) {
  final profile = _neutralProfile(uid).copyWith(displayName: uid);
  return ArcMatchCandidate(
    profile: profile,
    result: ArcMatchCompatibilityResult(
      score: score,
      reasons: const <String>[],
      tier: ArcMatchIntelligenceTier.basic,
      confidence: ArcMatchConfidenceLevel.medium,
      breakdown: const ArcMatchScoreBreakdown(
        coreProfile: 0,
        availability: 0,
        communication: 0,
        squadIntent: 0,
        archetypeFit: 0,
        reputation: 0,
        relationship: 0,
        progression: 0,
        mapAndEventFit: 0,
        blueprintComplementarity: 0,
        competitionPenalty: 0,
        incompleteProfilePenalty: 0,
      ),
      publicTags: const <String>[],
      exclusionReasons: const <String>[],
      ranking: ArcMatchRankingMetadata(
        rankScore: score,
        dataCompleteness: 80,
        staleProfile: false,
        tieBreaker: '${profile.title.toLowerCase()}|${profile.uid}',
      ),
    ),
  );
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

ArcMatchRiderProfile _neutralProfile(String uid) {
  return ArcMatchRiderProfile.empty(uid).copyWith(
    uid: uid,
    displayName: uid,
    platform: 'PC',
    region: 'EU',
    serverPreference: 'Europe',
    crossplayEnabled: true,
    lookingNow: false,
  );
}
