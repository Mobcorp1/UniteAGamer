import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_layout_system.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Trader Code of Conduct',
          style: ArcUiTokens.pageTitle(color: ArcUiTokens.primaryAccent),
        ),
      ),
      body: ArcTacticalPageList(
        width: ArcPageWidth.standard,
        maxWidth: 940,
        padding: ArcLayoutTokens.pagePadding(context),
        children: [
          ArcTacticalPanel(
            icon: Icons.shield_outlined,
            title: 'TRADE WITH TRUST',
            subtitle:
                'These rules protect fair trades, reliable coordination and a community where reputation means something.',
            accent: ArcUiTokens.primaryAccent,
            child: Wrap(
              spacing: ArcUiTokens.gapS,
              runSpacing: ArcUiTokens.gapS,
              children: const [
                _ConductChip(label: 'NO REAL-MONEY SALES'),
                _ConductChip(label: 'HONEST REPORTING'),
                _ConductChip(label: 'ADULT COMMUNITY'),
              ],
            ),
          ),
          for (final section in sections) _ConductCard(section: section),
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
    final compact = MediaQuery.sizeOf(context).width < 520;
    return ArcTacticalPanel(
      accent: ArcUiTokens.primaryAccent,
      padding: EdgeInsets.all(compact ? ArcUiTokens.gapM : ArcUiTokens.gapL),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 34 : 38,
            height: compact ? 34 : 38,
            decoration: ArcUiTokens.surfaceDecoration(
              role: ArcSurfaceRole.interactive,
              accent: ArcUiTokens.primaryAccent,
              radius: ArcUiTokens.radiusS,
              borderOpacity: 0.34,
            ),
            child: Icon(
              section.icon,
              color: ArcUiTokens.primaryAccent,
              size: compact ? 18 : 21,
            ),
          ),
          const SizedBox(width: ArcUiTokens.gapM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: ArcUiTokens.cardTitle(fontSize: compact ? 14 : 16),
                ),
                const SizedBox(height: ArcUiTokens.gapS),
                Text(section.body, style: ArcUiTokens.body(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConductChip extends StatelessWidget {
  const _ConductChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ArcUiTokens.chipPadding,
      decoration: ArcUiTokens.chipDecoration(color: ArcUiTokens.primaryAccent),
      child: Text(
        label,
        style: ArcUiTokens.label(color: ArcUiTokens.primaryAccent),
      ),
    );
  }
}
