import 'dart:math' as math;

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_quest_requirement_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_quest_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_item.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_state.dart';

class ArcQuestIntelligenceEngine {
  const ArcQuestIntelligenceEngine();

  ArcQuestIntelligence build({
    required Map<String, ArcScrappyState> scrappyStates,
  }) {
    final groups = _questGroups();
    final trackingKnown = scrappyStates.keys.any(
      (id) => id.startsWith('quest-'),
    );
    if (groups.isEmpty) {
      return const ArcQuestIntelligence(
        trackingKnown: false,
        questLabel: 'Quest Tracker',
        trader: 'Unknown',
        questName: 'Quest Tracker',
        statusLabel: 'No quest data',
        summary: 'Quest requirements are not available yet.',
        recommendation: 'Open the quest tracker once quest data is available.',
        actionLabel: 'Quest Tracker',
        status: ArcCommandStatus.neutral,
        completionPercent: 0,
        completedItems: 0,
        totalItems: 0,
        requiredCount: 0,
        collectedCount: 0,
        missingCount: 0,
        readyToComplete: false,
        hasBlocker: false,
        missingItems: [],
      );
    }

    if (!trackingKnown) {
      final first = groups.first;
      return ArcQuestIntelligence(
        trackingKnown: false,
        questLabel: first.label,
        trader: first.trader,
        questName: first.questName,
        statusLabel: 'Set up',
        summary:
            '${groups.length} quest steps are catalogued; item ownership is not tracked yet.',
        recommendation:
            'Open Mission Operations and mark quest items you have already collected.',
        actionLabel: 'Set Up Quests',
        status: ArcCommandStatus.neutral,
        completionPercent: 0,
        completedItems: 0,
        totalItems: first.items.length,
        requiredCount: first.requiredCount,
        collectedCount: 0,
        missingCount: 0,
        readyToComplete: false,
        hasBlocker: false,
        missingItems: const [],
      );
    }

    final progresses = groups
        .map((group) => _progressFor(group, scrappyStates))
        .toList(growable: false);
    final ready = progresses.where((progress) => progress.ready).toList();
    final target = ready.isNotEmpty
        ? ready.first
        : progresses.firstWhere(
            (progress) => !progress.ready,
            orElse: () => progresses.first,
          );

    if (ready.isNotEmpty) {
      return ArcQuestIntelligence(
        trackingKnown: true,
        questLabel: target.group.label,
        trader: target.group.trader,
        questName: target.group.questName,
        statusLabel: 'Ready',
        summary: '${target.group.label} has every required item tracked.',
        recommendation:
            'Hand in or confirm this quest before farming the next quest chain.',
        actionLabel: 'Hand In Quest',
        status: ArcCommandStatus.ready,
        completionPercent: 100,
        completedItems: target.completedItems,
        totalItems: target.totalItems,
        requiredCount: target.requiredCount,
        collectedCount: target.collectedCount,
        missingCount: 0,
        readyToComplete: true,
        hasBlocker: false,
        missingItems: const [],
      );
    }

    return ArcQuestIntelligence(
      trackingKnown: true,
      questLabel: target.group.label,
      trader: target.group.trader,
      questName: target.group.questName,
      statusLabel: target.completionPercent > 0 ? 'Missing items' : 'Track',
      summary: target.completionPercent > 0
          ? '${target.group.label} is ${target.completionPercent}% ready.'
          : '${target.group.label} is the next quest item set to track.',
      recommendation: target.missingItems.isEmpty
          ? 'Open Mission Operations and start marking quest item progress.'
          : 'Prioritise ${target.missingItems.first.missingLabel} for ${target.group.questName}.',
      actionLabel: 'Quest Tracker',
      status: target.completionPercent > 0
          ? ArcCommandStatus.warning
          : ArcCommandStatus.neutral,
      completionPercent: target.completionPercent,
      completedItems: target.completedItems,
      totalItems: target.totalItems,
      requiredCount: target.requiredCount,
      collectedCount: target.collectedCount,
      missingCount: target.missingCount,
      readyToComplete: false,
      hasBlocker: target.missingCount > 0,
      missingItems: target.missingItems,
    );
  }

  List<_QuestGroup> _questGroups() {
    final grouped = <String, _QuestGroup>{};
    for (final item
        in ArcQuestRequirementSeedData.items.whereType<ArcScrappyItem>()) {
      final key = '${item.category}|${item.group}';
      final existing = grouped[key];
      if (existing == null) {
        grouped[key] = _QuestGroup(
          trader: item.category,
          questName: item.group,
          firstOrder: item.sortOrder,
          items: [item],
        );
      } else {
        existing.items.add(item);
        existing.firstOrder = math.min(existing.firstOrder, item.sortOrder);
      }
    }
    final groups = grouped.values.toList(growable: false)
      ..sort((a, b) => a.firstOrder.compareTo(b.firstOrder));
    return groups;
  }

  _QuestProgress _progressFor(
    _QuestGroup group,
    Map<String, ArcScrappyState> states,
  ) {
    final missing = <ArcQuestRequirementProgress>[];
    var completedItems = 0;
    var requiredCount = 0;
    var collectedCount = 0;
    for (final item in group.items) {
      final state = states[item.id] ?? ArcScrappyState.empty(item.id);
      final collected = state.collectedCount.clamp(0, item.neededCount);
      final remaining = state.remainingNeededFor(item.neededCount);
      requiredCount += item.neededCount;
      collectedCount += collected;
      if (remaining == 0) {
        completedItems++;
      } else {
        missing.add(
          ArcQuestRequirementProgress(
            itemName: item.name,
            requiredCount: item.neededCount,
            collectedCount: collected,
            missingCount: remaining,
            sourceHint: item.locationHint,
          ),
        );
      }
    }
    final percent = requiredCount == 0
        ? 0
        : ((collectedCount / requiredCount) * 100).round().clamp(0, 100);
    return _QuestProgress(
      group: group,
      completedItems: completedItems,
      totalItems: group.items.length,
      requiredCount: requiredCount,
      collectedCount: collectedCount,
      missingCount: missing.fold<int>(
        0,
        (total, item) => total + item.missingCount,
      ),
      completionPercent: percent,
      missingItems: missing,
    );
  }
}

class _QuestGroup {
  _QuestGroup({
    required this.trader,
    required this.questName,
    required this.firstOrder,
    required this.items,
  });

  final String trader;
  final String questName;
  int firstOrder;
  final List<ArcScrappyItem> items;

  String get label => '$trader - $questName';

  int get requiredCount =>
      items.fold<int>(0, (total, item) => total + item.neededCount);
}

class _QuestProgress {
  const _QuestProgress({
    required this.group,
    required this.completedItems,
    required this.totalItems,
    required this.requiredCount,
    required this.collectedCount,
    required this.missingCount,
    required this.completionPercent,
    required this.missingItems,
  });

  final _QuestGroup group;
  final int completedItems;
  final int totalItems;
  final int requiredCount;
  final int collectedCount;
  final int missingCount;
  final int completionPercent;
  final List<ArcQuestRequirementProgress> missingItems;

  bool get ready => totalItems > 0 && completedItems == totalItems;
}
