enum ArcAdTier { free, supporter, premium }

class ArcAdTierVisibility {
  static bool showPrimaryAds(ArcAdTier tier) {
    return tier == ArcAdTier.free;
  }

  static bool showReducedAds(ArcAdTier tier) {
    return tier == ArcAdTier.supporter;
  }

  static bool disableAds(ArcAdTier tier) {
    return tier == ArcAdTier.premium;
  }
}
