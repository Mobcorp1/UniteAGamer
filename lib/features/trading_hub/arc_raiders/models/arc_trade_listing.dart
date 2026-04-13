class ArcTradeListing {
  final String id;
  final String userId;
  final String offeredBlueprintId;
  final String offeredBlueprintName;
  final String wantedBlueprintId;
  final String wantedBlueprintName;
  final String region;
  final String platform;
  final String status;
  final String note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ArcTradeListing({
    required this.id,
    required this.userId,
    required this.offeredBlueprintId,
    required this.offeredBlueprintName,
    required this.wantedBlueprintId,
    required this.wantedBlueprintName,
    required this.region,
    required this.platform,
    required this.status,
    required this.note,
    this.createdAt,
    this.updatedAt,
  });

  bool get isOpen => status == 'open';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'offeredBlueprintId': offeredBlueprintId,
      'offeredBlueprintName': offeredBlueprintName,
      'wantedBlueprintId': wantedBlueprintId,
      'wantedBlueprintName': wantedBlueprintName,
      'region': region,
      'platform': platform,
      'status': status,
      'note': note,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory ArcTradeListing.fromMap(Map<String, dynamic> map) {
    return ArcTradeListing(
      id: (map['id'] ?? '') as String,
      userId: (map['userId'] ?? '') as String,
      offeredBlueprintId: (map['offeredBlueprintId'] ?? '') as String,
      offeredBlueprintName: (map['offeredBlueprintName'] ?? '') as String,
      wantedBlueprintId: (map['wantedBlueprintId'] ?? '') as String,
      wantedBlueprintName: (map['wantedBlueprintName'] ?? '') as String,
      region: (map['region'] ?? '') as String,
      platform: (map['platform'] ?? '') as String,
      status: (map['status'] ?? 'open') as String,
      note: (map['note'] ?? '') as String,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : null,
    );
  }

  ArcTradeListing copyWith({
    String? id,
    String? userId,
    String? offeredBlueprintId,
    String? offeredBlueprintName,
    String? wantedBlueprintId,
    String? wantedBlueprintName,
    String? region,
    String? platform,
    String? status,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ArcTradeListing(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      offeredBlueprintId: offeredBlueprintId ?? this.offeredBlueprintId,
      offeredBlueprintName: offeredBlueprintName ?? this.offeredBlueprintName,
      wantedBlueprintId: wantedBlueprintId ?? this.wantedBlueprintId,
      wantedBlueprintName: wantedBlueprintName ?? this.wantedBlueprintName,
      region: region ?? this.region,
      platform: platform ?? this.platform,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
