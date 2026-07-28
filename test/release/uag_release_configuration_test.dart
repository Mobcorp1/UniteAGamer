import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('release Firebase configuration', () {
    test('declares Storage rules target', () {
      final config =
          jsonDecode(File('firebase.json').readAsStringSync())
              as Map<String, dynamic>;

      expect(config['storage'], isA<Map<String, dynamic>>());
      expect(
        (config['storage'] as Map<String, dynamic>)['rules'],
        'storage.rules',
      );
      expect(File('storage.rules').existsSync(), isTrue);
    });

    test('does not include rejected single-field coverage report index', () {
      final indexes =
          jsonDecode(File('firestore.indexes.json').readAsStringSync())
              as Map<String, dynamic>;
      final compositeIndexes = (indexes['indexes'] as List).cast<Map>();

      expect(
        compositeIndexes.any(
          (index) =>
              index['collectionGroup'] == 'arc_map_marker_coverage_reports',
        ),
        isFalse,
      );
    });

    test(
      'release scripts are present and require explicit deploy switches',
      () {
        final deployScript = File(
          'scripts/deploy_release_candidate.ps1',
        ).readAsStringSync();
        final validateScript = File(
          'scripts/validate_release_environment.ps1',
        ).readAsStringSync();

        expect(validateScript, contains('RequireJava21'));
        expect(
          validateScript,
          contains('Firebase emulator tests require Java 21'),
        );
        expect(deployScript, contains('DeployHosting'));
        expect(deployScript, contains('DeployFirestoreRules'));
        expect(deployScript, contains('DeployFirestoreIndexes'));
        expect(deployScript, contains('DeployStorageRules'));
        expect(deployScript, contains('DeployFunctions'));
        expect(deployScript, contains('does not push automatically'));
      },
    );

    test('Storage rules protect evidence and reject executable names', () {
      final rules = File('storage.rules').readAsStringSync();

      expect(rules, contains('conduct_evidence'));
      expect(rules, contains('message_evidence'));
      expect(rules, contains('contract_evidence'));
      expect(rules, contains('legal_exports'));
      expect(rules, contains('ageVerification.verifiedOver18 == true'));
      expect(rules, contains('exe|bat|cmd|com|scr|js|jar|ps1|sh|php|html|svg'));
      expect(rules, contains('allow read, write: if false'));
    });
  });
}
