import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/legal/widgets/arc_legal_document_page.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

class UagSupportScreen extends StatelessWidget {
  const UagSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ArcLegalDocumentPage(
      title: 'Support & Contact',
      subtitle: 'Official MobCorp contact and policy routes.',
      accent: ArcUiTokens.primaryAccent,
      sections: [
        ArcLegalSection(
          'Operator',
          'UAG ARC Raiders Hub is operated by MobCorp Limited, company number 16857854, registered in England and Wales. Service address: 107 Langley Hall Road, Solihull, B92 7HD, United Kingdom.',
          Icons.business_outlined,
        ),
        ArcLegalSection(
          'Support email',
          'For account, billing, privacy, moderation, copyright, accessibility or general support enquiries, email contact@mobcorp.co.uk.',
          Icons.email_outlined,
        ),
        ArcLegalSection(
          'Legal contact',
          'MobCorp Limited maintains an internal legal contact record. Public legal and compliance enquiries should use contact@mobcorp.co.uk so they can be tracked and routed appropriately.',
          Icons.badge_outlined,
        ),
        ArcLegalSection(
          'Account deletion',
          'To delete your UAG account and associated personal data in the app, open Privacy & Data > Delete My Account. If the in-app process cannot be completed, email contact@mobcorp.co.uk with the subject Account deletion or use https://unite-a-gamer.web.app/support#account-deletion. We verify account ownership before destructive deletion. Cancelling a Google Play or Stripe subscription is a separate step and should be completed through the relevant billing provider.',
          Icons.delete_forever_outlined,
        ),
        ArcLegalSection(
          'Public policies',
          'Privacy: https://unite-a-gamer.web.app/privacy\nTerms: https://unite-a-gamer.web.app/terms\nSubscriptions and refunds: https://unite-a-gamer.web.app/subscriptions-refunds\nSupport: https://unite-a-gamer.web.app/support',
          Icons.link_rounded,
        ),
        ArcLegalSection(
          'Response information',
          'Include the email address on your UAG account, a short description of the issue and any relevant order, listing or report reference. Do not send passwords, full card numbers or other authentication secrets.',
          Icons.security_outlined,
        ),
      ],
    );
  }
}
