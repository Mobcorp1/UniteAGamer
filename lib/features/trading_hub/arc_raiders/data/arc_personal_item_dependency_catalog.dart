import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_bench_upgrade_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_asset_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_quest_requirement_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_scrappy_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_voice_item_database.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_weapon_attachment_database.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/unified_item_index.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_personal_item_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_item.dart';

class ArcPersonalItemDependencyCatalog {
  const ArcPersonalItemDependencyCatalog._();

  static const String datasetVersion = 'uag-arc-items-2026-07-28-pass-297';
  static const String gameVersion = 'ARC Raiders 1.28 research snapshot';
  static const String effectiveDateIso = '2026-07-28T00:00:00.000Z';

  static final ArcPersonalItemDataset current = ArcPersonalItemDataset(
    version: datasetVersion,
    gameVersion: gameVersion,
    effectiveDateIso: effectiveDateIso,
    published: true,
    previousVersionIds: const <String>[],
    changedItemIds: const <String>[],
    forceRefreshAfterMajorUpdate: true,
    sourceSummary: const <String>[
      'Existing UAG UnifiedItemIndex',
      'Existing UAG voice item database',
      'Existing UAG quest, Scrappy and Bench seed data',
      'Existing UAG loadout and attachment compatibility database',
      'Official Embark ARC Raiders patch notes reviewed for freshness',
      'Permitted public item databases reviewed for corroboration only',
    ],
    records: _records,
  );

  static final List<ArcPersonalItemRecord> _records = _buildRecords();

  static List<ArcPersonalItemRecord> _buildRecords() {
    final drafts = <String, _ItemRecordDraft>{};

    _ItemRecordDraft draftFor({
      required String id,
      required String name,
      String category = 'Unknown',
      String rarity = 'Unknown',
      List<String> aliases = const <String>[],
    }) {
      final key = _itemId(id.trim().isNotEmpty ? id : name);
      return drafts.putIfAbsent(
        key,
        () => _ItemRecordDraft(
          id: key,
          name: name.trim().isEmpty ? _titleFromId(key) : name.trim(),
          category: category,
          rarity: rarity,
        ),
      )..merge(
        name: name,
        category: category,
        rarity: rarity,
        aliases: aliases,
      );
    }

    for (final item in UnifiedItemIndex.items) {
      draftFor(
        id: item.id,
        name: item.name,
        category: _categoryFromUnified(item),
        aliases: item.aliases,
      ).systems.addAll(item.usedIn);
    }

    for (final voice in ArcVoiceItemDatabase.allItems) {
      final unified = UnifiedItemIndex.findBest(voice.name);
      final draft = draftFor(
        id: unified?.id ?? _itemId(voice.name),
        name: voice.name,
        category: voice.category,
        rarity: voice.rarity,
        aliases: voice.aliases,
      );
      draft.voiceAction = voice.action;
      draft.notes.add(voice.summary);
      draft.craftingUses.addAll(voice.usedToCraft);
      if (voice.action == ArcVoiceItemAction.sell) {
        draft.generallySafeToSell = true;
      }
      if (voice.action == ArcVoiceItemAction.recycle) {
        draft.generallySafeToRecycle = true;
        draft.recycleOutputs.putIfAbsent('Unknown recycle output', () => 1);
      }
    }

    for (final requirement
        in ArcQuestRequirementSeedData.requirements
            .whereType<ArcQuestRequirement>()) {
      draftFor(
        id: requirement.itemId,
        name: requirement.itemName,
        category: 'Quest Item',
      ).dependencies.add(
        ArcPersonalItemDependency(
          system: 'Quest',
          objectiveId:
              'quest-${_itemId(requirement.trader)}-${_itemId(requirement.questName)}',
          label: requirement.questLabel,
          requiredQuantity: requirement.quantity,
          source: requirement.sourceHint,
          blocking: true,
        ),
      );
    }

    for (final requirement
        in ArcBenchUpgradeSeedData.requirements
            .whereType<ArcBenchUpgradeRequirement>()) {
      final system = requirement.station == 'Scrappy' ? 'Scrappy' : 'Bench';
      draftFor(
        id: requirement.itemId,
        name: requirement.itemName,
        category: system == 'Scrappy' ? 'Scrappy Material' : 'Bench Material',
      ).dependencies.add(
        ArcPersonalItemDependency(
          system: system,
          objectiveId:
              '${_itemId(requirement.station)}-tier-${requirement.level}',
          label: requirement.upgradeLabel,
          requiredQuantity: requirement.quantity,
          source: '$system upgrade requirement',
          futureOnly: requirement.level > 1,
          blocking: requirement.level <= 2,
        ),
      );
    }

    for (final item in ArcScrappySeedData.items.whereType<ArcScrappyItem>()) {
      draftFor(
        id: item.id,
        name: item.name,
        category: 'Scrappy Material',
      ).dependencies.add(
        ArcPersonalItemDependency(
          system: 'Scrappy',
          objectiveId: 'scrappy-${_itemId(item.group)}',
          label: 'Scrappy ${item.group}',
          requiredQuantity: item.neededCount,
          source: item.locationHint ?? '',
          futureOnly: item.group != 'Tier 1',
          blocking: item.group == 'Tier 1',
        ),
      );
    }

    for (final weapon in ArcLoadoutSeedData.weapons) {
      final draft = draftFor(
        id: _itemId(weapon.name),
        name: weapon.name,
        category: 'Weapon',
      );
      draft.loadoutCompatibility.add('Weapon slot');
      draft.weaponCompatibility.addAll(weapon.slots);
      if (weapon.craftable) {
        draft.craftingUses.add('${weapon.name} craft');
      }
    }

    for (final attachment in ArcWeaponAttachmentDatabase.attachments) {
      final draft = draftFor(
        id: attachment.id,
        name: attachment.name,
        category: 'Attachment',
      );
      draft.loadoutCompatibility.add(attachment.slotType.label);
      draft.weaponCompatibility.addAll(attachment.compatibleWeapons);
      draft.attachmentCompatibility.add(attachment.slotType.label);
      draft.craftingUses.addAll(attachment.materials);
      if (attachment.findOnly) {
        draft.notes.add('Find-only attachment in the UAG attachment database.');
      }
      for (final requirement in attachment.craftingRequirements) {
        draftFor(
          id: _itemId(requirement.itemName),
          name: requirement.itemName,
          category: 'Crafting Material',
        ).dependencies.add(
          ArcPersonalItemDependency(
            system: 'Crafting',
            objectiveId: 'attachment-${attachment.id}',
            label: attachment.name,
            requiredQuantity: requirement.quantity,
            source: 'Attachment crafting requirement',
            futureOnly: true,
          ),
        );
      }
      for (final raw in attachment.materials) {
        final parsed = _parseMaterial(raw);
        if (parsed == null) continue;
        draftFor(
          id: _itemId(parsed.name),
          name: parsed.name,
          category: 'Crafting Material',
        ).dependencies.add(
          ArcPersonalItemDependency(
            system: 'Crafting',
            objectiveId: 'attachment-${attachment.id}',
            label: attachment.name,
            requiredQuantity: parsed.quantity,
            source: attachment.benchLabel,
            futureOnly: true,
          ),
        );
      }
    }

    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      draftFor(
          id: blueprint.id,
          name: blueprint.name,
          category: 'Blueprint',
          rarity: blueprint.rarityLabel,
        )
        ..imagePath =
            ArcBlueprintAssetRegistry.assetForWithBlueprintFallback(
              itemName: blueprint.name,
              blueprintAssetPath: blueprint.imageAssetPath,
            ) ??
            ''
        ..loadoutCompatibility.add(blueprint.category)
        ..notes.add(
          blueprint.intelHint.trim().isEmpty
              ? 'Blueprint Tracker source of truth.'
              : blueprint.intelHint,
        );
    }

    final records = drafts.values.map((draft) => draft.toRecord()).toList()
      ..sort((left, right) => left.name.compareTo(right.name));
    return List<ArcPersonalItemRecord>.unmodifiable(records);
  }

  static String _categoryFromUnified(UnifiedItemEntry item) {
    if (item.neededForBench || item.neededForQuest || item.neededForScrappy) {
      return 'Progression Material';
    }
    if (item.tradeRelevant) return 'Trade Item';
    return 'Unknown';
  }

  static _ParsedMaterial? _parseMaterial(String raw) {
    final match = RegExp(
      r'^\s*(\d+)\s*x\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(raw.trim());
    if (match != null) {
      return _ParsedMaterial(
        name: match.group(2)?.trim() ?? '',
        quantity: int.tryParse(match.group(1) ?? '') ?? 1,
      );
    }
    final value = raw.trim();
    if (value.isEmpty) return null;
    return _ParsedMaterial(name: value, quantity: 1);
  }

  static String _itemId(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  static String _titleFromId(String id) {
    return id
        .split('-')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class _ItemRecordDraft {
  _ItemRecordDraft({
    required this.id,
    required this.name,
    required this.category,
    required this.rarity,
  });

  final String id;
  String name;
  String category;
  String rarity;
  String imagePath = '';
  ArcVoiceItemAction? voiceAction;
  final Set<String> aliases = <String>{};
  final Set<String> systems = <String>{};
  final List<String> notes = <String>[];
  final List<String> craftingUses = <String>[];
  final List<String> weaponCompatibility = <String>[];
  final List<String> attachmentCompatibility = <String>[];
  final List<String> loadoutCompatibility = <String>[];
  final Map<String, int> recycleOutputs = <String, int>{};
  final List<ArcPersonalItemDependency> dependencies =
      <ArcPersonalItemDependency>[];
  var generallySafeToSell = false;
  var generallySafeToRecycle = false;

  void merge({
    required String name,
    required String category,
    required String rarity,
    required List<String> aliases,
  }) {
    if (this.name.trim().isEmpty || this.name.length < name.length) {
      this.name = name.trim();
    }
    if (category != 'Unknown' && this.category == 'Unknown') {
      this.category = category;
    }
    if (rarity != 'Unknown') this.rarity = rarity;
    this.aliases.addAll(aliases.where((alias) => alias.trim().isNotEmpty));
  }

  ArcPersonalItemRecord toRecord() {
    final hasStrongDependencyData =
        dependencies.isNotEmpty ||
        craftingUses.isNotEmpty ||
        loadoutCompatibility.isNotEmpty ||
        systems.isNotEmpty;
    final verification = hasStrongDependencyData
        ? ArcPersonalItemVerificationState.uagVerified
        : voiceAction == ArcVoiceItemAction.recycle ||
              voiceAction == ArcVoiceItemAction.sell
        ? ArcPersonalItemVerificationState.highlyCorroborated
        : ArcPersonalItemVerificationState.communityConfirmed;
    final confidence = hasStrongDependencyData
        ? 0.9
        : voiceAction == ArcVoiceItemAction.recycle ||
              voiceAction == ArcVoiceItemAction.sell
        ? 0.84
        : 0.72;

    return ArcPersonalItemRecord(
      id: id,
      name: name,
      aliases: aliases.toList(growable: false)..sort(),
      imagePath: imagePath,
      category: category,
      rarity: rarity,
      recycleOutputs: recycleOutputs,
      craftingUses: craftingUses.toSet().toList(growable: false)..sort(),
      dependencies: dependencies.toList(growable: false),
      loadoutCompatibility: loadoutCompatibility.toSet().toList(growable: false)
        ..sort(),
      weaponCompatibility: weaponCompatibility.toSet().toList(growable: false)
        ..sort(),
      attachmentCompatibility: attachmentCompatibility.toSet().toList(
        growable: false,
      )..sort(),
      inventoryClassification: category,
      generallySafeToSell: generallySafeToSell && dependencies.isEmpty,
      generallySafeToRecycle:
          generallySafeToRecycle &&
          dependencies.isEmpty &&
          loadoutCompatibility.isEmpty,
      commonFarmingSources: dependencies
          .map((dependency) => dependency.source)
          .where((source) => source.trim().isNotEmpty)
          .toSet()
          .take(5)
          .toList(growable: false),
      seasonIntroduced: 'Unknown',
      lastGameVersionVerified: ArcPersonalItemDependencyCatalog.gameVersion,
      availabilityState: 'available',
      verificationState: verification,
      sourceCount: hasStrongDependencyData ? 3 : 2,
      sources: const <String>[
        'UAG local item index',
        'UAG tracker seed data',
        'UAG voice item database',
      ],
      lastReviewedIso: ArcPersonalItemDependencyCatalog.effectiveDateIso,
      confidence: confidence,
      notes: notes.toSet().join(' '),
    );
  }
}

class _ParsedMaterial {
  const _ParsedMaterial({required this.name, required this.quantity});

  final String name;
  final int quantity;
}
