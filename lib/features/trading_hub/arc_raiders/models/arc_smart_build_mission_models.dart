enum ArcSmartBuildMissionType {
  blueprintHunt,
  resourceGather,
  tradeBundle,
  craftAndEquip,
}

class ArcSmartBuildMission {
  const ArcSmartBuildMission({
    required this.id,
    required this.type,
    required this.title,
    required this.detail,
    required this.priority,
    required this.completed,
    this.targetId,
    this.targetName,
    this.quantity,
  });

  final String id;
  final ArcSmartBuildMissionType type;
  final String title;
  final String detail;
  final int priority;
  final bool completed;
  final String? targetId;
  final String? targetName;
  final int? quantity;
}

class ArcSmartBuildMissionSnapshot {
  const ArcSmartBuildMissionSnapshot({
    required this.displayName,
    required this.missions,
  });

  final String displayName;
  final List<ArcSmartBuildMission> missions;

  List<ArcSmartBuildMission> get incompleteMissions =>
      missions.where((mission) => !mission.completed).toList(growable: false);

  List<ArcSmartBuildMission> get prerequisiteMissions => missions
      .where(
        (mission) => mission.type != ArcSmartBuildMissionType.craftAndEquip,
      )
      .toList(growable: false);

  int get completedCount =>
      prerequisiteMissions.where((mission) => mission.completed).length;

  int get completionPercent => prerequisiteMissions.isEmpty
      ? 100
      : ((completedCount / prerequisiteMissions.length) * 100)
            .round()
            .clamp(0, 100)
            .toInt();

  ArcSmartBuildMission? get nextMission =>
      incompleteMissions.isEmpty ? null : incompleteMissions.first;

  bool get complete =>
      prerequisiteMissions.every((mission) => mission.completed);
}
