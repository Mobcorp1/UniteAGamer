import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_bottom_action_dock.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';

import 'package:uag_arc_raiders_hub/build/app_bar.dart';
import 'package:uag_arc_raiders_hub/build/app_drawer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_intel_seed.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_availability.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_drop_intel.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/raid_planner_blueprint_rules.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/raid_planner_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_regional_map_conditions.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_regional_opportunity_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/models/raid_planner_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/repositories/raid_planner_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_hunt_targets_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_command_centre_screen.dart';
import 'package:uag_arc_raiders_hub/widgets/collapsible_section_card.dart';
import 'package:uag_arc_raiders_hub/widgets/electric_charge_border.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';
import 'package:uag_arc_raiders_hub/widgets/uag_page_carousel.dart';

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
  ArcServerRegion _selectedServerRegion = ArcServerRegion.europe;
  String? _selectedItemTargetId;
  late Future<ArcRegionalMapConditionsSnapshot> _regionalConditionsFuture;

  late DateTime _plannerNowUtc;
  Timer? _plannerClockTimer;

  @override
  void initState() {
    super.initState();
    _plannerNowUtc = DateTime.now().toUtc();
    _regionalConditionsFuture = ArcRegionalMapConditionsService.load();
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
        return 'Your top priority targets. Exact event windows are shown when these match Surge Coil, Canto or Dolabra. Your ${entitlement.tier.label} plan allows ${_tierLimit(tier, entitlement)} Active Operations slot${_tierLimit(tier, entitlement) == 1 ? '' : 's'}.';
      case RaidTargetTier.nextUp:
        return 'Backup targets. When Active Operations targets are owned or removed, these move up into the planner automatically.';
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

  List<RaidBlueprintTarget> _targetsWithBlueprintPriorities({
    required List<RaidBlueprintTarget> storedTargets,
    required Map<String, ArcBlueprintState> states,
  }) {
    final prioritizedStates =
        states.values
            .where((state) => state.priorityRank > 0 && !state.owned)
            .toList(growable: false)
          ..sort((a, b) {
            final rankCompare = a.priorityRank.compareTo(b.priorityRank);
            if (rankCompare != 0) return rankCompare;
            return a.blueprintId.compareTo(b.blueprintId);
          });

    final activeTargets = <RaidBlueprintTarget>[];
    final activeIds = <String>{};

    for (final state in prioritizedStates.take(5)) {
      activeIds.add(state.blueprintId);
      activeTargets.add(
        RaidBlueprintTarget(
          blueprintId: state.blueprintId,
          tier: RaidTargetTier.activeHunt,
          rank: activeTargets.length,
          updatedAt: state.updatedAt,
        ),
      );
    }

    final legacyActiveTargets =
        _targetsForTier(storedTargets, RaidTargetTier.activeHunt).where((
          target,
        ) {
          if (activeIds.contains(target.blueprintId)) return false;
          final state = states[target.blueprintId];
          return !(state?.owned ?? false);
        });

    for (final target in legacyActiveTargets) {
      if (activeTargets.length >= 5) break;
      activeIds.add(target.blueprintId);
      activeTargets.add(
        target.copyWith(
          tier: RaidTargetTier.activeHunt,
          rank: activeTargets.length,
        ),
      );
    }

    final nonActiveTargets = storedTargets
        .where((target) {
          if (target.tier == RaidTargetTier.activeHunt) return false;
          if (activeIds.contains(target.blueprintId)) return false;
          return true;
        })
        .toList(growable: false);

    return <RaidBlueprintTarget>[...activeTargets, ...nonActiveTargets];
  }

  Future<void> _syncBlueprintPriority({
    required String blueprintId,
    required RaidTargetTier tier,
    required int rank,
    required Map<String, ArcBlueprintState> states,
  }) async {
    final current = states[blueprintId] ?? ArcBlueprintState.empty(blueprintId);
    final nextPriorityRank = tier == RaidTargetTier.activeHunt ? rank + 1 : 0;

    if (current.priorityRank == nextPriorityRank) return;

    await _blueprintRepository.saveBlueprintState(
      current.copyWith(
        priorityRank: nextPriorityRank,
        updatedAt: DateTime.now(),
      ),
    );
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
    await _syncBlueprintPriority(
      blueprintId: blueprint.id,
      tier: tier,
      rank: next.rank,
      states: states,
    );
    _showMessage('${blueprint.name} added to ${tier.label}.');
  }

  Future<void> _removeTarget(
    String blueprintId, {
    Map<String, ArcBlueprintState>? states,
  }) async {
    final blueprint = RaidPlannerEngine.findBlueprintById(blueprintId);
    await _plannerRepository.removeTarget(blueprintId);

    final current = states?[blueprintId];
    if (current != null && current.priorityRank > 0) {
      await _blueprintRepository.saveBlueprintState(
        current.copyWith(priorityRank: 0, updatedAt: DateTime.now()),
      );
    }

    _showMessage('${blueprint?.name ?? 'Target'} removed.');
  }

  Future<void> _clearTargets(Map<String, ArcBlueprintState> states) async {
    await _plannerRepository.clearTargets();

    final priorityUpdates = states.values
        .where((state) => state.priorityRank > 0)
        .map(
          (state) => state.copyWith(priorityRank: 0, updatedAt: DateTime.now()),
        )
        .toList(growable: false);

    if (priorityUpdates.isNotEmpty) {
      await _blueprintRepository.saveBlueprintStates(priorityUpdates);
    }

    _showMessage('Raid Timeline targets cleared.');
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
          decoration: ArcUiTokens.chipDecoration(
            color: onTap == null ? Colors.white54 : color,
            selected: onTap != null,
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

  Widget _targetTile(
    RaidBlueprintTarget target,
    Map<String, ArcBlueprintState> states,
  ) {
    final blueprint = RaidPlannerEngine.findBlueprintById(target.blueprintId);
    final rule = RaidPlannerBlueprintRules.byBlueprintId(target.blueprintId);
    final seededHint = blueprint == null
        ? null
        : ArcBlueprintIntelLibrary.resolve(blueprint);
    final seededConditions = seededHint == null
        ? <String>[]
        : ArcBlueprintIntelLibrary.playableConditions(
            seededHint.bestConditions,
          );
    final seededTimingLabel =
        rule?.eventName ??
        (seededConditions.isEmpty
            ? 'Seeded route enabled'
            : '${seededConditions.first} seeded route enabled');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.interactive,
        accent: _tierColor(target.tier),
        radius: 16,
        borderOpacity: 0.35,
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
            onPressed: () => _removeTarget(target.blueprintId, states: states),
            icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _targetTierCarouselPage({
    required RaidTargetTier tier,
    required List<RaidBlueprintTarget> displayTargets,
    required List<RaidBlueprintTarget> storedTargets,
    required RaidPlannerEntitlement entitlement,
    required Map<String, ArcBlueprintState> states,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SingleChildScrollView(
        primary: false,
        child: _targetTierCard(
          tier: tier,
          displayTargets: displayTargets,
          storedTargets: storedTargets,
          entitlement: entitlement,
          states: states,
          initiallyExpanded: true,
        ),
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
            ...displayTargets.map((target) => _targetTile(target, states)),
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
      padding: const EdgeInsets.all(16),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.interactive,
        accent: live ? AppTheme.neonPink : AppTheme.neonCyan,
        radius: 16,
        borderOpacity: 0.35,
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
                  '${opportunity.rule.blueprintName} - ${opportunity.slot.eventName}${opportunity.rule.isExactEventRule ? '' : ' boost'}',
                  style: AppTheme.tradingHeading(fontSize: 17),
                ),
                const SizedBox(height: 4),
                Text(
                  '${opportunity.slot.mapName} - ${opportunity.slot.lane} - ${_clock(opportunity.startUtc)}-${_clock(opportunity.endUtc)}',
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

  Future<void> _refreshRegionalConditions() async {
    final next = ArcRegionalMapConditionsService.load(forceRefresh: true);
    setState(() {
      _regionalConditionsFuture = next;
    });
    await next;
  }

  String _regionalStatusText(
    ArcRegionalOpportunity opportunity,
    DateTime utcNow,
  ) {
    if (opportunity.live) {
      final remaining = opportunity.window.endUtc.difference(utcNow);
      return 'LIVE - ${_durationLabel(remaining)} remaining';
    }
    final until = opportunity.window.startUtc.difference(utcNow);
    return 'Starts in ${_durationLabel(until)}';
  }

  Widget _regionalOpportunityTile(
    ArcRegionalOpportunity opportunity,
    DateTime utcNow,
  ) {
    final switchText = opportunity.shouldSwitchRegion
        ? 'Switch ARC server to ${opportunity.region.label}'
        : 'Stay on ${opportunity.region.label}';
    final playtimeText = opportunity.insideSavedPlaytime
        ? 'Matches your saved playtime'
        : 'Outside your usual playtime';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.interactive,
        accent: opportunity.insideSavedPlaytime
            ? AppTheme.neonCyan
            : AppTheme.neonPink,
        radius: 14,
        borderOpacity: opportunity.insideSavedPlaytime ? 0.38 : 0.28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  opportunity.target.label,
                  style: AppTheme.tradingHeading(fontSize: 16),
                ),
              ),
              if (opportunity.target.verifiedConditionLink)
                const Icon(
                  Icons.verified_rounded,
                  color: AppTheme.neonCyan,
                  size: 17,
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${opportunity.condition.conditionName} - ${opportunity.condition.mapDisplayName}',
            style: AppTheme.bodyTextStyle(
              fontSize: 13,
              color: AppTheme.tradingMutedText,
              isBold: true,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_clock(opportunity.window.startUtc)}-${_clock(opportunity.window.endUtc)} - ${opportunity.region.label}',
            style: AppTheme.bodyTextStyle(
              fontSize: 13,
              color: AppTheme.neonCyan,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_regionalStatusText(opportunity, utcNow)} - $playtimeText',
            style: AppTheme.bodyTextStyle(
              fontSize: 12,
              color: opportunity.insideSavedPlaytime
                  ? AppTheme.neonCyan
                  : AppTheme.tradingMutedText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            switchText,
            style: AppTheme.bodyTextStyle(
              fontSize: 12,
              color: opportunity.shouldSwitchRegion
                  ? AppTheme.neonPink
                  : Colors.white70,
              isBold: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _regionalBlueprintPlannerCard({
    required Map<String, ArcBlueprintState> states,
    required ArcAvailability availability,
    required DateTime utcNow,
  }) {
    return CollapsibleSectionCard(
      title: 'Regional Blueprint Opportunities',
      titleColor: AppTheme.neonCyan,
      initiallyExpanded: true,
      child: FutureBuilder<ArcRegionalMapConditionsSnapshot>(
        future: _regionalConditionsFuture,
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data == null) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final recommendations =
              ArcRegionalOpportunityEngine.blueprintRecommendations(
                snapshot: data,
                states: states,
                availability: availability,
                homeRegion: _selectedServerRegion,
                nowUtc: utcNow,
                limit: 8,
              );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UAG reads your missing Blueprint Tracker entries, your saved playtime and the regional ARC schedule. If your home region misses the window, it recommends the earliest server you can switch to.',
                style: AppTheme.bodyTextStyle(
                  fontSize: 13,
                  color: AppTheme.tradingMutedText,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<ArcServerRegion>(
                      initialValue: _selectedServerRegion,
                      decoration: const InputDecoration(
                        labelText: 'Your ARC server region',
                      ),
                      items: [
                        for (final region in ArcServerRegion.values)
                          DropdownMenuItem(
                            value: region,
                            child: Text(region.label),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedServerRegion = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    tooltip: 'Refresh official regional schedule',
                    onPressed: _refreshRegionalConditions,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                data.sourceLabel,
                style: AppTheme.bodyTextStyle(
                  fontSize: 11,
                  color: data.isOfficialLive
                      ? AppTheme.neonCyan
                      : Colors.orangeAccent,
                  isBold: true,
                ),
              ),
              if (!data.isOfficialLive) ...[
                const SizedBox(height: 4),
                Text(
                  'Live refresh was unavailable. UAG is showing the last official captured regional schedule until the source can be reached again.',
                  style: AppTheme.bodyTextStyle(
                    fontSize: 11,
                    color: AppTheme.tradingMutedText,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              if (recommendations.isEmpty)
                Text(
                  'No condition-linked missing Blueprint opportunities are available in the loaded schedule window.',
                  style: AppTheme.bodyTextStyle(
                    fontSize: 13,
                    color: AppTheme.tradingMutedText,
                  ),
                )
              else
                ...recommendations.map(
                  (item) => _regionalOpportunityTile(item, utcNow),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _regionalItemPlannerCard({
    required ArcAvailability availability,
    required DateTime utcNow,
  }) {
    return CollapsibleSectionCard(
      title: 'Condition Item Finder',
      titleColor: AppTheme.neonPink,
      initiallyExpanded: false,
      child: FutureBuilder<ArcRegionalMapConditionsSnapshot>(
        future: _regionalConditionsFuture,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final selected = _selectedItemTargetId;
          final recommendations = data == null || selected == null
              ? const <ArcRegionalOpportunity>[]
              : ArcRegionalOpportunityEngine.itemRecommendations(
                  snapshot: data,
                  itemId: selected,
                  availability: availability,
                  homeRegion: _selectedServerRegion,
                  nowUtc: utcNow,
                  limit: 6,
                );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose an in-game objective and UAG will resolve the condition, map window and best regional server against your playtime.',
                style: AppTheme.bodyTextStyle(
                  fontSize: 13,
                  color: AppTheme.tradingMutedText,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selected,
                decoration: const InputDecoration(
                  labelText: 'Item / ARC objective',
                ),
                items: [
                  for (final rule in ArcRegionalOpportunityEngine.itemRules)
                    DropdownMenuItem(value: rule.id, child: Text(rule.label)),
                ],
                onChanged: (value) {
                  setState(() => _selectedItemTargetId = value);
                },
              ),
              const SizedBox(height: 14),
              if (selected != null && data == null)
                const Center(child: CircularProgressIndicator())
              else if (selected != null && recommendations.isEmpty)
                Text(
                  'No matching regional condition is available in the loaded official schedule window.',
                  style: AppTheme.bodyTextStyle(
                    fontSize: 13,
                    color: AppTheme.tradingMutedText,
                  ),
                )
              else
                ...recommendations.map(
                  (item) => _regionalOpportunityTile(item, utcNow),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _eventFinderCard(DateTime utcNow) {
    final normalized = _eventFinderQuery.trim();

    return CollapsibleSectionCard(
      title: 'Regional Condition Finder',
      titleColor: AppTheme.neonCyan,
      initiallyExpanded: false,
      child: FutureBuilder<ArcRegionalMapConditionsSnapshot>(
        future: _regionalConditionsFuture,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final matches = data == null || normalized.length < 2
              ? const <ArcRegionalMapConditionEntry>[]
              : ArcRegionalOpportunityEngine.findConditions(
                  snapshot: data,
                  query: normalized,
                );

          final rows =
              <
                ({
                  ArcRegionalMapConditionEntry entry,
                  ArcServerRegion region,
                  ArcRegionalConditionWindow window,
                })
              >[];
          for (final entry in matches) {
            for (final region in ArcServerRegion.values) {
              final window = entry.windowFor(region);
              if (window == null || !window.endUtc.isAfter(utcNow)) continue;
              rows.add((entry: entry, region: region, window: window));
            }
          }
          rows.sort((a, b) => a.window.startUtc.compareTo(b.window.startUtc));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Search a condition or map. UAG compares Europe, North America, Brazil, East Asia and Oceania and shows the earliest opportunities in your local time.',
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
                  labelText: 'Find condition or map',
                  hintText: 'Matriarch, Harvester, Night Raid, Blue Gate...',
                  prefixIcon: const Icon(Icons.travel_explore_rounded),
                  suffixIcon: _eventFinderQuery.trim().isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: _eventFinderController.clear,
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              if (normalized.length < 2)
                Text(
                  'Type at least 2 characters.',
                  style: AppTheme.bodyTextStyle(
                    fontSize: 13,
                    color: AppTheme.tradingMutedText,
                  ),
                )
              else if (data == null)
                const Center(child: CircularProgressIndicator())
              else if (rows.isEmpty)
                Text(
                  'No matching upcoming regional windows found.',
                  style: AppTheme.bodyTextStyle(
                    fontSize: 13,
                    color: AppTheme.tradingMutedText,
                  ),
                )
              else
                ...rows.take(8).map((row) {
                  final switchServer = row.region != _selectedServerRegion;
                  final live = row.window.isActiveAt(utcNow);
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: ArcUiTokens.surfaceDecoration(
                      role: ArcSurfaceRole.interactive,
                      accent: live ? AppTheme.neonPink : AppTheme.neonCyan,
                      radius: 12,
                      borderOpacity: live ? 0.45 : 0.24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${row.entry.conditionName} - ${row.entry.mapDisplayName}',
                          style: AppTheme.tradingHeading(fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${row.region.label} - ${_clock(row.window.startUtc)}-${_clock(row.window.endUtc)}',
                          style: AppTheme.bodyTextStyle(
                            fontSize: 12,
                            color: AppTheme.neonCyan,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          live
                              ? 'LIVE NOW'
                              : switchServer
                              ? 'Switch server to ${row.region.label}'
                              : 'Available on your selected region',
                          style: AppTheme.bodyTextStyle(
                            fontSize: 12,
                            color: live
                                ? AppTheme.neonPink
                                : switchServer
                                ? AppTheme.neonPink
                                : Colors.white70,
                            isBold: true,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
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
                ? 'No active play windows found in your availability. Set your availability in Your Hub Profile to unlock playtime planning.'
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
          const SizedBox(height: 14),
          if (inPlaytime.isEmpty)
            Text(
              'No selected Active Operations target events line up with your saved playtime in the next 7 days.',
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
          const SizedBox(height: 14),
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
    final seededHint = blueprint == null
        ? null
        : ArcBlueprintIntelLibrary.resolve(blueprint);
    return StreamBuilder<ArcDropIntel>(
      stream: _blueprintRepository.watchIntelForBlueprint(target.blueprintId),
      builder: (context, snapshot) {
        final intel = snapshot.data ?? ArcDropIntel.empty(target.blueprintId);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: ArcUiTokens.surfaceDecoration(
            role: ArcSurfaceRole.interactive,
            accent: AppTheme.neonCyan,
            radius: 16,
            borderOpacity: 0.25,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.radar_rounded,
                    color: AppTheme.neonCyan,
                    size: 18,
                  ),
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
              const SizedBox(height: 14),
              if (!intel.hasReports) ...[
                Text(
                  'No community intel yet. Using seeded blueprint rules until player reports create a stronger route.',
                  style: AppTheme.bodyTextStyle(
                    fontSize: 12,
                    color: AppTheme.tradingMutedText,
                  ),
                ),
                if (seededHint != null) ...[
                  const SizedBox(height: 14),
                  _intelLine('Seed map', seededHint.likelyMaps.join(', ')),
                  _intelLine(
                    'Seed containers',
                    seededHint.likelyContainers.join(', '),
                  ),
                  _intelLine(
                    'Seed condition/event',
                    seededHint.bestConditions.join(', '),
                  ),
                ],
              ] else ...[
                _intelLine('Top map', intel.topMapLabel),
                _intelLine('Top area/source', intel.topAreaLabel),
                _intelLine('Top container', intel.topContainerLabel),
                _intelLine(
                  'Top condition/event',
                  intel.topConditionLabel ?? intel.topMapEventLabel,
                ),
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
            'Every Active Operations target now starts with seeded blueprint rules. Community reports only override the baseline when real player intel exists.',
            style: AppTheme.bodyTextStyle(
              fontSize: 13,
              color: AppTheme.tradingMutedText,
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          if (activeTargets.isEmpty)
            Text(
              'Add Active Operations targets to show seeded route guidance and community intel.',
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

  Widget _scheduleTimelineCard({
    required List<RaidPlannerOpportunity> opportunities,
    required DateTime utcNow,
  }) {
    final visible = opportunities.take(5).toList();

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
          Row(
            children: [
              const Icon(
                Icons.timeline_rounded,
                color: ArcUiTokens.primaryAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Raid Planner',
                  style: ArcUiTokens.sectionTitle(
                    color: ArcUiTokens.primaryAccent,
                  ),
                ),
              ),
              Text(
                _dateLabel(DateTime.now()),
                style: ArcUiTokens.metadata(color: ArcUiTokens.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            Text(
              'No selected target windows are scheduled in the next 7 days.',
              style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
            )
          else
            ...visible.map(
              (opportunity) => _timelineOpportunityTile(
                opportunity: opportunity,
                utcNow: utcNow,
              ),
            ),
        ],
      ),
    );
  }

  Widget _timelineOpportunityTile({
    required RaidPlannerOpportunity opportunity,
    required DateTime utcNow,
  }) {
    final accent = opportunity.isLive
        ? ArcUiTokens.success
        : ArcUiTokens.primaryAccent;
    final status = opportunity.isLive
        ? 'LIVE'
        : _durationLabel(opportunity.timeUntil(utcNow));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 46,
            child: Text(
              _timeLabel(opportunity.startUtc),
              style: ArcUiTokens.label(color: ArcUiTokens.textSecondary),
            ),
          ),
          Column(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 1,
                height: 58,
                color: ArcUiTokens.borderMedium.withValues(alpha: 0.70),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: ArcUiTokens.densePanelPadding,
              decoration: ArcUiTokens.surfaceDecoration(
                role: ArcSurfaceRole.interactive,
                radius: ArcUiTokens.radiusS,
                accent: accent,
                borderOpacity: opportunity.isLive ? 0.30 : 0.16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          opportunity.rule.blueprintName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ArcUiTokens.cardTitle(fontSize: 13),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: ArcUiTokens.chipDecoration(
                          color: accent,
                          selected: opportunity.isLive,
                        ),
                        child: Text(
                          status,
                          style: ArcUiTokens.label(
                            color: accent,
                          ).copyWith(fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${opportunity.slot.mapName} - ${opportunity.slot.eventName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ArcUiTokens.metadata(
                      color: ArcUiTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_timeLabel(opportunity.startUtc)}-${_timeLabel(opportunity.endUtc)} local',
                    style: ArcUiTokens.metadata(
                      color: ArcUiTokens.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeLabel(DateTime utc) {
    final local = utc.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _dateLabel(DateTime local) {
    return '${local.day}/${local.month}';
  }

  Widget _buildContent({
    required List<RaidBlueprintTarget> targets,
    required RaidPlannerEntitlement entitlement,
    required Map<String, ArcBlueprintState> states,
    required ArcAvailability availability,
  }) {
    final syncedTargets = _targetsWithBlueprintPriorities(
      storedTargets: targets,
      states: states,
    );
    final effectiveTargets = RaidPlannerEngine.effectiveTargets(
      storedTargets: syncedTargets,
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

    return UagPageCarousel(
      pages: [
        UagCarouselPage(
          children: [
            _entitlementCard(entitlement),
            const SizedBox(height: 14),
            _scheduleTimelineCard(
              opportunities: allOpportunities,
              utcNow: utcNow,
            ),
            const SizedBox(height: 14),
            _regionalBlueprintPlannerCard(
              states: states,
              availability: availability,
              utcNow: utcNow,
            ),
            const SizedBox(height: 14),
            _regionalItemPlannerCard(
              availability: availability,
              utcNow: utcNow,
            ),
            const SizedBox(height: 14),
            _availabilityPlannerCard(
              allOpportunities: allOpportunities,
              availability: availability,
              utcNow: utcNow,
            ),
          ],
        ),
        UagCarouselPage(children: [_eventFinderCard(utcNow)]),
        UagCarouselPage(children: [_communityIntelCard(intelTargets)]),
        UagCarouselPage(
          children: [
            _targetTierCard(
              tier: RaidTargetTier.activeHunt,
              displayTargets: activeTargets,
              storedTargets: syncedTargets,
              entitlement: entitlement,
              states: states,
              initiallyExpanded: true,
            ),
          ],
        ),
        UagCarouselPage(
          children: [
            _targetTierCard(
              tier: RaidTargetTier.nextUp,
              displayTargets: nextTargets,
              storedTargets: syncedTargets,
              entitlement: entitlement,
              states: states,
              initiallyExpanded: true,
            ),
          ],
        ),
        UagCarouselPage(
          children: [
            _targetTierCard(
              tier: RaidTargetTier.later,
              displayTargets: laterTargets,
              storedTargets: syncedTargets,
              entitlement: entitlement,
              states: states,
              initiallyExpanded: true,
            ),
            const SizedBox(height: 14),
            if (syncedTargets.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: _smallButton(
                  label: 'Clear Planner Targets',
                  icon: Icons.clear_all_rounded,
                  color: Colors.redAccent,
                  onTap: () => _clearTargets(states),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _entitlementCard(RaidPlannerEntitlement entitlement) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.raised,
        accent: AppTheme.neonPink,
        radius: 18,
        borderOpacity: 0.18,
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
              '${entitlement.tier.label} plan - ${entitlement.activeHuntSlots.clamp(1, 5)} Active Operations slot${entitlement.activeHuntSlots == 1 ? '' : 's'}',
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
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ArcCompanionBottomDock(activeLabel: 'Raid Timeline'),
          ArcBottomActionDock(
            actions: [
              ArcDockAction(
                label: 'Back',
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
              ArcDockAction(
                label: 'Assist',
                icon: Icons.auto_awesome_rounded,
                onTap: () => Navigator.of(
                  context,
                ).pushNamed(ArcCommandCentreScreen.routeName),
              ),
              ArcDockAction(
                label: 'Status',
                icon: Icons.sensors_rounded,
                onTap: () => Navigator.of(
                  context,
                ).pushNamed(RaidPlannerHuntTargetsScreen.routeName),
              ),
            ],
          ),
        ],
      ),
      appBar: const UagAppBar(
        title: 'Raid Planner',
        subtitle: 'Schedule view from saved targets and availability.',
      ),
      drawer: const AppDrawer(),
      body: ArcRaidersScreenShell(
        useSafeArea: true,
        showAdBanner: false,
        child: StreamBuilder<RaidPlannerEntitlement>(
          stream: _plannerRepository.watchEntitlement(),
          builder: (context, entitlementSnapshot) {
            final entitlement =
                entitlementSnapshot.data ??
                const RaidPlannerEntitlement(tier: RaidPlannerTier.free);
            return StreamBuilder<List<RaidBlueprintTarget>>(
              stream: _plannerRepository.watchTargets(),
              builder: (context, targetsSnapshot) {
                final targets = targetsSnapshot.data ?? <RaidBlueprintTarget>[];
                return StreamBuilder<Map<String, ArcBlueprintState>>(
                  stream: _blueprintRepository.watchMyBlueprintStates(),
                  builder: (context, statesSnapshot) {
                    final states =
                        statesSnapshot.data ?? <String, ArcBlueprintState>{};
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
    return RaidPlannerEngine.supportedBlueprints
        .where((blueprint) {
          if (widget.targetedIds.contains(blueprint.id)) return false;
          if (widget.states[blueprint.id]?.owned ?? false) return false;
          return blueprint.name.toLowerCase().contains(_query);
        })
        .take(30)
        .toList(growable: false);
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
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: candidates.length,
                  separatorBuilder: (_, _) =>
                      const Divider(color: Colors.white12),
                  itemBuilder: (context, index) {
                    final blueprint = candidates[index];
                    final rule = RaidPlannerBlueprintRules.byBlueprintId(
                      blueprint.id,
                    );
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        rule == null
                            ? Icons.track_changes_rounded
                            : Icons.bolt_rounded,
                        color: rule == null
                            ? Colors.white70
                            : AppTheme.neonPink,
                      ),
                      title: Text(
                        blueprint.name,
                        style: AppTheme.tradingHeading(fontSize: 17),
                      ),
                      subtitle: Text(
                        rule == null
                            ? 'Seeded blueprint route available.'
                            : '${rule.eventName} - exact Raid Timeline windows available.',
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
