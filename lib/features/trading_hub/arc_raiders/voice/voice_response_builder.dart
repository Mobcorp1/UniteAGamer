import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_item_advice_index.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_voice_item_database.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/unified_item_index.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/voice/voice_intent.dart';

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
    Map<String, ArcBlueprintState> blueprintStates =
        const <String, ArcBlueprintState>{},
  }) {
    final query = _resolveQuery(intent);

    final operationalResponse = _operationalResponse(intent);
    if (operationalResponse != null) return operationalResponse;

    if (intent.type == UagVoiceIntentType.blueprintSearch) {
      final lowerRaw = intent.rawText.toLowerCase();
      final blueprints = ArcBlueprintSeedData.blueprints;

      if (lowerRaw.contains('hunt') ||
          lowerRaw.contains('rarest missing') ||
          lowerRaw.contains('top five') ||
          lowerRaw.contains('top 5')) {
        final missing = blueprints
            .where((blueprint) {
              final state = blueprintStates[blueprint.id];
              return !(state?.owned ?? false);
            })
            .toList(growable: false);

        if (missing.isEmpty) {
          return const UagVoiceResponse(
            title: 'Hunts clear',
            body:
                'Blueprint Tracker says you own every tracked blueprint. No missing hunt target found.',
            spokenBody:
                'Blueprint Tracker says you own every tracked blueprint.',
            shouldSpeak: true,
          );
        }

        final wanted =
            missing
                .where((blueprint) {
                  final state = blueprintStates[blueprint.id];
                  final rank = state?.priorityRank ?? 0;
                  return rank > 0 && rank <= 5;
                })
                .toList(growable: false)
              ..sort((a, b) {
                final aRank = blueprintStates[a.id]?.priorityRank ?? 99;
                final bRank = blueprintStates[b.id]?.priorityRank ?? 99;
                return aRank.compareTo(bRank);
              });

        final targets = (wanted.isNotEmpty ? wanted : missing).take(5).toList();
        final names = targets.map((blueprint) => blueprint.name).join(', ');

        return UagVoiceResponse(
          title: 'Recommended hunt targets',
          body:
              'Recommended blueprint hunts: $names.\n\nBased on Blueprint Tracker missing state and Top 5 priority where available.',
          spokenBody: 'Recommended blueprint hunts are $names.',
          shouldSpeak: true,
        );
      }

      final blueprintDecision = ArcItemAdviceIndex.decide(
        query: _normaliseSpeechQuery(query),
        blueprintStates: blueprintStates,
      );

      if (blueprintDecision != null) {
        final action =
            blueprintDecision.primaryAction == ArcItemPrimaryAction.trade
            ? '\n\nIf this is a duplicate, use it as trade stock or create an Intel report for where it dropped.'
            : '\n\nIf you found this in-raid, say create intel for ${blueprintDecision.title}.';

        return UagVoiceResponse(
          title: blueprintDecision.title,
          body: '${blueprintDecision.displayAdvice}$action',
          spokenBody: blueprintDecision.spokenAdvice,
          shouldSpeak: true,
        );
      }
    }
    if (query.trim().isEmpty) {
      return const UagVoiceResponse(
        title: 'Ask UAG Raider',
        body:
            'Ask about an item, blueprint, Scrappy material, bench upgrade, quest item, or trade value.',
        shouldSpeak: true,
      );
    }

    final decision = ArcItemAdviceIndex.decide(
      query: _normaliseSpeechQuery(query),
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

    final suggestions = _suggestions(query).take(5).toList(growable: false);
    if (suggestions.isNotEmpty) {
      final first = suggestions.first;
      final names = suggestions.map((entry) => entry.name).join(', ');
      return UagVoiceResponse(
        title: 'Closest match',
        body:
            'I could not lock that in confidently. Did you mean ${first.name}?\n\nOther close matches: $names.',
        spokenBody:
            'I could not lock that in confidently. Did you mean ${first.name}? Say yes, or tap confirm, and I will open that item.',
        shouldSpeak: true,
        suggestedItemName: first.name,
        suggestionNames: suggestions
            .map((entry) => entry.name)
            .toList(growable: false),
      );
    }

    return const UagVoiceResponse(
      title: 'No item match found',
      body:
          'I could not match that to a tracked ARC Raiders item yet. Try the exact item name, blueprint name, or a shorter phrase.',
      spokenBody:
          'I could not match that to a tracked ARC Raiders item yet. Try the exact item name, blueprint name, or a shorter phrase.',
      shouldSpeak: true,
    );
  }

  UagVoiceResponse? _operationalResponse(UagVoiceIntent intent) {
    switch (intent.type) {
      case UagVoiceIntentType.wakePhrase:
        return const UagVoiceResponse(
          title: 'Raider online',
          body:
              'Say an item, blueprint, route, notification or priority command.',
          spokenBody: 'Raider online. What do you need?',
          shouldSpeak: true,
        );
      case UagVoiceIntentType.reportBlueprint:
        return const UagVoiceResponse(
          title: 'Blueprint report ready',
          body:
              'Open the Blueprint Tracker report sheet to submit map, source and acquisition evidence.',
          spokenBody: 'Open the Blueprint Tracker report sheet to submit it.',
          shouldSpeak: true,
        );
      case UagVoiceIntentType.reportWeaponCache:
        return const UagVoiceResponse(
          title: 'Cache report ready',
          body:
              'Open Raid Intelligence to place a weapon cache marker with evidence.',
          spokenBody: 'Open Raid Intelligence to place a cache marker.',
          shouldSpeak: true,
        );
      case UagVoiceIntentType.addLocationToRoute:
        return const UagVoiceResponse(
          title: 'Route marker ready',
          body: 'Open Route Builder to add the current location as a waypoint.',
          spokenBody: 'Open Route Builder to add that waypoint.',
          shouldSpeak: true,
        );
      case UagVoiceIntentType.readNotifications:
        return const UagVoiceResponse(
          title: 'Notifications',
          body:
              'Live notification reading needs the signed-in notification inbox context.',
          spokenBody: 'I need your live inbox before I can read notifications.',
          shouldSpeak: true,
        );
      case UagVoiceIntentType.readNextObjective:
        return const UagVoiceResponse(
          title: 'Next objective',
          body:
              'Open Command Centre for the current Decision Engine priority and top actions.',
          spokenBody: 'Open Command Centre for your current priority.',
          shouldSpeak: true,
        );
      case UagVoiceIntentType.conductRiskCheck:
        return const UagVoiceResponse(
          title: 'Trust check',
          body:
              'Open the trader profile or session detail to review trust, reports and conduct context.',
          spokenBody: 'Open the trader profile to review trust context.',
          shouldSpeak: true,
        );
      case UagVoiceIntentType.startConductReport:
        return const UagVoiceResponse(
          title: 'Conduct report',
          body:
              'Open the conduct report flow from the related trade, session or profile so evidence stays attached.',
          spokenBody: 'Open the related profile or session to file a report.',
          shouldSpeak: true,
        );
      case UagVoiceIntentType.confirm:
        return const UagVoiceResponse(
          title: 'Confirmed',
          body: 'Confirmed. Continue with the selected action.',
          spokenBody: 'Confirmed.',
          shouldSpeak: true,
        );
      case UagVoiceIntentType.cancel:
        return const UagVoiceResponse(
          title: 'Cancelled',
          body: 'Cancelled. No action was taken.',
          spokenBody: 'Cancelled.',
          shouldSpeak: true,
        );
      case UagVoiceIntentType.repeat:
        return const UagVoiceResponse(
          title: 'Repeat',
          body: 'Repeat the last response when a live voice session is active.',
          spokenBody: 'Repeat the last response when a live session is active.',
          shouldSpeak: true,
        );
      case UagVoiceIntentType.needCheck:
      case UagVoiceIntentType.tradeCheck:
      case UagVoiceIntentType.tradeMarketCheck:
      case UagVoiceIntentType.benchLookup:
      case UagVoiceIntentType.questLookup:
      case UagVoiceIntentType.keepCheck:
      case UagVoiceIntentType.blueprintSearch:
      case UagVoiceIntentType.todayTradeSessions:
      case UagVoiceIntentType.todayMatchSessions:
      case UagVoiceIntentType.unknown:
        return null;
    }
  }

  UagVoiceResponse buildConfirmedSuggestion(
    String itemName, {
    Map<String, ArcBlueprintState> blueprintStates =
        const <String, ArcBlueprintState>{},
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
    cleaned = cleaned.replaceAll(
      RegExp(r'\bARK\b', caseSensitive: false),
      'ARC',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'\bark\b', caseSensitive: false),
      'ARC',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'\bequaliser\b', caseSensitive: false),
      'Equalizer',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'\bdalabra\b', caseSensitive: false),
      'Dolabra',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'\bdoll abra\b', caseSensitive: false),
      'Dolabra',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'\bdoh labra\b', caseSensitive: false),
      'Dolabra',
    );
    return cleaned;
  }

  List<_Suggestion> _suggestions(String query) {
    final normalizedQuery = UnifiedItemIndex.normalize(
      _normaliseSpeechQuery(query),
    );
    if (normalizedQuery.isEmpty) return const <_Suggestion>[];

    final suggestions = <_Suggestion>[];
    final seen = <String>{};

    for (final match in ArcVoiceItemDatabase.search(normalizedQuery).take(10)) {
      final key = UnifiedItemIndex.normalize(match.name);
      if (seen.add(key)) {
        suggestions.add(
          _Suggestion(
            name: match.name,
            score: _score(normalizedQuery, match.name),
          ),
        );
      }
    }

    for (final match in ArcItemAdviceIndex.search(normalizedQuery).take(10)) {
      final key = UnifiedItemIndex.normalize(match.name);
      if (seen.add(key)) {
        suggestions.add(
          _Suggestion(
            name: match.name,
            score: _score(normalizedQuery, match.name),
          ),
        );
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

    final qTokens = normalizedQuery
        .split(' ')
        .where((token) => token.isNotEmpty)
        .toSet();
    final cTokens = candidate
        .split(' ')
        .where((token) => token.isNotEmpty)
        .toSet();
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
      parts.add(
        'Database: ${record.rarity} ${record.category}. Default action: ${record.actionLabel}.',
      );
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
