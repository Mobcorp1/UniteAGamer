import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

/// Full-screen loading treatment used while UAG resolves authentication,
/// session policy and onboarding state.
///
/// The background is deliberately asset-driven. Replace the canonical WebP
/// later without changing this widget or any routing logic.
class UagCinematicLoadingScreen extends StatefulWidget {
  const UagCinematicLoadingScreen({super.key});

  static const backgroundAsset =
      'assets/images/arc_raiders/hub/auth_bg_landscape.webp';

  @override
  State<UagCinematicLoadingScreen> createState() =>
      _UagCinematicLoadingScreenState();
}

class _UagCinematicLoadingScreenState extends State<UagCinematicLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
      lowerBound: 0.35,
      upperBound: 1,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFF020508),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            UagCinematicLoadingScreen.backgroundAsset,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, _, _) => const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF07141A),
                    Color(0xFF020508),
                    Color(0xFF120714),
                  ],
                ),
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x33000000),
                  Color(0x22000000),
                  Color(0xD9000000),
                ],
                stops: [0, 0.48, 1],
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.28),
                    radius: 0.9,
                    colors: [Color(0x2419E6F2), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? 24 : 48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'UAG ARC RAIDERS HUB',
                        textAlign: TextAlign.center,
                        style: AppTheme.tradingHeading(
                          fontSize: compact ? 22 : 28,
                          color: AppTheme.neonCyan,
                        ).copyWith(letterSpacing: 1.8),
                      ),
                      const SizedBox(height: 18),
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, _) => Opacity(
                          opacity: _pulse.value,
                          child: Text(
                            'INITIALISING SYSTEMS',
                            style: AppTheme.tradingHeading(
                              fontSize: compact ? 11 : 13,
                              color: Colors.white,
                            ).copyWith(letterSpacing: 1.4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: SizedBox(
                          width: compact ? size.width * 0.72 : 380,
                          height: 6,
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.55,
                            ),
                            color: AppTheme.neonCyan,
                          ),
                        ),
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
