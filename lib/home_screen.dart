import 'package:flutter/material.dart';

import 'package:uag_traders_hub/screens/build/app_drawer.dart';
import 'package:uag_traders_hub/build/trading_hub_screen.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class HomeScreen extends StatelessWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'UAG Traders Hub',
          style: AppTheme.neonTextStyle(
            fontSize: 24,
            color: AppTheme.neonCyan,
            isBold: true,
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceL),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Welcome to UAG Traders Hub',
                        textAlign: TextAlign.center,
                        style: AppTheme.heroTextStyle(
                          fontSize: 36,
                          color: AppTheme.neonCyan,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceM),
                      Text(
                        'Browse listings, create offers, manage trade sessions, and build your trader reputation.',
                        textAlign: TextAlign.center,
                        style: AppTheme.bodyTextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceXL),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.swap_horiz),
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).pushNamed(TradingHubScreen.routeName);
                          },
                          label: const Text('Enter Trading Hub'),
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
