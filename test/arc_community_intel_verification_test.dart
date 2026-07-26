import 'package:flutter_test/flutter_test.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_community_intel_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  ArcCommunityIntelReport report({
    int confirmations = 1,
    int disputes = 0,
    DateTime? expiresAt,
    double trust = 1,
    bool active = true,
  }) {
    return ArcCommunityIntelReport(
      id: 'report',
      reporterUid: 'reporter',
      mapId: 'blue_gate',
      layer: ArcRaidMapLayer.surface,
      category: ArcCommunityIntelCategory.blueprintFound,
      point: const ArcNormalizedPoint(x: 0.4, y: 0.4),
      createdAt: DateTime.utc(2026, 7, 26),
      updatedAt: DateTime.utc(2026, 7, 26),
      confirmationCount: confirmations,
      confirmedByUserIds: const <String>[],
      disputeCount: disputes,
      disputedByUserIds: const <String>[],
      signature: 'signature',
      expiresAt: expiresAt,
      reporterTrustWeight: trust,
      active: active,
    );
  }

  test('community verification score includes confirmations and disputes', () {
    expect(report(confirmations: 4, disputes: 1).verificationScore, 3);
    expect(
      report(confirmations: 4, disputes: 1).verificationState,
      ArcCommunityIntelVerificationState.communityVerified,
    );
  });

  test('matching disputes mark Intel as disputed', () {
    expect(
      report(confirmations: 2, disputes: 2).verificationState,
      ArcCommunityIntelVerificationState.disputed,
    );
  });

  test('expired reports are removed from active lifecycle', () {
    final now = DateTime.utc(2026, 7, 27);
    expect(
      report(expiresAt: DateTime.utc(2026, 7, 26)).verificationStateAt(now),
      ArcCommunityIntelVerificationState.expired,
    );
  });

  test('trusted reporter weighting increases verification score', () {
    expect(report(confirmations: 2, trust: 1.5).verificationScore, 3);
  });
}
