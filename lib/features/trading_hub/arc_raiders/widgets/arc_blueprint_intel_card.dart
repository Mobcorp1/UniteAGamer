import 'package:flutter/material.dart';
import '../data/arc_blueprint_seed_data.dart';
import '../data/arc_blueprint_sighting_aggregator.dart';
import '../models/arc_raid_intelligence_models.dart';
import 'arc_blueprint_opportunity_carousel.dart';
import 'arc_blueprint_sighting_activity.dart';
import 'foundation/arc_ui_tokens.dart';

class ArcBlueprintIntelCard extends StatelessWidget {
  const ArcBlueprintIntelCard({
    required this.marker,
    required this.cluster,
    required this.map,
    required this.onCentreMap,
    required this.onAddStop,
    required this.onOpenBlueprint,
    required this.onOpenRaidPlanner,
    this.showCarousel = true,
    super.key,
  });
  final ArcRaidMapMarker marker;
  final ArcRaidIntelCluster cluster;
  final ArcRaidMap map;
  final VoidCallback onCentreMap, onAddStop, onOpenBlueprint, onOpenRaidPlanner;
  final bool showCarousel;

  @override
  Widget build(BuildContext context) {
    final evidence = cluster.evidence;
    final reports = evidence
        .where((e) => e.sourceCategory == 'community_drop_report')
        .toList();
    final seeded = evidence
        .where((e) => e.sourceCategory != 'community_drop_report')
        .toList();
    final names = ArcBlueprintSeedData.blueprints
        .where((b) => cluster.blueprintIds.contains(b.id))
        .map((b) => b.name)
        .join(', ');
    String location(ArcRaidIntelEvidence e) {
      for (final poi in map.pois) {
        if (poi.id == e.poiId) return poi.name;
      }
      return e.approximateArea?.trim().isNotEmpty == true
          ? e.approximateArea!
          : 'Approximate area';
    }

    final pois = [...map.pois]
      ..sort(
        (a, b) => a.point
            .distanceTo(cluster.point)
            .compareTo(b.point.distanceTo(cluster.point)),
      );
    final exits = [...map.extractions]
      ..sort(
        (a, b) => a.point
            .distanceTo(cluster.point)
            .compareTo(b.point.distanceTo(cluster.point)),
      );
    final hatches = [...map.hatches]
      ..sort(
        (a, b) => a.point
            .distanceTo(cluster.point)
            .compareTo(b.point.distanceTo(cluster.point)),
      );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ArcUiTokens.surfaceDecoration(role: ArcSurfaceRole.panel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            names.isEmpty ? cluster.label : names,
            style: ArcUiTokens.cardTitle(),
          ),
          Text(cluster.label, style: ArcUiTokens.bodySmall()),
          if (evidence.isEmpty) const Text('No location evidence yet.'),
          for (final e in reports.take(2)) Text('Reported at ${location(e)}'),
          if (seeded.isNotEmpty)
            Text('Seeded guidance: ${seeded.map(location).toSet().join(', ')}'),
          Text(
            'Why here: ${cluster.commonSource}. ${cluster.conditionCorrelation}.',
            style: ArcUiTokens.bodySmall(),
          ),
          if (reports.isNotEmpty) Text('${reports.length} community reports'),
          if (seeded.isNotEmpty)
            const Text('Seeded guidance is not a confirmed find.'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ElevatedButton.icon(
                onPressed: onAddStop,
                icon: const Icon(Icons.add_location_alt_rounded),
                label: const Text('Add to Route'),
              ),
              OutlinedButton(
                onPressed: onCentreMap,
                child: const Text('Centre Map'),
              ),
              OutlinedButton(
                onPressed: onOpenBlueprint,
                child: const Text('Open Blueprint'),
              ),
              OutlinedButton(
                onPressed: onOpenRaidPlanner,
                child: const Text('Open Raid Planner'),
              ),
            ],
          ),
          if (showCarousel)
            ArcBlueprintOpportunityCarousel(marker: marker, cluster: cluster),
          ExpansionTile(
            title: const Text('Evidence and nearby navigation'),
            children: [
              Text(
                '${cluster.layer.label} - ${cluster.confidence.label} guidance confidence',
              ),
              ArcBlueprintSightingActivity(
                activity: const ArcBlueprintSightingAggregator().aggregate(
                  cluster,
                ),
              ),
              for (final e in evidence)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    e.sourceCategory == 'community_drop_report'
                        ? 'Reported at ${location(e)}'
                        : 'Seeded guidance: ${location(e)}',
                  ),
                  subtitle: Text(
                    [
                      e.sourceReference,
                      if (e.containerSource != null) e.containerSource!,
                      if (e.acquisitionSource != null) e.acquisitionSource!,
                      if (e.claimSummary.isNotEmpty) e.claimSummary,
                      if (e.publishedAt != null)
                        'Published ${e.publishedAt!.toIso8601String().split('T').first}',
                      if (e.reviewedAt != null)
                        'Reviewed ${e.reviewedAt!.toIso8601String().split('T').first}',
                      if (e.notes.isNotEmpty) e.notes,
                    ].join(' - '),
                  ),
                ),
              Text(
                'Nearest POI: ${pois.isEmpty ? 'No nearby location information' : 'Near ${pois.first.name}'}',
              ),
              Text(
                'Nearest Extraction: ${exits.isEmpty ? 'No extraction information available' : exits.first.name}',
              ),
              Text(
                'Nearest Raider Hatch: ${hatches.isEmpty ? 'No Raider Hatch information available' : hatches.first.name}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
