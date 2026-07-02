import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';

class ArcLoadoutCompatibilityRegistry {
  const ArcLoadoutCompatibilityRegistry._();

  static String normalise(String value) => value.trim().toLowerCase();

  static ArcAttachmentSlotType slotTypeForLabel(String label) {
    switch (normalise(label)) {
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

  static ArcLoadoutAttachmentSpec? attachmentSpecForName(String name) {
    final normalised = normalise(name);
    if (normalised.isEmpty || normalised == 'empty slot') return null;

    for (final attachment in ArcLoadoutSeedData.attachments) {
      if (normalise(attachment.name) == normalised) return attachment;
    }

    return null;
  }

  static ArcLoadoutWeaponSpec weaponSpecForName(String weaponName) {
    final normalised = normalise(weaponName);

    for (final weapon in ArcLoadoutSeedData.weapons) {
      if (normalise(weapon.name) == normalised) return weapon;
    }

    return ArcLoadoutSeedData.weapons.first;
  }

  static List<String> slotsForWeapon(String weaponName) {
    final weapon = weaponSpecForName(weaponName);
    if (weapon.slots.isEmpty) return const <String>['Special'];
    return List<String>.unmodifiable(weapon.slots);
  }

  static bool weaponSupportsSlot({
    required String weaponName,
    required String slotLabel,
  }) {
    final slotType = slotTypeForLabel(slotLabel);
    return slotsForWeapon(
      weaponName,
    ).any((slot) => slotTypeForLabel(slot) == slotType);
  }

  static List<ArcLoadoutAttachmentSpec> compatibleAttachmentsForSlot({
    required String weaponName,
    required String slotLabel,
  }) {
    final slotType = slotTypeForLabel(slotLabel);

    return ArcLoadoutSeedData.attachments
        .where(
          (attachment) =>
              attachment.slotType == slotType &&
              attachment.supportsWeapon(weaponName),
        )
        .toList(growable: false);
  }

  static bool isAttachmentCompatible({
    required String weaponName,
    required String slotLabel,
    required String attachmentName,
  }) {
    final attachment = attachmentSpecForName(attachmentName);
    if (attachment == null) return attachmentName == 'Empty Slot';

    return attachment.slotType == slotTypeForLabel(slotLabel) &&
        attachment.supportsWeapon(weaponName);
  }
}
