import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/unified_item_index.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/voice/voice_intent.dart';

class UagVoiceResponse {
  const UagVoiceResponse({required this.title, required this.body, required this.shouldSpeak});
  final String title;
  final String body;
  final bool shouldSpeak;
}

class UagVoiceResponseBuilder {
  const UagVoiceResponseBuilder();
  UagVoiceResponse build(UagVoiceIntent intent) {
    final query = intent.itemQuery ?? intent.rawText;
    final item = UnifiedItemIndex.findBest(query);
    if (item == null) {
      return const UagVoiceResponse(title: 'No item match found', body: 'I could not match that to a tracked ARC Raiders item yet.', shouldSpeak: true);
    }
    final usedIn = item.usedIn.isEmpty ? 'No tracker usage found yet.' : item.usedIn.join(', ');
    final keepLevel = item.neededForBench || item.neededForQuest || item.neededForScrappy ? 'KEEP' : item.tradeRelevant ? 'TRADE RELEVANT' : 'CHECK MANUALLY';
    final body = '${item.name}: $keepLevel. Used in: $usedIn.';
    return UagVoiceResponse(title: item.name, body: body, shouldSpeak: true);
  }
}
