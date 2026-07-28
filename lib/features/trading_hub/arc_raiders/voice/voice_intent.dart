enum UagVoiceIntentType {
  wakePhrase,
  needCheck,
  tradeCheck,
  tradeMarketCheck,
  benchLookup,
  questLookup,
  keepCheck,
  blueprintSearch,
  reportBlueprint,
  reportWeaponCache,
  addLocationToRoute,
  readNotifications,
  readNextObjective,
  conductRiskCheck,
  startConductReport,
  confirm,
  cancel,
  repeat,
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
      case UagVoiceIntentType.readNotifications:
      case UagVoiceIntentType.readNextObjective:
      case UagVoiceIntentType.conductRiskCheck:
      case UagVoiceIntentType.startConductReport:
        return true;
      case UagVoiceIntentType.wakePhrase:
      case UagVoiceIntentType.needCheck:
      case UagVoiceIntentType.tradeCheck:
      case UagVoiceIntentType.benchLookup:
      case UagVoiceIntentType.questLookup:
      case UagVoiceIntentType.keepCheck:
      case UagVoiceIntentType.blueprintSearch:
      case UagVoiceIntentType.reportBlueprint:
      case UagVoiceIntentType.reportWeaponCache:
      case UagVoiceIntentType.addLocationToRoute:
      case UagVoiceIntentType.confirm:
      case UagVoiceIntentType.cancel:
      case UagVoiceIntentType.repeat:
      case UagVoiceIntentType.unknown:
        return false;
    }
  }
}
