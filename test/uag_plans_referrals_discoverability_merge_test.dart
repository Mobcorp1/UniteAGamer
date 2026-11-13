import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String source(String path) => File(path).readAsStringSync();

  test('Plans & Referrals is directly discoverable across primary UAG surfaces', () {
    final navigation = source(
      'lib/features/trading_hub/arc_raiders/data/arc_compact_navigation_catalog.dart',
    );
    final myHub = source(
      'lib/features/trading_hub/arc_raiders/screens/my_hub_screen.dart',
    );
    final discover = source(
      'lib/features/trading_hub/arc_raiders/screens/arc_raiders_hub_screen.dart',
    );
    final commandCentre = source(
      'lib/features/trading_hub/arc_raiders/widgets/command_centre/arc_command_centre_content.dart',
    );
    final profile = source(
      'lib/features/trading_hub/arc_raiders/screens/trading_profile_screen.dart',
    );

    expect(navigation, contains("label: 'Plans & Referrals'"));
    expect(navigation, contains('routeName: MonetisationScreen.routeName'));

    expect(myHub, contains("title: 'Plans & Referrals'"));
    expect(myHub, contains("_featureByTitle('Plans & Referrals')"));
    expect(myHub, contains("'Plans & Referrals',"));

    expect(discover, contains("title: 'Plans & Referrals'"));
    expect(discover, contains("'Plans & Referrals',"));

    expect(commandCentre, contains("title: 'Plans & Referrals'"));
    expect(commandCentre, contains('routeName: MonetisationScreen.routeName'));

    expect(profile, contains("title: 'Plans & Referrals'"));
    expect(profile, contains('pushNamed(MonetisationScreen.routeName)'));
  });
}
