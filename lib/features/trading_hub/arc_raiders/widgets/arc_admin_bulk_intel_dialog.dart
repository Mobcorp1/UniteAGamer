import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_admin_marker_subtype_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_bulk_map_intel_plan.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_container_types.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

/// Only launched after the parent editor has verified the user's admin role.
/// Does not publish anything; returns a reviewed draft request to the editor.
class ArcAdminBulkIntelDialog extends StatefulWidget {
  const ArcAdminBulkIntelDialog({super.key, required this.initialMapId});
  final String initialMapId;

  @override
  State<ArcAdminBulkIntelDialog> createState() =>
      _ArcAdminBulkIntelDialogState();
}

class _ArcAdminBulkIntelDialogState extends State<ArcAdminBulkIntelDialog> {
  final _name = TextEditingController();
  final _notes = TextEditingController();
  final _condition = TextEditingController();
  final _source = TextEditingController(text: 'UAG Admin Bulk Intel');
  final Map<String, Set<String>> _targets = {};
  final Set<String> _containers = {};
  ArcAdminMapMarkerKind _kind = ArcAdminMapMarkerKind.naturalResource;
  ArcRaidIntelConfidence _confidence = ArcRaidIntelConfidence.moderate;
  bool _noContainer = true;
  String? _blueprintId;
  String? _subtypeId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _targets[widget.initialMapId] = <String>{};
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    _condition.dispose();
    _source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maps = ArcRaidIntelligenceSeedData.maps;
    final subtypes = ArcAdminMapMarkerSubtypeCatalog.forKind(_kind);
    final subtype = subtypes.where((item) => item.id == _subtypeId).firstOrNull;
    final validSubtypeId = subtype?.id;
    final previewCount = _targets.values.fold<int>(
      0,
      (sum, pois) => sum + (pois.isEmpty ? 1 : pois.length),
    );

    return AlertDialog(
      key: const Key('admin-bulk-intel-dialog'),
      backgroundColor: ArcUiTokens.surfaceOverlay,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: ArcUiTokens.secondaryAccent.withValues(alpha: .7),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      title: const Text(
        'BULK ADD INTEL',
        style: TextStyle(color: ArcUiTokens.secondaryAccent),
      ),
      content: SizedBox(
        width: 680,
        height: (MediaQuery.sizeOf(context).height - 230)
            .clamp(90.0, 520.0)
            .toDouble(),
        child: ListView(
          children: [
            const Text(
              'ADMIN ONLY · Drafts first · Approximate POIs are not exact spawn coordinates.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ArcAdminMapMarkerKind>(
              key: const Key('admin-bulk-kind'),
              isExpanded: true,
              initialValue: _kind,
              decoration: const InputDecoration(
                labelText: 'Intelligence category',
              ),
              items: [
                for (final kind in ArcAdminMapMarkerKind.values)
                  DropdownMenuItem(value: kind, child: Text(kind.label)),
              ],
              onChanged: (value) => setState(() {
                _kind = value ?? _kind;
                _subtypeId = null;
                _blueprintId = null;
                _noContainer = _kind == ArcAdminMapMarkerKind.naturalResource;
                _containers.clear();
              }),
            ),
            const SizedBox(height: 10),
            if (subtypes.isNotEmpty) ...[
              DropdownButtonFormField<String?>(
                key: ValueKey('bulk-subtype-${_kind.name}'),
                isExpanded: true,
                initialValue: validSubtypeId,
                decoration: const InputDecoration(
                  labelText: 'Item / marker subtype (optional)',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('No subtype'),
                  ),
                  for (final item in subtypes)
                    DropdownMenuItem<String?>(
                      value: item.id,
                      child: Text(item.label, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) => setState(() {
                  _subtypeId = value;
                  final selected = subtypes
                      .where((item) => item.id == value)
                      .firstOrNull;
                  if (selected != null) {
                    _name.text = selected.label;
                  }
                }),
              ),
              const SizedBox(height: 10),
            ],
            if (_kind == ArcAdminMapMarkerKind.blueprint) ...[
              DropdownButtonFormField<String?>(
                key: const Key('admin-bulk-blueprint'),
                isExpanded: true,
                initialValue: _blueprintId,
                decoration: const InputDecoration(
                  labelText: 'Blueprint (required)',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Choose Blueprint'),
                  ),
                  for (final bp in ArcBlueprintSeedData.blueprints)
                    DropdownMenuItem<String?>(
                      value: bp.id,
                      child: Text(bp.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) => setState(() {
                  _blueprintId = value;
                  final found = ArcBlueprintSeedData.blueprints
                      .where((bp) => bp.id == value)
                      .firstOrNull;
                  if (found != null) {
                    _name.text = found.name;
                  }
                }),
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Name of item, spawn or intel',
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'MAPS & POIs (${_targets.length} maps)',
              style: const TextStyle(
                color: ArcUiTokens.primaryAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tick a map for map-wide intel. Tick POIs inside it to create approximate POI pins instead.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            for (final map in maps)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(map.displayName),
                subtitle: _targets.containsKey(map.id)
                    ? Text(
                        _targets[map.id]!.isEmpty
                            ? 'Entire map / POI unknown — no pin'
                            : '${_targets[map.id]!.length} named POIs',
                        style: const TextStyle(
                          color: ArcUiTokens.secondaryAccent,
                        ),
                      )
                    : null,
                value: _targets.containsKey(map.id),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _targets[map.id] = <String>{};
                  } else {
                    _targets.remove(map.id);
                  }
                }),
                secondary: _targets.containsKey(map.id) && map.pois.isNotEmpty
                    ? IconButton(
                        tooltip: 'Select POIs on ${map.displayName}',
                        icon: const Icon(
                          Icons.list_alt_rounded,
                          color: ArcUiTokens.primaryAccent,
                        ),
                        onPressed: () => _selectPois(map),
                      )
                    : null,
              ),
            const Divider(),
            const Text(
              'CONTAINERS / SOURCES',
              style: TextStyle(
                color: ArcUiTokens.primaryAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            CheckboxListTile(
              key: const Key('admin-bulk-no-container'),
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'None / No container (nature or open-world spawns)',
              ),
              value: _noContainer,
              onChanged: (v) => setState(() {
                _noContainer = v == true;
                if (_noContainer) {
                  _containers.clear();
                }
              }),
            ),
            if (!_noContainer)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final container in ArcContainerTypes.reportable)
                    FilterChip(
                      label: Text(container.label),
                      selected: _containers.contains(container.id),
                      onSelected: (v) => setState(() {
                        if (v) {
                          _containers.add(container.id);
                        } else {
                          _containers.remove(container.id);
                        }
                      }),
                    ),
                ],
              ),
            const SizedBox(height: 10),
            DropdownButtonFormField<ArcRaidIntelConfidence>(
              initialValue: _confidence,
              decoration: const InputDecoration(
                labelText: 'Evidence confidence',
              ),
              items: [
                for (final level in ArcRaidIntelConfidence.values)
                  DropdownMenuItem(value: level, child: Text(level.label)),
              ],
              onChanged: (v) => setState(() => _confidence = v ?? _confidence),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _condition,
              decoration: const InputDecoration(
                labelText: 'Map condition (optional)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _source,
              decoration: const InputDecoration(labelText: 'Intel source'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Evidence and directions (optional)',
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Preview: $previewCount draft records · ${_targets.values.where((v) => v.isEmpty).length} unlocated · 0 published',
              key: const Key('admin-bulk-preview'),
              style: const TextStyle(color: ArcUiTokens.secondaryAccent),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          key: const Key('admin-bulk-create-drafts'),
          onPressed: previewCount == 0
              ? null
              : () {
                  try {
                    final request = ArcBulkIntelRequest(
                      kind: _kind,
                      name: _name.text,
                      mapPoiIds: {
                        for (final e in _targets.entries)
                          e.key: Set<String>.from(e.value),
                      },
                      containerTypeIds: Set<String>.from(_containers),
                      noContainer: _noContainer,
                      confidence: _confidence,
                      blueprintId: _blueprintId,
                      subtypeId: validSubtypeId,
                      subtypeLabel: subtype?.label,
                      itemId: subtype?.upgradeResource?.itemId,
                      description: _notes.text,
                      conditionLabel: _condition.text,
                      sourceLabel: _source.text,
                    );
                    ArcBulkIntelPlan.build(request); // Validate before closing.
                    Navigator.pop(context, request);
                  } catch (error) {
                    setState(() => _error = error.toString());
                  }
                },
          icon: const Icon(Icons.save_outlined),
          label: const Text('Create drafts'),
        ),
      ],
    );
  }

  Future<void> _selectPois(ArcRaidMap map) async {
    final selected = Set<String>.from(_targets[map.id] ?? {});
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text('${map.displayName} — POIs'),
          content: SizedBox(
            width: 480,
            height: (MediaQuery.sizeOf(context).height - 225)
                .clamp(90.0, 520.0)
                .toDouble(),
            child: ListView(
              children: [
                ListTile(
                  title: const Text('Entire map / POI unknown'),
                  subtitle: const Text('No coordinate or pin will be created.'),
                  trailing: selected.isEmpty
                      ? const Icon(
                          Icons.check,
                          color: ArcUiTokens.secondaryAccent,
                        )
                      : null,
                  onTap: () => update(() {
                    selected.clear();
                  }),
                ),
                for (final poi in map.pois)
                  CheckboxListTile(
                    dense: true,
                    title: Text(poi.name),
                    value: selected.contains(poi.id),
                    onChanged: (v) => update(() {
                      if (v == true) {
                        selected.add(poi.id);
                      } else {
                        selected.remove(poi.id);
                      }
                    }),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, selected),
              child: const Text('Apply POIs'),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _targets[map.id] = result);
    }
  }
}
