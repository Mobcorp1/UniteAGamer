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

  test('six furniture assets use existing verified-name catalogue', () {
    const expected = <String, String>{
      'Diner Sofa': 'diner_sofa.webp',
      'Draped Debris F': 'draped_debris_f.webp',
      'Multicolored Geometric Sofa': 'multicolored_geometric_sofa.webp',
      'Polished Wardrobe': 'polished_wardrobe.webp',
      'Printed Lab Sofa': 'printed_lab_sofa.webp',
      'Winter Table': 'winter_table.webp',
    };

    expect(ArcDesignReferenceCatalogue.names.length, 100);
    expect(ArcDesignReferenceCatalogue.suppliedArtwork.length, expected.length);
    for (final item in expected.entries) {
      expect(ArcDesignReferenceCatalogue.names, contains(item.key));
      final asset = ArcDesignReferenceCatalogue.artworkForName(item.key);
      expect(asset, 'assets/arc_raiders/blueprints/${item.value}');
      expect(File(asset!).existsSync(), isTrue, reason: asset);
    }

    expect(ArcDesignReferenceCatalogue.artworkForName('Other Design'), isNull);
    expect(ArcDesignReferenceCatalogue.artworkForVerifiedSlot(1, const {}), isNull);
    expect(
      ArcDesignReferenceCatalogue.artworkForVerifiedSlot(
        7,
        const <int, String>{7: 'Diner Sofa'},
      ),
      'assets/arc_raiders/blueprints/diner_sofa.webp',
    );
    expect(
      ArcDesignReferenceCatalogue.artworkForVerifiedSlot(
        1,
        const <int, String>{7: 'Diner Sofa'},
      ),
      isNull,
    );
    // These two existing grid labels must now show their supplied artwork.
    expect(
      ArcDesignReferenceCatalogue.artworkForDisplaySlot(1, const {}),
      'assets/arc_raiders/blueprints/printed_lab_sofa.webp',
    );
    expect(
      ArcDesignReferenceCatalogue.artworkForDisplaySlot(4, const {}),
      'assets/arc_raiders/blueprints/multicolored_geometric_sofa.webp',
    );
    expect(ArcDesignReferenceCatalogue.artworkForDisplaySlot(7, const {}), isNull);
    expect(
      ArcDesignReferenceCatalogue.artworkForDisplaySlot(
        1,
        const <int, String>{1: 'Diner Sofa'},
      ),
      'assets/arc_raiders/blueprints/diner_sofa.webp',
    );
  });

  test('Verdigris and Sacrifice stay in Stencils, not furniture', () {
    const expected = <int, String>{1: 'verdigris', 4: 'sacrifice'};
    for (final item in expected.entries) {
      final asset = ArcStencilCatalogue.assetAt(item.key);
      expect(asset, 'assets/arc_raiders/blueprints/${item.value}.webp');
      expect(File(asset).existsSync(), isTrue, reason: asset);
      expect(ArcStencilCatalogue.nameAt(item.key).toLowerCase(), item.value);
      final entry = ArcFrozenTrailCollectionCatalogue.entryAtSlot(
        ArcCollectionType.stencils,
        item.key,
      );
      expect(entry?.id, item.value);
      expect(
        ArcFrozenTrailCollectionCatalogue.frozenTrailArtworkPaths[item.value],
        asset,
      );
    }
    expect(ArcFrozenTrailCollectionCatalogue.blueprintGrid.totalSlots, 91);
    expect(ArcFrozenTrailCollectionCatalogue.designGrid.totalSlots, 100);
  });

  testWidgets('Design grid shows artwork only for assigned game slots',
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
        loader: (_) async => const ArcAdditionalCollectionState(),
        designNameLoader: () async => const <int, String>{
          7: 'Diner Sofa',
        },
        adBanner: const SizedBox(height: 60),
      ),
    ));
    await tester.pumpAndSettle();

    final assigned = find.descendant(
      of: find.byKey(const Key('collections-saved-slot-7')),
      matching: find.byType(Image),
    );
    expect(assigned, findsOneWidget);
    final image = tester.widget<Image>(assigned);
    expect(
      (image.image as AssetImage).assetName,
      'assets/arc_raiders/blueprints/diner_sofa.webp',
    );

    // Existing slot 1 and 4 captions resolve their corresponding images.
    for (final entry in const <int, String>{
      1: 'printed_lab_sofa.webp',
      4: 'multicolored_geometric_sofa.webp',
    }.entries) {
      final image = tester.widget<Image>(
        find.descendant(
          of: find.byKey(Key('collections-saved-slot-${entry.key}')),
          matching: find.byType(Image),
        ),
      );
      expect(
        (image.image as AssetImage).assetName,
        'assets/arc_raiders/blueprints/${entry.value}',
      );
    }

    // Other available furniture previews are visible but cannot be assigned
    // to arbitrary game slots or mark items owned automatically.
    expect(
      find.byKey(const Key('collections-design-artwork-preview')),
      findsOneWidget,
    );
    final unknown = find.descendant(
      of: find.byKey(const Key('collections-saved-slot-2')),
      matching: find.byType(Image),
    );
    expect(unknown, findsNothing);
    expect(tester.takeException(), isNull);
  });
}
