import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'package:uag_traders_hub/build/auth/auth_screen.dart';
import 'package:uag_traders_hub/build/home_screen.dart';
import 'package:uag_traders_hub/features/feature_access_gate.dart';
import 'package:uag_traders_hub/features/monetisation/screens/monetisation_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/arc_intel_explorer_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/arc_market_intelligence_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/arc_match_rider_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/arc_raiders_hub_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/play_like_a_pro_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_activity_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_create_listing_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_listings_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_my_listings_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_my_offers_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_notifications_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_profile_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_trade_sessions_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/services/trading_push_service.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/session_planner/session_planner_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/trading_hub_screen.dart';
import 'package:uag_traders_hub/screens/build/admin_console_screen.dart';
import 'package:uag_traders_hub/screens/build/app_entry_gate.dart';
import 'package:uag_traders_hub/screens/build/auth/auth_landing_screen.dart';
import 'package:uag_traders_hub/screens/build/feedback_screen.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    try {
      await TradingPushService.instance.initialize();
    } catch (e, st) {
      debugPrint('TradingPushService init failed: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  runApp(const UAGTradersHubApp());
}

class UAGTradersHubApp extends StatelessWidget {
  const UAGTradersHubApp({super.key});

  Route<dynamic> _buildRoute(RouteSettings settings) {
    switch (settings.name) {
      case AuthLandingScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const AuthLandingScreen(),
          settings: settings,
        );

      case AuthScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const AuthScreen(),
          settings: settings,
        );

      case AppEntryGate.routeName:
      case HomeScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const AppEntryGate(),
          settings: settings,
        );

      case MonetisationScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const MonetisationScreen(),
          settings: settings,
        );

      case TradingHubScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const TradingHubScreen(),
          settings: settings,
        );

      case ArcRaidersHubScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const ArcRaidersHubScreen(),
          settings: settings,
        );

      case BlueprintGridScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const BlueprintGridScreen(),
          settings: settings,
        );

      case ArcMarketIntelligenceScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const ArcMarketIntelligenceScreen(),
          settings: settings,
        );

      case ArcIntelExplorerScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const ArcIntelExplorerScreen(),
          settings: settings,
        );

      case ArcMatchRiderScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const FeatureAccessRouteGate(
            flag: FeatureAccessFlag.matchRaider,
            title: 'Match Raider',
            child: ArcMatchRiderScreen(),
          ),
          settings: settings,
        );

      case ScrappyGridScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const FeatureAccessRouteGate(
            flag: FeatureAccessFlag.scrappyTracker,
            title: 'Scrappy Tracker',
            child: ScrappyGridScreen(),
          ),
          settings: settings,
        );

      case ScrappyGridScreen.benchRouteName:
        return MaterialPageRoute(
          builder: (_) => const FeatureAccessRouteGate(
            flag: FeatureAccessFlag.scrappyTracker,
            title: 'Bench Tracker',
            child: ScrappyGridScreen.bench(),
          ),
          settings: settings,
        );

      case ScrappyGridScreen.questRouteName:
        return MaterialPageRoute(
          builder: (_) => const FeatureAccessRouteGate(
            flag: FeatureAccessFlag.scrappyTracker,
            title: 'Quest Tracker',
            child: ScrappyGridScreen.quest(),
          ),
          settings: settings,
        );

      case PlayLikeAProScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const FeatureAccessRouteGate(
            flag: FeatureAccessFlag.playLockerPro,
            title: 'Play Like a Pro',
            child: PlayLikeAProScreen(),
          ),
          settings: settings,
        );

      case RaidPlannerScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const RaidPlannerScreen(),
          settings: settings,
        );

      case SessionPlannerScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const FeatureAccessRouteGate(
            flag: FeatureAccessFlag.traderHub,
            title: 'Session Planner',
            child: SessionPlannerScreen(),
          ),
          settings: settings,
        );

      case TraderHubScreen.routeName:
      case TradingListingsScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const FeatureAccessRouteGate(
            flag: FeatureAccessFlag.traderHub,
            title: 'Trader Hub',
            child: TraderHubScreen(initialIndex: 0),
          ),
          settings: settings,
        );

      case TradingCreateListingScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const FeatureAccessRouteGate(
            flag: FeatureAccessFlag.traderHub,
            title: 'Trader Hub',
            child: TraderHubScreen(initialIndex: 1),
          ),
          settings: settings,
        );

      case TradingActivityScreen.routeName:
      case TradingMyListingsScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const FeatureAccessRouteGate(
            flag: FeatureAccessFlag.traderHub,
            title: 'Trader Hub',
            child: TraderHubScreen(initialIndex: 2, initialActivityTab: 0),
          ),
          settings: settings,
        );

      case TradingMyOffersScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const FeatureAccessRouteGate(
            flag: FeatureAccessFlag.traderHub,
            title: 'Trader Hub',
            child: TraderHubScreen(initialIndex: 2, initialActivityTab: 1),
          ),
          settings: settings,
        );

      case TradingTradeSessionsScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const FeatureAccessRouteGate(
            flag: FeatureAccessFlag.traderHub,
            title: 'Trader Hub',
            child: TraderHubScreen(initialIndex: 3),
          ),
          settings: settings,
        );

      case TradingNotificationsScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const FeatureAccessRouteGate(
            flag: FeatureAccessFlag.traderHub,
            title: 'Trader Hub',
            child: TraderHubScreen(initialIndex: 4),
          ),
          settings: settings,
        );

      case TradingProfileScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const FeatureAccessRouteGate(
            flag: FeatureAccessFlag.traderHub,
            title: 'Trader Hub',
            child: TraderHubScreen(initialIndex: 5),
          ),
          settings: settings,
        );

      case FeedbackScreen.routeName:
        final args = settings.arguments is FeedbackScreenArgs
            ? settings.arguments! as FeedbackScreenArgs
            : const FeedbackScreenArgs();
        return MaterialPageRoute(
          builder: (_) => FeedbackScreen(initialTabIndex: args.initialTabIndex),
          settings: settings,
        );

      case AdminConsoleScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const AdminConsoleScreen(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const AuthLandingScreen(),
          settings: settings,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UAG Raiders Hub',
      theme: AppTheme.theme,
      navigatorKey: TradingPushService.instance.navigatorKey,
      onGenerateRoute: _buildRoute,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: SizedBox.expand(
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          if (snapshot.hasData) return const AppEntryGate();

          return const AuthLandingScreen();
        },
      ),
    );
  }
}
