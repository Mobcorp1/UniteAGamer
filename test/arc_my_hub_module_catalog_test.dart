import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_my_hub_module_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';

void main() {
  group('ArcMyHubModuleCatalog', () {
    test('module titles are unique and route-backed where available', () {
      final modules = ArcMyHubModuleCatalog.modules;

      expect(
        modules.map((module) => module.title).toSet(),
        hasLength(modules.length),
      );
      for (final module in modules) {
        expect(module.routeName.trim(), isNotEmpty, reason: module.title);
      }
    });

    test('Trading Overview resolves to the real trader route', () {
      final module = ArcMyHubModuleCatalog.byTitle('Trading Overview');

      expect(module, isNotNull);
      expect(module!.routeName, TraderHubScreen.routeName);
    });
  });
}
