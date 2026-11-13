import 'package:uag_arc_raiders_hub/features/notifications/models/uag_notification_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_user_personalisation_profile.dart';

class UagPersonalisedNotificationMapper {
  const UagPersonalisedNotificationMapper._();

  static ArcPersonalisationNotificationCategory categoryFor(
    UagNotificationType type,
  ) {
    switch (type) {
      case UagNotificationType.trading:
      case UagNotificationType.tradeOffer:
      case UagNotificationType.tradeAccepted:
      case UagNotificationType.tradeRejected:
      case UagNotificationType.tradeReminder:
        return ArcPersonalisationNotificationCategory.tradeActivity;
      case UagNotificationType.watchMatch:
      case UagNotificationType.queueRelease:
        return ArcPersonalisationNotificationCategory.listingMatches;
      case UagNotificationType.blueprintReportConfirmed:
        return ArcPersonalisationNotificationCategory.blueprintWatches;
      case UagNotificationType.favouriteRider:
        return ArcPersonalisationNotificationCategory.favouriteRiderActivity;
      case UagNotificationType.matchmaking:
      case UagNotificationType.matchmakingSession:
        return ArcPersonalisationNotificationCategory.matchRiderActivity;
      case UagNotificationType.reminder:
        return ArcPersonalisationNotificationCategory.availabilityReminders;
      case UagNotificationType.communityIntelConfirmation:
      case UagNotificationType.communityIntelDispute:
        return ArcPersonalisationNotificationCategory.raidIntelligence;
      case UagNotificationType.operations:
      case UagNotificationType.reward:
      case UagNotificationType.itemRelevanceWarning:
        return ArcPersonalisationNotificationCategory.questProgress;
      case UagNotificationType.contractOffered:
      case UagNotificationType.contractAccepted:
      case UagNotificationType.contractEvidenceSubmitted:
      case UagNotificationType.contractRewardReady:
      case UagNotificationType.contractDispute:
      case UagNotificationType.conductReportResponse:
      case UagNotificationType.conductReportOutcome:
        return ArcPersonalisationNotificationCategory.futureBountyActivity;
      case UagNotificationType.announcement:
      case UagNotificationType.openBeta:
      case UagNotificationType.creatorReferral:
      case UagNotificationType.creatorPaidConversion:
      case UagNotificationType.creatorCommissionChanged:
      case UagNotificationType.subscriptionEvent:
      case UagNotificationType.paymentFailure:
      case UagNotificationType.foundingSupporterEvent:
      case UagNotificationType.communityEvent:
      case UagNotificationType.postSessionFeedback:
      case UagNotificationType.adminAnnouncement:
      case UagNotificationType.betaUpdate:
      case UagNotificationType.featureUpdate:
      case UagNotificationType.termsPrivacyUpdate:
      case UagNotificationType.ageVerificationRequired:
      case UagNotificationType.maintenance:
        return ArcPersonalisationNotificationCategory.systemAnnouncements;
    }
  }

  static bool allowsType({
    required UagNotificationType type,
    required ArcUserPersonalisationProfile personalisation,
  }) {
    return personalisation.includesNotificationCategory(categoryFor(type));
  }
}
