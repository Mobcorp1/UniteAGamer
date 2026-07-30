import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/build/app_drawer.dart';
import 'package:uag_arc_raiders_hub/features/feature_access_gate.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_command_centre_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_expedition_state_manager.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_feature_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_profile_completion_evaluator.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_trade_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_watch.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_expedition_state_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_nomadic_trader_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_operations_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_progression_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_season_reset_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_listing_queue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_user_personalisation_profile.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_notification.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_offer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_session.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_nomadic_trader_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_scrappy_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_scrappy_repository_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_trader_profile_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/trading_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_beta_feedback_screen.dart';
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

class _ArcCommandCentreScreenState extends State<ArcCommandCentreScreen>
    with AutomaticKeepAliveClientMixin<ArcCommandCentreScreen> {
  final ArcBlueprintRepository _blueprintRepository = ArcBlueprintRepository();
  final ArcSavedLoadoutRepository _loadoutRepository =
      ArcSavedLoadoutRepository();
  final ArcTraderProfileRepository _profileRepository =
      ArcTraderProfileRepository();
  final ArcUserPersonalisationRepository _personalisationRepository =
      ArcUserPersonalisationRepository();
  final ArcOperationsRepository _operationsRepository =
      ArcOperationsRepository();
  final ArcProgressionRepository _progressionRepository =
      ArcProgressionRepository();
  final ArcScrappyRepository _scrappyRepository = ArcScrappyRepository();
  final ArcNomadicTraderRepository _nomadicTraderRepository =
      const ArcNomadicTraderRepository();
  final TradingRepository _tradingRepository = TradingRepository();
  final ArcExpeditionStateManager _expeditionStateManager =
      ArcExpeditionStateManager.instance;
  final ArcTradeIntelligenceEngine _tradeIntelligenceEngine =
      const ArcTradeIntelligenceEngine();
  late final Stream<ArcExpeditionStateSnapshot> _expeditionStateStream =
      _expeditionStateManager.watchState();
  late final Stream<Map<String, ArcBlueprintState>> _blueprintStatesStream =
      _blueprintRepository.watchMyBlueprintStates();
  late final Stream<List<ArcSavedLoadout>> _loadoutsStream = _loadoutRepository
      .watchSavedLoadouts();
  late final Stream<ArcOperationsUserState> _operationsStateStream =
      _operationsRepository.watchUserState();
  late final Stream<ArcScrappyRepositoryState<Map<String, ArcScrappyState>>>
  _scrappyStatesStream = _scrappyRepository.watchMyScrappyStates();
  late final Stream<ArcProgressionRecords> _progressionRecordsStream =
      _progressionRepository.watchProgressionRecords();
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
  late final Stream<List<ArcBlueprintWatch>> _blueprintWatchesStream =
      _tradingRepository.watchBlueprintWatches();
  late final Stream<List<ArcTradeListingQueueItem>> _listingQueuesStream =
      _tradingRepository.watchListingQueues();
  late final Stream<ArcProfileCompletionResult> _profileCompletionStream =
      _profileRepository.watchProfileCompletion();
  late final Stream<ArcUserPersonalisationProfile> _personalisationStream =
      _personalisationRepository.watchProfile();
  late Future<ArcNomadicTraderTrackerSnapshot> _nomadicTraderSnapshotFuture =
      _nomadicTraderRepository.loadTrackerSnapshot();
  final Map<String, bool> _checklistState = <String, bool>{};
  Map<String, ArcBlueprintState> _cachedBlueprintStates =
      <String, ArcBlueprintState>{};
  List<ArcSavedLoadout> _cachedLoadouts = const <ArcSavedLoadout>[];
  ArcOperationsUserState _cachedOperationsState = ArcOperationsUserState.empty;
  ArcScrappyRepositoryState<Map<String, ArcScrappyState>> _cachedScrappyState =
      const ArcScrappyRepositoryState<Map<String, ArcScrappyState>>(
        status: ArcScrappyRepositoryStateStatus.restoring,
      );
  ArcProgressionRecords _cachedProgressionRecords = ArcProgressionRecords.empty;
  ArcNomadicTraderTrackerSnapshot _cachedNomadicTraderTracker =
      ArcNomadicTraderTrackerSnapshot.empty;
  List<TradingListing> _cachedActiveListings = const <TradingListing>[];
  List<TradingListing> _cachedMyListings = const <TradingListing>[];
  List<TradingOffer> _cachedOffers = const <TradingOffer>[];
  List<TradingSession> _cachedSessions = const <TradingSession>[];
  List<TradingNotification> _cachedNotifications =
      const <TradingNotification>[];
  List<ArcBlueprintWatch> _cachedBlueprintWatches = const <ArcBlueprintWatch>[];
  List<ArcTradeListingQueueItem> _cachedListingQueues =
      const <ArcTradeListingQueueItem>[];
  ArcProfileCompletionResult _cachedProfileCompletion =
      ArcProfileCompletionResult.completeResult;
  ArcUserPersonalisationProfile _cachedPersonalisation =
      ArcUserPersonalisationProfile.defaults;
  ArcExpeditionStateSnapshot _cachedExpeditionState =
      ArcExpeditionStateSnapshot.fromSeasonState(ArcSeasonState.initial());
  static ArcCommandCentreState? _lastCommandState;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    unawaited(_personalisationRepository.migrateLegacyIfNeeded());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const UagAppBar(
        title: 'Command Centre',
        subtitle: 'Your next ARC Raiders move',
        showLogout: true,
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'closed-beta-feedback',
        tooltip: 'Send closed-beta feedback',
        onPressed: () {
          Navigator.of(context).pushNamed(
            ArcBetaFeedbackScreen.routeName,
            arguments: const ArcBetaFeedbackScreenArgs(
              sourceRoute: ArcCommandCentreScreen.routeName,
            ),
          );
        },
        icon: const Icon(Icons.bug_report_rounded),
        label: const Text('Beta feedback'),
      ),
      body: ArcRaidersScreenShell(
        showAdBanner: true,
        child: KeyedSubtree(
          key: const PageStorageKey('arc-command-centre-shell'),
          child: _buildLiveCommandCentre(),
        ),
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
        final currentRoute = ModalRoute.of(context)?.settings.name;
        if (routeName == currentRoute ||
            routeName == ArcCommandCentreScreen.routeName) {
          return;
        }
        Navigator.of(context).pushNamed(routeName);
      case ArcCommandActionIntent.favouriteLoadout:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FavouriteLoadoutScreen()),
        );
      case ArcCommandActionIntent.toolDeck:
        Navigator.of(context).pushNamed(MyHubScreen.toolDeckRouteName);
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
      case ArcCommandActionIntent.comingSoon:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => FeatureComingSoonScreen(
              title: action.featureTitle ?? action.label,
              description: action.placeholderMessage,
            ),
          ),
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
              '${action.label} is not available in this beta build.',
          style: AppTheme.bodyTextStyle(fontSize: 12, color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildLiveCommandCentre() {
    return StreamBuilder<ArcUserPersonalisationProfile>(
      stream: _personalisationStream,
      builder: (context, personalisationSnapshot) {
        if (personalisationSnapshot.hasData) {
          _cachedPersonalisation = personalisationSnapshot.data!;
        }
        final personalisation = _cachedPersonalisation;
        final accessFlags = <String>{
          for (final entry in ArcFeatureRegistry.entries)
            if (entry.accessFlag != null) entry.accessFlag!,
        };
        return StreamBuilder<Map<String, FeatureAvailability>>(
          stream: FeatureAccess.watchAvailabilityMap(accessFlags),
          builder: (context, availabilitySnapshot) {
            final featureAvailability =
                availabilitySnapshot.data ??
                const <String, FeatureAvailability>{};
            return StreamBuilder<ArcExpeditionStateSnapshot>(
              stream: _expeditionStateStream,
              builder: (context, expeditionSnapshot) {
                if (expeditionSnapshot.hasData) {
                  _cachedExpeditionState = expeditionSnapshot.data!;
                }
                final expeditionState = _cachedExpeditionState;
                return StreamBuilder<ArcProfileCompletionResult>(
                  stream: _profileCompletionStream,
                  builder: (context, profileSnapshot) {
                    if (profileSnapshot.hasData) {
                      _cachedProfileCompletion = profileSnapshot.data!;
                    }
                    final profileCompletion = _cachedProfileCompletion;
                    return StreamBuilder<Map<String, ArcBlueprintState>>(
                      stream: _blueprintStatesStream,
                      builder: (context, blueprintSnapshot) {
                        if (blueprintSnapshot.hasData) {
                          _cachedBlueprintStates = blueprintSnapshot.data!;
                        }
                        final blueprintStates = _cachedBlueprintStates;
                        return StreamBuilder<List<ArcSavedLoadout>>(
                          stream: _loadoutsStream,
                          builder: (context, loadoutSnapshot) {
                            if (loadoutSnapshot.hasData) {
                              _cachedLoadouts = loadoutSnapshot.data!;
                            }
                            final loadouts = _cachedLoadouts;
                            return StreamBuilder<ArcOperationsUserState>(
                              stream: _operationsStateStream,
                              builder: (context, operationsSnapshot) {
                                if (operationsSnapshot.hasData) {
                                  _cachedOperationsState =
                                      operationsSnapshot.data!;
                                }
                                final operationsState = _cachedOperationsState;
                                return StreamBuilder<
                                  ArcScrappyRepositoryState<
                                    Map<String, ArcScrappyState>
                                  >
                                >(
                                  stream: _scrappyStatesStream,
                                  builder: (context, scrappySnapshot) {
                                    if (scrappySnapshot.hasData) {
                                      _cachedScrappyState =
                                          scrappySnapshot.data!;
                                    }
                                    final scrappyState = _cachedScrappyState;
                                    final scrappyStates =
                                        scrappyState.data ??
                                        const <String, ArcScrappyState>{};
                                    return StreamBuilder<ArcProgressionRecords>(
                                      stream: _progressionRecordsStream,
                                      builder: (context, progressionSnapshot) {
                                        if (progressionSnapshot.hasData) {
                                          _cachedProgressionRecords =
                                              progressionSnapshot.data!;
                                        }
                                        final progressionRecords =
                                            _cachedProgressionRecords;
                                        return FutureBuilder<
                                          ArcNomadicTraderTrackerSnapshot
                                        >(
                                          future: _nomadicTraderSnapshotFuture,
                                          builder: (context, traderSnapshot) {
                                            if (traderSnapshot.hasData) {
                                              _cachedNomadicTraderTracker =
                                                  traderSnapshot.data!;
                                            }
                                            final nomadicTraderTracker =
                                                _cachedNomadicTraderTracker;
                                            return _buildWithTradeActivity(
                                              expeditionState: expeditionState,
                                              blueprintStates: blueprintStates,
                                              loadouts: loadouts,
                                              operationsState: operationsState,
                                              scrappyStates: scrappyStates,
                                              progressionRecords:
                                                  progressionRecords,
                                              nomadicTraderTracker:
                                                  nomadicTraderTracker,
                                              profileCompletion:
                                                  profileCompletion,
                                              personalisation: personalisation,
                                              featureAvailability:
                                                  featureAvailability,
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
    required ArcExpeditionStateSnapshot expeditionState,
    required Map<String, ArcBlueprintState> blueprintStates,
    required List<ArcSavedLoadout> loadouts,
    required ArcOperationsUserState operationsState,
    required Map<String, ArcScrappyState> scrappyStates,
    required ArcProgressionRecords progressionRecords,
    required ArcNomadicTraderTrackerSnapshot nomadicTraderTracker,
    required ArcProfileCompletionResult profileCompletion,
    required ArcUserPersonalisationProfile personalisation,
    required Map<String, FeatureAvailability> featureAvailability,
  }) {
    return StreamBuilder<List<TradingListing>>(
      stream: _activeListingsStream,
      builder: (context, activeListingsSnapshot) {
        if (activeListingsSnapshot.hasData) {
          _cachedActiveListings = activeListingsSnapshot.data!;
        }
        final activeListings = _cachedActiveListings;
        return StreamBuilder<List<TradingListing>>(
          stream: _myListingsStream,
          builder: (context, myListingsSnapshot) {
            if (myListingsSnapshot.hasData) {
              _cachedMyListings = myListingsSnapshot.data!;
            }
            final myListings = _cachedMyListings;
            return StreamBuilder<List<TradingOffer>>(
              stream: _myOffersStream,
              builder: (context, offersSnapshot) {
                if (offersSnapshot.hasData) {
                  _cachedOffers = offersSnapshot.data!;
                }
                final offers = _cachedOffers;
                return StreamBuilder<List<TradingSession>>(
                  stream: _mySessionsStream,
                  builder: (context, sessionsSnapshot) {
                    if (sessionsSnapshot.hasData) {
                      _cachedSessions = sessionsSnapshot.data!;
                    }
                    final sessions = _cachedSessions;
                    return StreamBuilder<List<TradingNotification>>(
                      stream: _notificationsStream,
                      builder: (context, notificationsSnapshot) {
                        if (notificationsSnapshot.hasData) {
                          _cachedNotifications = notificationsSnapshot.data!;
                        }
                        final notifications = _cachedNotifications;
                        return StreamBuilder<List<ArcBlueprintWatch>>(
                          stream: _blueprintWatchesStream,
                          builder: (context, watchesSnapshot) {
                            if (watchesSnapshot.hasData) {
                              _cachedBlueprintWatches = watchesSnapshot.data!;
                            }
                            final watches = _cachedBlueprintWatches;
                            return StreamBuilder<
                              List<ArcTradeListingQueueItem>
                            >(
                              stream: _listingQueuesStream,
                              builder: (context, queuesSnapshot) {
                                if (queuesSnapshot.hasData) {
                                  _cachedListingQueues = queuesSnapshot.data!;
                                }
                                final queues = _cachedListingQueues;
                                final tradeActivity = _tradeActivityFrom(
                                  blueprintStates: blueprintStates,
                                  activeListings: activeListings,
                                  myListings: myListings,
                                  offers: offers,
                                  sessions: sessions,
                                  notifications: notifications,
                                  watches: watches,
                                  queues: queues,
                                );
                                final commandState =
                                    ArcCommandCentreEngine.build(
                                      blueprintStates: blueprintStates,
                                      savedLoadouts: loadouts,
                                      scrappyStates: scrappyStates,
                                      nomadicTraderTracker:
                                          nomadicTraderTracker,
                                      operationsState: operationsState,
                                      tradeActivity: tradeActivity,
                                      profileCompletion: profileCompletion,
                                      progressionRecords: progressionRecords,
                                      personalisation: personalisation,
                                      featureAvailability: featureAvailability,
                                    );
                                _lastCommandState = commandState;
                                return _buildResilientContent(
                                  expeditionState: expeditionState,
                                  commandState:
                                      _lastCommandState ?? commandState,
                                  scrappyState: _cachedScrappyState,
                                  profileCompletion: profileCompletion,
                                  operationsState: operationsState,
                                  blueprintStates: blueprintStates,
                                  loadouts: loadouts,
                                  progressionRecords: progressionRecords,
                                  nomadicTraderTracker: nomadicTraderTracker,
                                  tradeActivity: tradeActivity,
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
          },
        );
      },
    );
  }

  Widget _buildResilientContent({
    required ArcExpeditionStateSnapshot expeditionState,
    required ArcCommandCentreState commandState,
    required ArcScrappyRepositoryState<Map<String, ArcScrappyState>>
    scrappyState,
    required ArcProfileCompletionResult profileCompletion,
    required ArcOperationsUserState operationsState,
    required Map<String, ArcBlueprintState> blueprintStates,
    required List<ArcSavedLoadout> loadouts,
    required ArcProgressionRecords progressionRecords,
    required ArcNomadicTraderTrackerSnapshot nomadicTraderTracker,
    required ArcCommandTradeActivity tradeActivity,
  }) {
    if (scrappyState.status == ArcScrappyRepositoryStateStatus.error) {
      return ArcCommandCentreContent(
        expeditionState: expeditionState,
        commandState: commandState,
        checklistState: _checklistState,
        onAction: _handleAction,
        onChecklistChanged: _handleChecklistChanged,
        fallbackNotice:
            'Scrappy tracking is temporarily unavailable. Your Command Centre remains usable and will retry automatically.',
      );
    }

    if (scrappyState.status ==
            ArcScrappyRepositoryStateStatus.unauthenticated ||
        scrappyState.status == ArcScrappyRepositoryStateStatus.restoring) {
      return ArcCommandCentreContent(
        expeditionState: expeditionState,
        commandState: commandState,
        checklistState: _checklistState,
        onAction: _handleAction,
        onChecklistChanged: _handleChecklistChanged,
        fallbackNotice:
            'Restoring your account state… the Command Centre will appear as soon as your tracker data is ready.',
      );
    }

    return ArcCommandCentreContent(
      expeditionState: expeditionState,
      commandState: commandState,
      checklistState: _checklistState,
      onAction: _handleAction,
      onChecklistChanged: _handleChecklistChanged,
    );
  }

  ArcCommandTradeActivity _tradeActivityFrom({
    required Map<String, ArcBlueprintState> blueprintStates,
    required List<TradingListing> activeListings,
    required List<TradingListing> myListings,
    required List<TradingOffer> offers,
    required List<TradingSession> sessions,
    required List<TradingNotification> notifications,
    required List<ArcBlueprintWatch> watches,
    required List<ArcTradeListingQueueItem> queues,
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
    final activeWatches = watches.where((watch) => watch.active);
    final matchedWatches = activeWatches.where(
      (watch) => _watchHasLiveMatch(watch, activeListings),
    );
    final activeQueues = queues.where((queue) => !queue.isTerminal);
    final releasableQueues = activeQueues.where(
      (queue) => _queueCanRelease(queue, myListings, blueprintStates),
    );
    final blockedQueues = activeQueues.where(
      (queue) =>
          queue.isBlocked || _queueIsOwnershipBlocked(queue, blueprintStates),
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
      activeBlueprintWatches: activeWatches.length,
      matchedBlueprintWatches: matchedWatches.length,
      activeListingQueues: activeQueues.length,
      releasableListingQueues: releasableQueues.length,
      blockedListingQueues: blockedQueues.length,
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

  bool _watchHasLiveMatch(
    ArcBlueprintWatch watch,
    List<TradingListing> activeListings,
  ) {
    final watchId = _normalizeBlueprintText(watch.blueprintId);
    final watchName = _normalizeBlueprintText(watch.displayName);
    return activeListings.any(
      (listing) =>
          listing.isLive &&
          listing.offeredBlueprintNames.any((name) {
            final normalized = _normalizeBlueprintText(name);
            return normalized == watchId || normalized == watchName;
          }),
    );
  }

  bool _queueCanRelease(
    ArcTradeListingQueueItem queue,
    List<TradingListing> myListings,
    Map<String, ArcBlueprintState> blueprintStates,
  ) {
    if (!queue.canManuallyRelease) return false;
    final activeListing = _activeListingForQueue(queue, myListings);
    if (activeListing != null &&
        activeListing.active &&
        activeListing.expiresAt.isAfter(DateTime.now())) {
      return false;
    }
    return !_queueIsOwnershipBlocked(queue, blueprintStates);
  }

  bool _queueIsOwnershipBlocked(
    ArcTradeListingQueueItem queue,
    Map<String, ArcBlueprintState> blueprintStates,
  ) {
    final state =
        blueprintStates[queue.blueprintId] ??
        ArcBlueprintState.empty(queue.blueprintId);
    return queue.hasRemaining && state.dupesOwned < queue.releasedQuantity + 1;
  }

  TradingListing? _activeListingForQueue(
    ArcTradeListingQueueItem queue,
    List<TradingListing> myListings,
  ) {
    final activeId = queue.activeListingId.trim().isEmpty
        ? queue.sourceListingId
        : queue.activeListingId.trim();
    for (final listing in myListings) {
      if (listing.id == activeId) return listing;
    }
    return null;
  }

  String _normalizeBlueprintText(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}
