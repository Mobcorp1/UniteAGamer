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
          'Operator and contract',
          'UAG ARC Raiders Hub is operated by MobCorp Ltd, company number 16857854, registered in England and Wales with registered office at 1711 High Street, Knowle, Solihull, West Midlands, B93 0LN. These Terms govern your use of the UAG service.',
          Icons.business_outlined,
        ),
        _LegalSection(
          'Unofficial fan companion',
          'UAG is an independent, unofficial ARC Raiders companion and is not affiliated with, endorsed by, sponsored by or supported by Embark Studios. ARC Raiders, Embark Studios and third-party game names, marks, artwork, images and game assets remain the property of their respective rights holders.',
          Icons.info_outline_rounded,
        ),
        _LegalSection(
          '18+ account requirement',
          'You must be 18 or older to create or use a UAG account. You must provide accurate account information, keep your login secure and tell us promptly if you believe your account has been compromised.',
          Icons.verified_user_outlined,
        ),
        _LegalSection(
          'Licence to use UAG',
          'Subject to these Terms, MobCorp Ltd grants you a limited, personal, revocable, non-exclusive, non-transferable licence to access and use UAG for its intended personal companion and community purposes. No ownership rights are transferred to you.',
          Icons.key_outlined,
        ),
        _LegalSection(
          'MobCorp and UAG intellectual property',
          'Except for third-party material, MobCorp Ltd retains all rights, title and interest in UAG and its original software, source and object code, architecture, databases, data models, algorithms, workflows, documentation, original graphics, interface designs, branding, logos and other proprietary material. Copyright, database rights, trade marks and other intellectual-property rights are reserved.',
          Icons.copyright_rounded,
        ),
        _LegalSection(
          'No copying, cloning or competing reproduction',
          'You must not copy, reproduce, republish, distribute, sell, sublicense, mirror or commercially exploit UAG or a substantial part of its proprietary content. You must not use access to UAG, its non-public information or proprietary material to clone, reproduce or create a substantially similar service in breach of these Terms or applicable law.',
          Icons.content_copy_rounded,
        ),
        _LegalSection(
          'Reverse engineering and source code',
          'You must not reverse engineer, decompile, disassemble, decode, translate or otherwise attempt to discover, reconstruct or derive UAG source code, underlying implementation or non-public technical information, except to the limited extent that applicable law expressly permits an activity and does not allow that right to be excluded by contract.',
          Icons.code_off_rounded,
        ),
        _LegalSection(
          'Scraping, automation and security',
          'You must not use bots, crawlers, scrapers or automated extraction to copy substantial UAG data, build a substitute dataset or place unreasonable load on the service without written permission. You must not bypass access controls, probe vulnerabilities, interfere with security, obtain unauthorised access or misuse APIs or technical interfaces.',
          Icons.security_rounded,
        ),
        _LegalSection(
          'Brand and proprietary notices',
          'No licence is granted to use MobCorp, UAG, Unite A Gamer or associated logos and branding except as expressly permitted. You must not remove or obscure copyright, trade mark, attribution or other proprietary notices.',
          Icons.branding_watermark_outlined,
        ),
        _LegalSection(
          'Third-party and open-source rights',
          'Third-party software, open-source components and third-party content remain subject to their applicable licences and rights. Nothing in these Terms transfers ARC Raiders or Embark intellectual property to MobCorp Ltd or to a UAG user.',
          Icons.extension_outlined,
        ),
        _LegalSection(
          'Your content',
          'You keep ownership of content you create and submit, subject to third-party rights. You confirm you have the right to submit it and grant MobCorp Ltd a non-exclusive, worldwide, royalty-free licence to host, store, reproduce, format, display and process that content only as reasonably necessary to operate, secure, moderate and improve UAG and provide the features you request. This licence ends when the content is deleted except for lawful backups, evidence, dispute records and material we must retain.',
          Icons.edit_note_rounded,
        ),
        _LegalSection(
          'Acceptable use and community conduct',
          'Do not use UAG for unlawful activity, harassment, threats, discrimination, impersonation, spam, scams, fake reports, referral manipulation, exploit abuse, credential collection or other conduct that harms users, rights holders, MobCorp Ltd or the service.',
          Icons.balance_rounded,
        ),
        _LegalSection(
          'Trading and no real-money item sales',
          'Trades are coordinated between players inside the game. UAG does not escrow in-game items or guarantee outcomes. UAG does not permit real-money sale, purchase or brokering of in-game items, accounts, credentials, access or carries through the service.',
          Icons.handshake_outlined,
        ),
        _LegalSection(
          'Moderation, suspension and termination',
          'We may proportionately restrict features, remove content, preserve relevant evidence or suspend accounts where reasonably necessary for security, abuse prevention, legal compliance, payment risk or serious/repeated breaches. Where appropriate we will provide information about the action and an available review route. You may stop using UAG at any time.',
          Icons.admin_panel_settings_outlined,
        ),
        _LegalSection(
          'Subscriptions, ads and payments',
          'Free access may include advertising and paid plans may alter advertising or unlock features. Prices, renewal terms and material payment conditions must be shown before purchase. Provider-confirmed payment events control paid entitlement. Nothing in these Terms removes statutory cancellation, refund or consumer rights that apply to you.',
          Icons.workspace_premium_outlined,
        ),
        _LegalSection(
          'Beta and service changes',
          'UAG may change during beta. We may add, alter or retire features for product, security, legal or operational reasons. Material changes affecting paid services or legal rights will be communicated as required. We do not promise uninterrupted availability, but this does not exclude rights that cannot lawfully be excluded.',
          Icons.science_outlined,
        ),
        _LegalSection(
          'Liability and statutory rights',
          'Nothing in these Terms excludes or limits liability where doing so would be unlawful, including liability for death or personal injury caused by negligence, fraud or fraudulent misrepresentation, or your mandatory consumer rights. Subject to those rights, UAG is a companion and coordination service and users remain responsible for their own gameplay, trades, account security and decisions.',
          Icons.gavel_rounded,
        ),
        _LegalSection(
          'Changes to these Terms',
          'We may update these Terms when the service, law or our business changes. Where a change is material, we will provide appropriate notice and, where required, ask you to accept the new version before continuing to use affected account features. Your acceptance record may include the policy version, date, account, platform and app version.',
          Icons.update_rounded,
        ),
        _LegalSection(
          'Governing law',
          'These Terms are governed by the laws of England and Wales. If you are a consumer, this does not deprive you of mandatory protections or rights to bring proceedings that apply in the part of the United Kingdom or other jurisdiction where you live.',
          Icons.account_balance_outlined,
        ),
        _LegalSection(
          'Legal review status',
          'This release strengthens the operational legal framework but should receive qualified UK legal review before general public launch, particularly subscriptions, consumer cancellation rights, international availability, privacy processing and third-party game intellectual property.',
          Icons.fact_check_outlined,
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
