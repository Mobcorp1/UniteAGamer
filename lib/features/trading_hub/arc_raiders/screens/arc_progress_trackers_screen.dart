import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/build/app_drawer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_hunt_targets_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
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
              accent: AppTheme.neonCyan,
            ),
            ArcRaidersSectionCard(
              accent: AppTheme.neonCyan,
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final twoColumn = constraints.maxWidth >= 720;
                  final cardWidth = twoColumn
                      ? (constraints.maxWidth - 12) / 2
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _TrackerLinkCard(
                          title: 'Scrappy Tracker',
                          subtitle:
                              'Track Scrappy upgrade materials and resource progress.',
                          icon: Icons.egg_alt_rounded,
                          accent: AppTheme.neonPink,
                          routeName: ScrappyGridScreen.routeName,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _TrackerLinkCard(
                          title: 'Bench Tracker',
                          subtitle:
                              'Review bench tiers, material gaps and upgrade readiness.',
                          icon: Icons.build_rounded,
                          accent: AppTheme.neonCyan,
                          routeName: ScrappyGridScreen.benchRouteName,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _TrackerLinkCard(
                          title: 'Quest Tracker',
                          subtitle:
                              'Track trader quest items, hand-ins and blocker items.',
                          icon: Icons.assignment_rounded,
                          accent: Colors.amberAccent,
                          routeName: ScrappyGridScreen.questRouteName,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _TrackerLinkCard(
                          title: 'Hunt Targets',
                          subtitle:
                              'Open Raid Planner targets for focused collection routes.',
                          icon: Icons.my_location_rounded,
                          accent: Colors.lightGreenAccent,
                          routeName: RaidPlannerHuntTargetsScreen.routeName,
                        ),
                      ),
                    ],
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

class _TrackerLinkCard extends StatelessWidget {
  const _TrackerLinkCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.routeName,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String routeName;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).pushNamed(routeName),
      child: Container(
        constraints: const BoxConstraints(minHeight: 118),
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.tradingCardDecoration(
          radius: 16,
          borderColor: accent.withValues(alpha: 0.28),
          backgroundColor: AppTheme.cardBackground.withValues(alpha: 0.68),
        ),
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
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.tradingHeading(fontSize: 17, color: accent),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyTextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ).copyWith(height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: accent),
          ],
        ),
      ),
    );
  }
}
