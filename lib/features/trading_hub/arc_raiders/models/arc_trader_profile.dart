import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_player_archetype_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_player_session_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_profile_social_models.dart';

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
  final String sessionIntent;
  final String currentPriority;
  final String referralCode;
  final String referredByCode;
  final bool affiliateEnabled;
  final String payoutMethod;
  final String subscriptionStatus;
  final List<ArcProfileSocialLink> socialLinks;
  final ArcCreatorProgrammeProfile creatorProgramme;
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
    this.sessionIntent = ArcPlayerSessionCatalog.defaultIntent,
    this.currentPriority = ArcPlayerSessionCatalog.defaultPriority,
    required this.referralCode,
    required this.referredByCode,
    required this.affiliateEnabled,
    required this.payoutMethod,
    required this.subscriptionStatus,
    this.socialLinks = const <ArcProfileSocialLink>[],
    this.creatorProgramme = const ArcCreatorProgrammeProfile(),
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
      sessionIntent: ArcPlayerSessionCatalog.defaultIntent,
      currentPriority: ArcPlayerSessionCatalog.defaultPriority,
      referralCode: '',
      referredByCode: '',
      affiliateEnabled: false,
      payoutMethod: 'Bank Transfer',
      subscriptionStatus: 'inactive',
      socialLinks: const <ArcProfileSocialLink>[],
      creatorProgramme: const ArcCreatorProgrammeProfile(),
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

  List<ArcProfileSocialLink> get publicSocialLinks =>
      ArcProfileSocialLinks.publicLinks(socialLinks);

  Map<String, dynamic> toMap() {
    final normalisedSocialLinks = ArcProfileSocialLinks.merge(socialLinks);
    final normalisedCreatorProgramme = creatorProgramme.normalised(
      referralCode: referralCode,
      affiliateRequested: affiliateEnabled,
    );
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
      'sessionIntent': ArcPlayerSessionCatalog.normalizeIntent(sessionIntent),
      'currentPriority': ArcPlayerSessionCatalog.normalizePriority(
        currentPriority,
      ),
      'playStyle': playStyles.isNotEmpty ? playStyles.first : '',
      'referralCode': referralCode,
      'referredByCode': referredByCode,
      'affiliateEnabled': affiliateEnabled,
      'payoutMethod': payoutMethod,
      'subscriptionStatus': subscriptionStatus,
      'socialLinks': normalisedSocialLinks
          .map((link) => link.toMap())
          .toList(growable: false),
      'publicSocialLinks': ArcProfileSocialLinks.publicLinks(
        normalisedSocialLinks,
      ).map((link) => link.toPublicMap()).toList(growable: false),
      'creatorProgramme': normalisedCreatorProgramme.toMap(),
      'publicCreatorProgramme': normalisedCreatorProgramme.toPublicMap(),
      'creatorProgrammeStatus': normalisedCreatorProgramme.status.name,
      'creatorProgrammeApproved': normalisedCreatorProgramme.adminApproved,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'lastActiveAt': lastActiveAt == null
          ? null
          : Timestamp.fromDate(lastActiveAt!),
    };
  }

  Map<String, dynamic> toPublicProfileMap({required Object updatedAt}) {
    final normalisedCreatorProgramme = creatorProgramme.normalised(
      referralCode: referralCode,
      affiliateRequested: affiliateEnabled,
    );
    final publicName = uagName.trim().isEmpty ? 'New Trader' : uagName.trim();
    return <String, dynamic>{
      'uid': uid,
      'uagId': uagId.trim(),
      'uagName': publicName,
      'displayName': publicName,
      'region': region.trim(),
      'platform': platform.trim(),
      'serverPreference': serverPreference.trim().isEmpty
          ? 'Automatic'
          : serverPreference.trim(),
      'visibleInSearch': visibleInSearch,
      'archetypes': ArcPlayerArchetypeCatalog.normalizeLabels(
        archetypes,
        includeDefaultWhenEmpty: true,
      ),
      'playStyles': playStyles,
      'communicationStyle': communicationStyle.trim(),
      'squadIntent': squadIntent.trim(),
      'socialEnergy': socialEnergy.trim(),
      'sessionIntent': ArcPlayerSessionCatalog.normalizeIntent(sessionIntent),
      'currentPriority': ArcPlayerSessionCatalog.normalizePriority(
        currentPriority,
      ),
      'publicSocialLinks': publicSocialLinks
          .map((link) => link.toPublicMap())
          .toList(growable: false),
      'creatorProgramme': normalisedCreatorProgramme.toPublicMap(),
      'creatorProgrammeStatus': normalisedCreatorProgramme.hasPublicRecognition
          ? normalisedCreatorProgramme.status.name
          : ArcCreatorProgrammeStatus.none.name,
      'creatorProgrammeApproved': normalisedCreatorProgramme.adminApproved,
      'updatedAt': updatedAt,
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
      sessionIntent: ArcPlayerSessionCatalog.normalizeIntent(
        _string(map['sessionIntent'], _string(map['squadIntent'])),
      ),
      currentPriority: ArcPlayerSessionCatalog.normalizePriority(
        _string(map['currentPriority']),
      ),
      referralCode: _string(map['referralCode']),
      referredByCode: _string(map['referredByCode']),
      affiliateEnabled: _bool(map['affiliateEnabled']),
      payoutMethod: _string(map['payoutMethod'], 'Bank Transfer'),
      subscriptionStatus: _string(map['subscriptionStatus'], 'inactive'),
      socialLinks: ArcProfileSocialLinks.fromProfileMaps(<Map<String, dynamic>>[
        map,
      ]),
      creatorProgramme: ArcCreatorProgrammeProfile.fromMap(
        map['creatorProgramme'],
        fallbackReferralCode: _string(map['referralCode']),
        affiliateEnabled: _bool(map['affiliateEnabled']),
      ),
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
    String? sessionIntent,
    String? currentPriority,
    String? referralCode,
    String? referredByCode,
    bool? affiliateEnabled,
    String? payoutMethod,
    String? subscriptionStatus,
    List<ArcProfileSocialLink>? socialLinks,
    ArcCreatorProgrammeProfile? creatorProgramme,
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
      sessionIntent: sessionIntent ?? this.sessionIntent,
      currentPriority: currentPriority ?? this.currentPriority,
      referralCode: referralCode ?? this.referralCode,
      referredByCode: referredByCode ?? this.referredByCode,
      affiliateEnabled: affiliateEnabled ?? this.affiliateEnabled,
      payoutMethod: payoutMethod ?? this.payoutMethod,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      socialLinks: socialLinks ?? this.socialLinks,
      creatorProgramme: creatorProgramme ?? this.creatorProgramme,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
}
