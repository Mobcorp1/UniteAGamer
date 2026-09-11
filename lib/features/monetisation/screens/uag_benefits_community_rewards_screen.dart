import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/build/app_bar.dart';
import 'package:uag_arc_raiders_hub/build/app_drawer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_layout_system.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

import '../screens/uag_creator_programme_screen.dart';
import '../widgets/uag_community_growth_live_panel.dart';
import '../widgets/uag_refer_a_raider_panel.dart';
import '../widgets/uag_referral_progress_panel.dart';
import '../widgets/uag_referral_reward_locker_panel.dart';

class UagBenefitsCommunityRewardsScreen extends StatelessWidget {
  const UagBenefitsCommunityRewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const UagAppBar(
        title: 'Community Command',
        subtitle: 'Refer • earn • bank rewards • grow UAG',
      ),
      drawer: const AppDrawer(),
      body: ArcTacticalPageList(
        width: ArcPageWidth.wide,
        maxWidth: 1080,
        padding: ArcLayoutTokens.pagePadding(context),
        children: [
          const ArcTacticalPanel(
            icon: Icons.groups_2_outlined,
            title: 'COMMUNITY COMMAND',
            subtitle:
                'Your referral identity, recurring earnings and community rewards in one place.',
            accent: ArcUiTokens.secondaryAccent,
            child: Wrap(
              spacing: ArcUiTokens.gapS,
              runSpacing: ArcUiTokens.gapS,
              children: [
                _CommandTag('THEY GET 10% OFF FIRST PURCHASE', ArcUiTokens.primaryAccent),
                _CommandTag('YOU EARN 5% → 15%', ArcUiTokens.secondaryAccent),
                _CommandTag('PREMIUM BOOST +2.5PP', ArcUiTokens.secondaryAccent),
                _CommandTag('30-DAY VALIDATION', ArcUiTokens.primaryAccent),
              ],
            ),
          ),
          const SizedBox(height: ArcUiTokens.gapM),
          const UagReferARaiderPanel(),
          const SizedBox(height: ArcUiTokens.gapM),
          const UagReferralProgressPanel(),
          const SizedBox(height: ArcUiTokens.gapM),
          const UagReferralRewardLockerPanel(),
          const SizedBox(height: ArcUiTokens.gapM),
          const UagCommunityGrowthLivePanel(),
          const SizedBox(height: ArcUiTokens.gapM),
          ArcTacticalPanel(
            icon: Icons.campaign_outlined,
            title: 'CREATOR PROGRAMME',
            subtitle:
                'Creators get a dedicated commercial dashboard, campaign tools and a 7.5% → 20% base ladder with Community Growth uplift.',
            accent: ArcUiTokens.secondaryAccent,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                style: ArcUiTokens.textButtonStyle(
                  accent: ArcUiTokens.secondaryAccent,
                  primary: true,
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const UagCreatorProgrammeScreen(),
                  ),
                ),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('OPEN CREATOR PROGRAMME'),
              ),
            ),
          ),
          const SizedBox(height: ArcUiTokens.gapM),
          const ArcTacticalPanel(
            icon: Icons.shield_outlined,
            title: 'HOW EARNINGS WORK',
            subtitle: 'Simple enough to explain in one screen.',
            accent: ArcUiTokens.primaryAccent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Rule('Commission is based on eligible net subscription revenue actually received.'),
                _Rule('Refunds, chargebacks, self-referrals and fraudulent referrals do not qualify.'),
                _Rule('Commission validates for 30 days before it becomes payable.'),
                _Rule('The 10% customer referral discount applies to the first paid purchase only unless a specific approved campaign says otherwise.'),
                _Rule('Discounts do not stack with protected Beta or Founding Raider pricing.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandTag extends StatelessWidget {
  const _CommandTag(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ArcUiTokens.chipPadding,
      decoration: ArcUiTokens.chipDecoration(color: color),
      child: Text(label, style: ArcUiTokens.label(color: color)),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ArcUiTokens.gapS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 17,
            color: ArcUiTokens.primaryAccent,
          ),
          const SizedBox(width: ArcUiTokens.gapS),
          Expanded(child: Text(text, style: ArcUiTokens.bodySmall())),
        ],
      ),
    );
  }
}
