import 'package:flutter/foundation.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_compatibility_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_layout_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_weapon_attachment_database.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';

enum ArcBlueprintLoadoutKind { weapon, attachment, quickUse }

enum ArcBlueprintLoadoutDestinationType {
  primaryWeapon,
  secondaryWeapon,
  primaryAttachment,
  secondaryAttachment,
  quickUse,
}

@immutable
class ArcBlueprintLoadoutCandidate {
  const ArcBlueprintLoadoutCandidate({
    required this.itemName,
    required this.kind,
    this.weapon,
    this.attachment,
    this.quickUseOption,
  });

  final String itemName;
  final ArcBlueprintLoadoutKind kind;
  final ArcLoadoutWeaponSpec? weapon;
  final ArcLoadoutAttachmentSpec? attachment;
  final ArcLoadoutOption? quickUseOption;

  String get kindLabel {
    switch (kind) {
      case ArcBlueprintLoadoutKind.weapon:
        return 'Weapon';
      case ArcBlueprintLoadoutKind.attachment:
        return 'Attachment';
      case ArcBlueprintLoadoutKind.quickUse:
        return 'Quick Use';
    }
  }
}

@immutable
class ArcBlueprintLoadoutDestination {
  const ArcBlueprintLoadoutDestination({
    required this.type,
    required this.label,
    required this.currentItem,
    this.index,
  });

  final ArcBlueprintLoadoutDestinationType type;
  final String label;
  final String currentItem;
  final int? index;

  bool get replacesOccupiedSlot =>
      currentItem.trim().isNotEmpty &&
      currentItem != ArcLoadoutLayoutEngine.emptySlot;
}

class ArcBlueprintLoadoutBridge {
  const ArcBlueprintLoadoutBridge._();

  static String normalise(String value) => value.trim().toLowerCase();

  static ArcBlueprintLoadoutCandidate? candidateFor(ArcBlueprint blueprint) {
    final name = blueprint.name.trim();
    if (name.isEmpty) return null;

    if (normalise(blueprint.category) == 'weapons') {
      final weapon = _weaponForName(name);
      if (weapon != null) {
        return ArcBlueprintLoadoutCandidate(
          itemName: weapon.name,
          kind: ArcBlueprintLoadoutKind.weapon,
          weapon: weapon,
        );
      }
    }

    if (normalise(blueprint.category) == 'attachments') {
      final attachment = ArcWeaponAttachmentDatabase.attachmentForName(name);
      if (attachment != null) {
        return ArcBlueprintLoadoutCandidate(
          itemName: attachment.name,
          kind: ArcBlueprintLoadoutKind.attachment,
          attachment: attachment,
        );
      }
    }

    final quickUseOption = ArcLoadoutLayoutEngine.quickUseOptionForName(name);
    if (quickUseOption != null) {
      return ArcBlueprintLoadoutCandidate(
        itemName: quickUseOption.name,
        kind: ArcBlueprintLoadoutKind.quickUse,
        quickUseOption: quickUseOption,
      );
    }

    return null;
  }

  static bool isSelected({
    required ArcBlueprint blueprint,
    required ArcSavedLoadout? loadout,
  }) {
    final candidate = candidateFor(blueprint);
    if (candidate == null || loadout == null) return false;
    return _containsCandidate(loadout, candidate);
  }

  static ArcSavedLoadout baseLoadout(ArcSavedLoadout? current) {
    if (current != null) return current;
    final now = DateTime.now();
    const quickUse = <String>[
      'Survivor',
      'Snap Hook',
      'Vita Shot',
      'Lure Grenade',
      ArcLoadoutLayoutEngine.emptySlot,
      ArcLoadoutLayoutEngine.emptySlot,
    ];
    final migration = ArcLoadoutLayoutEngine.normaliseQuickUseSlots(
      savedItems: quickUse,
      legacyAugment: 'Survivor',
    );

    return ArcSavedLoadout(
      id: 'favourite-loadout',
      name: 'Favourite Raider Build',
      category: ArcLoadoutCategory.saved,
      playStyle: ArcPlayerPlayStyle.balanced,
      augment: migration.augment,
      shield: 'Shield Level 2',
      primaryWeapon: 'Anvil',
      primaryAttachments: ArcLoadoutLayoutEngine.normalisedAttachmentList(
        weaponName: 'Anvil',
        savedAttachments: const <String>[
          ArcLoadoutLayoutEngine.emptySlot,
          ArcLoadoutLayoutEngine.emptySlot,
        ],
      ),
      secondaryWeapon: 'Stitcher',
      secondaryAttachments: ArcLoadoutLayoutEngine.normalisedAttachmentList(
        weaponName: 'Stitcher',
        savedAttachments: const <String>[
          ArcLoadoutLayoutEngine.emptySlot,
          ArcLoadoutLayoutEngine.emptySlot,
          ArcLoadoutLayoutEngine.emptySlot,
          ArcLoadoutLayoutEngine.emptySlot,
        ],
      ),
      equipment: const <String>['Snap Hook'],
      consumables: const <String>['Vita Shot', 'Lure Grenade'],
      quickUse: migration.quickUse,
      createdAt: now,
      updatedAt: now,
    );
  }

  static List<ArcBlueprintLoadoutDestination> destinationsFor({
    required ArcBlueprint blueprint,
    required ArcSavedLoadout loadout,
    bool includeReplacementQuickUseSlots = true,
  }) {
    final candidate = candidateFor(blueprint);
    if (candidate == null) return const <ArcBlueprintLoadoutDestination>[];

    switch (candidate.kind) {
      case ArcBlueprintLoadoutKind.weapon:
        return [
          ArcBlueprintLoadoutDestination(
            type: ArcBlueprintLoadoutDestinationType.primaryWeapon,
            label: 'Primary Weapon',
            currentItem: loadout.primaryWeapon,
          ),
          ArcBlueprintLoadoutDestination(
            type: ArcBlueprintLoadoutDestinationType.secondaryWeapon,
            label: 'Secondary Weapon',
            currentItem: loadout.secondaryWeapon,
          ),
        ];
      case ArcBlueprintLoadoutKind.attachment:
        return _attachmentDestinations(candidate, loadout);
      case ArcBlueprintLoadoutKind.quickUse:
        return _quickUseDestinations(
          loadout,
          includeReplacementSlots: includeReplacementQuickUseSlots,
        );
    }
  }

  static ArcSavedLoadout applyDestination({
    required ArcBlueprint blueprint,
    required ArcSavedLoadout loadout,
    required ArcBlueprintLoadoutDestination destination,
  }) {
    final candidate = candidateFor(blueprint);
    if (candidate == null) return loadout;

    switch (destination.type) {
      case ArcBlueprintLoadoutDestinationType.primaryWeapon:
        return _copyLoadout(
          loadout,
          primaryWeapon: candidate.itemName,
          primaryAttachments: ArcLoadoutLayoutEngine.attachmentsForWeaponChange(
            previousWeaponName: loadout.primaryWeapon,
            nextWeaponName: candidate.itemName,
            previousAttachments: loadout.primaryAttachments,
          ),
        );
      case ArcBlueprintLoadoutDestinationType.secondaryWeapon:
        return _copyLoadout(
          loadout,
          secondaryWeapon: candidate.itemName,
          secondaryAttachments:
              ArcLoadoutLayoutEngine.attachmentsForWeaponChange(
                previousWeaponName: loadout.secondaryWeapon,
                nextWeaponName: candidate.itemName,
                previousAttachments: loadout.secondaryAttachments,
              ),
        );
      case ArcBlueprintLoadoutDestinationType.primaryAttachment:
        return _copyLoadout(
          loadout,
          primaryAttachments: _replaceAt(
            loadout.primaryAttachments,
            destination.index ?? 0,
            candidate.itemName,
          ),
        );
      case ArcBlueprintLoadoutDestinationType.secondaryAttachment:
        return _copyLoadout(
          loadout,
          secondaryAttachments: _replaceAt(
            loadout.secondaryAttachments,
            destination.index ?? 0,
            candidate.itemName,
          ),
        );
      case ArcBlueprintLoadoutDestinationType.quickUse:
        final nextQuickUse = _replaceAt(
          _normalisedQuickUse(loadout.quickUse),
          destination.index ?? 0,
          candidate.itemName,
        );
        return _copyLoadout(loadout, quickUse: nextQuickUse);
    }
  }

  static ArcSavedLoadout remove({
    required ArcBlueprint blueprint,
    required ArcSavedLoadout loadout,
  }) {
    final candidate = candidateFor(blueprint);
    if (candidate == null) return loadout;
    final item = candidate.itemName;

    switch (candidate.kind) {
      case ArcBlueprintLoadoutKind.weapon:
        final primary = normalise(loadout.primaryWeapon) == normalise(item);
        final secondary = normalise(loadout.secondaryWeapon) == normalise(item);
        return _copyLoadout(
          loadout,
          primaryWeapon: primary
              ? _fallbackWeapon(excluding: item, preferred: 'Anvil')
              : loadout.primaryWeapon,
          primaryAttachments: primary
              ? ArcLoadoutLayoutEngine.normalisedAttachmentList(
                  weaponName: _fallbackWeapon(
                    excluding: item,
                    preferred: 'Anvil',
                  ),
                  savedAttachments: const <String>[],
                )
              : loadout.primaryAttachments,
          secondaryWeapon: secondary
              ? _fallbackWeapon(excluding: item, preferred: 'Stitcher')
              : loadout.secondaryWeapon,
          secondaryAttachments: secondary
              ? ArcLoadoutLayoutEngine.normalisedAttachmentList(
                  weaponName: _fallbackWeapon(
                    excluding: item,
                    preferred: 'Stitcher',
                  ),
                  savedAttachments: const <String>[],
                )
              : loadout.secondaryAttachments,
        );
      case ArcBlueprintLoadoutKind.attachment:
        return _copyLoadout(
          loadout,
          primaryAttachments: _clearMatches(loadout.primaryAttachments, item),
          secondaryAttachments: _clearMatches(
            loadout.secondaryAttachments,
            item,
          ),
        );
      case ArcBlueprintLoadoutKind.quickUse:
        return _copyLoadout(
          loadout,
          quickUse: _clearMatches(_normalisedQuickUse(loadout.quickUse), item),
        );
    }
  }

  static bool _containsCandidate(
    ArcSavedLoadout loadout,
    ArcBlueprintLoadoutCandidate candidate,
  ) {
    final item = normalise(candidate.itemName);
    switch (candidate.kind) {
      case ArcBlueprintLoadoutKind.weapon:
        return normalise(loadout.primaryWeapon) == item ||
            normalise(loadout.secondaryWeapon) == item;
      case ArcBlueprintLoadoutKind.attachment:
        return loadout.primaryAttachments.any(
              (attachment) => normalise(attachment) == item,
            ) ||
            loadout.secondaryAttachments.any(
              (attachment) => normalise(attachment) == item,
            );
      case ArcBlueprintLoadoutKind.quickUse:
        return loadout.quickUse.any((slot) => normalise(slot) == item) ||
            loadout.equipment.any((slot) => normalise(slot) == item) ||
            loadout.consumables.any((slot) => normalise(slot) == item);
    }
  }

  static ArcLoadoutWeaponSpec? _weaponForName(String name) {
    final target = normalise(name);
    for (final weapon in ArcLoadoutSeedData.weapons) {
      if (normalise(weapon.name) == target) return weapon;
    }
    return null;
  }

  static List<ArcBlueprintLoadoutDestination> _attachmentDestinations(
    ArcBlueprintLoadoutCandidate candidate,
    ArcSavedLoadout loadout,
  ) {
    final attachment = candidate.attachment;
    if (attachment == null) return const <ArcBlueprintLoadoutDestination>[];
    final destinations = <ArcBlueprintLoadoutDestination>[];

    void addForWeapon({
      required String weaponName,
      required List<String> attachments,
      required bool primary,
    }) {
      final slots = ArcLoadoutCompatibilityRegistry.slotsForWeapon(weaponName);
      for (var index = 0; index < slots.length; index++) {
        final slot = slots[index];
        final compatible =
            ArcLoadoutCompatibilityRegistry.isAttachmentCompatible(
              weaponName: weaponName,
              slotLabel: slot,
              attachmentName: attachment.name,
            );
        if (!compatible) continue;
        destinations.add(
          ArcBlueprintLoadoutDestination(
            type: primary
                ? ArcBlueprintLoadoutDestinationType.primaryAttachment
                : ArcBlueprintLoadoutDestinationType.secondaryAttachment,
            index: index,
            label: '${primary ? 'Primary' : 'Secondary'} $slot',
            currentItem: index < attachments.length
                ? attachments[index]
                : ArcLoadoutLayoutEngine.emptySlot,
          ),
        );
      }
    }

    addForWeapon(
      weaponName: loadout.primaryWeapon,
      attachments: loadout.primaryAttachments,
      primary: true,
    );
    addForWeapon(
      weaponName: loadout.secondaryWeapon,
      attachments: loadout.secondaryAttachments,
      primary: false,
    );

    return List<ArcBlueprintLoadoutDestination>.unmodifiable(destinations);
  }

  static List<ArcBlueprintLoadoutDestination> _quickUseDestinations(
    ArcSavedLoadout loadout, {
    required bool includeReplacementSlots,
  }) {
    final quickUse = _normalisedQuickUse(loadout.quickUse);
    final destinations = <ArcBlueprintLoadoutDestination>[];

    for (var index = 0; index < quickUse.length; index++) {
      if (quickUse[index] == ArcLoadoutLayoutEngine.emptySlot) {
        destinations.add(
          ArcBlueprintLoadoutDestination(
            type: ArcBlueprintLoadoutDestinationType.quickUse,
            index: index,
            label: 'Quick Use ${index + 1}',
            currentItem: quickUse[index],
          ),
        );
      }
    }

    if (destinations.isNotEmpty || !includeReplacementSlots) {
      return List<ArcBlueprintLoadoutDestination>.unmodifiable(destinations);
    }

    for (var index = 0; index < quickUse.length; index++) {
      destinations.add(
        ArcBlueprintLoadoutDestination(
          type: ArcBlueprintLoadoutDestinationType.quickUse,
          index: index,
          label: 'Replace Quick Use ${index + 1}',
          currentItem: quickUse[index],
        ),
      );
    }

    return List<ArcBlueprintLoadoutDestination>.unmodifiable(destinations);
  }

  static List<String> _normalisedQuickUse(List<String> quickUse) {
    return ArcLoadoutLayoutEngine.normaliseQuickUseSlots(
      savedItems: quickUse,
    ).quickUse;
  }

  static List<String> _replaceAt(List<String> source, int index, String value) {
    final next = List<String>.from(source);
    while (next.length <= index) {
      next.add(ArcLoadoutLayoutEngine.emptySlot);
    }
    next[index] = value;
    return List<String>.unmodifiable(next);
  }

  static List<String> _clearMatches(List<String> source, String itemName) {
    final target = normalise(itemName);
    return source
        .map(
          (item) => normalise(item) == target
              ? ArcLoadoutLayoutEngine.emptySlot
              : item,
        )
        .toList(growable: false);
  }

  static String _fallbackWeapon({
    required String excluding,
    required String preferred,
  }) {
    if (normalise(preferred) != normalise(excluding)) return preferred;
    return ArcLoadoutSeedData.weapons
        .firstWhere((weapon) => normalise(weapon.name) != normalise(excluding))
        .name;
  }

  static ArcSavedLoadout _copyLoadout(
    ArcSavedLoadout loadout, {
    String? primaryWeapon,
    List<String>? primaryAttachments,
    String? secondaryWeapon,
    List<String>? secondaryAttachments,
    List<String>? quickUse,
  }) {
    final nextQuickUse = quickUse == null
        ? loadout.quickUse
        : ArcLoadoutLayoutEngine.normaliseQuickUseSlots(
            savedItems: quickUse,
          ).quickUse;
    final equipment = nextQuickUse
        .where((slot) {
          final option = ArcLoadoutLayoutEngine.quickUseOptionForName(slot);
          return option?.type == ArcLoadoutSlotType.equipment;
        })
        .where((slot) => slot != ArcLoadoutLayoutEngine.emptySlot)
        .toList(growable: false);
    final consumables = nextQuickUse
        .where((slot) {
          final option = ArcLoadoutLayoutEngine.quickUseOptionForName(slot);
          return option?.type == ArcLoadoutSlotType.consumables;
        })
        .where((slot) => slot != ArcLoadoutLayoutEngine.emptySlot)
        .toList(growable: false);
    final augment = nextQuickUse
        .map(ArcLoadoutLayoutEngine.quickUseOptionForName)
        .whereType<ArcLoadoutOption>()
        .firstWhere(
          (option) => option.type == ArcLoadoutSlotType.augment,
          orElse: () => const ArcLoadoutOption(
            name: '',
            type: ArcLoadoutSlotType.augment,
            description: '',
          ),
        )
        .name;

    return ArcSavedLoadout(
      id: loadout.id,
      name: loadout.name,
      category: loadout.category,
      playStyle: loadout.playStyle,
      augment: augment,
      shield: loadout.shield,
      primaryWeapon: primaryWeapon ?? loadout.primaryWeapon,
      primaryAttachments: List<String>.unmodifiable(
        primaryAttachments ?? loadout.primaryAttachments,
      ),
      secondaryWeapon: secondaryWeapon ?? loadout.secondaryWeapon,
      secondaryAttachments: List<String>.unmodifiable(
        secondaryAttachments ?? loadout.secondaryAttachments,
      ),
      equipment: equipment,
      consumables: consumables,
      quickUse: List<String>.unmodifiable(nextQuickUse),
      createdAt: loadout.createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
