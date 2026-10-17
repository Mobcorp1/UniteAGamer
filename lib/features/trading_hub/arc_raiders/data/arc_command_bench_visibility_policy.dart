import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_bench_upgrade_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';

/// Show unfinished benches in Command Centre; preserve completed progression
/// records and full station access inside Bench Tracker.
/// Unknown/stale data is shown, never silently interpreted as a completed bench.
class ArcCommandBenchVisibilityPolicy {
  const ArcCommandBenchVisibilityPolicy._();

  static bool showInCommandCentre(ArcCommandSnapshotMetric metric) {
    if (!metric.label.startsWith('Bench: ')) return false;
    final station = metric.label.substring('Bench: '.length).trim();
    final levels = ArcBenchUpgradeSeedData.levelsForStation(station);
    if (levels.isEmpty) return true;
    final match = RegExp(r'^Lv\.(\d+)$').firstMatch(metric.value.trim());
    if (match == null) return true;
    final currentLevel = int.tryParse(match.group(1)!);
    if (currentLevel == null) return true;
    return currentLevel < levels.last;
  }
}
