import 'package:cloud_firestore/cloud_firestore.dart';

enum UagNotificationType {
  announcement('announcement'),
  openBeta('open_beta'),
  trading('trading'),
  matchmaking('matchmaking'),
  favouriteRider('favourite_rider'),
  watchMatch('watch_match'),
  queueRelease('queue_release'),
  operations('operations'),
  reward('reward'),
  communityEvent('community_event'),
  reminder('reminder'),
  postSessionFeedback('post_session_feedback'),
  maintenance('maintenance');

  const UagNotificationType(this.wireName);

  final String wireName;

  static UagNotificationType fromWire(String? value) {
    final normalized = (value ?? '').trim();
    return UagNotificationType.values.firstWhere(
      (type) => type.wireName == normalized || type.name == normalized,
      orElse: () => UagNotificationType.announcement,
    );
  }
}

enum UagNotificationAudience {
  allEligible('all_eligible'),
  closedBetaUsers('closed_beta_users'),
  openBetaUsers('open_beta_users'),
  android('android'),
  web('web'),
  subscribedByPreference('subscribed_by_preference'),
  specificUser('specific_user');

  const UagNotificationAudience(this.wireName);

  final String wireName;

  static UagNotificationAudience fromWire(String? value) {
    final normalized = (value ?? '').trim();
    return UagNotificationAudience.values.firstWhere(
      (audience) =>
          audience.wireName == normalized || audience.name == normalized,
      orElse: () => UagNotificationAudience.allEligible,
    );
  }
}

enum UagNotificationPriority {
  low('low'),
  normal('normal'),
  high('high'),
  critical('critical');

  const UagNotificationPriority(this.wireName);

  final String wireName;

  static UagNotificationPriority fromWire(String? value) {
    final normalized = (value ?? '').trim();
    return UagNotificationPriority.values.firstWhere(
      (priority) =>
          priority.wireName == normalized || priority.name == normalized,
      orElse: () => UagNotificationPriority.normal,
    );
  }
}

enum UagNotificationDeliveryChannel {
  push('push'),
  inApp('in_app');

  const UagNotificationDeliveryChannel(this.wireName);

  final String wireName;

  static UagNotificationDeliveryChannel fromWire(String value) {
    return UagNotificationDeliveryChannel.values.firstWhere(
      (channel) => channel.wireName == value || channel.name == value,
      orElse: () => UagNotificationDeliveryChannel.push,
    );
  }
}

enum UagNotificationCategory {
  announcements('announcements', 'Announcements'),
  openBetaUpdates('openBetaUpdates', 'Open Beta Updates'),
  trading('trading', 'Trading'),
  matchmaking('matchmaking', 'Matchmaking'),
  favouriteRiders('favouriteRiders', 'Favourite Riders'),
  watchesAndQueues('watchesAndQueues', 'Watches & Queues'),
  operationsAndRewards('operationsAndRewards', 'Operations & Rewards'),
  communityEvents('communityEvents', 'Community Events'),
  reminders('reminders', 'Reminders'),
  postSessionFeedback('postSessionFeedback', 'Post-Session Feedback');

  const UagNotificationCategory(this.key, this.label);

  final String key;
  final String label;
}

class UagNotificationPreferences {
  const UagNotificationPreferences({
    this.announcements = true,
    this.openBetaUpdates = true,
    this.trading = true,
    this.matchmaking = true,
    this.favouriteRiders = true,
    this.watchesAndQueues = true,
    this.operationsAndRewards = true,
    this.communityEvents = true,
    this.reminders = true,
    this.postSessionFeedback = true,
    this.updatedAt,
  });

  final bool announcements;
  final bool openBetaUpdates;
  final bool trading;
  final bool matchmaking;
  final bool favouriteRiders;
  final bool watchesAndQueues;
  final bool operationsAndRewards;
  final bool communityEvents;
  final bool reminders;
  final bool postSessionFeedback;
  final DateTime? updatedAt;

  static const defaults = UagNotificationPreferences();

  bool valueFor(UagNotificationCategory category) {
    switch (category) {
      case UagNotificationCategory.announcements:
        return announcements;
      case UagNotificationCategory.openBetaUpdates:
        return openBetaUpdates;
      case UagNotificationCategory.trading:
        return trading;
      case UagNotificationCategory.matchmaking:
        return matchmaking;
      case UagNotificationCategory.favouriteRiders:
        return favouriteRiders;
      case UagNotificationCategory.watchesAndQueues:
        return watchesAndQueues;
      case UagNotificationCategory.operationsAndRewards:
        return operationsAndRewards;
      case UagNotificationCategory.communityEvents:
        return communityEvents;
      case UagNotificationCategory.reminders:
        return reminders;
      case UagNotificationCategory.postSessionFeedback:
        return postSessionFeedback;
    }
  }

  bool allowsType(UagNotificationType type) {
    switch (type) {
      case UagNotificationType.announcement:
      case UagNotificationType.maintenance:
        return announcements;
      case UagNotificationType.openBeta:
        return openBetaUpdates;
      case UagNotificationType.trading:
        return trading;
      case UagNotificationType.matchmaking:
        return matchmaking;
      case UagNotificationType.favouriteRider:
        return favouriteRiders;
      case UagNotificationType.watchMatch:
      case UagNotificationType.queueRelease:
        return watchesAndQueues;
      case UagNotificationType.operations:
      case UagNotificationType.reward:
        return operationsAndRewards;
      case UagNotificationType.communityEvent:
        return communityEvents;
      case UagNotificationType.reminder:
        return reminders;
      case UagNotificationType.postSessionFeedback:
        return postSessionFeedback;
    }
  }

  UagNotificationPreferences withCategory(
    UagNotificationCategory category,
    bool enabled,
  ) {
    switch (category) {
      case UagNotificationCategory.announcements:
        return copyWith(announcements: enabled);
      case UagNotificationCategory.openBetaUpdates:
        return copyWith(openBetaUpdates: enabled);
      case UagNotificationCategory.trading:
        return copyWith(trading: enabled);
      case UagNotificationCategory.matchmaking:
        return copyWith(matchmaking: enabled);
      case UagNotificationCategory.favouriteRiders:
        return copyWith(favouriteRiders: enabled);
      case UagNotificationCategory.watchesAndQueues:
        return copyWith(watchesAndQueues: enabled);
      case UagNotificationCategory.operationsAndRewards:
        return copyWith(operationsAndRewards: enabled);
      case UagNotificationCategory.communityEvents:
        return copyWith(communityEvents: enabled);
      case UagNotificationCategory.reminders:
        return copyWith(reminders: enabled);
      case UagNotificationCategory.postSessionFeedback:
        return copyWith(postSessionFeedback: enabled);
    }
  }

  UagNotificationPreferences copyWith({
    bool? announcements,
    bool? openBetaUpdates,
    bool? trading,
    bool? matchmaking,
    bool? favouriteRiders,
    bool? watchesAndQueues,
    bool? operationsAndRewards,
    bool? communityEvents,
    bool? reminders,
    bool? postSessionFeedback,
    DateTime? updatedAt,
  }) {
    return UagNotificationPreferences(
      announcements: announcements ?? this.announcements,
      openBetaUpdates: openBetaUpdates ?? this.openBetaUpdates,
      trading: trading ?? this.trading,
      matchmaking: matchmaking ?? this.matchmaking,
      favouriteRiders: favouriteRiders ?? this.favouriteRiders,
      watchesAndQueues: watchesAndQueues ?? this.watchesAndQueues,
      operationsAndRewards: operationsAndRewards ?? this.operationsAndRewards,
      communityEvents: communityEvents ?? this.communityEvents,
      reminders: reminders ?? this.reminders,
      postSessionFeedback: postSessionFeedback ?? this.postSessionFeedback,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'announcements': announcements,
      'openBetaUpdates': openBetaUpdates,
      'trading': trading,
      'matchmaking': matchmaking,
      'favouriteRiders': favouriteRiders,
      'watchesAndQueues': watchesAndQueues,
      'operationsAndRewards': operationsAndRewards,
      'communityEvents': communityEvents,
      'reminders': reminders,
      'postSessionFeedback': postSessionFeedback,
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  factory UagNotificationPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) return defaults;
    return UagNotificationPreferences(
      announcements: _readBool(map['announcements'], true),
      openBetaUpdates: _readBool(map['openBetaUpdates'], true),
      trading: _readBool(map['trading'], true),
      matchmaking: _readBool(map['matchmaking'], true),
      favouriteRiders: _readBool(map['favouriteRiders'], true),
      watchesAndQueues: _readBool(map['watchesAndQueues'], true),
      operationsAndRewards: _readBool(map['operationsAndRewards'], true),
      communityEvents: _readBool(map['communityEvents'], true),
      reminders: _readBool(map['reminders'], true),
      postSessionFeedback: _readBool(map['postSessionFeedback'], true),
      updatedAt: _readDate(map['updatedAt']),
    );
  }
}

class UagNotificationDevice {
  const UagNotificationDevice({
    required this.deviceId,
    required this.token,
    required this.userId,
    required this.platform,
    required this.enabled,
    required this.createdAt,
    required this.updatedAt,
    required this.lastSeenAt,
    required this.installationId,
    this.appVersion = '',
    this.preferences = UagNotificationPreferences.defaults,
    this.permissionStatus = 'notDetermined',
    this.tokenValid = true,
    this.signedOutAt,
  });

  final String deviceId;
  final String token;
  final String userId;
  final String platform;
  final bool enabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastSeenAt;
  final String appVersion;
  final String installationId;
  final UagNotificationPreferences preferences;
  final String permissionStatus;
  final bool tokenValid;
  final DateTime? signedOutAt;

  bool get hasUsableToken => token.trim().isNotEmpty && tokenValid;

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'token': token,
      'userId': userId,
      'platform': platform,
      'enabled': enabled,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (lastSeenAt != null) 'lastSeenAt': Timestamp.fromDate(lastSeenAt!),
      'appVersion': appVersion,
      'installationId': installationId,
      'preferences': preferences.toMap(),
      'permissionStatus': permissionStatus,
      'tokenValid': tokenValid,
      if (signedOutAt != null) 'signedOutAt': Timestamp.fromDate(signedOutAt!),
    };
  }

  factory UagNotificationDevice.fromMap(Map<String, dynamic> map) {
    return UagNotificationDevice(
      deviceId: _readString(map['deviceId']),
      token: _readString(map['token']),
      userId: _readString(map['userId']),
      platform: _readString(map['platform']),
      enabled: _readBool(map['enabled'], false),
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
      lastSeenAt: _readDate(map['lastSeenAt']),
      appVersion: _readString(map['appVersion']),
      installationId: _readString(map['installationId']),
      preferences: UagNotificationPreferences.fromMap(
        _readMap(map['preferences']),
      ),
      permissionStatus: _readString(
        map['permissionStatus'],
        fallback: 'notDetermined',
      ),
      tokenValid: _readBool(map['tokenValid'], true),
      signedOutAt: _readDate(map['signedOutAt']),
    );
  }
}

class UagNotificationPayload {
  const UagNotificationPayload({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.audience,
    required this.senderUid,
    this.imageUrl = '',
    this.deepLink = '',
    this.route = '',
    this.entityId = '',
    this.createdAt,
    this.expiresAt,
    this.priority = UagNotificationPriority.normal,
    this.deliveryChannels = const <UagNotificationDeliveryChannel>[
      UagNotificationDeliveryChannel.push,
      UagNotificationDeliveryChannel.inApp,
    ],
    this.metadata = const <String, String>{},
  });

  final String id;
  final UagNotificationType type;
  final String title;
  final String body;
  final String imageUrl;
  final String deepLink;
  final String route;
  final String entityId;
  final UagNotificationAudience audience;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final String senderUid;
  final UagNotificationPriority priority;
  final List<UagNotificationDeliveryChannel> deliveryChannels;
  final Map<String, String> metadata;

  bool get hasPushChannel =>
      deliveryChannels.contains(UagNotificationDeliveryChannel.push);

  bool get hasInAppChannel =>
      deliveryChannels.contains(UagNotificationDeliveryChannel.inApp);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.wireName,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'deepLink': deepLink,
      'route': route,
      'entityId': entityId,
      'audience': audience.wireName,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
      'senderUid': senderUid,
      'priority': priority.wireName,
      'deliveryChannels': deliveryChannels
          .map((channel) => channel.wireName)
          .toList(growable: false),
      'metadata': metadata,
    };
  }

  Map<String, String> toPushData({String notificationId = ''}) {
    return {
      'id': id,
      'notificationId': notificationId.isEmpty ? id : notificationId,
      'type': type.wireName,
      'deepLink': deepLink,
      'route': route,
      'entityId': entityId,
      'audience': audience.wireName,
      'priority': priority.wireName,
      ...metadata,
    };
  }

  factory UagNotificationPayload.fromMap(Map<String, dynamic> map) {
    return UagNotificationPayload(
      id: _readString(map['id']),
      type: UagNotificationType.fromWire(_readString(map['type'])),
      title: _readString(map['title']),
      body: _readString(map['body']),
      imageUrl: _readString(map['imageUrl']),
      deepLink: _readString(map['deepLink']),
      route: _readString(map['route']),
      entityId: _readString(map['entityId']),
      audience: UagNotificationAudience.fromWire(_readString(map['audience'])),
      createdAt: _readDate(map['createdAt']),
      expiresAt: _readDate(map['expiresAt']),
      senderUid: _readString(map['senderUid']),
      priority: UagNotificationPriority.fromWire(_readString(map['priority'])),
      deliveryChannels: _readStringList(
        map['deliveryChannels'],
      ).map(UagNotificationDeliveryChannel.fromWire).toList(growable: false),
      metadata: _readStringMap(map['metadata']),
    );
  }
}

class UagNotificationBroadcastRequest {
  const UagNotificationBroadcastRequest({
    required this.id,
    required this.payload,
    required this.sendPush,
    required this.createInApp,
    required this.testMode,
    required this.status,
    required this.clientRequestId,
    this.targetUid = '',
    this.createdAt,
  });

  final String id;
  final UagNotificationPayload payload;
  final bool sendPush;
  final bool createInApp;
  final bool testMode;
  final String status;
  final String targetUid;
  final String clientRequestId;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      ...payload.toMap(),
      'sendPush': sendPush,
      'createInApp': createInApp,
      'testMode': testMode,
      'status': status,
      'targetUid': targetUid,
      'clientRequestId': clientRequestId,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}

class UagNotificationAudienceEstimate {
  const UagNotificationAudienceEstimate({
    required this.eligibleDevices,
    required this.eligibleUsers,
    required this.limited,
  });

  final int eligibleDevices;
  final int eligibleUsers;
  final bool limited;
}

class UagScheduledNotification {
  const UagScheduledNotification({
    required this.id,
    required this.targetUid,
    required this.type,
    required this.title,
    required this.body,
    required this.dueAt,
    required this.route,
    required this.entityId,
    required this.status,
    this.createdAt,
    this.metadata = const <String, String>{},
  });

  final String id;
  final String targetUid;
  final UagNotificationType type;
  final String title;
  final String body;
  final DateTime dueAt;
  final String route;
  final String entityId;
  final String status;
  final DateTime? createdAt;
  final Map<String, String> metadata;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'targetUid': targetUid,
      'type': type.wireName,
      'title': title,
      'body': body,
      'dueAt': Timestamp.fromDate(dueAt),
      'route': route,
      'entityId': entityId,
      'status': status,
      'metadata': metadata,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}

bool _readBool(dynamic value, bool fallback) {
  if (value is bool) return value;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
  }
  return fallback;
}

DateTime? _readDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

Map<String, dynamic>? _readMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return null;
}

String _readString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString().trim();
}

List<String> _readStringList(dynamic value) {
  if (value is! Iterable) {
    return const <String>['push', 'in_app'];
  }
  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

Map<String, String> _readStringMap(dynamic value) {
  final map = _readMap(value);
  if (map == null) return const <String, String>{};
  return map.map((key, val) => MapEntry(key.toString(), val?.toString() ?? ''));
}
