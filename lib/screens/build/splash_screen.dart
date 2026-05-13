import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uag_traders_hub/screens/build/auth/auth_landing_screen.dart';
import 'package:uag_traders_hub/widgets/animated_logo.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class SplashScreen extends StatefulWidget {
  static const String routeName = '/splash';

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AuthLandingScreen.routeName, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AnimatedLogo(
                    assetPath: 'assets/icon/uag_traders_icon_transparent.webp',
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'UAG Arc Raiders Hub',
                    textAlign: TextAlign.center,
                    style: AppTheme.heroTextStyle(
                      fontSize: screenWidth * 0.09,
                      color: AppTheme.neonPink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Trade smarter. Build trust.',
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyTextStyle(
                      fontSize: (screenWidth * 0.03).clamp(16.0, 20.0),
                      color: AppTheme.neonCyan,
                      isBold: true,
                    ),
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
