import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trust/models/arc_raider_contract_models.dart';

void main() {
  test('report serializes lifecycle and evidence', () {
    final r = ArcRaiderReport(
      id: 'r1',
      reporterUid: 'u1',
      targetDisplayName: 'Target',
      category: ArcRaiderReportCategory.griefing,
      description: 'A sufficiently detailed encounter description.',
      status: ArcRaiderReportStatus.submitted,
      evidence: [
        ArcRaiderEvidence(
          id: 'e1',
          submittedByUid: 'u1',
          kind: 'link',
          url: 'https://example.com/evidence',
        ),
      ],
    );
    final copy = ArcRaiderReport.fromMap(r.toMap());
    expect(copy.status, ArcRaiderReportStatus.submitted);
    expect(copy.evidence.single.id, 'e1');
    expect(copy.canSubmit, isTrue);
  });
  test('contract rejects invalid transition', () {
    const c = ArcRaiderContract(
      id: 'c',
      reportId: 'r',
      targetDisplayName: 'T',
      reporterUid: 'u',
      status: ArcRaiderContractStatus.available,
    );
    expect(c.canTransitionTo(ArcRaiderContractStatus.completed), isFalse);
    expect(c.canTransitionTo(ArcRaiderContractStatus.accepted), isTrue);
  });
}
