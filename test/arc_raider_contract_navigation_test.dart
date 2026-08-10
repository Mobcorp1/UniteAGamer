import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_compact_navigation_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trust/screens/arc_raider_contracts_screen.dart';

void main() {
  test('Report a Raider is wired into compact navigation', () {
    final item = ArcCompactNavigationCatalog.items
        .where((e) => e.routeName == ArcRaiderContractsScreen.routeName)
        .single;
    expect(item.label, 'Report a Raider');
  });
}
