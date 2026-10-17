// ignore_for_file: use_null_aware_elements

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/screens/monetisation_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_command_centre_relevance_mapper.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_user_personalisation_profile.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_expedition_state_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_season_reset_screen.dart';
import 'package:uag_arc_raiders_hub/features/trust/screens/arc_raider_contracts_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_match_rider_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/nomadic_trader_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/play_like_a_pro_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/smart_trade_assist_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_notifications_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/wall_of_legends_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/services/arc_text_sanitizer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/command_centre/arc_command_centre_widgets.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/command_centre/arc_command_centre_layout_policy.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/command_centre/arc_command_centre_progress_policy.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/command_centre/arc_command_system_detail_mapper.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_global_visual_system.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcCommandCentreContent extends StatefulWidget {
  const ArcCommandCentreContent({
    super.key,
    required this.expeditionState,
    required this.commandState,
    this.tradeActivity = ArcCommandTradeActivity.empty,
    required this.checklistState,
    required this.onAction,
    required this.onChecklistChanged,
    this.personalisation = ArcUserPersonalisationProfile.defaults,
    this.fallbackNotice,
    this.eventPreview,
  });

  final ArcExpeditionStateSnapshot expeditionState;
  final ArcCommandCentreState commandState;
  final ArcCommandTradeActivity tradeActivity;
  final Map<String, bool> checklistState;
  final ValueChanged<ArcCommandAction> onAction;
  final void Function(String id, bool value) onChecklistChanged;
  final ArcUserPersonalisationProfile personalisation;
  final String? fallbackNotice;
  final Widget? eventPreview;

  @override
  State<ArcCommandCentreContent> createState() =>
      _ArcCommandCentreContentState();
}

class _ArcCommandCentreContentState extends State<ArcCommandCentreContent> {
  final Map<String, bool> _expandedPanels = <String, bool>{};
  int _systemsIndex = 0;

  static const double _briefingCarouselExtent = 258;
  static const int _briefingCarouselLoopBase = 40000;
  late final ScrollController _benchCarouselController;
  late final ScrollController _eventCarouselController;
  Timer? _eventRotationTimer;

  @override
  void initState() {
    super.initState();
    final initialOffset = _briefingCarouselLoopBase * _briefingCarouselExtent;
    _benchCarouselController = ScrollController(
      initialScrollOffset: initialOffset,
    );
    _eventCarouselController = ScrollController(
      initialScrollOffset: initialOffset,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _startEventRotation());
  }

  @override
  void dispose() {
    _eventRotationTimer?.cancel();
    _benchCarouselController.dispose();
    _eventCarouselController.dispose();
    super.dispose();
  }

  void _startEventRotation() {
    _eventRotationTimer?.cancel();
    _eventRotationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_eventCarouselController.hasClients) return;
      final position = _eventCarouselController.position;
      if (position.isScrollingNotifier.value) return;

      var next = position.pixels + _briefingCarouselExtent;
      if (next >= position.maxScrollExtent - (_briefingCarouselExtent * 4)) {
        final reset = _briefingCarouselLoopBase * _briefingCarouselExtent;
        _eventCarouselController.jumpTo(reset);
        next = reset + _briefingCarouselExtent;
      }

      _eventCarouselController.animateTo(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final commandState = widget.commandState;
    final exploreTiles = _systemCarouselTiles(commandState);

    return ArcRaidersPageList(
      maxWidth: 1220,
      bottomPadding: 92,
      children: [
        if (widget.fallbackNotice != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.neonCyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.neonCyan.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppTheme.neonCyan,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.fallbackNotice!,
                    style: AppTheme.bodyTextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        _nextRaidBrief(commandState),
        const SizedBox(height: 8),
        _progressionBrief(commandState),
        const SizedBox(height: 8),
        _loadoutQuestBrief(commandState),
        const SizedBox(height: 8),
        _eventsForYou(commandState),
        const SizedBox(height: 8),
        _tradeUpcomingBrief(commandState),
        const SizedBox(height: 8),
        _exploreBrief(commandState, exploreTiles),
      ],
    );
  }

  Widget _nextRaidBrief(ArcCommandCentreState state) {
    final panel = state.raidIntelligenceSummary;
    final map = _detailValue(panel.details, 'Map:') ?? 'Recommended map';
    final condition =
        _detailValue(panel.details, 'Condition:') ?? panel.statusLabel;
    final blueprintTargets = _detailContaining(panel.details, 'Blueprint');
    final accent = arcCommandStatusAccent(panel.status);
    final ctaLabel = panel.status == ArcCommandStatus.ready
        ? 'OPEN RAID'
        : 'BUILD MY RAID';

    return _tapSurface(
      action: panel.action,
      active: panel.status == ArcCommandStatus.ready,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 150),
        padding: const EdgeInsets.all(16),
        decoration: _imageDecoration(
          _imageForAction(panel.action),
          AppTheme.neonPink,
          radius: 20,
          darken: 0.40,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;
            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEXT RAID',
                  style: AppTheme.bodyTextStyle(
                    fontSize: 11,
                    color: AppTheme.neonPink,
                    isBold: true,
                  ).copyWith(letterSpacing: 1.35),
                ),
                const SizedBox(height: 6),
                Text(
                  _cleanText(map).toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.tradingHeading(
                    fontSize: compact ? 28 : 34,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _briefingChip(condition, accent),
                    if (blueprintTargets != null)
                      _briefingChip(blueprintTargets, AppTheme.neonCyan),
                  ],
                ),
              ],
            );

            final cta = Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.neonPink.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.neonPink.withValues(alpha: 0.52),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.route_rounded,
                    color: AppTheme.neonPink,
                    size: 18,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    ctaLabel,
                    style: AppTheme.bodyTextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      isBold: true,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.neonPink,
                    size: 18,
                  ),
                ],
              ),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  copy,
                  const SizedBox(height: 14),
                  Align(alignment: Alignment.centerLeft, child: cta),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: copy),
                const SizedBox(width: 18),
                cta,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _progressionBrief(ArcCommandCentreState state) {
    final blueprint = state.blueprintSummary;
    final owned =
        _detailContaining(blueprint.details, 'owned') ?? blueprint.statusLabel;
    final duplicates = _detailContaining(blueprint.details, 'duplicate');
    final scrappy = _snapshotByLabel(state.snapshots, 'Scrappy');
    final benchStations = state.snapshots
        .where((metric) => metric.label.startsWith('Bench: '))
        .toList(growable: false);

    final blueprintCard = _briefingStatusCard(
      title: 'COLLECTIONS TRACKER',
      value: owned,
      detail: duplicates ?? '',
      action: blueprint.action,
      status: blueprint.status,
      icon: Icons.grid_view_rounded,
      image: _operationAsset('complete_blueprint_collection_card.webp'),
      large: true,
    );

    final benchCards = <Widget>[
      for (final bench in benchStations)
        _briefingEventCard(
          title: bench.label.substring('Bench: '.length).toUpperCase(),
          value: bench.value,
          detail: bench.detail,
          status: bench.status,
          action: const ArcCommandAction(
            label: 'Open Bench Tracker',
            routeName: ScrappyGridScreen.benchRouteName,
          ),
          icon: Icons.build_circle_outlined,
        ),
      _briefingEventCard(
        title: 'SCRAPPY',
        value: scrappy?.value ?? 'Lv.0',
        detail: scrappy?.status == ArcCommandStatus.ready
            ? 'UPGRADE READY'
            : '',
        status: scrappy?.status ?? ArcCommandStatus.neutral,
        action: const ArcCommandAction(
          label: 'Open Scrappy Tracker',
          routeName: ScrappyGridScreen.routeName,
        ),
        icon: Icons.pets_rounded,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        blueprintCard,
        const SizedBox(height: 8),
        _railTitle('BENCHES + SCRAPPY', AppTheme.neonCyan),
        const SizedBox(height: 6),
        _loopingCardRail(
          cards: benchCards,
          controller: _benchCarouselController,
        ),
      ],
    );
  }

  Widget _loadoutQuestBrief(ArcCommandCentreState state) {
    final loadout = _snapshotByLabel(state.snapshots, 'Favourite Loadout');
    final activeQuest =
        _detailValue(state.questSummary.details, 'Active quest:') ??
        state.questSummary.statusLabel;

    final loadoutCard = _briefingStatusCard(
      title: 'FAVOURITE LOADOUT',
      value: loadout?.value ?? 'NOT SAVED',
      detail: loadout?.detail ?? '',
      action: const ArcCommandAction(
        label: 'Open Favourite Loadout',
        intent: ArcCommandActionIntent.favouriteLoadout,
      ),
      status: loadout?.status ?? ArcCommandStatus.warning,
      icon: Icons.tune_rounded,
      image: _operationAsset('finish_favourite_loadout_card.webp'),
    );
    final questCard = _briefingStatusCard(
      title: 'CURRENT QUESTS',
      value: activeQuest,
      detail: '',
      action: state.questSummary.action,
      status: state.questSummary.status,
      icon: Icons.assignment_turned_in_outlined,
      image: _operationAsset('track_quests_card.webp'),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [loadoutCard, const SizedBox(height: 8), questCard],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: loadoutCard),
            const SizedBox(width: 8),
            Expanded(child: questCard),
          ],
        );
      },
    );
  }

  Widget _eventsForYou(ArcCommandCentreState state) {
    final condition =
        _detailValue(state.raidIntelligenceSummary.details, 'Condition:') ??
        state.raidIntelligenceSummary.statusLabel;
    final map =
        _detailValue(state.raidIntelligenceSummary.details, 'Map:') ??
        'Raid Intelligence';
    final events = <Widget>[
      _briefingEventCard(
        title: 'RAID CONDITION',
        value: condition,
        detail: map,
        status: state.raidIntelligenceSummary.status,
        action: state.raidIntelligenceSummary.action,
        icon: Icons.nightlight_round,
      ),
      _briefingEventCard(
        title: 'NOMADIC TRADER',
        value: state.weeklyTraderSummary.statusLabel,
        detail: '',
        status: state.weeklyTraderSummary.status,
        action: state.weeklyTraderSummary.action,
        icon: Icons.storefront_rounded,
      ),
      _briefingEventCard(
        title: 'OPERATIONS',
        value: state.operationsSummary.statusLabel,
        detail: '',
        status: state.operationsSummary.status,
        action: state.operationsSummary.action,
        icon: Icons.bolt_rounded,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _railTitle('EVENTS FOR YOU', AppTheme.neonCyan),
        const SizedBox(height: 6),
        _loopingCardRail(cards: events, controller: _eventCarouselController),
      ],
    );
  }

  Widget _tradeUpcomingBrief(ArcCommandCentreState state) {
    final duplicateLine =
        _detailContaining(state.blueprintSummary.details, 'duplicate') ??
        'No duplicate Blueprint signal';
    final tradeAction = state.tradeSummary.actions.isNotEmpty
        ? state.tradeSummary.actions.first
        : const ArcCommandAction(
            label: 'Open Smart Trade',
            intent: ArcCommandActionIntent.smartTrade,
          );
    final tradeDetail = _hasTradeSignal(state.tradeSummary)
        ? _tradeSignalDetail(state.tradeSummary)
        : '';
    final sessions = widget.tradeActivity.activeSessions;
    final readySessions = widget.tradeActivity.readySessions;
    final unread = widget.tradeActivity.unreadNotifications;
    final upcomingValue = sessions == 0
        ? 'No active trade sessions'
        : '$sessions active trade ${sessions == 1 ? 'session' : 'sessions'}';
    final upcomingDetail = [
      if (readySessions > 0) '$readySessions ready',
      if (unread > 0) '$unread unread update${unread == 1 ? '' : 's'}',
    ].join('  •  ');

    final tradeCard = _briefingStatusCard(
      title: 'DUPLICATES / TRADE',
      value: duplicateLine,
      detail: tradeDetail,
      action: tradeAction,
      status: widget.tradeActivity.hasActionableTrades
          ? ArcCommandStatus.ready
          : state.blueprintSummary.status,
      icon: Icons.swap_horiz_rounded,
      image: _operationAsset('review_trade_activity_card.webp'),
    );
    final upcomingCard = _briefingStatusCard(
      title: 'CALENDAR / UPCOMING',
      value: upcomingValue,
      detail: upcomingDetail,
      action: const ArcCommandAction(
        label: 'Open Trading Hub',
        routeName: TraderHubScreen.routeName,
      ),
      status: sessions > 0 ? ArcCommandStatus.active : ArcCommandStatus.neutral,
      icon: Icons.event_available_rounded,
      image: _operationAsset('arc_command_centre_background.webp'),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [tradeCard, const SizedBox(height: 8), upcomingCard],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: tradeCard),
            const SizedBox(width: 8),
            Expanded(child: upcomingCard),
          ],
        );
      },
    );
  }

  Widget _exploreBrief(
    ArcCommandCentreState state,
    List<_CommandTileData> exploreTiles,
  ) {
    return _commandAccordion(
      title: 'EXPLORE',
      subtitle: '',
      icon: Icons.apps_rounded,
      accent: AppTheme.neonCyan,
      initiallyExpanded: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _systemCarousel(state, exploreTiles, showHeader: false),
          const SizedBox(height: 8),
          _seasonResetEntry(),
        ],
      ),
    );
  }

  Widget _railTitle(String title, Color accent) {
    return Text(
      title,
      style: AppTheme.bodyTextStyle(
        fontSize: 10,
        color: accent,
        isBold: true,
      ).copyWith(letterSpacing: 1.0),
    );
  }

  Widget _loopingCardRail({
    required List<Widget> cards,
    required ScrollController controller,
  }) {
    if (cards.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 118,
      child: ListView.builder(
        controller: controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemExtent: _briefingCarouselExtent,
        itemCount: _briefingCarouselLoopBase * 2,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: cards[index % cards.length],
        ),
      ),
    );
  }

  Widget _briefingStatusCard({
    required String title,
    required String value,
    required String detail,
    required ArcCommandAction action,
    required ArcCommandStatus status,
    required IconData icon,
    required String image,
    bool large = false,
    bool dense = false,
  }) {
    final accent = arcCommandStatusAccent(status);
    return _tapSurface(
      action: action,
      child: Container(
        constraints: BoxConstraints(
          minHeight: large
              ? 132
              : dense
              ? 104
              : 118,
        ),
        padding: EdgeInsets.all(dense ? 10 : 12),
        decoration: _imageDecoration(image, accent, radius: 17, darken: 0.52),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accent, size: dense ? 16 : 18),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyTextStyle(
                      fontSize: dense ? 9 : 10,
                      color: accent,
                      isBold: true,
                    ).copyWith(letterSpacing: 0.75),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: accent, size: 18),
              ],
            ),
            SizedBox(height: dense ? 7 : 9),
            Text(
              _cleanText(value),
              maxLines: large ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.tradingHeading(
                fontSize: large
                    ? 22
                    : dense
                    ? 16
                    : 18,
                color: Colors.white,
              ),
            ),
            if (detail.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _cleanText(detail),
                maxLines: dense ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyTextStyle(
                  fontSize: dense ? 9.5 : 10.5,
                  color: Colors.white70,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _briefingEventCard({
    required String title,
    required String value,
    required String detail,
    required ArcCommandStatus status,
    required ArcCommandAction action,
    required IconData icon,
  }) {
    final accent = arcCommandStatusAccent(status);
    return SizedBox(
      width: 250,
      child: _tapSurface(
        action: action,
        child: ArcCommandCentreCard(
          accent: accent,
          padding: const EdgeInsets.all(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: accent, size: 17),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodyTextStyle(
                        fontSize: 9,
                        color: accent,
                        isBold: true,
                      ).copyWith(letterSpacing: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _cleanText(value),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.tradingHeading(
                  fontSize: 17,
                  color: Colors.white,
                ),
              ),
              if (detail.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _shortActionText(detail),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 10,
                    color: Colors.white60,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _briefingChip(String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.34)),
      ),
      child: Text(
        _cleanText(label),
        style: AppTheme.bodyTextStyle(
          fontSize: 9,
          color: Colors.white70,
          isBold: true,
        ),
      ),
    );
  }

  String? _detailValue(List<String> details, String prefix) {
    final normalizedPrefix = prefix.toLowerCase();
    for (final detail in details) {
      final cleaned = _cleanText(detail).trim();
      if (cleaned.toLowerCase().startsWith(normalizedPrefix)) {
        return cleaned.substring(prefix.length).trim();
      }
    }
    return null;
  }

  String? _detailContaining(List<String> details, String token) {
    final normalizedToken = token.toLowerCase();
    for (final detail in details) {
      final cleaned = _cleanText(detail).trim();
      if (cleaned.toLowerCase().contains(normalizedToken)) return cleaned;
    }
    return null;
  }

  int _safeSystemIndex(int tileCount) {
    if (tileCount <= 0) return 0;
    return _systemsIndex.clamp(0, tileCount - 1).toInt();
  }

  Widget _commandAccordion({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required Widget child,
    bool initiallyExpanded = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.06), blurRadius: 18),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          leading: Icon(icon, color: accent, size: 19),
          iconColor: accent,
          collapsedIconColor: Colors.white54,
          title: Text(
            title,
            style: TextStyle(
              fontFamily: AppTheme.headingFontFamily,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.35,
              color: accent,
            ),
          ),
          subtitle: subtitle.trim().isEmpty
              ? null
              : Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 10,
                    color: Colors.white54,
                  ),
                ),
          children: [child],
        ),
      ),
    );
  }

  Widget _seasonResetEntry({bool showTitle = true}) {
    final expeditionState = widget.expeditionState;
    final resetSubtitle = expeditionState.resetInProgress
        ? '${expeditionState.currentSeasonId} reset in progress.'
        : '${expeditionState.currentSeasonId} - ${expeditionState.statusLabel}.';

    return _tapSurface(
      action: const ArcCommandAction(
        label: 'Start Expedition Reset',
        routeName: ArcSeasonResetScreen.routeName,
      ),
      child: ArcCommandCentreCard(
        padding: const EdgeInsets.all(12),
        accent: AppTheme.neonPink,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.neonPink.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.neonPink.withValues(alpha: 0.36),
                ),
              ),
              child: const Icon(
                Icons.restart_alt_rounded,
                color: AppTheme.neonPink,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: showTitle
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EXPEDITION RESET',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.tradingHeading(
                            fontSize: 15,
                            color: AppTheme.neonPink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          resetSubtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.bodyTextStyle(
                            fontSize: 11,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      resetSubtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodyTextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        isBold: true,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.neonPink),
          ],
        ),
      ),
    );
  }

  Widget _systemCarousel(
    ArcCommandCentreState state,
    List<_CommandTileData> tiles, {
    bool showHeader = true,
  }) {
    if (tiles.isEmpty) return const SizedBox.shrink();

    final activeIndex = _safeSystemIndex(tiles.length);

    void rotate(int delta) {
      if (tiles.length <= 1) return;
      setState(() {
        _systemsIndex = (_systemsIndex + delta) % tiles.length;
        if (_systemsIndex < 0) _systemsIndex += tiles.length;
      });
    }

    final previousIndex = tiles.length <= 1
        ? activeIndex
        : (activeIndex - 1 + tiles.length) % tiles.length;
    final nextIndex = tiles.length <= 1
        ? activeIndex
        : (activeIndex + 1) % tiles.length;

    return ArcCommandCentreCard(
      accent: AppTheme.neonCyan,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final ringHeight = ArcCommandCentreLayoutPolicy.systemRingHeight(
            constraints.maxWidth,
          );

          Widget sideCard(_CommandTileData tile) {
            return Opacity(
              opacity: 0.46,
              child: Transform.scale(
                scale: 0.82,
                child: _carouselCard(tile, active: false),
              ),
            );
          }

          Widget desktopRing() {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 3, child: sideCard(tiles[previousIndex])),
                const SizedBox(width: 4),
                _featureArrow(
                  icon: Icons.chevron_left_rounded,
                  tooltip: 'Previous feature',
                  onPressed: () => rotate(-1),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 7,
                  child: Transform.scale(
                    scale: 1.04,
                    child: _carouselCard(tiles[activeIndex], active: true),
                  ),
                ),
                const SizedBox(width: 8),
                _featureArrow(
                  icon: Icons.chevron_right_rounded,
                  tooltip: 'Next feature',
                  onPressed: () => rotate(1),
                ),
                const SizedBox(width: 4),
                Expanded(flex: 3, child: sideCard(tiles[nextIndex])),
              ],
            );
          }

          Widget compactRing() {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: _featureArrow(
                    icon: Icons.chevron_left_rounded,
                    tooltip: 'Previous feature',
                    compact: true,
                    onPressed: () => rotate(-1),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _carouselCard(tiles[activeIndex], active: true),
                ),
                const SizedBox(width: 6),
                Align(
                  alignment: Alignment.center,
                  child: _featureArrow(
                    icon: Icons.chevron_right_rounded,
                    tooltip: 'Next feature',
                    compact: true,
                    onPressed: () => rotate(1),
                  ),
                ),
              ],
            );
          }

          final ring = SizedBox(
            height: ringHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity.abs() < 120) return;
                rotate(velocity < 0 ? 1 : -1);
              },
              child: compact ? compactRing() : desktopRing(),
            ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showHeader) ...[
                const ArcCommandSectionHeader(
                  title: 'FEATURES',
                  subtitle: 'Active systems',
                  accent: AppTheme.neonCyan,
                ),
                const SizedBox(height: 7),
              ],
              ring,
              const SizedBox(height: 5),
              _featureRingIndicator(tiles.length, activeIndex),
              const SizedBox(height: 8),
              _systemIntelligencePanel(state, tiles[activeIndex]),
            ],
          );
        },
      ),
    );
  }

  Widget _systemIntelligencePanel(
    ArcCommandCentreState state,
    _CommandTileData tile,
  ) {
    final panel = ArcCommandSystemDetailMapper.panelFor(
      state: state,
      title: tile.title,
      value: tile.value,
      detail: tile.detail,
      status: tile.status,
      action: tile.action,
    );
    final accent = arcCommandStatusAccent(panel.status);
    final details = <String>[
      for (final detail in panel.details)
        if (_isUsefulSummaryDetail(detail)) _cleanText(detail),
    ].take(3).toList(growable: false);
    final body = _cleanText(panel.body).trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: accent, size: 16),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'SYSTEM INTELLIGENCE',
                  style: AppTheme.bodyTextStyle(
                    fontSize: 9,
                    color: accent,
                    isBold: true,
                  ).copyWith(letterSpacing: .8),
                ),
              ),
              ArcCommandStatusPill(
                label: panel.statusLabel.isEmpty
                    ? tile.value
                    : panel.statusLabel,
                status: panel.status,
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            _cleanText(tile.title),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.tradingHeading(fontSize: 14, color: Colors.white),
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              _shortActionText(body),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyTextStyle(
                fontSize: 10,
                color: Colors.white70,
              ).copyWith(height: 1.2),
            ),
          ],
          if (details.isNotEmpty) ...[
            const SizedBox(height: 7),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final detail in details)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: accent.withValues(alpha: 0.20)),
                    ),
                    child: Text(
                      detail,
                      style: AppTheme.bodyTextStyle(
                        fontSize: 8.5,
                        color: Colors.white70,
                        isBold: true,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _cleanText(tile.action.label).toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyTextStyle(
                fontSize: 9,
                color: accent,
                isBold: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureRingIndicator(int count, int activeIndex) {
    if (count <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: active ? 18 : 5,
          height: 5,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: active
                ? AppTheme.neonCyan
                : Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(99),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppTheme.neonCyan.withValues(alpha: 0.42),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _featureArrow({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool compact = false,
  }) {
    final size = compact ? 38.0 : 42.0;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: compact ? 24 : 27),
      style: IconButton.styleFrom(
        foregroundColor: AppTheme.neonCyan,
        backgroundColor: AppTheme.cardBackgroundDeep.withValues(alpha: 0.94),
        side: BorderSide(color: AppTheme.neonCyan.withValues(alpha: 0.56)),
        minimumSize: Size(size, size),
        maximumSize: Size(size, size),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _carouselCard(_CommandTileData tile, {required bool active}) {
    final accent = arcCommandStatusAccent(tile.status);
    return _tapSurface(
      action: tile.action,
      active: active,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
        decoration: _imageDecoration(
          tile.image,
          accent,
          radius: 12,
          darken: active ? 0.58 : 0.64,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (active) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_statusIcon(tile.status), color: accent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _cleanText(tile.title).toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.tradingHeading(
                        fontSize: 14,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Align(
                alignment: Alignment.centerRight,
                child: ArcCommandStatusPill(
                  label: tile.value,
                  status: tile.status,
                ),
              ),
            ] else
              Row(
                children: [
                  Icon(_statusIcon(tile.status), color: accent, size: 17),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      _cleanText(tile.title).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.tradingHeading(
                        fontSize: 12,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  ArcCommandStatusPill(label: tile.value, status: tile.status),
                ],
              ),
            const Spacer(),
            Text(
              _shortActionText(tile.detail),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyTextStyle(
                fontSize: active ? 11 : 9,
                color: Colors.white.withValues(alpha: active ? 0.90 : 0.72),
                isBold: true,
              ).copyWith(height: 1.24),
            ),
            const SizedBox(height: 4),
            Text(
              'TAP',
              style: AppTheme.bodyTextStyle(
                fontSize: active ? 9 : 8,
                color: accent,
                isBold: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  List<_CommandMoveData> _commandMoves(ArcCommandCentreState state) {
    final moves = <_CommandMoveData>[];
    final seen = <String>{};

    void add({
      required String title,
      required String detail,
      required String label,
      required ArcCommandStatus status,
      required ArcCommandAction action,
      required IconData icon,
      required Color accent,
      required String image,
      int? progressPercent,
    }) {
      final resolvedProgress =
          progressPercent ??
          ArcCommandCentreProgressPolicy.measuredPercent(
            status: status,
            label: label,
            detail: detail,
          );
      if (resolvedProgress == 100 || status == ArcCommandStatus.success) {
        return;
      }
      final key = '${title.toLowerCase()}|${action.intent}|${action.routeName}';
      if (!seen.add(key)) return;
      moves.add(
        _CommandMoveData(
          title: title,
          detail: detail,
          label: label,
          status: status,
          action: action,
          icon: icon,
          accent: accent,
          image: image,
          progressPercent: resolvedProgress,
        ),
      );
    }

    for (final objective in state.objectives) {
      final detail = objective.progressText.isNotEmpty
          ? objective.progressText
          : objective.reason;
      add(
        title: objective.title,
        detail: detail,
        label: objective.statusLabel,
        status: objective.status,
        action: objective.action,
        icon: _statusIcon(objective.status),
        accent: arcCommandStatusAccent(objective.status),
        image: _imageForCommandTitle(
          objective.title,
          fallback: _imageForAction(objective.action),
        ),
      );
    }

    for (final alert in state.alerts) {
      add(
        title: alert.title,
        detail: alert.body,
        label: alert.statusLabel,
        status: alert.status,
        action: alert.action,
        icon: _statusIcon(alert.status),
        accent: arcCommandStatusAccent(alert.status),
        image: _imageForCommandTitle(
          alert.title,
          fallback: _imageForAction(alert.action),
        ),
      );
    }

    if (_hasTradeSignal(state.tradeSummary)) {
      final action = state.tradeSummary.actions.isNotEmpty
          ? state.tradeSummary.actions.first
          : const ArcCommandAction(
              label: 'Open Trades',
              intent: ArcCommandActionIntent.smartTrade,
            );
      add(
        title: 'Trade Opportunity',
        detail: _tradeSignalDetail(state.tradeSummary),
        label: 'Trade',
        status: ArcCommandStatus.ready,
        action: action,
        icon: Icons.swap_horiz_rounded,
        accent: AppTheme.neonPink,
        image: _imageForCommandTitle(
          'Trade Opportunity',
          fallback: _imageForAction(action),
        ),
      );
    }

    for (final recommendation in state.recommendations) {
      add(
        title: recommendation.title,
        detail: recommendation.body,
        label: 'Pick',
        status: ArcCommandStatus.warning,
        action: recommendation.action,
        icon: Icons.auto_awesome_rounded,
        accent: Colors.amberAccent,
        image: _imageForCommandTitle(
          recommendation.title,
          fallback: _imageForAction(recommendation.action),
        ),
      );
    }

    return moves;
  }

  // ignore: unused_element
  Widget _actionConsole(
    List<_CommandMoveData> moves, {
    bool showHeader = true,
  }) {
    return ArcCommandCentreCard(
      accent: AppTheme.neonCyan,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            const ArcCommandSectionHeader(
              title: 'Next Move',
              subtitle: 'Priority actions',
              accent: AppTheme.neonCyan,
            ),
            const SizedBox(height: 8),
          ],
          if (moves.isEmpty)
            _quietLine('No active command needs attention.')
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = ArcCommandCentreLayoutPolicy.moveColumns(
                  constraints.maxWidth,
                );
                const spacing = 8.0;
                final width =
                    (constraints.maxWidth - (spacing * (columns - 1))) /
                    columns;
                final tileHeight = ArcCommandCentreLayoutPolicy.moveTileHeight(
                  constraints.maxWidth,
                );
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final move in moves)
                      SizedBox(
                        width: width,
                        child: _moveTile(move, height: tileHeight),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _moveTile(_CommandMoveData move, {required double height}) {
    return _tapSurface(
      action: move.action,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(9),
        decoration: _imageDecoration(move.image, move.accent, radius: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _moveProgressIndicator(move),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _cleanText(move.label).toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: AppTheme.bodyTextStyle(
                      fontSize: 8,
                      color: move.accent,
                      isBold: true,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              _cleanText(move.title),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyTextStyle(
                fontSize: 10.5,
                color: Colors.white,
                isBold: true,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _shortActionText(move.detail),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyTextStyle(
                fontSize: 9,
                color: Colors.white54,
              ).copyWith(height: 1.12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moveProgressIndicator(_CommandMoveData move) {
    final progressPercent = move.progressPercent;
    final progress = progressPercent == null
        ? null
        : progressPercent.clamp(0, 100) / 100;
    return SizedBox(
      width: 30,
      height: 30,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: Colors.black.withValues(alpha: 0.36),
            color: move.accent,
          ),
          if (progressPercent != null)
            Text(
              '${progressPercent.clamp(0, 100)}',
              style: AppTheme.bodyTextStyle(
                fontSize: 7,
                color: Colors.white.withValues(alpha: 0.90),
                isBold: true,
              ),
            )
          else
            Icon(move.icon, size: 13, color: move.accent),
        ],
      ),
    );
  }

  List<_CommandTileData> _systemCarouselTiles(ArcCommandCentreState state) {
    final loadout = _snapshotByLabel(state.snapshots, 'Favourite Loadout');

    _CommandTileData routeTile({
      required String title,
      required String detail,
      required String routeName,
      required String image,
      String value = 'Open',
      ArcCommandStatus status = ArcCommandStatus.active,
    }) {
      return _CommandTileData(
        title: title,
        value: value,
        detail: detail,
        status: status,
        action: ArcCommandAction(label: 'Open $title', routeName: routeName),
        image: image,
      );
    }

    final tiles = <_CommandTileData>[
      _tileFromPanel(
        state.blueprintSummary,
        image: _operationAsset('complete_blueprint_collection_card.webp'),
      ),
      routeTile(
        title: 'Scrappy Tracker',
        detail: 'Track Scrappy upgrade resources and requirements.',
        routeName: ScrappyGridScreen.routeName,
        image: _operationAsset('missing_resources_card.webp'),
      ),
      _tileFromPanel(
        state.benchSummary,
        image: _operationAsset('upgrade_gunsmith_card.webp'),
      ),
      _tileFromPanel(
        state.questSummary,
        image: _operationAsset('track_quests_card.webp'),
      ),
      _tileFromPanel(
        state.raidIntelligenceSummary,
        image: _imageForAction(state.raidIntelligenceSummary.action),
      ),
      routeTile(
        title: 'Raid Planner',
        detail: 'Plan raid objectives, routes and targets.',
        routeName: RaidPlannerScreen.routeName,
        image: _operationAsset('weekly_raid_card.webp'),
      ),
      _tileFromMetric(
        loadout ??
            const ArcCommandSnapshotMetric(
              label: 'Favourite Loadout',
              value: 'Set up',
              detail: 'Open loadout',
              status: ArcCommandStatus.warning,
            ),
        action: const ArcCommandAction(
          label: 'Open Loadout',
          intent: ArcCommandActionIntent.favouriteLoadout,
        ),
        image: _operationAsset('finish_favourite_loadout_card.webp'),
      ),
      routeTile(
        title: 'Trading Hub',
        detail: 'Listings, offers, watches and trade sessions.',
        routeName: TraderHubScreen.routeName,
        image: _operationAsset('review_trade_activity_card.webp'),
      ),
      routeTile(
        title: 'Smart Trade Assist',
        detail: 'Turn inventory needs into smarter trade decisions.',
        routeName: SmartTradeAssistScreen.routeName,
        image: _operationAsset('review_trade_activity_card.webp'),
      ),
      routeTile(
        title: 'Match Raider',
        detail: 'Find compatible Raiders and squad connections.',
        routeName: ArcMatchRiderScreen.routeName,
        image: _operationAsset('arc_command_centre_background.webp'),
      ),
      routeTile(
        title: 'Report a Rat',
        detail: 'Community reports, evidence and Raider contracts.',
        routeName: ArcRaiderContractsScreen.routeName,
        image: _operationAsset('arc_command_centre_background.webp'),
      ),
      routeTile(
        title: 'Play Like a Pro',
        detail: 'Expert tactics, guidance and advanced play.',
        routeName: PlayLikeAProScreen.routeName,
        image: _operationAsset('weekly_raid_card.webp'),
      ),
      routeTile(
        title: 'Communications',
        detail: 'Notifications, invites and trading updates.',
        routeName: TradingNotificationsScreen.routeName,
        image: _operationAsset('arc_command_centre_background.webp'),
      ),
      routeTile(
        title: 'Wall of Legends',
        detail: 'Community recognition and Raider achievements.',
        routeName: WallOfLegendsScreen.routeName,
        image: _operationAsset('arc_command_centre_background.webp'),
      ),
      routeTile(
        title: 'Plans & Referrals',
        detail: 'Premium plans, beta and Founder offers, passes and referrals.',
        routeName: MonetisationScreen.routeName,
        image: _operationAsset('arc_command_centre_background.webp'),
      ),
      _tileFromPanel(
        state.operationsSummary,
        image: _operationAsset('claim_operations_card.webp'),
      ),
      routeTile(
        title: 'Nomadic Trader',
        detail: 'Review the current weekly trader rotation.',
        routeName: NomadicTraderScreen.routeName,
        image: _operationAsset('check_nomadic_trader_card.webp'),
      ),
      _CommandTileData(
        title: 'Tool Deck',
        value: 'All tools',
        detail: 'Open full ARC launcher',
        status: ArcCommandStatus.active,
        action: const ArcCommandAction(
          label: 'Open Tool Deck',
          intent: ArcCommandActionIntent.toolDeck,
        ),
        image: _operationAsset('arc_tool_deck_background.webp'),
      ),
    ];

    final personalisation = widget.personalisation;
    if (!personalisation.hasExplicitPreferences ||
        personalisation.goals.contains(
          ArcPersonalisationGoal.exploreEverything,
        )) {
      return tiles;
    }

    final focused = tiles
        .where((tile) {
          if (tile.title == 'Tool Deck') return true;
          final feature = _featureForSystemTile(tile);
          return personalisation.interestFor(feature).isHighSignal;
        })
        .toList(growable: false);

    return focused;
  }

  ArcPersonalisationFeature _featureForSystemTile(_CommandTileData tile) {
    switch (tile.title) {
      case 'Scrappy Tracker':
        return ArcPersonalisationFeature.scrappyTracker;
      case 'Raid Planner':
        return ArcPersonalisationFeature.raidPlanner;
      case 'Trading Hub':
        return ArcPersonalisationFeature.trading;
      case 'Smart Trade Assist':
        return ArcPersonalisationFeature.smartTrade;
      case 'Match Raider':
        return ArcPersonalisationFeature.matchRider;
      case 'Report a Rat':
        return ArcPersonalisationFeature.reportARat;
      case 'Play Like a Pro':
        return ArcPersonalisationFeature.playLikeAPro;
      case 'Communications':
        return ArcPersonalisationFeature.communications;
      case 'Wall of Legends':
        return ArcPersonalisationFeature.operations;
      case 'Plans & Referrals':
        return ArcPersonalisationFeature.giftSubscriptions;
      case 'Nomadic Trader':
        return ArcPersonalisationFeature.nomadicTrader;
      default:
        return ArcCommandCentreRelevanceMapper.featureForAction(tile.action);
    }
  }

  // ignore: unused_element
  Widget _dailyChecklist(List<ArcCommandChecklistItem> checklist) {
    final items = checklist.take(9).toList(growable: false);
    return _detailAccordion(
      title: 'Daily Mission Board',
      subtitle: 'Fast daily checks. Tap a tile.',
      accent: AppTheme.neonCyan,
      initiallyExpanded: true,
      children: items.isEmpty
          ? [_quietLine('No checklist items are waiting.')]
          : [
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = ArcCommandCentreLayoutPolicy.dailyColumns(
                    constraints.maxWidth,
                  );
                  const spacing = 8.0;
                  final width =
                      (constraints.maxWidth - (spacing * (columns - 1))) /
                      columns;
                  final tileHeight =
                      ArcCommandCentreLayoutPolicy.dailyTileHeight(
                        constraints.maxWidth,
                      );
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final item in items)
                        SizedBox(
                          width: width,
                          child: _checklistTile(item, height: tileHeight),
                        ),
                    ],
                  );
                },
              ),
            ],
    );
  }

  Widget _checklistTile(
    ArcCommandChecklistItem item, {
    required double height,
  }) {
    final checked = widget.checklistState[item.id] ?? item.doneByDefault;
    final accent = checked ? Colors.lightGreenAccent : AppTheme.neonCyan;
    return _tapSurface(
      action: item.action,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(8),
        decoration: _imageDecoration(
          _imageForChecklistItem(item),
          accent,
          radius: 14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => widget.onChecklistChanged(item.id, !checked),
                  child: Icon(
                    checked
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: accent,
                    size: 14,
                  ),
                ),
                const Spacer(),
                ArcCommandStatusPill(
                  label: checked ? 'Done' : 'Daily',
                  status: checked
                      ? ArcCommandStatus.success
                      : ArcCommandStatus.active,
                ),
              ],
            ),
            const Spacer(),
            Text(
              _cleanText(item.label),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyTextStyle(
                fontSize: 8,
                color: checked ? Colors.lightGreenAccent : Colors.white,
                isBold: true,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              _shortActionText(item.reason),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyTextStyle(
                fontSize: 7,
                color: Colors.white60,
              ).copyWith(height: 1.05),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailAccordion({
    required String title,
    required String subtitle,
    required Color accent,
    required List<Widget> children,
    bool initiallyExpanded = true,
  }) {
    final expanded = _expandedPanels.putIfAbsent(
      title,
      () => initiallyExpanded,
    );
    final visibleChildren = children.isEmpty
        ? <Widget>[_quietLine('No additional detail is waiting.')]
        : children;

    return ArcCommandCentreCard(
      accent: accent,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              setState(() => _expandedPanels[title] = !expanded);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _cleanText(title).toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.tradingHeading(
                            fontSize: 15,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _cleanText(subtitle),
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
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: accent,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                children: [
                  for (final child in visibleChildren) ...[
                    child,
                    if (child != visibleChildren.last)
                      const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }

  Widget _tapSurface({
    required ArcCommandAction action,
    required Widget child,
    bool active = false,
  }) {
    final surface = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => widget.onAction(action),
        child: child,
      ),
    );

    if (!active) return surface;

    return ArcElectricActionBorder(active: active, radius: 20, child: surface);
  }

  Widget _quietLine(String text) {
    return Text(
      text,
      style: AppTheme.bodyTextStyle(fontSize: 12, color: Colors.white54),
    );
  }

  _CommandTileData _tileFromPanel(
    ArcCommandSummaryPanel panel, {
    required String image,
    String? forceTitle,
  }) {
    return _CommandTileData(
      title: forceTitle ?? panel.title,
      value: panel.statusLabel,
      detail: _summaryDetail(panel),
      status: panel.status,
      action: panel.action,
      image: image,
    );
  }

  _CommandTileData _tileFromMetric(
    ArcCommandSnapshotMetric metric, {
    required ArcCommandAction action,
    required String image,
    String? forceTitle,
  }) {
    return _CommandTileData(
      title: forceTitle ?? metric.label,
      value: metric.value,
      detail: metric.detail,
      status: metric.status,
      action: action,
      image: image,
    );
  }

  ArcCommandSnapshotMetric? _snapshotByLabel(
    List<ArcCommandSnapshotMetric> snapshots,
    String label,
  ) {
    for (final snapshot in snapshots) {
      if (snapshot.label == label) {
        return snapshot;
      }
    }
    return null;
  }

  String _summaryDetail(ArcCommandSummaryPanel panel) {
    for (final detail in panel.details) {
      if (_isUsefulSummaryDetail(detail)) {
        return detail;
      }
    }
    if (panel.body.isNotEmpty) {
      return panel.body;
    }
    return panel.details.isEmpty ? 'Tap to open' : panel.details.first;
  }

  bool _isUsefulSummaryDetail(String value) {
    final normalized = value.toLowerCase();
    return _isUsefulSignal(value) && !normalized.contains('open ');
  }

  bool _hasTradeSignal(ArcCommandTradeSummary summary) {
    return summary.lookingFor.any(_isUsefulSignal) ||
        summary.offering.any(_isUsefulSignal);
  }

  String _tradeSignalDetail(ArcCommandTradeSummary summary) {
    final lookingFor = summary.lookingFor.where(_isUsefulSignal).toList();
    if (lookingFor.isNotEmpty) {
      return 'Looking for ${lookingFor.first}.';
    }
    final offering = summary.offering.where(_isUsefulSignal).toList();
    if (offering.isNotEmpty) {
      return 'Offering ${offering.first}.';
    }
    return 'Open Smart Trade for current opportunities.';
  }

  bool _isUsefulSignal(String value) {
    final normalized = value.toLowerCase();
    return value.trim().isNotEmpty &&
        !normalized.contains('not tracked') &&
        !normalized.contains('no signal') &&
        !normalized.contains('no duplicate') &&
        !normalized.contains('coming online');
  }

  String _shortActionText(String value) {
    final cleaned = _cleanText(value);
    final lower = cleaned.toLowerCase();
    if (lower.contains('farm antiseptic')) {
      return 'Farm antiseptic via Medical POIs before trading it away.';
    }
    if (lower.contains('ranked from')) {
      return cleaned.split(' ranked from').first.trim();
    }
    if (lower.contains('primary mission is')) {
      return cleaned
          .split(RegExp(r' ranked from|\. Ranked from', caseSensitive: false))
          .first
          .trim();
    }
    if (lower.contains('medical pois') || lower.contains('med crates')) {
      return 'Farm via Medical POIs before trading it away.';
    }
    if (cleaned.length <= 68) return cleaned;
    final firstSentence = cleaned.split(RegExp(r'[.!?]')).first.trim();
    if (firstSentence.length >= 18 && firstSentence.length <= 68) {
      return firstSentence;
    }
    return '${cleaned.substring(0, 65).trim()}...';
  }

  String _cleanText(String value) {
    return ArcTextSanitizer.sanitize(value);
  }

  String _operationAsset(String fileName) =>
      'assets/arc_raiders/operations/$fileName';

  String _imageForChecklistItem(ArcCommandChecklistItem item) {
    return _imageForCommandTitle(
      item.label,
      fallback: _imageForAction(item.action),
    );
  }

  String _imageForCommandTitle(String title, {required String fallback}) {
    final key = title.toLowerCase();
    if (key.contains('upgrade gunsmith') || key.contains('upgrade bench')) {
      return _operationAsset('upgrade_gunsmith_card.webp');
    }
    if (key.contains('missing resources') ||
        key.contains('secure antiseptic')) {
      return _operationAsset('missing_resources_card.webp');
    }
    if (key.contains('protect resources')) {
      return _operationAsset('protect_resources_card.webp');
    }
    if (key.contains('complete blueprint')) {
      return _operationAsset('complete_blueprint_collection_card.webp');
    }
    if (key.contains('blueprint')) {
      return _operationAsset('complete_blueprint_collection_card.webp');
    }
    if (key.contains('review trade') ||
        key.contains('trade activity') ||
        key.contains('trade opportunity')) {
      return _operationAsset('review_trade_activity_card.webp');
    }
    if (key.contains('clearer skies') || key.contains('progress clearer')) {
      return _operationAsset('progress_clearer_skies_card.webp');
    }
    if (key.contains('track quests') || key.contains('quest progress')) {
      return _operationAsset('track_quests_card.webp');
    }
    if (key.contains('finish favourite loadout')) {
      return _operationAsset('finish_favourite_loadout_card.webp');
    }
    if (key.contains('review favourite loadout')) {
      return _operationAsset('review_favourite_loadout_card.webp');
    }
    if (key.contains('favourite loadout') || key.contains('loadout')) {
      return _operationAsset('finish_favourite_loadout_card.webp');
    }
    if (key.contains('clear inventory')) {
      return _operationAsset('clear_inventory_card.webp');
    }
    if (key.contains('weekly raid')) {
      return _operationAsset('weekly_raid_card.webp');
    }
    if (key.contains('nomadic trader')) {
      return _operationAsset('check_nomadic_trader_card.webp');
    }
    if (key.contains('claim operations')) {
      return _operationAsset('claim_operations_card.webp');
    }
    if (key.contains('operations') || key.contains('reward vault')) {
      return _operationAsset('claim_operations_card.webp');
    }
    if (key.contains('search')) {
      return _operationAsset('search_app_card.webp');
    }
    return fallback;
  }

  String _imageForAction(ArcCommandAction action) {
    switch (action.intent) {
      case ArcCommandActionIntent.favouriteLoadout:
        return _operationAsset('finish_favourite_loadout_card.webp');
      case ArcCommandActionIntent.smartTrade:
        return _operationAsset('review_trade_activity_card.webp');
      case ArcCommandActionIntent.nomadicTrader:
        return _operationAsset('check_nomadic_trader_card.webp');
      case ArcCommandActionIntent.operations:
        return _operationAsset('claim_operations_card.webp');
      case ArcCommandActionIntent.comingSoon:
        return _operationAsset('arc_command_centre_background.webp');
      case ArcCommandActionIntent.toolDeck:
        return _operationAsset('arc_tool_deck_background.webp');
      case ArcCommandActionIntent.route:
      case ArcCommandActionIntent.placeholder:
        final route = action.routeName ?? '';
        if (route.contains('raid-intelligence') ||
            route.contains('raid-planner')) {
          return _operationAsset('weekly_raid_card.webp');
        }
        if (route.contains('blueprint')) {
          return _operationAsset('complete_blueprint_collection_card.webp');
        }
        if (route.contains('bench')) {
          return _operationAsset('upgrade_gunsmith_card.webp');
        }
        if (route.contains('quest')) {
          return _operationAsset('track_quests_card.webp');
        }
        if (route.contains('resource') || route.contains('scrappy')) {
          return _operationAsset('missing_resources_card.webp');
        }
        return _operationAsset('arc_command_centre_background.webp');
    }
  }

  BoxDecoration _cardDecoration(Color accent, {double radius = 20}) {
    return AppTheme.tradingCardDecoration(
      radius: radius,
      borderColor: accent.withValues(alpha: 0.30),
      backgroundColor: AppTheme.cardBackgroundDeep.withValues(alpha: 0.92),
    ).copyWith(
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: 0.10),
          blurRadius: 22,
          spreadRadius: 1,
        ),
      ],
    );
  }

  BoxDecoration _imageDecoration(
    String image,
    Color accent, {
    double radius = 20,
    double darken = 0.47,
  }) {
    return _cardDecoration(accent, radius: radius).copyWith(
      image: DecorationImage(
        image: AssetImage(image),
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(
          Colors.black.withValues(alpha: darken),
          BlendMode.darken,
        ),
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.cardBackgroundDeep.withValues(alpha: 0.88),
          Colors.black.withValues(alpha: 0.58),
          accent.withValues(alpha: 0.10),
        ],
      ),
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

class _CommandMoveData {
  const _CommandMoveData({
    required this.title,
    required this.detail,
    required this.label,
    required this.status,
    required this.action,
    required this.icon,
    required this.accent,
    required this.image,
    required this.progressPercent,
  });

  final String title;
  final String detail;
  final String label;
  final ArcCommandStatus status;
  final ArcCommandAction action;
  final IconData icon;
  final Color accent;
  final String image;
  final int? progressPercent;
}

class _CommandTileData {
  const _CommandTileData({
    required this.title,
    required this.value,
    required this.detail,
    required this.status,
    required this.action,
    required this.image,
  });

  final String title;
  final String value;
  final String detail;
  final ArcCommandStatus status;
  final ArcCommandAction action;
  final String image;
}
