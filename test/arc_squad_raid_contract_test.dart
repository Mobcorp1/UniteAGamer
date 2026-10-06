import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Match Raider exposes squad raid launcher', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_match_rider_screen.dart',
    ).readAsStringSync();
    expect(source, contains('ArcSquadRaidLauncher'));
    expect(source, contains('myDisplayName: profile.title'));
  });

  test('Raid Intelligence consumes shared session objectives', () {
    final screen = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_raid_intelligence_screen.dart',
    ).readAsStringSync();
    final engine = File(
      'lib/features/trading_hub/arc_raiders/data/arc_raid_intelligence_engine.dart',
    ).readAsStringSync();

    expect(screen, contains('squadSessionId'));
    expect(screen, contains('ArcSquadRaidPlanningEngine'));
    expect(screen, contains('saveSharedRoute'));
    expect(screen, contains('allMembersSynced'));
    expect(screen, contains('participants: _squadParticipants()'));
    expect(engine, contains('additionalObjectives'));
  });

  test('Firestore rules enforce server-side squad contribution limits', () {
    final rules = File('firestore.rules').readAsStringSync();
    expect(rules, contains('squadObjectiveLimit'));
    expect(rules, contains("tier == 'premium' ? 24"));
    expect(rules, contains("tier == 'essential' ? 5 : 1"));
    expect(rules, contains('acceptedMatchInviteBetween'));
    expect(rules, contains('arc_squad_raid_sessions'));
    expect(rules, contains("resource.data.leaderUid == request.auth.uid"));
  });

  test('shared route strips private objective identifiers', () {
    final repository = File(
      'lib/features/trading_hub/arc_raiders/repositories/arc_squad_raid_repository.dart',
    ).readAsStringSync();
    expect(repository, contains('Shared squad route'));
    expect(repository, isNot(contains("'blueprintIds': route")));
    expect(repository, isNot(contains("'objectiveIds': route")));
  });
}
