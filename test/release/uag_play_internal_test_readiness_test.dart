import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Google Play internal/closed test readiness', () {
    test('Android release signing never reuses the debug key', () {
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();

      expect(gradle, contains('applicationId = "com.mobcorp.uagtradershub"'));
      expect(gradle, isNot(contains('signingConfigs.getByName("debug")')));
      expect(gradle, contains('UAG_ANDROID_STORE_FILE'));
      expect(gradle, contains('UAG_ANDROID_STORE_PASSWORD'));
      expect(gradle, contains('UAG_ANDROID_KEY_ALIAS'));
      expect(gradle, contains('UAG_ANDROID_KEY_PASSWORD'));
      expect(gradle, contains('Android release signing is not configured'));
    });

    test('local signing secrets remain ignored by Git', () {
      final ignore = File('android/.gitignore').readAsStringSync();

      expect(ignore, contains('key.properties'));
      expect(ignore, contains('**/*.keystore'));
      expect(ignore, contains('**/*.jks'));
      expect(File('android/key.properties.example').existsSync(), isTrue);
    });

    test('Play bundle script builds AAB without publishing', () {
      final script = File(
        'scripts/build_play_internal_test.ps1',
      ).readAsStringSync();

      expect(script, contains('-RequireAndroidReleaseSigning'));
      expect(script, contains('flutter build appbundle --release'));
      expect(
        script,
        contains('build\\app\\outputs\\bundle\\release\\app-release.aab'),
      );
      expect(script, contains('No Google Play upload was performed.'));
      expect(script, isNot(contains('firebase deploy')));
      expect(script, isNot(contains('git push')));
      expect(script, isNot(contains('dart format')));
      expect(script, contains('flutter analyze'));
      expect(script, contains('flutter test'));
    });

    test('release candidate script supports signed App Bundle builds', () {
      final deploy = File(
        'scripts/deploy_release_candidate.ps1',
      ).readAsStringSync();
      final validate = File(
        'scripts/validate_release_environment.ps1',
      ).readAsStringSync();

      expect(deploy, contains(r'$BuildAndroidAppBundle'));
      expect(deploy, contains('flutter build appbundle --release'));
      expect(validate, contains(r'$RequireAndroidReleaseSigning'));
      expect(validate, contains('Assert-AndroidReleaseSigning'));
    });

    test(
      'Play signing fingerprint helper is package-scoped and never deploys',
      () {
        final script = File(
          'scripts/set_play_app_signing_fingerprint.ps1',
        ).readAsStringSync();

        expect(script, contains('com.mobcorp.uagtradershub'));
        expect(script, contains('sha256_cert_fingerprints'));
        expect(script, contains('App signing key certificate'));
        expect(script, isNot(contains('firebase deploy')));
      },
    );

    test(
      'iOS identity is intentionally preserved until Firebase registration',
      () {
        final firebaseOptions = File(
          'lib/firebase_options.dart',
        ).readAsStringSync();
        final iosProject = File(
          'ios/Runner.xcodeproj/project.pbxproj',
        ).readAsStringSync();

        expect(
          firebaseOptions,
          contains("iosBundleId: 'com.example.uniteAGamer'"),
        );
        expect(
          iosProject,
          contains('PRODUCT_BUNDLE_IDENTIFIER = com.example.uniteAGamer;'),
        );
      },
    );
  });
}
