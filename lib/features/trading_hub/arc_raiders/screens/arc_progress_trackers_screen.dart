import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/build/app_drawer.dart';
import 'package:uag_arc_raiders_hub/features/feature_access_gate.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_hunt_targets_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/trading_card.dart';
import 'package:uag_arc_raiders_hub/screens/build/app_bar.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcProgressTrackersScreen extends StatelessWidget {
  const ArcProgressTrackersScreen({super.key});

  static const routeName = '/trading-hub/arc-raiders/progress-trackers';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const UagAppBar(
        title: 'Progress Trackers',
        subtitle: 'Scrappy, bench, quest and hunt target routing',
        showLogout: true,
      ),
      drawer: const AppDrawer(),
      bottomNavigationBar: const ArcCompanionBottomDock(activeLabel: 'Raid'),
      body: ArcRaidersScreenShell(
        useSafeArea: true,
        showAdBanner: true,
        child: ArcRaidersPageList(
          maxWidth: 980,
          bottomPadding: 120,
          children: [
            const ArcRaidersPageHeader(
              title: 'PROGRESS TRACKERS',
              subtitle:
                  'Open the focused tracker for the system you are updating.',
              icon: Icons.track_changes_rounded,
              accent: ArcUiTokens.primaryAccent,
            ),
            ArcRaidersSectionCard(
              accent: ArcUiTokens.primaryAccent,
              padding: const EdgeInsets.all(12),
              child: StreamBuilder<Map<String, FeatureAvailability>>(
                stream: FeatureAccess.watchAvailabilityMap(
                  _trackerLinks.map((link) => link.accessFlag),
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(8),
                      child: LinearProgressIndicator(
                        color: ArcUiTokens.primaryAccent,
                      ),
                    );
                  }
                  final availability =
                      snapshot.data ?? const <String, FeatureAvailability>{};
                  final visibleLinks = _trackerLinks
                      .where(
                        (link) =>
                            (availability[link.accessFlag] ??
                                    FeatureAvailability.hidden)
                                .isVisibleToStandardUsers,
                      )
                      .toList(growable: false);
                  if (visibleLinks.isEmpty) {
                    return const _TrackerEmptyState();
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final twoColumn = constraints.maxWidth >= 720;
                      final cardWidth = twoColumn
                          ? (constraints.maxWidth - 12) / 2
                          : constraints.maxWidth;

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final link in visibleLinks)
                            SizedBox(
                              width: cardWidth,
                              child: _TrackerLinkCard(
                                link: link,
                                availability:
                                    availability[link.accessFlag] ??
                                    FeatureAvailability.hidden,
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackerLinkDefinition {
  const _TrackerLinkDefinition({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.routeName,
    required this.accessFlag,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String routeName;
  final String accessFlag;
}

const _trackerLinks = <_TrackerLinkDefinition>[
  _TrackerLinkDefinition(
    title: 'Scrappy Tracker',
    subtitle: 'Track Scrappy upgrade materials and resource progress.',
    icon: Icons.egg_alt_rounded,
    accent: ArcUiTokens.secondaryAccent,
    routeName: ScrappyGridScreen.routeName,
    accessFlag: FeatureAccessFlag.scrappyTracker,
  ),
  _TrackerLinkDefinition(
    title: 'Bench Tracker',
    subtitle: 'Review bench tiers, material gaps and upgrade readiness.',
    icon: Icons.build_rounded,
    accent: ArcUiTokens.primaryAccent,
    routeName: ScrappyGridScreen.benchRouteName,
    accessFlag: FeatureAccessFlag.benchTracker,
  ),
  _TrackerLinkDefinition(
    title: 'Quest Tracker',
    subtitle: 'Track trader quest items, hand-ins and blocker items.',
    icon: Icons.assignment_rounded,
    accent: ArcUiTokens.warning,
    routeName: ScrappyGridScreen.questRouteName,
    accessFlag: FeatureAccessFlag.questTracker,
  ),
  _TrackerLinkDefinition(
    title: 'Hunt Targets',
    subtitle: 'Open Raid Planner targets for focused collection routes.',
    icon: Icons.my_location_rounded,
    accent: ArcUiTokens.success,
    routeName: RaidPlannerHuntTargetsScreen.routeName,
    accessFlag: FeatureAccessFlag.raidPlanner,
  ),
];

class _TrackerLinkCard extends StatelessWidget {
  const _TrackerLinkCard({required this.link, required this.availability});

  final _TrackerLinkDefinition link;
  final FeatureAvailability availability;

  @override
  Widget build(BuildContext context) {
    final accent = link.accent;
    return TradingCard(
      onTap: () {
        if (availability.canOpenFeature) {
          Navigator.of(context).pushNamed(link.routeName);
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => FeatureComingSoonScreen(
              title: link.title,
              description: link.subtitle,
            ),
          ),
        );
      },
      accent: accent,
      compact: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 104),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withValues(alpha: 0.42)),
              ),
              child: Icon(link.icon, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    link.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ArcUiTokens.cardTitle(fontSize: 17, color: accent),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    link.subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: ArcUiTokens.body(
                      fontSize: 12,
                      color: ArcUiTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (availability.isComingSoon)
                  _StatusPill(label: availability.label, color: accent),
                const SizedBox(height: 8),
                Icon(Icons.chevron_right_rounded, color: accent),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: ArcUiTokens.chipDecoration(color: color),
      child: Text(label.toUpperCase(), style: ArcUiTokens.label(color: color)),
    );
  }
}

class _TrackerEmptyState extends StatelessWidget {
  const _TrackerEmptyState();

  @override
  Widget build(BuildContext context) {
    return TradingCard(
      compact: true,
      accent: ArcUiTokens.secondaryAccent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.visibility_off_rounded,
            color: ArcUiTokens.secondaryAccent,
          ),
          const SizedBox(width: AppTheme.spaceS),
          Expanded(
            child: Text(
              'Progress trackers are hidden for this beta configuration. Adjust Feature Access in Admin Console to reopen them.',
              style: ArcUiTokens.body(
                fontSize: 13,
                color: ArcUiTokens.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
