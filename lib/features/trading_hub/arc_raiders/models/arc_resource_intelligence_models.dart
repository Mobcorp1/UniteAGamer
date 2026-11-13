import 'package:flutter/foundation.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';

@immutable
class ArcResourceRequirementSignal {
  const ArcResourceRequirementSignal({
    required this.system,
    required this.source,
    required this.requiredCount,
    required this.ownedCount,
    required this.missingCount,
    this.locationHint,
    this.currentBlocker = false,
    this.futureOnly = false,
  });

  final String system;
  final String source;
  final int requiredCount;
  final int ownedCount;
  final int missingCount;
  final String? locationHint;
  final bool currentBlocker;
  final bool futureOnly;

  bool get complete => missingCount <= 0;
}

@immutable
class ArcResourceIntelligenceEntry {
  const ArcResourceIntelligenceEntry({
    required this.id,
    required this.name,
    required this.ownedCount,
    required this.requiredCount,
    required this.missingCount,
    required this.duplicateCount,
    required this.systemLabels,
    required this.currentBlockerLabels,
    required this.sourceHints,
    required this.farmHint,
    required this.scarcityScore,
    required this.usefulnessScore,
    required this.progressionValue,
    required this.priorityLabel,
    required this.protectionLabel,
    required this.recommendation,
    required this.tradeActionLabel,
    required this.status,
    required this.neverTrade,
    required this.safeToTrade,
    required this.safeToSell,
    required this.futureRequirementLabels,
    required this.requirements,
  });

  final String id;
  final String name;
  final int ownedCount;
  final int requiredCount;
  final int missingCount;
  final int duplicateCount;
  final List<String> systemLabels;
  final List<String> currentBlockerLabels;
  final List<String> sourceHints;
  final String farmHint;
  final int scarcityScore;
  final int usefulnessScore;
  final int progressionValue;
  final String priorityLabel;
  final String protectionLabel;
  final String recommendation;
  final String tradeActionLabel;
  final ArcCommandStatus status;
  final bool neverTrade;
  final bool safeToTrade;
  final bool safeToSell;
  final List<String> futureRequirementLabels;
  final List<ArcResourceRequirementSignal> requirements;

  bool get isMissing => missingCount > 0;
  bool get blocksMultipleSystems => currentBlockerLabels.length >= 2;
  bool get usedByMultipleSystems => systemLabels.length >= 2;

  String get missingLabel =>
      missingCount <= 0 ? '$name ready' : '$name x$missingCount';

  String get duplicateLabel =>
      duplicateCount <= 0 ? 'No tracked surplus' : '$duplicateCount surplus';

  String get systemSummary => systemLabels.isEmpty
      ? 'No active system'
      : systemLabels.take(3).join(', ');
}

@immutable
class ArcInventoryIntelligence {
  const ArcInventoryIntelligence({
    required this.pressureLabel,
    required this.pressureDetail,
    required this.status,
    required this.safeTradeCandidates,
    required this.safeSellCandidates,
    required this.protectedResources,
    required this.futureRequirementLabels,
  });

  final String pressureLabel;
  final String pressureDetail;
  final ArcCommandStatus status;
  final List<ArcResourceIntelligenceEntry> safeTradeCandidates;
  final List<ArcResourceIntelligenceEntry> safeSellCandidates;
  final List<ArcResourceIntelligenceEntry> protectedResources;
  final List<String> futureRequirementLabels;
}

@immutable
class ArcResourceIntelligence {
  const ArcResourceIntelligence({
    required this.trackingKnown,
    required this.statusLabel,
    required this.summary,
    required this.recommendation,
    required this.actionLabel,
    required this.status,
    required this.totalTrackedResources,
    required this.totalRequiredResources,
    required this.totalMissingResources,
    required this.totalDuplicateResources,
    required this.entries,
    required this.highestPriorityResources,
    required this.lowestPriorityResources,
    required this.missingResources,
    required this.multiSystemResources,
    required this.safeTradeCandidates,
    required this.neverTradeResources,
    required this.farmTargets,
    required this.tradeTargets,
    required this.inventory,
    this.topResource,
  });

  final bool trackingKnown;
  final String statusLabel;
  final String summary;
  final String recommendation;
  final String actionLabel;
  final ArcCommandStatus status;
  final int totalTrackedResources;
  final int totalRequiredResources;
  final int totalMissingResources;
  final int totalDuplicateResources;
  final List<ArcResourceIntelligenceEntry> entries;
  final List<ArcResourceIntelligenceEntry> highestPriorityResources;
  final List<ArcResourceIntelligenceEntry> lowestPriorityResources;
  final List<ArcResourceIntelligenceEntry> missingResources;
  final List<ArcResourceIntelligenceEntry> multiSystemResources;
  final List<ArcResourceIntelligenceEntry> safeTradeCandidates;
  final List<ArcResourceIntelligenceEntry> neverTradeResources;
  final List<ArcResourceIntelligenceEntry> farmTargets;
  final List<ArcResourceIntelligenceEntry> tradeTargets;
  final ArcInventoryIntelligence inventory;
  final ArcResourceIntelligenceEntry? topResource;

  bool get hasCriticalBlocker =>
      topResource != null &&
      (topResource!.blocksMultipleSystems ||
          topResource!.status == ArcCommandStatus.critical);

  bool get hasTradeSurplus => safeTradeCandidates.isNotEmpty;
  bool get hasProtectedResources => neverTradeResources.isNotEmpty;

  String get topResourceLabel {
    final resource = topResource;
    if (resource == null) return 'No tracked blocker';
    return resource.missingCount > 0
        ? resource.missingLabel
        : '${resource.name} tracked';
  }
}
