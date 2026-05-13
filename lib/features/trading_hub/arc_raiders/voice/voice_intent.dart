enum UagVoiceIntentType {
  needCheck,
  tradeCheck,
  benchLookup,
  questLookup,
  keepCheck,
  unknown,
}

class UagVoiceIntent {
  const UagVoiceIntent({
    required this.type,
    required this.rawText,
    this.itemQuery,
  });

  final UagVoiceIntentType type;
  final String rawText;
  final String? itemQuery;
}
