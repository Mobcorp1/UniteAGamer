import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uag_traders_hub/build/app_bar.dart';
import 'package:uag_traders_hub/build/app_drawer.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class FeatureAccessFlag {
  static const scrappyTracker = 'canAccessScrappyTracker';
  static const traderHub = 'canAccessTraderHub';
  static const matchRaider = 'canAccessMatchRaider';
  static const playLockerPro = 'canAccessPlayLockerPro';
}

class FeatureAccess {
  const FeatureAccess._();

  static const Map<String, String> _globalFieldMap = <String, String>{
    FeatureAccessFlag.scrappyTracker: 'scrappyTrackerEnabled',
    FeatureAccessFlag.traderHub: 'traderHubEnabled',
    FeatureAccessFlag.matchRaider: 'matchRaiderEnabled',
    FeatureAccessFlag.playLockerPro: 'playLockerProEnabled',
  };

  static Stream<bool> watchFlag(String flag) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream<bool>.value(false);
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .asyncMap((snapshot) async {
      final data = snapshot.data() ?? <String, dynamic>{};
      if (data['isAdmin'] == true || data['isDev'] == true || data[flag] == true) {
        return true;
      }

      final globalField = _globalFieldMap[flag];
      if (globalField == null) return false;

      final configSnapshot = await FirebaseFirestore.instance
          .collection('config')
          .doc('feature_access')
          .get();
      final configData = configSnapshot.data() ?? <String, dynamic>{};
      return configData[globalField] == true;
    });
  }

  static Future<bool> hasAccess(String flag) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = snapshot.data() ?? <String, dynamic>{};
    if (data['isAdmin'] == true || data['isDev'] == true || data[flag] == true) {
      return true;
    }

    final globalField = _globalFieldMap[flag];
    if (globalField == null) return false;

    final configSnapshot = await FirebaseFirestore.instance
        .collection('config')
        .doc('feature_access')
        .get();
    final configData = configSnapshot.data() ?? <String, dynamic>{};
    return configData[globalField] == true;
  }

  static Future<void> showLockedDialog(
    BuildContext context, {
    required String title,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: AppTheme.neonPink.withValues(alpha: 0.35),
            ),
          ),
          title: Text(
            title,
            style: AppTheme.tradingHeading(fontSize: 22),
          ),
          content: Text(
            'We\'ll be releasing testing slots for this area shortly. Thanks for being early.',
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
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
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: UagAppBar(
        title: title,
        subtitle: 'Private testing only for now.',
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
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 38,
                        color: AppTheme.neonPink,
                      ),
                      const SizedBox(height: AppTheme.spaceM),
                      Text(
                        'Coming Soon',
                        textAlign: TextAlign.center,
                        style: AppTheme.tradingHeading(fontSize: 26),
                      ),
                      const SizedBox(height: AppTheme.spaceS),
                      const Text(
                        'We\'ll be releasing testing slots for this area shortly. Thanks for being early.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, height: 1.4),
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
    return StreamBuilder<bool>(
      stream: FeatureAccess.watchFlag(flag),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.darkBackground,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.neonCyan),
            ),
          );
        }

        if (snapshot.data == true) {
          return child;
        }

        return FeatureLockedScreen(title: title);
      },
    );
  }
}
