import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_import_service.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_photo_capture_session_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_layout_system.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

class ArcBlueprintPhotoReviewScreen extends StatefulWidget {
  const ArcBlueprintPhotoReviewScreen({
    super.key,
    required this.initialDecisions,
    required this.analysisWarnings,
  });

  final List<ArcBlueprintPhotoCellDecision> initialDecisions;
  final List<String> analysisWarnings;

  @override
  State<ArcBlueprintPhotoReviewScreen> createState() =>
      _ArcBlueprintPhotoReviewScreenState();
}

class _ArcBlueprintPhotoReviewScreenState
    extends State<ArcBlueprintPhotoReviewScreen> {
  late List<ArcBlueprintPhotoCellDecision> _decisions;
  ArcBlueprintPhotoImportService? _importService;
  bool _showUncertainOnly = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _decisions = List<ArcBlueprintPhotoCellDecision>.from(
      widget.initialDecisions,
    );
    if (!_decisions.any((decision) => decision.needsReview)) {
      _showUncertainOnly = false;
    }
  }

  String _nameFor(String blueprintId) {
    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      if (blueprint.id == blueprintId) return blueprint.name;
    }
    return blueprintId;
  }

  void _setDecision(
    ArcBlueprintPhotoCellDecision decision,
    ArcBlueprintPhotoCellState state,
  ) {
    final index = _decisions.indexWhere(
      (candidate) => candidate.blueprintId == decision.blueprintId,
    );
    if (index < 0) return;
    setState(() {
      _decisions[index] = decision.copyWith(
        state: state,
        confidence: 1,
        manuallyConfirmed: true,
      );
    });
  }

  Future<void> _apply() async {
    final unresolved = _decisions
        .where((decision) => decision.needsReview)
        .length;
    if (unresolved > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Review the remaining $unresolved uncertain slots.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ArcUiTokens.surfaceOverlay,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ArcUiTokens.radiusXL),
          side: BorderSide(
            color: ArcUiTokens.primaryAccent.withValues(alpha: 0.30),
          ),
        ),
        title: Text(
          'Apply Blueprint ownership?',
          style: ArcUiTokens.sectionTitle(
            fontSize: 18,
            color: ArcUiTokens.primaryAccent,
          ),
        ),
        content: Text(
          'This updates owned or missing status for the full in-game grid. Duplicate counts, priorities and other Blueprint data are preserved.',
          style: ArcUiTokens.body(color: ArcUiTokens.textSecondary),
        ),
        actions: [
          TextButton(
            style: ArcUiTokens.textButtonStyle(
              accent: ArcUiTokens.primaryAccent,
            ),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: ArcUiTokens.textButtonStyle(
              accent: ArcUiTokens.primaryAccent,
              primary: true,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apply Import'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      final summary =
          await (_importService ??= ArcBlueprintPhotoImportService()).apply(
            _decisions,
          );
      await ArcBlueprintPhotoCaptureSessionRepository.instance.clear();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: ArcUiTokens.surfaceOverlay,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ArcUiTokens.radiusXL),
            side: BorderSide(
              color: ArcUiTokens.success.withValues(alpha: 0.30),
            ),
          ),
          title: Text(
            'Blueprint grid imported',
            style: ArcUiTokens.sectionTitle(
              fontSize: 18,
              color: ArcUiTokens.success,
            ),
          ),
          content: Text(
            '${summary.ownedCount} owned and ${summary.missingCount} missing slots were confirmed. '
            '${summary.preservedDuplicateCount} duplicate records were preserved.',
            style: ArcUiTokens.body(color: ArcUiTokens.textSecondary),
          ),
          actions: [
            TextButton(
              style: ArcUiTokens.textButtonStyle(
                accent: ArcUiTokens.success,
                primary: true,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Blueprint import failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uncertainCount = _decisions
        .where((decision) => decision.needsReview)
        .length;
    final visible = _showUncertainOnly
        ? _decisions.where((decision) => decision.needsReview).toList()
        : _decisions;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'REVIEW BLUEPRINT IMPORT',
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
              padding: ArcLayoutTokens.pagePadding(context).copyWith(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.analysisWarnings.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        widget.analysisWarnings.join('\n'),
                        style: ArcUiTokens.body(
                          color: ArcUiTokens.warning,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          uncertainCount == 0
                              ? 'All ${_decisions.length} slots are ready to confirm.'
                              : '$uncertainCount uncertain slots need your decision.',
                          style: ArcUiTokens.body(fontSize: 13),
                        ),
                      ),
                      FilterChip(
                        key: const Key('blueprint-review-uncertain-filter'),
                        label: const Text('Uncertain only'),
                        selected: _showUncertainOnly,
                        onSelected: (value) {
                          setState(() => _showUncertainOnly = value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: visible.isEmpty
                  ? const Center(
                      child: Text(
                        'No uncertain slots remain. Turn off the filter to review the full import.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: ArcUiTokens.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final decision = visible[index];
                        return _DecisionCard(
                          key: ValueKey(
                            'blueprint-review-${decision.blueprintId}',
                          ),
                          name: _nameFor(decision.blueprintId),
                          decision: decision,
                          onOwned: () => _setDecision(
                            decision,
                            ArcBlueprintPhotoCellState.owned,
                          ),
                          onMissing: () => _setDecision(
                            decision,
                            ArcBlueprintPhotoCellState.missing,
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
              key: const Key('blueprint-review-apply'),
              onPressed: _saving ? null : _apply,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(
                uncertainCount == 0
                    ? 'Confirm and Apply Ownership'
                    : 'Review $uncertainCount Remaining',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({
    super.key,
    required this.name,
    required this.decision,
    required this.onOwned,
    required this.onMissing,
  });

  final String name;
  final ArcBlueprintPhotoCellDecision decision;
  final VoidCallback onOwned;
  final VoidCallback onMissing;

  @override
  Widget build(BuildContext context) {
    final confidence = (decision.confidence * 100).round();
    final selectedOwned = decision.state == ArcBlueprintPhotoCellState.owned;
    final selectedMissing =
        decision.state == ArcBlueprintPhotoCellState.missing;
    return Card(
      color: ArcUiTokens.surfacePanel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ArcUiTokens.radiusL),
        side: BorderSide(color: ArcUiTokens.borderMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ArcUiTokens.gapM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(name, style: ArcUiTokens.cardTitle(fontSize: 14)),
                ),
                Text(
                  decision.needsReview ? 'Needs review' : '$confidence%',
                  style: TextStyle(
                    color: decision.needsReview
                        ? ArcUiTokens.warning
                        : ArcUiTokens.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SegmentedButton<ArcBlueprintPhotoCellState>(
              segments: const [
                ButtonSegment(
                  value: ArcBlueprintPhotoCellState.owned,
                  icon: Icon(Icons.check_circle_outline),
                  label: Text('Owned'),
                ),
                ButtonSegment(
                  value: ArcBlueprintPhotoCellState.missing,
                  icon: Icon(Icons.radio_button_unchecked),
                  label: Text('Missing'),
                ),
              ],
              selected: {
                if (selectedOwned) ArcBlueprintPhotoCellState.owned,
                if (selectedMissing) ArcBlueprintPhotoCellState.missing,
              },
              emptySelectionAllowed: true,
              onSelectionChanged: (selection) {
                if (selection.contains(ArcBlueprintPhotoCellState.owned)) {
                  onOwned();
                } else if (selection.contains(
                  ArcBlueprintPhotoCellState.missing,
                )) {
                  onMissing();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
