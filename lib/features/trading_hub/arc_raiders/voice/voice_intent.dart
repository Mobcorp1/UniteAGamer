enum UagVoiceIntentType {
  needCheck,
  tradeCheck,
  tradeMarketCheck,
  benchLookup,
  questLookup,
  keepCheck,
  blueprintSearch,
  todayTradeSessions,
  todayMatchSessions,
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

  bool get needsLiveAppContext {
    switch (type) {
      case UagVoiceIntentType.tradeMarketCheck:
      case UagVoiceIntentType.todayTradeSessions:
      case UagVoiceIntentType.todayMatchSessions:
        return true;
      case UagVoiceIntentType.needCheck:
      case UagVoiceIntentType.tradeCheck:
      case UagVoiceIntentType.benchLookup:
      case UagVoiceIntentType.questLookup:
      case UagVoiceIntentType.keepCheck:
      case UagVoiceIntentType.blueprintSearch:
      case UagVoiceIntentType.unknown:
        return false;
    }
  }
}
