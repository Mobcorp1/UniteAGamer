/// Share-ready marketing copy. The actual opaque Raider invite URL must be
/// created and validated by UagTradeInviteService before these are called.
/// Never append the saved inventory, quantities, Firebase UID or an affiliate ID.
class ArcTradeShareCopy {
  const ArcTradeShareCopy._();

  static const String headline = '⚡ ARC RAIDERS BLUEPRINTS FOR TRADE';

  static const String hashtags =
      '#ArcRaiders #BlueprintTrading #ArcRaidersTrading #UniteAGamer #FYP';

  static String _displayName(String name) {
    final normalized = name.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) return 'a UAG Raider';
    return normalized.length > 42
        ? '${normalized.substring(0, 42)}…'
        : normalized;
  }

  /// Short direct-message caption; personal invitation resolves after sign-in.
  static String whatsApp({required String raider, required String link}) =>
      '🎮 ARC RAIDERS — TRADE WITH ${_displayName(raider)}\n\n'
      'I’ve got spare Blueprints. Fancy a trade?\n\n'
      'Check my trade card. Sign up or log in at uniteagamer.com to see what '
      'I need and make an offer.\n\n'
      '🔗 $link';

  /// Brief social post: no public inventory, no private wants or false offers.
  static String social({required String raider, required String link}) =>
      '$headline\n\n'
      'I’ve got spare Blueprints. Fancy a trade? 🎮\n\n'
      'Check out my trade card! Sign up or log in at uniteagamer.com to '
      'see what I need and make an offer.\n\n'
      '🔗 $link\n\n'
      '$hashtags';
}
