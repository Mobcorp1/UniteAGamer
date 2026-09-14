import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String source(String path) => File(path).readAsStringSync();

  test(
    'drawer group and nav tile typography are lifted for mobile readability',
    () {
      final drawer = source('lib/build/app_drawer.dart');
      final tile = source('lib/widgets/uag_drawer_nav_tile.dart');

      expect(drawer, contains(".copyWith(fontSize: 12)"));
      expect(tile, contains('fontSize: 14,'));
      expect(tile, contains('.copyWith(height: 1.08)'));
      expect(
        tile,
        contains(
          'contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3)',
        ),
      );
    },
  );
}
