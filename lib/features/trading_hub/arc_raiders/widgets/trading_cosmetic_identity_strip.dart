import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_operations_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_cosmetic_identity.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/trading_repository.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class TradingCosmeticIdentityStrip extends StatelessWidget {
  const TradingCosmeticIdentityStrip({
    super.key,
    required this.repository,
    required this.uid,
    required this.displayName,
    this.subtitle,
    this.compact = false,
    this.showBanner = true,
  });

  final TradingRepository repository;
  final String uid;
  final String displayName;
  final String? subtitle;
  final bool compact;
  final bool showBanner;

  Color _rarityAccent(ArcCosmeticRarity rarity) {
    return switch (rarity) {
      ArcCosmeticRarity.common => AppTheme.neonCyan,
      ArcCosmeticRarity.uncommon => Colors.lightGreenAccent,
      ArcCosmeticRarity.rare => Colors.lightBlueAccent,
      ArcCosmeticRarity.epic => AppTheme.neonPink,
      ArcCosmeticRarity.legendary => Colors.amberAccent,
      ArcCosmeticRarity.founder => Colors.amberAccent,
      ArcCosmeticRarity.closedBeta => AppTheme.neonCyan,
      ArcCosmeticRarity.community => Colors.lightGreenAccent,
      ArcCosmeticRarity.creator => AppTheme.neonPink,
    };
  }

  Widget _bannerBackdrop(TradingCosmeticIdentity cosmetics, Color accent) {
    final assetPath = cosmetics.profileBannerAssetPath;
    if (assetPath != null && assetPath.isNotEmpty) {
      return Opacity(
        opacity: 0.30,
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          errorBuilder: (_, _, _) => _bannerFallback(cosmetics, accent),
        ),
      );
    }

    return _bannerFallback(cosmetics, accent);
  }

  Widget _bannerFallback(TradingCosmeticIdentity cosmetics, Color accent) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: cosmetics.hasProfileBanner ? 0.18 : 0.08),
            Colors.transparent,
            AppTheme.neonPink.withValues(
              alpha: cosmetics.hasProfileBanner ? 0.11 : 0.05,
            ),
          ],
        ),
      ),
    );
  }

  Widget _badgeOrb(TradingCosmeticIdentity cosmetics, double size) {
    final badgeAsset = cosmetics.badgeAssetPath;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.cardBackground.withValues(alpha: 0.94),
        border: Border.all(
          color: AppTheme.neonCyan.withValues(alpha: 0.72),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonCyan.withValues(alpha: 0.20),
            blurRadius: 10,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: ClipOval(
        child: badgeAsset != null && badgeAsset.isNotEmpty
            ? Image.asset(
                badgeAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  Icons.military_tech_rounded,
                  color: AppTheme.neonCyan,
                  size: size * 0.58,
                ),
              )
            : Icon(
                Icons.military_tech_rounded,
                color: AppTheme.neonCyan,
                size: size * 0.58,
              ),
      ),
    );
  }

  Widget _avatar(
    TradingCosmeticIdentity cosmetics,
    String effectiveName,
    Color frameAccent,
  ) {
    final avatarSize = compact ? 46.0 : 54.0;
    final badgeSize = compact ? 20.0 : 23.0;
    final frameAsset = cosmetics.profileFrameAssetPath;
    final hasFrame = cosmetics.hasProfileFrame;

    return SizedBox(
      width: avatarSize + 4,
      height: avatarSize + 4,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: frameAccent.withValues(alpha: hasFrame ? 0.88 : 0.58),
                  width: hasFrame ? 2.2 : 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: frameAccent.withValues(
                      alpha: hasFrame ? 0.22 : 0.12,
                    ),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (frameAsset != null && frameAsset.isNotEmpty)
                    ClipOval(
                      child: Image.asset(
                        frameAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.all(hasFrame ? 5 : 0),
                    child: CircleAvatar(
                      backgroundColor: AppTheme.cardBackgroundAlt,
                      child: Text(
                        (effectiveName.isNotEmpty ? effectiveName[0] : 'T')
                            .toUpperCase(),
                        style: AppTheme.tradingHeading(
                          fontSize: compact ? 18 : 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: _badgeOrb(cosmetics, badgeSize),
          ),
        ],
      ),
    );
  }

  String _effectiveSubtitle(TradingCosmeticIdentity cosmetics) {
    if (subtitle != null && subtitle!.trim().isNotEmpty) {
      return subtitle!.trim();
    }

    final parts = <String>[
      if (cosmetics.gamerTag.trim().isNotEmpty) cosmetics.gamerTag.trim(),
      if (cosmetics.preferredPlatform.trim().isNotEmpty)
        cosmetics.preferredPlatform.trim(),
    ];
    return parts.join(' - ');
  }

  Widget _buildContent(TradingCosmeticIdentity cosmetics) {
    final effectiveName = cosmetics.displayName.trim().isNotEmpty
        ? cosmetics.displayName.trim()
        : displayName.trim().isNotEmpty
        ? displayName.trim()
        : 'Unknown Trader';
    final frameAccent = _rarityAccent(cosmetics.profileFrameRarity);
    final bannerAccent = _rarityAccent(cosmetics.profileBannerRarity);
    final titleLabel = cosmetics.titleLabel;
    final subtitleText = _effectiveSubtitle(cosmetics);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: AppTheme.tradingCardDecoration(
        radius: 16,
        borderColor: bannerAccent.withValues(alpha: 0.22),
        backgroundColor: AppTheme.cardBackgroundAlt.withValues(alpha: 0.74),
      ),
      child: Stack(
        children: [
          if (showBanner)
            Positioned.fill(child: _bannerBackdrop(cosmetics, bannerAccent)),
          Padding(
            padding: EdgeInsets.all(compact ? 10 : 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 260;
                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      effectiveName,
                      maxLines: narrow ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.tradingHeading(
                        fontSize: compact ? 16 : 18,
                        color: Colors.white,
                      ),
                    ),
                    if (titleLabel.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        titleLabel.toUpperCase(),
                        maxLines: narrow ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodyTextStyle(
                          fontSize: compact ? 11 : 12,
                          color: bannerAccent,
                          isBold: true,
                        ),
                      ),
                    ],
                    if (subtitleText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitleText,
                        maxLines: narrow ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodyTextStyle(
                          fontSize: compact ? 11 : 12,
                          color: AppTheme.tradingMutedText,
                        ),
                      ),
                    ],
                  ],
                );

                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _avatar(cosmetics, effectiveName, frameAccent),
                      const SizedBox(height: 8),
                      details,
                    ],
                  );
                }

                return Row(
                  children: [
                    _avatar(cosmetics, effectiveName, frameAccent),
                    SizedBox(width: compact ? 10 : 12),
                    Expanded(child: details),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (uid.trim().isEmpty) {
      return _buildContent(TradingCosmeticIdentity.empty);
    }

    return StreamBuilder<TradingCosmeticIdentity>(
      stream: repository.watchTraderCosmeticIdentity(uid),
      builder: (context, snapshot) {
        return _buildContent(snapshot.data ?? TradingCosmeticIdentity.empty);
      },
    );
  }
}
