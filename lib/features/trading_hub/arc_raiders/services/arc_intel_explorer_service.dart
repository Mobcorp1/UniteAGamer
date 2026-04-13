import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_intel_explorer_snapshot.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_intel_hotspot.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_report_filters.dart';

class ArcIntelExplorerService {
  const ArcIntelExplorerService();

  ArcIntelExplorerSnapshot build({
    required List<ArcBlueprintDropReport> reports,
    required ArcReportFilters filters,
  }) {
    final filteredReports =
        reports
            .where((report) => _matches(report, filters))
            .toList(growable: false)
          ..sort((a, b) {
            final aTime =
                a.createdAt ??
                a.foundAt ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bTime =
                b.createdAt ??
                b.foundAt ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });

    return ArcIntelExplorerSnapshot(
      filteredReports: filteredReports,
      hotspots: _buildHotspots(filteredReports),
      mapOptions: _distinctStrings(
        reports
            .map((report) => report.mapName.trim())
            .where((value) => value.isNotEmpty),
      ),
      containerOptions: _distinctStrings(
        reports
            .map((report) => report.resolvedContainerLabel)
            .where((value) => value.trim().isNotEmpty),
      ),
      conditionOptions: _distinctStrings(
        reports.map(
          (report) => (report.conditionLabel?.trim().isNotEmpty ?? false)
              ? report.conditionLabel!.trim()
              : 'No Special Condition',
        ),
      ),
    );
  }

  bool _matches(ArcBlueprintDropReport report, ArcReportFilters filters) {
    final normalizedQuery = filters.query.trim().toLowerCase();
    if (normalizedQuery.isNotEmpty) {
      final haystack = <String>[
        report.mapName,
        report.areaLabel,
        report.resolvedContainerLabel,
        report.notes,
        report.conditionLabel ?? '',
        report.resolvedContainerLabel,
      ].join(' ').toLowerCase();
      if (!haystack.contains(normalizedQuery)) return false;
    }

    if ((filters.mapName?.trim().isNotEmpty ?? false) &&
        report.mapName.trim().toLowerCase() !=
            filters.mapName!.trim().toLowerCase()) {
      return false;
    }

    final containerLabel = report.resolvedContainerLabel;
    if ((filters.containerLabel?.trim().isNotEmpty ?? false) &&
        containerLabel.toLowerCase() !=
            filters.containerLabel!.trim().toLowerCase()) {
      return false;
    }

    if (filters.raidType != null && report.raidType != filters.raidType) {
      return false;
    }

    if (filters.timeOfDay != null && report.timeOfDay != filters.timeOfDay) {
      return false;
    }

    final conditionLabel = (report.conditionLabel?.trim().isNotEmpty ?? false)
        ? report.conditionLabel!.trim()
        : 'No Special Condition';
    if ((filters.conditionLabel?.trim().isNotEmpty ?? false) &&
        conditionLabel.toLowerCase() !=
            filters.conditionLabel!.trim().toLowerCase()) {
      return false;
    }

    if (filters.onlyWithNotes && report.notes.trim().isEmpty) {
      return false;
    }

    return true;
  }

  List<ArcIntelHotspot> _buildHotspots(List<ArcBlueprintDropReport> reports) {
    if (reports.isEmpty) return const <ArcIntelHotspot>[];

    final counts = <String, int>{};
    final mapByKey = <String, String>{};
    final areaByKey = <String, String>{};
    final containerByKey = <String, String>{};
    final lastReportedByKey = <String, DateTime>{};
    final firstNoteByKey = <String, String>{};

    for (final report in reports) {
      final containerLabel = report.resolvedContainerLabel;
      final areaLabel = report.areaLabel.trim().isEmpty
          ? 'Unknown Area'
          : report.areaLabel.trim();
      final key = '${report.mapName}|$areaLabel|$containerLabel';

      counts.update(key, (value) => value + 1, ifAbsent: () => 1);
      mapByKey[key] = report.mapName.trim().isEmpty
          ? 'Unknown Map'
          : report.mapName.trim();
      areaByKey[key] = areaLabel;
      containerByKey[key] = containerLabel;

      final timestamp = report.createdAt ?? report.foundAt;
      if (timestamp != null) {
        final existing = lastReportedByKey[key];
        if (existing == null || timestamp.isAfter(existing)) {
          lastReportedByKey[key] = timestamp;
        }
      }

      if (report.notes.trim().isNotEmpty &&
          (firstNoteByKey[key]?.isEmpty ?? true)) {
        firstNoteByKey[key] = report.notes.trim();
      }
    }

    final total = reports.length;
    final hotspots =
        counts.entries
            .map((entry) {
              return ArcIntelHotspot(
                key: entry.key,
                mapName: mapByKey[entry.key] ?? 'Unknown Map',
                areaLabel: areaByKey[entry.key] ?? 'Unknown Area',
                containerLabel: containerByKey[entry.key] ?? 'Unknown',
                count: entry.value,
                percentage: total == 0 ? 0 : (entry.value / total) * 100,
                lastReportedAt: lastReportedByKey[entry.key],
                locationPreview: firstNoteByKey[entry.key],
              );
            })
            .toList(growable: false)
          ..sort((a, b) {
            final countCompare = b.count.compareTo(a.count);
            if (countCompare != 0) return countCompare;
            return a.key.toLowerCase().compareTo(b.key.toLowerCase());
          });

    return hotspots;
  }

  List<String> _distinctStrings(Iterable<String> values) {
    final normalized = <String>{};
    final result = <String>[];

    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) continue;
      final key = trimmed.toLowerCase();
      if (normalized.add(key)) {
        result.add(trimmed);
      }
    }

    result.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return result;
  }
}
