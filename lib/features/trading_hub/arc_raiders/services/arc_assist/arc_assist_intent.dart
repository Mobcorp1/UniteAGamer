enum ArcAssistIntentType {
  foundBlueprint,
  addDuplicate,
  createListing,
  findTrade,
  openTracker,
  openPlanner,
  unknown,
}

class ArcAssistIntent {
  final ArcAssistIntentType type;
  final String spokenText;
  final String? blueprintQuery;

  const ArcAssistIntent({
    required this.type,
    required this.spokenText,
    required this.blueprintQuery,
  });
}
