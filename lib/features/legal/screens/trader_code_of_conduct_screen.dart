import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/widgets/static_watermark.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class TraderCodeOfConductScreen extends StatelessWidget {
  const TraderCodeOfConductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const sections = <_ConductSection>[
      _ConductSection(
        title: 'Honour agreed trades',
        body:
            'Only confirm a trade when you intend to complete it. Bring the agreed items, communicate changes early and do not deliberately waste another player\'s time.',
        icon: Icons.handshake_outlined,
      ),
      _ConductSection(
        title: 'No real-money item sales',
        body:
            'Do not buy, sell, broker or pressure anyone for real-world money, gift cards, payment links, account access or anything outside the agreed in-game exchange.',
        icon: Icons.balance_rounded,
      ),
      _ConductSection(
        title: 'Use accurate listings',
        body:
            'List only items you genuinely have available. Keep quantities, wanted items and availability current. Remove or pause listings that can no longer be completed.',
        icon: Icons.inventory_2_outlined,
      ),
      _ConductSection(
        title: 'Respect every player',
        body:
            'No harassment, discrimination, threats, abusive language or pressure. Respect communication preferences, accessibility needs and players who decide not to continue a trade.',
        icon: Icons.groups_2_outlined,
      ),
      _ConductSection(
        title: 'Protect accounts and personal information',
        body:
            'Use Embark ID and the Hub coordination tools only for arranging play. Never ask for login credentials, private account information, recovery codes or unnecessary personal details.',
        icon: Icons.shield_outlined,
      ),
      _ConductSection(
        title: '18+ community use',
        body:
            'UAG account, trading, messaging, referral, subscription and community features are for adults only. Do not create an account if you are under 18.',
        icon: Icons.verified_user_outlined,
      ),
      _ConductSection(
        title: 'Report problems honestly',
        body:
            'Report no-shows, scams, abusive conduct and inaccurate listings truthfully. False or retaliatory reports can damage trust and may restrict access to community features.',
        icon: Icons.flag_outlined,
      ),
      _ConductSection(
        title: 'Accept moderation action',
        body:
            'Admins may hide listings, remove intel, restrict messaging, pause referrals or limit account access when reports, abuse signals or policy breaches require review.',
        icon: Icons.admin_panel_settings_outlined,
      ),
      _ConductSection(
        title: 'Beta responsibility',
        body:
            'Closed-beta features may change. Report defects rather than exploiting them, and understand that availability, rewards, reputation and moderation rules may be adjusted as the Hub improves.',
        icon: Icons.science_outlined,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Trader Code of Conduct',
          style: AppTheme.tradingHeading(
            fontSize: 22,
            color: AppTheme.neonCyan,
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/arc_raiders/hub/auth_bg_landscape.webp',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const StaticWatermark(),
          ),
          Container(color: Colors.black.withValues(alpha: 0.72)),
          const StaticWatermark(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 700;
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 14 : 28,
                    compact ? 16 : 28,
                    compact ? 14 : 28,
                    32,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 940),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: AppTheme.tradingCardDecoration(
                              borderColor: AppTheme.neonCyan.withValues(
                                alpha: 0.32,
                              ),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TRADE WITH TRUST',
                                  style: TextStyle(
                                    color: AppTheme.neonCyan,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.8,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'These rules protect fair trades, reliable coordination and a community where reputation means something.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          for (final section in sections) ...[
                            _ConductCard(section: section),
                            const SizedBox(height: 12),
                          ],
                        ],
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

class _ConductSection {
  const _ConductSection({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;
}

class _ConductCard extends StatelessWidget {
  const _ConductCard({required this.section});

  final _ConductSection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonCyan.withValues(alpha: 0.16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(section.icon, color: AppTheme.neonCyan, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  section.body,
                  style: const TextStyle(color: Colors.white70, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
