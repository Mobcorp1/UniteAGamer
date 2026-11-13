import 'package:flutter/foundation.dart';

enum ArcBlueprintResearchEligibility {
  generalCandidate,
  conditionCandidate,
  notDocumentedPool,
  eventOnly,
  conditionUnavailable,
  questOnly,
  unverifiedPool,
}

extension ArcBlueprintResearchEligibilityX on ArcBlueprintResearchEligibility {
  bool get canAutoRoute =>
      this == ArcBlueprintResearchEligibility.generalCandidate ||
      this == ArcBlueprintResearchEligibility.conditionCandidate;
}

@immutable
class ArcBlueprintResearchSite {
  const ArcBlueprintResearchSite({
    required this.poiName,
    this.poiId,
    this.needsAdminReview = false,
  });

  final String poiName;
  final String? poiId;
  final bool needsAdminReview;

  bool get canResolveAutomatically =>
      !needsAdminReview && poiId?.trim().isNotEmpty == true;
}

@immutable
class ArcBlueprintResearchEntry {
  const ArcBlueprintResearchEntry({
    required this.blueprintId,
    required this.blueprintName,
    required this.mapId,
    required this.eligibility,
    required this.condition,
    required this.container,
    required this.evidenceSummary,
    required this.sites,
    this.reportedFindCount = 0,
  });

  final String blueprintId;
  final String blueprintName;
  final String mapId;
  final ArcBlueprintResearchEligibility eligibility;
  final String condition;
  final String container;
  final String evidenceSummary;
  final List<ArcBlueprintResearchSite> sites;
  final int reportedFindCount;

  bool get canAutoRoute =>
      eligibility.canAutoRoute &&
      sites.any((site) => site.canResolveAutomatically);

  Iterable<ArcBlueprintResearchSite> get autoRouteSites =>
      sites.where((site) => site.canResolveAutomatically);
}
