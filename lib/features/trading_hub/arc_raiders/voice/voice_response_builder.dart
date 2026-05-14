import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_item_advice_index.dart';
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
    final query = intent.itemQuery ?? intent.rawText;
    final decision = ArcItemAdviceIndex.decide(
      query: query,
      blueprintStates: blueprintStates,
    );

    if (decision == null) {
      final suggestions = ArcItemAdviceIndex.search(query).take(5).map((item) => item.name).toList();
      final suggestionText = suggestions.isEmpty
          ? 'Try the exact item, weapon, material, key, or blueprint name.'
          : 'Closest matches: ${suggestions.join(', ')}.';
      return UagVoiceResponse(
        title: 'No item match found',
        body: 'I could not match that to a tracked ARC Raiders item yet. $suggestionText',
        spokenBody: 'I could not match that item yet. $suggestionText',
        shouldSpeak: true,
      );
    }

    return UagVoiceResponse(
      title: '${decision.actionLabel}: ${decision.title}',
      body: decision.displayAdvice,
      spokenBody: decision.spokenAdvice,
      shouldSpeak: true,
    );
  }
}
