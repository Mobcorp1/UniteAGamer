import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'features/monetisation/ads/uag_ad_consent_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_app_scroll_behavior.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_global_visual_system.dart';

import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uag_arc_raiders_hub/build/auth/auth_screen.dart';
import 'package:uag_arc_raiders_hub/build/home_screen.dart';
import 'package:uag_arc_raiders_hub/features/feature_access_gate.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/screens/monetisation_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_hunt_targets_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_availability_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_intel_explorer_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_beta_feedback_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_command_centre_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_help_centre_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_market_intelligence_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_match_rider_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_profile_setup_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_season_reset_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/my_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/my_intel_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/nomadic_trader_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/operations_command_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_raiders_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/play_like_a_pro_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/smart_trade_assist_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_activity_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_blueprint_watches_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_create_listing_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_listing_queues_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_listings_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_my_listings_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_my_offers_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_notifications_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_profile_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_trade_sessions_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/services/trading_push_service.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/session_planner/session_planner_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/trading_hub_screen.dart';
import 'package:uag_arc_raiders_hub/reg/onboarding_basic_profile_screen.dart';
import 'package:uag_arc_raiders_hub/screens/build/admin_console_screen.dart';
import 'package:uag_arc_raiders_hub/screens/build/app_entry_gate.dart';
import 'package:uag_arc_raiders_hub/screens/build/auth/auth_landing_screen.dart';
import 'package:uag_arc_raiders_hub/screens/build/feedback_screen.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const UAGTradersHubApp());

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      if (!kIsWeb) {
        await MobileAds.instance.initialize();
      }
    } catch (e, st) {
      debugPrint('MobileAds init failed: $e');
      debugPrintStack(stackTrace: st);
    }

    try {
      await UagAdConsentController.instance.initialiseForDevelopment();
    } catch (e, st) {
      debugPrint('Consent init failed: $e');
      debugPrintStack(stackTrace: st);
    }

    if (!kIsWeb) {
      try {
        await TradingPushService.instance.initialize();
      } catch (e, st) {
        debugPrint('TradingPushService init failed: $e');
        debugPrintStack(stackTrace: st);
      }
    }
  });
}

class UAGTradersHubApp extends StatelessWidget {
  const UAGTradersHubApp({super.key, this.testMode = false});

  final bool testMode;

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

      case OnboardingBasicProfileScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const OnboardingBasicProfileScreen(),
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

      case MyHubScreen.routeName:
      case ArcCommandCentreScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const ArcCommandCentreScreen(),
          settings: settings,
        );

      case BlueprintGridScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const BlueprintGridScreen(),
          settings: settings,
        );

      case FavouriteLoadoutScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const FavouriteLoadoutScreen(),
          settings: settings,
        );

      case MyIntelScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const MyIntelScreen(),
          settings: settings,
        );

      case NomadicTraderScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const NomadicTraderScreen(),
          settings: settings,
        );

      case OperationsCommandScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const OperationsCommandScreen(),
          settings: settings,
        );

      case ArcSeasonResetScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const ArcSeasonResetScreen(),
          settings: settings,
        );

      case ArcProfileSetupScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const ArcProfileSetupScreen(),
          settings: settings,
        );

      case ArcAvailabilityScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const ArcAvailabilityScreen(),
          settings: settings,
        );

      case ArcHelpCentreScreen.routeName:
        final args = settings.arguments is ArcHelpCentreArgs
            ? settings.arguments! as ArcHelpCentreArgs
            : const ArcHelpCentreArgs();

        return MaterialPageRoute(
          builder: (_) =>
              ArcHelpCentreScreen(initialCategoryId: args.initialCategoryId),
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

      case RaidPlannerHuntTargetsScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const FeatureAccessRouteGate(
            flag: FeatureAccessFlag.raidPlanner,
            title: 'Raid Planner',
            child: RaidPlannerHuntTargetsScreen(),
          ),
          settings: settings,
        );

      case SmartTradeAssistScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const FeatureAccessRouteGate(
            flag: FeatureAccessFlag.smartTradeAssist,
            title: 'Smart Trade Assist',
            child: SmartTradeAssistScreen(),
          ),
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

      case TradingBlueprintWatchesScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const FeatureAccessRouteGate(
            flag: FeatureAccessFlag.traderHub,
            title: 'Trader Hub',
            child: TraderHubScreen(initialIndex: 2, initialActivityTab: 2),
          ),
          settings: settings,
        );

      case TradingListingQueuesScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const FeatureAccessRouteGate(
            flag: FeatureAccessFlag.traderHub,
            title: 'Trader Hub',
            child: TraderHubScreen(initialIndex: 2, initialActivityTab: 3),
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

      case ArcBetaFeedbackScreen.routeName:
        final args = settings.arguments is ArcBetaFeedbackScreenArgs
            ? settings.arguments! as ArcBetaFeedbackScreenArgs
            : const ArcBetaFeedbackScreenArgs();

        return MaterialPageRoute(
          builder: (_) => ArcBetaFeedbackScreen(sourceRoute: args.sourceRoute),
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
      title: 'UAG Arc Raiders Hub',
      theme: AppTheme.theme,
      builder: (context, child) =>
          ArcGlobalVisualSystem(child: child ?? const SizedBox.shrink()),
      scrollBehavior: const ArcAppScrollBehavior(),
      navigatorKey: testMode ? null : TradingPushService.instance.navigatorKey,
      onGenerateRoute: _buildRoute,
      home: StreamBuilder<User?>(
        stream: testMode
            ? Stream<User?>.value(null)
            : FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            return const AppEntryGate();
          }

          return const AuthLandingScreen();
        },
      ),
    );
  }
}
