import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import 'package:uag_arc_raiders_hub/build/app_bar.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_marker_alignment_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_marker_import_adapters.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_marker_import_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_map_marker_import_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart';
import 'package:uag_arc_raiders_hub/widgets/static_watermark.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcAdminMapEditorScreen extends StatefulWidget {
  const ArcAdminMapEditorScreen({super.key, this.repository, this.appBar});

  static const routeName = '/admin-map-intel-editor';

  final ArcAdminMapEditorRepository? repository;
  final PreferredSizeWidget? appBar;

  @override
  State<ArcAdminMapEditorScreen> createState() =>
      _ArcAdminMapEditorScreenState();
}

class _ArcAdminMapEditorScreenState extends State<ArcAdminMapEditorScreen> {
  late final ArcAdminMapEditorRepository _repository;
  final _importAdapter = const ArcPermittedJsonMapMarkerImportAdapter();
  final _importEngine = const ArcMapMarkerImportEngine();
  final _alignmentEngine = const ArcMapMarkerAlignmentEngine();
  final _transformationController = TransformationController();
  final _searchController = TextEditingController();
  final _undoStack = <List<ArcAdminMapMarker>>[];

  late String _mapId;
  late ArcRaidMapLayer _layer;
  List<ArcAdminMapMarker> _markers = const <ArcAdminMapMarker>[];
  ArcAdminMapMarker? _selected;
  bool _loading = true;
  bool _saving = false;
  bool _showSeedDefinitions = true;
  bool _showCustomIntel = true;
  String _searchQuery = '';
  ArcAdminMapMarkerKind? _kindFilter;
  ArcMapMarkerImportSummary? _lastImportSummary;

  ArcRaidMap get _map => ArcRaidIntelligenceSeedData.mapById(_mapId);

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ArcAdminMapEditorRepository();
    final maps = ArcRaidIntelligenceSeedData.maps
        .where((item) => item.availableLayers.isNotEmpty)
        .toList(growable: false);
    _mapId = maps.first.id;
    _layer = maps.first.availableLayers.first;
    unawaited(_load());
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final drafts = await _repository.loadDrafts(_mapId, _layer);
    final seedMarkers = _seedMarkers(_map, _layer);
    final cachedImports = await _repository.loadImportCache(_mapId, _layer);
    final merged = <String, ArcAdminMapMarker>{
      for (final marker in seedMarkers) marker.id: marker,
      for (final marker in drafts) marker.id: marker,
      for (final marker in cachedImports) marker.id: marker,
    };

    if (!mounted) return;
    setState(() {
      _markers = merged.values.toList(growable: false)
        ..sort((a, b) => a.name.compareTo(b.name));
      _selected = null;
      _lastImportSummary = null;
      _undoStack.clear();
      _loading = false;
      _transformationController.value = Matrix4.identity();
    });
  }

  List<ArcAdminMapMarker> _seedMarkers(ArcRaidMap map, ArcRaidMapLayer layer) {
    if (layer != ArcRaidMapLayer.surface) {
      return const <ArcAdminMapMarker>[];
    }

    return <ArcAdminMapMarker>[
      for (final poi in map.pois)
        ArcAdminMapMarker(
          id: 'seed_${map.id}_poi_${poi.id}',
          mapId: map.id,
          layer: layer,
          kind: ArcAdminMapMarkerKind.poi,
          name: poi.name,
          point: poi.point,
          description: poi.lootTags.join(', '),
          seedReferenceId: poi.id,
        ),
      for (final extraction in map.extractions)
        ArcAdminMapMarker(
          id: 'seed_${map.id}_extraction_${extraction.id}',
          mapId: map.id,
          layer: layer,
          kind: ArcAdminMapMarkerKind.extraction,
          name: extraction.name,
          point: extraction.point,
          description: extraction.notes,
          seedReferenceId: extraction.id,
        ),
      for (final hatch in map.hatches)
        ArcAdminMapMarker(
          id: 'seed_${map.id}_hatch_${hatch.id}',
          mapId: map.id,
          layer: layer,
          kind: ArcAdminMapMarkerKind.raiderHatch,
          name: hatch.name,
          point: hatch.point,
          seedReferenceId: hatch.id,
        ),
    ];
  }

  List<ArcAdminMapMarker> get _visibleMarkers {
    final query = _searchQuery.trim().toLowerCase();
    return _markers
        .where((marker) {
          if (marker.kind.isSeedDefinition && !_showSeedDefinitions) {
            return false;
          }
          if (!marker.kind.isSeedDefinition && !_showCustomIntel) {
            return false;
          }
          if (_kindFilter != null && marker.kind != _kindFilter) {
            return false;
          }
          if (query.isNotEmpty &&
              !marker.name.toLowerCase().contains(query) &&
              !marker.description.toLowerCase().contains(query) &&
              !marker.sourceLabel.toLowerCase().contains(query) &&
              !(marker.sourceName?.toLowerCase().contains(query) ?? false)) {
            return false;
          }
          return marker.mapId == _mapId && marker.layer == _layer;
        })
        .toList(growable: false);
  }

  List<ArcAdminMapMarker> get _importedMarkers {
    return _markers
        .where(
          (marker) =>
              marker.mapId == _mapId &&
              marker.layer == _layer &&
              marker.sourceRecordId?.trim().isNotEmpty == true,
        )
        .toList(growable: false);
  }

  void _snapshotUndo() {
    _undoStack.add(List<ArcAdminMapMarker>.from(_markers));
    if (_undoStack.length > 40) {
      _undoStack.removeAt(0);
    }
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    final previous = _undoStack.removeLast();
    setState(() {
      _markers = previous;
      if (_selected != null) {
        final matches = _markers.where((item) => item.id == _selected!.id);
        _selected = matches.isEmpty ? null : matches.first;
      }
    });
  }

  void _updatePoint(ArcAdminMapMarker marker, ArcNormalizedPoint point) {
    _snapshotUndo();
    final updated = marker.copyWith(point: point.clamp());
    setState(() {
      _markers = [
        for (final item in _markers)
          if (item.id == marker.id) updated else item,
      ];
      _selected = updated;
    });
  }

  void _placeSelected(Offset localPosition, Size size) {
    final selected = _selected;
    if (selected == null || size.width <= 0 || size.height <= 0) return;
    _updatePoint(
      selected,
      ArcNormalizedPoint(
        x: localPosition.dx / size.width,
        y: localPosition.dy / size.height,
      ),
    );
  }

  Future<void> _saveDrafts() async {
    setState(() => _saving = true);
    try {
      await _repository.saveDrafts(_mapId, _layer, _markers);
      if (!mounted) return;
      _message('Draft positions saved on this device.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _publishSelected() async {
    final selected = _selected;
    if (selected == null) return;
    setState(() => _saving = true);
    try {
      await _repository.publish(selected);
      if (!mounted) return;
      final published = selected.copyWith(
        state: ArcAdminMapMarkerState.published,
      );
      setState(() {
        _markers = [
          for (final item in _markers)
            if (item.id == selected.id) published else item,
        ];
        _selected = published;
      });
      _message('Marker published to live Admin Intel.');
    } catch (error) {
      if (mounted) _message('Could not publish marker: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _publishAll() async {
    setState(() => _saving = true);
    try {
      await _repository.publishAll(_visibleMarkers);
      if (!mounted) return;
      setState(() {
        _markers = [
          for (final marker in _markers)
            if (marker.mapId == _mapId && marker.layer == _layer)
              marker.copyWith(state: ArcAdminMapMarkerState.published)
            else
              marker,
        ];
      });
      _message('${_visibleMarkers.length} markers published.');
    } catch (error) {
      if (mounted) _message('Could not publish markers: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _exportJson() async {
    final json = _repository.exportJson(_visibleMarkers);
    await Clipboard.setData(ClipboardData(text: json));
    if (mounted) _message('Production marker JSON copied to clipboard.');
  }

  Future<void> _importJsonFromClipboard() async {
    setState(() => _saving = true);
    try {
      final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
      final raw = clipboard?.text;
      if (raw == null || raw.trim().isEmpty) {
        _message('Clipboard does not contain marker JSON.');
        return;
      }
      final payload = _importAdapter.parse(
        raw,
        defaultMapId: _mapId,
        defaultLayer: _layer,
      );
      final mapAsset = _map.assetForLayer(_layer);
      final alignment = _alignmentEngine.identity(
        mapId: _mapId,
        layer: _layer,
        sourceId: payload.source.id,
      );
      final summary = _importEngine.importRecords(
        payload: payload,
        mapId: _mapId,
        layer: _layer,
        existingMarkers: _markers,
        alignment: alignment,
        mapAsset: mapAsset,
        importedAt: DateTime.now().toUtc(),
      );
      final accepted = summary.acceptedMarkers;
      _snapshotUndo();
      setState(() {
        _lastImportSummary = summary;
        _markers = _mergeMarkers(_markers, accepted);
        _showCustomIntel = true;
        if (accepted.isNotEmpty) _selected = accepted.first;
      });
      await _repository.saveImportCache(_mapId, _layer, _importedMarkers);

      if (summary.autoPublishedMarkers.isNotEmpty) {
        try {
          await _repository.publishAll(summary.autoPublishedMarkers);
        } catch (error) {
          if (mounted) {
            _message('Import cached; auto-publish needs admin sign-in: $error');
          }
          return;
        }
      }
      if (mounted) {
        _message(
          'Import processed: ${summary.autoPublishedCount} published, '
          '${summary.provisionalCount} provisional, '
          '${summary.exceptionCount} exceptions, '
          '${summary.duplicateCount} duplicates.',
        );
      }
    } catch (error) {
      if (mounted) _message('Could not import marker JSON: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _publishEligibleImports() async {
    final eligible = _visibleMarkers
        .where(
          (marker) =>
              marker.sourceRecordId?.trim().isNotEmpty == true &&
              !marker.isPublished &&
              !marker.hasImportException &&
              marker.sourcePermission.canPublish,
        )
        .toList(growable: false);
    if (eligible.isEmpty) {
      _message('No eligible imported markers are ready to publish.');
      return;
    }
    setState(() => _saving = true);
    try {
      await _repository.publishAll(eligible);
      if (!mounted) return;
      setState(() {
        _markers = [
          for (final marker in _markers)
            if (eligible.any((item) => item.id == marker.id))
              marker.copyWith(state: ArcAdminMapMarkerState.published)
            else
              marker,
        ];
      });
      await _repository.saveImportCache(_mapId, _layer, _importedMarkers);
      _message('${eligible.length} imported markers published.');
    } catch (error) {
      if (mounted) _message('Could not publish imported markers: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _reprocessImportCache() async {
    final cached = await _repository.loadImportCache(_mapId, _layer);
    if (!mounted) return;
    setState(() {
      _markers = _mergeMarkers(
        _markers.where((marker) => marker.sourceRecordId == null),
        cached,
      );
      _selected = cached.isEmpty ? null : cached.first;
    });
    _message('${cached.length} cached imported markers reloaded.');
  }

  static List<ArcAdminMapMarker> _mergeMarkers(
    Iterable<ArcAdminMapMarker> base,
    Iterable<ArcAdminMapMarker> incoming,
  ) {
    final merged = <String, ArcAdminMapMarker>{
      for (final marker in base) marker.id: marker,
      for (final marker in incoming) marker.id: marker,
    };
    return merged.values.toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> _createMarker() async {
    final result = await showDialog<_NewMarkerResult>(
      context: context,
      builder: (context) => const _NewMarkerDialog(),
    );
    if (result == null) return;

    _snapshotUndo();
    const uuid = Uuid();
    final marker = ArcAdminMapMarker(
      id: 'admin_${_mapId}_${_layer.name}_${uuid.v4()}',
      mapId: _mapId,
      layer: _layer,
      kind: result.kind,
      name: result.name,
      description: result.description,
      blueprintId: result.blueprintId,
      sourceLabel: result.sourceLabel,
      confidence: result.confidence,
      point: const ArcNormalizedPoint(x: 0.5, y: 0.5),
    );
    setState(() {
      _markers = [..._markers, marker];
      _selected = marker;
      _showCustomIntel = true;
    });
  }

  void _deleteSelected() {
    final selected = _selected;
    if (selected == null) return;
    _snapshotUndo();
    setState(() {
      _markers = _markers.where((item) => item.id != selected.id).toList();
      _selected = null;
    });
  }

  void _resetSelected() {
    final selected = _selected;
    if (selected == null) return;
    final matches = _seedMarkers(
      _map,
      _layer,
    ).where((item) => item.id == selected.id);
    final seed = matches.isEmpty ? null : matches.first;
    if (seed == null) return;
    _updatePoint(selected, seed.point);
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar:
          widget.appBar ??
          const UagAppBar(
            title: 'Admin Map & Intel Editor',
            subtitle: 'Calibrate existing markers and publish custom Intel.',
          ),
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 1000;
                      final mapPanel = _buildMapPanel();
                      final sidePanel = _buildSidePanel();
                      return Padding(
                        padding: AppTheme.pagePadding,
                        child: wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(flex: 7, child: mapPanel),
                                  const SizedBox(width: AppTheme.spaceM),
                                  SizedBox(width: 360, child: sidePanel),
                                ],
                              )
                            : Column(
                                children: [
                                  Expanded(flex: 6, child: mapPanel),
                                  const SizedBox(height: AppTheme.spaceM),
                                  Expanded(flex: 4, child: sidePanel),
                                ],
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPanel() {
    final asset = _map.assetForLayer(_layer);
    final assetPath = asset?.localAssetPath;

    return Container(
      decoration: AppTheme.tradingCardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _toolbar(),
          Expanded(
            child: assetPath == null
                ? const Center(
                    child: Text(
                      'No image registered for this map layer.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 0.5,
                    maxScale: 8,
                    boundaryMargin: const EdgeInsets.all(240),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapUp: (details) =>
                              _placeSelected(details.localPosition, size),
                          child: SizedBox(
                            width: size.width,
                            height: size.height,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned.fill(
                                  child: Image.asset(
                                    assetPath,
                                    fit: BoxFit.fill,
                                    filterQuality: FilterQuality.high,
                                    errorBuilder: (_, _, _) => const Center(
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        color: Colors.white54,
                                        size: 48,
                                      ),
                                    ),
                                  ),
                                ),
                                for (final marker in _visibleMarkers)
                                  _markerWidget(marker, size),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _toolbar() {
    final maps = ArcRaidIntelligenceSeedData.maps
        .where((item) => item.availableLayers.isNotEmpty)
        .toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.black.withValues(alpha: 0.35),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 190,
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _mapId,
              decoration: const InputDecoration(labelText: 'Map'),
              items: [
                for (final map in maps)
                  DropdownMenuItem(
                    value: map.id,
                    child: Text(
                      map.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value == null || value == _mapId) return;
                final next = ArcRaidIntelligenceSeedData.mapById(value);
                setState(() {
                  _mapId = value;
                  _layer = next.availableLayers.first;
                });
                unawaited(_load());
              },
            ),
          ),
          SizedBox(
            width: 170,
            child: DropdownButtonFormField<ArcRaidMapLayer>(
              isExpanded: true,
              initialValue: _layer,
              decoration: const InputDecoration(labelText: 'Layer'),
              items: [
                for (final layer in _map.availableLayers)
                  DropdownMenuItem(value: layer, child: Text(layer.label)),
              ],
              onChanged: (value) {
                if (value == null || value == _layer) return;
                setState(() => _layer = value);
                unawaited(_load());
              },
            ),
          ),
          FilterChip(
            selected: _showSeedDefinitions,
            label: const Text('POIs / exits'),
            onSelected: (value) => setState(() => _showSeedDefinitions = value),
          ),
          FilterChip(
            selected: _showCustomIntel,
            label: const Text('Custom Intel'),
            onSelected: (value) => setState(() => _showCustomIntel = value),
          ),
          IconButton(
            tooltip: 'Undo',
            onPressed: _undoStack.isEmpty ? null : _undo,
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            tooltip: 'Reset zoom',
            onPressed: () =>
                _transformationController.value = Matrix4.identity(),
            icon: const Icon(Icons.center_focus_strong_rounded),
          ),
        ],
      ),
    );
  }

  Widget _markerWidget(ArcAdminMapMarker marker, Size size) {
    final selected = _selected?.id == marker.id;
    final left = (marker.point.x * size.width) - 18;
    final top = (marker.point.y * size.height) - 18;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () => setState(() => _selected = marker),
        onPanStart: (_) {
          if (_selected?.id != marker.id) {
            setState(() => _selected = marker);
          }
          _snapshotUndo();
        },
        onPanUpdate: (details) {
          final current = _markers.firstWhere((item) => item.id == marker.id);
          final next = ArcNormalizedPoint(
            x: current.point.x + (details.delta.dx / size.width),
            y: current.point.y + (details.delta.dy / size.height),
          ).clamp();
          final updated = current.copyWith(point: next);
          setState(() {
            _markers = [
              for (final item in _markers)
                if (item.id == marker.id) updated else item,
            ];
            _selected = updated;
          });
        },
        child: Tooltip(
          message:
              '${marker.name}\nX ${marker.point.x.toStringAsFixed(4)} • Y ${marker.point.y.toStringAsFixed(4)}',
          child: AnimatedContainer(
            duration: AppTheme.fastAnimation,
            width: selected ? 42 : 36,
            height: selected ? 42 : 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.88),
              border: Border.all(
                color: selected ? Colors.white : _kindColor(marker.kind),
                width: selected ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _kindColor(marker.kind).withValues(alpha: 0.45),
                  blurRadius: selected ? 18 : 10,
                ),
              ],
            ),
            child: Icon(
              _kindIcon(marker.kind),
              size: selected ? 21 : 17,
              color: _kindColor(marker.kind),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidePanel() {
    return Container(
      decoration: AppTheme.tradingCardDecoration(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                ElevatedButton.icon(
                  onPressed: _createMarker,
                  icon: const Icon(Icons.add_location_alt_rounded),
                  label: const Text('New Intel'),
                ),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _saveDrafts,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Draft'),
                ),
                OutlinedButton.icon(
                  onPressed: _exportJson,
                  icon: const Icon(Icons.data_object_rounded),
                  label: const Text('Export JSON'),
                ),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _importJsonFromClipboard,
                  icon: const Icon(Icons.input_rounded),
                  label: const Text('Import JSON'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                _importDashboardCard(),
                const SizedBox(height: 10),
                _markerFiltersCard(),
                const SizedBox(height: 10),
                if (_selected != null) _selectedCard(_selected!),
                const SizedBox(height: 10),
                Text(
                  '${_visibleMarkers.length} MARKERS',
                  style: AppTheme.bodyTextStyle(
                    fontSize: 10,
                    color: AppTheme.neonCyan,
                    isBold: true,
                  ),
                ),
                const SizedBox(height: 6),
                for (final marker in _visibleMarkers)
                  ListTile(
                    dense: true,
                    selected: _selected?.id == marker.id,
                    leading: Icon(
                      _kindIcon(marker.kind),
                      color: _kindColor(marker.kind),
                    ),
                    title: Text(
                      marker.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${marker.kind.label} • ${marker.point.x.toStringAsFixed(4)}, ${marker.point.y.toStringAsFixed(4)}',
                    ),
                    trailing: _markerStateIcon(marker),
                    onTap: () => setState(() => _selected = marker),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selected == null || _saving
                        ? null
                        : _publishSelected,
                    icon: const Icon(Icons.cloud_upload_rounded),
                    label: const Text('Publish Selected'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Publish all visible markers',
                  onPressed: _visibleMarkers.isEmpty || _saving
                      ? null
                      : _publishAll,
                  icon: const Icon(Icons.cloud_sync_rounded),
                ),
                IconButton(
                  tooltip: 'Publish eligible imported markers',
                  onPressed: _saving ? null : _publishEligibleImports,
                  icon: const Icon(Icons.verified_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _importDashboardCard() {
    final imported = _importedMarkers;
    final exceptions = imported.where((marker) => marker.hasImportException);
    final provisional = imported.where((marker) => marker.provisionalVisible);
    final duplicateGroups = imported
        .map((marker) => marker.duplicateGroupId)
        .whereType<String>()
        .toSet();
    final confidenceValues = imported
        .map((marker) => marker.alignmentConfidence)
        .whereType<double>()
        .toList(growable: false);
    final averageConfidence = confidenceValues.isEmpty
        ? null
        : confidenceValues.reduce((a, b) => a + b) / confidenceValues.length;
    final last = _lastImportSummary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonCyan.withValues(alpha: 0.28),
        backgroundColor: Colors.black.withValues(alpha: 0.26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('IMPORT PIPELINE', style: _sectionLabelStyle()),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metricPill('Cached', imported.length.toString()),
              _metricPill('Exceptions', exceptions.length.toString()),
              _metricPill('Provisional', provisional.length.toString()),
              _metricPill('Groups', duplicateGroups.length.toString()),
              _metricPill(
                'Alignment',
                averageConfidence == null
                    ? 'None'
                    : '${(averageConfidence * 100).round()}%',
              ),
            ],
          ),
          if (last != null) ...[
            const SizedBox(height: 8),
            Text(
              '${last.source.name}: ${last.totalRecords} records • '
              '${last.alignment.confidenceLabel} alignment • '
              '${last.duplicateCount} duplicates',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              OutlinedButton.icon(
                onPressed: _saving ? null : _importJsonFromClipboard,
                icon: const Icon(Icons.content_paste_go_rounded),
                label: const Text('Import Clipboard'),
              ),
              TextButton.icon(
                onPressed: _reprocessImportCache,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reprocess Cache'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _markerFiltersCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: AppTheme.tradingCardDecoration(
        backgroundColor: Colors.black.withValues(alpha: 0.18),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search markers',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<ArcAdminMapMarkerKind?>(
            isExpanded: true,
            initialValue: _kindFilter,
            decoration: const InputDecoration(labelText: 'Category filter'),
            items: <DropdownMenuItem<ArcAdminMapMarkerKind?>>[
              const DropdownMenuItem<ArcAdminMapMarkerKind?>(
                value: null,
                child: Text('All marker categories'),
              ),
              for (final kind in ArcAdminMapMarkerKind.values)
                DropdownMenuItem<ArcAdminMapMarkerKind?>(
                  value: kind,
                  child: Text(kind.label),
                ),
            ],
            onChanged: (value) => setState(() => _kindFilter = value),
          ),
        ],
      ),
    );
  }

  Widget _metricPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(color: Colors.white70, fontSize: 11),
      ),
    );
  }

  Widget _markerStateIcon(ArcAdminMapMarker marker) {
    if (marker.hasImportException) {
      return const Icon(
        Icons.report_problem_rounded,
        color: Colors.redAccent,
        size: 18,
      );
    }
    if (marker.isPublished) {
      return const Icon(
        Icons.cloud_done_rounded,
        color: Colors.lightGreenAccent,
        size: 18,
      );
    }
    if (marker.provisionalVisible) {
      return const Icon(
        Icons.visibility_rounded,
        color: AppTheme.neonCyan,
        size: 18,
      );
    }
    return const Icon(
      Icons.edit_note_rounded,
      color: Colors.amberAccent,
      size: 18,
    );
  }

  TextStyle _sectionLabelStyle() {
    return AppTheme.bodyTextStyle(
      fontSize: 10,
      color: AppTheme.neonCyan,
      isBold: true,
    );
  }

  Widget _selectedCard(ArcAdminMapMarker marker) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: _kindColor(marker.kind).withValues(alpha: 0.45),
        backgroundColor: Colors.black.withValues(alpha: 0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(marker.name, style: AppTheme.tradingHeading(fontSize: 20)),
          const SizedBox(height: 3),
          Text(
            marker.kind.label,
            style: TextStyle(color: _kindColor(marker.kind)),
          ),
          const SizedBox(height: 8),
          SelectableText(
            'X ${marker.point.x.toStringAsFixed(6)}\n'
            'Y ${marker.point.y.toStringAsFixed(6)}',
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'monospace',
            ),
          ),
          if (marker.description.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              marker.description,
              style: const TextStyle(color: Colors.white60),
            ),
          ],
          if (marker.blueprintId != null) ...[
            const SizedBox(height: 6),
            Text(
              'Blueprint: ${marker.blueprintId}',
              style: const TextStyle(color: AppTheme.neonCyan),
            ),
          ],
          if (marker.sourceRecordId != null) ...[
            const SizedBox(height: 8),
            Text(
              'Source: ${marker.sourceName ?? marker.sourceLabel} • '
              '${marker.sourcePermission.label}',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
            if (marker.alignmentConfidence != null)
              Text(
                'Alignment ${(marker.alignmentConfidence! * 100).round()}% '
                '• ${marker.coordinateSpace ?? 'normalized'}',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            if (marker.exceptionReason?.trim().isNotEmpty == true)
              Text(
                'Review: ${marker.exceptionReason}',
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
          ],
          const SizedBox(height: 9),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (marker.kind.isSeedDefinition)
                TextButton.icon(
                  onPressed: _resetSelected,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Reset'),
                ),
              TextButton.icon(
                onPressed: _deleteSelected,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Remove'),
              ),
              TextButton.icon(
                onPressed: () => Clipboard.setData(
                  ClipboardData(text: jsonEncode(marker.toJsonMap())),
                ),
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _kindColor(ArcAdminMapMarkerKind kind) {
    switch (kind) {
      case ArcAdminMapMarkerKind.poi:
        return AppTheme.neonCyan;
      case ArcAdminMapMarkerKind.extraction:
        return Colors.lightGreenAccent;
      case ArcAdminMapMarkerKind.raiderHatch:
        return Colors.amberAccent;
      case ArcAdminMapMarkerKind.blueprint:
        return AppTheme.neonPink;
      case ArcAdminMapMarkerKind.questLocation:
        return Colors.cyanAccent;
      case ArcAdminMapMarkerKind.resourceNode:
        return Colors.tealAccent;
      case ArcAdminMapMarkerKind.weaponCache:
        return Colors.orangeAccent;
      case ArcAdminMapMarkerKind.lootContainer:
      case ArcAdminMapMarkerKind.highValueLoot:
        return Colors.yellowAccent;
      case ArcAdminMapMarkerKind.lockedRoom:
        return Colors.deepPurpleAccent;
      case ArcAdminMapMarkerKind.arcThreat:
      case ArcAdminMapMarkerKind.extractionDanger:
        return Colors.redAccent;
      case ArcAdminMapMarkerKind.customIntel:
        return Colors.white70;
    }
  }

  IconData _kindIcon(ArcAdminMapMarkerKind kind) {
    switch (kind) {
      case ArcAdminMapMarkerKind.poi:
        return Icons.location_city_rounded;
      case ArcAdminMapMarkerKind.extraction:
        return Icons.exit_to_app_rounded;
      case ArcAdminMapMarkerKind.raiderHatch:
        return Icons.key_rounded;
      case ArcAdminMapMarkerKind.blueprint:
        return Icons.extension_rounded;
      case ArcAdminMapMarkerKind.questLocation:
        return Icons.assignment_turned_in_rounded;
      case ArcAdminMapMarkerKind.resourceNode:
        return Icons.construction_rounded;
      case ArcAdminMapMarkerKind.weaponCache:
        return Icons.gps_fixed_rounded;
      case ArcAdminMapMarkerKind.lootContainer:
        return Icons.inventory_2_rounded;
      case ArcAdminMapMarkerKind.lockedRoom:
        return Icons.lock_rounded;
      case ArcAdminMapMarkerKind.highValueLoot:
        return Icons.diamond_rounded;
      case ArcAdminMapMarkerKind.arcThreat:
        return Icons.warning_amber_rounded;
      case ArcAdminMapMarkerKind.extractionDanger:
        return Icons.crisis_alert_rounded;
      case ArcAdminMapMarkerKind.customIntel:
        return Icons.push_pin_rounded;
    }
  }
}

class _NewMarkerResult {
  const _NewMarkerResult({
    required this.kind,
    required this.name,
    required this.description,
    required this.sourceLabel,
    required this.confidence,
    this.blueprintId,
  });

  final ArcAdminMapMarkerKind kind;
  final String name;
  final String description;
  final String sourceLabel;
  final ArcRaidIntelConfidence confidence;
  final String? blueprintId;
}

class _NewMarkerDialog extends StatefulWidget {
  const _NewMarkerDialog();

  @override
  State<_NewMarkerDialog> createState() => _NewMarkerDialogState();
}

class _NewMarkerDialogState extends State<_NewMarkerDialog> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _source = TextEditingController(text: 'Mike / Admin Intel');
  ArcAdminMapMarkerKind _kind = ArcAdminMapMarkerKind.customIntel;
  ArcRaidIntelConfidence _confidence = ArcRaidIntelConfidence.confirmed;
  String? _blueprintId;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blueprints = ArcBlueprintSeedData.blueprints;

    return AlertDialog(
      title: const Text('Create Admin Intel Marker'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField<ArcAdminMapMarkerKind>(
                isExpanded: true,
                initialValue: _kind,
                decoration: const InputDecoration(labelText: 'Marker type'),
                items: [
                  for (final kind in ArcAdminMapMarkerKind.values)
                    if (!kind.isSeedDefinition)
                      DropdownMenuItem(value: kind, child: Text(kind.label)),
                ],
                onChanged: (value) => setState(() => _kind = value ?? _kind),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description / directions',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _source,
                decoration: const InputDecoration(labelText: 'Intel source'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String?>(
                isExpanded: true,
                initialValue: _blueprintId,
                decoration: const InputDecoration(
                  labelText: 'Linked Blueprint (optional)',
                ),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('No Blueprint'),
                  ),
                  for (final ArcBlueprint blueprint in blueprints)
                    DropdownMenuItem<String?>(
                      value: blueprint.id,
                      child: Text(blueprint.name),
                    ),
                ],
                onChanged: (value) => setState(() => _blueprintId = value),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<ArcRaidIntelConfidence>(
                isExpanded: true,
                initialValue: _confidence,
                decoration: const InputDecoration(labelText: 'Confidence'),
                items: [
                  for (final confidence in ArcRaidIntelConfidence.values)
                    DropdownMenuItem(
                      value: confidence,
                      child: Text(confidence.label),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _confidence = value ?? _confidence),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(
              context,
              _NewMarkerResult(
                kind: _kind,
                name: name,
                description: _description.text.trim(),
                sourceLabel: _source.text.trim().isEmpty
                    ? 'Admin Intel'
                    : _source.text.trim(),
                confidence: _confidence,
                blueprintId: _blueprintId,
              ),
            );
          },
          child: const Text('Create at Map Centre'),
        ),
      ],
    );
  }
}
