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

  Map<String, dynamic> toMap() => <String, dynamic>{
    'itemName': itemName,
    'quantity': quantity,
  };

  static ArcLoadoutResourceNeed fromMap(Map<String, dynamic> data) {
    return ArcLoadoutResourceNeed(
      itemName: (data['itemName'] ?? '').toString(),
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
    );
  }
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

  Map<String, dynamic> toMap() => <String, dynamic>{
    'version': version,
    'researchedAt': researchedAt.toIso8601String(),
    'primaryWeapon': primaryWeapon,
    'primaryAttachments': primaryAttachments,
    'secondaryWeapon': secondaryWeapon,
    'secondaryAttachments': secondaryAttachments,
    'focus': focus.name,
    'tier': tier.name,
    'blueprintPriorities': blueprintPriorities,
    'resourceNeeds': resourceNeeds.map((item) => item.toMap()).toList(),
    'rationale': rationale,
    'confidence': confidence,
  };

  static ArcGeneratedLoadoutPlan? fromMap(dynamic value) {
    if (value is! Map) return null;
    final data = Map<String, dynamic>.from(value);
    final primaryWeapon = (data['primaryWeapon'] ?? '').toString().trim();
    final secondaryWeapon = (data['secondaryWeapon'] ?? '').toString().trim();
    if (primaryWeapon.isEmpty || secondaryWeapon.isEmpty) return null;

    List<String> strings(dynamic raw) => raw is List
        ? raw.map((item) => item.toString()).toList(growable: false)
        : const <String>[];

    final resources = <ArcLoadoutResourceNeed>[];
    final rawResources = data['resourceNeeds'];
    if (rawResources is List) {
      for (final item in rawResources) {
        if (item is Map) {
          resources.add(
            ArcLoadoutResourceNeed.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return ArcGeneratedLoadoutPlan(
      version: (data['version'] ?? 'legacy').toString(),
      researchedAt:
          DateTime.tryParse((data['researchedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      primaryWeapon: primaryWeapon,
      primaryAttachments: strings(data['primaryAttachments']),
      secondaryWeapon: secondaryWeapon,
      secondaryAttachments: strings(data['secondaryAttachments']),
      focus: ArcLoadoutCombatFocus.values.firstWhere(
        (item) => item.name == data['focus']?.toString(),
        orElse: () => ArcLoadoutCombatFocus.balanced,
      ),
      tier: ArcLoadoutBuildTier.values.firstWhere(
        (item) => item.name == data['tier']?.toString(),
        orElse: () => ArcLoadoutBuildTier.value,
      ),
      blueprintPriorities: strings(data['blueprintPriorities']),
      resourceNeeds: List<ArcLoadoutResourceNeed>.unmodifiable(resources),
      rationale: strings(data['rationale']),
      confidence: (data['confidence'] ?? 'Unspecified').toString(),
    );
  }
}
