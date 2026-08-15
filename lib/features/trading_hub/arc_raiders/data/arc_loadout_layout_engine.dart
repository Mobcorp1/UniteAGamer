import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_compatibility_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';

class ArcQuickUseMigrationResult {
  const ArcQuickUseMigrationResult({
    required this.quickUse,
    required this.augment,
  });

  final List<String> quickUse;
  final String augment;
}

class ArcLoadoutLayoutEngine {
  const ArcLoadoutLayoutEngine._();

  static const String emptySlot = 'Empty Slot';
  static const int quickUseSlotCount = 6;

  static String normalise(String value) => value.trim().toLowerCase();

  static List<String> normalisedAttachmentList({
    required String weaponName,
    required List<String> savedAttachments,
  }) {
    final slots = ArcLoadoutCompatibilityRegistry.slotsForWeapon(weaponName);
    return List<String>.generate(slots.length, (index) {
      if (index >= savedAttachments.length) return emptySlot;

      final attachmentName = savedAttachments[index].trim();
      if (attachmentName.isEmpty || attachmentName == emptySlot) {
        return emptySlot;
      }

      return ArcLoadoutCompatibilityRegistry.isAttachmentCompatible(
            weaponName: weaponName,
            slotLabel: slots[index],
            attachmentName: attachmentName,
          )
          ? attachmentName
          : emptySlot;
    }, growable: true);
  }

  static List<String> attachmentsForWeaponChange({
    required String previousWeaponName,
    required String nextWeaponName,
    required List<String> previousAttachments,
  }) {
    final previousSlots = ArcLoadoutCompatibilityRegistry.slotsForWeapon(
      previousWeaponName,
    );
    final nextSlots = ArcLoadoutCompatibilityRegistry.slotsForWeapon(
      nextWeaponName,
    );
    final previousByType = <ArcAttachmentSlotType, List<String>>{};

    for (var index = 0; index < previousSlots.length; index++) {
      if (index >= previousAttachments.length) break;
      final attachmentName = previousAttachments[index].trim();
      if (attachmentName.isEmpty || attachmentName == emptySlot) continue;
      if (!ArcLoadoutCompatibilityRegistry.isAttachmentCompatible(
        weaponName: previousWeaponName,
        slotLabel: previousSlots[index],
        attachmentName: attachmentName,
      )) {
        continue;
      }

      final type = ArcLoadoutCompatibilityRegistry.slotTypeForLabel(
        previousSlots[index],
      );
      previousByType.putIfAbsent(type, () => <String>[]).add(attachmentName);
    }

    return List<String>.generate(nextSlots.length, (index) {
      final slotLabel = nextSlots[index];
      final type = ArcLoadoutCompatibilityRegistry.slotTypeForLabel(slotLabel);
      final candidates = previousByType[type];
      if (candidates == null || candidates.isEmpty) return emptySlot;

      final candidateIndex = candidates.indexWhere(
        (attachmentName) =>
            ArcLoadoutCompatibilityRegistry.isAttachmentCompatible(
              weaponName: nextWeaponName,
              slotLabel: slotLabel,
              attachmentName: attachmentName,
            ),
      );
      if (candidateIndex == -1) return emptySlot;

      return candidates.removeAt(candidateIndex);
    }, growable: true);
  }

  static List<ArcLoadoutOption> quickUseOptions() {
    final optionsByName = <String, ArcLoadoutOption>{};

    void add(ArcLoadoutOption option) {
      if (option.name.trim().isEmpty || _isShield(option.name)) return;
      optionsByName.putIfAbsent(normalise(option.name), () => option);
    }

    for (final option in ArcLoadoutSeedData.augments) {
      add(option);
    }
    for (final option in ArcLoadoutSeedData.equipment) {
      add(option);
    }
    for (final option in ArcLoadoutSeedData.consumables) {
      add(option);
    }
    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      final type = _quickUseTypeForBlueprintCategory(blueprint.category);
      if (type == null) continue;
      add(
        ArcLoadoutOption(
          name: blueprint.name,
          type: type,
          description: blueprint.intelHint.isEmpty
              ? '${blueprint.category} blueprint quick-use item.'
              : blueprint.intelHint,
          blueprintBased: true,
        ),
      );
    }

    final options = optionsByName.values.toList();
    options.sort((left, right) {
      final typeCompare = left.type.index.compareTo(right.type.index);
      if (typeCompare != 0) return typeCompare;
      return left.name.compareTo(right.name);
    });
    return List<ArcLoadoutOption>.unmodifiable(options);
  }

  static ArcLoadoutOption? quickUseOptionForName(String name) {
    final target = normalise(name);
    if (target.isEmpty || target == normalise(emptySlot)) return null;

    for (final option in quickUseOptions()) {
      if (normalise(option.name) == target) return option;
    }
    return null;
  }

  static ArcQuickUseMigrationResult normaliseQuickUseSlots({
    required List<String> savedItems,
    String? legacyAugment,
  }) {
    String? foundAugment;
    final otherItems = <String>[];

    // Identify the augment and separate other items
    for (final item in savedItems) {
      final value = item.trim();
      if (value.isEmpty || value == emptySlot) continue;

      final option = quickUseOptionForName(value);
      if (option == null) continue;

      if (option.type == ArcLoadoutSlotType.augment) {
        foundAugment ??= option.name;
      } else {
        otherItems.add(option.name);
      }
    }

    final augment = foundAugment ?? legacyAugment?.trim() ?? '';

    // Build exactly six quick-use slots from non-augment items
    final quickUse = List<String>.generate(quickUseSlotCount, (index) {
      if (index < otherItems.length) return otherItems[index];
      return emptySlot;
    });

    return ArcQuickUseMigrationResult(
      quickUse: List<String>.unmodifiable(quickUse),
      augment: augment,
    );
  }

  static bool _isShield(String name) {
    return normalise(name).contains('shield');
  }

  static ArcLoadoutSlotType? _quickUseTypeForBlueprintCategory(
    String category,
  ) {
    switch (normalise(category)) {
      case 'weapons':
      case 'attachments':
      case 'parts':
        return null;
      case 'tactical mods':
      case 'combat mods':
      case 'looting mods':
        return ArcLoadoutSlotType.augment;
      case 'consumables':
      case 'grenades':
        return ArcLoadoutSlotType.consumables;
      case 'gadgets':
      case 'utility':
      case 'support':
      case 'deployables':
      case 'riven tides':
        return ArcLoadoutSlotType.equipment;
      default:
        return null;
    }
  }
}
