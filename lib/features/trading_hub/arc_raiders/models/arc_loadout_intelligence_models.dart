import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';

enum ArcLoadoutBuildTier { value, meta }

extension ArcLoadoutBuildTierLabel on ArcLoadoutBuildTier {
  String get label =>
      this == ArcLoadoutBuildTier.meta ? 'Meta Build' : 'Value Build';
}

enum ArcLoadoutCombatFocus { pvp, balanced, pve }

extension ArcLoadoutCombatFocusLabel on ArcLoadoutCombatFocus {
  String get label {
    switch (this) {
      case ArcLoadoutCombatFocus.pvp:
        return 'PvP';
      case ArcLoadoutCombatFocus.balanced:
        return 'Balanced';
      case ArcLoadoutCombatFocus.pve:
        return 'PvE';
    }
  }

  ArcPlayerPlayStyle get playStyle {
    switch (this) {
      case ArcLoadoutCombatFocus.pvp:
        return ArcPlayerPlayStyle.pvp;
      case ArcLoadoutCombatFocus.balanced:
        return ArcPlayerPlayStyle.balanced;
      case ArcLoadoutCombatFocus.pve:
        return ArcPlayerPlayStyle.pve;
    }
  }
}

enum ArcWeaponRangeBand { close, medium, long, specialist }

class ArcLoadoutWeaponIntelligenceProfile {
  const ArcLoadoutWeaponIntelligenceProfile({
    required this.weaponName,
    required this.rangeBand,
    required this.pvpScore,
    required this.pveScore,
    required this.valueScore,
    required this.roleSummary,
    required this.pvpSecondaries,
    required this.balancedSecondaries,
    required this.pveSecondaries,
    this.notes = const <String>[],
  });

  final String weaponName;
  final ArcWeaponRangeBand rangeBand;
  final int pvpScore;
  final int pveScore;
  final int valueScore;
  final String roleSummary;
  final List<String> pvpSecondaries;
  final List<String> balancedSecondaries;
  final List<String> pveSecondaries;
  final List<String> notes;

  List<String> secondariesFor(ArcLoadoutCombatFocus focus) {
    switch (focus) {
      case ArcLoadoutCombatFocus.pvp:
        return pvpSecondaries;
      case ArcLoadoutCombatFocus.balanced:
        return balancedSecondaries;
      case ArcLoadoutCombatFocus.pve:
        return pveSecondaries;
    }
  }
}

class ArcLoadoutResourceNeed {
  const ArcLoadoutResourceNeed({
    required this.itemName,
    required this.quantity,
  });

  final String itemName;
  final int quantity;
}

class ArcGeneratedLoadoutPlan {
  const ArcGeneratedLoadoutPlan({
    required this.version,
    required this.researchedAt,
    required this.primaryWeapon,
    required this.primaryAttachments,
    required this.secondaryWeapon,
    required this.secondaryAttachments,
    required this.focus,
    required this.tier,
    required this.blueprintPriorities,
    required this.resourceNeeds,
    required this.rationale,
    required this.confidence,
  });

  final String version;
  final DateTime researchedAt;
  final String primaryWeapon;
  final List<String> primaryAttachments;
  final String secondaryWeapon;
  final List<String> secondaryAttachments;
  final ArcLoadoutCombatFocus focus;
  final ArcLoadoutBuildTier tier;
  final List<String> blueprintPriorities;
  final List<ArcLoadoutResourceNeed> resourceNeeds;
  final List<String> rationale;
  final String confidence;

  String get displayName => '${focus.label} $primaryWeapon ${tier.label}';
}
