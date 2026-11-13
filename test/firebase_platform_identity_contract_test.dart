import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Firebase platform identities remain aligned', () {
    final firebaseOptions = File(
      'lib/firebase_options.dart',
    ).readAsStringSync();
    final androidGradle = File(
      'android/app/build.gradle.kts',
    ).readAsStringSync();
    final iosProject = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();

    expect(
      androidGradle,
      contains('applicationId = "com.mobcorp.uagtradershub"'),
    );
    expect(firebaseOptions, contains("iosBundleId: 'com.example.uniteAGamer'"));
    expect(
      iosProject,
      contains('PRODUCT_BUNDLE_IDENTIFIER = com.example.uniteAGamer;'),
    );
    expect(
      iosProject,
      isNot(contains('PRODUCT_BUNDLE_IDENTIFIER = com.example.uagTradersHub;')),
    );
  });

  test('Firebase Dynamic Links are absent from the application contract', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final firebaseOptions = File(
      'lib/firebase_options.dart',
    ).readAsStringSync();

    expect(pubspec, isNot(contains('firebase_dynamic_links')));
    expect(firebaseOptions, isNot(contains('.page.link')));
  });
}
