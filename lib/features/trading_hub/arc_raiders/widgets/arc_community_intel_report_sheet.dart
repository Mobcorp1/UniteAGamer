import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_community_intel_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_community_intel_repository.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcCommunityIntelReportSheet extends StatefulWidget {
  const ArcCommunityIntelReportSheet({
    required this.map,
    required this.layer,
    required this.point,
    required this.repository,
    this.onSubmitted,
    super.key,
  });

  final ArcRaidMap map;
  final ArcRaidMapLayer layer;
  final ArcNormalizedPoint point;
  final ArcCommunityIntelRepository repository;
  final VoidCallback? onSubmitted;

  @override
  State<ArcCommunityIntelReportSheet> createState() =>
      _ArcCommunityIntelReportSheetState();
}

class _ArcCommunityIntelReportSheetState
    extends State<ArcCommunityIntelReportSheet> {
  final TextEditingController _notesController = TextEditingController();
  ArcCommunityIntelCategory _category =
      ArcCommunityIntelCategory.blueprintFound;
  ArcBlueprint? _blueprint;
  bool _saving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  ArcRaidMapPoi? get _nearestPoi {
    if (widget.map.pois.isEmpty) return null;
    final pois = List<ArcRaidMapPoi>.from(widget.map.pois)
      ..sort((a, b) {
        final aDistance = _distance(a.point, widget.point);
        final bDistance = _distance(b.point, widget.point);
        return aDistance.compareTo(bDistance);
      });
    final nearest = pois.first;
    return _distance(nearest.point, widget.point) <= 0.12 ? nearest : null;
  }

  double _distance(ArcNormalizedPoint a, ArcNormalizedPoint b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return math.sqrt((dx * dx) + (dy * dy));
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (_category == ArcCommunityIntelCategory.blueprintFound &&
        _blueprint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose the Blueprint that was found.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final poi = _nearestPoi;
      await widget.repository.submit(
        mapId: widget.map.id,
        layer: widget.layer,
        category: _category,
        point: widget.point,
        poiId: poi?.id,
        poiName: poi?.name,
        blueprintId: _blueprint?.id,
        blueprintName: _blueprint?.name,
        notes: _notesController.text,
      );
      if (!mounted) return;
      widget.onSubmitted?.call();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Community Intel submitted.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not submit Intel: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final poi = _nearestPoi;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 14,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.add_location_alt_rounded),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'REPORT COMMUNITY INTEL',
                      style: AppTheme.tradingHeading(fontSize: 22),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.map.displayName} • ${widget.layer.label} • '
                '${(widget.point.x * 100).toStringAsFixed(1)}, '
                '${(widget.point.y * 100).toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.white60),
              ),
              if (poi != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Nearest POI: ${poi.name}',
                  style: TextStyle(color: AppTheme.neonCyan),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in ArcCommunityIntelCategory.values)
                    ChoiceChip(
                      selected: _category == category,
                      showCheckmark: false,
                      label: Text(category.shortLabel),
                      onSelected: (_) => setState(() {
                        _category = category;
                        if (category !=
                            ArcCommunityIntelCategory.blueprintFound) {
                          _blueprint = null;
                        }
                      }),
                    ),
                ],
              ),
              if (_category == ArcCommunityIntelCategory.blueprintFound) ...[
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _blueprint?.id,
                  isExpanded: true,
                  dropdownColor: AppTheme.cardBackgroundAlt,
                  decoration: AppTheme.tradingInputDecoration(
                    label: 'Blueprint found',
                  ),
                  items: [
                    for (final blueprint in ArcBlueprintSeedData.blueprints)
                      DropdownMenuItem(
                        value: blueprint.id,
                        child: Text(
                          '${blueprint.name} • ${blueprint.rarityLabel}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _blueprint = ArcBlueprintSeedData.blueprints.firstWhere(
                        (item) => item.id == value,
                      );
                    });
                  },
                ),
              ],
              const SizedBox(height: 14),
              TextField(
                controller: _notesController,
                maxLength: 280,
                maxLines: 3,
                decoration: AppTheme.tradingInputDecoration(
                  label: 'Optional notes',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_saving ? 'Submitting…' : 'Submit Intel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
