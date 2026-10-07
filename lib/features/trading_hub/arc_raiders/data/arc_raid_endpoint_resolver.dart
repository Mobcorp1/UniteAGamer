import '../models/arc_admin_map_marker.dart';
import '../models/arc_raid_intelligence_models.dart';
import 'arc_map_asset_registry.dart';

class ArcRaidEndpoints {
  const ArcRaidEndpoints({
    required this.spawns,
    required this.extractions,
    required this.hatches,
    required this.authoritativeSpawns,
    required this.authoritativeExtractions,
    this.aliases = const {},
  });
  final List<ArcRaidRouteStop> spawns;
  final List<ArcRaidRouteStop> extractions;
  final List<ArcRaidRouteStop> hatches;
  final bool authoritativeSpawns;
  final bool authoritativeExtractions;
  final Map<String, String> aliases;
  ArcRaidRouteStop? resolveSpawn(ArcRaidRouteStop saved) {
    if (!authoritativeSpawns &&
        saved.id == 'freeform_spawn' &&
        _validPoint(saved.point)) {
      return saved;
    }
    return _resolve(saved.id, spawns);
  }

  ArcRaidRouteStop? resolveExtraction(
    ArcRaidRouteStop saved, {
    bool hatch = false,
  }) => _resolve(saved.id, hatch ? hatches : extractions);
  ArcRaidRouteStop? _resolve(String id, List<ArcRaidRouteStop> options) {
    final resolved = aliases[id] ?? id;
    for (final option in options) {
      if (option.id == resolved) return option;
    }
    return null;
  }

  static bool _validPoint(ArcNormalizedPoint p) =>
      p.x.isFinite &&
      p.y.isFinite &&
      p.x >= 0 &&
      p.x <= 1 &&
      p.y >= 0 &&
      p.y <= 1;
}

/// Adapts published endpoint records without Firestore or route-engine coupling.
/// ARC enemy spawns are deliberately never treated as Raider/player spawns.
class ArcRaidEndpointResolver {
  const ArcRaidEndpointResolver();
  ArcRaidEndpoints resolve({
    required ArcRaidMap seedMap,
    required ArcRaidMapLayer layer,
    required Iterable<ArcAdminMapMarker> markers,
  }) {
    final live =
        markers
            .where(
              (m) =>
                  m.isPublished &&
                  m.isLive &&
                  m.layer == layer &&
                  (ArcMapAssetRegistry.canonicalMapIdFor(m.mapId) ?? m.mapId) ==
                      seedMap.id &&
                  ArcRaidEndpoints._validPoint(m.point),
            )
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    final spawns = live
        .where(
          (m) =>
              m.kind == ArcAdminMapMarkerKind.poi &&
              m.subtypeId == 'player_spawn',
        )
        .toList();
    final extractions = live
        .where((m) => m.kind == ArcAdminMapMarkerKind.extraction)
        .toList();
    final hatches = live
        .where((m) => m.kind == ArcAdminMapMarkerKind.raiderHatch)
        .toList();
    final aliases = <String, String>{};
    for (final m in [...extractions, ...hatches]) {
      final prefix = m.kind == ArcAdminMapMarkerKind.extraction
          ? 'extraction'
          : 'hatch';
      aliases['admin_${prefix}_${m.id}'] = m.id;
      final seed = m.seedReferenceId;
      if (seed != null &&
          seed.isNotEmpty &&
          live.where((other) => other.seedReferenceId == seed).length == 1) {
        aliases[seed] = m.id;
      }
    }
    ArcRaidRouteStop stop(ArcAdminMapMarker m) => ArcRaidRouteStop(
      id: m.id,
      label: m.name.trim().isEmpty
          ? '${m.kind == ArcAdminMapMarkerKind.poi ? 'Player Spawn' : m.kind.label} (${m.id})'
          : m.name,
      point: m.point,
      markerId: m.id,
      order: 0,
      reason:
          'Published administrator-authored endpoint. Confirm conditions in-game.',
    );
    // Legacy seed endpoints have surface coordinates, not underground geometry.
    final surface = layer == ArcRaidMapLayer.surface;
    return ArcRaidEndpoints(
      authoritativeSpawns: spawns.isNotEmpty,
      authoritativeExtractions: extractions.isNotEmpty,
      aliases: aliases,
      spawns: spawns.isNotEmpty
          ? spawns.map(stop).toList()
          : [
              if (surface)
                for (final s in seedMap.spawnRegions)
                  ArcRaidRouteStop(
                    id: s.id,
                    label: s.name,
                    point: s.center,
                    markerId: s.id,
                    order: 0,
                    reason: 'Schematic spawn fallback; approximate.',
                  ),
            ],
      extractions: extractions.isNotEmpty
          ? extractions.map(stop).toList()
          : [
              if (surface)
                for (final e in seedMap.extractions)
                  ArcRaidRouteStop(
                    id: e.id,
                    label: e.name,
                    point: e.point,
                    markerId: e.id,
                    order: 0,
                    reason:
                        'Catalogue extraction fallback. Confirm availability in-game.',
                  ),
            ],
      hatches: hatches.isNotEmpty
          ? hatches.map(stop).toList()
          : [
              if (surface)
                for (final h in seedMap.hatches)
                  ArcRaidRouteStop(
                    id: h.id,
                    label: h.name,
                    point: h.point,
                    markerId: h.id,
                    order: 0,
                    reason: 'Raider Hatch requires a confirmed key.',
                  ),
            ],
    );
  }

  static String nextPlayerSpawnName(Iterable<String> existingNames) {
    final names = existingNames.map((n) => n.trim().toLowerCase()).toSet();
    var index = 1;
    while (names.contains('player spawn $index')) {
      index++;
    }
    return 'Player Spawn $index';
  }
}
