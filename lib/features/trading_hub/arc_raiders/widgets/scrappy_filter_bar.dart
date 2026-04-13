import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_filter.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class ScrappyFilterBar extends StatelessWidget {
  const ScrappyFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.counts,
  });

  final ArcScrappyFilter selectedFilter;
  final ValueChanged<ArcScrappyFilter> onFilterSelected;
  final Map<ArcScrappyFilter, int> counts;

  static const List<MapEntry<ArcScrappyFilter, String>> _filters = [
    MapEntry(ArcScrappyFilter.all, 'All'),
    MapEntry(ArcScrappyFilter.owned, 'Owned'),
    MapEntry(ArcScrappyFilter.missing, 'Missing'),
    MapEntry(ArcScrappyFilter.duplicates, 'Dupes'),
    MapEntry(ArcScrappyFilter.wanted, 'Wanted'),
    MapEntry(ArcScrappyFilter.tradeable, 'Available'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _filters
          .map((entry) => _buildFilterChip(entry.key, entry.value))
          .toList(growable: false),
    );
  }

  Widget _buildFilterChip(ArcScrappyFilter filter, String label) {
    final selected = selectedFilter == filter;
    final count = counts[filter] ?? 0;

    return FilterChip(
      selected: selected,
      onSelected: (_) => onFilterSelected(filter),
      selectedColor: AppTheme.neonPink.withValues(alpha: 0.20),
      checkmarkColor: AppTheme.neonPink,
      backgroundColor: AppTheme.cardBackgroundAlt,
      side: BorderSide(
        color: selected
            ? AppTheme.neonPink.withValues(alpha: 0.75)
            : AppTheme.neonCyan.withValues(alpha: 0.20),
      ),
      label: Text(
        '$label ($count)',
        style: TextStyle(
          color: selected ? AppTheme.neonPink : AppTheme.neonCyan,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
