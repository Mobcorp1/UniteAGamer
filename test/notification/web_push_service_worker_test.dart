import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('web push service worker', () {
    test('uses FlutterFire-compatible compat scripts without a BOM', () {
      final workerFile = File('web/firebase-messaging-sw.js');
      final bytes = workerFile.readAsBytesSync();
      final worker = utf8.decode(bytes);

      expect(worker.startsWith('\uFEFF'), isFalse);
      expect(worker.startsWith('const firebaseSdkVersion'), isTrue);
      expect(worker, contains("const firebaseSdkVersion = '12.15.0';"));
      expect(
        worker,
        contains('/__/firebase/\${firebaseSdkVersion}/firebase-app-compat.js'),
      );
      expect(
        worker,
        contains(
          '/__/firebase/\${firebaseSdkVersion}/firebase-messaging-compat.js',
        ),
      );
      expect(
        worker,
        contains(
          'https://www.gstatic.com/firebasejs/\${firebaseSdkVersion}/firebase-app-compat.js',
        ),
      );
      expect(
        worker,
        contains(
          'https://www.gstatic.com/firebasejs/\${firebaseSdkVersion}/firebase-messaging-compat.js',
        ),
      );
      expect(worker, contains('firebase.messaging()'));
      expect(worker, isNot(contains('firebasejs/10.')));
      expect(worker, isNot(contains('import {')));
    });

    test('publishes explicit Firebase Messaging worker hosting headers', () {
      final config =
          jsonDecode(File('firebase.json').readAsStringSync())
              as Map<String, dynamic>;
      final hosting = config['hosting'] as Map<String, dynamic>;
      final headers = (hosting['headers'] as List)
          .whereType<Map>()
          .map((entry) => entry.cast<String, dynamic>())
          .toList();
      final messagingWorker = headers.singleWhere(
        (entry) => entry['source'] == '/firebase-messaging-sw.js',
      );
      final workerHeaders = ((messagingWorker['headers'] as List)
          .whereType<Map>()
          .map((entry) => entry.cast<String, dynamic>()));
      final values = <String, String>{
        for (final header in workerHeaders)
          header['key'].toString(): header['value'].toString(),
      };

      expect(values['Cache-Control'], 'no-cache, no-store, must-revalidate');
      expect(values['Service-Worker-Allowed'], '/');
    });
  });
}
