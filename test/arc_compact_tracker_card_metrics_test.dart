import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_compact_tracker_card_metrics.dart';

void main() {
  group('ArcCompactTrackerCardMetrics', () {
    test('single item cards are shorter than multi-item cards', () {
      final single = ArcCompactTrackerCardMetrics.centreHeight(
        stageWidth: 390,
        maxItemCount: 1,
      );
      final two = ArcCompactTrackerCardMetrics.centreHeight(
        stageWidth: 390,
        maxItemCount: 2,
      );
      final many = ArcCompactTrackerCardMetrics.centreHeight(
        stageWidth: 390,
        maxItemCount: 5,
      );

      expect(single, lessThan(two));
      expect(two, lessThan(many));
    });

    test('zero item card state is safe', () {
      expect(
        ArcCompactTrackerCardMetrics.centreHeight(
          stageWidth: 390,
          maxItemCount: 0,
        ),
        172,
      );
    });
  });
}
