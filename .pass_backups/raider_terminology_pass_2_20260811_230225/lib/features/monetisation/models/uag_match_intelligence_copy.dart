import 'uag_subscription_tier.dart';

class UagMatchIntelligenceTierCopy {
  const UagMatchIntelligenceTierCopy({
    required this.tier,
    required this.level,
    required this.label,
    required this.description,
  });

  final UagSubscriptionTier tier;
  final String level;
  final String label;
  final String description;
}

class UagMatchIntelligenceComparisonRow {
  const UagMatchIntelligenceComparisonRow({
    required this.feature,
    required this.free,
    required this.essential,
    required this.premium,
  });

  final String feature;
  final String free;
  final String essential;
  final String premium;
}

class UagMatchIntelligenceCopy {
  const UagMatchIntelligenceCopy._();

  static const freeDescription =
      'Basic compatibility matching using core profile, platform and availability signals.';
  static const essentialDescription =
      'Deeper compatibility analysis using communication style, schedule, squad intent and play preferences.';
  static const premiumDescription =
      'Full UAG Decision Engine analysis using dozens of private compatibility signals to surface the strongest squad recommendations.';

  static const free = UagMatchIntelligenceTierCopy(
    tier: UagSubscriptionTier.free,
    level: 'Basic',
    label: 'Basic Match Intelligence',
    description: freeDescription,
  );

  static const essential = UagMatchIntelligenceTierCopy(
    tier: UagSubscriptionTier.essential,
    level: 'Enhanced',
    label: 'Enhanced Match Intelligence',
    description: essentialDescription,
  );

  static const premium = UagMatchIntelligenceTierCopy(
    tier: UagSubscriptionTier.premium,
    level: 'Advanced',
    label: 'Advanced Match Intelligence',
    description: premiumDescription,
  );

  static const all = <UagMatchIntelligenceTierCopy>[free, essential, premium];

  static const comparisonRows = <UagMatchIntelligenceComparisonRow>[
    UagMatchIntelligenceComparisonRow(
      feature: 'Match Intelligence',
      free: 'Basic',
      essential: 'Enhanced',
      premium: 'Advanced',
    ),
    UagMatchIntelligenceComparisonRow(
      feature: 'Overall Match %',
      free: 'Included',
      essential: 'Included',
      premium: 'Included',
    ),
    UagMatchIntelligenceComparisonRow(
      feature: 'Compatibility Ranking',
      free: 'Core ranking',
      essential: 'Enhanced ranking',
      premium: 'Advanced ranking',
    ),
    UagMatchIntelligenceComparisonRow(
      feature: 'Availability Matching',
      free: 'Broad',
      essential: 'Detailed',
      premium: 'Dynamic',
    ),
    UagMatchIntelligenceComparisonRow(
      feature: 'Communication Compatibility',
      free: 'Core',
      essential: 'Included',
      premium: 'Weighted',
    ),
    UagMatchIntelligenceComparisonRow(
      feature: 'Squad Intent Matching',
      free: 'Core',
      essential: 'Included',
      premium: 'Weighted',
    ),
    UagMatchIntelligenceComparisonRow(
      feature: 'Archetype Fit',
      free: 'Core',
      essential: 'Included',
      premium: 'Weighted',
    ),
    UagMatchIntelligenceComparisonRow(
      feature: 'Reputation Weighting',
      free: 'Safety checks',
      essential: 'Stronger',
      premium: 'Advanced',
    ),
    UagMatchIntelligenceComparisonRow(
      feature: 'Favourite Rider Prioritisation',
      free: 'Not included',
      essential: 'Included',
      premium: 'Advanced',
    ),
    UagMatchIntelligenceComparisonRow(
      feature: 'Dynamic Re-ranking',
      free: 'Profile changes',
      essential: 'Profile and availability',
      premium: 'Full live signals',
    ),
    UagMatchIntelligenceComparisonRow(
      feature: 'Advanced Progression Compatibility',
      free: 'Not included',
      essential: 'Not included',
      premium: 'Included',
    ),
    UagMatchIntelligenceComparisonRow(
      feature: 'Advanced Decision Engine',
      free: 'Not included',
      essential: 'Not included',
      premium: 'Included',
    ),
  ];

  static UagMatchIntelligenceTierCopy forTier(UagSubscriptionTier tier) {
    switch (tier) {
      case UagSubscriptionTier.free:
        return free;
      case UagSubscriptionTier.essential:
        return essential;
      case UagSubscriptionTier.premium:
        return premium;
    }
  }
}
