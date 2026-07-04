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

enum ArcAttachmentSlotType {
  muzzle,
  shotgunMuzzle,
  underbarrel,
  lightMagazine,
  mediumMagazine,
  shotgunMagazine,
  stock,
  barrel,
  converter,
  special,
}

extension ArcAttachmentSlotTypeLabel on ArcAttachmentSlotType {
  String get label {
    switch (this) {
      case ArcAttachmentSlotType.muzzle:
        return 'Muzzle';
      case ArcAttachmentSlotType.shotgunMuzzle:
        return 'Shotgun Muzzle';
      case ArcAttachmentSlotType.underbarrel:
        return 'Grip';
      case ArcAttachmentSlotType.lightMagazine:
        return 'Light Mag';
      case ArcAttachmentSlotType.mediumMagazine:
        return 'Medium Mag';
      case ArcAttachmentSlotType.shotgunMagazine:
        return 'Shotgun Mag';
      case ArcAttachmentSlotType.stock:
        return 'Stock';
      case ArcAttachmentSlotType.barrel:
        return 'Barrel';
      case ArcAttachmentSlotType.converter:
        return 'Converter';
      case ArcAttachmentSlotType.special:
        return 'Special';
    }
  }
}

class ArcLoadoutAttachmentSpec {
  const ArcLoadoutAttachmentSpec({
    required this.name,
    required this.slotType,
    required this.benchLevel,
    required this.materials,
    required this.effect,
    required this.compatibleWeapons,
    this.imageAssetPath,
  });

  final String name;
  final ArcAttachmentSlotType slotType;
  final int benchLevel;
  final List<String> materials;
  final String effect;
  final List<String> compatibleWeapons;
  final String? imageAssetPath;

  bool supportsWeapon(String weaponName) {
    final normalised = weaponName.trim().toLowerCase();
    return compatibleWeapons.any(
      (weapon) => weapon.trim().toLowerCase() == normalised,
    );
  }

  String get benchLabel =>
      benchLevel <= 0 ? 'Special' : 'Bench Level $benchLevel';
  String get materialSummary =>
      materials.isEmpty ? 'Materials TBA' : materials.join(' • ');
}

class ArcSavedLoadoutSeed {
  const ArcSavedLoadoutSeed({
    required this.name,
    required this.category,
    required this.description,
    required this.augment,
    this.shield,
    required this.primaryWeapon,
    required this.secondaryWeapon,
    required this.equipment,
    required this.consumables,
  });

  final String name;
  final ArcLoadoutCategory category;
  final String description;
  final String augment;
  final String? shield;
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

class ArcSavedLoadout {
  const ArcSavedLoadout({
    required this.id,
    required this.name,
    required this.category,
    required this.playStyle,
    required this.augment,
    this.shield,
    required this.primaryWeapon,
    required this.primaryAttachments,
    required this.secondaryWeapon,
    required this.secondaryAttachments,
    required this.equipment,
    required this.consumables,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final ArcLoadoutCategory category;
  final ArcPlayerPlayStyle playStyle;
  final String augment;
  final String? shield;
  final String primaryWeapon;
  final List<String> primaryAttachments;
  final String secondaryWeapon;
  final List<String> secondaryAttachments;
  final List<String> equipment;
  final List<String> consumables;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category.name,
      'playStyle': playStyle.name,
      'augment': augment,
      'shield': shield,
      'primaryWeapon': primaryWeapon,
      'primaryAttachments': primaryAttachments,
      'secondaryWeapon': secondaryWeapon,
      'secondaryAttachments': secondaryAttachments,
      'equipment': equipment,
      'consumables': consumables,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static ArcSavedLoadout fromMap(String id, Map<String, dynamic> data) {
    ArcLoadoutCategory parseCategory(String? value) {
      return ArcLoadoutCategory.values.firstWhere(
        (category) => category.name == value,
        orElse: () => ArcLoadoutCategory.saved,
      );
    }

    ArcPlayerPlayStyle parsePlayStyle(String? value) {
      return ArcPlayerPlayStyle.values.firstWhere(
        (style) => style.name == value,
        orElse: () => ArcPlayerPlayStyle.balanced,
      );
    }

    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    List<String> parseList(dynamic value) {
      if (value is List) {
        return value.map((item) => item.toString()).toList(growable: false);
      }
      return const <String>[];
    }

    return ArcSavedLoadout(
      id: id,
      name: (data['name'] ?? 'Saved Loadout').toString(),
      category: parseCategory(data['category']?.toString()),
      playStyle: parsePlayStyle(data['playStyle']?.toString()),
      augment: (data['augment'] ?? 'Survivor').toString(),
      shield: (data['shield'] ?? 'Shield Level 2').toString(),
      primaryWeapon: (data['primaryWeapon'] ?? 'Anvil').toString(),
      primaryAttachments: parseList(data['primaryAttachments']),
      secondaryWeapon: (data['secondaryWeapon'] ?? 'Stitcher').toString(),
      secondaryAttachments: parseList(data['secondaryAttachments']),
      equipment: parseList(data['equipment']),
      consumables: parseList(data['consumables']),
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }
}
