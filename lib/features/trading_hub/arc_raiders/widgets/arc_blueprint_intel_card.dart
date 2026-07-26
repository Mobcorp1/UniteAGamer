import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_sighting_aggregator.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_blueprint_opportunity_carousel.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_blueprint_sighting_activity.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcBlueprintIntelCard extends StatelessWidget {
  const ArcBlueprintIntelCard({
    required this.marker,
    required this.cluster,
    required this.map,
    required this.onCentreMap,
    required this.onAddStop,
    required this.onOpenBlueprint,
    required this.onOpenRaidPlanner,
    super.key,
  });

  final ArcRaidMapMarker marker;
  final ArcRaidIntelCluster cluster;
  final ArcRaidMap map;
  final VoidCallback onCentreMap;
  final VoidCallback onAddStop;
  final VoidCallback onOpenBlueprint;
  final VoidCallback onOpenRaidPlanner;

  @override
  Widget build(BuildContext context) {
    final leadBlueprint = _leadBlueprint;
    final nearestPoi = _nearestPoi;
    final nearestExtraction = _nearestExtraction;
    final nearestHatch = _nearestHatch;
    final latestEvidence = _latestEvidence;
    final sourceTypes = cluster.evidence
        .map((item) => item.containerSource?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final acquisitionTypes = cluster.evidence
        .map((item) => item.acquisitionSource?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final sightingActivity = const ArcBlueprintSightingAggregator().aggregate(
      cluster,
    );

    return Container(
      decoration: AppTheme.tradingCardDecoration(
        borderColor: _confidenceColor.withValues(alpha: 0.50),
        backgroundColor: Colors.black.withValues(alpha: 0.38),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hero(leadBlueprint),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headline(leadBlueprint),
                const SizedBox(height: 10),
                _metrics(),
                const SizedBox(height: 14),
                ArcBlueprintOpportunityCarousel(
                  marker: marker,
                  cluster: cluster,
                  onOpenBlueprint: (_) => onOpenBlueprint(),
                ),
                const SizedBox(height: 14),
                ArcBlueprintSightingActivity(activity: sightingActivity),
                const SizedBox(height: 14),
                _sectionTitle('INTEL SUMMARY'),
                const SizedBox(height: 7),
                Text(
                  cluster.cautiousSummary,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  marker.detail.trim().isEmpty
                      ? 'Community and seeded evidence have been combined for this opportunity.'
                      : marker.detail,
                  style: const TextStyle(color: Colors.white60, height: 1.35),
                ),
                if (sourceTypes.isNotEmpty || acquisitionTypes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final value in sourceTypes.take(3))
                        _pill(value, AppTheme.neonCyan),
                      for (final value in acquisitionTypes.take(2))
                        _pill(value, AppTheme.neonPink),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                _sectionTitle('NEARBY NAVIGATION'),
                const SizedBox(height: 8),
                _navigationRow(
                  icon: Icons.location_city_rounded,
                  label: 'Nearest POI',
                  value: nearestPoi?.name ?? cluster.label,
                  distance: nearestPoi == null
                      ? null
                      : _distanceLabel(nearestPoi.point),
                ),
                _navigationRow(
                  icon: Icons.exit_to_app_rounded,
                  label: 'Nearest Extraction',
                  value: nearestExtraction?.name ?? 'No extraction calibrated',
                  distance: nearestExtraction == null
                      ? null
                      : _distanceLabel(nearestExtraction.point),
                ),
                _navigationRow(
                  icon: Icons.key_rounded,
                  label: 'Nearest Raider Hatch',
                  value: nearestHatch?.name ?? 'No Raider Hatch calibrated',
                  distance: nearestHatch == null
                      ? null
                      : _distanceLabel(nearestHatch.point),
                ),
                const SizedBox(height: 14),
                _sectionTitle('EVIDENCE'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _evidenceMetric(
                      Icons.receipt_long_rounded,
                      '${cluster.reportCount}',
                      'Reports',
                    ),
                    _evidenceMetric(
                      Icons.groups_rounded,
                      '${cluster.independentReporterCount}',
                      'Raiders',
                    ),
                    _evidenceMetric(
                      Icons.schedule_rounded,
                      cluster.freshnessLabel,
                      'Freshness',
                    ),
                    _evidenceMetric(
                      Icons.layers_rounded,
                      cluster.layer.label,
                      'Layer',
                    ),
                  ],
                ),
                if (latestEvidence != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _evidenceLine(latestEvidence),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _actionButton(
                      label: 'Centre Map',
                      icon: Icons.center_focus_strong_rounded,
                      onPressed: onCentreMap,
                    ),
                    _actionButton(
                      label: 'Add to Route',
                      icon: Icons.add_location_alt_rounded,
                      onPressed: onAddStop,
                      primary: true,
                    ),
                    _actionButton(
                      label: 'Open Blueprint',
                      icon: Icons.grid_view_rounded,
                      onPressed: onOpenBlueprint,
                    ),
                    _actionButton(
                      label: 'Open Raid Planner',
                      icon: Icons.route_rounded,
                      onPressed: onOpenRaidPlanner,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(ArcBlueprint? blueprint) {
    final imagePath = blueprint?.imageAssetPath;
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imagePath != null && imagePath.trim().isNotEmpty)
            Image.asset(
              imagePath,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, _, _) => _heroFallback(blueprint),
            )
          else
            _heroFallback(blueprint),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.92),
                ],
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: 12,
            child: _pill(cluster.confidence.label, _confidenceColor),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: _pill(
              '${marker.count} ${marker.count == 1 ? 'find' : 'finds'}',
              AppTheme.neonCyan,
            ),
          ),
          if (marker.prioritizedBlueprintIds.isNotEmpty)
            Positioned(
              left: 12,
              bottom: 12,
              child: _pill('TOP WANTED', AppTheme.neonPink),
            ),
        ],
      ),
    );
  }

  Widget _heroFallback(ArcBlueprint? blueprint) {
    return Container(
      color: AppTheme.cardBackgroundDeep,
      alignment: Alignment.center,
      child: Icon(
        blueprint?.icon ?? Icons.extension_rounded,
        size: 56,
        color: Colors.white38,
      ),
    );
  }

  Widget _headline(ArcBlueprint? blueprint) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                blueprint?.name ?? cluster.label,
                style: AppTheme.tradingHeading(
                  fontSize: 23,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                blueprint == null
                    ? cluster.label
                    : '${blueprint.rarityLabel} • ${blueprint.category} • ${cluster.label}',
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
        Icon(
          marker.approximate
              ? Icons.help_outline_rounded
              : Icons.verified_rounded,
          color: marker.approximate ? Colors.amberAccent : _confidenceColor,
        ),
      ],
    );
  }

  Widget _metrics() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _pill(
          '${cluster.blueprintIds.length} ${cluster.blueprintIds.length == 1 ? 'Blueprint' : 'Blueprints'}',
          AppTheme.neonCyan,
        ),
        _pill(cluster.commonSource, Colors.white70),
        _pill(cluster.conditionCorrelation, Colors.amberAccent),
      ],
    );
  }

  Widget _navigationRow({
    required IconData icon,
    required String label,
    required String value,
    String? distance,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppTheme.neonCyan),
          const SizedBox(width: 8),
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (distance != null) ...[
            const SizedBox(width: 8),
            Text(
              distance,
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  Widget _evidenceMetric(IconData icon, String value, String label) {
    return Container(
      width: 108,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.neonCyan),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool primary = false,
  }) {
    if (primary) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label),
    );
  }

  Widget _sectionTitle(String value) {
    return Text(
      value,
      style: AppTheme.bodyTextStyle(
        fontSize: 10,
        color: AppTheme.neonCyan,
        isBold: true,
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

  ArcBlueprint? get _leadBlueprint {
    final orderedIds = <String>[
      ...marker.prioritizedBlueprintIds,
      ...marker.blueprintIds.where(
        (id) => !marker.prioritizedBlueprintIds.contains(id),
      ),
    ];
    for (final id in orderedIds) {
      for (final blueprint in ArcBlueprintSeedData.blueprints) {
        if (blueprint.id == id) return blueprint;
      }
    }
    return null;
  }

  ArcRaidMapPoi? get _nearestPoi {
    if (map.pois.isEmpty) return null;
    final items = List<ArcRaidMapPoi>.from(map.pois)
      ..sort((a, b) => _distance(a.point).compareTo(_distance(b.point)));
    return items.first;
  }

  ArcRaidExtraction? get _nearestExtraction {
    if (map.extractions.isEmpty) return null;
    final items = List<ArcRaidExtraction>.from(map.extractions)
      ..sort((a, b) => _distance(a.point).compareTo(_distance(b.point)));
    return items.first;
  }

  ArcRaiderHatch? get _nearestHatch {
    if (map.hatches.isEmpty) return null;
    final items = List<ArcRaiderHatch>.from(map.hatches)
      ..sort((a, b) => _distance(a.point).compareTo(_distance(b.point)));
    return items.first;
  }

  ArcRaidIntelEvidence? get _latestEvidence {
    if (cluster.evidence.isEmpty) return null;
    final items = List<ArcRaidIntelEvidence>.from(cluster.evidence)
      ..sort((a, b) {
        final aDate = a.reviewedAt ?? a.publishedAt;
        final bDate = b.reviewedAt ?? b.publishedAt;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });
    return items.first;
  }

  double _distance(ArcNormalizedPoint point) {
    final dx = point.x - cluster.point.x;
    final dy = point.y - cluster.point.y;
    return math.sqrt((dx * dx) + (dy * dy));
  }

  String _distanceLabel(ArcNormalizedPoint point) {
    final percent = (_distance(point) * 100).round();
    if (percent <= 1) return 'at location';
    return '~$percent% map';
  }

  String _evidenceLine(ArcRaidIntelEvidence evidence) {
    final parts = <String>[
      evidence.sourceReference,
      if (evidence.containerSource?.trim().isNotEmpty == true)
        evidence.containerSource!.trim(),
      if (evidence.acquisitionSource?.trim().isNotEmpty == true)
        evidence.acquisitionSource!.trim(),
      if (evidence.notes.trim().isNotEmpty) evidence.notes.trim(),
    ];
    return parts.join(' • ');
  }

  Color get _confidenceColor {
    if (cluster.confidence.score >= 90) return Colors.lightGreenAccent;
    if (cluster.confidence.score >= 70) return AppTheme.neonCyan;
    if (cluster.confidence.score >= 45) return Colors.amberAccent;
    return Colors.white54;
  }
}
