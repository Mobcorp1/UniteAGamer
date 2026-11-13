import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('drop report uses step revolver and exact pins are not POI snapped', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/widgets/arc_blueprint_drop_report_sheet.dart',
    ).readAsStringSync();

    expect(source, contains('enum _DropReportStep'));
    expect(source, contains('_buildDropReportRevolver'));
    expect(source, contains('One step at a time'));
    expect(source, contains("poiName: isRaidReport && !isDolabra && point != null"));
    expect(source, isNot(contains('_nearestPublishedPoi')));
    expect(source, isNot(contains('Matching nearby POIs in the background')));
  });

  test('map picker exposes whole-map reset and deeper zoom', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/widgets/arc_drop_report_map_picker.dart',
    ).readAsStringSync();

    expect(source, contains('maxScale: 14'));
    expect(source, contains("tooltip: 'Zoom in'"));
    expect(source, contains("tooltip: 'Zoom out'"));
    expect(source, contains("tooltip: 'Show whole map'"));
    expect(source, contains('Use this exact pinpoint'));
  });
}
