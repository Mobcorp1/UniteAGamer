import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/uag_avatar_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_operations_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trader_profile.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/electric_charge_border.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class _LockerCatalogueItem {
  const _LockerCatalogueItem({
    required this.id,
    required this.label,
    required this.type,
    required this.rarity,
    this.assetPath,
  });

  final String id;
  final String label;
  final ArcOperationRewardType type;
  final ArcCosmeticRarity rarity;
  final String? assetPath;
}

const _lockerCatalogue = <_LockerCatalogueItem>[
  _LockerCatalogueItem(
    id: 'beta_access',
    label: 'Beta Access Badge',
    type: ArcOperationRewardType.badge,
    rarity: ArcCosmeticRarity.closedBeta,
    assetPath: 'assets/arc_raiders/operations/badges/beta_access_plus.png',
  ),
  _LockerCatalogueItem(
    id: 'founding_raider',
    label: 'Founding Raider Badge',
    type: ArcOperationRewardType.badge,
    rarity: ArcCosmeticRarity.founder,
    assetPath: 'assets/arc_raiders/operations/badges/founding_raider.png',
  ),
  _LockerCatalogueItem(
    id: 'pathfinder_badge',
    label: 'Pathfinder Badge',
    type: ArcOperationRewardType.badge,
    rarity: ArcCosmeticRarity.legendary,
    assetPath: 'assets/arc_raiders/operations/badges/pathfinder.png',
  ),
  _LockerCatalogueItem(
    id: 'trailblazer_badge',
    label: 'Trailblazer Badge',
    type: ArcOperationRewardType.badge,
    rarity: ArcCosmeticRarity.epic,
    assetPath: 'assets/arc_raiders/operations/badges/trailblazer.png',
  ),
  _LockerCatalogueItem(
    id: 'trade_pioneer',
    label: 'Trade Pioneer Badge',
    type: ArcOperationRewardType.badge,
    rarity: ArcCosmeticRarity.rare,
    assetPath: 'assets/arc_raiders/operations/badges/golden_pathfinder.png',
  ),
  _LockerCatalogueItem(
    id: 'intel_officer',
    label: 'Intel Officer Badge',
    type: ArcOperationRewardType.badge,
    rarity: ArcCosmeticRarity.rare,
    assetPath: 'assets/arc_raiders/operations/badges/pathfinder.png',
  ),
  _LockerCatalogueItem(
    id: 'community_raider',
    label: 'Community Raider Badge',
    type: ArcOperationRewardType.badge,
    rarity: ArcCosmeticRarity.community,
    assetPath: 'assets/arc_raiders/operations/badges/community_heart.png',
  ),
  _LockerCatalogueItem(
    id: 'og_legend',
    label: 'OG Legend Badge',
    type: ArcOperationRewardType.badge,
    rarity: ArcCosmeticRarity.legendary,
    assetPath: 'assets/arc_raiders/operations/badges/og_legend.png',
  ),
  _LockerCatalogueItem(
    id: 'inner_circle',
    label: 'UAG Inner Circle Badge',
    type: ArcOperationRewardType.badge,
    rarity: ArcCosmeticRarity.founder,
    assetPath: 'assets/arc_raiders/operations/badges/inner_circle.png',
  ),
  _LockerCatalogueItem(
    id: 'early_supporter_badge',
    label: 'Early Supporter Badge',
    type: ArcOperationRewardType.badge,
    rarity: ArcCosmeticRarity.epic,
    assetPath: 'assets/arc_raiders/operations/badges/early_supporter.png',
  ),
  _LockerCatalogueItem(
    id: 'unity_badge',
    label: 'Unity Emblem',
    type: ArcOperationRewardType.badge,
    rarity: ArcCosmeticRarity.community,
    assetPath: 'assets/arc_raiders/operations/badges/unity_emblem.png',
  ),
  _LockerCatalogueItem(
    id: 'beta_pioneer_badge',
    label: 'Beta Pioneer Badge',
    type: ArcOperationRewardType.badge,
    rarity: ArcCosmeticRarity.closedBeta,
    assetPath: 'assets/arc_raiders/operations/badges/beta_pioneer.png',
  ),

  _LockerCatalogueItem(
    id: 'field_tester',
    label: 'FIELD TESTER',
    type: ArcOperationRewardType.title,
    rarity: ArcCosmeticRarity.closedBeta,
  ),
  _LockerCatalogueItem(
    id: 'trusted_trader_title',
    label: 'TRUSTED TRADER',
    type: ArcOperationRewardType.title,
    rarity: ArcCosmeticRarity.rare,
  ),
  _LockerCatalogueItem(
    id: 'blueprint_sage_title',
    label: 'BLUEPRINT SAGE',
    type: ArcOperationRewardType.title,
    rarity: ArcCosmeticRarity.epic,
  ),
  _LockerCatalogueItem(
    id: 'guardian_title',
    label: 'GUARDIAN',
    type: ArcOperationRewardType.title,
    rarity: ArcCosmeticRarity.community,
  ),
  _LockerCatalogueItem(
    id: 'pathfinder_title',
    label: 'PATHFINDER',
    type: ArcOperationRewardType.title,
    rarity: ArcCosmeticRarity.legendary,
  ),
  _LockerCatalogueItem(
    id: 'og_raider_title',
    label: 'OG RAIDER',
    type: ArcOperationRewardType.title,
    rarity: ArcCosmeticRarity.founder,
  ),

  _LockerCatalogueItem(
    id: 'beta_signal_frame',
    label: 'Beta Signal Frame',
    type: ArcOperationRewardType.profileFrame,
    rarity: ArcCosmeticRarity.closedBeta,
  ),
  _LockerCatalogueItem(
    id: 'guardian_signal_frame',
    label: 'Guardian Signal Frame',
    type: ArcOperationRewardType.profileFrame,
    rarity: ArcCosmeticRarity.community,
  ),
  _LockerCatalogueItem(
    id: 'pathfinder_frame',
    label: 'Pathfinder Frame',
    type: ArcOperationRewardType.profileFrame,
    rarity: ArcCosmeticRarity.legendary,
  ),
  _LockerCatalogueItem(
    id: 'trade_elite_frame',
    label: 'Trade Elite Frame',
    type: ArcOperationRewardType.profileFrame,
    rarity: ArcCosmeticRarity.epic,
  ),
  _LockerCatalogueItem(
    id: 'inner_circle_frame',
    label: 'Inner Circle Frame',
    type: ArcOperationRewardType.profileFrame,
    rarity: ArcCosmeticRarity.founder,
  ),
  _LockerCatalogueItem(
    id: 'intel_command_frame',
    label: 'Intel Command Frame',
    type: ArcOperationRewardType.profileFrame,
    rarity: ArcCosmeticRarity.rare,
  ),

  _LockerCatalogueItem(
    id: 'beta_command_banner',
    label: 'Beta Command Banner',
    type: ArcOperationRewardType.profileBanner,
    rarity: ArcCosmeticRarity.closedBeta,
  ),
  _LockerCatalogueItem(
    id: 'guardian_banner',
    label: 'Guardian Banner',
    type: ArcOperationRewardType.profileBanner,
    rarity: ArcCosmeticRarity.community,
  ),
  _LockerCatalogueItem(
    id: 'pathfinder_banner',
    label: 'Pathfinder Banner',
    type: ArcOperationRewardType.profileBanner,
    rarity: ArcCosmeticRarity.legendary,
  ),
  _LockerCatalogueItem(
    id: 'trade_command_banner',
    label: 'Trade Command Banner',
    type: ArcOperationRewardType.profileBanner,
    rarity: ArcCosmeticRarity.epic,
  ),
  _LockerCatalogueItem(
    id: 'inner_circle_banner',
    label: 'Inner Circle Banner',
    type: ArcOperationRewardType.profileBanner,
    rarity: ArcCosmeticRarity.founder,
  ),
  _LockerCatalogueItem(
    id: 'intel_network_banner',
    label: 'Intel Network Banner',
    type: ArcOperationRewardType.profileBanner,
    rarity: ArcCosmeticRarity.rare,
  ),
];

class UagProfileCosmeticLocker extends StatefulWidget {
  const UagProfileCosmeticLocker({
    super.key,
    required this.profile,
    required this.operationsState,
    required this.onManageAvatars,
  });

  final ArcTraderProfile profile;
  final ArcOperationsUserState operationsState;
  final VoidCallback onManageAvatars;

  @override
  State<UagProfileCosmeticLocker> createState() =>
      _UagProfileCosmeticLockerState();
}

class _UagProfileCosmeticLockerState extends State<UagProfileCosmeticLocker> {
  final ArcOperationsRepository _repository = ArcOperationsRepository();

  int _tabIndex = 0;
  String? _busyRewardId;

  static const _tabs = <String>[
    'AVATARS',
    'BADGES',
    'TITLES',
    'FRAMES',
    'BANNERS',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonCyan.withValues(alpha: 0.22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.checkroom_rounded,
                color: AppTheme.neonCyan,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spaceS),
              Expanded(
                child: Text(
                  'COSMETIC LOCKER',
                  style: AppTheme.tradingHeading(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              _ownedCountPill(),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            'Browse the full collection. Earned items can be equipped; locked rewards still show their rarity and identity.',
            style: TextStyle(color: Colors.white60, fontSize: 11, height: 1.3),
          ),
          const SizedBox(height: 10),
          _tabsBar(),
          const SizedBox(height: 10),
          KeyedSubtree(key: ValueKey<int>(_tabIndex), child: _tabBody()),
        ],
      ),
    );
  }

  Widget _ownedCountPill() {
    final state = widget.operationsState;
    final owned =
        state.badges.length +
        state.titles.length +
        state.profileFrames.length +
        state.profileBanners.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: AppTheme.tradingPillDecoration(color: AppTheme.neonPink),
      child: Text(
        '$owned OWNED TOTAL',
        style: const TextStyle(
          color: AppTheme.neonPink,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.45,
        ),
      ),
    );
  }

  Widget _tabsBar() {
    return SingleChildScrollView(
      key: const ValueKey<String>('locker-category-strip'),
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          return Padding(
            padding: EdgeInsets.only(right: index == _tabs.length - 1 ? 0 : 8),
            child: _tabButton(index),
          );
        }),
      ),
    );
  }

  Widget _tabButton(int index) {
    final selected = _tabIndex == index;
    return Semantics(
      button: true,
      selected: selected,
      label: _tabs[index],
      child: InkWell(
        key: ValueKey<String>('locker-tab-${_tabs[index].toLowerCase()}'),
        onTap: () => setState(() => _tabIndex = index),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minWidth: 116),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.neonCyan.withValues(alpha: 0.12)
                : AppTheme.cardBackgroundAlt.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppTheme.neonCyan
                  : Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: Text(
            _tabs[index],
            style: TextStyle(
              color: selected ? AppTheme.neonCyan : Colors.white60,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabBody() {
    switch (_tabIndex) {
      case 1:
        return _rewardInventory(
          items: widget.operationsState.badges,
          equippedId: widget.operationsState.equippedCosmetics.badgeId,
          emptyTitle: 'No badges earned yet',
          emptyCopy:
              'Badges unlock through Operations, beta milestones, trading and community achievements.',
          typeIcon: Icons.military_tech_rounded,
        );
      case 2:
        return _rewardInventory(
          items: widget.operationsState.titles,
          equippedId: widget.operationsState.equippedCosmetics.titleId,
          emptyTitle: 'No titles earned yet',
          emptyCopy:
              'Earn titles through Operations and community reputation, then equip them here.',
          typeIcon: Icons.title_rounded,
        );
      case 3:
        return _rewardInventory(
          items: widget.operationsState.profileFrames,
          equippedId: widget.operationsState.equippedCosmetics.profileFrameId,
          emptyTitle: 'No profile frames earned yet',
          emptyCopy:
              'Frames unlock through Operations and community milestones.',
          typeIcon: Icons.crop_square_rounded,
        );
      case 4:
        return _rewardInventory(
          items: widget.operationsState.profileBanners,
          equippedId: widget.operationsState.equippedCosmetics.profileBannerId,
          emptyTitle: 'No profile banners earned yet',
          emptyCopy:
              'Banners unlock through Operations and community milestones.',
          typeIcon: Icons.crop_16_9_rounded,
        );
      default:
        return _avatarPanel();
    }
  }

  Widget _avatarPanel() {
    final avatar = UagAvatarCatalog.byId(widget.profile.avatarId);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final preview = Container(
          width: compact ? 104 : 126,
          height: compact ? 104 : 126,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.neonCyan.withValues(alpha: 0.72),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.neonCyan.withValues(alpha: 0.18),
                blurRadius: 20,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              avatar.assetPath,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.person_rounded,
                color: AppTheme.neonCyan,
                size: 48,
              ),
            ),
          ),
        );

        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              avatar.label.toUpperCase(),
              style: AppTheme.tradingHeading(fontSize: 20, color: Colors.white),
            ),
            const SizedBox(height: 5),
            Text(
              '${UagAvatarCatalog.options.length} AVATARS',
              style: ArcUiTokens.label(
                color: AppTheme.neonCyan.withValues(alpha: 0.82),
              ).copyWith(fontSize: 10, letterSpacing: 0.8),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: widget.onManageAvatars,
              icon: const Icon(Icons.grid_view_rounded),
              label: const Text('MANAGE AVATARS'),
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: preview),
              const SizedBox(height: AppTheme.spaceM),
              copy,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            preview,
            const SizedBox(width: AppTheme.spaceL),
            Expanded(child: copy),
          ],
        );
      },
    );
  }

  Widget _rewardInventory({
    required List<ArcRewardInventoryItem> items,
    required String? equippedId,
    required String emptyTitle,
    required String emptyCopy,
    required IconData typeIcon,
  }) {
    final type = switch (_tabIndex) {
      1 => ArcOperationRewardType.badge,
      2 => ArcOperationRewardType.title,
      3 => ArcOperationRewardType.profileFrame,
      _ => ArcOperationRewardType.profileBanner,
    };
    final catalogue = _lockerCatalogue
        .where((entry) => entry.type == type)
        .toList(growable: false);
    final ownedById = <String, ArcRewardInventoryItem>{
      for (final item in items) item.rewardId: item,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (items.isEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: AppTheme.spaceS),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.025),
                borderRadius: BorderRadius.circular(ArcUiTokens.radiusS),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Icon(typeIcon, color: Colors.white38, size: 16),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '$emptyTitle · $emptyCopy',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 9.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          _sectionLabel(
            'COLLECTION',
            '${items.length} earned · ${catalogue.length} total',
          ),
          const SizedBox(height: AppTheme.spaceS),
          if (catalogue.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.025),
                borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
                border: Border.all(color: Colors.white10),
              ),
              child: const Text(
                'Collection data is unavailable right now.',
                style: TextStyle(color: Colors.white60),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                final columns = type == ArcOperationRewardType.profileBanner
                    ? (availableWidth >= 900 ? 3 : availableWidth >= 560 ? 2 : 1)
                    : (availableWidth >= 1180
                          ? 5
                          : availableWidth >= 900
                          ? 4
                          : availableWidth >= 620
                          ? 3
                          : 2);
                final totalSpacing = 8.0 * (columns - 1);
                final cardWidth = (availableWidth - totalSpacing) / columns;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: catalogue
                      .map((entry) {
                        final owned = ownedById[entry.id];
                        if (owned != null) {
                          return SizedBox(
                            width: cardWidth,
                            child: _cosmeticCard(
                              item: owned,
                              equipped: owned.rewardId == equippedId,
                              typeIcon: typeIcon,
                            ),
                          );
                        }
                        return SizedBox(
                          width: cardWidth,
                          child: _lockedCatalogueCard(entry, typeIcon),
                        );
                      })
                      .toList(growable: false),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title, String detail) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        const Spacer(),
        Text(
          detail,
          style: const TextStyle(color: Colors.white38, fontSize: 9),
        ),
      ],
    );
  }

  Widget _lockedCatalogueCard(_LockerCatalogueItem entry, IconData typeIcon) {
    final accent = _rarityAccent(entry.rarity);
    final isTitle = entry.type == ArcOperationRewardType.title;
    final isBanner = entry.type == ArcOperationRewardType.profileBanner;
    final isFrame = entry.type == ArcOperationRewardType.profileFrame;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 150),
      padding: const EdgeInsets.all(AppTheme.spaceS),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundAlt.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: isBanner ? 62 : 68,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: 0.42,
                  child: _cataloguePreview(
                    entry: entry,
                    accent: accent,
                    typeIcon: typeIcon,
                    isTitle: isTitle,
                    isFrame: isFrame,
                  ),
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.66),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Text(
            entry.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _rarityLabel(entry.rarity),
            style: TextStyle(
              color: accent.withValues(alpha: 0.72),
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ArcUiTokens.radiusS),
              border: Border.all(color: Colors.white12),
            ),
            child: const Text(
              'LOCKED',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.7,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cataloguePreview({
    required _LockerCatalogueItem entry,
    required Color accent,
    required IconData typeIcon,
    required bool isTitle,
    required bool isFrame,
  }) {
    if (entry.assetPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(ArcUiTokens.radiusS),
        child: Container(
          color: Colors.black.withValues(alpha: 0.3),
          child: Image.asset(
            entry.assetPath!,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(typeIcon, color: accent, size: 34),
          ),
        ),
      );
    }
    if (isTitle) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ArcUiTokens.radiusS),
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.22),
              Colors.black.withValues(alpha: 0.24),
            ],
          ),
          border: Border.all(color: accent.withValues(alpha: 0.28)),
        ),
        child: Text(
          entry.label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: accent,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
          ),
        ),
      );
    }
    if (isFrame) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
          border: Border.all(color: accent, width: 3),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: 0.22), blurRadius: 14),
          ],
        ),
        child: Center(
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accent.withValues(alpha: 0.65),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.person_rounded,
              color: accent.withValues(alpha: 0.7),
            ),
          ),
        ),
      );
    }
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ArcUiTokens.radiusS),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.24),
            Colors.black.withValues(alpha: 0.36),
            AppTheme.neonCyan.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Icon(typeIcon, color: accent, size: 32),
    );
  }

  String _rarityLabel(ArcCosmeticRarity rarity) => switch (rarity) {
    ArcCosmeticRarity.common => 'COMMON',
    ArcCosmeticRarity.uncommon => 'UNCOMMON',
    ArcCosmeticRarity.rare => 'RARE',
    ArcCosmeticRarity.epic => 'EPIC',
    ArcCosmeticRarity.legendary => 'LEGENDARY',
    ArcCosmeticRarity.founder => 'FOUNDER',
    ArcCosmeticRarity.closedBeta => 'CLOSED BETA',
    ArcCosmeticRarity.community => 'COMMUNITY',
    ArcCosmeticRarity.creator => 'CREATOR',
  };

  Widget _cosmeticCard({
    required ArcRewardInventoryItem item,
    required bool equipped,
    required IconData typeIcon,
  }) {
    final accent = _rarityAccent(item.rarity);
    final busy = _busyRewardId == item.rewardId;
    final isTitle = item.type == ArcOperationRewardType.title;
    final isBanner = item.type == ArcOperationRewardType.profileBanner;

    final card = Container(
      width: isBanner ? 232 : 158,
      constraints: const BoxConstraints(minHeight: 154),
      padding: const EdgeInsets.all(AppTheme.spaceS),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundAlt.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
        border: Border.all(
          color: equipped
              ? accent.withValues(alpha: 0.78)
              : accent.withValues(alpha: 0.18),
          width: equipped ? 1.5 : 1,
        ),
        boxShadow: equipped
            ? [BoxShadow(color: accent.withValues(alpha: 0.12), blurRadius: 16)]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: isBanner ? 62 : 68,
            child: _artPreview(
              item: item,
              accent: accent,
              typeIcon: typeIcon,
              isTitle: isTitle,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Text(
                item.rarityLabel.toUpperCase(),
                style: TextStyle(
                  color: accent,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.45,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: equipped
                ? OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.check_rounded, size: 15),
                    label: const Text('EQUIPPED'),
                  )
                : FilledButton(
                    onPressed: busy ? null : () => _equip(item),
                    child: busy
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('EQUIP'),
                  ),
          ),
        ],
      ),
    );

    return ElectricChargeBorder(
      active: equipped,
      radius: ArcUiTokens.radiusM,
      child: card,
    );
  }

  Widget _artPreview({
    required ArcRewardInventoryItem item,
    required Color accent,
    required IconData typeIcon,
    required bool isTitle,
  }) {
    final assetPath = item.assetPath;

    if (assetPath != null && assetPath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(ArcUiTokens.radiusS),
        child: Container(
          color: Colors.black.withValues(alpha: 0.28),
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => _fallbackArt(
              item: item,
              accent: accent,
              typeIcon: typeIcon,
              isTitle: isTitle,
            ),
          ),
        ),
      );
    }

    return _fallbackArt(
      item: item,
      accent: accent,
      typeIcon: typeIcon,
      isTitle: isTitle,
    );
  }

  Widget _fallbackArt({
    required ArcRewardInventoryItem item,
    required Color accent,
    required IconData typeIcon,
    required bool isTitle,
  }) {
    if (isTitle) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ArcUiTokens.radiusS),
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.16),
              Colors.black.withValues(alpha: 0.20),
            ],
          ),
          border: Border.all(color: accent.withValues(alpha: 0.20)),
        ),
        child: Text(
          item.label.toUpperCase(),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: accent,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.45,
          ),
        ),
      );
    }

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ArcUiTokens.radiusS),
        color: accent.withValues(alpha: 0.07),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Icon(typeIcon, color: accent, size: 34),
    );
  }

  Future<void> _equip(ArcRewardInventoryItem item) async {
    if (_busyRewardId != null) return;
    setState(() => _busyRewardId = item.rewardId);
    try {
      await _repository.equipCosmetic(item);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${item.label} equipped.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'That reward could not be equipped right now. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyRewardId = null);
    }
  }

  Color _rarityAccent(ArcCosmeticRarity rarity) {
    return switch (rarity) {
      ArcCosmeticRarity.common => Colors.white70,
      ArcCosmeticRarity.uncommon => Colors.lightGreenAccent,
      ArcCosmeticRarity.rare => AppTheme.neonCyan,
      ArcCosmeticRarity.epic => AppTheme.neonPink,
      ArcCosmeticRarity.legendary => Colors.orangeAccent,
      ArcCosmeticRarity.founder => Colors.amberAccent,
      ArcCosmeticRarity.closedBeta => Colors.amberAccent,
      ArcCosmeticRarity.community => Colors.lightBlueAccent,
      ArcCosmeticRarity.creator => Colors.purpleAccent,
    };
  }
}
