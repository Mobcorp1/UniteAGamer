import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uag_traders_hub/features/legal/services/legal_gate.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/repositories/arc_user_initializer.dart';
import 'package:uag_traders_hub/reg/onboarding_basic_profile_screen.dart';
import 'package:uag_traders_hub/screens/build/auth/auth_landing_screen.dart';
import 'package:uag_traders_hub/build/home_screen.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class AppEntryGate extends StatefulWidget {
  static const routeName = '/app-entry-gate';

  const AppEntryGate({super.key});

  @override
  State<AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends State<AppEntryGate> {
  bool _fanDisclaimerChecked = false;
  final ArcUserInitializer _initializer = ArcUserInitializer();

  Future<bool> _prepareUser(String uid) async {
    await _initializer.initialize();
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data() ?? <String, dynamic>{};
    return !(data['onboardingComplete'] == true);
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
          future: _prepareUser(user.uid),
          builder: (context, onboardingSnapshot) {
            if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  if (details != null) ...[
                    const SizedBox(height: AppTheme.spaceS),
                    Text(
                      details.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
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
