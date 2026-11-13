import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_control_config.dart';

void main() {
  group('ArcAdminControlConfig', () {
    test('defaults keep core ARC features enabled and rollout at 100%', () {
      final config = ArcAdminControlConfig.defaults();

      expect(config.isFeatureEnabled('raidIntelligence'), isTrue);
      expect(config.isFeatureEnabled('officialMapConditions'), isTrue);
      expect(config.isFeatureEnabled('communityIntel'), isTrue);
      expect(config.isMapEnabled('Blue Gate'), isTrue);
      expect(config.rolloutPercent, 100);
      expect(config.isMaintenanceMode, isFalse);
      expect(config.isReadOnlyMode, isFalse);
      expect(config.isBetaOnlyMode, isFalse);
    });

    test('per-feature and per-map overrides can disable functionality', () {
      final config = const ArcAdminControlConfig(
        featureFlags: {'raidIntelligence': false, 'operations': false},
        mapFlags: {'Blue Gate': false, 'Riven Tides': true},
        rolloutPercent: 35,
      );

      expect(config.isFeatureEnabled('raidIntelligence'), isFalse);
      expect(config.isFeatureEnabled('operations'), isFalse);
      expect(config.isFeatureEnabled('communityIntel'), isTrue);
      expect(config.isMapEnabled('Blue Gate'), isFalse);
      expect(config.isMapEnabled('Riven Tides'), isTrue);
      expect(config.rolloutPercent, 35);
    });
  });
}
