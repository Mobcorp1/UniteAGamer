import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_operations_seed_data.dart';
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
    final tasks = switch (index) {
      0 => ArcOperationsSeedData.dailyOperations,
      1 => ArcOperationsSeedData.weeklyOperations,
      2 => ArcOperationsSeedData.monthlyOperations,
      3 => ArcOperationsSeedData.lifetimeOperations,
      _ => ArcOperationsSeedData.betaOperations,
    };

    final title = switch (index) {
      0 => 'Daily Adaptive Ops',
      1 => 'Weekly Operations',
      2 => 'Monthly Operations',
      3 => 'Lifetime Commendations',
      _ => 'Closed Beta Exclusives',
    };

    final subtitle = switch (index) {
      0 =>
        'Generated from player needs, community health and platform growth requirements.',
      1 =>
        'Higher value weekly goals that encourage trades, verified intel and squad activity.',
      2 =>
        'Longer goals with stronger rewards and community reputation impact.',
      3 => 'Permanent trophies that never reset after wipes.',
      _ => 'Unique closed beta rewards that will never be earnable again.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ArcRaidersHeroBanner(
          title: title,
          subtitle: subtitle,
          accent: index == 4 ? Colors.amberAccent : AppTheme.neonCyan,
        ),
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
