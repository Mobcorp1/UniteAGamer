import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final screen = File(
    'lib/features/trust/screens/arc_raider_contracts_screen.dart',
  ).readAsStringSync();
  final repo = File(
    'lib/features/trust/repositories/arc_raider_contracts_repository.dart',
  ).readAsStringSync();
  final map = File(
    'lib/features/trading_hub/arc_raiders/widgets/'
    'arc_raid_intelligence_map.dart',
  ).readAsStringSync();
  final seed = File(
    'lib/features/trading_hub/arc_raiders/data/'
    'arc_raid_intelligence_seed_data.dart',
  ).readAsStringSync();
  final catalog = File(
    'lib/features/trading_hub/arc_raiders/data/'
    'arc_known_extraction_catalog.dart',
  ).readAsStringSync();
  final rules = File('firestore.rules').readAsStringSync();

  test('screen username cannot be autofilled with email credentials', () {
    expect(screen, contains('autofillHints: const <String>[]'));
    expect(screen, contains("labelText: 'Screen username *'"));
  });

  test('Report a Rat exposes only approved report categories', () {
    final listStart = screen.indexOf(
      'static const List<ArcRaiderReportCategory> _reportCategories',
    );
    final listEnd = screen.indexOf('];', listStart);
    final block = screen.substring(listStart, listEnd);

    for (final removed in <String>[
      'ambushRatting',
      'objectiveCamping',
      'doorwayCamping',
      'traversalCamping',
      'lootRatting',
    ]) {
      expect(block, isNot(contains(removed)));
    }
    for (final retained in <String>[
      'extractionRatting',
      'spawnRatting',
      'pvpThirdParty',
      'pveThirdParty',
      'falseFriendly',
      'scam',
      'other',
    ]) {
      expect(block, contains(retained));
    }
  });

  test('map condition is expanded and report map hides Blueprint Intel', () {
    expect(screen, contains("key: const Key('report-rat-event-dropdown')"));
    expect(screen, contains('isExpanded: true'));
    expect(screen, contains('showBlueprintIntel: false'));
    expect(map, contains('this.showBlueprintIntel = true'));
  });

  test('incident time is automatically device-local and editable', () {
    expect(screen, contains('incidentAt = DateTime.now();'));
    expect(screen, contains('showDatePicker('));
    expect(screen, contains('showTimePicker('));
  });

  test('rat contract uses reward search quantity and repeatable add', () {
    expect(screen, contains("key: const Key('report-rat-reward-search')"));
    expect(screen, contains("key: const Key('report-rat-add-reward')"));
    expect(screen, contains('void _addSelectedReward()'));
    expect(screen, isNot(contains('...ArcTradeCatalog.items.map((item)')));
  });

  test('canonical extraction catalogue replaces generic seed exits', () {
    expect(seed, contains('ArcKnownExtractionCatalog.forMap(mapId)'));
    expect(seed, isNot(contains('North Standard Extraction')));
    for (final name in <String>[
      'North Complex Elevator',
      'Red Lakes Balcony Lift',
      'Central Elevator',
      'Eastern Station',
      'Cliffside Airshaft',
      'Warehouse Airshaft',
      'Loading Bay Metro Station',
    ]) {
      expect(catalog, contains(name));
    }
  });

  test('live contracts have explicit available-list permission', () {
    expect(
      rules,
      contains(
        "allow list: if isSignedIn() && resource.data.status == 'available';",
      ),
    );
    expect(repo, contains(".where('status', isEqualTo: 'available')"));
  });

  test(
    'successful report is not turned into failure by notification denial',
    () {
      expect(repo, contains('} on FirebaseException {'));
      expect(repo, contains('return ref.id;'));
    },
  );
}
