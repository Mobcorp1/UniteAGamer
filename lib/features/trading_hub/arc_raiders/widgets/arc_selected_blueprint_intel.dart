import 'package:flutter/material.dart';
import '../models/arc_raid_intelligence_models.dart';
import 'arc_blueprint_opportunity_carousel.dart';
import 'arc_blueprint_intel_card.dart';

/// Resolve only explicit member identities. Proximity cannot establish provenance.
List<ArcRaidIntelCluster> resolveBlueprintMemberClusters(
  ArcRaidMapMarker marker,
  String blueprintId,
  List<ArcRaidIntelCluster> clusters,
) {
  final identities = {marker.id, ...marker.clusterMemberIds};
  return clusters
      .where(
        (c) =>
            c.mapId == marker.mapId &&
            c.layer == marker.layer &&
            c.blueprintIds.contains(blueprintId) &&
            (c.id == marker.payloadId ||
                identities.contains(c.id) ||
                identities.contains('${c.id}_marker')),
      )
      .toList();
}

class ArcSelectedBlueprintIntel extends StatefulWidget {
  const ArcSelectedBlueprintIntel({
    super.key,
    required this.marker,
    required this.clusters,
    required this.map,
    required this.onCentreMap,
    required this.onAddStop,
    required this.onOpenBlueprint,
    required this.onOpenRaidPlanner,
  });
  final ArcRaidMapMarker marker;
  final List<ArcRaidIntelCluster> clusters;
  final ArcRaidMap map;
  final VoidCallback onCentreMap, onOpenBlueprint, onOpenRaidPlanner;
  final ValueChanged<ArcRaidIntelCluster> onAddStop;
  @override
  State<ArcSelectedBlueprintIntel> createState() =>
      _ArcSelectedBlueprintIntelState();
}

class _ArcSelectedBlueprintIntelState extends State<ArcSelectedBlueprintIntel> {
  String? _selected;
  @override
  void didUpdateWidget(covariant ArcSelectedBlueprintIntel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.marker.id != widget.marker.id ||
        oldWidget.marker.blueprintIds.join('|') !=
            widget.marker.blueprintIds.join('|')) {
      _selected = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ids = widget.marker.blueprintIds;
    if (ids.isEmpty) return const Text('No location evidence yet.');
    final id = ids.contains(_selected) ? _selected! : ids.first;
    final members = resolveBlueprintMemberClusters(
      widget.marker,
      id,
      widget.clusters,
    );
    final scoped = members
        .map(
          (c) => ArcRaidIntelCluster(
            id: c.id,
            mapId: c.mapId,
            label: c.label,
            point: c.point,
            layer: c.layer,
            poiId: c.poiId,
            blueprintIds: [id],
            evidence: c.evidence.where((e) => e.blueprintId == id).toList(),
            confidence: c.confidence,
            commonSource: c.commonSource,
            conditionCorrelation: c.conditionCorrelation,
            freshnessLabel: c.freshnessLabel,
          ),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (scoped.isEmpty)
          const Text(
            'No location evidence yet. Context unavailable for this Blueprint.',
          ),
        for (var i = 0; i < scoped.length; i++)
          ArcBlueprintIntelCard(
            marker: widget.marker,
            cluster: scoped[i],
            map: widget.map,
            showCarousel: false,
            onCentreMap: widget.onCentreMap,
            onAddStop: () => widget.onAddStop(members[i]),
            onOpenBlueprint: widget.onOpenBlueprint,
            onOpenRaidPlanner: widget.onOpenRaidPlanner,
          ),
        ArcBlueprintOpportunityCarousel(
          marker: widget.marker,
          cluster: scoped.firstOrNull,
          onSelectedBlueprint: (value) => setState(() => _selected = value),
        ),
      ],
    );
  }
}
