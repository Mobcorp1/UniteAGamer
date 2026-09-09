import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registration uses current UAG subscription tiers and prices', () {
    final source = File('lib/build/auth/auth_screen.dart').readAsStringSync();

    expect(source, contains("tier: 'free'"));
    expect(source, contains("tier: 'essential'"));
    expect(source, contains("tier: 'premium'"));
    expect(source, contains(r"price: '\u00A37.99/month'"));
    expect(source, contains(r"price: '\u00A39.99/month'"));

    expect(source, isNot(contains("tier: 'Operator'")));
    expect(source, isNot(contains("tier: 'Overseer'")));
    expect(source, isNot(contains('£4.99/month')));
    expect(source, isNot(contains('£8.99/month')));
    expect(source, isNot(contains('Â£')));
    expect(source, isNot(contains('commission path')));
  });

  test(
    'mobile bootstrap renders cinematic loading before Firebase startup',
    () {
      final mainSource = File('lib/main.dart').readAsStringSync();
      final loadingSource = File(
        'lib/widgets/uag_cinematic_loading_screen.dart',
      ).readAsStringSync();

      final bootIndex = mainSource.indexOf('runApp(const _UagBootstrapApp())');
      final firebaseIndex = mainSource.indexOf('await Firebase.initializeApp');
      expect(bootIndex, greaterThanOrEqualTo(0));
      expect(firebaseIndex, greaterThan(bootIndex));
      expect(loadingSource, contains('INITIALISING SYSTEMS'));
      expect(
        loadingSource,
        contains('assets/images/arc_raiders/hub/auth_bg_landscape.webp'),
      );
    },
  );
}
