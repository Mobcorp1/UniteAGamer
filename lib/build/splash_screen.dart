import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/screens/build/auth/auth_landing_screen.dart';
import 'package:uag_arc_raiders_hub/screens/build/app_entry_gate.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

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
    await Future.delayed(const Duration(milliseconds: 4200));

    if (!mounted) return;

    final nextRoute = FirebaseAuth.instance.currentUser == null
        ? AuthLandingScreen.routeName
        : AppEntryGate.routeName;

    Navigator.of(context).pushNamedAndRemoveUntil(nextRoute, (_) => false);
  }

  @override
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final logoSize = (width * 0.34).clamp(118.0, 170.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/arc_raiders/loading/loading_hub_background.webp',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.58),
                  Colors.black.withValues(alpha: 0.32),
                  Colors.black.withValues(alpha: 0.78),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  const Spacer(),
                  Container(
                    width: logoSize,
                    height: logoSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.neonCyan.withValues(alpha: 0.12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.neonCyan.withValues(alpha: 0.34),
                          blurRadius: 46,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Image.asset(
                        'assets/icon/uag_traders_icon_transparent.webp',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  Text(
                    'UAG',
                    textAlign: TextAlign.center,
                    style: AppTheme.heroTextStyle(
                      fontSize: (width * 0.18).clamp(54.0, 88.0),
                      color: Colors.white,
                    ).copyWith(letterSpacing: 2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ARC RAIDERS HUB',
                    textAlign: TextAlign.center,
                    style: AppTheme.tradingHeading(
                      fontSize: 20,
                      color: AppTheme.neonCyan,
                    ).copyWith(letterSpacing: 1.4),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'CONNECT. TRADE. HUNT. EXTRACT.',
                    textAlign: TextAlign.center,
                    style: AppTheme.tradingHeading(
                      fontSize: 18,
                      color: AppTheme.neonPink,
                    ).copyWith(letterSpacing: 1.1),
                  ),
                  const Spacer(),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.82, end: 1),
                    duration: const Duration(milliseconds: 1400),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Text(
                      'Booting operations hub...',
                      style: AppTheme.bodyTextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        isBold: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
