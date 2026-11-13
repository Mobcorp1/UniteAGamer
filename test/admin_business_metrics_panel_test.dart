import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/screens/build/admin_business_metrics_panel.dart';

void main() {
  group('AdminBusinessMetricsCalculator', () {
    test('calculates active users, revenue and session metrics', () {
      final now = DateTime.utc(2026, 8, 2, 12);
      final metrics = AdminBusinessMetricsCalculator.fromRaw(
        now: now,
        users: [
          {'uid': 'one', 'lastActiveAt': now.subtract(const Duration(days: 2))},
          {'uid': 'two', 'updatedAt': now.subtract(const Duration(days: 60))},
          {
            'uid': 'three',
            'profileCompletion': {
              'updatedAt': now.subtract(const Duration(days: 1)),
            },
          },
        ],
        revenueEvents: const [
          {'grossPence': 1000},
          {'eventName': 'rewarded_ad', 'grossPence': 250},
          {'adRevenuePence': 75},
        ],
        telemetrySummaries: [
          {
            'uid': 'one',
            'sessionsStarted': 3,
            'totalSessionSeconds': 600,
            'sessionDurationSamples': 3,
            'lastSessionStartedAt': now.subtract(const Duration(days: 1)),
          },
          {
            'uid': 'three',
            'sessionsStarted': 1,
            'totalSessionSeconds': 120,
            'sessionDurationSamples': 1,
            'lastSessionStartedAt': now.subtract(const Duration(hours: 4)),
          },
        ],
      );

      expect(metrics.totalUsers, 3);
      expect(metrics.monthlyActiveUsers, 2);
      expect(metrics.grossRevenuePence, 1250);
      expect(metrics.adRevenuePence, 325);
      expect(metrics.revenuePerActiveUserPence, 625);
      expect(metrics.lifetimeValuePence, 417);
      expect(metrics.totalSessions, 4);
      expect(metrics.averageSessionTime, const Duration(minutes: 3));
      expect(metrics.sessionsPerActiveUser, 2.0);
    });

    test(
      'falls back to login events when session starts are not tracked yet',
      () {
        final metrics = AdminBusinessMetricsCalculator.fromRaw(
          now: DateTime.utc(2026, 8, 2),
          users: const [
            {'uid': 'one', 'lastActiveAt': '2026-08-01T12:00:00Z'},
          ],
          revenueEvents: const [],
          telemetrySummaries: const [
            {'uid': 'one', 'loginEvents': 5},
          ],
        );

        expect(metrics.monthlyActiveUsers, 1);
        expect(metrics.totalSessions, 5);
        expect(metrics.sessionsPerActiveUser, 5.0);
        expect(metrics.averageSessionTime, Duration.zero);
      },
    );
  });
}
