import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_regional_map_conditions.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

enum ArcIntelligenceWorkspace { raidMap, community, explorer, planner }

extension ArcIntelligenceWorkspaceLabel on ArcIntelligenceWorkspace {
  String get label {
    switch (this) {
      case ArcIntelligenceWorkspace.raidMap:
        return 'Raid Map';
      case ArcIntelligenceWorkspace.community:
        return 'Community';
      case ArcIntelligenceWorkspace.explorer:
        return 'Explorer';
      case ArcIntelligenceWorkspace.planner:
        return 'Planner';
    }
  }

  IconData get icon {
    switch (this) {
      case ArcIntelligenceWorkspace.raidMap:
        return Icons.map_outlined;
      case ArcIntelligenceWorkspace.community:
        return Icons.radar_rounded;
      case ArcIntelligenceWorkspace.explorer:
        return Icons.manage_search_rounded;
      case ArcIntelligenceWorkspace.planner:
        return Icons.timeline_rounded;
    }
  }

  String get routeName {
    switch (this) {
      case ArcIntelligenceWorkspace.raidMap:
        return '/trading-hub/arc-raiders/raid-intelligence';
      case ArcIntelligenceWorkspace.community:
        return '/trading-hub/arc-raiders/market';
      case ArcIntelligenceWorkspace.explorer:
        return '/trading-hub/arc-raiders/intel-explorer';
      case ArcIntelligenceWorkspace.planner:
        return '/trading-hub/arc-raiders/raid-planner';
    }
  }
}

/// Compact cross-feature navigation for the Raid Intelligence family.
///
/// This is intentionally navigation-only: it does not repeat page summaries or
/// feature descriptions, which keeps the later screen-by-screen de-duplication
/// audit separate from architecture convergence.
class ArcIntelligenceWorkspaceBar extends StatelessWidget {
  const ArcIntelligenceWorkspaceBar({
    super.key,
    required this.current,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  final ArcIntelligenceWorkspace current;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (final workspace in ArcIntelligenceWorkspace.values) ...[
              _WorkspaceButton(
                workspace: workspace,
                selected: workspace == current,
                onTap: workspace == current
                    ? null
                    : () =>
                          Navigator.of(context).pushNamed(workspace.routeName),
              ),
              if (workspace != ArcIntelligenceWorkspace.values.last)
                const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _WorkspaceButton extends StatelessWidget {
  const _WorkspaceButton({
    required this.workspace,
    required this.selected,
    required this.onTap,
  });

  final ArcIntelligenceWorkspace workspace;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = selected
        ? ArcUiTokens.primaryAccent
        : ArcUiTokens.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      label: '${workspace.label} intelligence workspace',
      child: InkWell(
        borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppTheme.fastAnimation,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: ArcUiTokens.chipDecoration(
            color: accent,
            selected: selected,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(workspace.icon, size: 16, color: accent),
              const SizedBox(width: 7),
              Text(
                workspace.label.toUpperCase(),
                style: ArcUiTokens.label(color: accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pure view-model helpers for the official regional map-condition feed.
class ArcRegionalConditionDigest {
  ArcRegionalConditionDigest._();

  static String normalizeMapName(String value) {
    var normalized = value.trim().toLowerCase();
    if (normalized.startsWith('the ')) {
      normalized = normalized.substring(4);
    }
    return normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  static DateTime effectiveServerNow(
    ArcRegionalMapConditionsSnapshot snapshot, {
    DateTime? localNowUtc,
  }) {
    final now = localNowUtc ?? DateTime.now().toUtc();
    final elapsed = now.difference(snapshot.loadedAtUtc);
    if (elapsed.isNegative) return snapshot.serverNowUtc;
    return snapshot.serverNowUtc.add(elapsed);
  }

  static List<ArcRegionalMapConditionEntry> activeEntries(
    ArcRegionalMapConditionsSnapshot snapshot, {
    required ArcServerRegion region,
    String? mapDisplayName,
    DateTime? nowUtc,
  }) {
    final effectiveNow = nowUtc ?? effectiveServerNow(snapshot);
    final normalizedMap = mapDisplayName == null
        ? null
        : normalizeMapName(mapDisplayName);
    return snapshot.entries
        .where((entry) {
          if (normalizedMap != null &&
              normalizeMapName(entry.mapDisplayName) != normalizedMap) {
            return false;
          }
          final window = entry.windowFor(region);
          return window != null && window.isActiveAt(effectiveNow);
        })
        .toList(growable: false);
  }

  static List<ArcRegionalMapConditionEntry> upcomingEntries(
    ArcRegionalMapConditionsSnapshot snapshot, {
    required ArcServerRegion region,
    String? mapDisplayName,
    DateTime? nowUtc,
    int limit = 4,
  }) {
    final effectiveNow = nowUtc ?? effectiveServerNow(snapshot);
    final normalizedMap = mapDisplayName == null
        ? null
        : normalizeMapName(mapDisplayName);
    final entries =
        snapshot.entries
            .where((entry) {
              if (normalizedMap != null &&
                  normalizeMapName(entry.mapDisplayName) != normalizedMap) {
                return false;
              }
              final window = entry.windowFor(region);
              return window != null && window.startUtc.isAfter(effectiveNow);
            })
            .toList(growable: false)
          ..sort((a, b) {
            final aWindow = a.windowFor(region)!;
            final bWindow = b.windowFor(region)!;
            return aWindow.startUtc.compareTo(bWindow.startUtc);
          });
    return entries.take(limit).toList(growable: false);
  }
}

/// Shared live official-map-condition surface for the intelligence family.
///
/// When a map is supplied the card focuses on that map. Without a map it gives
/// a compact regional snapshot across the active maps.
class ArcLiveMapConditionsStrip extends StatefulWidget {
  const ArcLiveMapConditionsStrip({
    super.key,
    this.mapDisplayName,
    this.initialRegion = ArcServerRegion.europe,
    this.compact = false,
  });

  final String? mapDisplayName;
  final ArcServerRegion initialRegion;
  final bool compact;

  @override
  State<ArcLiveMapConditionsStrip> createState() =>
      _ArcLiveMapConditionsStripState();
}

class _ArcLiveMapConditionsStripState extends State<ArcLiveMapConditionsStrip> {
  late ArcServerRegion _region;
  late Future<ArcRegionalMapConditionsSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _region = widget.initialRegion;
    _future = ArcRegionalMapConditionsService.load();
  }

  @override
  void didUpdateWidget(covariant ArcLiveMapConditionsStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRegion != widget.initialRegion) {
      _region = widget.initialRegion;
    }
  }

  void _refresh() {
    setState(() {
      _future = ArcRegionalMapConditionsService.load(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ArcRegionalMapConditionsSnapshot>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return ArcRaidersSectionCard(
            radius: ArcUiTokens.radiusM,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ArcUiTokens.primaryAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Checking official regional map conditions...',
                    style: ArcUiTokens.bodySmall(),
                  ),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data!;
        final now = ArcRegionalConditionDigest.effectiveServerNow(data);
        final active = ArcRegionalConditionDigest.activeEntries(
          data,
          region: _region,
          mapDisplayName: widget.mapDisplayName,
          nowUtc: now,
        );
        final upcoming = ArcRegionalConditionDigest.upcomingEntries(
          data,
          region: _region,
          mapDisplayName: widget.mapDisplayName,
          nowUtc: now,
          limit: widget.mapDisplayName == null ? 3 : 1,
        );
        final sourceAccent = data.isOfficialLive
            ? ArcUiTokens.success
            : ArcUiTokens.warning;

        return ArcRaidersSectionCard(
          accent: sourceAccent,
          radius: ArcUiTokens.radiusM,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.sensors_rounded, size: 17, color: sourceAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.mapDisplayName == null
                          ? 'LIVE REGIONAL CONDITIONS'
                          : 'LIVE ${widget.mapDisplayName!.toUpperCase()} CONDITIONS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ArcUiTokens.label(color: sourceAccent),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _regionMenu(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Refresh official conditions',
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    color: ArcUiTokens.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (active.isEmpty)
                Text(
                  upcoming.isEmpty
                      ? 'No scheduled condition is available for this view.'
                      : 'No special condition is active right now.',
                  style: ArcUiTokens.bodySmall(
                    color: ArcUiTokens.textSecondary,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in active.take(widget.compact ? 2 : 4))
                      _ConditionPill(
                        entry: entry,
                        region: _region,
                        nowUtc: now,
                        active: true,
                        includeMap: widget.mapDisplayName == null,
                      ),
                  ],
                ),
              if (upcoming.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  widget.mapDisplayName == null
                      ? 'NEXT WINDOWS'
                      : 'NEXT WINDOW',
                  style: ArcUiTokens.metadata(color: ArcUiTokens.textTertiary),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in upcoming)
                      _ConditionPill(
                        entry: entry,
                        region: _region,
                        nowUtc: now,
                        active: false,
                        includeMap: widget.mapDisplayName == null,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                data.isOfficialLive
                    ? 'Official ARC Raiders schedule - refreshed from the live source.'
                    : 'Official captured schedule fallback - live refresh is temporarily unavailable.',
                maxLines: widget.compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: ArcUiTokens.metadata(color: ArcUiTokens.textTertiary),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _regionMenu() {
    return PopupMenuButton<ArcServerRegion>(
      tooltip: 'ARC server region',
      initialValue: _region,
      color: ArcUiTokens.surfaceOverlay,
      onSelected: (region) => setState(() => _region = region),
      itemBuilder: (context) => [
        for (final region in ArcServerRegion.values)
          PopupMenuItem(value: region, child: Text(region.label)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: ArcUiTokens.chipDecoration(
          color: ArcUiTokens.primaryAccent,
          selected: true,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.public_rounded,
              size: 14,
              color: ArcUiTokens.primaryAccent,
            ),
            const SizedBox(width: 5),
            Text(
              _region.label,
              style: ArcUiTokens.metadata(color: ArcUiTokens.primaryAccent),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.expand_more_rounded,
              size: 14,
              color: ArcUiTokens.primaryAccent,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConditionPill extends StatelessWidget {
  const _ConditionPill({
    required this.entry,
    required this.region,
    required this.nowUtc,
    required this.active,
    required this.includeMap,
  });

  final ArcRegionalMapConditionEntry entry;
  final ArcServerRegion region;
  final DateTime nowUtc;
  final bool active;
  final bool includeMap;

  @override
  Widget build(BuildContext context) {
    final window = entry.windowFor(region)!;
    final remaining = active
        ? window.endUtc.difference(nowUtc)
        : window.startUtc.difference(nowUtc);
    final accent = active ? ArcUiTokens.success : ArcUiTokens.primaryAccent;
    final timing = active
        ? '${_durationLabel(remaining)} left'
        : 'in ${_durationLabel(remaining)}';
    final label = includeMap
        ? '${entry.mapDisplayName} - ${entry.conditionName}'
        : entry.conditionName;

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: ArcUiTokens.chipDecoration(color: accent, selected: active),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.bolt_rounded : Icons.schedule_rounded,
            size: 14,
            color: accent,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              '$label - $timing',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ArcUiTokens.metadata(color: accent),
            ),
          ),
        ],
      ),
    );
  }

  static String _durationLabel(Duration value) {
    if (value.isNegative || value == Duration.zero) return 'now';
    if (value.inHours >= 1) {
      final minutes = value.inMinutes.remainder(60);
      return minutes == 0
          ? '${value.inHours}h'
          : '${value.inHours}h ${minutes}m';
    }
    return '${value.inMinutes.clamp(1, 59)}m';
  }
}
