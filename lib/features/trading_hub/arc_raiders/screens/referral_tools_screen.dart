import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/screens/uag_benefits_community_rewards_screen.dart';

/// Legacy route retained so every existing Referral Tools entry now opens the
/// complete Community Rewards / Creator experience instead of the old beta stub.
class ReferralToolsScreen extends StatelessWidget {
  const ReferralToolsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const UagBenefitsCommunityRewardsScreen();
}
