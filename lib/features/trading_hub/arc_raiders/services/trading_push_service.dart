import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_listings_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_my_offers_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_notifications_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_trade_sessions_screen.dart';

@pragma('vm:entry-point')
Future<void> tradingFirebaseMessagingBackgroundHandler(RemoteMessage message) async {
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

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'trading_alerts',
    'Trading Alerts',
    description: 'Offer, session, booking and match notifications.',
    importance: Importance.high,
  );

  bool _initialized = false;

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
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _saveCurrentToken();
    _messaging.onTokenRefresh.listen(_saveTokenValue);

    FirebaseAuth.instance.authStateChanges().listen((_) async {
      await _saveCurrentToken();
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
            'Trading Alerts',
            channelDescription:
                'Offer, session, booking and match notifications.',
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
        _navigateFromData(decoded.map(
          (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
        ));
        return;
      }
    } catch (_) {
      // Fall back to notifications inbox below.
    }

    _openRoute(TradingNotificationsScreen.routeName);
  }

  void _navigateFromData(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString();

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

  Future<void> _saveCurrentToken() async {
    final token = await _messaging.getToken();
    if (token == null || token.trim().isEmpty) return;
    await _saveTokenValue(token);
  }

  Future<void> _saveTokenValue(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || token.trim().isEmpty) return;

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notification_tokens')
        .doc(token);

    await ref.set({
      'token': token,
      'platform': defaultTargetPlatform.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
