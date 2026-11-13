import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_filter.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

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
  static const _filters = <MapEntry<ArcScrappyFilter, String>>[
    MapEntry(ArcScrappyFilter.all, 'ALL'),
    MapEntry(ArcScrappyFilter.owned, 'READY'),
    MapEntry(ArcScrappyFilter.missing, 'NEEDED'),
    MapEntry(ArcScrappyFilter.duplicates, 'DUPES'),
    MapEntry(ArcScrappyFilter.wanted, 'WANTED'),
    MapEntry(ArcScrappyFilter.tradeable, 'TRADE'),
  ];
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final entry in _filters)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _chip(entry.key, entry.value),
          ),
      ],
    ),
  );
  Widget _chip(ArcScrappyFilter filter, String label) {
    final selected = selectedFilter == filter;
    final color = selected
        ? ArcUiTokens.primaryAccent
        : ArcUiTokens.textTertiary;
    return InkWell(
      borderRadius: BorderRadius.circular(ArcUiTokens.radiusS),
      onTap: () => onFilterSelected(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: ArcUiTokens.surfaceDecoration(
          role: selected ? ArcSurfaceRole.interactive : ArcSurfaceRole.panel,
          radius: ArcUiTokens.radiusS,
          accent: color,
          borderOpacity: selected ? 0.38 : 0.10,
        ),
        child: Text(
          '$label ${counts[filter] ?? 0}',
          style: ArcUiTokens.metadata(
            color: color,
          ).copyWith(fontWeight: FontWeight.w800, letterSpacing: .45),
        ),
      ),
    );
  }
}
