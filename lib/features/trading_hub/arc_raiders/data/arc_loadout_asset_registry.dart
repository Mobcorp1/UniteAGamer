enum ArcLoadoutAssetKind {
  primaryWeapon,
  secondaryWeapon,
  attachment,
  equipment,
  augment,
}

class ArcLoadoutAssetRegistry {
  const ArcLoadoutAssetRegistry._();

  static const String fallbackAssetPath =
      'assets/arc_raiders/items/stash_expansion.webp';

  static const Map<String, String> _weaponAssets = {
    'anvil': 'assets/arc_raiders/blueprints/anvil.webp',
    'bobcat': 'assets/arc_raiders/blueprints/bobcat.webp',
    'burletta': 'assets/arc_raiders/blueprints/burletta.webp',
    'ferro': 'assets/images/arc_raiders/loadouts/weapons/ferro.webp',
    'harpin': 'assets/images/arc_raiders/loadouts/weapons/harpin.webp',
    'hairpin': 'assets/images/arc_raiders/loadouts/weapons/harpin.webp',
    'il toro': 'assets/arc_raiders/blueprints/il-toro.webp',
    'kettle': 'assets/images/arc_raiders/loadouts/weapons/kettle.webp',
    'osprey': 'assets/arc_raiders/blueprints/osprey.webp',
    'stitcher': 'assets/images/arc_raiders/loadouts/weapons/stitcher.webp',
    'tempest': 'assets/arc_raiders/blueprints/tempest.webp',
    'torrente': 'assets/arc_raiders/blueprints/torrente.webp',
    'venator': 'assets/arc_raiders/blueprints/venator.webp',
    'vulcano': 'assets/arc_raiders/blueprints/vulcano.webp',
  };

  static const Map<String, String> _attachmentAssets = {
    'anvil splitter': 'assets/arc_raiders/blueprints/anvil_splitter.webp',
    'angled grip ii': 'assets/arc_raiders/blueprints/angled-grip-ii.webp',
    'angled grip iii': 'assets/arc_raiders/blueprints/angled-grip-iii.webp',
    'compensator ii': 'assets/arc_raiders/blueprints/compensator-ii.webp',
    'compensator iii': 'assets/arc_raiders/blueprints/compensator-iii.webp',
    'extended barrel': 'assets/arc_raiders/blueprints/extended-barrel.webp',
    'extended light mag ii':
        'assets/arc_raiders/blueprints/extended-light-mag-ii.webp',
    'extended light mag iii':
        'assets/arc_raiders/blueprints/extended-light-mag-iii.webp',
    'extended medium mag ii':
        'assets/arc_raiders/blueprints/extended-medium-mag-ii.webp',
    'extended medium mag iii':
        'assets/arc_raiders/blueprints/extended-medium-mag-iii.webp',
    'extended shotgun mag ii':
        'assets/arc_raiders/blueprints/extended-shotgun-mag-ii.webp',
    'extended shotgun mag iii':
        'assets/arc_raiders/blueprints/extended-shotgun-mag-iii.webp',
    'kinetic converter': 'assets/arc_raiders/blueprints/kinetic_converter.webp',
    'lightweight stock': 'assets/arc_raiders/blueprints/lightweight-stock.webp',
    'muzzle brake ii': 'assets/arc_raiders/blueprints/muzzle-brake-ii.webp',
    'muzzle brake iii': 'assets/arc_raiders/blueprints/muzzle-brake-iii.webp',
    'padded stock': 'assets/arc_raiders/blueprints/padded-stock.webp',
    'shotgun choke ii': 'assets/arc_raiders/blueprints/shotgun-choke-ii.webp',
    'shotgun choke iii': 'assets/arc_raiders/blueprints/shotgun-choke-iii.webp',
    'shotgun silencer': 'assets/arc_raiders/blueprints/shotgun-silencer.webp',
    'silencer i': 'assets/arc_raiders/blueprints/silencer-i.webp',
    'silencer ii': 'assets/arc_raiders/blueprints/silencer-ii.webp',
    'stable stock ii': 'assets/arc_raiders/blueprints/stable-stock-ii.webp',
    'stable stock iii': 'assets/arc_raiders/blueprints/stable-stock-iii.webp',
    'vertical grip ii': 'assets/arc_raiders/blueprints/vertical-grip-ii.webp',
    'vertical grip iii': 'assets/arc_raiders/blueprints/vertical-grip-iii.webp',
  };

  static const Map<String, String> _equipmentAssets = {
    'lure grenade': 'assets/arc_raiders/blueprints/lure-grenade.webp',
    'pulse mine': 'assets/arc_raiders/blueprints/pulse-mine.webp',
    'shield level 2': 'assets/arc_raiders/blueprints/barricade-kit.webp',
    'snap hook': 'assets/arc_raiders/blueprints/snap-hook.webp',
    'trigger nade': 'assets/arc_raiders/blueprints/trigger-nade.webp',
    'triggernade': 'assets/arc_raiders/blueprints/trigger-nade.webp',
    'vita shot': 'assets/arc_raiders/blueprints/vita-shot.webp',
    'vita spray': 'assets/arc_raiders/blueprints/vita-spray.webp',
    'wolfpack': 'assets/arc_raiders/blueprints/wolfpack.webp',
  };

  static const Map<String, String> _augmentAssets = {
    'combat augment':
        'assets/arc_raiders/blueprints/combat-mk-3-aggressive.webp',
    'mobility augment':
        'assets/arc_raiders/blueprints/combat-mk-3-flanking.webp',
    'safekeeper': 'assets/arc_raiders/blueprints/looting-mk-3-safekeeper.webp',
    'survivor': 'assets/arc_raiders/blueprints/looting-mk-3-survivor.webp',
    'utility augment':
        'assets/arc_raiders/blueprints/tactical-mk-3-defensive.webp',
  };

  static String? assetFor({
    required String itemName,
    required ArcLoadoutAssetKind kind,
    String? explicitAssetPath,
    String? blueprintAssetPath,
  }) {
    final key = _normalise(itemName);
    if (key.isEmpty || key == 'empty slot') return null;

    final explicit = _cleanPath(explicitAssetPath);
    if (explicit != null) return explicit;

    final blueprint = _cleanPath(blueprintAssetPath);
    if (blueprint != null) return blueprint;

    return _assetMapFor(kind)[key] ?? fallbackAssetPath;
  }

  static String? _cleanPath(String? path) {
    final value = path?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  static String _normalise(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static Map<String, String> _assetMapFor(ArcLoadoutAssetKind kind) {
    switch (kind) {
      case ArcLoadoutAssetKind.primaryWeapon:
      case ArcLoadoutAssetKind.secondaryWeapon:
        return _weaponAssets;
      case ArcLoadoutAssetKind.attachment:
        return _attachmentAssets;
      case ArcLoadoutAssetKind.equipment:
        return _equipmentAssets;
      case ArcLoadoutAssetKind.augment:
        return _augmentAssets;
    }
  }
}
