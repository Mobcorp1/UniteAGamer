import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/arc_raider_setup_evaluator.dart';
import '../data/arc_progression_engine.dart';
import '../data/arc_quest_catalogue.dart';
import '../repositories/arc_raider_setup_repository.dart';
import '../../../../widgets/theme.dart';

/// Only setup-owned navigation may open these editors before completion.
class ArcRaiderSetupEditorAccess {
  const ArcRaiderSetupEditorAccess._();
  static const token = ArcRaiderSetupEditorAccess._();
  static const routes = <String>{
    '/trading-hub/arc-raiders/profile/setup',
    '/trading-hub/arc-raiders/profile/availability',
    '/trading-hub/arc-raiders/blueprints',
    '/favourite-loadout',
  };
}

class ArcRaiderSetupGate extends StatefulWidget {
  const ArcRaiderSetupGate({super.key, required this.child, this.repository});
  final Widget child;
  final ArcRaiderSetupRepository? repository;
  @override
  State<ArcRaiderSetupGate> createState() => _ArcRaiderSetupGateState();
}

class _ArcRaiderSetupGateState extends State<ArcRaiderSetupGate> {
  late final _repository = widget.repository ?? ArcRaiderSetupRepository();
  late Future<ArcRaiderSetupSnapshot> _snapshot = _repository.load();
  void _reload() {
    final next = _repository.load();
    setState(() {
      _snapshot = next;
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ArcRaiderSetupSnapshot>(
    future: _snapshot,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Raider Setup could not be loaded.'),
                  TextButton(onPressed: _reload, child: const Text('Retry')),
                ],
              ),
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (!snapshot.data!.status.needsSetup) return widget.child;
      return ArcRaiderSetupScreen(
        repository: _repository,
        snapshot: snapshot.data!,
        onCompleted: _reload,
      );
    },
  );
}

class ArcRaiderSetupScreen extends StatefulWidget {
  const ArcRaiderSetupScreen({
    super.key,
    required this.repository,
    required this.snapshot,
    required this.onCompleted,
  });
  final ArcRaiderSetupRepository repository;
  final ArcRaiderSetupSnapshot snapshot;
  final VoidCallback onCompleted;
  @override
  State<ArcRaiderSetupScreen> createState() => _ArcRaiderSetupScreenState();
}

class _ArcRaiderSetupScreenState extends State<ArcRaiderSetupScreen> {
  late ArcRaiderSetupSnapshot _snapshot = widget.snapshot;
  bool _saving = false;
  String? _error;
  String _query = '';
  final Set<String> _quests = {};
  int? _scrappyLevel;
  final Map<String, int?> _benchLevels = {};
  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await action();
      final snapshot = await widget.repository.load();
      if (mounted) setState(() => _snapshot = snapshot);
    } catch (error) {
      if (mounted) setState(() => _error = 'Setup was not saved. $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _edit(String route) => _run(() async {
    await Navigator.of(
      context,
    ).pushNamed(route, arguments: ArcRaiderSetupEditorAccess.token);
  });
  Widget _button(String label, Future<void> Function() action) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: FilledButton(
      onPressed: _saving ? null : () => _run(action),
      child: Text(label, textAlign: TextAlign.center),
    ),
  );
  Widget _editor(String label, String route) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: OutlinedButton(
      onPressed: _saving ? null : () => _edit(route),
      child: Text(label),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final status = _snapshot.status;
    final next = status.missing.firstOrNull;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.cardBackgroundDeep,
        appBar: AppBar(
          title: const Text('RAIDER SETUP'),
          automaticallyImplyLeading: false,
          actions: [
            TextButton(
              onPressed: _saving ? null : () => FirebaseAuth.instance.signOut(),
              child: const Text('Sign out'),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    '${status.completed.length} / 7 COMPLETE',
                    style: AppTheme.tradingHeading(
                      fontSize: 24,
                      color: AppTheme.neonCyan,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: status.completed.length / 7),
                  const SizedBox(height: 12),
                  if (!status.ready)
                    const Text(
                      'Confirm your current Raider state. Existing progress is kept; imports do not award completion credit.',
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.amber),
                      ),
                    ),
                  if (_saving) const LinearProgressIndicator(),
                  if (next != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      next.label.toUpperCase(),
                      style: AppTheme.tradingHeading(
                        fontSize: 22,
                        color: AppTheme.neonPink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._section(next),
                    const SizedBox(height: 20),
                    for (final section in status.missing.skip(1))
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.radio_button_unchecked),
                        title: Text(section.label),
                      ),
                  ] else ...[
                    const Text('RAIDER INTELLIGENCE READY'),
                    for (final section in ArcRaiderSetupSection.values)
                      ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.check,
                          color: AppTheme.neonCyan,
                        ),
                        title: Text(section.label),
                      ),
                    _button('ENTER COMMAND CENTRE', () async {
                      await widget.repository.complete();
                      if (mounted) widget.onCompleted();
                    }),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _section(ArcRaiderSetupSection section) {
    switch (section) {
      case ArcRaiderSetupSection.profile:
        return [
          const Text(
            'Complete your existing Raider identity, including Embark ID.',
          ),
          _editor('Complete Profile', '/trading-hub/arc-raiders/profile/setup'),
        ];
      case ArcRaiderSetupSection.availability:
        return [
          const Text(
            'Save your usual times, or confirm that you have no fixed pattern.',
          ),
          _editor(
            'Edit Availability',
            '/trading-hub/arc-raiders/profile/availability',
          ),
          _button(
            'Flexible / no fixed pattern',
            widget.repository.confirmFlexibleAvailability,
          ),
        ];
      case ArcRaiderSetupSection.blueprints:
        return [
          const Text(
            'Use your existing Tracker to import or select owned Blueprints, then return here.',
          ),
          _editor(
            'Open Blueprint Tracker',
            '/trading-hub/arc-raiders/blueprints',
          ),
          _button('No Blueprints yet', widget.repository.confirmNoBlueprints),
        ];
      case ArcRaiderSetupSection.loadout:
        return [
          _editor('Configure Favourite Loadout', '/favourite-loadout'),
          _button(
            'Not decided yet — set later',
            widget.repository.deferLoadout,
          ),
        ];
      case ArcRaiderSetupSection.quests:
        final completed = _snapshot.progression.questRecords;
        final nodes = ArcQuestCatalogue.nodes.where(
          (q) =>
              completed[q.id]?.completed != true &&
              '${q.displayName} ${q.trader}'.toLowerCase().contains(
                _query.toLowerCase(),
              ),
        );
        return [
          const Text(
            'Choose the quests currently active in your game. Verified prerequisites are imported automatically without rewards.',
          ),
          if (!completed.values.any((q) => q.completed))
            _button(
              'Starting / reset — start at the first quest',
              () => widget.repository.setQuestPosition({
                ArcQuestCatalogue.rootQuestId,
              }),
            ),
          _button(
            'No active quests right now',
            widget.repository.confirmNoActiveQuests,
          ),
          TextField(
            decoration: const InputDecoration(labelText: 'Find current quests'),
            onChanged: (value) => setState(() => _query = value),
          ),
          if (_quests.isNotEmpty)
            _button(
              'Import ${_quests.length} current quest(s)',
              () => widget.repository.setQuestPosition(_quests),
            ),
          for (final quest in nodes)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(quest.displayName),
              subtitle: Text(quest.trader),
              value: _quests.contains(quest.id),
              onChanged: _saving
                  ? null
                  : (value) => setState(() {
                      if (value == true) {
                        _quests.add(quest.id);
                      } else {
                        _quests.remove(quest.id);
                      }
                    }),
            ),
        ];
      case ArcRaiderSetupSection.scrappy:
        final levels = {
          1,
          ...const ArcProgressionEngine().scrappyDefinitions.map(
            (d) => d.level,
          ),
        }.toList()..sort();
        return [
          DropdownButtonFormField<int>(
            initialValue: _scrappyLevel,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Current Scrappy level',
            ),
            items: [
              for (final level in levels)
                DropdownMenuItem(value: level, child: Text('Level $level')),
            ],
            onChanged: _saving
                ? null
                : (value) => setState(() => _scrappyLevel = value),
          ),
          if (_scrappyLevel != null)
            _button(
              'Confirm Scrappy baseline',
              () => widget.repository.setScrappyLevel(_scrappyLevel!),
            ),
        ];
      case ArcRaiderSetupSection.benches:
        final definitions = const ArcProgressionEngine().benchDefinitions;
        final stations = definitions.map((d) => d.station).toSet();
        for (final station in stations) {
          final current =
              _snapshot
                  .progression
                  .benchRecords[ArcProgressionEngine.benchIdFor(station)]
                  ?.currentLevel ??
              0;
          _benchLevels.putIfAbsent(station, () => current > 0 ? current : null);
        }
        return [
          const Text(
            'Confirm every station. Not built is a valid baseline. Existing higher levels are preserved.',
          ),
          for (final station in stations)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: DropdownButtonFormField<int>(
                initialValue: _benchLevels[station],
                isExpanded: true,
                decoration: InputDecoration(labelText: station),
                items: [
                  const DropdownMenuItem(value: 0, child: Text('Not built')),
                  for (final level
                      in definitions
                          .where((d) => d.station == station)
                          .map((d) => d.level)
                          .toSet())
                    DropdownMenuItem(value: level, child: Text('Level $level')),
                ],
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _benchLevels[station] = value),
              ),
            ),
          if (stations.every((station) => _benchLevels[station] != null))
            _button(
              'Confirm Bench baseline',
              () => widget.repository.setBenchLevels({
                for (final station in stations) station: _benchLevels[station]!,
              }),
            ),
        ];
    }
  }
}
