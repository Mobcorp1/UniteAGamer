import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/build/app_bar.dart';
import 'package:uag_arc_raiders_hub/build/app_drawer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/features/trust/screens/arc_raider_contracts_screen.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_layout_system.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

import 'uag_creator_programme_screen.dart';
import '../widgets/uag_community_growth_live_panel.dart';
import '../widgets/uag_programme_section.dart';
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
        title: 'Community Rewards',
        subtitle: 'Grow UAG • support your community • earn recognition',
      ),
      drawer: const AppDrawer(),
      body: ArcTacticalPageList(
        width: ArcPageWidth.wide,
        maxWidth: 1080,
        padding: ArcLayoutTokens.pagePadding(context),
        children: [
          const ArcTacticalPanel(
            icon: Icons.groups_2_outlined,
            title: 'YOUR COMMUNITY. YOUR IMPACT.',
            subtitle:
                'Choose a programme to see your progress, rewards and next steps.',
            child: Text(
              'Bring Raiders together, build your creator community or take on a contract. Each programme has its own rules and rewards.',
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 760 ? 3 : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * ArcUiTokens.gapM) /
                  columns;
              return Wrap(
                spacing: ArcUiTokens.gapM,
                runSpacing: ArcUiTokens.gapM,
                children: [
                  SizedBox(
                    width: width,
                    child: _ProgrammeCard(
                      title: 'COMMUNITY REWARDS',
                      description:
                          'Your referral link, qualifying growth and banked rewards.',
                      icon: Icons.card_giftcard_outlined,
                      action: 'OPEN YOUR REWARDS',
                      onOpen: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const _CommunityRewardsDetail(),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _ProgrammeCard(
                      title: 'UAG CREATOR PROGRAM',
                      description:
                          'Creator Points, community growth, campaigns and earnings.',
                      icon: Icons.campaign_outlined,
                      action: 'OPEN CREATOR PROGRAM',
                      onOpen: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const UagCreatorProgrammeScreen(),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _ProgrammeCard(
                      title: 'HUNTER RATS',
                      description:
                          'Explore Raider Contracts and the planned country competition.',
                      icon: Icons.radar_rounded,
                      action: 'EXPLORE HUNTER RATS',
                      onOpen: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const _HunterProgrammeDetail(),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProgrammeCard extends StatelessWidget {
  const _ProgrammeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.action,
    required this.onOpen,
  });
  final String title;
  final String description;
  final IconData icon;
  final String action;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => ArcTacticalPanel(
    icon: icon,
    title: title,
    subtitle: description,
    accent: ArcUiTokens.secondaryAccent,
    child: FilledButton.icon(
      style: ArcUiTokens.textButtonStyle(
        accent: ArcUiTokens.secondaryAccent,
        primary: true,
      ),
      onPressed: onOpen,
      icon: const Icon(Icons.arrow_forward_rounded),
      label: Text(action),
    ),
  );
}

class _CommunityRewardsDetail extends StatelessWidget {
  const _CommunityRewardsDetail();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    appBar: const UagAppBar(
      title: 'Your Community Rewards',
      subtitle: 'Refer • progress • claim',
    ),
    body: ArcTacticalPageList(
      width: ArcPageWidth.wide,
      maxWidth: 1080,
      padding: ArcLayoutTokens.pagePadding(context),
      children: const [
        UagReferARaiderPanel(),
        UagProgrammeSection(
          title: 'YOUR PROGRESS',
          subtitle: 'Qualifying referrals and your current reward milestones.',
          icon: Icons.trending_up_rounded,
          initiallyExpanded: true,
          child: UagReferralProgressPanel(),
        ),
        UagProgrammeSection(
          title: 'REWARD LOCKER',
          subtitle: 'Review and activate your banked rewards.',
          icon: Icons.card_giftcard_outlined,
          child: UagReferralRewardLockerPanel(),
        ),
        UagProgrammeSection(
          title: 'COMMUNITY GROWTH',
          subtitle: 'See the community activity that qualifies for growth.',
          icon: Icons.groups_outlined,
          child: UagCommunityGrowthLivePanel(),
        ),
        UagProgrammeSection(
          title: 'HOW EARNINGS WORK',
          subtitle: 'Eligibility, validation and discount rules.',
          icon: Icons.shield_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Rule(
                'Commission is based on eligible net subscription revenue actually received.',
              ),
              _Rule(
                'Refunds, chargebacks, self-referrals and fraudulent referrals do not qualify.',
              ),
              _Rule(
                'Commission validates for 30 days before it becomes payable.',
              ),
              _Rule(
                'The 10% customer referral discount applies to the first paid purchase only unless a specific approved campaign says otherwise.',
              ),
              _Rule(
                'Discounts do not stack with protected Beta or Founding Raider pricing.',
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HunterProgrammeDetail extends StatelessWidget {
  const _HunterProgrammeDetail();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    appBar: const UagAppBar(
      title: 'Hunter Rats',
      subtitle: 'Contracts • evidence • recognition',
    ),
    body: ArcTacticalPageList(
      width: ArcPageWidth.wide,
      maxWidth: 1080,
      padding: ArcLayoutTokens.pagePadding(context),
      children: [
        ArcTacticalPanel(
          icon: Icons.radar_rounded,
          title: 'RAIDER CONTRACTS',
          subtitle:
              'Browse available contracts, manage accepted work and submit completion evidence.',
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              style: ArcUiTokens.textButtonStyle(
                accent: ArcUiTokens.primaryAccent,
                primary: true,
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ArcRaiderContractsScreen(),
                ),
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('OPEN CONTRACTS'),
            ),
          ),
        ),
        const ArcTacticalPanel(
          icon: Icons.emoji_events_outlined,
          title: 'COUNTRY LEADERBOARD · PLANNED',
          subtitle: 'Competition and monthly prizes are not live yet.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Rule(
                'The planned leaderboard counts successfully completed Hunter Rat contracts with a required video clip and confirmation from the person who placed the contract.',
              ),
              _Rule(
                'Reports, accusations and contracts created will never count towards rank.',
              ),
              _Rule(
                'Country is the primary competition. No county, state or province selection is required.',
              ),
              _Rule(
                'Verified country rankings are not available yet. Your current contract activity does not qualify for leaderboard prizes.',
              ),
              _Rule(
                'Monthly reward places and temporary access prizes are still being evaluated. No prize or subscription access is promised.',
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Rule extends StatelessWidget {
  const _Rule(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: ArcUiTokens.gapS),
    child: Text(text, style: ArcUiTokens.bodySmall()),
  );
}
