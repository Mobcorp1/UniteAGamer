import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

/// Pure map/source filtering keeps repeated Blueprint finds as separate records.
class ArcBlueprintLocationFilter {
  const ArcBlueprintLocationFilter._();

  static List<ArcAdminMapMarker> apply(
    Iterable<ArcAdminMapMarker> locations, {
    String? mapId,
    String? sourceLabel,
    String? conditionLabel,
  }) => locations
      .where(
        (marker) =>
            (mapId == null || marker.mapId == mapId) &&
            (sourceLabel == null || marker.sourceLabel == sourceLabel) &&
            (conditionLabel == null || marker.conditionLabel == conditionLabel),
      )
      .toList(growable: false);
}

/// Published admin evidence only. Community report summaries remain separate.
class ArcBlueprintLocationsPanel extends StatefulWidget {
  const ArcBlueprintLocationsPanel({
    super.key,
    required this.blueprintId,
    this.repository,
  });

  final String blueprintId;
  final ArcAdminMapEditorRepository? repository;

  @override
  State<ArcBlueprintLocationsPanel> createState() =>
      _ArcBlueprintLocationsPanelState();
}

class _ArcBlueprintLocationsPanelState
    extends State<ArcBlueprintLocationsPanel> {
  late Stream<List<ArcAdminMapMarker>> _locations;
  String? _selectedMap;
  String? _selectedSource;
  String? _selectedCondition;

  @override
  void initState() {
    super.initState();
    _watch();
  }

  @override
  void didUpdateWidget(covariant ArcBlueprintLocationsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.blueprintId != widget.blueprintId ||
        oldWidget.repository != widget.repository) {
      _selectedMap = null;
      _selectedSource = null;
      _selectedCondition = null;
      _watch();
    }
  }

  void _watch() {
    _locations = (widget.repository ?? ArcAdminMapEditorRepository())
        .watchPublishedBlueprintLocations(widget.blueprintId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ArcAdminMapMarker>>(
      stream: _locations,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text(
            'Published map locations are unavailable.',
            style: TextStyle(color: ArcUiTokens.textSecondary),
          );
        }
        if (!snapshot.hasData) {
          return const LinearProgressIndicator(
            color: ArcUiTokens.primaryAccent,
          );
        }
        final locations = snapshot.data!;
        if (locations.isEmpty) {
          return const Text(
            'No published map locations for this Blueprint yet.',
            style: TextStyle(color: ArcUiTokens.textSecondary),
          );
        }
        final maps = locations.map((m) => m.mapId).toSet().toList()..sort();
        final sources = locations.map((m) => m.sourceLabel).toSet().toList()
          ..sort();
        final conditions =
            locations
                .map((m) => m.conditionLabel)
                .where((label) => label.isNotEmpty)
                .toSet()
                .toList()
              ..sort();
        final filtered = ArcBlueprintLocationFilter.apply(
          locations,
          mapId: _selectedMap,
          sourceLabel: _selectedSource,
          conditionLabel: _selectedCondition,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PUBLISHED LOCATIONS · ${locations.length}',
              style: ArcUiTokens.sectionTitle(
                fontSize: 18,
                color: ArcUiTokens.primaryAccent,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                ChoiceChip(
                  label: const Text('All maps'),
                  selected: _selectedMap == null,
                  onSelected: (_) => setState(() => _selectedMap = null),
                ),
                for (final map in maps)
                  ChoiceChip(
                    label: Text(_mapLabel(map)),
                    selected: _selectedMap == map,
                    onSelected: (_) => setState(() => _selectedMap = map),
                  ),
              ],
            ),
            if (sources.length > 1) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  ChoiceChip(
                    label: const Text('All sources'),
                    selected: _selectedSource == null,
                    onSelected: (_) => setState(() => _selectedSource = null),
                  ),
                  for (final source in sources)
                    ChoiceChip(
                      label: Text(source),
                      selected: _selectedSource == source,
                      onSelected: (_) =>
                          setState(() => _selectedSource = source),
                    ),
                ],
              ),
            ],
            if (conditions.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  ChoiceChip(
                    label: const Text('All conditions'),
                    selected: _selectedCondition == null,
                    onSelected: (_) =>
                        setState(() => _selectedCondition = null),
                  ),
                  for (final condition in conditions)
                    ChoiceChip(
                      label: Text(condition),
                      selected: _selectedCondition == condition,
                      onSelected: (_) =>
                          setState(() => _selectedCondition = condition),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            if (filtered.isEmpty)
              const Text(
                'No locations match those filters.',
                style: TextStyle(color: ArcUiTokens.textSecondary),
              ),
            for (final marker in filtered)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: DecoratedBox(
                  decoration: ArcUiTokens.surfaceDecoration(
                    role: ArcSurfaceRole.interactive,
                    accent: ArcUiTokens.primaryAccent,
                    borderOpacity: .20,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(marker.name, style: ArcUiTokens.cardTitle()),
                        Text(
                          '${_mapLabel(marker.mapId)} · ${marker.layer.label}',
                          style: ArcUiTokens.label(
                            color: ArcUiTokens.primaryAccent,
                          ),
                        ),
                        if (marker.conditionLabel.isNotEmpty)
                          Text(
                            'Condition: ${marker.conditionLabel}',
                            style: ArcUiTokens.bodySmall(
                              color: ArcUiTokens.attentionAccent,
                            ),
                          ),
                        if (marker.description.trim().isNotEmpty)
                          Text(
                            marker.description,
                            style: ArcUiTokens.bodySmall(),
                          ),
                        Text(
                          '${marker.sourceLabel} · ${marker.confidence.label}',
                          style: ArcUiTokens.bodySmall(
                            color: ArcUiTokens.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  static String _mapLabel(String id) => id
      .split('_')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}
