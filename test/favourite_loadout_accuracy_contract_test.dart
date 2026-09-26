import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String source(String path) => File(path).readAsStringSync();

  test(
    'Favourite Loadout has one bottom nav, top family switcher and banner',
    () {
      final loadout = source(
        'lib/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart',
      );
      expect(
        loadout,
        contains("bottomNavigationBar: const ArcCompanionBottomDock("),
      );
      expect(
        loadout,
        isNot(
          contains(
            'ArcBlueprintWorkspaceDock(current: ArcBlueprintWorkspace.loadout)',
          ),
        ),
      );
      expect(loadout, contains('ArcBlueprintWorkspaceBar('));
      expect(loadout, contains('showAdBanner: true'));
    },
  );

  test(
    'Favourite Loadout has collapsible missing Blueprints and repair intelligence',
    () {
      final loadout = source(
        'lib/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart',
      );
      expect(loadout, contains("'MISSING BLUEPRINTS'"));
      expect(loadout, contains("'CRAFT + REPAIR INTELLIGENCE'"));
      expect(loadout, contains('_buildEquipmentMaintenancePlan'));
      expect(
        loadout,
        contains('ArcItemIntelligenceEngine.planForRequirements'),
      );
    },
  );

  test('owned weapon subtitle does not generically say Blueprint required', () {
    final loadout = source(
      'lib/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart',
    );
    final start = loadout.indexOf('String _weaponSubtitle');
    final tail = loadout.substring(start);
    final end = tail.indexOf('String _separator');
    expect(
      tail.substring(0, end),
      isNot(contains("parts.add('Blueprint required')")),
    );
  });

  test('shield asset registry never maps a shield to Barricade Kit', () {
    final assets = source(
      'lib/features/trading_hub/arc_raiders/data/arc_loadout_asset_registry.dart',
    );
    expect(assets, isNot(contains("'shield level 2':")));
    expect(assets, contains("'light shield'"));
    expect(assets, contains("'medium shield'"));
    expect(assets, contains("'heavy shield'"));
  });
}
