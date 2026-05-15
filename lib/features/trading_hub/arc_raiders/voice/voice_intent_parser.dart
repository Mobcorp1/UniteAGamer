import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/unified_item_index.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/voice/voice_intent.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/voice/voice_pronunciation.dart';

class UagVoiceIntentParser {
  const UagVoiceIntentParser();

  UagVoiceIntent parse(String text) {
    final raw = text.trim();
    final pronunciationCleaned = UagVoicePronunciation.normaliseForLookup(raw);
    final normalized = UnifiedItemIndex.normalize(pronunciationCleaned);
    if (normalized.isEmpty) {
      return UagVoiceIntent(type: UagVoiceIntentType.unknown, rawText: raw);
    }

    if (normalized.contains('what can i trade') ||
        normalized.contains('safe to trade') ||
        normalized.contains('can i trade') ||
        normalized.contains('who wants') ||
        normalized.contains('looking for')) {
      return UagVoiceIntent(
        type: UagVoiceIntentType.tradeCheck,
        rawText: raw,
        itemQuery: _extractItem(pronunciationCleaned),
      );
    }
    if (normalized.contains('bench') || normalized.contains('craft') || normalized.contains('upgrade')) {
      return UagVoiceIntent(
        type: UagVoiceIntentType.benchLookup,
        rawText: raw,
        itemQuery: _extractItem(pronunciationCleaned),
      );
    }
    if (normalized.contains('quest') || normalized.contains('mission')) {
      return UagVoiceIntent(
        type: UagVoiceIntentType.questLookup,
        rawText: raw,
        itemQuery: _extractItem(pronunciationCleaned),
      );
    }
    if (normalized.contains('keep') ||
        normalized.contains('need') ||
        normalized.contains('sell') ||
        normalized.contains('recycle') ||
        normalized.contains('stash')) {
      return UagVoiceIntent(
        type: UagVoiceIntentType.needCheck,
        rawText: raw,
        itemQuery: _extractItem(pronunciationCleaned),
      );
    }
    return UagVoiceIntent(
      type: UagVoiceIntentType.needCheck,
      rawText: raw,
      itemQuery: _extractItem(pronunciationCleaned),
    );
  }

  String? _extractItem(String raw) {
    var cleaned = UagVoicePronunciation.normaliseForLookup(raw).toLowerCase();
    const phrases = <String>[
      'do i need',
      'do we need',
      'should i keep',
      'can i trade',
      'what can i trade',
      'who wants',
      'is anyone looking for',
      'anyone looking for',
      'is this needed',
      'is it needed',
      'can i sell',
      'should i sell',
      'can i recycle',
      'should i recycle',
      'for bench',
      'for benches',
      'for quest',
      'for quests',
      'for crafting',
      'for upgrades',
      'uag raider',
      'hey uag raider',
      'raider',
      'blueprint',
    ];
    for (final phrase in phrases) {
      cleaned = cleaned.replaceAll(phrase, ' ');
    }
    cleaned = cleaned
        .replaceAll('?', ' ')
        .replaceAll('.', ' ')
        .replaceAll(',', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleaned.isEmpty) return null;

    final exact = UnifiedItemIndex.findBest(cleaned);
    if (exact != null) return exact.name;

    final blueprintFallback = UnifiedItemIndex.findBest('$cleaned blueprint');
    if (blueprintFallback != null) return blueprintFallback.name;

    return cleaned;
  }
}
