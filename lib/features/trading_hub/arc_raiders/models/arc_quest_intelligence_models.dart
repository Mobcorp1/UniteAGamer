import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';

class ArcQuestRequirementProgress {
  const ArcQuestRequirementProgress({
    required this.itemName,
    required this.requiredCount,
    required this.collectedCount,
    required this.missingCount,
    required this.sourceHint,
  });

  final String itemName;
  final int requiredCount;
  final int collectedCount;
  final int missingCount;
  final String? sourceHint;

  bool get complete => missingCount == 0;

  String get missingLabel =>
      missingCount <= 0 ? '$itemName ready' : '$itemName x$missingCount';

  String get progressLabel => '$collectedCount/$requiredCount $itemName';
}

class ArcQuestIntelligence {
  const ArcQuestIntelligence({
    required this.trackingKnown,
    required this.questLabel,
    required this.trader,
    required this.questName,
    required this.statusLabel,
    required this.summary,
    required this.recommendation,
    required this.actionLabel,
    required this.status,
    required this.completionPercent,
    required this.completedItems,
    required this.totalItems,
    required this.requiredCount,
    required this.collectedCount,
    required this.missingCount,
    required this.readyToComplete,
    required this.hasBlocker,
    required this.missingItems,
  });

  final bool trackingKnown;
  final String questLabel;
  final String trader;
  final String questName;
  final String statusLabel;
  final String summary;
  final String recommendation;
  final String actionLabel;
  final ArcCommandStatus status;
  final int completionPercent;
  final int completedItems;
  final int totalItems;
  final int requiredCount;
  final int collectedCount;
  final int missingCount;
  final bool readyToComplete;
  final bool hasBlocker;
  final List<ArcQuestRequirementProgress> missingItems;

  String get progressLabel => trackingKnown
      ? '$completedItems/$totalItems items - $completionPercent%'
      : 'Set up quest tracker';

  String get missingShortText {
    if (!trackingKnown) return 'Quest ownership not tracked';
    if (missingItems.isEmpty) return 'No missing quest items';
    return missingItems.take(3).map((item) => item.missingLabel).join(', ');
  }
}
