import 'package:flutter/material.dart';
import 'package:uag_traders_hub/build/auth/auth_screen.dart';
import 'package:uag_traders_hub/widgets/dose_action_button.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class AuthLandingScreen extends StatelessWidget {
  static const String routeName = '/auth-landing';

  const AuthLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final titleStyle = AppTheme.heroTextStyle(
      fontSize: 52,
      color: AppTheme.neonCyan,
    );
    final subStyle = AppTheme.bodyTextStyle(
      fontSize: 20,
      color: AppTheme.neonPink,
      isBold: true,
    );

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
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
                      horizontal: 32,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth - 64,
                        minHeight: constraints.maxHeight - 48,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 620),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Image.asset(
                                'assets/icon/uag_traders_icon_transparent.webp',
                                height: 140,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.swap_horiz_rounded,
                                  size: 96,
                                  color: AppTheme.neonCyan,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'UAG ARC Raiders Hub',
                                style: titleStyle,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Trade smarter.\nBuild trust.',
                                style: subStyle,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 48),
                              DoseActionButton(
                                label: 'Login',
                                icon: Icons.login,
                                onPressed: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => const AuthScreen(
                                        initialIsLogin: true,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              DoseActionButton(
                                label: 'Register',
                                icon: Icons.person_add_alt_1,
                                variant: DoseActionButtonVariant.secondary,
                                onPressed: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => const AuthScreen(
                                        initialIsLogin: false,
                                      ),
                                    ),
                                  );
                                },
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
