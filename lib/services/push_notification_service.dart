
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init() async {
    await _fcm.requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // handle foreground
    });

    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
  }

  static Future<void> _backgroundHandler(RemoteMessage message) async {}
}
