import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcBlueprintOpportunityCarousel extends StatefulWidget {
  const ArcBlueprintOpportunityCarousel({
    required this.marker,
    required this.cluster,
    this.onOpenBlueprint,
    super.key,
  });

  final ArcRaidMapMarker marker;
  final ArcRaidIntelCluster? cluster;
  final ValueChanged<String>? onOpenBlueprint;

  @override
  State<ArcBlueprintOpportunityCarousel> createState() =>
      _ArcBlueprintOpportunityCarouselState();
}

class _ArcBlueprintOpportunityCarouselState
    extends State<ArcBlueprintOpportunityCarousel> {
  late final PageController _controller;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.78);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blueprints = _blueprints;
    if (blueprints.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                blueprints.length == 1 ? 'FOUND BLUEPRINT' : 'FOUND BLUEPRINTS',
                style: AppTheme.bodyTextStyle(
                  fontSize: 11,
                  color: AppTheme.neonCyan,
                  isBold: true,
                ),
              ),
            ),
            if (blueprints.length > 1)
              Text(
                '${_page + 1} / ${blueprints.length}',
                style: AppTheme.bodyTextStyle(
                  fontSize: 11,
                  color: Colors.white54,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _controller,
            itemCount: blueprints.length,
            onPageChanged: (value) => setState(() => _page = value),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _blueprintCard(blueprints[index]),
            ),
          ),
        ),
        if (blueprints.length > 1) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Previous Blueprint',
                onPressed: _page == 0
                    ? null
                    : () => _controller.previousPage(
                        duration: AppTheme.fastAnimation,
                        curve: Curves.easeOut,
                      ),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              for (var index = 0; index < blueprints.length; index++)
                AnimatedContainer(
                  duration: AppTheme.fastAnimation,
                  width: index == _page ? 18 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: index == _page ? AppTheme.neonCyan : Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              IconButton(
                tooltip: 'Next Blueprint',
                onPressed: _page >= blueprints.length - 1
                    ? null
                    : () => _controller.nextPage(
                        duration: AppTheme.fastAnimation,
                        curve: Curves.easeOut,
                      ),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _blueprintCard(ArcBlueprint blueprint) {
    final prioritised = widget.marker.prioritizedBlueprintIds.contains(
      blueprint.id,
    );
    final finds = widget.marker.findsForBlueprint(blueprint.id);
    final imagePath = blueprint.imageAssetPath;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: AppTheme.fastAnimation,
        padding: const EdgeInsets.all(12),
        decoration: AppTheme.tradingCardDecoration(
          borderColor: prioritised
              ? AppTheme.neonPink.withValues(alpha: 0.58)
              : AppTheme.neonCyan.withValues(alpha: 0.30),
          backgroundColor: Colors.black.withValues(alpha: 0.30),
        ),
        child: Row(
          children: [
            Container(
              width: 96,
              height: 132,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppTheme.cardBackgroundDeep,
                border: Border.all(
                  color: prioritised ? AppTheme.neonPink : Colors.white24,
                ),
              ),
              child: imagePath == null || imagePath.trim().isEmpty
                  ? Icon(blueprint.icon, size: 42, color: Colors.white70)
                  : Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (_, _, _) =>
                          Icon(blueprint.icon, size: 42, color: Colors.white70),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (prioritised)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: AppTheme.neonPink,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'TOP WANTED',
                          style: AppTheme.bodyTextStyle(
                            fontSize: 10,
                            color: AppTheme.neonPink,
                            isBold: true,
                          ),
                        ),
                      ],
                    ),
                  Text(
                    blueprint.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.tradingHeading(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${blueprint.rarityLabel} • ${blueprint.category}',
                    style: AppTheme.bodyTextStyle(
                      fontSize: 11,
                      color: Colors.white54,
                    ),
                  ),
                  const Spacer(),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _pill(
                        '$finds ${finds == 1 ? 'find' : 'finds'}',
                        AppTheme.neonCyan,
                      ),
                      _pill(
                        widget.marker.confidence.label,
                        widget.marker.confidence.score >= 70
                            ? Colors.lightGreenAccent
                            : Colors.amberAccent,
                      ),
                    ],
                  ),
                  if (widget.onOpenBlueprint != null) ...[
                    const SizedBox(height: 7),
                    TextButton.icon(
                      onPressed: () =>
                          widget.onOpenBlueprint?.call(blueprint.id),
                      icon: const Icon(Icons.grid_view_rounded, size: 16),
                      label: const Text('Open Blueprint'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: AppTheme.bodyTextStyle(fontSize: 10, color: color, isBold: true),
      ),
    );
  }

  List<ArcBlueprint> get _blueprints {
    final byId = <String, ArcBlueprint>{
      for (final blueprint in ArcBlueprintSeedData.blueprints)
        blueprint.id: blueprint,
    };
    return widget.marker.blueprintIds
        .map((id) => byId[id])
        .whereType<ArcBlueprint>()
        .toList(growable: false);
  }
}
