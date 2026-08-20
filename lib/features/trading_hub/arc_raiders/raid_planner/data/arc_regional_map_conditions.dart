import 'dart:convert';

import 'package:http/http.dart' as http;

enum ArcServerRegion { europe, northAmerica, brazil, eastAsia, oceania }

extension ArcServerRegionLabel on ArcServerRegion {
  String get key {
    switch (this) {
      case ArcServerRegion.europe:
        return 'europe';
      case ArcServerRegion.northAmerica:
        return 'north-america';
      case ArcServerRegion.brazil:
        return 'brazil';
      case ArcServerRegion.eastAsia:
        return 'east-asia';
      case ArcServerRegion.oceania:
        return 'oceania';
    }
  }

  String get label {
    switch (this) {
      case ArcServerRegion.europe:
        return 'Europe';
      case ArcServerRegion.northAmerica:
        return 'North America';
      case ArcServerRegion.brazil:
        return 'Brazil';
      case ArcServerRegion.eastAsia:
        return 'East Asia';
      case ArcServerRegion.oceania:
        return 'Oceania';
    }
  }
}

class ArcRegionalConditionWindow {
  final DateTime startUtc;
  final DateTime endUtc;

  const ArcRegionalConditionWindow({
    required this.startUtc,
    required this.endUtc,
  });

  bool isActiveAt(DateTime utcNow) =>
      !utcNow.isBefore(startUtc) && utcNow.isBefore(endUtc);
}

class ArcRegionalMapConditionEntry {
  final String conditionName;
  final String mapDisplayName;
  final Duration duration;
  final Map<ArcServerRegion, ArcRegionalConditionWindow> regionWindows;

  const ArcRegionalMapConditionEntry({
    required this.conditionName,
    required this.mapDisplayName,
    required this.duration,
    required this.regionWindows,
  });

  ArcRegionalConditionWindow? windowFor(ArcServerRegion region) =>
      regionWindows[region];

  factory ArcRegionalMapConditionEntry.fromOfficialMap(
    Map<String, dynamic> map,
  ) {
    final startTimestamp = (map['startTimestamp'] as num?)?.toInt();
    final endTimestamp = (map['endTimestamp'] as num?)?.toInt();
    if (startTimestamp == null || endTimestamp == null) {
      throw const FormatException(
        'Map Condition entry is missing Europe timestamps.',
      );
    }

    final windows = <ArcServerRegion, ArcRegionalConditionWindow>{
      ArcServerRegion.europe: ArcRegionalConditionWindow(
        startUtc: DateTime.fromMillisecondsSinceEpoch(
          startTimestamp,
          isUtc: true,
        ),
        endUtc: DateTime.fromMillisecondsSinceEpoch(endTimestamp, isUtc: true),
      ),
    };

    final regional = map['regionTimestamps'];
    if (regional is Map) {
      for (final region in ArcServerRegion.values.where(
        (item) => item != ArcServerRegion.europe,
      )) {
        final raw = regional[region.key];
        if (raw is List && raw.length >= 2) {
          final start = (raw[0] as num?)?.toInt();
          final end = (raw[1] as num?)?.toInt();
          if (start != null && end != null) {
            windows[region] = ArcRegionalConditionWindow(
              startUtc: DateTime.fromMillisecondsSinceEpoch(start, isUtc: true),
              endUtc: DateTime.fromMillisecondsSinceEpoch(end, isUtc: true),
            );
          }
        }
      }
    }

    return ArcRegionalMapConditionEntry(
      conditionName: (map['conditionName'] ?? '').toString().trim(),
      mapDisplayName: (map['mapDisplayName'] ?? '').toString().trim(),
      duration: Duration(
        seconds:
            (map['durationInSeconds'] as num?)?.toInt() ??
            ((endTimestamp - startTimestamp) ~/ 1000),
      ),
      regionWindows: windows,
    );
  }
}

enum ArcMapConditionsSource { officialLive, officialCapturedFallback }

class ArcRegionalMapConditionsSnapshot {
  final List<ArcRegionalMapConditionEntry> entries;
  final DateTime serverNowUtc;
  final DateTime loadedAtUtc;
  final ArcMapConditionsSource source;
  final String? warning;

  const ArcRegionalMapConditionsSnapshot({
    required this.entries,
    required this.serverNowUtc,
    required this.loadedAtUtc,
    required this.source,
    this.warning,
  });

  bool get isOfficialLive => source == ArcMapConditionsSource.officialLive;

  String get sourceLabel => isOfficialLive
      ? 'Official ARC Raiders regional schedule'
      : 'Official captured schedule fallback';
}

class ArcRegionalMapConditionsParser {
  static ArcRegionalMapConditionsSnapshot parseOfficialPage(
    String html, {
    DateTime? loadedAtUtc,
  }) {
    final escaped = RegExp(
      r'\\\"liveEntries\\\":\[(.*?)\],\\\"lookAheadMs\\\"',
      dotAll: true,
    ).firstMatch(html);

    final plain = RegExp(
      r'"liveEntries":\[(.*?)\],"lookAheadMs"',
      dotAll: true,
    ).firstMatch(html);

    final match = escaped ?? plain;
    if (match == null) {
      throw const FormatException(
        'Official ARC Raiders page did not expose liveEntries.',
      );
    }

    var payload = '[${match.group(1)!}]';
    if (escaped != null) {
      payload = payload.replaceAll(r'\"', '"');
    }

    final decoded = jsonDecode(payload);
    if (decoded is! List) {
      throw const FormatException(
        'Official liveEntries payload is not a list.',
      );
    }

    final entries = decoded
        .whereType<Map>()
        .map(
          (item) => ArcRegionalMapConditionEntry.fromOfficialMap(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .where(
          (entry) =>
              entry.conditionName.isNotEmpty && entry.mapDisplayName.isNotEmpty,
        )
        .toList(growable: false);

    if (entries.isEmpty) {
      throw const FormatException('Official liveEntries payload was empty.');
    }

    final serverMatch =
        RegExp(r'\\\"serverNow\\\":(\d+)').firstMatch(html) ??
        RegExp(r'"serverNow":(\d+)').firstMatch(html);
    final serverNowMs = int.tryParse(serverMatch?.group(1) ?? '');

    return ArcRegionalMapConditionsSnapshot(
      entries: entries,
      serverNowUtc: serverNowMs == null
          ? DateTime.now().toUtc()
          : DateTime.fromMillisecondsSinceEpoch(serverNowMs, isUtc: true),
      loadedAtUtc: loadedAtUtc ?? DateTime.now().toUtc(),
      source: ArcMapConditionsSource.officialLive,
    );
  }
}

class ArcRegionalMapConditionsService {
  static const _officialUrl = 'https://arcraiders.com/map-conditions';
  static const _cacheFor = Duration(minutes: 10);

  static ArcRegionalMapConditionsSnapshot? _cached;

  static Future<ArcRegionalMapConditionsSnapshot> load({
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now().toUtc();
    final cached = _cached;
    if (!forceRefresh &&
        cached != null &&
        now.difference(cached.loadedAtUtc) < _cacheFor) {
      return cached;
    }

    try {
      final response = await http
          .get(
            Uri.parse(_officialUrl),
            headers: const {'Accept': 'text/html,application/xhtml+xml'},
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final parsed = ArcRegionalMapConditionsParser.parseOfficialPage(
          response.body,
          loadedAtUtc: now,
        );
        _cached = parsed;
        return parsed;
      }
      throw StateError('ARC Raiders returned HTTP ${response.statusCode}.');
    } catch (error) {
      final fallback = _capturedFallback(now, error.toString());
      _cached = fallback;
      return fallback;
    }
  }

  static ArcRegionalMapConditionsSnapshot _capturedFallback(
    DateTime loadedAtUtc,
    String warning,
  ) {
    final raw = jsonDecode(_officialCapturedEntriesJson);
    final entries = (raw as List)
        .whereType<Map>()
        .map(
          (item) => ArcRegionalMapConditionEntry.fromOfficialMap(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList(growable: false);

    return ArcRegionalMapConditionsSnapshot(
      entries: entries,
      serverNowUtc: DateTime.fromMillisecondsSinceEpoch(
        1787176305742,
        isUtc: true,
      ),
      loadedAtUtc: loadedAtUtc,
      source: ArcMapConditionsSource.officialCapturedFallback,
      warning: warning,
    );
  }

  static const String _officialCapturedEntriesJson =
      r'''[{"conditionName":"Uncovered Caches","mapDisplayName":"Buried City","durationInSeconds":3600,"startTimestamp":1787173200000,"endTimestamp":1787176800000,"regionTimestamps":{"north-america":[1787198400000,1787202000000],"brazil":[1787194800000,1787198400000],"east-asia":[1787155200000,1787158800000],"oceania":[1787140800000,1787144400000]}},{"conditionName":"Beachcombing","mapDisplayName":"Riven Tides","durationInSeconds":3600,"startTimestamp":1787173200000,"endTimestamp":1787176800000,"regionTimestamps":{"north-america":[1787198400000,1787202000000],"brazil":[1787194800000,1787198400000],"east-asia":[1787155200000,1787158800000],"oceania":[1787140800000,1787144400000]}},{"conditionName":"Night Raid","mapDisplayName":"The Blue Gate","durationInSeconds":3600,"startTimestamp":1787173200000,"endTimestamp":1787176800000,"regionTimestamps":{"north-america":[1787198400000,1787202000000],"brazil":[1787194800000,1787198400000],"east-asia":[1787155200000,1787158800000],"oceania":[1787140800000,1787144400000]}},{"conditionName":"Electromagnetic Storm","mapDisplayName":"Dam Battlegrounds","durationInSeconds":3600,"startTimestamp":1787173200000,"endTimestamp":1787176800000,"regionTimestamps":{"north-america":[1787198400000,1787202000000],"brazil":[1787194800000,1787198400000],"east-asia":[1787155200000,1787158800000],"oceania":[1787140800000,1787144400000]}},{"conditionName":"Bird City","mapDisplayName":"Buried City","durationInSeconds":3600,"startTimestamp":1787176800000,"endTimestamp":1787180400000,"regionTimestamps":{"north-america":[1787202000000,1787205600000],"brazil":[1787198400000,1787202000000],"east-asia":[1787158800000,1787162400000],"oceania":[1787144400000,1787148000000]}},{"conditionName":"Night Raid","mapDisplayName":"Stella Montis","durationInSeconds":3600,"startTimestamp":1787176800000,"endTimestamp":1787180400000,"regionTimestamps":{"north-america":[1787202000000,1787205600000],"brazil":[1787198400000,1787202000000],"east-asia":[1787158800000,1787162400000],"oceania":[1787144400000,1787148000000]}},{"conditionName":"Close Scrutiny","mapDisplayName":"Spaceport","durationInSeconds":3600,"startTimestamp":1787176800000,"endTimestamp":1787180400000,"regionTimestamps":{"north-america":[1787202000000,1787205600000],"brazil":[1787198400000,1787202000000],"east-asia":[1787158800000,1787162400000],"oceania":[1787144400000,1787148000000]}},{"conditionName":"Harvester","mapDisplayName":"The Blue Gate","durationInSeconds":3600,"startTimestamp":1787176800000,"endTimestamp":1787180400000,"regionTimestamps":{"north-america":[1787202000000,1787205600000],"brazil":[1787198400000,1787202000000],"east-asia":[1787158800000,1787162400000],"oceania":[1787144400000,1787148000000]}},{"conditionName":"Uncovered Caches","mapDisplayName":"Buried City","durationInSeconds":3600,"startTimestamp":1787180400000,"endTimestamp":1787184000000,"regionTimestamps":{"north-america":[1787205600000,1787209200000],"brazil":[1787202000000,1787205600000],"east-asia":[1787162400000,1787166000000],"oceania":[1787148000000,1787151600000]}},{"conditionName":"Beachcombing","mapDisplayName":"Riven Tides","durationInSeconds":3600,"startTimestamp":1787180400000,"endTimestamp":1787184000000,"regionTimestamps":{"north-america":[1787205600000,1787209200000],"brazil":[1787202000000,1787205600000],"east-asia":[1787162400000,1787166000000],"oceania":[1787148000000,1787151600000]}},{"conditionName":"Night Raid","mapDisplayName":"The Blue Gate","durationInSeconds":3600,"startTimestamp":1787180400000,"endTimestamp":1787184000000,"regionTimestamps":{"north-america":[1787205600000,1787209200000],"brazil":[1787202000000,1787205600000],"east-asia":[1787162400000,1787166000000],"oceania":[1787148000000,1787151600000]}},{"conditionName":"Night Raid","mapDisplayName":"Stella Montis","durationInSeconds":3600,"startTimestamp":1787184000000,"endTimestamp":1787187600000,"regionTimestamps":{"north-america":[1787209200000,1787212800000],"brazil":[1787205600000,1787209200000],"east-asia":[1787166000000,1787169600000],"oceania":[1787151600000,1787155200000]}},{"conditionName":"Prospecting Probes","mapDisplayName":"Riven Tides","durationInSeconds":3600,"startTimestamp":1787184000000,"endTimestamp":1787187600000,"regionTimestamps":{"north-america":[1787209200000,1787212800000],"brazil":[1787205600000,1787209200000],"east-asia":[1787166000000,1787169600000],"oceania":[1787151600000,1787155200000]}},{"conditionName":"Harvester","mapDisplayName":"Spaceport","durationInSeconds":3600,"startTimestamp":1787184000000,"endTimestamp":1787187600000,"regionTimestamps":{"north-america":[1787209200000,1787212800000],"brazil":[1787205600000,1787209200000],"east-asia":[1787166000000,1787169600000],"oceania":[1787151600000,1787155200000]}},{"conditionName":"Uncovered Caches","mapDisplayName":"Spaceport","durationInSeconds":3600,"startTimestamp":1787187600000,"endTimestamp":1787191200000,"regionTimestamps":{"north-america":[1787212800000,1787216400000],"brazil":[1787209200000,1787212800000],"east-asia":[1787169600000,1787173200000],"oceania":[1787155200000,1787158800000]}},{"conditionName":"Night Raid","mapDisplayName":"The Blue Gate","durationInSeconds":3600,"startTimestamp":1787187600000,"endTimestamp":1787191200000,"regionTimestamps":{"north-america":[1787212800000,1787216400000],"brazil":[1787209200000,1787212800000],"east-asia":[1787169600000,1787173200000],"oceania":[1787155200000,1787158800000]}},{"conditionName":"Matriarch","mapDisplayName":"Dam Battlegrounds","durationInSeconds":3600,"startTimestamp":1787187600000,"endTimestamp":1787191200000,"regionTimestamps":{"north-america":[1787212800000,1787216400000],"brazil":[1787209200000,1787212800000],"east-asia":[1787169600000,1787173200000],"oceania":[1787155200000,1787158800000]}},{"conditionName":"Bird City","mapDisplayName":"Buried City","durationInSeconds":3600,"startTimestamp":1787191200000,"endTimestamp":1787194800000,"regionTimestamps":{"north-america":[1787216400000,1787220000000],"brazil":[1787212800000,1787216400000],"east-asia":[1787173200000,1787176800000],"oceania":[1787158800000,1787162400000]}},{"conditionName":"Night Raid","mapDisplayName":"Stella Montis","durationInSeconds":3600,"startTimestamp":1787191200000,"endTimestamp":1787194800000,"regionTimestamps":{"north-america":[1787216400000,1787220000000],"brazil":[1787212800000,1787216400000],"east-asia":[1787173200000,1787176800000],"oceania":[1787158800000,1787162400000]}},{"conditionName":"Beachcombing","mapDisplayName":"Riven Tides","durationInSeconds":3600,"startTimestamp":1787194800000,"endTimestamp":1787198400000,"regionTimestamps":{"north-america":[1787220000000,1787223600000],"brazil":[1787216400000,1787220000000],"east-asia":[1787176800000,1787180400000],"oceania":[1787162400000,1787166000000]}},{"conditionName":"Night Raid","mapDisplayName":"The Blue Gate","durationInSeconds":3600,"startTimestamp":1787194800000,"endTimestamp":1787198400000,"regionTimestamps":{"north-america":[1787220000000,1787223600000],"brazil":[1787216400000,1787220000000],"east-asia":[1787176800000,1787180400000],"oceania":[1787162400000,1787166000000]}},{"conditionName":"Matriarch","mapDisplayName":"Dam Battlegrounds","durationInSeconds":3600,"startTimestamp":1787194800000,"endTimestamp":1787198400000,"regionTimestamps":{"north-america":[1787220000000,1787223600000],"brazil":[1787216400000,1787220000000],"east-asia":[1787176800000,1787180400000],"oceania":[1787162400000,1787166000000]}},{"conditionName":"Night Raid","mapDisplayName":"Stella Montis","durationInSeconds":3600,"startTimestamp":1787198400000,"endTimestamp":1787202000000,"regionTimestamps":{"north-america":[1787223600000,1787227200000],"brazil":[1787220000000,1787223600000],"east-asia":[1787180400000,1787184000000],"oceania":[1787166000000,1787169600000]}},{"conditionName":"Launch Tower Loot","mapDisplayName":"Spaceport","durationInSeconds":3600,"startTimestamp":1787198400000,"endTimestamp":1787202000000,"regionTimestamps":{"north-america":[1787223600000,1787227200000],"brazil":[1787220000000,1787223600000],"east-asia":[1787180400000,1787184000000],"oceania":[1787166000000,1787169600000]}},{"conditionName":"Harvester","mapDisplayName":"Dam Battlegrounds","durationInSeconds":3600,"startTimestamp":1787198400000,"endTimestamp":1787202000000,"regionTimestamps":{"north-america":[1787223600000,1787227200000],"brazil":[1787220000000,1787223600000],"east-asia":[1787180400000,1787184000000],"oceania":[1787166000000,1787169600000]}},{"conditionName":"Uncovered Caches","mapDisplayName":"Buried City","durationInSeconds":3600,"startTimestamp":1787202000000,"endTimestamp":1787205600000,"regionTimestamps":{"north-america":[1787227200000,1787230800000],"brazil":[1787223600000,1787227200000],"east-asia":[1787184000000,1787187600000],"oceania":[1787169600000,1787173200000]}},{"conditionName":"Night Raid","mapDisplayName":"Spaceport","durationInSeconds":3600,"startTimestamp":1787202000000,"endTimestamp":1787205600000,"regionTimestamps":{"north-america":[1787227200000,1787230800000],"brazil":[1787223600000,1787227200000],"east-asia":[1787184000000,1787187600000],"oceania":[1787169600000,1787173200000]}},{"conditionName":"Matriarch","mapDisplayName":"The Blue Gate","durationInSeconds":3600,"startTimestamp":1787202000000,"endTimestamp":1787205600000,"regionTimestamps":{"north-america":[1787227200000,1787230800000],"brazil":[1787223600000,1787227200000],"east-asia":[1787184000000,1787187600000],"oceania":[1787169600000,1787173200000]}},{"conditionName":"Bird City","mapDisplayName":"Buried City","durationInSeconds":3600,"startTimestamp":1787205600000,"endTimestamp":1787209200000,"regionTimestamps":{"north-america":[1787230800000,1787234400000],"brazil":[1787227200000,1787230800000],"east-asia":[1787187600000,1787191200000],"oceania":[1787173200000,1787176800000]}},{"conditionName":"Night Raid","mapDisplayName":"Stella Montis","durationInSeconds":3600,"startTimestamp":1787205600000,"endTimestamp":1787209200000,"regionTimestamps":{"north-america":[1787230800000,1787234400000],"brazil":[1787227200000,1787230800000],"east-asia":[1787187600000,1787191200000],"oceania":[1787173200000,1787176800000]}},{"conditionName":"Prospecting Probes","mapDisplayName":"Riven Tides","durationInSeconds":3600,"startTimestamp":1787205600000,"endTimestamp":1787209200000,"regionTimestamps":{"north-america":[1787230800000,1787234400000],"brazil":[1787227200000,1787230800000],"east-asia":[1787187600000,1787191200000],"oceania":[1787173200000,1787176800000]}},{"conditionName":"Beachcombing","mapDisplayName":"Riven Tides","durationInSeconds":3600,"startTimestamp":1787209200000,"endTimestamp":1787212800000,"regionTimestamps":{"north-america":[1787234400000,1787238000000],"brazil":[1787230800000,1787234400000],"east-asia":[1787191200000,1787194800000],"oceania":[1787176800000,1787180400000]}},{"conditionName":"Uncovered Caches","mapDisplayName":"Spaceport","durationInSeconds":3600,"startTimestamp":1787209200000,"endTimestamp":1787212800000,"regionTimestamps":{"north-america":[1787234400000,1787238000000],"brazil":[1787230800000,1787234400000],"east-asia":[1787191200000,1787194800000],"oceania":[1787176800000,1787180400000]}},{"conditionName":"Night Raid","mapDisplayName":"Dam Battlegrounds","durationInSeconds":3600,"startTimestamp":1787209200000,"endTimestamp":1787212800000,"regionTimestamps":{"north-america":[1787234400000,1787238000000],"brazil":[1787230800000,1787234400000],"east-asia":[1787191200000,1787194800000],"oceania":[1787176800000,1787180400000]}},{"conditionName":"Prospecting Probes","mapDisplayName":"Buried City","durationInSeconds":3600,"startTimestamp":1787212800000,"endTimestamp":1787216400000,"regionTimestamps":{"north-america":[1787238000000,1787241600000],"brazil":[1787234400000,1787238000000],"east-asia":[1787194800000,1787198400000],"oceania":[1787180400000,1787184000000]}},{"conditionName":"Night Raid","mapDisplayName":"Stella Montis","durationInSeconds":3600,"startTimestamp":1787212800000,"endTimestamp":1787216400000,"regionTimestamps":{"north-america":[1787238000000,1787241600000],"brazil":[1787234400000,1787238000000],"east-asia":[1787194800000,1787198400000],"oceania":[1787180400000,1787184000000]}},{"conditionName":"Harvester","mapDisplayName":"The Blue Gate","durationInSeconds":3600,"startTimestamp":1787212800000,"endTimestamp":1787216400000,"regionTimestamps":{"north-america":[1787238000000,1787241600000],"brazil":[1787234400000,1787238000000],"east-asia":[1787194800000,1787198400000],"oceania":[1787180400000,1787184000000]}},{"conditionName":"Beachcombing","mapDisplayName":"Riven Tides","durationInSeconds":3600,"startTimestamp":1787216400000,"endTimestamp":1787220000000,"regionTimestamps":{"north-america":[1787241600000,1787245200000],"brazil":[1787238000000,1787241600000],"east-asia":[1787198400000,1787202000000],"oceania":[1787184000000,1787187600000]}},{"conditionName":"Night Raid","mapDisplayName":"Riven Tides","durationInSeconds":3600,"startTimestamp":1787216400000,"endTimestamp":1787220000000,"regionTimestamps":{"north-america":[1787241600000,1787245200000],"brazil":[1787238000000,1787241600000],"east-asia":[1787198400000,1787202000000],"oceania":[1787184000000,1787187600000]}},{"conditionName":"Matriarch","mapDisplayName":"Spaceport","durationInSeconds":3600,"startTimestamp":1787216400000,"endTimestamp":1787220000000,"regionTimestamps":{"north-america":[1787241600000,1787245200000],"brazil":[1787238000000,1787241600000],"east-asia":[1787198400000,1787202000000],"oceania":[1787184000000,1787187600000]}},{"conditionName":"Bird City","mapDisplayName":"Buried City","durationInSeconds":3600,"startTimestamp":1787220000000,"endTimestamp":1787223600000,"regionTimestamps":{"north-america":[1787245200000,1787248800000],"brazil":[1787241600000,1787245200000],"east-asia":[1787202000000,1787205600000],"oceania":[1787187600000,1787191200000]}},{"conditionName":"Night Raid","mapDisplayName":"Stella Montis","durationInSeconds":3600,"startTimestamp":1787220000000,"endTimestamp":1787223600000,"regionTimestamps":{"north-america":[1787245200000,1787248800000],"brazil":[1787241600000,1787245200000],"east-asia":[1787202000000,1787205600000],"oceania":[1787187600000,1787191200000]}},{"conditionName":"Uncovered Caches","mapDisplayName":"The Blue Gate","durationInSeconds":3600,"startTimestamp":1787220000000,"endTimestamp":1787223600000,"regionTimestamps":{"north-america":[1787245200000,1787248800000],"brazil":[1787241600000,1787245200000],"east-asia":[1787202000000,1787205600000],"oceania":[1787187600000,1787191200000]}},{"conditionName":"Locked Gate","mapDisplayName":"The Blue Gate","durationInSeconds":3600,"startTimestamp":1787220000000,"endTimestamp":1787223600000,"regionTimestamps":{"north-america":[1787245200000,1787248800000],"brazil":[1787241600000,1787245200000],"east-asia":[1787202000000,1787205600000],"oceania":[1787187600000,1787191200000]}},{"conditionName":"Prospecting Probes","mapDisplayName":"Buried City","durationInSeconds":3600,"startTimestamp":1787223600000,"endTimestamp":1787227200000,"regionTimestamps":{"north-america":[1787248800000,1787252400000],"brazil":[1787245200000,1787248800000],"east-asia":[1787205600000,1787209200000],"oceania":[1787191200000,1787194800000]}},{"conditionName":"Night Raid","mapDisplayName":"Riven Tides","durationInSeconds":3600,"startTimestamp":1787223600000,"endTimestamp":1787227200000,"regionTimestamps":{"north-america":[1787248800000,1787252400000],"brazil":[1787245200000,1787248800000],"east-asia":[1787205600000,1787209200000],"oceania":[1787191200000,1787194800000]}},{"conditionName":"Close Scrutiny","mapDisplayName":"Spaceport","durationInSeconds":3600,"startTimestamp":1787223600000,"endTimestamp":1787227200000,"regionTimestamps":{"north-america":[1787248800000,1787252400000],"brazil":[1787245200000,1787248800000],"east-asia":[1787205600000,1787209200000],"oceania":[1787191200000,1787194800000]}},{"conditionName":"Night Raid","mapDisplayName":"Stella Montis","durationInSeconds":3600,"startTimestamp":1787227200000,"endTimestamp":1787230800000,"regionTimestamps":{"north-america":[1787252400000,1787256000000],"brazil":[1787248800000,1787252400000],"east-asia":[1787209200000,1787212800000],"oceania":[1787194800000,1787198400000]}},{"conditionName":"Prospecting Probes","mapDisplayName":"Riven Tides","durationInSeconds":3600,"startTimestamp":1787227200000,"endTimestamp":1787230800000,"regionTimestamps":{"north-america":[1787252400000,1787256000000],"brazil":[1787248800000,1787252400000],"east-asia":[1787209200000,1787212800000],"oceania":[1787194800000,1787198400000]}},{"conditionName":"Hurricane","mapDisplayName":"The Blue Gate","durationInSeconds":3600,"startTimestamp":1787227200000,"endTimestamp":1787230800000,"regionTimestamps":{"north-america":[1787252400000,1787256000000],"brazil":[1787248800000,1787252400000],"east-asia":[1787209200000,1787212800000],"oceania":[1787194800000,1787198400000]}},{"conditionName":"Harvester","mapDisplayName":"Dam Battlegrounds","durationInSeconds":3600,"startTimestamp":1787227200000,"endTimestamp":1787230800000,"regionTimestamps":{"north-america":[1787252400000,1787256000000],"brazil":[1787248800000,1787252400000],"east-asia":[1787209200000,1787212800000],"oceania":[1787194800000,1787198400000]}},{"conditionName":"Matriarch","mapDisplayName":"Spaceport","durationInSeconds":3600,"startTimestamp":1787230800000,"endTimestamp":1787234400000,"regionTimestamps":{"north-america":[1787256000000,1787259600000],"brazil":[1787252400000,1787256000000],"east-asia":[1787212800000,1787216400000],"oceania":[1787198400000,1787202000000]}},{"conditionName":"Hidden Bunker","mapDisplayName":"Spaceport","durationInSeconds":3600,"startTimestamp":1787230800000,"endTimestamp":1787234400000,"regionTimestamps":{"north-america":[1787256000000,1787259600000],"brazil":[1787252400000,1787256000000],"east-asia":[1787212800000,1787216400000],"oceania":[1787198400000,1787202000000]}},{"conditionName":"Night Raid","mapDisplayName":"The Blue Gate","durationInSeconds":3600,"startTimestamp":1787230800000,"endTimestamp":1787234400000,"regionTimestamps":{"north-america":[1787256000000,1787259600000],"brazil":[1787252400000,1787256000000],"east-asia":[1787212800000,1787216400000],"oceania":[1787198400000,1787202000000]}},{"conditionName":"Bird City","mapDisplayName":"Buried City","durationInSeconds":3600,"startTimestamp":1787234400000,"endTimestamp":1787238000000,"regionTimestamps":{"north-america":[1787259600000,1787263200000],"brazil":[1787256000000,1787259600000],"east-asia":[1787216400000,1787220000000],"oceania":[1787202000000,1787205600000]}},{"conditionName":"Night Raid","mapDisplayName":"Stella Montis","durationInSeconds":3600,"startTimestamp":1787234400000,"endTimestamp":1787238000000,"regionTimestamps":{"north-america":[1787259600000,1787263200000],"brazil":[1787256000000,1787259600000],"east-asia":[1787216400000,1787220000000],"oceania":[1787202000000,1787205600000]}},{"conditionName":"Locked Gate","mapDisplayName":"The Blue Gate","durationInSeconds":3600,"startTimestamp":1787234400000,"endTimestamp":1787238000000,"regionTimestamps":{"north-america":[1787259600000,1787263200000],"brazil":[1787256000000,1787259600000],"east-asia":[1787216400000,1787220000000],"oceania":[1787202000000,1787205600000]}},{"conditionName":"Beachcombing","mapDisplayName":"Riven Tides","durationInSeconds":3600,"startTimestamp":1787238000000,"endTimestamp":1787241600000,"regionTimestamps":{"north-america":[1787263200000,1787266800000],"brazil":[1787259600000,1787263200000],"east-asia":[1787220000000,1787223600000],"oceania":[1787205600000,1787209200000]}},{"conditionName":"Hidden Bunker","mapDisplayName":"Spaceport","durationInSeconds":3600,"startTimestamp":1787238000000,"endTimestamp":1787241600000,"regionTimestamps":{"north-america":[1787263200000,1787266800000],"brazil":[1787259600000,1787263200000],"east-asia":[1787220000000,1787223600000],"oceania":[1787205600000,1787209200000]}},{"conditionName":"Matriarch","mapDisplayName":"Dam Battlegrounds","durationInSeconds":3600,"startTimestamp":1787238000000,"endTimestamp":1787241600000,"regionTimestamps":{"north-america":[1787263200000,1787266800000],"brazil":[1787259600000,1787263200000],"east-asia":[1787220000000,1787223600000],"oceania":[1787205600000,1787209200000]}},{"conditionName":"Night Raid","mapDisplayName":"Dam Battlegrounds","durationInSeconds":3600,"startTimestamp":1787238000000,"endTimestamp":1787241600000,"regionTimestamps":{"north-america":[1787263200000,1787266800000],"brazil":[1787259600000,1787263200000],"east-asia":[1787220000000,1787223600000],"oceania":[1787205600000,1787209200000]}},{"conditionName":"Night Raid","mapDisplayName":"Stella Montis","durationInSeconds":3600,"startTimestamp":1787241600000,"endTimestamp":1787245200000,"regionTimestamps":{"north-america":[1787266800000,1787270400000],"brazil":[1787263200000,1787266800000],"east-asia":[1787223600000,1787227200000],"oceania":[1787209200000,1787212800000]}},{"conditionName":"Harvester","mapDisplayName":"Spaceport","durationInSeconds":3600,"startTimestamp":1787241600000,"endTimestamp":1787245200000,"regionTimestamps":{"north-america":[1787266800000,1787270400000],"brazil":[1787263200000,1787266800000],"east-asia":[1787223600000,1787227200000],"oceania":[1787209200000,1787212800000]}},{"conditionName":"Electromagnetic Storm","mapDisplayName":"The Blue Gate","durationInSeconds":3600,"startTimestamp":1787241600000,"endTimestamp":1787245200000,"regionTimestamps":{"north-america":[1787266800000,1787270400000],"brazil":[1787263200000,1787266800000],"east-asia":[1787223600000,1787227200000],"oceania":[1787209200000,1787212800000]}},{"conditionName":"Uncovered Caches","mapDisplayName":"Buried City","durationInSeconds":3600,"startTimestamp":1787245200000,"endTimestamp":1787248800000,"regionTimestamps":{"north-america":[1787270400000,1787274000000],"brazil":[1787266800000,1787270400000],"east-asia":[1787227200000,1787230800000],"oceania":[1787212800000,1787216400000]}},{"conditionName":"Close Scrutiny","mapDisplayName":"Spaceport","durationInSeconds":3600,"startTimestamp":1787245200000,"endTimestamp":1787248800000,"regionTimestamps":{"north-america":[1787270400000,1787274000000],"brazil":[1787266800000,1787270400000],"east-asia":[1787227200000,1787230800000],"oceania":[1787212800000,1787216400000]}},{"conditionName":"Night Raid","mapDisplayName":"The Blue Gate","durationInSeconds":3600,"startTimestamp":1787245200000,"endTimestamp":1787248800000,"regionTimestamps":{"north-america":[1787270400000,1787274000000],"brazil":[1787266800000,1787270400000],"east-asia":[1787227200000,1787230800000],"oceania":[1787212800000,1787216400000]}},{"conditionName":"Matriarch","mapDisplayName":"Dam Battlegrounds","durationInSeconds":3600,"startTimestamp":1787245200000,"endTimestamp":1787248800000,"regionTimestamps":{"north-america":[1787270400000,1787274000000],"brazil":[1787266800000,1787270400000],"east-asia":[1787227200000,1787230800000],"oceania":[1787212800000,1787216400000]}},{"conditionName":"Bird City","mapDisplayName":"Buried City","durationInSeconds":3600,"startTimestamp":1787248800000,"endTimestamp":1787252400000,"regionTimestamps":{"north-america":[1787274000000,1787277600000],"brazil":[1787270400000,1787274000000],"east-asia":[1787230800000,1787234400000],"oceania":[1787216400000,1787220000000]}},{"conditionName":"Night Raid","mapDisplayName":"Stella Montis","durationInSeconds":3600,"startTimestamp":1787248800000,"endTimestamp":1787252400000,"regionTimestamps":{"north-america":[1787274000000,1787277600000],"brazil":[1787270400000,1787274000000],"east-asia":[1787230800000,1787234400000],"oceania":[1787216400000,1787220000000]}},{"conditionName":"Hurricane","mapDisplayName":"Spaceport","durationInSeconds":3600,"startTimestamp":1787248800000,"endTimestamp":1787252400000,"regionTimestamps":{"north-america":[1787274000000,1787277600000],"brazil":[1787270400000,1787274000000],"east-asia":[1787230800000,1787234400000],"oceania":[1787216400000,1787220000000]}},{"conditionName":"Harvester","mapDisplayName":"Dam Battlegrounds","durationInSeconds":3600,"startTimestamp":1787248800000,"endTimestamp":1787252400000,"regionTimestamps":{"north-america":[1787274000000,1787277600000],"brazil":[1787270400000,1787274000000],"east-asia":[1787230800000,1787234400000],"oceania":[1787216400000,1787220000000]}},{"conditionName":"Beachcombing","mapDisplayName":"Riven Tides","durationInSeconds":3600,"startTimestamp":1787252400000,"endTimestamp":1787256000000,"regionTimestamps":{"north-america":[1787277600000,1787281200000],"brazil":[1787274000000,1787277600000],"east-asia":[1787234400000,1787238000000],"oceania":[1787220000000,1787223600000]}},{"conditionName":"Matriarch","mapDisplayName":"The Blue Gate","durationInSeconds":3600,"startTimestamp":1787252400000,"endTimestamp":1787256000000,"regionTimestamps":{"north-america":[1787277600000,1787281200000],"brazil":[1787274000000,1787277600000],"east-asia":[1787234400000,1787238000000],"oceania":[1787220000000,1787223600000]}},{"conditionName":"Locked Gate","mapDisplayName":"The Blue Gate","durationInSeconds":3600,"startTimestamp":1787252400000,"endTimestamp":1787256000000,"regionTimestamps":{"north-america":[1787277600000,1787281200000],"brazil":[1787274000000,1787277600000],"east-asia":[1787234400000,1787238000000],"oceania":[1787220000000,1787223600000]}},{"conditionName":"Night Raid","mapDisplayName":"Dam Battlegrounds","durationInSeconds":3600,"startTimestamp":1787252400000,"endTimestamp":1787256000000,"regionTimestamps":{"north-america":[1787277600000,1787281200000],"brazil":[1787274000000,1787277600000],"east-asia":[1787234400000,1787238000000],"oceania":[1787220000000,1787223600000]}},{"conditionName":"Bird City","mapDisplayName":"Buried City","durationInSeconds":3600,"startTimestamp":1787256000000,"endTimestamp":1787259600000,"regionTimestamps":{"north-america":[1787281200000,1787284800000],"brazil":[1787277600000,1787281200000],"east-asia":[1787238000000,1787241600000],"oceania":[1787223600000,1787227200000]}},{"conditionName":"Night Raid","mapDisplayName":"Stella Montis","durationInSeconds":3600,"startTimestamp":1787256000000,"endTimestamp":1787259600000,"regionTimestamps":{"north-america":[1787281200000,1787284800000],"brazil":[1787277600000,1787281200000],"east-asia":[1787238000000,1787241600000],"oceania":[1787223600000,1787227200000]}},{"conditionName":"Harvester","mapDisplayName":"Spaceport","durationInSeconds":3600,"startTimestamp":1787256000000,"endTimestamp":1787259600000,"regionTimestamps":{"north-america":[1787281200000,1787284800000],"brazil":[1787277600000,1787281200000],"east-asia":[1787238000000,1787241600000],"oceania":[1787223600000,1787227200000]}},{"conditionName":"Hurricane","mapDisplayName":"Dam Battlegrounds","durationInSeconds":3600,"startTimestamp":1787256000000,"endTimestamp":1787259600000,"regionTimestamps":{"north-america":[1787281200000,1787284800000],"brazil":[1787277600000,1787281200000],"east-asia":[1787238000000,1787241600000],"oceania":[1787223600000,1787227200000]}},{"conditionName":"Beachcombing","mapDisplayName":"Riven Tides","durationInSeconds":3600,"startTimestamp":1787259600000,"endTimestamp":1787263200000,"regionTimestamps":{"north-america":[1787284800000,1787288400000],"brazil":[1787281200000,1787284800000],"east-asia":[1787241600000,1787245200000],"oceania":[1787227200000,1787230800000]}},{"conditionName":"Night Raid","mapDisplayName":"Riven Tides","durationInSeconds":3600,"startTimestamp":1787259600000,"endTimestamp":1787263200000,"regionTimestamps":{"north-america":[1787284800000,1787288400000],"brazil":[1787281200000,1787284800000],"east-asia":[1787241600000,1787245200000],"oceania":[1787227200000,1787230800000]}},{"conditionName":"Hidden Bunker","mapDisplayName":"Spaceport","durationInSeconds":3600,"startTimestamp":1787259600000,"endTimestamp":1787263200000,"regionTimestamps":{"north-america":[1787284800000,1787288400000],"brazil":[1787281200000,1787284800000],"east-asia":[1787241600000,1787245200000],"oceania":[1787227200000,1787230800000]}},{"conditionName":"Matriarch","mapDisplayName":"Dam Battlegrounds","durationInSeconds":3600,"startTimestamp":1787259600000,"endTimestamp":1787263200000,"regionTimestamps":{"north-america":[1787284800000,1787288400000],"brazil":[1787281200000,1787284800000],"east-asia":[1787241600000,1787245200000],"oceania":[1787227200000,1787230800000]}},{"conditionName":"Bird City","mapDisplayName":"Buried City","durationInSeconds":3600,"startTimestamp":1787263200000,"endTimestamp":1787266800000,"regionTimestamps":{"north-america":[1787288400000,1787292000000],"brazil":[1787284800000,1787288400000],"east-asia":[1787245200000,1787248800000],"oceania":[1787230800000,1787234400000]}},{"conditionName":"Night Raid","mapDisplayName":"Stella Montis","durationInSeconds":3600,"startTimestamp":1787263200000,"endTimestamp":1787266800000,"regionTimestamps":{"north-america":[1787288400000,1787292000000],"brazil":[1787284800000,1787288400000],"east-asia":[1787245200000,1787248800000],"oceania":[1787230800000,1787234400000]}},{"conditionName":"Harvester","mapDisplayName":"Spaceport","durationInSeconds":3600,"startTimestamp":1787263200000,"endTimestamp":1787266800000,"regionTimestamps":{"north-america":[1787288400000,1787292000000],"brazil":[1787284800000,1787288400000],"east-asia":[1787245200000,1787248800000],"oceania":[1787230800000,1787234400000]}},{"conditionName":"Hidden Bunker","mapDisplayName":"Spaceport","durationInSeconds":3600,"startTimestamp":1787263200000,"endTimestamp":1787266800000,"regionTimestamps":{"north-america":[1787288400000,1787292000000],"brazil":[1787284800000,1787288400000],"east-asia":[1787245200000,1787248800000],"oceania":[1787230800000,1787234400000]}},{"conditionName":"Beachcombing","mapDisplayName":"Riven Tides","durationInSeconds":3600,"startTimestamp":1787266800000,"endTimestamp":1787270400000,"regionTimestamps":{"north-america":[1787292000000,1787295600000],"brazil":[1787288400000,1787292000000],"east-asia":[1787248800000,1787252400000],"oceania":[1787234400000,1787238000000]}},{"conditionName":"Night Raid","mapDisplayName":"Riven Tides","durationInSeconds":3600,"startTimestamp":1787266800000,"endTimestamp":1787270400000,"regionTimestamps":{"north-america":[1787292000000,1787295600000],"brazil":[1787288400000,1787292000000],"east-asia":[1787248800000,1787252400000],"oceania":[1787234400000,1787238000000]}},{"conditionName":"Matriarch","mapDisplayName":"Dam Battlegrounds","durationInSeconds":3600,"startTimestamp":1787266800000,"endTimestamp":1787270400000,"regionTimestamps":{"north-america":[1787292000000,1787295600000],"brazil":[1787288400000,1787292000000],"east-asia":[1787248800000,1787252400000],"oceania":[1787234400000,1787238000000]}}]''';
}
