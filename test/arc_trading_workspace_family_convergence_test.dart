import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('trading workspace exposes one compact family navigation contract', () {
    final source = read(
      'lib/features/trading_hub/arc_raiders/widgets/arc_trading_workspace_bar.dart',
    );

    expect(source, contains('enum ArcTradingWorkspace'));
    expect(source, contains('market, smartTrade, traders, activity, sessions'));
    expect(source, contains("return '/trading-hub/arc-raiders/trader-hub';"));
    expect(
      source,
      contains("return '/trading-hub/arc-raiders/smart-trade-assist';"),
    );
    expect(source, contains("return '/arc-trader-search';"));
    expect(source, contains("return '/trading-hub/arc-raiders/activity';"));
    expect(source, contains("return '/trading-hub/arc-raiders/sessions';"));
    expect(source, contains('rootNavigator: true'));
    expect(source, isNot(contains('TradingRepository')));
    expect(source, isNot(contains('StreamBuilder')));
  });

  test('market, activity, sessions, Smart Trade and trader search join family', () {
    final screens = <String, String>{
      'lib/features/trading_hub/arc_raiders/screens/trading_listings_screen.dart':
          'ArcTradingWorkspace.market',
      'lib/features/trading_hub/arc_raiders/screens/trading_activity_screen.dart':
          'ArcTradingWorkspace.activity',
      'lib/features/trading_hub/arc_raiders/screens/trading_trade_sessions_screen.dart':
          'ArcTradingWorkspace.sessions',
      'lib/features/trading_hub/arc_raiders/screens/smart_trade_assist_screen.dart':
          'ArcTradingWorkspace.smartTrade',
      'lib/features/trading_hub/arc_raiders/screens/arc_trader_search_screen.dart':
          'ArcTradingWorkspace.traders',
    };

    for (final entry in screens.entries) {
      final source = read(entry.key);
      expect(source, contains('ArcTradingWorkspaceBar('), reason: entry.key);
      expect(source, contains(entry.value), reason: entry.key);
    }
  });

  test('trader search route is registered in the app router', () {
    final mainSource = read('lib/main.dart');
    expect(mainSource, contains("screens/arc_trader_search_screen.dart"));
    expect(mainSource, contains('case ArcTraderSearchScreen.routeName:'));
    expect(mainSource, contains('child: ArcTraderSearchScreen()'));
  });

  test('trading business wiring remains present on converged screens', () {
    final listings = read(
      'lib/features/trading_hub/arc_raiders/screens/trading_listings_screen.dart',
    );
    final activity = read(
      'lib/features/trading_hub/arc_raiders/screens/trading_activity_screen.dart',
    );
    final sessions = read(
      'lib/features/trading_hub/arc_raiders/screens/trading_trade_sessions_screen.dart',
    );
    final smart = read(
      'lib/features/trading_hub/arc_raiders/screens/smart_trade_assist_screen.dart',
    );
    final search = read(
      'lib/features/trading_hub/arc_raiders/screens/arc_trader_search_screen.dart',
    );

    expect(listings, contains('_repository.watchActiveListings()'));
    expect(activity, contains('TradingMyOffersScreen(showAppBar: false)'));
    expect(sessions, contains('_repository.watchMySessions()'));
    expect(smart, contains('_repository.watchActiveListings()'));
    expect(search, contains('_repository.searchTraders('));
  });
}
