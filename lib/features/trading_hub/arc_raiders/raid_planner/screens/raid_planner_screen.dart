import 'dart:async';

import 'package:flutter/material.dart';

import 'package:uag_traders_hub/build/app_bar.dart';
import 'package:uag_traders_hub/build/app_drawer.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_intel_seed.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_availability.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_drop_intel.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/raid_planner/data/raid_planner_blueprint_rules.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/raid_planner/data/raid_planner_engine.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/raid_planner/models/raid_planner_models.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/raid_planner/repositories/raid_planner_repository.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart';
import 'package:uag_traders_hub/widgets/collapsible_section_card.dart';
import 'package:uag_traders_hub/widgets/electric_charge_border.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class RaidPlannerScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/raid-planner';

  const RaidPlannerScreen({super.key});

  @override
  State<RaidPlannerScreen> createState() => _RaidPlannerScreenState();
}

class _RaidPlannerScreenState extends State<RaidPlannerScreen> {
  final RaidPlannerRepository _plannerRepository = RaidPlannerRepository();
  final ArcBlueprintRepository _blueprintRepository = ArcBlueprintRepository();
  final ArcTraderProfileRepository _profileRepository =
      ArcTraderProfileRepository();
  late final TextEditingController _eventFinderController;
  String _eventFinderQuery = '';

  late DateTime _plannerNowUtc;
  Timer? _plannerClockTimer;

  @override
  void initState() {
    super.initState();
    _plannerNowUtc = DateTime.now().toUtc();
    _eventFinderController = TextEditingController();
    _eventFinderController.addListener(_onEventFinderChanged);
    _plannerClockTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      setState(() {
        _plannerNowUtc = DateTime.now().toUtc();
      });
    });
  }

  void _onEventFinderChanged() {
    if (!mounted) return;
    setState(() {
      _eventFinderQuery = _eventFinderController.text;
    });
  }

  @override
  void dispose() {
    _plannerClockTimer?.cancel();
    _eventFinderController.removeListener(_onEventFinderChanged);
    _eventFinderController.dispose();
    super.dispose();
  }

  String _clock(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final zone = local.timeZoneName.isNotEmpty ? local.timeZoneName : 'local';
    return '$hour:$minute $zone';
  }

  String _durationLabel(Duration duration) {
    if (duration.isNegative) return 'now';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours <= 0) return '${minutes}m';
    return '${hours}h ${minutes}m';
  }

  String _eventSearchLabel(String query) {
    final value = query.trim();
    return value.isEmpty
        ? 'Type an event or map name to search windows.'
        : 'Showing next 3 windows for "$value".';
  }

  Color _tierColor(RaidTargetTier tier) {
    switch (tier) {
      case RaidTargetTier.activeHunt:
        return AppTheme.neonPink;
      case RaidTargetTier.nextUp:
        return AppTheme.neonCyan;
      case RaidTargetTier.later:
        return Colors.white70;
    }
  }

  int _tierLimit(RaidTargetTier tier, RaidPlannerEntitlement entitlement) {
    switch (tier) {
      case RaidTargetTier.activeHunt:
        return entitlement.activeHuntSlots.clamp(1, 5).toInt();
      case RaidTargetTier.nextUp:
      case RaidTargetTier.later:
        return 5;
    }
  }

  String _tierHelp(RaidTargetTier tier, RaidPlannerEntitlement entitlement) {
    switch (tier) {
      case RaidTargetTier.activeHunt:
        return 'Your top priority targets. Exact event windows are shown when these match Surge Coil, Canto or Dolabra. Your ${entitlement.tier.label} plan allows ${_tierLimit(tier, entitlement)} Active Hunt slot${_tierLimit(tier, entitlement) == 1 ? '' : 's'}.';
      case RaidTargetTier.nextUp:
        return 'Backup targets. When Active Hunt targets are owned or removed, these move up into the planner automatically.';
      case RaidTargetTier.later:
        return 'Lower priority targets to keep parked for later.';
    }
  }

  RaidBlueprintTarget? _findTarget(
    List<RaidBlueprintTarget> targets,
    String blueprintId,
  ) {
    for (final target in targets) {
      if (target.blueprintId == blueprintId) return target;
    }
    return null;
  }

  List<RaidBlueprintTarget> _targetsForTier(
    List<RaidBlueprintTarget> targets,
    RaidTargetTier tier,
  ) {
    final matching = targets.where((target) => target.tier == tier).toList()
      ..sort((a, b) {
        final rankCompare = a.rank.compareTo(b.rank);
        if (rankCompare != 0) return rankCompare;
        return a.blueprintId.compareTo(b.blueprintId);
      });
    return matching;
  }

  int _nextRank(List<RaidBlueprintTarget> targets, RaidTargetTier tier) {
    final matching = _targetsForTier(targets, tier);
    if (matching.isEmpty) return 0;
    return matching
            .map((target) => target.rank)
            .reduce((a, b) => a > b ? a : b) +
        1;
  }

  Future<void> _saveTarget({
    required ArcBlueprint blueprint,
    required RaidTargetTier tier,
    required List<RaidBlueprintTarget> targets,
    required RaidPlannerEntitlement entitlement,
    required Map<String, ArcBlueprintState> states,
  }) async {
    final isOwned = states[blueprint.id]?.owned ?? false;
    if (isOwned) {
      _showMessage('${blueprint.name} is already marked as owned.');
      return;
    }

    final current = _findTarget(targets, blueprint.id);
    final currentTier = current?.tier;
    final tierTargets = _targetsForTier(targets, tier);
    final limit = _tierLimit(tier, entitlement);

    if (currentTier != tier && tierTargets.length >= limit) {
      _showMessage('${tier.label} is full. Remove a target first.');
      return;
    }

    final next = RaidBlueprintTarget(
      blueprintId: blueprint.id,
      tier: tier,
      rank: currentTier == tier
          ? current?.rank ?? _nextRank(targets, tier)
          : _nextRank(targets, tier),
      createdAt: current?.createdAt,
    );

    await _plannerRepository.saveTarget(next);
    _showMessage('${blueprint.name} added to ${tier.label}.');
  }

  Future<void> _removeTarget(String blueprintId) async {
    final blueprint = RaidPlannerEngine.findBlueprintById(blueprintId);
    await _plannerRepository.removeTarget(blueprintId);
    _showMessage('${blueprint?.name ?? 'Target'} removed.');
  }

  Future<void> _clearTargets() async {
    await _plannerRepository.clearTargets();
    _showMessage('Raid Planner targets cleared.');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openBlueprintSearch({
    required RaidTargetTier tier,
    required List<RaidBlueprintTarget> targets,
    required RaidPlannerEntitlement entitlement,
    required Map<String, ArcBlueprintState> states,
  }) async {
    final targetedIds = targets.map((target) => target.blueprintId).toSet();
    final tierTargets = _targetsForTier(targets, tier);
    final limit = _tierLimit(tier, entitlement);

    if (tierTargets.length >= limit) {
      _showMessage('${tier.label} is full. Remove a target first.');
      return;
    }

    final selected = await showModalBottomSheet<ArcBlueprint>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return _BlueprintSearchSheet(
          tier: tier,
          titleColor: _tierColor(tier),
          targetedIds: targetedIds,
          states: states,
        );
      },
    );

    if (!mounted || selected == null) return;

    await _saveTarget(
      blueprint: selected,
      tier: tier,
      targets: targets,
      entitlement: entitlement,
      states: states,
    );
  }

  Widget _smallButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return ElectricChargeBorder(
      active: onTap != null,
      radius: 999,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: onTap == null
                ? Colors.white.withValues(alpha: 0.03)
                : color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: onTap == null
                  ? Colors.white24
                  : color.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: onTap == null ? Colors.white38 : color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTheme.buttonTextStyle(
                  color: onTap == null ? Colors.white38 : color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _targetTile(RaidBlueprintTarget target) {
    final blueprint = RaidPlannerEngine.findBlueprintById(target.blueprintId);
    final rule = RaidPlannerBlueprintRules.byBlueprintId(target.blueprintId);
    final seededHint = blueprint == null ? null : ArcBlueprintIntelLibrary.resolve(blueprint);
    final seededConditions = seededHint == null
        ? <String>[]
        : ArcBlueprintIntelLibrary.playableConditions(seededHint.bestConditions);
    final seededTimingLabel = rule?.eventName ??
        (seededConditions.isEmpty ? 'Seeded route enabled' : '${seededConditions.first} seeded route enabled');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _tierColor(target.tier).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: _tierColor(target.tier).withValues(alpha: 0.16),
            child: Text(
              '${target.rank + 1}',
              style: AppTheme.bodyTextStyle(
                color: _tierColor(target.tier),
                isBold: true,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  blueprint?.name ?? target.blueprintId,
                  style: AppTheme.tradingHeading(fontSize: 17),
                ),
                const SizedBox(height: 3),
                Text(
                  seededTimingLabel,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 12,
                    color: AppTheme.neonCyan,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove target',
            onPressed: () => _removeTarget(target.blueprintId),
            icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Widget _targetTierCard({
    required RaidTargetTier tier,
    required List<RaidBlueprintTarget> displayTargets,
    required List<RaidBlueprintTarget> storedTargets,
    required RaidPlannerEntitlement entitlement,
    required Map<String, ArcBlueprintState> states,
    bool initiallyExpanded = true,
  }) {
    final limit = _tierLimit(tier, entitlement);
    final canAdd = _targetsForTier(storedTargets, tier).length < limit;
    return CollapsibleSectionCard(
      title: '${tier.label} (${displayTargets.length}/$limit)',
      titleColor: _tierColor(tier),
      initiallyExpanded: initiallyExpanded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tierHelp(tier, entitlement),
            style: AppTheme.bodyTextStyle(
              fontSize: 13,
              color: AppTheme.tradingMutedText,
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          if (displayTargets.isEmpty)
            Text(
              'No ${tier.label} targets selected.',
              style: AppTheme.bodyTextStyle(
                fontSize: 13,
                color: AppTheme.tradingMutedText,
              ),
            )
          else
            ...displayTargets.map(_targetTile),
          const SizedBox(height: AppTheme.spaceS),
          _smallButton(
            label: canAdd ? 'Search + Add Target' : '${tier.label} Full',
            icon: Icons.search_rounded,
            color: _tierColor(tier),
            onTap: canAdd
                ? () => _openBlueprintSearch(
                    tier: tier,
                    targets: storedTargets,
                    entitlement: entitlement,
                    states: states,
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _opportunityCard(RaidPlannerOpportunity opportunity, DateTime utcNow) {
    final live = opportunity.isLive;
    final timeText = live
        ? 'Ends in ${_durationLabel(opportunity.timeRemaining(utcNow))}'
        : 'Starts in ${_durationLabel(opportunity.timeUntil(utcNow))}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (live ? AppTheme.neonPink : AppTheme.neonCyan).withValues(
            alpha: 0.35,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            live ? Icons.flash_on_rounded : Icons.schedule_rounded,
            color: live ? AppTheme.neonPink : AppTheme.neonCyan,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${opportunity.rule.blueprintName} • ${opportunity.slot.eventName}${opportunity.rule.isExactEventRule ? '' : ' boost'}',
                  style: AppTheme.tradingHeading(fontSize: 17),
                ),
                const SizedBox(height: 4),
                Text(
                  '${opportunity.slot.mapName} • ${opportunity.slot.lane} • ${_clock(opportunity.startUtc)}-${_clock(opportunity.endUtc)}',
                  style: AppTheme.bodyTextStyle(
                    fontSize: 13,
                    color: AppTheme.tradingMutedText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeText,
                  style: AppTheme.bodyTextStyle(
                    color: live ? AppTheme.neonPink : AppTheme.neonCyan,
                    isBold: true,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventFinderCard(DateTime utcNow) {
    final normalized = _eventFinderQuery.trim().toLowerCase();
    final windows = normalized.length < 2
        ? <RaidPlannerOpportunity>[]
        : RaidPlannerEngine.eventLookup(
            query: normalized,
            nowUtc: utcNow,
            limit: 3,
          );

    return CollapsibleSectionCard(
      title: 'Event Finder',
      titleColor: AppTheme.neonCyan,
      initiallyExpanded: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search any event or map to see the next 3 matching windows. This uses the same live UTC schedule as the planner and converts times to your device timezone.',
            style: AppTheme.bodyTextStyle(
              fontSize: 13,
              color: AppTheme.tradingMutedText,
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          TextField(
            controller: _eventFinderController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Search event or map',
              hintText: 'Locked Gate, lock gate, Hurricane, Dam...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _eventFinderQuery.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: _eventFinderController.clear,
                      icon: const Icon(Icons.close_rounded),
                    ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: AppTheme.neonCyan.withValues(alpha: 0.45),
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: AppTheme.neonCyan),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          Text(
            _eventSearchLabel(_eventFinderQuery),
            style: AppTheme.bodyTextStyle(
              fontSize: 13,
              color: AppTheme.tradingMutedText,
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          if (normalized.length >= 2 && windows.isEmpty)
            Text(
              'No matching upcoming event windows found.',
              style: AppTheme.bodyTextStyle(
                fontSize: 13,
                color: AppTheme.tradingMutedText,
              ),
            )
          else
            ...windows.map((opportunity) => _opportunityCard(opportunity, utcNow)),
        ],
      ),
    );
  }

  bool _overlaps(
    DateTime startA,
    DateTime endA,
    DateTime startB,
    DateTime endB,
  ) {
    return startA.isBefore(endB) && endA.isAfter(startB);
  }

  int _weekdayIndexToDart(String dayKey) {
    switch (dayKey) {
      case 'mon':
        return DateTime.monday;
      case 'tue':
        return DateTime.tuesday;
      case 'wed':
        return DateTime.wednesday;
      case 'thu':
        return DateTime.thursday;
      case 'fri':
        return DateTime.friday;
      case 'sat':
        return DateTime.saturday;
      case 'sun':
        return DateTime.sunday;
      default:
        return DateTime.monday;
    }
  }

  DateTime? _localDateTimeForSlot(DateTime localDay, String time) {
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return DateTime(localDay.year, localDay.month, localDay.day, hour, minute);
  }

  List<_AvailabilityWindow> _availabilityWindows(
    ArcAvailability availability,
    DateTime utcNow,
  ) {
    final localNow = utcNow.toLocal();
    final baseLocalDay = DateTime(localNow.year, localNow.month, localNow.day);
    final windows = <_AvailabilityWindow>[];
    final weeks = availability.weeks.isEmpty
        ? ArcAvailability.initial().weeks
        : availability.weeks;
    final week = weeks.first;

    for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
      final localDay = baseLocalDay.add(Duration(days: dayOffset));
      for (final slot in week.slots.where((slot) => slot.enabled)) {
        if (_weekdayIndexToDart(slot.dayKey) != localDay.weekday) continue;
        final localStart = _localDateTimeForSlot(localDay, slot.fromTime);
        var localEnd = _localDateTimeForSlot(localDay, slot.toTime);
        if (localStart == null || localEnd == null) continue;
        if (!localEnd.isAfter(localStart)) {
          localEnd = localEnd.add(const Duration(days: 1));
        }
        if (localEnd.toUtc().isBefore(utcNow)) continue;
        windows.add(
          _AvailabilityWindow(
            startUtc: localStart.toUtc(),
            endUtc: localEnd.toUtc(),
          ),
        );
      }
    }

    windows.sort((a, b) => a.startUtc.compareTo(b.startUtc));
    return windows;
  }

  Widget _availabilityPlannerCard({
    required List<RaidPlannerOpportunity> allOpportunities,
    required ArcAvailability availability,
    required DateTime utcNow,
  }) {
    final windows = _availabilityWindows(availability, utcNow);
    final inPlaytime = allOpportunities
        .where((opportunity) {
          return windows.any(
            (window) => _overlaps(
              opportunity.startUtc,
              opportunity.endUtc,
              window.startUtc,
              window.endUtc,
            ),
          );
        })
        .take(3)
        .toList(growable: false);

    final outsidePlaytime = allOpportunities
        .where((opportunity) {
          if (opportunity.isLive) return false;
          return !windows.any(
            (window) => _overlaps(
              opportunity.startUtc,
              opportunity.endUtc,
              window.startUtc,
              window.endUtc,
            ),
          );
        })
        .take(3)
        .toList(growable: false);

    return CollapsibleSectionCard(
      title: 'Playtime Match',
      titleColor: AppTheme.neonPink,
      initiallyExpanded: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            windows.isEmpty
                ? 'No active play windows found in your availability. Set your availability in Trader Profile to unlock playtime planning.'
                : 'Planner checks your saved availability and shows target events that overlap your usual gaming time.',
            style: AppTheme.bodyTextStyle(
              fontSize: 13,
              color: AppTheme.tradingMutedText,
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          Text(
            'Target windows inside your playtime',
            style: AppTheme.tradingHeading(
              fontSize: 18,
              color: AppTheme.neonCyan,
            ),
          ),
          const SizedBox(height: 8),
          if (inPlaytime.isEmpty)
            Text(
              'No selected Active Hunt target events line up with your saved playtime in the next 7 days.',
              style: AppTheme.bodyTextStyle(
                fontSize: 13,
                color: AppTheme.tradingMutedText,
              ),
            )
          else
            ...inPlaytime.map(
              (opportunity) => _opportunityCard(opportunity, utcNow),
            ),
          const SizedBox(height: AppTheme.spaceM),
          Text(
            'Useful windows you may need to move for',
            style: AppTheme.tradingHeading(
              fontSize: 18,
              color: AppTheme.neonPink,
            ),
          ),
          const SizedBox(height: 8),
          if (outsidePlaytime.isEmpty)
            Text(
              'No missed high-priority windows found for your current targets.',
              style: AppTheme.bodyTextStyle(
                fontSize: 13,
                color: AppTheme.tradingMutedText,
              ),
            )
          else
            ...outsidePlaytime.map(
              (opportunity) => _opportunityCard(opportunity, utcNow),
            ),
        ],
      ),
    );
  }


  Widget _intelLine(String label, String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label: $text',
        style: AppTheme.bodyTextStyle(
          fontSize: 12,
          color: AppTheme.tradingMutedText,
        ),
      ),
    );
  }

  Widget _targetIntelTile(RaidBlueprintTarget target) {
    final blueprint = RaidPlannerEngine.findBlueprintById(target.blueprintId);
    final seededHint = blueprint == null ? null : ArcBlueprintIntelLibrary.resolve(blueprint);
    return StreamBuilder<ArcDropIntel>(
      stream: _blueprintRepository.watchIntelForBlueprint(target.blueprintId),
      builder: (context, snapshot) {
        final intel = snapshot.data ?? ArcDropIntel.empty(target.blueprintId);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.radar_rounded, color: AppTheme.neonCyan, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      blueprint?.name ?? target.blueprintId,
                      style: AppTheme.tradingHeading(fontSize: 16),
                    ),
                  ),
                  Text(
                    '${intel.totalReports} report${intel.totalReports == 1 ? '' : 's'}',
                    style: AppTheme.bodyTextStyle(
                      fontSize: 12,
                      color: AppTheme.neonCyan,
                      isBold: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (!intel.hasReports) ...[
                Text(
                  'No community intel yet. Using seeded blueprint rules until player reports create a stronger route.',
                  style: AppTheme.bodyTextStyle(
                    fontSize: 12,
                    color: AppTheme.tradingMutedText,
                  ),
                ),
                if (seededHint != null) ...[
                  const SizedBox(height: 8),
                  _intelLine('Seed map', seededHint.likelyMaps.join(', ')),
                  _intelLine('Seed containers', seededHint.likelyContainers.join(', ')),
                  _intelLine('Seed condition/event', seededHint.bestConditions.join(', ')),
                ],
              ] else ...[
                _intelLine('Top map', intel.topMapLabel),
                _intelLine('Top area/source', intel.topAreaLabel),
                _intelLine('Top container', intel.topContainerLabel),
                _intelLine('Top condition/event', intel.topConditionLabel ?? intel.topMapEventLabel),
                if (intel.topCombinations.isNotEmpty)
                  Text(
                    'Best signal: ${intel.topCombinations.first.summaryLabel} (${intel.topCombinations.first.reportCount} weighted)',
                    style: AppTheme.bodyTextStyle(
                      fontSize: 12,
                      color: AppTheme.neonPink,
                      isBold: true,
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _communityIntelCard(List<RaidBlueprintTarget> activeTargets) {
    return CollapsibleSectionCard(
      title: 'Seeded + Community Intel Signals',
      titleColor: AppTheme.neonCyan,
      initiallyExpanded: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Every Active Hunt target now starts with seeded blueprint rules. Community reports only override the baseline when real player intel exists.',
            style: AppTheme.bodyTextStyle(
              fontSize: 13,
              color: AppTheme.tradingMutedText,
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          if (activeTargets.isEmpty)
            Text(
              'Add Active Hunt targets to show seeded route guidance and community intel.',
              style: AppTheme.bodyTextStyle(
                fontSize: 13,
                color: AppTheme.tradingMutedText,
              ),
            )
          else
            ...activeTargets.map(_targetIntelTile),
        ],
      ),
    );
  }
  Widget _buildContent({
    required List<RaidBlueprintTarget> targets,
    required RaidPlannerEntitlement entitlement,
    required Map<String, ArcBlueprintState> states,
    required ArcAvailability availability,
  }) {
    final effectiveTargets = RaidPlannerEngine.effectiveTargets(
      storedTargets: targets,
      states: states,
      entitlement: entitlement,
    );
    final utcNow = _plannerNowUtc;
    final allOpportunities = RaidPlannerEngine.allOpportunities(
      effectiveTargets: effectiveTargets,
      nowUtc: utcNow,
      horizonDays: 7,
    );

    final activeTargets = _targetsForTier(
      effectiveTargets,
      RaidTargetTier.activeHunt,
    );
    final intelTargets = activeTargets;
    final nextTargets = _targetsForTier(
      effectiveTargets,
      RaidTargetTier.nextUp,
    );
    final laterTargets = _targetsForTier(
      effectiveTargets,
      RaidTargetTier.later,
    );

    return ListView(
      padding: AppTheme.pagePadding,
      children: [
        _entitlementCard(entitlement),
        const SizedBox(height: 14),
        _availabilityPlannerCard(
          allOpportunities: allOpportunities,
          availability: availability,
          utcNow: utcNow,
        ),
        const SizedBox(height: 14),
        _eventFinderCard(utcNow),
        const SizedBox(height: 14),
        _communityIntelCard(intelTargets),
        const SizedBox(height: 14),
        _targetTierCard(
          tier: RaidTargetTier.activeHunt,
          displayTargets: activeTargets,
          storedTargets: targets,
          entitlement: entitlement,
          states: states,
          initiallyExpanded: true,
        ),
        const SizedBox(height: 14),
        _targetTierCard(
          tier: RaidTargetTier.nextUp,
          displayTargets: nextTargets,
          storedTargets: targets,
          entitlement: entitlement,
          states: states,
          initiallyExpanded: false,
        ),
        const SizedBox(height: 14),
        _targetTierCard(
          tier: RaidTargetTier.later,
          displayTargets: laterTargets,
          storedTargets: targets,
          entitlement: entitlement,
          states: states,
          initiallyExpanded: false,
        ),
        const SizedBox(height: 14),
        if (targets.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: _smallButton(
              label: 'Clear Planner Targets',
              icon: Icons.clear_all_rounded,
              color: Colors.redAccent,
              onTap: _clearTargets,
            ),
          ),
      ],
    );
  }

  Widget _entitlementCard(RaidPlannerEntitlement entitlement) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonPink.withValues(alpha: 0.18),
        radius: 18,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.workspace_premium_outlined,
            color: AppTheme.neonPink,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${entitlement.tier.label} plan • ${entitlement.activeHuntSlots.clamp(1, 5)} Active Hunt slot${entitlement.activeHuntSlots == 1 ? '' : 's'}',
              style: AppTheme.tradingHeading(
                fontSize: 18,
                color: AppTheme.neonPink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: const UagAppBar(
        title: 'Raid Planner',
        subtitle: 'Blueprint-driven event timing and session planning.',
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          SafeArea(
            child: StreamBuilder<RaidPlannerEntitlement>(
              stream: _plannerRepository.watchEntitlement(),
              builder: (context, entitlementSnapshot) {
                final entitlement =
                    entitlementSnapshot.data ??
                    const RaidPlannerEntitlement(tier: RaidPlannerTier.free);
                return StreamBuilder<List<RaidBlueprintTarget>>(
                  stream: _plannerRepository.watchTargets(),
                  builder: (context, targetsSnapshot) {
                    final targets =
                        targetsSnapshot.data ?? <RaidBlueprintTarget>[];
                    return StreamBuilder<Map<String, ArcBlueprintState>>(
                      stream: _blueprintRepository.watchMyBlueprintStates(),
                      builder: (context, statesSnapshot) {
                        final states =
                            statesSnapshot.data ??
                            <String, ArcBlueprintState>{};
                        return StreamBuilder<ArcAvailability>(
                          stream: _profileRepository.watchAvailability(),
                          builder: (context, availabilitySnapshot) {
                            final availability =
                                availabilitySnapshot.data ??
                                ArcAvailability.initial();
                            return _buildContent(
                              targets: targets,
                              entitlement: entitlement,
                              states: states,
                              availability: availability,
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BlueprintSearchSheet extends StatefulWidget {
  const _BlueprintSearchSheet({
    required this.tier,
    required this.titleColor,
    required this.targetedIds,
    required this.states,
  });

  final RaidTargetTier tier;
  final Color titleColor;
  final Set<String> targetedIds;
  final Map<String, ArcBlueprintState> states;

  @override
  State<_BlueprintSearchSheet> createState() => _BlueprintSearchSheetState();
}

class _BlueprintSearchSheetState extends State<_BlueprintSearchSheet> {
  late final TextEditingController _controller;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    if (!mounted) return;
    setState(() {
      _query = _controller.text.trim().toLowerCase();
    });
  }

  List<ArcBlueprint> get _candidates {
    if (_query.length < 2) return <ArcBlueprint>[];
    return RaidPlannerEngine.supportedBlueprints.where((blueprint) {
      if (widget.targetedIds.contains(blueprint.id)) return false;
      if (widget.states[blueprint.id]?.owned ?? false) return false;
      return blueprint.name.toLowerCase().contains(_query);
    }).take(30).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final candidates = _candidates;
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spaceL,
        right: AppTheme.spaceL,
        top: AppTheme.spaceL,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spaceL,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.86,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Add ${widget.tier.label} Target',
                    style: AppTheme.tradingHeading(
                      fontSize: 22,
                      color: widget.titleColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceM),
            TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Search blueprint',
                hintText: 'Type Canto, Dolabra, Surge Coil...',
                prefixIcon: const Icon(Icons.search_rounded),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: widget.titleColor.withValues(alpha: 0.45),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: widget.titleColor),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceM),
            if (_query.length < 2)
              Text(
                'Type at least 2 characters to search your missing blueprints.',
                style: AppTheme.bodyTextStyle(
                  color: AppTheme.tradingMutedText,
                  fontSize: 13,
                ),
              )
            else if (candidates.isEmpty)
              Text(
                'No matching missing blueprints found.',
                style: AppTheme.bodyTextStyle(
                  color: AppTheme.tradingMutedText,
                  fontSize: 13,
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: candidates.length,
                  separatorBuilder: (_, _) => const Divider(color: Colors.white12),
                  itemBuilder: (context, index) {
                    final blueprint = candidates[index];
                    final rule = RaidPlannerBlueprintRules.byBlueprintId(blueprint.id);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        rule == null ? Icons.track_changes_rounded : Icons.bolt_rounded,
                        color: rule == null ? Colors.white70 : AppTheme.neonPink,
                      ),
                      title: Text(
                        blueprint.name,
                        style: AppTheme.tradingHeading(fontSize: 17),
                      ),
                      subtitle: Text(
                        rule == null
                            ? 'Seeded blueprint route available.'
                            : '${rule.eventName} — exact Raid Planner windows available.',
                        style: AppTheme.bodyTextStyle(
                          fontSize: 12,
                          color: AppTheme.tradingMutedText,
                        ),
                      ),
                      onTap: () => Navigator.of(context).pop(blueprint),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityWindow {
  const _AvailabilityWindow({required this.startUtc, required this.endUtc});

  final DateTime startUtc;
  final DateTime endUtc;
}
