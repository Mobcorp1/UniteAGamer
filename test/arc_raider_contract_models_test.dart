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

  test('open and closed contract serialization round trips', () {
    final open = ArcRaiderContract(
      id: 'open-contract',
      reportId: 'report-1',
      targetDisplayName: 'Target',
      reporterUid: 'reporter',
      status: ArcRaiderContractStatus.available,
      contractType: ArcRaiderContractType.open,
      rewardPool: const [
        ArcRaiderRewardPoolEntry(
          itemId: 'wolfpack-blueprint',
          name: 'Wolfpack Blueprint',
          category: 'Blueprint',
          quantityOffered: 2,
          quantityRemaining: 2,
        ),
      ],
      participantCount: 4,
      rewardSummary: '2× Wolfpack Blueprint',
    );
    final closed = ArcRaiderContract(
      id: 'closed-contract',
      reportId: 'report-2',
      targetDisplayName: 'Target',
      reporterUid: 'reporter',
      status: ArcRaiderContractStatus.available,
      contractType: ArcRaiderContractType.closed,
      rewardPool: const [
        ArcRaiderRewardPoolEntry(
          itemId: 'elite-key',
          name: 'Elite Key',
          category: 'Key',
          quantityOffered: 1,
          quantityRemaining: 1,
        ),
      ],
      participantCount: 2,
      expiresAt: DateTime.now().add(const Duration(days: 3)),
      closedContractEntitlement: 'premium',
    );

    final restoredOpen = ArcRaiderContract.fromMap(open.toMap());
    final restoredClosed = ArcRaiderContract.fromMap(closed.toMap());

    expect(restoredOpen.contractType, ArcRaiderContractType.open);
    expect(restoredOpen.rewardPool.single.quantityRemaining, 2);
    expect(restoredClosed.contractType, ArcRaiderContractType.closed);
    expect(restoredClosed.closedContractEntitlement, 'premium');
    expect(restoredClosed.isClosedContract, isTrue);
  });

  test('closed contract expiry must stay within 7-day maximum', () {
    final createdAt = DateTime(2026, 1, 1, 12);
    final withinLimit = createdAt.add(const Duration(days: 7));
    final beyondLimit = createdAt.add(const Duration(days: 8));

    expect(
      ArcRaiderContract.isValidClosedContractExpiry(withinLimit, createdAt),
      isTrue,
    );
    expect(
      ArcRaiderContract.isValidClosedContractExpiry(beyondLimit, createdAt),
      isFalse,
    );
  });

  test('invalid closed contract expiry is rejected', () {
    final contract = ArcRaiderContract(
      id: 'closed-invalid',
      reportId: 'report-3',
      targetDisplayName: 'Target',
      reporterUid: 'reporter',
      status: ArcRaiderContractStatus.available,
      contractType: ArcRaiderContractType.closed,
      rewardPool: const [
        ArcRaiderRewardPoolEntry(
          itemId: 'blueprint',
          name: 'Blueprint',
          category: 'Blueprint',
          quantityOffered: 1,
          quantityRemaining: 1,
        ),
      ],
      createdAt: DateTime(2026, 1, 1),
      expiresAt: DateTime(2026, 1, 10),
    );

    expect(
      ArcRaiderContract.isValidClosedContractExpiry(
        contract.expiresAt,
        contract.createdAt ?? DateTime(2026, 1, 1),
      ),
      isFalse,
    );
  });

  test(
    'reward pool supports multiple verified claims without dropping below zero',
    () {
      final pool = const [
        ArcRaiderRewardPoolEntry(
          itemId: 'wolfpack-blueprint',
          name: 'Wolfpack Blueprint',
          category: 'Blueprint',
          quantityOffered: 3,
          quantityRemaining: 3,
        ),
      ];
      final contract = ArcRaiderContract(
        id: 'contract-claim',
        reportId: 'report-claim',
        targetDisplayName: 'Target',
        reporterUid: 'reporter',
        status: ArcRaiderContractStatus.available,
        contractType: ArcRaiderContractType.open,
        rewardPool: pool,
      );

      final afterOne = contract.applyVerifiedRewardClaim(
        itemId: 'wolfpack-blueprint',
        quantity: 1,
      );
      final afterTwo = afterOne.applyVerifiedRewardClaim(
        itemId: 'wolfpack-blueprint',
        quantity: 1,
      );
      final afterThree = afterTwo.applyVerifiedRewardClaim(
        itemId: 'wolfpack-blueprint',
        quantity: 1,
      );
      final afterFour = afterThree.applyVerifiedRewardClaim(
        itemId: 'wolfpack-blueprint',
        quantity: 1,
      );

      expect(afterOne.rewardPool.single.quantityRemaining, 2);
      expect(afterTwo.rewardPool.single.quantityRemaining, 1);
      expect(afterThree.rewardPool.single.quantityRemaining, 0);
      expect(afterFour.rewardPool.single.quantityRemaining, 0);
      expect(afterFour.isExhausted, isTrue);
      expect(afterFour.isLive, isFalse);
    },
  );

  test(
    'contract remains live while reward remains and participant count is tracked',
    () {
      final contract = ArcRaiderContract(
        id: 'live-contract',
        reportId: 'report-live',
        targetDisplayName: 'Target',
        reporterUid: 'reporter',
        status: ArcRaiderContractStatus.available,
        participantCount: 4,
        rewardPool: const [
          ArcRaiderRewardPoolEntry(
            itemId: 'atlas-core',
            name: 'Atlas Core',
            category: 'Material',
            quantityOffered: 2,
            quantityRemaining: 1,
          ),
        ],
      );
      expect(contract.isLive, isTrue);
      expect(contract.participantCount, 4);

      final exhausted = contract.applyVerifiedRewardClaim(
        itemId: 'atlas-core',
        quantity: 1,
      );
      expect(exhausted.isLive, isFalse);
      expect(exhausted.isExhausted, isTrue);
    },
  );

  test('participant-specific counter offers serialize cleanly', () {
    const offer = ArcRaiderCounterOffer(
      id: 'offer-1',
      contractId: 'contract-1',
      hunterUid: 'hunter-1',
      requestedRewardItemIds: ['wolfpack-blueprint'],
      quantities: [1],
      alternativeItemIds: ['atlas-core'],
      status: ArcRaiderCounterOfferStatus.countered,
    );

    final restored = ArcRaiderCounterOffer.fromMap(offer.toMap());
    expect(restored.hunterUid, 'hunter-1');
    expect(restored.alternativeItemIds.single, 'atlas-core');
    expect(restored.status, ArcRaiderCounterOfferStatus.countered);
  });

  test('invalid contract transitions are rejected', () {
    const contract = ArcRaiderContract(
      id: 'invalid-transition',
      reportId: 'report-invalid',
      targetDisplayName: 'Target',
      reporterUid: 'reporter',
      status: ArcRaiderContractStatus.available,
      rewardPool: [
        ArcRaiderRewardPoolEntry(
          itemId: 'x',
          name: 'X',
          category: 'Blueprint',
          quantityOffered: 1,
          quantityRemaining: 1,
        ),
      ],
    );

    expect(
      contract.canTransitionTo(ArcRaiderContractStatus.completed),
      isFalse,
    );
    expect(contract.canTransitionTo(ArcRaiderContractStatus.accepted), isTrue);
  });
}
