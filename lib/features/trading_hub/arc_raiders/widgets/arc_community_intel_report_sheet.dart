import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_community_intel_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_community_intel_repository.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

typedef ArcCommunityIntelSubmitter =
    Future<String> Function({
      required String mapId,
      required ArcRaidMapLayer layer,
      required ArcCommunityIntelCategory category,
      required ArcNormalizedPoint point,
      String? poiId,
      String? poiName,
      String? blueprintId,
      String? blueprintName,
      String notes,
    });

enum _IntelLocationChoice { exactPin, nearbyPoi }

class ArcCommunityIntelReportSheet extends StatefulWidget {
  const ArcCommunityIntelReportSheet({
    required this.map,
    required this.layer,
    required this.point,
    this.repository,
    this.submitter,
    this.onSubmitted,
    super.key,
  }) : assert(repository != null || submitter != null);

  final ArcRaidMap map;
  final ArcRaidMapLayer layer;
  final ArcNormalizedPoint point;
  final ArcCommunityIntelRepository? repository;
  final ArcCommunityIntelSubmitter? submitter;
  final VoidCallback? onSubmitted;

  @override
  State<ArcCommunityIntelReportSheet> createState() =>
      _ArcCommunityIntelReportSheetState();
}

class _ArcCommunityIntelReportSheetState
    extends State<ArcCommunityIntelReportSheet> {
  final TextEditingController _notesController = TextEditingController();
  ArcCommunityIntelCategory? _category;
  ArcBlueprint? _blueprint;
  _IntelLocationChoice? _locationChoice;
  int _step = 0;
  int _direction = 1;
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

  int get _totalSteps =>
      _category == ArcCommunityIntelCategory.blueprintFound ? 5 : 4;

  String get _stepLabel {
    if (_step == 0) return 'Intel type';
    if (_category == ArcCommunityIntelCategory.blueprintFound) {
      return switch (_step) {
        1 => 'Blueprint',
        2 => 'Location',
        3 => 'Notes',
        _ => 'Review',
      };
    }
    return switch (_step) {
      1 => 'Location',
      2 => 'Notes',
      _ => 'Review',
    };
  }

  void _goTo(int value) {
    final next = value.clamp(0, _totalSteps - 1);
    setState(() {
      _direction = next >= _step ? 1 : -1;
      _step = next;
    });
  }

  void _advance() => _goTo(_step + 1);

  void _selectCategory(ArcCommunityIntelCategory category) {
    setState(() {
      _category = category;
      if (category != ArcCommunityIntelCategory.blueprintFound) {
        _blueprint = null;
      }
    });
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (mounted) _advance();
    });
  }

  Future<void> _submit() async {
    final category = _category;
    if (_saving || category == null) return;
    if (category == ArcCommunityIntelCategory.blueprintFound &&
        _blueprint == null) {
      _goTo(1);
      return;
    }
    if (_locationChoice == null) {
      _goTo(category == ArcCommunityIntelCategory.blueprintFound ? 2 : 1);
      return;
    }

    setState(() => _saving = true);
    try {
      final usePoi = _locationChoice == _IntelLocationChoice.nearbyPoi;
      final poi = usePoi ? _nearestPoi : null;
      final submitter = widget.submitter;
      if (submitter != null) {
        await submitter(
          mapId: widget.map.id,
          layer: widget.layer,
          category: category,
          point: widget.point,
          poiId: poi?.id,
          poiName: poi?.name,
          blueprintId: _blueprint?.id,
          blueprintName: _blueprint?.name,
          notes: _notesController.text,
        );
      } else {
        await widget.repository!.submit(
          mapId: widget.map.id,
          layer: widget.layer,
          category: category,
          point: widget.point,
          poiId: poi?.id,
          poiName: poi?.name,
          blueprintId: _blueprint?.id,
          blueprintName: _blueprint?.name,
          notes: _notesController.text,
        );
      }
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
    final progress = (_step + 1) / _totalSteps;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 14,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Text(
              '${widget.map.displayName} • ${widget.layer.label} • '
              '${(widget.point.x * 100).toStringAsFixed(1)}, '
              '${(widget.point.y * 100).toStringAsFixed(1)}',
              style: const TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${_step + 1}/$_totalSteps • $_stepLabel',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: math.min(MediaQuery.sizeOf(context).height * 0.55, 520.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, animation) {
                  final begin = Offset(_direction.toDouble(), 0);
                  return ClipRect(
                    child: SlideTransition(
                      position: Tween<Offset>(begin: begin, end: Offset.zero)
                          .animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                  );
                },
                child: SingleChildScrollView(
                  key: ValueKey<int>(_step),
                  child: _buildStep(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _step == 0 || _saving
                      ? null
                      : () => _goTo(_step - 1),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back'),
                ),
                const Spacer(),
                if (_step < _totalSteps - 1)
                  ElevatedButton.icon(
                    onPressed: _canContinue ? _advance : null,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Next'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(_saving ? 'Submitting…' : 'Submit Intel'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool get _canContinue {
    if (_step == 0) return _category != null;
    if (_category == ArcCommunityIntelCategory.blueprintFound) {
      if (_step == 1) return _blueprint != null;
      if (_step == 2) return _locationChoice != null;
    } else if (_step == 1) {
      return _locationChoice != null;
    }
    return true;
  }

  Widget _buildStep() {
    if (_step == 0) return _categoryStep();
    if (_category == ArcCommunityIntelCategory.blueprintFound) {
      return switch (_step) {
        1 => _blueprintStep(),
        2 => _locationStep(),
        3 => _notesStep(),
        _ => _reviewStep(),
      };
    }
    return switch (_step) {
      1 => _locationStep(),
      2 => _notesStep(),
      _ => _reviewStep(),
    };
  }

  Widget _card({
    required String title,
    required Widget child,
    String? subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.tradingCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.tradingHeading(fontSize: 20)),
          if (subtitle != null) ...[
            const SizedBox(height: 5),
            Text(subtitle, style: const TextStyle(color: Colors.white60)),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _categoryStep() {
    return _card(
      title: 'What did you find?',
      subtitle: 'Choose one Intel type. The next card opens automatically.',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final category in ArcCommunityIntelCategory.values)
            ChoiceChip(
              selected: _category == category,
              showCheckmark: false,
              label: Text(category.shortLabel),
              onSelected: (_) => _selectCategory(category),
            ),
        ],
      ),
    );
  }

  Widget _blueprintStep() {
    return _card(
      title: 'Which Blueprint?',
      subtitle: 'Select the Blueprint found at this location.',
      child: DropdownButtonFormField<String>(
        initialValue: _blueprint?.id,
        isExpanded: true,
        dropdownColor: AppTheme.cardBackgroundAlt,
        decoration: AppTheme.tradingInputDecoration(label: 'Blueprint found'),
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
          Future<void>.delayed(const Duration(milliseconds: 180), () {
            if (mounted) _advance();
          });
        },
      ),
    );
  }

  Widget _locationStep() {
    final poi = _nearestPoi;
    return _card(
      title: 'Where was it?',
      subtitle: 'Keep the exact pin or deliberately attach it to a named POI.',
      child: Column(
        children: [
          _locationChoiceTile(
            key: const ValueKey<String>('intel-location-exact-pin'),
            selected: _locationChoice == _IntelLocationChoice.exactPin,
            title: 'No listed POI — use exact dropped pin',
            subtitle:
                'X ${(widget.point.x * 100).toStringAsFixed(1)} • '
                'Y ${(widget.point.y * 100).toStringAsFixed(1)}',
            onTap: () =>
                setState(() => _locationChoice = _IntelLocationChoice.exactPin),
          ),
          if (poi != null)
            _locationChoiceTile(
              key: const ValueKey<String>('intel-location-nearby-poi'),
              selected: _locationChoice == _IntelLocationChoice.nearbyPoi,
              title: 'Attach to ${poi.name}',
              subtitle: 'Use only when the report was at this POI.',
              onTap: () => setState(
                () => _locationChoice = _IntelLocationChoice.nearbyPoi,
              ),
            )
          else
            const ListTile(
              leading: Icon(Icons.location_off_outlined),
              title: Text('No nearby named POI'),
              subtitle: Text('This report will remain coordinate-based.'),
            ),
        ],
      ),
    );
  }

  Widget _locationChoiceTile({
    required Key key,
    required bool selected,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        key: key,
        color: selected
            ? AppTheme.neonCyan.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected ? AppTheme.neonCyan : Colors.white54,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _notesStep() {
    return _card(
      title: 'Add useful detail',
      subtitle: 'Optional. Keep it short and factual.',
      child: TextField(
        controller: _notesController,
        maxLength: 280,
        maxLines: 4,
        decoration: AppTheme.tradingInputDecoration(label: 'Optional notes'),
      ),
    );
  }

  Widget _reviewStep() {
    final poi = _locationChoice == _IntelLocationChoice.nearbyPoi
        ? _nearestPoi
        : null;
    return _card(
      title: 'Review Intel',
      subtitle: 'Nothing is submitted until you confirm.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _reviewRow('Type', _category?.label ?? 'Not selected'),
          if (_blueprint != null) _reviewRow('Blueprint', _blueprint!.name),
          _reviewRow(
            'Map',
            '${widget.map.displayName} • ${widget.layer.label}',
          ),
          _reviewRow(
            'Location',
            poi?.name ??
                'Exact pin ${(widget.point.x * 100).toStringAsFixed(1)}, '
                    '${(widget.point.y * 100).toStringAsFixed(1)}',
          ),
          if (_notesController.text.trim().isNotEmpty)
            _reviewRow('Notes', _notesController.text.trim()),
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(label, style: const TextStyle(color: Colors.white54)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
