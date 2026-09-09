import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/ads/uag_tactical_banner_ad.dart';

enum ArcAdAccessTier { free, traderPro, elite }

/// Legacy ARC banner compatibility wrapper.
///
/// All actual ad eligibility is owned by UagAdService/UagUserEntitlement.
/// The legacy ARC tier arguments are retained only so existing screens do not
/// need to change in the convergence pass.
class ArcAdBannerCard extends StatelessWidget {
  const ArcAdBannerCard({
    super.key,
    this.tier = ArcAdAccessTier.free,
    this.showForTraderPro = false,
  });

  final ArcAdAccessTier tier;
  final bool showForTraderPro;

  static bool shouldShowForTier({
    required ArcAdAccessTier tier,
    bool showForTraderPro = false,
  }) {
    switch (tier) {
      case ArcAdAccessTier.free:
        return true;
      case ArcAdAccessTier.traderPro:
        return showForTraderPro;
      case ArcAdAccessTier.elite:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return UagTacticalBannerAd(
      enabled: shouldShowForTier(
        tier: tier,
        showForTraderPro: showForTraderPro,
      ),
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 8),
    );
  }
}
