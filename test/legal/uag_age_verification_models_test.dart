import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/legal/models/uag_age_verification_models.dart';

void main() {
  group('UagAgeVerificationPolicy', () {
    const policy = UagAgeVerificationPolicy();

    test('accepts users who are 18 or older', () {
      final decision = policy.evaluate(
        dateOfBirthIso: '2008-07-28T00:00:00.000Z',
        now: DateTime.utc(2026, 7, 28),
      );

      expect(decision.status, UagAgeVerificationStatus.accepted);
      expect(decision.verifiedOver18, isTrue);
      expect(decision.ageYears, 18);
    });

    test('rejects under-18 and invalid dates safely', () {
      final under18 = policy.evaluate(
        dateOfBirthIso: '2009-07-29T00:00:00.000Z',
        now: DateTime.utc(2026, 7, 28),
      );
      final invalid = policy.evaluate(
        dateOfBirthIso: 'not-a-date',
        now: DateTime.utc(2026, 7, 28),
      );

      expect(under18.status, UagAgeVerificationStatus.rejected);
      expect(under18.verifiedOver18, isFalse);
      expect(invalid.status, UagAgeVerificationStatus.rejected);
      expect(invalid.reason, contains('invalid'));
    });

    test('serializes pending requests without trusting verified fields', () {
      const request = UagAgeVerificationRequest(
        id: 'age-1',
        uid: 'user-1',
        dateOfBirthIso: '2000-01-01T00:00:00.000Z',
        status: UagAgeVerificationStatus.pending,
      );

      final map = request.toCreateMap();
      final restored = UagAgeVerificationRequest.fromMap(map);

      expect(map['status'], 'pending');
      expect(map.containsKey('verifiedOver18'), isFalse);
      expect(restored.status, UagAgeVerificationStatus.pending);
    });
  });
}
