import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trust/models/arc_raider_contract_models.dart';

void main() {
  test('report accepts Blueprint duplicate rewards without item rewards', () {
    final report = ArcRaiderReport(
      id: 'r1',
      reporterUid: 'creator',
      targetDisplayName: 'RatName',
      category: ArcRaiderReportCategory.shotInBack,
      description: '',
      status: ArcRaiderReportStatus.submitted,
      mapId: 'dam',
      serverRegion: 'Europe',
      incidentAt: DateTime(2026, 8, 30),
      locationX: .2,
      locationY: .3,
      requestContract: true,
      blueprintRewardCount: 2,
    );

    expect(report.canSubmit, isTrue);
    expect(report.toMap()['blueprintRewardCount'], 2);
    expect(report.category, ArcRaiderReportCategory.shotInBack);
  });

  test('contract round trips Blueprint reward pool and selection', () {
    final contract = ArcRaiderContract(
      id: 'c1',
      reportId: 'r1',
      targetDisplayName: 'RatName',
      reporterUid: 'creator',
      status: ArcRaiderContractStatus.accepted,
      hunterUid: 'hunter',
      blueprintRewardCount: 2,
      blueprintRewardPool: const ['bobcat', 'tempest', 'vulcano'],
      blueprintRewardSelection: const ['tempest', 'vulcano'],
    );

    final restored = ArcRaiderContract.fromMap(contract.toMap());
    expect(restored.blueprintRewardCount, 2);
    expect(
      restored.blueprintRewardPool,
      containsAll(['bobcat', 'tempest', 'vulcano']),
    );
    expect(restored.blueprintRewardSelection, ['tempest', 'vulcano']);
  });

  test('Blueprint reward candidate is stable', () {
    const candidate = ArcRaiderBlueprintRewardCandidate(
      blueprintId: 'tempest',
      name: 'Tempest',
    );
    expect(candidate.blueprintId, 'tempest');
    expect(candidate.name, 'Tempest');
  });
  test(
    'Firestore rules preserve Blueprint reward terms and restrict claimant selection',
    () {
      final rules = File('firestore.rules').readAsStringSync();
      expect(
        rules,
        contains(
          'request.resource.data.blueprintRewardCount == resource.data.blueprintRewardCount',
        ),
      );
      expect(
        rules,
        contains(
          'request.resource.data.blueprintRewardPool == resource.data.blueprintRewardPool',
        ),
      );
      expect(
        rules,
        contains(
          "affectedKeys().hasOnly(['blueprintRewardSelection', 'updatedAt'])",
        ),
      );
      expect(rules, contains('blueprintRewardPool.toSet().hasAll'));
      expect(rules, contains('resource.data.reporterUid == request.auth.uid'));
      expect(rules, contains('resource.data.hunterUid == request.auth.uid'));
    },
  );
}
