import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/legal/widgets/arc_legal_document_page.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

class SubscriptionRefundsScreen extends StatelessWidget {
  const SubscriptionRefundsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ArcLegalDocumentPage(
      title: 'Subscriptions & Refunds',
      subtitle:
          'Billing authority, renewals, cancellation and refund handling.',
      accent: ArcUiTokens.secondaryAccent,
      sections: [
        ArcLegalSection(
          'Android purchases',
          'Paid digital access purchased inside the Google Play-distributed Android app is intended to use Google Play Billing. Google Play controls checkout, payment collection, subscription management and the provider-side purchase record. UAG entitlement is granted only after provider-confirmed purchase state is available.',
          Icons.android_rounded,
        ),
        ArcLegalSection(
          'Web purchases',
          'Paid digital access purchased on the UAG web service may use Stripe Checkout and the Stripe Customer Portal. Stripe handles payment-card or bank-payment data supported by the checkout flow; UAG should store only the provider references and entitlement information needed to operate the account.',
          Icons.language_rounded,
        ),
        ArcLegalSection(
          'Recurring subscriptions',
          'Recurring plans continue until cancelled. The checkout surface must show the price, billing period and material renewal terms before purchase. Cancelling stops future renewal but does not automatically create a refund for a period already paid for unless the payment provider, UAG policy or applicable law provides otherwise.',
          Icons.autorenew_rounded,
        ),
        ArcLegalSection(
          'How to cancel',
          'Google Play subscriptions should be managed through Google Play subscription controls. Stripe web subscriptions should be managed through the Stripe Customer Portal when enabled. If you cannot access the correct cancellation route, contact contact@mobcorp.co.uk before the next renewal where possible.',
          Icons.cancel_outlined,
        ),
        ArcLegalSection(
          'Refunds',
          'Refund eligibility depends on the payment route, purchase circumstances, provider rules and applicable consumer law. Google Play purchases may be requested through Google Play and may also be reviewed by MobCorp Limited where the developer is able to assist. Stripe web refund requests should be sent to contact@mobcorp.co.uk. Nothing in this policy removes statutory rights that cannot lawfully be excluded.',
          Icons.payments_outlined,
        ),
        ArcLegalSection(
          'Entitlement after refund or chargeback',
          'If a payment is refunded, revoked, charged back or otherwise reversed, the related paid entitlement, reward or commission may be removed or recalculated when the provider-confirmed event is processed.',
          Icons.receipt_long_outlined,
        ),
        ArcLegalSection(
          'Beta pricing and plan changes',
          'UAG may test beta, founder, pass or promotional pricing. The price accepted at checkout applies to that transaction or subscription subject to its stated terms. Material changes to an existing recurring paid service will be communicated as required before they take effect.',
          Icons.science_outlined,
        ),
        ArcLegalSection(
          'Support',
          'Billing and subscription support: contact@mobcorp.co.uk. Public policy copy: https://unite-a-gamer.web.app/subscriptions-refunds.',
          Icons.contact_support_outlined,
        ),
      ],
    );
  }
}
