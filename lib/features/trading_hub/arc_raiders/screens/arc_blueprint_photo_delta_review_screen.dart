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
  bool _saving = false;

  String _nameFor(String blueprintId) {
    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      if (blueprint.id == blueprintId) return blueprint.name;
    }
    return blueprintId;
  }

  Future<void> _apply() async {
    if (_saving) return;

    final additions = widget.proposedAdditions
        .map(
          (decision) => decision.copyWith(
            state: ArcBlueprintPhotoCellState.owned,
            confidence: 1,
            manuallyConfirmed: true,
          ),
        )
        .toList(growable: false);

    if (additions.isEmpty) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() => _saving = true);
    try {
      final applySelected = widget.applySelected;
      if (applySelected == null) {
        await ArcBlueprintPhotoImportService().apply(additions);
      } else {
        await applySelected(additions);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: ArcUiTokens.danger,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Blueprint update failed. Try again.'),
          backgroundColor: ArcUiTokens.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'BLUEPRINT SCAN RESULT',
          style: ArcUiTokens.pageTitle(color: ArcUiTokens.primaryAccent),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ArcTacticalPageBody(
        width: ArcPageWidth.standard,
        maxWidth: 960,
        padding: ArcLayoutTokens.pagePadding(context),
        scrollable: false,
        child: SizedBox.expand(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ArcTacticalPanel(
                icon: Icons.document_scanner_outlined,
                title: 'Detected Ownership',
                accent: ArcUiTokens.primaryAccent,
                child: Text(
                  '${widget.proposedAdditions.length} new Blueprint'
                  '${widget.proposedAdditions.length == 1 ? '' : 's'} detected. '
                  '${widget.uncertainIgnoredCount} uncertain slot'
                  '${widget.uncertainIgnoredCount == 1 ? '' : 's'} will be left unchanged. '
                  'Existing ownership and duplicate counts are preserved.',
                  style: ArcUiTokens.body(fontSize: 13),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: widget.proposedAdditions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final decision = widget.proposedAdditions[index];
                    return DecoratedBox(
                      decoration: ArcUiTokens.surfaceDecoration(
                        role: ArcSurfaceRole.interactive,
                        accent: ArcUiTokens.primaryAccent,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              color: ArcUiTokens.success,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _nameFor(decision.blueprintId),
                                style: ArcUiTokens.body(
                                  fontSize: 13,
                                  color: ArcUiTokens.textPrimary,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              '${(decision.confidence * 100).round()}%',
                              style: ArcUiTokens.metadata(
                                color: ArcUiTokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
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
                      _saving
                          ? 'Updating Blueprint Grid...'
                          : 'Update Blueprint Grid',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
