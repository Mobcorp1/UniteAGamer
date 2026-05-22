import 'package:flutter/material.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/arc_raiders_hub_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/widgets/trading_hub_feature_card.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class TradingHubScreen extends StatelessWidget {
  static const routeName = '/trading-hub';

  const TradingHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'UAG Arc Raiders Hub',
          style: AppTheme.neonTextStyle(
            fontSize: 25,
            color: AppTheme.neonCyan,
            isBold: true,
          ),
        ),
      ),
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
                        title: 'UAG Arc Raiders Hub',
                        icon: Icons.swap_horiz,
                        description:
                            'Trade blueprints, seeds and resources with other players using structured offers, safer swap guidance and reputation tracking.',
                        backgroundImagePath:
                            'assets/arc_raiders/banners/arc_raiders_hub_banner_2.webp',
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            ArcRaidersHubScreen.routeName,
                          );
                        },
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
