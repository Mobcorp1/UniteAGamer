import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/notifications/data/uag_notification_delivery_engine.dart';
import 'package:uag_arc_raiders_hub/features/notifications/models/uag_notification_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_notification.dart';

void main() {
  group('unified notification models', () {
    test(
      'serializes multiple device registrations without merging devices',
      () {
        final now = DateTime.utc(2026, 7, 20, 10);
        final android = UagNotificationDevice(
          deviceId: 'android_installation_a',
          token: 'token-a',
          userId: 'user-1',
          platform: 'android',
          enabled: true,
          createdAt: now,
          updatedAt: now,
          lastSeenAt: now,
          installationId: 'installation-a',
          permissionStatus: 'authorized',
        );
        final web = UagNotificationDevice(
          deviceId: 'web_installation_b',
          token: 'token-b',
          userId: 'user-1',
          platform: 'web',
          enabled: true,
          createdAt: now,
          updatedAt: now,
          lastSeenAt: now,
          installationId: 'installation-b',
          permissionStatus: 'granted',
        );

        expect(android.deviceId, isNot(web.deviceId));
        expect(UagNotificationDevice.fromMap(android.toMap()).token, 'token-a');
        expect(UagNotificationDevice.fromMap(web.toMap()).platform, 'web');
      },
    );

    test('payload parsing preserves routing, audience and metadata', () {
      const payload = UagNotificationPayload(
        id: 'broadcast-1',
        type: UagNotificationType.openBeta,
        title: 'Open Beta',
        body: 'Doors are open.',
        deepLink: '/my-hub',
        route: '/my-hub',
        entityId: 'open-beta',
        audience: UagNotificationAudience.allEligible,
        senderUid: 'admin-1',
        priority: UagNotificationPriority.high,
        metadata: {'source': 'admin'},
      );

      final restored = UagNotificationPayload.fromMap(payload.toMap());

      expect(restored.type, UagNotificationType.openBeta);
      expect(restored.route, '/my-hub');
      expect(restored.audience, UagNotificationAudience.allEligible);
      expect(restored.metadata['source'], 'admin');
      expect(restored.toPushData()['type'], 'open_beta');
    });

    test('trading inbox model accepts broadcast wire names', () {
      expect(
        tradingNotificationTypeFromWire('open_beta'),
        TradingNotificationType.openBeta,
      );
      expect(
        tradingNotificationTypeFromWire('post_session_feedback'),
        TradingNotificationType.postSessionFeedback,
      );
      expect(
        tradingNotificationTypeFromWire('community_event'),
        TradingNotificationType.communityEvent,
      );
    });

    test('new compliance and intel notification types obey preferences', () {
      const muted = UagNotificationPreferences(
        blueprintIntel: false,
        contractsAndReports: false,
        legalAndPolicy: false,
      );

      expect(
        UagNotificationType.fromWire('blueprint_report_confirmed'),
        UagNotificationType.blueprintReportConfirmed,
      );
      expect(
        UagNotificationType.fromWire('terms_privacy_update'),
        UagNotificationType.termsPrivacyUpdate,
      );
      expect(
        muted.allowsType(UagNotificationType.communityIntelConfirmation),
        isFalse,
      );
      expect(
        muted.allowsType(UagNotificationType.contractRewardReady),
        isFalse,
      );
      expect(
        muted.allowsType(UagNotificationType.conductReportOutcome),
        isFalse,
      );
      expect(muted.allowsType(UagNotificationType.termsPrivacyUpdate), isFalse);
      expect(muted.allowsType(UagNotificationType.openBeta), isTrue);
    });
  });

  group('unified notification delivery engine', () {
    const engine = UagNotificationDeliveryEngine();
    const payload = UagNotificationPayload(
      id: 'broadcast-1',
      type: UagNotificationType.openBeta,
      title: 'Open Beta',
      body: 'Doors are open.',
      audience: UagNotificationAudience.allEligible,
      senderUid: 'admin-1',
    );

    test('filters disabled, denied and preference-muted devices', () {
      final devices = [
        _device('a', 'token-a', permissionStatus: 'authorized'),
        _device('b', 'token-b', enabled: false),
        _device('c', 'token-c', permissionStatus: 'denied'),
        _device(
          'd',
          'token-d',
          preferences: const UagNotificationPreferences(openBetaUpdates: false),
        ),
      ];

      final eligible = engine.eligibleDevices(
        payload: payload,
        devices: devices,
      );

      expect(eligible.map((device) => device.deviceId), ['a']);
    });

    test('deduplicates token delivery across device records', () {
      final devices = [
        _device('a', 'same-token'),
        _device('b', 'same-token'),
        _device('c', 'other-token'),
      ];

      final eligible = engine.eligibleDevices(
        payload: payload,
        devices: devices,
      );

      expect(eligible.map((device) => device.token), [
        'same-token',
        'other-token',
      ]);
    });

    test('applies platform and specific-user audiences', () {
      final devices = [
        _device('a', 'token-a', platform: 'android', userId: 'user-1'),
        _device('b', 'token-b', platform: 'web', userId: 'user-2'),
      ];

      final androidOnly = engine.eligibleDevices(
        payload: const UagNotificationPayload(
          id: 'broadcast-2',
          type: UagNotificationType.announcement,
          title: 'Android',
          body: 'Android only',
          audience: UagNotificationAudience.android,
          senderUid: 'admin-1',
        ),
        devices: devices,
      );
      final specific = engine.eligibleDevices(
        payload: const UagNotificationPayload(
          id: 'broadcast-3',
          type: UagNotificationType.announcement,
          title: 'Target',
          body: 'Specific user',
          audience: UagNotificationAudience.specificUser,
          senderUid: 'admin-1',
        ),
        devices: devices,
        specificTargetUid: 'user-2',
      );

      expect(androidOnly.single.deviceId, 'a');
      expect(specific.single.deviceId, 'b');
    });

    test('protects broadcast validation and idempotency', () {
      final invalid = engine.validateBroadcast(
        payload: const UagNotificationPayload(
          id: 'broadcast-4',
          type: UagNotificationType.announcement,
          title: '',
          body: '',
          audience: UagNotificationAudience.allEligible,
          senderUid: 'user-1',
        ),
        senderIsAdmin: false,
        sendPush: false,
        createInApp: false,
      );

      expect(invalid.isValid, isFalse);
      expect(invalid.errors.length, greaterThanOrEqualTo(3));
      expect(engine.shouldProcessBroadcastStatus('queued'), isTrue);
      expect(engine.shouldProcessBroadcastStatus('sent'), isFalse);
    });

    test('classifies invalid FCM tokens for cleanup', () {
      expect(
        engine.isInvalidFcmTokenError(
          'messaging/registration-token-not-registered',
        ),
        isTrue,
      );
      expect(
        engine.isInvalidFcmTokenError('messaging/invalid-registration-token'),
        isTrue,
      );
      expect(
        engine.isInvalidFcmTokenError('messaging/internal-error'),
        isFalse,
      );
    });

    test('open beta preset is editable and routes to Command Centre', () {
      final preset = engine.openBetaPreset(
        id: 'broadcast-5',
        senderUid: 'admin-1',
      );

      expect(preset.type, UagNotificationType.openBeta);
      expect(preset.title, contains('Open Beta'));
      expect(preset.route, '/my-hub');
      expect(preset.priority, UagNotificationPriority.high);
    });
  });
}

UagNotificationDevice _device(
  String deviceId,
  String token, {
  String userId = 'user-1',
  String platform = 'android',
  bool enabled = true,
  String permissionStatus = 'authorized',
  UagNotificationPreferences preferences = UagNotificationPreferences.defaults,
}) {
  return UagNotificationDevice(
    deviceId: deviceId,
    token: token,
    userId: userId,
    platform: platform,
    enabled: enabled,
    createdAt: DateTime.utc(2026, 7, 20),
    updatedAt: DateTime.utc(2026, 7, 20),
    lastSeenAt: DateTime.utc(2026, 7, 20),
    installationId: '$deviceId-install',
    preferences: preferences,
    permissionStatus: permissionStatus,
  );
}
