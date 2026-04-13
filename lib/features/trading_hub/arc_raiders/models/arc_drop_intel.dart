import 'package:flutter/foundation.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';

@immutable
class ArcAreaIntelBreakdown {
  const ArcAreaIntelBreakdown({
    required this.key,
    required this.label,
    required this.reportCount,
    required this.percentage,
  });

  final String key;
  final String label;
  final int reportCount;
  final double percentage;

  String get percentageLabel => '${percentage.toStringAsFixed(0)}%';
}

@immutable
class ArcIntelCombination {
  const ArcIntelCombination({
    required this.key,
    required this.mapLabel,
    required this.areaLabel,
    required this.containerLabel,
    required this.weatherLabel,
    required this.eventLabel,
    required this.reportCount,
    required this.percentage,
  });

  final String key;
  final String mapLabel;
  final String areaLabel;
  final String containerLabel;
  final String weatherLabel;
  final String eventLabel;
  final int reportCount;
  final double percentage;

  String get summaryLabel =>
      '$mapLabel → $areaLabel → $containerLabel → $weatherLabel → $eventLabel';

  String get percentageLabel => '${percentage.toStringAsFixed(0)}%';
}

@immutable
class ArcDropIntel {
  const ArcDropIntel({
    required this.blueprintId,
    required this.totalReports,
    required this.mapBreakdown,
    required this.areaBreakdown,
    required this.containerBreakdown,
    required this.conditionBreakdown,
    required this.weatherBreakdown,
    required this.mapEventBreakdown,
    required this.raidTypeBreakdown,
    required this.timeOfDayBreakdown,
    required this.topCombinations,
    this.topMapLabel,
    this.topAreaLabel,
    this.topContainerLabel,
    this.topConditionLabel,
    this.topWeatherLabel,
    this.topMapEventLabel,
    this.lastReportedAt,
  });

  final String blueprintId;
  final int totalReports;
  final List<ArcAreaIntelBreakdown> mapBreakdown;
  final List<ArcAreaIntelBreakdown> areaBreakdown;
  final List<ArcAreaIntelBreakdown> containerBreakdown;
  final List<ArcAreaIntelBreakdown> conditionBreakdown;
  final List<ArcAreaIntelBreakdown> weatherBreakdown;
  final List<ArcAreaIntelBreakdown> mapEventBreakdown;
  final List<ArcAreaIntelBreakdown> raidTypeBreakdown;
  final List<ArcAreaIntelBreakdown> timeOfDayBreakdown;
  final List<ArcIntelCombination> topCombinations;
  final String? topMapLabel;
  final String? topAreaLabel;
  final String? topContainerLabel;
  final String? topConditionLabel;
  final String? topWeatherLabel;
  final String? topMapEventLabel;
  final DateTime? lastReportedAt;

  bool get hasReports => totalReports > 0;

  factory ArcDropIntel.empty(String blueprintId) {
    return ArcDropIntel(
      blueprintId: blueprintId,
      totalReports: 0,
      mapBreakdown: const [],
      areaBreakdown: const [],
      containerBreakdown: const [],
      conditionBreakdown: const [],
      weatherBreakdown: const [],
      mapEventBreakdown: const [],
      raidTypeBreakdown: const [],
      timeOfDayBreakdown: const [],
      topCombinations: const [],
    );
  }

  factory ArcDropIntel.fromReports({
    required String blueprintId,
    required List<ArcBlueprintDropReport> reports,
  }) {
    if (reports.isEmpty) return ArcDropIntel.empty(blueprintId);

    final countsByMap = <String, int>{};
    final countsByArea = <String, int>{};
    final countsByContainer = <String, int>{};
    final countsByCondition = <String, int>{};
    final countsByWeather = <String, int>{};
    final countsByEvent = <String, int>{};
    final countsByRaidType = <String, int>{};
    final countsByTimeOfDay = <String, int>{};
    final comboCounts = <String, _ComboAccumulator>{};

    DateTime? lastReportedAt;
    var weightedTotal = 0;

    for (final report in reports) {
      final weight = report.confirmationCount <= 0 ? 1 : report.confirmationCount;
      weightedTotal += weight;

      final mapLabel = report.mapName.trim().isEmpty ? 'Unknown Map' : report.mapName.trim();
      countsByMap[mapLabel] = (countsByMap[mapLabel] ?? 0) + weight;

      final areaLabel = report.areaLabel.trim().isEmpty ? 'Unknown Area' : report.areaLabel.trim();
      countsByArea[areaLabel] = (countsByArea[areaLabel] ?? 0) + weight;

      final containerLabel = report.resolvedContainerLabel;
      countsByContainer[containerLabel] = (countsByContainer[containerLabel] ?? 0) + weight;

      final conditionLabel = (report.conditionLabel?.trim().isNotEmpty ?? false)
          ? report.conditionLabel!.trim()
          : 'No Special Condition';
      countsByCondition[conditionLabel] = (countsByCondition[conditionLabel] ?? 0) + weight;

      final weatherLabel = report.weatherLabel;
      countsByWeather[weatherLabel] = (countsByWeather[weatherLabel] ?? 0) + weight;

      final eventLabel = report.eventLabel;
      countsByEvent[eventLabel] = (countsByEvent[eventLabel] ?? 0) + weight;

      final raidTypeLabel = report.raidType.label;
      countsByRaidType[raidTypeLabel] = (countsByRaidType[raidTypeLabel] ?? 0) + weight;

      final timeOfDayLabel = report.timeOfDay.label;
      countsByTimeOfDay[timeOfDayLabel] = (countsByTimeOfDay[timeOfDayLabel] ?? 0) + weight;

      final comboKey = [
        mapLabel,
        areaLabel,
        containerLabel,
        weatherLabel,
        eventLabel,
      ].join('|');
      comboCounts.update(
        comboKey,
        (existing) => existing.copyWith(count: existing.count + weight),
        ifAbsent: () => _ComboAccumulator(
          key: comboKey,
          mapLabel: mapLabel,
          areaLabel: areaLabel,
          containerLabel: containerLabel,
          weatherLabel: weatherLabel,
          eventLabel: eventLabel,
          count: weight,
        ),
      );

      final timestamp = report.lastConfirmedAt ?? report.createdAt ?? report.foundAt;
      if (timestamp != null && (lastReportedAt == null || timestamp.isAfter(lastReportedAt))) {
        lastReportedAt = timestamp;
      }
    }

    final mapBreakdown = _buildBreakdown(countsByMap, weightedTotal);
    final areaBreakdown = _buildBreakdown(countsByArea, weightedTotal);
    final containerBreakdown = _buildBreakdown(countsByContainer, weightedTotal);
    final conditionBreakdown = _buildBreakdown(countsByCondition, weightedTotal);
    final weatherBreakdown = _buildBreakdown(countsByWeather, weightedTotal);
    final mapEventBreakdown = _buildBreakdown(countsByEvent, weightedTotal);
    final raidTypeBreakdown = _buildBreakdown(countsByRaidType, weightedTotal);
    final timeOfDayBreakdown = _buildBreakdown(countsByTimeOfDay, weightedTotal);

    final topCombinations = comboCounts.values
        .map(
          (combo) => ArcIntelCombination(
            key: combo.key,
            mapLabel: combo.mapLabel,
            areaLabel: combo.areaLabel,
            containerLabel: combo.containerLabel,
            weatherLabel: combo.weatherLabel,
            eventLabel: combo.eventLabel,
            reportCount: combo.count,
            percentage: weightedTotal == 0 ? 0 : (combo.count / weightedTotal) * 100,
          ),
        )
        .toList(growable: false)
      ..sort((a, b) {
        final valueCompare = b.reportCount.compareTo(a.reportCount);
        if (valueCompare != 0) return valueCompare;
        return a.summaryLabel.toLowerCase().compareTo(b.summaryLabel.toLowerCase());
      });

    return ArcDropIntel(
      blueprintId: blueprintId,
      totalReports: weightedTotal,
      mapBreakdown: mapBreakdown,
      areaBreakdown: areaBreakdown,
      containerBreakdown: containerBreakdown,
      conditionBreakdown: conditionBreakdown,
      weatherBreakdown: weatherBreakdown,
      mapEventBreakdown: mapEventBreakdown,
      raidTypeBreakdown: raidTypeBreakdown,
      timeOfDayBreakdown: timeOfDayBreakdown,
      topCombinations: topCombinations.take(5).toList(growable: false),
      topMapLabel: mapBreakdown.isEmpty ? null : mapBreakdown.first.label,
      topAreaLabel: areaBreakdown.isEmpty ? null : areaBreakdown.first.label,
      topContainerLabel: containerBreakdown.isEmpty ? null : containerBreakdown.first.label,
      topConditionLabel: conditionBreakdown.isEmpty ? null : conditionBreakdown.first.label,
      topWeatherLabel: weatherBreakdown.isEmpty ? null : weatherBreakdown.first.label,
      topMapEventLabel: mapEventBreakdown.isEmpty ? null : mapEventBreakdown.first.label,
      lastReportedAt: lastReportedAt,
    );
  }

  static List<ArcAreaIntelBreakdown> _buildBreakdown(Map<String, int> counts, int total) {
    final sortedEntries = counts.entries.toList()
      ..sort((a, b) {
        final valueCompare = b.value.compareTo(a.value);
        if (valueCompare != 0) return valueCompare;
        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });

    return sortedEntries.map((entry) {
      final percentage = total == 0 ? 0.0 : (entry.value / total) * 100;
      return ArcAreaIntelBreakdown(
        key: entry.key,
        label: entry.key,
        reportCount: entry.value,
        percentage: percentage,
      );
    }).toList(growable: false);
  }
}

@immutable
class _ComboAccumulator {
  const _ComboAccumulator({
    required this.key,
    required this.mapLabel,
    required this.areaLabel,
    required this.containerLabel,
    required this.weatherLabel,
    required this.eventLabel,
    required this.count,
  });

  final String key;
  final String mapLabel;
  final String areaLabel;
  final String containerLabel;
  final String weatherLabel;
  final String eventLabel;
  final int count;

  _ComboAccumulator copyWith({int? count}) {
    return _ComboAccumulator(
      key: key,
      mapLabel: mapLabel,
      areaLabel: areaLabel,
      containerLabel: containerLabel,
      weatherLabel: weatherLabel,
      eventLabel: eventLabel,
      count: count ?? this.count,
    );
  }
}
