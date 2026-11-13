import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_filter.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class BlueprintFilterBar extends StatelessWidget {
  const BlueprintFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.counts,
    required this.selectionMode,
    this.onEnterSelectionMode,
    this.onSelectionToolSelected,
  });

  final ArcBlueprintFilter selectedFilter;
  final ValueChanged<ArcBlueprintFilter> onFilterSelected;
  final Map<ArcBlueprintFilter, int> counts;
  final bool selectionMode;
  final VoidCallback? onEnterSelectionMode;
  final ValueChanged<String>? onSelectionToolSelected;

  static const List<MapEntry<ArcBlueprintFilter, String>> _filters = [
    MapEntry(ArcBlueprintFilter.all, 'All'),
    MapEntry(ArcBlueprintFilter.owned, 'Owned'),
    MapEntry(ArcBlueprintFilter.missing, 'Missing'),
    MapEntry(ArcBlueprintFilter.duplicates, 'Dupes'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final entry in _filters) ...[
            _BlueprintFilterChip(
              label: '${entry.value} (${counts[entry.key] ?? 0})',
              selected: selectedFilter == entry.key,
              onTap: () => onFilterSelected(entry.key),
            ),
            const SizedBox(width: 8),
          ],
          _BlueprintFilterChip(
            label: selectionMode ? 'Selecting' : 'Select',
            selected: selectionMode,
            onTap: onEnterSelectionMode,
            accent: AppTheme.neonPink,
          ),
        ],
      ),
    );
  }
}

class _BlueprintFilterChip extends StatelessWidget {
  const _BlueprintFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.accent = AppTheme.neonCyan,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.fastAnimation,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.16)
              : Colors.black.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.72)
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          style: AppTheme.buttonTextStyle(
            color: selected ? accent : Colors.white70,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
