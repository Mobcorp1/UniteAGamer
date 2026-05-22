import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
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

  List<ArcBlueprint> _optionsForSlot({
    required int slotIndex,
    required Map<String, ArcBlueprintState> states,
  }) {
    final currentId = _selectedIds[slotIndex];
    final selectedSet = _selectedIds.whereType<String>().toSet();

    final options =
        ArcBlueprintSeedData.blueprints
            .where((blueprint) {
              final state =
                  states[blueprint.id] ?? ArcBlueprintState.empty(blueprint.id);

              if (blueprint.id == currentId) {
                return true;
              }

              if (selectedSet.contains(blueprint.id)) {
                return false;
              }

              return !state.owned;
            })
            .toList(growable: false)
          ..sort((a, b) => a.name.compareTo(b.name));

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
              builder: (context, snapshot) {
                final states =
                    snapshot.data ?? const <String, ArcBlueprintState>{};

                if (!_saving && snapshot.hasData) {
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

                final selectedCount = _selectedIds
                    .whereType<String>()
                    .where((id) => id.isNotEmpty)
                    .length;

                return ListView(
                  padding: const EdgeInsets.all(AppTheme.spaceM),
                  children: [
                    ElectricChargeBorder(
                      active: true,
                      radius: 18,
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.spaceM),
                        decoration: AppTheme.tradingCardDecoration(radius: 18),
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
                              'Set up to 5 active blueprint hunts. Smart Trade Assist uses this same list as your wanted priority source.',
                              style: AppTheme.bodyTextStyle(
                                fontSize: 14,
                                color: AppTheme.tradingMutedText,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '$selectedCount / 5 active hunts selected',
                              style: AppTheme.bodyTextStyle(
                                fontSize: 13,
                                color: AppTheme.neonCyan,
                                isBold: true,
                              ),
                            ),
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
                        ),
                        onChanged: (value) {
                          setState(() {
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
            ),
          ),
        ],
      ),
    );
  }
}

class _HuntTargetDropdown extends StatelessWidget {
  final int index;
  final String? value;
  final List<ArcBlueprint> options;
  final ValueChanged<String?> onChanged;

  const _HuntTargetDropdown({
    required this.index,
    required this.value,
    required this.options,
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
          ...options.whereType<ArcBlueprint>().map(
            (blueprint) => DropdownMenuItem<String?>(
              value: blueprint.id,
              child: Text(
                blueprint.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
