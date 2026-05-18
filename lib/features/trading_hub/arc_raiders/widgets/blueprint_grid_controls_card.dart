import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_filter.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class BlueprintGridControlsCard extends StatelessWidget {
  const BlueprintGridControlsCard({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.selectedFilter,
    required this.counts,
    required this.totalBlueprints,
    required this.selectionMode,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilterSelected,
    required this.onEnterSelectionMode,
    required this.onResetAll,
  });

  final TextEditingController searchController;
  final String searchQuery;
  final ArcBlueprintFilter selectedFilter;
  final Map<ArcBlueprintFilter, int> counts;
  final int totalBlueprints;
  final bool selectionMode;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<ArcBlueprintFilter> onFilterSelected;
  final VoidCallback onEnterSelectionMode;
  final VoidCallback onResetAll;

  @override
  Widget build(BuildContext context) {
    final ownedCount = counts[ArcBlueprintFilter.owned] ?? 0;
    final missingCount = counts[ArcBlueprintFilter.missing] ?? 0;
    final dupesCount = counts[ArcBlueprintFilter.duplicates] ?? 0;
    final completion = totalBlueprints == 0
        ? 0.0
        : ownedCount / totalBlueprints;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceL),
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonCyan.withValues(alpha: 0.16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TextField(
            controller: searchController,
            style: const TextStyle(color: Colors.white),
            onChanged: onSearchChanged,
            decoration:
                AppTheme.tradingInputDecoration(
                  label: 'Search blueprints',
                ).copyWith(
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Colors.white70,
                  ),
                  suffixIcon: searchQuery.trim().isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: onClearSearch,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                          ),
                        ),
                ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniActionButton(
                label: 'All (${counts[ArcBlueprintFilter.all] ?? 0})',
                selected: selectedFilter == ArcBlueprintFilter.all,
                onTap: () => onFilterSelected(ArcBlueprintFilter.all),
              ),
              _MiniActionButton(
                label: 'Owned ($ownedCount)',
                selected: selectedFilter == ArcBlueprintFilter.owned,
                onTap: () => onFilterSelected(ArcBlueprintFilter.owned),
              ),
              _MiniActionButton(
                label: 'Missing ($missingCount)',
                selected: selectedFilter == ArcBlueprintFilter.missing,
                onTap: () => onFilterSelected(ArcBlueprintFilter.missing),
              ),
              _MiniActionButton(
                label: 'Dupes ($dupesCount)',
                selected: selectedFilter == ArcBlueprintFilter.duplicates,
                onTap: () => onFilterSelected(ArcBlueprintFilter.duplicates),
              ),
              _MiniActionButton(
                label: selectionMode ? 'Selecting' : 'Select Multiple',
                selected: selectionMode,
                onTap: onEnterSelectionMode,
              ),
              _MiniActionButton(label: 'Reset All', onTap: onResetAll),
              const Tooltip(
                message:
                    'Tap missing to mark owned. Tap owned to edit reports or duplicates. Long press to select quickly.',
                child: Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: completion,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.neonCyan,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$ownedCount / $totalBlueprints owned • $missingCount missing • $dupesCount with dupes',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  const _MiniActionButton({
    required this.label,
    this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? AppTheme.neonPink : AppTheme.neonCyan;
    final backgroundColor = selected
        ? AppTheme.neonPink.withValues(alpha: 0.14)
        : AppTheme.cardBackgroundAlt;
    final textColor = selected ? AppTheme.neonPink : AppTheme.neonCyan;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.fastAnimation,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: onTap == null
              ? Colors.white.withValues(alpha: 0.03)
              : backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: onTap == null
                ? Colors.white.withValues(alpha: 0.10)
                : borderColor.withValues(alpha: 0.75),
          ),
        ),
        child: Text(
          label,
          style: AppTheme.buttonTextStyle(
            color: onTap == null ? Colors.white38 : textColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
