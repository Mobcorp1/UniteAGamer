import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_personal_item_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/voice/voice_intent.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/voice/voice_intent_parser.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/voice/voice_response_builder.dart';

void main() {
  group('UAG voice companion intents', () {
    const parser = UagVoiceIntentParser();

    test('recognises wake phrase without live app context', () {
      final intent = parser.parse('Hey Raider');

      expect(intent.type, UagVoiceIntentType.wakePhrase);
      expect(intent.needsLiveAppContext, isFalse);
    });

    test('strips wake phrase before parsing operational commands', () {
      final intent = parser.parse('Hey Raider read notifications');

      expect(intent.type, UagVoiceIntentType.readNotifications);
      expect(intent.needsLiveAppContext, isTrue);
    });

    test('recognises blueprint, cache and route reporting commands', () {
      expect(
        parser.parse('report blueprint Anvil').type,
        UagVoiceIntentType.reportBlueprint,
      );
      expect(
        parser.parse('log weapon cache near Data Vault').type,
        UagVoiceIntentType.reportWeaponCache,
      );
      expect(
        parser.parse('add waypoint to route').type,
        UagVoiceIntentType.addLocationToRoute,
      );
    });

    test('recognises trust, confirm and cancel commands', () {
      expect(
        parser.parse('is this trader safe').type,
        UagVoiceIntentType.conductRiskCheck,
      );
      expect(parser.parse('confirm').type, UagVoiceIntentType.confirm);
      expect(parser.parse('cancel').type, UagVoiceIntentType.cancel);
    });

    test('voice response uses personal item inventory protection context', () {
      final response = const UagVoiceResponseBuilder().build(
        const UagVoiceIntent(
          type: UagVoiceIntentType.keepCheck,
          rawText: 'Should I recycle Broken Flashlight?',
          itemQuery: 'Broken Flashlight',
        ),
        personalInventory: const ArcPersonalItemInventorySnapshot(
          ownedQuantities: {'broken-flashlight': 2},
          protectionOverrides: {
            'broken-flashlight': ArcPersonalItemProtectionOverride(
              userId: 'user-1',
              itemId: 'broken-flashlight',
              protections: {ArcPersonalItemProtectionType.neverRecycle},
              customMinimumQuantity: 2,
            ),
          },
        ),
      );

      expect(response.shouldSpeak, isTrue);
      expect(response.spokenBody, contains('Reserve'));
      expect(response.body, contains('User protection'));
    });
  });
}
