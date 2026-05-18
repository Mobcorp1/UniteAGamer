import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/monetisation/models/uag_monetisation_models.dart';
import 'package:uag_traders_hub/features/monetisation/repositories/uag_monetisation_repository.dart';
import 'package:uag_traders_hub/features/monetisation/widgets/uag_impact_pots_panel.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class AdminMonetisationDashboard extends StatelessWidget {
  const AdminMonetisationDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = UagMonetisationRepository();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monetisation',
          style: AppTheme.tradingHeading(
            fontSize: 26,
            color: AppTheme.neonCyan,
          ),
        ),
        const SizedBox(height: AppTheme.spaceS),
        Text(
          'Private admin view for users, subscription mix, referral exposure, revenue, platform fees and impact pot allocation.',
          style: AppTheme.bodyTextStyle(
            fontSize: 14,
            color: AppTheme.tradingMutedText,
          ),
        ),
        const SizedBox(height: AppTheme.spaceL),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: repository.watchAdminUsers(),
          builder: (context, snapshot) {
            final docs =
                snapshot.data?.docs ??
                const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
            final stats = _AdminUserStats.fromDocs(docs);
            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 850;
                final cards = [
                  _StatCard(
                    label: 'Free Users',
                    value: '${stats.freeUsers}',
                    color: Colors.white70,
                  ),
                  _StatCard(
                    label: 'Essential Users',
                    value: '${stats.essentialUsers}',
                    color: AppTheme.neonCyan,
                  ),
                  _StatCard(
                    label: 'Premium Users',
                    value: '${stats.premiumUsers}',
                    color: AppTheme.neonPink,
                  ),
                  _StatCard(
                    label: 'Admin / Dev',
                    value: '${stats.adminUsers}',
                    color: AppTheme.warningAmber,
                  ),
                ];
                if (!isWide) {
                  return Column(
                    children: cards
                        .map(
                          (card) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppTheme.spaceM,
                            ),
                            child: card,
                          ),
                        )
                        .toList(),
                  );
                }
                return Row(
                  children: cards
                      .map(
                        (card) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              right: AppTheme.spaceM,
                            ),
                            child: card,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            );
          },
        ),
        const SizedBox(height: AppTheme.spaceL),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: repository.watchAdminRevenueEvents(limit: 80),
          builder: (context, snapshot) {
            final docs =
                snapshot.data?.docs ??
                const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
            final stats = _RevenueStats.fromDocs(docs);
            return Container(
              padding: AppTheme.sectionCardPadding,
              decoration: AppTheme.tradingCardDecoration(
                borderColor: AppTheme.neonCyan.withValues(alpha: 0.22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenue Snapshot',
                    style: AppTheme.tradingHeading(
                      fontSize: 22,
                      color: AppTheme.neonCyan,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  _moneyRow('Gross paid revenue logged', stats.grossPence),
                  _moneyRow('Estimated Stripe fees', stats.stripeFeesPence),
                  _moneyRow(
                    'Referral commission owed',
                    stats.referralCommissionPence,
                  ),
                  _moneyRow(
                    'Net platform profit logged',
                    stats.netPlatformProfitPence,
                  ),
                  _moneyRow('Charity impact allocated', stats.charityPence),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppTheme.spaceL),
        const UagImpactPotsPanel(showAdminDetail: true),
        const SizedBox(height: AppTheme.spaceL),
        _PaymentMethodCard(),
      ],
    );
  }

  Widget _moneyRow(String label, int pence) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTheme.bodyTextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ),
          Text(
            '£${(pence / 100).toStringAsFixed(2)}',
            style: AppTheme.bodyTextStyle(
              fontSize: 14,
              color: Colors.white,
              isBold: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppTheme.sectionCardPadding,
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.warningAmber.withValues(alpha: 0.22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Channels',
            style: AppTheme.tradingHeading(
              fontSize: 22,
              color: AppTheme.warningAmber,
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            'Active launch route: Stripe Checkout and Stripe Customer Portal. Card wallets are handled by Stripe. Bacs Direct Debit is enabled in the function payment method config. PayPal is not enabled in this pass to avoid splitting subscription authority, webhook logic and payout reporting across two providers.',
            style: AppTheme.bodyTextStyle(
              fontSize: 14,
              color: AppTheme.tradingMutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppTheme.sectionCardPadding,
      decoration: AppTheme.tradingCardDecoration(
        borderColor: color.withValues(alpha: 0.22),
        radius: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.bodyTextStyle(
              fontSize: 13,
              color: AppTheme.tradingMutedText,
              isBold: true,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTheme.tradingHeading(fontSize: 28, color: color),
          ),
        ],
      ),
    );
  }
}

class _AdminUserStats {
  const _AdminUserStats({
    required this.freeUsers,
    required this.essentialUsers,
    required this.premiumUsers,
    required this.adminUsers,
  });

  final int freeUsers;
  final int essentialUsers;
  final int premiumUsers;
  final int adminUsers;

  factory _AdminUserStats.fromDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    var free = 0;
    var essential = 0;
    var premium = 0;
    var admin = 0;
    for (final doc in docs) {
      final data = doc.data();
      if (data['isAdmin'] == true || data['isDev'] == true) admin++;
      final entitlement = UagEntitlement.fromUserDoc(doc.id, data);
      switch (entitlement.tier) {
        case UagPlanTier.free:
          free++;
          break;
        case UagPlanTier.essential:
          essential++;
          break;
        case UagPlanTier.premium:
          premium++;
          break;
      }
    }
    return _AdminUserStats(
      freeUsers: free,
      essentialUsers: essential,
      premiumUsers: premium,
      adminUsers: admin,
    );
  }
}

class _RevenueStats {
  const _RevenueStats({
    required this.grossPence,
    required this.stripeFeesPence,
    required this.referralCommissionPence,
    required this.netPlatformProfitPence,
    required this.charityPence,
  });

  final int grossPence;
  final int stripeFeesPence;
  final int referralCommissionPence;
  final int netPlatformProfitPence;
  final int charityPence;

  factory _RevenueStats.fromDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    var gross = 0;
    var stripe = 0;
    var referral = 0;
    var net = 0;
    var charity = 0;
    for (final doc in docs) {
      final data = doc.data();
      gross += (data['grossPence'] as num?)?.toInt() ?? 0;
      stripe += (data['stripeFeePence'] as num?)?.toInt() ?? 0;
      referral += (data['referralCommissionPence'] as num?)?.toInt() ?? 0;
      net += (data['netPlatformProfitPence'] as num?)?.toInt() ?? 0;
      charity += (data['charityPence'] as num?)?.toInt() ?? 0;
    }
    return _RevenueStats(
      grossPence: gross,
      stripeFeesPence: stripe,
      referralCommissionPence: referral,
      netPlatformProfitPence: net,
      charityPence: charity,
    );
  }
}
