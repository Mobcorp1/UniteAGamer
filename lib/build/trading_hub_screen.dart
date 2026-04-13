import 'package:flutter/material.dart';

import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/arc_raiders_hub_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/widgets/trading_hub_feature_card.dart';

class TradingHubScreen extends StatelessWidget {
  static const routeName = '/trading-hub';

  const TradingHubScreen({super.key});

  Widget _comingSoonCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceL),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonPink.withValues(alpha: 0.22),
      ),
      child: Column(
        children: [
          const Icon(Icons.extension, color: AppTheme.neonPink, size: 30),
          const SizedBox(height: AppTheme.spaceM),
          Text(
            'More Games Coming',
            textAlign: TextAlign.center,
            style: AppTheme.neonTextStyle(
              fontSize: 22,
              color: AppTheme.neonCyan,
              isBold: true,
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            'Dying Light, Dying Light: The Beast, Dead Island and more trading hubs can be added here later using the same system.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'UAG Traders Hub',
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
                      _comingSoonCard(context),
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
