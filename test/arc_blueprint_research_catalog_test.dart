import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_research_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_research_models.dart';

void main() {
  test(
    'LOADMAP01 research baseline keeps the reconciled dataset cardinality',
    () {
      expect(ArcBlueprintResearchCatalog.entries, hasLength(498));
      expect(
        ArcBlueprintResearchCatalog.entries
            .map((entry) => entry.blueprintId)
            .toSet(),
        hasLength(83),
      );
      expect(
        ArcBlueprintResearchCatalog.entries.fold<int>(
          0,
          (total, entry) => total + entry.sites.length,
        ),
        768,
      );
      expect(ArcBlueprintResearchCatalog.autoMatchedNamedPoiCount, 83);
      expect(ArcBlueprintResearchCatalog.namedPoiReviewCount, 1);
    },
  );

  test(
    'candidate POIs stay explicitly non-confirmed research intelligence',
    () {
      final entry = ArcBlueprintResearchCatalog.forBlueprintOnMap(
        'extended-shotgun-mag-iii',
        'blue_gate',
      )!;

      expect(
        entry.eligibility,
        ArcBlueprintResearchEligibility.conditionCandidate,
      );
      expect(entry.canAutoRoute, isTrue);
      expect(
        entry.sites.map((site) => site.poiId),
        containsAll(<String>[
          'blue_gate_village',
          'blue_gate_ruined_homestead',
          'blue_gate_abandoned_housing_project',
        ]),
      );
      expect(entry.evidenceSummary, contains('not an independently verified'));
    },
  );

  test('ambiguous named location remains review-only instead of guessed', () {
    final reviewSites = ArcBlueprintResearchCatalog.entries
        .expand((entry) => entry.sites)
        .where((site) => site.needsAdminReview)
        .toList(growable: false);
    final reviewNames = reviewSites.map((site) => site.poiName).toSet();

    expect(reviewNames, <String>{'Business Center / Lobby security office'});
    expect(reviewSites, isNotEmpty);
    for (final site in reviewSites) {
      expect(site.poiId, isNull);
      expect(site.canResolveAutomatically, isFalse);
    }
  });
}
