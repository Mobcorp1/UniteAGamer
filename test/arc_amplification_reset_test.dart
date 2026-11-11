import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/amplification/arc_amplification_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/amplification/arc_amplification_state.dart';

void main() {
  test('reset selected removes only targeted research progress and keeps stock', () {
    final projects = ArcAmplificationCatalog.projects.take(2).toList();
    final before = const ArcAmplificationState(researchPoints: 455, materials: {'Tick Pod': 7})
        .confirmStepOneInGame(projects.first.id)
        .confirmResearchCompletedInGame(projects.first.id)
        .confirmStepOneInGame(projects.last.id);
    final after = before.resetProject(projects.first.id);
    expect(after.completed, isNot(contains(projects.first.id)));
    expect(after.objectives.containsKey(projects.first.id), isFalse);
    expect(after.active, contains(projects.last.id));
    expect(after.objectivesDone(projects.last.id), isTrue);
    expect(after.researchPoints, 455);
    expect(after.materials['Tick Pod'], 7);
  });

  test('reset all clears stages but preserves shared Research Points and materials', () {
    final project = ArcAmplificationCatalog.projects.first;
    final before = const ArcAmplificationState(researchPoints: 55, materials: {'Tick Pod': 8})
        .confirmStepOneInGame(project.id)
        .confirmResearchCompletedInGame(project.id);
    final after = before.resetAllProjects();
    expect(after.active, isEmpty);
    expect(after.completed, isEmpty);
    expect(after.objectives, isEmpty);
    expect(after.installedPerks, isEmpty);
    expect(after.materials, before.materials);
    expect(after.researchPoints, 55);
  });
}
