import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  test('route metrics expose a stable empty state', () {
    expect(ArcRaidRouteMetrics.empty.hasData, isFalse);
    const metrics = ArcRaidRouteMetrics(
      totalDistance: 12.5,
      estimatedMinutes: 18,
      opportunityCount: 3,
      blueprintTargetCount: 4,
      averageConfidence: 78,
      efficiencyScore: 86,
      riskLabel: 'Compact route',
    );
    expect(metrics.hasData, isTrue);
    expect(metrics.blueprintTargetCount, 4);
    expect(metrics.riskLabel, 'Compact route');
  });
}
