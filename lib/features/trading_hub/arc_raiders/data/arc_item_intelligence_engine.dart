import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_item_intelligence_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_item_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';

class ArcItemIntelligenceEngine {
  ArcItemIntelligenceEngine._();

  static final Map<String, ArcItemIntelligenceItem> _byId =
      <String, ArcItemIntelligenceItem>{
        for (final item in ArcItemIntelligenceCatalog.items) item.id: item,
      };

  static List<ArcItemIntelligenceItem> get items =>
      ArcItemIntelligenceCatalog.items;

  static List<ArcItemIntelligenceItem> get craftables =>
      ArcItemIntelligenceCatalog.items
          .where((item) => item.craftable)
          .toList(growable: false);

  static List<ArcItemIntelligenceItem> get recyclables =>
      ArcItemIntelligenceCatalog.items
          .where((item) => item.recyclable)
          .toList(growable: false);

  static ArcItemIntelligenceItem? byId(String id) => _byId[id];

  static String normalise(String value) {
    var text = value.trim().toLowerCase();
    text = text.replaceAll('&', ' and ');
    text = text.replaceAll(RegExp(r"['’`]"), '');
    text = text.replaceAll(RegExp(r'[_\-/]+'), ' ');
    text = text.replaceAll(RegExp(r'\biv\b'), '4');
    text = text.replaceAll(RegExp(r'\biii\b'), '3');
    text = text.replaceAll(RegExp(r'\bii\b'), '2');
    text = text.replaceAll(RegExp(r'\bi\b'), '1');
    text = text.replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }

  static Set<String> _forms(String value) {
    final base = normalise(value);
    if (base.isEmpty) {
      return const <String>{};
    }
    final result = <String>{base};

    final parts = base.split(' ');
    if (parts.isNotEmpty) {
      final last = parts.last;
      if (last.endsWith('ies') && last.length > 3) {
        final singular = '${last.substring(0, last.length - 3)}y';
        result.add([...parts.take(parts.length - 1), singular].join(' '));
      } else if (last.endsWith('s') && last.length > 1) {
        result.add(
          [
            ...parts.take(parts.length - 1),
            last.substring(0, last.length - 1),
          ].join(' '),
        );
      } else {
        result.add([...parts.take(parts.length - 1), '${last}s'].join(' '));
      }
    }
    return result;
  }

  static bool _matches(ArcItemIntelligenceItem item, String query) {
    final queryForms = _forms(query);
    if (queryForms.isEmpty) {
      return false;
    }

    final values = <String>[item.id, item.name, ...item.aliases];
    for (final value in values) {
      if (_forms(value).intersection(queryForms).isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  static ArcItemIntelligenceItem? resolve(String query) {
    final matches = ArcItemIntelligenceCatalog.items
        .where((item) => _matches(item, query))
        .toList(growable: false);
    if (matches.isEmpty) {
      return null;
    }

    final exact = matches.where(
      (item) =>
          normalise(item.name) == normalise(query) ||
          normalise(item.id) == normalise(query),
    );
    if (exact.isNotEmpty) {
      return exact.first;
    }

    return matches.first;
  }

  static int _tier(ArcItemIntelligenceItem item) {
    final match = RegExp(r'\s([1-4])$').firstMatch(normalise(item.name));
    return match == null ? 0 : int.tryParse(match.group(1) ?? '') ?? 0;
  }

  static String _baseName(String name) =>
      normalise(name).replaceFirst(RegExp(r'\s[1-4]$'), '').trim();

  static ArcItemIntelligenceItem? resolveCraftTarget(
    String query, {
    bool preferHighestTier = true,
  }) {
    final direct = resolve(query);
    final normalisedQuery = normalise(query);
    final queryHasTier = RegExp(r'\s[1-4]$').hasMatch(normalisedQuery);

    if (direct != null && (!preferHighestTier || queryHasTier)) {
      return direct.craftable ? direct : null;
    }

    final base = direct == null ? normalisedQuery : _baseName(direct.name);
    final tierCandidates =
        craftables
            .where((item) => _baseName(item.name) == base)
            .toList(growable: false)
          ..sort((a, b) => _tier(b).compareTo(_tier(a)));

    if (preferHighestTier && tierCandidates.isNotEmpty) {
      return tierCandidates.first;
    }

    if (direct?.craftable == true) {
      return direct;
    }
    return tierCandidates.isEmpty ? null : tierCandidates.first;
  }

  static ArcCraftingPlan planForItem(
    String query, {
    int quantity = 1,
    Map<String, int> ownedItems = const <String, int>{},
  }) {
    final target = resolveCraftTarget(query);
    if (target == null) {
      return ArcCraftingPlan(
        targetId: '',
        targetName: query,
        targetQuantity: quantity,
        immediateRecipe: const <String, int>{},
        rawMaterials: const <String, int>{},
        craftSteps: const <ArcCraftStep>[],
        unresolvedTargets: <String>[query],
      );
    }

    final raw = <String, int>{};
    final steps = <String, int>{};
    final unresolved = <String>[];
    final owned = <String, int>{
      for (final entry in ownedItems.entries)
        if (entry.value > 0) entry.key: entry.value,
    };

    void expand(String itemId, int count, Set<String> stack) {
      if (count <= 0) {
        return;
      }

      final available = owned[itemId] ?? 0;
      if (available > 0) {
        final used = available < count ? available : count;
        owned[itemId] = available - used;
        count -= used;
        if (count <= 0) {
          return;
        }
      }

      final item = _byId[itemId];
      if (item == null) {
        raw[itemId] = (raw[itemId] ?? 0) + count;
        unresolved.add(itemId);
        return;
      }

      if (item.recipe.isEmpty) {
        raw[itemId] = (raw[itemId] ?? 0) + count;
        return;
      }

      if (stack.contains(itemId)) {
        raw[itemId] = (raw[itemId] ?? 0) + count;
        unresolved.add(itemId);
        return;
      }

      steps[itemId] = (steps[itemId] ?? 0) + count;
      final nextStack = <String>{...stack, itemId};
      for (final ingredient in item.recipe.entries) {
        expand(ingredient.key, ingredient.value * count, nextStack);
      }
    }

    expand(target.id, quantity, <String>{});

    final orderedRaw = Map<String, int>.fromEntries(
      raw.entries.toList()..sort((a, b) {
        final aName = _byId[a.key]?.name ?? a.key;
        final bName = _byId[b.key]?.name ?? b.key;
        return aName.compareTo(bName);
      }),
    );

    final orderedSteps =
        steps.entries
            .map(
              (entry) => ArcCraftStep(itemId: entry.key, quantity: entry.value),
            )
            .toList(growable: false)
          ..sort((a, b) {
            final aName = _byId[a.itemId]?.name ?? a.itemId;
            final bName = _byId[b.itemId]?.name ?? b.itemId;
            return aName.compareTo(bName);
          });

    return ArcCraftingPlan(
      targetId: target.id,
      targetName: target.name,
      targetQuantity: quantity,
      immediateRecipe: Map<String, int>.unmodifiable(target.recipe),
      rawMaterials: Map<String, int>.unmodifiable(orderedRaw),
      craftSteps: List<ArcCraftStep>.unmodifiable(orderedSteps),
      unresolvedTargets: List<String>.unmodifiable(unresolved.toSet()),
    );
  }

  static ArcCraftingPlan planForRequirements({
    required String targetName,
    required Map<String, int> requirements,
    Map<String, int> ownedItems = const <String, int>{},
  }) {
    final immediate = <String, int>{};
    for (final entry in requirements.entries) {
      if (entry.value <= 0) continue;
      final resolved = resolve(entry.key);
      final itemId = resolved?.id ?? normalise(entry.key).replaceAll(' ', '_');
      immediate[itemId] = (immediate[itemId] ?? 0) + entry.value;
    }

    final raw = <String, int>{};
    final steps = <String, int>{};
    final unresolved = <String>[];
    final owned = <String, int>{};
    for (final entry in ownedItems.entries) {
      if (entry.value <= 0) continue;
      final resolved = resolve(entry.key);
      owned[resolved?.id ?? entry.key] = entry.value;
    }

    void expand(String itemId, int count, Set<String> stack) {
      if (count <= 0) return;
      final available = owned[itemId] ?? 0;
      if (available > 0) {
        final used = available < count ? available : count;
        owned[itemId] = available - used;
        count -= used;
        if (count <= 0) return;
      }

      final item = _byId[itemId];
      if (item == null) {
        raw[itemId] = (raw[itemId] ?? 0) + count;
        unresolved.add(itemId);
        return;
      }
      if (item.recipe.isEmpty) {
        raw[itemId] = (raw[itemId] ?? 0) + count;
        return;
      }
      if (stack.contains(itemId)) {
        raw[itemId] = (raw[itemId] ?? 0) + count;
        unresolved.add(itemId);
        return;
      }

      steps[itemId] = (steps[itemId] ?? 0) + count;
      final nextStack = <String>{...stack, itemId};
      for (final ingredient in item.recipe.entries) {
        expand(ingredient.key, ingredient.value * count, nextStack);
      }
    }

    for (final entry in immediate.entries) {
      expand(entry.key, entry.value, <String>{});
    }

    final orderedRaw = Map<String, int>.fromEntries(
      raw.entries.toList()
        ..sort((a, b) => itemName(a.key).compareTo(itemName(b.key))),
    );
    final orderedSteps =
        steps.entries
            .map(
              (entry) => ArcCraftStep(itemId: entry.key, quantity: entry.value),
            )
            .toList(growable: false)
          ..sort((a, b) => itemName(a.itemId).compareTo(itemName(b.itemId)));

    return ArcCraftingPlan(
      targetId: 'custom_${normalise(targetName).replaceAll(' ', '_')}',
      targetName: targetName,
      targetQuantity: 1,
      immediateRecipe: Map<String, int>.unmodifiable(immediate),
      rawMaterials: Map<String, int>.unmodifiable(orderedRaw),
      craftSteps: List<ArcCraftStep>.unmodifiable(orderedSteps),
      unresolvedTargets: List<String>.unmodifiable(unresolved.toSet()),
    );
  }

  static ArcLoadoutCraftingPlan planForFavouriteLoadout(
    ArcSavedLoadout loadout, {
    Map<String, int> ownedItems = const <String, int>{},
  }) {
    final requested = <String, int>{};

    void request(String? name) {
      final value = name?.trim() ?? '';
      if (value.isEmpty ||
          value.toLowerCase() == 'none' ||
          value.toLowerCase() == 'not set') {
        return;
      }
      requested[value] = (requested[value] ?? 0) + 1;
    }

    request(loadout.primaryWeapon);
    for (final item in loadout.primaryAttachments) {
      request(item);
    }
    request(loadout.secondaryWeapon);
    for (final item in loadout.secondaryAttachments) {
      request(item);
    }
    request(loadout.augment);
    request(loadout.shield);
    for (final item in loadout.equipment) {
      request(item);
    }
    for (final item in loadout.consumables) {
      request(item);
    }
    for (final item in loadout.quickUse) {
      request(item);
    }

    return _planForNamedTargets(
      loadout.name,
      requested,
      ownedItems: ownedItems,
      preferHighestWeaponTier: true,
    );
  }

  static ArcLoadoutCraftingPlan planForGeneratedLoadout(
    ArcGeneratedLoadoutPlan plan, {
    Map<String, int> ownedItems = const <String, int>{},
  }) {
    final requested = <String, int>{};

    void request(String name) {
      final value = name.trim();
      if (value.isEmpty) {
        return;
      }
      requested[value] = (requested[value] ?? 0) + 1;
    }

    request(plan.primaryWeapon);
    for (final item in plan.primaryAttachments) {
      request(item);
    }
    request(plan.secondaryWeapon);
    for (final item in plan.secondaryAttachments) {
      request(item);
    }

    return _planForNamedTargets(
      plan.displayName,
      requested,
      ownedItems: ownedItems,
      preferHighestWeaponTier: true,
    );
  }

  static ArcLoadoutCraftingPlan _planForNamedTargets(
    String name,
    Map<String, int> requested, {
    required Map<String, int> ownedItems,
    required bool preferHighestWeaponTier,
  }) {
    final raw = <String, int>{};
    final steps = <String, int>{};
    final resolved = <String, int>{};
    final unresolved = <String>[];

    for (final entry in requested.entries) {
      final target = resolveCraftTarget(
        entry.key,
        preferHighestTier: preferHighestWeaponTier,
      );
      if (target == null) {
        unresolved.add(entry.key);
        continue;
      }

      resolved[target.id] = (resolved[target.id] ?? 0) + entry.value;
      final plan = planForItem(
        target.name,
        quantity: entry.value,
        ownedItems: ownedItems,
      );
      for (final material in plan.rawMaterials.entries) {
        raw[material.key] = (raw[material.key] ?? 0) + material.value;
      }
      for (final step in plan.craftSteps) {
        steps[step.itemId] = (steps[step.itemId] ?? 0) + step.quantity;
      }
      unresolved.addAll(plan.unresolvedTargets);
    }

    final orderedRaw = Map<String, int>.fromEntries(
      raw.entries.toList()..sort((a, b) {
        final aName = _byId[a.key]?.name ?? a.key;
        final bName = _byId[b.key]?.name ?? b.key;
        return aName.compareTo(bName);
      }),
    );

    final orderedSteps =
        steps.entries
            .map(
              (entry) => ArcCraftStep(itemId: entry.key, quantity: entry.value),
            )
            .toList(growable: false)
          ..sort((a, b) {
            final aName = _byId[a.itemId]?.name ?? a.itemId;
            final bName = _byId[b.itemId]?.name ?? b.itemId;
            return aName.compareTo(bName);
          });

    return ArcLoadoutCraftingPlan(
      loadoutName: name,
      resolvedTargets: Map<String, int>.unmodifiable(resolved),
      rawMaterials: Map<String, int>.unmodifiable(orderedRaw),
      craftSteps: List<ArcCraftStep>.unmodifiable(orderedSteps),
      unresolvedTargets: List<String>.unmodifiable(unresolved.toSet()),
    );
  }

  static List<ArcRecycleSource> recyclersFor(String resourceQuery) {
    final resource = resolve(resourceQuery);
    final resourceId =
        resource?.id ?? normalise(resourceQuery).replaceAll(' ', '_');

    final sources = <ArcRecycleSource>[
      for (final item in recyclables)
        if ((item.recyclesInto[resourceId] ?? 0) > 0)
          ArcRecycleSource(
            item: item,
            resourceId: resourceId,
            yield: item.recyclesInto[resourceId]!,
          ),
    ];

    sources.sort((a, b) {
      final yieldCompare = b.yield.compareTo(a.yield);
      if (yieldCompare != 0) {
        return yieldCompare;
      }
      return a.item.name.compareTo(b.item.name);
    });
    return sources;
  }

  static String itemName(String id) => _byId[id]?.name ?? id;

  static String recyclingSummary(
    String spokenQuery, {
    Map<String, int> materialNeeds = const <String, int>{},
    Set<String> keepItemIds = const <String>{},
  }) {
    final item = resolve(spokenQuery);
    if (item == null) {
      return 'I could not match $spokenQuery to an ARC Raiders item.';
    }

    final keep = keepItemIds.contains(item.id);
    if (!item.recyclable) {
      return keep
          ? '${item.name} is on your keep list and has no tracked Topside recycling output.'
          : '${item.name} has no tracked Topside recycling output.';
    }

    final outputs = item.recyclesInto.entries
        .map((entry) => '${entry.value} ${itemName(entry.key)}')
        .join(', ');

    final useful = item.recyclesInto.entries
        .where((entry) => (materialNeeds[entry.key] ?? 0) > 0)
        .map((entry) => itemName(entry.key))
        .toList(growable: false);

    final keepPrefix = keep
        ? '${item.name} is currently needed, so keep it unless you deliberately want the materials.'
        : '${item.name} is not on your current keep list.';

    final usefulSuffix = useful.isEmpty
        ? ''
        : ' ${useful.join(' and ')} also help your current crafting requirements.';

    return '$keepPrefix Topside recycling returns $outputs.$usefulSuffix';
  }
}
