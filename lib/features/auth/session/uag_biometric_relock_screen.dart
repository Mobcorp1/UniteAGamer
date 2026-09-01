import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import 'package:uag_arc_raiders_hub/features/auth/session/uag_session_gate_controller.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_layout_system.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';
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
      backgroundColor: Colors.transparent,
      body: ArcTacticalPageBody(
        width: ArcPageWidth.form,
        scrollable: false,
        child: _checking || _unlocking
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.neonCyan),
              )
            : ArcTacticalStatePanel(
                icon: Icons.fingerprint_rounded,
                title: 'Session Locked',
                message:
                    'Confirm your device biometric unlock or return to password sign in.',
                accent: ArcUiTokens.primaryAccent,
                action: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_canUseBiometrics) ...[
                      ElevatedButton.icon(
                        onPressed: _unlockWithBiometrics,
                        icon: const Icon(Icons.fingerprint_rounded),
                        label: const Text('Unlock with biometrics'),
                      ),
                      const SizedBox(height: ArcUiTokens.gapS),
                    ],
                    OutlinedButton.icon(
                      onPressed: _signOutToPasswordLogin,
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Use password sign in'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
