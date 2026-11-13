import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_operations_models.dart';

class ArcCosmeticEquipability {
  const ArcCosmeticEquipability._();

  static bool canEquip(
    ArcRewardInventoryItem item, {
    required String currentSeasonId,
  }) {
    if (!item.isBadge &&
        !item.isTitle &&
        !item.isProfileFrame &&
        !item.isProfileBanner) {
      return false;
    }
    if (item.permanent || item.equipableAfterSeason) return true;
    if (item.sourceSeasonId == null || item.sourceSeasonId!.isEmpty) {
      return item.currentSeasonUnlock;
    }
    return item.currentSeasonUnlock && item.sourceSeasonId == currentSeasonId;
  }

  static bool isExpiredSeasonOnly(
    ArcRewardInventoryItem item, {
    required String currentSeasonId,
  }) {
    if (item.permanent || item.equipableAfterSeason) return false;
    if (item.sourceSeasonId == null || item.sourceSeasonId!.isEmpty) {
      return !item.currentSeasonUnlock;
    }
    return item.sourceSeasonId != currentSeasonId || !item.currentSeasonUnlock;
  }
}
