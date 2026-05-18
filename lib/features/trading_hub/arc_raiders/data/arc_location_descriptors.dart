import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_container_types.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_poi_data.dart';

class ArcLocationDescriptorPack {
  const ArcLocationDescriptorPack({
    required this.quickNotes,
    required this.examples,
  });

  final List<String> quickNotes;
  final List<String> examples;
}

class ArcLocationDescriptors {
  ArcLocationDescriptors._();

  static ArcLocationDescriptorPack resolve({
    required String mapName,
    ArcPoiData? poi,
    required ArcContainerType containerType,
  }) {
    final notes = <String>{
      ..._genericByContainer(containerType),
      ..._genericByPoi(poi),
      if (poi?.notes?.trim().isNotEmpty ?? false) poi!.notes!.trim(),
    };

    final examples = <String>[
      if (poi != null) 'Behind ${poi.name.toLowerCase()} near the outer wall',
      if (containerType.id == ArcContainerTypes.weaponCache.id)
        'Weapon cache on broken bridge / platform edge',
      if (containerType.id == ArcContainerTypes.lockedRoom.id)
        'Inside breach room near desk / shelf after opening',
      if (containerType.id == ArcContainerTypes.hiddenCache.id)
        'Tucked behind debris, rock cover, or rear structure line',
      '${mapName.split(' ').first} side approach near cover / stairs',
    ];

    return ArcLocationDescriptorPack(
      quickNotes: notes.toList(growable: false),
      examples: examples.toSet().toList(growable: false),
    );
  }

  static List<String> _genericByContainer(ArcContainerType containerType) {
    switch (containerType.id) {
      case 'raider_cache':
        return const [
          'Front side of POI',
          'Rear side of POI',
          'Upper level / rooftop',
          'Ground floor',
          'Outside against wall / cover',
          'Near stairs or ladder',
        ];
      case 'weapon_cache':
        return const [
          'Broken bridge / platform edge',
          'Near truck / vehicle',
          'Corner room / side room',
          'Behind barricade / cover',
          'Upper walkway',
          'Near stairs / landing',
        ];
      case 'locker':
        return const [
          'Inside side room',
          'Hallway / corridor wall',
          'Basement / lower level',
          'Near spawn-side entrance',
          'Near extraction-side exit',
          'Back office / utility room',
        ];
      case 'hidden_cache':
        return const [
          'Behind debris / rubble',
          'Under stairs / ramp',
          'Behind building',
          'In bushes / rock cover',
          'Off the main route',
          'Near wall gap / fence line',
        ];
      case 'locked_room':
        return const [
          'Inside breach room',
          'Near desk / shelf',
          'Next to terminal / console',
          'Side room off main POI',
          'Upstairs locked section',
          'Lower locked room',
        ];
      default:
        return const [
          'Front side of POI',
          'Rear side of POI',
          'Upper level',
          'Lower level',
          'Near stairs',
          'Behind cover',
        ];
    }
  }

  static List<String> _genericByPoi(ArcPoiData? poi) {
    if (poi == null) return const [];

    final notes = <String>{};

    if (poi.lootLevel == ArcLootLevel.high) {
      notes.add('High-loot section of ${poi.name}');
    }

    for (final type in poi.buildingTypes) {
      switch (type) {
        case ArcBuildingType.medical:
          notes.add('Near treatment room / ward / med bay');
          break;
        case ArcBuildingType.security:
          notes.add('Near checkpoint / security desk');
          break;
        case ArcBuildingType.industrial:
          notes.add('Near machinery / workshop / loading area');
          break;
        case ArcBuildingType.technological:
          notes.add('Near server room / console / lab equipment');
          break;
        case ArcBuildingType.commercial:
          notes.add('Near shopfront / counter / storage room');
          break;
        case ArcBuildingType.electrical:
          notes.add('Near power room / cable area / generators');
          break;
        case ArcBuildingType.oldWorld:
          notes.add('Near old structure / ruins / interior rooms');
          break;
        default:
          break;
      }
    }

    return notes.toList(growable: false);
  }
}
