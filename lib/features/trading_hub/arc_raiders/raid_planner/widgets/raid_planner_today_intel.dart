import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raider_goal_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_live_raid_recommendation_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_regional_map_conditions.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

class RaidPlannerTodayIntel extends StatelessWidget {
  const RaidPlannerTodayIntel({
    super.key,
    required this.intel,
    required this.now,
    required this.onSetPlaytime,
    required this.onSelectGoals,
    required this.onOpenFinder,
    this.scheduleStale = false,
  });

  final ArcTodayRaidIntel intel;
  final DateTime now;
  final VoidCallback onSetPlaytime;
  final VoidCallback onSelectGoals;
  final VoidCallback onOpenFinder;
  final bool scheduleStale;

  String _clock(DateTime value) {
    final local = value.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _window(DateTime start, DateTime end) {
    final a = start.toLocal();
    final b = end.toLocal();
    final today = now.toLocal();
    final date =
        a.year != today.year || a.month != today.month || a.day != today.day
        ? '${a.day}/${a.month} '
        : '';
    final crossesDay = a.year != b.year || a.month != b.month || a.day != b.day;
    return '$date${_clock(start)}–${_clock(end)}${crossesDay ? ' (+1 day)' : ''}';
  }

  String _duration(Duration duration) {
    final minutes = duration.inMinutes.clamp(0, 1440);
    return minutes >= 60 ? '${minutes ~/ 60}h ${minutes % 60}m' : '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final local = now.toLocal();
    final needsPlaytime =
        intel.status == ArcTodayRaidIntelStatus.noAvailability;
    final needsGoals = intel.status == ArcTodayRaidIntelStatus.noGoals;
    final noCurrentSchedule = scheduleStale && !needsPlaytime && !needsGoals;
    final title = needsPlaytime
        ? 'SET YOUR PLAYTIME'
        : needsGoals
        ? 'NO ACTIVE TARGETS'
        : noCurrentSchedule
        ? "TODAY'S SCHEDULE UNAVAILABLE"
        : 'NO PRIORITY WINDOWS DURING YOUR PLAYTIME TODAY';
    final detail = needsPlaytime
        ? "Add your usual availability in Profile so UAG can filter today's events around when you actually play."
        : needsGoals
        ? "Add an Active Hunt blueprint or choose an item objective to personalise today's Raid Intel."
        : noCurrentSchedule
        ? 'The schedule could not be refreshed. Saved times may be out of date.'
        : intel.status == ArcTodayRaidIntelStatus.noPlaytime
        ? 'No saved play window remains today. Your next session will appear on its local day.'
        : 'Your tracked objectives do not currently line up with an event during your saved play window.';
    return Container(
      padding: ArcUiTokens.compactPanelPadding,
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.panel,
        radius: ArcUiTokens.radiusM,
        accent: ArcUiTokens.primaryAccent,
        borderOpacity: 0.20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TODAY'S RAID INTEL",
            style: ArcUiTokens.sectionTitle(color: ArcUiTokens.primaryAccent),
          ),
          Text(
            '${local.day}/${local.month} · Local time',
            style: ArcUiTokens.metadata(),
          ),
          if (intel.playtime.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'YOUR PLAYTIME: ${intel.playtime.map((w) => _window(w.startUtc, w.endUtc)).join(' · ')}',
              style: ArcUiTokens.bodySmall(color: ArcUiTokens.textPrimary),
            ),
          ],
          const SizedBox(height: 12),
          if (intel.recommendations.isEmpty) ...[
            Text(title, style: ArcUiTokens.cardTitle(fontSize: 14)),
            const SizedBox(height: 6),
            Text(detail, style: ArcUiTokens.bodySmall()),
          ] else ...[
            if (scheduleStale)
              Text(
                'Saved schedule — times need confirmation.',
                style: ArcUiTokens.bodySmall(color: ArcUiTokens.warning),
              ),
            for (final item in intel.recommendations) _recommendation(item),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton(
                onPressed: onSetPlaytime,
                child: Text(needsPlaytime ? 'Set playtime' : 'Edit playtime'),
              ),
              TextButton(
                onPressed: onSelectGoals,
                child: const Text('Choose objectives'),
              ),
              TextButton(
                onPressed: onOpenFinder,
                child: const Text('Open Event Finder'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recommendation(ArcTodayRaidRecommendation item) {
    final recommendation = item.recommendation;
    final candidate = recommendation.candidate;
    final live = candidate.isLive;
    final accent = live ? ArcUiTokens.success : ArcUiTokens.primaryAccent;
    return Container(
      key: ValueKey('today-recommendation:${candidate.key}'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: ArcUiTokens.densePanelPadding,
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.interactive,
        radius: ArcUiTokens.radiusS,
        accent: accent,
        borderOpacity: live ? 0.38 : 0.18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (live) Text('LIVE NOW', style: ArcUiTokens.label(color: accent)),
          Text(
            '${_clock(candidate.startUtc!)} — ${candidate.conditionName.toUpperCase()}',
            style: ArcUiTokens.cardTitle(fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(candidate.mapName, style: ArcUiTokens.bodySmall()),
          Text(
            '${_window(candidate.startUtc!, candidate.endUtc!)} local',
            style: ArcUiTokens.metadata(),
          ),
          const SizedBox(height: 6),
          if (recommendation.goalCount > 1)
            Text(
              '${recommendation.goalCount} OBJECTIVES ALIGNED',
              style: ArcUiTokens.label(color: accent),
            ),
          for (final goal in recommendation.matchedGoals)
            Text(
              'TARGET: ${goal.label}${goal.source == ArcRaiderGoalSource.blueprint ? ' Blueprint' : ''}',
              style: ArcUiTokens.bodySmall(color: ArcUiTokens.textPrimary),
            ),
          Text(
            'Matches your saved playtime',
            style: ArcUiTokens.metadata(color: accent),
          ),
          Text(
            live
                ? '${_duration(item.playableEndUtc.difference(now))} remaining in your playtime'
                : '${item.playableStartUtc.isAfter(candidate.startUtc!) ? 'Join' : 'Starts'} in ${_duration(item.playableStartUtc.difference(now))}',
            style: ArcUiTokens.bodySmall(color: accent),
          ),
          Text(
            item.homeRegion
                ? 'Stay on ${item.region.label}'
                : 'Switch ARC server to ${item.region.label}',
            style: ArcUiTokens.metadata(
              color: item.homeRegion
                  ? ArcUiTokens.textSecondary
                  : ArcUiTokens.secondaryAccent,
            ),
          ),
        ],
      ),
    );
  }
}
