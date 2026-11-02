import 'arc_stencil_catalogue.dart';

/// Compatibility for the 14 Frozen Trail Stencils (October 2026).
/// The three common paint finishes support the documented 20 regular guns;
/// special, energy and explosive platforms are not assumed to be eligible.
/// The numbering preserves the in-game Stencil grid and existing UAG saves.
class ArcWeaponStencilCompatibility {
  const ArcWeaponStencilCompatibility._();

  static const Set<String> _standardGuns = <String>{
    'anvil',
    'arpeggio',
    'bantam',
    'bettina',
    'bobcat',
    'burletta',
    'canto',
    'ferro',
    'hairpin',
    'il toro',
    'kettle',
    'osprey',
    'rattler',
    'renegade',
    'stiletto',
    'stitcher',
    'tempest',
    'torrente',
    'venator',
    'vulcano',
  };

  static const Map<int, Set<String>> _limited = <int, Set<String>>{
    2: <String>{'anvil', 'il toro', 'rattler'}, // Slipstream
    3: <String>{'anvil', 'rattler'}, // Tortoise
    4: <String>{'renegade'}, // Sacrifice
    5: <String>{'burletta', 'canto', 'ferro', 'hairpin', 'kettle', 'renegade'},
    6: <String>{
      'anvil',
      'arpeggio',
      'bantam',
      'bettina',
      'bobcat',
      'osprey',
      'venator',
      'vulcano',
    },
    7: <String>{
      'burletta',
      'il toro',
      'rattler',
      'stiletto',
      'tempest',
      'torrente',
    },
    8: <String>{'hullcracker'}, // Bulwark
    9: <String>{'tempest'}, // Dragon's Breath
    10: <String>{'osprey'}, // Empyrean
    11: <String>{'anvil'}, // Fortuna
    12: <String>{'bobcat'}, // Serac
  };

  static String _normalise(String weaponName) =>
      weaponName.trim().toLowerCase();

  static bool isCompatible({required String weaponName, required int? slot}) {
    if (slot == null || slot < 1 || slot > ArcStencilCatalogue.names.length) {
      return false;
    }
    final weapon = _normalise(weaponName);
    if (slot == 1 || slot == 13 || slot == 14) {
      return _standardGuns.contains(weapon);
    }
    return _limited[slot]?.contains(weapon) ?? false;
  }

  static List<int> slotsForWeapon(String weaponName) {
    return List<int>.unmodifiable(<int>[
      for (var slot = 1; slot <= ArcStencilCatalogue.names.length; slot++)
        if (isCompatible(weaponName: weaponName, slot: slot)) slot,
    ]);
  }

  static int? compatibleSavedSlot({
    required String weaponName,
    required int? slot,
  }) {
    return isCompatible(weaponName: weaponName, slot: slot) ? slot : null;
  }

  /// Actual Stencil label is Cerulean. Do not rename the existing WebP asset
  /// (curulean.webp) or stored grid slot: both are established UAG identifiers.
  static String displayName(int slot) {
    return slot == 6 ? 'Cerulean' : ArcStencilCatalogue.nameAt(slot);
  }
}
