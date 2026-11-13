class WebVersionMetadata {
  const WebVersionMetadata({
    required this.buildId,
    required this.builtAt,
    required this.branch,
  });

  final String buildId;
  final String builtAt;
  final String branch;

  factory WebVersionMetadata.fromInputs({
    required String buildId,
    required String builtAt,
    required String branch,
  }) {
    final resolvedBuildId = buildId.trim().isEmpty
        ? 'local-${DateTime.now().toUtc().millisecondsSinceEpoch}'
        : buildId.trim();
    final resolvedBuiltAt = builtAt.trim().isEmpty
        ? DateTime.now().toUtc().toIso8601String()
        : builtAt.trim();
    final resolvedBranch = branch.trim().isEmpty ? 'local' : branch.trim();

    return WebVersionMetadata(
      buildId: resolvedBuildId,
      builtAt: resolvedBuiltAt,
      branch: resolvedBranch,
    );
  }

  Map<String, dynamic> toJson() {
    return {'buildId': buildId, 'builtAt': builtAt, 'branch': branch};
  }
}
