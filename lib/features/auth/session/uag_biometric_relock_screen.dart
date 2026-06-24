import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import 'package:uag_arc_raiders_hub/features/auth/session/uag_session_gate_controller.dart';
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
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          const Positioned.fill(child: _ArcAuthBackdrop()),
          if (_checking || _unlocking)
            const Center(
              child: CircularProgressIndicator(color: AppTheme.neonCyan),
            )
          else
            Positioned(
              left: AppTheme.spaceL,
              right: AppTheme.spaceL,
              bottom: AppTheme.spaceXL,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_canUseBiometrics)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _unlockWithBiometrics,
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
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ArcAuthBackdrop extends StatelessWidget {
  const _ArcAuthBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/arc_raiders/hub/auth_bg_landscape.webp',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
        Container(color: Colors.black.withValues(alpha: 0.62)),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.82),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.92),
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.0, -0.08),
              radius: 0.82,
              colors: [
                AppTheme.neonCyan.withValues(alpha: 0.10),
                AppTheme.neonPink.withValues(alpha: 0.07),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
