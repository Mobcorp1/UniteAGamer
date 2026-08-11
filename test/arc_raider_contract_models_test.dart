import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trust/models/arc_raider_contract_models.dart';

void main() {
  test('structured ratting report serializes intelligence and rewards', () {
    final report = ArcRaiderReport(
      id: 'r1',
      reporterUid: 'reporter',
      targetDisplayName: 'Target',
      category: ArcRaiderReportCategory.extractionRatting,
      description:
          'Target repeatedly camped the extraction during the encounter.',
      status: ArcRaiderReportStatus.submitted,
      mapId: 'dam_battlegrounds',
      mapDisplayName: 'Dam Battlegrounds',
      locationX: .75,
      locationY: .25,
      locationLabel: 'North Standard Extraction',
      atExtraction: true,
      extractionId: 'dam_battlegrounds_north_extraction',
      extractionName: 'North Standard Extraction',
      rattingSubtype: 'Waiting at extraction',
      serverRegion: 'Europe',
      incidentAt: DateTime(2026, 8, 10, 21, 30),
      repeatBehaviour: ArcRaiderRepeatBehaviour.sameRaid,
      repeatCount: 3,
      requestContract: true,
      rewardItems: const [
        ArcRaiderRewardItem(
          itemId: 'assorted-seeds',
          name: 'Assorted Seeds',
          category: 'Currency',
          quantity: 5,
        ),
      ],
    );
    final restored = ArcRaiderReport.fromMap(report.toMap());
    expect(restored.mapId, 'dam_battlegrounds');
    expect(restored.atExtraction, isTrue);
    expect(restored.repeatCount, 3);
    expect(restored.rewardItems.single.quantity, 5);
    expect(restored.canSubmit, isTrue);
  });

  test('requested contract requires a reward bundle', () {
    final report = ArcRaiderReport(
      id: 'r2',
      reporterUid: 'reporter',
      targetDisplayName: 'Target',
      category: ArcRaiderReportCategory.ambushRatting,
      description:
          'A sufficiently detailed description of the encounter happened here.',
      status: ArcRaiderReportStatus.submitted,
      mapId: 'blue_gate',
      mapDisplayName: 'Blue Gate',
      locationX: .5,
      locationY: .5,
      serverRegion: 'Europe',
      incidentAt: DateTime(2026, 8, 10),
      requestContract: true,
    );
    expect(report.canSubmit, isFalse);
  });

  test('contract reward bundle round trips', () {
    final contract = ArcRaiderContract(
      id: 'c1',
      reportId: 'r1',
      targetDisplayName: 'Target',
      reporterUid: 'reporter',
      status: ArcRaiderContractStatus.available,
      rewardItems: const [
        ArcRaiderRewardItem(
          itemId: 'queen-reactor',
          name: 'Queen Reactor',
          category: 'Legendary Material',
          quantity: 1,
        ),
      ],
      rewardSummary: '1× Queen Reactor',
    );
    final restored = ArcRaiderContract.fromMap(contract.toMap());
    expect(restored.rewardItems.single.itemId, 'queen-reactor');
    expect(restored.rewardSummary, contains('Queen Reactor'));
  });
}
