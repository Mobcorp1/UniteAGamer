import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/widgets/static_watermark.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalPage(
      title: 'Privacy Policy',
      subtitle: 'How account, trading, intel and referral data is handled.',
      accent: AppTheme.neonPink,
      sections: [
        _LegalSection(
          'Account data',
          'We may store your email, display name, region, platform, timezone, account tier, referral code, affiliate status and onboarding choices so the hub works properly.',
          Icons.person_outline_rounded,
        ),
        _LegalSection(
          'Trading and reputation data',
          'Listings, offers, sessions, completed trades, cancellations, no-shows, reputation signals and marketplace behaviour may be stored to support safer trading.',
          Icons.handshake_outlined,
        ),
        _LegalSection(
          'Intel reports',
          'Drop sightings, map/event data, confirmations and trust weighting may be stored so community intelligence can improve over time.',
          Icons.radar_rounded,
        ),
        _LegalSection(
          'Referrals and rewards',
          'Referral codes, signups, subscription status, reward progress, commission rates and monthly operations may be tracked to support the referral system.',
          Icons.auto_graph_rounded,
        ),
        _LegalSection(
          'Device preferences',
          'The app may remember your email locally if you choose that option. Biometric settings are device-level preferences used for login convenience.',
          Icons.fingerprint_rounded,
        ),
        _LegalSection(
          'Safety and abuse prevention',
          'Data may be used to detect spam, fake intel, suspicious referrals, marketplace manipulation, repeated no-shows and behaviour that harms the community.',
          Icons.health_and_safety_outlined,
        ),
        _LegalSection(
          'Payments later',
          'Subscription and payment handling will be integrated later through providers such as Stripe. Sensitive payment details should be handled by the provider, not directly stored by UAG.',
          Icons.payments_outlined,
        ),
        _LegalSection(
          'Beta changes',
          'Because the product is still developing, data models, features and reward systems may change as the app improves.',
          Icons.science_outlined,
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
      backgroundColor: AppTheme.darkBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.58),
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
                Icon(Icons.privacy_tip_outlined, color: accent, size: 62),
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
        'By continuing, you confirm you understand how core UAG Traders Hub data may be used to run the beta safely and improve the platform.',
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
