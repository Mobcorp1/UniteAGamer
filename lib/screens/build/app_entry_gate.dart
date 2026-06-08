import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/auth/session/uag_biometric_relock_screen.dart';
import 'package:uag_arc_raiders_hub/features/auth/session/uag_session_gate_controller.dart';
import 'package:uag_arc_raiders_hub/features/legal/services/legal_gate.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_user_initializer.dart';
import 'package:uag_arc_raiders_hub/reg/onboarding_basic_profile_screen.dart';
import 'package:uag_arc_raiders_hub/screens/build/auth/auth_landing_screen.dart';
import 'package:uag_arc_raiders_hub/build/home_screen.dart';
import 'package:uag_arc_raiders_hub/widgets/static_watermark.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class AppEntryGate extends StatefulWidget {
  static const routeName = '/app-entry-gate';

  const AppEntryGate({super.key});

  @override
  State<AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends State<AppEntryGate>
    with WidgetsBindingObserver {
  bool _fanDisclaimerChecked = false;
  final ArcUserInitializer _initializer = ArcUserInitializer();
  Future<bool>? _sessionAllowedFuture;
  Future<bool>? _biometricRelockFuture;
  String? _sessionUid;
  String? _biometricUid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      UagSessionGateController.markAppBackgrounded();
      _biometricRelockFuture = null;
      _biometricUid = null;
      return;
    }

    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {
        _biometricRelockFuture = null;
        _biometricUid = null;
      });
    }
  }

  Future<bool> _sessionAllowedFor(User user) {
    if (_sessionUid != user.uid || _sessionAllowedFuture == null) {
      _sessionUid = user.uid;
      _sessionAllowedFuture = UagSessionGateController.isSessionAllowed(
        user.uid,
      );
    }
    return _sessionAllowedFuture!;
  }

  Future<bool> _biometricRelockRequiredFor(User user) {
    if (_biometricUid != user.uid || _biometricRelockFuture == null) {
      _biometricUid = user.uid;
      _biometricRelockFuture =
          UagSessionGateController.isBiometricRelockRequired(user.uid);
    }
    return _biometricRelockFuture!;
  }

  Future<void> _handleBiometricUnlocked() async {
    _biometricRelockFuture = null;
    _biometricUid = null;
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _clearSilentFirebaseLogin() async {
    _fanDisclaimerChecked = false;
    _sessionAllowedFuture = null;
    _biometricRelockFuture = null;
    _sessionUid = null;
    _biometricUid = null;
    await UagSessionGateController.clearSession();
    await FirebaseAuth.instance.signOut();
  }

  Future<bool> _prepareUser(String uid) async {
    try {
      await _initializer.initialize();
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data() ?? <String, dynamic>{};

      // Signup already captures the basic/trader profile. If the profile exists,
      // do not send the user through the older duplicate onboarding flow.
      final hasBasicProfile = data['basicProfile'] is Map;
      final hasTraderProfile = data['traderProfile'] is Map;
      if (hasBasicProfile || hasTraderProfile) return false;

      return !(data['onboardingComplete'] == true);
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('AppEntryGate prepare user failed: ${error.code}');
      debugPrintStack(stackTrace: stackTrace);

      // Do not trap the user on an endless loading screen if Firestore rules or
      // first-run propagation blocks the profile read. Auth has succeeded, so let
      // the app open and surface any feature-specific permission issue later.
      if (error.code == 'permission-denied' || error.code == 'unavailable') {
        return false;
      }
      rethrow;
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
          future: _sessionAllowedFor(user),
          builder: (context, sessionSnapshot) {
            if (sessionSnapshot.connectionState == ConnectionState.waiting) {
              return const _GateLoadingScaffold();
            }

            final sessionAllowed = sessionSnapshot.data ?? false;
            if (!sessionAllowed) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _clearSilentFirebaseLogin();
              });
              return const AuthLandingScreen();
            }

            return FutureBuilder<bool>(
              future: _biometricRelockRequiredFor(user),
              builder: (context, biometricSnapshot) {
                if (biometricSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const _GateLoadingScaffold();
                }

                final relockRequired = biometricSnapshot.data ?? false;
                if (relockRequired) {
                  _fanDisclaimerChecked = false;
                  return UagBiometricRelockScreen(
                    user: user,
                    onUnlocked: _handleBiometricUnlocked,
                    onSignOut: _clearSilentFirebaseLogin,
                  );
                }

                return FutureBuilder<bool>(
                  future: _prepareUser(user.uid),
                  builder: (context, onboardingSnapshot) {
                    if (onboardingSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const _GateLoadingScaffold();
                    }

                    if (onboardingSnapshot.hasError) {
                      return _GateErrorScaffold(
                        message: 'Could not prepare your trader profile.',
                        details: onboardingSnapshot.error,
                      );
                    }

                    final needsOnboarding = onboardingSnapshot.data ?? true;
                    if (needsOnboarding) {
                      _fanDisclaimerChecked = false;
                      return const OnboardingBasicProfileScreen();
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      _runLegalGateOnce();
                    });

                    return const HomeScreen();
                  },
                );
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
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: const [
          Positioned.fill(child: StaticWatermark()),
          Center(child: CircularProgressIndicator(color: AppTheme.neonCyan)),
        ],
      ),
    );
  }
}

class _GateErrorScaffold extends StatelessWidget {
  const _GateErrorScaffold({required this.message, this.details});

  final String message;
  final Object? details;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.warningAmber,
                    size: 44,
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                  if (details != null) ...[
                    const SizedBox(height: AppTheme.spaceS),
                    Text(
                      details.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
