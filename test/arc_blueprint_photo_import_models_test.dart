import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';

void main() {
  group('blueprint photo import models', () {
    test(
      'does not allow blueprint writes without confirmed high confidence',
      () {
        const session = ArcBlueprintPhotoImportSession(
          id: 'import-1',
          uid: 'user-1',
          status: ArcBlueprintPhotoImportStatus.needsUserReview,
          candidates: <ArcBlueprintPhotoCandidate>[
            ArcBlueprintPhotoCandidate(
              blueprintId: 'anvil',
              label: 'Anvil',
              confidence: 0.72,
            ),
          ],
        );

        expect(session.hasProviderConfigured, isFalse);
        expect(session.candidates.single.needsReview, isTrue);
        expect(session.canWriteBlueprintState, isFalse);
      },
    );

    test('serializes confirmed high-confidence import sessions', () {
      const session = ArcBlueprintPhotoImportSession(
        id: 'import-2',
        uid: 'user-1',
        status: ArcBlueprintPhotoImportStatus.confirmed,
        provider: 'configured_provider',
        candidates: <ArcBlueprintPhotoCandidate>[
          ArcBlueprintPhotoCandidate(
            blueprintId: 'anvil',
            label: 'Anvil',
            confidence: 0.96,
          ),
        ],
      );

      final restored = ArcBlueprintPhotoImportSession.fromMap(session.toMap());

      expect(restored.hasProviderConfigured, isTrue);
      expect(restored.canWriteBlueprintState, isTrue);
      expect(restored.candidates.single.blueprintId, 'anvil');
    });
  });
}
