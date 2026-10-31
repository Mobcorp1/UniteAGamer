import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File(
    'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart',
  ).readAsStringSync();

  test('all blueprint action entry points expose the existing report editor', () {
    expect(source, contains("title: 'Add Intel / Drop Report'"));
    expect(source, contains("case 'report':\n        await _openBlueprintEditor(blueprint, state);"));
    expect(source, contains("key: const Key('blueprint-quick-add-intel')"));
    expect(
      source,
      contains("label: 'Add Intel',\n                          icon: Icons.add_location_alt_rounded"),
    );
    expect(source, contains("if (!state.owned) _buildBlueprintActionButton("));
    expect(source, contains("label: 'Mark Owned'"));
    expect(source, contains("title: 'View Intel'"));
    expect(source, contains("case 'intel':"));
  });

  test('long-press report entry scrolls on compact Sony landscape screens', () {
    expect(
      source,
      contains("maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.88"),
    );
    expect(source, contains('child: SingleChildScrollView('));
    expect(source, contains('isScrollControlled: true'));
  });

  test('existing drop-report wizard remains wired to Firestore and state', () {
    final sheet = File(
      'lib/features/trading_hub/arc_raiders/widgets/arc_blueprint_drop_report_sheet.dart',
    ).readAsStringSync();
    expect(sheet, contains('widget.repository.addDropReport('));
    expect(sheet, contains("'Save Blueprint + Report'"));
    expect(source, contains('return ArcBlueprintDropReportSheet('));
    expect(source, contains('onSaved: () {'));
  });

  test('tile and in-game grid layouts are not redefined by intel entry repair', () {
    expect(
      source,
      contains("key: const Key('blueprint-authoritative-grid-view')"),
    );
    expect(source, contains('const crossAxisCount = _gridColumns;'));
    expect(source, contains('child: BlueprintTile('));
    expect(source, contains('onDoubleTap: _isFavouriteLoadoutTargetPickMode'));
  });
}
