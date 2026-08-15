import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uag_arc_raiders_hub/features/auth/session/uag_session_gate_controller.dart';
import 'package:uag_arc_raiders_hub/features/legal/services/legal_gate.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_command_centre_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_mandatory_onboarding_screen.dart';
import 'package:uag_arc_raiders_hub/screens/build/auth/auth_landing_screen.dart';

import 'package:uag_arc_raiders_hub/widgets/theme.dart';

bool arcHasCompletedMandatoryOnboarding(Map<String, dynamic> data) {
  if (data['isAdmin'] == true || data['isDev'] == true) return true;
  if (data['arcMandatoryOnboardingComplete'] == true) return true;

  // PASS 342 migration bridge:
  // Accounts that completed the pre-canonical onboarding flow must not be
  // forced through onboarding again. _needsOnboarding migrates this legacy
  // state to arcMandatoryOnboardingComplete when the account is next loaded.
  if (data['onboardingComplete'] == true) return true;

  return false;
}

bool arcNeedsLegacyOnboardingMigration(Map<String, dynamic> data) {
  if (data['isAdmin'] == true || data['isDev'] == true) return false;
  if (data['arcMandatoryOnboardingComplete'] == true) return false;
  return data['onboardingComplete'] == true;
}

bool arcNeedsMandatoryOnboarding(Map<String, dynamic> data) =>
    !arcHasCompletedMandatoryOnboarding(data);

bool arcNeedsProgressiveOnboarding(Map<String, dynamic> data) =>
    arcNeedsMandatoryOnboarding(data);

class AppEntryGate extends StatefulWidget {
  static const routeName = '/app-entry-gate';

  const AppEntryGate({super.key});

  @override
  State<AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends State<AppEntryGate> {
  bool _fanDisclaimerChecked = false;

  Future<void> _migrateLegacyOnboardingCompletion(
    String uid,
    Map<String, dynamic> data,
  ) async {
    if (!arcNeedsLegacyOnboardingMigration(data)) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'arcMandatoryOnboardingComplete': true,
        'arcMandatoryOnboardingMigratedFromLegacy': true,
        'arcMandatoryOnboardingMigratedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasCompletedOnboarding', true);
    } catch (error, stackTrace) {
      // Migration failure must never throw an already-completed account back
      // into onboarding. The legacy completion flag remains authoritative for
      // this read and migration will be retried on a later entry.
      debugPrint('AppEntryGate legacy onboarding migration failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<bool> _needsOnboarding(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data() ?? <String, dynamic>{};

      if (arcNeedsLegacyOnboardingMigration(data)) {
        await _migrateLegacyOnboardingCompletion(uid, data);
      }

      return arcNeedsMandatoryOnboarding(data);
    } catch (error, stackTrace) {
      debugPrint('AppEntryGate onboarding lookup failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      // A transient Firestore failure must not throw an already-completed
      // account back into setup on the same device.
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('hasCompletedOnboarding') != true;
    }
  }

  Future<void> _runLegalGateOnce() async {
    if (_fanDisclaimerChecked) return;
    _fanDisclaimerChecked = true;

    try {
      await LegalGate.checkFanDisclaimer(context);
    } catch (error, stackTrace) {
      debugPrint('AppEntryGate legal gate failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _GateLoadingScaffold();
        }

        final user = authSnapshot.data;
        if (user == null) {
          _fanDisclaimerChecked = false;
          return const AuthLandingScreen();
        }

        return FutureBuilder<bool>(
          future: UagSessionGateController.isSessionAllowed(user.uid),
          builder: (context, sessionSnapshot) {
            if (sessionSnapshot.connectionState == ConnectionState.waiting) {
              return const _GateLoadingScaffold();
            }

            // Firebase may restore a user automatically on Android or web.
            // The UAG session policy remains authoritative: a restored Firebase
            // user cannot silently enter unless this runtime was explicitly
            // authenticated or Keep Signed In authorises the device.
            if (sessionSnapshot.data != true) {
              _fanDisclaimerChecked = false;
              return const AuthLandingScreen();
            }

            return FutureBuilder<bool>(
              future: _needsOnboarding(user.uid),
              builder: (context, onboardingSnapshot) {
                if (onboardingSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const _GateLoadingScaffold();
                }

                final needsOnboarding = onboardingSnapshot.data ?? true;
                if (needsOnboarding) {
                  _fanDisclaimerChecked = false;
                  return const ArcMandatoryOnboardingScreen();
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _runLegalGateOnce();
                });

                return const ArcCommandCentreScreen();
              },
            );
          },
        );
      },
    );
  }
}

class _GateLoadingScaffold extends StatelessWidget {
  const _GateLoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: const Center(
        child: CircularProgressIndicator(color: AppTheme.neonCyan),
      ),
    );
  }
}
