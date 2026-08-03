import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

class ArcMapMarkerStackResolver {
  const ArcMapMarkerStackResolver();

  static const double defaultStackRadius = 0.012;

  List<ArcRaidMapMarker> stackFor({
    required ArcRaidMapMarker selected,
    required Iterable<ArcRaidMapMarker> markers,
    double radius = defaultStackRadius,
  }) {
    final stack = markers.where((marker) {
      return marker.enabled &&
          marker.mapId == selected.mapId &&
          marker.layer == selected.layer &&
          marker.point.distanceTo(selected.point) <= radius;
    }).toList();

    stack.sort((a, b) {
      if (a.id == selected.id) return -1;
      if (b.id == selected.id) return 1;
      final categoryCompare = a.category.label.compareTo(b.category.label);
      if (categoryCompare != 0) return categoryCompare;
      return a.label.compareTo(b.label);
    });

    return List<ArcRaidMapMarker>.unmodifiable(stack);
  }
}
