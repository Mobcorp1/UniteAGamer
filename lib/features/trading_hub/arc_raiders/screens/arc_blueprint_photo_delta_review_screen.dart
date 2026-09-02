import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_import_service.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_layout_system.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

class ArcBlueprintPhotoDeltaReviewScreen extends StatefulWidget {
  const ArcBlueprintPhotoDeltaReviewScreen({
    super.key,
    required this.proposedAdditions,
    required this.uncertainIgnoredCount,
    this.applySelected,
  });

  final List<ArcBlueprintPhotoCellDecision> proposedAdditions;
  final int uncertainIgnoredCount;
  final Future<void> Function(List<ArcBlueprintPhotoCellDecision> selected)?
  applySelected;

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

    setState(() => _saving = true);
    try {
      final applySelected = widget.applySelected;
      if (applySelected == null) {
        await ArcBlueprintPhotoImportService().apply(selected);
      } else {
        await applySelected(selected);
      }
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'REVIEW NEW BLUEPRINTS',
          style: ArcUiTokens.pageTitle(color: ArcUiTokens.primaryAccent),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ArcTacticalPageBody(
        width: ArcPageWidth.standard,
        maxWidth: 960,
        padding: EdgeInsets.zero,
        scrollable: false,
        child: Column(
          children: [
            Padding(
              padding: ArcLayoutTokens.pagePadding(
                context,
              ).copyWith(bottom: 10),
              child: ArcTacticalPanel(
                icon: Icons.playlist_add_check_circle_outlined,
                title: 'Detected Blueprint Additions',
                accent: ArcUiTokens.primaryAccent,
                child: Text(
                  '${widget.proposedAdditions.length} confidently detected '
                  'Blueprint${widget.proposedAdditions.length == 1 ? '' : 's'} '
                  'are not currently marked owned. Uncheck anything the scan '
                  'got wrong. ${widget.uncertainIgnoredCount} uncertain slot'
                  '${widget.uncertainIgnoredCount == 1 ? '' : 's'} will be '
                  'ignored and left exactly as they are.',
                  style: ArcUiTokens.body(fontSize: 13),
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
                    color: ArcUiTokens.surfacePanel,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ArcUiTokens.radiusL),
                      side: BorderSide(
                        color: selected
                            ? ArcUiTokens.primaryAccent.withValues(alpha: 0.42)
                            : ArcUiTokens.borderMedium,
                      ),
                    ),
                    child: CheckboxListTile(
                      key: ValueKey('delta-${decision.blueprintId}'),
                      value: selected,
                      onChanged: _saving
                          ? null
                          : (value) => _setSelected(
                              decision.blueprintId,
                              value == true,
                            ),
                      activeColor: ArcUiTokens.primaryAccent,
                      checkColor: Colors.black,
                      title: Text(
                        _nameFor(decision.blueprintId),
                        style: ArcUiTokens.cardTitle(fontSize: 14),
                      ),
                      subtitle: Text(
                        '${_positionFor(decision)} - '
                        '${(decision.confidence * 100).round()}% confidence',
                        style: ArcUiTokens.bodySmall(),
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
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
                    : 'Update Blueprint Grid',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
