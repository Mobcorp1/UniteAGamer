import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_design_reference_catalogue.dart';

void main() {
  const expectedInGameOrder = <String>[
    'Printed Lab Sofa',
    'Sturdy Faculty Chair',
    'Diner Ceiling Lamp',
    'Multicolored Geometric Sofa',
    'Polished Wardrobe',
    'Diner Sofa',
    'Winter Table',
    'Battered Lab Cabinet (Wide)',
    'Draped Debris F',
    'Sturdy Stash',
    'Alpine Wardrobe',
    'Security Chair',
    'Draped Debris E',
    'Green Geometric Chair',
    'Battered Weapon Rack',
    'Faculty Closet',
    'Battered Stash',
    'Battered Shelf',
    'Faculty Dresser',
    'Chambers Nightstand',
    'Chambers Shelf',
    'Clinic Medical Cabinet',
    'Ornate Wardrobe',
    'Polished Faculty Table',
    'Ornate Stash',
    'Diner Stool',
    'Lab Stool',
    'Polished Study Sofa',
    'Polished Round Sofa',
    'Lab Ceiling Light',
    'Tufted Sofa',
    'Sturdy Lab Cabinet (Wide)',
    'Work Light',
    'Sturdy Lab Cabinet',
    'Sturdy Wardrobe',
    'Draped Debris B',
    'Study Armchair',
    'Bar Table',
    'Battered Bureau Sofa',
    'Sturdy Bureau Chair',
    'Hotel Chair',
    'Polished Den Bed',
    'Draped Debris A',
    'Chambers Lamp',
    'Sturdy Weapon Rack',
    'Glass Ceiling Lamp',
    'Polished Diner Chair',
    'Cafeteria Table',
    'Study TV Stand',
    'Diner Table',
    'Diner Shelf',
    'Weather Station Chair',
    'Battered Den Shelf',
    'Study Ceiling Lamp',
    'Console Chest',
    'Sturdy Bureau Sofa',
    'Geometric Fabric Chair',
    'Study Piano',
    'Sturdy Den Bed',
    'Weather Station Table',
    'Battered Faculty Table',
    'Ornate Den Shelf',
    'Battered Bureau Chair',
    'Battered Aviary Table',
    'Barstool',
    'Holly Bush',
    'Green Lab Sofa',
    'Battered Lab Chair',
    'Warehouse Dresser',
    'Red Study Sofa',
    'Polished Den Shelf',
    'Battered Lab Cabinet',
    'Solid Green Chair',
    'Venetian Dresser',
    'Battered Den Bed',
    'Sturdy Shelf',
    'Draped Debris G',
    'Polished Faculty Chair',
    'Diner Cupboard',
    'Chandelier',
    'Draped Debris C',
    'Bureau Ceiling Lamp',
    'Floor Lamp',
    'Battered Diner Chair',
    'Ornate Den Bed',
    'Polished Stash',
    'Study Armchair',
    'Restaurant Table',
    'Archive Floor Lamp',
    'Polished Weapon Rack',
    'Printed Fabric Chair',
    'Sturdy Aviary Table',
    'Warehouse Desk',
    'Green Geometric Sofa',
    'Small Lab Cabinet',
    'Sturdy Lab Chair',
    'Blue Lab Cabinet',
    'Warehouse Chair',
    'Sturdy Faculty Table',
    'Sturdy Den Shelf',
  ];

  test('PASS26 maps all 100 Designs in MetaForge in-game order', () {
    expect(ArcDesignReferenceCatalogue.inGameOrder, expectedInGameOrder);
    expect(ArcDesignReferenceCatalogue.inGameOrder.length, 100);
    for (var i = 1; i <= 100; i++) {
      expect(
        ArcDesignReferenceCatalogue.nameAt(i),
        expectedInGameOrder[i - 1],
        reason: 'Wrong label for persisted Design slot $i',
      );
    }
    expect(ArcDesignReferenceCatalogue.nameAt(0), isNull);
    expect(ArcDesignReferenceCatalogue.nameAt(101), isNull);
  });

  test('PASS26 preserves the duplicate Study Armchair ambiguity', () {
    expect(ArcDesignReferenceCatalogue.nameAt(37), 'Study Armchair');
    expect(ArcDesignReferenceCatalogue.nameAt(87), 'Study Armchair');
    expect(expectedInGameOrder.toSet().length, 99);
    expect(
      ArcDesignReferenceCatalogue.names,
      contains('Study Armchair (Uncommon)'),
    );
    expect(
      ArcDesignReferenceCatalogue.names,
      contains('Study Armchair (Legendary)'),
    );
  });

  test('PASS26 artwork filenames use item names, not slot numbers', () {
    expect(
      ArcDesignReferenceCatalogue.artworkFilenameForName('Printed Lab Sofa'),
      'printed_lab_sofa.webp',
    );
    expect(
      ArcDesignReferenceCatalogue.artworkFilenameForName(
        'Battered Lab Cabinet (Wide)',
      ),
      'battered_lab_cabinet_wide.webp',
    );
    expect(
      ArcDesignReferenceCatalogue.artworkFilenameForName(
        'Study Armchair (Uncommon)',
      ),
      'study_armchair_uncommon.webp',
    );
    expect(
      ArcDesignReferenceCatalogue.artworkFilenameForName(
        'Study Armchair (Legendary)',
      ),
      'study_armchair_legendary.webp',
    );
  });

  test('PASS26 never writes names into Firestore or moves slot-based ownership', () {
    final screen = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_additional_collections_screen.dart',
    ).readAsStringSync();
    final state = File(
      'lib/features/trading_hub/arc_raiders/data/arc_collection_slot_repository.dart',
    ).readAsStringSync();
    // The existing personal assignment takes priority over the researched default.
    expect(screen, contains('_assignedDesignNames[slot] ??'));
    expect(screen, contains('ArcDesignReferenceCatalogue.nameAt(slot)'));
    expect(screen, contains('itemCount: _kind.slots'));
    expect(screen, contains('final slot = index + 1;'));
    expect(screen, contains('_designArtworkForName(name)'));
    expect(
      RegExp(
        r'Positioned\.fill\s*\([\s\S]*?Image\.asset\s*\(\s*artwork',
      ).hasMatch(screen),
      isTrue,
    );
    expect(
      RegExp(
        r'_designArtworkForName\s*\(\s*_name\s*\(\s*slot\s*\)\s*\)',
      ).hasMatch(screen),
      isTrue,
    );
    expect(
      RegExp(
        r'AssetManifest\.loadFromAssetBundle\s*\(\s*rootBundle\s*\)',
      ).hasMatch(screen),
      isTrue,
    );
    // Regression: R4's unbraced `continue` was rejected by Flutter analyze.
    expect(screen, contains("!path.toLowerCase().endsWith('.webp')) {"));
    expect(RegExp(r'\)\)\s*continue\s*;').hasMatch(screen), isFalse);
    // Loader must be called INSIDE initState, never spliced at end-of-file.
    final initStart = screen.indexOf('void initState()');
    final savedStart = screen.indexOf('Future<void> _loadSaved()', initStart);
    expect(initStart, greaterThanOrEqualTo(0));
    expect(savedStart, greaterThan(initStart));
    final initBody = screen.substring(initStart, savedStart);
    expect(initBody, contains('_loadDesignArtwork();'));
    expect(RegExp(r'_loadDesignArtwork\(\);').allMatches(screen).length, 1);

    expect(state, contains('for (final slot in addOwned)'));
    expect(state, contains('final nextDuplicates = <int, int>'));
    // Legacy manual-confirmation API is intentionally unchanged.
    expect(ArcDesignReferenceCatalogue.inGameNameForSlot(1, const {}), isNull);
    expect(
      ArcDesignReferenceCatalogue.inGameNameForSlot(1, const {
        1: 'Printed Lab Sofa',
      }),
      'Printed Lab Sofa',
    );
  });
}
