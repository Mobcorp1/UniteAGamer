class ArcSmartBuildHuntSnapshot {
  const ArcSmartBuildHuntSnapshot({
    required this.displayName,
    required this.requiredBlueprintIds,
    required this.missingBlueprintIds,
    required this.completionPercent,
    required this.nextTargetId,
    required this.nextTargetName,
  });

  final String displayName;
  final Set<String> requiredBlueprintIds;
  final Set<String> missingBlueprintIds;
  final int completionPercent;
  final String? nextTargetId;
  final String? nextTargetName;

  int get requiredCount => requiredBlueprintIds.length;
  int get missingCount => missingBlueprintIds.length;
  bool get complete => missingBlueprintIds.isEmpty;

  bool contains(String blueprintId, {bool missingOnly = false}) {
    return missingOnly
        ? missingBlueprintIds.contains(blueprintId)
        : requiredBlueprintIds.contains(blueprintId);
  }
}
