enum ArcCommandStatus { critical, warning, active, ready, neutral, success }

enum ArcCommandActionIntent {
  route,
  favouriteLoadout,
  toolDeck,
  smartTrade,
  nomadicTrader,
  operations,
  placeholder,
}

class ArcCommandAction {
  const ArcCommandAction({
    required this.label,
    this.routeName,
    this.intent = ArcCommandActionIntent.route,
    this.placeholderMessage,
  });

  final String label;
  final String? routeName;
  final ArcCommandActionIntent intent;
  final String? placeholderMessage;
}

class ArcCommandPriority {
  const ArcCommandPriority({
    required this.title,
    required this.explanation,
    required this.progressLabel,
    required this.statusTag,
    required this.detail,
    required this.status,
    required this.primaryAction,
    this.secondaryAction,
  });

  final String title;
  final String explanation;
  final String progressLabel;
  final String statusTag;
  final String detail;
  final ArcCommandStatus status;
  final ArcCommandAction primaryAction;
  final ArcCommandAction? secondaryAction;
}

class ArcCommandSnapshotMetric {
  const ArcCommandSnapshotMetric({
    required this.label,
    required this.value,
    required this.detail,
    required this.status,
  });

  final String label;
  final String value;
  final String detail;
  final ArcCommandStatus status;
}

class ArcCommandObjective {
  const ArcCommandObjective({
    required this.title,
    required this.reason,
    required this.statusLabel,
    required this.progressText,
    required this.status,
    required this.action,
  });

  final String title;
  final String reason;
  final String statusLabel;
  final String progressText;
  final ArcCommandStatus status;
  final ArcCommandAction action;
}

class ArcCommandAlert {
  const ArcCommandAlert({
    required this.title,
    required this.body,
    required this.statusLabel,
    required this.status,
    required this.action,
  });

  final String title;
  final String body;
  final String statusLabel;
  final ArcCommandStatus status;
  final ArcCommandAction action;
}

class ArcCommandRecommendation {
  const ArcCommandRecommendation({
    required this.title,
    required this.body,
    required this.action,
  });

  final String title;
  final String body;
  final ArcCommandAction action;
}

class ArcCommandChecklistItem {
  const ArcCommandChecklistItem({
    required this.id,
    required this.label,
    required this.reason,
    required this.action,
    this.doneByDefault = false,
  });

  final String id;
  final String label;
  final String reason;
  final ArcCommandAction action;
  final bool doneByDefault;
}

class ArcCommandResourceStatus {
  const ArcCommandResourceStatus({
    required this.name,
    required this.ownedLabel,
    required this.requiredLabel,
    required this.status,
  });

  final String name;
  final String ownedLabel;
  final String requiredLabel;
  final ArcCommandStatus status;
}

class ArcCommandTradeSummary {
  const ArcCommandTradeSummary({
    required this.lookingFor,
    required this.offering,
    required this.actions,
  });

  final List<String> lookingFor;
  final List<String> offering;
  final List<ArcCommandAction> actions;
}

class ArcCommandTradeActivity {
  const ArcCommandTradeActivity({
    required this.communityListings,
    required this.myListings,
    required this.activeMyListings,
    required this.pendingOffers,
    required this.acceptedOffers,
    required this.activeSessions,
    required this.readySessions,
    required this.unreadNotifications,
    this.intelligenceMatches = 0,
    this.bestIntelligenceConfidence = 0,
    this.bestIntelligenceLabel = '',
    this.activeBlueprintWatches = 0,
    this.matchedBlueprintWatches = 0,
    this.activeListingQueues = 0,
    this.releasableListingQueues = 0,
    this.blockedListingQueues = 0,
  });

  final int communityListings;
  final int myListings;
  final int activeMyListings;
  final int pendingOffers;
  final int acceptedOffers;
  final int activeSessions;
  final int readySessions;
  final int unreadNotifications;
  final int intelligenceMatches;
  final int bestIntelligenceConfidence;
  final String bestIntelligenceLabel;
  final int activeBlueprintWatches;
  final int matchedBlueprintWatches;
  final int activeListingQueues;
  final int releasableListingQueues;
  final int blockedListingQueues;

  static const empty = ArcCommandTradeActivity(
    communityListings: 0,
    myListings: 0,
    activeMyListings: 0,
    pendingOffers: 0,
    acceptedOffers: 0,
    activeSessions: 0,
    readySessions: 0,
    unreadNotifications: 0,
    intelligenceMatches: 0,
    bestIntelligenceConfidence: 0,
    bestIntelligenceLabel: '',
    activeBlueprintWatches: 0,
    matchedBlueprintWatches: 0,
    activeListingQueues: 0,
    releasableListingQueues: 0,
    blockedListingQueues: 0,
  );

  int get actionableCount =>
      pendingOffers +
      activeSessions +
      unreadNotifications +
      intelligenceMatches +
      matchedBlueprintWatches +
      releasableListingQueues +
      blockedListingQueues;

  bool get hasActionableTrades => actionableCount > 0;
  bool get hasHighValueIntelligence => bestIntelligenceConfidence >= 75;
  bool get hasWatchMatches => matchedBlueprintWatches > 0;
  bool get hasQueueAction =>
      releasableListingQueues > 0 || blockedListingQueues > 0;
}

class ArcCommandSummaryPanel {
  const ArcCommandSummaryPanel({
    required this.title,
    required this.statusLabel,
    required this.body,
    required this.details,
    required this.status,
    required this.action,
  });

  final String title;
  final String statusLabel;
  final String body;
  final List<String> details;
  final ArcCommandStatus status;
  final ArcCommandAction action;
}

class ArcCommandCentreState {
  const ArcCommandCentreState({
    required this.priority,
    required this.snapshots,
    required this.objectives,
    required this.alerts,
    required this.recommendations,
    required this.checklist,
    required this.resources,
    required this.tradeSummary,
    required this.blueprintSummary,
    required this.questSummary,
    required this.benchSummary,
    required this.operationsSummary,
    required this.weeklyTraderSummary,
    required this.resourceSummary,
    required this.raidIntelligenceSummary,
    required this.decisionSummary,
    required this.communitySummary,
    required this.statisticsSummary,
  });

  final ArcCommandPriority priority;
  final List<ArcCommandSnapshotMetric> snapshots;
  final List<ArcCommandObjective> objectives;
  final List<ArcCommandAlert> alerts;
  final List<ArcCommandRecommendation> recommendations;
  final List<ArcCommandChecklistItem> checklist;
  final List<ArcCommandResourceStatus> resources;
  final ArcCommandTradeSummary tradeSummary;
  final ArcCommandSummaryPanel blueprintSummary;
  final ArcCommandSummaryPanel questSummary;
  final ArcCommandSummaryPanel benchSummary;
  final ArcCommandSummaryPanel operationsSummary;
  final ArcCommandSummaryPanel weeklyTraderSummary;
  final ArcCommandSummaryPanel resourceSummary;
  final ArcCommandSummaryPanel raidIntelligenceSummary;
  final ArcCommandSummaryPanel decisionSummary;
  final ArcCommandSummaryPanel communitySummary;
  final ArcCommandSummaryPanel statisticsSummary;
}
