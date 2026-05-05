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
    }
  }

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
      type: TradingNotificationType.values.firstWhere(
        (value) => value.name == rawType,
        orElse: () => TradingNotificationType.sessionUpdated,
      ),
      listingId: (map['listingId'] ?? '') as String,
      offerId: (map['offerId'] ?? '') as String,
      sessionId: (map['sessionId'] ?? '') as String,
      read: (map['read'] ?? false) as bool,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
