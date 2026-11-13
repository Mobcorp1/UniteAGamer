import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app scroll behavior does not force shared-controller scrollbar', () {
    final source = File(
      'lib/widgets/arc_app_scroll_behavior.dart',
    ).readAsStringSync();
    expect(source, contains('if (!desktop || details.controller == null)'));
    expect(source, isNot(contains('TargetPlatform.android')));
  });

  test('Map Editor exposes dedicated extraction placement', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_admin_map_editor_screen.dart',
    ).readAsStringSync();
    expect(source, contains("key: const Key('admin-map-add-extraction')"));
    expect(source, contains('ArcAdminMapMarkerKind.extraction'));
  });
}
