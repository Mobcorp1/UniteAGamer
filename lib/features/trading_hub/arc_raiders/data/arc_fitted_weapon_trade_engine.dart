import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_compatibility_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_bundle_models.dart';

class ArcFittedWeaponTradeEngine {
  const ArcFittedWeaponTradeEngine();

  List<ArcLoadoutWeaponSpec> get weapons =>
      List<ArcLoadoutWeaponSpec>.unmodifiable(ArcLoadoutSeedData.weapons);

  ArcLoadoutWeaponSpec? weaponForName(String weaponName) {
    final normalised = weaponName.trim().toLowerCase();
    for (final weapon in ArcLoadoutSeedData.weapons) {
      if (weapon.name.trim().toLowerCase() == normalised) {
        return weapon;
      }
    }
    return null;
  }

  List<String> slotsForWeapon(String weaponName) =>
      ArcLoadoutCompatibilityRegistry.slotsForWeapon(weaponName);

  List<ArcLoadoutAttachmentSpec> attachmentsForSlot({
    required String weaponName,
    required String slotLabel,
  }) {
    return ArcLoadoutCompatibilityRegistry.compatibleAttachmentsForSlot(
      weaponName: weaponName,
      slotLabel: slotLabel,
    );
  }

  List<String> validate(ArcFittedWeaponConfiguration configuration) {
    final errors = <String>[];
    final weapon = weaponForName(configuration.weaponName);
    if (weapon == null) {
      return <String>['Select a valid weapon.'];
    }

    final canonicalSlots = weapon.slots;
    for (final slot in canonicalSlots) {
      final requirement = configuration.attachmentsBySlot[slot];
      if (requirement == null || requirement.trim().isEmpty) {
        errors.add('Choose a requirement for $slot.');
        continue;
      }
      if (requirement == ArcFittedWeaponConfiguration.anyCompatibleAttachment) {
        if (attachmentsForSlot(
          weaponName: weapon.name,
          slotLabel: slot,
        ).isEmpty) {
          errors.add(
            '${weapon.name} has no mapped compatible option for $slot.',
          );
        }
        continue;
      }
      if (!ArcLoadoutCompatibilityRegistry.isAttachmentCompatible(
        weaponName: weapon.name,
        slotLabel: slot,
        attachmentName: requirement,
      )) {
        errors.add('$requirement is not compatible with ${weapon.name} $slot.');
      }
    }

    final unknownSlots = configuration.attachmentsBySlot.keys.where(
      (slot) => !canonicalSlots.contains(slot),
    );
    for (final slot in unknownSlots) {
      errors.add('$slot is not a valid slot for ${weapon.name}.');
    }
    return List<String>.unmodifiable(errors);
  }

  bool matchesRequirement({
    required ArcFittedWeaponConfiguration requested,
    required ArcFittedWeaponConfiguration offered,
  }) {
    if (requested.weaponName.trim().toLowerCase() !=
        offered.weaponName.trim().toLowerCase()) {
      return false;
    }
    for (final entry in requested.attachmentsBySlot.entries) {
      final offeredAttachment = offered.attachmentsBySlot[entry.key];
      if (entry.value == ArcFittedWeaponConfiguration.anyCompatibleAttachment) {
        if (offeredAttachment == null ||
            offeredAttachment.isEmpty ||
            !ArcLoadoutCompatibilityRegistry.isAttachmentCompatible(
              weaponName: requested.weaponName,
              slotLabel: entry.key,
              attachmentName: offeredAttachment,
            )) {
          return false;
        }
      } else if (offeredAttachment != entry.value) {
        return false;
      }
    }
    return true;
  }

  String summary(ArcFittedWeaponConfiguration configuration) {
    if (configuration.attachmentsBySlot.isEmpty) {
      return '${configuration.weaponName} (no attachments)';
    }
    final parts = configuration.attachmentsBySlot.entries.map((entry) {
      final value =
          entry.value == ArcFittedWeaponConfiguration.anyCompatibleAttachment
          ? 'Any compatible'
          : entry.value;
      return '${entry.key}: $value';
    });
    return '${configuration.weaponName} — ${parts.join(' • ')}';
  }
}
