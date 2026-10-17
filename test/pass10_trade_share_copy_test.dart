import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_trade_share_copy.dart';

void main() {
  const tradeUrl = 'https://unite-a-gamer.web.app/t/abcdefghijklmnopqrstuvwxyz123456';

  test('WhatsApp message links to the original Raider without inventory dumps', () {
    final text = ArcTradeShareCopy.whatsApp(raider: 'Raider One', link: tradeUrl);
    expect(text, contains(tradeUrl));
    expect(text, contains('Raider One'));
    expect(text, contains('complete your Raider setup'));
    expect(text.toLowerCase(), isNot(contains('spares for trade:')));
    expect(text.toLowerCase(), isNot(contains('needed:')));
    expect(text, isNot(contains(' x2 ')));
  });

  test('social post has a headline, useful long CTA and five hashtags', () {
    final text = ArcTradeShareCopy.social(raider: 'Raider One', link: tradeUrl);
    expect(text, startsWith(ArcTradeShareCopy.headline));
    expect(text, contains(tradeUrl));
    expect(text, contains('brought straight back to my trading page'));
    expect(text.length, greaterThan(650));
    expect(RegExp(r'#[A-Za-z0-9]+').allMatches(text).length, 5);
    expect(text, contains('#FYP'));
    expect(text, isNot(contains('SPARES FOR TRADE:')));
    expect(text, isNot(contains('NEEDED:')));
  });

  test('share implementation rejects generic or UID-based fallback links', () {
    final source = File('lib/features/trading_hub/arc_raiders/widgets/arc_collection_visual_share.dart')
        .readAsStringSync();
    expect(source, contains('UagTradeInviteService.parse(uri)'));
    expect(source, contains('ArcTradeShareCopy.whatsApp('));
    expect(source, contains('ArcTradeShareCopy.social('));
    expect(source, contains('text: imageOnly ? null : caption'));
    expect(source, contains("key: const Key('copy-personal-raider-link')"));
    expect(source, isNot(contains("widget.link ?? 'https://unite-a-gamer.web.app'")));
  });
}
