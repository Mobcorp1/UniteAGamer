import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:uag_traders_hub/build/trading_hub_screen.dart';
import 'package:uag_traders_hub/screens/build/app_drawer.dart';
import 'package:uag_traders_hub/widgets/animated_logo.dart';
import 'package:uag_traders_hub/widgets/dose_action_button.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
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
                  'UAG Raiders Hub',
                  Theme.of(context).appBarTheme.titleTextStyle,
                ),
              ],
              isRepeatingAnimation: false,
            ),
          ),
        ),
      ),
      drawer: const AppDrawer(drawerWidth: 250),
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(child: StaticWatermark()),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceXL,
                      vertical: AppTheme.spaceL,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth - (AppTheme.spaceXL * 2),
                        minHeight: constraints.maxHeight - (AppTheme.spaceL * 2),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 980),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              AnimatedLogo(
                                assetPath:
                                    'assets/icon/uag_traders_icon_transparent.webp',
                                size: screenWidth >= 900 ? 180 : 150,
                              ),
                              const SizedBox(height: 24),
                              if (_showText) ...[
                                AnimatedTextKit(
                                  animatedTexts: [
                                    TypewriterAnimatedText(
                                      'UAG Raiders Hub',
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
                                constraints: const BoxConstraints(maxWidth: 520),
                                child: DoseActionButton(
                                  label: 'Enter Trading Hub',
                                  icon: Icons.swap_horiz_rounded,
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pushNamed(TradingHubScreen.routeName);
                                  },
                                ),
                              ),
                            ],
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
      ),
    );
  }
}
