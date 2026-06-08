import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:uag_arc_raiders_hub/screens/build/auth/auth_landing_screen.dart';
import 'package:uag_arc_raiders_hub/widgets/static_watermark.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class UagAppLockGate extends StatefulWidget {
  const UagAppLockGate({super.key, required this.child});

  final Widget child;

  @override
  State<UagAppLockGate> createState() => _UagAppLockGateState();
}

class _UagAppLockGateState extends State<UagAppLockGate>
    with WidgetsBindingObserver {
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _loading = true;
  bool _unlocked = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialiseLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_biometricEnabled && mounted) {
        setState(() => _unlocked = false);
      }
    }
  }

  Future<void> _initialiseLock() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('uag_biometric_login_enabled') ?? false;
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      final available =
          supported && (canCheck || availableBiometrics.isNotEmpty);

      if (!mounted) return;
      setState(() {
        _biometricEnabled = enabled && available;
        _biometricAvailable = available;
        _unlocked = !(enabled && available);
        _loading = false;
      });

      if (enabled && available) {
        await _unlock();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = 'App lock unavailable on this device.';
        _unlocked = true;
        _loading = false;
      });
    }
  }

  Future<void> _unlock() async {
    if (!_biometricEnabled || !_biometricAvailable) return;

    setState(() => _message = null);

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Unlock UAG Arc Raiders Hub',
      );

      if (!mounted) return;
      setState(() {
        _unlocked = authenticated;
        if (!authenticated) {
          _message =
              'Unlock cancelled. Use biometrics or use password instead.';
        }
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.message ?? 'Biometric unlock failed.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = 'Biometric unlock failed: $error');
    }
  }

  Future<void> _signOutAndReturn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('uag_biometric_login_enabled', false);
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthLandingScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Stack(
          children: [
            Positioned.fill(child: StaticWatermark()),
            Center(child: CircularProgressIndicator(color: AppTheme.neonCyan)),
          ],
        ),
      );
    }

    if (_unlocked) return widget.child;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/arc_raiders/hub/auth_bg_landscape.webp',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const StaticWatermark(),
          ),
          Container(color: Colors.black.withValues(alpha: 0.72)),
          const StaticWatermark(),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.66),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.neonCyan.withValues(alpha: 0.45),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.neonCyan.withValues(alpha: 0.18),
                        blurRadius: 34,
                      ),
                      BoxShadow(
                        color: AppTheme.neonPink.withValues(alpha: 0.10),
                        blurRadius: 42,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.fingerprint_rounded,
                        color: AppTheme.neonCyan,
                        size: 72,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'SECURE HUB LOCK',
                        textAlign: TextAlign.center,
                        style: AppTheme.neonTextStyle(
                          fontSize: 26,
                          color: Colors.white,
                          isBold: true,
                        ).copyWith(letterSpacing: 1.4),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Authenticate to continue into UAG Arc Raiders Hub on this device.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, height: 1.35),
                      ),
                      if (_message != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          _message!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.neonPink),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _unlock,
                          icon: const Icon(Icons.lock_open_rounded),
                          label: const Text('UNLOCK HUB'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _signOutAndReturn,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Use password instead'),
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
