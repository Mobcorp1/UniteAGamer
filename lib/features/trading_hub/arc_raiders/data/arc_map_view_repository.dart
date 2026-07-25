import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

@immutable
class ArcMapViewSnapshot {
  const ArcMapViewSnapshot({
    required this.mapId,
    required this.layer,
    required this.matrixValues,
    required this.updatedAt,
  });

  final String mapId;
  final ArcRaidMapLayer layer;
  final List<double> matrixValues;
  final DateTime updatedAt;

  bool get hasValidMatrix =>
      matrixValues.length == 16 &&
      matrixValues.every((value) => value.isFinite);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'mapId': mapId,
      'layer': layer.storageValue,
      'matrixValues': matrixValues,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory ArcMapViewSnapshot.fromJson(Map<String, dynamic> json) {
    final rawMatrix = json['matrixValues'];
    final matrix = rawMatrix is Iterable
        ? rawMatrix
              .whereType<num>()
              .map((value) => value.toDouble())
              .toList(growable: false)
        : const <double>[];
    final layerName = json['layer']?.toString();
    final layer = ArcRaidMapLayer.values.firstWhere(
      (value) => value.storageValue == layerName,
      orElse: () => ArcRaidMapLayer.surface,
    );
    return ArcMapViewSnapshot(
      mapId: json['mapId']?.toString().trim() ?? '',
      layer: layer,
      matrixValues: matrix,
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

class ArcMapViewRepository {
  const ArcMapViewRepository();

  static const String _lastSelectionKey = 'arc_raid_map_view_last_selection_v1';
  static const String _snapshotPrefix = 'arc_raid_map_view_snapshot_v1';

  Future<ArcMapViewSnapshot?> loadLast() async {
    final preferences = await SharedPreferences.getInstance();
    final rawSelection = preferences.getString(_lastSelectionKey);
    if (rawSelection == null || rawSelection.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(rawSelection);
      if (decoded is! Map) return null;
      final mapId = decoded['mapId']?.toString().trim() ?? '';
      final layerName = decoded['layer']?.toString().trim() ?? '';
      final layer = ArcRaidMapLayer.values.firstWhere(
        (value) => value.storageValue == layerName,
        orElse: () => ArcRaidMapLayer.surface,
      );
      if (mapId.isEmpty) return null;
      return loadFor(mapId: mapId, layer: layer);
    } catch (_) {
      return null;
    }
  }

  Future<ArcMapViewSnapshot?> loadFor({
    required String mapId,
    required ArcRaidMapLayer layer,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_snapshotKey(mapId, layer));
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final snapshot = ArcMapViewSnapshot.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
      if (snapshot.mapId != mapId ||
          snapshot.layer != layer ||
          !snapshot.hasValidMatrix) {
        return null;
      }
      return snapshot;
    } catch (_) {
      return null;
    }
  }

  Future<void> save(ArcMapViewSnapshot snapshot) async {
    if (snapshot.mapId.trim().isEmpty || !snapshot.hasValidMatrix) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _snapshotKey(snapshot.mapId, snapshot.layer),
      jsonEncode(snapshot.toJson()),
    );
    await preferences.setString(
      _lastSelectionKey,
      jsonEncode(<String, dynamic>{
        'mapId': snapshot.mapId,
        'layer': snapshot.layer.storageValue,
      }),
    );
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    final keys = preferences
        .getKeys()
        .where(
          (key) =>
              key == _lastSelectionKey || key.startsWith('$_snapshotPrefix:'),
        )
        .toList(growable: false);
    for (final key in keys) {
      await preferences.remove(key);
    }
  }

  static String _snapshotKey(String mapId, ArcRaidMapLayer layer) {
    return '$_snapshotPrefix:${mapId.trim()}:${layer.storageValue}';
  }
}
