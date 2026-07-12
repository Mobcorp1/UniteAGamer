import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_watch.dart';

class ArcTradeNotificationDecision {
  const ArcTradeNotificationDecision({
    required this.shouldNotifyNow,
    required this.queueForNextLogin,
    required this.includeInDigest,
    required this.reason,
  });

  final bool shouldNotifyNow;
  final bool queueForNextLogin;
  final bool includeInDigest;
  final String reason;
}

class ArcTradeNotificationEngine {
  const ArcTradeNotificationEngine();

  ArcTradeNotificationDecision evaluate({
    required ArcBlueprintWatchNotificationPreference preference,
    required bool favouriteRiderEvent,
    required bool userAvailableNow,
    required bool sellerAvailableNow,
    required bool quietHoursActive,
    required bool watchedTradeReady,
  }) {
    if (preference == ArcBlueprintWatchNotificationPreference.muted) {
      return const ArcTradeNotificationDecision(
        shouldNotifyNow: false,
        queueForNextLogin: false,
        includeInDigest: false,
        reason: 'Muted by preference',
      );
    }

    if (preference ==
            ArcBlueprintWatchNotificationPreference.favouriteRidersOnly &&
        !favouriteRiderEvent) {
      return const ArcTradeNotificationDecision(
        shouldNotifyNow: false,
        queueForNextLogin: false,
        includeInDigest: true,
        reason: 'Waiting for Favourite Rider activity',
      );
    }

    if (preference == ArcBlueprintWatchNotificationPreference.digest) {
      return const ArcTradeNotificationDecision(
        shouldNotifyNow: false,
        queueForNextLogin: false,
        includeInDigest: true,
        reason: 'Digest preference',
      );
    }

    if (preference == ArcBlueprintWatchNotificationPreference.nextLogin) {
      return const ArcTradeNotificationDecision(
        shouldNotifyNow: false,
        queueForNextLogin: true,
        includeInDigest: false,
        reason: 'Next login preference',
      );
    }

    if (quietHoursActive) {
      return const ArcTradeNotificationDecision(
        shouldNotifyNow: false,
        queueForNextLogin: true,
        includeInDigest: false,
        reason: 'Quiet hours active',
      );
    }

    if (preference ==
            ArcBlueprintWatchNotificationPreference.duringAvailabilityOnly &&
        (!userAvailableNow || !sellerAvailableNow)) {
      return const ArcTradeNotificationDecision(
        shouldNotifyNow: false,
        queueForNextLogin: true,
        includeInDigest: false,
        reason: 'No shared availability window',
      );
    }

    return ArcTradeNotificationDecision(
      shouldNotifyNow: watchedTradeReady || sellerAvailableNow,
      queueForNextLogin: !(watchedTradeReady || sellerAvailableNow),
      includeInDigest: false,
      reason: watchedTradeReady
          ? 'Watched trade is ready'
          : sellerAvailableNow
          ? 'Seller is available'
          : 'Waiting for availability',
    );
  }
}
