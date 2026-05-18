import 'package:cloud_firestore/cloud_firestore.dart';

class UagSession {
  const UagSession({
    required this.id,
    required this.type,
    required this.game,
    required this.createdBy,
    required this.participantOneUid,
    required this.participantTwoUid,
    required this.participantOneDisplayName,
    required this.participantTwoDisplayName,
    required this.participantOneEmbarkId,
    required this.participantTwoEmbarkId,
    required this.scheduledAt,
    required this.timezone,
    required this.status,
    this.tradeListingId,
    this.matchmakingId,
    this.notes,
    this.participantOneReady = false,
    this.participantTwoReady = false,
    this.participantOneCompleted = false,
    this.participantTwoCompleted = false,
    this.participantOneNoShow = false,
    this.participantTwoNoShow = false,
  });
  final String id;
  final String type;
  final String game;
  final String createdBy;
  final String participantOneUid;
  final String participantTwoUid;
  final String participantOneDisplayName;
  final String participantTwoDisplayName;
  final String participantOneEmbarkId;
  final String participantTwoEmbarkId;
  final DateTime scheduledAt;
  final String timezone;
  final String status;
  final String? tradeListingId;
  final String? matchmakingId;
  final String? notes;
  final bool participantOneReady;
  final bool participantTwoReady;
  final bool participantOneCompleted;
  final bool participantTwoCompleted;
  final bool participantOneNoShow;
  final bool participantTwoNoShow;
  factory UagSession.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    DateTime readTime(Object? value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return UagSession(
      id: data['id'] as String? ?? doc.id,
      type: data['type'] as String? ?? 'trade',
      game: data['game'] as String? ?? 'arc_raiders',
      createdBy: data['createdBy'] as String? ?? '',
      participantOneUid: data['participantOneUid'] as String? ?? '',
      participantTwoUid: data['participantTwoUid'] as String? ?? '',
      participantOneDisplayName:
          data['participantOneDisplayName'] as String? ?? 'Player One',
      participantTwoDisplayName:
          data['participantTwoDisplayName'] as String? ?? 'Player Two',
      participantOneEmbarkId: data['participantOneEmbarkId'] as String? ?? '',
      participantTwoEmbarkId: data['participantTwoEmbarkId'] as String? ?? '',
      scheduledAt: readTime(data['scheduledAt']),
      timezone: data['timezone'] as String? ?? 'Europe/London',
      status: data['status'] as String? ?? 'scheduled',
      tradeListingId: data['tradeListingId'] as String?,
      matchmakingId: data['matchmakingId'] as String?,
      notes: data['notes'] as String?,
      participantOneReady: data['participantOneReady'] as bool? ?? false,
      participantTwoReady: data['participantTwoReady'] as bool? ?? false,
      participantOneCompleted:
          data['participantOneCompleted'] as bool? ?? false,
      participantTwoCompleted:
          data['participantTwoCompleted'] as bool? ?? false,
      participantOneNoShow: data['participantOneNoShow'] as bool? ?? false,
      participantTwoNoShow: data['participantTwoNoShow'] as bool? ?? false,
    );
  }
  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'type': type,
    'game': game,
    'createdBy': createdBy,
    'participantOneUid': participantOneUid,
    'participantTwoUid': participantTwoUid,
    'participantOneDisplayName': participantOneDisplayName,
    'participantTwoDisplayName': participantTwoDisplayName,
    'participantOneEmbarkId': participantOneEmbarkId,
    'participantTwoEmbarkId': participantTwoEmbarkId,
    'participantOneEmbarkVisible': true,
    'participantTwoEmbarkVisible': true,
    'scheduledAt': Timestamp.fromDate(scheduledAt),
    'timezone': timezone,
    'status': status,
    'tradeListingId': tradeListingId,
    'matchmakingId': matchmakingId,
    'notes': notes,
    'participantOneReady': participantOneReady,
    'participantTwoReady': participantTwoReady,
    'participantOneCompleted': participantOneCompleted,
    'participantTwoCompleted': participantTwoCompleted,
    'participantOneNoShow': participantOneNoShow,
    'participantTwoNoShow': participantTwoNoShow,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
