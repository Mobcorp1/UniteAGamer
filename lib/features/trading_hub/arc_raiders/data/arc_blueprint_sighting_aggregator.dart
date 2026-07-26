import 'package:flutter/foundation.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

enum ArcBlueprintSightingTrend { surging, active, steady, cooling, seeded }

extension ArcBlueprintSightingTrendX on ArcBlueprintSightingTrend {
  String get label {
    switch (this) {
      case ArcBlueprintSightingTrend.surging:
        return 'Surging';
      case ArcBlueprintSightingTrend.active:
        return 'Active';
      case ArcBlueprintSightingTrend.steady:
        return 'Steady';
      case ArcBlueprintSightingTrend.cooling:
        return 'Cooling';
      case ArcBlueprintSightingTrend.seeded:
        return 'Seeded Intel';
    }
  }
}

@immutable
class ArcBlueprintSightingSummary {
  const ArcBlueprintSightingSummary({
    required this.blueprintId,
    required this.totalFinds,
    required this.findsLast24Hours,
    required this.findsLast7Days,
    required this.latestSightingAt,
    required this.trend,
    required this.confidence,
    required this.reportDriven,
  });

  final String blueprintId;
  final int totalFinds;
  final int findsLast24Hours;
  final int findsLast7Days;
  final DateTime? latestSightingAt;
  final ArcBlueprintSightingTrend trend;
  final ArcRaidIntelConfidence confidence;
  final bool reportDriven;

  String recencyLabel(DateTime now) {
    final latest = latestSightingAt;
    if (latest == null) return reportDriven ? 'No timestamp' : 'Seeded Intel';

    final age = now.difference(latest);
    if (age.isNegative || age.inMinutes < 60) return 'Seen this hour';
    if (age.inHours < 24) return 'Seen ${age.inHours}h ago';
    if (age.inDays == 1) return 'Seen yesterday';
    if (age.inDays < 7) return 'Seen ${age.inDays}d ago';
    return 'Last seen ${age.inDays}d ago';
  }
}

@immutable
class ArcBlueprintLocationActivity {
  const ArcBlueprintLocationActivity({
    required this.sightings,
    required this.totalFinds,
    required this.findsLast24Hours,
    required this.findsLast7Days,
    required this.contributorCount,
    required this.latestSightingAt,
    required this.trend,
  });

  final List<ArcBlueprintSightingSummary> sightings;
  final int totalFinds;
  final int findsLast24Hours;
  final int findsLast7Days;
  final int contributorCount;
  final DateTime? latestSightingAt;
  final ArcBlueprintSightingTrend trend;

  bool get hasLiveReports => sightings.any((item) => item.reportDriven);
}

class ArcBlueprintSightingAggregator {
  const ArcBlueprintSightingAggregator();

  ArcBlueprintLocationActivity aggregate(
    ArcRaidIntelCluster cluster, {
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final summaries = <ArcBlueprintSightingSummary>[];

    for (final blueprintId in cluster.blueprintIds) {
      final evidence = cluster.evidence
          .where((item) => item.blueprintId == blueprintId)
          .toList(growable: false);
      final reportEvidence = evidence
          .where((item) => item.sourceCategory == 'community_drop_report')
          .toList(growable: false);
      final timestamps =
          reportEvidence
              .map((item) => item.reviewedAt ?? item.publishedAt)
              .whereType<DateTime>()
              .toList(growable: false)
            ..sort((a, b) => b.compareTo(a));

      final last24Hours = timestamps.where((value) {
        final age = reference.difference(value);
        return !age.isNegative && age <= const Duration(hours: 24);
      }).length;
      final last7Days = timestamps.where((value) {
        final age = reference.difference(value);
        return !age.isNegative && age <= const Duration(days: 7);
      }).length;
      final total = reportEvidence.isEmpty
          ? evidence.length.clamp(1, cluster.reportCount.clamp(1, 999))
          : reportEvidence.length;
      final confidence = _confidence(
        totalFinds: total,
        findsLast7Days: last7Days,
        base: cluster.confidence,
        reportDriven: reportEvidence.isNotEmpty,
      );

      summaries.add(
        ArcBlueprintSightingSummary(
          blueprintId: blueprintId,
          totalFinds: total,
          findsLast24Hours: last24Hours,
          findsLast7Days: last7Days,
          latestSightingAt: timestamps.isEmpty ? null : timestamps.first,
          trend: _trend(
            reportDriven: reportEvidence.isNotEmpty,
            totalFinds: total,
            findsLast24Hours: last24Hours,
            findsLast7Days: last7Days,
          ),
          confidence: confidence,
          reportDriven: reportEvidence.isNotEmpty,
        ),
      );
    }

    summaries.sort((a, b) {
      final liveCompare = b.findsLast24Hours.compareTo(a.findsLast24Hours);
      if (liveCompare != 0) return liveCompare;
      final weekCompare = b.findsLast7Days.compareTo(a.findsLast7Days);
      if (weekCompare != 0) return weekCompare;
      return b.totalFinds.compareTo(a.totalFinds);
    });

    final timestamps =
        summaries
            .map((item) => item.latestSightingAt)
            .whereType<DateTime>()
            .toList(growable: false)
          ..sort((a, b) => b.compareTo(a));
    final total24 = summaries.fold<int>(
      0,
      (total, item) => total + item.findsLast24Hours,
    );
    final total7 = summaries.fold<int>(
      0,
      (total, item) => total + item.findsLast7Days,
    );
    final totalFinds = summaries.fold<int>(
      0,
      (total, item) => total + item.totalFinds,
    );

    return ArcBlueprintLocationActivity(
      sightings: summaries,
      totalFinds: totalFinds,
      findsLast24Hours: total24,
      findsLast7Days: total7,
      contributorCount: cluster.independentReporterCount,
      latestSightingAt: timestamps.isEmpty ? null : timestamps.first,
      trend: _trend(
        reportDriven: summaries.any((item) => item.reportDriven),
        totalFinds: totalFinds,
        findsLast24Hours: total24,
        findsLast7Days: total7,
      ),
    );
  }

  ArcBlueprintSightingTrend _trend({
    required bool reportDriven,
    required int totalFinds,
    required int findsLast24Hours,
    required int findsLast7Days,
  }) {
    if (!reportDriven) return ArcBlueprintSightingTrend.seeded;
    if (findsLast24Hours >= 3 ||
        (findsLast24Hours >= 2 && findsLast24Hours * 2 >= findsLast7Days)) {
      return ArcBlueprintSightingTrend.surging;
    }
    if (findsLast24Hours >= 1 || findsLast7Days >= 4) {
      return ArcBlueprintSightingTrend.active;
    }
    if (findsLast7Days >= 1 || totalFinds >= 3) {
      return ArcBlueprintSightingTrend.steady;
    }
    return ArcBlueprintSightingTrend.cooling;
  }

  ArcRaidIntelConfidence _confidence({
    required int totalFinds,
    required int findsLast7Days,
    required ArcRaidIntelConfidence base,
    required bool reportDriven,
  }) {
    if (!reportDriven) return base;
    final score = base.score + (totalFinds * 4) + (findsLast7Days * 6);
    if (score >= 90) return ArcRaidIntelConfidence.confirmed;
    if (score >= 70) return ArcRaidIntelConfidence.strong;
    if (score >= 45) return ArcRaidIntelConfidence.moderate;
    return ArcRaidIntelConfidence.limited;
  }
}
