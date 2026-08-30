import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'web update manager validates JSON and preserves Firebase Messaging worker',
    () {
      final source = File('web/uag_update_manager.js').readAsStringSync();
      expect(source, contains("application/json"));
      expect(source, contains("flutter_service_worker"));
      expect(
        source,
        isNot(
          contains(
            "if (registration.scope.startsWith(window.location.origin)) {\n"
            "          removed = (await registration.unregister()) || removed;",
          ),
        ),
      );
    },
  );

  test('web deploy writes deterministic release metadata', () {
    final deploy = File('scripts/deploy_web_release.ps1').readAsStringSync();
    final helper = File(
      'scripts/write_web_release_metadata.ps1',
    ).readAsStringSync();

    expect(deploy, contains('UAG_GIT_COMMIT'));
    expect(deploy, contains('UAG_BUILD_TIMESTAMP'));
    expect(deploy, contains('write_web_release_metadata.ps1'));
    expect(helper, contains(r'$env:UAG_BUILD_ID = $buildId'));
    expect(helper, contains('Generated buildId does not match HEAD'));
  });

  test('release candidate hosting path also creates version metadata', () {
    final source = File(
      'scripts/deploy_release_candidate.ps1',
    ).readAsStringSync();
    expect(source, contains('write_web_release_metadata.ps1'));
    expect(source, contains(r'build\web\version.json'));
  });

  test('Firebase hosting prevents stale version metadata', () {
    final firebase = File('firebase.json').readAsStringSync();
    expect(firebase, contains('"/version.json"'));
    expect(firebase, contains('no-cache, no-store, must-revalidate'));
  });
}
