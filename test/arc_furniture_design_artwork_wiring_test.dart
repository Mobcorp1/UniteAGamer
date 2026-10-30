import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_collection_slot_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_design_reference_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_frozen_trail_collection_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_native_collection_screenshot_recognizer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_stencil_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_collection_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_additional_collections_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const designs = <int, String>{
    1: 'Printed Lab Sofa',
    4: 'Multicolored Geometric Sofa',
    5: 'Polished Wardrobe',
    6: 'Diner Sofa',
    7: 'Winter Table',
    9: 'Draped Debris F',
  };

  test('six furniture images match recovered PASS26 in-game positions', () {
    expect(ArcDesignReferenceCatalogue.inGameOrder.length, 100);
    for (final entry in designs.entries) {
      expect(ArcDesignReferenceCatalogue.nameAt(entry.key), entry.value);
      final filename =
          ArcDesignReferenceCatalogue.artworkFilenameForName(entry.value);
      final path = 'assets/arc_raiders/blueprints/$filename';
      expect(File(path).existsSync(), isTrue, reason: path);
    }
    expect(File('assets/arc_raiders/blueprints/sacrifice.webp').existsSync(), isTrue);
    expect(File('assets/arc_raiders/blueprints/verdigris.webp').existsSync(), isTrue);
    // Original position identities and owned/dupe data must not be remapped.
    expect(ArcDesignReferenceCatalogue.nameAt(37), 'Study Armchair');
    expect(ArcDesignReferenceCatalogue.nameAt(87), 'Study Armchair');
  });

  test('stencils remain in the stencil catalogue', () {
    for (final entry in const <int, String>{
      1: 'verdigris',
      4: 'sacrifice',
    }.entries) {
      final path = ArcStencilCatalogue.assetAt(entry.key);
      expect(path, 'assets/arc_raiders/blueprints/${entry.value}.webp');
      expect(
        ArcFrozenTrailCollectionCatalogue.entryAtSlot(
          ArcCollectionType.stencils, entry.key,
        )?.id,
        entry.value,
      );
    }
  });

  test('Design grid does not contain a second image strip or manual-link rail', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_additional_collections_screen.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('_designArtworkStrip')));
    expect(source, isNot(contains('Tap to link a slot')));
    expect(source, contains('ArcDesignReferenceCatalogue.nameAt(slot)'));
    expect(source, contains('_designArtworkForName(name)'));
    expect(source, contains('crossAxisCount: columns'));
    expect(source, contains('itemCount: _kind.slots'));
  });

  testWidgets('Designs grid displays six available furniture images in place',
      (tester) async {
    tester.view.physicalSize = const Size(1100, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      home: ArcAdditionalCollectionsScreen(
        initialKind: ArcNativeCollectionKind.designs,
        adBanner: const SizedBox(height: 60),
        loader: (_) async => const ArcAdditionalCollectionState(),
        designNameLoader: () async => const <int, String>{},
      ),
    ));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('collections-design-readable-gallery')),
      findsOneWidget,
    );
    for (final entry in designs.entries) {
      final card = find.byKey(Key('collections-saved-slot-${entry.key}'));
      expect(card, findsOneWidget);
      final images = find.descendant(of: card, matching: find.byType(Image));
      expect(images, findsWidgets);
      final filename =
          ArcDesignReferenceCatalogue.artworkFilenameForName(entry.value);
      expect(
        images.evaluate().map((e) => e.widget).whereType<Image>().any(
          (img) => img.image is AssetImage &&
              (img.image as AssetImage).assetName ==
                  'assets/arc_raiders/blueprints/$filename',
        ),
        isTrue,
        reason: 'Missing artwork for Design slot ${entry.key}',
      );
    }
    expect(tester.takeException(), isNull);
  });
}
