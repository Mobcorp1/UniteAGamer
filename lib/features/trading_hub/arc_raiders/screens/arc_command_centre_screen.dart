import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/build/app_drawer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_command_centre_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_trade_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_operations_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_notification.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_offer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_session.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
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
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/command_centre/arc_command_centre_widgets.dart';
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
  final Map<String, bool> _checklistState = <String, bool>{};

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
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const NomadicTraderScreen()));
      case ArcCommandActionIntent.operations:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const OperationsCommandScreen()),
        );
      case ArcCommandActionIntent.placeholder:
        _showPlaceholder(action);
    }
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
                    return _buildWithTradeActivity(
                      blueprintStates: blueprintStates,
                      loadouts: loadouts,
                      operationsState: operationsState,
                      scrappyStates: scrappyStates,
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
                          operationsState: operationsState,
                          tradeActivity: tradeActivity,
                        );
                        return _commandCentreContent(commandState);
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

  Widget _commandCentreContent(ArcCommandCentreState commandState) {
    final compactSnapshots = _compactSnapshots(commandState.snapshots);
    final topObjectives = commandState.objectives.take(3).toList();
    final topAlerts = commandState.alerts.take(3).toList();
    final topRecommendations = commandState.recommendations.take(3).toList();
    final moreObjectives = commandState.objectives.skip(3).toList();
    final moreAlerts = commandState.alerts.skip(3).toList();
    final moreRecommendations = commandState.recommendations.skip(3).toList();
    final hasTradeSignal = _hasTradeSignal(commandState.tradeSummary);
    final moreCommandDetail = <Widget>[
      if (moreObjectives.isNotEmpty) _objectives(moreObjectives),
      if (moreAlerts.isNotEmpty) _alerts(moreAlerts),
      if (moreRecommendations.isNotEmpty) _recommendations(moreRecommendations),
    ];
    final systemDetailPanels = <Widget>[
      _summaryPanel(commandState.blueprintSummary),
      _summaryPanel(commandState.operationsSummary),
      _summaryPanel(commandState.questSummary),
      _summaryPanel(commandState.benchSummary),
      _resourceSummary(commandState.resources),
      _summaryPanel(commandState.weeklyTraderSummary),
      _summaryPanel(commandState.communitySummary),
      _summaryPanel(commandState.statisticsSummary),
      _dailyChecklist(commandState.checklist),
    ];

    return ArcRaidersPageList(
      maxWidth: 1220,
      bottomPadding: 68,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      children: [
        _priorityHero(commandState.priority),
        if (compactSnapshots.isNotEmpty) ...[
          const SizedBox(height: 6),
          _snapshotGrid(compactSnapshots),
        ],
        const SizedBox(height: 6),
        _nextActions(topObjectives),
        if (topAlerts.isNotEmpty) ...[
          const SizedBox(height: 6),
          _compactAlerts(topAlerts),
        ],
        if (hasTradeSignal) ...[
          const SizedBox(height: 6),
          _compactTradeSummary(commandState.tradeSummary),
        ],
        const SizedBox(height: 6),
        _compactSystemSummaries(commandState),
        if (topRecommendations.isNotEmpty) ...[
          const SizedBox(height: 6),
          _detailAccordion(
            title: 'Optional Smart Picks',
            subtitle: 'Top recommendations when you want a second opinion.',
            accent: Colors.amberAccent,
            children: [_compactRecommendations(topRecommendations)],
          ),
        ],
        const SizedBox(height: 6),
        _toolDeckPanel(),
        if (moreCommandDetail.isNotEmpty) ...[
          const SizedBox(height: 6),
          _detailAccordion(
            title: 'Optional Command Detail',
            subtitle: 'More objectives, alerts and recommendations.',
            accent: AppTheme.neonCyan,
            children: moreCommandDetail,
          ),
        ],
        const SizedBox(height: 6),
        _detailAccordion(
          title: 'Optional System Detail',
          subtitle: 'Expanded summaries and lower-priority status cards.',
          accent: AppTheme.neonPink,
          children: systemDetailPanels,
        ),
      ],
    );
  }

  List<ArcCommandSnapshotMetric> _compactSnapshots(
    List<ArcCommandSnapshotMetric> snapshots,
  ) {
    const preferred = <String>{
      'Operations',
      'Quest',
      'Bench',
      'Blueprints',
      'Favourite Loadout',
      'Trade Activity',
      'Reward Vault',
      'Inventory',
    };
    final selected = snapshots
        .where((metric) => preferred.contains(metric.label))
        .take(4)
        .toList(growable: false);
    if (selected.length >= 4) return selected;
    return snapshots.take(4).toList(growable: false);
  }

  Widget _nextActions(List<ArcCommandObjective> objectives) {
    return ArcCommandCentreCard(
      accent: AppTheme.neonCyan,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ArcCommandSectionHeader(
            title: 'Next 3 Actions',
            subtitle: 'The shortest path from current state to useful action.',
            accent: AppTheme.neonCyan,
          ),
          const SizedBox(height: 8),
          if (objectives.isEmpty)
            _quietLine('No active objective needs attention.')
          else
            for (final objective in objectives) ...[
              _compactObjectiveRow(objective),
              if (objective != objectives.last) const SizedBox(height: 6),
            ],
        ],
      ),
    );
  }

  Widget _compactObjectiveRow(ArcCommandObjective objective) {
    final accent = arcCommandStatusAccent(objective.status);
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 460;
        final action = ArcCommandActionButton(
          action: objective.action,
          accent: accent,
          compact: true,
          onPressed: () => _handleAction(objective.action),
        );
        final summary = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    objective.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyTextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      isBold: true,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                ArcCommandStatusPill(
                  label: objective.statusLabel,
                  status: objective.status,
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              objective.progressText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyTextStyle(
                fontSize: 10,
                color: Colors.white54,
              ),
            ),
          ],
        );

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: _innerDecoration(accent),
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _statusIcon(objective.status),
                          color: accent,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: summary),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(alignment: Alignment.centerLeft, child: action),
                  ],
                )
              : Row(
                  children: [
                    Icon(
                      _statusIcon(objective.status),
                      color: accent,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: summary),
                    const SizedBox(width: 8),
                    action,
                  ],
                ),
        );
      },
    );
  }

  Widget _compactRecommendations(
    List<ArcCommandRecommendation> recommendations,
  ) {
    return ArcCommandCentreCard(
      accent: Colors.amberAccent,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ArcCommandSectionHeader(
            title: 'Smart Picks',
            subtitle: 'Top recommendations only.',
            accent: Colors.amberAccent,
          ),
          const SizedBox(height: 8),
          if (recommendations.isEmpty)
            _quietLine('No recommendation is waiting.')
          else
            for (final recommendation in recommendations) ...[
              _compactRecommendationRow(recommendation),
              if (recommendation != recommendations.last)
                const SizedBox(height: 6),
            ],
        ],
      ),
    );
  }

  Widget _compactRecommendationRow(ArcCommandRecommendation recommendation) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 420;
        final action = ArcCommandActionButton(
          action: recommendation.action,
          accent: Colors.amberAccent,
          compact: true,
          onPressed: () => _handleAction(recommendation.action),
        );
        final title = Row(
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.amberAccent,
              size: 15,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                recommendation.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyTextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  isBold: true,
                ),
              ),
            ),
          ],
        );
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: _innerDecoration(Colors.amberAccent),
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 6), action],
                )
              : Row(
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: 8),
                    action,
                  ],
                ),
        );
      },
    );
  }

  Widget _compactAlerts(List<ArcCommandAlert> alerts) {
    return ArcCommandCentreCard(
      accent: AppTheme.neonPink,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ArcCommandSectionHeader(
            title: 'Alerts / Blockers',
            subtitle: 'Only the top blockers are shown here.',
            accent: AppTheme.neonPink,
          ),
          const SizedBox(height: 8),
          for (final alert in alerts) ...[
            _compactAlertRow(alert),
            if (alert != alerts.last) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _compactAlertRow(ArcCommandAlert alert) {
    final accent = arcCommandStatusAccent(alert.status);
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 480;
        final action = ArcCommandActionButton(
          action: alert.action,
          accent: accent,
          compact: true,
          onPressed: () => _handleAction(alert.action),
        );
        final summary = Row(
          children: [
            Icon(_statusIcon(alert.status), color: accent, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                alert.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyTextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  isBold: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ArcCommandStatusPill(
              label: alert.statusLabel,
              status: alert.status,
            ),
          ],
        );
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: _innerDecoration(accent),
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [summary, const SizedBox(height: 6), action],
                )
              : Row(
                  children: [
                    Expanded(child: summary),
                    const SizedBox(width: 8),
                    action,
                  ],
                ),
        );
      },
    );
  }

  Widget _compactTradeSummary(ArcCommandTradeSummary summary) {
    return ArcCommandCentreCard(
      accent: AppTheme.neonPink,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ArcCommandSectionHeader(
            title: 'Trade Opportunity',
            subtitle: 'Compact read of what to ask for and offer.',
            accent: AppTheme.neonPink,
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final looking = _compactTradeLane(
                'Looking For',
                summary.lookingFor,
                AppTheme.neonCyan,
              );
              final offering = _compactTradeLane(
                'Offering',
                summary.offering,
                Colors.amberAccent,
              );
              if (compact) {
                return Column(
                  children: [looking, const SizedBox(height: 6), offering],
                );
              }
              return Row(
                children: [
                  Expanded(child: looking),
                  const SizedBox(width: 8),
                  Expanded(child: offering),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final action in summary.actions.take(2))
                ArcCommandActionButton(
                  action: action,
                  accent: AppTheme.neonPink,
                  compact: true,
                  onPressed: () => _handleAction(action),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _compactTradeLane(String title, List<String> items, Color accent) {
    final visible = items.take(3).toList(growable: false);
    final chips = Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (visible.isEmpty)
          ArcCommandStatusPill(
            label: 'No signal',
            status: ArcCommandStatus.neutral,
          )
        else
          for (final item in visible)
            ArcCommandStatusPill(label: item, status: ArcCommandStatus.neutral),
      ],
    );
    final label = Text(
      title.toUpperCase(),
      style: AppTheme.bodyTextStyle(fontSize: 10, color: accent, isBold: true),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 380;
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: _innerDecoration(accent),
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [label, const SizedBox(height: 6), chips],
                )
              : Row(
                  children: [
                    label,
                    const SizedBox(width: 8),
                    Expanded(child: chips),
                  ],
                ),
        );
      },
    );
  }

  bool _hasTradeSignal(ArcCommandTradeSummary summary) {
    return summary.lookingFor.any(_isUsefulSignal) ||
        summary.offering.any(_isUsefulSignal);
  }

  bool _isUsefulSignal(String value) {
    final normalized = value.toLowerCase();
    return !normalized.contains('not tracked') &&
        !normalized.contains('no signal') &&
        !normalized.contains('no duplicate') &&
        !normalized.contains('coming online');
  }

  bool _summaryHasUsefulSignal(ArcCommandSummaryPanel panel) {
    if (panel.status != ArcCommandStatus.neutral) return true;
    return panel.details.any(_isUsefulSummaryDetail);
  }

  String _summaryDetail(ArcCommandSummaryPanel panel) {
    for (final detail in panel.details) {
      if (_isUsefulSummaryDetail(detail)) {
        return detail;
      }
    }
    return panel.details.isEmpty ? panel.body : panel.details.first;
  }

  bool _isUsefulSummaryDetail(String value) {
    return _isUsefulSignal(value) && !value.toLowerCase().contains('open ');
  }

  List<Widget> _compactSystemSummaryTiles(ArcCommandCentreState commandState) {
    final loadout = _snapshotByLabel(
      commandState.snapshots,
      'Favourite Loadout',
    );
    return [
      _summaryTile(commandState.blueprintSummary),
      _metricSummaryTile(
        title: 'Favourite Loadout',
        statusLabel: loadout?.value ?? 'Unknown',
        detail: loadout?.detail ?? 'Open loadout',
        status: loadout?.status ?? ArcCommandStatus.neutral,
        action: const ArcCommandAction(
          label: 'Open Loadout',
          intent: ArcCommandActionIntent.favouriteLoadout,
        ),
      ),
      if (_summaryHasUsefulSignal(commandState.operationsSummary))
        _summaryTile(commandState.operationsSummary),
      if (_summaryHasUsefulSignal(commandState.benchSummary))
        _summaryTile(commandState.benchSummary),
      if (_summaryHasUsefulSignal(commandState.questSummary))
        _summaryTile(commandState.questSummary),
    ];
  }

  Widget _compactSystemSummaries(ArcCommandCentreState commandState) {
    final summaryTiles = _compactSystemSummaryTiles(commandState);
    return _responsiveGrid(
      minTileWidth: 240,
      spacing: 6,
      children: summaryTiles,
    );
  }

  ArcCommandSnapshotMetric? _snapshotByLabel(
    List<ArcCommandSnapshotMetric> snapshots,
    String label,
  ) {
    for (final snapshot in snapshots) {
      if (snapshot.label == label) return snapshot;
    }
    return null;
  }

  Widget _summaryTile(ArcCommandSummaryPanel panel) {
    return _metricSummaryTile(
      title: panel.title,
      statusLabel: panel.statusLabel,
      detail: _summaryDetail(panel),
      status: panel.status,
      action: panel.action,
    );
  }

  Widget _metricSummaryTile({
    required String title,
    required String statusLabel,
    required String detail,
    required ArcCommandStatus status,
    required ArcCommandAction action,
  }) {
    final accent = arcCommandStatusAccent(status);
    return ArcCommandCentreCard(
      accent: accent,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_statusIcon(status), color: accent, size: 16),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    isBold: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ArcCommandStatusPill(label: statusLabel, status: status),
          const SizedBox(height: 7),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyTextStyle(fontSize: 10, color: Colors.white54),
          ),
          const SizedBox(height: 8),
          ArcCommandActionButton(
            action: action,
            accent: accent,
            compact: true,
            onPressed: () => _handleAction(action),
          ),
        ],
      ),
    );
  }

  Widget _toolDeckPanel() {
    return _detailAccordion(
      title: 'Optional Tool Deck',
      subtitle: 'Legacy carousel and full tool launcher.',
      accent: AppTheme.neonCyan,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 460;
            final action = ArcCommandActionButton(
              action: const ArcCommandAction(
                label: 'Open Tool Deck',
                intent: ArcCommandActionIntent.toolDeck,
              ),
              accent: AppTheme.neonCyan,
              compact: true,
              onPressed: () => _handleAction(
                const ArcCommandAction(
                  label: 'Open Tool Deck',
                  intent: ArcCommandActionIntent.toolDeck,
                ),
              ),
            );
            final summary = Row(
              children: [
                const Icon(
                  Icons.view_carousel_rounded,
                  color: AppTheme.neonCyan,
                  size: 18,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Open the old carousel-style launcher when you want the full tool deck.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyTextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            );
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: _innerDecoration(AppTheme.neonCyan),
              child: narrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [summary, const SizedBox(height: 8), action],
                    )
                  : Row(
                      children: [
                        Expanded(child: summary),
                        const SizedBox(width: 8),
                        action,
                      ],
                    ),
            );
          },
        ),
      ],
    );
  }

  Widget _detailAccordion({
    required String title,
    required String subtitle,
    required Color accent,
    required List<Widget> children,
  }) {
    return ArcCommandCentreCard(
      accent: accent,
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          iconColor: accent,
          collapsedIconColor: Colors.white60,
          title: Row(
            children: [
              Icon(Icons.unfold_more_rounded, color: accent, size: 15),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.tradingHeading(fontSize: 14, color: accent),
                ),
              ),
            ],
          ),
          subtitle: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyTextStyle(fontSize: 11, color: Colors.white54),
          ),
          children: children.isEmpty
              ? [_quietLine('No additional detail is waiting.')]
              : [
                  for (final child in children) ...[
                    child,
                    if (child != children.last) const SizedBox(height: 8),
                  ],
                ],
        ),
      ),
    );
  }

  Widget _quietLine(String text) {
    return Text(
      text,
      style: AppTheme.bodyTextStyle(fontSize: 12, color: Colors.white54),
    );
  }

  Widget _priorityHero(ArcCommandPriority priority) {
    final accent = arcCommandStatusAccent(priority.status);
    return ArcCommandCentreCard(
      accent: accent,
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "TODAY'S MISSION",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyTextStyle(
                      fontSize: 10,
                      color: Colors.white54,
                      isBold: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ArcCommandStatusPill(
                    label: priority.statusTag,
                    status: priority.status,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_statusIcon(priority.status), color: accent, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          priority.title.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.tradingHeading(
                            fontSize: compact ? 21 : 27,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          priority.explanation,
                          maxLines: compact ? 3 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.bodyTextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            isBold: true,
                          ).copyWith(height: 1.28),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ArcCommandStatusPill(
                    label: priority.progressLabel,
                    status: ArcCommandStatus.neutral,
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                priority.detail,
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyTextStyle(
                  fontSize: 12,
                  color: Colors.white60,
                ),
              ),
            ],
          );

          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: compact ? WrapAlignment.start : WrapAlignment.end,
            children: [
              ArcCommandActionButton(
                action: priority.primaryAction,
                accent: accent,
                onPressed: () => _handleAction(priority.primaryAction),
              ),
              if (priority.secondaryAction != null)
                ArcCommandActionButton(
                  action: priority.secondaryAction!,
                  accent: AppTheme.neonCyan,
                  compact: true,
                  onPressed: () => _handleAction(priority.secondaryAction!),
                ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [content, const SizedBox(height: 12), actions],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: content),
              const SizedBox(width: 14),
              Flexible(child: actions),
            ],
          );
        },
      ),
    );
  }

  Widget _snapshotGrid(List<ArcCommandSnapshotMetric> snapshots) {
    return _responsiveGrid(
      minTileWidth: 150,
      spacing: 6,
      children: snapshots.map(_snapshotTile).toList(growable: false),
    );
  }

  Widget _snapshotTile(ArcCommandSnapshotMetric metric) {
    final accent = arcCommandStatusAccent(metric.status);
    return ArcCommandCentreCard(
      accent: accent,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Icon(_statusIcon(metric.status), color: accent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.tradingHeading(fontSize: 17, color: accent),
                ),
                Text(
                  metric.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 10,
                    color: Colors.white54,
                    isBold: true,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  metric.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 10,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _objectives(List<ArcCommandObjective> objectives) {
    return ArcCommandCentreCard(
      accent: AppTheme.neonCyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ArcCommandSectionHeader(
            title: 'Active Objectives',
            subtitle: 'Generated from the current command centre state.',
            accent: AppTheme.neonCyan,
          ),
          const SizedBox(height: 10),
          for (final objective in objectives) ...[
            _objectiveRow(objective),
            if (objective != objectives.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _objectiveRow(ArcCommandObjective objective) {
    final accent = arcCommandStatusAccent(objective.status);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _innerDecoration(accent),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_statusIcon(objective.status), color: accent, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        objective.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodyTextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          isBold: true,
                        ),
                      ),
                    ),
                    ArcCommandStatusPill(
                      label: objective.statusLabel,
                      status: objective.status,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  objective.reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 11,
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        objective.progressText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodyTextStyle(
                          fontSize: 10,
                          color: accent,
                          isBold: true,
                        ),
                      ),
                    ),
                    ArcCommandActionButton(
                      action: objective.action,
                      accent: accent,
                      compact: true,
                      onPressed: () => _handleAction(objective.action),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _alerts(List<ArcCommandAlert> alerts) {
    return ArcCommandCentreCard(
      accent: AppTheme.neonPink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ArcCommandSectionHeader(
            title: 'Inventory Alerts',
            subtitle: 'Blockers and setup warnings.',
            accent: AppTheme.neonPink,
          ),
          const SizedBox(height: 10),
          for (final alert in alerts) ...[
            _alertRow(alert),
            if (alert != alerts.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _alertRow(ArcCommandAlert alert) {
    final accent = arcCommandStatusAccent(alert.status);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _innerDecoration(accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_statusIcon(alert.status), color: accent, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    isBold: true,
                  ),
                ),
              ),
              ArcCommandStatusPill(
                label: alert.statusLabel,
                status: alert.status,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            alert.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyTextStyle(fontSize: 11, color: Colors.white60),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: ArcCommandActionButton(
              action: alert.action,
              accent: accent,
              compact: true,
              onPressed: () => _handleAction(alert.action),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryPanel(ArcCommandSummaryPanel panel) {
    final accent = arcCommandStatusAccent(panel.status);
    return ArcCommandCentreCard(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ArcCommandSectionHeader(
            title: panel.title,
            subtitle: panel.body,
            accent: accent,
            trailing: ArcCommandStatusPill(
              label: panel.statusLabel,
              status: panel.status,
            ),
          ),
          const SizedBox(height: 10),
          ArcCommandDetailList(details: panel.details),
          const SizedBox(height: 6),
          ArcCommandActionButton(
            action: panel.action,
            accent: accent,
            compact: true,
            onPressed: () => _handleAction(panel.action),
          ),
        ],
      ),
    );
  }

  Widget _resourceSummary(List<ArcCommandResourceStatus> resources) {
    return ArcCommandCentreCard(
      accent: Colors.lightGreenAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ArcCommandSectionHeader(
            title: 'Resource Summary',
            subtitle: 'Key resource readiness without fake stash counts.',
            accent: Colors.lightGreenAccent,
          ),
          const SizedBox(height: 10),
          for (final resource in resources) ...[
            _resourceRow(resource),
            if (resource != resources.last) const SizedBox(height: 7),
          ],
        ],
      ),
    );
  }

  Widget _resourceRow(ArcCommandResourceStatus resource) {
    final accent = arcCommandStatusAccent(resource.status);
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: _innerDecoration(accent),
      child: Row(
        children: [
          Icon(_statusIcon(resource.status), color: accent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              resource.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyTextStyle(
                fontSize: 12,
                color: Colors.white,
                isBold: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '${resource.ownedLabel} - ${resource.requiredLabel}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: AppTheme.bodyTextStyle(
                fontSize: 10,
                color: Colors.white54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recommendations(List<ArcCommandRecommendation> recommendations) {
    return ArcCommandCentreCard(
      accent: Colors.amberAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ArcCommandSectionHeader(
            title: 'Smart Recommendations',
            subtitle: 'Structured guidance from the phase 1 engine.',
            accent: Colors.amberAccent,
          ),
          const SizedBox(height: 10),
          for (final recommendation in recommendations) ...[
            _recommendationRow(recommendation),
            if (recommendation != recommendations.last)
              const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _recommendationRow(ArcCommandRecommendation recommendation) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _innerDecoration(Colors.amberAccent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recommendation.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyTextStyle(
              fontSize: 13,
              color: Colors.white,
              isBold: true,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            recommendation.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyTextStyle(fontSize: 11, color: Colors.white60),
          ),
          const SizedBox(height: 7),
          ArcCommandActionButton(
            action: recommendation.action,
            accent: Colors.amberAccent,
            compact: true,
            onPressed: () => _handleAction(recommendation.action),
          ),
        ],
      ),
    );
  }

  Widget _dailyChecklist(List<ArcCommandChecklistItem> checklist) {
    return ArcCommandCentreCard(
      accent: AppTheme.neonCyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ArcCommandSectionHeader(
            title: 'Daily Checklist',
            subtitle: 'Local UI state for beta phase 1.',
            accent: AppTheme.neonCyan,
          ),
          const SizedBox(height: 10),
          for (final item in checklist) ...[
            _checklistRow(item),
            if (item != checklist.last) const SizedBox(height: 7),
          ],
        ],
      ),
    );
  }

  Widget _checklistRow(ArcCommandChecklistItem item) {
    final checked = _checklistState[item.id] ?? item.doneByDefault;
    final accent = checked ? Colors.lightGreenAccent : AppTheme.neonCyan;
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: _innerDecoration(accent),
      child: Row(
        children: [
          Checkbox(
            value: checked,
            activeColor: Colors.lightGreenAccent,
            onChanged: (value) {
              setState(() => _checklistState[item.id] = value ?? false);
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 12,
                    color: checked ? Colors.lightGreenAccent : Colors.white,
                    isBold: true,
                  ),
                ),
                Text(
                  item.reason,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 10,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ArcCommandActionButton(
            action: item.action,
            accent: accent,
            compact: true,
            onPressed: () => _handleAction(item.action),
          ),
        ],
      ),
    );
  }

  Widget _responsiveGrid({
    required List<Widget> children,
    double minTileWidth = 300,
    double spacing = 10,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / minTileWidth)
            .floor()
            .clamp(1, 3)
            .toInt();
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }

  BoxDecoration _innerDecoration(Color accent) {
    return BoxDecoration(
      color: Colors.black.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: accent.withValues(alpha: 0.20)),
    );
  }

  IconData _statusIcon(ArcCommandStatus status) {
    switch (status) {
      case ArcCommandStatus.critical:
        return Icons.priority_high_rounded;
      case ArcCommandStatus.warning:
        return Icons.warning_amber_rounded;
      case ArcCommandStatus.active:
        return Icons.radar_rounded;
      case ArcCommandStatus.ready:
        return Icons.swap_horiz_rounded;
      case ArcCommandStatus.neutral:
        return Icons.circle_outlined;
      case ArcCommandStatus.success:
        return Icons.check_circle_rounded;
    }
  }
}
