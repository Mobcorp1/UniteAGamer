import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uag_traders_hub/screens/build/auth/auth_landing_screen.dart';
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
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final logoSize = (width * 0.34).clamp(118.0, 170.0);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _UagAuthBackdrop(),
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
                  Text(
                    'Booting operations hub...',
                    style: AppTheme.bodyTextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      isBold: true,
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

class _UagAuthBackdrop extends StatelessWidget {
  const _UagAuthBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/arc_raiders/hub/auth_bg_landscape.webp',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, _, _) => const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF02030B),
                  AppTheme.cardBackgroundDeep,
                  Color(0xFF050014),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.24),
                AppTheme.cardBackgroundDeep.withValues(alpha: 0.58),
                Colors.black.withValues(alpha: 0.86),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.12, -0.42),
                  radius: 0.86,
                  colors: [
                    AppTheme.neonCyan.withValues(alpha: 0.20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        const Positioned.fill(child: StaticWatermark()),
      ],
    );
  }
}
