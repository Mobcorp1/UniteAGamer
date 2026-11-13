import 'arc_frozen_trail_collection_catalogue.dart';
import '../models/arc_collection_models.dart';

/// Frozen Trail migration contract for the Blueprint scanner.
///
/// The underlying recognition/evidence pipeline is intentionally preserved.
/// Only physical grid geometry and slot-to-blueprint identity need to migrate.
///
/// Automatic ownership application MUST remain on the legacy 83-slot contract
/// until all 91 slot identities are verified. Feeding unknown positions into
/// the ownership repository would risk assigning a detected cell to the wrong
/// Blueprint.
class ArcFrozenTrailBlueprintGridMigration {
  const ArcFrozenTrailBlueprintGridMigration._();

  static const int legacyBlueprintCount = 83;
  static const int frozenTrailBlueprintCount = 91;
  static const int columns = 17;
  static const List<int> rowColumnCounts = <int>[17, 17, 17, 17, 17, 6];

  // Slot occupation alone is not verification. Provisional legacy entries
  // deliberately retain their historical IDs but MUST NOT authorise a scanner
  // import until their positions have been confirmed in-game.
  static int get verifiedSlotCount => ArcFrozenTrailCollectionCatalogue
      .blueprintEntries
      .where((entry) =>
          entry.slot != null &&
          entry.confidence == ArcCollectionSlotConfidence.verifiedInGame)
      .length;

  static int get unresolvedSlotCount =>
      frozenTrailBlueprintCount - verifiedSlotCount;

  static bool get scannerAutoApplyReady =>
      verifiedSlotCount == frozenTrailBlueprintCount;

  static const String scannerBlockingReason =
      'Frozen Trail uses a 91-slot 17-column Blueprint grid. '
      'Recognition logic can be reused, but automatic ownership import must '
      'not switch from the legacy 83-slot mapping until every new slot identity '
      'has been verified in-game.';
}
