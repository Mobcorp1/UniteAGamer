import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trust/models/uag_conduct_models.dart';

void main() {
  group('conduct and contract models', () {
    test('conduct reports require different users and useful detail', () {
      const report = UagConductReport(
        id: 'conduct-1',
        reporterUid: 'reporter',
        subjectUid: 'subject',
        type: UagConductReportType.scamAttempt,
        status: UagConductReportStatus.submitted,
        relatedTradeId: 'trade-1',
        description: 'Demanded items then left the trade.',
      );

      final restored = UagConductReport.fromMap(report.toMap());

      expect(restored.type, UagConductReportType.scamAttempt);
      expect(restored.hasContext, isTrue);
      expect(restored.isActionable, isTrue);
    });

    test('conduct reports are not actionable against self', () {
      const report = UagConductReport(
        id: 'conduct-2',
        reporterUid: 'same',
        subjectUid: 'same',
        type: UagConductReportType.other,
        status: UagConductReportStatus.submitted,
        description: 'This has enough detail but same participant.',
      );

      expect(report.isActionable, isFalse);
    });

    test('contracts require evidence before reward-ready state', () {
      const contract = UagCommunityContract(
        id: 'contract-1',
        ownerUid: 'owner',
        assigneeUid: 'assignee',
        status: UagCommunityContractStatus.evidenceSubmitted,
        objective: 'Guide a new raider through Spaceport extraction.',
        rewardSummary: 'Founder badge progress',
      );

      expect(contract.evidenceSatisfied, isFalse);
      expect(contract.canMarkRewardReady, isFalse);

      final withEvidence = UagCommunityContract.fromMap({
        ...contract.toMap(),
        'evidenceUrls': ['https://example.com/evidence'],
      });

      expect(withEvidence.evidenceSatisfied, isTrue);
      expect(withEvidence.canMarkRewardReady, isTrue);
      expect(withEvidence.hasParticipantConflict, isFalse);
    });
  });
}
