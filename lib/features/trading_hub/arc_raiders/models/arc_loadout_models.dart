enum ArcLoadoutCategory { saved, meta, pvp, pve, balanced }

extension ArcLoadoutCategoryLabel on ArcLoadoutCategory {
  String get label {
    switch (this) {
      case ArcLoadoutCategory.saved:
        return 'Saved Loadouts';
      case ArcLoadoutCategory.meta:
        return 'Meta Loadouts';
      case ArcLoadoutCategory.pvp:
        return 'PvP Loadouts';
      case ArcLoadoutCategory.pve:
        return 'PvE Loadouts';
      case ArcLoadoutCategory.balanced:
        return 'Balanced PvP/PvE';
    }
  }

  String get shortLabel {
    switch (this) {
      case ArcLoadoutCategory.saved:
        return 'Saved';
      case ArcLoadoutCategory.meta:
        return 'Meta';
      case ArcLoadoutCategory.pvp:
        return 'PvP';
      case ArcLoadoutCategory.pve:
        return 'PvE';
      case ArcLoadoutCategory.balanced:
        return 'Balanced';
    }
  }
}

enum ArcLoadoutSlotType {
  augment,
  primaryWeapon,
  primaryAttachments,
  secondaryWeapon,
  secondaryAttachments,
  equipment,
  consumables,
}

extension ArcLoadoutSlotTypeLabel on ArcLoadoutSlotType {
  String get label {
    switch (this) {
      case ArcLoadoutSlotType.augment:
        return 'Augment';
      case ArcLoadoutSlotType.primaryWeapon:
        return 'Primary Weapon';
      case ArcLoadoutSlotType.primaryAttachments:
        return 'Primary Attachments';
      case ArcLoadoutSlotType.secondaryWeapon:
        return 'Secondary Weapon';
      case ArcLoadoutSlotType.secondaryAttachments:
        return 'Secondary Attachments';
      case ArcLoadoutSlotType.equipment:
        return 'Equipment';
      case ArcLoadoutSlotType.consumables:
        return 'Consumables';
    }
  }
}

class ArcLoadoutWeaponSpec {
  const ArcLoadoutWeaponSpec({
    required this.name,
    required this.category,
    required this.role,
    required this.slots,
    this.craftable = false,
    this.gunsmithLevel,
    this.blueprintBased = false,
    this.notes,
  });

  final String name;
  final String category;
  final String role;
  final List<String> slots;
  final bool craftable;
  final int? gunsmithLevel;
  final bool blueprintBased;
  final String? notes;
}

class ArcLoadoutOption {
  const ArcLoadoutOption({
    required this.name,
    required this.type,
    required this.description,
    this.blueprintBased = false,
    this.craftable = false,
    this.gunsmithLevel,
  });

  final String name;
  final ArcLoadoutSlotType type;
  final String description;
  final bool blueprintBased;
  final bool craftable;
  final int? gunsmithLevel;
}

class ArcSavedLoadoutSeed {
  const ArcSavedLoadoutSeed({
    required this.name,
    required this.category,
    required this.description,
    required this.augment,
    required this.primaryWeapon,
    required this.secondaryWeapon,
    required this.equipment,
    required this.consumables,
  });

  final String name;
  final ArcLoadoutCategory category;
  final String description;
  final String augment;
  final String primaryWeapon;
  final String secondaryWeapon;
  final List<String> equipment;
  final List<String> consumables;
}

enum ArcPlayerPlayStyle {
  pve,
  pvp,
  balanced,
  blueprintHunter,
  lootRunner,
  trader,
  squadSupport,
  soloSurvivor,
}

extension ArcPlayerPlayStyleLabel on ArcPlayerPlayStyle {
  String get label {
    switch (this) {
      case ArcPlayerPlayStyle.pve:
        return 'PvE-focused';
      case ArcPlayerPlayStyle.pvp:
        return 'PvP-focused';
      case ArcPlayerPlayStyle.balanced:
        return 'Balanced PvP/PvE';
      case ArcPlayerPlayStyle.blueprintHunter:
        return 'Blueprint hunter';
      case ArcPlayerPlayStyle.lootRunner:
        return 'Loot runner';
      case ArcPlayerPlayStyle.trader:
        return 'Trader';
      case ArcPlayerPlayStyle.squadSupport:
        return 'Squad support';
      case ArcPlayerPlayStyle.soloSurvivor:
        return 'Solo survivor';
    }
  }

  String get shortLabel {
    switch (this) {
      case ArcPlayerPlayStyle.pve:
        return 'PvE';
      case ArcPlayerPlayStyle.pvp:
        return 'PvP';
      case ArcPlayerPlayStyle.balanced:
        return 'Balanced';
      case ArcPlayerPlayStyle.blueprintHunter:
        return 'Blueprints';
      case ArcPlayerPlayStyle.lootRunner:
        return 'Loot';
      case ArcPlayerPlayStyle.trader:
        return 'Trader';
      case ArcPlayerPlayStyle.squadSupport:
        return 'Support';
      case ArcPlayerPlayStyle.soloSurvivor:
        return 'Solo';
    }
  }
}
