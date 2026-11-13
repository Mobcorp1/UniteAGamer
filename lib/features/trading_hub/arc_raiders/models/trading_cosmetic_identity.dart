import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_operations_models.dart';

class TradingCosmeticIdentity {
  const TradingCosmeticIdentity({
    required this.uid,
    this.displayName = '',
    this.gamerTag = '',
    this.preferredPlatform = '',
    this.equippedCosmetics = const ArcEquippedCosmetics(),
    this.badge,
    this.title,
    this.profileFrame,
    this.profileBanner,
  });

  final String uid;
  final String displayName;
  final String gamerTag;
  final String preferredPlatform;
  final ArcEquippedCosmetics equippedCosmetics;
  final ArcRewardInventoryItem? badge;
  final ArcRewardInventoryItem? title;
  final ArcRewardInventoryItem? profileFrame;
  final ArcRewardInventoryItem? profileBanner;

  static const empty = TradingCosmeticIdentity(uid: '');

  String? get badgeAssetPath =>
      _assetPath(badge, equippedCosmetics.badgeAssetPath);

  String get titleLabel => _label(
    item: title,
    persistedLabel: equippedCosmetics.titleLabel,
    persistedId: equippedCosmetics.titleId,
  );

  String? get profileFrameAssetPath =>
      _assetPath(profileFrame, equippedCosmetics.profileFrameAssetPath);

  String? get profileBannerAssetPath =>
      _assetPath(profileBanner, equippedCosmetics.profileBannerAssetPath);

  bool get hasBadge => badge != null || equippedCosmetics.hasBadge;
  bool get hasTitle => titleLabel.isNotEmpty;
  bool get hasProfileFrame =>
      profileFrame != null || equippedCosmetics.hasFrame;
  bool get hasProfileBanner =>
      profileBanner != null || equippedCosmetics.hasBanner;

  ArcCosmeticRarity get badgeRarity =>
      badge?.rarity ?? ArcCosmeticRarity.common;
  ArcCosmeticRarity get titleRarity =>
      title?.rarity ?? ArcCosmeticRarity.common;
  ArcCosmeticRarity get profileFrameRarity =>
      profileFrame?.rarity ?? ArcCosmeticRarity.common;
  ArcCosmeticRarity get profileBannerRarity =>
      profileBanner?.rarity ?? ArcCosmeticRarity.common;

  static String? _assetPath(
    ArcRewardInventoryItem? item,
    String? persistedAssetPath,
  ) {
    final itemAsset = item?.assetPath;
    if (itemAsset != null && itemAsset.isNotEmpty) return itemAsset;
    if (persistedAssetPath != null && persistedAssetPath.isNotEmpty) {
      return persistedAssetPath;
    }
    return null;
  }

  static String _label({
    required ArcRewardInventoryItem? item,
    required String? persistedLabel,
    required String? persistedId,
  }) {
    if (item != null && item.label.isNotEmpty) return item.label;
    if (persistedLabel != null && persistedLabel.isNotEmpty) {
      return persistedLabel;
    }
    if (persistedId != null && persistedId.isNotEmpty) return persistedId;
    return '';
  }
}
