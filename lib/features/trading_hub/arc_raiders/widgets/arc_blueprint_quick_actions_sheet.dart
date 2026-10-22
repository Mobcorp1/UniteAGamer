import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

enum ArcBlueprintQuickAction {
  add,
  clear,
  intel,
  addDuplicate,
  removeDuplicate,
  addReport,
}

/// Contextual actions do not mutate Blueprint state until the player chooses.
/// Ownership, duplicate and priority writes stay in the existing repository.
class ArcBlueprintQuickActionsSheet extends StatelessWidget {
  const ArcBlueprintQuickActionsSheet({
    super.key,
    required this.blueprint,
    required this.state,
  });

  final ArcBlueprint blueprint;
  final ArcBlueprintState state;

  @override
  Widget build(BuildContext context) {
    Widget action({
      required String keyName,
      required String label,
      required IconData icon,
      required Color accent,
      required ArcBlueprintQuickAction value,
    }) {
      return OutlinedButton.icon(
        key: Key(keyName),
        onPressed: () => Navigator.of(context).pop(value),
        icon: Icon(icon, color: accent),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: accent.withValues(alpha: 0.55)),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(blueprint.name.toUpperCase(),
                    style: AppTheme.tradingHeading(
                      fontSize: 23, color: AppTheme.neonCyan)),
                ),
                IconButton(
                  tooltip: 'Close blueprint actions',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                ),
              ],
            ),
            Text(
              state.owned
                  ? 'OWNED · ${state.dupesOwned} DUPLICATE${state.dupesOwned == 1 ? '' : 'S'}'
                  : 'MISSING · FIND THIS BLUEPRINT',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!state.owned)
                  action(keyName: 'blueprint-action-add', label: 'ADD',
                    icon: Icons.add_circle_outline_rounded,
                    accent: AppTheme.neonCyan,
                    value: ArcBlueprintQuickAction.add),
                action(keyName: 'blueprint-action-clear', label: 'CLEAR',
                  icon: Icons.clear_rounded, accent: AppTheme.neonPink,
                  value: ArcBlueprintQuickAction.clear),
                action(keyName: 'blueprint-action-intel', label: 'INTEL',
                  icon: Icons.radar_rounded, accent: Colors.amberAccent,
                  value: ArcBlueprintQuickAction.intel),
                if (state.owned) ...[
                  if (state.dupesOwned < 999)
                    action(keyName: 'blueprint-action-add-dupe', label: 'ADD DUPE +1',
                      icon: Icons.add_circle_outline_rounded,
                      accent: AppTheme.neonCyan,
                      value: ArcBlueprintQuickAction.addDuplicate),
                  if (state.dupesOwned > 0)
                    action(keyName: 'blueprint-action-remove-dupe', label: 'REMOVE DUPE',
                      icon: Icons.remove_circle_outline_rounded,
                      accent: AppTheme.neonPink,
                      value: ArcBlueprintQuickAction.removeDuplicate),
                  action(keyName: 'blueprint-action-report', label: 'ADD REPORT',
                    icon: Icons.add_location_alt_outlined,
                    accent: Colors.white70,
                    value: ArcBlueprintQuickAction.addReport),
                ],
              ],
            ),
          ],
          ),
        ),
      ),
    );
  }
}
