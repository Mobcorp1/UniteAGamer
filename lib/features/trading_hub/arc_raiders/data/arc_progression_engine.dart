import 'dart:math' as math;

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_bench_upgrade_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_quest_requirement_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_scrappy_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_progression_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_item.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_season_reset_models.dart';

class ArcProgressionEngine {
  const ArcProgressionEngine();

  ArcProgressionSnapshotBundle build({
    required Map<String, ArcScrappyState> scrappyStates,
    ArcProgressionRecords records = ArcProgressionRecords.empty,
  }) {
    return ArcProgressionSnapshotBundle(
      quest: buildQuestSnapshot(
        scrappyStates: scrappyStates,
        records: records.questRecords,
        seasonId: records.seasonId,
      ),
      scrappy: buildScrappySnapshot(
        scrappyStates: scrappyStates,
        state: records.scrappyState,
        seasonId: records.seasonId,
      ),
      bench: buildBenchSnapshot(
        scrappyStates: scrappyStates,
        records: records.benchRecords,
        seasonId: records.seasonId,
      ),
    );
  }

  List<ArcQuestProgressionDefinition> get questDefinitions {
    final grouped = <String, List<ArcScrappyItem>>{};
    for (final item
        in ArcQuestRequirementSeedData.items.whereType<ArcScrappyItem>()) {
      grouped.putIfAbsent('${item.category}|||${item.group}', () => []);
      grouped['${item.category}|||${item.group}']!.add(item);
    }

    final definitions = <ArcQuestProgressionDefinition>[];
    for (final entry in grouped.entries) {
      final items = entry.value
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      final first = items.first;
      definitions.add(
        ArcQuestProgressionDefinition(
          questId: questIdFor(first.category, first.group),
          trader: first.category,
          questName: first.group,
          order: first.sortOrder,
          prerequisiteQuestIds: const <String>[],
          objectives: [
            for (final item in items)
              ArcProgressionObjective(
                id: item.id,
                label: item.name,
                requiredCount: item.neededCount,
                currentCount: 0,
                sourceHint: item.locationHint,
              ),
          ],
        ),
      );
    }

    definitions.sort((a, b) => a.order.compareTo(b.order));
    final chained = <ArcQuestProgressionDefinition>[];
    for (var i = 0; i < definitions.length; i++) {
      final previous = i == 0 ? null : definitions[i - 1];
      final definition = definitions[i];
      chained.add(
        ArcQuestProgressionDefinition(
          questId: definition.questId,
          trader: definition.trader,
          questName: definition.questName,
          order: definition.order,
          prerequisiteQuestIds: previous == null
              ? const <String>[]
              : <String>[previous.questId],
          objectives: definition.objectives,
        ),
      );
    }
    return chained;
  }

  List<ArcScrappyProgressionDefinition> get scrappyDefinitions {
    final grouped = <int, List<ArcScrappyItem>>{};
    for (final item in ArcScrappySeedData.items.whereType<ArcScrappyItem>()) {
      grouped.putIfAbsent(_scrappyLevelForTier(item.tier), () => []);
      grouped[_scrappyLevelForTier(item.tier)]!.add(item);
    }

    final definitions = <ArcScrappyProgressionDefinition>[];
    final levels = grouped.keys.toList()..sort();
    for (final level in levels) {
      final items = grouped[level]!
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      definitions.add(
        ArcScrappyProgressionDefinition(
          level: level,
          title: 'Scrappy Lv.$level',
          objectives: [
            for (final item in items)
              ArcProgressionObjective(
                id: item.id,
                label: item.name,
                requiredCount: item.neededCount,
                currentCount: 0,
                sourceHint: item.locationHint,
              ),
          ],
        ),
      );
    }
    return definitions;
  }

  List<ArcBenchProgressionDefinition> get benchDefinitions {
    final grouped = <String, List<ArcScrappyItem>>{};
    for (final item
        in ArcBenchUpgradeSeedData.items.whereType<ArcScrappyItem>()) {
      grouped.putIfAbsent('${item.category}|||${item.group}', () => []);
      grouped['${item.category}|||${item.group}']!.add(item);
    }

    final definitions = <ArcBenchProgressionDefinition>[];
    for (final entry in grouped.entries) {
      final items = entry.value
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      final first = items.first;
      final level = _levelFromBenchGroup(first.group);
      final station = first.category;
      definitions.add(
        ArcBenchProgressionDefinition(
          benchId: benchIdFor(station),
          station: station,
          level: level,
          objectives: [
            for (final item in items)
              ArcProgressionObjective(
                id: item.id,
                label: item.name,
                requiredCount: item.neededCount,
                currentCount: 0,
                sourceHint: item.locationHint,
              ),
          ],
        ),
      );
    }

    definitions.sort((a, b) {
      final stationCompare = _stationSort(
        a.station,
      ).compareTo(_stationSort(b.station));
      if (stationCompare != 0) return stationCompare;
      return a.level.compareTo(b.level);
    });
    return definitions;
  }

  ArcQuestProgressionSnapshot buildQuestSnapshot({
    required Map<String, ArcScrappyState> scrappyStates,
    Map<String, ArcQuestProgressionRecord> records =
        const <String, ArcQuestProgressionRecord>{},
    String seasonId = ArcSeasonResetPolicy.defaultCurrentSeasonId,
  }) {
    final definitions = questDefinitions;
    final completedQuestIds = records.values
        .where((record) => record.status == ArcProgressionStatus.completed)
        .map((record) => record.questId)
        .toSet();
    final archivedQuestIds = records.values
        .where((record) => record.status == ArcProgressionStatus.archived)
        .map((record) => record.questId)
        .toSet();
    final entries = <ArcQuestProgressionEntry>[];
    final trackingKnown = scrappyStates.keys.any(
      (id) => id.startsWith('quest-'),
    );

    for (final definition in definitions) {
      final record = records[definition.questId];
      final prereqsComplete = definition.prerequisiteQuestIds.every(
        completedQuestIds.contains,
      );
      final objectives = _objectivesWithProgress(
        definition.objectives,
        scrappyStates,
        record?.objectiveProgress,
      );
      final allObjectivesReady =
          objectives.isNotEmpty &&
          objectives.every((objective) => objective.complete);
      final status = record?.status == ArcProgressionStatus.completed
          ? ArcProgressionStatus.completed
          : record?.status == ArcProgressionStatus.archived
          ? ArcProgressionStatus.archived
          : !prereqsComplete
          ? ArcProgressionStatus.locked
          : allObjectivesReady
          ? ArcProgressionStatus.ready
          : ArcProgressionStatus.active;
      entries.add(
        ArcQuestProgressionEntry(
          definition: definition,
          status: status,
          objectives: objectives,
          record: record,
        ),
      );
    }

    return ArcQuestProgressionSnapshot(
      seasonId: seasonId,
      entries: entries,
      completedQuestIds: completedQuestIds,
      archivedQuestIds: archivedQuestIds,
      trackingKnown: trackingKnown,
    );
  }

  ArcScrappyProgressionSnapshot buildScrappySnapshot({
    required Map<String, ArcScrappyState> scrappyStates,
    ArcScrappyProgressionState state = ArcScrappyProgressionState.empty,
    String seasonId = ArcSeasonResetPolicy.defaultCurrentSeasonId,
  }) {
    final definitions = scrappyDefinitions;
    final normalizedState = state.seasonId == seasonId
        ? state
        : state.copyWith(seasonId: seasonId);
    ArcScrappyProgressionDefinition? next;
    for (final definition in definitions) {
      if (definition.level > normalizedState.currentLevel) {
        next = definition;
        break;
      }
    }
    final trackingKnown = scrappyStates.keys.any(
      (id) => ArcScrappySeedData.items.whereType<ArcScrappyItem>().any(
        (item) => item.id == id,
      ),
    );
    final objectives = next == null
        ? const <ArcProgressionObjective>[]
        : _objectivesWithProgress(next.objectives, scrappyStates);
    final required = objectives.fold<int>(
      0,
      (total, objective) => total + objective.requiredCount,
    );
    final collected = objectives.fold<int>(
      0,
      (total, objective) => total + objective.safeCurrentCount,
    );
    final ready =
        trackingKnown &&
        objectives.isNotEmpty &&
        objectives.every((o) => o.complete);
    return ArcScrappyProgressionSnapshot(
      state: normalizedState,
      definitions: definitions,
      nextUpgrade: next,
      trackingKnown: trackingKnown,
      status: next == null
          ? ArcCommandStatus.success
          : ready
          ? ArcCommandStatus.ready
          : trackingKnown
          ? ArcCommandStatus.active
          : ArcCommandStatus.neutral,
      completionPercent: required == 0
          ? 100
          : ((collected / required) * 100).round().clamp(0, 100),
      collectedCount: collected,
      requiredCount: required,
    );
  }

  ArcBenchProgressionSnapshot buildBenchSnapshot({
    required Map<String, ArcScrappyState> scrappyStates,
    Map<String, ArcBenchProgressionRecord> records =
        const <String, ArcBenchProgressionRecord>{},
    String seasonId = ArcSeasonResetPolicy.defaultCurrentSeasonId,
  }) {
    final definitions = benchDefinitions;
    final candidates = <_BenchCandidate>[];
    final trackingKnown = scrappyStates.keys.any(
      (id) => id.startsWith('bench-'),
    );

    for (final definition in definitions) {
      final record =
          records[definition.benchId] ??
          ArcBenchProgressionRecord(
            benchId: definition.benchId,
            station: definition.station,
            seasonId: seasonId,
          );
      if (definition.level != record.currentLevel + 1) continue;
      final objectives = _objectivesWithProgress(
        definition.objectives,
        scrappyStates,
      );
      final required = objectives.fold<int>(
        0,
        (total, objective) => total + objective.requiredCount,
      );
      final collected = objectives.fold<int>(
        0,
        (total, objective) => total + objective.safeCurrentCount,
      );
      final completion = required == 0
          ? 100
          : ((collected / required) * 100).round().clamp(0, 100);
      final ready =
          trackingKnown &&
          objectives.isNotEmpty &&
          objectives.every((objective) => objective.complete);
      candidates.add(
        _BenchCandidate(
          definition: definition,
          collectedCount: collected,
          requiredCount: required,
          completionPercent: completion,
          ready: ready,
        ),
      );
    }

    candidates.sort((a, b) {
      if (a.ready != b.ready) return a.ready ? -1 : 1;
      final progressCompare = b.completionPercent.compareTo(
        a.completionPercent,
      );
      if (progressCompare != 0) return progressCompare;
      final stationCompare = _stationSort(
        a.definition.station,
      ).compareTo(_stationSort(b.definition.station));
      if (stationCompare != 0) return stationCompare;
      return a.definition.level.compareTo(b.definition.level);
    });

    final best = candidates.isEmpty ? null : candidates.first;
    final normalizedRecords = records.map(
      (key, record) => MapEntry(
        key,
        record.seasonId == seasonId
            ? record
            : record.copyWith(seasonId: seasonId),
      ),
    );
    return ArcBenchProgressionSnapshot(
      recordsByBenchId: normalizedRecords,
      definitions: definitions,
      nextUpgrade: best?.definition,
      trackingKnown: trackingKnown,
      status: best == null
          ? ArcCommandStatus.success
          : best.ready
          ? ArcCommandStatus.ready
          : trackingKnown
          ? ArcCommandStatus.active
          : ArcCommandStatus.neutral,
      completionPercent: best?.completionPercent ?? 100,
      collectedCount: best?.collectedCount ?? 0,
      requiredCount: best?.requiredCount ?? 0,
    );
  }

  ArcQuestProgressionRecord completeQuestRecord({
    required ArcQuestProgressionSnapshot snapshot,
    required String questId,
    DateTime? completedAt,
  }) {
    final entry = snapshot.entries.firstWhere(
      (entry) => entry.questId == questId,
      orElse: () => throw StateError('Unknown quest progression id: $questId'),
    );
    final now = completedAt ?? DateTime.now().toUtc();
    return ArcQuestProgressionRecord(
      questId: questId,
      seasonId: snapshot.seasonId,
      status: ArcProgressionStatus.completed,
      objectiveProgress: {
        for (final objective in entry.objectives)
          objective.id: math.max(
            objective.currentCount,
            objective.requiredCount,
          ),
      },
      completedAt: entry.record?.completedAt ?? now,
      rewardsGrantedAt: entry.record?.rewardsGrantedAt ?? now,
      updatedAt: now,
    );
  }

  ArcScrappyProgressionState confirmScrappyLevel({
    required ArcScrappyProgressionSnapshot snapshot,
    required int level,
    DateTime? completedAt,
  }) {
    final now = completedAt ?? DateTime.now().toUtc();
    if (level <= snapshot.state.currentLevel) {
      return snapshot.state.copyWith(updatedAt: now);
    }
    if (level != snapshot.state.currentLevel + 1) {
      throw StateError('Scrappy Lv.$level is not the next upgrade.');
    }
    if (!snapshot.readyToUpgrade || snapshot.nextLevel != level) {
      throw StateError('Scrappy Lv.$level is not ready to upgrade.');
    }
    final completed = {
      ...snapshot.state.completedLevelIds,
      'scrappy-lv-$level',
    };
    return snapshot.state.copyWith(
      currentLevel: level,
      maximumLevelReachedThisSeason: math.max(
        snapshot.state.maximumLevelReachedThisSeason,
        level,
      ),
      historicalMaximumLevel: math.max(
        snapshot.state.historicalMaximumLevel,
        level,
      ),
      completedLevelIds: completed,
      updatedAt: now,
    );
  }

  ArcBenchProgressionRecord confirmBenchLevel({
    required ArcBenchProgressionSnapshot snapshot,
    required Map<String, ArcScrappyState> scrappyStates,
    required String station,
    required int level,
    DateTime? completedAt,
  }) {
    final now = completedAt ?? DateTime.now().toUtc();
    final benchId = benchIdFor(station);
    final record =
        snapshot.recordsByBenchId[benchId] ??
        ArcBenchProgressionRecord(
          benchId: benchId,
          station: station,
          seasonId: ArcSeasonResetPolicy.defaultCurrentSeasonId,
        );
    if (level <= record.currentLevel) return record.copyWith(updatedAt: now);
    if (level != record.currentLevel + 1) {
      throw StateError('$station Lv.$level is not the next upgrade.');
    }
    final definition = snapshot.definitions.firstWhere(
      (definition) =>
          definition.benchId == benchId && definition.level == level,
      orElse: () =>
          throw StateError('Unknown bench progression: $station Lv.$level'),
    );
    final objectives = _objectivesWithProgress(
      definition.objectives,
      scrappyStates,
    );
    if (objectives.isEmpty ||
        objectives.any((objective) => !objective.complete)) {
      throw StateError('${definition.upgradeLabel} is not ready to upgrade.');
    }
    final completed = {...record.completedLevelIds, '$benchId-lv-$level'};
    return record.copyWith(
      currentLevel: level,
      maximumLevelReachedThisSeason: math.max(
        record.maximumLevelReachedThisSeason,
        level,
      ),
      historicalMaximumLevel: math.max(record.historicalMaximumLevel, level),
      completedLevelIds: completed,
      updatedAt: now,
    );
  }

  String questIdForItems(List<ArcScrappyItem> items) {
    if (items.isEmpty) return '';
    final first = items.first;
    return questIdFor(first.category, first.group);
  }

  int scrappyLevelForItems(List<ArcScrappyItem> items) {
    if (items.isEmpty) return 0;
    return _scrappyLevelForTier(items.first.tier);
  }

  String benchIdForItems(List<ArcScrappyItem> items) {
    if (items.isEmpty) return '';
    return benchIdFor(items.first.category);
  }

  int benchLevelForItems(List<ArcScrappyItem> items) {
    if (items.isEmpty) return 0;
    return _levelFromBenchGroup(items.first.group);
  }

  static String questIdFor(String trader, String questName) =>
      'quest-chain-${_slug(trader)}-${_slug(questName)}';

  static String benchIdFor(String station) => 'bench-${_slug(station)}';

  List<ArcProgressionObjective> _objectivesWithProgress(
    List<ArcProgressionObjective> objectives,
    Map<String, ArcScrappyState> scrappyStates, [
    Map<String, int>? persistedProgress,
  ]) {
    return [
      for (final objective in objectives)
        ArcProgressionObjective(
          id: objective.id,
          label: objective.label,
          requiredCount: objective.requiredCount,
          currentCount: math.max(
            scrappyStates[objective.id]?.collectedCount ?? 0,
            persistedProgress?[objective.id] ?? 0,
          ),
          source: objective.source,
          sourceHint: objective.sourceHint,
        ),
    ];
  }

  int _scrappyLevelForTier(ArcScrappyTier tier) {
    return switch (tier) {
      ArcScrappyTier.tier1 => 2,
      ArcScrappyTier.tier2 => 3,
      ArcScrappyTier.tier3 => 4,
      ArcScrappyTier.tier4 => 5,
    };
  }

  int _levelFromBenchGroup(String group) {
    final match = RegExp(
      r'Lv\.(\d+)|Tier\s+(\d+)',
      caseSensitive: false,
    ).firstMatch(group);
    if (match == null) return 1;
    return int.tryParse(match.group(1) ?? match.group(2) ?? '') ?? 1;
  }

  int _stationSort(String station) {
    final index = ArcBenchUpgradeSeedData.stationOrder.indexOf(station);
    return index < 0 ? 999 : index;
  }

  static String _slug(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}

class _BenchCandidate {
  const _BenchCandidate({
    required this.definition,
    required this.collectedCount,
    required this.requiredCount,
    required this.completionPercent,
    required this.ready,
  });

  final ArcBenchProgressionDefinition definition;
  final int collectedCount;
  final int requiredCount;
  final int completionPercent;
  final bool ready;
}
