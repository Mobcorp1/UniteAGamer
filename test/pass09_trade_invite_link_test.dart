import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/services/uag_trade_invite_service.dart';

void main() {
  test('opaque trading URL parses only trusted HTTPS hosts', () {
    const token = 's9LkDsPlsP02_sk-O2ssr9LPxcGHyVcNZNgTR5_12';
    expect(
      UagTradeInviteService.parse(
        Uri.parse('https://unite-a-gamer.web.app/t/$token'),
      ),
      token,
    );
    expect(
      UagTradeInviteService.parse(
        Uri.parse('https://uniteagamer.com/t/$token'),
      ),
      token,
    );
    expect(
      UagTradeInviteService.parse(Uri.parse('https://evil.example/t/$token')),
      isNull,
    );
    expect(
      UagTradeInviteService.parse(
        Uri.parse('http://unite-a-gamer.web.app/t/$token'),
      ),
      isNull,
    );
    expect(
      UagTradeInviteService.parse(
        Uri.parse('https://unite-a-gamer.web.app/?referrer=uid&refcode=X'),
      ),
      isNull,
    );
  });
  test('malformed tokens rejected', () {
    expect(
      UagTradeInviteService.parse(
        Uri.parse('https://unite-a-gamer.web.app/t/x'),
      ),
      isNull,
    );
    expect(
      UagTradeInviteService.parse(
        Uri.parse('https://unite-a-gamer.web.app/t/%2e%2e'),
      ),
      isNull,
    );
  });
  test('only trusted personal tokens become canonical public-domain links', () {
    const token = 's9LkDsPlsP02_sk-O2ssr9LPxcGHyVcNZNgTR5_12';
    final expected = 'https://uniteagamer.com/t/$token';
    expect(
      UagTradeInviteService.canonicalShareUrl(
        'https://unite-a-gamer.web.app/t/$token',
      ),
      expected,
    );
    expect(
      UagTradeInviteService.canonicalShareUrl(
        'https://www.uniteagamer.com/t/$token',
      ),
      expected,
    );
    expect(UagTradeInviteService.canonicalShareUrl(expected), expected);
    expect(
      UagTradeInviteService.canonicalShareUrl('https://evil.example/t/$token'),
      isNull,
    );
    expect(
      UagTradeInviteService.canonicalShareUrl(
        'https://uniteagamer.com/t/$token?owner=someone',
      ),
      isNull,
    );
    expect(
      UagTradeInviteService.canonicalShareUrl(
        'https://uniteagamer.com/t/not-valid',
      ),
      isNull,
    );
  });
}
