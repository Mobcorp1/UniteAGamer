import '../models/arc_availability.dart';
import '../models/arc_progression_models.dart';
import 'arc_profile_completion_evaluator.dart';
import 'arc_progression_engine.dart';
import 'arc_quest_catalogue.dart';

enum ArcRaiderSetupSection {
  profile('Profile'),
  availability('Availability'),
  quests('Quest Position'),
  blueprints('Blueprints'),
  scrappy('Scrappy'),
  benches('Bench'),
  loadout('Loadout');

  const ArcRaiderSetupSection(this.label);
  final String label;
}

class ArcRaiderSetupStatus {
  const ArcRaiderSetupStatus({
    required this.completed,
    required this.version,
    this.preview = false,
  });
  final Set<ArcRaiderSetupSection> completed;
  final int version;
  final bool preview;
  List<ArcRaiderSetupSection> get missing => ArcRaiderSetupSection.values
      .where((section) => !completed.contains(section))
      .toList(growable: false);
  bool get ready => missing.isEmpty;
  bool get needsSetup =>
      !preview && (!ready || version < ArcRaiderSetupEvaluator.version);
}

/// Completion is derived from authoritative state, not document existence.
/// Metadata only records deliberate empty/default answers and version acceptance.
class ArcRaiderSetupEvaluator {
  const ArcRaiderSetupEvaluator();
  static const version = 1;
  static Map<String, dynamic> map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  ArcRaiderSetupStatus evaluate({
    Map<String, dynamic> userData = const {},
    Map<String, dynamic> profileData = const {},
    Map<String, dynamic> availabilityData = const {},
    ArcProgressionRecords progression = ArcProgressionRecords.empty,
    bool hasOwnedBlueprints = false,
    bool hasConfiguredLoadout = false,
  }) {
    final metadata = map(userData['arcRaiderSetup']);
    final confirmation =
        metadata['confirmationVersion'] == version &&
            metadata['seasonId'] == progression.seasonId
        ? metadata
        : <String, dynamic>{};
    final profile = const ArcProfileCompletionEvaluator().evaluate(
      userData: userData,
      profileData: profileData,
    );
    final availability = ArcAvailability.fromMap(availabilityData);
    final validSchedule = availability.weeks.any(
      (week) => week.slots.any(
        (slot) =>
            slot.enabled &&
            const {
              'mon',
              'tue',
              'wed',
              'thu',
              'fri',
              'sat',
              'sun',
            }.contains(slot.dayKey) &&
            _validTime(slot.fromTime) &&
            _validTime(slot.toTime) &&
            slot.fromTime != slot.toTime,
      ),
    );
    final flexibleConfirmed =
        availability.scheduleType == 'flexible' &&
        (availabilityData['completed'] == true ||
            availabilityData['availabilityCompleted'] == true);
    final quests =
        progression.trackedQuestIds.any(ArcQuestCatalogue.byId.containsKey) ||
        ArcQuestCatalogue.nodes.every(
          (quest) => progression.questRecords[quest.id]?.completed == true,
        );
    final engine = const ArcProgressionEngine();
    final scrappyLevel = progression.scrappyState.currentLevel;
    final scrappy =
        (scrappyLevel > 1 &&
            engine.scrappyDefinitions.any((d) => d.level == scrappyLevel)) ||
        (scrappyLevel == 1 && confirmation['scrappyStartingConfirmed'] == true);
    final zeroBenches = (confirmation['unbuiltBenchIds'] as List? ?? const [])
        .toSet();
    final stations = engine.benchDefinitions.map((d) => d.station).toSet();
    final benches = stations.every((station) {
      final id = ArcProgressionEngine.benchIdFor(station);
      final record = progression.benchRecords[id];
      final level = record?.currentLevel ?? 0;
      return (record?.seasonId == progression.seasonId &&
              engine.benchDefinitions.any(
                (d) => d.station == station && d.level == level,
              )) ||
          (level == 0 && zeroBenches.contains(id));
    });
    return ArcRaiderSetupStatus(
      version: (metadata['version'] as num?)?.toInt() ?? 0,
      preview: false,
      completed: {
        if (profile.identityComplete) ArcRaiderSetupSection.profile,
        if (validSchedule || flexibleConfirmed)
          ArcRaiderSetupSection.availability,
        if (quests || confirmation['noActiveQuestsConfirmed'] == true)
          ArcRaiderSetupSection.quests,
        if (hasOwnedBlueprints || confirmation['noBlueprintsConfirmed'] == true)
          ArcRaiderSetupSection.blueprints,
        if (scrappy) ArcRaiderSetupSection.scrappy,
        if (benches) ArcRaiderSetupSection.benches,
        if (hasConfiguredLoadout || metadata['loadoutDeferred'] == true)
          ArcRaiderSetupSection.loadout,
      },
    );
  }

  static bool _validTime(String time) =>
      RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').hasMatch(time);
}
