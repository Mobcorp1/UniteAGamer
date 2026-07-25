import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_community_intel_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  test('community report signature clusters nearby matching reports', () {
    const pointA = ArcNormalizedPoint(x: 0.313, y: 0.476);
    const pointB = ArcNormalizedPoint(x: 0.317, y: 0.474);

    final a = ArcCommunityIntelReport.buildSignature(
      mapId: 'blue_gate',
      layer: ArcRaidMapLayer.surface,
      category: ArcCommunityIntelCategory.blueprintFound,
      point: pointA,
      blueprintId: 'tempest',
    );
    final b = ArcCommunityIntelReport.buildSignature(
      mapId: 'blue_gate',
      layer: ArcRaidMapLayer.surface,
      category: ArcCommunityIntelCategory.blueprintFound,
      point: pointB,
      blueprintId: 'tempest',
    );

    expect(a, b);
  });

  test('separate locations do not share a signature', () {
    const pointA = ArcNormalizedPoint(x: 0.313, y: 0.476);
    const pointB = ArcNormalizedPoint(x: 0.355, y: 0.476);

    final a = ArcCommunityIntelReport.buildSignature(
      mapId: 'blue_gate',
      layer: ArcRaidMapLayer.surface,
      category: ArcCommunityIntelCategory.blueprintFound,
      point: pointA,
      blueprintId: 'tempest',
    );
    final b = ArcCommunityIntelReport.buildSignature(
      mapId: 'blue_gate',
      layer: ArcRaidMapLayer.surface,
      category: ArcCommunityIntelCategory.blueprintFound,
      point: pointB,
      blueprintId: 'tempest',
    );

    expect(a, isNot(b));
  });

  test('confidence increases with independent confirmations', () {
    ArcCommunityIntelReport report(int confirmations) {
      return ArcCommunityIntelReport(
        id: 'report',
        reporterUid: 'u1',
        mapId: 'blue_gate',
        layer: ArcRaidMapLayer.surface,
        category: ArcCommunityIntelCategory.highValueLoot,
        point: const ArcNormalizedPoint(x: 0.4, y: 0.5),
        createdAt: DateTime.utc(2026, 7, 25),
        updatedAt: DateTime.now(),
        confirmationCount: confirmations,
        confirmedByUserIds: const <String>[],
        signature: 'signature',
      );
    }

    expect(report(1).confidence, ArcRaidIntelConfidence.limited);
    expect(report(2).confidence, ArcRaidIntelConfidence.moderate);
    expect(report(3).confidence, ArcRaidIntelConfidence.strong);
    expect(report(5).confidence, ArcRaidIntelConfidence.confirmed);
  });
}
