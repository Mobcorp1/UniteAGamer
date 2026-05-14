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

    if (_containsAny(normalized, const <String>[
      'what can i trade',
      'safe to trade',
      'can i trade',
      'should i trade',
      'trade this',
      'trade it',
    ])) {
      return UagVoiceIntent(type: UagVoiceIntentType.tradeCheck, rawText: raw, itemQuery: _extractItem(raw));
    }

    if (_containsAny(normalized, const <String>[
      'bench',
      'upgrade',
      'workshop',
      'gunsmith',
      'gear bench',
      'medical lab',
    ])) {
      return UagVoiceIntent(type: UagVoiceIntentType.benchLookup, rawText: raw, itemQuery: _extractItem(raw));
    }

    if (_containsAny(normalized, const <String>[
      'quest',
      'mission',
      'project',
      'expedition',
    ])) {
      return UagVoiceIntent(type: UagVoiceIntentType.questLookup, rawText: raw, itemQuery: _extractItem(raw));
    }

    if (_containsAny(normalized, const <String>[
      'sell',
      'recycle',
      'salvage',
      'keep',
      'need',
      'consume',
      'learn',
      'blueprint',
      'found',
      'what about',
    ])) {
      return UagVoiceIntent(type: UagVoiceIntentType.needCheck, rawText: raw, itemQuery: _extractItem(raw));
    }

    return UagVoiceIntent(type: UagVoiceIntentType.needCheck, rawText: raw, itemQuery: _extractItem(raw));
  }

  bool _containsAny(String normalized, List<String> phrases) {
    return phrases.any((phrase) => normalized.contains(UnifiedItemIndex.normalize(phrase)));
  }

  String? _extractItem(String raw) {
    var cleaned = raw.toLowerCase();
    const phrases = <String>[
      'hey uag raider',
      'uag raider',
      'hey raider',
      'raider',
      'do i need',
      'do we need',
      'should i keep',
      'should we keep',
      'can i trade',
      'can we trade',
      'what can i trade',
      'safe to trade',
      'should i trade',
      'is this needed',
      'is it needed',
      'for bench',
      'for quest',
      'for mission',
      'for project',
      'for scrappy',
      'should i sell',
      'can i sell',
      'sell this',
      'sell it',
      'should i recycle',
      'can i recycle',
      'recycle this',
      'recycle it',
      'should i salvage',
      'can i salvage',
      'consume it',
      'learn it',
      'i found',
      'found a',
      'found an',
      'found some',
      'what about',
      'please',
    ];
    for (final phrase in phrases) {
      cleaned = cleaned.replaceAll(phrase, ' ');
    }
    cleaned = cleaned.replaceAll(RegExp(r'[?!.:,;]+'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.isEmpty ? null : cleaned;
  }
}
