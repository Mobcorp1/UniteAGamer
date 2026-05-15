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
  });

  final String title;
  final String body;
  final bool shouldSpeak;
  final String? spokenBody;
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
      query: query,
      blueprintStates: blueprintStates,
    );

    if (decision != null) {
      final extra = _extraContext(decision.title);
      final body = extra.isEmpty
          ? decision.displayAdvice
          : '${decision.displayAdvice}\n\n$extra';

      return UagVoiceResponse(
        title: decision.title,
        body: body,
        spokenBody: decision.spokenAdvice,
        shouldSpeak: true,
      );
    }

    final suggestions = ArcItemAdviceIndex.search(query).take(5).toList(growable: false);
    if (suggestions.isNotEmpty) {
      final names = suggestions.map((entry) => entry.name).join(', ');
      return UagVoiceResponse(
        title: 'Closest matches',
        body: 'I could not lock that to one item. Closest matches: $names.',
        spokenBody: 'I could not lock that to one item. Closest matches are $names.',
        shouldSpeak: true,
      );
    }

    return const UagVoiceResponse(
      title: 'No item match found',
      body: 'I could not match that to a tracked ARC Raiders item yet. Try the exact item name, blueprint name, or a shorter phrase.',
      spokenBody: 'I could not match that to a tracked ARC Raiders item yet. Try the exact item name, blueprint name, or a shorter phrase.',
      shouldSpeak: true,
    );
  }

  String _resolveQuery(UagVoiceIntent intent) {
    final query = intent.itemQuery?.trim();
    if (query != null && query.isNotEmpty) {
      return query;
    }
    return intent.rawText.trim();
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
