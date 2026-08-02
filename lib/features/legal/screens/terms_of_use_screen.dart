import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/widgets/static_watermark.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalPage(
      title: 'Terms of Use',
      subtitle: 'Fair trading, trusted intel and community standards.',
      accent: AppTheme.neonCyan,
      sections: [
        _LegalSection(
          'What this hub is',
          'UAG Traders Hub helps players track blueprints, coordinate trades, share intel, build reputation and manage progression. It is an independent, unofficial ARC Raiders companion and is not affiliated with or endorsed by Embark Studios.',
          Icons.hub_outlined,
        ),
        _LegalSection(
          '18+ account requirement',
          'Account creation, messaging, trading, referrals, creator features, subscriptions and community tools are intended for users aged 18 or older. Do not create or use an account if you do not meet that requirement.',
          Icons.verified_user_outlined,
        ),
        _LegalSection(
          'Fair use',
          'Do not abuse listings, offers, matchmaking, referrals, intel reports, rewards or reputation systems. False information, spam, harassment, impersonation, manipulation, botting or exploit use can restrict your account.',
          Icons.balance_rounded,
        ),
        _LegalSection(
          'Trading responsibility and no real-money sales',
          'Trades are coordinated between users inside the game. UAG does not escrow items, does not guarantee outcomes, and does not allow real-money sale, purchase or brokering of in-game items, accounts or access.',
          Icons.handshake_outlined,
        ),
        _LegalSection(
          'Reputation and trust',
          'Successful trades, verified intel, no-shows, cancellations, behaviour and future safety signals may influence trust, visibility, rewards and access to features.',
          Icons.verified_user_outlined,
        ),
        _LegalSection(
          'Intel quality',
          'Intel should be submitted honestly and with the best available location context. Rewards tied to intel should only count when reports are verified, confirmed, correlated or trusted by the system.',
          Icons.radar_rounded,
        ),
        _LegalSection(
          'User content',
          'Profile text, listings, reports, screenshots, notes and feedback you submit must be lawful, accurate where required, and yours to share. UAG may hide, correct or remove content that creates safety, rights or reliability issues.',
          Icons.edit_note_rounded,
        ),
        _LegalSection(
          'Moderation and account restrictions',
          'Admins may limit account access, pause features, hide listings, remove reports, block referrals or preserve evidence when policy breaches, abuse reports, payment risk or safety concerns require review.',
          Icons.admin_panel_settings_outlined,
        ),
        _LegalSection(
          'Referrals and rewards',
          'Referral discounts, commissions, boosts, monthly operations and progression may change during beta. Rewards are for quality contribution, not spam volume, fake accounts or misleading promotion.',
          Icons.auto_graph_rounded,
        ),
        _LegalSection(
          'Subscriptions, ads and payments',
          'Free tiers may include ads and paid tiers may remove or reduce them. Paid access, refunds, taxes and billing status depend on provider-confirmed events before entitlements or revenue are treated as final.',
          Icons.workspace_premium_rounded,
        ),
        _LegalSection(
          'Beta notice',
          'Features, limits, tiers, rewards, marketplace tools, legal wording and data structures may change while UAG Traders Hub is tested and improved. Availability is not guaranteed during beta.',
          Icons.science_outlined,
        ),
        _LegalSection(
          'Legal review and operator details',
          'This beta wording is operational guidance and still needs qualified legal review, final operator details and final launch terms before wider public release.',
          Icons.gavel_rounded,
        ),
      ],
    );
  }
}

class _LegalPage extends StatelessWidget {
  const _LegalPage({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.sections,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final List<_LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title,
          style: AppTheme.tradingHeading(fontSize: 24, color: accent),
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
          Container(color: Colors.black.withValues(alpha: 0.68)),
          const StaticWatermark(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.88),
                  AppTheme.darkBackground.withValues(alpha: 0.30),
                  Colors.black.withValues(alpha: 0.96),
                ],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 700;
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 14 : 28,
                    compact ? 16 : 28,
                    compact ? 14 : 28,
                    28,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _LegalHero(
                            title: title,
                            subtitle: subtitle,
                            accent: accent,
                          ),
                          const SizedBox(height: 18),
                          for (final section in sections) ...[
                            _LegalSectionCard(section: section, accent: accent),
                            const SizedBox(height: 12),
                          ],
                          _LegalFooter(accent: accent),
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

class _LegalHero extends StatelessWidget {
  const _LegalHero({
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.12), blurRadius: 28),
        ],
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/icon/uag_traders_icon_transparent.webp',
            height: 72,
            errorBuilder: (_, _, _) =>
                Icon(Icons.shield_outlined, color: accent, size: 62),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTheme.tradingHeading(fontSize: 32, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'TACTICAL LEGAL BRIEF',
            style: AppTheme.neonTextStyle(
              fontSize: 13,
              color: accent,
              isBold: true,
            ).copyWith(letterSpacing: 1.7),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _LegalSectionCard extends StatelessWidget {
  const _LegalSectionCard({required this.section, required this.accent});

  final _LegalSection section;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(section.icon, color: accent, size: 24),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: AppTheme.tradingHeading(fontSize: 20, color: accent),
                ),
                const SizedBox(height: 6),
                Text(
                  section.body,
                  style: const TextStyle(color: Colors.white70, height: 1.38),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalFooter extends StatelessWidget {
  const _LegalFooter({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: const Text(
        'By continuing, you confirm you understand these terms as part of using the UAG Traders Hub beta.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70, height: 1.35),
      ),
    );
  }
}

class _LegalSection {
  const _LegalSection(this.title, this.body, this.icon);
  final String title;
  final String body;
  final IconData icon;
}
