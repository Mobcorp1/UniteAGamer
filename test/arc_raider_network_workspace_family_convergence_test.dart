import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final workspace = File(
    'lib/features/trading_hub/arc_raiders/widgets/'
    'arc_raider_network_workspace_bar.dart',
  ).readAsStringSync();
  final community = File(
    'lib/features/trading_hub/arc_raiders/screens/'
    'arc_market_intelligence_screen.dart',
  ).readAsStringSync();
  final matchRaider = File(
    'lib/features/trading_hub/arc_raiders/screens/arc_match_rider_screen.dart',
  ).readAsStringSync();
  final contracts = File(
    'lib/features/trust/screens/arc_raider_contracts_screen.dart',
  ).readAsStringSync();

  test('Raider network workspace exposes the three connected families', () {
    expect(
      workspace,
      contains(
        'enum ArcRaiderNetworkWorkspace { community, matchRaider, contracts }',
      ),
    );
    expect(workspace, contains("return '/trading-hub/arc-raiders/market';"));
    expect(
      workspace,
      contains("return '/trading-hub/arc-raiders/match-a-raider';"),
    );
    expect(workspace, contains("return '/raider-contracts';"));
    expect(workspace, contains('rootNavigator: true'));
  });

  test(
    'Community Intel keeps Intelligence family and gains Raider network',
    () {
      expect(
        community,
        contains('current: ArcIntelligenceWorkspace.community'),
      );
      expect(
        community,
        contains('current: ArcRaiderNetworkWorkspace.community'),
      );
    },
  );

  test(
    'Match Raider joins the Raider network without replacing match logic',
    () {
      expect(
        matchRaider,
        contains('current: ArcRaiderNetworkWorkspace.matchRaider'),
      );
      expect(matchRaider, contains('ArcMatchRiderRepository _repository'));
      expect(matchRaider, contains('_buildFeedAndInvites(profile)'));
      expect(matchRaider, contains('_buildProfileEditor(profile)'));
    },
  );

  test(
    'Report and Contracts joins network while preserving four-tab workflow',
    () {
      expect(
        contracts,
        contains('current: ArcRaiderNetworkWorkspace.contracts'),
      );
      expect(contracts, contains('TabController(length: 4'));
      for (final label in <String>[
        'REPORT',
        'CONTRACTS',
        'ACTIVITY',
        'REWARDS',
      ]) {
        expect(contracts, contains("text: '$label'"));
      }
      expect(contracts, contains('_ProgressiveReport(repo: repo)'));
      expect(contracts, contains('_Contracts(repo: repo, live: true)'));
    },
  );

  test('workspace remains navigation only ahead of de-duplication audit', () {
    expect(workspace, isNot(contains('StreamBuilder')));
    expect(workspace, isNot(contains('ArcMatchRiderRepository')));
    expect(workspace, isNot(contains('ArcRaiderContractsRepository')));
  });
}
