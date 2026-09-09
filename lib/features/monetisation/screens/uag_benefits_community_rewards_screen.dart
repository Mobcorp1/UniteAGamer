import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/build/app_bar.dart';
import 'package:uag_arc_raiders_hub/build/app_drawer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_layout_system.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

import '../models/uag_community_referral_policy.dart';
import '../models/uag_creator_commission_rate_policy.dart';
import '../models/uag_creator_live_models.dart';
import '../models/uag_creator_programme_models.dart';
import '../repositories/uag_creator_live_repository.dart';
import '../screens/uag_creator_programme_screen.dart';
import '../widgets/uag_community_growth_live_panel.dart';
import '../widgets/uag_creator_commission_rate_panel.dart';
import '../widgets/uag_refer_a_raider_panel.dart';
import '../widgets/uag_referral_progress_panel.dart';
import '../widgets/uag_referral_reward_locker_panel.dart';

class UagBenefitsCommunityRewardsScreen extends StatelessWidget {
  const UagBenefitsCommunityRewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final creatorRepository = UagCreatorLiveRepository();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const UagAppBar(
        title: 'Community Command',
        subtitle: 'Referrals • rewards • Creator earnings',
      ),
      drawer: const AppDrawer(),
      body: ArcTacticalPageList(
        width: ArcPageWidth.wide,
        maxWidth: 1180,
        padding: ArcLayoutTokens.pagePadding(context),
        children: [
          _CommandHero(repository: creatorRepository),
          const SizedBox(height: 12),
          const _SectionNav(),
          const SizedBox(height: ArcUiTokens.gapM),
          const _SectionLabel(
            'REFER A RAIDER',
            'Invite. Validate. Bank the reward.',
          ),
          const SizedBox(height: 8),
          const UagReferARaiderPanel(),
          const SizedBox(height: 10),
          const UagReferralProgressPanel(),
          const SizedBox(height: 10),
          const UagReferralRewardLockerPanel(),
          const SizedBox(height: ArcUiTokens.gapM),
          const _ReferralMilestonesPanel(),
          const SizedBox(height: ArcUiTokens.gapM),
          const _SectionLabel(
            'COMMUNITY GROWTH',
            'The whole community can move the needle.',
          ),
          const SizedBox(height: 8),
          const UagCommunityGrowthLivePanel(),
          const SizedBox(height: ArcUiTokens.gapM),
          const _SectionLabel(
            'CREATOR PROGRAMME',
            'Performance earns better rates and better tools.',
          ),
          const SizedBox(height: 8),
          _CreatorLivePanel(repository: creatorRepository),
          const SizedBox(height: 10),
          const _CreatorCommissionLadder(),
          const SizedBox(height: 10),
          _CreatorProgrammeCta(
            onOpen: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const UagCreatorProgrammeScreen(),
              ),
            ),
          ),
          const SizedBox(height: ArcUiTokens.gapM),
          const _RewardPolicyPanel(),
        ],
      ),
    );
  }
}

class _CommandHero extends StatelessWidget {
  const _CommandHero({required this.repository});
  final UagCreatorLiveRepository repository;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      constraints: const BoxConstraints(minHeight: 310),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ArcUiTokens.primaryAccent.withValues(alpha: .52),
        ),
        image: const DecorationImage(
          image: AssetImage(
            'assets/arc_raiders/hero_cards/community_rewards.webp',
          ),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x33020A10), Color(0xA6081118), Color(0xF0060D13)],
            stops: [0, .48, 1],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const _Eyebrow('UAG COMMUNITY COMMAND'),
            const SizedBox(height: 8),
            const Text(
              'BUILD THE COMMUNITY.\nEARN YOUR PLACE IN IT.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                height: 1.02,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Refer Raiders. Bank Premium rewards. Grow into the Creator Programme. Track the value you create.',
              style: TextStyle(
                color: Color(0xFFE2E7EA),
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            StreamBuilder<UagCreatorProgrammeApplication?>(
              stream: repository.watchMyApplication(),
              builder: (context, appSnapshot) {
                final application = appSnapshot.data;
                if (application == null) {
                  return const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _HeroStat('RAIDER', 'Referral rewards live'),
                      _HeroStat('CREATOR', 'Fast-track at 5 validated'),
                    ],
                  );
                }
                return StreamBuilder<UagCreatorLiveDashboard>(
                  stream: repository.watchMyDashboard(),
                  builder: (context, dashSnapshot) {
                    final dash =
                        dashSnapshot.data ??
                        UagCreatorLiveDashboard(
                          uid: application.uid,
                          creatorId: application.creatorId,
                        );
                    final approved =
                        application.status ==
                        UagCreatorApplicationStatus.approved;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HeroStat(
                          approved
                              ? 'APPROVED CREATOR'
                              : application.status.label.toUpperCase(),
                          dash.creatorId.isEmpty
                              ? 'Creator ID pending'
                              : dash.creatorId,
                        ),
                        _HeroStat(
                          '${dash.creatorPoints.toStringAsFixed(dash.creatorPoints % 1 == 0 ? 0 : 1)} PTS',
                          'Creator Points',
                        ),
                        _HeroStat(
                          '${dash.commissionPercent.toStringAsFixed(dash.commissionPercent % 1 == 0 ? 0 : 1)}%',
                          'Base commission',
                        ),
                        _HeroStat(
                          '£${(dash.approvedCommissionPence / 100).toStringAsFixed(2)}',
                          'Approved earnings',
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionNav extends StatelessWidget {
  const _SectionNav();
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: const [
      _NavChip(Icons.person_add_alt_1, 'REFER'),
      _NavChip(Icons.inventory_2_outlined, 'REWARD LOCKER'),
      _NavChip(Icons.groups_2_outlined, 'COMMUNITY'),
      _NavChip(Icons.campaign_outlined, 'CREATOR'),
      _NavChip(Icons.payments_outlined, 'EARNINGS'),
    ],
  );
}

class _NavChip extends StatelessWidget {
  const _NavChip(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xD90A151D),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: ArcUiTokens.primaryAccent.withValues(alpha: .28),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: ArcUiTokens.primaryAccent),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: .6,
          ),
        ),
      ],
    ),
  );
}

class _CreatorLivePanel extends StatelessWidget {
  const _CreatorLivePanel({required this.repository});
  final UagCreatorLiveRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UagCreatorProgrammeApplication?>(
      stream: repository.watchMyApplication(),
      builder: (context, appSnapshot) {
        final application = appSnapshot.data;
        if (application == null) {
          return ArcTacticalPanel(
            icon: Icons.campaign_outlined,
            title: 'Creator Command Centre',
            subtitle:
                'No application linked yet. Your Raider referral progress still counts.',
            accent: ArcUiTokens.secondaryAccent,
            child: const Text(
              'Five validated Raider referrals unlock Creator fast-track review. You can also open the full Creator Programme below.',
            ),
          );
        }
        return StreamBuilder<UagCreatorLiveDashboard>(
          stream: repository.watchMyDashboard(),
          builder: (context, dashSnapshot) {
            final dash =
                dashSnapshot.data ??
                UagCreatorLiveDashboard(
                  uid: application.uid,
                  creatorId: application.creatorId,
                );
            final approved =
                application.status == UagCreatorApplicationStatus.approved;
            return ArcTacticalPanel(
              icon: Icons.radar,
              title: approved
                  ? 'Creator Command Centre • LIVE'
                  : 'Creator Command Centre',
              subtitle: approved
                  ? 'Your live audience, points, commission and earnings.'
                  : application.status.label,
              accent: approved
                  ? ArcUiTokens.primaryAccent
                  : ArcUiTokens.secondaryAccent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth >= 720
                          ? (constraints.maxWidth - 20) / 3
                          : constraints.maxWidth >= 420
                          ? (constraints.maxWidth - 10) / 2
                          : constraints.maxWidth;
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _Metric(
                            width,
                            'CREATOR POINTS',
                            dash.creatorPoints.toStringAsFixed(
                              dash.creatorPoints % 1 == 0 ? 0 : 1,
                            ),
                            Icons.bolt,
                          ),
                          _Metric(
                            width,
                            'COMMISSION',
                            '${dash.commissionPercent.toStringAsFixed(dash.commissionPercent % 1 == 0 ? 0 : 1)}%',
                            Icons.trending_up,
                          ),
                          _Metric(
                            width,
                            'ESSENTIAL',
                            '${dash.essentialSubscribers}',
                            Icons.shield_outlined,
                          ),
                          _Metric(
                            width,
                            'PREMIUM',
                            '${dash.premiumSubscribers}',
                            Icons.workspace_premium_outlined,
                          ),
                          _Metric(
                            width,
                            'PENDING',
                            '£${(dash.pendingCommissionPence / 100).toStringAsFixed(2)}',
                            Icons.hourglass_top,
                          ),
                          _Metric(
                            width,
                            'APPROVED',
                            '£${(dash.approvedCommissionPence / 100).toStringAsFixed(2)}',
                            Icons.payments_outlined,
                          ),
                          _Metric(
                            width,
                            'PAID',
                            '£${(dash.paidCommissionPence / 100).toStringAsFixed(2)}',
                            Icons.done_all,
                          ),
                          _Metric(
                            width,
                            'LEVEL',
                            dash.level?.name ?? 'Unranked',
                            Icons.military_tech_outlined,
                          ),
                        ],
                      );
                    },
                  ),
                  if (approved) ...[
                    const SizedBox(height: 14),
                    UagCreatorCommissionRatePanel(
                      creatorPoints: dash.creatorPoints,
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.width, this.label, this.value, this.icon);
  final double width;
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xB9071219),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ArcUiTokens.primaryAccent.withValues(alpha: .22),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: ArcUiTokens.primaryAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF9AA8B1),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ReferralMilestonesPanel extends StatelessWidget {
  const _ReferralMilestonesPanel();
  @override
  Widget build(BuildContext context) => ArcTacticalPanel(
    icon: Icons.flag_outlined,
    title: 'Referral milestones',
    subtitle:
        'Validated referrals — not raw sign-ups. ${UagCommunityReferralPolicy.retentionValidationDays}-day retention validation.',
    accent: ArcUiTokens.primaryAccent,
    child: Column(
      children: [
        for (final milestone in UagCommunityReferralPolicy.milestones)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _MilestoneRow(
              count: milestone.validatedReferrals,
              label: milestone.label,
            ),
          ),
      ],
    ),
  );
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({required this.count, required this.label});
  final int count;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: Colors.black.withValues(alpha: .16),
      border: Border.all(
        color: ArcUiTokens.primaryAccent.withValues(alpha: .22),
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ArcUiTokens.primaryAccent),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: ArcUiTokens.primaryAccent,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            '$count validated ${count == 1 ? 'referral' : 'referrals'}  →  $label',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _CreatorCommissionLadder extends StatelessWidget {
  const _CreatorCommissionLadder();
  static const _points = <double>[1, 8, 15, 25, 40, 60, 100];
  @override
  Widget build(BuildContext context) => ArcTacticalPanel(
    icon: Icons.trending_up,
    title: 'Creator commission ladder',
    subtitle:
        'Essential = 1 point • Premium = 1.5 points • Community Growth can add up to +2.5 points to the rate.',
    accent: ArcUiTokens.primaryAccent,
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final points in _points)
          Container(
            width: 132,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xB9071219),
              border: Border.all(
                color: ArcUiTokens.primaryAccent.withValues(alpha: .22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${UagCreatorCommissionRatePolicy.baseRatePercent(points).toStringAsFixed(UagCreatorCommissionRatePolicy.baseRatePercent(points) % 1 == 0 ? 0 : 1)}%',
                  style: const TextStyle(
                    color: ArcUiTokens.primaryAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${points.toStringAsFixed(0)}+ POINTS',
                  style: const TextStyle(
                    color: Color(0xFF9AA8B1),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _CreatorProgrammeCta extends StatelessWidget {
  const _CreatorProgrammeCta({required this.onOpen});
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => ArcTacticalPanel(
    icon: Icons.campaign_outlined,
    title: 'Full Creator Programme',
    subtitle:
        'Application, campaign codes, Community Arsenal and commission ledger.',
    accent: ArcUiTokens.secondaryAccent,
    child: SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onOpen,
        icon: const Icon(Icons.open_in_new),
        label: const Text('OPEN CREATOR COMMAND CENTRE'),
      ),
    ),
  );
}

class _RewardPolicyPanel extends StatelessWidget {
  const _RewardPolicyPanel();
  @override
  Widget build(BuildContext context) => const ArcTacticalPanel(
    icon: Icons.verified_user_outlined,
    title: 'Reward rules',
    subtitle: 'Built to reward genuine, retained community growth.',
    accent: ArcUiTokens.secondaryAccent,
    child: Text(
      'Referral rewards are banked before activation. Paid Premium is protected. Creator commission is based on eligible net subscription revenue actually received, with validation, refund and chargeback controls. Programme rewards can evolve as UAG grows.',
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title, this.subtitle);
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 4,
        height: 38,
        decoration: BoxDecoration(
          color: ArcUiTokens.primaryAccent,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF98A7B0), fontSize: 12),
            ),
          ],
        ),
      ),
    ],
  );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: ArcUiTokens.primaryAccent,
      fontSize: 11,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.3,
    ),
  );
}

class _HeroStat extends StatelessWidget {
  const _HeroStat(this.value, this.label);
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 128),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xCC071119),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(
        color: ArcUiTokens.primaryAccent.withValues(alpha: .3),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: ArcUiTokens.primaryAccent,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFB7C0C6), fontSize: 10),
        ),
      ],
    ),
  );
}
