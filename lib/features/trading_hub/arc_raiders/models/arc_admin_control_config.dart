class ArcAdminControlConfig {
  const ArcAdminControlConfig({
    this.featureFlags = const {},
    this.mapFlags = const {},
    this.rolloutPercent = 100,
    this.isMaintenanceMode = false,
    this.isReadOnlyMode = false,
    this.isBetaOnlyMode = false,
  });

  final Map<String, bool> featureFlags;
  final Map<String, bool> mapFlags;
  final int rolloutPercent;
  final bool isMaintenanceMode;
  final bool isReadOnlyMode;
  final bool isBetaOnlyMode;

  factory ArcAdminControlConfig.defaults() {
    return const ArcAdminControlConfig(
      featureFlags: {
        'raidIntelligence': true,
        'officialMapConditions': true,
        'communityIntel': true,
        'operations': true,
      },
      mapFlags: {'Blue Gate': true, 'Riven Tides': true},
      rolloutPercent: 100,
    );
  }

  factory ArcAdminControlConfig.fromDocument(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) {
      return ArcAdminControlConfig.defaults();
    }

    final featureFlags = <String, bool>{};
    final rawFeatureFlags = data['featureFlags'];
    if (rawFeatureFlags is Map) {
      for (final entry in rawFeatureFlags.entries) {
        if (entry.key is String && entry.value is bool) {
          featureFlags[entry.key as String] = entry.value as bool;
        }
      }
    }

    final mapFlags = <String, bool>{};
    final rawMapFlags = data['mapFlags'];
    if (rawMapFlags is Map) {
      for (final entry in rawMapFlags.entries) {
        if (entry.key is String && entry.value is bool) {
          mapFlags[entry.key as String] = entry.value as bool;
        }
      }
    }

    return ArcAdminControlConfig(
      featureFlags: featureFlags,
      mapFlags: mapFlags,
      rolloutPercent: _parseInt(data['rolloutPercent']) ?? 100,
      isMaintenanceMode: _parseBool(data['maintenanceMode']) ?? false,
      isReadOnlyMode: _parseBool(data['readOnlyMode']) ?? false,
      isBetaOnlyMode: _parseBool(data['betaOnlyMode']) ?? false,
    );
  }

  bool isFeatureEnabled(String feature) {
    if (featureFlags.containsKey(feature)) {
      return featureFlags[feature]!;
    }

    const defaults = <String, bool>{
      'raidIntelligence': true,
      'officialMapConditions': true,
      'communityIntel': true,
      'operations': true,
    };

    return defaults[feature] ?? true;
  }

  bool isMapEnabled(String mapName) {
    if (mapFlags.containsKey(mapName)) {
      return mapFlags[mapName]!;
    }

    const defaults = <String, bool>{'Blue Gate': true, 'Riven Tides': true};

    return defaults[mapName] ?? true;
  }

  ArcAdminControlConfig copyWith({
    Map<String, bool>? featureFlags,
    Map<String, bool>? mapFlags,
    int? rolloutPercent,
    bool? isMaintenanceMode,
    bool? isReadOnlyMode,
    bool? isBetaOnlyMode,
  }) {
    return ArcAdminControlConfig(
      featureFlags: featureFlags ?? this.featureFlags,
      mapFlags: mapFlags ?? this.mapFlags,
      rolloutPercent: rolloutPercent ?? this.rolloutPercent,
      isMaintenanceMode: isMaintenanceMode ?? this.isMaintenanceMode,
      isReadOnlyMode: isReadOnlyMode ?? this.isReadOnlyMode,
      isBetaOnlyMode: isBetaOnlyMode ?? this.isBetaOnlyMode,
    );
  }

  Map<String, dynamic> toDocument() {
    return {
      'featureFlags': featureFlags,
      'mapFlags': mapFlags,
      'rolloutPercent': rolloutPercent,
      'maintenanceMode': isMaintenanceMode,
      'readOnlyMode': isReadOnlyMode,
      'betaOnlyMode': isBetaOnlyMode,
    };
  }

  static int? _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static bool? _parseBool(Object? value) {
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return null;
  }
}
