import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('landscape Blueprint view defaults to fitted full 91-slot overview', () {
    final grid = File('lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart').readAsStringSync();
    final prefs = File('lib/features/trading_hub/arc_raiders/data/arc_blueprint_grid_view_preferences.dart').readAsStringSync();
    expect(grid, contains('_gridColumns = 17'));
    expect(grid, contains('ArcBlueprintGridViewMode _viewMode = ArcBlueprintGridViewMode.fullOverview'));
    expect(prefs, contains('arcBlueprintGridViewModeV3'));
    expect(prefs, contains('_ => ArcBlueprintGridViewMode.fullOverview'));
    expect(grid, contains('math.min(widthScale, heightScale)'));
    expect(grid, contains('ArcFrozenTrailCollectionCatalogue.blueprintGrid.totalSlots'));
    expect(grid, contains('totalCount: ArcFrozenTrailCollectionCatalogue.blueprintGrid.totalSlots'));
    expect(grid, contains('_fullGridWithUnknownCells(filteredByState)'));
    expect(grid, contains('InteractiveViewer('));
    expect(grid, contains('scaleEnabled: true'));
  });
  test('Blueprint tiles do not expose web-only favourite stars', () {
    final grid = File('lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart').readAsStringSync();
    expect(grid, isNot(contains('_buildLoadoutAction(')));
    expect(grid, isNot(contains('loadoutAction: isNativeMobile')));
    expect(grid, contains('FavouriteLoadoutScreen.routeName'));
    expect(grid, contains('BlueprintTile('));
  });
  test('web build identity derives from compiled assets not stale HEAD', () {
    final tool = File('tool/prepare_web_release.dart').readAsStringSync();
    expect(tool, contains('sha256.convert(await mainDartJs.readAsBytes())'));
    expect(tool, contains('builtAt'));
    final hosting = File('firebase.json').readAsStringSync();
    expect(hosting, contains('tool/prepare_web_release.dart'));
    expect(hosting, contains('build/web'));
  });
  test('trade invites do not print raw Firebase errors to users', () {
    final landing = File('lib/features/trading_hub/arc_raiders/screens/uag_trade_invite_landing.dart').readAsStringSync();
    expect(landing, isNot(contains(r'${snapshot.error}')));
    expect(landing, contains('cannot be opened right now'));
  });
}
