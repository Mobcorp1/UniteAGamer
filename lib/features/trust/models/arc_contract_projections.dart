/// Explicit allowlisted wire views. Never deserialize a private Contract here.
class ArcContractDiscoveryItem {
  const ArcContractDiscoveryItem({
    required this.id,
    required this.targetDisplayName,
    required this.category,
    required this.rewardSummary,
    required this.mapAffinity,
    required this.confidence,
    required this.regionMatch,
    required this.evidenceState,
  });
  final String id,
      targetDisplayName,
      category,
      rewardSummary,
      mapAffinity,
      confidence,
      regionMatch,
      evidenceState;
  factory ArcContractDiscoveryItem.fromMap(Map<String, dynamic> map) =>
      ArcContractDiscoveryItem(
        id: map['id'] as String,
        targetDisplayName: map['targetDisplayName'] as String,
        category: map['category'] as String,
        rewardSummary: map['rewardSummary'] as String,
        mapAffinity: map['mapAffinity'] as String,
        confidence: map['confidence'] as String,
        regionMatch: map['regionMatch'] as String,
        evidenceState: map['evidenceState'] as String,
      );
}

class ArcContractAccountCase {
  const ArcContractAccountCase({
    required this.id,
    required this.category,
    required this.status,
    required this.evidenceState,
    required this.challengeStatus,
    required this.canChallenge,
  });
  final String id, category, status, evidenceState, challengeStatus;
  final bool canChallenge;
  factory ArcContractAccountCase.fromMap(Map<String, dynamic> map) =>
      ArcContractAccountCase(
        id: map['id'] as String,
        category: map['category'] as String,
        status: map['status'] as String,
        evidenceState: map['evidenceState'] as String,
        challengeStatus: map['challengeStatus'] as String,
        canChallenge: map['canChallenge'] == true,
      );
}
