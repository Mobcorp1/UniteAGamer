import 'package:uag_arc_raiders_hub/features/notifications/data/uag_personalised_notification_mapper.dart';
import 'package:uag_arc_raiders_hub/features/notifications/models/uag_notification_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_user_personalisation_profile.dart';

class UagNotificationDeliveryEngine {
  const UagNotificationDeliveryEngine();

  List<UagNotificationDevice> eligibleDevices({
    required UagNotificationPayload payload,
    required Iterable<UagNotificationDevice> devices,
    String specificTargetUid = '',
    ArcUserPersonalisationProfile? personalisation,
  }) {
    final seenTokens = <String>{};
    final output = <UagNotificationDevice>[];

    for (final device in devices) {
      final token = device.token.trim();
      if (token.isEmpty || !seenTokens.add(token)) continue;
      if (!isEligibleDevice(
        payload: payload,
        device: device,
        specificTargetUid: specificTargetUid,
        personalisation: personalisation,
      )) {
        continue;
      }
      output.add(device);
    }

    return output;
  }

  bool isEligibleDevice({
    required UagNotificationPayload payload,
    required UagNotificationDevice device,
    String specificTargetUid = '',
    ArcUserPersonalisationProfile? personalisation,
  }) {
    if (!device.enabled || !device.hasUsableToken) return false;
    if (!_hasNotificationPermission(device.permissionStatus)) return false;

    switch (payload.audience) {
      case UagNotificationAudience.android:
        if (device.platform != 'android') return false;
        break;
      case UagNotificationAudience.web:
        if (device.platform != 'web') return false;
        break;
      case UagNotificationAudience.specificUser:
        if (specificTargetUid.trim().isEmpty ||
            device.userId != specificTargetUid.trim()) {
          return false;
        }
        break;
      case UagNotificationAudience.subscribedByPreference:
      case UagNotificationAudience.allEligible:
      case UagNotificationAudience.closedBetaUsers:
      case UagNotificationAudience.openBetaUsers:
        break;
    }

    if (!device.preferences.allowsType(payload.type)) return false;
    if (personalisation == null) return true;
    return UagPersonalisedNotificationMapper.allowsType(
      type: payload.type,
      personalisation: personalisation,
    );
  }

  UagBroadcastValidationResult validateBroadcast({
    required UagNotificationPayload payload,
    required bool senderIsAdmin,
    required bool sendPush,
    required bool createInApp,
  }) {
    final errors = <String>[];
    if (!senderIsAdmin) errors.add('Admin privileges are required.');
    if (payload.title.trim().isEmpty) errors.add('Title is required.');
    if (payload.body.trim().isEmpty) errors.add('Body is required.');
    if (!sendPush && !createInApp) {
      errors.add('Select at least one delivery channel.');
    }
    if (payload.expiresAt != null &&
        payload.expiresAt!.isBefore(DateTime.now())) {
      errors.add('Expiry must be in the future.');
    }
    return UagBroadcastValidationResult(errors);
  }

  bool shouldProcessBroadcastStatus(String status) {
    return status.trim().toLowerCase() == 'queued';
  }

  bool isInvalidFcmTokenError(String code) {
    return code == 'messaging/registration-token-not-registered' ||
        code == 'messaging/invalid-registration-token';
  }

  UagNotificationPayload openBetaPreset({
    required String id,
    required String senderUid,
    String route = '/my-hub',
  }) {
    return UagNotificationPayload(
      id: id,
      type: UagNotificationType.openBeta,
      title: 'UAG ARC Raiders Hub Open Beta Is Live',
      body:
          'The open beta is now live. Update or open the UAG ARC Raiders Hub and join the community.',
      audience: UagNotificationAudience.allEligible,
      senderUid: senderUid,
      route: route,
      deepLink: route,
      priority: UagNotificationPriority.high,
    );
  }

  bool _hasNotificationPermission(String status) {
    final normalized = status.trim().toLowerCase();
    return normalized == 'authorized' ||
        normalized == 'granted' ||
        normalized == 'provisional';
  }
}

class UagBroadcastValidationResult {
  const UagBroadcastValidationResult(this.errors);

  final List<String> errors;

  bool get isValid => errors.isEmpty;
}
