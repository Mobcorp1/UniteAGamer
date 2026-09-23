import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_events_screen.dart';
import 'dart:async';

import 'features/monetisation/ads/uag_ad_consent_controller.dart';
import 'features/monetisation/ads/uag_ad_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_app_scroll_behavior.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_global_visual_system.dart';
import 'package:uag_arc_raiders_hub/widgets/uag_cinematic_loading_screen.dart';

import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uag_arc_raiders_hub/build/auth/auth_screen.dart';
import 'package:uag_arc_raiders_hub/build/home_screen.dart';
import 'package:uag_arc_raiders_hub/features/feature_access_gate.dart';
import 'package:uag_arc_raiders_hub/features/legal/screens/legal_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/legal/screens/privacy_data_screen.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/screens/monetisation_screen.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/services/uag_creator_referral_bootstrap.dart';
import 'package:uag_arc_raiders_hub/features/profile/screens/profile_settings_screen.dart';
import 'package:uag_arc_raiders_hub/features/trust/screens/arc_raider_contracts_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_hunt_targets_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_availability_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_away_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_admin_map_editor_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_intel_explorer_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_beta_feedback_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_command_centre_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_help_centre_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_map_filter_icon_review_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_market_intelligence_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_match_rider_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_progress_trackers_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_profile_edit_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_profile_setup_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_raid_intelligence_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_season_reset_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_smart_build_trade_draft_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_trader_search_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_future_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/referral_tools_screen.dart';
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
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/wall_of_legends_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/services/trading_push_service.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/session_planner/session_planner_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/trading_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_mandatory_onboarding_screen.dart';
import 'package:uag_arc_raiders_hub/screens/build/admin_console_screen.dart';
import 'package:uag_arc_raiders_hub/screens/build/app_entry_gate.dart';
import 'package:uag_arc_raiders_hub/screens/build/auth/auth_landing_screen.dart';
import 'package:uag_arc_raiders_hub/screens/build/feedback_screen.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

import 'package:uag_arc_raiders_hub/features/monetisation/services/uag_community_referral_deep_link_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Render the approved UAG boot treatment immediately while Firebase and
  // startup services initialise. This gives native mobile the same first
  // impression as the web bootstrap instead of waiting on a blank frame.
  runApp(const _UagBootstrapApp());

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await UagCreatorReferralBootstrap.instance.initialise();
  await UagCommunityReferralDeepLinkBootstrap.instance.initialise();
  UagCommunityReferralDeepLinkBootstrap.instance.captureWebRoute(Uri.base);

  runApp(const UAGTradersHubApp());

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await UagAdConsentController.instance.initialiseForDevelopment();
    } catch (e, st) {
      debugPrint('Consent init failed: $e');
      debugPrintStack(stackTrace: st);
    }

    try {
      await UagAdService.instance.initialise();
    } catch (e, st) {
      debugPrint('UagAdService init failed: $e');
      debugPrintStack(stackTrace: st);
    }

    try {
      await TradingPushService.instance.initialize();
    } catch (e, st) {
      debugPrint('TradingPushService init failed: $e');
      debugPrintStack(stackTrace: st);
    }
  });
}

class _UagBootstrapApp extends StatelessWidget {
  const _UagBootstrapApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const UagCinematicLoadingScreen(),
    );
  }
}

class UAGTradersHubApp extends StatefulWidget {
  const UAGTradersHubApp({super.key, this.testMode = false});

  final bool testMode;

  @override
  State<UAGTradersHubApp> createState() => _UAGTradersHubAppState();

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

      case ArcMandatoryOnboardingScreen.routeName:
      case '/onboarding-basic-profile':
        return MaterialPageRoute(
          builder: (_) => _DirectOnboardingRouteGate(settings: settings),
          settings: settings,
        );

      case MonetisationScreen.routeName:
      case '/monetisation/plans':
        return MaterialPageRoute(
          builder: (_) => const MonetisationScreen(),
          settings: settings,
        );

      case ProfileSettingsScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const ProfileSettingsScreen(),
          settings: settings,
        );

      case LegalHubScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const LegalHubScreen(),
          settings: settings,
        );

      case UagPrivacyDataScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const UagPrivacyDataScreen(),
          settings: settings,
        );

      case ArcRaiderContractsScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const FeatureAccessRouteGate(
            flag: FeatureAccessFlag.raiderContracts,
            title: 'Report a Rat',
            child: ArcRaiderContractsScreen(),
          ),
          settings: settings,
        );

      case TradingHubScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const TradingHubScreen(),
          settings: settings,
        );

      case ArcFutureHubScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const ArcFutureHubScreen(),
          settings: settings,
        );

      case '/community-command':
        return MaterialPageRoute(
          builder: (_) => ReferralToolsScreen(),
          settings: settings,
        );

      case ArcRaidersHubScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const ArcRaidersHubScreen(),
          settings: settings,
        );

      case MyHubScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const MyHubScreen(),
          settings: settings,
        );

      case ArcCommandCentreScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const ArcCommandCentreScreen(),
          settings: settings,
        );

      case MyHubScreen.toolDeckRouteName:
        return MaterialPageRoute(
          builder: (_) => const MyHubScreen(),
          settings: settings,
        );

      case ArcProgressTrackersScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const ArcProgressTrackersScreen(),
          settings: settings,
        );

      case BlueprintGridScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const FeatureAccessRouteGate(
            flag: FeatureAccessFlag.blueprintTracker,
            title: 'Blueprint Tracker',
            child: BlueprintGridScreen(),
          ),
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

      case ArcProfileEditScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const ArcProfileEditScreen(),
          settings: settings,
        );

      case ArcAvailabilityScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const ArcAvailabilityScreen(),
          settings: settings,
        );

      case ArcAwayScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const ArcAwayScreen(),
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
          builder: (_) => const FeatureAccessRouteGate(
            flag: FeatureAccessFlag.intelExplorer,
            title: 'Intel Explorer',
            child: ArcIntelExplorerScreen(),
          ),
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
            flag: FeatureAccessFlag.benchTracker,
            title: 'Bench Tracker',
            child: ScrappyGridScreen.bench(),
          ),
          settings: settings,
        );

      case ScrappyGridScreen.questRouteName:
        return MaterialPageRoute(
          builder: (_) => const FeatureAccessRouteGate(
            flag: FeatureAccessFlag.questTracker,
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

      case ArcEventsScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const FeatureAccessRouteGate(
            flag: FeatureAccessFlag.raidPlanner,
            title: 'Events',
            child: ArcEventsScreen(),
          ),
          settings: settings,
        );

      case RaidPlannerScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const FeatureAccessRouteGate(
            flag: FeatureAccessFlag.raidPlanner,
            title: 'Raid Planner',
            child: RaidPlannerScreen(),
          ),
          settings: settings,
        );

      case ArcRaidIntelligenceScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const FeatureAccessRouteGate(
            flag: FeatureAccessFlag.intelExplorer,
            title: 'Raid Intelligence',
            child: ArcRaidIntelligenceScreen(),
          ),
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

      case ArcSmartBuildTradeDraftScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const FeatureAccessRouteGate(
            flag: FeatureAccessFlag.smartTradeAssist,
            title: 'Smart Build Trade Draft',
            child: ArcSmartBuildTradeDraftScreen(),
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

      case ArcTraderSearchScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const FeatureAccessRouteGate(
            flag: FeatureAccessFlag.traderHub,
            title: 'Search Traders',
            child: ArcTraderSearchScreen(),
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
      case '/arc-create-trade-listing':
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
      case '/arc-my-trade-listings':
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
          builder: (_) => const TradingNotificationsScreen(),
          settings: settings,
        );

      case TradingProfileScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const FeatureAccessRouteGate(
            flag: FeatureAccessFlag.traderHub,
            title: 'Raider Profile',
            child: TradingProfileScreen(),
          ),
          settings: settings,
        );

      case WallOfLegendsScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const FeatureAccessRouteGate(
            flag: FeatureAccessFlag.traderHub,
            title: 'Wall of Legends',
            child: WallOfLegendsScreen(),
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

      case ArcAdminMapEditorScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const ArcAdminMapEditorScreen(),
          settings: settings,
        );

      case ArcMapFilterIconReviewScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => const ArcMapFilterIconReviewScreen(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const AuthLandingScreen(),
          settings: settings,
        );
    }
  }
}

class _DirectOnboardingRouteGate extends StatelessWidget {
  const _DirectOnboardingRouteGate({required this.settings});

  final RouteSettings settings;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return ArcMandatoryOnboardingScreen.fromRouteSettings(settings);
        }

        final args = settings.arguments;
        final adminPreview = args is Map && args['adminPreview'] == true;
        if (adminPreview) {
          return ArcMandatoryOnboardingScreen.fromRouteSettings(settings);
        }

        // Signed-in users always re-enter through the single production gate.
        // That gate decides onboarding -> profile -> availability -> Hub.
        return const AppEntryGate();
      },
    );
  }
}

class _UAGTradersHubAppState extends State<UAGTradersHubApp>
    with WidgetsBindingObserver {
  ArcOperationsRepository? _operationsRepository;
  StreamSubscription<User?>? _authSubscription;
  Timer? _sessionHeartbeat;
  String? _sessionUid;
  String? _sessionId;
  DateTime? _lastSessionDurationRecordedAt;

  @override
  void initState() {
    super.initState();
    if (!widget.testMode) {
      _operationsRepository = ArcOperationsRepository();
      WidgetsBinding.instance.addObserver(this);
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
        _handleSessionUser,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    _sessionHeartbeat?.cancel();
    unawaited(_flushSessionDuration());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.testMode) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      unawaited(_flushSessionDuration());
      return;
    }
    if (state == AppLifecycleState.resumed && _sessionUid != null) {
      _lastSessionDurationRecordedAt = DateTime.now();
    }
  }

  void _handleSessionUser(User? user) {
    if (user == null) {
      _stopSessionTracking();
      return;
    }
    if (_sessionUid == user.uid) return;

    _stopSessionTracking();
    final now = DateTime.now();
    _sessionUid = user.uid;
    unawaited(
      UagCreatorReferralBootstrap.instance.captureForSignedInUser(user.uid),
    );
    _sessionId = '${user.uid}-${now.toUtc().millisecondsSinceEpoch}';
    _lastSessionDurationRecordedAt = now;
    final operationsRepository = _operationsRepository;
    if (operationsRepository != null) {
      unawaited(
        operationsRepository.recordSessionStarted(sessionId: _sessionId),
      );
    }
    _sessionHeartbeat = Timer.periodic(
      const Duration(minutes: 1),
      (_) => unawaited(_flushSessionDuration()),
    );
  }

  void _stopSessionTracking() {
    _sessionHeartbeat?.cancel();
    _sessionHeartbeat = null;
    unawaited(_flushSessionDuration());
    _sessionUid = null;
    _sessionId = null;
    _lastSessionDurationRecordedAt = null;
  }

  Future<void> _flushSessionDuration() async {
    final uid = _sessionUid;
    final lastRecordedAt = _lastSessionDurationRecordedAt;
    if (uid == null || lastRecordedAt == null) return;

    final now = DateTime.now();
    final duration = now.difference(lastRecordedAt);
    if (duration.inSeconds < 5) return;

    _lastSessionDurationRecordedAt = now;
    final operationsRepository = _operationsRepository;
    if (operationsRepository == null) return;

    await operationsRepository.recordSessionDuration(
      duration,
      sessionId: _sessionId,
    );
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
      navigatorKey: widget.testMode
          ? null
          : TradingPushService.instance.navigatorKey,
      navigatorObservers: widget.testMode
          ? const <NavigatorObserver>[]
          : <NavigatorObserver>[UagAdNavigationObserver.instance],
      onGenerateRoute: widget._buildRoute,
      // PASS 343: AppEntryGate is the single production entry authority.
      // Test mode stays Firebase-independent for widget smoke tests.
      home: widget.testMode ? const AuthLandingScreen() : const AppEntryGate(),
    );
  }
}
