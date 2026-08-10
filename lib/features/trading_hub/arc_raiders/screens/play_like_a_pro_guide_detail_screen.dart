import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_asset_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/play_like_a_pro_guide.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_raid_intelligence_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class PlayLikeAProGuideDetailScreen extends StatelessWidget {
  const PlayLikeAProGuideDetailScreen({
    super.key,
    required this.guide,
    required this.allGuides,
    required this.onOpenGuide,
  });

  final PlayLikeAProGuide guide;
  final List<PlayLikeAProGuide> allGuides;
  final ValueChanged<PlayLikeAProGuide> onOpenGuide;

  @override
  Widget build(BuildContext context) {
    final related = <PlayLikeAProGuide>[
      for (final id in guide.relatedGuideIds)
        ...allGuides.where((item) => item.id == id),
    ];
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(guide.category.label),
      ),
      body: ArcRaidersPageScaffold(
        showAdBanner: true,
        maxWidth: 920,
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceL),
              decoration: AppTheme.tradingCardDecoration(
                borderColor: AppTheme.neonCyan.withValues(alpha: 0.32),
                radius: 22,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppTheme.spaceS,
                    runSpacing: AppTheme.spaceS,
                    children: [
                      _pill(guide.category.label, AppTheme.neonCyan),
                      _pill(guide.skillLevel.label, AppTheme.neonPink),
                      _pill(guide.squadScope.label, AppTheme.tradingSuccess),
                      if (guide.featured)
                        _pill('Featured', AppTheme.warningAmber),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  Text(
                    guide.title,
                    style: AppTheme.tradingHeading(
                      fontSize: 30,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceS),
                  Text(
                    guide.summary,
                    style: const TextStyle(
                      color: Colors.white70,
                      height: 1.45,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  Text(
                    'By ${guide.author.displayName}${guide.author.creatorTitle?.trim().isNotEmpty == true ? ' • ${guide.author.creatorTitle}' : ''}',
                    style: AppTheme.bodyTextStyle(
                      fontSize: 13,
                      color: AppTheme.neonCyan,
                      isBold: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceM),
            ...guide.sections.map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spaceL),
                  decoration: AppTheme.tradingCardDecoration(
                    borderColor: AppTheme.tradingSoftBorder,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.heading,
                        style: AppTheme.tradingHeading(fontSize: 21),
                      ),
                      if (section.body.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.spaceS),
                        Text(
                          section.body,
                          style: const TextStyle(
                            color: Colors.white70,
                            height: 1.45,
                          ),
                        ),
                      ],
                      if (section.bullets.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.spaceM),
                        ...section.bullets.map(
                          (bullet) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppTheme.spaceS,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Icon(
                                    Icons.bolt_rounded,
                                    size: 15,
                                    color: AppTheme.neonPink,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spaceS),
                                Expanded(
                                  child: Text(
                                    bullet,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (guide.isMapRelevant ||
                guide.isLoadoutRelevant ||
                guide.category == PlayLikeAProCategory.blueprintRoutes) ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceL),
                decoration: AppTheme.tradingCardDecoration(
                  borderColor: AppTheme.neonPink.withValues(alpha: 0.25),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connected UAG tools',
                      style: AppTheme.tradingHeading(fontSize: 20),
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    Wrap(
                      spacing: AppTheme.spaceS,
                      runSpacing: AppTheme.spaceS,
                      children: [
                        if (guide.isMapRelevant)
                          _routeButton(
                            context,
                            'Open Raid Intelligence',
                            Icons.map_rounded,
                            ArcRaidIntelligenceScreen.routeName,
                          ),
                        if (guide.category ==
                                PlayLikeAProCategory.blueprintRoutes ||
                            guide.tags.contains('blueprints'))
                          _routeButton(
                            context,
                            'Open Blueprint Tracker',
                            Icons.grid_view_rounded,
                            BlueprintGridScreen.routeName,
                          ),
                        if (guide.isLoadoutRelevant)
                          _routeButton(
                            context,
                            'Open Favourite Loadout',
                            Icons.backpack_rounded,
                            FavouriteLoadoutScreen.routeName,
                          ),
                      ],
                    ),
                    if (guide.mapIds.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spaceM),
                      Text(
                        'Map relevance: ${guide.mapIds.map((id) => ArcMapAssetRegistry.canonicalMapDisplayNameFor(id) ?? id).join(', ')}',
                        style: const TextStyle(color: Colors.white60),
                      ),
                    ],
                    if (guide.weaponNames.isNotEmpty)
                      Text(
                        'Weapon relevance: ${guide.weaponNames.join(', ')}',
                        style: const TextStyle(color: Colors.white60),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
            ],
            if (related.isNotEmpty) ...[
              Text(
                'Related guidance',
                style: AppTheme.tradingHeading(fontSize: 22),
              ),
              const SizedBox(height: AppTheme.spaceS),
              ...related.map(
                (item) => Card(
                  color: Colors.transparent,
                  child: ListTile(
                    title: Text(
                      item.title,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      item.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white60),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppTheme.neonCyan,
                    ),
                    onTap: () => onOpenGuide(item),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppTheme.spaceXL),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppTheme.spaceM,
      vertical: 6,
    ),
    decoration: AppTheme.tradingPillDecoration(color: color),
    child: Text(
      text,
      style: AppTheme.bodyTextStyle(fontSize: 12, color: color, isBold: true),
    ),
  );

  Widget _routeButton(
    BuildContext context,
    String label,
    IconData icon,
    String routeName,
  ) => OutlinedButton.icon(
    onPressed: () => Navigator.of(context).pushNamed(routeName),
    icon: Icon(icon, size: 18),
    label: Text(label),
  );
}
