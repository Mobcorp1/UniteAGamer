import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_beta_founder_pricing.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_premium_pass_entitlement.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_user_entitlement.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

class UagBetaFounderOfferPanel extends StatelessWidget {
  const UagBetaFounderOfferPanel({
    super.key,
    required this.entitlement,
    required this.checkoutBusy,
    required this.onCheckout,
  });

  final UagUserEntitlement entitlement;
  final bool checkoutBusy;
  final ValueChanged<String> onCheckout;

  @override
  Widget build(BuildContext context) {
    final recognition = entitlement.betaFounderStatus;
    final hasFounderOffer = recognition.hasFoundingRaiderRate;
    final hasBetaOffer = recognition.hasBetaPricing;

    return Column(
      children: [
        if (hasFounderOffer) ...[
          ArcTacticalPanel(
            icon: Icons.military_tech_rounded,
            title: 'FOUNDING RAIDER // LIFETIME RATE',
            subtitle:
                'A permanent thank-you for helping build UAG before public launch.',
            accent: ArcUiTokens.warning,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _priceLine(
                  UagBetaCommercialOffer.foundingRaiderAnnual.priceLabel,
                  '/ year',
                  ArcUiTokens.warning,
                ),
                const SizedBox(height: ArcUiTokens.gapS),
                Text(
                  'Full Premium. No ads. The £29.99 annual rate remains fixed while this Founder subscription stays continuously active. If it is cancelled and later restarted, the Founder price is forfeited; your Founding Raider status and legacy recognition remain.',
                  style: ArcUiTokens.bodySmall(
                    color: ArcUiTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: ArcUiTokens.gapM),
                FilledButton.icon(
                  onPressed:
                      checkoutBusy || entitlement.hasActiveCoreSubscription
                      ? null
                      : () => onCheckout(
                          UagBetaCommercialOffer
                              .foundingRaiderAnnual
                              .checkoutPlanId,
                        ),
                  icon: const Icon(Icons.workspace_premium_outlined),
                  label: Text(
                    entitlement.hasActiveCoreSubscription
                        ? 'ACTIVE SUBSCRIPTION'
                        : 'LOCK FOUNDING RAIDER RATE',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ArcUiTokens.gapM),
        ],
        if (hasBetaOffer) ...[
          ArcTacticalPanel(
            icon: Icons.science_outlined,
            title: 'CLOSED BETA REWARD PRICING',
            subtitle:
                'Reduced Premium access for Raiders helping test and shape the launch build.',
            accent: ArcUiTokens.primaryAccent,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final offers = <_OfferData>[
                  _OfferData(
                    title: 'Premium Monthly',
                    price: UagBetaCommercialOffer.premiumMonthly.priceLabel,
                    suffix: '/ month',
                    planId:
                        UagBetaCommercialOffer.premiumMonthly.checkoutPlanId,
                    detail: 'Full Premium at the Closed Beta rate.',
                    enabled: !entitlement.hasActiveCoreSubscription,
                    disabledLabel: 'ACTIVE SUBSCRIPTION',
                  ),
                  _OfferData(
                    title: 'Premium Annual',
                    price: UagBetaCommercialOffer.premiumAnnual.priceLabel,
                    suffix: '/ year',
                    planId: UagBetaCommercialOffer.premiumAnnual.checkoutPlanId,
                    detail: 'Best-value standard Beta Tester subscription.',
                    recommended: true,
                    enabled: !entitlement.hasActiveCoreSubscription,
                    disabledLabel: 'ACTIVE SUBSCRIPTION',
                  ),
                  _OfferData(
                    title: '24-Hour Premium',
                    price: UagBetaCommercialOffer.premiumDayPass.priceLabel,
                    suffix: '',
                    planId:
                        UagBetaCommercialOffer.premiumDayPass.checkoutPlanId,
                    detail: 'One introductory 24-hour pass per account.',
                    enabled: entitlement.premiumPass.canPurchase(
                      UagPremiumPassType.day24,
                    ),
                  ),
                  _OfferData(
                    title: '7-Day Premium',
                    price: UagBetaCommercialOffer.premiumWeekPass.priceLabel,
                    suffix: '',
                    planId:
                        UagBetaCommercialOffer.premiumWeekPass.checkoutPlanId,
                    detail: 'One introductory 7-day pass per account.',
                    enabled: entitlement.premiumPass.canPurchase(
                      UagPremiumPassType.week7,
                    ),
                  ),
                ];
                final cardWidth = constraints.maxWidth >= 920
                    ? (constraints.maxWidth - ArcUiTokens.gapM) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: ArcUiTokens.gapM,
                  runSpacing: ArcUiTokens.gapM,
                  children: offers
                      .map(
                        (offer) => SizedBox(
                          width: cardWidth,
                          child: _offerCard(offer),
                        ),
                      )
                      .toList(growable: false),
                );
              },
            ),
          ),
          const SizedBox(height: ArcUiTokens.gapM),
        ],
        if (!hasBetaOffer && !hasFounderOffer)
          ArcTacticalPanel(
            icon: Icons.timer_outlined,
            title: 'PREMIUM ACCESS PASSES',
            subtitle:
                'Short-term Premium for a raid day, a weekend or a week off without starting a subscription.',
            accent: ArcUiTokens.secondaryAccent,
            child: Wrap(
              spacing: ArcUiTokens.gapM,
              runSpacing: ArcUiTokens.gapM,
              children: [
                _publicPass(
                  label: '24-Hour Premium',
                  pricePence: UagPremiumPassType.day24.pricePence,
                  planId: 'premium_pass_day',
                  enabled: entitlement.premiumPass.canPurchase(
                    UagPremiumPassType.day24,
                  ),
                ),
                _publicPass(
                  label: '7-Day Premium',
                  pricePence: UagPremiumPassType.week7.pricePence,
                  planId: 'premium_pass_week',
                  enabled: entitlement.premiumPass.canPurchase(
                    UagPremiumPassType.week7,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _offerCard(_OfferData offer) {
    final enabled = offer.enabled && !checkoutBusy;
    final accent = offer.recommended
        ? ArcUiTokens.warning
        : ArcUiTokens.primaryAccent;
    return Container(
      padding: ArcUiTokens.panelPadding,
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.raised,
        accent: accent,
        borderOpacity: offer.recommended ? 0.38 : 0.22,
        glow: offer.recommended,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  offer.title,
                  style: ArcUiTokens.cardTitle(color: ArcUiTokens.textPrimary),
                ),
              ),
              if (offer.recommended)
                Container(
                  padding: ArcUiTokens.chipPadding,
                  decoration: ArcUiTokens.chipDecoration(color: accent),
                  child: Text(
                    'BEST VALUE',
                    style: ArcUiTokens.label(color: accent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: ArcUiTokens.gapS),
          _priceLine(offer.price, offer.suffix, accent),
          const SizedBox(height: ArcUiTokens.gapS),
          Text(offer.detail, style: ArcUiTokens.bodySmall()),
          const SizedBox(height: ArcUiTokens.gapM),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: enabled ? () => onCheckout(offer.planId) : null,
              child: Text(offer.enabled ? 'SELECT' : offer.disabledLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _publicPass({
    required String label,
    required int pricePence,
    required String planId,
    required bool enabled,
  }) {
    return SizedBox(
      width: 260,
      child: OutlinedButton(
        onPressed: enabled && !checkoutBusy ? () => onCheckout(planId) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Text(label),
              Text('£${(pricePence / 100).toStringAsFixed(2)}'),
              if (!enabled) const Text('INTRODUCTORY PASS USED'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priceLine(String price, String suffix, Color accent) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: price,
            style: ArcUiTokens.numeric(fontSize: 26, color: accent),
          ),
          TextSpan(
            text: suffix,
            style: ArcUiTokens.body(
              fontSize: 13,
              color: ArcUiTokens.textSecondary,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferData {
  const _OfferData({
    required this.title,
    required this.price,
    required this.suffix,
    required this.planId,
    required this.detail,
    this.recommended = false,
    this.enabled = true,
    this.disabledLabel = 'INTRODUCTORY PASS USED',
  });

  final String title;
  final String price;
  final String suffix;
  final String planId;
  final String detail;
  final bool recommended;
  final bool enabled;
  final String disabledLabel;
}
