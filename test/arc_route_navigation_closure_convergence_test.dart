import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('legacy deep links converge onto current route authority', () {
    final main = read('lib/main.dart');

    expect(main, contains("case '/monetisation/plans':"));
    expect(main, contains('case ArcAwayScreen.routeName:'));
    expect(main, contains("case '/arc-create-trade-listing':"));
    expect(main, contains("case '/arc-my-trade-listings':"));

    final legacyPlans = main.indexOf("case '/monetisation/plans':");
    final plansBuilder = main.indexOf(
      'builder: (_) => const MonetisationScreen()',
      legacyPlans,
    );
    expect(plansBuilder, greaterThan(legacyPlans));

    final legacyCreate = main.indexOf("case '/arc-create-trade-listing':");
    final canonicalCreate = main.indexOf(
      'TraderHubScreen(initialIndex: 1)',
      legacyCreate,
    );
    expect(canonicalCreate, greaterThan(legacyCreate));

    final legacyListings = main.indexOf("case '/arc-my-trade-listings':");
    final canonicalListings = main.indexOf(
      'TraderHubScreen(initialIndex: 2, initialActivityTab: 0)',
      legacyListings,
    );
    expect(canonicalListings, greaterThan(legacyListings));
  });

  test('primary navigation catalog closes remaining player-facing gaps', () {
    final catalog = read(
      'lib/features/trading_hub/arc_raiders/data/arc_compact_navigation_catalog.dart',
    );

    expect(catalog, contains("label: 'My Intel'"));
    expect(catalog, contains('routeName: MyIntelScreen.routeName'));
    expect(catalog, contains("label: 'Help Centre'"));
    expect(catalog, contains('routeName: ArcHelpCentreScreen.routeName'));
    expect(catalog, contains("label: 'Beta Feedback'"));
    expect(catalog, contains('routeName: ArcBetaFeedbackScreen.routeName'));
    expect(catalog, contains("selectedRouteNames: ['/feedback']"));
    expect(catalog, contains("label: 'Privacy & Data'"));
    expect(catalog, contains('routeName: UagPrivacyDataScreen.routeName'));
    expect(catalog, contains("label: 'Legal'"));
    expect(catalog, contains('routeName: LegalHubScreen.routeName'));
  });

  test('profile and trading aliases highlight their canonical families', () {
    final catalog = read(
      'lib/features/trading_hub/arc_raiders/data/arc_compact_navigation_catalog.dart',
    );

    expect(catalog, contains('ArcProfileEditScreen.routeName'));
    expect(catalog, contains('ArcAvailabilityScreen.routeName'));
    expect(catalog, contains('ArcAwayScreen.routeName'));
    expect(catalog, contains("'/monetisation/plans'"));
    expect(catalog, contains("'/arc-create-trade-listing'"));
    expect(catalog, contains("'/arc-my-trade-listings'"));
  });

  test('bottom dock classifies support and community utility surfaces', () {
    final dock = read(
      'lib/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart',
    );

    for (final label in const [
      "normalised == 'settings'",
      "normalised == 'plans & referrals'",
      "normalised == 'help centre'",
      "normalised == 'beta feedback'",
      "normalised == 'legal & privacy'",
    ]) {
      expect(dock, contains(label));
    }
    expect(dock, contains("normalised == 'community rewards'"));
    expect(dock, contains("normalised == 'wall of legends'"));
  });

  test('route closure does not absorb business or persistence authority', () {
    final main = read('lib/main.dart');
    final catalog = read(
      'lib/features/trading_hub/arc_raiders/data/arc_compact_navigation_catalog.dart',
    );
    final dock = read(
      'lib/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart',
    );

    for (final source in [main, catalog, dock]) {
      expect(source, isNot(contains('FirebaseFirestore.instance.collection')));
      expect(source, isNot(contains('createListing(')));
      expect(source, isNot(contains('saveAwayStatus(')));
      expect(source, isNot(contains('purchase')));
    }
  });
}
