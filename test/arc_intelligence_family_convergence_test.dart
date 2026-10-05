import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_regional_map_conditions.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_intelligence_workspace_bar.dart';

void main() {
  group('ARC intelligence family convergence', () {
    test('map names normalize official The Blue Gate to app Blue Gate', () {
      expect(
        ArcRegionalConditionDigest.normalizeMapName('The Blue Gate'),
        ArcRegionalConditionDigest.normalizeMapName('Blue Gate'),
      );
      expect(
        ArcRegionalConditionDigest.normalizeMapName('Dam Battlegrounds'),
        'dambattlegrounds',
      );
    });

    test('digest resolves active and next conditions by selected region', () {
      final loadedAt = DateTime.utc(2026, 9, 16, 12);
      final snapshot = ArcRegionalMapConditionsSnapshot(
        entries: [
          ArcRegionalMapConditionEntry(
            conditionName: 'Night Raid',
            mapDisplayName: 'The Blue Gate',
            duration: const Duration(hours: 1),
            regionWindows: {
              ArcServerRegion.europe: ArcRegionalConditionWindow(
                startUtc: DateTime.utc(2026, 9, 16, 12),
                endUtc: DateTime.utc(2026, 9, 16, 13),
              ),
            },
          ),
          ArcRegionalMapConditionEntry(
            conditionName: 'Matriarch',
            mapDisplayName: 'The Blue Gate',
            duration: const Duration(hours: 1),
            regionWindows: {
              ArcServerRegion.europe: ArcRegionalConditionWindow(
                startUtc: DateTime.utc(2026, 9, 16, 13),
                endUtc: DateTime.utc(2026, 9, 16, 14),
              ),
            },
          ),
        ],
        serverNowUtc: loadedAt,
        loadedAtUtc: loadedAt,
        source: ArcMapConditionsSource.officialLive,
      );

      final now = DateTime.utc(2026, 9, 16, 12, 30);
      final active = ArcRegionalConditionDigest.activeEntries(
        snapshot,
        region: ArcServerRegion.europe,
        mapDisplayName: 'Blue Gate',
        nowUtc: now,
      );
      final upcoming = ArcRegionalConditionDigest.upcomingEntries(
        snapshot,
        region: ArcServerRegion.europe,
        mapDisplayName: 'Blue Gate',
        nowUtc: now,
      );

      expect(active.map((entry) => entry.conditionName), ['Night Raid']);
      expect(upcoming.map((entry) => entry.conditionName), ['Matriarch']);
    });

    test('all four intelligence workspaces are wired into their family screens', () {
      const expected = <String, String>{
        'lib/features/trading_hub/arc_raiders/screens/arc_raid_intelligence_screen.dart':
            'ArcIntelligenceWorkspace.raidMap',
        'lib/features/trading_hub/arc_raiders/screens/arc_market_intelligence_screen.dart':
            'ArcIntelligenceWorkspace.community',
        'lib/features/trading_hub/arc_raiders/screens/arc_intel_explorer_screen.dart':
            'ArcIntelligenceWorkspace.explorer',
        'lib/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_screen.dart':
            'ArcIntelligenceWorkspace.planner',
      };

      for (final entry in expected.entries) {
        final source = File(entry.key).readAsStringSync();
        expect(source, contains('ArcIntelligenceWorkspaceBar'));
        expect(source, contains(entry.value));
      }
    });

    test('official conditions feed recommendations and discovery views', () {
      final raid = File(
        'lib/features/trading_hub/arc_raiders/screens/arc_raid_intelligence_screen.dart',
      ).readAsStringSync();
      final community = File(
        'lib/features/trading_hub/arc_raiders/screens/arc_market_intelligence_screen.dart',
      ).readAsStringSync();
      final explorer = File(
        'lib/features/trading_hub/arc_raiders/screens/arc_intel_explorer_screen.dart',
      ).readAsStringSync();

      // Raid Intelligence now shows the relevant condition in its recommendation
      // rather than a separate strip. Protect the shared source and its wiring.
      expect(raid, contains('ArcRegionalMapConditionsService.load()'));
      expect(raid, contains('_regionalConditions = regional'));
      expect(raid, contains('final snapshot = _regionalConditions'));
      expect(raid, contains('_autoRecommendationEngine.recommend('));
      expect(raid, contains('snapshot: snapshot'));
      expect(raid, contains(r'${recommendation.conditionName}'));
      final strip = File(
        'lib/features/trading_hub/arc_raiders/widgets/arc_intelligence_workspace_bar.dart',
      ).readAsStringSync();
      expect(strip, contains('ArcRegionalMapConditionsService.load()'));
      expect(community, contains('ArcLiveMapConditionsStrip'));
      expect(explorer, contains('ArcLiveMapConditionsStrip'));
    });
  });
}
