import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import 'package:uag_arc_raiders_hub/features/auth/session/uag_session_gate_controller.dart';
import 'package:uag_arc_raiders_hub/widgets/static_watermark.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class UagBiometricRelockScreen extends StatefulWidget {
  const UagBiometricRelockScreen({
    super.key,
    required this.user,
    required this.onUnlocked,
    required this.onSignOut,
  });

  final User user;
  final Future<void> Function() onUnlocked;
  final Future<void> Function() onSignOut;

  @override
  State<UagBiometricRelockScreen> createState() =>
      _UagBiometricRelockScreenState();
}

class _UagBiometricRelockScreenState extends State<UagBiometricRelockScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _checking = true;
  bool _unlocking = false;
  bool _canUseBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      final available = await _localAuth.getAvailableBiometrics();

      if (!mounted) return;
      setState(() {
        _canUseBiometrics = supported && (canCheck || available.isNotEmpty);
        _checking = false;
      });

      if (_canUseBiometrics) {
        await _unlockWithBiometrics();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _canUseBiometrics = false;
      });
    }
  }

  Future<void> _unlockWithBiometrics() async {
    if (_unlocking || !_canUseBiometrics) return;

    setState(() {
      _unlocking = true;
    });

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Unlock UAG Arc Raiders Hub',
        biometricOnly: true,
      );

      if (!mounted) return;

      if (!authenticated) {
        setState(() {
          _unlocking = false;
        });
        return;
      }

      await UagSessionGateController.markBiometricUnlocked(
        uid: widget.user.uid,
      );
      await widget.onUnlocked();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _unlocking = false;
      });
    }
  }

  Future<void> _signOutToPasswordLogin() async {
    setState(() => _unlocking = true);
    await widget.onSignOut();
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.user.email ?? 'your account';

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceL),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.neonCyan.withValues(alpha: 0.55),
                      width: 1.3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.neonCyan.withValues(alpha: 0.18),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spaceL),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fingerprint_rounded,
                          color: AppTheme.neonCyan,
                          size: 58,
                          shadows: [
                            Shadow(
                              color: AppTheme.neonCyan.withValues(alpha: 0.65),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spaceM),
                        Text(
                          '',
                          textAlign: TextAlign.center,
                          style: AppTheme.neonTextStyle(
                            fontSize: 30,
                            color: AppTheme.neonCyan,
                            isBold: true,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceS),
                        Text(
                          'Confirm it is you before reopening $email.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceL),
                        if (_checking || _unlocking)
                          const CircularProgressIndicator(
                            color: AppTheme.neonCyan,
                          )
                        else ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _canUseBiometrics
                                  ? _unlockWithBiometrics
                                  : null,
                              icon: const Icon(Icons.fingerprint_rounded),
                              label: const Text('Unlock with biometrics'),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceS),
                          TextButton(
                            onPressed: _signOutToPasswordLogin,
                            child: const Text('Use password sign in'),
                          ),
                        ],
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
