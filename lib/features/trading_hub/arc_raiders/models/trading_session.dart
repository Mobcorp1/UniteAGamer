import 'package:cloud_firestore/cloud_firestore.dart';

enum TradingSessionStatus {
  pending,
  scheduled,
  ready,
  completed,
  noShow,
  betrayal,
  cancelled,
}

enum TradingProtocolType {
  sequentialSafePocketSwap,
  simultaneousDrop,
  extractSwap,
}

class TradingSession {
  final String id;
  final String listingId;
  final String offerId;
  final String traderOneUid;
  final String traderTwoUid;
  final String traderOneName;
  final String traderTwoName;
  final DateTime? scheduledAt;
  final String timezone;
  final TradingProtocolType protocolType;
  final TradingSessionStatus status;
  final String traderOneEmbarkId;
  final String traderTwoEmbarkId;
  final bool traderOneSharedEmbarkId;
  final bool traderTwoSharedEmbarkId;
  final bool traderOneReady;
  final bool traderTwoReady;
  final bool dropOrderAssigned;
  final String firstDropUid;
  final bool traderOneMarkedComplete;
  final bool traderTwoMarkedComplete;
  final bool traderOneMarkedNoShow;
  final bool traderTwoMarkedNoShow;
  final bool traderOneMarkedBetrayal;
  final bool traderTwoMarkedBetrayal;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TradingSession({
    required this.id,
    required this.listingId,
    required this.offerId,
    required this.traderOneUid,
    required this.traderTwoUid,
    required this.traderOneName,
    required this.traderTwoName,
    required this.scheduledAt,
    required this.timezone,
    required this.protocolType,
    required this.status,
    required this.traderOneEmbarkId,
    required this.traderTwoEmbarkId,
    required this.traderOneSharedEmbarkId,
    required this.traderTwoSharedEmbarkId,
    required this.traderOneReady,
    required this.traderTwoReady,
    required this.dropOrderAssigned,
    required this.firstDropUid,
    required this.traderOneMarkedComplete,
    required this.traderTwoMarkedComplete,
    required this.traderOneMarkedNoShow,
    required this.traderTwoMarkedNoShow,
    required this.traderOneMarkedBetrayal,
    required this.traderTwoMarkedBetrayal,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get bothReady => traderOneReady && traderTwoReady;
  bool get bothMarkedComplete =>
      traderOneMarkedComplete && traderTwoMarkedComplete;

  String get protocolLabel {
    switch (protocolType) {
      case TradingProtocolType.sequentialSafePocketSwap:
        return 'Sequential Safe Pocket Swap';
      case TradingProtocolType.simultaneousDrop:
        return 'Simultaneous Drop';
      case TradingProtocolType.extractSwap:
        return 'Extract Swap';
    }
  }

  String get statusLabel {
    switch (status) {
      case TradingSessionStatus.pending:
        return 'Pending Schedule';
      case TradingSessionStatus.scheduled:
        return 'Scheduled';
      case TradingSessionStatus.ready:
        return 'Ready';
      case TradingSessionStatus.completed:
        return 'Completed';
      case TradingSessionStatus.noShow:
        return 'No-Show';
      case TradingSessionStatus.betrayal:
        return 'Betrayal Flagged';
      case TradingSessionStatus.cancelled:
        return 'Cancelled';
    }
  }

  TradingSession copyWith({
    DateTime? scheduledAt,
    String? timezone,
    TradingProtocolType? protocolType,
    TradingSessionStatus? status,
    String? traderOneEmbarkId,
    String? traderTwoEmbarkId,
    bool? traderOneSharedEmbarkId,
    bool? traderTwoSharedEmbarkId,
    bool? traderOneReady,
    bool? traderTwoReady,
    bool? dropOrderAssigned,
    String? firstDropUid,
    bool? traderOneMarkedComplete,
    bool? traderTwoMarkedComplete,
    bool? traderOneMarkedNoShow,
    bool? traderTwoMarkedNoShow,
    bool? traderOneMarkedBetrayal,
    bool? traderTwoMarkedBetrayal,
    DateTime? updatedAt,
  }) {
    return TradingSession(
      id: id,
      listingId: listingId,
      offerId: offerId,
      traderOneUid: traderOneUid,
      traderTwoUid: traderTwoUid,
      traderOneName: traderOneName,
      traderTwoName: traderTwoName,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      timezone: timezone ?? this.timezone,
      protocolType: protocolType ?? this.protocolType,
      status: status ?? this.status,
      traderOneEmbarkId: traderOneEmbarkId ?? this.traderOneEmbarkId,
      traderTwoEmbarkId: traderTwoEmbarkId ?? this.traderTwoEmbarkId,
      traderOneSharedEmbarkId:
          traderOneSharedEmbarkId ?? this.traderOneSharedEmbarkId,
      traderTwoSharedEmbarkId:
          traderTwoSharedEmbarkId ?? this.traderTwoSharedEmbarkId,
      traderOneReady: traderOneReady ?? this.traderOneReady,
      traderTwoReady: traderTwoReady ?? this.traderTwoReady,
      dropOrderAssigned: dropOrderAssigned ?? this.dropOrderAssigned,
      firstDropUid: firstDropUid ?? this.firstDropUid,
      traderOneMarkedComplete:
          traderOneMarkedComplete ?? this.traderOneMarkedComplete,
      traderTwoMarkedComplete:
          traderTwoMarkedComplete ?? this.traderTwoMarkedComplete,
      traderOneMarkedNoShow:
          traderOneMarkedNoShow ?? this.traderOneMarkedNoShow,
      traderTwoMarkedNoShow:
          traderTwoMarkedNoShow ?? this.traderTwoMarkedNoShow,
      traderOneMarkedBetrayal:
          traderOneMarkedBetrayal ?? this.traderOneMarkedBetrayal,
      traderTwoMarkedBetrayal:
          traderTwoMarkedBetrayal ?? this.traderTwoMarkedBetrayal,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    String statusValue;
    switch (status) {
      case TradingSessionStatus.noShow:
        statusValue = 'no_show';
        break;
      default:
        statusValue = status.name;
    }

    return {
      'id': id,
      'listingId': listingId,
      'offerId': offerId,
      'traderOneUid': traderOneUid,
      'traderTwoUid': traderTwoUid,
      'traderOneName': traderOneName,
      'traderTwoName': traderTwoName,
      'scheduledAt':
          scheduledAt == null ? null : Timestamp.fromDate(scheduledAt!),
      'timezone': timezone,
      'protocolType': protocolType.name,
      'status': statusValue,
      'traderOneEmbarkId': traderOneEmbarkId,
      'traderTwoEmbarkId': traderTwoEmbarkId,
      'traderOneSharedEmbarkId': traderOneSharedEmbarkId,
      'traderTwoSharedEmbarkId': traderTwoSharedEmbarkId,
      'traderOneReady': traderOneReady,
      'traderTwoReady': traderTwoReady,
      'dropOrderAssigned': dropOrderAssigned,
      'firstDropUid': firstDropUid,
      'traderOneMarkedComplete': traderOneMarkedComplete,
      'traderTwoMarkedComplete': traderTwoMarkedComplete,
      'traderOneMarkedNoShow': traderOneMarkedNoShow,
      'traderTwoMarkedNoShow': traderTwoMarkedNoShow,
      'traderOneMarkedBetrayal': traderOneMarkedBetrayal,
      'traderTwoMarkedBetrayal': traderTwoMarkedBetrayal,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  factory TradingSession.fromMap(Map<String, dynamic> map) {
    final rawStatus = (map['status'] ?? '').toString();
    final normalizedStatus = switch (rawStatus) {
      'awaitingSchedule' => 'pending',
      'no_show' => 'noShow',
      'dispute' => 'betrayal',
      _ => rawStatus,
    };

    return TradingSession(
      id: (map['id'] ?? '') as String,
      listingId: (map['listingId'] ?? '') as String,
      offerId: (map['offerId'] ?? '') as String,
      traderOneUid: (map['traderOneUid'] ?? '') as String,
      traderTwoUid: (map['traderTwoUid'] ?? '') as String,
      traderOneName: (map['traderOneName'] ?? '') as String,
      traderTwoName: (map['traderTwoName'] ?? '') as String,
      scheduledAt: (map['scheduledAt'] as Timestamp?)?.toDate(),
      timezone: (map['timezone'] ?? 'Europe/London') as String,
      protocolType: TradingProtocolType.values.firstWhere(
        (value) => value.name == (map['protocolType'] ?? ''),
        orElse: () => TradingProtocolType.sequentialSafePocketSwap,
      ),
      status: TradingSessionStatus.values.firstWhere(
        (value) => value.name == normalizedStatus,
        orElse: () => TradingSessionStatus.pending,
      ),
      traderOneEmbarkId: (map['traderOneEmbarkId'] ?? '') as String,
      traderTwoEmbarkId: (map['traderTwoEmbarkId'] ?? '') as String,
      traderOneSharedEmbarkId:
          (map['traderOneSharedEmbarkId'] ?? false) as bool,
      traderTwoSharedEmbarkId:
          (map['traderTwoSharedEmbarkId'] ?? false) as bool,
      traderOneReady: (map['traderOneReady'] ?? false) as bool,
      traderTwoReady: (map['traderTwoReady'] ?? false) as bool,
      dropOrderAssigned: (map['dropOrderAssigned'] ?? false) as bool,
      firstDropUid: (map['firstDropUid'] ?? '') as String,
      traderOneMarkedComplete:
          (map['traderOneMarkedComplete'] ?? false) as bool,
      traderTwoMarkedComplete:
          (map['traderTwoMarkedComplete'] ?? false) as bool,
      traderOneMarkedNoShow: (map['traderOneMarkedNoShow'] ?? false) as bool,
      traderTwoMarkedNoShow: (map['traderTwoMarkedNoShow'] ?? false) as bool,
      traderOneMarkedBetrayal:
          (map['traderOneMarkedBetrayal'] ?? false) as bool,
      traderTwoMarkedBetrayal:
          (map['traderTwoMarkedBetrayal'] ?? false) as bool,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
