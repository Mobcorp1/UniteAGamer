import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_import_service.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcBlueprintPhotoDeltaReviewScreen extends StatefulWidget {
  const ArcBlueprintPhotoDeltaReviewScreen({
    super.key,
    required this.proposedAdditions,
    required this.uncertainIgnoredCount,
  });

  final List<ArcBlueprintPhotoCellDecision> proposedAdditions;
  final int uncertainIgnoredCount;

  @override
  State<ArcBlueprintPhotoDeltaReviewScreen> createState() =>
      _ArcBlueprintPhotoDeltaReviewScreenState();
}

class _ArcBlueprintPhotoDeltaReviewScreenState
    extends State<ArcBlueprintPhotoDeltaReviewScreen> {
  late final Set<String> _selectedIds;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.proposedAdditions
        .map((decision) => decision.blueprintId)
        .toSet();
  }

  String _nameFor(String blueprintId) {
    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      if (blueprint.id == blueprintId) return blueprint.name;
    }
    return blueprintId;
  }

  String _positionFor(ArcBlueprintPhotoCellDecision decision) {
    final row = decision.blueprintIndex ~/ 10;
    final column = decision.blueprintIndex % 10;
    final rowLabel = String.fromCharCode('A'.codeUnitAt(0) + row);
    return '$rowLabel${column + 1}';
  }

  void _setSelected(String blueprintId, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(blueprintId);
      } else {
        _selectedIds.remove(blueprintId);
      }
    });
  }

  Future<void> _apply() async {
    if (_saving) return;

    final selected = widget.proposedAdditions
        .where((decision) => _selectedIds.contains(decision.blueprintId))
        .map(
          (decision) => decision.copyWith(
            state: ArcBlueprintPhotoCellState.owned,
            confidence: 1,
            manuallyConfirmed: true,
          ),
        )
        .toList(growable: false);

    if (selected.isEmpty) {
      Navigator.of(context).pop(false);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add selected Blueprints?'),
        content: Text(
          'Add ${selected.length} newly detected Blueprint'
          '${selected.length == 1 ? '' : 's'} to your existing tracker? '
          'Previously owned Blueprints and duplicate counts will not be changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add Selected'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await ArcBlueprintPhotoImportService().apply(selected);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.red.shade800,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Blueprint update failed: $error'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedIds.length;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('REVIEW NEW BLUEPRINTS'),
        backgroundColor: AppTheme.cardBackgroundDeep,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackgroundDeep,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.cyanAccent.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  '${widget.proposedAdditions.length} confidently detected '
                  'Blueprint${widget.proposedAdditions.length == 1 ? '' : 's'} '
                  'are not currently marked owned. Uncheck anything the scan '
                  'got wrong. ${widget.uncertainIgnoredCount} uncertain slot'
                  '${widget.uncertainIgnoredCount == 1 ? '' : 's'} will be '
                  'ignored and left exactly as they are.',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                itemCount: widget.proposedAdditions.length,
                itemBuilder: (context, index) {
                  final decision = widget.proposedAdditions[index];
                  final selected = _selectedIds.contains(decision.blueprintId);
                  return Card(
                    color: AppTheme.cardBackgroundDeep,
                    child: CheckboxListTile(
                      key: ValueKey('delta-${decision.blueprintId}'),
                      value: selected,
                      onChanged: _saving
                          ? null
                          : (value) => _setSelected(
                              decision.blueprintId,
                              value == true,
                            ),
                      activeColor: Colors.cyanAccent,
                      checkColor: Colors.black,
                      title: Text(
                        _nameFor(decision.blueprintId),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        '${_positionFor(decision)} • '
                        '${(decision.confidence * 100).round()}% confidence',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          key: const Key('blueprint-delta-apply'),
          onPressed: _saving ? null : _apply,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.playlist_add_check_circle_outlined),
          label: Text(
            selectedCount == 0
                ? 'Keep Tracker Unchanged'
                : 'Add $selectedCount Selected',
          ),
        ),
      ),
    );
  }
}
