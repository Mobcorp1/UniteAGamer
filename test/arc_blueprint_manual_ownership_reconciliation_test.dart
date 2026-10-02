import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_import_service.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';

ArcBlueprintPhotoCellDecision decision(
  String id,
  ArcBlueprintPhotoCellState state,
) {
  return ArcBlueprintPhotoCellDecision(
    blueprintId: id,
    blueprintIndex: 0,
    state: state,
    confidence: 0.95,
    sourceCaptureId: 'top',
    rowIndex: 0,
    columnIndex: 0,
  );
}

ArcBlueprintState owned(
  String id, {
  ArcBlueprintOwnershipSource source = ArcBlueprintOwnershipSource.unknown,
  int dupes = 0,
}) {
  return ArcBlueprintState.empty(
    id,
  ).copyWith(owned: true, dupesOwned: dupes, ownershipSource: source);
}

void main() {
  group('Blueprint ownership provenance', () {
    test('manual ownership is persisted and clearing resets its source', () {
      final state = ArcBlueprintState.empty('tempest').copyWith(
        owned: true,
        ownershipSource: ArcBlueprintOwnershipSource.manual,
      );

      expect(state.isManualOwnership, isTrue);
      expect(state.toMap()['ownershipSource'], 'manual');

      final cleared = state.copyWith(owned: false, dupesOwned: 0);
      expect(cleared.owned, isFalse);
      expect(cleared.ownershipSource, ArcBlueprintOwnershipSource.unknown);
    });

    test('confident missing removes explicit manual ownership', () {
      final existing = <String, ArcBlueprintState>{
        'wrong': owned('wrong', source: ArcBlueprintOwnershipSource.manual),
      };

      final updates =
          ArcBlueprintPhotoImportService.buildOwnershipReconciliationUpdates(
            decisions: <ArcBlueprintPhotoCellDecision>[
              decision('wrong', ArcBlueprintPhotoCellState.missing),
            ],
            existing: existing,
          );

      expect(updates, hasLength(1));
      expect(updates.single.owned, isFalse);
      expect(
        updates.single.ownershipSource,
        ArcBlueprintOwnershipSource.unknown,
      );
    });

    test('uncertain never removes manual ownership', () {
      final existing = <String, ArcBlueprintState>{
        'maybe': owned('maybe', source: ArcBlueprintOwnershipSource.manual),
      };

      final updates =
          ArcBlueprintPhotoImportService.buildOwnershipReconciliationUpdates(
            decisions: <ArcBlueprintPhotoCellDecision>[
              decision('maybe', ArcBlueprintPhotoCellState.uncertain),
            ],
            existing: existing,
          );

      expect(updates, isEmpty);
    });

    test(
      'scan-confirmed ownership is never removed by a later missing result',
      () {
        final existing = <String, ArcBlueprintState>{
          'confirmed': owned(
            'confirmed',
            source: ArcBlueprintOwnershipSource.scan,
          ),
        };

        final updates =
            ArcBlueprintPhotoImportService.buildOwnershipReconciliationUpdates(
              decisions: <ArcBlueprintPhotoCellDecision>[
                decision('confirmed', ArcBlueprintPhotoCellState.missing),
              ],
              existing: existing,
              allowLegacyUnknownCorrection: true,
            );

        expect(updates, isEmpty);
      },
    );

    test('duplicate state is never auto-cleared', () {
      final existing = <String, ArcBlueprintState>{
        'dupe': owned(
          'dupe',
          source: ArcBlueprintOwnershipSource.manual,
          dupes: 1,
        ),
      };

      final updates =
          ArcBlueprintPhotoImportService.buildOwnershipReconciliationUpdates(
            decisions: <ArcBlueprintPhotoCellDecision>[
              decision('dupe', ArcBlueprintPhotoCellState.missing),
            ],
            existing: existing,
            allowLegacyUnknownCorrection: true,
          );

      expect(updates, isEmpty);
    });

    test(
      'legacy unknown ownership only clears for trusted screenshot reconciliation',
      () {
        final existing = <String, ArcBlueprintState>{'legacy': owned('legacy')};

        final cameraUpdates =
            ArcBlueprintPhotoImportService.buildOwnershipReconciliationUpdates(
              decisions: <ArcBlueprintPhotoCellDecision>[
                decision('legacy', ArcBlueprintPhotoCellState.missing),
              ],
              existing: existing,
            );
        expect(cameraUpdates, isEmpty);

        final screenshotUpdates =
            ArcBlueprintPhotoImportService.buildOwnershipReconciliationUpdates(
              decisions: <ArcBlueprintPhotoCellDecision>[
                decision('legacy', ArcBlueprintPhotoCellState.missing),
              ],
              existing: existing,
              allowLegacyUnknownCorrection: true,
            );
        expect(screenshotUpdates, hasLength(1));
        expect(screenshotUpdates.single.owned, isFalse);
      },
    );

    test(
      'confident owned evidence promotes manual or legacy ownership to scan-confirmed',
      () {
        final existing = <String, ArcBlueprintState>{
          'tempest': owned(
            'tempest',
            source: ArcBlueprintOwnershipSource.manual,
          ),
          'legacy': owned('legacy'),
        };

        final updates =
            ArcBlueprintPhotoImportService.buildOwnershipReconciliationUpdates(
              decisions: <ArcBlueprintPhotoCellDecision>[
                decision('tempest', ArcBlueprintPhotoCellState.owned),
                decision('legacy', ArcBlueprintPhotoCellState.owned),
              ],
              existing: existing,
            );

        expect(updates, hasLength(2));
        expect(
          updates.every(
            (state) =>
                state.ownershipSource == ArcBlueprintOwnershipSource.scan,
          ),
          isTrue,
        );
      },
    );

    test('scanner-owned additions are saved with scan provenance', () {
      final updates = ArcBlueprintPhotoImportService.buildUpdates(
        decisions: <ArcBlueprintPhotoCellDecision>[
          decision('tempest', ArcBlueprintPhotoCellState.owned),
        ],
        existing: const <String, ArcBlueprintState>{},
      );

      expect(updates.single.owned, isTrue);
      expect(updates.single.ownershipSource, ArcBlueprintOwnershipSource.scan);
    });
  });
}
