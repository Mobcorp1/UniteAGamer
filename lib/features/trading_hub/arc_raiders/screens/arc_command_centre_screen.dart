import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/build/app_drawer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_command_centre_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/my_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/nomadic_trader_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/smart_trade_assist_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/command_centre/arc_command_centre_widgets.dart';
import 'package:uag_arc_raiders_hub/screens/build/app_bar.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcCommandCentreScreen extends StatefulWidget {
  const ArcCommandCentreScreen({super.key});

  static const routeName = '/trading-hub/arc-raiders/command-centre';

  @override
  State<ArcCommandCentreScreen> createState() => _ArcCommandCentreScreenState();
}

class _ArcCommandCentreScreenState extends State<ArcCommandCentreScreen> {
  final ArcBlueprintRepository _blueprintRepository = ArcBlueprintRepository();
  final ArcSavedLoadoutRepository _loadoutRepository =
      ArcSavedLoadoutRepository();
  final Map<String, bool> _checklistState = <String, bool>{};

  void _handleAction(ArcCommandAction action) {
    switch (action.intent) {
      case ArcCommandActionIntent.route:
        final routeName = action.routeName;
        if (routeName == null || routeName.isEmpty) {
          _showPlaceholder(action);
          return;
        }
        Navigator.of(context).pushNamed(routeName);
      case ArcCommandActionIntent.favouriteLoadout:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FavouriteLoadoutScreen()),
        );
      case ArcCommandActionIntent.toolDeck:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MyHubScreen()));
      case ArcCommandActionIntent.smartTrade:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SmartTradeAssistScreen()),
        );
      case ArcCommandActionIntent.nomadicTrader:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const NomadicTraderScreen()));
      case ArcCommandActionIntent.placeholder:
        _showPlaceholder(action);
    }
  }

  void _showPlaceholder(ArcCommandAction action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          action.placeholderMessage ??
              '${action.label} will come online in a later Command Centre pass.',
          style: AppTheme.bodyTextStyle(fontSize: 12, color: Colors.white70),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: const UagAppBar(
        title: 'Command Centre',
        subtitle: 'Your next ARC Raiders move',
        showLogout: true,
      ),
      drawer: const AppDrawer(),
      body: ArcRaidersScreenShell(
        showAdBanner: true,
        child: StreamBuilder<Map<String, ArcBlueprintState>>(
          stream: _blueprintRepository.watchMyBlueprintStates(),
          builder: (context, blueprintSnapshot) {
            final blueprintStates =
                blueprintSnapshot.data ?? <String, ArcBlueprintState>{};
            return StreamBuilder<List<ArcSavedLoadout>>(
              stream: _loadoutRepository.watchSavedLoadouts(),
              builder: (context, loadoutSnapshot) {
                final loadouts =
                    loadoutSnapshot.data ?? const <ArcSavedLoadout>[];
                final commandState = ArcCommandCentreEngine.build(
                  blueprintStates: blueprintStates,
                  savedLoadouts: loadouts,
                );

                return ArcRaidersPageList(
                  maxWidth: 1220,
                  bottomPadding: 68,
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  children: [
                    ArcRaidersPageHeader(
                      title: 'ARC COMMAND CENTRE',
                      subtitle:
                          'Priority, blockers, trades and daily actions in one scan.',
                      icon: Icons.dashboard_customize_rounded,
                      accent: AppTheme.neonCyan,
                      trailing: ArcCommandActionButton(
                        action: const ArcCommandAction(
                          label: 'Tool Deck',
                          intent: ArcCommandActionIntent.toolDeck,
                        ),
                        accent: AppTheme.neonPink,
                        compact: true,
                        onPressed: () => _handleAction(
                          const ArcCommandAction(
                            label: 'Tool Deck',
                            intent: ArcCommandActionIntent.toolDeck,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _priorityHero(commandState.priority),
                    const SizedBox(height: 10),
                    _snapshotGrid(commandState.snapshots),
                    const SizedBox(height: 10),
                    _objectivesAndAlerts(commandState),
                    const SizedBox(height: 10),
                    _responsiveGrid(
                      minTileWidth: 340,
                      children: [
                        _tradeSummary(commandState.tradeSummary),
                        _summaryPanel(commandState.blueprintSummary),
                        _summaryPanel(commandState.questSummary),
                        _summaryPanel(commandState.benchSummary),
                        _resourceSummary(commandState.resources),
                        _summaryPanel(commandState.weeklyTraderSummary),
                        _recommendations(commandState.recommendations),
                        _dailyChecklist(commandState.checklist),
                        _summaryPanel(commandState.communitySummary),
                        _summaryPanel(commandState.statisticsSummary),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _priorityHero(ArcCommandPriority priority) {
    final accent = arcCommandStatusAccent(priority.status);
    return ArcCommandCentreCard(
      accent: accent,
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_statusIcon(priority.status), color: accent, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          priority.title.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.tradingHeading(
                            fontSize: compact ? 24 : 31,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          priority.explanation,
                          maxLines: compact ? 3 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.bodyTextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            isBold: true,
                          ).copyWith(height: 1.28),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ArcCommandStatusPill(
                    label: priority.statusTag,
                    status: priority.status,
                  ),
                  ArcCommandStatusPill(
                    label: priority.progressLabel,
                    status: ArcCommandStatus.neutral,
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                priority.detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyTextStyle(
                  fontSize: 12,
                  color: Colors.white60,
                ),
              ),
            ],
          );

          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: compact ? WrapAlignment.start : WrapAlignment.end,
            children: [
              ArcCommandActionButton(
                action: priority.primaryAction,
                accent: accent,
                onPressed: () => _handleAction(priority.primaryAction),
              ),
              if (priority.secondaryAction != null)
                ArcCommandActionButton(
                  action: priority.secondaryAction!,
                  accent: AppTheme.neonCyan,
                  compact: true,
                  onPressed: () => _handleAction(priority.secondaryAction!),
                ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [content, const SizedBox(height: 12), actions],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: content),
              const SizedBox(width: 14),
              Flexible(child: actions),
            ],
          );
        },
      ),
    );
  }

  Widget _snapshotGrid(List<ArcCommandSnapshotMetric> snapshots) {
    return _responsiveGrid(
      minTileWidth: 180,
      spacing: 8,
      children: snapshots.map(_snapshotTile).toList(growable: false),
    );
  }

  Widget _snapshotTile(ArcCommandSnapshotMetric metric) {
    final accent = arcCommandStatusAccent(metric.status);
    return ArcCommandCentreCard(
      accent: accent,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Icon(_statusIcon(metric.status), color: accent, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.tradingHeading(fontSize: 19, color: accent),
                ),
                Text(
                  metric.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 10,
                    color: Colors.white54,
                    isBold: true,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  metric.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 10,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _objectivesAndAlerts(ArcCommandCentreState commandState) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 860;
        final objectives = _objectives(commandState.objectives);
        final alerts = _alerts(commandState.alerts);
        if (compact) {
          return Column(
            children: [objectives, const SizedBox(height: 10), alerts],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: objectives),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: alerts),
          ],
        );
      },
    );
  }

  Widget _objectives(List<ArcCommandObjective> objectives) {
    return ArcCommandCentreCard(
      accent: AppTheme.neonCyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ArcCommandSectionHeader(
            title: 'Active Objectives',
            subtitle: 'Generated from the current command centre state.',
            accent: AppTheme.neonCyan,
          ),
          const SizedBox(height: 10),
          for (final objective in objectives) ...[
            _objectiveRow(objective),
            if (objective != objectives.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _objectiveRow(ArcCommandObjective objective) {
    final accent = arcCommandStatusAccent(objective.status);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _innerDecoration(accent),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_statusIcon(objective.status), color: accent, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        objective.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodyTextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          isBold: true,
                        ),
                      ),
                    ),
                    ArcCommandStatusPill(
                      label: objective.statusLabel,
                      status: objective.status,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  objective.reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 11,
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        objective.progressText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodyTextStyle(
                          fontSize: 10,
                          color: accent,
                          isBold: true,
                        ),
                      ),
                    ),
                    ArcCommandActionButton(
                      action: objective.action,
                      accent: accent,
                      compact: true,
                      onPressed: () => _handleAction(objective.action),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _alerts(List<ArcCommandAlert> alerts) {
    return ArcCommandCentreCard(
      accent: AppTheme.neonPink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ArcCommandSectionHeader(
            title: 'Inventory Alerts',
            subtitle: 'Blockers and setup warnings.',
            accent: AppTheme.neonPink,
          ),
          const SizedBox(height: 10),
          for (final alert in alerts) ...[
            _alertRow(alert),
            if (alert != alerts.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _alertRow(ArcCommandAlert alert) {
    final accent = arcCommandStatusAccent(alert.status);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _innerDecoration(accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_statusIcon(alert.status), color: accent, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    isBold: true,
                  ),
                ),
              ),
              ArcCommandStatusPill(
                label: alert.statusLabel,
                status: alert.status,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            alert.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyTextStyle(fontSize: 11, color: Colors.white60),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: ArcCommandActionButton(
              action: alert.action,
              accent: accent,
              compact: true,
              onPressed: () => _handleAction(alert.action),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tradeSummary(ArcCommandTradeSummary summary) {
    return ArcCommandCentreCard(
      accent: AppTheme.neonPink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ArcCommandSectionHeader(
            title: 'Trade Centre Snapshot',
            subtitle: 'Looking-for and offering lanes.',
            accent: AppTheme.neonPink,
          ),
          const SizedBox(height: 10),
          _tradeLane('Looking For', summary.lookingFor, AppTheme.neonCyan),
          const SizedBox(height: 8),
          _tradeLane('Offering', summary.offering, Colors.amberAccent),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final action in summary.actions)
                ArcCommandActionButton(
                  action: action,
                  accent: AppTheme.neonPink,
                  compact: true,
                  onPressed: () => _handleAction(action),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tradeLane(String title, List<String> items, Color accent) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _innerDecoration(accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTheme.bodyTextStyle(
              fontSize: 10,
              color: accent,
              isBold: true,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final item in items)
                ArcCommandStatusPill(
                  label: item,
                  status: ArcCommandStatus.neutral,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryPanel(ArcCommandSummaryPanel panel) {
    final accent = arcCommandStatusAccent(panel.status);
    return ArcCommandCentreCard(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ArcCommandSectionHeader(
            title: panel.title,
            subtitle: panel.body,
            accent: accent,
            trailing: ArcCommandStatusPill(
              label: panel.statusLabel,
              status: panel.status,
            ),
          ),
          const SizedBox(height: 10),
          ArcCommandDetailList(details: panel.details),
          const SizedBox(height: 6),
          ArcCommandActionButton(
            action: panel.action,
            accent: accent,
            compact: true,
            onPressed: () => _handleAction(panel.action),
          ),
        ],
      ),
    );
  }

  Widget _resourceSummary(List<ArcCommandResourceStatus> resources) {
    return ArcCommandCentreCard(
      accent: Colors.lightGreenAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ArcCommandSectionHeader(
            title: 'Resource Summary',
            subtitle: 'Key resource readiness without fake stash counts.',
            accent: Colors.lightGreenAccent,
          ),
          const SizedBox(height: 10),
          for (final resource in resources) ...[
            _resourceRow(resource),
            if (resource != resources.last) const SizedBox(height: 7),
          ],
        ],
      ),
    );
  }

  Widget _resourceRow(ArcCommandResourceStatus resource) {
    final accent = arcCommandStatusAccent(resource.status);
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: _innerDecoration(accent),
      child: Row(
        children: [
          Icon(_statusIcon(resource.status), color: accent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              resource.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyTextStyle(
                fontSize: 12,
                color: Colors.white,
                isBold: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '${resource.ownedLabel} - ${resource.requiredLabel}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: AppTheme.bodyTextStyle(
                fontSize: 10,
                color: Colors.white54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recommendations(List<ArcCommandRecommendation> recommendations) {
    return ArcCommandCentreCard(
      accent: Colors.amberAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ArcCommandSectionHeader(
            title: 'Smart Recommendations',
            subtitle: 'Structured guidance from the phase 1 engine.',
            accent: Colors.amberAccent,
          ),
          const SizedBox(height: 10),
          for (final recommendation in recommendations) ...[
            _recommendationRow(recommendation),
            if (recommendation != recommendations.last)
              const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _recommendationRow(ArcCommandRecommendation recommendation) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _innerDecoration(Colors.amberAccent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recommendation.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyTextStyle(
              fontSize: 13,
              color: Colors.white,
              isBold: true,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            recommendation.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyTextStyle(fontSize: 11, color: Colors.white60),
          ),
          const SizedBox(height: 7),
          ArcCommandActionButton(
            action: recommendation.action,
            accent: Colors.amberAccent,
            compact: true,
            onPressed: () => _handleAction(recommendation.action),
          ),
        ],
      ),
    );
  }

  Widget _dailyChecklist(List<ArcCommandChecklistItem> checklist) {
    return ArcCommandCentreCard(
      accent: AppTheme.neonCyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ArcCommandSectionHeader(
            title: 'Daily Checklist',
            subtitle: 'Local UI state for beta phase 1.',
            accent: AppTheme.neonCyan,
          ),
          const SizedBox(height: 10),
          for (final item in checklist) ...[
            _checklistRow(item),
            if (item != checklist.last) const SizedBox(height: 7),
          ],
        ],
      ),
    );
  }

  Widget _checklistRow(ArcCommandChecklistItem item) {
    final checked = _checklistState[item.id] ?? item.doneByDefault;
    final accent = checked ? Colors.lightGreenAccent : AppTheme.neonCyan;
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: _innerDecoration(accent),
      child: Row(
        children: [
          Checkbox(
            value: checked,
            activeColor: Colors.lightGreenAccent,
            onChanged: (value) {
              setState(() => _checklistState[item.id] = value ?? false);
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 12,
                    color: checked ? Colors.lightGreenAccent : Colors.white,
                    isBold: true,
                  ),
                ),
                Text(
                  item.reason,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 10,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ArcCommandActionButton(
            action: item.action,
            accent: accent,
            compact: true,
            onPressed: () => _handleAction(item.action),
          ),
        ],
      ),
    );
  }

  Widget _responsiveGrid({
    required List<Widget> children,
    double minTileWidth = 300,
    double spacing = 10,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / minTileWidth)
            .floor()
            .clamp(1, 3)
            .toInt();
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }

  BoxDecoration _innerDecoration(Color accent) {
    return BoxDecoration(
      color: Colors.black.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: accent.withValues(alpha: 0.20)),
    );
  }

  IconData _statusIcon(ArcCommandStatus status) {
    switch (status) {
      case ArcCommandStatus.critical:
        return Icons.priority_high_rounded;
      case ArcCommandStatus.warning:
        return Icons.warning_amber_rounded;
      case ArcCommandStatus.active:
        return Icons.radar_rounded;
      case ArcCommandStatus.ready:
        return Icons.swap_horiz_rounded;
      case ArcCommandStatus.neutral:
        return Icons.circle_outlined;
      case ArcCommandStatus.success:
        return Icons.check_circle_rounded;
    }
  }
}
