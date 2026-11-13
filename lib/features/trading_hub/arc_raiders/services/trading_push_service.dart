import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uag_arc_raiders_hub/features/notifications/data/uag_notification_repository.dart';
import 'package:uag_arc_raiders_hub/features/notifications/models/uag_notification_models.dart';
import 'package:uag_arc_raiders_hub/features/notifications/models/uag_session_schedule_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_command_centre_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_listings_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_my_offers_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_notifications_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_trade_sessions_screen.dart';

@pragma('vm:entry-point')
Future<void> tradingFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  // Keep background handling lightweight. Routing happens when the user opens the app.
}

@pragma('vm:entry-point')
void onDidReceiveNotificationResponse(NotificationResponse response) {
  TradingPushService.instance.handleNotificationPayload(response.payload);
}

class TradingPushService {
  TradingPushService._();

  static final TradingPushService instance = TradingPushService._();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final UagNotificationRepository _notificationRepository =
      UagNotificationRepository();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'trading_alerts',
    'UAG Alerts',
    description: 'Announcements, offers, sessions, rewards and match alerts.',
    importance: Importance.high,
  );
  static const String _installationIdKey = 'uag_notification_installation_id';

  bool _initialized = false;
  String? _lastUid;
  String? _lastDeviceId;
  String? _lastToken;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(
      tradingFirebaseMessagingBackgroundHandler,
    );

    if (!kIsWeb) {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const initSettings = InitializationSettings(android: androidSettings);
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);

      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    }

    await registerCurrentDevice();
    _messaging.onTokenRefresh.listen((token) async {
      await _saveTokenValue(token);
    });

    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        await _disableLastDevice();
        return;
      }
      _lastUid = user.uid;
      await registerCurrentDevice();
    });

    FirebaseMessaging.onMessage.listen((message) async {
      if (kIsWeb) return;

      final title =
          message.notification?.title ??
          (message.data['title']?.toString() ?? 'Trading update');
      final body =
          message.notification?.body ??
          (message.data['body']?.toString() ?? 'Open the app for details.');

      await _localNotifications.show(
        title.hashCode ^ body.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'trading_alerts',
            'UAG Alerts',
            channelDescription:
                'Announcements, offers, sessions, rewards and match alerts.',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      handleMessage(message);
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      handleMessage(initialMessage);
    }
  }

  void handleMessage(RemoteMessage message) {
    _navigateFromData(message.data);
  }

  void handleNotificationPayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) {
      _openRoute(TradingNotificationsScreen.routeName);
      return;
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        _navigateFromData(decoded);
        return;
      }
      if (decoded is Map) {
        _navigateFromData(
          decoded.map(
            (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
          ),
        );
        return;
      }
    } catch (_) {
      // Fall back to notifications inbox below.
    }

    _openRoute(TradingNotificationsScreen.routeName);
  }

  void _navigateFromData(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString();
    final route = (data['route'] ?? data['deepLink'] ?? '').toString().trim();
    if (route.startsWith('/')) {
      _openRoute(route);
      return;
    }

    if (type == 'announcement' ||
        type == 'open_beta' ||
        type == 'maintenance' ||
        type == 'operations' ||
        type == 'reward' ||
        type == 'community_event') {
      _openRoute(ArcCommandCentreScreen.routeName);
      return;
    }

    if (type == 'offerReceived' ||
        type == 'offerAccepted' ||
        type == 'offerDeclined' ||
        type == 'offerCancelled') {
      _openRoute(TradingMyOffersScreen.routeName);
      return;
    }

    if (type == 'duplicateMatch' || type == 'mutualMatch') {
      _openRoute(TradingListingsScreen.routeName);
      return;
    }

    if (type == 'tradeReminder') {
      _openRoute(TradingTradeSessionsScreen.routeName);
      return;
    }

    if ((data['sessionId'] ?? '').toString().isNotEmpty ||
        type == 'sessionCreated' ||
        type == 'sessionUpdated' ||
        type == 'sessionReady' ||
        type == 'sessionOutcome') {
      _openRoute(TradingTradeSessionsScreen.routeName);
      return;
    }

    _openRoute(TradingNotificationsScreen.routeName);
  }

  void _openRoute(String routeName) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    navigator.pushNamed(routeName);
  }

  Future<void> scheduleTradeReminder({
    required String sessionId,
    required DateTime scheduledAt,
    required String otherTraderName,
    DateTime? scheduledEndAt,
    String listingId = '',
    String offerId = '',
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final endAt = scheduledEndAt ?? scheduledAt.add(const Duration(hours: 1));
    final plan = const UagSessionSchedulePlanner().notificationPlan(
      sessionId: sessionId,
      kind: UagSessionScheduleKind.trade,
      targetUid: uid,
      startAt: scheduledAt,
      duration: endAt.difference(scheduledAt),
      route: TradingTradeSessionsScreen.routeName,
      deepLink: TradingTradeSessionsScreen.routeName,
      otherParticipantName: otherTraderName,
      listingId: listingId,
      offerId: offerId,
    );

    for (final schedule in plan.schedules) {
      await _notificationRepository.createSchedule(schedule);
    }
  }

  Future<UagNotificationRuntimeStatus> runtimeStatus() async {
    final settings = await _messaging.getNotificationSettings();
    final installationId = await _installationId();
    final deviceId = _deviceIdFor(installationId);
    return UagNotificationRuntimeStatus(
      permissionStatus: settings.authorizationStatus.name,
      platform: _platformName(),
      deviceId: deviceId,
      hasWebVapidKey:
          !kIsWeb ||
          const String.fromEnvironment('UAG_WEB_PUSH_VAPID_KEY').isNotEmpty,
      lastTokenRegistered: _lastToken?.trim().isNotEmpty == true,
    );
  }

  Future<void> enableNotificationsFromUserAction() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    await registerCurrentDevice(explicitUserAction: true);
  }

  Future<bool> showLocalTestNotification() async {
    if (kIsWeb) return false;
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'UAG notification test',
      'Android notifications are ready on this device.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'trading_alerts',
          'UAG Alerts',
          channelDescription:
              'Announcements, offers, sessions, rewards and match alerts.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: jsonEncode(<String, dynamic>{
        'type': UagNotificationType.announcement.wireName,
        'route': ArcCommandCentreScreen.routeName,
      }),
    );
    return true;
  }

  Future<void> registerCurrentDevice({bool explicitUserAction = false}) async {
    await _saveCurrentToken(explicitUserAction: explicitUserAction);
  }

  Future<void> _saveCurrentToken({bool explicitUserAction = false}) async {
    final token = await _getToken(explicitUserAction: explicitUserAction);
    if (token == null || token.trim().isEmpty) return;
    await _saveTokenValue(token);
  }

  Future<String?> _getToken({bool explicitUserAction = false}) async {
    if (kIsWeb) {
      if (const String.fromEnvironment('UAG_WEB_PUSH_VAPID_KEY').isEmpty) {
        return null;
      }
      if (!explicitUserAction) {
        final settings = await _messaging.getNotificationSettings();
        if (settings.authorizationStatus != AuthorizationStatus.authorized) {
          return null;
        }
      }
      return FirebaseMessaging.instance.getToken(
        vapidKey: const String.fromEnvironment('UAG_WEB_PUSH_VAPID_KEY'),
      );
    }
    return _messaging.getToken();
  }

  Future<void> _saveTokenValue(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || token.trim().isEmpty) return;

    final settings = await _messaging.getNotificationSettings();
    final preferences = await _notificationRepository.loadPreferences(uid: uid);
    final installationId = await _installationId();
    final deviceId = _deviceIdFor(installationId);
    final authorized =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    final device = UagNotificationDevice(
      deviceId: deviceId,
      token: token.trim(),
      userId: uid,
      platform: _platformName(),
      enabled: authorized,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastSeenAt: DateTime.now(),
      installationId: installationId,
      appVersion: '1.0.0+1',
      preferences: preferences,
      permissionStatus: settings.authorizationStatus.name,
      tokenValid: true,
    );

    await _notificationRepository.saveDeviceRegistration(device);
    _lastUid = uid;
    _lastDeviceId = deviceId;
    _lastToken = token.trim();
  }

  Future<void> _disableLastDevice() async {
    final uid = _lastUid;
    final deviceId = _lastDeviceId;
    if (uid == null || deviceId == null) return;
    await _notificationRepository.disableDevice(
      uid: uid,
      deviceId: deviceId,
      token: _lastToken ?? '',
    );
    _lastUid = null;
    _lastDeviceId = null;
    _lastToken = null;
  }

  Future<String> _installationId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_installationIdKey);
    if (existing != null && existing.trim().isNotEmpty) return existing;
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final generated = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    await prefs.setString(_installationIdKey, generated);
    return generated;
  }

  String _deviceIdFor(String installationId) {
    return '${_platformName()}_$installationId';
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }
}

class UagNotificationRuntimeStatus {
  const UagNotificationRuntimeStatus({
    required this.permissionStatus,
    required this.platform,
    required this.deviceId,
    required this.hasWebVapidKey,
    required this.lastTokenRegistered,
  });

  final String permissionStatus;
  final String platform;
  final String deviceId;
  final bool hasWebVapidKey;
  final bool lastTokenRegistered;
}
