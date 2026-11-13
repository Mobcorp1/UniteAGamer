import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trust/models/arc_raider_contract_models.dart';
import 'package:uag_arc_raiders_hub/features/trust/models/arc_hunter_verified_result.dart';

Map<String, dynamic> verified({String id = 'c1', String country = 'GB'}) => {
  'contractId': id,
  'hunterUid': 'hunter',
  'issuerUid': 'issuer',
  'verifiedByUid': 'issuer',
  'verificationStatus': 'verified',
  'evidenceSubmissionId': 'submission',
  'countryCode': country,
  'verifiedAt': Timestamp.fromDate(DateTime.utc(2026, 9, 14)),
};
ArcRaiderContract contract(
  ArcRaiderContractStatus status, {
  String verification = '',
  String verifier = 'issuer',
  List<ArcRaiderEvidence>? evidence,
}) => ArcRaiderContract(
  id: 'c1',
  reportId: 'r1',
  targetDisplayName: 'Target',
  reporterUid: 'issuer',
  hunterUid: 'hunter',
  status: status,
  verificationStatus: verification,
  verifiedByUid: verifier,
  evidenceSubmissionId: 'submission',
  verifiedAt: DateTime.utc(2026, 9, 14),
  rejectionReason: 'Target is not visible',
  evidence:
      evidence ??
      const [
        ArcRaiderEvidence(
          id: 'submission',
          submittedByUid: 'hunter',
          kind: 'video',
          url: '',
          storagePath: 'contract_evidence/c1/hunter/submission.mp4',
        ),
      ],
);

void main() {
  for (final state in [
    ArcRaiderContractStatus.available,
    ArcRaiderContractStatus.accepted,
    ArcRaiderContractStatus.inProgress,
    ArcRaiderContractStatus.evidenceSubmitted,
    ArcRaiderContractStatus.rejected,
  ]) {
    test('${state.name} never counts, even with stray attestation fields', () {
      expect(
        contract(state, verification: 'verified').isVerifiedComplete,
        isFalse,
      );
    });
  }
  test('legacy completion never counts', () {
    expect(
      contract(ArcRaiderContractStatus.completed).isVerifiedComplete,
      isFalse,
    );
  });
  test('issuer attestation and complete video round trip', () {
    final value = contract(
      ArcRaiderContractStatus.completed,
      verification: 'verified',
    );
    expect(ArcRaiderContract.fromMap(value.toMap()).isVerifiedComplete, isTrue);
    expect(value.canSubmitVideoEvidence, isFalse);
    for (final next in ArcRaiderContractStatus.values) {
      expect(value.canTransitionTo(next), isFalse);
    }
  });
  test('wrong verifier or missing video cannot display verified', () {
    expect(
      contract(
        ArcRaiderContractStatus.completed,
        verification: 'verified',
        verifier: 'hunter',
      ).isVerifiedComplete,
      isFalse,
    );
    expect(
      contract(
        ArcRaiderContractStatus.completed,
        verification: 'verified',
        evidence: [],
      ).isVerifiedComplete,
      isFalse,
    );
  });
  test('pending review locks new uploads; rejection allows replacement', () {
    final pending = contract(
      ArcRaiderContractStatus.evidenceSubmitted,
      verification: 'pending',
    );
    final rejected = contract(
      ArcRaiderContractStatus.evidenceSubmitted,
      verification: 'rejected',
    );
    expect(pending.isAwaitingIssuerReview, isTrue);
    expect(pending.canSubmitVideoEvidence, isFalse);
    expect(rejected.isAwaitingIssuerReview, isFalse);
    expect(rejected.canSubmitVideoEvidence, isTrue);
    expect(rejected.isVerifiedComplete, isFalse);
    expect(
      ArcRaiderContract.fromMap(rejected.toMap()).rejectionReason,
      'Target is not visible',
    );
  });
  test('accept start submit dispute lifecycle stays available', () {
    expect(
      contract(
        ArcRaiderContractStatus.available,
      ).canTransitionTo(ArcRaiderContractStatus.accepted),
      isTrue,
    );
    expect(
      contract(
        ArcRaiderContractStatus.accepted,
      ).canTransitionTo(ArcRaiderContractStatus.inProgress),
      isTrue,
    );
    expect(
      contract(
        ArcRaiderContractStatus.inProgress,
      ).canTransitionTo(ArcRaiderContractStatus.evidenceSubmitted),
      isTrue,
    );
    expect(
      contract(
        ArcRaiderContractStatus.evidenceSubmitted,
      ).canTransitionTo(ArcRaiderContractStatus.disputed),
      isTrue,
    );
    expect(
      contract(
        ArcRaiderContractStatus.disputed,
      ).canTransitionTo(ArcRaiderContractStatus.completed),
      isFalse,
    );
  });
  test(
    'country/month projection excludes unverified and deduplicates contracts',
    () {
      final inputs = [
        verified(),
        verified(),
        verified(id: 'c2', country: 'DE'),
        {...verified(id: 'c3'), 'verificationStatus': 'pending'},
        {...verified(id: 'c4'), 'verifiedByUid': 'hunter'},
        {
          ...verified(id: 'c5'),
          'verifiedAt': Timestamp.fromDate(DateTime.utc(2026, 8, 31)),
        },
      ];
      final records = inputs
          .map(
            (m) => ArcHunterVerifiedResult.fromServerRecord(
              m['contractId'] as String,
              m,
            ),
          )
          .whereType<ArcHunterVerifiedResult>()
          .toList();
      expect(
        ArcHunterVerifiedResult.totals(
          records,
          countryCode: 'GB',
          month: DateTime.utc(2026, 9),
        ),
        {'hunter': 1},
      );
      expect(ArcHunterVerifiedResult.totals(records), {'hunter': 3});
      expect(
        ArcHunterVerifiedResult.fromServerRecord('wrong-document', verified()),
        isNull,
      );
    },
  );
  test('missing country is never assigned a default nation', () {
    final result = ArcHunterVerifiedResult.fromServerRecord(
      'c1',
      verified(country: ''),
    )!;
    expect(result.countryCode, isEmpty);
    expect(
      ArcHunterVerifiedResult.totals([result], countryCode: 'US'),
      isEmpty,
    );
    expect(ArcHunterVerifiedResult.totals([result]), {'hunter': 1});
  });
}
