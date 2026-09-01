import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/legal/widgets/arc_legal_document_page.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ArcLegalDocumentPage(
      title: 'Terms of Use',
      subtitle: 'Fair trading, trusted intel and community standards.',
      accent: ArcUiTokens.primaryAccent,
      sections: [
        ArcLegalSection(
          'Operator and contract',
          'UAG ARC Raiders Hub is operated by MobCorp Ltd, company number 16857854, registered in England and Wales with registered office at 1711 High Street, Knowle, Solihull, West Midlands, B93 0LN. These Terms govern your use of the UAG service.',
          Icons.business_outlined,
        ),
        ArcLegalSection(
          'Unofficial fan companion',
          'UAG is an independent, unofficial ARC Raiders companion and is not affiliated with, endorsed by, sponsored by or supported by Embark Studios. ARC Raiders, Embark Studios and third-party game names, marks, artwork, images and game assets remain the property of their respective rights holders.',
          Icons.info_outline_rounded,
        ),
        ArcLegalSection(
          '18+ account requirement',
          'You must be 18 or older to create or use a UAG account. You must provide accurate account information, keep your login secure and tell us promptly if you believe your account has been compromised.',
          Icons.verified_user_outlined,
        ),
        ArcLegalSection(
          'Licence to use UAG',
          'Subject to these Terms, MobCorp Ltd grants you a limited, personal, revocable, non-exclusive, non-transferable licence to access and use UAG for its intended personal companion and community purposes. No ownership rights are transferred to you.',
          Icons.key_outlined,
        ),
        ArcLegalSection(
          'MobCorp and UAG intellectual property',
          'Except for third-party material, MobCorp Ltd retains all rights, title and interest in UAG and its original software, source and object code, architecture, databases, data models, algorithms, workflows, documentation, original graphics, interface designs, branding, logos and other proprietary material. Copyright, database rights, trade marks and other intellectual-property rights are reserved.',
          Icons.copyright_rounded,
        ),
        ArcLegalSection(
          'No copying, cloning or competing reproduction',
          'You must not copy, reproduce, republish, distribute, sell, sublicense, mirror or commercially exploit UAG or a substantial part of its proprietary content. You must not use access to UAG, its non-public information or proprietary material to clone, reproduce or create a substantially similar service in breach of these Terms or applicable law.',
          Icons.content_copy_rounded,
        ),
        ArcLegalSection(
          'Reverse engineering and source code',
          'You must not reverse engineer, decompile, disassemble, decode, translate or otherwise attempt to discover, reconstruct or derive UAG source code, underlying implementation or non-public technical information, except to the limited extent that applicable law expressly permits an activity and does not allow that right to be excluded by contract.',
          Icons.code_off_rounded,
        ),
        ArcLegalSection(
          'Scraping, automation and security',
          'You must not use bots, crawlers, scrapers or automated extraction to copy substantial UAG data, build a substitute dataset or place unreasonable load on the service without written permission. You must not bypass access controls, probe vulnerabilities, interfere with security, obtain unauthorised access or misuse APIs or technical interfaces.',
          Icons.security_rounded,
        ),
        ArcLegalSection(
          'Brand and proprietary notices',
          'No licence is granted to use MobCorp, UAG, Unite A Gamer or associated logos and branding except as expressly permitted. You must not remove or obscure copyright, trade mark, attribution or other proprietary notices.',
          Icons.branding_watermark_outlined,
        ),
        ArcLegalSection(
          'Third-party and open-source rights',
          'Third-party software, open-source components and third-party content remain subject to their applicable licences and rights. Nothing in these Terms transfers ARC Raiders or Embark intellectual property to MobCorp Ltd or to a UAG user.',
          Icons.extension_outlined,
        ),
        ArcLegalSection(
          'Your content',
          'You keep ownership of content you create and submit, subject to third-party rights. You confirm you have the right to submit it and grant MobCorp Ltd a non-exclusive, worldwide, royalty-free licence to host, store, reproduce, format, display and process that content only as reasonably necessary to operate, secure, moderate and improve UAG and provide the features you request. This licence ends when the content is deleted except for lawful backups, evidence, dispute records and material we must retain.',
          Icons.edit_note_rounded,
        ),
        ArcLegalSection(
          'Acceptable use and community conduct',
          'Do not use UAG for unlawful activity, harassment, threats, discrimination, impersonation, spam, scams, fake reports, referral manipulation, exploit abuse, credential collection or other conduct that harms users, rights holders, MobCorp Ltd or the service.',
          Icons.balance_rounded,
        ),
        ArcLegalSection(
          'Trading and no real-money item sales',
          'Trades are coordinated between players inside the game. UAG does not escrow in-game items or guarantee outcomes. UAG does not permit real-money sale, purchase or brokering of in-game items, accounts, credentials, access or carries through the service.',
          Icons.handshake_outlined,
        ),
        ArcLegalSection(
          'Moderation, suspension and termination',
          'We may proportionately restrict features, remove content, preserve relevant evidence or suspend accounts where reasonably necessary for security, abuse prevention, legal compliance, payment risk or serious/repeated breaches. Where appropriate we will provide information about the action and an available review route. You may stop using UAG at any time.',
          Icons.admin_panel_settings_outlined,
        ),
        ArcLegalSection(
          'Subscriptions, ads and payments',
          'Free access may include advertising and paid plans may alter advertising or unlock features. Prices, renewal terms and material payment conditions must be shown before purchase. Provider-confirmed payment events control paid entitlement. Nothing in these Terms removes statutory cancellation, refund or consumer rights that apply to you.',
          Icons.workspace_premium_outlined,
        ),
        ArcLegalSection(
          'Beta and service changes',
          'UAG may change during beta. We may add, alter or retire features for product, security, legal or operational reasons. Material changes affecting paid services or legal rights will be communicated as required. We do not promise uninterrupted availability, but this does not exclude rights that cannot lawfully be excluded.',
          Icons.science_outlined,
        ),
        ArcLegalSection(
          'Liability and statutory rights',
          'Nothing in these Terms excludes or limits liability where doing so would be unlawful, including liability for death or personal injury caused by negligence, fraud or fraudulent misrepresentation, or your mandatory consumer rights. Subject to those rights, UAG is a companion and coordination service and users remain responsible for their own gameplay, trades, account security and decisions.',
          Icons.gavel_rounded,
        ),
        ArcLegalSection(
          'Changes to these Terms',
          'We may update these Terms when the service, law or our business changes. Where a change is material, we will provide appropriate notice and, where required, ask you to accept the new version before continuing to use affected account features. Your acceptance record may include the policy version, date, account, platform and app version.',
          Icons.update_rounded,
        ),
        ArcLegalSection(
          'Governing law',
          'These Terms are governed by the laws of England and Wales. If you are a consumer, this does not deprive you of mandatory protections or rights to bring proceedings that apply in the part of the United Kingdom or other jurisdiction where you live.',
          Icons.account_balance_outlined,
        ),
        ArcLegalSection(
          'Legal review status',
          'This release strengthens the operational legal framework but should receive qualified UK legal review before general public launch, particularly subscriptions, consumer cancellation rights, international availability, privacy processing and third-party game intellectual property.',
          Icons.fact_check_outlined,
        ),
      ],
    );
  }
}
