import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_operations_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_dynamic_operations_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_operations_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class OperationsCommandScreen extends StatefulWidget {
  const OperationsCommandScreen({super.key});

  @override
  State<OperationsCommandScreen> createState() =>
      _OperationsCommandScreenState();
}

class _OperationsCommandScreenState extends State<OperationsCommandScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ArcOperationsRepository _repository = ArcOperationsRepository();

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
      backgroundColor: AppTheme.darkBackground,
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
    return ArcRaidersSectionCard(
      accent: AppTheme.neonCyan,
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          final children = [
            _equippedPreview(
              label: 'Equipped Badge',
              value: equipped.hasBadge ? 'Active' : 'None equipped',
              assetPath: equipped.badgeAssetPath,
              icon: Icons.military_tech_rounded,
              accent: Colors.amberAccent,
            ),
            _equippedPreview(
              label: 'Profile Title',
              value: equipped.titleLabel ?? 'No title equipped',
              icon: Icons.title_rounded,
              accent: AppTheme.neonCyan,
            ),
            _equippedPreview(
              label: 'Inventory',
              value: '${userState.inventory.length} rewards owned',
              icon: Icons.inventory_2_rounded,
              accent: AppTheme.neonPink,
            ),
          ];
          if (compact) {
            return Column(
              children: [
                for (final child in children)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: child,
                  ),
              ],
            );
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
          ),
          const SizedBox(height: 10),
          _buildRecentUnlockPanel(userState),
          const SizedBox(height: 10),
          _buildBadgeInventoryGrid(userState),
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

  Widget _buildVaultSummaryGrid({
    required int badgeCount,
    required int titleCount,
    required int frameCount,
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
        ];

        if (compact) {
          return Column(
            children: [
              for (final child in children)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: child,
                ),
            ],
          );
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

  Widget _buildBadgeInventoryGrid(ArcOperationsUserState userState) {
    final ownedBadges = userState.inventory
        .where((item) => item.isBadge)
        .toList();
    final previewBadges = ArcOperationsSeedData.rewards.values
        .where((reward) => reward.type == ArcOperationRewardType.badge)
        .take(6)
        .toList();
    final equippedBadgeId = userState.equippedCosmetics.badgeId;

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
              final itemWidth = (width - (spacing * (columns - 1))) / columns;
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
                    SizedBox(width: itemWidth.clamp(118, 180), child: card),
                ],
              );
            },
          ),
        ],
      ),
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
                      onEquip: _repository.equipCosmetic,
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
