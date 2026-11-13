import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/amplification/arc_amplification_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/amplification/arc_amplification_state.dart';

void main() {
  test('confirming step one advances to step two without inventing stock', () {
    final project = ArcAmplificationCatalog.projects.first;
    final before = const ArcAmplificationState(researchPoints: 125);
    final after = before.confirmStepOneInGame(project.id);
    expect(after.active, contains(project.id));
    expect(after.objectivesDone(project.id), isTrue);
    expect(after.materials, isEmpty);
    expect(after.researchPoints, 125);
    expect(after.completed, isEmpty);
  });

  test('completing confirmed in-game research preserves resource counts', () {
    final project = ArcAmplificationCatalog.projects.first;
    final before = const ArcAmplificationState(
      researchPoints: 200,
      materials: <String, int>{'Tick Pod': 3},
    ).confirmStepOneInGame(project.id);
    final after = before.confirmResearchCompletedInGame(project.id);
    expect(after.active, isNot(contains(project.id)));
    expect(after.completed, contains(project.id));
    expect(after.researchPoints, before.researchPoints);
    expect(after.materials, before.materials);
    expect(after.confirmResearchCompletedInGame(project.id).completed,
      contains(project.id));
  });
}
