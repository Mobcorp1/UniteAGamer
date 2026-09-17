import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/build/app_drawer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';
import 'package:uag_arc_raiders_hub/screens/build/app_bar.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_wall_of_legends_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_wall_of_legends_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class WallOfLegendsScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/wall-of-legends';

  const WallOfLegendsScreen({super.key});

  @override
  State<WallOfLegendsScreen> createState() => _WallOfLegendsScreenState();
}

class _WallOfLegendsScreenState extends State<WallOfLegendsScreen> {
  final ArcWallOfLegendsRepository _repository = ArcWallOfLegendsRepository();

  ArcWallOfLegendsCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: const UagAppBar(
        title: 'Wall of Legends',
        subtitle: 'Permanent recognition across the UAG network',
        showLogout: false,
      ),
      drawer: const AppDrawer(),
      bottomNavigationBar: const ArcCompanionBottomDock(
        activeLabel: 'DISCOVER',
      ),
      body: ArcRaidersScreenShell(
        useSafeArea: true,
        showAdBanner: false,
        child: StreamBuilder<List<ArcWallOfLegendsEntry>>(
          stream: _repository.watchEntries(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: ArcRaidersStatePanel(
                  title: 'Loading legends',
                  message: 'Syncing approved UAG recognition records.',
                  icon: Icons.sync_rounded,
                  accent: ArcUiTokens.primaryAccent,
                  compact: true,
                ),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: ArcRaidersStatePanel(
                    title: 'Wall of Legends unavailable',
                    message:
                        'Recognised community entries could not load right now.',
                    icon: Icons.cloud_off_rounded,
                    accent: ArcUiTokens.warning,
                  ),
                ),
              );
            }

            final entries = snapshot.data ?? const <ArcWallOfLegendsEntry>[];
            final filtered = _selectedCategory == null
                ? entries
                : entries
                      .where((entry) => entry.category == _selectedCategory)
                      .toList(growable: false);

            return ArcRaidersPageList(
              maxWidth: 1120,
              children: [
                ArcRaidersHeroBanner(
                  title: 'IMMORTALISED IN THE UAG NETWORK',
                  subtitle: entries.isEmpty
                      ? 'Founders, beta Raiders, creators, guardians and community contributors can be permanently recognised here once approved.'
                      : '${entries.length} approved ${entries.length == 1 ? 'legend' : 'legends'} currently recorded across the UAG community.',
                  accent: ArcUiTokens.warning,
                ),
                const SizedBox(height: AppTheme.spaceM),
                _categoryFilters(),
                const SizedBox(height: AppTheme.spaceM),
                if (entries.isEmpty)
                  const ArcRaidersStatePanel(
                    title: 'Legends awaiting curation',
                    message:
                        'Approved historical entries will appear here as the Wall of Legends grows.',
                    icon: Icons.workspace_premium_outlined,
                    accent: ArcUiTokens.primaryAccent,
                  )
                else if (filtered.isEmpty)
                  const ArcRaidersStatePanel(
                    title: 'No legends in this category yet',
                    message:
                        'Choose another category or check back after the next community update.',
                    icon: Icons.filter_alt_off_rounded,
                    accent: ArcUiTokens.secondaryAccent,
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 680;
                      return Wrap(
                        spacing: AppTheme.spaceM,
                        runSpacing: AppTheme.spaceM,
                        children: filtered
                            .map(
                              (entry) => SizedBox(
                                width: compact
                                    ? double.infinity
                                    : (constraints.maxWidth - AppTheme.spaceM) /
                                          2,
                                child: _legendCard(entry),
                              ),
                            )
                            .toList(growable: false),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _categoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(label: 'All', selected: _selectedCategory == null),
          for (final category in ArcWallOfLegendsCategory.values)
            _filterChip(
              label: category.label,
              selected: _selectedCategory == category,
              onSelected: () => setState(() => _selectedCategory = category),
            ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    VoidCallback? onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: AppTheme.spaceS),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () {
            if (onSelected != null) {
              onSelected();
            } else {
              setState(() => _selectedCategory = null);
            }
          },
          child: ArcTacticalStatusPill(
            label: label,
            icon: selected ? Icons.check_circle_rounded : Icons.circle_outlined,
            accent: selected
                ? ArcUiTokens.primaryAccent
                : ArcUiTokens.textTertiary,
            selected: selected,
          ),
        ),
      ),
    );
  }

  Widget _legendCard(ArcWallOfLegendsEntry entry) {
    final accent = _categoryAccent(entry.category);
    return ArcRaidersSectionCard(
      accent: accent,
      radius: 16,
      padding: const EdgeInsets.all(AppTheme.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.12),
                  border: Border.all(color: accent.withValues(alpha: 0.42)),
                ),
                child: Icon(Icons.emoji_events_rounded, color: accent),
              ),
              const SizedBox(width: AppTheme.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ArcUiTokens.cardTitle(
                        fontSize: 18,
                        color: ArcUiTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ArcUiTokens.body(
                        color: accent,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          Wrap(
            spacing: AppTheme.spaceS,
            runSpacing: AppTheme.spaceS,
            children: [
              _pill(entry.category.label, accent),
              if (entry.uagId.isNotEmpty) _pill(entry.uagId, AppTheme.neonCyan),
              if (entry.seasonId.isNotEmpty)
                _pill(entry.seasonId, Colors.amberAccent),
            ],
          ),
          if (entry.reason.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceM),
            Text(
              entry.reason,
              style: ArcUiTokens.body(color: ArcUiTokens.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return ArcTacticalStatusPill(label: label, accent: color);
  }

  Color _categoryAccent(ArcWallOfLegendsCategory category) {
    return switch (category) {
      ArcWallOfLegendsCategory.founders => Colors.amberAccent,
      ArcWallOfLegendsCategory.closedBetaRaiders => AppTheme.neonCyan,
      ArcWallOfLegendsCategory.communityHeroes => Colors.lightGreenAccent,
      ArcWallOfLegendsCategory.guardians => Colors.lightGreenAccent,
      ArcWallOfLegendsCategory.trustedTraders => AppTheme.neonPink,
      ArcWallOfLegendsCategory.topIntelContributors => Colors.amberAccent,
      ArcWallOfLegendsCategory.creators => AppTheme.neonPink,
      ArcWallOfLegendsCategory.competitionWinners => AppTheme.neonCyan,
    };
  }
}
