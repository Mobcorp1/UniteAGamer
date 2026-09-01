import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/legal/widgets/arc_legal_document_page.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ArcLegalDocumentPage(
      title: 'Privacy Policy',
      subtitle: 'How account, trading, intel and referral data is handled.',
      accent: ArcUiTokens.secondaryAccent,
      sections: [
        ArcLegalSection(
          'Account data',
          'We may store your email, display name, Raider name, region, platform, timezone, account tier, referral code, affiliate status, age confirmation and onboarding choices so the hub works properly.',
          Icons.person_outline_rounded,
        ),
        ArcLegalSection(
          'Trading and reputation data',
          'Listings, offers, sessions, completed trades, cancellations, no-shows, reports, reputation signals and marketplace behaviour may be stored to support safer trading and moderation.',
          Icons.handshake_outlined,
        ),
        ArcLegalSection(
          'Intel reports',
          'Drop sightings, blueprint locations, map/event data, confirmations, source notes and trust weighting may be stored so community intelligence can improve over time.',
          Icons.radar_rounded,
        ),
        ArcLegalSection(
          'Admin metrics and usage analytics',
          'We may calculate monthly active users, sessions per user, average session time, ad revenue, revenue per active user and lifetime value from account, telemetry and monetisation records.',
          Icons.query_stats_rounded,
        ),
        ArcLegalSection(
          'Referrals and rewards',
          'Referral codes, signups, subscription status, reward progress, commission rates and monthly operations may be tracked to support the referral system.',
          Icons.auto_graph_rounded,
        ),
        ArcLegalSection(
          'Ads, subscriptions and payment providers',
          'Ad events, entitlement status, subscription tier and provider-confirmed revenue events may be stored. Sensitive card or bank details should be handled by payment providers, not directly stored by UAG.',
          Icons.payments_outlined,
        ),
        ArcLegalSection(
          'Device preferences',
          'The app may remember your email locally if you choose that option. Biometric settings and keep-signed-in preferences are device-level choices used for login convenience.',
          Icons.fingerprint_rounded,
        ),
        ArcLegalSection(
          'Firebase and service providers',
          'Firebase Authentication, Firestore, Hosting, analytics, ad services, payment providers and future operational tools may process the data needed to run, secure and improve the hub.',
          Icons.cloud_done_outlined,
        ),
        ArcLegalSection(
          'Safety and abuse prevention',
          'Data may be used to detect spam, fake intel, suspicious referrals, marketplace manipulation, repeated no-shows, under-age use and behaviour that harms the community.',
          Icons.health_and_safety_outlined,
        ),
        ArcLegalSection(
          'Retention, deletion and corrections',
          'Operational records may be kept while your account, safety reviews, disputes, legal duties or product analytics require them. You may request correction or deletion where it is operationally and legally available.',
          Icons.manage_accounts_outlined,
        ),
        ArcLegalSection(
          'Who is responsible for your data',
          'MobCorp Ltd, company number 16857854, registered office 1711 High Street, Knowle, Solihull, West Midlands, B93 0LN, is the operator of UAG and is responsible for deciding how personal data used by the service is processed, subject to the roles of individual service providers.',
          Icons.business_outlined,
        ),
        ArcLegalSection(
          'Why we process data and lawful bases',
          'We process data to provide accounts and requested features, perform our contract with you, secure and administer the service, prevent fraud and abuse, comply with legal obligations, and pursue legitimate interests such as service security, analytics and product improvement where those interests are not overridden by your rights. Where the law requires consent for a specific activity, we will request it separately and you may withdraw it.',
          Icons.rule_folder_outlined,
        ),
        ArcLegalSection(
          'Sharing and processors',
          'Personal data may be shared with service providers that help us operate authentication, hosting, databases, analytics, communications, advertising, payments, security and support, and with professional advisers, regulators or authorities where legally required. Providers should receive only data reasonably necessary for their role and be subject to appropriate contractual safeguards.',
          Icons.share_outlined,
        ),
        ArcLegalSection(
          'International transfers',
          'Some technology providers may process data outside the United Kingdom. Where UK data-protection law requires safeguards for an international transfer, we will use an applicable adequacy regulation, approved contractual safeguard or another lawful transfer mechanism.',
          Icons.public_rounded,
        ),
        ArcLegalSection(
          'How long we keep data',
          'We keep personal data only for as long as reasonably necessary for the purpose collected, account operation, security, fraud prevention, disputes, legal obligations and establishment or defence of legal claims. Different records may require different periods. We will document and review retention periods before general public launch.',
          Icons.schedule_outlined,
        ),
        ArcLegalSection(
          'Your data-protection rights',
          'Depending on the circumstances, you may have rights of access, rectification, erasure, restriction, objection and data portability, and rights concerning certain automated decisions. Where processing relies on consent you may withdraw that consent without affecting earlier lawful processing. Some rights are subject to legal exemptions.',
          Icons.manage_accounts_outlined,
        ),
        ArcLegalSection(
          'Complaints',
          'Please raise privacy concerns with MobCorp Ltd first so they can be investigated. You also have the right to complain to the UK Information Commissioner’s Office about the handling of your personal data.',
          Icons.report_outlined,
        ),
        ArcLegalSection(
          'Automated signals and profiling',
          'UAG may use rules, scores or automated signals to help rank intel, detect abuse, assess trust or personalise features. These signals may inform moderation or product decisions. We will identify any processing that becomes solely automated decision-making with legal or similarly significant effects and provide the safeguards required by law.',
          Icons.psychology_outlined,
        ),
        ArcLegalSection(
          'Beta changes',
          'Because the product is still developing, data models, features, providers, reward systems and legal wording may change as the app improves and receives legal review.',
          Icons.science_outlined,
        ),
      ],
    );
  }
}
