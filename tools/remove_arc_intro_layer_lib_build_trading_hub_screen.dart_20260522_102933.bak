import 'package:flutter/material.dart';

import 'package:uag_traders_hub/build/app_bar.dart';
import 'package:uag_traders_hub/build/app_drawer.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/arc_raiders_hub_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/widgets/trading_hub_feature_card.dart';

class TradingHubScreen extends StatelessWidget {
  static const routeName = '/trading-hub';

  const TradingHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: const UagAppBar(
        title: 'UAG Arc Raiders Hub',
        subtitle:
            'Choose a live game hub and keep the app shell consistent across the project.',
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceL),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TradingHubFeatureCard(
                        title: 'ARC Raiders Trading',
                        icon: Icons.swap_horiz,
                        description:
                            'Trade blueprints, seeds and resources with other players using structured offers, safer swap guidance and reputation tracking.',
                        backgroundImagePath:
                            'assets/arc_raiders/banners/arc_raiders_hub_banner.webp',
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            ArcRaidersHubScreen.routeName,
                          );
                        },
                      ),
                      const SizedBox(height: AppTheme.spaceL),
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
