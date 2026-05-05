import 'package:flutter/material.dart';

import 'package:uag_traders_hub/widgets/theme.dart';

class BlueprintSelectionToolbelt extends StatelessWidget {
  const BlueprintSelectionToolbelt({
    super.key,
    required this.visible,
    required this.selectedCount,
    required this.hasFilteredItems,
    this.onSelectAll,
    this.onSelectRow,
    this.onSelectColumn,
    this.onMarkOwned,
    this.onAddDupe,
    this.onClearSelected,
    required this.onExitSelection,
  });

  final bool visible;
  final int selectedCount;
  final bool hasFilteredItems;
  final VoidCallback? onSelectAll;
  final VoidCallback? onSelectRow;
  final VoidCallback? onSelectColumn;
  final VoidCallback? onMarkOwned;
  final VoidCallback? onAddDupe;
  final VoidCallback? onClearSelected;
  final VoidCallback onExitSelection;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.spaceM),
          decoration: BoxDecoration(
            color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.neonPink.withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.neonPink.withValues(alpha: 0.08),
                blurRadius: 14,
                spreadRadius: 0.2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$selectedCount selected',
                style: AppTheme.tradingHeading(
                  fontSize: 18,
                  color: AppTheme.neonPink,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ToolbeltButton(
                    label: 'Select All',
                    onTap: hasFilteredItems ? onSelectAll : null,
                    color: AppTheme.neonCyan,
                  ),
                  _ToolbeltButton(
                    label: 'Select Row',
                    onTap: hasFilteredItems ? onSelectRow : null,
                    color: AppTheme.neonCyan,
                  ),
                  _ToolbeltButton(
                    label: 'Select Column',
                    onTap: hasFilteredItems ? onSelectColumn : null,
                    color: AppTheme.neonCyan,
                  ),
                  _ToolbeltButton(
                    label: 'Mark Owned',
                    onTap: onMarkOwned,
                    color: AppTheme.neonPink,
                  ),
                  _ToolbeltButton(
                    label: 'Add 1 Dupe',
                    onTap: onAddDupe,
                    color: AppTheme.neonPink,
                  ),
                  _ToolbeltButton(
                    label: 'Clear Selected',
                    onTap: onClearSelected,
                    color: Colors.redAccent,
                  ),
                  _ToolbeltButton(
                    label: 'Exit Selection',
                    onTap: onExitSelection,
                    color: Colors.white70,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbeltButton extends StatelessWidget {
  const _ToolbeltButton({
    required this.label,
    required this.onTap,
    required this.color,
  });

  final String label;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: onTap == null
              ? Colors.white.withValues(alpha: 0.03)
              : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: onTap == null
                ? Colors.white.withValues(alpha: 0.10)
                : color.withValues(alpha: 0.40),
          ),
        ),
        child: Text(
          label,
          style: AppTheme.buttonTextStyle(
            color: onTap == null ? Colors.white38 : color,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
