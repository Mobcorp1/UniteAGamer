import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/repositories/trading_repository.dart';
import 'package:uag_traders_hub/widgets/electric_charge_border.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class RaidPlannerHuntTargetsScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/raid-planner/hunt-targets';

  const RaidPlannerHuntTargetsScreen({super.key});

  @override
  State<RaidPlannerHuntTargetsScreen> createState() =>
      _RaidPlannerHuntTargetsScreenState();
}

class _RaidPlannerHuntTargetsScreenState
    extends State<RaidPlannerHuntTargetsScreen> {
  final TradingRepository _repository = TradingRepository();
  List<String?> _selectedIds = List<String?>.filled(5, null);
  bool _saving = false;
  bool _syncing = false;
  bool _manualDirty = false;
  String _lastSyncSignature = '';

  void _hydrateFromStates(Map<String, ArcBlueprintState> states) {
    final next = List<String?>.filled(5, null);

    for (final entry in states.entries) {
      final rank = entry.value.priorityRank;
      if (rank >= 1 && rank <= 5) {
        next[rank - 1] = entry.key;
      }
    }

    _selectedIds = next;
  }

  int _rarityScore(ArcBlueprintRarity rarity) {
    switch (rarity) {
      case ArcBlueprintRarity.legendary:
        return 5;
      case ArcBlueprintRarity.epic:
        return 4;
      case ArcBlueprintRarity.rare:
        return 3;
      case ArcBlueprintRarity.uncommon:
        return 2;
      case ArcBlueprintRarity.common:
        return 1;
    }
  }

  String _normalise(String value) {
    return value.trim().toLowerCase();
  }

  Set<String> _tradeAvailableBlueprintIds(List<TradingListing> listings) {
    final currentUid = _repository.currentUid;
    final offeredNames = <String>{};

    for (final listing in listings) {
      if (!listing.active) {
        continue;
      }
      if (currentUid != null && listing.ownerUid == currentUid) {
        continue;
      }

      offeredNames.add(_normalise(listing.offeredItem));
      offeredNames.addAll(listing.offeredBlueprintNames.map(_normalise));
      offeredNames.addAll(listing.offeredTradeItemNames.map(_normalise));
      offeredNames.addAll(listing.offeredAssetNames.map(_normalise));
    }

    return ArcBlueprintSeedData.blueprints
        .where(
          (blueprint) =>
              offeredNames.contains(_normalise(blueprint.id)) ||
              offeredNames.contains(_normalise(blueprint.name)),
        )
        .map((blueprint) => blueprint.id)
        .toSet();
  }

  List<String?> _buildSmartHuntQueue({
    required Map<String, ArcBlueprintState> states,
    required List<TradingListing> listings,
  }) {
    final tradeAvailableIds = _tradeAvailableBlueprintIds(listings);
    final selected = <String>[];

    final rankedEntries =
        states.entries
            .where((entry) => entry.value.priorityRank >= 1)
            .where((entry) => entry.value.priorityRank <= 5)
            .toList()
          ..sort(
            (a, b) => a.value.priorityRank.compareTo(b.value.priorityRank),
          );

    for (final entry in rankedEntries) {
      final state = entry.value;
      if (state.owned) {
        continue;
      }
      if (!selected.contains(entry.key)) {
        selected.add(entry.key);
      }
    }

    final candidateBlueprints = ArcBlueprintSeedData.blueprints.where((
      blueprint,
    ) {
      final state =
          states[blueprint.id] ?? ArcBlueprintState.empty(blueprint.id);
      if (state.owned) {
        return false;
      }
      if (selected.contains(blueprint.id)) {
        return false;
      }
      return true;
    }).toList();

    candidateBlueprints.sort((a, b) {
      final aTrade = tradeAvailableIds.contains(a.id) ? 1 : 0;
      final bTrade = tradeAvailableIds.contains(b.id) ? 1 : 0;
      final tradeCompare = bTrade.compareTo(aTrade);
      if (tradeCompare != 0) {
        return tradeCompare;
      }

      final rarityCompare = _rarityScore(
        b.rarity,
      ).compareTo(_rarityScore(a.rarity));
      if (rarityCompare != 0) {
        return rarityCompare;
      }

      return a.sortOrder.compareTo(b.sortOrder);
    });

    for (final blueprint in candidateBlueprints) {
      if (selected.length >= 5) {
        break;
      }
      selected.add(blueprint.id);
    }

    return List<String?>.generate(
      5,
      (index) => index < selected.length ? selected[index] : null,
    );
  }

  int _ownedRankedCount(Map<String, ArcBlueprintState> states) {
    return states.values
        .where((state) => state.priorityRank >= 1 && state.priorityRank <= 5)
        .where((state) => state.owned)
        .length;
  }

  int _filledCount(List<String?> before, List<String?> after) {
    final beforeCount = before
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .length;
    final afterCount = after
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .length;
    return afterCount > beforeCount ? afterCount - beforeCount : 0;
  }

  Future<void> _autoSyncHunts({
    required Map<String, ArcBlueprintState> states,
    required List<TradingListing> listings,
  }) async {
    if (_saving || _syncing || _manualDirty) {
      return;
    }

    final next = _buildSmartHuntQueue(states: states, listings: listings);
    final currentFromStates = List<String?>.filled(5, null);

    for (final entry in states.entries) {
      final rank = entry.value.priorityRank;
      if (rank >= 1 && rank <= 5) {
        currentFromStates[rank - 1] = entry.key;
      }
    }

    final signature = next.map((id) => id ?? '').join('|');
    final currentSignature = currentFromStates.map((id) => id ?? '').join('|');

    if (signature == currentSignature || signature == _lastSyncSignature) {
      if (_selectedIds.map((id) => id ?? '').join('|') != signature) {
        setState(() => _selectedIds = next);
      }
      return;
    }

    final updates = <ArcBlueprintState>[];
    final selectedById = <String, int>{};

    for (var index = 0; index < next.length; index++) {
      final blueprintId = next[index];
      if (blueprintId == null || blueprintId.trim().isEmpty) {
        continue;
      }
      selectedById[blueprintId] = index + 1;
    }

    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      final current =
          states[blueprint.id] ?? ArcBlueprintState.empty(blueprint.id);
      final nextRank = selectedById[blueprint.id] ?? 0;

      if (current.priorityRank != nextRank) {
        updates.add(
          current.copyWith(
            blueprintId: blueprint.id,
            priorityRank: nextRank,
            updatedAt: DateTime.now(),
          ),
        );
      }
    }

    if (updates.isEmpty) {
      setState(() => _selectedIds = next);
      _lastSyncSignature = signature;
      return;
    }

    final removedOwned = _ownedRankedCount(states);
    final filled = _filledCount(currentFromStates, next);

    setState(() {
      _syncing = true;
      _selectedIds = next;
    });

    try {
      await _saveBlueprintStates(updates);
      _lastSyncSignature = signature;

      if (!mounted) {
        return;
      }

      if (removedOwned > 0 || filled > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              removedOwned > 0
                  ? 'Hunts updated: removed $removedOwned owned target${removedOwned == 1 ? '' : 's'} and refilled open slots.'
                  : 'Hunts updated: filled $filled open slot${filled == 1 ? '' : 's'}.',
            ),
            backgroundColor: AppTheme.cardBackgroundDeep,
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not auto-sync hunts: $error'),
          backgroundColor: AppTheme.cardBackgroundDeep,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  List<ArcBlueprint> _optionsForSlot({
    required int slotIndex,
    required Map<String, ArcBlueprintState> states,
    required List<TradingListing> listings,
  }) {
    final currentId = _selectedIds[slotIndex];
    final selectedSet = _selectedIds.whereType<String>().toSet();
    final tradeAvailableIds = _tradeAvailableBlueprintIds(listings);

    final options = ArcBlueprintSeedData.blueprints.where((blueprint) {
      final state =
          states[blueprint.id] ?? ArcBlueprintState.empty(blueprint.id);
      if (blueprint.id == currentId) {
        return true;
      }
      if (selectedSet.contains(blueprint.id)) {
        return false;
      }
      return !state.owned;
    }).toList();

    options.sort((a, b) {
      final aTrade = tradeAvailableIds.contains(a.id) ? 1 : 0;
      final bTrade = tradeAvailableIds.contains(b.id) ? 1 : 0;
      final tradeCompare = bTrade.compareTo(aTrade);
      if (tradeCompare != 0) {
        return tradeCompare;
      }

      final rarityCompare = _rarityScore(
        b.rarity,
      ).compareTo(_rarityScore(a.rarity));
      if (rarityCompare != 0) {
        return rarityCompare;
      }

      return a.name.compareTo(b.name);
    });

    return options;
  }

  Future<void> _saveBlueprintStates(List<ArcBlueprintState> states) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('You must be signed in to save hunt targets.');
    }

    if (states.isEmpty) {
      return;
    }

    final batch = FirebaseFirestore.instance.batch();
    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('arc_blueprints');

    for (final state in states) {
      final blueprintId = state.blueprintId.trim();
      if (blueprintId.isEmpty) {
        continue;
      }

      batch.set(
        collection.doc(blueprintId),
        state.toMap(),
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<void> _save(Map<String, ArcBlueprintState> states) async {
    if (_saving) {
      return;
    }

    setState(() => _saving = true);

    final selectedById = <String, int>{};

    for (var index = 0; index < _selectedIds.length; index++) {
      final blueprintId = _selectedIds[index];

      if (blueprintId == null || blueprintId.trim().isEmpty) {
        continue;
      }

      selectedById[blueprintId] = index + 1;
    }

    final updates = <ArcBlueprintState>[];

    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      final current =
          states[blueprint.id] ?? ArcBlueprintState.empty(blueprint.id);
      final nextRank = selectedById[blueprint.id] ?? 0;

      if (current.priorityRank != nextRank) {
        updates.add(
          current.copyWith(
            blueprintId: blueprint.id,
            priorityRank: nextRank,
            updatedAt: DateTime.now(),
          ),
        );
      }
    }

    try {
      if (updates.isNotEmpty) {
        await _saveBlueprintStates(updates);
      }

      _manualDirty = false;
      _lastSyncSignature = _selectedIds.map((id) => id ?? '').join('|');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved ${selectedById.length} active hunt targets.'),
          backgroundColor: AppTheme.cardBackgroundDeep,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save hunt targets: $error'),
          backgroundColor: AppTheme.cardBackgroundDeep,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _clearAll() {
    setState(() {
      _manualDirty = true;
      _selectedIds = List<String?>.filled(5, null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackgroundDeep,
        foregroundColor: Colors.white,
        title: Text(
          'Active Hunt Targets',
          style: AppTheme.neonTextStyle(
            fontSize: 22,
            color: AppTheme.neonCyan,
            isBold: true,
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: StaticWatermark()),
          SafeArea(
            child: StreamBuilder<Map<String, ArcBlueprintState>>(
              stream: _repository.watchBlueprintStates(),
              builder: (context, stateSnapshot) {
                final states = stateSnapshot.data ?? const {};

                if (!_saving &&
                    !_syncing &&
                    !_manualDirty &&
                    stateSnapshot.hasData) {
                  final existing = _selectedIds.whereType<String>().toSet();
                  final incoming = <String>{};

                  for (final entry in states.entries) {
                    final rank = entry.value.priorityRank;
                    if (rank >= 1 && rank <= 5) {
                      incoming.add(entry.key);
                    }
                  }

                  if (existing.isEmpty && incoming.isNotEmpty) {
                    _hydrateFromStates(states);
                  }
                }

                return StreamBuilder<List<TradingListing>>(
                  stream: _repository.watchActiveListings(),
                  builder: (context, listingSnapshot) {
                    final listings =
                        listingSnapshot.data ?? const <TradingListing>[];

                    if (stateSnapshot.hasData && listingSnapshot.hasData) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) {
                          return;
                        }

                        unawaited(
                          _autoSyncHunts(states: states, listings: listings),
                        );
                      });
                    }

                    final selectedCount = _selectedIds
                        .whereType<String>()
                        .where((id) => id.isNotEmpty)
                        .length;

                    final ownedRankedCount = _ownedRankedCount(states);
                    final tradeAvailableIds = _tradeAvailableBlueprintIds(
                      listings,
                    );
                    final selectedTradeAvailable = _selectedIds
                        .whereType<String>()
                        .where(tradeAvailableIds.contains)
                        .length;

                    return ListView(
                      padding: const EdgeInsets.all(AppTheme.spaceM),
                      children: [
                        ElectricChargeBorder(
                          active: true,
                          radius: 18,
                          child: Container(
                            padding: const EdgeInsets.all(AppTheme.spaceM),
                            decoration: AppTheme.tradingCardDecoration(
                              radius: 18,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Raid Planner Source of Truth',
                                  style: AppTheme.neonTextStyle(
                                    fontSize: 24,
                                    color: AppTheme.neonPink,
                                    isBold: true,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Hunts now sync with Blueprint Tracker ownership. Owned targets are removed from active hunt slots and replacements are filled automatically.',
                                  style: AppTheme.bodyTextStyle(
                                    fontSize: 14,
                                    color: AppTheme.tradingMutedText,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _StatusPill(
                                      label: '$selectedCount / 5 active',
                                      color: AppTheme.neonCyan,
                                    ),
                                    _StatusPill(
                                      label:
                                          '$ownedRankedCount owned removed automatically',
                                      color: AppTheme.neonPink,
                                    ),
                                    _StatusPill(
                                      label:
                                          '$selectedTradeAvailable trade-linked',
                                      color: Colors.white70,
                                    ),
                                  ],
                                ),
                                if (_syncing) ...[
                                  const SizedBox(height: 12),
                                  LinearProgressIndicator(
                                    minHeight: 3,
                                    color: AppTheme.neonCyan,
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.08,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceM),
                        for (var index = 0; index < 5; index++) ...[
                          _HuntTargetDropdown(
                            index: index,
                            value: _selectedIds[index],
                            options: _optionsForSlot(
                              slotIndex: index,
                              states: states,
                              listings: listings,
                            ),
                            tradeAvailableIds: tradeAvailableIds,
                            onChanged: (value) {
                              setState(() {
                                _manualDirty = true;
                                _selectedIds[index] = value;
                              });
                            },
                          ),
                          const SizedBox(height: AppTheme.spaceS),
                        ],
                        const SizedBox(height: AppTheme.spaceM),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _saving ? null : _clearAll,
                                icon: const Icon(Icons.clear_all_rounded),
                                label: const Text('Clear'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white70,
                                  side: BorderSide(
                                    color: AppTheme.neonCyan.withValues(
                                      alpha: 0.45,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spaceS),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _saving ? null : () => _save(states),
                                icon: _saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.save_rounded),
                                label: Text(_saving ? 'Saving' : 'Save Hunts'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.neonPink,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceS,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: AppTheme.bodyTextStyle(fontSize: 12, color: color, isBold: true),
      ),
    );
  }
}

class _HuntTargetDropdown extends StatelessWidget {
  final int index;
  final String? value;
  final List<ArcBlueprint> options;
  final Set<String> tradeAvailableIds;
  final ValueChanged<String?> onChanged;

  const _HuntTargetDropdown({
    required this.index,
    required this.value,
    required this.options,
    required this.tradeAvailableIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceS),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.25)),
      ),
      child: DropdownButtonFormField<String?>(
        initialValue: value,
        isExpanded: true,
        dropdownColor: AppTheme.cardBackgroundDeep,
        decoration: InputDecoration(
          labelText: 'Priority ${index + 1}',
          labelStyle: TextStyle(
            color: AppTheme.neonCyan.withValues(alpha: 0.85),
          ),
          border: InputBorder.none,
        ),
        style: const TextStyle(color: Colors.white),
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('Not set', style: TextStyle(color: Colors.white70)),
          ),
          ...options.map((blueprint) {
            final tradeLinked = tradeAvailableIds.contains(blueprint.id);

            return DropdownMenuItem<String?>(
              value: blueprint.id,
              child: Text(
                tradeLinked
                    ? '${blueprint.name} - trade available'
                    : '${blueprint.name} - ${blueprint.rarityLabel}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tradeLinked ? AppTheme.neonCyan : Colors.white,
                ),
              ),
            );
          }),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
