import 'dart:math' as math;

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_intelligence_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_weapon_attachment_database.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';

class ArcLoadoutIntelligenceEngine {
  const ArcLoadoutIntelligenceEngine._();

  static ArcGeneratedLoadoutPlan generate({
    required String primaryWeapon,
    required ArcLoadoutCombatFocus focus,
    required ArcLoadoutBuildTier tier,
    String? secondaryWeaponOverride,
  }) {
    final primaryProfile = ArcLoadoutIntelligenceCatalog.profileFor(
      primaryWeapon,
    );
    final secondaryOptions = secondaryOptionsFor(
      primaryWeapon: primaryWeapon,
      focus: focus,
      tier: tier,
    );
    final requestedSecondary = secondaryWeaponOverride?.trim();
    final secondaryWeapon =
        requestedSecondary != null &&
            secondaryOptions.contains(requestedSecondary)
        ? requestedSecondary
        : secondaryOptions.first;
    final primaryAttachments = _attachmentsFor(
      weaponName: primaryWeapon,
      focus: focus,
      tier: tier,
    );
    final secondaryAttachments = _attachmentsFor(
      weaponName: secondaryWeapon,
      focus: focus,
      tier: tier,
    );
    final resources = _aggregateResources(<String>[
      ...primaryAttachments,
      ...secondaryAttachments,
    ]);
    final blueprints = _blueprintPriorities(
      primaryWeapon: primaryWeapon,
      secondaryWeapon: secondaryWeapon,
      primaryAttachments: primaryAttachments,
      secondaryAttachments: secondaryAttachments,
    );

    return ArcGeneratedLoadoutPlan(
      version: ArcLoadoutIntelligenceCatalog.version,
      researchedAt: ArcLoadoutIntelligenceCatalog.researchedAt,
      primaryWeapon: primaryWeapon,
      primaryAttachments: List<String>.unmodifiable(primaryAttachments),
      secondaryWeapon: secondaryWeapon,
      secondaryAttachments: List<String>.unmodifiable(secondaryAttachments),
      focus: focus,
      tier: tier,
      blueprintPriorities: List<String>.unmodifiable(blueprints),
      resourceNeeds: List<ArcLoadoutResourceNeed>.unmodifiable(resources),
      rationale: List<String>.unmodifiable(<String>[
        primaryProfile.roleSummary,
        '$secondaryWeapon covers the primary weapon\'s range, sustain or target-type weakness.',
        tier == ArcLoadoutBuildTier.meta
            ? 'Uses the strongest compatible mapped attachments, accepting higher bench and replacement cost.'
            : 'Prioritises low-bench, craftable attachments and strong performance per material invested.',
      ]),
      confidence: 'Research-backed v1; validate after each balance patch.',
    );
  }

  static List<String> secondaryOptionsFor({
    required String primaryWeapon,
    required ArcLoadoutCombatFocus focus,
    required ArcLoadoutBuildTier tier,
  }) {
    final profile = ArcLoadoutIntelligenceCatalog.profileFor(primaryWeapon);
    final knownWeapons = ArcLoadoutSeedData.weapons
        .map((weapon) => weapon.name)
        .toSet();
    final candidates = profile
        .secondariesFor(focus)
        .where(
          (weapon) => weapon != primaryWeapon && knownWeapons.contains(weapon),
        )
        .toSet()
        .toList(growable: true);

    if (candidates.isEmpty) {
      final fallback = knownWeapons.firstWhere(
        (weapon) => weapon != primaryWeapon,
        orElse: () => primaryWeapon,
      );
      return <String>[fallback];
    }

    if (tier == ArcLoadoutBuildTier.value) {
      candidates.sort((a, b) {
        final aProfile = ArcLoadoutIntelligenceCatalog.profileFor(a);
        final bProfile = ArcLoadoutIntelligenceCatalog.profileFor(b);
        return bProfile.valueScore.compareTo(aProfile.valueScore);
      });
    }
    return List<String>.unmodifiable(candidates);
  }

  static List<String> _attachmentsFor({
    required String weaponName,
    required ArcLoadoutCombatFocus focus,
    required ArcLoadoutBuildTier tier,
  }) {
    final weapon = ArcLoadoutSeedData.weapons.firstWhere(
      (entry) => entry.name.toLowerCase() == weaponName.toLowerCase(),
      orElse: () => ArcLoadoutSeedData.weapons.first,
    );

    return weapon.slots
        .map((slotLabel) {
          final slotType = _slotTypeForLabel(slotLabel);
          final candidates = ArcWeaponAttachmentDatabase.attachments
              .where(
                (attachment) =>
                    attachment.slotType == slotType &&
                    attachment.supportsWeapon(weapon.name),
              )
              .toList(growable: false);
          if (candidates.isEmpty) return 'Empty Slot';

          final ranked = List<ArcLoadoutAttachmentSpec>.from(candidates)
            ..sort(
              (a, b) =>
                  _attachmentScore(
                    b,
                    weapon: weapon,
                    focus: focus,
                    tier: tier,
                  ).compareTo(
                    _attachmentScore(
                      a,
                      weapon: weapon,
                      focus: focus,
                      tier: tier,
                    ),
                  ),
            );
          return ranked.first.name;
        })
        .toList(growable: false);
  }

  static int _attachmentScore(
    ArcLoadoutAttachmentSpec attachment, {
    required ArcLoadoutWeaponSpec weapon,
    required ArcLoadoutCombatFocus focus,
    required ArcLoadoutBuildTier tier,
  }) {
    var score = 0;
    if (tier == ArcLoadoutBuildTier.meta) {
      score += attachment.findOnly ? 28 : attachment.benchLevel * 18;
    } else {
      score += attachment.findOnly
          ? -35
          : math.max(0, 45 - attachment.benchLevel * 12);
      score -= attachment.craftingRequirements.fold<int>(
        0,
        (total, item) => total + item.quantity,
      );
    }

    for (final effect in attachment.effects) {
      final stat = effect.stat.toLowerCase();
      if (stat.contains('magazine')) {
        score += focus == ArcLoadoutCombatFocus.pve ? 28 : 24;
      }
      if (stat.contains('recoil')) {
        score += focus == ArcLoadoutCombatFocus.pvp ? 26 : 20;
      }
      if (stat.contains('dispersion')) {
        score += 24;
      }
      if (stat.contains('recovery')) {
        score += 19;
      }
      if (stat.contains('noise')) {
        score += focus == ArcLoadoutCombatFocus.pve ? 12 : 5;
      }
      if (stat.contains('agility') || stat.contains('handling')) {
        score += focus == ArcLoadoutCombatFocus.pvp ? 18 : 9;
      }
      if (effect.isPenalty) {
        score -= 18;
      }
    }

    final category = weapon.category.toLowerCase();
    if (category.contains('shotgun') &&
        attachment.slotType == ArcAttachmentSlotType.shotgunMuzzle) {
      score += 35;
    }
    if ((category.contains('sniper') || category.contains('rifle')) &&
        attachment.slotType == ArcAttachmentSlotType.muzzle) {
      score += 12;
    }
    if ((category.contains('smg') || category.contains('lmg')) &&
        attachment.slotType.name.contains('Magazine')) {
      score += 15;
    }
    return score;
  }

  static List<ArcLoadoutResourceNeed> _aggregateResources(
    List<String> attachmentNames,
  ) {
    final totals = <String, int>{};
    for (final name in attachmentNames) {
      final attachment = ArcWeaponAttachmentDatabase.attachmentForName(name);
      if (attachment == null) continue;
      for (final requirement in attachment.craftingRequirements) {
        totals.update(
          requirement.itemName,
          (value) => value + requirement.quantity,
          ifAbsent: () => requirement.quantity,
        );
      }
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries
        .map(
          (entry) => ArcLoadoutResourceNeed(
            itemName: entry.key,
            quantity: entry.value,
          ),
        )
        .toList(growable: false);
  }

  static List<String> _blueprintPriorities({
    required String primaryWeapon,
    required String secondaryWeapon,
    required List<String> primaryAttachments,
    required List<String> secondaryAttachments,
  }) {
    final priorities = <String>[];
    for (final weaponName in <String>[primaryWeapon, secondaryWeapon]) {
      final weapon = ArcLoadoutSeedData.weapons.firstWhere(
        (entry) => entry.name.toLowerCase() == weaponName.toLowerCase(),
        orElse: () => ArcLoadoutSeedData.weapons.first,
      );
      if (weapon.blueprintBased) priorities.add(weapon.name);
    }
    for (final name in <String>[
      ...primaryAttachments,
      ...secondaryAttachments,
    ]) {
      final attachment = ArcWeaponAttachmentDatabase.attachmentForName(name);
      if (attachment?.blueprintItemId != null && name != 'Empty Slot') {
        priorities.add(name);
      }
    }
    return priorities.toSet().toList(growable: false);
  }

  static ArcAttachmentSlotType _slotTypeForLabel(String label) {
    final normalised = label.toLowerCase().replaceAll(' mod', '').trim();
    switch (normalised) {
      case 'muzzle':
        return ArcAttachmentSlotType.muzzle;
      case 'shotgun muzzle':
        return ArcAttachmentSlotType.shotgunMuzzle;
      case 'underbarrel':
      case 'grip':
        return ArcAttachmentSlotType.underbarrel;
      case 'light magazine':
        return ArcAttachmentSlotType.lightMagazine;
      case 'medium magazine':
      case 'magazine':
        return ArcAttachmentSlotType.mediumMagazine;
      case 'shotgun magazine':
        return ArcAttachmentSlotType.shotgunMagazine;
      case 'stock':
        return ArcAttachmentSlotType.stock;
      case 'barrel':
        return ArcAttachmentSlotType.barrel;
      case 'converter':
        return ArcAttachmentSlotType.converter;
      default:
        return ArcAttachmentSlotType.special;
    }
  }
}
