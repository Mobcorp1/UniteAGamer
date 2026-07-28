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

    test('flags provider configuration before OCR can run', () {
      const session = ArcBlueprintPhotoImportSession(
        id: 'import-provider',
        uid: 'user-1',
        status: ArcBlueprintPhotoImportStatus.awaitingProvider,
      );

      expect(session.providerConfigurationRequired, isTrue);
      expect(session.canWriteBlueprintState, isFalse);
    });

    test('serializes confirmed high-confidence import sessions', () {
      const session = ArcBlueprintPhotoImportSession(
        id: 'import-2',
        uid: 'user-1',
        status: ArcBlueprintPhotoImportStatus.confirmed,
        provider: 'configured_provider',
        confirmedByUser: true,
        writePreviewOnly: false,
        candidates: <ArcBlueprintPhotoCandidate>[
          ArcBlueprintPhotoCandidate(
            blueprintId: 'anvil',
            label: 'Anvil',
            confidence: 0.96,
          ),
        ],
        captures: <ArcBlueprintPhotoCapture>[
          ArcBlueprintPhotoCapture(
            id: 'capture-1',
            imagePath: 'gs://bucket/user/import-2/capture-1.webp',
            sequenceIndex: 0,
            detectedRows: 4,
            detectedCells: 20,
            overlapSignature: 'row-a',
          ),
        ],
        reviewChanges: <ArcBlueprintPhotoReviewChange>[
          ArcBlueprintPhotoReviewChange(
            blueprintId: 'anvil',
            owned: true,
            source: 'template_match',
            confidence: 0.96,
          ),
        ],
      );

      final restored = ArcBlueprintPhotoImportSession.fromMap(session.toMap());

      expect(restored.hasProviderConfigured, isTrue);
      expect(restored.canWriteBlueprintState, isTrue);
      expect(restored.candidates.single.blueprintId, 'anvil');
      expect(restored.captures.single.overlapSignature, 'row-a');
      expect(restored.reviewChanges.single.needsReview, isFalse);
    });

    test(
      'requires explicit user confirmation before writing blueprint state',
      () {
        const session = ArcBlueprintPhotoImportSession(
          id: 'import-3',
          uid: 'user-1',
          status: ArcBlueprintPhotoImportStatus.confirmed,
          provider: 'configured_provider',
          candidates: <ArcBlueprintPhotoCandidate>[
            ArcBlueprintPhotoCandidate(
              blueprintId: 'anvil',
              label: 'Anvil',
              confidence: 0.97,
            ),
          ],
        );

        expect(session.canWriteBlueprintState, isFalse);
        expect(session.writePreviewOnly, isTrue);
      },
    );
  });
}
