import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';

class ArcAttachmentSlotMatrixConflict {
  const ArcAttachmentSlotMatrixConflict({
    required this.attachmentName,
    required this.weaponName,
    required this.attachmentSlot,
    required this.weaponSlots,
  });

  final String attachmentName;
  final String weaponName;
  final ArcAttachmentSlotType attachmentSlot;
  final List<String> weaponSlots;

  String get label => '$attachmentName -> $weaponName';
}

class ArcWeaponAttachmentDatabase {
  const ArcWeaponAttachmentDatabase._();

  static final List<ArcLoadoutAttachmentSpec>
  attachments = List.unmodifiable(<ArcLoadoutAttachmentSpec>[
    _craftable(
      name: 'Compensator I',
      slotType: ArcAttachmentSlotType.muzzle,
      benchLevel: 1,
      requirements: [_req(6, 'Metal Parts'), _req(1, 'Wires')],
      effects: [
        _effect(
          '25% reduced per-shot dispersion',
          stat: 'perShotDispersion',
          value: -25,
        ),
      ],
      compatibleWeapons: [
        'Ferro',
        'Torrente',
        'Tempest',
        'Arpeggio',
        'Bettina',
      ],
      assetPath: 'assets/arc_raiders/blueprints/compensator-i.webp',
    ),
    _craftable(
      name: 'Muzzle Brake I',
      slotType: ArcAttachmentSlotType.muzzle,
      benchLevel: 1,
      requirements: [_req(6, 'Metal Parts'), _req(1, 'Wires')],
      effects: [
        _effect(
          '15% reduced horizontal recoil',
          stat: 'horizontalRecoil',
          value: -15,
        ),
        _effect(
          '15% reduced vertical recoil',
          stat: 'verticalRecoil',
          value: -15,
        ),
      ],
      compatibleWeapons: ['Arpeggio', 'Ferro'],
      assetPath: 'assets/arc_raiders/blueprints/muzzle-brake-i.webp',
    ),
    _craftable(
      name: 'Shotgun Choke I',
      slotType: ArcAttachmentSlotType.shotgunMuzzle,
      benchLevel: 1,
      requirements: [_req(6, 'Metal Parts'), _req(1, 'Wires')],
      effects: [
        _effect(
          '20% reduced base dispersion',
          stat: 'baseDispersion',
          value: -20,
        ),
      ],
      compatibleWeapons: ['Vulcano', 'Il Toro'],
      assetPath: 'assets/arc_raiders/blueprints/shotgun-choke-i.webp',
    ),
    _craftable(
      name: 'Angled Grip I',
      slotType: ArcAttachmentSlotType.underbarrel,
      benchLevel: 1,
      requirements: [_req(6, 'Plastic Parts'), _req(1, 'Duct Tape')],
      effects: [
        _effect(
          '20% reduced horizontal recoil',
          stat: 'horizontalRecoil',
          value: -20,
        ),
      ],
      compatibleWeapons: ['Vulcano', 'Osprey', 'Ferro', 'Venator', 'Il Toro'],
      assetPath: 'assets/arc_raiders/scrappy_resources/angled_grip_i.webp',
    ),
    _craftable(
      name: 'Vertical Grip I',
      slotType: ArcAttachmentSlotType.underbarrel,
      benchLevel: 1,
      requirements: [_req(6, 'Plastic Parts'), _req(1, 'Duct Tape')],
      effects: [
        _effect(
          '20% reduced vertical recoil',
          stat: 'verticalRecoil',
          value: -20,
        ),
      ],
      compatibleWeapons: ['Vulcano', 'Ferro', 'Bobcat', 'Il Toro', 'Tempest'],
      assetPath: 'assets/arc_raiders/blueprints/vertical-grip-i.webp',
    ),
    _craftable(
      name: 'Extended Light Mag I',
      slotType: ArcAttachmentSlotType.lightMagazine,
      benchLevel: 1,
      requirements: [_req(6, 'Plastic Parts'), _req(1, 'Steel Spring')],
      effects: [
        _effect(
          '+5 magazine size',
          stat: 'magazineSize',
          value: 5,
          unit: 'rounds',
        ),
      ],
      compatibleWeapons: ['Bobcat'],
      assetPath: 'assets/arc_raiders/blueprints/extended-light-mag-i.webp',
    ),
    _craftable(
      name: 'Extended Medium Mag I',
      slotType: ArcAttachmentSlotType.mediumMagazine,
      benchLevel: 1,
      requirements: [_req(6, 'Plastic Parts'), _req(1, 'Steel Spring')],
      effects: [
        _effect(
          '+4 magazine size',
          stat: 'magazineSize',
          value: 4,
          unit: 'rounds',
        ),
      ],
      compatibleWeapons: [
        'Arpeggio',
        'Venator',
        'Torrente',
        'Renegade',
        'Osprey',
        'Tempest',
      ],
      assetPath: 'assets/arc_raiders/blueprints/extended-medium-mag-i.webp',
    ),
    _craftable(
      name: 'Extended Shotgun Mag I',
      slotType: ArcAttachmentSlotType.shotgunMagazine,
      benchLevel: 1,
      requirements: [_req(6, 'Plastic Parts'), _req(1, 'Steel Spring')],
      effects: [
        _effect(
          '+2 magazine size',
          stat: 'magazineSize',
          value: 2,
          unit: 'shells',
        ),
      ],
      compatibleWeapons: ['Il Toro', 'Vulcano'],
      assetPath: 'assets/arc_raiders/blueprints/extended-shotgun-mag-i.webp',
    ),
    _craftable(
      name: 'Stable Stock I',
      slotType: ArcAttachmentSlotType.stock,
      benchLevel: 1,
      requirements: [_req(7, 'Rubber Parts'), _req(1, 'Duct Tape')],
      effects: [
        _effect(
          '40% reduced recoil recovery time',
          stat: 'recoilRecoveryTime',
          value: -40,
        ),
        _effect(
          '40% reduced dispersion recovery time',
          stat: 'dispersionRecoveryTime',
          value: -40,
        ),
      ],
      compatibleWeapons: [
        'Vulcano',
        'Ferro',
        'Bobcat',
        'Il Toro',
        'Torrente',
        'Arpeggio',
        'Rattler',
      ],
      assetPath: 'assets/arc_raiders/blueprints/stable-stock-i.webp',
    ),
    _craftable(
      name: 'Compensator II',
      slotType: ArcAttachmentSlotType.muzzle,
      benchLevel: 2,
      requirements: [_req(8, 'Metal Parts'), _req(1, 'Wires')],
      effects: [
        _effect(
          '35% reduced per-shot dispersion',
          stat: 'perShotDispersion',
          value: -35,
        ),
      ],
      compatibleWeapons: [
        'Arpeggio',
        'Renegade',
        'Bobcat',
        'Torrente',
        'Burletta',
        'Anvil',
        'Osprey',
        'Ferro',
      ],
      assetPath: 'assets/arc_raiders/blueprints/compensator-ii.webp',
    ),
    _craftable(
      name: 'Muzzle Brake II',
      slotType: ArcAttachmentSlotType.muzzle,
      benchLevel: 2,
      requirements: [_req(1, 'Mechanical Components'), _req(1, 'Duct Tape')],
      effects: [
        _effect(
          '20% reduced horizontal recoil',
          stat: 'horizontalRecoil',
          value: -20,
        ),
        _effect(
          '20% reduced vertical recoil',
          stat: 'verticalRecoil',
          value: -20,
        ),
      ],
      compatibleWeapons: ['Arpeggio', 'Ferro', 'Tempest', 'Anvil', 'Osprey'],
      assetPath: 'assets/arc_raiders/blueprints/muzzle-brake-ii.webp',
    ),
    _craftable(
      name: 'Shotgun Choke II',
      slotType: ArcAttachmentSlotType.shotgunMuzzle,
      benchLevel: 2,
      requirements: [_req(1, 'Mechanical Components'), _req(1, 'Duct Tape')],
      effects: [
        _effect(
          '30% reduced base dispersion',
          stat: 'baseDispersion',
          value: -30,
        ),
      ],
      compatibleWeapons: ['Vulcano', 'Il Toro'],
      assetPath: 'assets/arc_raiders/blueprints/shotgun-choke-ii.webp',
    ),
    _craftable(
      name: 'Silencer I',
      slotType: ArcAttachmentSlotType.muzzle,
      benchLevel: 2,
      requirements: [_req(1, 'Mechanical Components'), _req(1, 'Wires')],
      effects: [_effect('20% reduced noise', stat: 'noise', value: -20)],
      compatibleWeapons: [
        'Bobcat',
        'Osprey',
        'Torrente',
        'Tempest',
        'Arpeggio',
        'Anvil',
        'Burletta',
        'Renegade',
      ],
      assetPath: 'assets/arc_raiders/blueprints/silencer-i.webp',
    ),
    _craftable(
      name: 'Angled Grip II',
      slotType: ArcAttachmentSlotType.underbarrel,
      benchLevel: 2,
      requirements: [_req(6, 'Plastic Parts'), _req(1, 'Duct Tape')],
      effects: [
        _effect(
          '30% reduced horizontal recoil',
          stat: 'horizontalRecoil',
          value: -30,
        ),
      ],
      compatibleWeapons: ['Vulcano', 'Tempest', 'Osprey', 'Bobcat'],
      assetPath: 'assets/arc_raiders/blueprints/angled-grip-ii.webp',
    ),
    _craftable(
      name: 'Vertical Grip II',
      slotType: ArcAttachmentSlotType.underbarrel,
      benchLevel: 2,
      requirements: [_req(6, 'Plastic Parts'), _req(1, 'Duct Tape')],
      effects: [
        _effect(
          '30% reduced vertical recoil',
          stat: 'verticalRecoil',
          value: -30,
        ),
      ],
      compatibleWeapons: [
        'Arpeggio',
        'Kettle',
        'Ferro',
        'Rattler',
        'Stitcher',
        'Venator',
      ],
      assetPath: 'assets/arc_raiders/blueprints/vertical-grip-ii.webp',
    ),
    _craftable(
      name: 'Extended Light Mag II',
      slotType: ArcAttachmentSlotType.lightMagazine,
      benchLevel: 2,
      requirements: [_req(1, 'Mechanical Components'), _req(1, 'Steel Spring')],
      effects: [
        _effect(
          '+10 magazine size',
          stat: 'magazineSize',
          value: 10,
          unit: 'rounds',
        ),
      ],
      compatibleWeapons: ['Burletta', 'Bobcat'],
      assetPath: 'assets/arc_raiders/blueprints/extended-light-mag-ii.webp',
    ),
    _craftable(
      name: 'Extended Medium Mag II',
      slotType: ArcAttachmentSlotType.mediumMagazine,
      benchLevel: 2,
      requirements: [_req(6, 'Plastic Parts'), _req(1, 'Steel Spring')],
      effects: [
        _effect(
          '+8 magazine size',
          stat: 'magazineSize',
          value: 8,
          unit: 'rounds',
        ),
      ],
      compatibleWeapons: [
        'Arpeggio',
        'Venator',
        'Torrente',
        'Renegade',
        'Osprey',
        'Tempest',
      ],
      assetPath: 'assets/arc_raiders/blueprints/extended-medium-mag-ii.webp',
    ),
    _craftable(
      name: 'Extended Shotgun Mag II',
      slotType: ArcAttachmentSlotType.shotgunMagazine,
      benchLevel: 2,
      requirements: [_req(1, 'Mechanical Components'), _req(1, 'Steel Spring')],
      effects: [
        _effect(
          '+4 magazine size',
          stat: 'magazineSize',
          value: 4,
          unit: 'shells',
        ),
      ],
      compatibleWeapons: ['Il Toro', 'Vulcano'],
      assetPath: 'assets/arc_raiders/blueprints/extended-shotgun-mag-ii.webp',
    ),
    _craftable(
      name: 'Stable Stock II',
      slotType: ArcAttachmentSlotType.stock,
      benchLevel: 2,
      requirements: [_req(1, 'Mechanical Components'), _req(1, 'Duct Tape')],
      effects: [
        _effect(
          '60% reduced recoil recovery time',
          stat: 'recoilRecoveryTime',
          value: -60,
        ),
        _effect(
          '60% reduced dispersion recovery time',
          stat: 'dispersionRecoveryTime',
          value: -60,
        ),
      ],
      compatibleWeapons: ['Renegade', 'Vulcano', 'Torrente'],
      assetPath: 'assets/arc_raiders/blueprints/stable-stock-ii.webp',
    ),
    _craftable(
      name: 'Compensator III',
      slotType: ArcAttachmentSlotType.muzzle,
      benchLevel: 3,
      requirements: [_req(1, 'Mod Components'), _req(6, 'Wires')],
      effects: [
        _effect(
          '50% reduced per-shot dispersion',
          stat: 'perShotDispersion',
          value: -50,
        ),
        _effect(
          '20% increased durability burn time',
          stat: 'durabilityBurnTime',
          value: 20,
          isPenalty: true,
        ),
      ],
      compatibleWeapons: [
        'Arpeggio',
        'Renegade',
        'Anvil',
        'Burletta',
        'Osprey',
      ],
      assetPath: 'assets/arc_raiders/blueprints/compensator-iii.webp',
    ),
    _craftable(
      name: 'Muzzle Brake III',
      slotType: ArcAttachmentSlotType.muzzle,
      benchLevel: 3,
      requirements: [_req(1, 'Mod Components'), _req(6, 'Wires')],
      effects: [
        _effect(
          '25% reduced horizontal recoil',
          stat: 'horizontalRecoil',
          value: -25,
        ),
        _effect(
          '25% reduced vertical recoil',
          stat: 'verticalRecoil',
          value: -25,
        ),
        _effect(
          '20% increased durability burn time',
          stat: 'durabilityBurnTime',
          value: 20,
          isPenalty: true,
        ),
      ],
      compatibleWeapons: [
        'Arpeggio',
        'Anvil',
        'Ferro',
        'Bobcat',
        'Torrente',
        'Tempest',
        'Osprey',
        'Renegade',
      ],
      assetPath: 'assets/arc_raiders/blueprints/muzzle-brake-iii.webp',
    ),
    _craftable(
      name: 'Shotgun Choke III',
      slotType: ArcAttachmentSlotType.shotgunMuzzle,
      benchLevel: 3,
      requirements: [_req(1, 'Mod Components'), _req(9, 'Wires')],
      effects: [
        _effect(
          '40% reduced base dispersion',
          stat: 'baseDispersion',
          value: -40,
        ),
        _effect(
          '20% increased durability burn time',
          stat: 'durabilityBurnTime',
          value: 20,
          isPenalty: true,
        ),
      ],
      compatibleWeapons: ['Vulcano', 'Il Toro'],
      assetPath: 'assets/arc_raiders/blueprints/shotgun-choke-iii.webp',
    ),
    _craftable(
      name: 'Silencer II',
      slotType: ArcAttachmentSlotType.muzzle,
      benchLevel: 3,
      requirements: [_req(1, 'Mod Components'), _req(9, 'Wires')],
      effects: [_effect('40% reduced noise', stat: 'noise', value: -40)],
      compatibleWeapons: [
        'Bobcat',
        'Osprey',
        'Torrente',
        'Tempest',
        'Arpeggio',
        'Anvil',
        'Burletta',
        'Renegade',
      ],
      assetPath: 'assets/arc_raiders/blueprints/silencer-ii.webp',
    ),
    _craftable(
      name: 'Silencer III',
      slotType: ArcAttachmentSlotType.muzzle,
      benchLevel: 3,
      requirements: [_req(3, 'Mod Components'), _req(15, 'Wires')],
      effects: [
        _effect('60% reduced noise', stat: 'noise', value: -60),
        _effect(
          '20% increased durability burn rate',
          stat: 'durabilityBurnRate',
          value: 20,
          isPenalty: true,
        ),
      ],
      compatibleWeapons: [
        'Bobcat',
        'Osprey',
        'Torrente',
        'Tempest',
        'Arpeggio',
        'Renegade',
      ],
      assetPath: 'assets/arc_raiders/blueprints/silencer-iii.webp',
    ),
    _craftable(
      name: 'Shotgun Silencer',
      slotType: ArcAttachmentSlotType.shotgunMuzzle,
      benchLevel: 3,
      requirements: [_req(1, 'Mod Components'), _req(9, 'Wires')],
      effects: [_effect('50% reduced noise', stat: 'noise', value: -50)],
      compatibleWeapons: ['Il Toro', 'Vulcano'],
      assetPath: 'assets/arc_raiders/blueprints/shotgun-silencer.webp',
    ),
    _craftable(
      name: 'Extended Barrel',
      slotType: ArcAttachmentSlotType.barrel,
      benchLevel: 3,
      requirements: [_req(6, 'Metal Parts'), _req(1, 'Steel Spring')],
      effects: [
        _effect(
          '25% increased bullet velocity',
          stat: 'bulletVelocity',
          value: 25,
        ),
        _effect(
          '15% increased vertical recoil',
          stat: 'verticalRecoil',
          value: 15,
          isPenalty: true,
        ),
      ],
      compatibleWeapons: [
        'Osprey',
        'Stitcher',
        'Ferro',
        'Arpeggio',
        'Anvil',
        'Burletta',
        'Kettle',
      ],
      assetPath: 'assets/arc_raiders/blueprints/extended-barrel.webp',
      notes:
          'Authoritative compatibility provided, but current weapon slot matrix has no barrel slot.',
    ),
    _craftable(
      name: 'Angled Grip III',
      slotType: ArcAttachmentSlotType.underbarrel,
      benchLevel: 3,
      requirements: [_req(1, 'Mod Components'), _req(6, 'Duct Tape')],
      effects: [
        _effect(
          '40% reduced horizontal recoil',
          stat: 'horizontalRecoil',
          value: -40,
        ),
        _effect(
          '30% reduced ADS speed',
          stat: 'adsSpeed',
          value: -30,
          isPenalty: true,
        ),
      ],
      compatibleWeapons: ['Vulcano', 'Osprey', 'Ferro', 'Venator', 'Il Toro'],
      assetPath: 'assets/arc_raiders/blueprints/angled-grip-iii.webp',
    ),
    _craftable(
      name: 'Vertical Grip III',
      slotType: ArcAttachmentSlotType.underbarrel,
      benchLevel: 3,
      requirements: [_req(1, 'Mod Components'), _req(6, 'Duct Tape')],
      effects: [
        _effect(
          '40% reduced vertical recoil',
          stat: 'verticalRecoil',
          value: -40,
        ),
        _effect(
          '30% reduced ADS speed',
          stat: 'adsSpeed',
          value: -30,
          isPenalty: true,
        ),
      ],
      compatibleWeapons: ['Arpeggio', 'Il Toro', 'Vulcano'],
      assetPath: 'assets/arc_raiders/blueprints/vertical-grip-iii.webp',
    ),
    _craftable(
      name: 'Horizontal Grip',
      slotType: ArcAttachmentSlotType.underbarrel,
      benchLevel: 3,
      requirements: [_req(1, 'Mod Components'), _req(6, 'Duct Tape')],
      effects: [
        _effect(
          '30% reduced horizontal recoil',
          stat: 'horizontalRecoil',
          value: -30,
        ),
        _effect(
          '30% reduced vertical recoil',
          stat: 'verticalRecoil',
          value: -30,
        ),
        _effect(
          '30% reduced ADS speed',
          stat: 'adsSpeed',
          value: -30,
          isPenalty: true,
        ),
      ],
      compatibleWeapons: ['Tempest', 'Vulcano', 'Osprey'],
      assetPath: 'assets/arc_raiders/blueprints/horizontal-grip.webp',
    ),
    _craftable(
      name: 'Extended Light Mag III',
      slotType: ArcAttachmentSlotType.lightMagazine,
      benchLevel: 3,
      requirements: [_req(1, 'Mod Components'), _req(6, 'Steel Spring')],
      effects: [
        _effect(
          '+15 magazine size',
          stat: 'magazineSize',
          value: 15,
          unit: 'rounds',
        ),
      ],
      compatibleWeapons: ['Burletta', 'Bobcat'],
      assetPath: 'assets/arc_raiders/blueprints/extended-light-mag-iii.webp',
    ),
    _craftable(
      name: 'Extended Medium Mag III',
      slotType: ArcAttachmentSlotType.mediumMagazine,
      benchLevel: 3,
      requirements: [_req(1, 'Mod Components'), _req(6, 'Steel Spring')],
      effects: [
        _effect(
          '+12 magazine size',
          stat: 'magazineSize',
          value: 12,
          unit: 'rounds',
        ),
      ],
      compatibleWeapons: [
        'Arpeggio',
        'Venator',
        'Torrente',
        'Renegade',
        'Osprey',
        'Tempest',
      ],
      assetPath: 'assets/arc_raiders/blueprints/extended-medium-mag-iii.webp',
    ),
    _craftable(
      name: 'Extended Shotgun Mag III',
      slotType: ArcAttachmentSlotType.shotgunMagazine,
      benchLevel: 3,
      requirements: [_req(1, 'Mod Components'), _req(6, 'Steel Spring')],
      effects: [
        _effect(
          '+6 magazine size',
          stat: 'magazineSize',
          value: 6,
          unit: 'shells',
        ),
      ],
      compatibleWeapons: ['Il Toro', 'Vulcano'],
      assetPath: 'assets/arc_raiders/blueprints/extended-shotgun-mag-iii.webp',
    ),
    _craftable(
      name: 'Stable Stock III',
      slotType: ArcAttachmentSlotType.stock,
      benchLevel: 3,
      requirements: [_req(1, 'Mod Components'), _req(6, 'Duct Tape')],
      effects: [
        _effect(
          '50% reduced recoil recovery time',
          stat: 'recoilRecoveryTime',
          value: -50,
        ),
        _effect(
          '50% reduced dispersion recovery time',
          stat: 'dispersionRecoveryTime',
          value: -50,
        ),
        _effect(
          '20% increased equip time',
          stat: 'equipTime',
          value: 20,
          isPenalty: true,
        ),
        _effect(
          '20% increased unequip time',
          stat: 'unequipTime',
          value: 20,
          isPenalty: true,
        ),
      ],
      compatibleWeapons: [
        'Bobcat',
        'Vulcano',
        'Osprey',
        'Il Toro',
        'Ferro',
        'Renegade',
      ],
      assetPath: 'assets/arc_raiders/blueprints/stable-stock-iii.webp',
    ),
    _craftable(
      name: 'Lightweight Stock',
      slotType: ArcAttachmentSlotType.stock,
      benchLevel: 3,
      requirements: [_req(1, 'Mod Components'), _req(6, 'Duct Tape')],
      effects: [
        _effect(
          '50% increased recoil recovery duration',
          stat: 'recoilRecoveryDuration',
          value: 50,
          isPenalty: true,
        ),
        _effect(
          '50% increased vertical recoil control',
          stat: 'verticalRecoilControl',
          value: 50,
        ),
        _effect('30% reduced equip time', stat: 'equipTime', value: -30),
        _effect('30% reduced unequip time', stat: 'unequipTime', value: -30),
        _effect('200% increased ADS speed', stat: 'adsSpeed', value: 200),
      ],
      compatibleWeapons: ['Renegade', 'Vulcano'],
      assetPath: 'assets/arc_raiders/blueprints/lightweight-stock.webp',
    ),
    _craftable(
      name: 'Padded Stock',
      slotType: ArcAttachmentSlotType.stock,
      benchLevel: 3,
      requirements: [_req(1, 'Mod Components'), _req(6, 'Duct Tape')],
      effects: [
        _effect(
          '30% reduced horizontal recoil',
          stat: 'horizontalRecoil',
          value: -30,
        ),
        _effect(
          '30% reduced vertical recoil',
          stat: 'verticalRecoil',
          value: -30,
        ),
        _effect(
          '30% reduced per-shot dispersion',
          stat: 'perShotDispersion',
          value: -30,
        ),
        _effect(
          '20% increased equip time',
          stat: 'equipTime',
          value: 20,
          isPenalty: true,
        ),
        _effect(
          '20% increased unequip time',
          stat: 'unequipTime',
          value: 20,
          isPenalty: true,
        ),
        _effect(
          '30% reduced ADS speed',
          stat: 'adsSpeed',
          value: -30,
          isPenalty: true,
        ),
      ],
      compatibleWeapons: [
        'Rattler',
        'Il Toro',
        'Osprey',
        'Stitcher',
        'Ferro',
        'Arpeggio',
        'Renegade',
        'Vulcano',
      ],
      assetPath: 'assets/arc_raiders/blueprints/padded-stock.webp',
    ),
    _findOnly(
      name: 'Kinetic Converter',
      slotType: ArcAttachmentSlotType.converter,
      effects: [
        _effect('15% increased fire rate', stat: 'fireRate', value: 15),
        _effect(
          '20% increased horizontal recoil',
          stat: 'horizontalRecoil',
          value: 20,
          isPenalty: true,
        ),
        _effect(
          '20% increased vertical recoil',
          stat: 'verticalRecoil',
          value: 20,
          isPenalty: true,
        ),
      ],
      compatibleWeapons: [
        'Arpeggio',
        'Rattler',
        'Kettle',
        'Vulcano',
        'Osprey',
        'Torrente',
        'Ferro',
        'Il Toro',
      ],
      assetPath: 'assets/arc_raiders/blueprints/kinetic-converter.webp',
    ),
    _findOnly(
      name: 'Anvil Splitter',
      slotType: ArcAttachmentSlotType.special,
      effects: [
        _effect(
          '+3 projectiles per shot',
          stat: 'projectilesPerShot',
          value: 3,
          unit: 'projectiles',
        ),
        _effect(
          '60% reduced projectile damage',
          stat: 'projectileDamage',
          value: -60,
          isPenalty: true,
        ),
      ],
      compatibleWeapons: ['Anvil'],
      assetPath: 'assets/arc_raiders/blueprints/anvil-splitter.webp',
      notes: 'Uses the current Tech Mod slot through the special slot type.',
    ),
  ]);

  static final Map<String, ArcLoadoutAttachmentSpec> _byId = {
    for (final attachment in attachments) attachment.id: attachment,
  };

  static final Map<String, ArcLoadoutAttachmentSpec> _byName = {
    for (final attachment in attachments)
      _normalise(attachment.name): attachment,
  };

  static ArcLoadoutAttachmentSpec? attachmentForId(String id) {
    return _byId[id.trim().toLowerCase()];
  }

  static ArcLoadoutAttachmentSpec? attachmentForName(String name) {
    return _byName[_normalise(name)];
  }

  static List<ArcAttachmentSlotMatrixConflict> slotMatrixConflicts(
    Iterable<ArcLoadoutWeaponSpec> weapons,
  ) {
    final weaponsByName = <String, ArcLoadoutWeaponSpec>{
      for (final weapon in weapons) _normalise(weapon.name): weapon,
    };
    final conflicts = <ArcAttachmentSlotMatrixConflict>[];

    for (final attachment in attachments) {
      for (final weaponName in attachment.compatibleWeapons) {
        final weapon = weaponsByName[_normalise(weaponName)];
        if (weapon == null) continue;
        final supportsSlot = weapon.slots.any(
          (slotLabel) => _slotTypeForLabel(slotLabel) == attachment.slotType,
        );
        if (supportsSlot) continue;
        conflicts.add(
          ArcAttachmentSlotMatrixConflict(
            attachmentName: attachment.name,
            weaponName: weapon.name,
            attachmentSlot: attachment.slotType,
            weaponSlots: List<String>.unmodifiable(weapon.slots),
          ),
        );
      }
    }

    return List<ArcAttachmentSlotMatrixConflict>.unmodifiable(conflicts);
  }

  static String expectedBlueprintAssetPath(
    ArcLoadoutAttachmentSpec attachment,
  ) {
    switch (attachment.name) {
      case 'Anvil Splitter':
        return 'assets/arc_raiders/blueprints/anvil-splitter.webp';
      case 'Kinetic Converter':
        return 'assets/arc_raiders/blueprints/kinetic-converter.webp';
      default:
        return 'assets/arc_raiders/blueprints/${attachment.id}.webp';
    }
  }

  static ArcLoadoutAttachmentSpec _craftable({
    required String name,
    required ArcAttachmentSlotType slotType,
    required int benchLevel,
    required List<ArcCraftingRequirement> requirements,
    required List<ArcAttachmentEffect> effects,
    required List<String> compatibleWeapons,
    required String assetPath,
    String? notes,
  }) {
    return ArcLoadoutAttachmentSpec(
      id: _id(name),
      name: name,
      slotType: slotType,
      benchLevel: benchLevel,
      compatibleWeapons: List<String>.unmodifiable(compatibleWeapons),
      craftable: true,
      findOnly: false,
      craftingRequirements: List<ArcCraftingRequirement>.unmodifiable(
        requirements,
      ),
      effects: List<ArcAttachmentEffect>.unmodifiable(effects),
      materials: requirements
          .map((requirement) => requirement.label)
          .toList(growable: false),
      effect: effects.map((entry) => entry.description).join(' / '),
      blueprintItemId: _id(name),
      imageAssetPath: assetPath,
      notes: notes,
    );
  }

  static ArcLoadoutAttachmentSpec _findOnly({
    required String name,
    required ArcAttachmentSlotType slotType,
    required List<ArcAttachmentEffect> effects,
    required List<String> compatibleWeapons,
    required String assetPath,
    String? notes,
  }) {
    return ArcLoadoutAttachmentSpec(
      id: _id(name),
      name: name,
      slotType: slotType,
      benchLevel: 0,
      compatibleWeapons: List<String>.unmodifiable(compatibleWeapons),
      craftable: false,
      findOnly: true,
      craftingRequirements: const <ArcCraftingRequirement>[],
      effects: List<ArcAttachmentEffect>.unmodifiable(effects),
      materials: const <String>[],
      effect: effects.map((entry) => entry.description).join(' / '),
      blueprintItemId: _id(name),
      imageAssetPath: assetPath,
      notes:
          notes ??
          'Crafting materials are TBA in the supplied source; treated as find-only.',
    );
  }

  static ArcCraftingRequirement _req(int quantity, String itemName) {
    return ArcCraftingRequirement(itemName: itemName, quantity: quantity);
  }

  static ArcAttachmentEffect _effect(
    String description, {
    required String stat,
    required num value,
    String unit = 'percent',
    bool isPenalty = false,
  }) {
    return ArcAttachmentEffect(
      description: description,
      stat: stat,
      value: value,
      unit: unit,
      isPenalty: isPenalty,
    );
  }

  static ArcAttachmentSlotType _slotTypeForLabel(String label) {
    switch (_normaliseSlotLabel(label)) {
      case 'muzzle':
        return ArcAttachmentSlotType.muzzle;
      case 'shotgun muzzle':
      case 'shotgun choke':
        return ArcAttachmentSlotType.shotgunMuzzle;
      case 'underbarrel':
      case 'grip':
        return ArcAttachmentSlotType.underbarrel;
      case 'light magazine':
      case 'light mag':
        return ArcAttachmentSlotType.lightMagazine;
      case 'medium magazine':
      case 'medium mag':
      case 'magazine':
        return ArcAttachmentSlotType.mediumMagazine;
      case 'shotgun magazine':
      case 'shotgun mag':
        return ArcAttachmentSlotType.shotgunMagazine;
      case 'stock':
        return ArcAttachmentSlotType.stock;
      case 'barrel':
        return ArcAttachmentSlotType.barrel;
      case 'converter':
        return ArcAttachmentSlotType.converter;
      case 'tech mod':
      case 'utility':
      case 'special':
      default:
        return ArcAttachmentSlotType.special;
    }
  }

  static String _normaliseSlotLabel(String value) {
    final normalised = _normalise(value);
    return normalised.endsWith(' mod')
        ? normalised.substring(0, normalised.length - 4)
        : normalised;
  }

  static String _id(String name) {
    return _normalise(name).replaceAll(' ', '-');
  }

  static String _normalise(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
