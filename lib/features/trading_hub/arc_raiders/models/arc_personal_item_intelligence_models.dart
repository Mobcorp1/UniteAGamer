import 'package:flutter/foundation.dart';

enum ArcPersonalItemRecommendation {
  keep,
  use,
  equip,
  craft,
  trade,
  list,
  reserve,
  sell,
  recycle,
  unknown,
}

extension ArcPersonalItemRecommendationX on ArcPersonalItemRecommendation {
  String get label {
    switch (this) {
      case ArcPersonalItemRecommendation.keep:
        return 'KEEP';
      case ArcPersonalItemRecommendation.use:
        return 'USE';
      case ArcPersonalItemRecommendation.equip:
        return 'EQUIP';
      case ArcPersonalItemRecommendation.craft:
        return 'CRAFT';
      case ArcPersonalItemRecommendation.trade:
        return 'TRADE';
      case ArcPersonalItemRecommendation.list:
        return 'LIST';
      case ArcPersonalItemRecommendation.reserve:
        return 'RESERVE';
      case ArcPersonalItemRecommendation.sell:
        return 'SELL';
      case ArcPersonalItemRecommendation.recycle:
        return 'RECYCLE';
      case ArcPersonalItemRecommendation.unknown:
        return 'UNKNOWN';
    }
  }

  static ArcPersonalItemRecommendation fromWire(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    return ArcPersonalItemRecommendation.values.firstWhere(
      (item) => item.name == normalized,
      orElse: () => ArcPersonalItemRecommendation.unknown,
    );
  }
}

enum ArcPersonalItemVerificationState {
  officiallyVerified,
  uagVerified,
  highlyCorroborated,
  communityConfirmed,
  singleSourceResearch,
  unverified,
  outdated,
  conflicting,
  unknownAfterUpdate,
}

extension ArcPersonalItemVerificationStateX
    on ArcPersonalItemVerificationState {
  String get label {
    switch (this) {
      case ArcPersonalItemVerificationState.officiallyVerified:
        return 'Officially verified';
      case ArcPersonalItemVerificationState.uagVerified:
        return 'UAG verified';
      case ArcPersonalItemVerificationState.highlyCorroborated:
        return 'Highly corroborated';
      case ArcPersonalItemVerificationState.communityConfirmed:
        return 'Community confirmed';
      case ArcPersonalItemVerificationState.singleSourceResearch:
        return 'Single-source research';
      case ArcPersonalItemVerificationState.unverified:
        return 'Unverified';
      case ArcPersonalItemVerificationState.outdated:
        return 'Outdated';
      case ArcPersonalItemVerificationState.conflicting:
        return 'Conflicting';
      case ArcPersonalItemVerificationState.unknownAfterUpdate:
        return 'Unknown after update';
    }
  }

  bool get canSupportRecycleRecommendation {
    switch (this) {
      case ArcPersonalItemVerificationState.officiallyVerified:
      case ArcPersonalItemVerificationState.uagVerified:
      case ArcPersonalItemVerificationState.highlyCorroborated:
        return true;
      case ArcPersonalItemVerificationState.communityConfirmed:
      case ArcPersonalItemVerificationState.singleSourceResearch:
      case ArcPersonalItemVerificationState.unverified:
      case ArcPersonalItemVerificationState.outdated:
      case ArcPersonalItemVerificationState.conflicting:
      case ArcPersonalItemVerificationState.unknownAfterUpdate:
        return false;
    }
  }

  bool get isIncomplete {
    switch (this) {
      case ArcPersonalItemVerificationState.unverified:
      case ArcPersonalItemVerificationState.outdated:
      case ArcPersonalItemVerificationState.conflicting:
      case ArcPersonalItemVerificationState.unknownAfterUpdate:
        return true;
      case ArcPersonalItemVerificationState.officiallyVerified:
      case ArcPersonalItemVerificationState.uagVerified:
      case ArcPersonalItemVerificationState.highlyCorroborated:
      case ArcPersonalItemVerificationState.communityConfirmed:
      case ArcPersonalItemVerificationState.singleSourceResearch:
        return false;
    }
  }

  static ArcPersonalItemVerificationState fromWire(String? value) {
    final normalized = (value ?? '').trim();
    return ArcPersonalItemVerificationState.values.firstWhere(
      (item) => item.name == normalized,
      orElse: () => ArcPersonalItemVerificationState.unverified,
    );
  }
}

enum ArcPersonalItemProtectionType {
  alwaysKeep,
  neverRecycle,
  reservedForQuest,
  reservedForScrappy,
  reservedForBench,
  reservedForCrafting,
  reservedForTrade,
  reservedForFavouriteLoadout,
  ignoreRecommendation,
}

extension ArcPersonalItemProtectionTypeX on ArcPersonalItemProtectionType {
  String get label {
    switch (this) {
      case ArcPersonalItemProtectionType.alwaysKeep:
        return 'Always keep';
      case ArcPersonalItemProtectionType.neverRecycle:
        return 'Never recycle';
      case ArcPersonalItemProtectionType.reservedForQuest:
        return 'Reserved for quest';
      case ArcPersonalItemProtectionType.reservedForScrappy:
        return 'Reserved for Scrappy';
      case ArcPersonalItemProtectionType.reservedForBench:
        return 'Reserved for Bench';
      case ArcPersonalItemProtectionType.reservedForCrafting:
        return 'Reserved for crafting';
      case ArcPersonalItemProtectionType.reservedForTrade:
        return 'Reserved for trade';
      case ArcPersonalItemProtectionType.reservedForFavouriteLoadout:
        return 'Reserved for Favourite Loadout';
      case ArcPersonalItemProtectionType.ignoreRecommendation:
        return 'Ignore recommendation';
    }
  }
}

@immutable
class ArcPersonalItemDependency {
  const ArcPersonalItemDependency({
    required this.system,
    required this.objectiveId,
    required this.label,
    required this.requiredQuantity,
    this.source = '',
    this.futureOnly = false,
    this.blocking = false,
  });

  final String system;
  final String objectiveId;
  final String label;
  final int requiredQuantity;
  final String source;
  final bool futureOnly;
  final bool blocking;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'system': system,
      'objectiveId': objectiveId,
      'label': label,
      'requiredQuantity': requiredQuantity,
      'source': source,
      'futureOnly': futureOnly,
      'blocking': blocking,
    };
  }

  factory ArcPersonalItemDependency.fromMap(Map<String, dynamic> map) {
    return ArcPersonalItemDependency(
      system: _readString(map['system']),
      objectiveId: _readString(map['objectiveId']),
      label: _readString(map['label']),
      requiredQuantity: _readInt(map['requiredQuantity']),
      source: _readString(map['source']),
      futureOnly: _readBool(map['futureOnly']),
      blocking: _readBool(map['blocking']),
    );
  }
}

@immutable
class ArcPersonalItemRecord {
  const ArcPersonalItemRecord({
    required this.id,
    required this.name,
    required this.category,
    required this.verificationState,
    required this.confidence,
    this.aliases = const <String>[],
    this.imagePath = '',
    this.subcategory = '',
    this.rarity = 'Unknown',
    this.tier = '',
    this.stackSize,
    this.weight,
    this.saleValue,
    this.recycleOutputs = const <String, int>{},
    this.craftingUses = const <String>[],
    this.weaponCraftingUses = const <String>[],
    this.attachmentCraftingUses = const <String>[],
    this.consumableCraftingUses = const <String>[],
    this.upgradeUses = const <String>[],
    this.dependencies = const <ArcPersonalItemDependency>[],
    this.loadoutCompatibility = const <String>[],
    this.weaponCompatibility = const <String>[],
    this.attachmentCompatibility = const <String>[],
    this.inventoryClassification = '',
    this.generallySafeToSell = false,
    this.generallySafeToRecycle = false,
    this.commonFarmingSources = const <String>[],
    this.maps = const <String>[],
    this.pois = const <String>[],
    this.containers = const <String>[],
    this.seasonIntroduced = '',
    this.lastGameVersionVerified = '',
    this.availabilityState = 'available',
    this.sourceCount = 0,
    this.sources = const <String>[],
    this.lastReviewedIso = '',
    this.notes = '',
    this.deprecated = false,
    this.replacedByItemId = '',
  });

  final String id;
  final String name;
  final List<String> aliases;
  final String imagePath;
  final String category;
  final String subcategory;
  final String rarity;
  final String tier;
  final int? stackSize;
  final double? weight;
  final int? saleValue;
  final Map<String, int> recycleOutputs;
  final List<String> craftingUses;
  final List<String> weaponCraftingUses;
  final List<String> attachmentCraftingUses;
  final List<String> consumableCraftingUses;
  final List<String> upgradeUses;
  final List<ArcPersonalItemDependency> dependencies;
  final List<String> loadoutCompatibility;
  final List<String> weaponCompatibility;
  final List<String> attachmentCompatibility;
  final String inventoryClassification;
  final bool generallySafeToSell;
  final bool generallySafeToRecycle;
  final List<String> commonFarmingSources;
  final List<String> maps;
  final List<String> pois;
  final List<String> containers;
  final String seasonIntroduced;
  final String lastGameVersionVerified;
  final String availabilityState;
  final ArcPersonalItemVerificationState verificationState;
  final int sourceCount;
  final List<String> sources;
  final String lastReviewedIso;
  final double confidence;
  final String notes;
  final bool deprecated;
  final String replacedByItemId;

  bool get hasDependencyData =>
      dependencies.isNotEmpty ||
      craftingUses.isNotEmpty ||
      weaponCraftingUses.isNotEmpty ||
      attachmentCraftingUses.isNotEmpty ||
      consumableCraftingUses.isNotEmpty ||
      upgradeUses.isNotEmpty ||
      loadoutCompatibility.isNotEmpty;

  bool get canRecommendRecycle {
    return generallySafeToRecycle &&
        !deprecated &&
        verificationState.canSupportRecycleRecommendation &&
        lastGameVersionVerified.trim().isNotEmpty &&
        confidence >= 0.82;
  }

  bool isFreshAt(DateTime now, {int maxAgeDays = 120}) {
    if (lastReviewedIso.trim().isEmpty) return false;
    final reviewed = DateTime.tryParse(lastReviewedIso);
    if (reviewed == null) return false;
    if (reviewed.isAfter(now.add(const Duration(days: 1)))) return false;
    return now.difference(reviewed).inDays <= maxAgeDays &&
        verificationState != ArcPersonalItemVerificationState.outdated &&
        verificationState !=
            ArcPersonalItemVerificationState.unknownAfterUpdate;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'aliases': aliases,
      'imagePath': imagePath,
      'category': category,
      'subcategory': subcategory,
      'rarity': rarity,
      'tier': tier,
      if (stackSize != null) 'stackSize': stackSize,
      if (weight != null) 'weight': weight,
      if (saleValue != null) 'saleValue': saleValue,
      'recycleOutputs': recycleOutputs,
      'craftingUses': craftingUses,
      'weaponCraftingUses': weaponCraftingUses,
      'attachmentCraftingUses': attachmentCraftingUses,
      'consumableCraftingUses': consumableCraftingUses,
      'upgradeUses': upgradeUses,
      'dependencies': dependencies.map((item) => item.toMap()).toList(),
      'loadoutCompatibility': loadoutCompatibility,
      'weaponCompatibility': weaponCompatibility,
      'attachmentCompatibility': attachmentCompatibility,
      'inventoryClassification': inventoryClassification,
      'generallySafeToSell': generallySafeToSell,
      'generallySafeToRecycle': generallySafeToRecycle,
      'commonFarmingSources': commonFarmingSources,
      'maps': maps,
      'pois': pois,
      'containers': containers,
      'seasonIntroduced': seasonIntroduced,
      'lastGameVersionVerified': lastGameVersionVerified,
      'availabilityState': availabilityState,
      'verificationState': verificationState.name,
      'sourceCount': sourceCount,
      'sources': sources,
      'lastReviewedIso': lastReviewedIso,
      'confidence': confidence,
      'notes': notes,
      'deprecated': deprecated,
      'replacedByItemId': replacedByItemId,
    };
  }
}

@immutable
class ArcPersonalItemDataset {
  const ArcPersonalItemDataset({
    required this.version,
    required this.gameVersion,
    required this.effectiveDateIso,
    required this.published,
    required this.records,
    this.previousVersionIds = const <String>[],
    this.changedItemIds = const <String>[],
    this.forceRefreshAfterMajorUpdate = true,
    this.sourceSummary = const <String>[],
  });

  final String version;
  final String gameVersion;
  final String effectiveDateIso;
  final bool published;
  final List<ArcPersonalItemRecord> records;
  final List<String> previousVersionIds;
  final List<String> changedItemIds;
  final bool forceRefreshAfterMajorUpdate;
  final List<String> sourceSummary;

  ArcPersonalItemRecord? findBest(String query) {
    final normalized = normalize(query);
    if (normalized.isEmpty) return null;
    for (final record in records) {
      if (normalize(record.id) == normalized ||
          normalize(record.name) == normalized ||
          record.aliases.any((alias) => normalize(alias) == normalized)) {
        return record;
      }
    }

    ArcPersonalItemRecord? best;
    var bestScore = 0;
    for (final record in records) {
      final score = _score(record, normalized);
      if (score > bestScore) {
        best = record;
        bestScore = score;
      }
    }
    return bestScore >= 62 ? best : null;
  }

  ArcPersonalItemCoverageReport get coverage {
    final verified = records
        .where((item) => !item.verificationState.isIncomplete)
        .length;
    final incomplete = records.length - verified;
    return ArcPersonalItemCoverageReport(
      datasetVersion: version,
      totalKnownItems: records.length,
      verifiedItems: verified,
      incompleteItems: incomplete,
      itemsWithRecycleData: records
          .where((item) => item.recycleOutputs.isNotEmpty)
          .length,
      itemsWithCraftingDependencies: records
          .where(
            (item) =>
                item.craftingUses.isNotEmpty ||
                item.weaponCraftingUses.isNotEmpty ||
                item.attachmentCraftingUses.isNotEmpty ||
                item.consumableCraftingUses.isNotEmpty,
          )
          .length,
      itemsWithQuestDependencies: records
          .where(
            (item) => item.dependencies.any(
              (dependency) => dependency.system == 'Quest',
            ),
          )
          .length,
      itemsWithScrappyDependencies: records
          .where(
            (item) => item.dependencies.any(
              (dependency) => dependency.system == 'Scrappy',
            ),
          )
          .length,
      itemsWithBenchDependencies: records
          .where(
            (item) => item.dependencies.any(
              (dependency) => dependency.system == 'Bench',
            ),
          )
          .length,
      itemsWithLoadoutRelevance: records
          .where((item) => item.loadoutCompatibility.isNotEmpty)
          .length,
      staleItems: records.where((item) {
        final now = DateTime.now().toUtc();
        return !item.isFreshAt(now);
      }).length,
      conflictingItems: records
          .where(
            (item) =>
                item.verificationState ==
                ArcPersonalItemVerificationState.conflicting,
          )
          .length,
      unknownItems: records
          .where(
            (item) =>
                item.verificationState ==
                    ArcPersonalItemVerificationState.unverified ||
                item.verificationState ==
                    ArcPersonalItemVerificationState.unknownAfterUpdate,
          )
          .length,
      missingSourceCategories:
          records
              .where((item) => item.sources.isEmpty)
              .map((item) => item.category)
              .toSet()
              .toList(growable: false)
            ..sort(),
    );
  }

  static String normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('&', ' and ')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static int _score(ArcPersonalItemRecord record, String normalizedQuery) {
    final queryTokens = normalizedQuery
        .split(' ')
        .where((token) => token.isNotEmpty)
        .toSet();
    var best = 0;
    for (final candidate in <String>[
      record.id,
      record.name,
      ...record.aliases,
    ].map(normalize)) {
      if (candidate.isEmpty) continue;
      if (candidate == normalizedQuery) best = best < 100 ? 100 : best;
      if (candidate.contains(normalizedQuery) ||
          normalizedQuery.contains(candidate)) {
        best = best < 86 ? 86 : best;
      }
      final tokens = candidate
          .split(' ')
          .where((token) => token.isNotEmpty)
          .toSet();
      if (tokens.isEmpty || queryTokens.isEmpty) continue;
      final overlap = tokens.intersection(queryTokens).length;
      final score = ((overlap / tokens.length) * 75).round();
      if (score > best) best = score;
    }
    return best;
  }
}

@immutable
class ArcPersonalItemCoverageReport {
  const ArcPersonalItemCoverageReport({
    required this.datasetVersion,
    required this.totalKnownItems,
    required this.verifiedItems,
    required this.incompleteItems,
    required this.itemsWithRecycleData,
    required this.itemsWithCraftingDependencies,
    required this.itemsWithQuestDependencies,
    required this.itemsWithScrappyDependencies,
    required this.itemsWithBenchDependencies,
    required this.itemsWithLoadoutRelevance,
    required this.staleItems,
    required this.conflictingItems,
    required this.unknownItems,
    required this.missingSourceCategories,
  });

  final String datasetVersion;
  final int totalKnownItems;
  final int verifiedItems;
  final int incompleteItems;
  final int itemsWithRecycleData;
  final int itemsWithCraftingDependencies;
  final int itemsWithQuestDependencies;
  final int itemsWithScrappyDependencies;
  final int itemsWithBenchDependencies;
  final int itemsWithLoadoutRelevance;
  final int staleItems;
  final int conflictingItems;
  final int unknownItems;
  final List<String> missingSourceCategories;
}

@immutable
class ArcPersonalItemProtectionOverride {
  const ArcPersonalItemProtectionOverride({
    required this.userId,
    required this.itemId,
    this.protections = const <ArcPersonalItemProtectionType>{},
    this.customMinimumQuantity = 0,
    this.customNote = '',
    this.updatedAtIso = '',
  });

  final String userId;
  final String itemId;
  final Set<ArcPersonalItemProtectionType> protections;
  final int customMinimumQuantity;
  final String customNote;
  final String updatedAtIso;

  bool get blocksRecycle =>
      protections.contains(ArcPersonalItemProtectionType.alwaysKeep) ||
      protections.contains(ArcPersonalItemProtectionType.neverRecycle) ||
      protections.any((item) => item.name.startsWith('reservedFor'));

  bool get ignoresRecommendation =>
      protections.contains(ArcPersonalItemProtectionType.ignoreRecommendation);

  String get summary {
    if (protections.isEmpty && customMinimumQuantity <= 0) return '';
    final labels = protections.map((item) => item.label).toList();
    if (customMinimumQuantity > 0) {
      labels.add('Keep at least $customMinimumQuantity');
    }
    return labels.join(', ');
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userId': userId,
      'itemId': itemId,
      'protections': protections.map((item) => item.name).toList(),
      'customMinimumQuantity': customMinimumQuantity,
      'customNote': customNote,
      'updatedAtIso': updatedAtIso,
    };
  }

  factory ArcPersonalItemProtectionOverride.fromMap(Map<String, dynamic> map) {
    return ArcPersonalItemProtectionOverride(
      userId: _readString(map['userId']),
      itemId: _readString(map['itemId']),
      protections: _readStringList(map['protections'])
          .map(
            (value) => ArcPersonalItemProtectionType.values.firstWhere(
              (item) => item.name == value,
              orElse: () => ArcPersonalItemProtectionType.neverRecycle,
            ),
          )
          .toSet(),
      customMinimumQuantity: _readInt(map['customMinimumQuantity']),
      customNote: _readString(map['customNote']),
      updatedAtIso: _readString(map['updatedAtIso']),
    );
  }
}

@immutable
class ArcPersonalItemInventorySnapshot {
  const ArcPersonalItemInventorySnapshot({
    this.ownedQuantities = const <String, int>{},
    this.reservedTradeQuantities = const <String, int>{},
    this.promisedTradeQuantities = const <String, int>{},
    this.protectionOverrides =
        const <String, ArcPersonalItemProtectionOverride>{},
  });

  final Map<String, int> ownedQuantities;
  final Map<String, int> reservedTradeQuantities;
  final Map<String, int> promisedTradeQuantities;
  final Map<String, ArcPersonalItemProtectionOverride> protectionOverrides;

  int quantityFor(String itemId, String itemName) =>
      ownedQuantities[_key(itemId)] ?? ownedQuantities[_key(itemName)] ?? 0;

  int reservedFor(String itemId, String itemName) =>
      reservedTradeQuantities[_key(itemId)] ??
      reservedTradeQuantities[_key(itemName)] ??
      0;

  int promisedFor(String itemId, String itemName) =>
      promisedTradeQuantities[_key(itemId)] ??
      promisedTradeQuantities[_key(itemName)] ??
      0;

  ArcPersonalItemProtectionOverride? protectionFor(
    String itemId,
    String itemName,
  ) {
    return protectionOverrides[_key(itemId)] ??
        protectionOverrides[_key(itemName)];
  }

  static String _key(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}

@immutable
class ArcPersonalItemTradeOpportunity {
  const ArcPersonalItemTradeOpportunity({
    required this.id,
    required this.title,
    required this.reason,
    required this.actionLabel,
    required this.confidence,
    this.listingId = '',
    this.traderUid = '',
  });

  final String id;
  final String title;
  final String reason;
  final String actionLabel;
  final double confidence;
  final String listingId;
  final String traderUid;
}

@immutable
class ArcPersonalItemRecommendationResult {
  const ArcPersonalItemRecommendationResult({
    required this.query,
    required this.outcome,
    required this.primaryReason,
    required this.secondaryReasons,
    required this.linkedObjectiveIds,
    required this.requiredQuantity,
    required this.ownedQuantity,
    required this.surplusQuantity,
    required this.confidence,
    required this.dataVersion,
    required this.dataFreshness,
    required this.conflictingRecommendations,
    required this.suggestedAction,
    required this.relevantTradeOpportunities,
    required this.relevantRouteOrFarmingOpportunity,
    this.record,
  });

  final String query;
  final ArcPersonalItemRecommendation outcome;
  final String primaryReason;
  final List<String> secondaryReasons;
  final List<String> linkedObjectiveIds;
  final int requiredQuantity;
  final int ownedQuantity;
  final int surplusQuantity;
  final double confidence;
  final String dataVersion;
  final String dataFreshness;
  final List<ArcPersonalItemRecommendation> conflictingRecommendations;
  final String suggestedAction;
  final List<ArcPersonalItemTradeOpportunity> relevantTradeOpportunities;
  final String relevantRouteOrFarmingOpportunity;
  final ArcPersonalItemRecord? record;

  bool get itemRecognized => record != null;

  bool get isRecycleSafe =>
      outcome == ArcPersonalItemRecommendation.recycle &&
      record != null &&
      record!.canRecommendRecycle &&
      conflictingRecommendations.isEmpty;

  String get spokenSummary {
    final name = record?.name ?? query;
    switch (outcome) {
      case ArcPersonalItemRecommendation.keep:
        return 'Keep $name. $primaryReason';
      case ArcPersonalItemRecommendation.use:
        return 'Use $name. $primaryReason';
      case ArcPersonalItemRecommendation.equip:
        return 'Equip $name. $primaryReason';
      case ArcPersonalItemRecommendation.craft:
        return 'Craft with $name. $primaryReason';
      case ArcPersonalItemRecommendation.trade:
        return 'Trade $name only if the conflict is clear. $primaryReason';
      case ArcPersonalItemRecommendation.list:
        return 'List the surplus $name. $primaryReason';
      case ArcPersonalItemRecommendation.reserve:
        return 'Reserve $name. $primaryReason';
      case ArcPersonalItemRecommendation.sell:
        return 'Sell the surplus $name. $primaryReason';
      case ArcPersonalItemRecommendation.recycle:
        return 'Recycle $name. $primaryReason';
      case ArcPersonalItemRecommendation.unknown:
        return '$name needs a manual check. $primaryReason';
    }
  }
}

String _readString(dynamic value) => value?.toString().trim() ?? '';

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(_readString(value)) ?? 0;
}

bool _readBool(dynamic value) {
  if (value is bool) return value;
  final normalized = _readString(value).toLowerCase();
  if (normalized == 'true') return true;
  if (normalized == 'false') return false;
  return false;
}

List<String> _readStringList(dynamic value) {
  if (value is! Iterable) return const <String>[];
  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}
