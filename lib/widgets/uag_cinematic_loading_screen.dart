import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

/// Shared in-app boot treatment. Mirrors the approved web boot screen so
/// Android, iOS and Flutter web converge on the same UAG first impression.
class UagCinematicLoadingScreen extends StatefulWidget {
  const UagCinematicLoadingScreen({super.key});

  @override
  State<UagCinematicLoadingScreen> createState() =>
      _UagCinematicLoadingScreenState();
}

class _UagCinematicLoadingScreenState extends State<UagCinematicLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scan;

  @override
  void initState() {
    super.initState();
    _scan = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _scan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final phone = size.width < 600;
    final panelWidth = phone ? size.width * 0.94 : 560.0;
    final logoSize = phone ? 150.0 : 190.0;

    return Scaffold(
      backgroundColor: const Color(0xFF020508),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/arc_raiders/hub/auth_bg_landscape.webp',
            fit: BoxFit.cover,
            alignment: phone ? const Alignment(-0.28, 0) : Alignment.center,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x1A000000),
                  Color(0x2E000000),
                  Color(0xE0000000),
                ],
                stops: [0, 0.46, 1],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Container(
                width: panelWidth,
                margin: EdgeInsets.symmetric(horizontal: phone ? 24 : 32),
                padding: EdgeInsets.fromLTRB(
                  phone ? 24 : 36,
                  phone ? 30 : 34,
                  phone ? 24 : 36,
                  phone ? 26 : 30,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.neonCyan.withValues(alpha: 0.18),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF030D12).withValues(alpha: 0.52),
                      const Color(0xFF020508).withValues(alpha: 0.78),
                    ],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x57000000),
                      blurRadius: 80,
                      offset: Offset(0, 24),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/icon/uag_traders_icon_transparent.png',
                      width: logoSize,
                      height: logoSize,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'UAG ARC RAIDERS HUB',
                      textAlign: TextAlign.center,
                      style:
                          AppTheme.tradingHeading(
                            fontSize: phone ? 21 : 28,
                            color: AppTheme.neonCyan,
                          ).copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                    ),
                    SizedBox(height: phone ? 28 : 30),
                    const Text(
                      'INITIALISING SYSTEMS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        height: 9,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.56),
                          border: Border.all(
                            color: AppTheme.neonCyan.withValues(alpha: 0.28),
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final barWidth = constraints.maxWidth * 0.18;
                            return AnimatedBuilder(
                              animation: _scan,
                              builder: (context, _) {
                                final travel = constraints.maxWidth + barWidth;
                                return Stack(
                                  children: [
                                    Positioned(
                                      left: (_scan.value * travel) - barWidth,
                                      top: 0,
                                      bottom: 0,
                                      width: barWidth,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          gradient: const LinearGradient(
                                            colors: [
                                              AppTheme.neonCyan,
                                              Color(0xFF55D9FF),
                                              AppTheme.neonPink,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0x6B10E7F3),
                            Color(0x66D52BD5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
