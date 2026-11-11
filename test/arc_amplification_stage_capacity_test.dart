import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/amplification/arc_amplification_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/amplification/arc_amplification_state.dart';

void main() {
  final ids = ArcAmplificationCatalog.projects.map((p) => p.id).toList();

  test('five Step 1 projects block a sixth until one advances', () {
    var state = ArcAmplificationState.empty;
    for (final id in ids.take(5)) {
      state = state.start(id);
    }
    expect(state.stepOneActiveCount, 5);
    expect(state.stepTwoActiveCount, 0);
    expect(state.canStartMore, isFalse);
    expect(() => state.start(ids[5]), throwsStateError);
    state = state.confirmStepOneInGame(ids.first);
    expect(state.stepOneActiveCount, 4);
    expect(state.stepTwoActiveCount, 1);
    expect(state.canStartMore, isTrue);
    state = state.start(ids[5]);
    expect(state.active.length, 6);
    expect(state.stepOneActiveCount, 5);
    expect(state.stepTwoActiveCount, 1);
  });

  test('Stage 2 does not consume Stage 1 slots, across save/load', () {
    var state = ArcAmplificationState.empty;
    for (final id in ids.take(5)) {
      state = state.start(id).confirmStepOneInGame(id);
    }
    expect(state.stepOneActiveCount, 0);
    expect(state.stepTwoActiveCount, 5);
    for (final id in ids.skip(5).take(5)) {
      state = state.start(id);
    }
    expect(state.active.length, 10);
    final restored = ArcAmplificationState.fromMap(state.toMap());
    expect(restored.active.length, 10);
    expect(restored.stepOneActiveCount, 5);
    expect(restored.stepTwoActiveCount, 5);
    expect(restored.canStartMore, isFalse);
  });

  test('completing or resetting an active Stage 1 project frees capacity', () {
    var state = ArcAmplificationState.empty;
    for (final id in ids.take(5)) {
      state = state.start(id);
    }
    state = state.resetProject(ids.first);
    expect(state.canStartMore, isTrue);
    expect(state.stepOneActiveCount, 4);
    state = state.start(ids[5]).confirmResearchCompletedInGame(ids[5]);
    expect(state.stepOneActiveCount, 4);
    expect(state.completed, contains(ids[5]));
    expect(state.canStartMore, isTrue);
  });
}
