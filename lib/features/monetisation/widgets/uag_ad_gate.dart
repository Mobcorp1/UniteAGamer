import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/monetisation/models/uag_ad_policy.dart';
import 'package:uag_traders_hub/features/monetisation/services/uag_entitlement_service.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class UagAdGate extends StatelessWidget {
  const UagAdGate({
    super.key,
    this.service,
    this.hideDuringActiveSession = false,
    this.placeholderLabel = 'Sponsored slot',
  });

  final UagEntitlementService? service;
  final bool hideDuringActiveSession;
  final String placeholderLabel;

  @override
  Widget build(BuildContext context) {
    final entitlementService = service ?? UagEntitlementService();
    return FutureBuilder<UagAdPolicy>(
      future: entitlementService.getMyAdPolicy(),
      builder: (context, snapshot) {
        final policy = snapshot.data;
        if (policy == null || !policy.showBannerAds) {
          return const SizedBox.shrink();
        }
        if (hideDuringActiveSession && !policy.allowMidSessionAds) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: AppTheme.spaceM),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceM,
            vertical: AppTheme.spaceS,
          ),
          decoration: AppTheme.tradingCardDecoration(
            borderColor: AppTheme.neonCyan.withValues(alpha: 0.18),
            radius: 14,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.campaign_outlined,
                size: 18,
                color: Colors.white54,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  placeholderLabel,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
              ),
              if (policy.showRewardedAds)
                Text(
                  'Boosts available',
                  style: AppTheme.bodyTextStyle(
                    fontSize: 12,
                    color: AppTheme.neonCyan,
                    isBold: true,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
