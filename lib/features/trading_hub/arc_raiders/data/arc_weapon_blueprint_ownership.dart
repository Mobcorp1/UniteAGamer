import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';

/// Ownership lookup for weapon recipes. The fixed in-game Blueprint grid is
/// authoritative for its existing cells. Newly introduced recipes without grid
/// cells can be tracked separately in the SAME canonical user Blueprint store.
/// Missing records must never be reported as proof a player lacks a Blueprint.
class ArcWeaponBlueprintOwnership {
  const ArcWeaponBlueprintOwnership._();

  static const Set<String> supplementalBlueprintIds = <String>{
    'bantam',
    'stiletto',
  };

  static String? blueprintIdForName(String weaponName) {
    final name = weaponName.trim().toLowerCase();
    if (name.isEmpty) return null;
    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      if (blueprint.name.trim().toLowerCase() == name) {
        return blueprint.id;
      }
    }
    if (supplementalBlueprintIds.contains(name)) return name;
    return null;
  }

  static bool isSupplemental(String weaponName) =>
      supplementalBlueprintIds.contains(weaponName.trim().toLowerCase());

  static bool hasTrackedRecord(
    String weaponName,
    Map<String, ArcBlueprintState> states,
  ) {
    final id = blueprintIdForName(weaponName);
    return id != null && states.containsKey(id);
  }

  static bool isLearned(
    String weaponName,
    Map<String, ArcBlueprintState> states,
  ) {
    final id = blueprintIdForName(weaponName);
    return id != null && states[id]?.owned == true;
  }

  static String ownershipLabel(
    String weaponName,
    Map<String, ArcBlueprintState> states,
  ) {
    if (isLearned(weaponName, states)) return 'Blueprint owned';
    if (isSupplemental(weaponName) && !hasTrackedRecord(weaponName, states)) {
      return 'Blueprint not tracked - select to verify';
    }
    return 'Missing blueprint - selectable for planning';
  }
}
