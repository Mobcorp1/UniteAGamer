import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/trading_notification.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/repositories/trading_repository.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_listings_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_my_offers_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_trade_sessions_screen.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class TradingNotificationsScreen extends StatelessWidget {
  static const routeName = '/trading-hub/arc-raiders/notifications';

  const TradingNotificationsScreen({super.key});

  Color _typeColor(TradingNotificationType type) {
    switch (type) {
      case TradingNotificationType.offerReceived:
        return AppTheme.neonPink;
      case TradingNotificationType.offerAccepted:
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
      case TradingNotificationType.duplicateMatch:
      case TradingNotificationType.mutualMatch:
        return AppTheme.tradingSuccess;
      case TradingNotificationType.collectionRequest:
        return AppTheme.neonPink;
    }
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Just now';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year • $hour:$minute';
  }

  Future<void> _openNotification(
    BuildContext context,
    TradingNotification notification,
  ) async {
    final repository = TradingRepository();
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
        break;
      case TradingNotificationType.duplicateMatch:
      case TradingNotificationType.mutualMatch:
      case TradingNotificationType.collectionRequest:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TradingListingsScreen()),
        );
        break;
      default:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TradingTradeSessionsScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = TradingRepository();

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: AppTheme.tradingHeading(fontSize: 25),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          SafeArea(
            child: StreamBuilder<List<TradingNotification>>(
              stream: repository.watchNotifications(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.neonCyan,
                    ),
                  );
                }

                final notifications = snapshot.data ?? const <TradingNotification>[];
                if (notifications.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: AppTheme.pagePadding,
                      child: Text(
                        'No trading notifications yet. Offer updates, session bookings and match alerts will land here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.tradingMutedText,
                          fontSize: 16,
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

                    return InkWell(
                      onTap: () => _openNotification(context, notification),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: AppTheme.sectionCardPadding,
                        decoration: AppTheme.tradingCardDecoration(),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                color: notification.read ? AppTheme.tradingFaintText : color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      Text(
                                        notification.title,
                                        style: AppTheme.tradingHeading(fontSize: 20),
                                      ),
                                      Container(
                                        padding: AppTheme.pillPadding,
                                        decoration: AppTheme.tradingPillDecoration(color: color),
                                        child: Text(
                                          notification.typeLabel,
                                          style: TextStyle(
                                            color: color,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    notification.body,
                                    style: TextStyle(
                                      color: AppTheme.tradingMutedText,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatDate(notification.createdAt),
                                    style: TextStyle(
                                      color: AppTheme.tradingFaintText,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: AppTheme.tradingFaintText,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
