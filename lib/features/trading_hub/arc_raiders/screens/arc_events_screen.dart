import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/build/app_drawer.dart';
import 'package:uag_arc_raiders_hub/screens/build/app_bar.dart';
import '../data/arc_event_relevance.dart';
import '../data/arc_progression_engine.dart';
import '../models/arc_blueprint_state.dart';
import '../models/arc_loadout_models.dart';
import '../models/arc_progression_models.dart';
import '../models/arc_scrappy_state.dart';
import '../models/arc_user_personalisation_profile.dart';
import '../repositories/arc_blueprint_repository.dart';
import '../repositories/arc_saved_loadout_repository.dart';
import '../repositories/arc_progression_repository.dart';
import '../repositories/arc_scrappy_repository.dart';
import '../repositories/arc_scrappy_repository_state.dart';
import '../repositories/arc_user_personalisation_repository.dart';
import '../widgets/arc_events_workspace.dart';
import '../widgets/arc_raiders_screen_shell.dart';

class ArcEventsScreen extends StatefulWidget {
  const ArcEventsScreen({super.key});
  static const routeName = arcEventsRoute;
  @override
  State<ArcEventsScreen> createState() => _ArcEventsScreenState();
}

class _ArcEventsScreenState extends State<ArcEventsScreen> {
  final _subscriptions = <StreamSubscription<dynamic>>[];
  final _waiting = <String>{
    'preferences',
    'Blueprints',
    'loadouts',
    'progression',
    'resources',
  };
  final _failures = <String>{};
  ArcUserPersonalisationProfile _profile =
      ArcUserPersonalisationProfile.defaults;
  Map<String, ArcBlueprintState>? _blueprints;
  List<ArcSavedLoadout> _loadouts = [];
  ArcProgressionRecords _records = ArcProgressionRecords.empty;
  Map<String, ArcScrappyState>? _resources;

  @override
  void initState() {
    super.initState();
    _listen(
      'preferences',
      ArcUserPersonalisationRepository().watchProfile(),
      (value) => _profile = value,
    );
    _listen(
      'Blueprints',
      ArcBlueprintRepository().watchMyBlueprintStates(),
      (value) => _blueprints = value,
    );
    _listen(
      'loadouts',
      ArcSavedLoadoutRepository().watchSavedLoadouts(),
      (value) => _loadouts = value,
    );
    _listen(
      'progression',
      ArcProgressionRepository().watchProgressionRecords(),
      (value) => _records = value,
    );
    _listen('resources', ArcScrappyRepository().watchMyScrappyStates(), (
      value,
    ) {
      if (value.status == ArcScrappyRepositoryStateStatus.error) {
        _failures.add('resources');
      } else if (value.status == ArcScrappyRepositoryStateStatus.loaded ||
          value.status == ArcScrappyRepositoryStateStatus.empty) {
        _resources = value.data ?? {};
      } else {
        _resources = null;
        _waiting.add('resources');
      }
    });
  }

  void _listen<T>(String name, Stream<T> stream, void Function(T) update) {
    _subscriptions.add(
      stream.listen(
        (value) {
          if (!mounted) return;
          setState(() {
            _waiting.remove(name);
            _failures.remove(name);
            update(value);
          });
        },
        onError: (Object error) {
          if (mounted) {
            setState(() {
              _waiting.remove(name);
              _failures.add(name);
            });
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    appBar: UagAppBar(title: 'Events', subtitle: 'Operations schedule'),
    drawer: const AppDrawer(),
    body: ArcRaidersScreenShell(
      child: ArcRaidersPageList(
        maxWidth: 1220,
        children: [
          ArcEventsWorkspace(
            relevance: ArcEventRelevance(
              profile: _profile,
              blueprints: _blueprints,
              loadouts: _loadouts,
              progression:
                  _resources == null || _waiting.contains('progression')
                  ? ArcProgressionSnapshotBundle.empty
                  : const ArcProgressionEngine().build(
                      scrappyStates: _resources!,
                      records: _records,
                    ),
            ),
            contextNotice: _failures.isNotEmpty
                ? '${_failures.join(', ')} unavailable. Relevance uses retained data where available.'
                : _waiting.isNotEmpty
                ? 'Loading saved relevance context…'
                : null,
          ),
        ],
      ),
    ),
  );
}
