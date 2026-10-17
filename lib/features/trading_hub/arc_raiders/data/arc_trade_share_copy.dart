/// Share-ready marketing copy. The actual opaque Raider invite URL must be
/// created and validated by UagTradeInviteService before these are called.
/// Never append the saved inventory, quantities, Firebase UID or an affiliate ID.
class ArcTradeShareCopy {
  const ArcTradeShareCopy._();

  static const String headline =
      '⚡ ARC RAIDERS: YOUR NEXT BLUEPRINT IS ONE TRADE AWAY';

  static const String hashtags =
      '#ArcRaiders #BlueprintTrading #ArcRaidersTrading #UniteAGamer #FYP';

  static String _displayName(String name) {
    final normalized = name.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) return 'a UAG Raider';
    return normalized.length > 42 ? '${normalized.substring(0, 42)}…' : normalized;
  }

  /// Short invite for WhatsApp and direct messages: link resolves to the
  /// original Raider after authentication and mandatory onboarding.
  static String whatsApp({required String raider, required String link}) =>
      '🎮 ARC RAIDERS — TRADE WITH ${_displayName(raider)}\n\n'
      'Got spare Blueprints? I’m looking to swap. Tap my personal Raider link, '
      'sign in or join UAG, complete your Raider setup and come straight '
      'to my trading page to propose a trade.\n\n'
      '🔗 $link';

  /// Long social caption. Use with the cinematic artwork, not a text inventory.
  /// Up to five relevant hashtags, including #FYP, and no assumed social handle.
  static String social({required String raider, required String link}) =>
      '$headline\n\n'
      'Still hunting that one ARC Raiders Blueprint while your stash fills '
      'up with duplicates? Someone out there might have exactly what you need — '
      'and your spare might be the one they have been searching for.\n\n'
      'I’m ${_displayName(raider)}, and I’m trading through the UAG ARC Raiders Hub. '
      'Take a look at my personal Raider trading page, compare what works for '
      'your collection and send me an offer directly. Whether you are trying '
      'to finish your Blueprint grid, gear up for your next raid or complete '
      'a favourite loadout, a good trade beats another night of blind grinding.\n\n'
      'No endless back-and-forth listing every item in the comments. Open the '
      'link, create your free account or sign in, finish the required Raider '
      'setup and you will be brought straight back to my trading page. '
      'From there, propose a trade and arrange the exchange through UAG.\n\n'
      '👇 SEE MY TRADES AND SEND AN OFFER\n'
      '🔗 $link\n\n'
      '$hashtags';
}
