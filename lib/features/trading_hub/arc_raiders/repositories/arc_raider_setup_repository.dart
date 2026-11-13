import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/arc_raider_setup_evaluator.dart';
import '../data/arc_progression_engine.dart';
import '../data/arc_quest_catalogue.dart';
import '../models/arc_availability.dart';
import '../models/arc_progression_models.dart';
import 'arc_blueprint_repository.dart';
import 'arc_progression_repository.dart';
import 'arc_saved_loadout_repository.dart';
import 'arc_trader_profile_repository.dart';

class ArcRaiderSetupSnapshot {
  const ArcRaiderSetupSnapshot({
    required this.status,
    required this.progression,
  });
  final ArcRaiderSetupStatus status;
  final ArcProgressionRecords progression;
}

class ArcRaiderSetupRepository {
  ArcRaiderSetupRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    ArcProgressionRepository? progression,
    ArcBlueprintRepository? blueprints,
    ArcTraderProfileRepository? profile,
    ArcSavedLoadoutRepository? loadouts,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance {
    this.progression =
        progression ??
        ArcProgressionRepository(firestore: _firestore, auth: _auth);
    this.profile =
        profile ??
        ArcTraderProfileRepository(firestore: _firestore, auth: _auth);
    _blueprints =
        blueprints ??
        ArcBlueprintRepository(firestore: _firestore, auth: _auth);
    _loadouts =
        loadouts ??
        ArcSavedLoadoutRepository(firestore: _firestore, auth: _auth);
  }
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  late final ArcProgressionRepository progression;
  late final ArcTraderProfileRepository profile;
  late final ArcBlueprintRepository _blueprints;
  late final ArcSavedLoadoutRepository _loadouts;
  DocumentReference<Map<String, dynamic>> get _user {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sign in to complete Raider Setup.');
    return _firestore.collection('users').doc(uid);
  }

  Future<ArcRaiderSetupSnapshot> load() async {
    final userRef = _user;
    final userData = (await userRef.get()).data() ?? <String, dynamic>{};
    final uid = userRef.id;
    final profileData =
        (await profile.profileDoc(uid).get()).data() ?? <String, dynamic>{};
    final availability =
        (await profile.availabilityDoc(uid).get()).data() ??
        <String, dynamic>{};
    final records = await progression.loadProgressionRecords();
    final blueprints = await _blueprints.loadMyBlueprintStates();
    final configuredLoadout = await _loadouts.hasConfiguredFavouriteLoadout();
    return ArcRaiderSetupSnapshot(
      progression: records,
      status: const ArcRaiderSetupEvaluator().evaluate(
        userData: userData,
        profileData: profileData,
        availabilityData: availability,
        progression: records,
        hasOwnedBlueprints: blueprints.values.any((state) => state.owned),
        hasConfiguredLoadout: configuredLoadout,
      ),
    );
  }

  Future<void> _confirm(Map<String, dynamic> values) async {
    final ref = _user;
    final records = await progression.loadProgressionRecords();
    await _firestore.runTransaction((transaction) async {
      final userData =
          (await transaction.get(ref)).data() ?? <String, dynamic>{};
      final previous = ArcRaiderSetupEvaluator.map(userData['arcRaiderSetup']);
      final sameSeason = previous['seasonId'] == records.seasonId;
      // Replace this metadata field atomically, never merge old season answers.
      transaction.update(ref, {
        'arcRaiderSetup': {
          if (sameSeason) ...previous,
          if (!sameSeason && previous['loadoutDeferred'] == true)
            'loadoutDeferred': true,
          'confirmationVersion': ArcRaiderSetupEvaluator.version,
          'seasonId': records.seasonId,
          ...values,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      });
    });
  }

  Future<void> confirmNoActiveQuests() async {
    await progression.setCurrentQuestIds({});
    await _confirm({'noActiveQuestsConfirmed': true});
  }

  Future<void> setQuestPosition(Set<String> ids) async {
    if (ids.isEmpty ||
        ids.any((id) => !ArcQuestCatalogue.byId.containsKey(id))) {
      throw ArgumentError(
        'Choose at least one current quest from the catalogue.',
      );
    }
    await progression.setCurrentQuestIds(ids);
  }

  Future<void> setScrappyLevel(int level) async {
    await progression.setScrappyBaseline(level: level);
    if (level == 1) await _confirm({'scrappyStartingConfirmed': true});
  }

  Future<void> setBenchLevels(Map<String, int> levels) async {
    final definitions = const ArcProgressionEngine().benchDefinitions;
    final stations = definitions.map((d) => d.station).toSet();
    if (levels.length != stations.length ||
        !stations.every(levels.containsKey) ||
        levels.entries.any(
          (e) =>
              e.value != 0 &&
              !definitions.any((d) => d.station == e.key && d.level == e.value),
        )) {
      throw ArgumentError('Confirm a supported level for every bench.');
    }
    // Validate the entire form before any writes. Import APIs never lower progress.
    for (final entry in levels.entries) {
      if (entry.value > 0) {
        await progression.setBenchBaseline(
          station: entry.key,
          level: entry.value,
        );
      }
    }
    await _confirm({
      'unbuiltBenchIds': [
        for (final e in levels.entries)
          if (e.value == 0) ArcProgressionEngine.benchIdFor(e.key),
      ],
    });
  }

  Future<void> confirmNoBlueprints() async {
    if ((await _blueprints.loadMyBlueprintStates()).values.any(
      (state) => state.owned,
    )) {
      throw StateError('Owned Blueprints already form your baseline.');
    }
    await _confirm({'noBlueprintsConfirmed': true});
  }

  Future<void> deferLoadout() async {
    await _confirm({'loadoutDeferred': true});
  }

  Future<void> confirmFlexibleAvailability() async {
    final current = await profile.getAvailability();
    await profile.saveAvailability(
      ArcAvailability(
        scheduleType: 'flexible',
        useEveryWeek: current.useEveryWeek,
        weeks: current.weeks,
      ),
    );
  }

  Future<void> complete() async {
    if (!(await load()).status.ready) {
      throw StateError('Complete the remaining setup sections first.');
    }
    await _confirm({
      'version': ArcRaiderSetupEvaluator.version,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }
}
