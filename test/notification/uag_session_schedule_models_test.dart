import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/notifications/models/uag_notification_models.dart';
import 'package:uag_arc_raiders_hub/features/notifications/models/uag_session_schedule_models.dart';

void main() {
  group('UAG session schedule planner', () {
    const planner = UagSessionSchedulePlanner();
    final startAt = DateTime.utc(2026, 8, 1, 19, 30);

    test('creates pre-session and post-session feedback schedules', () {
      final plan = planner.notificationPlan(
        sessionId: 'session-1',
        kind: UagSessionScheduleKind.trade,
        targetUid: 'user-a',
        startAt: startAt,
        route: '/trading-hub/arc-raiders/sessions',
        deepLink: '/trading-hub/arc-raiders/sessions',
        otherParticipantName: 'Raider B',
        listingId: 'listing-1',
        offerId: 'offer-1',
      );

      expect(plan.schedules, hasLength(2));
      expect(plan.preSession.type, UagNotificationType.reminder);
      expect(
        plan.preSession.dueAt,
        startAt.subtract(const Duration(minutes: 15)),
      );
      expect(plan.preSession.priority, UagNotificationPriority.high);
      expect(plan.preSession.sessionId, 'session-1');
      expect(plan.preSession.listingId, 'listing-1');
      expect(plan.preSession.offerId, 'offer-1');
      expect(plan.preSession.route, '/trading-hub/arc-raiders/sessions');

      expect(
        plan.postSessionFeedback.type,
        UagNotificationType.postSessionFeedback,
      );
      expect(
        plan.postSessionFeedback.dueAt,
        startAt.add(const Duration(hours: 1, minutes: 15)),
      );
      expect(
        plan.postSessionFeedback.metadata['recommendedAction'],
        'confirm_trade_outcome',
      );
      expect(plan.postSessionFeedback.body, contains('no-show'));
    });

    test('uses deterministic ids to prevent duplicates when rescheduled', () {
      final original = planner.notificationPlan(
        sessionId: 'Session/One',
        kind: UagSessionScheduleKind.trade,
        targetUid: 'User/A',
        startAt: startAt,
        route: '/sessions',
      );
      final rescheduled = planner.notificationPlan(
        sessionId: 'Session/One',
        kind: UagSessionScheduleKind.trade,
        targetUid: 'User/A',
        startAt: startAt.add(const Duration(hours: 2)),
        route: '/sessions',
      );

      expect(rescheduled.preSession.id, original.preSession.id);
      expect(
        rescheduled.postSessionFeedback.id,
        original.postSessionFeedback.id,
      );
      expect(
        rescheduled.preSession.dueAt,
        original.preSession.dueAt.add(const Duration(hours: 2)),
      );
      expect(
        rescheduled.postSessionFeedback.dueAt,
        original.postSessionFeedback.dueAt.add(const Duration(hours: 2)),
      );
      expect(original.preSession.id, isNot(contains('/')));
    });

    test('supports safe cancellation state for queued schedules', () {
      final plan = planner.notificationPlan(
        sessionId: 'session-1',
        kind: UagSessionScheduleKind.matchmaking,
        targetUid: 'user-a',
        startAt: startAt,
        route: '/match-rider',
      );

      final cancelled = plan.preSession.copyWith(
        status: 'cancelled',
        cancelledAt: DateTime.utc(2026, 8, 1, 18),
      );

      expect(cancelled.status, 'cancelled');
      expect(cancelled.cancelledAt, DateTime.utc(2026, 8, 1, 18));
      expect(cancelled.id, plan.preSession.id);
    });

    test('maps preferences for reminders and post-session feedback', () {
      const preferences = UagNotificationPreferences(
        reminders: false,
        postSessionFeedback: true,
      );

      expect(preferences.allowsType(UagNotificationType.reminder), isFalse);
      expect(
        preferences.allowsType(UagNotificationType.postSessionFeedback),
        isTrue,
      );
    });

    test('builds calendar payload with deep link and calendar exports', () {
      final payload = planner.calendarPayload(
        sessionId: 'session-1',
        kind: UagSessionScheduleKind.raid,
        startAt: startAt,
        route: '/raid-planner',
        deepLink: '/raid-planner',
        location: 'ARC Raiders',
        notes: 'Bring ammo and confirm squad voice.',
        participants: const [
          UagSessionParticipant(uid: 'user-a', displayName: 'Raider A'),
          UagSessionParticipant(
            uid: 'user-b',
            displayName: 'Raider B',
            embarkId: 'RaiderB#1234',
          ),
        ],
      );

      expect(payload.title, 'UAG Raid: Raider A + Raider B');
      expect(payload.endAt, startAt.add(const Duration(hours: 1)));
      expect(payload.description, contains('RaiderB#1234'));
      expect(payload.description, contains('/raid-planner'));
      expect(payload.googleCalendarUrl, contains('calendar.google.com'));
      expect(payload.googleCalendarUrl, contains('action=TEMPLATE'));
      expect(payload.icsText, contains('BEGIN:VCALENDAR'));
      expect(payload.icsText, contains('DTSTART:20260801T193000Z'));
      expect(payload.icsText, contains('TRIGGER:-PT15M'));
      expect(payload.icsText, contains('URL:/raid-planner'));
    });
  });
}
