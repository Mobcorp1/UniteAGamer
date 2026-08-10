import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/build/app_bar.dart';
import 'package:uag_arc_raiders_hub/build/app_drawer.dart';
import 'package:uag_arc_raiders_hub/widgets/static_watermark.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class FeatureAccessFlag {
  static const scrappyTracker = 'canAccessScrappyTracker';
  static const traderHub = 'canAccessTraderHub';
  static const matchRaider = 'canAccessMatchRaider';
  static const playLockerPro = 'canAccessPlayLockerPro';

  static const blueprintTracker = 'canAccessBlueprintTracker';
  static const intelExplorer = 'canAccessIntelExplorer';
  static const benchTracker = 'canAccessBenchTracker';
  static const questTracker = 'canAccessQuestTracker';
  static const raidPlanner = 'canAccessRaidPlanner';
  static const voiceAssistant = 'canAccessVoiceAssistant';
  static const monetisation = 'canAccessMonetisation';
  static const smartTradeAssist = 'canAccessSmartTradeAssist';
  static const raiderContracts = 'canAccessRaiderContracts';
}

enum FeatureAvailability {
  live,
  comingSoon,
  hidden;

  String get storageValue {
    switch (this) {
      case FeatureAvailability.live:
        return 'live';
      case FeatureAvailability.comingSoon:
        return 'comingSoon';
      case FeatureAvailability.hidden:
        return 'hidden';
    }
  }

  String get label {
    switch (this) {
      case FeatureAvailability.live:
        return 'Live';
      case FeatureAvailability.comingSoon:
        return 'Coming Soon';
      case FeatureAvailability.hidden:
        return 'Hidden';
    }
  }

  bool get isLive => this == FeatureAvailability.live;
  bool get isComingSoon => this == FeatureAvailability.comingSoon;
  bool get isHidden => this == FeatureAvailability.hidden;
  bool get isVisibleToStandardUsers => !isHidden;
  bool get canOpenFeature => isLive;

  static FeatureAvailability? fromStorage(Object? value) {
    final normalized = value?.toString().trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '',
    );
    switch (normalized) {
      case 'live':
      case 'enabled':
      case 'true':
        return FeatureAvailability.live;
      case 'comingsoon':
      case 'soon':
      case 'beta':
        return FeatureAvailability.comingSoon;
      case 'hidden':
      case 'disabled':
      case 'false':
        return FeatureAvailability.hidden;
    }
    return null;
  }
}

class FeatureAccess {
  const FeatureAccess._();

  static const Map<String, String> _globalFieldMap = {
    FeatureAccessFlag.scrappyTracker: 'scrappyTrackerEnabled',
    FeatureAccessFlag.traderHub: 'traderHubEnabled',
    FeatureAccessFlag.matchRaider: 'matchRaiderEnabled',
    FeatureAccessFlag.playLockerPro: 'playLockerProEnabled',
    FeatureAccessFlag.blueprintTracker: 'blueprintTrackerEnabled',
    FeatureAccessFlag.intelExplorer: 'intelExplorerEnabled',
    FeatureAccessFlag.benchTracker: 'benchTrackerEnabled',
    FeatureAccessFlag.questTracker: 'questTrackerEnabled',
    FeatureAccessFlag.raidPlanner: 'raidPlannerEnabled',
    FeatureAccessFlag.voiceAssistant: 'voiceAssistantEnabled',
    FeatureAccessFlag.monetisation: 'monetisationEnabled',
    FeatureAccessFlag.smartTradeAssist: 'smartTradeAssistEnabled',
    FeatureAccessFlag.raiderContracts: 'raiderContractsEnabled',
  };

  static String availabilityFieldForGlobalField(String globalField) {
    if (globalField.endsWith('Enabled')) {
      return '${globalField.substring(0, globalField.length - 7)}Availability';
    }
    return '${globalField}Availability';
  }

  static String? globalFieldForFlag(String flag) => _globalFieldMap[flag];

  static FeatureAvailability availabilityFromConfigData(
    Map<String, dynamic> data,
    String globalFieldOrFlag,
  ) {
    final globalField = _globalFieldMap[globalFieldOrFlag] ?? globalFieldOrFlag;
    final availabilityField = availabilityFieldForGlobalField(globalField);
    final explicit = FeatureAvailability.fromStorage(data[availabilityField]);
    if (explicit != null) return explicit;
    final legacy = data[globalField];
    if (legacy == true) return FeatureAvailability.live;
    if (legacy == false) return FeatureAvailability.hidden;
    return FeatureAvailability.hidden;
  }

  static Stream<bool> watchFlag(String flag) {
    return watchAvailability(flag).map((availability) => availability.isLive);
  }

  static Stream<FeatureAvailability> watchAvailability(String flag) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(FeatureAvailability.hidden);
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .asyncMap((snapshot) async {
          final data = snapshot.data() ?? {};
          if (data['isAdmin'] == true ||
              data['isDev'] == true ||
              data[flag] == true) {
            return FeatureAvailability.live;
          }

          final globalField = _globalFieldMap[flag];
          if (globalField == null) return FeatureAvailability.hidden;

          final configSnapshot = await FirebaseFirestore.instance
              .collection('config')
              .doc('feature_access')
              .get();
          final configData = configSnapshot.data() ?? {};
          return availabilityFromConfigData(configData, globalField);
        });
  }

  static Stream<Map<String, FeatureAvailability>> watchAvailabilityMap(
    Iterable<String> flags,
  ) {
    final resolvedFlags = flags.toSet().toList(growable: false)..sort();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(<String, FeatureAvailability>{
        for (final flag in resolvedFlags) flag: FeatureAvailability.hidden,
      });
    }

    return FirebaseFirestore.instance
        .collection('config')
        .doc('feature_access')
        .snapshots()
        .asyncMap((configSnapshot) async {
          final userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          final userData = userSnapshot.data() ?? const <String, dynamic>{};
          final configData = configSnapshot.data() ?? const <String, dynamic>{};
          return <String, FeatureAvailability>{
            for (final flag in resolvedFlags)
              flag: _availabilityFor(flag, userData, configData),
          };
        });
  }

  static Future<bool> hasAccess(String flag) async {
    return (await getAvailability(flag)).isLive;
  }

  static Future<FeatureAvailability> getAvailability(String flag) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return FeatureAvailability.hidden;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = snapshot.data() ?? {};
    if (data['isAdmin'] == true ||
        data['isDev'] == true ||
        data[flag] == true) {
      return FeatureAvailability.live;
    }

    final globalField = _globalFieldMap[flag];
    if (globalField == null) return FeatureAvailability.hidden;

    final configSnapshot = await FirebaseFirestore.instance
        .collection('config')
        .doc('feature_access')
        .get();
    final configData = configSnapshot.data() ?? {};
    return availabilityFromConfigData(configData, globalField);
  }

  static Map<String, FeatureAvailability> availabilityMapFromConfigData(
    Map<String, dynamic> data,
    Iterable<String> flags,
  ) {
    return <String, FeatureAvailability>{
      for (final flag in flags) flag: availabilityFromConfigData(data, flag),
    };
  }

  static Map<String, FeatureAvailability> availabilityMapFromUserAndConfigData({
    required Map<String, dynamic> userData,
    required Map<String, dynamic> configData,
    required Iterable<String> flags,
  }) {
    return <String, FeatureAvailability>{
      for (final flag in flags)
        flag: _availabilityFor(flag, userData, configData),
    };
  }

  static Map<String, dynamic> updatePayloadForAvailability({
    required String globalField,
    required FeatureAvailability availability,
  }) {
    return <String, dynamic>{
      globalField: availability.isLive,
      availabilityFieldForGlobalField(globalField): availability.storageValue,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static String featureLiveNotificationKey({
    required String uid,
    required String flag,
  }) {
    return '${uid.trim()}_${flag.trim()}_feature_live';
  }

  static bool shouldNotifyComingSoonToLive({
    required FeatureAvailability previous,
    required FeatureAvailability next,
  }) {
    return previous.isComingSoon && next.isLive;
  }

  static FeatureAvailability _availabilityFor(
    String flag,
    Map<String, dynamic> userData,
    Map<String, dynamic> configData,
  ) {
    if (userData['isAdmin'] == true ||
        userData['isDev'] == true ||
        userData[flag] == true) {
      return FeatureAvailability.live;
    }
    final globalField = _globalFieldMap[flag];
    if (globalField == null) return FeatureAvailability.hidden;
    return availabilityFromConfigData(configData, globalField);
  }

  static Future<bool> isAdminOrDev() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = snapshot.data() ?? {};
    return data['isAdmin'] == true || data['isDev'] == true;
  }

  static Future<void> showLockedDialog(
    BuildContext context, {
    required String title,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: AppTheme.neonPink.withValues(alpha: 0.35)),
          ),
          title: Text(
            'Coming Soon',
            style: AppTheme.tradingHeading(
              fontSize: 22,
              color: AppTheme.neonPink,
            ),
          ),
          content: Text(
            '$title is coming soon. Available in a future beta release. The Blueprint Tracker beta is currently the focus.',
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class FeatureLockedScreen extends StatelessWidget {
  const FeatureLockedScreen({
    super.key,
    required this.title,
    this.availability = FeatureAvailability.comingSoon,
  });

  final String title;
  final FeatureAvailability availability;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: UagAppBar(
        title: title,
        subtitle: availability.isHidden ? 'Unavailable.' : 'Coming soon.',
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: AppTheme.pagePadding,
                child: Container(
                  width: double.infinity,
                  padding: AppTheme.sectionCardPadding,
                  decoration: AppTheme.tradingCardDecoration(
                    borderColor: AppTheme.neonPink.withValues(alpha: 0.28),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        availability.isHidden
                            ? Icons.visibility_off_outlined
                            : Icons.lock_outline_rounded,
                        size: 38,
                        color: availability.isHidden
                            ? Colors.white60
                            : AppTheme.neonPink,
                      ),
                      const SizedBox(height: AppTheme.spaceM),
                      Text(
                        availability.isHidden ? 'Unavailable' : 'Coming Soon',
                        textAlign: TextAlign.center,
                        style: AppTheme.tradingHeading(fontSize: 26),
                      ),
                      const SizedBox(height: AppTheme.spaceS),
                      Text(
                        availability.isHidden
                            ? '$title is currently hidden from closed beta users.'
                            : '$title is coming soon. Available in a future beta release. The Blueprint Tracker beta is currently the focus.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FeatureComingSoonScreen extends StatelessWidget {
  const FeatureComingSoonScreen({
    super.key,
    required this.title,
    this.description,
    this.purpose,
    this.benefits = const <String>[],
  });

  final String title;
  final String? description;
  final String? purpose;
  final List<String> benefits;

  @override
  Widget build(BuildContext context) {
    final resolvedBenefits = benefits.isEmpty
        ? const <String>[
            'Visible in closed beta so you can plan ahead.',
            'Selectable as an interest for future personalisation.',
            'Launch is blocked until the feature is marked Live.',
          ]
        : benefits;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: UagAppBar(title: title, subtitle: 'Coming soon.'),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: AppTheme.pagePadding,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Container(
                    width: double.infinity,
                    padding: AppTheme.sectionCardPadding,
                    decoration: AppTheme.tradingCardDecoration(
                      borderColor: AppTheme.neonCyan.withValues(alpha: 0.28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.asset(
                                'assets/icon/uag_traders_icon_transparent.webp',
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spaceM),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: AppTheme.tradingHeading(
                                      fontSize: 28,
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spaceS),
                                  Text(
                                    'Closed Beta Status: Coming Soon',
                                    style: AppTheme.bodyTextStyle(
                                      fontSize: 12,
                                      color: AppTheme.neonCyan,
                                      isBold: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spaceL),
                        Text(
                          description?.trim().isNotEmpty == true
                              ? description!.trim()
                              : '$title is visible during closed beta, but it is not ready to launch yet.',
                          style: AppTheme.bodyTextStyle(
                            fontSize: 15,
                            color: Colors.white70,
                          ),
                        ),
                        if (purpose?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: AppTheme.spaceM),
                          Text(
                            purpose!.trim(),
                            style: AppTheme.bodyTextStyle(
                              fontSize: 14,
                              color: AppTheme.tradingMutedText,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppTheme.spaceM),
                        for (final benefit in resolvedBenefits)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.bolt_rounded,
                                  size: 16,
                                  color: AppTheme.neonPink,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    benefit,
                                    style: AppTheme.bodyTextStyle(
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: AppTheme.spaceM),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Use Personalisation in Settings to register interest. Feature-live notifications are queued only when supported.',
                                    style: AppTheme.bodyTextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.bookmark_add_outlined),
                            label: const Text('Register Interest'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FeatureAccessRouteGate extends StatelessWidget {
  const FeatureAccessRouteGate({
    super.key,
    required this.flag,
    required this.title,
    required this.child,
  });

  final String flag;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FeatureAvailability>(
      stream: FeatureAccess.watchAvailability(flag),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.neonCyan),
            ),
          );
        }

        final availability = snapshot.data ?? FeatureAvailability.hidden;
        if (availability.isLive) {
          return child;
        }

        if (availability.isComingSoon) {
          return FeatureComingSoonScreen(title: title);
        }

        return FeatureLockedScreen(
          title: title,
          availability: FeatureAvailability.hidden,
        );
      },
    );
  }
}
