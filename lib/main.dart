import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'package:uag_traders_hub/widgets/theme.dart';
import 'package:uag_traders_hub/screens/build/auth/auth_landing_screen.dart';
import 'package:uag_traders_hub/build/auth/auth_screen.dart';
import 'package:uag_traders_hub/screens/build/app_entry_gate.dart';
import 'package:uag_traders_hub/features/trading_hub/trading_hub_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/arc_raiders_hub_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/arc_market_intelligence_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/arc_intel_explorer_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_create_listing_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_listings_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_my_offers_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_my_listings_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_notifications_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_profile_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_trade_sessions_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/services/trading_push_service.dart';
import 'package:uag_traders_hub/screens/build/feedback_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await TradingPushService.instance.initialize();
  runApp(const UAGTradersHubApp());
}

class UAGTradersHubApp extends StatelessWidget {
  const UAGTradersHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UAG Traders Hub',
      theme: AppTheme.theme,
      navigatorKey: TradingPushService.instance.navigatorKey,
      routes: {
        AuthLandingScreen.routeName: (context) => const AuthLandingScreen(),
        AuthScreen.routeName: (context) => const AuthScreen(),
        AppEntryGate.routeName: (context) => const AppEntryGate(),
        TradingHubScreen.routeName: (context) => const TradingHubScreen(),
        ArcRaidersHubScreen.routeName: (context) => const ArcRaidersHubScreen(),
        BlueprintGridScreen.routeName: (context) => const BlueprintGridScreen(),
        ArcMarketIntelligenceScreen.routeName: (context) =>
            const ArcMarketIntelligenceScreen(),
        ArcIntelExplorerScreen.routeName: (context) =>
            const ArcIntelExplorerScreen(),
        TradingCreateListingScreen.routeName: (context) =>
            const TradingCreateListingScreen(),
        TradingListingsScreen.routeName: (context) =>
            const TradingListingsScreen(),
        TradingMyListingsScreen.routeName: (context) =>
            const TradingMyListingsScreen(),
        TradingMyOffersScreen.routeName: (context) =>
            const TradingMyOffersScreen(),
        TradingTradeSessionsScreen.routeName: (context) =>
            const TradingTradeSessionsScreen(),
        TradingProfileScreen.routeName: (context) =>
            const TradingProfileScreen(),
        TradingNotificationsScreen.routeName: (context) =>
            const TradingNotificationsScreen(),
        FeedbackScreen.routeName: (context) => const FeedbackScreen(),
        ScrappyGridScreen.routeName: (context) => const ScrappyGridScreen(),
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) return const AppEntryGate();
          return const AuthLandingScreen();
        },
      ),
    );
  }
}
