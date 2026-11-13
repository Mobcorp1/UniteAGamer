import 'dart:math' as math;

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_bench_upgrade_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_bench_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_item.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_state.dart';

class ArcBenchIntelligenceEngine {
  const ArcBenchIntelligenceEngine();

  ArcBenchIntelligence build({
    required Map<String, ArcScrappyState> scrappyStates,
    Map<String, int> currentLevelsByStation = const <String, int>{},
  }) {
    final allGroups = _upgradeGroups();
    final groups = allGroups
        .where(
          (group) => group.level > (currentLevelsByStation[group.station] ?? 0),
        )
        .toList(growable: false);
    final trackingKnown = scrappyStates.keys.any(
      (id) => id.startsWith('bench-'),
    );
    if (allGroups.isEmpty) {
      return const ArcBenchIntelligence(
        trackingKnown: false,
        station: 'Bench',
        upgradeLabel: 'Bench Tracker',
        statusLabel: 'No bench data',
        summary: 'Bench upgrade requirements are not available yet.',
        recommendation:
            'Open the bench tracker once upgrade data is available.',
        actionLabel: 'Bench Tracker',
        status: ArcCommandStatus.neutral,
        completionPercent: 0,
        completedResources: 0,
        totalResources: 0,
        requiredCount: 0,
        collectedCount: 0,
        missingCount: 0,
        readyToUpgrade: false,
        hasBlocker: false,
        missingResources: [],
        currentLevelLabel: 'Bench level not tracked',
      );
    }
    if (groups.isEmpty) {
      return ArcBenchIntelligence(
        trackingKnown: trackingKnown,
        station: 'Bench',
        upgradeLabel: 'Bench Upgrades Complete',
        statusLabel: 'Complete',
        summary: '${allGroups.length} bench upgrades are complete this season.',
        recommendation:
            'Bench progression is clear. Keep collecting resources for future station levels.',
        actionLabel: 'Bench Tracker',
        status: ArcCommandStatus.success,
        completionPercent: 100,
        completedResources: allGroups.length,
        totalResources: allGroups.length,
        requiredCount: allGroups.length,
        collectedCount: allGroups.length,
        missingCount: 0,
        readyToUpgrade: false,
        hasBlocker: false,
        missingResources: const [],
        currentLevelLabel: 'All tracked benches upgraded',
      );
    }

    if (!trackingKnown) {
      final first = groups.first;
      return ArcBenchIntelligence(
        trackingKnown: false,
        station: first.station,
        upgradeLabel: first.label,
        statusLabel: 'Set up',
        summary:
            '${groups.length} bench upgrades are catalogued; resource ownership is not tracked yet.',
        recommendation:
            'Open Bench Operations and mark resources you already have.',
        actionLabel: 'Set Up Bench',
        status: ArcCommandStatus.neutral,
        completionPercent: 0,
        completedResources: 0,
        totalResources: first.items.length,
        requiredCount: first.requiredCount,
        collectedCount: 0,
        missingCount: 0,
        readyToUpgrade: false,
        hasBlocker: false,
        missingResources: const [],
        currentLevelLabel: 'Bench level not tracked',
      );
    }

    final progresses = groups
        .map((group) => _progressFor(group, scrappyStates))
        .toList(growable: false);
    final ready = progresses.where((progress) => progress.ready).toList();
    final target = ready.isNotEmpty
        ? ready.first
        : _bestIncompleteProgress(progresses);

    if (ready.isNotEmpty) {
      return ArcBenchIntelligence(
        trackingKnown: true,
        station: target.group.station,
        upgradeLabel: target.group.label,
        statusLabel: 'Ready',
        summary: '${target.group.label} has every resource tracked.',
        recommendation:
            'Upgrade ${target.group.station} before spending or trading those resources.',
        actionLabel: 'Upgrade Bench',
        status: ArcCommandStatus.ready,
        completionPercent: 100,
        completedResources: target.completedResources,
        totalResources: target.totalResources,
        requiredCount: target.requiredCount,
        collectedCount: target.collectedCount,
        missingCount: 0,
        readyToUpgrade: true,
        hasBlocker: false,
        missingResources: const [],
        currentLevelLabel: _currentLevelLabel(
          progresses,
          target.group.station,
          currentLevelsByStation,
        ),
      );
    }

    return ArcBenchIntelligence(
      trackingKnown: true,
      station: target.group.station,
      upgradeLabel: target.group.label,
      statusLabel: target.completionPercent > 0 ? 'Missing resources' : 'Track',
      summary: target.completionPercent > 0
          ? '${target.group.label} is ${target.completionPercent}% ready.'
          : '${target.group.label} is the next bench upgrade to track.',
      recommendation: target.missingResources.isEmpty
          ? 'Open Bench Operations and start marking resource progress.'
          : 'Prioritise ${target.missingResources.first.missingLabel} for ${target.group.label}.',
      actionLabel: 'Bench Tracker',
      status: target.completionPercent > 0
          ? ArcCommandStatus.warning
          : ArcCommandStatus.neutral,
      completionPercent: target.completionPercent,
      completedResources: target.completedResources,
      totalResources: target.totalResources,
      requiredCount: target.requiredCount,
      collectedCount: target.collectedCount,
      missingCount: target.missingCount,
      readyToUpgrade: false,
      hasBlocker: target.missingCount > 0,
      missingResources: target.missingResources,
      currentLevelLabel: _currentLevelLabel(
        progresses,
        target.group.station,
        currentLevelsByStation,
      ),
    );
  }

  List<_BenchGroup> _upgradeGroups() {
    final grouped = <String, _BenchGroup>{};
    for (final item
        in ArcBenchUpgradeSeedData.items.whereType<ArcScrappyItem>()) {
      final key = '${item.category}|${item.group}';
      final existing = grouped[key];
      final level = _levelFromGroup(item.group);
      if (existing == null) {
        grouped[key] = _BenchGroup(
          station: item.category,
          level: level,
          firstOrder: item.sortOrder,
          items: [item],
        );
      } else {
        existing.items.add(item);
        existing.firstOrder = math.min(existing.firstOrder, item.sortOrder);
      }
    }
    final groups = grouped.values.toList(growable: false)
      ..sort((a, b) {
        final stationCompare = _stationIndex(
          a.station,
        ).compareTo(_stationIndex(b.station));
        if (stationCompare != 0) return stationCompare;
        final levelCompare = a.level.compareTo(b.level);
        if (levelCompare != 0) return levelCompare;
        return a.firstOrder.compareTo(b.firstOrder);
      });
    return groups;
  }

  _BenchProgress _progressFor(
    _BenchGroup group,
    Map<String, ArcScrappyState> states,
  ) {
    final missing = <ArcBenchResourceProgress>[];
    var completedResources = 0;
    var requiredCount = 0;
    var collectedCount = 0;
    for (final item in group.items) {
      final state = states[item.id] ?? ArcScrappyState.empty(item.id);
      final collected = state.collectedCount.clamp(0, item.neededCount);
      final remaining = state.remainingNeededFor(item.neededCount);
      requiredCount += item.neededCount;
      collectedCount += collected;
      if (remaining == 0) {
        completedResources++;
      } else {
        missing.add(
          ArcBenchResourceProgress(
            itemName: item.name,
            requiredCount: item.neededCount,
            collectedCount: collected,
            missingCount: remaining,
            locationHint: item.locationHint,
          ),
        );
      }
    }
    final percent = requiredCount == 0
        ? 0
        : ((collectedCount / requiredCount) * 100).round().clamp(0, 100);
    return _BenchProgress(
      group: group,
      completedResources: completedResources,
      totalResources: group.items.length,
      requiredCount: requiredCount,
      collectedCount: collectedCount,
      missingCount: missing.fold<int>(
        0,
        (total, item) => total + item.missingCount,
      ),
      completionPercent: percent,
      missingResources: missing,
    );
  }

  _BenchProgress _bestIncompleteProgress(List<_BenchProgress> progresses) {
    final incomplete = progresses.where((progress) => !progress.ready).toList();
    if (incomplete.isEmpty) return progresses.first;
    incomplete.sort((a, b) {
      final percentCompare = b.completionPercent.compareTo(a.completionPercent);
      if (percentCompare != 0) return percentCompare;
      final stationCompare = _stationIndex(
        a.group.station,
      ).compareTo(_stationIndex(b.group.station));
      if (stationCompare != 0) return stationCompare;
      return a.group.level.compareTo(b.group.level);
    });
    return incomplete.first;
  }

  String _currentLevelLabel(
    List<_BenchProgress> progresses,
    String station,
    Map<String, int> currentLevelsByStation,
  ) {
    final durableLevel = currentLevelsByStation[station] ?? 0;
    if (durableLevel > 0) return '$station Lv.$durableLevel complete';
    final completedLevels = progresses
        .where(
          (progress) => progress.group.station == station && progress.ready,
        )
        .map((progress) => progress.group.level)
        .toList(growable: false);
    if (completedLevels.isEmpty) return '$station level not tracked';
    final maxLevel = completedLevels.reduce(math.max);
    return '$station Lv.$maxLevel ready';
  }

  int _stationIndex(String station) {
    final index = ArcBenchUpgradeSeedData.stationOrder.indexOf(station);
    return index < 0 ? 999 : index;
  }

  int _levelFromGroup(String group) {
    final match = RegExp(r'Tier (\d+)').firstMatch(group);
    if (match == null) return 0;
    return int.tryParse(match.group(1) ?? '') ?? 0;
  }
}

class _BenchGroup {
  _BenchGroup({
    required this.station,
    required this.level,
    required this.firstOrder,
    required this.items,
  });

  final String station;
  final int level;
  int firstOrder;
  final List<ArcScrappyItem> items;

  String get label => '$station Lv.$level';

  int get requiredCount =>
      items.fold<int>(0, (total, item) => total + item.neededCount);
}

class _BenchProgress {
  const _BenchProgress({
    required this.group,
    required this.completedResources,
    required this.totalResources,
    required this.requiredCount,
    required this.collectedCount,
    required this.missingCount,
    required this.completionPercent,
    required this.missingResources,
  });

  final _BenchGroup group;
  final int completedResources;
  final int totalResources;
  final int requiredCount;
  final int collectedCount;
  final int missingCount;
  final int completionPercent;
  final List<ArcBenchResourceProgress> missingResources;

  bool get ready => totalResources > 0 && completedResources == totalResources;
}
