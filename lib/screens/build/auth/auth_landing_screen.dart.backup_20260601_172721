import 'package:flutter/material.dart';
import 'package:uag_traders_hub/build/auth/auth_screen.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class AuthLandingScreen extends StatelessWidget {
  static const String routeName = '/auth-landing';

  const AuthLandingScreen({super.key});

  @override
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
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  phone ? 22 : 34,
                  phone ? 22 : 30,
                  phone ? 22 : 34,
                  28,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: phone ? 430 : 980,
                    minHeight: size.height - 72,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: phone
                        ? CrossAxisAlignment.stretch
                        : CrossAxisAlignment.center,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: phone ? 390 : 920,
                        ),
                        child: Row(
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
                      ),
                      SizedBox(height: phone ? 30 : 38),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: phone ? 390 : 920,
                        ),
                        child: Align(
                          alignment: phone
                              ? Alignment.centerLeft
                              : Alignment.center,
                          child: Text(
                            'CONNECT.\nTRADE.\nHUNT.\nEXTRACT.',
                            textAlign: phone
                                ? TextAlign.left
                                : TextAlign.center,
                            style: AppTheme.heroTextStyle(
                              fontSize: phone ? 38 : 56,
                              color: Colors.white,
                            ).copyWith(height: 0.95, letterSpacing: 1.1),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Your operations start here.',
                        textAlign: TextAlign.center,
                        style: AppTheme.bodyTextStyle(
                          fontSize: 15,
                          color: Colors.white70,
                          isBold: true,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _AuthIntelCarousel(),
                      const SizedBox(height: 18),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: _AuthGlassPanel(
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

class _AuthIntelCarousel extends StatelessWidget {
  const _AuthIntelCarousel();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final phone = width < 430;
    final cardWidth = phone ? (width - 74).clamp(236.0, 308.0) : 286.0;

    Widget card({
      required String label,
      required String value,
      required String detail,
      required IconData icon,
      required Color accent,
      required String asset,
    }) {
      return SizedBox(
        width: cardWidth,
        child: Container(
          margin: const EdgeInsets.only(right: 12),
          clipBehavior: Clip.antiAlias,
          decoration: AppTheme.tradingCardDecoration(
            radius: 24,
            borderColor: accent.withValues(alpha: 0.54),
            backgroundColor: AppTheme.cardBackgroundDeep.withValues(
              alpha: 0.88,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                asset,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, _, _) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.30),
                        AppTheme.cardBackgroundDeep,
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
                      Colors.black.withValues(alpha: 0.26),
                      AppTheme.cardBackgroundDeep.withValues(alpha: 0.68),
                      Colors.black.withValues(alpha: 0.92),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: accent, size: 21),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.bodyTextStyle(
                              fontSize: 11,
                              color: accent,
                              isBold: true,
                            ).copyWith(letterSpacing: 1.0),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.tradingHeading(
                        fontSize: phone ? 21 : 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodyTextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.82),
                        isBold: true,
                      ).copyWith(height: 1.18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920),
        child: SizedBox(
          height: phone ? 186 : 196,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: phone ? 0 : 4),
            children: [
              card(
                label: 'LIVE INTEL',
                value: 'Raid Window',
                detail: 'Track events, drops and current hunt targets.',
                icon: Icons.radar_rounded,
                accent: AppTheme.neonCyan,
                asset: 'assets/images/arc_raiders/hub/card_raid_window.webp',
              ),
              card(
                label: 'EXTRACTION RISK',
                value: 'High Value',
                detail: 'Plan safer runs before you commit gear.',
                icon: Icons.warning_amber_rounded,
                accent: AppTheme.neonPink,
                asset: 'assets/images/arc_raiders/hub/card_high_value.webp',
              ),
              card(
                label: 'MARKET PULSE',
                value: 'Trade Ready',
                detail: 'Blueprints, Scrappy and offers in one hub.',
                icon: Icons.show_chart_rounded,
                accent: AppTheme.neonCyan,
                asset: 'assets/images/arc_raiders/hub/card_trade_ready.webp',
              ),
            ],
          ),
        ),
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
                'Protected by UAG security protocols',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
