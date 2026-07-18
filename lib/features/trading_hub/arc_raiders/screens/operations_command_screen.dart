import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_operations_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_dynamic_operations_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_operations_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class OperationsCommandScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/operations';

  const OperationsCommandScreen({super.key});

  @override
  State<OperationsCommandScreen> createState() =>
      _OperationsCommandScreenState();
}

class _OperationsCommandScreenState extends State<OperationsCommandScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ArcOperationsRepository _repository = ArcOperationsRepository();
  String? _equippedBadgeRewardId;
  String? _equippedTitleRewardId;
  String? _selectedProfileFrameRewardId;
  String? _equippedProfileFrameRewardId;
  String? _selectedProfileBannerRewardId;
  String? _equippedProfileBannerRewardId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: 4);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: const ArcCompanionBottomDock(
        activeLabel: 'Operations',
      ),
      body: StreamBuilder<ArcOperationsUserState>(
        stream: _repository.watchUserState(),
        initialData: ArcOperationsUserState.empty,
        builder: (context, snapshot) {
          final userState = snapshot.data ?? ArcOperationsUserState.empty;
          return ArcRaidersScreenShell(
            useSafeArea: true,
            showAdBanner: true,
            child: ArcRaidersPageList(
              maxWidth: 1180,
              bottomPadding: 120,
              children: [
                ArcRaidersPageHeader(
                  title: 'OPERATIONS COMMAND',
                  subtitle:
                      'Adaptive rewards, beta trophies, community goals and permanent commendations.',
                  icon: Icons.military_tech_rounded,
                  accent: Colors.amberAccent,
                ),
                const SizedBox(height: 10),
                _buildHero(userState),
                const SizedBox(height: 10),
                _buildProfileRewardStrip(userState),
                const SizedBox(height: 10),
                _buildCommunityObjectivePanel(),
                const SizedBox(height: 10),
                _buildRewardVaultPanel(userState),
                const SizedBox(height: 10),
                _buildTabs(),
                const SizedBox(height: 10),
                _buildActiveTab(userState),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHero(ArcOperationsUserState userState) {
    final summary = ArcOperationsSeedData.summary;
    return ArcRaidersSectionCard(
      accent: Colors.amberAccent,
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final rank = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OPERATION LEVEL ${userState.operationLevel}',
                style: AppTheme.tradingHeading(
                  fontSize: compact ? 26 : 36,
                  color: Colors.amberAccent,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userState.equippedCosmetics.titleLabel ?? summary.rankLabel,
                style: AppTheme.bodyTextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  isBold: true,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Closed Beta Operations are exclusive and will never return after beta.',
                style: AppTheme.bodyTextStyle(
                  fontSize: 12,
                  color: Colors.white60,
                ),
              ),
            ],
          );

          final metrics = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: compact ? WrapAlignment.start : WrapAlignment.end,
            children: [
              _metric('Intel XP', '${userState.intelXp}', AppTheme.neonCyan),
              _metric(
                'Completed',
                '${userState.completedCount}',
                Colors.lightGreenAccent,
              ),
              _metric(
                'Trade Slots',
                '+${userState.extraTradeSlots}',
                AppTheme.neonPink,
              ),
              _metric(
                'Match Slots',
                '+${userState.extraMatchmakingSlots}',
                Colors.lightBlueAccent,
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [rank, const SizedBox(height: 12), metrics],
            );
          }

          return Row(
            children: [
              Expanded(child: rank),
              const SizedBox(width: 16),
              Flexible(child: metrics),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileRewardStrip(ArcOperationsUserState userState) {
    final equipped = userState.equippedCosmetics;
    final equippedBadge = _effectiveEquippedBadge(userState);
    final hasEquippedBadge =
        equippedBadge != null ||
        (equipped.hasBadge && _equippedBadgeRewardId == null);
    final equippedBadgeAssetPath =
        equippedBadge?.assetPath ??
        (_equippedBadgeRewardId == null ? equipped.badgeAssetPath : null);
    final equippedTitle = _effectiveEquippedTitle(userState);
    final equippedTitleLabel =
        equippedTitle?.label ??
        (_equippedTitleRewardId == null ? equipped.titleLabel : null);
    final equippedFrame = _effectiveEquippedProfileFrame(userState);
    final hasEquippedFrame =
        equippedFrame != null ||
        (equipped.hasFrame && _equippedProfileFrameRewardId == null);
    final equippedFrameAssetPath =
        equippedFrame?.assetPath ??
        (_equippedProfileFrameRewardId == null
            ? equipped.profileFrameAssetPath
            : null);
    return ArcRaidersSectionCard(
      accent: AppTheme.neonCyan,
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          final children = [
            _equippedPreview(
              label: 'Equipped Badge',
              value: hasEquippedBadge ? 'Active' : 'None equipped',
              assetPath: equippedBadgeAssetPath,
              icon: Icons.military_tech_rounded,
              accent: Colors.amberAccent,
            ),
            _equippedPreview(
              label: 'Profile Title',
              value: equippedTitleLabel ?? 'No title equipped',
              icon: Icons.title_rounded,
              accent: AppTheme.neonCyan,
            ),
            _equippedPreview(
              label: 'Profile Frame',
              value: hasEquippedFrame ? 'Frame active' : 'No frame equipped',
              assetPath: equippedFrameAssetPath,
              icon: Icons.crop_square_rounded,
              accent: AppTheme.neonPink,
            ),
            _equippedPreview(
              label: 'Inventory',
              value: '${userState.inventory.length} rewards owned',
              icon: Icons.inventory_2_rounded,
              accent: AppTheme.neonPink,
            ),
          ];
          if (compact) {
            return Column(children: _withVerticalSpacing(children, spacing: 8));
          }
          return Row(
            children: [
              for (final child in children)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: child,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _equippedPreview({
    required String label,
    required String value,
    String? assetPath,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            clipBehavior: Clip.antiAlias,
            child: assetPath == null
                ? Icon(icon, color: accent, size: 22)
                : Image.asset(assetPath, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppTheme.bodyTextStyle(
                    fontSize: 10,
                    color: Colors.white54,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    isBold: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _withVerticalSpacing(
    List<Widget> children, {
    required double spacing,
  }) {
    return [
      for (var index = 0; index < children.length; index++) ...[
        if (index > 0) SizedBox(height: spacing),
        children[index],
      ],
    ];
  }

  Widget _buildCommunityObjectivePanel() {
    return ArcRaidersSectionCard(
      accent: AppTheme.neonPink,
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final intro = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COMMUNITY OBJECTIVES',
                style: AppTheme.tradingHeading(
                  fontSize: compact ? 22 : 28,
                  color: AppTheme.neonPink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Operations will steer Raiders toward whatever the wider hub needs most: listings, verified intel, matchmaking, guardians or referrals.',
                style: AppTheme.bodyTextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ).copyWith(height: 1.25),
              ),
            ],
          );

          final objectives = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: compact ? WrapAlignment.start : WrapAlignment.end,
            children: [
              _objectiveTile('Market Health', '42%', AppTheme.neonPink),
              _objectiveTile('Verified Intel', '68%', AppTheme.neonCyan),
              _objectiveTile('Guardian Aid', '24%', Colors.amberAccent),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [intro, const SizedBox(height: 12), objectives],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: intro),
              const SizedBox(width: 14),
              Flexible(child: objectives),
            ],
          );
        },
      ),
    );
  }

  Widget _objectiveTile(String label, String value, Color accent) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTheme.tradingHeading(fontSize: 24, color: accent),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyTextStyle(fontSize: 10, color: Colors.white60),
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (int.tryParse(value.replaceAll('%', '')) ?? 0) / 100,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardVaultPanel(ArcOperationsUserState userState) {
    final previewRewards = ArcOperationsSeedData.rewards.values
        .where((reward) => reward.isCosmetic)
        .take(6)
        .toList();
    final badgeCount = userState.inventory.where((item) => item.isBadge).length;
    final titleCount = userState.inventory.where((item) => item.isTitle).length;
    final frameCount = userState.inventory
        .where((item) => item.type == ArcOperationRewardType.profileFrame)
        .length;
    final bannerCount = userState.inventory
        .where((item) => item.type == ArcOperationRewardType.profileBanner)
        .length;

    return ArcRaidersSectionCard(
      accent: Colors.amberAccent,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REWARD VAULT',
                      style: AppTheme.tradingHeading(
                        fontSize: 24,
                        color: Colors.amberAccent,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Unlocked cosmetics and honours earned through Operations. Beta rewards are permanent and exclusive.',
                      style: AppTheme.bodyTextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              _tagPill(
                '${userState.inventory.length} OWNED',
                AppTheme.neonCyan,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildVaultSummaryGrid(
            badgeCount: badgeCount,
            titleCount: titleCount,
            frameCount: frameCount,
            bannerCount: bannerCount,
          ),
          const SizedBox(height: 10),
          _buildSeasonalRewardSections(userState),
          const SizedBox(height: 10),
          _buildRecentUnlockPanel(userState),
          const SizedBox(height: 10),
          _buildBadgeInventoryGrid(userState),
          const SizedBox(height: 10),
          _buildTitleInventoryGrid(userState),
          const SizedBox(height: 10),
          _buildProfileFrameInventoryGrid(userState),
          const SizedBox(height: 10),
          _buildProfileBannerInventoryGrid(userState),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final reward in previewRewards)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _vaultRewardCard(reward),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonalRewardSections(ArcOperationsUserState userState) {
    final currentSeason = userState.inventory
        .where((item) => item.currentSeasonUnlock)
        .toList(growable: false);
    final permanent = userState.inventory
        .where((item) => !item.currentSeasonUnlock && item.permanent)
        .toList(growable: false);
    final previous = userState.inventory
        .where((item) => !item.currentSeasonUnlock && !item.permanent)
        .toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 780;
        final sections = [
          _seasonalVaultSection(
            title: 'CURRENT SEASON',
            subtitle: 'Unlocked this season or still active for this season.',
            items: currentSeason,
            emptyText: 'No current-season rewards unlocked yet.',
            accent: AppTheme.neonCyan,
          ),
          _seasonalVaultSection(
            title: 'PREVIOUS SEASONS',
            subtitle: 'Historical earned rewards retained after reset.',
            items: previous,
            emptyText: 'No previous-season-only rewards archived yet.',
            accent: AppTheme.neonPink,
          ),
          _seasonalVaultSection(
            title: 'PERMANENT',
            subtitle: 'Permanent cosmetics and honours that survive seasons.',
            items: permanent,
            emptyText:
                'Permanent rewards will appear here after they are archived from a season.',
            accent: Colors.amberAccent,
          ),
        ];

        if (compact) {
          return Column(children: _withVerticalSpacing(sections, spacing: 8));
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final section in sections)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: section,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _seasonalVaultSection({
    required String title,
    required String subtitle,
    required List<ArcRewardInventoryItem> items,
    required String emptyText,
    required Color accent,
  }) {
    final preview = items.take(4).toList(growable: false);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: accent.withValues(alpha: 0.22),
        backgroundColor: Colors.black.withValues(alpha: 0.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.tradingHeading(fontSize: 14, color: accent),
                ),
              ),
              _tinyVaultChip('${items.length}', accent),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyTextStyle(fontSize: 10, color: Colors.white60),
          ),
          const SizedBox(height: 8),
          if (preview.isEmpty)
            Text(
              emptyText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyTextStyle(
                fontSize: 11,
                color: Colors.white54,
              ),
            )
          else
            Column(
              children: [
                for (final item in preview)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          _rewardTypeIcon(item.type),
                          color: accent,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.bodyTextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              isBold: true,
                            ),
                          ),
                        ),
                        if (!item.equipableAfterSeason && !item.permanent)
                          _tinyVaultChip('HISTORICAL', Colors.orangeAccent),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildVaultSummaryGrid({
    required int badgeCount,
    required int titleCount,
    required int frameCount,
    required int bannerCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final children = [
          _vaultSummaryTile(
            icon: Icons.military_tech_rounded,
            label: 'Owned Badges',
            value: '$badgeCount',
            accent: Colors.amberAccent,
          ),
          _vaultSummaryTile(
            icon: Icons.title_rounded,
            label: 'Owned Titles',
            value: '$titleCount',
            accent: AppTheme.neonCyan,
          ),
          _vaultSummaryTile(
            icon: Icons.crop_square_rounded,
            label: 'Owned Frames',
            value: '$frameCount',
            accent: AppTheme.neonPink,
          ),
          _vaultSummaryTile(
            icon: Icons.view_day_rounded,
            label: 'Owned Banners',
            value: '$bannerCount',
            accent: Colors.lightBlueAccent,
          ),
        ];

        if (compact) {
          return Column(children: _withVerticalSpacing(children, spacing: 8));
        }

        return Row(
          children: [
            for (final child in children)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: child,
                ),
              ),
          ],
        );
      },
    );
  }

  double _vaultCardWidth(
    double availableWidth,
    int columns,
    double spacing, {
    required double minWidth,
    required double maxWidth,
  }) {
    if (availableWidth <= minWidth) return availableWidth;

    final calculated = (availableWidth - (spacing * (columns - 1))) / columns;
    final cappedMax = maxWidth > availableWidth ? availableWidth : maxWidth;
    if (cappedMax <= minWidth) return availableWidth;
    return calculated.clamp(minWidth, cappedMax).toDouble();
  }

  Widget _vaultSummaryTile({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTheme.tradingHeading(fontSize: 22, color: accent),
                ),
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 10,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _effectiveEquippedBadgeId(ArcOperationsUserState userState) {
    return _equippedBadgeRewardId ?? userState.equippedCosmetics.badgeId;
  }

  ArcRewardInventoryItem? _rewardById(
    Iterable<ArcRewardInventoryItem> rewards,
    String? rewardId,
  ) {
    if (rewardId == null) return null;
    for (final reward in rewards) {
      if (reward.rewardId == rewardId) return reward;
    }
    return null;
  }

  ArcRewardInventoryItem? _equippedOrFirstOwnedReward(
    List<ArcRewardInventoryItem> rewards,
    String? equippedId,
  ) {
    return _rewardById(rewards, equippedId) ??
        (rewards.isEmpty ? null : rewards.first);
  }

  ArcRewardInventoryItem? _effectiveEquippedBadge(
    ArcOperationsUserState userState,
  ) {
    return _rewardById(userState.badges, _effectiveEquippedBadgeId(userState));
  }

  String? _effectiveEquippedTitleId(ArcOperationsUserState userState) {
    return _equippedTitleRewardId ?? userState.equippedCosmetics.titleId;
  }

  ArcRewardInventoryItem? _effectiveEquippedTitle(
    ArcOperationsUserState userState,
  ) {
    return _rewardById(userState.titles, _effectiveEquippedTitleId(userState));
  }

  Future<void> _equipRewardVaultCosmetic(ArcRewardInventoryItem item) async {
    if (item.cosmeticType == null) return;

    final previousBadgeId = _equippedBadgeRewardId;
    final previousTitleId = _equippedTitleRewardId;
    final previousFrameId = _equippedProfileFrameRewardId;
    final previousBannerId = _equippedProfileBannerRewardId;
    final previousSelectedFrameId = _selectedProfileFrameRewardId;
    final previousSelectedBannerId = _selectedProfileBannerRewardId;

    setState(() {
      switch (item.type) {
        case ArcOperationRewardType.badge:
          _equippedBadgeRewardId = item.rewardId;
        case ArcOperationRewardType.title:
          _equippedTitleRewardId = item.rewardId;
        case ArcOperationRewardType.profileFrame:
          _equippedProfileFrameRewardId = item.rewardId;
          _selectedProfileFrameRewardId = item.rewardId;
        case ArcOperationRewardType.profileBanner:
          _equippedProfileBannerRewardId = item.rewardId;
          _selectedProfileBannerRewardId = item.rewardId;
        case ArcOperationRewardType.intelXp:
        case ArcOperationRewardType.tradeSlot:
        case ArcOperationRewardType.matchmakingSlot:
        case ArcOperationRewardType.premiumTrial:
        case ArcOperationRewardType.operationCredit:
          return;
      }
    });

    try {
      await _repository.equipCosmetic(item);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${item.label} equipped to your profile.',
            style: AppTheme.bodyTextStyle(fontSize: 12, color: Colors.white70),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _equippedBadgeRewardId = previousBadgeId;
        _equippedTitleRewardId = previousTitleId;
        _equippedProfileFrameRewardId = previousFrameId;
        _equippedProfileBannerRewardId = previousBannerId;
        _selectedProfileFrameRewardId = previousSelectedFrameId;
        _selectedProfileBannerRewardId = previousSelectedBannerId;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save that equipped cosmetic. Please try again.',
            style: AppTheme.bodyTextStyle(fontSize: 12, color: Colors.white70),
          ),
        ),
      );
    }
  }

  Widget _rewardVaultEquipButton({
    required bool equipped,
    required Color accent,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    double borderAlpha = 0.45,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: equipped ? null : onPressed,
        icon: Icon(equipped ? Icons.verified_rounded : icon, size: 17),
        label: Text(equipped ? 'Equipped' : label),
        style: ElevatedButton.styleFrom(
          backgroundColor: accent.withValues(alpha: 0.20),
          foregroundColor: accent,
          disabledBackgroundColor: accent.withValues(alpha: 0.12),
          disabledForegroundColor: accent.withValues(alpha: 0.72),
          side: BorderSide(color: accent.withValues(alpha: borderAlpha)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTheme.bodyTextStyle(
            fontSize: 11,
            color: accent,
            isBold: true,
          ),
        ),
      ),
    );
  }

  Widget _buildTitleInventoryGrid(ArcOperationsUserState userState) {
    final ownedTitles = userState.inventory
        .where((item) => item.isTitle)
        .toList();
    final previewTitles = ArcOperationsSeedData.rewards.values
        .where((reward) => reward.type == ArcOperationRewardType.title)
        .take(6)
        .toList();
    final equippedTitleId = _effectiveEquippedTitleId(userState);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TITLE INVENTORY',
                      style: AppTheme.tradingHeading(
                        fontSize: 19,
                        color: AppTheme.neonCyan,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ownedTitles.isEmpty
                          ? 'Preview titles earned through Operations, beta rewards and community reputation.'
                          : 'Earned titles ready for profile display and future equip flows.',
                      style: AppTheme.bodyTextStyle(
                        fontSize: 11,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              _tagPill('${ownedTitles.length} OWNED', AppTheme.neonCyan),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width >= 900
                  ? 3
                  : width >= 620
                  ? 2
                  : 1;
              final spacing = 8.0;
              final itemWidth = _vaultCardWidth(
                width,
                columns,
                spacing,
                minWidth: 180,
                maxWidth: 380,
              );
              final cards = ownedTitles.isNotEmpty
                  ? ownedTitles
                        .map(
                          (title) => _titleInventoryCard(
                            label: title.label,
                            rarity: title.rarity,
                            unlocked: true,
                            equipped: title.rewardId == equippedTitleId,
                            betaExclusive: title.betaExclusive,
                            source: 'Claimed Operations reward',
                          ),
                        )
                        .toList()
                  : previewTitles
                        .map(
                          (title) => _titleInventoryCard(
                            label: title.label,
                            rarity: title.rarity,
                            unlocked: false,
                            equipped: false,
                            betaExclusive: title.betaExclusive,
                            source: 'Preview title reward',
                          ),
                        )
                        .toList();

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final card in cards)
                    SizedBox(width: itemWidth, child: card),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          _buildSelectedTitlePreview(userState),
        ],
      ),
    );
  }

  Widget _titleInventoryCard({
    required String label,
    required ArcCosmeticRarity rarity,
    required bool unlocked,
    required bool equipped,
    required bool betaExclusive,
    required String source,
  }) {
    final accent = _rarityAccent(rarity);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: unlocked
            ? AppTheme.cardBackgroundDeep.withValues(alpha: 0.92)
            : AppTheme.cardBackgroundDeep.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: equipped
              ? AppTheme.neonCyan.withValues(alpha: 0.75)
              : accent.withValues(alpha: unlocked ? 0.34 : 0.18),
        ),
        boxShadow: equipped
            ? [
                BoxShadow(
                  color: AppTheme.neonCyan.withValues(alpha: 0.18),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: unlocked ? 0.12 : 0.06),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: accent.withValues(alpha: 0.32)),
            ),
            child: Icon(
              equipped ? Icons.workspace_premium_rounded : Icons.title_rounded,
              color: unlocked ? accent : Colors.white30,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 12,
                    color: unlocked ? Colors.white70 : Colors.white38,
                    isBold: true,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  source,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 10,
                    color: Colors.white38,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    _tinyVaultChip(rarity.label.toUpperCase(), accent),
                    _tinyVaultChip(
                      equipped
                          ? 'EQUIPPED'
                          : unlocked
                          ? 'OWNED'
                          : 'LOCKED',
                      equipped
                          ? AppTheme.neonCyan
                          : unlocked
                          ? accent
                          : Colors.white38,
                    ),
                    if (betaExclusive)
                      _tinyVaultChip('BETA', Colors.amberAccent),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTitlePreview(ArcOperationsUserState userState) {
    final ownedTitles = userState.inventory
        .where((item) => item.isTitle)
        .toList();
    final equippedTitleId = _effectiveEquippedTitleId(userState);

    final selectedOwned = _equippedOrFirstOwnedReward(
      ownedTitles,
      equippedTitleId,
    );

    if (selectedOwned != null) {
      return _titlePreviewPanel(
        item: selectedOwned,
        label: selectedOwned.label,
        rarity: selectedOwned.rarity,
        unlocked: true,
        equipped: selectedOwned.rewardId == equippedTitleId,
        betaExclusive: selectedOwned.betaExclusive,
        source: 'Claimed from Operations reward inventory',
      );
    }

    final previewTitles = ArcOperationsSeedData.rewards.values
        .where((reward) => reward.type == ArcOperationRewardType.title)
        .toList();
    final previewTitle = previewTitles.isEmpty ? null : previewTitles.first;

    if (previewTitle == null) {
      return _titlePreviewPanel(
        item: null,
        label: 'No title rewards seeded',
        rarity: ArcCosmeticRarity.common,
        unlocked: false,
        equipped: false,
        betaExclusive: false,
        source: 'Complete Operations to unlock profile titles.',
      );
    }

    return _titlePreviewPanel(
      item: null,
      label: previewTitle.label,
      rarity: previewTitle.rarity,
      unlocked: false,
      equipped: false,
      betaExclusive: previewTitle.betaExclusive,
      source: 'Preview reward. Claim Operations to unlock this title.',
    );
  }

  Widget _titlePreviewPanel({
    required ArcRewardInventoryItem? item,
    required String label,
    required ArcCosmeticRarity rarity,
    required bool unlocked,
    required bool equipped,
    required bool betaExclusive,
    required String source,
  }) {
    final accent = _rarityAccent(rarity);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (equipped ? AppTheme.neonCyan : accent).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.10),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final showcase = Container(
            width: compact ? double.infinity : 190,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: unlocked ? 0.10 : 0.06),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  equipped
                      ? Icons.workspace_premium_rounded
                      : Icons.title_rounded,
                  color: unlocked ? accent : Colors.white38,
                  size: 34,
                ),
                const SizedBox(height: 10),
                Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.tradingHeading(
                    fontSize: compact ? 20 : 22,
                    color: unlocked ? accent : Colors.white38,
                  ),
                ),
                const SizedBox(height: 8),
                _tinyVaultChip(
                  equipped
                      ? 'ACTIVE TITLE'
                      : unlocked
                      ? 'READY TO EQUIP'
                      : 'LOCKED PREVIEW',
                  equipped
                      ? AppTheme.neonCyan
                      : unlocked
                      ? accent
                      : Colors.white38,
                ),
              ],
            ),
          );

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SELECTED TITLE',
                style: AppTheme.bodyTextStyle(
                  fontSize: 10,
                  color: Colors.white54,
                  isBold: true,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.tradingHeading(fontSize: 22, color: accent),
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _tinyVaultChip(rarity.label.toUpperCase(), accent),
                  _tinyVaultChip(
                    unlocked ? 'UNLOCKED' : 'LOCKED',
                    unlocked ? Colors.lightGreenAccent : Colors.white38,
                  ),
                  if (equipped) _tinyVaultChip('EQUIPPED', AppTheme.neonCyan),
                  if (betaExclusive)
                    _tinyVaultChip('BETA ONLY', Colors.amberAccent),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                source,
                style: AppTheme.bodyTextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                unlocked
                    ? 'This title is unlocked and can be equipped to your profile header.'
                    : 'Locked preview. Complete the linked Operation chain to claim this title permanently.',
                style: AppTheme.bodyTextStyle(
                  fontSize: 11,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 10),
              _titleEquipActions(
                item: item,
                unlocked: unlocked,
                equipped: equipped,
                accent: accent,
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [showcase, const SizedBox(height: 10), details],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              showcase,
              const SizedBox(width: 12),
              Expanded(child: details),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileFrameInventoryGrid(ArcOperationsUserState userState) {
    final ownedFrames = userState.inventory
        .where((item) => item.isProfileFrame)
        .toList();
    final previewFrames = ArcOperationsSeedData.rewards.values
        .where((reward) => reward.type == ArcOperationRewardType.profileFrame)
        .take(6)
        .toList();
    final equippedFrameId = _effectiveEquippedProfileFrameId(userState);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neonPink.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROFILE FRAME INVENTORY',
                      style: AppTheme.tradingHeading(
                        fontSize: 19,
                        color: AppTheme.neonPink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ownedFrames.isEmpty
                          ? 'Preview profile frames earned through beta Operations and guardian reputation.'
                          : 'Select a frame to preview profile styling before equipping.',
                      style: AppTheme.bodyTextStyle(
                        fontSize: 11,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              _tagPill('${ownedFrames.length} OWNED', AppTheme.neonPink),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width >= 900
                  ? 3
                  : width >= 620
                  ? 2
                  : 1;
              final spacing = 8.0;
              final itemWidth = _vaultCardWidth(
                width,
                columns,
                spacing,
                minWidth: 180,
                maxWidth: 380,
              );
              final cards = ownedFrames.isNotEmpty
                  ? ownedFrames
                        .map(
                          (frame) => _profileFrameInventoryCard(
                            item: frame,
                            label: frame.label,
                            rarity: frame.rarity,
                            unlocked: true,
                            selected:
                                frame.rewardId == _selectedProfileFrameRewardId,
                            equipped: frame.rewardId == equippedFrameId,
                            betaExclusive: frame.betaExclusive,
                            source: _profileCosmeticSource(frame),
                            onSelected: () => setState(() {
                              _selectedProfileFrameRewardId = frame.rewardId;
                            }),
                          ),
                        )
                        .toList()
                  : previewFrames
                        .map(
                          (frame) => _profileFrameInventoryCard(
                            item: null,
                            label: frame.label,
                            rarity: frame.rarity,
                            unlocked: false,
                            selected: false,
                            equipped: false,
                            betaExclusive: frame.betaExclusive,
                            source: 'Preview frame reward',
                            onSelected: null,
                          ),
                        )
                        .toList();

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final card in cards)
                    SizedBox(width: itemWidth, child: card),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          _buildSelectedProfileFramePreview(userState),
        ],
      ),
    );
  }

  Widget _profileFrameInventoryCard({
    required ArcRewardInventoryItem? item,
    required String label,
    required ArcCosmeticRarity rarity,
    required bool unlocked,
    required bool selected,
    required bool equipped,
    required bool betaExclusive,
    required String source,
    required VoidCallback? onSelected,
  }) {
    final accent = _rarityAccent(rarity);
    final highlighted = selected || equipped;
    final framePreview = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: unlocked ? accent : Colors.white30,
          width: highlighted ? 2.2 : 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: item?.assetPath == null
          ? Icon(
              Icons.person_rounded,
              color: unlocked ? accent : Colors.white30,
              size: 20,
            )
          : Image.asset(
              item!.assetPath!,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(
                Icons.person_rounded,
                color: unlocked ? accent : Colors.white30,
                size: 20,
              ),
            ),
    );

    return MouseRegion(
      cursor: onSelected == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onSelected,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: unlocked
                ? AppTheme.cardBackgroundDeep.withValues(alpha: 0.92)
                : AppTheme.cardBackgroundDeep.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: highlighted
                  ? AppTheme.neonPink.withValues(alpha: 0.75)
                  : accent.withValues(alpha: unlocked ? 0.34 : 0.18),
            ),
            boxShadow: highlighted
                ? [
                    BoxShadow(
                      color: AppTheme.neonPink.withValues(alpha: 0.18),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 48,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: unlocked ? 0.10 : 0.05),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: accent.withValues(alpha: 0.30)),
                ),
                child: framePreview,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodyTextStyle(
                        fontSize: 12,
                        color: unlocked ? Colors.white70 : Colors.white38,
                        isBold: true,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      source,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodyTextStyle(
                        fontSize: 10,
                        color: Colors.white38,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        _tinyVaultChip(rarity.label.toUpperCase(), accent),
                        _tinyVaultChip(
                          equipped
                              ? 'EQUIPPED'
                              : selected
                              ? 'SELECTED'
                              : unlocked
                              ? 'OWNED'
                              : 'LOCKED',
                          equipped
                              ? AppTheme.neonPink
                              : selected
                              ? AppTheme.neonCyan
                              : unlocked
                              ? accent
                              : Colors.white38,
                        ),
                        if (betaExclusive)
                          _tinyVaultChip('BETA', Colors.amberAccent),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ArcRewardInventoryItem? _selectedProfileFrame(
    List<ArcRewardInventoryItem> ownedFrames,
  ) {
    return _rewardById(ownedFrames, _selectedProfileFrameRewardId);
  }

  String? _effectiveEquippedProfileFrameId(ArcOperationsUserState userState) {
    return _equippedProfileFrameRewardId ??
        userState.equippedCosmetics.profileFrameId;
  }

  ArcRewardInventoryItem? _effectiveEquippedProfileFrame(
    ArcOperationsUserState userState,
  ) {
    return _rewardById(
      userState.profileFrames,
      _effectiveEquippedProfileFrameId(userState),
    );
  }

  void _equipProfileFrame(ArcRewardInventoryItem frame) {
    if (_equippedProfileFrameRewardId == frame.rewardId) return;
    _equipRewardVaultCosmetic(frame);
  }

  String _profileCosmeticSource(ArcRewardInventoryItem item) {
    if (item.betaExclusive) return 'Closed Beta Operations reward';
    if (item.rarity == ArcCosmeticRarity.community) {
      return 'Community Operations reward';
    }
    return 'Operations reward inventory';
  }

  String _profileCosmeticDescription(ArcRewardInventoryItem item) {
    final isBanner = item.isProfileBanner;
    final cosmeticLabel = isBanner ? 'profile banner' : 'profile frame';
    if (item.betaExclusive) {
      return 'A permanent beta-era $cosmeticLabel for your ARC identity.';
    }
    if (item.rarity == ArcCosmeticRarity.community) {
      if (isBanner) {
        return 'A wide profile banner earned through community and guardian activity.';
      }
      return 'A profile frame earned through community and guardian activity.';
    }
    return 'A $cosmeticLabel earned through Operations Command progress.';
  }

  Widget _buildSelectedProfileFramePreview(ArcOperationsUserState userState) {
    final ownedFrames = userState.inventory
        .where((item) => item.isProfileFrame)
        .toList();
    final equippedFrameId = _effectiveEquippedProfileFrameId(userState);
    final selectedOwned = _selectedProfileFrame(ownedFrames);

    if (selectedOwned == null) {
      return _profileFramePlaceholderPanel();
    }

    return _profileFramePreviewPanel(
      item: selectedOwned,
      label: selectedOwned.label,
      assetPath: selectedOwned.assetPath,
      rarity: selectedOwned.rarity,
      owned: true,
      equipped: selectedOwned.rewardId == equippedFrameId,
      betaExclusive: selectedOwned.betaExclusive,
      source: _profileCosmeticSource(selectedOwned),
      description: _profileCosmeticDescription(selectedOwned),
    );
  }

  Widget _profileFramePlaceholderPanel() {
    return _profileFramePreviewPanel(
      item: null,
      label: 'No profile frame selected',
      assetPath: null,
      rarity: ArcCosmeticRarity.common,
      owned: false,
      equipped: false,
      betaExclusive: false,
      source: 'Select an owned profile frame from inventory.',
      description: 'Frame details will appear here once a reward is selected.',
      showAction: false,
    );
  }

  Widget _profileFramePreviewPanel({
    required ArcRewardInventoryItem? item,
    required String label,
    required String? assetPath,
    required ArcCosmeticRarity rarity,
    required bool owned,
    required bool equipped,
    required bool betaExclusive,
    required String source,
    required String description,
    bool showAction = true,
  }) {
    final accent = _rarityAccent(rarity);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (equipped ? AppTheme.neonPink : accent).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.10),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final showcase = Container(
            width: compact ? double.infinity : 190,
            height: compact ? 156 : 164,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: owned ? 0.10 : 0.06),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppTheme.darkBackground.withValues(alpha: 0.36),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: owned ? accent : Colors.white38,
                  width: equipped ? 2.4 : 1.4,
                ),
                boxShadow: equipped
                    ? [
                        BoxShadow(
                          color: AppTheme.neonPink.withValues(alpha: 0.18),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: assetPath == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_rounded,
                          color: owned ? accent : Colors.white38,
                          size: 34,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'PROFILE',
                          style: AppTheme.bodyTextStyle(
                            fontSize: 10,
                            color: owned ? accent : Colors.white38,
                            isBold: true,
                          ),
                        ),
                        const SizedBox(height: 7),
                        _tinyVaultChip(
                          equipped
                              ? 'ACTIVE FRAME'
                              : owned
                              ? 'READY TO EQUIP'
                              : 'NO SELECTION',
                          equipped
                              ? AppTheme.neonPink
                              : owned
                              ? accent
                              : Colors.white38,
                        ),
                      ],
                    )
                  : Image.asset(
                      assetPath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.person_rounded,
                        color: owned ? accent : Colors.white38,
                        size: 34,
                      ),
                    ),
            ),
          );

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SELECTED FRAME',
                style: AppTheme.bodyTextStyle(
                  fontSize: 10,
                  color: Colors.white54,
                  isBold: true,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.tradingHeading(fontSize: 22, color: accent),
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _tinyVaultChip(rarity.label.toUpperCase(), accent),
                  _tinyVaultChip(
                    owned ? 'OWNED' : 'NO SELECTION',
                    owned ? Colors.lightGreenAccent : Colors.white38,
                  ),
                  _tinyVaultChip(
                    equipped ? 'EQUIPPED' : 'NOT EQUIPPED',
                    equipped ? AppTheme.neonPink : Colors.white54,
                  ),
                  if (betaExclusive)
                    _tinyVaultChip('BETA ONLY', Colors.amberAccent),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                source,
                style: AppTheme.bodyTextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: AppTheme.bodyTextStyle(
                  fontSize: 11,
                  color: Colors.white54,
                ),
              ),
              if (showAction && item != null) ...[
                const SizedBox(height: 10),
                _profileFrameEquipActions(
                  item: item,
                  equipped: equipped,
                  accent: accent,
                ),
              ],
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [showcase, const SizedBox(height: 10), details],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              showcase,
              const SizedBox(width: 12),
              Expanded(child: details),
            ],
          );
        },
      ),
    );
  }

  Widget _profileFrameEquipActions({
    required ArcRewardInventoryItem item,
    required bool equipped,
    required Color accent,
  }) {
    return _rewardVaultEquipButton(
      equipped: equipped,
      accent: accent,
      icon: Icons.crop_square_rounded,
      label: 'Equip',
      borderAlpha: 0.35,
      onPressed: () => _equipProfileFrame(item),
    );
  }

  Widget _buildProfileBannerInventoryGrid(ArcOperationsUserState userState) {
    final ownedBanners = userState.inventory
        .where((item) => item.isProfileBanner)
        .toList();
    final previewBanners = ArcOperationsSeedData.rewards.values
        .where((reward) => reward.type == ArcOperationRewardType.profileBanner)
        .take(6)
        .toList();
    final equippedBannerId = _effectiveEquippedProfileBannerId(userState);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.lightBlueAccent.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROFILE BANNER INVENTORY',
                      style: AppTheme.tradingHeading(
                        fontSize: 19,
                        color: Colors.lightBlueAccent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ownedBanners.isEmpty
                          ? 'Preview profile banners earned through beta Operations and guardian reputation.'
                          : 'Select a banner to stage it for profile display.',
                      style: AppTheme.bodyTextStyle(
                        fontSize: 11,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              _tagPill('${ownedBanners.length} OWNED', Colors.lightBlueAccent),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width >= 900
                  ? 3
                  : width >= 620
                  ? 2
                  : 1;
              final spacing = 8.0;
              final itemWidth = _vaultCardWidth(
                width,
                columns,
                spacing,
                minWidth: 220,
                maxWidth: 380,
              );
              final cards = ownedBanners.isNotEmpty
                  ? ownedBanners
                        .map(
                          (banner) => _profileBannerInventoryCard(
                            item: banner,
                            label: banner.label,
                            rarity: banner.rarity,
                            unlocked: true,
                            selected:
                                banner.rewardId ==
                                _selectedProfileBannerRewardId,
                            equipped: banner.rewardId == equippedBannerId,
                            betaExclusive: banner.betaExclusive,
                            source: _profileCosmeticSource(banner),
                            onSelected: () => setState(() {
                              _selectedProfileBannerRewardId = banner.rewardId;
                            }),
                          ),
                        )
                        .toList()
                  : previewBanners
                        .map(
                          (banner) => _profileBannerInventoryCard(
                            item: null,
                            label: banner.label,
                            rarity: banner.rarity,
                            unlocked: false,
                            selected: false,
                            equipped: false,
                            betaExclusive: banner.betaExclusive,
                            source: 'Preview banner reward',
                            onSelected: null,
                          ),
                        )
                        .toList();

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final card in cards)
                    SizedBox(width: itemWidth, child: card),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          _buildSelectedProfileBannerPreview(userState),
        ],
      ),
    );
  }

  Widget _profileBannerInventoryCard({
    required ArcRewardInventoryItem? item,
    required String label,
    required ArcCosmeticRarity rarity,
    required bool unlocked,
    required bool selected,
    required bool equipped,
    required bool betaExclusive,
    required String source,
    required VoidCallback? onSelected,
  }) {
    final accent = _rarityAccent(rarity);
    final highlighted = selected || equipped;
    final bannerPreview = Container(
      height: 58,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked ? accent : Colors.white30,
          width: highlighted ? 2.2 : 1.2,
        ),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: unlocked ? 0.32 : 0.10),
            Colors.lightBlueAccent.withValues(alpha: unlocked ? 0.16 : 0.05),
            AppTheme.darkBackground.withValues(alpha: 0.58),
          ],
        ),
      ),
      child: item?.assetPath == null
          ? Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                        bottom: BorderSide(
                          color: Colors.black.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  bottom: 12,
                  child: Icon(
                    Icons.view_day_rounded,
                    color: unlocked ? accent : Colors.white30,
                    size: 24,
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 13,
                  child: _tinyVaultChip(
                    unlocked ? 'BANNER' : 'LOCKED',
                    unlocked ? accent : Colors.white38,
                  ),
                ),
              ],
            )
          : Image.asset(
              item!.assetPath!,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(
                Icons.view_day_rounded,
                color: unlocked ? accent : Colors.white30,
                size: 24,
              ),
            ),
    );

    return MouseRegion(
      cursor: onSelected == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onSelected,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: unlocked
                ? AppTheme.cardBackgroundDeep.withValues(alpha: 0.92)
                : AppTheme.cardBackgroundDeep.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: highlighted
                  ? Colors.lightBlueAccent.withValues(alpha: 0.75)
                  : accent.withValues(alpha: unlocked ? 0.34 : 0.18),
            ),
            boxShadow: highlighted
                ? [
                    BoxShadow(
                      color: Colors.lightBlueAccent.withValues(alpha: 0.18),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bannerPreview,
              const SizedBox(height: 9),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyTextStyle(
                  fontSize: 12,
                  color: unlocked ? Colors.white70 : Colors.white38,
                  isBold: true,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                source,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyTextStyle(
                  fontSize: 10,
                  color: Colors.white38,
                ),
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  _tinyVaultChip(rarity.label.toUpperCase(), accent),
                  _tinyVaultChip(
                    equipped
                        ? 'EQUIPPED'
                        : selected
                        ? 'SELECTED'
                        : unlocked
                        ? 'OWNED'
                        : 'LOCKED',
                    equipped
                        ? Colors.lightBlueAccent
                        : selected
                        ? AppTheme.neonCyan
                        : unlocked
                        ? accent
                        : Colors.white38,
                  ),
                  if (betaExclusive) _tinyVaultChip('BETA', Colors.amberAccent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  ArcRewardInventoryItem? _selectedProfileBanner(
    List<ArcRewardInventoryItem> ownedBanners,
  ) {
    return _rewardById(ownedBanners, _selectedProfileBannerRewardId);
  }

  Widget _buildSelectedProfileBannerPreview(ArcOperationsUserState userState) {
    final ownedBanners = userState.profileBanners;
    final selectedOwned = _selectedProfileBanner(ownedBanners);
    final equippedBannerId = _effectiveEquippedProfileBannerId(userState);

    if (selectedOwned == null) {
      return _profileBannerPlaceholderPanel();
    }

    return _profileBannerPreviewPanel(
      item: selectedOwned,
      label: selectedOwned.label,
      assetPath: selectedOwned.assetPath,
      rarity: selectedOwned.rarity,
      owned: true,
      equipped: selectedOwned.rewardId == equippedBannerId,
      betaExclusive: selectedOwned.betaExclusive,
      source: _profileCosmeticSource(selectedOwned),
      description: _profileCosmeticDescription(selectedOwned),
    );
  }

  Widget _profileBannerPlaceholderPanel() {
    return _profileBannerPreviewPanel(
      item: null,
      label: 'No profile banner selected',
      assetPath: null,
      rarity: ArcCosmeticRarity.common,
      owned: false,
      equipped: false,
      betaExclusive: false,
      source: 'Select an owned profile banner from inventory.',
      description: 'Banner details will appear here once a reward is selected.',
      showAction: false,
    );
  }

  Widget _profileBannerPreviewPanel({
    required ArcRewardInventoryItem? item,
    required String label,
    required String? assetPath,
    required ArcCosmeticRarity rarity,
    required bool owned,
    required bool equipped,
    required bool betaExclusive,
    required String source,
    required String description,
    bool showAction = true,
  }) {
    final accent = _rarityAccent(rarity);
    final statusAccent = equipped ? Colors.lightBlueAccent : accent;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusAccent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.10),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final showcase = Container(
            width: compact ? double.infinity : 280,
            height: compact ? 144 : 156,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: owned ? 0.10 : 0.06),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppTheme.darkBackground.withValues(alpha: 0.36),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: owned ? statusAccent : Colors.white38,
                  width: equipped ? 2.4 : 1.4,
                ),
                boxShadow: equipped
                    ? [
                        BoxShadow(
                          color: Colors.lightBlueAccent.withValues(alpha: 0.18),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: assetPath == null
                  ? Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  accent.withValues(alpha: owned ? 0.30 : 0.10),
                                  Colors.lightBlueAccent.withValues(
                                    alpha: owned ? 0.16 : 0.05,
                                  ),
                                  AppTheme.darkBackground.withValues(
                                    alpha: 0.66,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          top: 0,
                          bottom: 0,
                          child: Icon(
                            Icons.view_day_rounded,
                            color: owned ? accent : Colors.white38,
                            size: 36,
                          ),
                        ),
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: _tinyVaultChip(
                            equipped
                                ? 'ACTIVE BANNER'
                                : owned
                                ? 'READY TO EQUIP'
                                : 'NO SELECTION',
                            equipped
                                ? Colors.lightBlueAccent
                                : owned
                                ? accent
                                : Colors.white38,
                          ),
                        ),
                      ],
                    )
                  : Image.asset(
                      assetPath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.view_day_rounded,
                        color: owned ? accent : Colors.white38,
                        size: 36,
                      ),
                    ),
            ),
          );

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SELECTED BANNER',
                style: AppTheme.bodyTextStyle(
                  fontSize: 10,
                  color: Colors.white54,
                  isBold: true,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.tradingHeading(fontSize: 22, color: accent),
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _tinyVaultChip(rarity.label.toUpperCase(), accent),
                  _tinyVaultChip(
                    owned ? 'OWNED' : 'NO SELECTION',
                    owned ? Colors.lightGreenAccent : Colors.white38,
                  ),
                  _tinyVaultChip(
                    equipped ? 'EQUIPPED' : 'NOT EQUIPPED',
                    equipped ? Colors.lightBlueAccent : Colors.white54,
                  ),
                  if (betaExclusive)
                    _tinyVaultChip('BETA ONLY', Colors.amberAccent),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                source,
                style: AppTheme.bodyTextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: AppTheme.bodyTextStyle(
                  fontSize: 11,
                  color: Colors.white54,
                ),
              ),
              if (showAction && item != null) ...[
                const SizedBox(height: 10),
                _profileBannerEquipActions(
                  item: item,
                  equipped: equipped,
                  accent: accent,
                ),
              ],
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [showcase, const SizedBox(height: 10), details],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              showcase,
              const SizedBox(width: 12),
              Expanded(child: details),
            ],
          );
        },
      ),
    );
  }

  String? _effectiveEquippedProfileBannerId(ArcOperationsUserState userState) {
    return _equippedProfileBannerRewardId ??
        userState.equippedCosmetics.profileBannerId;
  }

  void _equipProfileBanner(ArcRewardInventoryItem banner) {
    if (_equippedProfileBannerRewardId == banner.rewardId) return;
    _equipRewardVaultCosmetic(banner);
  }

  Widget _profileBannerEquipActions({
    required ArcRewardInventoryItem item,
    required bool equipped,
    required Color accent,
  }) {
    return _rewardVaultEquipButton(
      equipped: equipped,
      accent: accent,
      icon: Icons.view_day_rounded,
      label: 'Equip',
      borderAlpha: 0.35,
      onPressed: () => _equipProfileBanner(item),
    );
  }

  Widget _buildBadgeInventoryGrid(ArcOperationsUserState userState) {
    final ownedBadges = userState.inventory
        .where((item) => item.isBadge)
        .toList();
    final previewBadges = ArcOperationsSeedData.rewards.values
        .where((reward) => reward.type == ArcOperationRewardType.badge)
        .take(6)
        .toList();
    final equippedBadgeId = _effectiveEquippedBadgeId(userState);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BADGE INVENTORY',
                      style: AppTheme.tradingHeading(
                        fontSize: 19,
                        color: Colors.amberAccent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ownedBadges.isEmpty
                          ? 'Preview beta, founder and community badges. Claimed badges appear here.'
                          : 'Earned badges ready for profile display and future equip flows.',
                      style: AppTheme.bodyTextStyle(
                        fontSize: 11,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              _tagPill('${ownedBadges.length} OWNED', Colors.amberAccent),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width >= 900
                  ? 6
                  : width >= 680
                  ? 4
                  : width >= 430
                  ? 3
                  : 2;
              final spacing = 8.0;
              final itemWidth = _vaultCardWidth(
                width,
                columns,
                spacing,
                minWidth: 118,
                maxWidth: 180,
              );
              final cards = ownedBadges.isNotEmpty
                  ? ownedBadges
                        .map(
                          (badge) => _badgeInventoryCard(
                            label: badge.label,
                            assetPath: badge.assetPath,
                            rarity: badge.rarity,
                            unlocked: true,
                            equipped: badge.rewardId == equippedBadgeId,
                            betaExclusive: badge.betaExclusive,
                          ),
                        )
                        .toList()
                  : previewBadges
                        .map(
                          (badge) => _badgeInventoryCard(
                            label: badge.label,
                            assetPath: badge.assetPath,
                            rarity: badge.rarity,
                            unlocked: false,
                            equipped: false,
                            betaExclusive: badge.betaExclusive,
                          ),
                        )
                        .toList();

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final card in cards)
                    SizedBox(width: itemWidth, child: card),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          _buildSelectedBadgePreview(userState),
        ],
      ),
    );
  }

  Widget _buildSelectedBadgePreview(ArcOperationsUserState userState) {
    final ownedBadges = userState.inventory
        .where((item) => item.isBadge)
        .toList();
    final equippedBadgeId = _effectiveEquippedBadgeId(userState);

    final selectedOwned = _equippedOrFirstOwnedReward(
      ownedBadges,
      equippedBadgeId,
    );

    if (selectedOwned != null) {
      return _badgePreviewPanel(
        item: selectedOwned,
        label: selectedOwned.label,
        assetPath: selectedOwned.assetPath,
        rarity: selectedOwned.rarity,
        unlocked: true,
        equipped: selectedOwned.rewardId == equippedBadgeId,
        betaExclusive: selectedOwned.betaExclusive,
        source: 'Claimed from Operations reward inventory',
      );
    }

    final previewBadges = ArcOperationsSeedData.rewards.values
        .where((reward) => reward.type == ArcOperationRewardType.badge)
        .toList();
    final previewBadge = previewBadges.isEmpty ? null : previewBadges.first;

    if (previewBadge == null) {
      return _badgePreviewPanel(
        item: null,
        label: 'No badge rewards seeded',
        assetPath: null,
        rarity: ArcCosmeticRarity.common,
        unlocked: false,
        equipped: false,
        betaExclusive: false,
        source: 'Complete Operations to unlock badge rewards',
      );
    }

    return _badgePreviewPanel(
      item: null,
      label: previewBadge.label,
      assetPath: previewBadge.assetPath,
      rarity: previewBadge.rarity,
      unlocked: false,
      equipped: false,
      betaExclusive: previewBadge.betaExclusive,
      source: 'Preview reward. Claim Operations to unlock and equip.',
    );
  }

  Widget _badgePreviewPanel({
    required ArcRewardInventoryItem? item,
    required String label,
    required String? assetPath,
    required ArcCosmeticRarity rarity,
    required bool unlocked,
    required bool equipped,
    required bool betaExclusive,
    required String source,
  }) {
    final accent = _rarityAccent(rarity);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (equipped ? AppTheme.neonCyan : accent).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.10),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final preview = Container(
            width: compact ? double.infinity : 148,
            height: compact ? 168 : 148,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: unlocked ? 0.10 : 0.06),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            clipBehavior: Clip.antiAlias,
            child: assetPath == null
                ? Icon(
                    Icons.military_tech_rounded,
                    color: unlocked ? accent : Colors.white38,
                    size: 54,
                  )
                : ColorFiltered(
                    colorFilter: unlocked
                        ? const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.dst,
                          )
                        : const ColorFilter.matrix(<double>[
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0,
                            0,
                            0,
                            0.55,
                            0,
                          ]),
                    child: Image.asset(
                      assetPath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.military_tech_rounded,
                        color: accent,
                        size: 54,
                      ),
                    ),
                  ),
          );

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SELECTED BADGE',
                style: AppTheme.bodyTextStyle(
                  fontSize: 10,
                  color: Colors.white54,
                  isBold: true,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.tradingHeading(fontSize: 22, color: accent),
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _tinyVaultChip(rarity.label.toUpperCase(), accent),
                  _tinyVaultChip(
                    unlocked ? 'UNLOCKED' : 'LOCKED',
                    unlocked ? Colors.lightGreenAccent : Colors.white38,
                  ),
                  if (equipped) _tinyVaultChip('EQUIPPED', AppTheme.neonCyan),
                  if (betaExclusive)
                    _tinyVaultChip('BETA ONLY', Colors.amberAccent),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                source,
                style: AppTheme.bodyTextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                unlocked
                    ? 'This badge is ready to equip to your public ARC profile and trading identity.'
                    : 'Locked preview. Complete the linked Operation chain to claim this badge permanently.',
                style: AppTheme.bodyTextStyle(
                  fontSize: 11,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 10),
              _badgeEquipActionButton(
                item: item,
                unlocked: unlocked,
                equipped: equipped,
                accent: accent,
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [preview, const SizedBox(height: 10), details],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              preview,
              const SizedBox(width: 12),
              Expanded(child: details),
            ],
          );
        },
      ),
    );
  }

  Widget _badgeEquipActionButton({
    required ArcRewardInventoryItem? item,
    required bool unlocked,
    required bool equipped,
    required Color accent,
  }) {
    if (!unlocked || item == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_rounded, color: Colors.white38, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'LOCKED - COMPLETE THE LINKED OPERATION TO CLAIM',
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyTextStyle(
                  fontSize: 10,
                  color: Colors.white54,
                  isBold: true,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (equipped) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: AppTheme.neonCyan.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.neonCyan.withValues(alpha: 0.40),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: AppTheme.neonCyan,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'CURRENTLY EQUIPPED',
                  style: AppTheme.bodyTextStyle(
                    fontSize: 10,
                    color: AppTheme.neonCyan,
                    isBold: true,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Badge remains equipped until another badge is selected.',
                    style: AppTheme.bodyTextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.swap_horiz_rounded, size: 16),
            label: const Text('Replace via another badge'),
          ),
        ],
      );
    }

    return _rewardVaultEquipButton(
      equipped: false,
      accent: accent,
      icon: Icons.military_tech_rounded,
      label: 'Equip Badge',
      onPressed: () => _equipRewardVaultCosmetic(item),
    );
  }

  Widget _titleEquipActions({
    required ArcRewardInventoryItem? item,
    required bool unlocked,
    required bool equipped,
    required Color accent,
  }) {
    if (!unlocked || item == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_rounded, color: Colors.white38, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'LOCKED - CLAIM THIS TITLE FROM OPERATIONS FIRST',
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyTextStyle(
                  fontSize: 10,
                  color: Colors.white54,
                  isBold: true,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (equipped) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: AppTheme.neonCyan.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.neonCyan.withValues(alpha: 0.40),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: AppTheme.neonCyan,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'CURRENTLY EQUIPPED',
                  style: AppTheme.bodyTextStyle(
                    fontSize: 10,
                    color: AppTheme.neonCyan,
                    isBold: true,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Title remains equipped until another title is selected.',
                    style: AppTheme.bodyTextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.swap_horiz_rounded, size: 16),
            label: const Text('Replace via another title'),
          ),
        ],
      );
    }

    return _rewardVaultEquipButton(
      equipped: false,
      accent: accent,
      icon: Icons.title_rounded,
      label: 'Equip Title',
      onPressed: () => _equipRewardVaultCosmetic(item),
    );
  }

  Widget _badgeInventoryCard({
    required String label,
    required String? assetPath,
    required ArcCosmeticRarity rarity,
    required bool unlocked,
    required bool equipped,
    required bool betaExclusive,
  }) {
    final accent = _rarityAccent(rarity);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: unlocked
            ? AppTheme.cardBackgroundDeep.withValues(alpha: 0.92)
            : AppTheme.cardBackgroundDeep.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: equipped
              ? AppTheme.neonCyan.withValues(alpha: 0.75)
              : accent.withValues(alpha: unlocked ? 0.34 : 0.18),
        ),
        boxShadow: equipped
            ? [
                BoxShadow(
                  color: AppTheme.neonCyan.withValues(alpha: 0.18),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: assetPath == null
                        ? Container(
                            color: accent.withValues(
                              alpha: unlocked ? 0.12 : 0.06,
                            ),
                            child: Icon(
                              Icons.military_tech_rounded,
                              color: unlocked ? accent : Colors.white30,
                              size: 34,
                            ),
                          )
                        : ColorFiltered(
                            colorFilter: unlocked
                                ? const ColorFilter.mode(
                                    Colors.transparent,
                                    BlendMode.dst,
                                  )
                                : const ColorFilter.matrix(<double>[
                                    0.2126,
                                    0.7152,
                                    0.0722,
                                    0,
                                    0,
                                    0.2126,
                                    0.7152,
                                    0.0722,
                                    0,
                                    0,
                                    0.2126,
                                    0.7152,
                                    0.0722,
                                    0,
                                    0,
                                    0,
                                    0,
                                    0,
                                    0.5,
                                    0,
                                  ]),
                            child: Image.asset(
                              assetPath,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (_, _, _) => Container(
                                color: accent.withValues(alpha: 0.08),
                                child: Icon(
                                  Icons.military_tech_rounded,
                                  color: accent,
                                  size: 34,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: _tinyVaultChip(
                    equipped
                        ? 'EQUIPPED'
                        : unlocked
                        ? 'OWNED'
                        : 'LOCKED',
                    equipped
                        ? AppTheme.neonCyan
                        : unlocked
                        ? accent
                        : Colors.white38,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyTextStyle(
              fontSize: 11,
              color: unlocked ? Colors.white70 : Colors.white38,
              isBold: true,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              _tinyVaultChip(rarity.label.toUpperCase(), accent),
              if (betaExclusive) _tinyVaultChip('BETA', Colors.amberAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tinyVaultChip(String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppTheme.bodyTextStyle(fontSize: 8, color: accent, isBold: true),
      ),
    );
  }

  Color _rarityAccent(ArcCosmeticRarity rarity) {
    return switch (rarity) {
      ArcCosmeticRarity.common => Colors.white60,
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

  Widget _buildRecentUnlockPanel(ArcOperationsUserState userState) {
    final recent = userState.inventory.isEmpty
        ? null
        : userState.inventory.last;
    final accent = recent?.betaExclusive == true
        ? Colors.amberAccent
        : AppTheme.neonCyan;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.26)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: accent.withValues(alpha: 0.28)),
            ),
            clipBehavior: Clip.antiAlias,
            child: recent?.assetPath == null
                ? Icon(Icons.workspace_premium_rounded, color: accent, size: 24)
                : Image.asset(recent!.assetPath!, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RECENT UNLOCK',
                  style: AppTheme.bodyTextStyle(
                    fontSize: 10,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  recent?.label ?? 'Complete Operations to unlock cosmetics',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    isBold: true,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  recent == null
                      ? 'Badges, titles and frames will appear here as they are claimed.'
                      : recent.rarity.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyTextStyle(fontSize: 10, color: accent),
                ),
              ],
            ),
          ),
          if (recent?.betaExclusive == true) _tagPill('BETA ONLY', accent),
        ],
      ),
    );
  }

  Widget _vaultRewardCard(ArcOperationReward reward) {
    final accent = reward.betaExclusive
        ? Colors.amberAccent
        : AppTheme.neonCyan;
    return Container(
      width: 128,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 78,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: reward.assetPath == null
                  ? Container(
                      color: accent.withValues(alpha: 0.08),
                      child: Icon(Icons.military_tech_rounded, color: accent),
                    )
                  : Image.asset(
                      reward.assetPath!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, _, _) => Container(
                        color: accent.withValues(alpha: 0.08),
                        child: Icon(Icons.military_tech_rounded, color: accent),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            reward.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyTextStyle(
              fontSize: 11,
              color: Colors.white70,
              isBold: true,
            ),
          ),
          if (reward.betaExclusive) ...[
            const SizedBox(height: 5),
            _tagPill('BETA ONLY', Colors.amberAccent),
          ],
        ],
      ),
    );
  }

  Widget _tagPill(String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: AppTheme.bodyTextStyle(fontSize: 9, color: accent, isBold: true),
      ),
    );
  }

  Widget _metric(String label, String value, Color accent) {
    return Container(
      constraints: const BoxConstraints(minWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTheme.tradingHeading(fontSize: 22, color: accent),
          ),
          Text(
            label.toUpperCase(),
            style: AppTheme.bodyTextStyle(fontSize: 10, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return ArcRaidersSectionCard(
      accent: AppTheme.neonCyan,
      padding: const EdgeInsets.all(6),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Colors.amberAccent,
        labelColor: Colors.amberAccent,
        unselectedLabelColor: Colors.white60,
        labelStyle: AppTheme.bodyTextStyle(
          fontSize: 12,
          color: Colors.amberAccent,
          isBold: true,
        ),
        onTap: (_) => setState(() {}),
        tabs: const [
          Tab(text: 'DAILY'),
          Tab(text: 'WEEKLY'),
          Tab(text: 'MONTHLY'),
          Tab(text: 'LIFETIME'),
          Tab(text: 'BETA'),
        ],
      ),
    );
  }

  Widget _buildActiveTab(ArcOperationsUserState userState) {
    final index = _tabController.index;
    final cadence = switch (index) {
      0 => ArcOperationCadence.daily,
      1 => ArcOperationCadence.weekly,
      2 => ArcOperationCadence.monthly,
      3 => ArcOperationCadence.lifetime,
      _ => ArcOperationCadence.beta,
    };
    final plan = ArcDynamicOperationsEngine.generate(
      userState: userState,
      cadence: cadence,
    );
    final tasks = plan.tasks;

    final title = plan.title;
    final subtitle = plan.subtitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ArcRaidersHeroBanner(
          title: title,
          subtitle: subtitle,
          accent: index == 4 ? Colors.amberAccent : AppTheme.neonCyan,
        ),
        const SizedBox(height: 10),
        _buildGenerationStrategyPanel(plan),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1050
                ? 3
                : constraints.maxWidth >= 680
                ? 2
                : 1;
            final spacing = 10.0;
            final itemWidth =
                (constraints.maxWidth - (spacing * (columns - 1))) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final task in tasks)
                  SizedBox(
                    width: itemWidth,
                    child: _OperationTaskCard(
                      task: task,
                      userState: userState,
                      onTrack: () => _repository.trackProgress(task),
                      onClaim: () => _repository.claimReward(task),
                      onEquip: _equipRewardVaultCosmetic,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildGenerationStrategyPanel(ArcDynamicOperationPlan plan) {
    return ArcRaidersSectionCard(
      accent: plan.accent,
      padding: const EdgeInsets.all(10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 640;
          final chips = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _tagPill(plan.rotationLabel, plan.accent),
              _tagPill(plan.rewardLabel, AppTheme.neonPink),
              _tagPill(plan.priorityLabel, Colors.amberAccent),
            ],
          );

          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ADAPTIVE OPS ENGINE',
                style: AppTheme.tradingHeading(
                  fontSize: compact ? 20 : 24,
                  color: plan.accent,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                plan.strategy,
                style: AppTheme.bodyTextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 10), chips],
            );
          }

          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 12),
              Flexible(child: chips),
            ],
          );
        },
      ),
    );
  }
}

IconData _rewardTypeIcon(ArcOperationRewardType type) {
  return switch (type) {
    ArcOperationRewardType.badge => Icons.military_tech_rounded,
    ArcOperationRewardType.title => Icons.title_rounded,
    ArcOperationRewardType.profileFrame => Icons.crop_square_rounded,
    ArcOperationRewardType.profileBanner => Icons.view_day_rounded,
    ArcOperationRewardType.tradeSlot => Icons.swap_horiz_rounded,
    ArcOperationRewardType.matchmakingSlot => Icons.groups_rounded,
    ArcOperationRewardType.premiumTrial => Icons.workspace_premium_rounded,
    ArcOperationRewardType.operationCredit => Icons.toll_rounded,
    ArcOperationRewardType.intelXp => Icons.psychology_rounded,
  };
}

class _OperationTaskCard extends StatelessWidget {
  const _OperationTaskCard({
    required this.task,
    required this.userState,
    required this.onTrack,
    required this.onClaim,
    required this.onEquip,
  });

  final ArcOperationTask task;
  final ArcOperationsUserState userState;
  final Future<void> Function() onTrack;
  final Future<void> Function() onClaim;
  final Future<void> Function(ArcRewardInventoryItem item) onEquip;

  @override
  Widget build(BuildContext context) {
    ArcOperationReward? rewardWithAsset;
    for (final reward in task.rewards) {
      if (reward.assetPath != null) {
        rewardWithAsset = reward;
        break;
      }
    }

    final progress = userState.progressFor(task);
    final state = userState.stateFor(task);
    final completion = task.target <= 0
        ? 0.0
        : (progress / task.target).clamp(0, 1).toDouble();
    final ready = state == ArcOperationClaimState.readyToClaim;
    final complete = state == ArcOperationClaimState.completed;

    return ArcRaidersSectionCard(
      accent: complete ? Colors.lightGreenAccent : task.accent,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BadgePreview(
                reward: rewardWithAsset,
                fallbackColor: task.accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title.toUpperCase(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.tradingHeading(
                              fontSize: 18,
                              color: complete
                                  ? Colors.lightGreenAccent
                                  : task.accent,
                            ),
                          ),
                        ),
                        if (task.betaExclusive)
                          _tag('BETA', Colors.amberAccent),
                        if (complete) ...[
                          const SizedBox(width: 4),
                          _tag('OWNED', Colors.lightGreenAccent),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      task.description,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodyTextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ).copyWith(height: 1.28),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: completion,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              color: complete
                  ? Colors.lightGreenAccent
                  : ready
                  ? Colors.amberAccent
                  : task.accent,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$progress/${task.target}',
                style: AppTheme.bodyTextStyle(
                  fontSize: 11,
                  color: Colors.white60,
                ),
              ),
              const Spacer(),
              if (task.verificationRequired)
                _tag('VERIFY', Colors.lightGreenAccent),
              if (ready) ...[
                const SizedBox(width: 4),
                _tag('READY', Colors.amberAccent),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final reward in task.rewards) _rewardChip(reward)],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: complete
                      ? null
                      : ready
                      ? onClaim
                      : onTrack,
                  icon: Icon(
                    ready
                        ? Icons.redeem_rounded
                        : complete
                        ? Icons.check_circle_rounded
                        : Icons.add_task_rounded,
                    size: 16,
                  ),
                  label: Text(
                    ready
                        ? 'CLAIM REWARD'
                        : complete
                        ? 'COMPLETED'
                        : 'TRACK +1',
                  ),
                ),
              ),
            ],
          ),
          if (complete && userState.inventory.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InventoryPreview(userState: userState, onEquip: onEquip),
          ],
        ],
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppTheme.bodyTextStyle(fontSize: 9, color: color, isBold: true),
      ),
    );
  }

  Widget _rewardChip(ArcOperationReward reward) {
    final color = switch (reward.type) {
      ArcOperationRewardType.badge => Colors.amberAccent,
      ArcOperationRewardType.title => AppTheme.neonCyan,
      ArcOperationRewardType.profileFrame => AppTheme.neonPink,
      ArcOperationRewardType.profileBanner => Colors.lightBlueAccent,
      ArcOperationRewardType.tradeSlot => Colors.lightGreenAccent,
      ArcOperationRewardType.matchmakingSlot => Colors.lightBlueAccent,
      ArcOperationRewardType.premiumTrial => Colors.purpleAccent,
      ArcOperationRewardType.operationCredit => Colors.orangeAccent,
      ArcOperationRewardType.intelXp => Colors.white70,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        reward.label,
        style: AppTheme.bodyTextStyle(fontSize: 10, color: color, isBold: true),
      ),
    );
  }
}

class _InventoryPreview extends StatelessWidget {
  const _InventoryPreview({required this.userState, required this.onEquip});

  final ArcOperationsUserState userState;
  final Future<void> Function(ArcRewardInventoryItem item) onEquip;

  @override
  Widget build(BuildContext context) {
    final cosmetics = userState.inventory
        .where(
          (item) =>
              item.type == ArcOperationRewardType.badge ||
              item.type == ArcOperationRewardType.title ||
              item.type == ArcOperationRewardType.profileFrame,
        )
        .take(3)
        .toList();
    if (cosmetics.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final item in cosmetics)
          ActionChip(
            onPressed: () => onEquip(item),
            avatar: item.assetPath == null
                ? null
                : CircleAvatar(backgroundImage: AssetImage(item.assetPath!)),
            label: Text('Equip ${item.label}', overflow: TextOverflow.ellipsis),
          ),
      ],
    );
  }
}

class _BadgePreview extends StatelessWidget {
  const _BadgePreview({required this.reward, required this.fallbackColor});

  final ArcOperationReward? reward;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: fallbackColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: fallbackColor.withValues(alpha: 0.14),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: reward?.assetPath == null
            ? Icon(Icons.military_tech_rounded, color: fallbackColor, size: 34)
            : Image.asset(
                reward!.assetPath!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, _, _) => Icon(
                  Icons.military_tech_rounded,
                  color: fallbackColor,
                  size: 34,
                ),
              ),
      ),
    );
  }
}
