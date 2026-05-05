import 'package:flutter/foundation.dart';

@immutable
class ArcContainerType {
  const ArcContainerType({
    required this.id,
    required this.label,
    required this.description,
    this.isPrimaryBlueprintSource = true,
  });

  final String id;
  final String label;
  final String description;
  final bool isPrimaryBlueprintSource;
}

class ArcContainerTypes {
  ArcContainerTypes._();

  static const ArcContainerType fieldCrate = ArcContainerType(
    id: 'field_crate',
    label: 'Field Crate',
    description: 'Standard field loot crate.',
  );

  static const ArcContainerType metalCrate = ArcContainerType(
    id: 'metal_crate',
    label: 'Metal Crate',
    description: 'Heavy metal crate or industrial loot box.',
  );

  static const ArcContainerType ammoCase = ArcContainerType(
    id: 'ammo_case',
    label: 'Ammo Case',
    description: 'Ammo case or ammunition container.',
  );

  static const ArcContainerType medicalBag = ArcContainerType(
    id: 'medical_bag',
    label: 'Medical Bag',
    description: 'Medical bag or first aid style loot source.',
  );

  static const ArcContainerType firstWaveCache = ArcContainerType(
    id: 'first_wave_cache',
    label: 'First Wave Cache',
    description: 'First Wave cache loot source.',
  );

  static const ArcContainerType cupboard = ArcContainerType(
    id: 'cupboard',
    label: 'Cupboard',
    description: 'Cupboard, cabinet, or storage unit.',
  );

  static const ArcContainerType locker = ArcContainerType(
    id: 'locker',
    label: 'Locker',
    description: 'Searchable locker or bank of lockers.',
  );

  static const ArcContainerType suitcase = ArcContainerType(
    id: 'suitcase',
    label: 'Suitcase',
    description: 'Suitcase or travel case.',
  );

  static const ArcContainerType trailer = ArcContainerType(
    id: 'trailer',
    label: 'Trailer',
    description: 'Loot source inside or attached to a trailer.',
  );

  static const ArcContainerType bus = ArcContainerType(
    id: 'bus',
    label: 'Bus',
    description: 'Loot source found in or around a bus.',
  );

  static const ArcContainerType shippingContainer = ArcContainerType(
    id: 'shipping_container',
    label: 'Shipping Container',
    description: 'Shipping container or cargo container.',
  );

  static const ArcContainerType generator = ArcContainerType(
    id: 'generator',
    label: 'Generator',
    description: 'Loot source near or inside a generator housing.',
  );

  static const ArcContainerType backpack = ArcContainerType(
    id: 'backpack',
    label: 'Backpack',
    description: 'Backpack or rucksack loot source.',
  );

  static const ArcContainerType combatSupplies = ArcContainerType(
    id: 'combat_supplies',
    label: 'Combat Supplies',
    description: 'Combat supplies box or military supply source.',
  );

  static const ArcContainerType fieldDepot = ArcContainerType(
    id: 'field_depot',
    label: 'Field Depot',
    description: 'Field depot or larger staged supply source.',
  );

  static const ArcContainerType weaponCache = ArcContainerType(
    id: 'weapon_cache',
    label: 'Weapon Cache',
    description: 'Weapon-focused cache or case.',
  );

  static const ArcContainerType grenadeCase = ArcContainerType(
    id: 'grenade_case',
    label: 'Grenade Case',
    description: 'Grenade or explosive storage case.',
  );

  static const ArcContainerType raiderCache = ArcContainerType(
    id: 'raider_cache',
    label: 'Raider Cache',
    description: 'Standard raider cache container.',
  );

  static const ArcContainerType drawers = ArcContainerType(
    id: 'drawers',
    label: 'Drawers',
    description: 'Desk drawers or storage drawers.',
  );

  static const ArcContainerType fridge = ArcContainerType(
    id: 'fridge',
    label: 'Fridge',
    description: 'Fridge or cooler-style loot source.',
  );

  static const ArcContainerType securityLocker = ArcContainerType(
    id: 'security_locker',
    label: 'Security Locker',
    description: 'Security locker or secured loot point.',
  );

  static const ArcContainerType toolbox = ArcContainerType(
    id: 'toolbox',
    label: 'Toolbox',
    description: 'Toolbox or engineering storage box.',
  );

  static const ArcContainerType car = ArcContainerType(
    id: 'car',
    label: 'Car',
    description: 'Loot source found in or around a car.',
  );

  static const ArcContainerType garbageBin = ArcContainerType(
    id: 'garbage_bin',
    label: 'Garbage Bin / Dumpster',
    description: 'Large rubbish bin, dumpster, or waste container.',
  );

  static const ArcContainerType electricalBox = ArcContainerType(
    id: 'electrical_box',
    label: 'Electrical Box',
    description: 'Electrical box, panel, or powered cabinet.',
  );

  static const ArcContainerType wickerBasket = ArcContainerType(
    id: 'wicker_basket',
    label: 'Wicker Basket',
    description: 'Basket or open woven storage container.',
  );

  static const ArcContainerType netNest = ArcContainerType(
    id: 'net_nest',
    label: 'Net Nest',
    description: 'Nest or netted stash-style loot source.',
  );

  static const ArcContainerType hiddenCache = ArcContainerType(
    id: 'hidden_cache',
    label: 'Hidden Cache',
    description: 'Tucked-away stash, off-route cache, or concealed loot point.',
  );

  static const ArcContainerType lockedRoom = ArcContainerType(
    id: 'locked_room',
    label: 'Locked Room (Key Required)',
    description: 'Room that requires a key or keycard to access.',
  );

  static const ArcContainerType breachableDoor = ArcContainerType(
    id: 'breachable_door',
    label: 'Breachable Door',
    description: 'Door that must be pried or forced open to access loot.',
  );

  static const ArcContainerType looseLoot = ArcContainerType(
    id: 'loose_loot',
    label: 'Loose Loot / Surface Spawn',
    description: 'Found loose on a surface, shelf, desk, floor, or bench.',
    isPrimaryBlueprintSource: false,
  );


  static const ArcContainerType assessor = ArcContainerType(
    id: 'assessor',
    label: 'Assessor',
    description: 'Legendary Assessor breach/search source.',
  );

  static const ArcContainerType unknown = ArcContainerType(
    id: 'unknown',
    label: 'Unknown Container',
    description: 'Container was not confirmed by the player report.',
    isPrimaryBlueprintSource: false,
  );

  static const List<ArcContainerType> reportable = [
    assessor,
    ammoCase,
    backpack,
    breachableDoor,
    bus,
    car,
    combatSupplies,
    cupboard,
    drawers,
    electricalBox,
    fieldCrate,
    fieldDepot,
    firstWaveCache,
    fridge,
    garbageBin,
    generator,
    grenadeCase,
    hiddenCache,
    locker,
    lockedRoom,
    medicalBag,
    metalCrate,
    netNest,
    raiderCache,
    securityLocker,
    shippingContainer,
    suitcase,
    toolbox,
    trailer,
    weaponCache,
    wickerBasket,
    looseLoot,
    unknown,
  ];

  static ArcContainerType byId(String? id) {
    if (id == null || id.trim().isEmpty) return unknown;
    final normalized = id.trim().toLowerCase();
    for (final item in reportable) {
      if (item.id == normalized) return item;
    }
    return unknown;
  }
}
