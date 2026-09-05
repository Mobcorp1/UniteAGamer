import 'package:cloud_firestore/cloud_firestore.dart';

class UagAdRuntimeSettings {
  const UagAdRuntimeSettings({
    required this.adsEnabled,
    required this.bannerEnabled,
    required this.appOpenEnabled,
    required this.interstitialEnabled,
    required this.productionAdsEnabled,
    required this.forceTestAds,
    required this.interstitialEveryTransitions,
    required this.interstitialCooldownSeconds,
    required this.appOpenForegroundCooldownMinutes,
    required this.minimumSessionsBeforeAppOpen,
  });

  final bool adsEnabled;
  final bool bannerEnabled;
  final bool appOpenEnabled;
  final bool interstitialEnabled;
  final bool productionAdsEnabled;
  final bool forceTestAds;
  final int interstitialEveryTransitions;
  final int interstitialCooldownSeconds;
  final int appOpenForegroundCooldownMinutes;
  final int minimumSessionsBeforeAppOpen;

  static const defaults = UagAdRuntimeSettings(
    adsEnabled: true,
    bannerEnabled: true,
    appOpenEnabled: true,
    interstitialEnabled: true,
    productionAdsEnabled: false,
    forceTestAds: true,
    interstitialEveryTransitions: 3,
    interstitialCooldownSeconds: 120,
    appOpenForegroundCooldownMinutes: 15,
    minimumSessionsBeforeAppOpen: 3,
  );

  factory UagAdRuntimeSettings.fromMap(Map<String, dynamic>? data) {
    final value = data ?? const <String, dynamic>{};
    int intValue(String key, int fallback, int min, int max) {
      final parsed = (value[key] as num?)?.toInt() ?? fallback;
      return parsed.clamp(min, max).toInt();
    }

    return UagAdRuntimeSettings(
      adsEnabled: value['adsEnabled'] as bool? ?? defaults.adsEnabled,
      bannerEnabled: value['bannerEnabled'] as bool? ?? defaults.bannerEnabled,
      appOpenEnabled:
          value['appOpenEnabled'] as bool? ?? defaults.appOpenEnabled,
      interstitialEnabled:
          value['interstitialEnabled'] as bool? ?? defaults.interstitialEnabled,
      productionAdsEnabled:
          value['productionAdsEnabled'] as bool? ??
          defaults.productionAdsEnabled,
      forceTestAds: value['forceTestAds'] as bool? ?? defaults.forceTestAds,
      interstitialEveryTransitions: intValue(
        'interstitialEveryTransitions',
        defaults.interstitialEveryTransitions,
        2,
        20,
      ),
      interstitialCooldownSeconds: intValue(
        'interstitialCooldownSeconds',
        defaults.interstitialCooldownSeconds,
        30,
        3600,
      ),
      appOpenForegroundCooldownMinutes: intValue(
        'appOpenForegroundCooldownMinutes',
        defaults.appOpenForegroundCooldownMinutes,
        5,
        240,
      ),
      minimumSessionsBeforeAppOpen: intValue(
        'minimumSessionsBeforeAppOpen',
        defaults.minimumSessionsBeforeAppOpen,
        1,
        20,
      ),
    );
  }

  Map<String, Object> toMap() => <String, Object>{
    'adsEnabled': adsEnabled,
    'bannerEnabled': bannerEnabled,
    'appOpenEnabled': appOpenEnabled,
    'interstitialEnabled': interstitialEnabled,
    'productionAdsEnabled': productionAdsEnabled,
    'forceTestAds': forceTestAds,
    'interstitialEveryTransitions': interstitialEveryTransitions,
    'interstitialCooldownSeconds': interstitialCooldownSeconds,
    'appOpenForegroundCooldownMinutes': appOpenForegroundCooldownMinutes,
    'minimumSessionsBeforeAppOpen': minimumSessionsBeforeAppOpen,
  };

  UagAdRuntimeSettings copyWith({
    bool? adsEnabled,
    bool? bannerEnabled,
    bool? appOpenEnabled,
    bool? interstitialEnabled,
    bool? productionAdsEnabled,
    bool? forceTestAds,
    int? interstitialEveryTransitions,
    int? interstitialCooldownSeconds,
    int? appOpenForegroundCooldownMinutes,
    int? minimumSessionsBeforeAppOpen,
  }) => UagAdRuntimeSettings(
    adsEnabled: adsEnabled ?? this.adsEnabled,
    bannerEnabled: bannerEnabled ?? this.bannerEnabled,
    appOpenEnabled: appOpenEnabled ?? this.appOpenEnabled,
    interstitialEnabled: interstitialEnabled ?? this.interstitialEnabled,
    productionAdsEnabled: productionAdsEnabled ?? this.productionAdsEnabled,
    forceTestAds: forceTestAds ?? this.forceTestAds,
    interstitialEveryTransitions:
        interstitialEveryTransitions ?? this.interstitialEveryTransitions,
    interstitialCooldownSeconds:
        interstitialCooldownSeconds ?? this.interstitialCooldownSeconds,
    appOpenForegroundCooldownMinutes:
        appOpenForegroundCooldownMinutes ??
        this.appOpenForegroundCooldownMinutes,
    minimumSessionsBeforeAppOpen:
        minimumSessionsBeforeAppOpen ?? this.minimumSessionsBeforeAppOpen,
  );
}

class UagAdSettingsRepository {
  UagAdSettingsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _ref =>
      _firestore.collection('app_config').doc('ads');

  Stream<UagAdRuntimeSettings> watch() => _ref.snapshots().map(
    (snapshot) => UagAdRuntimeSettings.fromMap(snapshot.data()),
  );

  Future<UagAdRuntimeSettings> get() async =>
      UagAdRuntimeSettings.fromMap((await _ref.get()).data());

  Future<void> save(UagAdRuntimeSettings settings) =>
      _ref.set(<String, Object?>{
        ...settings.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
}
