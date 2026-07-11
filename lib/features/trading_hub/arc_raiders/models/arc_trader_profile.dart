import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_player_archetype_catalog.dart';

class ArcTraderProfile {
  final String uid;
  final String uagId;
  final String uagName;
  final String embarkId;
  final String region;
  final String serverPreference;
  final String platform;
  final String timezone;
  final bool visibleInSearch;
  final bool micOk;
  final bool crossRegionOk;
  final bool crossPlatformOk;
  final bool isProfileComplete;
  final List<String> archetypes;
  final List<String> playStyles;
  final String communicationStyle;
  final String squadIntent;
  final String socialEnergy;
  final String referralCode;
  final String referredByCode;
  final bool affiliateEnabled;
  final String payoutMethod;
  final String subscriptionStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastActiveAt;

  const ArcTraderProfile({
    required this.uid,
    required this.uagId,
    required this.uagName,
    required this.embarkId,
    required this.region,
    required this.serverPreference,
    required this.platform,
    required this.timezone,
    required this.visibleInSearch,
    required this.micOk,
    required this.crossRegionOk,
    required this.crossPlatformOk,
    required this.isProfileComplete,
    this.archetypes = const [],
    this.playStyles = const [],
    this.communicationStyle = 'Flexible',
    this.squadIntent = 'Flexible',
    this.socialEnergy = 'Depends on the day',
    required this.referralCode,
    required this.referredByCode,
    required this.affiliateEnabled,
    required this.payoutMethod,
    required this.subscriptionStatus,
    this.createdAt,
    this.updatedAt,
    this.lastActiveAt,
  });

  factory ArcTraderProfile.empty(String uid) {
    return ArcTraderProfile(
      uid: uid,
      uagId: '',
      uagName: '',
      embarkId: '',
      region: 'UK',
      serverPreference: 'Automatic',
      platform: '',
      timezone: 'Europe/London',
      visibleInSearch: true,
      micOk: true,
      crossRegionOk: false,
      crossPlatformOk: true,
      isProfileComplete: false,
      archetypes: const [ArcPlayerArchetypeCatalog.defaultLabel],
      playStyles: const ['PvE defensive'],
      communicationStyle: 'Flexible',
      squadIntent: 'Flexible',
      socialEnergy: 'Depends on the day',
      referralCode: '',
      referredByCode: '',
      affiliateEnabled: false,
      payoutMethod: 'Bank Transfer',
      subscriptionStatus: 'inactive',
    );
  }

  static String _string(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }

  static List<String> _stringList(
    dynamic value, [
    List<String> fallback = const [],
  ]) {
    if (value == null) return fallback;
    if (value is Iterable) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList(growable: false);
    }
    if (value is String && value.trim().isNotEmpty) return [value.trim()];
    return fallback;
  }

  static bool _bool(dynamic value, [bool fallback = false]) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true';
    return fallback;
  }

  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  bool get hasCoreDetails =>
      uagId.trim().isNotEmpty &&
      uagName.trim().isNotEmpty &&
      region.trim().isNotEmpty &&
      platform.trim().isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'uagId': uagId,
      'uagName': uagName,
      'embarkId': embarkId,
      'region': region,
      'serverPreference': serverPreference,
      'platform': platform,
      'timezone': timezone,
      'visibleInSearch': visibleInSearch,
      'micOk': micOk,
      'crossRegionOk': crossRegionOk,
      'crossPlatformOk': crossPlatformOk,
      'crossplayEnabled': crossPlatformOk,
      'isProfileComplete': isProfileComplete,
      'archetypes': ArcPlayerArchetypeCatalog.normalizeLabels(
        archetypes,
        includeDefaultWhenEmpty: true,
      ),
      'playStyles': playStyles,
      'communicationStyle': communicationStyle,
      'squadIntent': squadIntent,
      'socialEnergy': socialEnergy,
      'playStyle': playStyles.isNotEmpty ? playStyles.first : '',
      'referralCode': referralCode,
      'referredByCode': referredByCode,
      'affiliateEnabled': affiliateEnabled,
      'payoutMethod': payoutMethod,
      'subscriptionStatus': subscriptionStatus,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'lastActiveAt': lastActiveAt == null
          ? null
          : Timestamp.fromDate(lastActiveAt!),
    };
  }

  factory ArcTraderProfile.fromMap(Map<String, dynamic> map) {
    final archetypes = ArcPlayerArchetypeCatalog.normalizeLabels(
      _stringList(map['archetypes'], _stringList(map['playStyle'])),
      includeDefaultWhenEmpty: true,
    );
    final playStyles = _stringList(
      map['playStyles'],
      _stringList(map['playStyle']),
    );
    return ArcTraderProfile(
      uid: _string(map['uid']),
      uagId: _string(map['uagId']),
      uagName: _string(map['uagName']),
      embarkId: _string(map['embarkId']),
      region: _string(map['region'], 'UK'),
      serverPreference: _string(map['serverPreference'], 'Automatic'),
      platform: _string(map['platform']),
      timezone: _string(map['timezone'], 'Europe/London'),
      visibleInSearch: _bool(map['visibleInSearch'], true),
      micOk: _bool(map['micOk'], true),
      crossRegionOk: _bool(map['crossRegionOk']),
      crossPlatformOk: map.containsKey('crossplayEnabled')
          ? _bool(map['crossplayEnabled'], true)
          : _bool(map['crossPlatformOk'], true),
      isProfileComplete: _bool(map['isProfileComplete']),
      archetypes: archetypes,
      playStyles: playStyles.isEmpty ? const ['PvE defensive'] : playStyles,
      communicationStyle: _string(map['communicationStyle'], 'Flexible'),
      squadIntent: _string(map['squadIntent'], 'Flexible'),
      socialEnergy: _string(map['socialEnergy'], 'Depends on the day'),
      referralCode: _string(map['referralCode']),
      referredByCode: _string(map['referredByCode']),
      affiliateEnabled: _bool(map['affiliateEnabled']),
      payoutMethod: _string(map['payoutMethod'], 'Bank Transfer'),
      subscriptionStatus: _string(map['subscriptionStatus'], 'inactive'),
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
      lastActiveAt: _date(map['lastActiveAt']),
    );
  }

  ArcTraderProfile copyWith({
    String? uid,
    String? uagId,
    String? uagName,
    String? embarkId,
    String? region,
    String? serverPreference,
    String? platform,
    String? timezone,
    bool? visibleInSearch,
    bool? micOk,
    bool? crossRegionOk,
    bool? crossPlatformOk,
    bool? isProfileComplete,
    List<String>? archetypes,
    List<String>? playStyles,
    String? communicationStyle,
    String? squadIntent,
    String? socialEnergy,
    String? referralCode,
    String? referredByCode,
    bool? affiliateEnabled,
    String? payoutMethod,
    String? subscriptionStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActiveAt,
  }) {
    return ArcTraderProfile(
      uid: uid ?? this.uid,
      uagId: uagId ?? this.uagId,
      uagName: uagName ?? this.uagName,
      embarkId: embarkId ?? this.embarkId,
      region: region ?? this.region,
      serverPreference: serverPreference ?? this.serverPreference,
      platform: platform ?? this.platform,
      timezone: timezone ?? this.timezone,
      visibleInSearch: visibleInSearch ?? this.visibleInSearch,
      micOk: micOk ?? this.micOk,
      crossRegionOk: crossRegionOk ?? this.crossRegionOk,
      crossPlatformOk: crossPlatformOk ?? this.crossPlatformOk,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      archetypes: archetypes ?? this.archetypes,
      playStyles: playStyles ?? this.playStyles,
      communicationStyle: communicationStyle ?? this.communicationStyle,
      squadIntent: squadIntent ?? this.squadIntent,
      socialEnergy: socialEnergy ?? this.socialEnergy,
      referralCode: referralCode ?? this.referralCode,
      referredByCode: referredByCode ?? this.referredByCode,
      affiliateEnabled: affiliateEnabled ?? this.affiliateEnabled,
      payoutMethod: payoutMethod ?? this.payoutMethod,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
}
