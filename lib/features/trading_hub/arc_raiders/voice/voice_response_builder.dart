import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_item_advice_index.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_voice_item_database.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/unified_item_index.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/voice/voice_intent.dart';

class UagVoiceResponse {
  const UagVoiceResponse({
    required this.title,
    required this.body,
    required this.shouldSpeak,
    this.spokenBody,
    this.suggestedItemName,
    this.suggestionNames = const <String>[],
  });

  final String title;
  final String body;
  final bool shouldSpeak;
  final String? spokenBody;
  final String? suggestedItemName;
  final List<String> suggestionNames;

  bool get hasConfirmableSuggestion => suggestedItemName != null;
}

class UagVoiceResponseBuilder {
  const UagVoiceResponseBuilder();

  UagVoiceResponse build(
    UagVoiceIntent intent, {
    Map<String, ArcBlueprintState> blueprintStates = const <String, ArcBlueprintState>{},
  }) {
    final query = _resolveQuery(intent);

    if (query.trim().isEmpty) {
      return const UagVoiceResponse(
        title: 'Ask UAG Raider',
        body: 'Ask about an item, blueprint, Scrappy material, bench upgrade, quest item, or trade value.',
        shouldSpeak: true,
      );
    }

    final decision = ArcItemAdviceIndex.decide(
      query: _normaliseSpeechQuery(query),
      blueprintStates: blueprintStates,
    );

    if (decision != null) {
      final extra = _extraContext(decision.title);
      final body = extra.isEmpty ? decision.displayAdvice : '${decision.displayAdvice}\n\n$extra';

      return UagVoiceResponse(
        title: decision.title,
        body: body,
        spokenBody: decision.spokenAdvice,
        shouldSpeak: true,
      );
    }

    final suggestions = _suggestions(query).take(5).toList(growable: false);
    if (suggestions.isNotEmpty) {
      final first = suggestions.first;
      final names = suggestions.map((entry) => entry.name).join(', ');
      return UagVoiceResponse(
        title: 'Closest match',
        body: 'I could not lock that in confidently. Did you mean ${first.name}?\n\nOther close matches: $names.',
        spokenBody: 'I could not lock that in confidently. Did you mean ${first.name}? Say yes, or tap confirm, and I will open that item.',
        shouldSpeak: true,
        suggestedItemName: first.name,
        suggestionNames: suggestions.map((entry) => entry.name).toList(growable: false),
      );
    }

    return const UagVoiceResponse(
      title: 'No item match found',
      body: 'I could not match that to a tracked ARC Raiders item yet. Try the exact item name, blueprint name, or a shorter phrase.',
      spokenBody: 'I could not match that to a tracked ARC Raiders item yet. Try the exact item name, blueprint name, or a shorter phrase.',
      shouldSpeak: true,
    );
  }

  UagVoiceResponse buildConfirmedSuggestion(
    String itemName, {
    Map<String, ArcBlueprintState> blueprintStates = const <String, ArcBlueprintState>{},
  }) {
    return build(
      UagVoiceIntent(
        type: UagVoiceIntentType.needCheck,
        rawText: itemName,
        itemQuery: itemName,
      ),
      blueprintStates: blueprintStates,
    );
  }

  String _resolveQuery(UagVoiceIntent intent) {
    final query = intent.itemQuery?.trim();
    if (query != null && query.isNotEmpty) {
      return query;
    }
    return intent.rawText.trim();
  }

  String _normaliseSpeechQuery(String query) {
    var cleaned = query.trim();
    cleaned = cleaned.replaceAll(RegExp(r'\bARK\b', caseSensitive: false), 'ARC');
    cleaned = cleaned.replaceAll(RegExp(r'\bark\b', caseSensitive: false), 'ARC');
    cleaned = cleaned.replaceAll(RegExp(r'\bequaliser\b', caseSensitive: false), 'Equalizer');
    cleaned = cleaned.replaceAll(RegExp(r'\bdalabra\b', caseSensitive: false), 'Dolabra');
    cleaned = cleaned.replaceAll(RegExp(r'\bdoll abra\b', caseSensitive: false), 'Dolabra');
    cleaned = cleaned.replaceAll(RegExp(r'\bdoh labra\b', caseSensitive: false), 'Dolabra');
    return cleaned;
  }

  List<_Suggestion> _suggestions(String query) {
    final normalizedQuery = UnifiedItemIndex.normalize(_normaliseSpeechQuery(query));
    if (normalizedQuery.isEmpty) return const <_Suggestion>[];

    final suggestions = <_Suggestion>[];
    final seen = <String>{};

    for (final match in ArcVoiceItemDatabase.search(normalizedQuery).take(10)) {
      final key = UnifiedItemIndex.normalize(match.name);
      if (seen.add(key)) {
        suggestions.add(_Suggestion(name: match.name, score: _score(normalizedQuery, match.name)));
      }
    }

    for (final match in ArcItemAdviceIndex.search(normalizedQuery).take(10)) {
      final key = UnifiedItemIndex.normalize(match.name);
      if (seen.add(key)) {
        suggestions.add(_Suggestion(name: match.name, score: _score(normalizedQuery, match.name)));
      }
    }

    suggestions.sort((a, b) => b.score.compareTo(a.score));
    return suggestions;
  }

  int _score(String normalizedQuery, String candidateName) {
    final candidate = UnifiedItemIndex.normalize(candidateName);
    if (candidate == normalizedQuery) return 100;
    if (candidate.contains(normalizedQuery)) return 86;
    if (normalizedQuery.contains(candidate)) return 82;

    final qTokens = normalizedQuery.split(' ').where((token) => token.isNotEmpty).toSet();
    final cTokens = candidate.split(' ').where((token) => token.isNotEmpty).toSet();
    final overlap = qTokens.intersection(cTokens).length;
    if (overlap == 0) return 0;
    return 45 + (overlap * 10);
  }

  String _extraContext(String itemName) {
    final databaseMatch = ArcVoiceItemDatabase.findBest(itemName);
    final item = UnifiedItemIndex.findBest(itemName);

    final parts = <String>[];

    if (databaseMatch != null) {
      final record = databaseMatch.item;
      parts.add('Database: ${record.rarity} ${record.category}. Default action: ${record.actionLabel}.');
      if (record.usedToCraft.isNotEmpty) {
        parts.add('Crafting links: ${record.usedToCraft.take(8).join(', ')}.');
      }
    }

    if (item != null && item.usedIn.isNotEmpty) {
      parts.add('Tracked in: ${item.usedIn.join(', ')}.');
    }

    return parts.join('\n');
  }
}

class _Suggestion {
  const _Suggestion({required this.name, required this.score});

  final String name;
  final int score;
}
