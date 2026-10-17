import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_bench_upgrade_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_bench_artwork.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_command_bench_visibility_policy.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart';

void main() {
  ArcCommandSnapshotMetric bench(String name, String level, String detail) {
    return ArcCommandSnapshotMetric(
      label: 'Bench: $name',
      value: level,
      detail: detail,
      status: ArcCommandStatus.neutral,
    );
  }

  test('Research Station has four material-tracked levels and its own art', () {
    expect(ArcBenchUpgradeSeedData.levelsForStation('Research Station'), [
      1,
      2,
      3,
      4,
    ]);
    expect(
      ArcBenchArtwork.forStation('Research Station'),
      'assets/arc_raiders/hub/benches/research_station.webp',
    );
    final items = ArcBenchUpgradeSeedData.requirements
        .where((r) => r.station == 'Research Station')
        .toList();
    expect(items.length, 12);
    expect(items.where((r) => r.level == 1).map((r) => r.quantity).toList(), [
      35,
      5,
      3,
    ]);
    expect(items.where((r) => r.level == 4).map((r) => r.quantity).toList(), [
      3,
      3,
      1,
    ]);
  });

  test('Gunsmith reaches level four, not obsolete level three cap', () {
    expect(ArcBenchUpgradeSeedData.levelsForStation('Gunsmith'), [1, 2, 3, 4]);
    final upgrade = ArcBenchUpgradeSeedData.requirements
        .where((r) => r.station == 'Gunsmith' && r.level == 4)
        .toList();
    expect(upgrade.map((r) => r.quantity).toList(), [3, 3, 1]);
    expect(
      ArcCommandBenchVisibilityPolicy.showInCommandCentre(
        bench('Gunsmith', 'Lv.3', 'NEXT Lv.4'),
      ),
      isTrue,
    );
    expect(
      ArcCommandBenchVisibilityPolicy.showInCommandCentre(
        bench('Gunsmith', 'Lv.4', 'MAX'),
      ),
      isFalse,
    );
  });

  test(
    'only true max-level benches disappear; unknown levels stay visible',
    () {
      expect(
        ArcCommandBenchVisibilityPolicy.showInCommandCentre(
          bench('Research Station', 'Lv.0', 'NEXT Lv.1'),
        ),
        isTrue,
      );
      expect(
        ArcCommandBenchVisibilityPolicy.showInCommandCentre(
          bench('Research Station', 'Lv.3', 'NEXT Lv.4'),
        ),
        isTrue,
      );
      expect(
        ArcCommandBenchVisibilityPolicy.showInCommandCentre(
          bench('Research Station', 'Lv.4', 'MAX'),
        ),
        isFalse,
      );
      expect(
        ArcCommandBenchVisibilityPolicy.showInCommandCentre(
          bench('Medical Lab', 'Lv.3', 'MAX'),
        ),
        isFalse,
      );
      expect(
        ArcCommandBenchVisibilityPolicy.showInCommandCentre(
          bench('Unknown Station', 'Lv.5', 'MAX'),
        ),
        isTrue,
      );
      expect(
        ArcCommandBenchVisibilityPolicy.showInCommandCentre(
          bench('Research Station', 'Not loaded', 'MAX'),
        ),
        isTrue,
      );
    },
  );

  test('Bench Tracker can open with Research Station already selected', () {
    const screen = ScrappyGridScreen.bench(
      initialBenchCategory: 'Research Station',
    );
    expect(screen.initialMode, ArcScrappyTrackerMode.bench);
    expect(screen.initialBenchCategory, 'Research Station');
  });
}
