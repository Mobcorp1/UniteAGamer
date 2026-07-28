import 'package:cloud_firestore/cloud_firestore.dart';

enum TradingNotificationType {
  offerReceived,
  offerAccepted,
  offerDeclined,
  offerCancelled,
  sessionCreated,
  sessionUpdated,
  sessionReady,
  sessionOutcome,
  duplicateMatch,
  mutualMatch,
  collectionRequest,
  feedbackReply,
  blueprintWatchMatch,
  favouriteRiderListing,
  favouriteRiderAcquisitionSignal,
  tradeOfferNeedsResponse,
  queuedListingReleased,
  queuedListingBlocked,
  tradeReadyPreparation,
  tradeObjectiveOpportunity,
  availabilityOverlap,
  scheduledTradeReminder,
  announcement,
  openBeta,
  operations,
  reward,
  itemRelevanceWarning,
  blueprintReportConfirmed,
  communityIntelConfirmation,
  communityIntelDispute,
  conductReportResponse,
  conductReportOutcome,
  creatorReferral,
  creatorPaidConversion,
  creatorCommissionChanged,
  subscriptionEvent,
  paymentFailure,
  foundingSupporterEvent,
  ageVerificationRequired,
  communityEvent,
  reminder,
  postSessionFeedback,
  maintenance,
}

TradingNotificationType tradingNotificationTypeFromWire(String rawType) {
  final normalized = rawType.trim();
  return TradingNotificationType.values.firstWhere(
    (value) => value.name == normalized,
    orElse: () {
      switch (normalized) {
        case 'open_beta':
          return TradingNotificationType.openBeta;
        case 'community_event':
          return TradingNotificationType.communityEvent;
        case 'post_session_feedback':
          return TradingNotificationType.postSessionFeedback;
        case 'watch_match':
          return TradingNotificationType.blueprintWatchMatch;
        case 'queue_release':
          return TradingNotificationType.queuedListingReleased;
        case 'trade_offer':
          return TradingNotificationType.offerReceived;
        case 'trade_accepted':
          return TradingNotificationType.offerAccepted;
        case 'trade_rejected':
          return TradingNotificationType.offerDeclined;
        case 'trade_reminder':
          return TradingNotificationType.scheduledTradeReminder;
        case 'trading':
          return TradingNotificationType.sessionUpdated;
        case 'matchmaking_session':
        case 'matchmaking':
          return TradingNotificationType.availabilityOverlap;
        case 'favourite_rider':
          return TradingNotificationType.favouriteRiderListing;
        case 'item_relevance_warning':
          return TradingNotificationType.itemRelevanceWarning;
        case 'blueprint_report_confirmed':
          return TradingNotificationType.blueprintReportConfirmed;
        case 'community_intel_confirmation':
          return TradingNotificationType.communityIntelConfirmation;
        case 'community_intel_dispute':
          return TradingNotificationType.communityIntelDispute;
        case 'conduct_report_response':
          return TradingNotificationType.conductReportResponse;
        case 'conduct_report_outcome':
          return TradingNotificationType.conductReportOutcome;
        case 'creator_referral':
          return TradingNotificationType.creatorReferral;
        case 'creator_paid_conversion':
          return TradingNotificationType.creatorPaidConversion;
        case 'creator_commission_changed':
          return TradingNotificationType.creatorCommissionChanged;
        case 'subscription_event':
          return TradingNotificationType.subscriptionEvent;
        case 'payment_failure':
          return TradingNotificationType.paymentFailure;
        case 'founding_supporter_event':
          return TradingNotificationType.foundingSupporterEvent;
        case 'age_verification_required':
          return TradingNotificationType.ageVerificationRequired;
        default:
          return TradingNotificationType.sessionUpdated;
      }
    },
  );
}

class TradingNotification {
  final String id;
  final String targetUid;
  final String actorUid;
  final String title;
  final String body;
  final TradingNotificationType type;
  final String listingId;
  final String offerId;
  final String sessionId;
  final String watchId;
  final String queueId;
  final String preparationId;
  final String opportunityId;
  final String route;
  final String deepLink;
  final String imageUrl;
  final String entityId;
  final bool read;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TradingNotification({
    required this.id,
    required this.targetUid,
    required this.actorUid,
    required this.title,
    required this.body,
    required this.type,
    required this.listingId,
    required this.offerId,
    required this.sessionId,
    this.watchId = '',
    this.queueId = '',
    this.preparationId = '',
    this.opportunityId = '',
    this.route = '',
    this.deepLink = '',
    this.imageUrl = '',
    this.entityId = '',
    required this.read,
    required this.createdAt,
    required this.updatedAt,
  });

  String get typeLabel {
    switch (type) {
      case TradingNotificationType.offerReceived:
        return 'Offer Received';
      case TradingNotificationType.offerAccepted:
        return 'Offer Accepted';
      case TradingNotificationType.offerDeclined:
        return 'Offer Declined';
      case TradingNotificationType.offerCancelled:
        return 'Offer Cancelled';
      case TradingNotificationType.sessionCreated:
        return 'Session Created';
      case TradingNotificationType.sessionUpdated:
        return 'Session Updated';
      case TradingNotificationType.sessionReady:
        return 'Trader Ready';
      case TradingNotificationType.sessionOutcome:
        return 'Session Update';
      case TradingNotificationType.duplicateMatch:
        return 'Duplicate Match';
      case TradingNotificationType.mutualMatch:
        return 'Mutual Match';
      case TradingNotificationType.collectionRequest:
        return 'Collection Request';
      case TradingNotificationType.feedbackReply:
        return 'Feedback Reply';
      case TradingNotificationType.blueprintWatchMatch:
        return 'Watch Match';
      case TradingNotificationType.favouriteRiderListing:
        return 'Favourite Rider';
      case TradingNotificationType.favouriteRiderAcquisitionSignal:
        return 'Rider Signal';
      case TradingNotificationType.tradeOfferNeedsResponse:
        return 'Offer Response';
      case TradingNotificationType.queuedListingReleased:
        return 'Queue Released';
      case TradingNotificationType.queuedListingBlocked:
        return 'Queue Blocked';
      case TradingNotificationType.tradeReadyPreparation:
        return 'Trade Ready';
      case TradingNotificationType.tradeObjectiveOpportunity:
        return 'Trade Objective';
      case TradingNotificationType.availabilityOverlap:
        return 'Availability';
      case TradingNotificationType.scheduledTradeReminder:
        return 'Trade Reminder';
      case TradingNotificationType.announcement:
        return 'Announcement';
      case TradingNotificationType.openBeta:
        return 'Open Beta';
      case TradingNotificationType.operations:
        return 'Operations';
      case TradingNotificationType.reward:
        return 'Reward';
      case TradingNotificationType.itemRelevanceWarning:
        return 'Item Warning';
      case TradingNotificationType.blueprintReportConfirmed:
        return 'Blueprint Confirmed';
      case TradingNotificationType.communityIntelConfirmation:
        return 'Intel Confirmed';
      case TradingNotificationType.communityIntelDispute:
        return 'Intel Dispute';
      case TradingNotificationType.conductReportResponse:
        return 'Report Response';
      case TradingNotificationType.conductReportOutcome:
        return 'Report Outcome';
      case TradingNotificationType.creatorReferral:
        return 'Creator Referral';
      case TradingNotificationType.creatorPaidConversion:
        return 'Creator Conversion';
      case TradingNotificationType.creatorCommissionChanged:
        return 'Commission';
      case TradingNotificationType.subscriptionEvent:
        return 'Subscription';
      case TradingNotificationType.paymentFailure:
        return 'Payment';
      case TradingNotificationType.foundingSupporterEvent:
        return 'Supporter';
      case TradingNotificationType.ageVerificationRequired:
        return 'Age Verification';
      case TradingNotificationType.communityEvent:
        return 'Community Event';
      case TradingNotificationType.reminder:
        return 'Reminder';
      case TradingNotificationType.postSessionFeedback:
        return 'Feedback';
      case TradingNotificationType.maintenance:
        return 'Maintenance';
    }
  }

  bool get hasListingTarget => listingId.trim().isNotEmpty;
  bool get hasWatchTarget => watchId.trim().isNotEmpty;
  bool get hasQueueTarget => queueId.trim().isNotEmpty;
  bool get hasSessionTarget => sessionId.trim().isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'targetUid': targetUid,
      'actorUid': actorUid,
      'title': title,
      'body': body,
      'type': type.name,
      'listingId': listingId,
      'offerId': offerId,
      'sessionId': sessionId,
      'watchId': watchId,
      'queueId': queueId,
      'preparationId': preparationId,
      'opportunityId': opportunityId,
      'route': route,
      'deepLink': deepLink,
      'imageUrl': imageUrl,
      'entityId': entityId,
      'read': read,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  factory TradingNotification.fromMap(Map<String, dynamic> map) {
    final rawType = (map['type'] ?? '').toString();
    return TradingNotification(
      id: (map['id'] ?? '') as String,
      targetUid: (map['targetUid'] ?? '') as String,
      actorUid: (map['actorUid'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      body: (map['body'] ?? '') as String,
      type: tradingNotificationTypeFromWire(rawType),
      listingId: (map['listingId'] ?? '') as String,
      offerId: (map['offerId'] ?? '') as String,
      sessionId: (map['sessionId'] ?? '') as String,
      watchId: (map['watchId'] ?? '') as String,
      queueId: (map['queueId'] ?? '') as String,
      preparationId: (map['preparationId'] ?? '') as String,
      opportunityId: (map['opportunityId'] ?? '') as String,
      route: (map['route'] ?? '') as String,
      deepLink: (map['deepLink'] ?? '') as String,
      imageUrl: (map['imageUrl'] ?? '') as String,
      entityId: (map['entityId'] ?? '') as String,
      read: (map['read'] ?? false) as bool,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
