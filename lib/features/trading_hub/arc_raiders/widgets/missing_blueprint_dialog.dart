import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class MissingBlueprintDialog extends StatelessWidget {
  const MissingBlueprintDialog({
    super.key,
    required this.blueprint,
    required this.currentState,
    required this.repository,
    required this.rarityColor,
  });

  final ArcBlueprint blueprint;
  final ArcBlueprintState currentState;
  final ArcBlueprintRepository repository;
  final Color rarityColor;

  Future<void> _markOwned(BuildContext context) async {
    await repository.saveBlueprintState(
      currentState.copyWith(owned: true, dupesOwned: 0),
    );

    if (!context.mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardBackgroundDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: rarityColor.withValues(alpha: 0.28)),
      ),
      title: Text(
        blueprint.name,
        style: AppTheme.tradingHeading(fontSize: 24, color: rarityColor),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This blueprint is currently marked as missing.',
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: AppTheme.spaceM),
          const Text(
            'Mark it as owned now, or close this window and leave it as missing for later.',
            style: TextStyle(color: Colors.white60, height: 1.35),
          ),
          const SizedBox(height: AppTheme.spaceM),
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceM),
            decoration: AppTheme.tradingCardDecoration(
              borderColor: AppTheme.neonCyan.withValues(alpha: 0.14),
            ),
            child: const Text(
              'Marking a blueprint as owned will set dupes to 0 by default. Dupes should only be added separately when you actually have extra copies.',
              style: TextStyle(color: Colors.white70, height: 1.35),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Close'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: rarityColor,
            foregroundColor: Colors.black,
          ),
          onPressed: () => _markOwned(context),
          icon: const Icon(Icons.check_circle_rounded),
          label: const Text('Mark Owned'),
        ),
      ],
    );
  }
}
