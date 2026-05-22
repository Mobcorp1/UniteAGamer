import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/trading_notification.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/repositories/trading_repository.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_listings_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_my_offers_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_trade_sessions_screen.dart';
import 'package:uag_traders_hub/screens/build/feedback_screen.dart';
import 'package:uag_traders_hub/widgets/electric_charge_border.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class TradingNotificationsScreen extends StatelessWidget {
  static const routeName = '/trading-hub/arc-raiders/notifications';

  const TradingNotificationsScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  Color _typeColor(TradingNotificationType type) {
    switch (type) {
      case TradingNotificationType.offerReceived:
        return AppTheme.neonPink;
      case TradingNotificationType.offerAccepted:
      case TradingNotificationType.duplicateMatch:
      case TradingNotificationType.mutualMatch:
        return AppTheme.tradingSuccess;
      case TradingNotificationType.offerDeclined:
      case TradingNotificationType.offerCancelled:
        return AppTheme.tradingDanger;
      case TradingNotificationType.sessionCreated:
      case TradingNotificationType.sessionUpdated:
      case TradingNotificationType.sessionReady:
        return AppTheme.neonCyan;
      case TradingNotificationType.sessionOutcome:
        return AppTheme.warningAmber;
      case TradingNotificationType.collectionRequest:
        return AppTheme.neonPink;
      case TradingNotificationType.feedbackReply:
        return AppTheme.neonCyan;
    }
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Just now';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year} • $hour:$minute';
  }

  Future<void> _openNotification(
    BuildContext context,
    TradingRepository repository,
    TradingNotification notification,
  ) async {
    await repository.markNotificationRead(notification.id);
    if (!context.mounted) return;

    switch (notification.type) {
      case TradingNotificationType.offerReceived:
      case TradingNotificationType.offerAccepted:
      case TradingNotificationType.offerDeclined:
      case TradingNotificationType.offerCancelled:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TradingMyOffersScreen()),
        );
        return;
      case TradingNotificationType.duplicateMatch:
      case TradingNotificationType.mutualMatch:
      case TradingNotificationType.collectionRequest:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TradingListingsScreen()),
        );
        return;
      case TradingNotificationType.sessionCreated:
      case TradingNotificationType.sessionUpdated:
      case TradingNotificationType.sessionReady:
      case TradingNotificationType.sessionOutcome:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TradingTradeSessionsScreen()),
        );
        return;
      case TradingNotificationType.feedbackReply:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const FeedbackScreen(initialTabIndex: 1),
          ),
        );
        return;
    }
  }

  Future<void> _deleteNotification(
    BuildContext context,
    TradingRepository repository,
    TradingNotification notification,
  ) async {
    try {
      await repository.deleteNotification(notification.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notification deleted.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete notification: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = TradingRepository();

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: showAppBar
          ? AppBar(
              title: Text(
                'Notifications',
                style: AppTheme.tradingHeading(fontSize: 25),
              ),
            )
          : null,
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppTheme.pageMaxWidth,
                ),
                child: StreamBuilder<List<TradingNotification>>(
                  stream: repository.watchNotifications(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: AppTheme.pagePadding,
                          child: Text(
                            'Could not load notifications.\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: AppTheme.bodyTextStyle(
                              fontSize: 15,
                              color: AppTheme.tradingDanger,
                            ),
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

                    final notifications =
                        snapshot.data ?? <TradingNotification>[];

                    if (notifications.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: AppTheme.pagePadding,
                          child: Text(
                            'No trading notifications yet. Offer updates, booking proposals, confirmed slots and session alerts will land here.',
                            textAlign: TextAlign.center,
                            style: AppTheme.bodyTextStyle(
                              fontSize: 16,
                              color: AppTheme.tradingMutedText,
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: AppTheme.pagePadding,
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        final color = _typeColor(notification.type);
                        final highlighted = !notification.read;
                        final canDelete = notification.read;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Dismissible(
                            key: ValueKey(notification.id),
                            direction: canDelete
                                ? DismissDirection.endToStart
                                : DismissDirection.none,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.tradingDanger.withValues(
                                  alpha: 0.22,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                color: AppTheme.tradingDanger,
                              ),
                            ),
                            confirmDismiss: canDelete
                                ? (_) async => true
                                : (_) async => false,
                            onDismissed: (_) => _deleteNotification(
                              context,
                              repository,
                              notification,
                            ),
                            child: ElectricChargeBorder(
                              active: highlighted,
                              radius: 20,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => _openNotification(
                                  context,
                                  repository,
                                  notification,
                                ),
                                child: Container(
                                  padding: AppTheme.sectionCardPadding,
                                  decoration: AppTheme.tradingCardDecoration(
                                    borderColor: highlighted
                                        ? color.withValues(alpha: 0.45)
                                        : AppTheme.tradingCardBorder,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        margin: const EdgeInsets.only(top: 6),
                                        decoration: BoxDecoration(
                                          color: highlighted
                                              ? color
                                              : AppTheme.tradingFaintText,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                Text(
                                                  notification.title,
                                                  style:
                                                      AppTheme.tradingHeading(
                                                        fontSize: 20,
                                                        color: Colors.white,
                                                      ),
                                                ),
                                                Container(
                                                  padding: AppTheme.pillPadding,
                                                  decoration:
                                                      AppTheme.tradingPillDecoration(
                                                        color: color,
                                                      ),
                                                  child: Text(
                                                    notification.typeLabel,
                                                    style:
                                                        AppTheme.bodyTextStyle(
                                                          fontSize: 12,
                                                          color: color,
                                                          isBold: true,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              notification.body,
                                              style: AppTheme.bodyTextStyle(
                                                fontSize: 14,
                                                color:
                                                    AppTheme.tradingMutedText,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              _formatDate(
                                                notification.createdAt,
                                              ),
                                              style: AppTheme.bodyTextStyle(
                                                fontSize: 12,
                                                color:
                                                    AppTheme.tradingFaintText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        children: [
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            color: AppTheme.tradingFaintText,
                                          ),
                                          if (notification.read)
                                            IconButton(
                                              tooltip: 'Delete notification',
                                              onPressed: () =>
                                                  _deleteNotification(
                                                    context,
                                                    repository,
                                                    notification,
                                                  ),
                                              icon: Icon(
                                                Icons.delete_outline_rounded,
                                                size: 20,
                                                color: AppTheme.tradingDanger,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
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
