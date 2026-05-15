import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_item_advice_index.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_voice_item_database.dart';
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

    final itemQuery = _extractItem(raw);

    if (_containsAny(normalized, const <String>[
      'trade',
      'swap',
      'offer',
      'offering',
      'looking for',
      'who wants',
      'anyone need',
    ])) {
      return UagVoiceIntent(
        type: UagVoiceIntentType.tradeCheck,
        rawText: raw,
        itemQuery: itemQuery,
      );
    }

    if (_containsAny(normalized, const <String>[
      'bench',
      'upgrade',
      'workbench',
      'crafting bench',
    ])) {
      return UagVoiceIntent(
        type: UagVoiceIntentType.benchLookup,
        rawText: raw,
        itemQuery: itemQuery,
      );
    }

    if (_containsAny(normalized, const <String>[
      'quest',
      'mission',
      'objective',
      'task',
    ])) {
      return UagVoiceIntent(
        type: UagVoiceIntentType.questLookup,
        rawText: raw,
        itemQuery: itemQuery,
      );
    }

    if (_containsAny(normalized, const <String>[
      'keep',
      'need',
      'needed',
      'sell',
      'recycle',
      'worth',
      'valuable',
      'consume',
      'learn',
      'blueprint',
      'scrappy',
    ])) {
      return UagVoiceIntent(
        type: UagVoiceIntentType.needCheck,
        rawText: raw,
        itemQuery: itemQuery,
      );
    }

    return UagVoiceIntent(
      type: UagVoiceIntentType.needCheck,
      rawText: raw,
      itemQuery: itemQuery,
    );
  }

  bool _containsAny(String normalized, List<String> phrases) {
    return phrases.any((phrase) => normalized.contains(UnifiedItemIndex.normalize(phrase)));
  }

  String? _extractItem(String raw) {
    final directDatabaseMatch = ArcVoiceItemDatabase.findBest(raw);
    final directAdviceMatches = ArcItemAdviceIndex.search(raw);

    var bestName = directDatabaseMatch?.item.name;
    if (directAdviceMatches.isNotEmpty) {
      final indexedName = directAdviceMatches.first.name;
      if (bestName == null || indexedName.length >= bestName.length) {
        bestName = indexedName;
      }
    }
    if (bestName != null && bestName.trim().isNotEmpty) {
      return bestName.trim();
    }

    var cleaned = raw.toLowerCase();
    const phrases = <String>[
      'do i need',
      'do we need',
      'should i keep',
      'should we keep',
      'can i trade',
      'what can i trade',
      'is this needed',
      'is it needed',
      'do i sell',
      'should i sell',
      'do i recycle',
      'should i recycle',
      'for bench',
      'for quest',
      'for scrappy',
      'check item',
      'look up',
      'search for',
      'find',
      'uag raider',
      'hey uag raider',
      'okay uag raider',
      'ok uag raider',
      'raider',
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

    return cleaned.isEmpty ? raw.trim() : cleaned;
  }
}
