import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_my_listings_screen.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/screens/trading_my_offers_screen.dart';
import 'package:uag_traders_hub/widgets/electric_charge_border.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class TradingActivityScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/activity';

  const TradingActivityScreen({
    super.key,
    this.showAppBar = true,
    this.initialTabIndex = 0,
  });

  final bool showAppBar;
  final int initialTabIndex;

  @override
  State<TradingActivityScreen> createState() => _TradingActivityScreenState();
}

class _TradingActivityScreenState extends State<TradingActivityScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex.clamp(0, 1);
  }

  @override
  void didUpdateWidget(covariant TradingActivityScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIndex = widget.initialTabIndex.clamp(0, 1);
    if (nextIndex != _selectedIndex) {
      setState(() => _selectedIndex = nextIndex);
    }
  }

  Widget _toggleButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final content = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: AppTheme.tradingCardDecoration(
          radius: 16,
          borderColor: selected
              ? AppTheme.neonPink
              : AppTheme.tradingSoftBorder,
          backgroundColor: AppTheme.cardBackground,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppTheme.neonPink : AppTheme.neonCyan,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTheme.bodyTextStyle(
                fontSize: 13,
                color: Colors.white,
                isBold: true,
              ),
            ),
          ],
        ),
      ),
    );

    return ElectricChargeBorder(active: selected, radius: 16, child: content);
  }

  @override
  Widget build(BuildContext context) {
    final views = <Widget>[
      const TradingMyListingsScreen(showAppBar: false),
      const TradingMyOffersScreen(showAppBar: false),
    ];

    final content = Stack(
      children: [
        const Positioned.fill(child: StaticWatermark()),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: AppTheme.pagePadding.copyWith(bottom: AppTheme.spaceM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Track your live trading flow in one place.',
                      style: AppTheme.bodyTextStyle(
                        fontSize: 14,
                        color: AppTheme.tradingMutedText,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _toggleButton(
                          label: 'My Listings',
                          icon: Icons.inventory_2_outlined,
                          selected: _selectedIndex == 0,
                          onTap: () => setState(() => _selectedIndex = 0),
                        ),
                        _toggleButton(
                          label: 'My Offers',
                          icon: Icons.local_offer_outlined,
                          selected: _selectedIndex == 1,
                          onTap: () => setState(() => _selectedIndex = 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: IndexedStack(index: _selectedIndex, children: views),
              ),
            ],
          ),
        ),
      ],
    );

    if (!widget.showAppBar) {
      return Scaffold(backgroundColor: AppTheme.darkBackground, body: content);
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text('Activity', style: AppTheme.tradingHeading(fontSize: 25)),
      ),
      body: content,
    );
  }
}
