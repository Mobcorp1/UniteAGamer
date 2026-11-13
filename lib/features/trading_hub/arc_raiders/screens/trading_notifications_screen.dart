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
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
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
    _InboxFilter.matchmaking => 'Match Raider',
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
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not mark messages as read. Try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openNotification(TradingNotification notification) async {
    try {
      await _repository.markNotificationRead(notification.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message opened, but read status could not sync.'),
          ),
        );
      }
    }
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
    try {
      await _repository.deleteNotification(notification.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Message deleted.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete the message. Try again.'),
        ),
      );
    }
  }

  IconData _filterIcon(_InboxFilter filter) => switch (filter) {
    _InboxFilter.all => Icons.inbox_outlined,
    _InboxFilter.unread => Icons.mark_email_unread_outlined,
    _InboxFilter.trading => Icons.swap_horiz_rounded,
    _InboxFilter.matchmaking => Icons.groups_2_outlined,
    _InboxFilter.operations => Icons.radar_rounded,
    _InboxFilter.community => Icons.forum_outlined,
    _InboxFilter.announcements => Icons.campaign_outlined,
  };

  Color _filterAccent(_InboxFilter filter) => switch (filter) {
    _InboxFilter.unread => ArcUiTokens.secondaryAccent,
    _InboxFilter.trading => ArcUiTokens.primaryAccent,
    _InboxFilter.matchmaking => ArcUiTokens.secondaryAccent,
    _InboxFilter.operations => ArcUiTokens.attentionAccent,
    _InboxFilter.community => ArcUiTokens.success,
    _InboxFilter.announcements => ArcUiTokens.warning,
    _InboxFilter.all => ArcUiTokens.primaryAccent,
  };

  Widget _buildFilterStrip() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: _InboxFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _InboxFilter.values[index];
          final selected = _filter == filter;
          final accent = _filterAccent(filter);
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => setState(() => _filter = filter),
              child: ArcTacticalStatusPill(
                label: _filterLabel(filter),
                icon: _filterIcon(filter),
                accent: accent,
                selected: selected,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(TradingNotification item) {
    final color = _typeColor(item.type);

    return Dismissible(
      key: ValueKey(item.id),
      direction: item.read
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.tradingDanger.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: AppTheme.tradingDanger,
        ),
      ),
      onDismissed: (_) => _deleteNotification(item),
      child: ElectricChargeBorder(
        active: !item.read,
        radius: 18,
        child: ArcRaidersSectionCard(
          accent: color,
          radius: 18,
          selected: false,
          padding: const EdgeInsets.all(14),
          onTap: () => _openNotification(item),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.30)),
                ),
                child: Icon(
                  item.read
                      ? Icons.mail_outline_rounded
                      : Icons.mark_email_unread_rounded,
                  color: color,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: ArcUiTokens.cardTitle(
                              fontSize: 16,
                              color: ArcUiTokens.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: ArcUiTokens.textTertiary,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        ArcTacticalStatusPill(
                          label: item.typeLabel,
                          accent: color,
                          selected: !item.read,
                        ),
                        ArcTacticalStatusPill(
                          label: item.read ? 'Read' : 'Unread',
                          icon: item.read
                              ? Icons.done_rounded
                              : Icons.fiber_manual_record_rounded,
                          accent: item.read
                              ? ArcUiTokens.textTertiary
                              : ArcUiTokens.secondaryAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      item.body,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: ArcUiTokens.body(
                        fontSize: 13,
                        color: ArcUiTokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(item.createdAt),
                      style: ArcUiTokens.metadata(
                        color: ArcUiTokens.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'Communications Centre',
                style: ArcUiTokens.sectionTitle(
                  fontSize: 20,
                  color: ArcUiTokens.primaryAccent,
                ),
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
      bottomNavigationBar: widget.showAppBar
          ? const ArcCompanionBottomDock(activeLabel: 'messages')
          : null,
      body: ArcRaidersScreenShell(
        showAdBanner: false,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: StreamBuilder<List<TradingNotification>>(
                stream: _repository.watchNotifications(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: ArcRaidersStatePanel(
                          title: 'Communications unavailable',
                          message:
                              'Messages and alerts could not load right now.',
                          icon: Icons.cloud_off_rounded,
                          accent: ArcUiTokens.warning,
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: ArcRaidersStatePanel(
                          title: 'Syncing communications',
                          message:
                              'Checking trade replies, squad signals and UAG updates.',
                          icon: Icons.sync_rounded,
                          compact: true,
                        ),
                      ),
                    );
                  }

                  final all = snapshot.data ?? const <TradingNotification>[];
                  final unread = all.where((item) => !item.read).length;
                  final visible = all.where(_matches).toList(growable: false);

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const ArcRaidersHeroBanner(
                              title: 'COMMUNICATIONS CENTRE',
                              subtitle:
                                  'Trade replies, Match Raider signals, operations updates and UAG broadcasts in one command feed.',
                              accent: ArcUiTokens.primaryAccent,
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ArcTacticalStatTile(
                                  label: 'Unread',
                                  value: unread.toString(),
                                  icon: Icons.mark_email_unread_outlined,
                                  accent: unread > 0
                                      ? ArcUiTokens.secondaryAccent
                                      : ArcUiTokens.success,
                                ),
                                ArcTacticalStatTile(
                                  label: 'Total',
                                  value: all.length.toString(),
                                  icon: Icons.inbox_outlined,
                                  accent: ArcUiTokens.primaryAccent,
                                ),
                                ArcTacticalStatTile(
                                  label: 'View',
                                  value: _filterLabel(_filter),
                                  icon: _filterIcon(_filter),
                                  accent: _filterAccent(_filter),
                                ),
                              ],
                            ),
                            if (unread > 0) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  style: ArcUiTokens.textButtonStyle(
                                    accent: ArcUiTokens.primaryAccent,
                                  ),
                                  onPressed: _busy ? null : _markAllRead,
                                  icon: const Icon(Icons.done_all_rounded),
                                  label: Text(
                                    _busy ? 'Updating...' : 'Mark all read',
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      _buildFilterStrip(),
                      const SizedBox(height: 4),
                      Expanded(
                        child: visible.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  12,
                                  14,
                                  104,
                                ),
                                child: Center(
                                  child: ArcRaidersStatePanel(
                                    title: all.isEmpty
                                        ? 'No communications yet'
                                        : 'No matching messages',
                                    message: all.isEmpty
                                        ? 'Messages, alerts, broadcasts and system updates will appear here.'
                                        : 'Choose another communications filter to widen the feed.',
                                    icon: all.isEmpty
                                        ? Icons.inbox_outlined
                                        : Icons.filter_alt_off_outlined,
                                    accent: all.isEmpty
                                        ? ArcUiTokens.primaryAccent
                                        : _filterAccent(_filter),
                                    compact: true,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  10,
                                  14,
                                  104,
                                ),
                                itemCount: visible.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) =>
                                    _buildNotificationCard(visible[index]),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
