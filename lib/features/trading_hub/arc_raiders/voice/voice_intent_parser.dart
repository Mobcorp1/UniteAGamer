import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/unified_item_index.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/voice/voice_intent.dart';

class UagVoiceIntentParser {
  const UagVoiceIntentParser();

  UagVoiceIntent parse(String text) {
    final raw = text.trim();
    final normalized = UnifiedItemIndex.normalize(raw);
    if (normalized.isEmpty) {
      return UagVoiceIntent(type: UagVoiceIntentType.unknown, rawText: raw);
    }

    if (normalized.contains('what can i trade') ||
        normalized.contains('safe to trade') ||
        normalized.contains('can i trade')) {
      return UagVoiceIntent(type: UagVoiceIntentType.tradeCheck, rawText: raw, itemQuery: _extractItem(raw));
    }
    if (normalized.contains('bench')) {
      return UagVoiceIntent(type: UagVoiceIntentType.benchLookup, rawText: raw, itemQuery: _extractItem(raw));
    }
    if (normalized.contains('quest')) {
      return UagVoiceIntent(type: UagVoiceIntentType.questLookup, rawText: raw, itemQuery: _extractItem(raw));
    }
    if (normalized.contains('keep') || normalized.contains('need')) {
      return UagVoiceIntent(type: UagVoiceIntentType.needCheck, rawText: raw, itemQuery: _extractItem(raw));
    }
    return UagVoiceIntent(type: UagVoiceIntentType.needCheck, rawText: raw, itemQuery: _extractItem(raw));
  }

  String? _extractItem(String raw) {
    var cleaned = raw.toLowerCase();
    const phrases = <String>['do i need','do we need','should i keep','can i trade','what can i trade','is this needed','is it needed','for bench','for quest','uag raider','hey uag raider'];
    for (final phrase in phrases) { cleaned = cleaned.replaceAll(phrase, ' '); }
    cleaned = cleaned.replaceAll('?', ' ').trim();
    return cleaned.isEmpty ? null : cleaned;
  }
}
