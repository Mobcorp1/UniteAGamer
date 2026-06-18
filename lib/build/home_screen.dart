import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/build/trading_hub_screen.dart';
import 'package:uag_arc_raiders_hub/build/app_drawer.dart';
import 'package:uag_arc_raiders_hub/widgets/animated_logo.dart';
import 'package:uag_arc_raiders_hub/widgets/dose_action_button.dart';
import 'package:uag_arc_raiders_hub/widgets/static_watermark.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showText = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _showText = true);
    });
  }

  TextStyle _heroStyle(double screenWidth) {
    final size = (screenWidth * 0.065).clamp(32.0, 64.0);
    return AppTheme.heroTextStyle(fontSize: size, color: AppTheme.neonPink);
  }

  TextStyle _subStyle(double screenWidth) {
    final size = (screenWidth * 0.022).clamp(15.0, 22.0);
    return AppTheme.bodyTextStyle(
      fontSize: size,
      color: AppTheme.neonCyan.withValues(alpha: 0.92),
      isBold: true,
    );
  }

  Widget _cinematicBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/arc_raiders/hub/auth_bg_landscape.webp',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const StaticWatermark(),
        ),
        Container(color: Colors.black.withValues(alpha: 0.58)),
        const StaticWatermark(),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.78),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.90),
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.0, -0.08),
              radius: 0.82,
              colors: [
                AppTheme.neonCyan.withValues(alpha: 0.10),
                AppTheme.neonPink.withValues(alpha: 0.07),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 650;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground.withValues(alpha: 0.92),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 12,
        title: SizedBox(
          height: kToolbarHeight,
          width: double.infinity,
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedTextKit(
              animatedTexts: [
                AppTheme.animatedText(
                  'UAG Arc Raiders Hub',
                  Theme.of(context).appBarTheme.titleTextStyle,
                ),
              ],
              isRepeatingAnimation: false,
            ),
          ),
        ),
      ),
      drawer: const AppDrawer(drawerWidth: 250),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _cinematicBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? AppTheme.spaceL : AppTheme.spaceXL,
                    vertical: compact ? AppTheme.spaceL : AppTheme.spaceXL,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - (compact ? 32 : 48),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 980),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: compact
                                ? AppTheme.spaceM
                                : AppTheme.spaceXL,
                            vertical: compact
                                ? AppTheme.spaceL
                                : AppTheme.spaceXL,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: AppTheme.neonCyan.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              AnimatedLogo(
                                assetPath:
                                    'assets/icon/uag_traders_icon_transparent.webp',
                                size: compact ? 132 : 176,
                              ),
                              const SizedBox(height: 24),
                              if (_showText) ...[
                                AnimatedTextKit(
                                  animatedTexts: [
                                    TypewriterAnimatedText(
                                      'UAG Arc Raiders Hub',
                                      textStyle: _heroStyle(screenWidth),
                                      speed: const Duration(milliseconds: 85),
                                    ),
                                  ],
                                  isRepeatingAnimation: false,
                                ),
                                const SizedBox(height: 14),
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 650),
                                  opacity: 1,
                                  child: Text(
                                    'Welcome back.\nBuild trust, browse trades, and manage your ARC Raiders deals.',
                                    textAlign: TextAlign.center,
                                    style: _subStyle(screenWidth),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 28),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 520,
                                ),
                                child: DoseActionButton(
                                  label: 'Enter UAG Arc Raiders Hub',
                                  icon: Icons.swap_horiz_rounded,
                                  onPressed: () {
                                    Navigator.of(
                                      context,
                                    ).pushNamed(TradingHubScreen.routeName);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
