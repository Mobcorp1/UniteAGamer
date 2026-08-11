import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('classified user-facing Raider terminology has no legacy Rider copy', () {
    const forbidden = <String>[
      'Favourite Riders',
      'Favourite Rider',
      'Match Rider',
      'Nomadic Rider',
      'Private Riders',
      'Rider Signal',
    ];

    const roots = <String>['lib', 'test', 'integration_test'];
    final offenders = <String>[];

    for (final rootName in roots) {
      final root = Directory(rootName);
      if (!root.existsSync()) continue;

      for (final entity in root.listSync(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        final path = entity.path.replaceAll('\\', '/');
        if (path.endsWith(
          '/raider_terminology_user_facing_regression_test.dart',
        )) {
          continue;
        }
        if (!path.endsWith('.dart') &&
            !path.endsWith('.md') &&
            !path.endsWith('.txt') &&
            !path.endsWith('.yaml') &&
            !path.endsWith('.yml') &&
            !path.endsWith('.json')) {
          continue;
        }

        final content = entity.readAsStringSync();
        for (final term in forbidden) {
          if (content.contains(term)) {
            offenders.add('$path contains "$term"');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Legacy user-facing Rider terminology remains:\n${offenders.join('\n')}',
    );
  });
}
