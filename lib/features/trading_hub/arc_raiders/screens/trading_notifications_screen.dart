import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_notification.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/trading_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_command_centre_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_blueprint_watches_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_listing_detail_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_listing_queues_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_listings_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_my_offers_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_trade_sessions_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/screens/build/feedback_screen.dart';
import 'package:uag_arc_raiders_hub/widgets/electric_charge_border.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

enum _InboxFilter {
  all,
  unread,
  trading,
  matchmaking,
  operations,
  community,
  announcements,
}

class TradingNotificationsScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/notifications';

  const TradingNotificationsScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<TradingNotificationsScreen> createState() =>
      _TradingNotificationsScreenState();
}

class _TradingNotificationsScreenState
    extends State<TradingNotificationsScreen> {
  final TradingRepository _repository = TradingRepository();
  _InboxFilter _filter = _InboxFilter.all;
  bool _busy = false;

  String _filterLabel(_InboxFilter filter) => switch (filter) {
    _InboxFilter.all => 'All',
    _InboxFilter.unread => 'Unread',
    _InboxFilter.trading => 'Trading',
    _InboxFilter.matchmaking => 'Match Rider',
    _InboxFilter.operations => 'Operations & Rewards',
    _InboxFilter.community => 'Community',
    _InboxFilter.announcements => 'Announcements',
  };

  bool _matches(TradingNotification item) {
    switch (_filter) {
      case _InboxFilter.all:
        return true;
      case _InboxFilter.unread:
        return !item.read;
      case _InboxFilter.trading:
        return {
          TradingNotificationType.offerReceived,
          TradingNotificationType.offerAccepted,
          TradingNotificationType.offerDeclined,
          TradingNotificationType.offerCancelled,
          TradingNotificationType.sessionCreated,
          TradingNotificationType.sessionUpdated,
          TradingNotificationType.sessionReady,
          TradingNotificationType.sessionOutcome,
          TradingNotificationType.duplicateMatch,
          TradingNotificationType.mutualMatch,
          TradingNotificationType.collectionRequest,
          TradingNotificationType.blueprintWatchMatch,
          TradingNotificationType.tradeOfferNeedsResponse,
          TradingNotificationType.queuedListingReleased,
          TradingNotificationType.queuedListingBlocked,
          TradingNotificationType.tradeReadyPreparation,
          TradingNotificationType.tradeObjectiveOpportunity,
          TradingNotificationType.scheduledTradeReminder,
        }.contains(item.type);
      case _InboxFilter.matchmaking:
        return item.type == TradingNotificationType.availabilityOverlap;
      case _InboxFilter.operations:
        return item.type == TradingNotificationType.operations ||
            item.type == TradingNotificationType.reward ||
            item.type == TradingNotificationType.reminder;
      case _InboxFilter.community:
        return item.type == TradingNotificationType.communityEvent ||
            item.type == TradingNotificationType.favouriteRiderListing ||
            item.type ==
                TradingNotificationType.favouriteRiderAcquisitionSignal ||
            item.type == TradingNotificationType.feedbackReply ||
            item.type == TradingNotificationType.postSessionFeedback;
      case _InboxFilter.announcements:
        return item.type == TradingNotificationType.announcement ||
            item.type == TradingNotificationType.openBeta ||
            item.type == TradingNotificationType.maintenance;
    }
  }

  Color _typeColor(TradingNotificationType type) {
    if ({
      TradingNotificationType.offerDeclined,
      TradingNotificationType.offerCancelled,
      TradingNotificationType.queuedListingBlocked,
    }.contains(type)) {
      return AppTheme.tradingDanger;
    }
    if ({
      TradingNotificationType.offerAccepted,
      TradingNotificationType.duplicateMatch,
      TradingNotificationType.mutualMatch,
      TradingNotificationType.queuedListingReleased,
    }.contains(type)) {
      return AppTheme.tradingSuccess;
    }
    if ({
      TradingNotificationType.offerReceived,
      TradingNotificationType.collectionRequest,
      TradingNotificationType.tradeOfferNeedsResponse,
    }.contains(type)) {
      return AppTheme.neonPink;
    }
    return AppTheme.neonCyan;
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Just now';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year}  $hour:$minute';
  }

  Future<void> _markAllRead() async {
    setState(() => _busy = true);
    try {
      await _repository.markAllNotificationsRead();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openNotification(TradingNotification notification) async {
    await _repository.markNotificationRead(notification.id);
    if (!mounted) return;
    final route = notification.route.trim().isNotEmpty
        ? notification.route.trim()
        : notification.deepLink.trim();
    if (route.startsWith('/')) {
      Navigator.of(context).pushNamed(route);
      return;
    }
    switch (notification.type) {
      case TradingNotificationType.offerReceived:
      case TradingNotificationType.tradeOfferNeedsResponse:
      case TradingNotificationType.offerAccepted:
      case TradingNotificationType.offerDeclined:
      case TradingNotificationType.offerCancelled:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TradingMyOffersScreen()),
        );
        return;
      case TradingNotificationType.blueprintWatchMatch:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const TradingBlueprintWatchesScreen(),
          ),
        );
        return;
      case TradingNotificationType.queuedListingReleased:
      case TradingNotificationType.queuedListingBlocked:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TradingListingQueuesScreen()),
        );
        return;
      case TradingNotificationType.sessionCreated:
      case TradingNotificationType.sessionUpdated:
      case TradingNotificationType.sessionReady:
      case TradingNotificationType.sessionOutcome:
      case TradingNotificationType.availabilityOverlap:
      case TradingNotificationType.scheduledTradeReminder:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TradingTradeSessionsScreen()),
        );
        return;
      case TradingNotificationType.feedbackReply:
      case TradingNotificationType.postSessionFeedback:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const FeedbackScreen(initialTabIndex: 1),
          ),
        );
        return;
      case TradingNotificationType.duplicateMatch:
      case TradingNotificationType.mutualMatch:
      case TradingNotificationType.collectionRequest:
      case TradingNotificationType.favouriteRiderListing:
      case TradingNotificationType.favouriteRiderAcquisitionSignal:
      case TradingNotificationType.tradeObjectiveOpportunity:
        if (notification.hasListingTarget) {
          final listing = await _repository.getListingById(
            notification.listingId,
          );
          if (!mounted) return;
          if (listing != null && listing.isLive) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TradingListingDetailScreen(listing: listing),
              ),
            );
            return;
          }
        }
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TradingListingsScreen()),
          );
        }
        return;
      case TradingNotificationType.tradeReadyPreparation:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TradingListingsScreen()),
        );
        return;
      case TradingNotificationType.announcement:
      case TradingNotificationType.openBeta:
      case TradingNotificationType.operations:
      case TradingNotificationType.reward:
      case TradingNotificationType.itemRelevanceWarning:
      case TradingNotificationType.blueprintReportConfirmed:
      case TradingNotificationType.communityIntelConfirmation:
      case TradingNotificationType.communityIntelDispute:
      case TradingNotificationType.conductReportResponse:
      case TradingNotificationType.conductReportOutcome:
      case TradingNotificationType.creatorReferral:
      case TradingNotificationType.creatorPaidConversion:
      case TradingNotificationType.creatorCommissionChanged:
      case TradingNotificationType.subscriptionEvent:
      case TradingNotificationType.paymentFailure:
      case TradingNotificationType.foundingSupporterEvent:
      case TradingNotificationType.ageVerificationRequired:
      case TradingNotificationType.communityEvent:
      case TradingNotificationType.reminder:
      case TradingNotificationType.maintenance:
        Navigator.of(context).pushNamed(ArcCommandCentreScreen.routeName);
        return;
    }
  }

  Future<void> _deleteNotification(TradingNotification notification) async {
    await _repository.deleteNotification(notification.id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Message deleted.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: Colors.transparent,
              title: Text(
                'Communications Centre',
                style: AppTheme.tradingHeading(fontSize: 25),
              ),
              actions: [
                IconButton(
                  tooltip: 'Mark all as read',
                  onPressed: _busy ? null : _markAllRead,
                  icon: const Icon(Icons.done_all_rounded),
                ),
              ],
            )
          : null,
      body: Stack(
        children: [
          const Positioned.fill(child: ArcRaidersScreenBackdrop()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: StreamBuilder<List<TradingNotification>>(
                  stream: _repository.watchNotifications(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Could not load messages.\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: AppTheme.bodyTextStyle(
                            fontSize: 15,
                            color: AppTheme.tradingDanger,
                          ),
                        ),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.neonCyan,
                        ),
                      );
                    }
                    final all = snapshot.data ?? const <TradingNotification>[];
                    final unread = all.where((item) => !item.read).length;
                    final visible = all.where(_matches).toList(growable: false);
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '$unread unread • ${all.length} total',
                                  style: AppTheme.bodyTextStyle(
                                    fontSize: 13,
                                    color: AppTheme.tradingMutedText,
                                  ),
                                ),
                              ),
                              if (unread > 0)
                                TextButton.icon(
                                  onPressed: _busy ? null : _markAllRead,
                                  icon: const Icon(Icons.done_all_rounded),
                                  label: const Text('Mark all read'),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 48,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            scrollDirection: Axis.horizontal,
                            itemCount: _InboxFilter.values.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final filter = _InboxFilter.values[index];
                              return ChoiceChip(
                                label: Text(_filterLabel(filter)),
                                selected: _filter == filter,
                                onSelected: (_) =>
                                    setState(() => _filter = filter),
                              );
                            },
                          ),
                        ),
                        Expanded(
                          child: visible.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      all.isEmpty
                                          ? 'Your messages, alerts, broadcasts and system updates will appear here.'
                                          : 'No messages match this filter.',
                                      textAlign: TextAlign.center,
                                      style: AppTheme.bodyTextStyle(
                                        fontSize: 16,
                                        color: AppTheme.tradingMutedText,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    12,
                                    14,
                                    104,
                                  ),
                                  itemCount: visible.length,
                                  itemBuilder: (context, index) {
                                    final item = visible[index];
                                    final color = _typeColor(item.type);
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 14,
                                      ),
                                      child: Dismissible(
                                        key: ValueKey(item.id),
                                        direction: item.read
                                            ? DismissDirection.endToStart
                                            : DismissDirection.none,
                                        background: Container(
                                          alignment: Alignment.centerRight,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.tradingDanger
                                                .withValues(alpha: 0.22),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.delete_outline_rounded,
                                            color: AppTheme.tradingDanger,
                                          ),
                                        ),
                                        onDismissed: (_) =>
                                            _deleteNotification(item),
                                        child: ElectricChargeBorder(
                                          active: !item.read,
                                          radius: 20,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            onTap: () =>
                                                _openNotification(item),
                                            child: Container(
                                              padding:
                                                  AppTheme.sectionCardPadding,
                                              decoration:
                                                  AppTheme.tradingCardDecoration(
                                                    borderColor: !item.read
                                                        ? color.withValues(
                                                            alpha: 0.45,
                                                          )
                                                        : AppTheme
                                                              .tradingCardBorder,
                                                  ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    width: 10,
                                                    height: 10,
                                                    margin:
                                                        const EdgeInsets.only(
                                                          top: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: !item.read
                                                          ? color
                                                          : AppTheme
                                                                .tradingFaintText,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Wrap(
                                                          spacing: 8,
                                                          runSpacing: 8,
                                                          children: [
                                                            Text(
                                                              item.title,
                                                              style:
                                                                  AppTheme.tradingHeading(
                                                                    fontSize:
                                                                        20,
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                            ),
                                                            Container(
                                                              padding: AppTheme
                                                                  .pillPadding,
                                                              decoration:
                                                                  AppTheme.tradingPillDecoration(
                                                                    color:
                                                                        color,
                                                                  ),
                                                              child: Text(
                                                                item.typeLabel,
                                                                style:
                                                                    AppTheme.bodyTextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      color:
                                                                          color,
                                                                      isBold:
                                                                          true,
                                                                    ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        Text(
                                                          item.body,
                                                          style: AppTheme.bodyTextStyle(
                                                            fontSize: 14,
                                                            color: AppTheme
                                                                .tradingMutedText,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        Text(
                                                          _formatDate(
                                                            item.createdAt,
                                                          ),
                                                          style: AppTheme.bodyTextStyle(
                                                            fontSize: 12,
                                                            color: AppTheme
                                                                .tradingFaintText,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.chevron_right_rounded,
                                                    color: AppTheme
                                                        .tradingFaintText,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
