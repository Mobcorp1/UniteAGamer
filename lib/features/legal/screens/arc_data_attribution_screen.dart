import 'package:flutter/material.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class ArcDataAttributionScreen extends StatelessWidget {
  const ArcDataAttributionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(title: const Text('Data Attribution')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spaceL),
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceL),
            decoration: AppTheme.tradingCardDecoration(
              borderColor: AppTheme.neonCyan.withValues(alpha: 0.18),
            ),
            child: Text(
              'ARC Raiders Item Intelligence',
              style: AppTheme.tradingHeading(
                fontSize: 26,
                color: AppTheme.neonCyan,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceL),
            decoration: AppTheme.tradingCardDecoration(
              borderColor: AppTheme.neonPink.withValues(alpha: 0.16),
            ),
            child: const Text(
              'UAG Raider uses a locally maintained item-intelligence layer for gameplay advice, item recognition, blueprint guidance, trading guidance, recycle/sell suggestions, and progression warnings.\n\n'
              'Where external community datasets are used as references or import sources, they must be used only where their license allows it and with the required attribution preserved.\n\n'
              'RaidTheory arcraiders-data is MIT licensed. If imported, preserve its license notice and attribution in the project repository.\n\n'
              'GamesRadar, MetaForge, ARC Raiders Database, and wiki pages may be used as human reference sources only unless their terms explicitly allow direct reuse. Do not copy copyrighted editorial tables, images, or page content directly into the app.\n\n'
              'ARC Raiders, related names, game data, assets, images, logos, and trademarks belong to their respective rights holders. UAG Arc Raiders Hub is an unofficial fan-made companion tool and is not affiliated with, endorsed by, or supported by Embark Studios AB or Nexon.',
              style: TextStyle(color: Colors.white70, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
