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
          'We may store your email, display name, Raider name, region, platform, timezone, account tier, referral code, affiliate status, age confirmation and onboarding choices so the hub works properly.',
          Icons.person_outline_rounded,
        ),
        _LegalSection(
          'Trading and reputation data',
          'Listings, offers, sessions, completed trades, cancellations, no-shows, reports, reputation signals and marketplace behaviour may be stored to support safer trading and moderation.',
          Icons.handshake_outlined,
        ),
        _LegalSection(
          'Intel reports',
          'Drop sightings, blueprint locations, map/event data, confirmations, source notes and trust weighting may be stored so community intelligence can improve over time.',
          Icons.radar_rounded,
        ),
        _LegalSection(
          'Admin metrics and usage analytics',
          'We may calculate monthly active users, sessions per user, average session time, ad revenue, revenue per active user and lifetime value from account, telemetry and monetisation records.',
          Icons.query_stats_rounded,
        ),
        _LegalSection(
          'Referrals and rewards',
          'Referral codes, signups, subscription status, reward progress, commission rates and monthly operations may be tracked to support the referral system.',
          Icons.auto_graph_rounded,
        ),
        _LegalSection(
          'Ads, subscriptions and payment providers',
          'Ad events, entitlement status, subscription tier and provider-confirmed revenue events may be stored. Sensitive card or bank details should be handled by payment providers, not directly stored by UAG.',
          Icons.payments_outlined,
        ),
        _LegalSection(
          'Device preferences',
          'The app may remember your email locally if you choose that option. Biometric settings and keep-signed-in preferences are device-level choices used for login convenience.',
          Icons.fingerprint_rounded,
        ),
        _LegalSection(
          'Firebase and service providers',
          'Firebase Authentication, Firestore, Hosting, analytics, ad services, payment providers and future operational tools may process the data needed to run, secure and improve the hub.',
          Icons.cloud_done_outlined,
        ),
        _LegalSection(
          'Safety and abuse prevention',
          'Data may be used to detect spam, fake intel, suspicious referrals, marketplace manipulation, repeated no-shows, under-age use and behaviour that harms the community.',
          Icons.health_and_safety_outlined,
        ),
        _LegalSection(
          'Retention, deletion and corrections',
          'Operational records may be kept while your account, safety reviews, disputes, legal duties or product analytics require them. You may request correction or deletion where it is operationally and legally available.',
          Icons.manage_accounts_outlined,
        ),
        _LegalSection(
          'Who is responsible for your data',
          'MobCorp Ltd, company number 16857854, registered office 1711 High Street, Knowle, Solihull, West Midlands, B93 0LN, is the operator of UAG and is responsible for deciding how personal data used by the service is processed, subject to the roles of individual service providers.',
          Icons.business_outlined,
        ),
        _LegalSection(
          'Why we process data and lawful bases',
          'We process data to provide accounts and requested features, perform our contract with you, secure and administer the service, prevent fraud and abuse, comply with legal obligations, and pursue legitimate interests such as service security, analytics and product improvement where those interests are not overridden by your rights. Where the law requires consent for a specific activity, we will request it separately and you may withdraw it.',
          Icons.rule_folder_outlined,
        ),
        _LegalSection(
          'Sharing and processors',
          'Personal data may be shared with service providers that help us operate authentication, hosting, databases, analytics, communications, advertising, payments, security and support, and with professional advisers, regulators or authorities where legally required. Providers should receive only data reasonably necessary for their role and be subject to appropriate contractual safeguards.',
          Icons.share_outlined,
        ),
        _LegalSection(
          'International transfers',
          'Some technology providers may process data outside the United Kingdom. Where UK data-protection law requires safeguards for an international transfer, we will use an applicable adequacy regulation, approved contractual safeguard or another lawful transfer mechanism.',
          Icons.public_rounded,
        ),
        _LegalSection(
          'How long we keep data',
          'We keep personal data only for as long as reasonably necessary for the purpose collected, account operation, security, fraud prevention, disputes, legal obligations and establishment or defence of legal claims. Different records may require different periods. We will document and review retention periods before general public launch.',
          Icons.schedule_outlined,
        ),
        _LegalSection(
          'Your data-protection rights',
          'Depending on the circumstances, you may have rights of access, rectification, erasure, restriction, objection and data portability, and rights concerning certain automated decisions. Where processing relies on consent you may withdraw that consent without affecting earlier lawful processing. Some rights are subject to legal exemptions.',
          Icons.manage_accounts_outlined,
        ),
        _LegalSection(
          'Complaints',
          'Please raise privacy concerns with MobCorp Ltd first so they can be investigated. You also have the right to complain to the UK Information Commissioner’s Office about the handling of your personal data.',
          Icons.report_outlined,
        ),
        _LegalSection(
          'Automated signals and profiling',
          'UAG may use rules, scores or automated signals to help rank intel, detect abuse, assess trust or personalise features. These signals may inform moderation or product decisions. We will identify any processing that becomes solely automated decision-making with legal or similarly significant effects and provide the safeguards required by law.',
          Icons.psychology_outlined,
        ),
        _LegalSection(
          'Beta changes',
          'Because the product is still developing, data models, features, providers, reward systems and legal wording may change as the app improves and receives legal review.',
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
