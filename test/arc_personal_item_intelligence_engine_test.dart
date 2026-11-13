import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_personal_item_dependency_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_personal_item_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_personal_item_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';

void main() {
  group('ArcPersonalItemIntelligenceEngine', () {
    const engine = ArcPersonalItemIntelligenceEngine();

    test('keeps active quest and progression requirements', () {
      final dataset = _dataset(
        const ArcPersonalItemRecord(
          id: 'queen-reactor',
          name: 'Queen Reactor',
          category: 'Progression Material',
          verificationState: ArcPersonalItemVerificationState.uagVerified,
          confidence: 0.93,
          lastGameVersionVerified: 'ARC Raiders 1.28',
          lastReviewedIso: '2026-07-28T00:00:00.000Z',
          dependencies: <ArcPersonalItemDependency>[
            ArcPersonalItemDependency(
              system: 'Quest',
              objectiveId: 'quest-critical',
              label: 'Critical quest hand-in',
              requiredQuantity: 1,
              blocking: true,
            ),
          ],
        ),
      );

      final result = engine.evaluate(
        query: 'Queen Reactor',
        dataset: dataset,
        inventory: const ArcPersonalItemInventorySnapshot(
          ownedQuantities: {'queen-reactor': 1},
        ),
        now: DateTime.utc(2026, 7, 29),
      );

      expect(result.outcome, ArcPersonalItemRecommendation.keep);
      expect(result.linkedObjectiveIds, contains('quest-critical'));
      expect(
        result.conflictingRecommendations,
        contains(ArcPersonalItemRecommendation.recycle),
      );
    });

    test('is quantity aware and only trades surplus', () {
      final dataset = _dataset(
        const ArcPersonalItemRecord(
          id: 'advanced-mechanical-components',
          name: 'Advanced Mechanical Components',
          category: 'Progression Material',
          verificationState: ArcPersonalItemVerificationState.uagVerified,
          confidence: 0.94,
          lastGameVersionVerified: 'ARC Raiders 1.28',
          lastReviewedIso: '2026-07-28T00:00:00.000Z',
          dependencies: <ArcPersonalItemDependency>[
            ArcPersonalItemDependency(
              system: 'Scrappy',
              objectiveId: 'scrappy-4',
              label: 'Scrappy Level 4',
              requiredQuantity: 3,
              blocking: true,
            ),
            ArcPersonalItemDependency(
              system: 'Bench',
              objectiveId: 'bench-gunsmith',
              label: 'Gunsmith upgrade',
              requiredQuantity: 2,
              blocking: true,
            ),
          ],
        ),
      );

      final result = engine.evaluate(
        query: 'Advanced Mechanical Components',
        dataset: dataset,
        inventory: const ArcPersonalItemInventorySnapshot(
          ownedQuantities: {'advanced-mechanical-components': 8},
        ),
        activeListings: <TradingListing>[
          TradingListing.empty().copyWith(
            id: 'listing-1',
            ownerUid: 'trader-2',
            traderName: 'Raider Two',
            wantedTradeItemNames: const ['Advanced Mechanical Components'],
            expiresAt: DateTime.utc(2026, 8, 1),
          ),
        ],
        now: DateTime.utc(2026, 7, 29),
      );

      expect(result.outcome, ArcPersonalItemRecommendation.trade);
      expect(result.requiredQuantity, 5);
      expect(result.surplusQuantity, 3);
      expect(result.primaryReason, contains('only trade the 3 surplus'));
    });

    test('user protections override sell and recycle recommendations', () {
      final result = engine.evaluate(
        query: 'Broken Flashlight',
        dataset: _dataset(_safeRecycleRecord()),
        inventory: const ArcPersonalItemInventorySnapshot(
          ownedQuantities: {'broken-flashlight': 2},
          protectionOverrides: {
            'broken-flashlight': ArcPersonalItemProtectionOverride(
              userId: 'user-1',
              itemId: 'broken-flashlight',
              protections: {ArcPersonalItemProtectionType.neverRecycle},
              customMinimumQuantity: 2,
            ),
          },
        ),
        now: DateTime.utc(2026, 7, 29),
      );

      expect(result.outcome, ArcPersonalItemRecommendation.reserve);
      expect(result.requiredQuantity, 2);
      expect(
        result.conflictingRecommendations,
        contains(ArcPersonalItemRecommendation.recycle),
      );
    });

    test('incomplete and stale data prevents recycle', () {
      final result = engine.evaluate(
        query: 'Unknown Relic',
        dataset: _dataset(
          const ArcPersonalItemRecord(
            id: 'unknown-relic',
            name: 'Unknown Relic',
            category: 'Unknown',
            verificationState: ArcPersonalItemVerificationState.unverified,
            confidence: 0.4,
            generallySafeToRecycle: true,
            recycleOutputs: {'Material': 1},
            lastGameVersionVerified: '',
            lastReviewedIso: '',
          ),
        ),
        inventory: const ArcPersonalItemInventorySnapshot(
          ownedQuantities: {'unknown-relic': 1},
        ),
      );

      expect(result.outcome, ArcPersonalItemRecommendation.unknown);
      expect(
        result.primaryReason,
        ArcPersonalItemIntelligenceEngine.unsafeRecycleMessage,
      );
      expect(result.isRecycleSafe, isFalse);
    });

    test('allows recycle only for fresh verified no-dependency surplus', () {
      final result = engine.evaluate(
        query: 'Broken Flashlight',
        dataset: _dataset(_safeRecycleRecord()),
        inventory: const ArcPersonalItemInventorySnapshot(
          ownedQuantities: {'broken-flashlight': 1},
        ),
        now: DateTime.utc(2026, 7, 29),
      );

      expect(result.outcome, ArcPersonalItemRecommendation.recycle);
      expect(result.isRecycleSafe, isTrue);
    });

    test('coverage report exposes dataset version and incomplete counts', () {
      final coverage = engine.coverage(
        dataset: _dataset(
          _safeRecycleRecord(),
          const ArcPersonalItemRecord(
            id: 'mystery',
            name: 'Mystery',
            category: 'Unknown',
            verificationState: ArcPersonalItemVerificationState.unverified,
            confidence: 0.1,
          ),
        ),
      );

      expect(coverage.datasetVersion, 'test-version');
      expect(coverage.totalKnownItems, 2);
      expect(coverage.incompleteItems, 1);
      expect(coverage.itemsWithRecycleData, 1);
    });

    test('generated catalogue has real local coverage', () {
      final coverage = ArcPersonalItemDependencyCatalog.current.coverage;

      expect(coverage.totalKnownItems, greaterThan(100));
      expect(coverage.itemsWithQuestDependencies, greaterThan(0));
      expect(coverage.itemsWithScrappyDependencies, greaterThan(0));
      expect(coverage.itemsWithBenchDependencies, greaterThan(0));
      expect(coverage.itemsWithLoadoutRelevance, greaterThan(0));
    });
  });
}

ArcPersonalItemDataset _dataset(
  ArcPersonalItemRecord first, [
  ArcPersonalItemRecord? second,
]) {
  return ArcPersonalItemDataset(
    version: 'test-version',
    gameVersion: 'ARC Raiders 1.28',
    effectiveDateIso: '2026-07-28T00:00:00.000Z',
    published: true,
    records: <ArcPersonalItemRecord>[first, ?second],
  );
}

ArcPersonalItemRecord _safeRecycleRecord() {
  return const ArcPersonalItemRecord(
    id: 'broken-flashlight',
    name: 'Broken Flashlight',
    category: 'Recyclable',
    verificationState: ArcPersonalItemVerificationState.highlyCorroborated,
    confidence: 0.9,
    generallySafeToRecycle: true,
    recycleOutputs: {'Wires': 1},
    lastGameVersionVerified: 'ARC Raiders 1.28',
    lastReviewedIso: '2026-07-28T00:00:00.000Z',
  );
}
