import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/screens/build/auth/auth_landing_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_layout_system.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

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
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 520;
    final logoSize = (width * 0.25).clamp(86.0, 132.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ArcTacticalPageBody(
        width: ArcPageWidth.form,
        scrollable: false,
        padding: EdgeInsets.all(compact ? 18 : 28),
        child: Center(
          child: ArcTacticalPanel(
            icon: Icons.radar_rounded,
            title: 'UAG ARC RAIDERS HUB',
            subtitle: 'Booting operations hub',
            accent: ArcUiTokens.primaryAccent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: ArcUiTokens.surfaceDecoration(
                    role: ArcSurfaceRole.raised,
                    accent: ArcUiTokens.primaryAccent,
                    radius: ArcUiTokens.radiusL,
                    borderOpacity: 0.34,
                    glow: true,
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Image.asset(
                    'assets/icon/uag_traders_icon_transparent.webp',
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.swap_horiz_rounded,
                      color: ArcUiTokens.primaryAccent,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: ArcUiTokens.gapL),
                Text(
                  'CONNECT. TRADE. HUNT. EXTRACT.',
                  textAlign: TextAlign.center,
                  style: ArcUiTokens.sectionTitle(
                    fontSize: compact ? 14 : 16,
                    color: ArcUiTokens.secondaryAccent,
                  ),
                ),
                const SizedBox(height: ArcUiTokens.gapL),
                const LinearProgressIndicator(
                  minHeight: 2,
                  color: ArcUiTokens.primaryAccent,
                  backgroundColor: Colors.white12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
