import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('Ad service singleton is safe before Firebase bootstrap', () {
    final service = read('lib/features/monetisation/ads/uag_ad_service.dart');
    expect(
      service,
      contains(
        'late final UagEntitlementService _entitlements = UagEntitlementService();',
      ),
    );
    expect(
      service,
      contains('late final UagAdSettingsRepository _settingsRepository ='),
    );
    expect(service, contains('bool get canShowBanner =>'));
  });

  test('Shared ARC shell keeps sponsor lane outside working content', () {
    final shell = read(
      'lib/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart',
    );
    expect(shell, contains('return DecoratedBox('));
    expect(shell, contains('Expanded(child: content)'));
    expect(shell, contains('BoxConstraints(maxHeight: 76)'));
    expect(shell, contains('ArcAdBannerCard('));
  });
}
