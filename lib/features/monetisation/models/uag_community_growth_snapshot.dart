class UagCommunityGrowthSnapshot {
  const UagCommunityGrowthSnapshot({
    required this.qualifiedActiveUsers,
    required this.updatedAtIso,
  });

  final int qualifiedActiveUsers;
  final String updatedAtIso;

  factory UagCommunityGrowthSnapshot.fromMap(Map<String, dynamic> data) {
    return UagCommunityGrowthSnapshot(
      qualifiedActiveUsers:
          (data['qualifiedActiveUsers'] as num?)?.toInt() ?? 0,
      updatedAtIso: data['updatedAtIso']?.toString() ?? '',
    );
  }
}
