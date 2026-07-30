import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/feature_access_gate.dart';

void main() {
  group('FeatureAvailability', () {
    test('parses explicit beta sandbox states before legacy booleans', () {
      final data = <String, dynamic>{
        'raidPlannerEnabled': false,
        'raidPlannerAvailability': 'comingSoon',
        'traderHubEnabled': true,
        'voiceAssistantAvailability': 'hidden',
      };

      expect(
        FeatureAccess.availabilityFromConfigData(data, 'raidPlannerEnabled'),
        FeatureAvailability.comingSoon,
      );
      expect(
        FeatureAccess.availabilityFromConfigData(data, 'traderHubEnabled'),
        FeatureAvailability.live,
      );
      expect(
        FeatureAccess.availabilityFromConfigData(data, 'voiceAssistantEnabled'),
        FeatureAvailability.hidden,
      );
    });

    test('writes legacy compatibility and availability fields together', () {
      final payload = FeatureAccess.updatePayloadForAvailability(
        globalField: 'smartTradeAssistEnabled',
        availability: FeatureAvailability.comingSoon,
      );

      expect(payload['smartTradeAssistEnabled'], isFalse);
      expect(payload['smartTradeAssistAvailability'], 'comingSoon');
      expect(payload, contains('updatedAt'));
    });

    test('detects deduped Coming Soon to Live notification transitions', () {
      expect(
        FeatureAccess.shouldNotifyComingSoonToLive(
          previous: FeatureAvailability.comingSoon,
          next: FeatureAvailability.live,
        ),
        isTrue,
      );
      expect(
        FeatureAccess.shouldNotifyComingSoonToLive(
          previous: FeatureAvailability.hidden,
          next: FeatureAvailability.live,
        ),
        isFalse,
      );
      expect(
        FeatureAccess.featureLiveNotificationKey(
          uid: 'user-1',
          flag: FeatureAccessFlag.intelExplorer,
        ),
        'user-1_canAccessIntelExplorer_feature_live',
      );
    });
  });
}
