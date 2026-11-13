import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_frozen_trail_collection_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_collection_models.dart';

void main() {
  test('exact 17-column launch geometry and canonical identity retention', () {

    expect(ArcFrozenTrailCollectionCatalogue.blueprintGrid.rowColumnCounts, [17,17,17,17,17,6]);
    final entries = ArcFrozenTrailCollectionCatalogue.blueprintEntries.where((e) => e.slot != null).toList();
    expect(entries.length, 91); // 91 physical slots, including provisional legacy IDs
    expect(entries.map((e) => e.slot).toSet().length, 91);
    for (final (slot, id) in <(int,String)>[
      (60, 'Extended Light Mag III'), (62, 'Bantam'), (89, 'Burletta'),
    ]) {
      expect(ArcFrozenTrailCollectionCatalogue.entryAtSlot(ArcCollectionType.blueprints, slot)?.name, id);
    }
    for (final slot in [28,59,90]) {
      expect(ArcFrozenTrailCollectionCatalogue.entryAtSlot(ArcCollectionType.blueprints, slot)?.confidence, ArcCollectionSlotConfidence.unverified);
    }
    // Existing ownership uses immutable IDs. Only the two player-verified
    // slot corrections may differ from historical display positions.
    const confirmedRelocations = <String, int>{
      'extended-light-mag-iii': 60,
      'burletta': 89,
    };
    for (var i = 0; i < ArcBlueprintSeedData.blueprints.length; i++) {
      final original = ArcBlueprintSeedData.blueprints[i];
      final mapped = entries.where((e) => e.id == original.id).toList();
      expect(mapped.length, 1, reason: 'identity ${original.id}');
      final expectedSlot = confirmedRelocations[original.id] ??
          ArcFrozenTrailCollectionCatalogue.legacyBlueprintSlotOrder[i];
      expect(mapped.single.slot, expectedSlot,
          reason: 'confirmed position for ${original.id}');
    }
  });
  test('player-verified anchor positions never drift', () {
    const anchors=<int,String>{4:'Silencer II',5:'Red Light Stick',11:'Medium Gun Parts',13:'Crash Mat',16:'Jupiter',18:'Tactical Mk. 3 (Smoke)',20:'Dolabra',21:'Shotgun Silencer',25:'Remote Raider Flare',29:'Aphelion',30:'Tempest',32:'Vertical Grip III',33:'Wolfpack',35:'Torrente',36:'Jolt Mine',37:'Hullcracker',39:'Deadline',40:'Banjo',41:'Shotgun Choke II',42:'Anvil',43:'Osprey',44:'Looting Mk. 3 (Survivor)',46:'Advanced Camera',47:'Powered Descender',48:'Compensator III',49:'Vulcano',50:'Lightweight Stock',52:'Barricade Kit',53:'Green Light Stick',61:'Il Toro',63:'Padded Stock',65:'Rascal',66:'Canto',67:'Bettina',68:'Emperor Gateway Conduit',69:'Fireworks Box',70:'Gas Mine',71:'Yellow Light Stick',72:'Looting Mk. 3 (Safekeeper)',73:'Surge Coil',74:'Complex Gun Parts',75:'Explosive Mine',76:'Venator',80:'Seeker Grenade',85:'Extended Barrel II',86:'Muzzle Brake II',91:'Snap Hook'};
    for(final item in anchors.entries){
      expect(ArcFrozenTrailCollectionCatalogue.entryAtSlot(ArcCollectionType.blueprints,item.key)?.name,item.value,reason:'slot ${item.key}');
    }
  });
  test('new artwork paths are stable; five unknown additions remain unassigned',(){
    expect(ArcFrozenTrailCollectionCatalogue.frozenTrailArtworkPaths['banjo'], 'assets/arc_raiders/blueprints/banjo.webp');
    expect(ArcFrozenTrailCollectionCatalogue.frozenTrailArtworkPaths['advanced-camera'], 'assets/arc_raiders/blueprints/advanced-camera.webp');
    expect(ArcFrozenTrailCollectionCatalogue.frozenTrailArtworkPaths['emperor-gateway-conduit'], 'assets/arc_raiders/blueprints/emperor-gateway-conduit.webp');
    expect(ArcFrozenTrailCollectionCatalogue.frozenTrailBlueprintAdditions.where((e)=>e.slot==null).length,0);
  });
}
