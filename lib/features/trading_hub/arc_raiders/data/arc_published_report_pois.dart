import '../models/arc_admin_map_marker.dart';
import 'arc_map_asset_registry.dart';

/// Named location choices, shared by the report form and persistence boundary.
class ArcPublishedReportPois {
  static List<ArcAdminMapMarker> forMap(
    String mapName,
    Iterable<ArcAdminMapMarker> markers,
  ) {
    final mapId = ArcMapAssetRegistry.canonicalMapIdFor(mapName);
    return markers
        .where(
          (marker) =>
              marker.mapId == mapId &&
              marker.isPublished &&
              marker.kind.isSeedDefinition &&
              marker.name.trim().isNotEmpty,
        )
        .toList()
      ..sort((a, b) {
        final name = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        return name == 0 ? a.id.compareTo(b.id) : name;
      });
  }
}
