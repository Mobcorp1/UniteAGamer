import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/ads/uag_tactical_banner_ad.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/ads/uag_ad_service.dart';

enum ArcAdAccessTier { free, traderPro, elite }

/// Opt-in fixed outer geometry. Creative load/failure never changes this lane.
/// Eligibility remains owned by the existing commercial/route policy.
class ArcBlueprintBannerSlot extends StatelessWidget {
  const ArcBlueprintBannerSlot({super.key, this.eligibility, this.banner});

  final ValueListenable<bool>? eligibility;
  final Widget? banner;

  Widget _slot(bool eligible) => eligible
      ? SizedBox(
          key: const Key('blueprint-banner-slot'),
          height: 74,
          child: banner ?? const ArcAdBannerCard(),
        )
      : const SizedBox.shrink();

  @override
  Widget build(BuildContext context) {
    if (eligibility != null) {
      return ValueListenableBuilder<bool>(
        valueListenable: eligibility!,
        builder: (_, eligible, _) => _slot(eligible),
      );
    }
    return AnimatedBuilder(
      animation: UagAdService.instance,
      builder: (_, _) => _slot(UagAdService.instance.canShowBanner),
    );
  }
}

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
