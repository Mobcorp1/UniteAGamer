import 'package:flutter/material.dart';
import 'package:uag_traders_hub/build/auth/auth_screen.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class AuthLandingScreen extends StatelessWidget {
  static const String routeName = '/auth-landing';

  const AuthLandingScreen({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final phone = size.width < 430;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _UagAuthBackdrop(),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                phone ? 22 : 34,
                phone ? 22 : 30,
                phone ? 22 : 34,
                28,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: size.height - 72),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/icon/uag_traders_icon_transparent.webp',
                          width: 48,
                          height: 48,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'UAG ARC RAIDERS HUB',
                            style: AppTheme.tradingHeading(
                              fontSize: phone ? 17 : 21,
                              color: Colors.white,
                            ).copyWith(letterSpacing: 1.1),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: phone ? 34 : 46),
                    Text(
                      'CONNECT.`nTRADE.`nHUNT.`nEXTRACT.',
                      style: AppTheme.heroTextStyle(
                        fontSize: phone ? 38 : 52,
                        color: Colors.white,
                      ).copyWith(height: 0.95, letterSpacing: 1.1),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Your operations start here.',
                      style: AppTheme.bodyTextStyle(
                        fontSize: 15,
                        color: Colors.white70,
                        isBold: true,
                      ),
                    ),
                    const SizedBox(height: 26),
                    const _AuthIntelCarousel(),
                    const SizedBox(height: 26),
                    _AuthGlassPanel(
                      title: 'Welcome Raider',
                      subtitle: 'Fast email access to your trading hub.',
                      primaryLabel: 'Email Login',
                      secondaryLabel: 'Create Account',
                      onPrimary: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) =>
                                const AuthScreen(initialIsLogin: true),
                          ),
                        );
                      },
                      onSecondary: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) =>
                                const AuthScreen(initialIsLogin: false),
                          ),
                        );
                      },
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

class _UagAuthBackdrop extends StatelessWidget {
  const _UagAuthBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF02030B),
                AppTheme.cardBackgroundDeep,
                const Color(0xFF050014),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        const Positioned.fill(child: StaticWatermark()),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.08, -0.32),
                radius: 0.98,
                colors: [
                  AppTheme.neonCyan.withValues(alpha: 0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.05),
                  Colors.black.withValues(alpha: 0.78),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthIntelCarousel extends StatelessWidget {
  const _AuthIntelCarousel();

  @override
  Widget build(BuildContext context) {
    final cards = const [
      ('LIVE INTEL', 'Dam Battlegrounds', 'High value targets detected'),
      ('EXTRACTION RISK', 'HIGH', 'Risk level elevated'),
      ('MARKET PULSE', 'RISING', 'Prices moving fast'),
    ];

    return SizedBox(
      height: 238,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.78),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          final accent = index == 1 ? AppTheme.neonPink : AppTheme.neonCyan;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: AppTheme.tradingCardDecoration(
                radius: 26,
                borderColor: accent.withValues(alpha: 0.58),
                backgroundColor: AppTheme.cardBackgroundDeep.withValues(
                  alpha: 0.82,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.$1,
                    style: AppTheme.bodyTextStyle(
                      fontSize: 12,
                      color: accent,
                      isBold: true,
                    ).copyWith(letterSpacing: 1.2),
                  ),
                  const Spacer(),
                  Icon(
                    index == 0
                        ? Icons.radar_rounded
                        : index == 1
                        ? Icons.warning_amber_rounded
                        : Icons.show_chart_rounded,
                    color: accent,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    card.$2,
                    style: AppTheme.tradingHeading(
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    card.$3,
                    style: AppTheme.bodyTextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      isBold: true,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AuthGlassPanel extends StatelessWidget {
  const _AuthGlassPanel({
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
  });

  final String title;
  final String subtitle;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.tradingCardDecoration(
        radius: 28,
        borderColor: AppTheme.neonCyan.withValues(alpha: 0.24),
        backgroundColor: AppTheme.cardBackgroundDeep.withValues(alpha: 0.82),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: AppTheme.tradingHeading(
              fontSize: 18,
              color: AppTheme.neonCyan,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [AppTheme.neonPink, AppTheme.neonCyan],
                ),
              ),
              child: ElevatedButton.icon(
                onPressed: onPrimary,
                icon: const Icon(Icons.mail_outline_rounded),
                label: Text(primaryLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onSecondary, child: Text(secondaryLabel)),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, size: 14, color: Colors.white54),
              SizedBox(width: 6),
              Text(
                'Protected by UAG Security Protocols',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
