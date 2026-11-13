import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

class ArcMapMarkerClusterEngine {
  const ArcMapMarkerClusterEngine();

  List<ArcRaidMapMarker> cluster(
    Iterable<ArcRaidMapMarker> markers, {
    double radius = 0.045,
  }) {
    final input = markers
        .where((marker) => marker.enabled)
        .toList(growable: false);
    if (input.length < 2) return input;

    final output = <ArcRaidMapMarker>[];
    final consumed = <String>{};

    for (final marker in input) {
      if (consumed.contains(marker.id)) continue;
      if (!marker.category.clustersByDefault) {
        output.add(marker);
        consumed.add(marker.id);
        continue;
      }

      final nearby = input
          .where((candidate) {
            return !consumed.contains(candidate.id) &&
                candidate.mapId == marker.mapId &&
                candidate.layer == marker.layer &&
                candidate.category == marker.category &&
                candidate.category.clustersByDefault &&
                candidate.point.distanceTo(marker.point) <= radius;
          })
          .toList(growable: false);

      if (nearby.length < 2) {
        output.add(marker);
        consumed.add(marker.id);
        continue;
      }

      for (final item in nearby) {
        consumed.add(item.id);
      }

      final totalCount = nearby.fold<int>(
        0,
        (total, item) => total + item.count,
      );
      final averageX =
          nearby.fold<double>(0, (total, item) => total + item.point.x) /
          nearby.length;
      final averageY =
          nearby.fold<double>(0, (total, item) => total + item.point.y) /
          nearby.length;
      final confidence = nearby
          .map((item) => item.confidence)
          .reduce(
            (current, next) => next.score > current.score ? next : current,
          );
      final labels = nearby
          .map((item) => item.label.trim())
          .where((label) => label.isNotEmpty)
          .toSet()
          .toList(growable: false);
      final clusterLabel =
          marker.category == ArcRaidMapMarkerCategory.blueprintOpportunity &&
              labels.isNotEmpty
          ? labels.take(3).join(' + ')
          : '$totalCount nearby ${marker.category.label}s';
      final ids = nearby
          .expand(
            (item) => item.clusterMemberIds.isEmpty
                ? <String>[item.id]
                : item.clusterMemberIds,
          )
          .toSet()
          .toList(growable: false);
      final blueprintIds = nearby
          .expand((item) => item.blueprintIds)
          .toSet()
          .toList(growable: false);
      final prioritizedBlueprintIds = nearby
          .expand((item) => item.prioritizedBlueprintIds)
          .toSet()
          .toList(growable: false);
      final blueprintFindCounts = <String, int>{};
      final iconKeys = nearby
          .map((item) => item.iconKey?.trim())
          .whereType<String>()
          .where((item) => item.isNotEmpty)
          .toSet();
      for (final item in nearby) {
        for (final entry in item.blueprintFindCounts.entries) {
          blueprintFindCounts.update(
            entry.key,
            (value) => value + entry.value,
            ifAbsent: () => entry.value,
          );
        }
      }

      output.add(
        ArcRaidMapMarker(
          id: 'cluster_${marker.mapId}_${marker.layer.storageValue}_${marker.category.id}_${ids.join('_')}',
          mapId: marker.mapId,
          category: marker.category,
          label: clusterLabel,
          point: ArcNormalizedPoint(x: averageX, y: averageY),
          layer: marker.layer,
          payloadId: marker.payloadId,
          confidence: confidence,
          approximate: nearby.any((item) => item.approximate),
          count: totalCount,
          detail: labels.take(4).join(' • '),
          iconKey: iconKeys.length == 1 ? iconKeys.single : null,
          tags: nearby
              .expand((item) => item.tags)
              .toSet()
              .toList(growable: false),
          clusterMemberIds: ids,
          blueprintIds: blueprintIds,
          blueprintFindCounts: blueprintFindCounts,
          prioritizedBlueprintIds: prioritizedBlueprintIds,
        ),
      );
    }

    return output;
  }
}
