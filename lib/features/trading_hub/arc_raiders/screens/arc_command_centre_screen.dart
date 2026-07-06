import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/build/app_drawer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_command_centre_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_trade_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_nomadic_trader_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_operations_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_notification.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_offer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_session.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_nomadic_trader_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_scrappy_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/trading_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/my_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/nomadic_trader_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/operations_command_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/smart_trade_assist_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/command_centre/arc_command_centre_content.dart';
import 'package:uag_arc_raiders_hub/screens/build/app_bar.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcCommandCentreScreen extends StatefulWidget {
  const ArcCommandCentreScreen({super.key});

  static const routeName = '/trading-hub/arc-raiders/command-centre';

  @override
  State<ArcCommandCentreScreen> createState() => _ArcCommandCentreScreenState();
}

class _ArcCommandCentreScreenState extends State<ArcCommandCentreScreen> {
  final ArcBlueprintRepository _blueprintRepository = ArcBlueprintRepository();
  final ArcSavedLoadoutRepository _loadoutRepository =
      ArcSavedLoadoutRepository();
  final ArcOperationsRepository _operationsRepository =
      ArcOperationsRepository();
  final ArcScrappyRepository _scrappyRepository = ArcScrappyRepository();
  final ArcNomadicTraderRepository _nomadicTraderRepository =
      const ArcNomadicTraderRepository();
  final TradingRepository _tradingRepository = TradingRepository();
  final ArcTradeIntelligenceEngine _tradeIntelligenceEngine =
      const ArcTradeIntelligenceEngine();
  late final Stream<Map<String, ArcBlueprintState>> _blueprintStatesStream =
      _blueprintRepository.watchMyBlueprintStates();
  late final Stream<List<ArcSavedLoadout>> _loadoutsStream = _loadoutRepository
      .watchSavedLoadouts();
  late final Stream<ArcOperationsUserState> _operationsStateStream =
      _operationsRepository.watchUserState();
  late final Stream<Map<String, ArcScrappyState>> _scrappyStatesStream =
      _scrappyRepository.watchMyScrappyStates();
  late final Stream<List<TradingListing>> _activeListingsStream =
      _tradingRepository.watchActiveListings();
  late final Stream<List<TradingListing>> _myListingsStream = _tradingRepository
      .watchMyListings();
  late final Stream<List<TradingOffer>> _myOffersStream = _tradingRepository
      .watchMyOffers();
  late final Stream<List<TradingSession>> _mySessionsStream = _tradingRepository
      .watchMySessions();
  late final Stream<List<TradingNotification>> _notificationsStream =
      _tradingRepository.watchNotifications();
  late Future<ArcNomadicTraderTrackerSnapshot> _nomadicTraderSnapshotFuture =
      _nomadicTraderRepository.loadTrackerSnapshot();
  final Map<String, bool> _checklistState = <String, bool>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: const UagAppBar(
        title: 'Command Centre',
        subtitle: 'Your next ARC Raiders move',
        showLogout: true,
      ),
      drawer: const AppDrawer(),
      body: ArcRaidersScreenShell(
        showAdBanner: true,
        child: _buildLiveCommandCentre(),
      ),
    );
  }

  void _handleAction(ArcCommandAction action) {
    switch (action.intent) {
      case ArcCommandActionIntent.route:
        final routeName = action.routeName;
        if (routeName == null || routeName.isEmpty) {
          _showPlaceholder(action);
          return;
        }
        Navigator.of(context).pushNamed(routeName);
      case ArcCommandActionIntent.favouriteLoadout:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FavouriteLoadoutScreen()),
        );
      case ArcCommandActionIntent.toolDeck:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MyHubScreen()));
      case ArcCommandActionIntent.smartTrade:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SmartTradeAssistScreen()),
        );
      case ArcCommandActionIntent.nomadicTrader:
        _openNomadicTrader();
      case ArcCommandActionIntent.operations:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const OperationsCommandScreen()),
        );
      case ArcCommandActionIntent.placeholder:
        _showPlaceholder(action);
    }
  }

  Future<void> _openNomadicTrader() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NomadicTraderScreen()));
    if (!mounted) return;
    setState(() {
      _nomadicTraderSnapshotFuture = _nomadicTraderRepository
          .loadTrackerSnapshot();
    });
  }

  void _showPlaceholder(ArcCommandAction action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          action.placeholderMessage ??
              '${action.label} will come online in a later Command Centre pass.',
          style: AppTheme.bodyTextStyle(fontSize: 12, color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildLiveCommandCentre() {
    return StreamBuilder<Map<String, ArcBlueprintState>>(
      stream: _blueprintStatesStream,
      builder: (context, blueprintSnapshot) {
        final blueprintStates =
            blueprintSnapshot.data ?? <String, ArcBlueprintState>{};
        return StreamBuilder<List<ArcSavedLoadout>>(
          stream: _loadoutsStream,
          builder: (context, loadoutSnapshot) {
            final loadouts = loadoutSnapshot.data ?? const <ArcSavedLoadout>[];
            return StreamBuilder<ArcOperationsUserState>(
              stream: _operationsStateStream,
              builder: (context, operationsSnapshot) {
                final operationsState =
                    operationsSnapshot.data ?? ArcOperationsUserState.empty;
                return StreamBuilder<Map<String, ArcScrappyState>>(
                  stream: _scrappyStatesStream,
                  builder: (context, scrappySnapshot) {
                    final scrappyStates =
                        scrappySnapshot.data ?? <String, ArcScrappyState>{};
                    return FutureBuilder<ArcNomadicTraderTrackerSnapshot>(
                      future: _nomadicTraderSnapshotFuture,
                      builder: (context, traderSnapshot) {
                        final nomadicTraderTracker =
                            traderSnapshot.data ??
                            ArcNomadicTraderTrackerSnapshot.empty;
                        return _buildWithTradeActivity(
                          blueprintStates: blueprintStates,
                          loadouts: loadouts,
                          operationsState: operationsState,
                          scrappyStates: scrappyStates,
                          nomadicTraderTracker: nomadicTraderTracker,
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildWithTradeActivity({
    required Map<String, ArcBlueprintState> blueprintStates,
    required List<ArcSavedLoadout> loadouts,
    required ArcOperationsUserState operationsState,
    required Map<String, ArcScrappyState> scrappyStates,
    required ArcNomadicTraderTrackerSnapshot nomadicTraderTracker,
  }) {
    return StreamBuilder<List<TradingListing>>(
      stream: _activeListingsStream,
      builder: (context, activeListingsSnapshot) {
        final activeListings =
            activeListingsSnapshot.data ?? const <TradingListing>[];
        return StreamBuilder<List<TradingListing>>(
          stream: _myListingsStream,
          builder: (context, myListingsSnapshot) {
            final myListings =
                myListingsSnapshot.data ?? const <TradingListing>[];
            return StreamBuilder<List<TradingOffer>>(
              stream: _myOffersStream,
              builder: (context, offersSnapshot) {
                final offers = offersSnapshot.data ?? const <TradingOffer>[];
                return StreamBuilder<List<TradingSession>>(
                  stream: _mySessionsStream,
                  builder: (context, sessionsSnapshot) {
                    final sessions =
                        sessionsSnapshot.data ?? const <TradingSession>[];
                    return StreamBuilder<List<TradingNotification>>(
                      stream: _notificationsStream,
                      builder: (context, notificationsSnapshot) {
                        final notifications =
                            notificationsSnapshot.data ??
                            const <TradingNotification>[];
                        final tradeActivity = _tradeActivityFrom(
                          blueprintStates: blueprintStates,
                          activeListings: activeListings,
                          myListings: myListings,
                          offers: offers,
                          sessions: sessions,
                          notifications: notifications,
                        );
                        final commandState = ArcCommandCentreEngine.build(
                          blueprintStates: blueprintStates,
                          savedLoadouts: loadouts,
                          scrappyStates: scrappyStates,
                          nomadicTraderTracker: nomadicTraderTracker,
                          operationsState: operationsState,
                          tradeActivity: tradeActivity,
                        );
                        return ArcCommandCentreContent(
                          commandState: commandState,
                          checklistState: _checklistState,
                          onAction: _handleAction,
                          onChecklistChanged: _handleChecklistChanged,
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  ArcCommandTradeActivity _tradeActivityFrom({
    required Map<String, ArcBlueprintState> blueprintStates,
    required List<TradingListing> activeListings,
    required List<TradingListing> myListings,
    required List<TradingOffer> offers,
    required List<TradingSession> sessions,
    required List<TradingNotification> notifications,
  }) {
    final intelligence = _tradeIntelligenceEngine.buildSummary(
      blueprintStates: blueprintStates,
      activeListings: activeListings,
      currentUid: _tradingRepository.currentUid,
    );
    final activeMyListings = myListings.where((listing) => listing.isLive);
    final pendingOffers = offers.where(
      (offer) => offer.status == TradingOfferStatus.pending,
    );
    final acceptedOffers = offers.where(
      (offer) => offer.status == TradingOfferStatus.accepted,
    );
    final activeSessions = sessions.where(_sessionIsActive);
    final readySessions = sessions.where(
      (session) => session.status == TradingSessionStatus.ready,
    );
    final unreadNotifications = notifications.where(
      (notification) => !notification.read,
    );

    return ArcCommandTradeActivity(
      communityListings: activeListings.length,
      myListings: myListings.length,
      activeMyListings: activeMyListings.length,
      pendingOffers: pendingOffers.length,
      acceptedOffers: acceptedOffers.length,
      activeSessions: activeSessions.length,
      readySessions: readySessions.length,
      unreadNotifications: unreadNotifications.length,
      intelligenceMatches: intelligence.suggestions.length,
      bestIntelligenceConfidence: intelligence.bestConfidence,
      bestIntelligenceLabel: _bestIntelligenceLabel(intelligence),
    );
  }

  void _handleChecklistChanged(String id, bool value) {
    setState(() => _checklistState[id] = value);
  }

  String _bestIntelligenceLabel(ArcTradeIntelligenceSummary intelligence) {
    if (intelligence.suggestions.isEmpty) return '';
    return intelligence.suggestions.first.title;
  }

  bool _sessionIsActive(TradingSession session) {
    switch (session.status) {
      case TradingSessionStatus.pending:
      case TradingSessionStatus.scheduled:
      case TradingSessionStatus.ready:
        return true;
      case TradingSessionStatus.completed:
      case TradingSessionStatus.noShow:
      case TradingSessionStatus.betrayal:
      case TradingSessionStatus.cancelled:
        return false;
    }
  }
}
