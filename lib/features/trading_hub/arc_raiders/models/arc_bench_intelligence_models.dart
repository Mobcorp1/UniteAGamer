import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';

class ArcBenchResourceProgress {
  const ArcBenchResourceProgress({
    required this.itemName,
    required this.requiredCount,
    required this.collectedCount,
    required this.missingCount,
    required this.locationHint,
  });

  final String itemName;
  final int requiredCount;
  final int collectedCount;
  final int missingCount;
  final String? locationHint;

  bool get complete => missingCount == 0;

  String get missingLabel =>
      missingCount <= 0 ? '$itemName ready' : '$itemName x$missingCount';

  String get progressLabel => '$collectedCount/$requiredCount $itemName';
}

class ArcBenchIntelligence {
  const ArcBenchIntelligence({
    required this.trackingKnown,
    required this.station,
    required this.upgradeLabel,
    required this.statusLabel,
    required this.summary,
    required this.recommendation,
    required this.actionLabel,
    required this.status,
    required this.completionPercent,
    required this.completedResources,
    required this.totalResources,
    required this.requiredCount,
    required this.collectedCount,
    required this.missingCount,
    required this.readyToUpgrade,
    required this.hasBlocker,
    required this.missingResources,
    required this.currentLevelLabel,
  });

  final bool trackingKnown;
  final String station;
  final String upgradeLabel;
  final String statusLabel;
  final String summary;
  final String recommendation;
  final String actionLabel;
  final ArcCommandStatus status;
  final int completionPercent;
  final int completedResources;
  final int totalResources;
  final int requiredCount;
  final int collectedCount;
  final int missingCount;
  final bool readyToUpgrade;
  final bool hasBlocker;
  final List<ArcBenchResourceProgress> missingResources;
  final String currentLevelLabel;

  String get progressLabel => trackingKnown
      ? '$completedResources/$totalResources resources - $completionPercent%'
      : 'Set up bench tracker';

  String get missingShortText {
    if (!trackingKnown) return 'Bench resources not tracked';
    if (missingResources.isEmpty) return 'No missing bench resources';
    return missingResources
        .take(3)
        .map((resource) => resource.missingLabel)
        .join(', ');
  }
}
