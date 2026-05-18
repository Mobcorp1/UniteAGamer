import 'package:cloud_firestore/cloud_firestore.dart';

class ArcMatchRiderInvite {
  const ArcMatchRiderInvite({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.recipientUid,
    required this.recipientName,
    required this.status,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String senderUid;
  final String senderName;
  final String recipientUid;
  final String recipientName;
  final String status;
  final String note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderUid': senderUid,
      'senderName': senderName,
      'recipientUid': recipientUid,
      'recipientName': recipientName,
      'status': status,
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ArcMatchRiderInvite copyWith({String? status, String? note}) {
    return ArcMatchRiderInvite(
      id: id,
      senderUid: senderUid,
      senderName: senderName,
      recipientUid: recipientUid,
      recipientName: recipientName,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory ArcMatchRiderInvite.fromMap(Map<String, dynamic> map) {
    DateTime? readDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      return null;
    }

    return ArcMatchRiderInvite(
      id: (map['id'] as String? ?? '').trim(),
      senderUid: (map['senderUid'] as String? ?? '').trim(),
      senderName: (map['senderName'] as String? ?? '').trim(),
      recipientUid: (map['recipientUid'] as String? ?? '').trim(),
      recipientName: (map['recipientName'] as String? ?? '').trim(),
      status: (map['status'] as String? ?? 'pending').trim(),
      note: (map['note'] as String? ?? '').trim(),
      createdAt: readDate(map['createdAt']),
      updatedAt: readDate(map['updatedAt']),
    );
  }
}
