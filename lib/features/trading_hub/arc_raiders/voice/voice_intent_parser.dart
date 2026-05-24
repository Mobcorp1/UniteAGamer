import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_item_advice_index.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_voice_item_database.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/unified_item_index.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/voice/voice_intent.dart';

class UagVoiceIntentParser {
  const UagVoiceIntentParser();

  UagVoiceIntent parse(String text) {
    final raw = text.trim();
    final normalized = UnifiedItemIndex.normalize(_normaliseSpeech(raw));

    if (normalized.isEmpty) {
      return UagVoiceIntent(type: UagVoiceIntentType.unknown, rawText: raw);
    }

    final itemQuery = _extractItem(raw);

    if (_containsAny(normalized, const [
      'hunt',
      'hunts',
      'hunt target',
      'hunt targets',
      'what should i hunt',
      'what am i hunting',
      'rarest missing',
      'priority target',
      'top five',
      'top 5',
    ])) {
      return UagVoiceIntent(
        type: UagVoiceIntentType.blueprintSearch,
        rawText: raw,
        itemQuery: itemQuery,
      );
    }

    if (_containsAny(normalized, const [
      'intel',
      'report',
      'create intel',
      'log intel',
      'add intel',
      'where find',
      'where to find',
      'best map',
      'best condition',
      'dupe blueprint',
      'duplicate blueprint',
    ])) {
      return UagVoiceIntent(
        type: UagVoiceIntentType.blueprintSearch,
        rawText: raw,
        itemQuery: itemQuery,
      );
    }

    if (_containsAny(normalized, const [
      'trade',
      'swap',
      'offer',
      'offering',
      'looking for',
      'who wants',
      'anyone need',
      'dupe',
      'duplicate',
      'spare',
      'extra copy',
      'market',
      'marketplace',
    ])) {
      return UagVoiceIntent(
        type: UagVoiceIntentType.tradeCheck,
        rawText: raw,
        itemQuery: itemQuery,
      );
    }

    if (_containsAny(normalized, const [
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

    if (_containsAny(normalized, const [
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

    return UagVoiceIntent(
      type: UagVoiceIntentType.needCheck,
      rawText: raw,
      itemQuery: itemQuery,
    );
  }

  bool _containsAny(String normalized, List<String> phrases) {
    return phrases.any(
      (phrase) => normalized.contains(UnifiedItemIndex.normalize(phrase)),
    );
  }

  String? _extractItem(String raw) {
    final normalisedRaw = _normaliseSpeech(raw);

    final directDatabaseMatch = ArcVoiceItemDatabase.findBest(normalisedRaw);
    final directAdviceMatches = ArcItemAdviceIndex.search(normalisedRaw);

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

    var cleaned = normalisedRaw.toLowerCase();

    const phrases = [
      'do i need',
      'do we need',
      'do i own',
      'do we own',
      'have i got',
      'have we got',
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
      'where find',
      'where to find',
      'what should i hunt',
      'what am i hunting',
      'hunt target',
      'hunt targets',
      'create intel on',
      'create intel for',
      'add intel on',
      'add intel for',
      'log intel on',
      'log intel for',
      'intel on',
      'intel for',
      'report',
      'dupe blueprint',
      'duplicate blueprint',
      'dupe',
      'duplicate',
      'spare',
      'extra copy',
      'find',
      'uag raider',
      'hey uag raider',
      'okay uag raider',
      'ok uag raider',
      'arc assistant',
      'hey arc',
      'ok arc',
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

    return cleaned.isEmpty ? normalisedRaw.trim() : cleaned;
  }

  String _normaliseSpeech(String text) {
    var value = text.trim();

    value = value.replaceAll(RegExp(r'\bark\b', caseSensitive: false), 'ARC');
    value = value.replaceAll(
      RegExp(r'\bequaliser\b', caseSensitive: false),
      'Equalizer',
    );
    value = value.replaceAll(
      RegExp(r'\bdalabra\b', caseSensitive: false),
      'Dolabra',
    );
    value = value.replaceAll(
      RegExp(r'\bdoll abra\b', caseSensitive: false),
      'Dolabra',
    );
    value = value.replaceAll(
      RegExp(r'\bdoh labra\b', caseSensitive: false),
      'Dolabra',
    );
    value = value.replaceAll(
      RegExp(r'\banvil blue print\b', caseSensitive: false),
      'Anvil blueprint',
    );
    value = value.replaceAll(
      RegExp(r'\bblue print\b', caseSensitive: false),
      'blueprint',
    );

    return value;
  }
}
