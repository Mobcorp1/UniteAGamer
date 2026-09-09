import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_compact_navigation_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_profile_screen.dart';

void main() {
  test('Profile & Reputation is directly discoverable under Account & UAG', () {
    final account = ArcCompactNavigationCatalog.groups.singleWhere(
      (group) => group.label == 'ACCOUNT & UAG',
    );

    final profile = account.items.singleWhere(
      (item) => item.label == 'Profile & Reputation',
    );

    expect(profile.routeName, TradingProfileScreen.routeName);
  });

  test('Trading profile is not hidden behind My Hub route selection', () {
    final squad = ArcCompactNavigationCatalog.groups.singleWhere(
      (group) => group.label == 'SQUAD & COMMUNITY',
    );
    final myHub = squad.items.singleWhere((item) => item.label == 'My Hub');

    expect(
      myHub.selectedRouteNames,
      isNot(contains(TradingProfileScreen.routeName)),
    );
  });
}
